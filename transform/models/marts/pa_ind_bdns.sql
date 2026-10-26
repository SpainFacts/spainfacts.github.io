-- Índice propio de publicidad activa: concesiones de subvenciones registradas en la
-- Base de Datos Nacional de Subvenciones (BDNS) a tiempo. Elaboración propia, criterios
-- en docs/elaboracion-propia/bdns.md; ingesta en ingestion/pa_bdns.py.
--
-- Obligación: art. 5.2.b RD 130/2019 (BOE-A-2019-4671) y art. 20 Ley 38/2003: cada
-- concesión se registra «antes de que finalice el mes siguiente» al de la concesión.
-- Fuera de plazo = fechaAlta en la BDNS posterior al último día del mes siguiente a
-- fechaConcesion (calculado concesión a concesión en la ingesta).
--
-- Una fila por entidad y año natural de concesión (periodo = 'AAAA'), con el universo
-- completo: todos los ayuntamientos del padrón (sin Ceuta ni Melilla), las 41
-- diputaciones (38 provinciales y 3 forales), los 7 cabildos y 4 consells insulares y
-- las 19 comunidades y ciudades autónomas.
--   con_registros   la entidad tiene al menos una concesión registrada ese año;
--                   n_total, n_fuera_plazo y mediana_dias la miden
--   sin_registros   ninguna concesión registrada ese año. NO es un incumplimiento por
--                   sí mismo: puede que no conceda subvenciones (o que se las conceda la
--                   diputación por ella)
--   no_vencido      año en curso, o año cuyo último plazo (31-ene del año siguiente)
--                   aún no ha pasado el día de la medición
--   no_aplica       el dato no mide a la entidad: Consell de Formentera (= ayuntamiento),
--                   diputaciones forales de Álava y Gipuzkoa y Gobierno Vasco (no registran
--                   o registran una parte mínima de sus concesiones en la BDNS)
--
-- Entidad = todos los órganos concedentes del nodo de la BDNS: el ayuntamiento con sus
-- áreas, distritos, organismos autónomos, fundaciones y sociedades (Madrid registra por
-- sus distritos y áreas, no como «Ayuntamiento de Madrid»); la diputación con sus
-- organismos; la comunidad con todas sus consejerías y entes. Mancomunidades, comarcas,
-- consells comarcals, consorcios y entidades locales menores que son nodo propio no se
-- atribuyen a nadie.
--
-- Medición: la API solo enseña los 4 últimos años y quita las concesiones a personas
-- físicas al acabar el año siguiente al de concesión. Para el año N se usa la medición
-- hecha durante N+1; si no la hay, la más reciente, y x_medicion_tardia = true (faltan
-- las concesiones a personas físicas: no comparable con los años bien medidos).

with conc as (
    -- última descarga de cada mes dentro de cada año de medición
    select
        c.*,
        cast(left(c.mes, 4) as integer) as anio
    from {{ source('raw_pa_bdns', 'pa_bdns_concesiones_mes') }} c
    qualify c.fecha_medicion = max(c.fecha_medicion) over (partition by c.tipo_admon, c.mes, c.anio_medicion)
),

medicion as (
    select
        tipo_admon,
        anio,
        coalesce(max(anio_medicion) filter (where anio_medicion = anio + 1), max(anio_medicion)) as anio_medicion
    from conc
    group by all
),

fecha_medicion as (
    select c.tipo_admon, c.anio, max(c.fecha_medicion)::date as fecha_medicion
    from conc c
    join medicion m using (tipo_admon, anio, anio_medicion)
    group by all
),

conc_sel as (
    select c.*
    from conc c
    join medicion m using (tipo_admon, anio, anio_medicion)
),

-- convocatorias (fecha de recepción): no desaparecen, se usa la última medición
conv as (
    select c.*, cast(left(c.mes, 4) as integer) as anio
    from {{ source('raw_pa_bdns', 'pa_bdns_convocatorias_mes') }} c
    qualify c.fecha_medicion = max(c.fecha_medicion) over (partition by c.tipo_admon, c.mes, c.anio_medicion)
        and c.anio_medicion = max(c.anio_medicion) over (partition by c.tipo_admon, c.mes)
),

