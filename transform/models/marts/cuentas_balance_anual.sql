-- Balance anual consolidado de las AAPP de España (S13) a partir de datos oficiales de Eurostat:
-- ingresos (TR), gastos (TE) y saldo (B9) de gov_10a_main; deuda PDE a cierre de año (Q4) de
-- gov_10q_ggdebt; población media de nama_10_pe.
with main as (
    select
        cast(periodo as integer) as anio,
        max(case when na_item = 'TR' and unidad = 'MIO_EUR' then valor end) as ingresos_mio,
        max(case when na_item = 'TE' and unidad = 'MIO_EUR' then valor end) as gastos_mio,
        max(case when na_item = 'B9' and unidad = 'MIO_EUR' then valor end) as saldo_mio,
        max(case when na_item = 'B9' and unidad = 'PC_GDP' then valor end) as saldo_pib
    from {{ source('raw_eurostat_extra', 'eurostat_cuentas_subsectores') }}
    where sector = 'S13' and valor is not null
    group by 1
),

deuda as (
    select
        cast(left(periodo, 4) as integer) as anio,
        max(case when unidad = 'MIO_EUR' then valor end) as deuda_mio,
        max(case when unidad = 'PC_GDP' then valor end) as deuda_pib
    from {{ source('raw', 'eurostat_deuda') }}
    where periodo like '%-Q4' and valor is not null
    group by 1
),

poblacion as (
    select cast(periodo as integer) as anio, valor / 1000.0 as poblacion_m
    from {{ source('raw_eurostat_extra', 'eurostat_poblacion') }}
    where valor is not null
)

select
    m.anio as "año",
    round(m.ingresos_mio / 1000.0, 2) as ingresos_totales_mrd,
    round(m.gastos_mio / 1000.0, 2) as gastos_totales_mrd,
    round(m.saldo_mio / 1000.0, 2) as saldo_deficit_mrd,
    m.saldo_pib as saldo_deficit_pib,
    round(d.deuda_mio / 1000.0, 2) as deuda_publica_mrd,
    d.deuda_pib,
    round(p.poblacion_m, 3) as poblacion_m
from main m
left join deuda d using (anio)
left join poblacion p using (anio)
where m.ingresos_mio is not null and m.gastos_mio is not null
order by 1
