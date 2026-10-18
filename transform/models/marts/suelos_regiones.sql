-- Suelo agrario de cada región NUTS 2 (2021) de Europa con el mismo método que España (SoilGrids
-- sobre la superficie agraria de CORINE 2018), con lo medido por LUCAS 2018 en la región (si tiene
-- 10 muestras o más) y la erosión estimada del último año: para comparar regiones y no solo países.
with medias as (
    select * from {{ source('raw_suelos', 'suelos_medias') }}
    where ambito = 'nuts2' and cultivo = 'Toda la superficie agraria'
),

clases as (
    select
        cod,
        100.0 * sum(superficie_km2) filter (where dimension = 'textura_grupo' and orden >= 2)
            / nullif(sum(superficie_km2) filter (where dimension = 'textura_grupo'), 0) as pct_fuertes,
        100.0 * sum(superficie_km2) filter (where dimension = 'ph' and orden >= 3)
            / nullif(sum(superficie_km2) filter (where dimension = 'ph'), 0) as pct_basico,
        arg_max(clase, superficie_km2) filter (where dimension = 'textura') as textura_dominante,
        arg_max(clase, superficie_km2) filter (where dimension = 'wrb') as wrb_dominante
    from {{ source('raw_suelos', 'suelos_clases') }}
    where ambito = 'nuts2' and cultivo = 'Toda la superficie agraria'
    group by cod
),

erosion as (
    select cod, arg_max(erosion_t_ha, anio) as erosion_t_ha, arg_max(pct_moderada_grave, anio) as pct_erosion_moderada_grave,
        max(anio) as anio_erosion
    from {{ ref('suelos_erosion') }}
    where nivel = 'nuts2'
    group by cod
),

lucas as (
    select cod, muestras, materia_organica_pct, pct_mo_menos_2, ph, pct_erosion_visible, pct_carcavas
    from {{ ref('suelos_lucas_2018') }}
    where nivel = 'nuts2' and uso = 'Agraria'
)

select
    r.cod as nuts2,
    r.nombre,
    r.pais as cod_pais_eurostat,
    p.cod_pais,
    p.pais,
    p.es_ue,
    m.superficie_km2 as superficie_agraria_km2,
    100.0 * m.superficie_km2 / nullif(m.superficie_total_km2, 0) as pct_agraria,
    m.arcilla as arcilla_pct,
    m.ph,
    m.mo as materia_organica_pct,
    c.pct_fuertes,
    c.pct_basico,
    c.textura_dominante,
    c.wrb_dominante,
    e.erosion_t_ha,
    e.pct_erosion_moderada_grave,
    e.anio_erosion,
    l.muestras as lucas_muestras,
    l.materia_organica_pct as lucas_materia_organica_pct,
    l.pct_mo_menos_2 as lucas_pct_mo_menos_2,
    l.ph as lucas_ph,
    l.pct_erosion_visible as lucas_pct_erosion_visible,
    l.pct_carcavas as lucas_pct_carcavas
from {{ source('raw_suelos', 'suelos_regiones') }} r
join medias m on m.cod = r.cod
left join clases c on c.cod = r.cod
left join erosion e on e.cod = r.cod
left join lucas l on l.cod = r.cod
left join {{ ref('paises_iso') }} p on p.eurostat = r.pais
-- Turquía e Islandia se salen del mapa de regiones de Europa (static/geo/nuts2_europa.geojson)
where r.pais not in ('TR', 'IS')
