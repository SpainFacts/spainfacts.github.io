{{ config(materialized='table') }}
-- Récord vigente de cada métrica, sistema y periodo ('5 min' instantáneo, 'hora'
-- media horaria, 'día' energía o media diaria), con el récord anterior al que batió,
-- los días que lleva vigente y si se ha batido en los últimos 30 días.
-- Los récords instantáneos por frontera solo cubren desde finales de 2024 (antes el
-- visor solo daba el saldo neto); los horarios y diarios usan hasta entonces el saldo
-- neto telemedido por frontera de ESIOS. Se indica en `nota`.
with h as (
    select *, row_number() over (partition by codigo, sistema, periodo order by fecha desc) as rn
    from {{ ref('electricidad_records_historia') }}
)

select
    codigo,
    categoria,
    sistema,
    case sistema when 'peninsula' then 'Península' when 'baleares' then 'Baleares' when 'canarias' then 'Canarias' end as sistema_nombre,
    periodo,
    valor,
    unidad,
    ts_local as ts,
    ts_utc,
    fecha,
    valor_anterior,
    ts_anterior,
    n_record - 1 as veces_batido,
    inicio_serie,
    date_diff('day', fecha, current_date) as dias_vigente,
    date_diff('day', fecha, current_date) <= 30 as reciente,
    case
        when (codigo like 'imp\_%' escape '\' or codigo like 'exp\_%' escape '\') and periodo = '5 min'
            then 'El visor de REE desglosa por frontera solo desde ' || strftime(inicio_serie, '%m/%Y')
        when codigo like 'imp\_%' escape '\' or codigo like 'exp\_%' escape '\'
            then 'Hasta finales de 2024, saldo neto horario telemedido por frontera (ESIOS)'
        when codigo like 'baterias%' then 'Serie de baterías desde ' || strftime(inicio_serie, '%m/%Y')
        when codigo in ('consumo_bombeo_max', 'turbinacion_bombeo_max')
            then 'REE desglosa el bombeo desde ' || strftime(inicio_serie, '%m/%Y') || '; antes va neto dentro de la hidráulica'
        when codigo like 'precio%' then 'Precio spot del mercado diario (OMIE), media ' || case when periodo = 'hora' then 'horaria' else 'diaria' end
    end as nota,
    orden
from h
where rn = 1
