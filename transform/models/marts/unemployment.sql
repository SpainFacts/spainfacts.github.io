-- Tabla que consume Evidence (sources/mother/unemployment.sql).
-- Todas las series de la tabla 65292 del INE (tasa de paro por sexo y edad).
select
    date,
    value,
    serie,
    cod_serie
from {{ ref('stg_ine_paro') }}
