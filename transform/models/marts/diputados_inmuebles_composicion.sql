-- Qué inmuebles declaran los diputados del Congreso (XV Legislatura, declaración inicial de
-- Bienes y Rentas) y cómo los adquirieron, por partido (ver diputados_inmuebles_partidos) y
-- 'Total'. El formulario no pide el valor de los inmuebles: el patrimonio inmobiliario se
-- describe por su composición.
--   desglose 'tipo': inmuebles a su nombre por tipo (vivienda, garaje o trastero, local u
--     oficina, otros urbanos, finca rústica); por_diputado = unidades / diputados válidos.
--   desglose 'adquisicion': inmuebles urbanos según el título declarado (herencia o
--     donación, compra, no consta); pct = % de los urbanos del partido.
-- Se calcula fila a fila sobre la lectura automática (cong_inmuebles_declarados), también
-- para los diputados revisados a mano, cuyos totales corregidos están en
-- diputados_inmuebles_diputados: por eso estas sumas no cuadran exactamente con aquellas.
with dip as (
    select id_diputado, partido from {{ ref('diputados_inmuebles_diputados') }} where extraccion_ok
),

validos as (
    select partido, count(*) as n_validos from dip group by partido
    union all
    select 'Total', count(*) from dip
),

i as (
    select dip.partido, x.*
    from {{ source('raw_diputados_inmuebles', 'cong_inmuebles_declarados') }} x
    join dip on dip.id_diputado = cast(x.id_diputado as integer)
),

filas as (
    select partido, tipo, titulo, cast(unidades as integer) as unidades, unidades_vivienda,
           unidades_garaje, unidades_local, unidades_otros
    from i
    union all
    select 'Total', tipo, titulo, cast(unidades as integer), unidades_vivienda,
           unidades_garaje, unidades_local, unidades_otros
    from i
),

tipos as (
    select partido, 'tipo' as desglose, categoria, orden, sum(unidades) as unidades
    from (
        select partido, 'Vivienda' as categoria, 1 as orden, unidades_vivienda as unidades from filas where tipo = 'urbano'
        union all
        select partido, 'Garaje o trastero', 2, unidades_garaje from filas where tipo = 'urbano'
        union all
        select partido, 'Local, oficina o nave', 3, unidades_local from filas where tipo = 'urbano'
        union all
        select partido, 'Otros urbanos (solares, edificios...)', 4, unidades_otros from filas where tipo = 'urbano'
        union all
        select partido, 'Finca rústica', 5, unidades from filas where tipo = 'rustico'
    )
    group by all
),

adquisicion as (
    select partido, 'adquisicion' as desglose,
           case titulo when 'herencia' then 'Herencia o donación' when 'compra' then 'Compra' else 'No consta' end as categoria,
           case titulo when 'herencia' then 1 when 'compra' then 2 else 3 end as orden,
           sum(unidades) as unidades
    from filas
    where tipo = 'urbano'
    group by all
),

u as (
    select * from tipos
    union all
    select * from adquisicion
)

select
    u.partido,
    u.desglose,
    u.categoria,
    u.orden,
    cast(u.unidades as integer) as unidades,
    v.n_validos,
    round(u.unidades / v.n_validos, 2) as por_diputado,
    round(100.0 * u.unidades / sum(u.unidades) over (partition by u.partido, u.desglose), 1) as pct,
    case when u.partido = 'Total' then 0 else 1 end as orden_total
from u
join validos v on v.partido = u.partido
order by orden_total, u.partido, u.desglose, u.orden
