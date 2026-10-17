-- Celdas de España con superficie agraria para el mapa de puntos, en tres escalas: espana (10 km),
-- ccaa (5 km) y provincia (2 km), con la provincia y comunidad donde más superficie agraria
-- tienen: textura, grupo de suelo y cultivo dominantes y medias de arcilla, pH y materia orgánica.
select
    r.escala,
    r.celda_km,
    r.celda,
    r.lon,
    r.lat,
    r.cod_prov,
    r.cod_ccaa,
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
order by r.escala, r.cod_ccaa, r.cod_prov
