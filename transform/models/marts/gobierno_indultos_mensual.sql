-- Reales decretos de indulto por mes de aprobación (BOE, desde julio de 1977),
-- con el presidente en ejercicio a mitad de mes. Sin los decretos anteriores a 1977 (fechas
-- erróneas en el BOE). Los meses sin indulto no tienen fila; es_parcial = mes en curso.
with meses as (
    select date_trunc('month', fecha_disposicion) as mes, count(*) as indultos
    from {{ ref('stg_boe_actos_gobierno') }}
    where tipo = 'indulto' and fecha_disposicion >= date '1977-07-01'
    group by 1
)

select
    m.mes as fecha,
    cast(year(m.mes) as integer) as anio,
    m.indultos,
    p.presidente,
    p.familia,
    m.mes = date_trunc('month', current_date) as es_parcial
from meses m
left join {{ ref('stg_presidencias_gobierno') }} p
    on m.mes + interval 14 day >= p.desde
    and m.mes + interval 14 day < coalesce(p.hasta, current_date + 1)
order by m.mes
