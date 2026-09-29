-- Generación anual por tecnología REE (una fila por año y tecnología original de REE).
-- Desde 2007 (primer año de REData): lee raw.clima_ree_generacion (ingestion/clima.py),
-- idéntica a raw.ree_estructura_generacion (ingestion/ree.py) en los años que comparten.
select
    anio,
    tecnologia as tecnologia_ree,
    case when tipo = 'Renovable' then 'Renovable'
         when tipo = 'No-Renovable' then 'No Renovable'
         else 'Total' end as tipo_fuente,
    valor / 1e6 as generacion_twh,
    provisional
from {{ source('raw_clima', 'clima_ree_generacion') }}
where valor is not null
