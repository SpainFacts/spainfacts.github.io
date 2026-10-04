{{ config(materialized='ephemeral') }}
-- Ya no se publica en mother.* (era un duplicado peor de mercado_ipc_grupos y mercado_ipc_ccaa);
-- solo alimenta a mercado_ipc_grupos.
-- Contiene TODAS las series de la tabla 76125 del INE (IPC base 2025) con columnas date/value;
-- las páginas deben filtrar por `serie` o `cod_serie` (p. ej. el índice general).
select
    date,
    value,
    serie,
    cod_serie
from {{ ref('stg_ine_ipc') }}
