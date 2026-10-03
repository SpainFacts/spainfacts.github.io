-- Publicidad de la Administración General del Estado por año (2006-2026):
-- coste ejecutado de las campañas institucionales (Ley 29/2005) y comerciales
-- (Loterías, Renfe, AENA, Paradores...) según los Informes anuales, y lo
-- planificado en los Planes anuales (Comisión de Publicidad y Comunicación
-- Institucional, La Moncloa: Evolucion_Informes_Publicidad.csv y
-- Evolucion_Planes_Publicidad.csv; ingestion/medios_publicidad.py).
-- El coste ejecutado incluye producción/creatividad, compra de medios y
-- evaluación. Los informes no dicen si llevan IVA; los importes por medio del
-- Informe 2025 son en su mayoría múltiplos de 1,21, señal de que van con IVA.
-- Por habitante con el padrón a 1 de enero (main.poblacion_territorios, España)
-- y en euros constantes del año base del deflactor (main.deflactor:
-- real = nominal * factor). ejecucion_pct = ejecutado institucional /
-- planificado institucional (en 2016 no hubo plan: Gobierno en funciones;
-- 2026 solo trae el plan). Partido del Gobierno de España a 1 de julio de cada
-- año (seed gobiernos_presidentes, nivel 'estatal').
with ejec as (
    select cast(anio as integer) as anio,
        max(importe_eur) filter (where tipo = 'institucional') as institucional,
        max(importe_eur) filter (where tipo = 'comercial') as comercial,
        max(importe_eur) filter (where tipo = 'total') as total,
        max(campanas) filter (where tipo = 'institucional') as campanas_institucionales,
        max(campanas) filter (where tipo = 'comercial') as campanas_comerciales
    from {{ source('raw_medios_publicidad', 'pub_ejecutado') }}
    group by 1
),

plan as (
    select cast(anio as integer) as anio,
        max(importe_eur) filter (where tipo = 'institucional') as planificado,
        max(importe_eur) filter (where tipo = 'comercial') as planificado_comercial,
        max(campanas) filter (where tipo = 'institucional') as campanas_planificadas
    from {{ source('raw_medios_publicidad', 'pub_planificado') }}
    group by 1
),

anios as (
    select anio from ejec union select anio from plan
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

pob_rango as (
    select min(anio) as amin, max(anio) as amax from pob
),

gob as (
    select desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'estatal'
),

colores as (
    select familia, any_value(color) as color
    from {{ ref('partidos_familias') }}
    where familia = partido_original and color is not null
    group by familia
),

base as (
    select a.anio,
        e.institucional, e.comercial, e.total,
        e.campanas_institucionales, e.campanas_comerciales,
        p.planificado, p.planificado_comercial, p.campanas_planificadas,
        po.poblacion,
        d.factor
    from anios a
    left join ejec e using (anio)
    left join plan p using (anio)
    cross join pob_rango r
    left join pob po on po.anio = greatest(least(a.anio, r.amax), r.amin)
    left join {{ ref('deflactor') }} d on d.anio = a.anio
)

select
    b.anio,
    b.institucional as institucional_eur_nominal,
    b.comercial as comercial_eur_nominal,
    b.total as total_eur_nominal,
    b.planificado as planificado_eur_nominal,
    b.planificado_comercial as planificado_comercial_eur_nominal,
    cast(b.campanas_institucionales as integer) as campanas_institucionales,
    cast(b.campanas_comerciales as integer) as campanas_comerciales,
    cast(b.campanas_planificadas as integer) as campanas_planificadas,
    b.institucional * b.factor as institucional_eur_real,
    b.comercial * b.factor as comercial_eur_real,
    b.institucional * b.factor / b.poblacion as institucional_eur_hab_real,
    b.comercial * b.factor / b.poblacion as comercial_eur_hab_real,
    b.total * b.factor / b.poblacion as total_eur_hab_real,
    b.planificado * b.factor / b.poblacion as planificado_eur_hab_real,
    100.0 * b.institucional / nullif(b.planificado, 0) as ejecucion_pct,
    100.0 * b.comercial / nullif(b.planificado_comercial, 0) as ejecucion_comercial_pct,
    cast(b.poblacion as bigint) as poblacion,
    b.factor as factor_deflactor,
    g.familia,
    g.presidente,
    coalesce(c.color, '#94a3b8') as color
from base b
left join gob g on g.desde <= make_date(b.anio, 7, 1) and g.hasta > make_date(b.anio, 7, 1)
left join colores c on c.familia = g.familia
order by b.anio
