-- Normal climatológica diaria 1991-2020 de cada provincia: para cada día del año
-- se usan los datos de ese día ±7 días (ventana de 15 días) de los 30 años,
-- lo que suaviza la curva sin borrar el ciclo estacional (~450 observaciones).
with base as (
    select cod_prov, dia_anio, tmax, tmin, tmed
    from {{ ref('stg_aemet_diario') }}
    where anio between 1991 and 2020
),

ventana as (
    select
        cod_prov,
        ((dia_anio - 1 + desfase + 365) % 365) + 1 as dia_anio,
        tmax,
        tmin,
        tmed
    from base
    cross join range(-7, 8) as r(desfase)
),

normal as (
    select
        cod_prov,
        dia_anio::integer as dia_anio,
        avg(tmax) as tmax_media,
        quantile_cont(tmax, 0.10) as tmax_p10,
        quantile_cont(tmax, 0.90) as tmax_p90,
        avg(tmin) as tmin_media,
        avg(tmed) as tmed_media,
        count(tmax) as n_obs
    from ventana
    group by 1, 2
)

select
    cod_prov,
    dia_anio,
    strftime(make_date(2001, 1, 1) + (dia_anio - 1) * interval 1 day, '%d/%m') as dia_mes,
    round(tmax_media, 2) as tmax_media,
    round(tmax_p10, 2) as tmax_p10,
    round(tmax_p90, 2) as tmax_p90,
    round(tmin_media, 2) as tmin_media,
    round(tmed_media, 2) as tmed_media,
    n_obs
from normal
-- al menos ~10 años de datos en la ventana para dar la normal por buena
where n_obs >= 150
