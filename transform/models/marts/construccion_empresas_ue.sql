-- Empresas de la construcción por país de la UE, rama y año (Eurostat, estadísticas estructurales
-- de empresas sbs_ovw_act, raw.eurostat_construccion_sbs; 2021-último). Ramas F (total), F41
-- (edificios), F42 (ingeniería civil) y F43 (construcción especializada).
--   empresas_1000hab: empresas por 1.000 habitantes (población media nama_10_pe).
--   ocupados_por_empresa: tamaño medio = personas ocupadas / empresas (Eurostat solo publica el
--     tamaño medio redondeado a entero, por eso se recalcula).
--   productividad_miles_eur: valor añadido por persona ocupada (LABPRY_TEUR, miles de euros corrientes).
--   cifra_negocios_hab_eur: cifra de negocios neta por habitante (euros corrientes); España también
--     en euros constantes (cifra_negocios_hab_eur_real, construccion_deflactor).
--   cuota_*_ue_pct: % del agregado EU27_2020; puesto_empresas_1000hab entre los 27 con dato.
-- El número de empresas de España por sector y comunidad del INE (DIRCE) está en el mart
-- empresas_dirce_sector (sector 'Construcción').
with base as (
    select
        cast(anio as integer) as anio,
        pais,
        rama,
        max(valor) filter (where indicador = 'ENT_NR') as empresas,
        max(valor) filter (where indicador = 'EMP_NR') as ocupados,
        max(valor) filter (where indicador = 'NETTUR_MEUR') as cifra_negocios_meur,
        max(valor) filter (where indicador = 'AV_MEUR') as valor_anadido_meur,
        max(valor) filter (where indicador = 'LABPRY_TEUR') as productividad_miles_eur
    from {{ source('raw_construccion', 'eurostat_construccion_sbs') }}
    group by all
),

pob as (
    select cast(anio as integer) as anio, pais, miles as poblacion_miles
    from {{ source('raw_construccion', 'eurostat_construccion_poblacion') }}
),

calc as (
    select
        b.*,
        b.empresas / nullif(p.poblacion_miles, 0) as empresas_1000hab,
        b.ocupados / nullif(b.empresas, 0) as ocupados_por_empresa,
        b.cifra_negocios_meur * 1000.0 / nullif(p.poblacion_miles, 0) as cifra_negocios_hab_eur,
        p.poblacion_miles
    from base b
    left join pob p using (anio, pais)
)

select
    c.anio,
    c.pais,
    n.pais_nombre,
    c.pais in ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT', 'IE') as es_referencia,
    c.rama,
    case c.rama
        when 'F' then 'Construcción (total)'
        when 'F41' then 'Edificación'
        when 'F42' then 'Ingeniería civil (obra pública)'
        when 'F43' then 'Construcción especializada'
    end as rama_nombre,
    c.empresas_1000hab,
    c.ocupados_por_empresa,
    c.productividad_miles_eur,
    c.cifra_negocios_hab_eur,
    case when c.pais = 'ES' then c.cifra_negocios_hab_eur * d.factor end as cifra_negocios_hab_eur_real,
    case when c.pais <> 'EU27_2020' and c.empresas_1000hab is not null then
        rank() over (partition by c.anio, c.rama, (c.pais <> 'EU27_2020' and c.empresas_1000hab is not null)
                     order by c.empresas_1000hab desc) end as puesto_empresas_1000hab,
    100.0 * c.empresas / nullif(ue.empresas, 0) as cuota_empresas_ue_pct,
    100.0 * c.cifra_negocios_meur / nullif(ue.cifra_negocios_meur, 0) as cuota_cifra_negocios_ue_pct,
    100.0 * c.poblacion_miles / nullif(ue.poblacion_miles, 0) as cuota_poblacion_ue_pct,
    c.empresas,
    c.ocupados,
    c.cifra_negocios_meur,
    c.valor_anadido_meur,
    c.poblacion_miles,
    d.anio_base
from calc c
left join calc ue on ue.pais = 'EU27_2020' and ue.anio = c.anio and ue.rama = c.rama
left join {{ ref('industria_paises') }} n on n.pais = c.pais
left join {{ ref('construccion_deflactor') }} d on d.anio = c.anio
where coalesce(c.empresas, c.ocupados, c.cifra_negocios_meur) is not null
