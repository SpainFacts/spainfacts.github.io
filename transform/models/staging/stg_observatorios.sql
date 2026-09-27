-- Limpieza que antes hacía scripts/clean_observatories_data.py:
--   año de creación = primer año de 4 cifras del texto; si solo hay 2 cifras,
--   <= 24 -> 20xx y el resto 19xx. Activo = "si/sí/yes/true/1".
with base as (
    select
        nombre,
        coalesce(ambito, 'Unknown') as ambito,
        fecha_creacion_texto,
        lower(cast(activo_texto as varchar)) as activo_texto,
        regexp_extract(fecha_creacion_texto, '\b(\d{4})\b', 1) as anio4,
        regexp_extract(fecha_creacion_texto, '\b(\d{2})\b', 1) as anio2
    from {{ source('raw', 'observatorios_publicos') }}
)

select
    nombre,
    ambito,
    case
        when anio4 <> '' then cast(anio4 as integer)
        when anio2 <> '' and cast(anio2 as integer) <= 24 then 2000 + cast(anio2 as integer)
        when anio2 <> '' then 1900 + cast(anio2 as integer)
    end as anio_creacion,
    coalesce(activo_texto in ('si', 'sí', 'yes', 'true', '1'), false) as activo
from base
