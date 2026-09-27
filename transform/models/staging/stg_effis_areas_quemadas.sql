-- Una fila por incendio cartografiado por EFFIS en España (desde 2000).
-- La provincia de EFFIS es la NUTS3 (en las islas viene la isla), así que se
-- traduce al código INE de provincia con el seed provincias_codigos.
select
    e.id,
    cast(timezone('Europe/Madrid', cast(e.firedate as timestamptz)) as date) as fecha,
    extract(year from timezone('Europe/Madrid', cast(e.firedate as timestamptz)))::integer as anio,
    cast(timezone('Europe/Madrid', cast(e.lastupdate as timestamptz)) as date) as fecha_actualizacion,
    e.province as provincia_effis,
    p.cod_prov,
    p.provincia,
    e.commune as municipio,
    e.area_ha,
    e.latitud,
    e.longitud,
    -- Cubiertas del suelo afectadas (% de la superficie quemada)
    coalesce(e.broadlea, 0) as pct_frondosas,
    coalesce(e.conifer, 0) as pct_coniferas,
    coalesce(e.mixed, 0) as pct_bosque_mixto,
    coalesce(e.scleroph, 0) as pct_esclerofila,
    coalesce(e.transit, 0) as pct_matorral_transicion,
    coalesce(e.othernatlc, 0) as pct_otra_natural,
    coalesce(e.agriareas, 0) as pct_agricola,
    coalesce(e.artifsurf, 0) as pct_artificial,
    coalesce(e.otherlc, 0) as pct_otras,
    coalesce(e.percna2k, 0) as pct_natura2000
from {{ source('raw_incendios', 'effis_areas_quemadas') }} as e
left join {{ ref('provincias_codigos') }} as p
  on p.nombre_effis = e.province
where e.area_ha > 0
