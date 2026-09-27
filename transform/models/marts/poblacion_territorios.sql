-- Población oficial (padrón, INE 29005) agregada a España, comunidad y provincia.
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
)

select
    anio,
    nivel,
    cod,
    sexo,
    cast(poblacion as bigint) as poblacion,
    cast(n_municipios as integer) as n_municipios,
    nivel || '-' || cod || '-' || sexo || '-' || anio as clave
from agregados
