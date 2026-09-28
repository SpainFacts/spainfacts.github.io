-- Potencia y número de unidades y centrales por tecnología y grupo de estado.
select
    u.tecnologia,
    t.color,
    t.orden as orden_tecnologia,
    t.renovable,
    u.estado_grupo,
    min(u.orden_estado) as orden_estado,
    round(sum(u.potencia_mw), 1) as potencia_mw,
    count(*) as n_unidades,
    count(distinct u.id_central) as n_centrales
from {{ ref('stg_gem_centrales') }} u
left join {{ ref('tecnologias_electricas') }} t on t.tecnologia = u.tecnologia
group by all
order by orden_estado, orden_tecnologia
