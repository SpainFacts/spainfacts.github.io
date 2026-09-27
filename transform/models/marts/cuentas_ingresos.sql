-- Ingresos públicos consolidados (S13) por figura, a partir de Eurostat gov_10a_taxag (impuestos y
-- cotizaciones) y gov_10a_main (ingresos totales TR). Las categorías "Otros..." y
-- "Ingresos No Tributarios" se calculan como residuo, de modo que la suma cuadra con TR.
with tax as (
    select
        cast(periodo as integer) as anio,
        max(case when na_item = 'D2' then valor end) as d2,
        max(case when na_item = 'D211' then valor end) as d211,
        max(case when na_item = 'D214A' then valor end) as d214a,
        max(case when na_item = 'D5' then valor end) as d5,
        max(case when na_item = 'D51A_C1' then valor end) as d51a,
        max(case when na_item = 'D51B_C2' then valor end) as d51b,
        max(case when na_item = 'D59A' then valor end) as d59a,
        max(case when na_item = 'D91' then valor end) as d91,
        max(case when na_item = 'D61' then valor end) as d61
    from {{ source('raw', 'eurostat_cuentas_ingresos') }}
    where unidad = 'MIO_EUR' and valor is not null
    group by 1
),

tr as (
    select cast(periodo as integer) as anio, valor as tr
    from {{ source('raw_eurostat_extra', 'eurostat_cuentas_subsectores') }}
    where sector = 'S13' and na_item = 'TR' and unidad = 'MIO_EUR' and valor is not null
),

base as (
    select *
    from tax
    join tr using (anio)
    where d2 is not null and d5 is not null and d61 is not null
),

categorias as (
    select anio, 'Cotizaciones Sociales' as categoria, 'Cotizaciones' as tipo_ingreso, d61 as millones_euros from base
    union all
    select anio, 'IRPF y Patrimonio', 'Impuestos Directos', d51a + coalesce(d59a, 0) from base
    union all
    select anio, 'Impuesto sobre Sociedades', 'Impuestos Directos', d51b from base
    union all
    select anio, 'Otros Impuestos Directos y sobre el Capital', 'Impuestos Directos',
        d5 - d51a - coalesce(d59a, 0) - d51b + coalesce(d91, 0) from base
    union all
    select anio, 'IVA', 'Impuestos Indirectos', d211 from base
    union all
    select anio, 'Impuestos Especiales', 'Impuestos Indirectos', d214a from base
    union all
    select anio, 'Otros Impuestos Indirectos', 'Impuestos Indirectos', d2 - d211 - d214a from base
    union all
    select anio, 'Ingresos No Tributarios y Fondos UE', 'No Tributarios',
        tr - d2 - d5 - coalesce(d91, 0) - d61 from base
),

pib as (
    select cast(periodo as integer) as anio, valor as pib_mio
    from {{ source('raw_eurostat_extra', 'eurostat_pib') }}
    where valor is not null
)

select
    c.anio as "año",
    c.categoria,
    c.tipo_ingreso,
    c.millones_euros,
    round(c.millones_euros / p.pib_mio * 100, 2) as porcentaje_pib,
    round(c.millones_euros / t.tr * 100, 2) as porcentaje_ingreso_total
from categorias c
join tr t using (anio)
left join pib p using (anio)
where c.millones_euros is not null
order by 1, 4 desc
