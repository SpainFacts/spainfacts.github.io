-- Suelo agrario de cada país europeo con el mismo método que España (SoilGrids sobre la
-- superficie agraria de CORINE 2018): medias de la capa arable y % de suelos arcillosos,
-- arenosos, básicos y ácidos, con el puesto en cada indicador.
with m as (
    select p.cod_pais, p.pais, p.es_ue, s.*
    from {{ source('raw_suelos', 'suelos_medias') }} s
    join {{ ref('paises_iso') }} p on p.eurostat = s.cod
    where s.ambito = 'pais' and s.cultivo = 'Toda la superficie agraria' and s.superficie_km2 >= 1000
),

c as (
    select
        cod,
        100.0 * sum(superficie_km2) filter (where dimension = 'textura_grupo' and clase = 'Arcillosa (pesada)')
            / nullif(sum(superficie_km2) filter (where dimension = 'textura_grupo'), 0) as pct_arcillosa,
        100.0 * sum(superficie_km2) filter (where dimension = 'textura_grupo' and clase = 'Arenosa (ligera)')
            / nullif(sum(superficie_km2) filter (where dimension = 'textura_grupo'), 0) as pct_arenosa,
        100.0 * sum(superficie_km2) filter (where dimension = 'ph' and orden >= 3)
            / nullif(sum(superficie_km2) filter (where dimension = 'ph'), 0) as pct_basico,
        100.0 * sum(superficie_km2) filter (where dimension = 'ph' and orden <= 1)
            / nullif(sum(superficie_km2) filter (where dimension = 'ph'), 0) as pct_acido,
        arg_max(clase, superficie_km2) filter (where dimension = 'wrb') as wrb_dominante,
        arg_max(clase, superficie_km2) filter (where dimension = 'textura') as textura_dominante
    from {{ source('raw_suelos', 'suelos_clases') }}
    where ambito = 'pais' and cultivo = 'Toda la superficie agraria'
    group by cod
)

select
    m.cod_pais,
    m.pais,
    m.es_ue,
    m.superficie_km2 as superficie_agraria_km2,
    m.arcilla as arcilla_pct,
    m.limo as limo_pct,
    m.arena as arena_pct,
    m.ph,
    m.carbono as carbono_g_kg,
    m.mo as materia_organica_pct,
    c.pct_arcillosa,
    c.pct_arenosa,
    c.pct_basico,
    c.pct_acido,
    c.wrb_dominante,
    c.textura_dominante,
    rank() over (order by m.mo) as puesto_mo_menor,
    rank() over (order by m.ph desc) as puesto_ph_mayor,
    rank() over (order by c.pct_arcillosa desc) as puesto_arcillosa,
    count(*) over () as paises
from m
join c on c.cod = m.cod
