-- Estado de cada embalse en la última semana publicada y hace un año.
with base as (
    select * from {{ ref('stg_miteco_embalses') }}
),

ultima as (
    select * from base where fecha = (select max(fecha) from base)
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
    round(100 * a.volumen_hm3 / a.capacidad_hm3, 1) as pct_hace_un_anio
from ultima u
left join base a
  on a.embalse = u.embalse
 and a.cuenca = u.cuenca
 and a.anio = u.anio - 1
 and a.semana = u.semana
