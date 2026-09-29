-- Emisiones de GEI de España por sector y año desde 1990, en total y por habitante.
-- Fuentes: Eurostat env_air_gge agrupado en sectores divulgativos en
-- stg_energia_emisiones_gei (mapeo CRF -> sector documentado allí) y, para los años que
-- aún no publica Eurostat, el avance del inventario del MITECO (seed clima_avance_gei,
-- mismo mapeo; provisional = true). Población media anual: Eurostat demo_gind (AVG).
--   kg_hab   = kg CO2eq por habitante
--   pct_total = peso del sector sobre el total sin LULUCF
with inv as (
    select cast(anio as integer) as anio, sector, mt_co2eq, false as provisional
    from {{ ref('stg_energia_emisiones_gei') }}
),

avance as (
    select cast(anio as integer) as anio, sector, kt_co2eq / 1000 as mt_co2eq, true as provisional
    from {{ ref('clima_avance_gei') }}
    where sector not in ('TOTAL', 'LULUCF')
      and cast(anio as integer) > (select max(anio) from inv)
),

serie as (
    select * from inv
    union all
    select * from avance
),

pob as (
    select cast(anio as integer) as anio, poblacion_media
    from {{ source('raw_clima', 'eurostat_clima_poblacion') }}
    where geo = 'ES' and poblacion_media is not null
)

select
    s.anio,
    s.sector,
    s.provisional,
    round(s.mt_co2eq, 3) as mt_co2eq,
    round(1e9 * s.mt_co2eq / p.poblacion_media, 1) as kg_hab,
    round(100 * s.mt_co2eq / sum(s.mt_co2eq) over (partition by s.anio), 2) as pct_total
from serie s
left join pob p on p.anio = s.anio
order by s.anio, s.sector
