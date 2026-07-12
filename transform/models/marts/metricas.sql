-- Modelo largo de métricas: una fila por (metrica_id, periodo).
-- Es la tabla que consumen las fichas de indicador de Evidence
-- (pages/indicadores/[metrica_id].md). Añadir una métrica nueva =
-- una fila en el seed metricas_catalogo + su rama aquí si viene de
-- una fuente nueva.

with catalogo as (
    select * from {{ ref('metricas_catalogo') }}
),

ine as (
    select c.metrica_id, s.date as periodo, s.value as valor
    from (
        select cod_serie, date, value from {{ ref('stg_ine_ipc') }}
        union all
        select cod_serie, date, value from {{ ref('stg_ine_paro') }}
    ) s
    join catalogo c on c.cod_serie = s.cod_serie
),

deuda as (
    select
        case unidad when 'MIO_EUR' then 'deuda_publica' else 'deuda_publica_pib' end as metrica_id,
        periodo,
        valor
    from {{ ref('stg_eurostat_deuda') }}
)

select
    m.metrica_id,
    c.nombre,
    m.periodo,
    m.valor,
    c.unidad,
    c.fuente,
    c.url_fuente
from (
    select * from ine
    union all
    select * from deuda
) m
join catalogo c using (metrica_id)
