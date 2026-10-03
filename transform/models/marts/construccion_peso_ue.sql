-- Peso de la construcción (rama F de la NACE) en la economía de cada país de la UE, por año
-- (Eurostat, cuentas nacionales nama_10_a10 y nama_10_a10_e, raw.eurostat_construccion_vab /
-- _empleo; población media nama_10_pe). Una fila por país (27 + EU27_2020) y año desde 1995.
--   pct_vab_construccion: VAB de la construcción en % del VAB total a precios corrientes (PC_TOT).
--   pct_empleo_construccion: ocupados de la rama F sobre el total de ocupados (EMP_DC).
--   ocupados_constr_1000hab: ocupados de la construcción por 1.000 habitantes.
--   vab_constr_hab_eur: VAB de la construcción por habitante a precios corrientes; para España
--     también en euros constantes de anio_base (vab_constr_hab_eur_real; deflactor IPC del INE,
--     enlazado con el IPCA antes de 2002: construccion_deflactor).
--   vab_constr_real_indice_2007: VAB de la construcción en volumen (CLV10), índice 2007 = 100
--     (año de máximo de la burbuja en España), para comparar la evolución real sin mezclar precios.
--   puesto_vab / puesto_empleo: posición entre los 27 (1 = más peso de la construcción);
--     n_paises con dato ese año.
--   es_referencia: España, UE y los países con los que se compara (DE, FR, IT, PT, IE).
with vab as (
    select
        cast(anio as integer) as anio,
        pais,
        max(case when rama = 'F' and unidad = 'PC_TOT' then valor end) as pct_vab_construccion,
        max(case when rama = 'F' and unidad = 'CP_MEUR' then valor end) as vab_constr_meur,
        max(case when rama = 'TOTAL' and unidad = 'CP_MEUR' then valor end) as vab_total_meur,
        max(case when rama = 'F' and unidad = 'CLV10_MEUR' then valor end) as vab_constr_clv10
    from {{ source('raw_construccion', 'eurostat_construccion_vab') }}
    group by all
),

empleo as (
    select
        cast(anio as integer) as anio,
        pais,
        max(case when rama = 'TOTAL' then miles end) as ocupados_total_miles,
        max(case when rama = 'F' then miles end) as ocupados_constr_miles
    from {{ source('raw_construccion', 'eurostat_construccion_empleo') }}
    group by all
),

poblacion as (
    select cast(anio as integer) as anio, pais, miles as poblacion_miles
    from {{ source('raw_construccion', 'eurostat_construccion_poblacion') }}
),

base as (
    select
        v.anio,
        v.pais,
        v.pct_vab_construccion,
        100.0 * e.ocupados_constr_miles / nullif(e.ocupados_total_miles, 0) as pct_empleo_construccion,
        v.vab_constr_meur,
        v.vab_total_meur,
        e.ocupados_constr_miles,
        e.ocupados_total_miles,
        p.poblacion_miles,
        e.ocupados_constr_miles / nullif(p.poblacion_miles, 0) * 1000.0 as ocupados_constr_1000hab,
        v.vab_constr_meur * 1000.0 / nullif(p.poblacion_miles, 0) as vab_constr_hab_eur,
        100.0 * v.vab_constr_clv10
            / nullif(max(case when v.anio = 2007 then v.vab_constr_clv10 end) over (partition by v.pais), 0)
            as vab_constr_real_indice_2007
    from vab v
    left join empleo e using (anio, pais)
    left join poblacion p using (anio, pais)
),

ranking as (
    select
        *,
        case when pais <> 'EU27_2020' and pct_vab_construccion is not null then
            rank() over (partition by anio, (pais <> 'EU27_2020' and pct_vab_construccion is not null)
                         order by pct_vab_construccion desc) end as puesto_vab,
        case when pais <> 'EU27_2020' and pct_empleo_construccion is not null then
            rank() over (partition by anio, (pais <> 'EU27_2020' and pct_empleo_construccion is not null)
                         order by pct_empleo_construccion desc) end as puesto_empleo,
        count(case when pais <> 'EU27_2020' then pct_vab_construccion end) over (partition by anio) as n_paises
    from base
)

select
    r.anio,
    r.pais,
    n.pais_nombre,
    r.pais in ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT', 'IE') as es_referencia,
    r.pct_vab_construccion,
    r.pct_empleo_construccion,
    r.puesto_vab,
    r.puesto_empleo,
    r.n_paises,
    r.ocupados_constr_1000hab,
    r.vab_constr_hab_eur,
    case when r.pais = 'ES' then r.vab_constr_hab_eur * d.factor end as vab_constr_hab_eur_real,
    d.anio_base,
    r.vab_constr_real_indice_2007,
    r.vab_constr_meur,
    r.ocupados_constr_miles,
    r.ocupados_total_miles,
    r.poblacion_miles,
    -- cuota del país en el VAB de la construcción de la UE frente a su cuota de población
    100.0 * r.vab_constr_meur / nullif(ue.vab_constr_meur, 0) as cuota_vab_constr_ue_pct,
    100.0 * r.poblacion_miles / nullif(ue.poblacion_miles, 0) as cuota_poblacion_ue_pct
from ranking r
left join {{ ref('industria_paises') }} n using (pais)
left join base ue on ue.pais = 'EU27_2020' and ue.anio = r.anio
left join {{ ref('construccion_deflactor') }} d on d.anio = r.anio
where r.pct_vab_construccion is not null or r.pct_empleo_construccion is not null
