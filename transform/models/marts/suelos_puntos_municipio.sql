-- Trozo de cada celda de 1 km que cae dentro de cada municipio, con su superficie agraria (CORINE
-- 2018 a 250 m), el cultivo con más superficie y el suelo de la celda (SoilGrids): mapa de puntos
-- de un municipio y reparto de su superficie agraria por textura, tipo de suelo y pH.
select
    p.cod_mun,
    left(p.cod_mun, 2) as cod_prov,
    t.cod_ccaa,
    p.celda,
    p.lon,
    p.lat,
    p.superficie_agraria_km2,
    p.cultivo,
    p.textura,
    p.textura_grupo,
    p.wrb,
    p.ph_clase,
    p.arcilla as arcilla_pct,
    p.ph,
    p.mo as materia_organica_pct
from {{ source('raw_suelos', 'suelos_puntos_municipio') }} p
left join {{ ref('territorios') }} t on t.nivel = 'provincia' and t.cod = left(p.cod_mun, 2)
order by p.cod_mun
