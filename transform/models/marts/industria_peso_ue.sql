-- Peso de la industria en la economía de cada país de la UE, por año (Eurostat, cuentas
-- nacionales nama_10_a10 y nama_10_a10_e, raw.eurostat_industria_vab / _empleo; población
-- nama_10_pe). Una fila por país (27 + EU27_2020) y año desde 1995.
--   pct_vab_industria / pct_vab_manufacturas: VAB de la industria (B-E) y de las manufacturas (C)
--     en % del VAB total, a precios corrientes (unidad PC_TOT de Eurostat).
--   pct_empleo_*: ocupados de la rama sobre el total de ocupados.
--   vab_manuf_hab_eur: VAB manufacturero por habitante a precios corrientes (euros); para España
--     también en euros constantes de anio_base (main.deflactor, IPC del INE).
--   vab_manuf_real_indice: VAB manufacturero en volumen (CLV10), índice 2015 = 100, para comparar
--     la evolución real de cada país sin mezclar precios.
--   puesto_*: posición entre los 27 (1 = más peso de la industria), n_paises con dato ese año.
--   es_referencia: España, UE y los países con los que se compara en la página (DE, FR, IT, PL, PT).
with vab as (
    select
        cast(anio as integer) as anio,
        pais,
        max(case when rama = 'B-E' and unidad = 'PC_TOT' then valor end) as pct_vab_industria,
        max(case when rama = 'C' and unidad = 'PC_TOT' then valor end) as pct_vab_manufacturas,
        max(case when rama = 'C' and unidad = 'CP_MEUR' then valor end) as vab_manuf_meur,
        max(case when rama = 'B-E' and unidad = 'CP_MEUR' then valor end) as vab_industria_meur,
        max(case when rama = 'C' and unidad = 'CLV10_MEUR' then valor end) as vab_manuf_clv10
    from {{ source('raw_industria', 'eurostat_industria_vab') }}
    group by all
),

empleo as (
    select
        cast(anio as integer) as anio,
        pais,
        max(case when rama = 'TOTAL' then miles end) as ocupados_total_miles,
        max(case when rama = 'B-E' then miles end) as ocupados_industria_miles,
        max(case when rama = 'C' then miles end) as ocupados_manuf_miles
    from {{ source('raw_industria', 'eurostat_industria_empleo') }}
    group by all
),

poblacion as (
    select cast(anio as integer) as anio, pais, miles as poblacion_miles
    from {{ source('raw_industria', 'eurostat_industria_poblacion') }}
),

base as (
    select
        v.anio,
        v.pais,
        v.pct_vab_industria,
        v.pct_vab_manufacturas,
        100.0 * e.ocupados_industria_miles / nullif(e.ocupados_total_miles, 0) as pct_empleo_industria,
        100.0 * e.ocupados_manuf_miles / nullif(e.ocupados_total_miles, 0) as pct_empleo_manufacturas,
        v.vab_industria_meur,
        v.vab_manuf_meur,
        e.ocupados_manuf_miles,
        p.poblacion_miles,
        v.vab_manuf_meur * 1000.0 / nullif(p.poblacion_miles, 0) as vab_manuf_hab_eur,
        100.0 * v.vab_manuf_clv10
            / nullif(max(case when v.anio = 2015 then v.vab_manuf_clv10 end) over (partition by v.pais), 0)
            as vab_manuf_real_indice
    from vab v
    left join empleo e using (anio, pais)
    left join poblacion p using (anio, pais)
),

ranking as (
    select
        *,
        case when pais <> 'EU27_2020' and pct_vab_manufacturas is not null then
            rank() over (partition by anio, (pais <> 'EU27_2020' and pct_vab_manufacturas is not null)
                         order by pct_vab_manufacturas desc) end as puesto_manufacturas,
        case when pais <> 'EU27_2020' and pct_vab_industria is not null then
            rank() over (partition by anio, (pais <> 'EU27_2020' and pct_vab_industria is not null)
                         order by pct_vab_industria desc) end as puesto_industria,
        count(case when pais <> 'EU27_2020' then pct_vab_manufacturas end) over (partition by anio) as n_paises
    from base
)

select
    r.anio,
    r.pais,
    n.pais_nombre,
    r.pais in ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PL', 'PT') as es_referencia,
    r.pct_vab_industria,
    r.pct_vab_manufacturas,
    r.pct_empleo_industria,
    r.pct_empleo_manufacturas,
    r.puesto_industria,
    r.puesto_manufacturas,
    r.n_paises,
    r.vab_industria_meur,
    r.vab_manuf_meur,
    r.ocupados_manuf_miles,
    r.poblacion_miles,
    r.vab_manuf_hab_eur,
    case when r.pais = 'ES' then r.vab_manuf_hab_eur * d.factor end as vab_manuf_hab_eur_real,
    d.anio_base,
    r.vab_manuf_real_indice,
    -- cuota del país en el VAB manufacturero y en la población de la UE (mismo año)
    100.0 * r.vab_manuf_meur / nullif(ue.vab_manuf_meur, 0) as cuota_vab_manuf_ue_pct,
    100.0 * r.poblacion_miles / nullif(ue.poblacion_miles, 0) as cuota_poblacion_ue_pct
from ranking r
left join {{ ref('industria_paises') }} n using (pais)
left join base ue on ue.pais = 'EU27_2020' and ue.anio = r.anio
left join {{ ref('deflactor') }} d on d.anio = r.anio
where r.pct_vab_manufacturas is not null or r.pct_vab_industria is not null
