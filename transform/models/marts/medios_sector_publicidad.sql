-- Inversión publicitaria en España por medio (InfoAdex, seed medios_sector_infoadex, transcrito
-- de los resúmenes públicos del Estudio InfoAdex de la inversión publicitaria, ediciones 2010-2026).
-- Dos metodologías que no se mezclan en una misma serie (columna metodologia):
--  'convencionales' 2004-2023: diarios, revistas, radio y TV solo en su soporte tradicional y todo
--     lo digital en 'internet';
--  'controlados' 2022-2025: cada medio con su parte digital (diarios con sus webs, radio con podcast,
--     TV con la conectada) y redes sociales, buscadores y otras webs aparte.
-- En euros constantes (main.deflactor, real = nominal * factor) y por habitante (padrón a 1 de enero).
-- pct_controlados = % del subtotal de medios convencionales/controlados del mismo año y metodología.
-- es_medio = true para los soportes de medios de comunicación (prensa, revistas, radio, TV, cine,
-- exterior en la serie nueva; en la serie larga también 'internet', que mezcla buscadores, redes y webs).
with s as (
    select cast(anio as integer) as anio, medio, inversion_meur, metodologia, cast(edicion as integer) as edicion
    from {{ ref('medios_sector_infoadex') }}
),
sub as (
    select anio, metodologia, inversion_meur as subtotal_meur
    from s where medio = 'subtotal_controlados'
),
pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
)
select
    s.anio, s.metodologia, s.medio,
    case s.medio
        when 'cine' then 'Cine'
        when 'diarios' then 'Diarios (papel)'
        when 'dominicales' then 'Dominicales'
        when 'exterior' then 'Exterior'
        when 'internet' then 'Internet'
        when 'radio' then 'Radio'
        when 'revistas' then 'Revistas'
        when 'television' then 'Televisión'
        when 'diarios_dominicales' then 'Diarios y dominicales (papel y web)'
        when 'diarios_dominicales_papel' then 'Diarios y dominicales: papel'
        when 'diarios_dominicales_digital' then 'Diarios y dominicales: web'
        when 'radio_audio' then 'Radio y audio digital'
        when 'redes_sociales' then 'Redes sociales'
        when 'search' then 'Buscadores'
        when 'websites' then 'Otras webs'
        when 'subtotal_controlados' then 'Total medios convencionales / controlados'
        when 'subtotal_estimados' then 'Total medios no convencionales / estimados'
        when 'gran_total' then 'Total mercado publicitario'
    end as medio_nombre,
    s.medio not in ('subtotal_controlados', 'subtotal_estimados', 'gran_total',
                    'diarios_dominicales_papel', 'diarios_dominicales_digital') as es_desglose,
    s.inversion_meur as inversion_meur_nominal,
    s.inversion_meur * d.factor as inversion_meur_real,
    1e6 * s.inversion_meur * d.factor / p.poblacion as eur_hab_real,
    100.0 * s.inversion_meur / sub.subtotal_meur as pct_controlados,
    s.edicion,
    p.poblacion,
    d.anio_base
from s
left join sub on sub.anio = s.anio and sub.metodologia = s.metodologia
left join pob p on p.anio = s.anio
left join {{ ref('deflactor') }} d on d.anio = s.anio
