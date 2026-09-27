-- Resumen anual del sistema eléctrico nacional (REE), solo años completos.
-- Mismas columnas que el antiguo CSV clima_energia.resumen_anual_mix.
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
    g.anio as "año",
    round(g.total_twh, 2) as total_twh,
    round(g.renovable_twh, 2) as renovable_twh,
    round(g.total_twh - g.renovable_twh, 2) as no_renovable_twh,
    round(100 * g.renovable_twh / g.total_twh, 2) as cuota_renovable_pct,
    round(100 * (g.renovable_twh + g.nuclear_twh) / g.total_twh, 2) as cuota_libre_emisiones_pct,
    round(d.demanda_twh, 2) as demanda_twh
from gen as g
left join {{ ref('stg_energia_demanda') }} as d
    on d.anio = g.anio and not d.provisional
