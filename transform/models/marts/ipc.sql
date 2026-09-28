-- Tabla que consume Evidence (sources/mother/ipc.sql -> SELECT * FROM ipc).
-- Contiene TODAS las series de la tabla 76125 del INE (IPC base 2025) con columnas date/value;
-- las páginas deben filtrar por `serie` o `cod_serie` (p. ej. el índice general).
select
    date,
    value,
    serie,
    cod_serie
from {{ ref('stg_ine_ipc') }}
