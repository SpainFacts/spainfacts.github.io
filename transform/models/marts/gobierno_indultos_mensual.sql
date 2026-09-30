-- Reales decretos de indulto por mes de aprobación (BOE, desde julio de 1977),
-- con el presidente en ejercicio a mitad de mes.
with meses as (
    select date_trunc('month', fecha_disposicion) as mes, count(*) as indultos
    from {{ ref('stg_boe_actos_gobierno') }}
    where tipo = 'indulto'
    group by 1
)

select
    m.mes,
    cast(year(m.mes) as integer) as anio,
    m.indultos,
    p.presidente,
    p.familia
from meses m
left join {{ ref('stg_presidencias_gobierno') }} p
    on m.mes + interval 14 day >= p.desde
    and m.mes + interval 14 day < coalesce(p.hasta, current_date + 1)
order by m.mes
