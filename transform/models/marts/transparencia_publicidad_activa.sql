-- Evaluaciones oficiales del cumplimiento de la publicidad activa (Ley 19/2013 y
-- leyes autonómicas), formato largo: una fila por evaluador, entidad y evaluación.
--
-- Solo hay dos fuentes oficiales con puntuación por entidad reutilizable:
--   * ITCanarias (Comisionado de Transparencia de Canarias), 0-10 -> x10.
--   * ICIO del CTBG (metodología MESTA), ya en 0-100.
-- Las escalas no son comparables entre evaluadores: la puntuación 0-100 solo
-- homogeneiza el rango.
--
-- Atribución: gobierno en funciones en fecha_referencia (fin del periodo evaluado
-- en el ITCanarias; 30 de junio del año de la evaluación en el CTBG). Ayuntamientos
-- -> alcalde (alcaldes_historia); comunidades -> presidente autonómico; AGE ->
-- presidente del Gobierno (seed gobiernos_presidentes). Cabildos y entes
-- dependientes quedan sin atribuir.

with itc as (
    select * from {{ source('raw_transparencia_publicidad_activa', 'pa_itcanarias') }}
),

ctbg as (
    select * from {{ source('raw_transparencia_publicidad_activa', 'pa_ctbg') }}
),

-- municipios de Canarias con el nombre como lo escribe el Comisionado
-- («Ayuntamiento de Las Palmas de Gran Canaria» frente a «Palmas de Gran Canaria, Las»)
mun_canarias as (
    select
        cod_mun,
        any_value(municipio) as municipio,
        any_value(cod_prov) as cod_prov,
        lower(strip_accents(any_value(case
            when regexp_matches(municipio, ', (El|La|Los|Las)$')
                then regexp_extract(municipio, ', (El|La|Los|Las)$', 1) || ' ' || regexp_replace(municipio, ', (El|La|Los|Las)$', '')
            else municipio
        end))) as clave_nombre
    from {{ ref('poblacion_municipios') }}
    where cod_ccaa = '05' and vigente
    group by cod_mun
),

-- nombres del Comisionado que no coinciden con el nomenclátor del INE
alias_canarias(nombre_itc, cod_mun) as (
    values
        ('valsequillo', '35031'),
        ('la villa de mazo', '38053'),
        ('la frontera', '38013'),
        ('vilaflor', '38052'),
        ('fuencaliente', '38014'),
        ('santa maria de guia', '35023')
),

cabildos(entidad, cod_prov) as (
    values
        ('Cabildo Insular de El Hierro', '38'),
        ('Cabildo Insular de Fuerteventura', '35'),
        ('Cabildo Insular de Gran Canaria', '35'),
        ('Cabildo Insular de La Gomera', '38'),
        ('Cabildo Insular de La Palma', '38'),
        ('Cabildo Insular de Lanzarote', '35'),
        ('Cabildo Insular de Tenerife', '38')
),

itc_base as (
    select
        'Comisionado de Transparencia de Canarias' as evaluador,
        'ITCanarias' as indice,
        i.entidad,
        i.tipo_entidad,
        case
            when i.tipo_entidad = 'Comunidad Autónoma' then 'Comunidad autónoma'
            when i.tipo_entidad = 'Cabildos' then 'Cabildo insular'
            when i.tipo_entidad = 'Ayuntamientos' then 'Ayuntamiento'
            else 'Entes dependientes y otros'
        end as tipo_administracion,
        i.entidad_principal,
        i.periodo,
        i.orden_periodo,
        cast(i.anio as integer) as anio,
        case
            when i.periodo like '2022%' then date '2023-06-01'     -- 2022-1.er sem. 2023: corporaciones 2019-2023
            else make_date(cast(i.anio as integer), 12, 31)
        end as fecha_referencia,
        i.estado,
        i.puntuacion as puntuacion_original,
        '0-10' as escala_original,
        i.puntuacion * 10 as puntuacion,
        -- ayuntamiento propio o del que depende el ente
        lower(strip_accents(regexp_replace(
            case when i.tipo_entidad = 'Ayuntamientos' then i.entidad else i.entidad_principal end,
            '^Ayuntamiento de ', ''))) as clave_nombre,
        (i.tipo_entidad = 'Ayuntamientos' or i.entidad_principal like 'Ayuntamiento de %') as es_local,
        i.url_fuente,
        'https://transparenciacanarias.org/evaluacion/puntuaciones/' as url_pagina
    from itc i
),

itc_territorio as (
    select
        b.*,
        '05' as cod_ccaa,
        coalesce(m.cod_prov, m2.cod_prov, c.cod_prov) as cod_prov,
        coalesce(m.cod_mun, m2.cod_mun) as cod_mun
    from itc_base b
    left join alias_canarias a on b.es_local and a.nombre_itc = b.clave_nombre
    left join mun_canarias m on b.es_local and m.cod_mun = a.cod_mun
    left join mun_canarias m2 on b.es_local and a.cod_mun is null and m2.clave_nombre = b.clave_nombre
    left join cabildos c on c.entidad = b.entidad
                         or (b.tipo_entidad like '%(cabildo)%' and c.entidad = b.entidad_principal)
),

