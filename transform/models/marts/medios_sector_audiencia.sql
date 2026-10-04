-- Audiencia de los medios en España, 1980-2025: penetración del Estudio General de Medios (EGM)
-- transcrita del «Marco General de los Medios en España 2026» de AIMC (seed
-- medios_sector_egm_penetracion) más los minutos diarios de radio y TV (seed
-- medios_sector_egm_minutos).
-- penetracion_pct = % de la población de 14 o más años (15 o más hasta 1984) que lee, ve u oye
-- el medio (diarios: en el día; radio y TV: audiencia acumulada diaria).
-- personas_miles = penetración x universo del EGM; por_1000_hab = esas personas por cada 1.000
-- habitantes de toda la población (padrón a 1 de enero, main.poblacion_territorios; desde 1998,
-- antes queda nulo). Diarios papel: hasta 2017 solo papel, desde 2018 incluye el visor digital/PDF.
-- Exterior cambia de pregunta en 2015 y cine en 2024 (ver descripción del seed).
with p as (
    select cast(anio as integer) as anio, medio, penetracion_pct, universo_miles
    from {{ ref('medios_sector_egm_penetracion') }}
),
u as (
    select anio, max(universo_miles) as universo_miles from p group by anio
),
pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),
m as (
    select cast(anio as integer) as anio, medio, minutos_dia
    from {{ ref('medios_sector_egm_minutos') }}
)
select
    p.anio, p.medio,
    case p.medio
        when 'diarios' then 'Diarios (papel o web)'
        when 'diarios_papel' then 'Diarios en papel'
        when 'diarios_internet' then 'Diarios en internet'
        when 'suplementos' then 'Suplementos'
        when 'suplementos_papel' then 'Suplementos en papel'
        when 'suplementos_internet' then 'Suplementos en internet'
        when 'revistas' then 'Revistas (papel o web)'
        when 'revistas_papel' then 'Revistas en papel'
        when 'revistas_internet' then 'Revistas en internet'
        when 'radio' then 'Radio'
        when 'radio_internet' then 'Radio por internet'
        when 'television' then 'Televisión'
        when 'cine' then 'Cine'
        when 'exterior' then 'Publicidad exterior'
        when 'diarios_tipo_total' then 'Diarios en papel (total)'
        when 'diarios_informacion_general' then 'Diarios de información general'
        when 'diarios_economicos' then 'Diarios económicos'
        when 'diarios_deportivos' then 'Diarios deportivos'
        when 'diarios_de_pago' then 'Diarios de pago'
        when 'diarios_gratuitos' then 'Diarios gratuitos'
    end as medio_nombre,
    p.penetracion_pct,
    u.universo_miles,
    p.penetracion_pct / 100 * u.universo_miles as personas_miles,
    1000.0 * (p.penetracion_pct / 100 * u.universo_miles * 1000) / pob.poblacion as por_1000_hab,
    m.minutos_dia
from p
join u on u.anio = p.anio
left join pob on pob.anio = p.anio
left join m on m.anio = p.anio and m.medio = p.medio