filas as (
    select 'concesiones' as que, tipo_admon, nivel1, nivel2, nivel3, id_organo, anio,
        n, n_fuera_plazo, n_persona_fisica, n_sin_fecha_alta, importe, dias_hist,
        cast(null as bigint) as n_convocatorias
    from conc_sel
    union all
    select 'convocatorias', tipo_admon, nivel1, nivel2, nivel3, id_organo, anio,
        null, null, null, null, null, null, n_convocatorias
    from conv
),

organos as (
    select *
    from {{ source('raw_pa_bdns', 'pa_bdns_organos') }}
    qualify row_number() over (partition by tipo_admon, id_organo order by visto desc) = 1
),

-- pares (nodo, órgano) y nodos: si el nombre se repite en dos nodos no se casa por nombre
pares as (
    select tipo_admon, trim(nodo) as nodo, trim(organo) as organo,
        count(distinct id_nodo) as n_nodos, any_value(cod_agrupacion) as cod_agrupacion,
        any_value(nodo) as nodo_original
    from organos
    group by all
),

nodos as (
    select tipo_admon, trim(nodo) as nodo,
        count(distinct id_nodo) as n_nodos, any_value(cod_agrupacion) as cod_agrupacion,
        any_value(nodo) as nodo_original
    from organos
    group by all
),

conc_cod as (
    select
        c.*,
        case
            when c.id_organo > 0 then o.cod_agrupacion
            when p.n_nodos = 1 then p.cod_agrupacion
            when p.n_nodos > 1 then null      -- ambiguo: lo cubren las filas pedidas por id
            when n.n_nodos = 1 then n.cod_agrupacion
        end as cod_agrupacion,
        coalesce(o.nodo, p.nodo_original, n.nodo_original, c.nivel2) as nodo,
        c.id_organo = 0 and p.n_nodos > 1 as ambiguo
    from filas c
    left join organos o on c.id_organo > 0 and o.tipo_admon = c.tipo_admon and o.id_organo = c.id_organo
    left join pares p on c.id_organo = 0 and p.tipo_admon = c.tipo_admon
        and p.nodo = trim(c.nivel2) and p.organo = trim(c.nivel3)
    left join nodos n on c.id_organo = 0 and n.tipo_admon = c.tipo_admon and n.nodo = trim(c.nivel2)
),

municipios_ine as (
    select distinct cod_mun from {{ ref('poblacion_municipios') }}
),

-- tipo de entidad del nodo. Municipio: código INE de 6 cifras con dígito de control
-- válido (algoritmo del INE) y municipio existente en el padrón; las mancomunidades y
-- comarcas tienen códigos propios que no lo cumplen o no existen en el padrón.
conc_ent as (
    select
        c.*,
        case
            when c.tipo_admon = 'A' then 'Comunidad autónoma'
            when c.cod_agrupacion like '__0000' and upper(c.nodo) like 'DIPUTACI%' then 'Diputación provincial'
            when c.cod_agrupacion in ('355010', '355020', '355030', '385010', '385020', '385030', '385040',
                                      '075010', '075020', '075030') then 'Cabildo o consell insular'
            when length(c.cod_agrupacion) = 6
                 and regexp_full_match(c.cod_agrupacion, '[0-9]{6}')
                 and (10 - (
                        [0, 2, 4, 6, 8, 1, 3, 5, 7, 9][try_cast(c.cod_agrupacion[1] as integer) + 1]
                      + [0, 3, 8, 2, 7, 4, 1, 5, 9, 6][try_cast(c.cod_agrupacion[2] as integer) + 1]
                      + try_cast(c.cod_agrupacion[3] as integer)
                      + [0, 2, 4, 6, 8, 1, 3, 5, 7, 9][try_cast(c.cod_agrupacion[4] as integer) + 1]
                      + [0, 3, 8, 2, 7, 4, 1, 5, 9, 6][try_cast(c.cod_agrupacion[5] as integer) + 1]
                    ) % 10) % 10 = try_cast(c.cod_agrupacion[6] as integer)
                 and left(c.cod_agrupacion, 5) in (select cod_mun from municipios_ine)
                then 'Ayuntamiento'
        end as tipo_entidad,
        case
            when c.tipo_admon = 'A' then 'C' || c.cod_agrupacion
            when c.cod_agrupacion like '__0000' and upper(c.nodo) like 'DIPUTACI%' then 'D' || left(c.cod_agrupacion, 2)
            when c.cod_agrupacion = '355010' then 'I35002'  -- Fuerteventura (DIR3 L03350002)
            when c.cod_agrupacion = '355020' then 'I35004'  -- Gran Canaria   (L03350004)
            when c.cod_agrupacion = '355030' then 'I35007'  -- Lanzarote      (L03350007)
            when c.cod_agrupacion = '385010' then 'I38003'  -- La Gomera      (L03380003)
            when c.cod_agrupacion = '385020' then 'I38005'  -- El Hierro      (L03380005)
            when c.cod_agrupacion = '385030' then 'I38010'  -- La Palma       (L03380010)
            when c.cod_agrupacion = '385040' then 'I38011'  -- Tenerife       (L03380011)
            when c.cod_agrupacion = '075010' then 'I07006'  -- Eivissa        (L03070006)
            when c.cod_agrupacion = '075020' then 'I07008'  -- Mallorca       (L03070008)
            when c.cod_agrupacion = '075030' then 'I07009'  -- Menorca        (L03070009)
            else left(c.cod_agrupacion, 5)
        end as cod_entidad_tmp
    from conc_cod c
),

