-- Cada indicador una sola vez por ámbito en el catálogo internacional
select ambito, indicador_id, count(*) as n
from {{ ref('internacional_indicadores') }}
group by all
having count(*) > 1
