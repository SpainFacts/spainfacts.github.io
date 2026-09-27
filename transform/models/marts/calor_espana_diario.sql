-- Resumen nacional por día: anomalía media de las provincias y cuántas están
-- por encima de lo normal. Solo días con dato en al menos 40 provincias.
select
    fecha,
    anio,
    round(avg(anomalia_tmax), 2) as anomalia_tmax_media,
    round(avg(anomalia_tmed), 2) as anomalia_tmed_media,
    round(avg(tmax), 1) as tmax_media,
    round(avg(tmax_media_historica), 1) as tmax_media_historica,
    count(anomalia_tmax) as n_provincias,
    count(*) filter (where anomalia_tmax > 1) as n_provincias_por_encima,
    count(*) filter (where supera_p90) as n_provincias_p90,
    count(*) filter (where es_record_dia) as n_records_dia
from {{ ref('calor_provincia_diario') }}
where anomalia_tmax is not null
group by fecha, anio
having count(anomalia_tmax) >= 40
