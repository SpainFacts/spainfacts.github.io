-- Una fila por unidad o fase de central eléctrica en España (Global Energy
-- Monitor, GIPT) con todos los campos de presentación.
select *
from {{ ref('stg_gem_centrales') }}
order by orden_estado, potencia_mw desc nulls last
