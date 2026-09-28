-- Parque de vehículos en España por mes, grupo y energía (DGT). Un punto por
-- cada fichero mensual de parque cargado.
select
    p.mes,
    p.grupo,
    p.energia,
    e.etiqueta as energia_etiqueta,
    e.orden as energia_orden,
    sum(p.vehiculos) as vehiculos
from {{ source('raw_movilidad', 'dgt_parque') }} p
left join {{ ref('movilidad_energias') }} e on e.energia = p.energia
group by all
