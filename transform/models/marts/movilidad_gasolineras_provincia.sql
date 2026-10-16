-- Gasolineras por provincia: estaciones por 10.000 habitantes, municipios y vecinos sin
-- ninguna, precio medio del momento, peso de las de bajo coste y del primer grupo, y consumo
-- de carburante de automoción por habitante del último año completo de CORES.
with base as (
    select * from {{ ref('movilidad_gasolineras') }}
),

por_grupo as (
    select cod_prov, grupo, count(*) as n
    from base
    group by cod_prov, grupo
),

primero as (
    select cod_prov, grupo as grupo_principal, n
    from por_grupo
    qualify row_number() over (partition by cod_prov order by n desc, grupo) = 1
),

municipios as (
    select cod_mun, cod_prov, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and vigente
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
),

con_estacion as (
    select distinct cod_mun from base where cod_mun is not null
),

sin as (
    select
        m.cod_prov,
        count(*) as municipios,
        count(*) filter (where c.cod_mun is null) as municipios_sin_gasolinera,
        sum(m.poblacion) filter (where c.cod_mun is null) as poblacion_sin_gasolinera
    from municipios m
    left join con_estacion c on c.cod_mun = m.cod_mun
    group by m.cod_prov
),

poblacion as (
    select cod as cod_prov, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'provincia' and sexo = 'Total'
    qualify row_number() over (partition by cod order by anio desc) = 1
),

consumo as (
    select cod, anio, litros_automocion_hab
    from {{ ref('movilidad_carburantes_consumo') }}
    where nivel = 'provincia' and meses = 12
    qualify row_number() over (partition by cod order by anio desc) = 1
),

agregado as (
    select
        cod_prov,
        count(*) as estaciones,
        count(*) filter (where tipo = 'Bajo coste') as estaciones_bajo_coste,
        count(*) filter (where tipo = 'Supermercado') as estaciones_supermercado,
        count(*) filter (where abierta_24h) as estaciones_24h,
        avg(precio_gasoleo_a) as precio_gasoleo_a,
        avg(precio_gasolina_95) as precio_gasolina_95
    from base
    where cod_prov is not null
    group by cod_prov
)

select
    t.cod_prov,
    t.nombre as provincia,
    t.cod_ccaa,
    coalesce(a.estaciones, 0) as estaciones,
    10000.0 * a.estaciones / nullif(h.poblacion, 0) as estaciones_por_10k_hab,
    h.poblacion,
    s.municipios,
    s.municipios_sin_gasolinera,
    coalesce(s.poblacion_sin_gasolinera, 0) as poblacion_sin_gasolinera,
    100.0 * coalesce(s.poblacion_sin_gasolinera, 0) / nullif(h.poblacion, 0) as poblacion_sin_gasolinera_pct,
    100.0 * a.estaciones_bajo_coste / nullif(a.estaciones, 0) as bajo_coste_pct,
    100.0 * a.estaciones_supermercado / nullif(a.estaciones, 0) as supermercado_pct,
    100.0 * a.estaciones_24h / nullif(a.estaciones, 0) as abiertas_24h_pct,
    p.grupo_principal,
    100.0 * p.n / nullif(a.estaciones, 0) as grupo_principal_pct,
    a.precio_gasoleo_a,
    a.precio_gasolina_95,
    c.litros_automocion_hab,
    c.anio as anio_consumo
from {{ ref('territorios_provincias') }} t
left join agregado a on a.cod_prov = t.cod_prov
left join primero p on p.cod_prov = t.cod_prov
left join sin s on s.cod_prov = t.cod_prov
left join poblacion h on h.cod_prov = t.cod_prov
left join consumo c on c.cod = t.cod_prov
