-- Una fila por año y grupo en medios_sector_grupos (seed transcrito a mano: evita filas duplicadas).
select anio, grupo, count(*) as n
from {{ ref('medios_sector_grupos') }}
group by anio, grupo
having count(*) > 1
