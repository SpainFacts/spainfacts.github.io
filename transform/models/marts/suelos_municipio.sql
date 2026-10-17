-- Suelo agrario de cada municipio por cultivo: superficie agraria de CORINE 2018 (muestras de
-- 250 m dentro del término) y medias de la capa arable de SoilGrids, con las clases dominantes
-- y el % de tierras fuertes, arcillosas, arenosas, básicas, ácidas y calcisoles.
with nombres as (
    select cod_mun, municipio, cod_prov, cod_ccaa
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
)

select
    s.cod_mun,
    n.municipio,
    coalesce(n.cod_prov, left(s.cod_mun, 2)) as cod_prov,
    n.cod_ccaa,
    s.cultivo,
    s.superficie_total_km2,
    s.superficie_km2 as superficie_agraria_km2,
    100.0 * s.superficie_km2 / nullif(s.superficie_total_km2, 0) as pct_agraria,
    100.0 * s.superficie_km2 / nullif(max(s.superficie_km2) filter (where s.cultivo = 'Toda la superficie agraria')
        over (partition by s.cod_mun), 0) as pct_de_la_agraria,
    s.arcilla as arcilla_pct,
    s.limo as limo_pct,
    s.arena as arena_pct,
    s.ph,
    s.carbono as carbono_g_kg,
    s.mo as materia_organica_pct,
    s.textura_dominante,
    s.grupo_textura_dominante,
    s.wrb_dominante,
    s.pct_fuertes,
    s.pct_arcillosa,
    s.pct_arenosa,
    s.pct_basico,
    s.pct_acido,
    s.pct_calcisoles,
    '/territorios/municipios?m=' || s.cod_mun as enlace
from {{ source('raw_suelos', 'suelos_municipio') }} s
left join nombres n using (cod_mun)
