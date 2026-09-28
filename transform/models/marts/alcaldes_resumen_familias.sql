-- Alcaldías y población gobernada por cada familia política (mandato 2023-2027).
-- Población: último padrón (INE 29005) de cada municipio.
with a as (
    select * from {{ ref('alcaldes_actuales') }}
),

agregado as (
    select
        familia,
        any_value(siglas_familia) as siglas_familia,
        any_value(color) as color,
        count(*) as n_ayuntamientos,
        coalesce(sum(poblacion), 0) as poblacion_gobernada
    from a
    group by familia
)

select
    familia,
    siglas_familia,
    color,
    n_ayuntamientos,
    poblacion_gobernada,
    round(100.0 * n_ayuntamientos / sum(n_ayuntamientos) over (), 2) as pct_ayuntamientos,
    round(100.0 * poblacion_gobernada / sum(poblacion_gobernada) over (), 2) as pct_poblacion
from agregado
order by n_ayuntamientos desc
