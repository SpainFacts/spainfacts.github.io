-- Focos de calor NASA FIRMS dentro de España (la provincia se asigna en la ingesta).
-- La confianza se homogeneiza: VIIRS trae low/nominal/high (o l/n/h) y
-- MODIS un porcentaje 0-100 (umbrales de la documentación de FIRMS: <30 baja, >=80 alta).
select
    latitude as latitud,
    longitude as longitud,
    acq_date as fecha,
    -- acq_time es HHMM en UTC
    cast(acq_date as timestamp)
        + to_hours(cast(substr(acq_time, 1, 2) as integer))
        + to_minutes(cast(substr(acq_time, 3, 2) as integer)) as fecha_hora_utc,
    satellite as satelite,
    instrument as instrumento,
    case
        when lower(confidence) in ('h', 'high') then 'alta'
        when lower(confidence) in ('n', 'nominal') then 'media'
        when lower(confidence) in ('l', 'low') then 'baja'
        when try_cast(confidence as integer) >= 80 then 'alta'
        when try_cast(confidence as integer) >= 30 then 'media'
        when try_cast(confidence as integer) is not null then 'baja'
    end as confianza,
    frp as frp_mw,
    case when daynight = 'D' then 'Día' else 'Noche' end as dia_noche,
    cod_prov
from {{ source('raw_incendios', 'firms_focos') }}
