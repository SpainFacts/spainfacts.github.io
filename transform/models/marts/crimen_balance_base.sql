{{ config(materialized='ephemeral') }}
-- Filas del Balance de Criminalidad tomadas SOLO del fichero más reciente que
-- trae cada periodo. Cada año completo aparece en dos ficheros (el suyo y el del
-- año siguiente, como comparación) con la tipología escrita distinto
-- ("TOTAL INFRACCIONES PENALES" / "III. TOTAL INFRACCIONES PENALES"): sin este
-- filtro 2019 y 2021 salían contados dos veces.
with rango as (
    select
        *,
        case
            when fichero like 'DatosBalanceAct%' then 99
            else try_cast(regexp_extract(fichero, '/([0-9]+)09012', 1) as integer)
        end as orden_fichero
    from {{ source('raw_criminalidad', 'ses_balance_municipios') }}
)
select * exclude (orden_fichero)
from rango
qualify orden_fichero = max(orden_fichero) over (partition by anio, periodo)
