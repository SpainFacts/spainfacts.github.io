-- Población oficial (padrón, INE 29005) agregada a España, comunidad y provincia.
-- El nombre sale de territorios_ccaa y territorios_provincias (no de `territorios`,
-- que lee esta tabla para su población_ultima).
with m as (
    select * from {{ ref('poblacion_municipios') }}
),

agregados as (
    select anio, 'pais' as nivel, '00' as cod, sexo,
        sum(poblacion) as poblacion, count(*) as n_municipios
    from m group by all
    union all
    select anio, 'ccaa', cod_ccaa, sexo, sum(poblacion), count(*)
    from m group by all
    union all
    select anio, 'provincia', cod_prov, sexo, sum(poblacion), count(*)
    from m group by all
),

nombres as (
    select 'pais' as nivel, '00' as cod, 'España' as nombre
    union all
    select 'ccaa', cod_ccaa, nombre from {{ ref('territorios_ccaa') }}
    union all
    select 'provincia', cod_prov, nombre from {{ ref('territorios_provincias') }}
)

select
    a.anio,
    a.nivel,
    a.cod,
    n.nombre,
    a.sexo,
    cast(a.poblacion as bigint) as poblacion,
    cast(a.n_municipios as integer) as n_municipios,
    a.nivel || '-' || a.cod || '-' || a.sexo || '-' || a.anio as clave
from agregados a
left join nombres n on n.nivel = a.nivel and n.cod = a.cod
