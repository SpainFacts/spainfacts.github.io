-- Series anuales por comunidad para la vivienda pública en alquiler:
-- % de hogares en alquiler inferior al precio de mercado (ECV, 2004-...) y
-- calificaciones provisionales de vivienda protegida en alquiler (MIVAU,
-- 2005-2023) por 100.000 habitantes, con el partido que gobernaba la comunidad
-- a 1 de julio de cada año (seed gobiernos_presidentes). Las calificaciones
-- dependen también de los planes estatales de vivienda, que las financian en
-- parte: la atribución al Gobierno autonómico es orientativa.
with calif as (
    select cod_ccaa, cast(anio as integer) as anio,
        max(viviendas) filter (where regimen = 'alquiler') as calif_alquiler,
        max(viviendas) filter (where regimen = 'total') as calif_total
    from {{ source('raw_vivienda_publica', 'vp_calificaciones') }}
    where cod_ccaa <> '00'
    group by all
),

ecv as (
    select cod_ccaa, anio, pct_alquiler_inferior, pct_alquiler_mercado
    from {{ ref('stg_vivienda_publica_ecv') }}
    where cod_ccaa <> '00'
),

base as (
    select coalesce(c.cod_ccaa, e.cod_ccaa) as cod_ccaa, coalesce(c.anio, e.anio) as anio,
        c.calif_alquiler, c.calif_total, e.pct_alquiler_inferior, e.pct_alquiler_mercado
    from calif c
    full join ecv e on e.cod_ccaa = c.cod_ccaa and e.anio = c.anio
),

pob as (
    select cod, anio, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

gobiernos as (
    select cod, desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'autonomico'
)

select
    b.cod_ccaa,
    t.nombre as comunidad,
    b.anio,
    b.pct_alquiler_inferior as ecv_pct_alquiler_inferior,
    b.pct_alquiler_mercado as ecv_pct_alquiler_mercado,
    cast(b.calif_alquiler as integer) as calif_alquiler,
    cast(b.calif_total as integer) as calif_total,
    100000.0 * b.calif_alquiler / p.poblacion as calif_alquiler_100k,
    cast(p.poblacion as bigint) as poblacion,
    g.familia,
    g.presidente
from base b
join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = b.cod_ccaa
left join pob p on p.cod = b.cod_ccaa and p.anio = b.anio
left join gobiernos g on g.cod = b.cod_ccaa
    and g.desde <= make_date(b.anio, 7, 1) and g.hasta > make_date(b.anio, 7, 1)
order by b.cod_ccaa, b.anio
