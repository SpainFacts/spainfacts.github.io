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

{% set articulos = "el|la|los|las|l''|els|les|lo|o|a|os|as|sa|ses|es|s''" %}
{% set normaliza -%}
regexp_replace(
    regexp_replace(
        regexp_replace(lower(strip_accents(trim(__E__))), '^(.*), ({{ articulos }})$', '\2 \1'),
        '^(.*) \(({{ articulos }})\)$', '\2 \1'),
    '[^a-z0-9]', '', 'g')
{%- endset %}

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

-- Nombres de municipio normalizados (Cataluña y Murcia): sin tildes ni signos, con
-- el artículo pospuesto del INE delante («Bisbal d'Empordà, La» = «La Bisbal d'Empordà»)
-- y cada parte de los nombres bilingües «A/B».
nombres_mun as (
    select distinct cod_mun, cod_prov, cod_ccaa, {{ normaliza | replace('__E__', 'parte') }} as nombre_norm
    from (
        select cod_mun, cod_prov, cod_ccaa, municipio as parte
        from {{ ref('poblacion_municipios') }} where vigente and cod_ccaa in ('09', '14')
        union all
        select cod_mun, cod_prov, cod_ccaa, unnest(string_split(municipio, '/'))
        from {{ ref('poblacion_municipios') }} where vigente and cod_ccaa in ('09', '14') and municipio like '%/%'
    )
),

-- Nombres del Consejo de Murcia que no coinciden con el nomenclátor
alias_murcia(nombre, cod_mun) as (
    values ('caravaca', '30015'), ('fuentealamo', '30021'), ('villanuevadelsegura', '30042')
),

provincias_cat(nombre, cod_prov) as (
    values ('Barcelona', '08'), ('Girona', '17'), ('Lleida', '25'), ('Tarragona', '43')
),

-- Síndic de Greuges de Catalunya (IDPAC, edición 2026)
sindic_base as (
    select
        'Síndic de Greuges de Catalunya' as evaluador,
        'IDPAC' as indice,
        s.entidad,
        s.categoria_n3 as tipo_entidad,
        case
            when s.categoria_n2 = 'Ajuntaments' then 'Ayuntamiento'
            when s.categoria_n3 = 'Diputacions' then 'Diputación provincial'
            when s.categoria_n2 = 'Departaments' then 'Comunidad autónoma'
            else 'Entes dependientes y otros'
        end as tipo_administracion,
        case when s.categoria_n2 = 'Departaments' then 'Generalitat de Catalunya' else s.entidad end as entidad_principal,
        cast(s.edicion as varchar) as periodo,
        1 as orden_periodo,
        cast(s.edicion as integer) as anio,
        make_date(cast(s.edicion as integer), 5, 31) as fecha_referencia,  -- fin del trabajo de campo
        case when s.idpac is null then 'sin_dato' else 'evaluada' end as estado,
        s.idpac as puntuacion_original,
        '0-100' as escala_original,
        s.idpac as puntuacion,
        '09' as cod_ccaa,
        case when s.categoria_n2 = 'Ajuntaments' then n.cod_prov
             when s.categoria_n3 = 'Diputacions' then pc.cod_prov end as cod_prov,
        case when s.categoria_n2 = 'Ajuntaments' then n.cod_mun end as cod_mun,
        s.url_fuente,
        s.url_pagina
    from {{ source('raw_transparencia_publicidad_activa', 'pa_sindic') }} s
    left join provincias_cat pc on pc.nombre = s.provincia
    left join nombres_mun n
        on s.categoria_n2 = 'Ajuntaments'
        and n.cod_prov = pc.cod_prov
        and n.nombre_norm = {{ normaliza | replace('__E__', "case s.municipio when 'Les Piles de Gaià' then 'Les Piles' else s.municipio end") }}
    where s.idpac is not null
    qualify row_number() over (partition by s.entidad order by n.cod_mun) = 1
),

