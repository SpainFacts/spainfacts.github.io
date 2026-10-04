{{ config(materialized='ephemeral') }}
-- Deflactor de los marts construccion_*: hoy es main.deflactor, que ya llega a 1996 enlazando
-- el IPCA de Eurostat. Se mantiene el nombre para no tocar esos marts.
select cast(anio as integer) as anio, factor, anio_base, origen from {{ ref('deflactor') }}
