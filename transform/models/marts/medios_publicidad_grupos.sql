-- Inversión en medios de la publicidad de la Administración General del Estado
-- por grupo mediático, empresa o plataforma (seed medios_publicidad_grupos_informe:
-- Informe de Publicidad y Comunicación Institucional 2025, Anexo IV, e Informe
-- 2025 de publicidad estatal comercial, Anexo III, tablas «Inversión por
-- grupos»). Primer año con este desglose (Reglamento europeo de libertad de los
-- medios, art. 25). Solo compra de medios: sin producción, evaluación ni líneas
-- de apoyo (RRPP, influencers). Los importes parecen llevar IVA (múltiplos de
-- 1,21). pct = % sobre la suma del tipo (institucional o comercial) y año.
-- Por habitante con el padrón de España del año (o el último disponible) y en
-- euros constantes (main.deflactor).
with s as (
    select cast(anio as integer) as anio, tipo, grupo, nullif(soporte, '') as soporte,
        importe_eur, fuente, nullif(nota, '') as nota
    from {{ ref('medios_publicidad_grupos_informe') }}
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

pob_rango as (select min(anio) as amin, max(anio) as amax from pob)

select
    s.anio,
    s.tipo,
    s.grupo,
    s.soporte,
    s.importe_eur as importe_eur_nominal,
    s.importe_eur * d.factor as importe_eur_real,
    s.importe_eur * d.factor / p.poblacion as eur_hab_real,
    100.0 * s.importe_eur / sum(s.importe_eur) over (partition by s.anio, s.tipo) as pct,
    cast(row_number() over (partition by s.anio, s.tipo order by s.importe_eur desc) as integer) as puesto,
    coalesce(s.nota like 'plataforma%', false) as es_plataforma,
    coalesce(s.nota like 'medio público%', false) as es_publico,
    s.fuente,
    s.nota
from s
cross join pob_rango r
left join pob p on p.anio = greatest(least(s.anio, r.amax), r.amin)
left join {{ ref('deflactor') }} d on d.anio = s.anio
order by s.anio, s.tipo, s.importe_eur desc
