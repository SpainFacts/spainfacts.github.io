-- Todas las estaciones de AEMET (solo los últimos años), para el lugar más caluroso del día.
select
    fecha,
    indicativo,
    nombre as estacion,
    provincia,
    altitud,
    tmax,
    tmin
from {{ source('raw_aemet', 'aemet_diario_todas') }}
where tmax is not null
