-- Potencia instalada a cierre de año por tecnología (MW).
-- Mismas columnas que el antiguo CSV clima_energia.potencia_instalada, más `fuente`.
-- "Otras Tecnologías" = total - tecnologías principales (cogeneración, residuos,
-- biomasa, fuel, bombeo... según la fuente). Ver stg_energia_potencia.
with pot as (
    select * from {{ ref('stg_energia_potencia') }}
),

total as (
    select anio, fuente, potencia_mw as total_mw
    from pot
    where tecnologia = 'TOTAL'
),

principales as (
    select anio, fuente, tecnologia, sum(potencia_mw) as potencia_mw
    from pot
    where tecnologia is not null and tecnologia <> 'TOTAL'
    group by anio, fuente, tecnologia
),

otras as (
    select
        t.anio,
        t.fuente,
        'Otras Tecnologías' as tecnologia,
        t.total_mw - coalesce(sum(p.potencia_mw), 0) as potencia_mw
    from total as t
    left join principales as p on p.anio = t.anio and p.fuente = t.fuente
    group by t.anio, t.fuente, t.total_mw
),

todas as (
    select * from principales
    union all
    select * from otras
)

select
    a.anio as "año",
    a.tecnologia,
    case
        when a.tecnologia in ('Eólica', 'Solar Fotovoltaica', 'Solar Térmica', 'Hidráulica') then 'Renovable'
        when a.tecnologia = 'Otras Tecnologías' then 'Otras'
        else 'No Renovable'
    end as tipo,
    round(a.potencia_mw, 0) as potencia_mw,
    round(100 * a.potencia_mw / t.total_mw, 2) as porcentaje_total,
    a.fuente
from todas as a
inner join total as t on t.anio = a.anio and t.fuente = a.fuente