-- histograma de días por entidad y año, para la mediana exacta
dias as (
    select
        e.cod_entidad_tmp as cod_entidad, e.anio,
        cast(split_part(x, ':', 1) as integer) as dias,
        sum(cast(split_part(x, ':', 2) as integer)) as n
    from conc_ent e, unnest(string_split(e.dias_hist, ';')) as t(x)
    where e.que = 'concesiones' and e.tipo_entidad is not null and not e.ambiguo and x <> ''
    group by all
),

dias_acum as (
    select *,
        sum(n) over (partition by cod_entidad, anio order by dias rows between unbounded preceding and current row) as hasta,
        sum(n) over (partition by cod_entidad, anio) as total
    from dias
),

mediana as (
    -- media de los valores en las posiciones floor((N+1)/2) y floor(N/2)+1
    select cod_entidad, anio,
        (min(dias) filter (where hasta >= (total + 1) // 2)
         + min(dias) filter (where hasta >= total // 2 + 1)) / 2.0 as mediana_dias,
        min(dias) filter (where hasta >= ceil(total * 0.9)) as p90_dias
    from dias_acum
    group by all
),

medido as (
    select
        cod_entidad_tmp as cod_entidad, anio,
        any_value(tipo_entidad) as tipo_entidad,
        sum(n) as n_total,
        sum(n_fuera_plazo) as n_fuera_plazo,
        sum(n_persona_fisica) as n_persona_fisica,
        sum(n_sin_fecha_alta) as n_sin_fecha_alta,
        sum(importe) as importe,
        count(distinct nivel3) as n_organos
    from conc_ent
    where que = 'concesiones' and tipo_entidad is not null and not ambiguo
    group by all
),

convocatorias as (
    select cod_entidad_tmp as cod_entidad, anio, sum(n_convocatorias) as n_convocatorias
    from conc_ent
    where que = 'convocatorias' and tipo_entidad is not null and not ambiguo
    group by all
),

anios as (
    select m.tipo_admon, m.anio, m.anio_medicion, f.fecha_medicion
    from medicion m
    join fecha_medicion f using (tipo_admon, anio)
),

poblacion as (
    select anio, cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

anio_pob as (
    select a.*, least(a.anio, (select max(anio) from poblacion)) as anio_padron from anios a
),

provincias as (
    select cod_prov, cod_ccaa, nombre from {{ ref('territorios_provincias') }}
),

ccaa(cod_ccaa, nombre) as (
    values ('01', 'Andalucía'), ('02', 'Aragón'), ('03', 'Principado de Asturias'), ('04', 'Illes Balears'),
        ('05', 'Canarias'), ('06', 'Cantabria'), ('07', 'Castilla y León'), ('08', 'Castilla-La Mancha'),
        ('09', 'Cataluña'), ('10', 'Comunitat Valenciana'), ('11', 'Extremadura'), ('12', 'Galicia'),
        ('13', 'Comunidad de Madrid'), ('14', 'Región de Murcia'), ('15', 'Comunidad Foral de Navarra'),
        ('16', 'País Vasco'), ('17', 'La Rioja'), ('18', 'Ciudad Autónoma de Ceuta'), ('19', 'Ciudad Autónoma de Melilla')
),

islas(cod_entidad, nombre, cod_prov, aplica, motivo) as (
    values ('I35002', 'Cabildo Insular de Fuerteventura', '35', true, null),
        ('I35004', 'Cabildo Insular de Gran Canaria', '35', true, null),
        ('I35007', 'Cabildo Insular de Lanzarote', '35', true, null),
        ('I38003', 'Cabildo Insular de La Gomera', '38', true, null),
        ('I38005', 'Cabildo Insular de El Hierro', '38', true, null),
        ('I38010', 'Cabildo Insular de La Palma', '38', true, null),
        ('I38011', 'Cabildo Insular de Tenerife', '38', true, null),
        ('I07006', 'Consell Insular d''Eivissa', '07', true, null),
        ('I07008', 'Consell Insular de Mallorca', '07', true, null),
        ('I07009', 'Consell Insular de Menorca', '07', true, null),
        ('I07001', 'Consell Insular de Formentera', '07', false,
         'El Consell de Formentera es también su ayuntamiento: la BDNS lo registra como Ayuntamiento de Formentera y se mide como ayuntamiento (07024)')
),

universo as (
    -- ayuntamientos
    select 'Ayuntamiento' as tipo_entidad, p.cod_mun as cod_entidad, p.municipio as nombre_entidad,
        p.cod_mun, p.cod_prov, p.cod_ccaa, a.anio, a.anio_medicion, a.fecha_medicion,
        p.poblacion, true as aplica_indicador, cast(null as varchar) as motivo_no_aplica
    from anio_pob a
    join poblacion p on p.anio = a.anio_padron
    where a.tipo_admon = 'L' and p.cod_prov not in ('51', '52')

    union all
    -- diputaciones: provincias de comunidades pluriprovinciales, sin Canarias ni Baleares
    select 'Diputación provincial', 'D' || pr.cod_prov,
        case when pr.cod_prov = '01' then 'Diputación Foral de Álava'
             when pr.cod_prov = '20' then 'Diputación Foral de Gipuzkoa'
             when pr.cod_prov = '48' then 'Diputación Foral de Bizkaia'
             when pr.cod_prov = '08' then 'Diputació de Barcelona'
             else 'Diputación Provincial de ' || pr.nombre end,
        null, pr.cod_prov, pr.cod_ccaa, a.anio, a.anio_medicion, a.fecha_medicion,
        (select sum(poblacion) from poblacion q where q.anio = a.anio_padron and q.cod_prov = pr.cod_prov),
        -- Álava y Gipuzkoa: ninguna concesión de la diputación foral en la BDNS (Gipuzkoa, 17 en
        -- 2022 y 30 en 2023), mientras Bizkaia registra cientos de miles: la fuente no mide su
        -- actividad subvencional, que se publica por el cauce foral. Comprobado el 2026-10-25.
        pr.cod_prov not in ('01', '20'),
        case when pr.cod_prov in ('01', '20') then
            'Régimen foral: la diputación foral no registra sus concesiones en la BDNS (ninguna o casi ninguna en 2022-2026); la BDNS no mide su actividad subvencional'
        end
    from anio_pob a
    cross join provincias pr
    where a.tipo_admon = 'L'
      and pr.cod_prov not in ('07', '26', '28', '30', '31', '33', '35', '38', '39', '51', '52')

    union all
    select 'Cabildo o consell insular', i.cod_entidad, i.nombre, null, i.cod_prov,
        case i.cod_prov when '07' then '04' else '05' end, a.anio, a.anio_medicion, a.fecha_medicion,
        null, i.aplica, i.motivo
    from anio_pob a
    cross join islas i
    where a.tipo_admon = 'L'

    union all
    select 'Comunidad autónoma', 'C' || c.cod_ccaa, c.nombre, null,
        case c.cod_ccaa when '18' then '51' when '19' then '52' end, c.cod_ccaa,
        a.anio, a.anio_medicion, a.fecha_medicion,
        (select sum(poblacion) from poblacion q where q.anio = a.anio_padron and q.cod_ccaa = c.cod_ccaa),
        -- País Vasco: cobertura parcial. En 2025 constan 5.770 concesiones (2,6 por 1.000
        -- habitantes y 41 € por habitante), frente a 12-496 por 1.000 y 270-1.160 € en las
        -- demás comunidades; Navarra sí registra con normalidad. Comprobado el 2026-10-25.
        c.cod_ccaa <> '16',
        case when c.cod_ccaa = '16' then
            'Cobertura parcial: el Gobierno Vasco registra en la BDNS muy pocas de sus concesiones (2,6 por 1.000 habitantes en 2025, frente a 12 o más en el resto); la BDNS no mide su actividad subvencional'
        end
    from anio_pob a
    cross join ccaa c
    where a.tipo_admon = 'A'
),

final as (
    select
        'bdns_concesiones' as obligacion,
        'Subvenciones registradas en la BDNS a tiempo' as obligacion_nombre,
        'art. 5.2.b RD 130/2019; art. 20 Ley 38/2003 General de Subvenciones' as base_legal,
        u.tipo_entidad,
        u.cod_entidad,
        u.nombre_entidad,
        u.cod_mun,
        u.cod_prov,
        u.cod_ccaa,
        cast(u.anio as varchar) as periodo,
        cast(u.anio as integer) as anio,
        make_date(u.anio + 1, 1, 31) as fecha_plazo,
        case
            when not u.aplica_indicador then 'no_aplica'
            when u.fecha_medicion <= make_date(u.anio + 1, 1, 31) then 'no_vencido'
            when coalesce(m.n_total, 0) > 0 then 'con_registros'
            else 'sin_registros'
        end as estado,
        cast(null as integer) as dias_retraso,
        cast(case when u.aplica_indicador then coalesce(m.n_total, 0) end as integer) as n_total,
        cast(case when u.aplica_indicador then coalesce(m.n_fuera_plazo, 0) end as integer) as n_fuera_plazo,
        cast(md.mediana_dias as double) as mediana_dias,
        u.aplica_indicador,
        u.motivo_no_aplica,
        cast(u.poblacion as integer) as poblacion,
        'https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones' as url_fuente,
        'bdns_concesiones|' || u.cod_entidad || '|' || u.anio as clave,
        -- extras
        round(100.0 * m.n_fuera_plazo / nullif(m.n_total, 0), 2) as x_pct_fuera_plazo,
        cast(md.p90_dias as integer) as x_p90_dias,
        cast(m.n_persona_fisica as integer) as x_n_persona_fisica,
        cast(m.n_sin_fecha_alta as integer) as x_n_sin_fecha_alta,
        round(m.importe, 2) as x_importe,
        round(m.importe / nullif(u.poblacion, 0), 2) as x_importe_por_habitante,
        cast(m.n_organos as integer) as x_n_organos,
        cast(case when u.aplica_indicador then coalesce(cv.n_convocatorias, 0) end as integer) as x_n_convocatorias,
        cast(u.anio_medicion as integer) as x_anio_medicion,
        u.fecha_medicion as x_fecha_medicion,
        u.anio_medicion > u.anio + 1 as x_medicion_tardia
    from universo u
    left join medido m on m.cod_entidad = u.cod_entidad and m.anio = u.anio
    left join mediana md on md.cod_entidad = u.cod_entidad and md.anio = u.anio
    left join convocatorias cv on cv.cod_entidad = u.cod_entidad and cv.anio = u.anio
)

select * from final
