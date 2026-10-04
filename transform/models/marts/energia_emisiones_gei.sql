-- Emisiones brutas de GEI por sector (Mt CO2eq), sin LULUCF. Fuente: Eurostat
-- env_air_gge (inventario nacional de España reportado a la CMNUCC).
-- millones_toneladas_co2eq = total del sector; t_co2eq_hab = toneladas por habitante
-- (población media de Eurostat demo_gind, poblacion_paises); cuota_pct = % del total.
-- El mapeo CRF -> sector está documentado en stg_energia_emisiones_gei.
select
    s.anio,
    s.sector,
    round(s.mt_co2eq, 2) as millones_toneladas_co2eq,
    round(s.mt_co2eq * 1e6 / p.poblacion, 3) as t_co2eq_hab,
    round(100 * s.mt_co2eq / s.total_inventario_mt, 2) as cuota_pct
from {{ ref('stg_energia_emisiones_gei') }} as s
left join {{ ref('poblacion_paises') }} as p on p.cod_pais = 'ES' and p.anio = s.anio
