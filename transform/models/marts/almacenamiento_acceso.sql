-- Capacidad de acceso a la red de transporte concedida y en tramitación para
-- instalaciones de almacenamiento (baterías, bombeo...), por comunidad y
-- fichero mensual de REE. Es un permiso para conectarse, no una instalación
-- construida: muchos proyectos no llegan a hacerse.
select
    a.fecha_fichero,
    c.cod_ccaa,
    coalesce(c.nombre, a.ccaa) as comunidad,
    count(*) filter (where a.otorgada_mw > 0 or a.en_tramitacion_mw > 0) as nudos,
    sum(a.otorgada_mw) as otorgada_mw,
    sum(a.en_tramitacion_mw) as en_tramitacion_mw
from {{ source('raw_almacenamiento', 'ree_acceso_almacenamiento') }} a
left join {{ ref('territorios_ccaa') }} c
  on c.nombre = case a.ccaa when 'Islas Baleares' then 'Illes Balears' when 'Islas Canarias' then 'Canarias' else a.ccaa end
group by all
