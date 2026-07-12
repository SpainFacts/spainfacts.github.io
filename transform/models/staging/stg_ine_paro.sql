select
    cod_serie,
    serie,
    cast(epoch_ms(fecha) + interval 12 hour as date) as date,
    anyo as year,
    valor as value
from {{ source('raw', 'ine_paro') }}
where valor is not null
