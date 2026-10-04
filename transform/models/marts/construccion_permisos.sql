-- Visados de obra por habitante, por año: viviendas de obra nueva (y de ampliación y reforma, desde 2000) y
-- superficie a construir, para España ('pais', '00') desde 1992 y las comunidades ('ccaa', código INE) desde 2000.
-- Una sola fuente por fila (la columna fuente la dice) y España una sola vez:
--   - desde 2000: visados de dirección de obra de los colegios de aparejadores (Ministerio de
--     Transportes, vía ISTAC E20006A_000002, filas anuales); sin Ceuta ni Melilla. Población a 1 de
--     enero (main.poblacion_territorios, desde 1996).
--   - 1992-1999, solo España: Banco de España, Boletín Estadístico 23.8 (suma de 12 meses). Desde 2000
--     es el mismo dato que el del Ministerio; se usa el del Ministerio y de aquí solo se toma la
--     superficie. Población: nama_10_pe (Eurostat).
-- Los permisos de construcción de la UE (Eurostat, otra fuente que no se puede mezclar con los
-- visados) están en construccion_permisos_ue.
-- *_1000hab: por 1.000 habitantes; m2_obra_nueva_hab: metros cuadrados por habitante (solo España).
with vis as (
    select
        m.cod_ccaa as cod,
        m.nombre,
        cast(v.anio as integer) as anio,
        max(v.viviendas) filter (where v.tipo_obra = 'OBRA_NUEVA') as nueva,
        max(v.viviendas) filter (where v.tipo_obra = 'AMPLIACION') as ampliacion,
        max(v.viviendas) filter (where v.tipo_obra = 'REFORMA_RESTAURACION') as reforma
    from {{ source('raw_construccion', 'construccion_visados_ccaa') }} v
    join {{ ref('construccion_nuts') }} m on m.nuts = v.territorio_code
    where v.mes is null
    group by all
),

pob as (
    select nivel, cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

pob_ue as (
    select cast(anio as integer) as anio, pais, miles as poblacion_miles
    from {{ source('raw_construccion', 'eurostat_construccion_poblacion') }}
),

bde as (
    select
        cast(anio as integer) as anio,
        sum(valor) filter (where serie = 'D_1KB52212') as viviendas,
        sum(valor) filter (where serie = 'D_1KB52220') as m2_obra_nueva,
        count(distinct mes) as meses
    from {{ source('raw_construccion', 'construccion_bde_series') }}
    where cuadro = 'be2308' and serie in ('D_1KB52212', 'D_1KB52220')
    group by 1
),

ministerio as (
    select
        case when v.cod = '00' then 'pais' else 'ccaa' end as nivel,
        v.cod,
        v.nombre,
        v.anio,
        v.nueva,
        v.ampliacion,
        v.reforma,
        cast(p.poblacion as double) as poblacion
    from vis v
    asof left join pob p
      on p.nivel = case when v.cod = '00' then 'pais' else 'ccaa' end and p.cod = v.cod and p.anio <= v.anio
),

desde_2000 as (
    select
        m.nivel,
        m.cod,
        m.nombre,
        m.anio,
        m.nueva as viviendas_nueva,
        m.ampliacion as viviendas_ampliacion,
        m.reforma as viviendas_reforma,
        1000.0 * m.nueva / m.poblacion as viviendas_nueva_1000hab,
        1000.0 * m.reforma / m.poblacion as viviendas_reforma_1000hab,
        case when m.cod = '00' then b.m2_obra_nueva / m.poblacion end as m2_obra_nueva_hab,
        m.poblacion,
        'Ministerio de Transportes, visados (ISTAC E20006A_000002)' as fuente
    from ministerio m
    left join bde b on b.anio = m.anio and b.meses = 12
),

antes_2000 as (
    select
        'pais' as nivel,
        '00' as cod,
        'España' as nombre,
        b.anio,
        b.viviendas as viviendas_nueva,
        cast(null as double) as viviendas_ampliacion,
        cast(null as double) as viviendas_reforma,
        b.viviendas / nullif(p.poblacion_miles, 0) as viviendas_nueva_1000hab,
        cast(null as double) as viviendas_reforma_1000hab,
        b.m2_obra_nueva / nullif(p.poblacion_miles * 1000.0, 0) as m2_obra_nueva_hab,
        p.poblacion_miles * 1000.0 as poblacion,
        'Banco de España, Boletín Estadístico 23.8 (visados)' as fuente
    from bde b
    left join pob_ue p on p.pais = 'ES' and p.anio = b.anio
    where b.meses = 12 and b.anio < 2000
)

select * from antes_2000
union all
select * from desde_2000
order by cod, anio
