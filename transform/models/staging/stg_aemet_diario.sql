-- Una fila por (provincia, día): serie de temperaturas de la estación de
-- referencia de cada provincia. Si una provincia tiene varias estaciones en la
-- semilla, cada día se toma la de menor prioridad que tenga temperatura máxima
-- (empalme de cambios de indicativo, p. ej. Santander 1109 -> 1109X).
with datos as (
    select
        d.fecha,
        e.cod_prov,
        e.provincia,
        e.indicativo,
        e.estacion,
        e.prioridad,
        d.tmax,
        d.tmin,
        d.tmed
    from {{ source('raw_aemet', 'aemet_diario') }} as d
    join {{ ref('aemet_estaciones_referencia') }} as e
      on e.indicativo = d.indicativo
    where d.tmax is not null or d.tmin is not null
)

select
    fecha,
    cod_prov,
    provincia,
    indicativo,
    estacion,
    tmax,
    tmin,
    coalesce(tmed, (tmax + tmin) / 2) as tmed,
    extract(year from fecha)::integer as anio,
    -- Día del año en un año no bisiesto (el 29 de febrero cuenta como el 28)
    dayofyear(make_date(2001, month(fecha), case when month(fecha) = 2 and day(fecha) = 29 then 28 else day(fecha) end))::integer as dia_anio
from datos
qualify row_number() over (partition by cod_prov, fecha order by (tmax is null), prioridad) = 1
