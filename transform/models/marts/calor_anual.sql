-- Anomalía anual en España: media de las provincias de su anomalía media anual
-- (y de verano, junio-agosto) y días al año por encima de lo normal.
with provincia_anio as (
    select
        anio,
        cod_prov,
        avg(anomalia_tmax) as anomalia_tmax,
        avg(anomalia_tmed) as anomalia_tmed,
        avg(anomalia_tmax) filter (where month(fecha) between 6 and 8) as anomalia_tmax_verano,
        count(*) filter (where anomalia_tmax > 1) as dias_por_encima,
        count(*) filter (where supera_p90) as dias_p90,
        count(*) filter (where es_record_dia) as records_dia,
        count(anomalia_tmax) as dias_con_dato,
        max(fecha) as ultima_fecha
    from {{ ref('calor_provincia_diario') }}
    group by anio, cod_prov
    -- se descartan provincia-años con muchos huecos
    having count(anomalia_tmax) >= 0.8 * (max(dia_anio) - min(dia_anio) + 1)
)

select
    anio,
    round(avg(anomalia_tmax), 2) as anomalia_tmax,
    round(avg(anomalia_tmed), 2) as anomalia_tmed,
    round(avg(anomalia_tmax_verano), 2) as anomalia_tmax_verano,
    round(avg(dias_por_encima), 0) as dias_por_encima,
    round(avg(dias_p90), 0) as dias_p90,
    sum(records_dia) as records_dia,
    count(*) as n_provincias,
    max(ultima_fecha) as ultima_fecha,
    max(ultima_fecha) >= make_date(anio, 12, 28) as anio_completo
from provincia_anio
group by anio
