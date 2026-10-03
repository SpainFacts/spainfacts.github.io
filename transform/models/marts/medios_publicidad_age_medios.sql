-- Inversión de la publicidad de la Administración General del Estado por
-- herramienta o tipo de medio y año (Comisión de Publicidad y Comunicación
-- Institucional, La Moncloa: Invers_herram_campanas_instituc_InformesPublicidad.csv
-- para las campañas institucionales, 2006-, e
-- Invers_herram_camp_instituc_y_comerciales_InformesPublicidad.csv para
-- institucionales + comerciales, 2009-, que agrupa cine, exterior, RRPP,
-- marketing y otras en «resto»). Es la difusión (compra de medios y otras
-- herramientas), sin producción/creatividad ni evaluación. pct = % sobre la
-- suma de las herramientas del año y ámbito (en 2020 y 2024 el «total
-- herramientas» del CSV es 0,5 y 0,9 % menor que la suma de sus partes: se
-- conserva en total_herramientas_eur_nominal). Por habitante (padrón, España) y en
-- euros constantes (main.deflactor). En 2006-2007 el cine iba dentro de otras
-- herramientas.
with base as (
    select cast(anio as integer) as anio, ambito, medio, importe_eur
    from {{ source('raw_medios_publicidad', 'pub_medios') }}
    where medio not in ('total_herramientas', 'total_campanas')
),

totales as (
    select cast(anio as integer) as anio, ambito, importe_eur as total_herramientas
    from {{ source('raw_medios_publicidad', 'pub_medios') }}
    where medio = 'total_herramientas'
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

pob_rango as (select min(anio) as amin, max(anio) as amax from pob)

select
    b.anio,
    b.ambito,
    b.medio,
    case b.medio
        when 'television' then 'Televisión'
        when 'radio' then 'Radio'
        when 'medios_graficos' then 'Prensa y revistas'
        when 'digital' then 'Digital'
        when 'exterior' then 'Exterior'
        when 'cine' then 'Cine'
        when 'relaciones_publicas' then 'Relaciones públicas'
        when 'marketing' then 'Marketing'
        when 'otras' then 'Otras herramientas'
        when 'resto' then 'Resto (cine, exterior, RRPP, otras)'
    end as medio_nombre,
    b.importe_eur as importe_eur_nominal,
    b.importe_eur * d.factor as importe_eur_real,
    b.importe_eur * d.factor / p.poblacion as eur_hab_real,
    100.0 * b.importe_eur / nullif(sum(b.importe_eur) over (partition by b.anio, b.ambito), 0) as pct,
    t.total_herramientas as total_herramientas_eur_nominal
from base b
left join totales t on t.anio = b.anio and t.ambito = b.ambito
cross join pob_rango r
left join pob p on p.anio = greatest(least(b.anio, r.amax), r.amin)
left join {{ ref('deflactor') }} d on d.anio = b.anio
order by b.ambito, b.anio, b.importe_eur desc
