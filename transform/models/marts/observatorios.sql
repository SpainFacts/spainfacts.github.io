-- Mismas columnas que la tabla que cargaba el script antiguo: las consultas de
-- pages/varios/observatorios.md no cambian.
select
    nombre as name,
    anio_creacion as creation_year,
    activo as is_active,
    ambito as scope
from {{ ref('stg_observatorios') }}
