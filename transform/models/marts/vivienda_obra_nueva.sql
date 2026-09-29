-- Viviendas libres iniciadas y terminadas por año, España, comunidades y
-- provincias (Ministerio de Vivienda y Agenda Urbana, boletín estadístico,
-- tablas 32200500 y 32201000; estimaciones a partir de los certificados de
-- los colegios de aparejadores). Solo vivienda libre: no incluye la protegida.
-- *_1000: por 1.000 habitantes (población a 1 de enero, poblacion_territorios),
-- solo desde el primer año con población (1996); para años sin padrón (1997)
-- se usa el último anterior disponible.
with base as (
    select
        nivel,
        cod,
        cast(anio as integer) as anio,
        max(viviendas) filter (where fase = 'Iniciadas') as iniciadas,
        max(viviendas) filter (where fase = 'Terminadas') as terminadas
    from {{ source('raw_vivienda', 'vivienda_obra_nueva') }}
    group by all
),

pob as (
    select nivel, cod, anio, poblacion from {{ ref('poblacion_territorios') }} where sexo = 'Total'
),

con_pob as (
    select b.*, p.poblacion
    from base b
    asof left join pob p
      on p.nivel = b.nivel and p.cod = b.cod and p.anio <= b.anio
)

select
    b.nivel,
    b.cod,
    coalesce(t.nombre, 'España') as nombre,
    b.anio,
    b.iniciadas,
    b.terminadas,
    b.poblacion,
    1000.0 * b.iniciadas / b.poblacion as iniciadas_1000,
    1000.0 * b.terminadas / b.poblacion as terminadas_1000
from con_pob b
left join {{ ref('territorios') }} t on t.nivel = b.nivel and t.cod = b.cod
