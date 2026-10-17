-- Celdas de 10 km de España con superficie agraria, para el mapa de puntos: textura, grupo de
-- suelo y cultivo dominantes y medias de arcilla, pH y materia orgánica de la capa arable.
select
    r.celda,
    r.lon,
    r.lat,
    r.cod_prov,
    t.nombre as provincia,
    r.superficie_agraria_km2,
    r.textura,
    r.textura_grupo,
    r.wrb,
    r.cultivo,
    r.arcilla as arcilla_pct,
    r.ph,
    r.mo as materia_organica_pct
from {{ source('raw_suelos', 'suelos_rejilla') }} r
left join {{ ref('territorios') }} t on t.nivel = 'provincia' and t.cod = r.cod_prov
