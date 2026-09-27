select
    cast(anio as integer) as anio,
    cod_mun,
    municipio,
    sexo,
    cast(poblacion as bigint) as poblacion
from {{ source('raw_territorios', 'ine_poblacion_municipios') }}
where poblacion is not null
