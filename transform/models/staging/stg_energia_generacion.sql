-- Generación anual por tecnología REE (una fila por año y tecnología original de REE).
select
    anio,
    tecnologia as tecnologia_ree,
    case when tipo = 'Renovable' then 'Renovable'
         when tipo = 'No-Renovable' then 'No Renovable'
         else 'Total' end as tipo_fuente,
    valor / 1e6 as generacion_twh,
    provisional
from {{ source('raw_energia', 'ree_estructura_generacion') }}
where valor is not null
