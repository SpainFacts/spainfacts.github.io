-- Alumnado matriculado en España por nivel y titularidad del centro (Eurostat, recogida
-- conjunta UNESCO-OCDE-Eurostat): educ_uoe_enra01 para todos los niveles y educ_uoe_enrs04
-- para separar la segunda etapa de secundaria (CINE 3) en general (bachillerato) y
-- profesional (FP). El año es el del final del curso (2024 = curso 2023-24).
-- Titularidad: PUB pública; PRV_DEP privada dependiente del Estado (en España, la concertada);
-- PRV_IND privada independiente.
-- por_1000_hab: alumnos por 1.000 habitantes (población a 1 de enero del año de fin de curso,
-- INE, main.poblacion_territorios).
with enra as (
    select cast(anio as integer) as anio, isced11, sector, valor
    from {{ source('raw_educacion', 'eurostat_edu_matriculados') }}
    where isced11 in ('ED0', 'ED1', 'ED2', 'ED4', 'ED5', 'ED6', 'ED7', 'ED8')
),

sec2 as (
    select cast(anio as integer) as anio, isced11, sector, valor
    from {{ source('raw_educacion', 'eurostat_edu_secundaria2') }}
    where geo = 'ES' and isced11 in ('ED34', 'ED35')
      and cast(anio as integer) >= 2013  -- mismo periodo (CINE 2011) que educ_uoe_enra01
),

todo as (
    select
        anio,
        case isced11
            when 'ED0' then 'Infantil'
            when 'ED1' then 'Primaria'
            when 'ED2' then 'ESO'
            when 'ED34' then 'Bachillerato'
            when 'ED35' then 'FP de grado medio y básica'
            when 'ED4' then 'Postsecundaria no superior'
            when 'ED5' then 'FP de grado superior'
            else 'Universidad y otros estudios superiores'
        end as nivel,
        case isced11
            when 'ED0' then 1 when 'ED1' then 2 when 'ED2' then 3 when 'ED34' then 4
            when 'ED35' then 5 when 'ED4' then 6 when 'ED5' then 7 else 8
        end as orden,
        sector,
        valor
    from (select * from enra union all select * from sec2)
),

agregado as (
    select
        anio, nivel, orden,
        sum(case when sector = 'TOT_SEC' then valor end) as alumnos,
        sum(case when sector = 'PUB' then valor end) as publica,
        sum(case when sector = 'PRV_DEP' then valor end) as concertada,
        sum(case when sector = 'PRV_IND' then valor end) as privada
    from todo
    group by all
)

select
    a.anio,
    cast(a.anio - 1 as varchar) || '-' || right(cast(a.anio as varchar), 2) as curso,
    a.nivel,
    a.orden,
    a.alumnos,
    a.publica,
    a.concertada,
    a.privada,
    100.0 * a.publica / nullif(a.alumnos, 0) as pct_publica,
    100.0 * a.concertada / nullif(a.alumnos, 0) as pct_concertada,
    100.0 * a.privada / nullif(a.alumnos, 0) as pct_privada,
    1000.0 * a.alumnos / p.poblacion as por_1000_hab
from agregado a
left join {{ ref('poblacion_territorios') }} p
    on p.nivel = 'pais' and p.cod = '00' and p.sexo = 'Total' and p.anio = a.anio
where a.alumnos is not null
