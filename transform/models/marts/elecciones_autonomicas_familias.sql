-- Voto por familia política en cada elección autonómica, sumando los municipios de la
-- comunidad (mismo criterio que elecciones_autonomicas_municipios: el municipio entero si
-- la fuente lo da, si no la suma de sus secciones). % sobre votos válidos y sin voto CERA
-- (los totales oficiales lo incluyen, por eso difieren en torno a un 1 %). Una fila por
-- elección y familia, con su bloque y color, para la página de cada comunidad.
-- Solo elecciones con datos de al menos el 90 % de los municipios de la comunidad: las que
-- solo tienen una ciudad (Cáceres, Gijón) no dan un total de comunidad.
with enteros as (
    select distinct proceso, cod_mun
    from {{ source('raw_elecciones', 'elecciones_secciones') }}
    where tipo = '05' and nivel = 'municipio'
),

votos as (
    select
        v.proceso,
        c.familia,
        c.bloque,
        c.color,
        c.orden_familia,
        sum(v.votos) as votos
    from {{ source('raw_elecciones', 'elecciones_secciones_votos') }} v
    join {{ ref('elecciones_candidaturas') }} c
        on c.proceso = v.proceso and c.cod_candidatura = v.cod_candidatura
    where v.tipo = '05' and v.vuelta = 1
        and (coalesce(v.nivel, 'seccion') = 'municipio'
            or not exists (select 1 from enteros e
                           where e.proceso = v.proceso and e.cod_mun = coalesce(v.cod_mun, left(v.cod_seccion, 5))))
    group by all
),

totales as (
    select proceso, any_value(anio) as anio, any_value(fecha) as fecha, any_value(eleccion) as eleccion,
        any_value(cod_ccaa) as cod_ccaa, any_value(ccaa) as ccaa,
        sum(censo) as censo, sum(votantes) as votantes, sum(validos) as validos,
        bool_or(sin_blancos_nulos) as incompleto,
        count(distinct cod_mun) as municipios
    from {{ ref('elecciones_autonomicas_municipios') }}
    group by proceso
),

municipios_ccaa as (
    select cod_ccaa, count(*) as municipios from {{ ref('stg_ine_municipios') }} group by cod_ccaa
)

select
    v.proceso,
    t.anio,
    t.fecha,
    t.eleccion,
    t.cod_ccaa,
    t.ccaa,
    v.familia,
    v.bloque,
    v.color,
    v.orden_familia,
    cast(v.votos as integer) as votos,
    cast(100.0 * v.votos / nullif(t.validos, 0) as decimal(4, 1)) as pct,
    case when not t.incompleto then cast(100.0 * t.votantes / nullif(t.censo, 0) as decimal(4, 1)) end as participacion
from votos v
join totales t using (proceso)
join municipios_ccaa mc on mc.cod_ccaa = t.cod_ccaa and t.municipios >= 0.9 * mc.municipios
order by t.cod_ccaa, t.fecha, v.votos desc
