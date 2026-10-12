-- Ciudades de Urban Audit (Eurostat): una fila por ciudad con su nombre (el de GISCO o, si no
-- está en el mapa de 2021, el de Eurostat), país (cod_pais ISO alfa-2 del seed paises_iso),
-- posición (lat, lon del punto de etiqueta de GISCO), si es capital, su última población y,
-- en las españolas, el municipio del INE (cod_mun, para enlazar con su ficha): se casa por
-- nombre (cualquiera de las partes separadas por '/', sin tildes; el de más población si hay
-- homónimos) salvo las del seed ciudades_municipios.
with codigos as (
    select cod_ciudad, any_value(nombre_eurostat) as nombre_eurostat
    from {{ source('raw_ciudades', 'ciudades_urban_audit') }}
    group by cod_ciudad
),

base as (
    select
        c.cod_ciudad,
        replace(coalesce(g.nombre, c.nombre_eurostat), ' (greater city)', '') as ciudad,
        left(c.cod_ciudad, 2) as pais_eurostat,
        g.lat,
        g.lon,
        coalesce(g.capital, false) as es_capital
    from codigos c
    left join {{ source('raw_ciudades', 'ciudades_gisco') }} g using (cod_ciudad)
),

poblacion as (
    select cod_ciudad, max_by(valor, anio) as poblacion, max(anio) as anio_poblacion
    from {{ ref('stg_ciudades_series') }}
    where indicador_id = 'poblacion'
    group by cod_ciudad
),

municipios as (
    select cod_mun, any_value(municipio) as municipio, max_by(poblacion, anio) as poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    group by cod_mun
),

partes_ciudad as (
    select cod_ciudad, lower(strip_accents(trim(unnest(string_split(ciudad, '/'))))) as parte
    from base
    where pais_eurostat = 'ES'
),

partes_municipio as (
    select cod_mun, poblacion, lower(strip_accents(trim(unnest(string_split(municipio, '/'))))) as parte
    from municipios
),

por_nombre as (
    select pc.cod_ciudad, pm.cod_mun
    from partes_ciudad pc
    join partes_municipio pm using (parte)
    qualify row_number() over (partition by pc.cod_ciudad order by pm.poblacion desc) = 1
)

select
    b.cod_ciudad,
    b.ciudad,
    p.cod_pais,
    p.pais,
    p.cod_pais = 'ES' as es_espana,
    coalesce(m.cod_mun, n.cod_mun) as cod_mun,
    b.es_capital,
    b.lat,
    b.lon,
    cast(po.poblacion as bigint) as poblacion,
    po.anio_poblacion
from base b
join {{ ref('paises_iso') }} p on p.eurostat = b.pais_eurostat
left join {{ ref('ciudades_municipios') }} m using (cod_ciudad)
left join por_nombre n using (cod_ciudad)
left join poblacion po using (cod_ciudad)
