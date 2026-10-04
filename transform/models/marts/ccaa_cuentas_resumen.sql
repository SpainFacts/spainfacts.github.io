-- Resumen anual de la liquidación consolidada de cada comunidad autónoma, en
-- euros corrientes, sobre lo ejecutado (derechos y obligaciones reconocidas netas).
-- No financieros = capítulos 1-7. saldo = ingresos - gastos (totales, 1-9);
-- saldo_no_financiero = ingresos_nf - gastos_nf (negativo = déficit).
-- Es un saldo presupuestario, no la capacidad/necesidad de financiación en
-- contabilidad nacional (SEC) que se usa para el objetivo de déficit.
-- *_eur_hab_real: por habitante (padrón del año, o el último anterior) en euros constantes
-- de anio_base (main.deflactor), para comparar entre comunidades y entre años.
with agregado as (
    select
        anio,
        cod_ccaa,
        any_value(ccaa) as ccaa,
        sum(case when tipo = 'ingreso' then ejecutado end) as ingresos_totales,
        sum(case when tipo = 'gasto' then ejecutado end) as gastos_totales,
        sum(case when tipo = 'ingreso' and capitulo <= 7 then ejecutado end) as ingresos_no_financieros,
        sum(case when tipo = 'gasto' and capitulo <= 7 then ejecutado end) as gastos_no_financieros
    from {{ ref('ccaa_cuentas_capitulos') }}
    group by anio, cod_ccaa
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

base as (
    select * from agregado
    where ingresos_totales is not null and gastos_totales is not null
)

select
    b.anio,
    b.cod_ccaa,
    b.ccaa,
    b.ingresos_totales,
    b.gastos_totales,
    b.ingresos_totales - b.gastos_totales as saldo,
    b.ingresos_no_financieros,
    b.gastos_no_financieros,
    b.ingresos_no_financieros - b.gastos_no_financieros as saldo_no_financiero,
    b.ingresos_totales * d.factor / p.poblacion as ingresos_totales_eur_hab_real,
    b.gastos_totales * d.factor / p.poblacion as gastos_totales_eur_hab_real,
    (b.ingresos_totales - b.gastos_totales) * d.factor / p.poblacion as saldo_eur_hab_real,
    b.ingresos_no_financieros * d.factor / p.poblacion as ingresos_nf_eur_hab_real,
    b.gastos_no_financieros * d.factor / p.poblacion as gastos_nf_eur_hab_real,
    (b.ingresos_no_financieros - b.gastos_no_financieros) * d.factor / p.poblacion as saldo_nf_eur_hab_real,
    d.anio_base,
    b.anio || '-' || b.cod_ccaa as clave
from base as b
asof left join pob as p
  on p.cod = b.cod_ccaa and p.anio <= b.anio
left join {{ ref('deflactor') }} as d
  on d.anio = cast(b.anio as integer)
order by b.anio, b.cod_ccaa
