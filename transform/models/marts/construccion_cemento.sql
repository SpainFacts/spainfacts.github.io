-- Cemento en España por año: producción, exportaciones, importaciones y consumo aparente
-- (Banco de España, Boletín Estadístico cuadro 23.11, raw.construccion_bde_series; datos de
-- Oficemen / Ministerio de Industria). Suma de los 12 meses; solo años completos.
-- kg_hab: consumo aparente en kilos por habitante (población media anual de Eurostat nama_10_pe,
-- desde 1995; antes nulo). consumo_aparente = producción + importaciones - exportaciones.
with mensual as (
    select cast(anio as integer) as anio, serie, valor, mes
    from {{ source('raw_construccion', 'construccion_bde_series') }}
    where cuadro = 'be2311'
      and serie in ('D_1IE00000', 'D_1KB22000', 'D_1KB21000', 'D_1KB23000')
),

anual as (
    select
        anio,
        sum(valor) filter (where serie = 'D_1IE00000') as produccion_kt,
        sum(valor) filter (where serie = 'D_1KB22000') as exportaciones_kt,
        sum(valor) filter (where serie = 'D_1KB21000') as importaciones_kt,
        sum(valor) filter (where serie = 'D_1KB23000') as consumo_aparente_kt,
        count(distinct mes) filter (where serie = 'D_1KB23000') as meses
    from mensual
    group by anio
),

pob as (
    select cast(anio as integer) as anio, miles as poblacion_miles
    from {{ source('raw_construccion', 'eurostat_construccion_poblacion') }}
    where pais = 'ES'
)

select
    a.anio,
    a.consumo_aparente_kt / nullif(p.poblacion_miles, 0) * 1000.0 as consumo_kg_hab,
    a.produccion_kt / nullif(p.poblacion_miles, 0) * 1000.0 as produccion_kg_hab,
    a.consumo_aparente_kt,
    a.produccion_kt,
    a.exportaciones_kt,
    a.importaciones_kt,
    100.0 * a.exportaciones_kt / nullif(a.produccion_kt, 0) as pct_produccion_exportada,
    p.poblacion_miles
from anual a
left join pob p using (anio)
where a.meses = 12
order by a.anio
