-- Gasolineras por municipio (todos los municipios, también los que no tienen ninguna).
with base as (
    select cod_mun, count(*) as estaciones, avg(precio_gasoleo_a) as precio_gasoleo_a, avg(precio_gasolina_95) as precio_gasolina_95
    from {{ ref('movilidad_gasolineras') }}
    where cod_mun is not null
    group by cod_mun
),

municipios as (
    select cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and vigente
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
)

select
    m.cod_mun,
    m.municipio,
    m.cod_prov,
    p.nombre as provincia,
    m.cod_ccaa,
    m.poblacion,
    coalesce(b.estaciones, 0) as estaciones,
    10000.0 * coalesce(b.estaciones, 0) / nullif(m.poblacion, 0) as estaciones_por_10k_hab,
    b.precio_gasoleo_a,
    b.precio_gasolina_95
from municipios m
left join base b on b.cod_mun = m.cod_mun
left join {{ ref('territorios_provincias') }} p on p.cod_prov = m.cod_prov
