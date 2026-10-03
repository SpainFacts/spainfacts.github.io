-- Caseros en el Congreso por grupo parlamentario (XV Legislatura, declaración inicial de
-- Bienes y Rentas de cada diputado en activo; ver diputados_inmuebles_diputados).
-- Una fila por grupo y otra 'Total' (todos los diputados). Los porcentajes se calculan
-- sobre las declaraciones leídas correctamente (n_validos); n_excluidos = no legibles o que
-- remiten a otra declaración. Medianas sobre los válidos. Renta media de alquiler en
-- euros reales de 2025, solo entre los que declaran alquilar.
with d as (
    select * from {{ ref('diputados_inmuebles_diputados') }}
),

grupos as (
    select grupo, grupo_parlamentario, d.* exclude (grupo, grupo_parlamentario) from d
    union all
    select 'Total' as grupo, 'Todos los diputados en activo' as grupo_parlamentario,
           d.* exclude (grupo, grupo_parlamentario) from d
)

select
    grupo,
    any_value(grupo_parlamentario) as grupo_parlamentario,
    count(*) as n_diputados,
    count(*) filter (where extraccion_ok) as n_validos,
    count(*) filter (where not extraccion_ok) as n_excluidos,
    count(*) filter (where alquila) as n_alquila,
    round(100.0 * count(*) filter (where alquila) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_alquila,
    count(*) filter (where dos_urbanos) as n_dos_urbanos,
    round(100.0 * count(*) filter (where dos_urbanos) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_dos_urbanos,
    count(*) filter (where dos_viviendas) as n_dos_viviendas,
    round(100.0 * count(*) filter (where dos_viviendas) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_dos_viviendas,
    count(*) filter (where dos_equivalentes) as n_dos_equivalentes,
    round(100.0 * count(*) filter (where dos_equivalentes) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_dos_equivalentes,
    count(*) filter (where n_urbanos = 0) as n_sin_urbanos,
    round(100.0 * count(*) filter (where n_urbanos = 0) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_sin_urbanos,
    median(n_inmuebles) as mediana_inmuebles,
    median(n_urbanos) as mediana_urbanos,
    round(avg(n_urbanos), 2) as media_urbanos,
    median(urbanos_equivalentes) as mediana_urbanos_equivalentes,
    round(avg(rend_real_eur) filter (where alquila and rend_real_eur > 0), 0) as media_alquiler_real_eur,
    round(median(rend_real_eur) filter (where alquila and rend_real_eur > 0), 0) as mediana_alquiler_real_eur,
    max(ejercicio_rentas) filter (where extraccion_ok) as ejercicio_rentas_max,
    mode(ejercicio_rentas) filter (where extraccion_ok) as ejercicio_rentas_moda,
    case when grupo = 'Total' then 0 else 1 end as orden_total
from grupos
group by grupo
order by orden_total, n_diputados desc
