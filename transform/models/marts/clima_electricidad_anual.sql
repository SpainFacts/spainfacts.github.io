-- Sistema eléctrico nacional por año desde 2007 (primer año de la API REData de REE),
-- solo años completos: cuotas del mix, intensidad de emisiones y demanda por habitante.
-- Fuentes:
--   - REE REData generacion/estructura-generacion (stg_energia_generacion) y
--     demanda/evolucion (stg_energia_demanda), ingestion/clima.py.
--   - REE generacion/no-renovables-detalle-emisiones-CO2: tCO2eq de la generación no
--     renovable ('Total tCO2 eq.'). REE asigna emisiones solo a las centrales
--     térmicas (carbón, ciclo combinado, cogeneración, motores, turbinas, residuos
--     no renovables); la biomasa y el resto de renovables y la nuclear cuentan 0.
--   - Población media anual: Eurostat demo_gind (AVG).
-- Cálculos:
--   g_co2_kwh         = tCO2eq totales / generación total (MWh) x 1.000 (gCO2eq por kWh generado)
--   cuota_*_pct       = generación de la tecnología / generación total
--   demanda_kwh_hab   = demanda nacional en barras de central / población media
--   emisiones_t_hab   = t CO2eq de la generación eléctrica por habitante (REE)
with gen as (
    select
        anio,
        max(case when tipo_fuente = 'Total' then generacion_twh end) as total_twh,
        sum(case when tipo_fuente = 'Renovable' then generacion_twh else 0 end) as renovable_twh,
        sum(case when tecnologia_ree = 'Nuclear' then generacion_twh else 0 end) as nuclear_twh,
        sum(case when tecnologia_ree = 'Carbón' then generacion_twh else 0 end) as carbon_twh,
        sum(case when tecnologia_ree = 'Ciclo combinado' then generacion_twh else 0 end) as ciclo_twh,
        sum(case when tecnologia_ree = 'Eólica' then generacion_twh else 0 end) as eolica_twh,
        sum(case when tecnologia_ree = 'Solar fotovoltaica' then generacion_twh else 0 end) as solar_fv_twh
    from {{ ref('stg_energia_generacion') }}
    where not provisional
    group by anio
),

co2 as (
    select cast(anio as integer) as anio, valor as t_co2eq
    from {{ source('raw_clima', 'clima_ree_emisiones_co2') }}
    where tecnologia = 'Total tCO2 eq.' and not provisional
),

pob as (
    select cast(anio as integer) as anio, poblacion_media
    from {{ source('raw_clima', 'eurostat_clima_poblacion') }}
    where geo = 'ES' and poblacion_media is not null
)

select
    cast(g.anio as integer) as anio,
    round(g.total_twh, 2) as generacion_twh,
    round(d.demanda_twh, 2) as demanda_twh,
    round(100 * g.renovable_twh / g.total_twh, 2) as cuota_renovable_pct,
    round(100 * (g.renovable_twh + g.nuclear_twh) / g.total_twh, 2) as cuota_libre_emisiones_pct,
    round(100 * g.eolica_twh / g.total_twh, 2) as cuota_eolica_pct,
    round(100 * g.solar_fv_twh / g.total_twh, 2) as cuota_solar_fv_pct,
    round(100 * g.nuclear_twh / g.total_twh, 2) as cuota_nuclear_pct,
    round(100 * g.ciclo_twh / g.total_twh, 2) as cuota_ciclo_pct,
    round(100 * g.carbon_twh / g.total_twh, 2) as cuota_carbon_pct,
    round(c.t_co2eq / 1e6, 3) as emisiones_mt,
    round(1000 * c.t_co2eq / (g.total_twh * 1e6), 1) as g_co2_kwh,
    round(1e9 * d.demanda_twh / p.poblacion_media, 0) as demanda_kwh_hab,
    round(c.t_co2eq / p.poblacion_media, 3) as emisiones_t_hab
from gen g
left join {{ ref('stg_energia_demanda') }} d on d.anio = g.anio and not d.provisional
left join co2 c on c.anio = g.anio
left join pob p on p.anio = g.anio
order by g.anio
