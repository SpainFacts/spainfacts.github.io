-- Modelo largo de métricas: una fila por (metrica_id, periodo).
-- Es la tabla que consumen las fichas de indicador de Evidence
-- (pages/indicadores/[metrica_id].md).

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
),

cuentas_balance as (
    select
        case concepto
            when 'ingresos_totales' then 'ingreso_publico_total'
            when 'gastos_totales' then 'gasto_publico_total'
            when 'saldo_deficit' then 'saldo_deficit_publico'
            else null
        end as metrica_id,
        periodo,
        millones_euros as valor
    from {{ ref('stg_eurostat_cuentas_balance') }}
    where concepto in ('ingresos_totales', 'gastos_totales', 'saldo_deficit')
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
    union all
    select * from cuentas_balance
) m
join catalogo c using (metrica_id)
