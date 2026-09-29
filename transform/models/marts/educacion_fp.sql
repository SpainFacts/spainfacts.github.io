-- Peso de la formación profesional en la segunda etapa de secundaria (Eurostat educ_uoe_enrs04),
-- España y UE-27: alumnos en programas profesionales (CINE 35: en España, FP de grado medio y
-- FP básica) sobre el total de la etapa (CINE 3: también bachillerato), en %.
-- El año es el del final del curso (2024 = curso 2023-24). Desde 2013 (CINE 2011).
select
    cast(anio as integer) as anio,
    case geo when 'ES' then 'pais' else 'ue' end as nivel,
    max(case when isced11 = 'ED35' then valor end) as alumnos_fp,
    max(case when isced11 = 'ED3' then valor end) as alumnos_etapa,
    100.0 * max(case when isced11 = 'ED35' then valor end)
        / nullif(max(case when isced11 = 'ED3' then valor end), 0) as pct_fp
from {{ source('raw_educacion', 'eurostat_edu_secundaria2') }}
where sector = 'TOT_SEC'
  and cast(anio as integer) >= 2013  -- antes de 2013 la clasificación era CINE 1997 y la serie no es comparable
group by all
having max(case when isced11 = 'ED35' then valor end) is not null
   and max(case when isced11 = 'ED3' then valor end) is not null
