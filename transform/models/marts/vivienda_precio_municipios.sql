-- Valor tasado medio de la vivienda libre (€/m²) por año en los municipios de
-- más de 25.000 habitantes (Ministerio de Vivienda y Agenda Urbana, boletín
-- estadístico, tabla 35103500, trimestral desde 2005). Media anual de los
-- trimestres publicados (trimestres = cuántos), ponderada por el número de
-- tasaciones; en euros del año base de main.deflactor.
-- El fichero solo trae nombres: se casa con el código INE por provincia y
-- nombre normalizado (sin tildes, sin artículo, cualquiera de las formas
-- bilingües), y si no, por nombre único en toda España.
with raw as (
    select
        cod_prov,
        municipio,
        cast(anio as integer) as anio,
        cast(trimestre as integer) as trimestre,
        euros_m2,
        tasaciones
    from {{ source('raw_vivienda', 'vivienda_valor_tasado_municipios') }}
    where euros_m2 is not null
),

-- Clave normalizada: 'Ejido (El)' -> 'ejido'; 'Palmas de Gran Canaria (Las)' -> 'palmasdegrancanaria'
claves_mivau as (
    select distinct
        cod_prov,
        municipio,
        regexp_replace(lower(strip_accents(trim(parte))), '[^a-z]', '', 'g') as clave
    from (
        select cod_prov, municipio,
               unnest(string_split(regexp_replace(regexp_replace(municipio, '\s*\(.*\)\s*', '', 'g'), ',\s*\S+$', ''), '/')) as parte
        from (select distinct cod_prov, municipio from raw)
    )
),

ine as (
    select distinct cod_mun, municipio, cod_prov
    from {{ ref('poblacion_municipios') }}
),

claves_ine as (
    select distinct
        cod_mun,
        cod_prov,
        regexp_replace(lower(strip_accents(trim(regexp_replace(parte, ',\s*\S+$', '')))), '[^a-z]', '', 'g') as clave
    from (select cod_mun, cod_prov, unnest(string_split(municipio, '/')) as parte from ine)
),

por_provincia as (
    select m.municipio, m.cod_prov, min(i.cod_mun) as cod_mun
    from claves_mivau m
    join claves_ine i on i.clave = m.clave and i.cod_prov = m.cod_prov
    group by all
),

unicos as (
    select clave, min(cod_mun) as cod_mun
    from claves_ine
    group by clave
    having count(distinct cod_mun) = 1
),

por_nombre as (
    select m.municipio, m.cod_prov, min(u.cod_mun) as cod_mun
    from claves_mivau m
    join unicos u on u.clave = m.clave
    group by all
),

-- Casos que no casan por nombre
manuales as (
    select * from (values
        ('Palma de Mallorca', '07040'),
        ('Palma', '07040'),
        ('Santa Coloma Gramanet', '08245'),
        ('San Cristóbal Laguna', '38023'),
        ('Mahón', '07032'),
        ('Vitoria', '01059'),
        ('Santa Eulalia del Río', '07054')
    ) as t(municipio, cod_mun)
),

codigos as (
    select distinct r.cod_prov, r.municipio,
        coalesce(p.cod_mun, n.cod_mun, x.cod_mun) as cod_mun
    from (select distinct cod_prov, municipio from raw) r
    left join por_provincia p on p.municipio = r.municipio and p.cod_prov is not distinct from r.cod_prov
    left join por_nombre n on n.municipio = r.municipio and n.cod_prov is not distinct from r.cod_prov
    left join manuales x on x.municipio = r.municipio
),

anual as (
    select
        c.cod_mun,
        r.anio,
        count(*) as trimestres,
        sum(r.euros_m2 * coalesce(r.tasaciones, 1)) / sum(coalesce(r.tasaciones, 1)) as euros_m2,
        sum(r.euros_m2 * d.factor * coalesce(r.tasaciones, 1)) / sum(coalesce(r.tasaciones, 1)) as euros_m2_real,
        sum(r.tasaciones) as tasaciones,
        max(d.anio_base) as anio_base
    from raw r
    join codigos c on c.municipio = r.municipio and c.cod_prov is not distinct from r.cod_prov
    left join {{ ref('vivienda_deflactor_trimestral') }} d on d.anio = r.anio and d.trimestre = r.trimestre
    where c.cod_mun is not null
    group by all
),

nombres as (
    select cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and anio = (select max(anio) from {{ ref('poblacion_municipios') }})
)

select
    a.cod_mun,
    n.municipio,
    n.cod_prov,
    n.cod_ccaa,
    n.poblacion,
    a.anio,
    a.trimestres,
    a.euros_m2,
    a.euros_m2_real,
    90 * a.euros_m2_real as precio_90m2_real,
    a.tasaciones,
    a.anio_base,
    100 * (a.euros_m2_real / l.euros_m2_real - 1) as variacion_real
from anual a
left join anual l on l.cod_mun = a.cod_mun and l.anio = a.anio - 1
left join nombres n on n.cod_mun = a.cod_mun
