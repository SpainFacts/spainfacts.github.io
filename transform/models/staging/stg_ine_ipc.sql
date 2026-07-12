select
    cod_serie,
    serie,
    -- el epoch del INE es medianoche de Madrid (23:00 UTC del día anterior);
    -- +12h y cast a date recupera el día natural correcto
    cast(epoch_ms(fecha) + interval 12 hour as date) as date,
    anyo as year,
    valor as value
from {{ source('raw', 'ine_ipc') }}
where valor is not null
