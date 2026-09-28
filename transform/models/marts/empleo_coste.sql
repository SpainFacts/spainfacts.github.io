-- Remuneración de asalariados de las AAPP (D1PAY: sueldos + cotizaciones
-- sociales a cargo del empleador), total y por subsector, anual desde 1995
-- (Eurostat gov_10a_main, contabilidad nacional SEC 2010). Millones de euros y % del PIB.
with base as (
    select
        cast(periodo as integer) as anio,
        sector,
        max(valor) filter (where unidad = 'MIO_EUR') as millones_eur,
        max(valor) filter (where unidad = 'PC_GDP') as pct_pib
    from {{ source('raw_eurostat_extra', 'eurostat_cuentas_subsectores') }}
    where na_item = 'D1PAY' and valor is not null
    group by 1, 2
),

poblacion as (
    select cast(periodo as integer) as anio, valor * 1000 as habitantes
    from {{ source('raw_eurostat_extra', 'eurostat_poblacion') }}
)

select
    b.anio,
    b.sector as cod_sector,
    case b.sector
        when 'S13' then 'Total AAPP'
        when 'S1311' then 'Administración central'
        when 'S1312' then 'Comunidades autónomas'
        when 'S1313' then 'Corporaciones locales'
        when 'S1314' then 'Seguridad Social'
    end as subsector,
    b.millones_eur,
    b.pct_pib,
    b.millones_eur * 1e6 / p.habitantes as eur_por_habitante
from base b
left join poblacion p using (anio)
