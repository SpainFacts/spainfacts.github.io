-- Inmuebles declarados por los diputados del Congreso (XV Legislatura, declaración inicial
-- de Bienes y Rentas) por partido: la formación por la que fueron elegidos, con las
-- federaciones del PSOE dentro de PSOE (ver diputados_inmuebles_diputados). Una fila por
-- partido y otra 'Total'. Medias y medianas por diputado sobre las declaraciones leídas
-- correctamente (n_validos), para comparar partidos de distinto tamaño; los totales
-- (suma_*) solo como dato secundario. La medida principal es urbanos_equivalentes
-- (inmuebles urbanos completos: suma de su parte de cada uno), que no cuenta las fincas
-- rústicas, muchas veces parcelas pequeñas heredadas en el rural.
with d as (
    select * from {{ ref('diputados_inmuebles_diputados') }}
),

partidos as (
    select partido, d.* exclude (partido) from d
    union all
    select 'Total' as partido, d.* exclude (partido) from d
)

select
    partido,
    count(*) as n_diputados,
    count(*) filter (where extraccion_ok) as n_validos,
    round(avg(n_inmuebles), 2) as media_inmuebles,
    median(n_inmuebles) as mediana_inmuebles,
    round(avg(n_urbanos), 2) as media_urbanos,
    median(n_urbanos) as mediana_urbanos,
    round(avg(n_viviendas_urbanas), 2) as media_viviendas,
    median(n_viviendas_urbanas) as mediana_viviendas,
    round(avg(n_rusticos), 2) as media_rusticos,
    round(avg(urbanos_equivalentes), 2) as media_urbanos_equivalentes,
    median(urbanos_equivalentes) as mediana_urbanos_equivalentes,
    max(urbanos_equivalentes) as max_urbanos_equivalentes,
    round(100.0 * count(*) filter (where alquila) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_alquila,
    round(100.0 * count(*) filter (where dos_viviendas) / nullif(count(*) filter (where extraccion_ok), 0), 1) as pct_dos_viviendas,
    max(n_inmuebles) as max_inmuebles,
    sum(n_inmuebles) as suma_inmuebles,
    sum(n_urbanos) as suma_urbanos,
    sum(n_viviendas_urbanas) as suma_viviendas,
    case when partido = 'Total' then 0 else 1 end as orden_total
from partidos
group by partido
order by orden_total, media_urbanos_equivalentes desc
