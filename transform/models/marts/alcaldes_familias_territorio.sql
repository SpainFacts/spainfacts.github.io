-- Alcaldías (n) y población gobernada por familia política en España, cada
-- comunidad y cada provincia (mandato 2023-2027), con su peso en el territorio.
with a as (
    select * from {{ ref('alcaldes_actuales') }}
),

niveles as (
    select 'pais' as nivel, '00' as cod, familia, siglas_familia, color, poblacion from a
    union all
    select 'ccaa', cod_ccaa, familia, siglas_familia, color, poblacion from a
    union all
    select 'provincia', cod_prov, familia, siglas_familia, color, poblacion from a
),

agregado as (
    select
        nivel,
        cod,
        familia,
        any_value(siglas_familia) as siglas_familia,
        any_value(color) as color,
        count(*) as n,
        coalesce(sum(poblacion), 0) as poblacion
    from niveles
    group by nivel, cod, familia
)

select
    nivel,
    cod,
    familia,
    siglas_familia,
    color,
    n,
    poblacion,
    round(100.0 * n / sum(n) over (partition by nivel, cod), 2) as pct_ayuntamientos,
    round(100.0 * poblacion / nullif(sum(poblacion) over (partition by nivel, cod), 0), 2) as pct_poblacion,
    nivel || '-' || cod || '-' || familia as clave
from agregado
order by nivel, cod, n desc
