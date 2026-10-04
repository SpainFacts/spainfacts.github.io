-- Gasto público consolidado (S13) por función COFOG, Eurostat gov_10a_exp (MIO_EUR),
-- agrupado en las funciones que muestra la web. Los intereses de la deuda (GF0107) se separan
-- de Servicios Públicos Generales (GF01). % PIB con nama_10_gdp y por habitante con nama_10_pe.
with cofog as (
    select cast(periodo as integer) as anio, cofog99, valor
    from {{ source('raw', 'eurostat_cuentas_gastos') }}
    where na_item = 'TE' and unidad = 'MIO_EUR' and valor is not null
),

funciones as (
    select
        anio,
        case
            when cofog99 = 'GF10' then 'Protección Social y Pensiones'
            when cofog99 = 'GF07' then 'Sanidad Pública'
            when cofog99 = 'GF09' then 'Educación'
            when cofog99 = 'GF01' then 'Servicios Públicos Generales'
            when cofog99 = 'GF0107' then 'Intereses de la Deuda'
            when cofog99 = 'GF04' then 'Asuntos Económicos y Transporte'
            when cofog99 = 'GF03' then 'Orden Público y Seguridad'
            when cofog99 = 'GF02' then 'Defensa'
            when cofog99 in ('GF05', 'GF06') then 'Vivienda y Medio Ambiente'
            when cofog99 = 'GF08' then 'Cultura, Ocio y Religión'
        end as funcion_cofog,
        cofog99,
        valor
    from cofog
    where cofog99 in ('GF01', 'GF0107', 'GF02', 'GF03', 'GF04', 'GF05', 'GF06', 'GF07', 'GF08', 'GF09', 'GF10')
),

ajustado as (
    select anio, funcion_cofog, sum(valor) as millones_euros
    from (
        select anio, funcion_cofog, valor from funciones
        union all
        -- GF0107 (intereses) forma parte de GF01: se resta para no contarlo dos veces
        select anio, 'Servicios Públicos Generales' as funcion_cofog, -valor as valor
        from funciones
        where cofog99 = 'GF0107'
    ) f
    group by 1, 2
),

total as (
    select anio, valor as total_mio from cofog where cofog99 = 'TOTAL'
),

pib as (
    select cast(periodo as integer) as anio, valor as pib_mio
    from {{ source('raw_eurostat_extra', 'eurostat_pib') }}
    where valor is not null
),

poblacion as (
    select cast(periodo as integer) as anio, valor * 1000.0 as habitantes
    from {{ source('raw_eurostat_extra', 'eurostat_poblacion') }}
    where valor is not null
)

select
    a.anio,
    a.funcion_cofog,
    case a.funcion_cofog
        when 'Protección Social y Pensiones' then 'Gasto Social'
        when 'Sanidad Pública' then 'Gasto Social'
        when 'Educación' then 'Gasto Social'
        when 'Servicios Públicos Generales' then 'Administración'
        when 'Intereses de la Deuda' then 'Carga Financiera'
        when 'Asuntos Económicos y Transporte' then 'Economía e Infraestructuras'
        when 'Orden Público y Seguridad' then 'Seguridad y Justicia'
        when 'Defensa' then 'Defensa'
        else 'Servicios Comunitarios'
    end as categoria_macro,
    a.millones_euros,
    round(a.millones_euros / p.pib_mio * 100, 2) as porcentaje_pib,
    round(a.millones_euros / t.total_mio * 100, 2) as porcentaje_gasto_total,
    f.anio_base,
    round(a.millones_euros * 1e6 * f.factor / h.habitantes, 0) as gasto_eur_hab_real
from ajustado a
left join {{ ref('deflactor') }} f using (anio)
join total t using (anio)
left join pib p using (anio)
left join poblacion h using (anio)
order by 1, 4 desc
