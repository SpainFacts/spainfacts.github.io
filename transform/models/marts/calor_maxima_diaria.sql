-- Lugar más caluroso de España cada día, entre todas las estaciones de AEMET.
select
    fecha,
    indicativo,
    estacion,
    provincia,
    altitud,
    tmax
from {{ ref('stg_aemet_diario_todas') }}
qualify row_number() over (partition by fecha order by tmax desc, indicativo) = 1
