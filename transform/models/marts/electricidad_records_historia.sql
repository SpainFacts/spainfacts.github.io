{{ config(materialized='table') }}
-- Cada vez que se batió un récord: para cada métrica, sistema y periodo, los días
-- cuyo mejor valor supera al mejor de todos los días anteriores (máximo o mínimo
-- según la métrica). valor_anterior/ts_anterior es el récord que se batió.
-- es_inicio_serie marca el primer año de cada serie, en el que casi todo es
-- "récord" porque apenas hay historia: conviene filtrarlo en las visualizaciones.
with e as (
    select
        *,
        case when sentido = 'max' then valor else -valor end as puntos
    from {{ ref('electricidad_extremos_diarios') }}
),

r as (
    select
        *,
        max(puntos) over (
            partition by codigo, sistema, periodo order by fecha
            rows between unbounded preceding and 1 preceding
        ) as mejor_previo,
        min(fecha) over (partition by codigo, sistema, periodo) as inicio_serie
    from e
),

batidos as (
    select * from r
    where mejor_previo is null or puntos > mejor_previo
)

select
    codigo,
    categoria,
    sentido,
    sistema,
    periodo,
    fecha,
    valor,
    unidad,
    ts_local,
    ts_utc,
    lag(valor) over w as valor_anterior,
    lag(ts_local) over w as ts_anterior,
    valor - lag(valor) over w as mejora,
    inicio_serie,
    fecha < inicio_serie + interval 365 day as es_inicio_serie,
    row_number() over w as n_record,
    orden
from batidos
window w as (partition by codigo, sistema, periodo order by fecha)
