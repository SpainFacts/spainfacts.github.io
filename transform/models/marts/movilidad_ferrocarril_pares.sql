-- Trenes de viajeros al día entre cada par de paradas consecutivas (en los dos sentidos), por
-- clase de servicio. Un tren que no para en las intermedias cuenta en el par de sus paradas.
select
    estacion_a,
    estacion_b,
    sum(trenes_dia) as trenes_dia,
    coalesce(sum(trenes_dia) filter (where clase = 'cercanias'), 0) as trenes_cercanias,
    coalesce(sum(trenes_dia) filter (where clase = 'media_distancia'), 0) as trenes_media_distancia,
    coalesce(sum(trenes_dia) filter (where clase = 'larga_distancia'), 0) as trenes_larga_distancia,
    coalesce(sum(trenes_dia) filter (where clase = 'autonomico'), 0) as trenes_autonomico,
    string_agg(distinct operador, ', ' order by operador) as operadores,
    any_value(fecha_horarios) as fecha_horarios
from {{ source('raw_ferrocarril', 'ferrocarril_pares') }}
group by estacion_a, estacion_b
