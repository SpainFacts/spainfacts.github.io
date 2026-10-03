-- Licitación oficial de obra pública por año, España y comunidades, en euros reales por habitante
-- (Ministerio de Transportes, «Licitación oficial en construcción», vía ISTAC E20004A_000001,
-- raw.construccion_licitacion_ccaa, filas anuales; presupuesto de licitación con IVA en miles de
-- euros). Desde 1989; los años recientes son provisionales (columna provisional).
--   Agentes: estado = Estado y Seguridad Social, INCLUIDAS las entidades públicas estatales
--     (Adif, Aena, Puertos, SEITT...); entes_territoriales = comunidades autónomas + entidades
--     locales (la fuente abierta no las separa); total = suma de ambos.
--   Para España ('00') se añade, del Banco de España (Boletín Estadístico 23.9), la parte de las
--     entidades públicas estatales (epe) y la Administración General del Estado + Seguridad Social
--     (age = estado - epe). Se comprobó que total ISTAC = total BdE (2007: 37.400 M€).
--   cod 'NR': licitación no regionalizable (obras de ámbito supraautonómico), sin población.
--   *_real_meur: millones de euros constantes de anio_base (construccion_deflactor: IPC del INE,
--     enlazado con el IPCA antes de 2002; nulo antes de 1996).
--   *_hab_real: euros constantes por habitante (España: población media de Eurostat nama_10_pe;
--     comunidades: población a 1 de enero, main.poblacion_territorios, desde 1996).
--   familia_estatal / presidente_estatal: partido del Gobierno central a 1 de julio del año
--     (seed gobiernos_presidentes), atribuible a la parte estatal. familia_autonomica: partido del
--     Gobierno de la comunidad a 1 de julio; la parte territorial mezcla comunidad y ayuntamientos,
--     así que la atribución es orientativa.
with lic as (
    select
        coalesce(m.cod_ccaa, 'NR') as cod,
        coalesce(m.nombre, 'No regionalizable') as nombre,
        cast(l.anio as integer) as anio,
        max(l.miles_eur) filter (where l.agente = 'ADMINISTRACIONES_PUBLICAS' and l.tipo_obra = '_T') / 1000.0 as total_meur,
        max(l.miles_eur) filter (where l.agente = 'ESTADO_SEGURIDAD_SOCIAL' and l.tipo_obra = '_T') / 1000.0 as estado_meur,
        max(l.miles_eur) filter (where l.agente = 'ENTES_TERRITORIALES' and l.tipo_obra = '_T') / 1000.0 as entes_territoriales_meur,
        max(l.miles_eur) filter (where l.agente = 'ADMINISTRACIONES_PUBLICAS' and l.tipo_obra = 'EDIFICACION') / 1000.0 as edificacion_meur,
        max(l.miles_eur) filter (where l.agente = 'ADMINISTRACIONES_PUBLICAS' and l.tipo_obra = 'INGENIERIA_CIVIL') / 1000.0 as obra_civil_meur,
        bool_or(l.estado = 'Valor provisional') as provisional
    from {{ source('raw_construccion', 'construccion_licitacion_ccaa') }} l
    left join {{ ref('construccion_nuts') }} m on m.nuts = l.nuts
    where l.mes is null
    group by all
),

bde as (
    select
        cast(anio as integer) as anio,
        sum(valor) filter (where serie = 'D_1KB53418') / 1000.0 as epe_meur,
        count(distinct mes) as meses
    from {{ source('raw_construccion', 'construccion_bde_series') }}
    where cuadro = 'be2309' and serie = 'D_1KB53418'
    group by 1
),

pob_es as (
    select cast(anio as integer) as anio, miles * 1000.0 as poblacion
    from {{ source('raw_construccion', 'eurostat_construccion_poblacion') }}
    where pais = 'ES'
),

pob_ccaa as (
    select cod, cast(anio as integer) as anio, cast(poblacion as double) as poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

con_pob as (
    select l.*, coalesce(pe.poblacion, pc.poblacion) as poblacion
    from lic l
    left join pob_es pe on l.cod = '00' and pe.anio = l.anio
    asof left join pob_ccaa pc on pc.cod = l.cod and pc.anio <= l.anio
),

gob as (
    select nivel, cod, desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
)

select
    c.cod,
    c.nombre,
    c.anio,
    c.total_meur * d.factor / nullif(c.poblacion, 0) * 1e6 as total_hab_real,
    c.estado_meur * d.factor / nullif(c.poblacion, 0) * 1e6 as estado_hab_real,
    c.entes_territoriales_meur * d.factor / nullif(c.poblacion, 0) * 1e6 as entes_territoriales_hab_real,
    c.edificacion_meur * d.factor / nullif(c.poblacion, 0) * 1e6 as edificacion_hab_real,
    c.obra_civil_meur * d.factor / nullif(c.poblacion, 0) * 1e6 as obra_civil_hab_real,
    case when c.cod = '00' and b.meses = 12 then b.epe_meur * d.factor / nullif(c.poblacion, 0) * 1e6 end as epe_hab_real,
    case when c.cod = '00' and b.meses = 12 then (c.estado_meur - b.epe_meur) * d.factor / nullif(c.poblacion, 0) * 1e6 end as age_hab_real,
    100.0 * c.estado_meur / nullif(c.total_meur, 0) as pct_estado,
    100.0 * c.obra_civil_meur / nullif(c.total_meur, 0) as pct_obra_civil,
    c.total_meur * d.factor as total_real_meur,
    c.estado_meur * d.factor as estado_real_meur,
    c.entes_territoriales_meur * d.factor as entes_territoriales_real_meur,
    c.total_meur,
    c.estado_meur,
    c.entes_territoriales_meur,
    c.edificacion_meur,
    c.obra_civil_meur,
    case when c.cod = '00' and b.meses = 12 then b.epe_meur end as epe_meur,
    case when c.cod = '00' and b.meses = 12 then c.estado_meur - b.epe_meur end as age_meur,
    c.poblacion,
    d.factor,
    d.anio_base,
    c.provisional,
    ge.familia as familia_estatal,
    ge.presidente as presidente_estatal,
    ga.familia as familia_autonomica,
    ga.presidente as presidente_autonomico
from con_pob c
left join {{ ref('construccion_deflactor') }} d on d.anio = c.anio
left join bde b on b.anio = c.anio
left join gob ge on ge.nivel = 'estatal'
    and ge.desde <= make_date(c.anio, 7, 1) and ge.hasta > make_date(c.anio, 7, 1)
left join gob ga on ga.nivel = 'autonomico' and ga.cod = c.cod
    and ga.desde <= make_date(c.anio, 7, 1) and ga.hasta > make_date(c.anio, 7, 1)
order by c.cod, c.anio
