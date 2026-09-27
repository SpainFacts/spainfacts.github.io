-- Ingresos, gastos y saldo por subsector de las AAPP (Eurostat gov_10a_main). Datos NO consolidados
-- entre subsectores: la suma de subsectores supera el total S13 por las transferencias internas.
-- peso_gasto_pct = gasto del subsector / gasto consolidado del total AAPP.
with base as (
    select
        cast(periodo as integer) as anio,
        sector,
        max(case when na_item = 'TE' then valor end) as te,
        max(case when na_item = 'TR' then valor end) as tr,
        max(case when na_item = 'B9' then valor end) as b9
    from {{ source('raw_eurostat_extra', 'eurostat_cuentas_subsectores') }}
    where unidad = 'MIO_EUR' and valor is not null
    group by 1, 2
),

total as (
    select anio, te as te_total from base where sector = 'S13'
)

select
    b.anio as "año",
    case b.sector
        when 'S1311' then 'Administración Central'
        when 'S1312' then 'Comunidades Autónomas'
        when 'S1313' then 'Corporaciones Locales'
        when 'S1314' then 'Seguridad Social'
    end as subsector,
    b.sector as cod_sector,
    round(b.te / 1000.0, 2) as gasto_mrd,
    round(b.tr / 1000.0, 2) as ingreso_mrd,
    round(b.b9 / 1000.0, 2) as saldo_deficit_mrd,
    round(b.te / t.te_total * 100, 2) as peso_gasto_pct
from base b
join total t using (anio)
where b.sector in ('S1311', 'S1312', 'S1313', 'S1314')
  and b.te is not null
order by 1, 4 desc
