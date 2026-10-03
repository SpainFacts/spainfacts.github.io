-- Dinero público a la radio-televisión pública en España por año: RTVE
-- (2008-2025) y el conjunto de entes autonómicos (2017-2025), por habitante de
-- España y en euros reales.
-- RTVE (seed medios_tv_rtve, nota de subvenciones de explotación de las cuentas
-- anuales): rtve_estado = compensación de los PGE + otras subvenciones de
-- administraciones + subvenciones de capital; rtve_tasas = tasa del espectro
-- cedida y aportaciones obligatorias de TV privadas, telecos y plataformas (Ley
-- 8/2009 y Ley 13/2022). Los derechos de emisión donados no cuentan.
-- Autonómicas: suma de medios_tv_ccaa_anual, solo en los años en que están
-- todas las comunidades con ente (14, Valencia incluida). Por habitante, con la
-- población de España (poblacion_territorios, nivel pais, cod 00); real = nominal
-- x factor del deflactor (euros de anio_base).
with rtve as (
    select anio,
        sum(meur) filter (where grupo in ('estado', 'tasas_operadores')) as rtve_meur,
        sum(meur) filter (where grupo = 'estado') as rtve_estado_meur,
        sum(meur) filter (where grupo = 'tasas_operadores') as rtve_tasas_meur,
        coalesce(sum(meur) filter (where extraordinario), 0) as rtve_extra_meur
    from {{ ref('medios_tv_rtve') }}
    group by 1
),

auton as (
    select anio,
        count(*) as comunidades,
        sum(meur_nominal) as autonomicas_meur,
        sum(meur_extraordinario) as autonomicas_extra_meur
    from {{ ref('medios_tv_ccaa_anual') }}
    where meur_nominal is not null
    group by 1
),

n_entes as (
    select count(distinct cod_ccaa) as n from {{ ref('medios_tv_aportacion') }}
),

pob as (
    select anio, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

la1 as (
    select anio, cuota from {{ ref('medios_tv_audiencia') }}
    where ambito = 'espana' and cadena = 'La 1'
),

base as (
    select
        coalesce(r.anio, a.anio) as anio,
        r.rtve_meur, r.rtve_estado_meur, r.rtve_tasas_meur, r.rtve_extra_meur,
        a.comunidades,
        case when a.comunidades = (select n from n_entes) then a.autonomicas_meur end as autonomicas_meur,
        case when a.comunidades = (select n from n_entes) then a.autonomicas_extra_meur end as autonomicas_extra_meur
    from rtve r
    full join auton a on a.anio = r.anio
)

select
    cast(b.anio as integer) as anio,
    b.rtve_meur as rtve_meur_nominal,
    b.rtve_estado_meur,
    b.rtve_tasas_meur,
    b.rtve_extra_meur,
    1e6 * b.rtve_meur / p.poblacion * d.factor as rtve_eur_hab_real,
    1e6 * b.rtve_estado_meur / p.poblacion * d.factor as rtve_estado_eur_hab_real,
    1e6 * b.rtve_tasas_meur / p.poblacion * d.factor as rtve_tasas_eur_hab_real,
    cast(b.comunidades as integer) as comunidades_con_dato,
    b.autonomicas_meur as autonomicas_meur_nominal,
    b.autonomicas_extra_meur,
    1e6 * b.autonomicas_meur / p.poblacion * d.factor as autonomicas_eur_hab_real,
    b.rtve_meur + b.autonomicas_meur as total_meur_nominal,
    1e6 * (b.rtve_meur + b.autonomicas_meur) / p.poblacion * d.factor as total_eur_hab_real,
    l.cuota as cuota_la1,
    cast(p.poblacion as bigint) as poblacion,
    d.anio_base
from base b
left join pob p on p.anio = b.anio
left join {{ ref('deflactor') }} d on d.anio = b.anio
left join la1 l on l.anio = b.anio
order by b.anio
