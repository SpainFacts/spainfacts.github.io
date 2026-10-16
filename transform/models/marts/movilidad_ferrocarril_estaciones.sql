-- Estaciones con los trenes de viajeros que paran en ellas en un día laborable. Las de Renfe
-- salen en dos horarios (larga y media distancia, y Cercanías) con el mismo código de Adif
-- (con o sin ceros a la izquierda): se juntan.
with crudo as (
    select
        case
            when estacion_id like 'renfe_%' then 'renfe:' || ltrim(split_part(estacion_id, ':', 2), '0')
            else estacion_id
        end as estacion,
        *
    from {{ source('raw_ferrocarril', 'ferrocarril_estaciones') }}
)

select
    estacion,
    arg_max(nombre, trenes_dia) as nombre,
    arg_max(operador, trenes_dia) as operador,
    avg(latitud) as latitud,
    avg(longitud) as longitud,
    sum(trenes_dia) as trenes_dia,
    sum(trenes_cercanias) as trenes_cercanias,
    sum(trenes_media_distancia) as trenes_media_distancia,
    sum(trenes_larga_distancia) as trenes_larga_distancia,
    sum(trenes_autonomico) as trenes_autonomico,
    any_value(fecha_horarios) as fecha_horarios
from crudo
group by estacion
having sum(trenes_dia) > 0
