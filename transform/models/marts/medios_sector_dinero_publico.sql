-- Dinero público que llega a los medios comparado con el mercado publicitario, por año.
-- Mercado: inversión publicitaria en medios convencionales/controlados de InfoAdex
-- (medios_sector_publicidad; en 2022-2025 la metodología nueva, antes la serie larga) y total del
-- mercado (incluidos los medios no convencionales: buzoneo, patrocinio, PLV, mailing...).
-- Dinero público (marts ya existentes de la sección Medios, todos en millones de euros corrientes):
--  publicidad_estado: coste ejecutado de las campañas institucionales y comerciales de la
--     Administración General del Estado y sus empresas (medios_publicidad_age_anual; incluye
--     producción y, según parece, IVA, mientras que InfoAdex es inversión neta en espacios);
--  tv_publica: aportación pública a RTVE y a las radiotelevisiones autonómicas (medios_tv_espana_anual;
--     autonómicas solo desde 2017); no es publicidad, es financiación directa de medios públicos;
--  subvenciones: subvenciones a medios privados de la BDNS (medios_subvenciones_anual, años completos);
--  contratos: contratos adjudicados a empresas de medios privados en la Plataforma de Contratación
--     (medios_contratos_anual, años completos; mínimo documentado).
-- No incluye la publicidad institucional de comunidades y ayuntamientos (solo la publican algunos).
-- Los porcentajes son cocientes de magnitudes que no miden exactamente lo mismo: orientativos.
with mercado_met as (
    select anio, metodologia,
        max(inversion_meur_nominal) filter (where medio = 'subtotal_controlados') as controlados_meur,
        max(inversion_meur_nominal) filter (where medio = 'gran_total') as total_mercado_meur,
        max(inversion_meur_nominal) filter (where medio = 'television') as television_meur
    from {{ ref('medios_sector_publicidad') }}
    group by anio, metodologia
),
mercado as (
    select * from mercado_met
    qualify row_number() over (partition by anio order by case when metodologia = 'controlados' then 1 else 2 end) = 1
),
age as (
    select anio, (coalesce(institucional_eur_nominal, 0) + coalesce(comercial_eur_nominal, 0)) / 1e6 as publicidad_estado_meur,
        institucional_eur_nominal / 1e6 as publicidad_institucional_meur
    from {{ ref('medios_publicidad_age_anual') }}
    where institucional_eur_nominal is not null
),
tv as (
    select anio, total_meur_nominal as tv_publica_meur, rtve_meur_nominal as rtve_meur,
        autonomicas_meur_nominal as autonomicas_meur
    from {{ ref('medios_tv_espana_anual') }}
),
sub as (
    select anio, sum(importe_eur_nominal) / 1e6 as subvenciones_meur
    from {{ ref('medios_subvenciones_anual') }}
    group by anio
    having not bool_or(parcial)
),
con as (
    select anio, sum(importe_eur_nominal) / 1e6 as contratos_meur
    from {{ ref('medios_contratos_anual') }}
    group by anio
    having not bool_or(parcial)
),
pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
)
select
    m.anio, m.metodologia,
    m.controlados_meur, m.total_mercado_meur,
    age.publicidad_estado_meur, age.publicidad_institucional_meur,
    tv.tv_publica_meur, tv.rtve_meur, tv.autonomicas_meur,
    sub.subvenciones_meur, con.contratos_meur,
    100.0 * age.publicidad_estado_meur / m.controlados_meur as publicidad_estado_pct_mercado,
    100.0 * tv.tv_publica_meur / m.controlados_meur as tv_publica_pct_mercado,
    100.0 * tv.tv_publica_meur / m.television_meur as tv_publica_pct_publicidad_tv,
    1e6 * m.controlados_meur * d.factor / p.poblacion as controlados_eur_hab_real,
    1e6 * age.publicidad_estado_meur * d.factor / p.poblacion as publicidad_estado_eur_hab_real,
    1e6 * tv.tv_publica_meur * d.factor / p.poblacion as tv_publica_eur_hab_real,
    1e6 * sub.subvenciones_meur * d.factor / p.poblacion as subvenciones_eur_hab_real,
    1e6 * con.contratos_meur * d.factor / p.poblacion as contratos_eur_hab_real,
    d.anio_base
from mercado m
left join age on age.anio = m.anio
left join tv on tv.anio = m.anio
left join sub on sub.anio = m.anio
left join con on con.anio = m.anio
left join pob p on p.anio = m.anio
left join {{ ref('deflactor') }} d on d.anio = m.anio
