-- Resumen anual de la liquidación consolidada de cada comunidad autónoma, en
-- euros, sobre lo ejecutado (derechos y obligaciones reconocidas netas).
-- No financieros = capítulos 1-7. saldo = ingresos - gastos (totales, 1-9);
-- saldo_no_financiero = ingresos_nf - gastos_nf (negativo = déficit) y
-- deficit_no_financiero = gastos_nf - ingresos_nf (positivo = déficit).
-- Es un saldo presupuestario, no la capacidad/necesidad de financiación en
-- contabilidad nacional (SEC) que se usa para el objetivo de déficit.
with agregado as (
    select
        anio,
        cod_ccaa,
        sum(case when tipo = 'ingreso' then ejecutado end) as ingresos_totales,
        sum(case when tipo = 'gasto' then ejecutado end) as gastos_totales,
        sum(case when tipo = 'ingreso' and capitulo <= 7 then ejecutado end) as ingresos_no_financieros,
        sum(case when tipo = 'gasto' and capitulo <= 7 then ejecutado end) as gastos_no_financieros
    from {{ ref('ccaa_cuentas_capitulos') }}
    group by anio, cod_ccaa
)

select
    anio,
    cod_ccaa,
    ingresos_totales,
    gastos_totales,
    ingresos_totales - gastos_totales as saldo,
    ingresos_no_financieros,
    gastos_no_financieros,
    ingresos_no_financieros - gastos_no_financieros as saldo_no_financiero,
    gastos_no_financieros - ingresos_no_financieros as deficit_no_financiero,
    anio || '-' || cod_ccaa as clave
from agregado
where ingresos_totales is not null and gastos_totales is not null
order by anio, cod_ccaa
