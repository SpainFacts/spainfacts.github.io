-- Hogares en viviendas familiares a 1 de enero por año y territorio (España
-- 'pais', comunidad 'ccaa', provincia 'provincia'), desde 2021.
-- Fuente: INE, Estadística Continua de Población, tablas 60131/60133 (hogares
-- por número de miembros) y 60132/60134 (tamaño medio del hogar). El INE las
-- publica cada trimestre (provisionales): se toma el dato a 1 de enero.
-- pct_unipersonales = hogares de 1 persona / total de hogares x 100.
with hogares as (
    select nivel, cod, cast(anio as integer) as anio, miembros, max(valor) as hogares
    from {{ source('raw_demografia', 'ine_hogares') }}
    where periodo = '1 de enero de' and nivel in ('pais', 'ccaa', 'provincia')
    group by all
),

tamano as (
    select nivel, cod, cast(anio as integer) as anio, max(valor) as tamano_medio
    from {{ source('raw_demografia', 'ine_hogares_tamano_medio') }}
    where periodo = '1 de enero de' and nivel in ('pais', 'ccaa', 'provincia')
    group by all
),

resumen as (
    select nivel, cod, anio,
        max(hogares) filter (where miembros = 'Total') as hogares,
        max(hogares) filter (where miembros = '1') as unipersonales,
        max(hogares) filter (where miembros = '2') as de_2,
        max(hogares) filter (where miembros = '3') as de_3,
        max(hogares) filter (where miembros = '4 y más') as de_4_o_mas
    from hogares
    group by all
)

select
    r.anio,
    r.nivel,
    r.cod,
    r.hogares,
    t.tamano_medio,
    r.unipersonales,
    100.0 * r.unipersonales / r.hogares as pct_unipersonales,
    100.0 * r.de_2 / r.hogares as pct_2,
    100.0 * r.de_3 / r.hogares as pct_3,
    100.0 * r.de_4_o_mas / r.hogares as pct_4_o_mas,
    r.nivel || '-' || r.cod || '-' || r.anio as clave
from resumen r
left join tamano t using (nivel, cod, anio)
