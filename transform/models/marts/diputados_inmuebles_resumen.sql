-- Resumen: cuántos diputados del Congreso (XV Legislatura, en activo) cumplen cada
-- definición de "casero" según su declaración inicial de Bienes y Rentas (Registro de
-- Intereses del Congreso; ver diputados_inmuebles_diputados). Una fila por definición.
-- pct = n_cumplen / n_validos (declaraciones leídas correctamente); las no legibles o que
-- remiten a otra declaración (n_excluidos) quedan fuera del porcentaje.
with d as (
    select * from {{ ref('diputados_inmuebles_diputados') }}
),

totales as (
    select
        count(*) as n_diputados,
        count(*) filter (where extraccion_ok) as n_validos,
        count(*) filter (where not extraccion_ok) as n_excluidos,
        median(n_inmuebles) as mediana_inmuebles,
        median(n_urbanos) as mediana_urbanos,
        round(avg(n_urbanos), 2) as media_urbanos,
        median(urbanos_equivalentes) as mediana_urbanos_equivalentes,
        mode(ejercicio_rentas) filter (where extraccion_ok) as ejercicio_rentas,
        min(fecha_declaracion) as primera_declaracion,
        max(fecha_declaracion) as ultima_declaracion
    from d
),

defs as (
    select 1 as orden, 'alquila' as definicion_id,
           'Declara rentas por alquiler de inmuebles' as definicion,
           count(*) filter (where alquila) as n_cumplen from d
    union all
    select 2, 'dos_urbanos', 'Declara 2 o más inmuebles urbanos (incluye garajes y trasteros)',
           count(*) filter (where dos_urbanos) from d
    union all
    select 3, 'dos_viviendas', 'Declara 2 o más viviendas',
           count(*) filter (where dos_viviendas) from d
    union all
    select 4, 'dos_equivalentes', 'Suma 2 o más inmuebles urbanos completos según su % de titularidad',
           count(*) filter (where dos_equivalentes) from d
    union all
    select 5, 'alquila_o_dos_viviendas', 'Alquila o declara 2 o más viviendas',
           count(*) filter (where alquila or dos_viviendas) from d
    union all
    select 6, 'sin_urbanos', 'No declara ningún inmueble urbano',
           count(*) filter (where n_urbanos = 0) from d
)

select
    defs.orden,
    defs.definicion_id,
    defs.definicion,
    defs.n_cumplen,
    round(100.0 * defs.n_cumplen / nullif(t.n_validos, 0), 1) as pct,
    t.*
from defs
cross join totales t
order by defs.orden
