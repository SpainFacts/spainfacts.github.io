-- Reparto de la superficie agraria de cada municipio por textura del USDA, grupo de suelo WRB y
-- banda de pH, con las celdas de 250 m (muestras de CORINE 2018 dentro del término y suelo de
-- SoilGrids en la misma celda). pct = % de la superficie agraria con dato de esa dimensión.
select
    cod_mun,
    dimension,
    clase,
    orden,
    superficie_km2,
    100.0 * superficie_km2 / nullif(sum(superficie_km2) over (partition by cod_mun, dimension), 0) as pct
from {{ source('raw_suelos', 'suelos_municipio_clases') }}
order by cod_mun, dimension, orden
