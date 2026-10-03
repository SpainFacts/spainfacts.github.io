{{ config(materialized='ephemeral') }}
-- Deflactor anual para los marts construccion_*: main.deflactor (IPC del INE, desde 2002, euros
-- de anio_base) y, para 1996-2001, el mismo factor de 2002 enlazado con el IPCA anual de España de
-- Eurostat (prc_hicp_aind): factor(a) = factor(2002) * IPCA(2002) / IPCA(a).
-- real = nominal * factor. Antes de 1996 no hay deflactor (factor nulo).
with d as (
    select cast(anio as integer) as anio, factor, anio_base from {{ ref('deflactor') }}
),

h as (
    select cast(anio as integer) as anio, indice
    from {{ source('raw_construccion', 'eurostat_construccion_hicp') }}
    where pais = 'ES'
),

enlace as (
    select d.factor * h.indice as k, d.anio_base
    from d join h using (anio)
    where d.anio = 2002
)

select anio, factor, anio_base, 'INE IPC' as origen from d
union all
select h.anio, e.k / h.indice, e.anio_base, 'Eurostat IPCA enlazado' as origen
from h cross join enlace e
where h.anio < 2002
