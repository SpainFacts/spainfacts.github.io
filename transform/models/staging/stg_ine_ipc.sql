select
    cod_serie,
    serie,
    epoch_ms(fecha) as date,
    anyo as year,
    valor as value
from {{ source('raw', 'ine_ipc') }}
where valor is not null
