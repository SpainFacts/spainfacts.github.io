-- Matriculaciones ordinarias en España por mes, grupo de vehículo, energía y
-- nuevo/usado (DGT, MATRABA). co2_medio: media del CO2 homologado (g/km) de
-- los que lo tienen informado (turismos; NEDC hasta 2018 y WLTP después).
select
    m.mes,
    m.grupo,
    g.etiqueta as grupo_etiqueta,
    m.energia,
    e.etiqueta as energia_etiqueta,
    e.orden as energia_orden,
    e.color as energia_color,
    m.nuevo_usado,
    sum(m.matriculaciones) as matriculaciones,
    sum(m.co2_suma) / nullif(sum(m.co2_n), 0) as co2_medio
from {{ source('raw_movilidad', 'dgt_matriculaciones') }} m
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
left join {{ ref('movilidad_grupos') }} g on g.grupo = m.grupo
group by all
