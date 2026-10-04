-- Puntos de recarga públicos en España por día y tramo de potencia (la serie
-- empieza el primer día que se cargó el NAP en SpainFacts). El texto del tramo
-- es el mismo que el de movilidad_recarga_sitios.
select
    fecha,
    year(fecha) as anio,
    upper(left(tramo_potencia, 1)) || substr(tramo_potencia, 2) as tramo_potencia,
    case tramo_potencia
        when 'ultrarrápida (≥150 kW)' then 1
        when 'rápida (50-149 kW)' then 2
        when 'semirrápida (22-49 kW)' then 3
        else 4
    end as tramo_orden,
    sum(puntos) as puntos,
    sum(potencia_kw) as potencia_kw
from {{ source('raw_movilidad', 'recarga_resumen_diario') }}
group by all