-- Consejo de la Transparencia de la Región de Murcia (ICPA 2020-2023)
murcia_base as (
    select
        'Consejo de la Transparencia de la Región de Murcia' as evaluador,
        'ICPA' as indice,
        m.entidad,
        m.tipo_entidad,
        case
            when m.tipo_entidad = 'Ayuntamientos' then 'Ayuntamiento'
            when m.tipo_entidad = 'Comunidad Autónoma' then 'Comunidad autónoma'
            else 'Entes dependientes y otros'
        end as tipo_administracion,
        m.entidad as entidad_principal,
        cast(m.anio as varchar) as periodo,
        cast(m.anio as integer) - 2019 as orden_periodo,
        cast(m.anio as integer) as anio,
        make_date(cast(m.anio as integer), 12, 31) as fecha_referencia,
        case m.estado when 'no_participo' then 'no_participo' when 'evaluada' then 'evaluada' else 'sin_dato' end as estado,
        m.icpa as puntuacion_original,
        '0-10' as escala_original,
        m.icpa * 10 as puntuacion,
        '14' as cod_ccaa,
        case when m.tipo_entidad = 'Ayuntamientos' then '30' end as cod_prov,
        case when m.tipo_entidad = 'Ayuntamientos' then coalesce(a.cod_mun, n.cod_mun) end as cod_mun,
        m.url_fuente,
        m.url_pagina
    from {{ source('raw_transparencia_publicidad_activa', 'pa_murcia') }} m
    left join alias_murcia a
        on m.tipo_entidad = 'Ayuntamientos'
        and a.nombre = {{ normaliza | replace('__E__', "regexp_replace(m.entidad, '^AYUNTAMIENTO DE ', '')") }}
    left join nombres_mun n
        on m.tipo_entidad = 'Ayuntamientos'
        and n.cod_prov = '30'
        and n.nombre_norm = {{ normaliza | replace('__E__', "regexp_replace(m.entidad, '^AYUNTAMIENTO DE ', '')") }}
    where m.estado <> 'sin_dato'
    qualify row_number() over (partition by m.entidad, m.anio order by n.cod_mun) = 1
),

-- CTBG, informes agregados (sector público estatal y otros sujetos de su ámbito)
ctbg_agr_base as (
    select
        'Consejo de Transparencia y Buen Gobierno' as evaluador,
        'ICIO (MESTA)' as indice,
        entidad,
        grupo as tipo_entidad,
        case when grupo = 'Entidades privadas subvencionadas' then 'Entidades privadas'
             when grupo = 'Corporaciones de derecho público' then 'Corporaciones de derecho público'
             else 'Sector público estatal' end as tipo_administracion,
        entidad as entidad_principal,
        cast(anio as varchar) || case when ronda > 1 then ' (' || ronda || 'ª evaluación)' else '' end as periodo,
        cast(anio as integer) - 2015 as orden_periodo,
        cast(anio as integer) as anio,
        make_date(cast(anio as integer), 6, 30) as fecha_referencia,
        'evaluada' as estado,
        icio as puntuacion_original,
        '0-100 %' as escala_original,
        icio as puntuacion,
        '00' as cod_ccaa,
        cast(null as varchar) as cod_prov,
        cast(null as varchar) as cod_mun,
        url_fuente,
        'https://consejodetransparencia.es/evaluacion' as url_pagina
    from {{ source('raw_transparencia_publicidad_activa', 'pa_ctbg_agregados') }}
),

unido as (
    {% for cte in ['itc_territorio', 'ctbg_territorio', 'sindic_base', 'murcia_base', 'ctbg_agr_base'] %}
    select evaluador, indice, entidad, tipo_entidad, tipo_administracion, entidad_principal,
        periodo, orden_periodo, anio, fecha_referencia, estado, puntuacion_original, escala_original,
        puntuacion, cod_ccaa, cod_prov, cod_mun, url_fuente, url_pagina
    from {{ cte }}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
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
    tc.nombre as ccaa,
    t.cod_prov,
    tp.nombre as provincia,
    t.cod_mun,
    nm.municipio,
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
left join {{ ref('territorios') }} tc on tc.nivel in ('ccaa', 'pais') and tc.cod = t.cod_ccaa
left join {{ ref('territorios') }} tp on tp.nivel = 'provincia' and tp.cod = t.cod_prov
left join (
    select cod_mun, municipio
    from {{ ref('poblacion_municipios') }}
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
) nm on nm.cod_mun = t.cod_mun
