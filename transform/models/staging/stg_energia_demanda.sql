-- Demanda eléctrica anual nacional (REE), en TWh.
select
    anio,
    valor / 1e6 as demanda_twh,
    provisional
from {{ source('raw_energia', 'ree_demanda') }}
where valor is not null
