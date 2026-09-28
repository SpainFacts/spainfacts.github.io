-- Puntos de recarga públicos en España por día y tramo de potencia (la serie
-- empieza el primer día que se cargó el NAP en SpainFacts).
select
    fecha,
    tramo_potencia,
    sum(puntos) as puntos,
    sum(potencia_kw) as potencia_kw
from {{ source('raw_movilidad', 'recarga_resumen_diario') }}
group by all
