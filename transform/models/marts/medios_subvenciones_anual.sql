-- Subvenciones a medios de comunicación privados por año, nivel de la
-- administración concedente y comunidad. Fuente: BDNS (IGAE), concesiones de las
-- convocatorias de la lista curada medios_subvenciones_convocatorias (ver
-- medios_subvenciones_concesiones).
-- - Año = año de concesión. La BDNS solo muestra 4 años naturales (hoy, 2022-...):
--   el último año está siempre incompleto (parcial = true).
-- - eur_hab_real = euros de 2025 por habitante del ámbito del concedente: España
--   para el Estado ('00') y la comunidad para las autonómicas y las locales
--   (las locales se agregan por comunidad). Población a 1 de enero del INE
--   (poblacion_territorios); para años sin dato se usa el último disponible.
-- - familia / presidente = partido que gobernaba a 1 de julio (seed
--   gobiernos_presidentes): estatal para el nivel estatal y autonómico para el
--   autonómico. Las locales no llevan familia (cada concedente es un
--   ayuntamiento o diputación distinto).
-- - Huecos: el Gobierno Vasco no publica en la BDNS sus ayudas a medios (País Vasco
--   solo tiene diputaciones forales y ayuntamientos); Andalucía y Canarias no
--   tienen líneas visibles para medios privados.
with conc as (
    select * from {{ ref('medios_subvenciones_concesiones') }}
),

agregado as (
    select anio, nivel, cod_ccaa,
        sum(importe_eur) as importe_eur_nominal,
        sum(importe_eur_real) as importe_eur_real,
        count(*) as n_concesiones,
        count(distinct beneficiario_nif) filter (where not es_persona_fisica) as n_beneficiarios_juridicos,
        count(*) filter (where es_persona_fisica) as n_concesiones_personas_fisicas,
        count(distinct cod_bdns) as n_convocatorias
    from conc
    group by all
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

rango_pob as (
    select min(anio) as amin, max(anio) as amax from pob
),

gob as (
    select nivel, cod, desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
),

colores as (
    select familia, any_value(color) as color
    from {{ ref('alcaldes_historia') }}
    where familia is not null and color is not null
    group by familia
),

ultimo as (
    select max(anio) as anio_max from conc
)

select
    a.anio,
    a.nivel,
    a.cod_ccaa,
    case when a.cod_ccaa = '00' then 'España' else t.nombre end as comunidad,
    a.importe_eur_nominal,
    a.importe_eur_real,
    a.importe_eur_real / p.poblacion as eur_hab_real,
    a.importe_eur_nominal / p.poblacion as eur_hab_nominal,
    cast(a.n_concesiones as integer) as n_concesiones,
    cast(a.n_beneficiarios_juridicos + a.n_concesiones_personas_fisicas as integer) as n_beneficiarios,
    cast(a.n_beneficiarios_juridicos as integer) as n_beneficiarios_juridicos,
    cast(a.n_concesiones_personas_fisicas as integer) as n_concesiones_personas_fisicas,
    cast(a.n_convocatorias as integer) as n_convocatorias,
    cast(p.poblacion as bigint) as poblacion,
    g.familia,
    g.presidente,
    c.color,
    a.anio = u.anio_max as parcial,
    case when a.cod_ccaa = '16' and a.nivel <> 'estatal'
         then 'El Gobierno Vasco no publica en la BDNS sus ayudas a medios: solo diputaciones forales y ayuntamientos'
    end as nota
from agregado a
cross join ultimo u
cross join rango_pob r
left join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = a.cod_ccaa
left join pob p on p.cod = a.cod_ccaa and p.anio = greatest(least(a.anio, r.amax), r.amin)
left join gob g
    on a.nivel in ('estatal', 'autonomico')
    and g.nivel = a.nivel
    and g.cod = a.cod_ccaa
    and g.desde <= make_date(a.anio, 7, 1) and g.hasta > make_date(a.anio, 7, 1)
left join colores c on c.familia = g.familia
order by a.anio, a.nivel, a.cod_ccaa
