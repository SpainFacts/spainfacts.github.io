-- Una fila por (provincia, día) desde 1991: temperaturas observadas frente a la
-- normal 1991-2020 de ese día del año, y marcas de récord de la serie.
with diario as (
    select
        s.*,
        n.tmax_media as tmax_media_historica,
        n.tmax_p10,
        n.tmax_p90,
        n.tmin_media as tmin_media_historica,
        n.tmed_media as tmed_media_historica,
        -- máximo anterior de ese mismo día del año y máximo anterior absoluto
        max(s.tmax) over (
            partition by s.cod_prov, s.dia_anio order by s.fecha
            rows between unbounded preceding and 1 preceding
        ) as tmax_record_dia_previo,
        max(s.tmax) over (
            partition by s.cod_prov order by s.fecha
            rows between unbounded preceding and 1 preceding
        ) as tmax_record_previo
    from {{ ref('stg_aemet_diario') }} as s
    left join {{ ref('calor_normal_diaria') }} as n
      on n.cod_prov = s.cod_prov and n.dia_anio = s.dia_anio
)

select
    fecha,
    anio,
    dia_anio,
    cod_prov,
    provincia,
    indicativo,
    estacion,
    tmax,
    tmin,
    tmed,
    tmax_media_historica,
    tmax_p10,
    tmax_p90,
    tmin_media_historica,
    tmed_media_historica,
    round(tmax - tmax_media_historica, 1) as anomalia_tmax,
    round(tmin - tmin_media_historica, 1) as anomalia_tmin,
    round(tmed - tmed_media_historica, 1) as anomalia_tmed,
    case
        when tmax is null or tmax_media_historica is null then null
        when tmax > tmax_p90 then 'Muy por encima'
        when tmax > tmax_media_historica + 1 then 'Por encima'
        when tmax < tmax_p10 then 'Muy por debajo'
        when tmax < tmax_media_historica - 1 then 'Por debajo'
        else 'Normal'
    end as categoria,
    tmax > tmax_p90 as supera_p90,
    tmax_record_dia_previo,
    -- Los récords solo cuentan con al menos 10 años de serie previa
    coalesce(anio >= 2001 and tmax > tmax_record_dia_previo, false) as es_record_dia,
    coalesce(anio >= 2001 and tmax > tmax_record_previo, false) as es_record_absoluto
from diario
