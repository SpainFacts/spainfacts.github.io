-- Red de carreteras de España para el mapa: una fila por titular, tipo de vía, carretera y
-- provincia con todos sus trozos en el trazado («lon,lat;...|lon,lat;...», el formato del modo
-- líneas de MapaEspana). La del Estado sale del catálogo oficial; la de comunidades y
-- diputaciones, de OpenStreetMap (km aproximados: las cifras oficiales están en
-- movilidad_carreteras_provincia).
select
    titular,
    case titular when 'estado' then 1 when 'comunidad' then 2 when 'diputacion' then 3 end as titular_orden,
    tipo,
    case tipo when 'peaje' then 1 when 'autovia' then 2 when 'multicarril' then 3 when 'convencional' then 4 end as tipo_orden,
    carretera,
    r.cod_prov,
    p.nombre as provincia,
    p.cod_ccaa,
    longitud_km,
    trazado
from {{ source('raw_carreteras', 'carreteras_red') }} r
left join {{ ref('territorios_provincias') }} p on p.cod_prov = r.cod_prov
