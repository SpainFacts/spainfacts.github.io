-- Estado de cada embalse en la última semana publicada, hace un año y frente a
-- lo habitual: media de la misma semana ISO en los 10 años anteriores (mismo
-- criterio que embalses_estado_actual, pero por embalse). Con menos de 5 años
-- de historia en esa semana no se calcula lo habitual: sería poco representativo.
with base as (
    select * from {{ ref('stg_miteco_embalses') }}
),

ultima as (
    select * from base where fecha = (select max(fecha) from base)
),

habitual as (
    select
        u.embalse,
        u.cuenca,
        round(avg(100 * h.volumen_hm3 / h.capacidad_hm3), 1) as pct_habitual,
        count(*) as anios_habitual
    from ultima u
    join base h
      on h.embalse = u.embalse
     and h.cuenca = u.cuenca
     and h.semana = u.semana
     and h.anio between u.anio - 10 and u.anio - 1
    group by all
)

select
    u.fecha,
    u.cuenca,
    u.cod_demarcacion,
    u.embalse,
    u.uso_electrico,
    u.capacidad_hm3,
    u.volumen_hm3,
    round(100 * u.volumen_hm3 / u.capacidad_hm3, 1) as pct_llenado,
    round(100 * a.volumen_hm3 / a.capacidad_hm3, 1) as pct_hace_un_anio,
    case when h.anios_habitual >= 5 then h.pct_habitual end as pct_habitual,
    case when h.anios_habitual >= 5
         then round(100 * u.volumen_hm3 / u.capacidad_hm3 - h.pct_habitual, 1)
    end as dif_vs_habitual,
    -- coordenadas: OSM/Wikidata casadas por nombre (seed embalses_coordenadas)
    g.lat,
    g.lon
from ultima u
left join base a
  on a.embalse = u.embalse
 and a.cuenca = u.cuenca
 and a.anio = u.anio - 1
 and a.semana = u.semana
left join habitual h
  on h.embalse = u.embalse
 and h.cuenca = u.cuenca
left join {{ ref('embalses_coordenadas') }} g
  on g.embalse = u.embalse
 and g.cuenca = u.cuenca
