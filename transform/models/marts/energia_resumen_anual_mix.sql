-- Resumen anual del sistema eléctrico nacional (REE), solo años completos.
-- generacion_kwh_hab y demanda_kwh_hab: kWh por habitante (población de España, poblacion_territorios).
--   cuota_libre_emisiones_pct = (renovable + nuclear) / total
--   demanda_twh = demanda nacional en barras de central (REE demanda/evolucion)
with gen as (
    select
        anio,
        max(case when tipo_fuente = 'Total' then generacion_twh end) as total_twh,
        sum(case when tipo_fuente = 'Renovable' then generacion_twh else 0 end) as renovable_twh,
        sum(case when tecnologia_ree = 'Nuclear' then generacion_twh else 0 end) as nuclear_twh
    from {{ ref('stg_energia_generacion') }}
    where not provisional
    group by anio
)

select
    g.anio,
    round(g.total_twh, 2) as total_twh,
    round(g.renovable_twh, 2) as renovable_twh,
    round(g.total_twh - g.renovable_twh, 2) as no_renovable_twh,
    round(100 * g.renovable_twh / g.total_twh, 2) as cuota_renovable_pct,
    round(100 * (g.renovable_twh + g.nuclear_twh) / g.total_twh, 2) as cuota_libre_emisiones_pct,
    round(d.demanda_twh, 2) as demanda_twh,
    round(g.total_twh * 1e9 / p.poblacion, 0) as generacion_kwh_hab,
    round(d.demanda_twh * 1e9 / p.poblacion, 0) as demanda_kwh_hab
from gen as g
left join {{ ref('poblacion_territorios') }} as p
    on p.nivel = 'pais' and p.cod = '00' and p.sexo = 'Total' and p.anio = g.anio
left join {{ ref('stg_energia_demanda') }} as d
    on d.anio = g.anio and not d.provisional
