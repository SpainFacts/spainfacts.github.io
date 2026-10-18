-- Celdas con superficie agraria para el mapa de puntos, en cuatro escalas: espana (10 km), ccaa
-- (5 km) y provincia (2 km) en España, con la provincia y comunidad donde más superficie agraria
-- tienen, y europa (25 km) con su región NUTS 2 y su país: textura, grupo de suelo y cultivo
-- dominantes y medias de arcilla, pH y materia orgánica.
select
    r.escala,
    r.celda_km,
    r.celda,
    r.lon,
    r.lat,
    r.cod_prov,
    r.cod_ccaa,
    r.nuts2,
    r.pais as cod_pais_eurostat,
    coalesce(t.nombre, g.nombre) as provincia,
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
left join {{ source('raw_suelos', 'suelos_regiones') }} g on g.cod = r.nuts2
-- Turquía e Islandia se salen del mapa de regiones de Europa (static/geo/nuts2_europa.geojson)
where coalesce(r.pais, '') not in ('TR', 'IS')
order by r.escala, r.cod_ccaa, r.cod_prov
