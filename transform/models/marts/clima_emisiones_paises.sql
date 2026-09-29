-- Emisiones de GEI por habitante: España frente a la UE-27 y grandes países europeos.
-- Fuentes: Eurostat env_air_gge (TOTX4_MEMO: total sin LULUCF ni partidas memo,
-- inventarios nacionales reportados a la CMNUCC) y Eurostat demo_gind (población
-- media anual, AVG). Solo datos definitivos (sin avances nacionales).
--   t_hab        = t CO2eq por habitante
--   var_1990_pct = variación de las emisiones totales del país frente a 1990
-- demo_gind da para Alemania en 1990 solo la población de la antigua RFA (63 millones
-- frente a 80 en 1991): se descartan las poblaciones que difieren más de un 10 % de la
-- del año siguiente (t_hab queda nulo ese año).
with g as (
    select cast(anio as integer) as anio, geo, mt_co2eq
    from {{ source('raw_clima', 'eurostat_clima_gei_paises') }}
    where mt_co2eq > 0
),

p0 as (
    select
        cast(anio as integer) as anio,
        geo,
        poblacion_media,
        lead(poblacion_media) over (partition by geo order by anio) as pob_siguiente
    from {{ source('raw_clima', 'eurostat_clima_poblacion') }}
    where poblacion_media is not null
),

p as (
    select anio, geo, poblacion_media
    from p0
    where pob_siguiente is null or abs(poblacion_media / pob_siguiente - 1) <= 0.10
),

nombres as (
    select * from (values
        ('ES', 'España'), ('EU27_2020', 'UE-27'), ('DE', 'Alemania'), ('FR', 'Francia'),
        ('IT', 'Italia'), ('PT', 'Portugal'), ('PL', 'Polonia'), ('NL', 'Países Bajos')
    ) as t (geo, nombre)
)

select
    g.anio,
    g.geo,
    n.nombre,
    round(g.mt_co2eq, 3) as mt_co2eq,
    cast(round(p.poblacion_media) as bigint) as poblacion,
    round(1e6 * g.mt_co2eq / p.poblacion_media, 3) as t_hab,
    round(100 * (g.mt_co2eq / first_value(g.mt_co2eq) over (partition by g.geo order by g.anio) - 1), 2) as var_1990_pct
from g
left join p on p.anio = g.anio and p.geo = g.geo
join nombres n on n.geo = g.geo
order by g.anio, g.geo
