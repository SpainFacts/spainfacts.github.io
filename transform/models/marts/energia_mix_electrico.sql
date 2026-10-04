-- Generación eléctrica anual nacional por tecnología (REE), solo años completos.
-- generacion_kwh_hab = kWh por habitante (población de España, poblacion_territorios);
-- cuota_pct = % del total de la generación del año.
-- Agrupación de tecnologías REE -> etiquetas de la web:
--   Hidráulica -> Hidroeléctrica; Ciclo combinado -> Ciclos Combinados (Gas);
--   Cogeneración + Residuos no renovables -> Cogeneración y Residuos;
--   Otras renovables + Residuos renovables + Hidroeólica -> Otras Renovables;
--   Motores diésel + Turbina de gas + Turbina de vapor + Fuel + Gas (sistemas no
--   peninsulares) -> Motores, Turbinas y Fuel; cualquier otra -> Otras Renovables /
--   Otras No Renovables según su tipo.
with gen as (
    select
        anio,
        case tecnologia_ree
            when 'Eólica' then 'Eólica'
            when 'Solar fotovoltaica' then 'Solar Fotovoltaica'
            when 'Solar térmica' then 'Solar Térmica'
            when 'Hidráulica' then 'Hidroeléctrica'
            when 'Nuclear' then 'Nuclear'
            when 'Carbón' then 'Carbón'
            when 'Ciclo combinado' then 'Ciclos Combinados (Gas)'
            when 'Cogeneración' then 'Cogeneración y Residuos'
            when 'Residuos no renovables' then 'Cogeneración y Residuos'
            when 'Motores diésel' then 'Motores, Turbinas y Fuel'
            when 'Turbina de gas' then 'Motores, Turbinas y Fuel'
            when 'Turbina de vapor' then 'Motores, Turbinas y Fuel'
            when 'Fuel + Gas' then 'Motores, Turbinas y Fuel'
            else case when tipo_fuente = 'Renovable' then 'Otras Renovables' else 'Otras No Renovables' end
        end as tecnologia,
        tipo_fuente,
        generacion_twh
    from {{ ref('stg_energia_generacion') }}
    where not provisional and tipo_fuente <> 'Total'
),

total as (
    select anio, generacion_twh as total_twh
    from {{ ref('stg_energia_generacion') }}
    where not provisional and tipo_fuente = 'Total'
)

select
    g.anio,
    g.tecnologia,
    g.tipo_fuente,
    round(sum(g.generacion_twh), 2) as generacion_twh,
    round(sum(g.generacion_twh) * 1e9 / any_value(p.poblacion), 0) as generacion_kwh_hab,
    round(100 * sum(g.generacion_twh) / any_value(t.total_twh), 2) as cuota_pct
from gen as g
inner join total as t on t.anio = g.anio
left join {{ ref('poblacion_territorios') }} as p
    on p.nivel = 'pais' and p.cod = '00' and p.sexo = 'Total' and p.anio = g.anio
group by g.anio, g.tecnologia, g.tipo_fuente
