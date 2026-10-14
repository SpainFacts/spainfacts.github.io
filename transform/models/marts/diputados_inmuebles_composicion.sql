-- Qué inmuebles declaran los diputados del Congreso (XV Legislatura, declaración inicial de
-- Bienes y Rentas) y cómo los adquirieron, por partido (ver diputados_inmuebles_partidos) y
-- 'Total', a partir de los recuentos revisados a mano de cada diputado
-- (diputados_inmuebles_diputados). El formulario no pide el valor de los inmuebles: el
-- patrimonio inmobiliario se describe por su composición.
--   desglose 'tipo': inmuebles a su nombre por tipo (vivienda, garaje o trastero, local u
--     oficina, otros urbanos, finca rústica); por_diputado = unidades / diputados válidos.
--   desglose 'adquisicion': inmuebles urbanos según el título declarado (herencia o
--     donación, compra, otro o no consta); pct = % de los urbanos del partido.
with d as (
    select * from {{ ref('diputados_inmuebles_diputados') }} where extraccion_ok
),

p as (
    select partido, d.* exclude (partido) from d
    union all
    select 'Total', d.* exclude (partido) from d
),

agregado as (
    select
        partido,
        count(*) as n_validos,
        sum(n_viviendas_urbanas) as viviendas,
        sum(n_garajes_trasteros) as garajes,
        sum(n_locales) as locales,
        sum(n_otros_urbanos) as otros,
        sum(n_rusticos) as rusticos,
        sum(n_urbanos) as urbanos,
        sum(n_urbanos_herencia) as herencia,
        sum(n_urbanos_compra) as compra
    from p
    group by partido
),

u as (
    select partido, n_validos, 'tipo' as desglose, 'Vivienda' as categoria, 1 as orden, viviendas as unidades from agregado
    union all select partido, n_validos, 'tipo', 'Garaje o trastero', 2, garajes from agregado
    union all select partido, n_validos, 'tipo', 'Local, oficina o nave', 3, locales from agregado
    union all select partido, n_validos, 'tipo', 'Otros urbanos (solares, edificios...)', 4, otros from agregado
    union all select partido, n_validos, 'tipo', 'Finca rústica', 5, rusticos from agregado
    union all select partido, n_validos, 'adquisicion', 'Herencia o donación', 1, herencia from agregado
    union all select partido, n_validos, 'adquisicion', 'Compra', 2, compra from agregado
    union all select partido, n_validos, 'adquisicion', 'Otro o no consta', 3, urbanos - herencia - compra from agregado
)

select
    partido,
    desglose,
    categoria,
    orden,
    cast(unidades as integer) as unidades,
    n_validos,
    round(unidades / n_validos, 2) as por_diputado,
    round(100.0 * unidades / nullif(sum(unidades) over (partition by partido, desglose), 0), 1) as pct,
    case when partido = 'Total' then 0 else 1 end as orden_total
from u
order by orden_total, partido, desglose, orden
