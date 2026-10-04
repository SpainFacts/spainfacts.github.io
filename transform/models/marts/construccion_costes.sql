-- Costes y precios de construcción de la vivienda nueva por país de la UE y año (Eurostat
-- sts_copi_a, raw.eurostat_construccion_costes; edificios residenciales sin residencias
-- colectivas, CPA_F41001_X_410014, 2021 = 100). Desde 1995 (UE en costes desde 2000).
--   coste_indice_2021: índice de costes de construcción (materiales y mano de obra).
--   precio_produccion_indice_2021: índice de precios de producción (lo que cobra el constructor).
--     OJO: España no publica un índice de costes propio en Eurostat; sus dos series son idénticas.
--   coste_real_indice_2021 (solo España): el índice de costes descontada la inflación general
--     (IPC del INE, enlazado con el IPCA antes de 2002; construccion_deflactor), 2021 = 100: si
--     sube, construir se encarece más que el resto de precios.
--   var_coste_anual_pct: variación del índice de costes sobre el año anterior.
-- cod_pais / pais: seed paises_iso (ISO 3166-1 alfa-2, p. ej. GR y no el EL de Eurostat; EU27_2020 la UE-27).
with base as (
    select
        cast(anio as integer) as anio,
        pais as pais_eurostat,
        max(indice) filter (where indicador = 'COST') as coste_indice_2021,
        max(indice) filter (where indicador = 'PRC_PRR') as precio_produccion_indice_2021
    from {{ source('raw_construccion', 'eurostat_construccion_costes') }}
    group by all
),

d as (
    select anio, factor, max(case when anio = 2021 then factor end) over () as factor_2021
    from {{ ref('construccion_deflactor') }}
)

select
    b.anio,
    coalesce(n.cod_pais, b.pais_eurostat) as cod_pais,
    coalesce(n.pais, b.pais_eurostat) as pais,
    coalesce(n.cod_pais, b.pais_eurostat) in ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT', 'IE') as es_referencia,
    b.coste_indice_2021,
    b.precio_produccion_indice_2021,
    case when n.cod_pais = 'ES' then b.coste_indice_2021 * d.factor / d.factor_2021 end as coste_real_indice_2021,
    100.0 * (b.coste_indice_2021 / nullif(lag(b.coste_indice_2021) over (partition by b.pais_eurostat order by b.anio), 0) - 1)
        as var_coste_anual_pct,
    n.cod_pais = 'ES' as serie_coste_es_precio
from base b
left join {{ ref('paises_iso') }} n on n.eurostat = b.pais_eurostat
left join d on d.anio = b.anio
where coalesce(b.coste_indice_2021, b.precio_produccion_indice_2021) is not null
