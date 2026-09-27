-- Emisiones brutas de GEI por sector (Mt CO2eq), sin LULUCF. Fuente: Eurostat
-- env_air_gge (inventario nacional de España reportado a la CMNUCC).
-- Mismas columnas que el antiguo CSV clima_energia.emisiones_gei.
-- El mapeo CRF -> sector está documentado en stg_energia_emisiones_gei.
select
    anio as "año",
    sector,
    round(mt_co2eq, 2) as millones_toneladas_co2eq,
    round(100 * mt_co2eq / total_inventario_mt, 2) as porcentaje_total
from {{ ref('stg_energia_emisiones_gei') }}
