-- Turismos NUEVOS matriculados por año y municipio del domicilio del vehículo,
-- en columnas por energía (DGT, MATRABA). Ojo: el municipio es el del titular;
-- las flotas de renting y alquiler se concentran donde tienen la sede, así que para
-- comparar pueblos conviene particulares_por_1000_hab (sin flotas).
-- Población: padrón del año (el último para los años sin padrón). Los municipios que
-- no figuran en el padrón conservan su fila con población, nombre y tasas vacíos.
-- bev_pct, phev_pct y hev_pct son el % de cada energía sobre los turismos nuevos.
with m as (
    select
        cast(year(mes) as integer) as anio,
        cod_mun,
        sum(matriculaciones) as turismos,
        sum(matriculaciones) filter (where energia = 'bev') as bev,
        sum(matriculaciones) filter (where energia = 'phev') as phev,
        sum(matriculaciones) filter (where energia = 'hev') as hev,
        sum(matriculaciones) filter (where energia = 'gasolina') as gasolina,
        sum(matriculaciones) filter (where energia = 'diesel') as diesel,
        sum(matriculaciones) filter (where energia not in ('bev', 'phev', 'hev', 'gasolina', 'diesel')) as otras,
        sum(matriculaciones) filter (where not renting and titular = 'fisica') as particulares
    from {{ source('raw_movilidad', 'dgt_matriculaciones') }}
    where grupo = 'turismo'
      and nuevo_usado = 'N'
      and cod_mun is not null
    group by all
),

pob as (
    select cod_mun, anio, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

ultimo as (select max(anio) as anio from pob),

-- Nombre y comunidad del municipio según el padrón más reciente en que aparece
nombres as (
    select cod_mun, municipio, cod_prov, cod_ccaa
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
)

select
    m.anio,
    m.cod_mun,
    n.municipio,
    coalesce(n.cod_prov, left(m.cod_mun, 2)) as cod_prov,
    pr.nombre as provincia,
    coalesce(n.cod_ccaa, pr.cod_ccaa) as cod_ccaa,
    c.nombre as ccaa,
    p.poblacion,
    m.turismos,
    m.bev,
    m.phev,
    m.hev,
    m.gasolina,
    m.diesel,
    m.otras,
    m.particulares,
    1000.0 * m.turismos / nullif(p.poblacion, 0) as turismos_por_1000_hab,
    1000.0 * m.particulares / nullif(p.poblacion, 0) as particulares_por_1000_hab,
    100.0 * m.bev / nullif(m.turismos, 0) as bev_pct,
    100.0 * m.phev / nullif(m.turismos, 0) as phev_pct,
    100.0 * m.hev / nullif(m.turismos, 0) as hev_pct
from m
join ultimo u on true
left join pob p on p.cod_mun = m.cod_mun and p.anio = least(m.anio, u.anio)
left join nombres n on n.cod_mun = m.cod_mun
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = coalesce(n.cod_prov, left(m.cod_mun, 2))
left join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = coalesce(n.cod_ccaa, pr.cod_ccaa)
