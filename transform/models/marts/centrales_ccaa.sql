-- Potencia por comunidad autónoma, tecnología y grupo de estado.
select
    u.cod_ccaa,
    u.ccaa,
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
where u.cod_ccaa is not null
group by all
order by cod_ccaa, orden_estado, orden_tecnologia
