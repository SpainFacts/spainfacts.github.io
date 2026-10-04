-- Alcaldías (n) y población gobernada por familia política en España, cada
-- comunidad y cada provincia (mandato 2023-2027), con su peso en el territorio.
-- La fila nivel = 'pais' es el total de España.
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
    g.nivel,
    g.cod,
    t.nombre,
    g.familia,
    g.siglas_familia,
    g.color,
    g.n,
    g.poblacion,
    round(100.0 * g.n / sum(g.n) over (partition by g.nivel, g.cod), 2) as pct_ayuntamientos,
    round(100.0 * g.poblacion / nullif(sum(g.poblacion) over (partition by g.nivel, g.cod), 0), 2) as pct_poblacion,
    g.nivel || '-' || g.cod || '-' || g.familia as clave
from agregado g
left join {{ ref('territorios') }} t on t.nivel = g.nivel and t.cod = g.cod
order by g.nivel, g.cod, g.n desc
