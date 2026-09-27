-- Última semana publicada para cada (nivel, clave) de embalses_semanal,
-- comparada con la misma semana ISO del año anterior y con la media de esa
-- semana en los 10 años anteriores (criterio del Boletín Hidrológico).
with serie as (
    select * from {{ ref('embalses_semanal') }}
),

ultima as (
    select * from serie
    where fecha = (select max(fecha) from serie)
),

historico as (
    select
        u.id,
        max(case when s.anio = u.anio - 1 then s.pct_llenado end) as pct_hace_un_anio,
        round(avg(case when s.anio between u.anio - 10 and u.anio - 1 then s.pct_llenado end), 1) as pct_media_10_anios
    from ultima u
    join serie s
      on s.id = u.id
     and s.semana = u.semana
     and s.anio < u.anio
    group by u.id
)

select
    u.id,
    u.nivel,
    u.clave,
    u.nombre,
    u.fecha,
    u.capacidad_hm3,
    u.volumen_hm3,
    u.pct_llenado,
    u.n_embalses,
    h.pct_hace_un_anio,
    h.pct_media_10_anios,
    round(u.pct_llenado - h.pct_hace_un_anio, 1) as dif_vs_anio_anterior,
    round(u.pct_llenado - h.pct_media_10_anios, 1) as dif_vs_media_10_anios
from ultima u
left join historico h using (id)
