-- Una fila por central (id_central de GEM) y grupo de estado: las unidades de
-- una misma central pueden estar en estados distintos (p. ej. Aboño: grupos de
-- carbón retirados y ciclo combinado en operación), y cada estado es un punto
-- distinto del mapa. La tecnología es la de más potencia dentro del grupo.
with u as (
    select * from {{ ref('stg_gem_centrales') }}
),

por_tecnologia as (
    select id_central, estado_grupo, tecnologia, sum(coalesce(potencia_mw, 0)) as mw
    from u
    group by all
),

dominante as (
    select id_central, estado_grupo, arg_max(tecnologia, mw) as tecnologia,
           count(*) as n_tecnologias
    from por_tecnologia
    group by all
)

select
    u.id_central || ' · ' || u.estado_grupo as id,
    u.id_central,
    arg_max(u.nombre, coalesce(u.potencia_mw, 0)) as nombre,
    d.tecnologia,
    any_value(t.color) as color,
    any_value(t.orden) as orden_tecnologia,
    any_value(t.renovable) as renovable,
    d.n_tecnologias > 1 as mixta,
    string_agg(distinct u.tecnologia, ', ' order by u.tecnologia) as tecnologias,
    u.estado_grupo,
    min(u.orden_estado) as orden_estado,
    string_agg(distinct u.estado_es, ', ' order by u.estado_es) as estados,
    round(sum(u.potencia_mw), 1) as potencia_mw,
    count(*) as n_unidades,
    min(u.anio_inicio) as anio_inicio_min,
    max(u.anio_inicio) as anio_inicio_max,
    max(u.anio_retiro) as anio_retiro,
    arg_max(u.propietario, coalesce(u.potencia_mw, 0)) as propietario,
    arg_max(u.operador, coalesce(u.potencia_mw, 0)) as operador,
    round(avg(u.lat), 5) as lat,
    round(avg(u.lon), 5) as lon,
    bool_and(u.ubicacion_exacta) as ubicacion_exacta,
    case when bool_and(u.ubicacion_exacta) then 'Exacta' else 'Aproximada' end as precision_ubicacion,
    arg_max(u.municipio, coalesce(u.potencia_mw, 0)) as municipio,
    mode(u.cod_prov) as cod_prov,
    mode(u.provincia) as provincia,
    mode(u.cod_ccaa) as cod_ccaa,
    mode(u.ccaa) as ccaa,
    any_value(u.url_gem) as url_gem
from u
join dominante d on d.id_central = u.id_central and d.estado_grupo = u.estado_grupo
left join {{ ref('tecnologias_electricas') }} t on t.tecnologia = d.tecnologia
group by u.id_central, u.estado_grupo, d.tecnologia, d.n_tecnologias
order by orden_estado, potencia_mw desc nulls last