ctbg_base as (
    select
        'Consejo de Transparencia y Buen Gobierno' as evaluador,
        'ICIO (MESTA)' as indice,
        entidad,
        case tipo when 'age' then 'Administración General del Estado'
                  when 'ccaa' then 'Comunidad o ciudad autónoma'
                  else 'Ayuntamiento' end as tipo_entidad,
        case tipo when 'age' then 'Administración General del Estado'
                  when 'ccaa' then 'Comunidad autónoma'
                  else 'Ayuntamiento' end as tipo_administracion,
        entidad as entidad_principal,
        cast(anio as varchar) as periodo,
        cast(anio as integer) - 2015 as orden_periodo,
        cast(anio as integer) as anio,
        make_date(cast(anio as integer), 6, 30) as fecha_referencia,
        'evaluada' as estado,
        icio as puntuacion_original,
        '0-100 %' as escala_original,
        icio as puntuacion,
        case tipo when 'ccaa' then cod when 'ayuntamiento' then left(cod, 2) end as cod_prov_o_ccaa,
        tipo,
        cod,
        url_fuente,
        url_pagina
    from ctbg
),

ctbg_territorio as (
    select
        b.* exclude (cod_prov_o_ccaa, tipo, cod),
        case when b.tipo = 'ccaa' then b.cod
             when b.tipo = 'ayuntamiento' then p.cod_ccaa
             else '00' end as cod_ccaa,  -- '00' = España (AGE), como en territorios
        case when b.tipo = 'ayuntamiento' then left(b.cod, 2) end as cod_prov,
        case when b.tipo = 'ayuntamiento' then b.cod end as cod_mun
    from ctbg_base b
    left join (
        select cod_mun, any_value(cod_ccaa) as cod_ccaa from {{ ref('poblacion_municipios') }} group by cod_mun
    ) p on p.cod_mun = b.cod
),

unido as (
    select evaluador, indice, entidad, tipo_entidad, tipo_administracion, entidad_principal,
        periodo, orden_periodo, anio, fecha_referencia, estado, puntuacion_original, escala_original,
        puntuacion, cod_ccaa, cod_prov, cod_mun, url_fuente, url_pagina
    from itc_territorio
    union all
    select evaluador, indice, entidad, tipo_entidad, tipo_administracion, entidad_principal,
        periodo, orden_periodo, anio, fecha_referencia, estado, puntuacion_original, escala_original,
        puntuacion, cod_ccaa, cod_prov, cod_mun, url_fuente, url_pagina
    from ctbg_territorio
),

alcaldes as (
    select cod_mun, fecha_posesion, fecha_fin, familia, alcalde
    from {{ ref('alcaldes_historia') }}
),

gobiernos as (
    select nivel, cod, desde, hasta, familia, presidente
    from {{ ref('gobiernos_presidentes') }}
),

atribuido as (
    select
        u.*,
        coalesce(a.familia, g.familia) as familia,
        coalesce(a.alcalde, g.presidente) as gobernante,
        case when a.familia is not null then 'alcalde'
             when g.familia is not null and u.tipo_administracion = 'Administración General del Estado' then 'presidente del Gobierno'
             when g.familia is not null then 'presidente autonómico' end as tipo_gobernante
    from unido u
    left join alcaldes a
        on u.tipo_administracion = 'Ayuntamiento'
        and a.cod_mun = u.cod_mun
        and a.fecha_posesion <= u.fecha_referencia
        and coalesce(a.fecha_fin, date '9999-12-31') > u.fecha_referencia
    left join gobiernos g
        on u.tipo_administracion in ('Comunidad autónoma', 'Administración General del Estado')
        and g.nivel = case when u.tipo_administracion = 'Comunidad autónoma' then 'autonomico' else 'estatal' end
        and g.cod = case when u.tipo_administracion = 'Comunidad autónoma' then u.cod_ccaa else '00' end
        and g.desde <= u.fecha_referencia
        and coalesce(g.hasta, date '9999-12-31') > u.fecha_referencia
    qualify row_number() over (
        partition by u.evaluador, u.entidad, u.periodo
        order by a.fecha_posesion desc nulls last, g.desde desc nulls last
    ) = 1
),

pob as (
    select cod_mun, anio, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
)

select
    t.evaluador,
    t.indice,
    t.entidad,
    t.tipo_entidad,
    t.tipo_administracion,
    t.entidad_principal,
    t.cod_ccaa,
    t.cod_prov,
    t.cod_mun,
    t.periodo,
    t.orden_periodo,
    t.anio,
    t.fecha_referencia,
    t.estado,
    t.puntuacion_original,
    t.escala_original,
    t.puntuacion,
    t.familia,
    t.gobernante,
    t.tipo_gobernante,
    -- población municipal del año evaluado (o la más cercana publicada)
    case when t.tipo_administracion = 'Ayuntamiento' then (
        select p.poblacion from pob p
        where p.cod_mun = t.cod_mun
        order by abs(p.anio - t.anio), p.anio desc
        limit 1
    ) end as poblacion,
    t.orden_periodo = max(t.orden_periodo) over (partition by t.evaluador, t.entidad) as es_ultima,
    t.url_fuente,
    t.url_pagina,
    t.evaluador || '|' || t.entidad || '|' || t.periodo as clave
from atribuido t
