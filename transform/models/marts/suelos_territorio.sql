-- Suelo agrario de España, sus comunidades y provincias por cultivo: superficie agraria de CORINE
-- 2018 y medias de la capa arable (0-30 cm) de SoilGrids, con la textura y el grupo de suelo WRB
-- que más superficie ocupan y el porcentaje de suelos arcillosos, arenosos, básicos, ácidos y calcisoles.
with medias as (
    select
        ambito as nivel,
        case when ambito = 'pais' then '00' else cod end as cod,
        cultivo, superficie_km2, superficie_total_km2, arcilla, limo, arena, ph, carbono, mo
    from {{ source('raw_suelos', 'suelos_medias') }}
    where ambito in ('ccaa', 'provincia') or (ambito = 'pais' and cod = 'ES')
),

clases as (
    select
        ambito as nivel,
        case when ambito = 'pais' then '00' else cod end as cod,
        cultivo, dimension, clase, orden, superficie_km2
    from {{ source('raw_suelos', 'suelos_clases') }}
    where ambito in ('ccaa', 'provincia') or (ambito = 'pais' and cod = 'ES')
),

resumen as (
    select
        nivel, cod, cultivo,
        arg_max(clase, superficie_km2) filter (where dimension = 'textura') as textura_dominante,
        arg_max(clase, superficie_km2) filter (where dimension = 'textura_grupo') as grupo_textura_dominante,
        arg_max(clase, superficie_km2) filter (where dimension = 'wrb') as wrb_dominante,
        100.0 * sum(superficie_km2) filter (where dimension = 'textura_grupo' and clase = 'Arcillosa (pesada)')
            / nullif(sum(superficie_km2) filter (where dimension = 'textura_grupo'), 0) as pct_arcillosa,
        100.0 * sum(superficie_km2) filter (where dimension = 'textura_grupo' and orden >= 2)
            / nullif(sum(superficie_km2) filter (where dimension = 'textura_grupo'), 0) as pct_fuertes,
        100.0 * sum(superficie_km2) filter (where dimension = 'textura_grupo' and clase = 'Arenosa (ligera)')
            / nullif(sum(superficie_km2) filter (where dimension = 'textura_grupo'), 0) as pct_arenosa,
        100.0 * sum(superficie_km2) filter (where dimension = 'ph' and orden >= 3)
            / nullif(sum(superficie_km2) filter (where dimension = 'ph'), 0) as pct_basico,
        100.0 * sum(superficie_km2) filter (where dimension = 'ph' and orden <= 1)
            / nullif(sum(superficie_km2) filter (where dimension = 'ph'), 0) as pct_acido,
        100.0 * sum(superficie_km2) filter (where dimension = 'wrb' and clase = 'Calcisoles')
            / nullif(sum(superficie_km2) filter (where dimension = 'wrb'), 0) as pct_calcisoles
    from clases
    group by nivel, cod, cultivo
)

select
    m.nivel,
    m.cod,
    t.nombre,
    t.cod_ccaa,
    t.ruta,
    m.cultivo,
    m.superficie_km2 as superficie_agraria_km2,
    m.superficie_total_km2,
    100.0 * m.superficie_km2 / nullif(m.superficie_total_km2, 0) as pct_agraria,
    100.0 * m.superficie_km2 / nullif(max(m.superficie_km2) filter (where m.cultivo = 'Toda la superficie agraria')
        over (partition by m.nivel, m.cod), 0) as pct_de_la_agraria,
    m.arcilla as arcilla_pct,
    m.limo as limo_pct,
    m.arena as arena_pct,
    m.ph,
    m.carbono as carbono_g_kg,
    m.mo as materia_organica_pct,
    r.textura_dominante,
    r.grupo_textura_dominante,
    r.wrb_dominante,
    r.pct_fuertes,
    r.pct_arcillosa,
    r.pct_arenosa,
    r.pct_basico,
    r.pct_acido,
    r.pct_calcisoles
from medias m
left join resumen r using (nivel, cod, cultivo)
left join {{ ref('territorios') }} t on t.nivel = m.nivel and t.cod = m.cod
