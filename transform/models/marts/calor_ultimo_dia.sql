-- Situación de cada provincia en el último día con datos para (casi) toda España,
-- para el mapa y los KPI de la página.
with ultima as (
    select max(fecha) as fecha from {{ ref('calor_espana_diario') }}
),

provincias as (
    select distinct cod_prov, provincia from {{ ref('aemet_estaciones_referencia') }}
)

select
    u.fecha,
    p.cod_prov,
    p.provincia,
    d.estacion,
    d.tmax,
    d.tmin,
    d.tmax_media_historica,
    d.tmax_p90,
    d.anomalia_tmax,
    d.anomalia_tmin,
    d.categoria,
    d.supera_p90,
    d.es_record_dia,
    d.tmax_record_dia_previo,
    rank() over (order by d.anomalia_tmax desc nulls last) as rango_anomalia
from provincias as p
cross join ultima as u
left join {{ ref('calor_provincia_diario') }} as d
  on d.cod_prov = p.cod_prov and d.fecha = u.fecha
