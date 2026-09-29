-- Emisiones de GEI de España por año desde 1990, por habitante y por euro de PIB real.
-- Fuentes:
--   - Eurostat env_air_gge (inventario nacional del MITECO reportado a la CMNUCC):
--     total sin LULUCF ni partidas memo (TOTX4_MEMO) y LULUCF (CRF4), Mt CO2eq.
--   - Avance del inventario del MITECO (seed clima_avance_gei) para los años que aún no
--     publica Eurostat: provisional = true.
--   - Población media anual: Eurostat demo_gind (AVG).
--   - PIB real por habitante: mart economia_pib_per_capita (real_eur, euros del último
--     año completo), desde 1995.
-- Cálculos:
--   t_hab        = total_mt x 1e6 / población (t CO2eq por habitante)
--   kg_por_euro  = total_mt x 1e9 / (población x PIB real por habitante) = kg CO2eq por
--                  euro de PIB real
--   var_1990_pct / var_2005_pct = variación del total frente a 1990 (año base de la
--                  CMNUCC y de la Ley Europea del Clima) y 2005 (año base de los
--                  objetivos europeos de reparto de esfuerzos y del RCDE)
--   t_hab_ue     = media de la UE-27 (env_air_gge + demo_gind), solo años definitivos
with crf as (
    select
        cast(anio as integer) as anio,
        max(case when src_crf = 'TOTX4_MEMO' then mt_co2eq end) as total_mt,
        max(case when src_crf = 'CRF4' then mt_co2eq end) as lulucf_mt
    from {{ source('raw_clima', 'eurostat_clima_gei') }}
    group by 1
    having max(case when src_crf = 'TOTX4_MEMO' then mt_co2eq end) > 0
),

avance as (
    select
        cast(anio as integer) as anio,
        max(case when sector = 'TOTAL' then kt_co2eq end) / 1000 as total_mt,
        max(case when sector = 'LULUCF' then kt_co2eq end) / 1000 as lulucf_mt
    from {{ ref('clima_avance_gei') }}
    where cast(anio as integer) > (select max(anio) from crf)
    group by 1
),

serie as (
    select anio, total_mt, lulucf_mt, false as provisional, 'Eurostat env_air_gge' as fuente from crf
    union all
    select anio, total_mt, lulucf_mt, true as provisional, 'MITECO, avance del inventario' as fuente from avance
),

pob as (
    select cast(anio as integer) as anio, geo, poblacion_media
    from {{ source('raw_clima', 'eurostat_clima_poblacion') }}
    where poblacion_media is not null
),

ue as (
    select cast(g.anio as integer) as anio, 1e6 * g.mt_co2eq / p.poblacion_media as t_hab_ue
    from {{ source('raw_clima', 'eurostat_clima_gei_paises') }} g
    join pob p on p.anio = g.anio and p.geo = g.geo
    where g.geo = 'EU27_2020' and g.mt_co2eq > 0
),

pib as (
    select cast(anio as integer) as anio, real_eur
    from {{ ref('economia_pib_per_capita') }}
    where pais = 'ES' and real_eur is not null
),

base as (
    select total_mt as mt_1990 from serie where anio = 1990
),

base05 as (
    select total_mt as mt_2005 from serie where anio = 2005
)

select
    s.anio,
    s.provisional,
    s.fuente,
    round(s.total_mt, 3) as total_mt,
    round(s.lulucf_mt, 3) as lulucf_mt,
    round(s.total_mt + s.lulucf_mt, 3) as netas_mt,
    cast(round(p.poblacion_media) as bigint) as poblacion,
    round(1e6 * s.total_mt / p.poblacion_media, 3) as t_hab,
    round(1e6 * (s.total_mt + s.lulucf_mt) / p.poblacion_media, 3) as t_hab_netas,
    round(u.t_hab_ue, 3) as t_hab_ue,
    round(pib.real_eur, 0) as pib_real_hab,
    round(1e9 * s.total_mt / (p.poblacion_media * pib.real_eur), 4) as kg_por_euro,
    round(100 * (s.total_mt / b.mt_1990 - 1), 2) as var_1990_pct,
    round(100 * (s.total_mt / b5.mt_2005 - 1), 2) as var_2005_pct
from serie s
cross join base b
cross join base05 b5
left join pob p on p.anio = s.anio and p.geo = 'ES'
left join ue u on u.anio = s.anio
left join pib on pib.anio = s.anio
order by s.anio
