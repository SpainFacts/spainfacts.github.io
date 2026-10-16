-- Oleoductos de España según OpenStreetMap: una fila por vía con operador, nombre, diámetro,
-- longitud y trazado simplificado («lon,lat;lon,lat», el formato del modo líneas de
-- MapaEspana). OSM cubre ~3.950 km de los más de 4.000 que declara Exolum.
select
    osm_id,
    coalesce(operador, 'Sin operador en OSM') as operador,
    nombre,
    diametro,
    uso,
    ubicacion,
    longitud_km,
    trazado
from {{ source('raw_oleoductos', 'oleoductos_osm') }}
where sustancia = 'petroleo'
