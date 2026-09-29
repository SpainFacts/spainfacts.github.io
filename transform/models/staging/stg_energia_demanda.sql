-- Demanda eléctrica anual nacional (REE), en TWh.
-- Desde 2007: lee raw.clima_ree_demanda (ingestion/clima.py), misma consulta que ree_demanda.
select
    anio,
    valor / 1e6 as demanda_twh,
    provisional
from {{ source('raw_clima', 'clima_ree_demanda') }}
where valor is not null
