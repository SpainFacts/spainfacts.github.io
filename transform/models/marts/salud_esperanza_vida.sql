-- Esperanza de vida al nacer por territorio y sexo, anual: España (Eurostat
-- demo_mlexpec), comunidades (INE 1448) y provincias (INE 1485).
with ccaa as (
    select
        anyo as anio,
        'ccaa' as nivel,
        n.cod_ccaa as cod,
        rtrim(split_part(serie, '. ', 3), '.') as sexo,
        valor as anios
    from {{ source('raw', 'ine_esperanza_vida_ccaa') }} e
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = split_part(e.serie, '. ', 2)
    where valor is not null
),

provincias as (
    select
        anyo as anio,
        'provincia' as nivel,
        p.cod_prov as cod,
        rtrim(split_part(serie, '. ', 3), '.') as sexo,
        valor as anios
    from {{ source('raw', 'ine_esperanza_vida_provincia') }} e
    join {{ ref('ine_provincias_nombres') }} p on p.nombre_ine = split_part(e.serie, '. ', 2)
    where valor is not null
),

espana as (
    select
        cast(anio as integer) as anio,
        'pais' as nivel,
        '00' as cod,
        case sexo when 'T' then 'Ambos sexos' when 'M' then 'Varones' when 'F' then 'Mujeres' end as sexo,
        anios
    from {{ source('raw_eurostat_extra', 'eurostat_esperanza_vida') }}
    where anios is not null
)

select anio, nivel, cod, case sexo when 'Varones' then 'Hombres' else sexo end as sexo, anios
from (
    select * from ccaa
    union all select * from provincias
    union all select * from espana
)
