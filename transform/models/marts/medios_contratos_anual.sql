-- Contratos adjudicados a empresas de medios por año, nivel de la administración
-- contratante, comunidad y categoría del objeto. Fuente: PLACSP (Ministerio de
-- Hacienda), ver medios_contratos_base.
-- - Columnas principales (importe_*, eur_hab_real, n_contratos, n_menores): solo
--   medios de titularidad privada con es_medio = 'si' y sin importes sospechosos.
--   Aparte: importe_gris_eur_real (NIF dudosos del padrón: comercializadoras,
--   asociaciones de prensa...) e importe_publicos_eur_real (EFE, RTVE y
--   radiotelevisiones autonómicas o locales, que ya se cuentan en otro bloque).
-- - nivel: estatal | autonomico | local | empresa_publica | otro (universidades,
--   órganos constitucionales, mutuas). ambito = administración de la que depende
--   el órgano (las empresas públicas se reparten así).
-- - cod_ccaa: '00' para el ámbito estatal; la comunidad del órgano en el resto.
-- - eur_hab_real = euros de 2025 por habitante del ámbito: España para el
--   estatal, la comunidad para el autonómico y para el local (todos los entes
--   locales de la comunidad sumados). Población a 1 de enero (poblacion_territorios);
--   para años sin dato se usa el último disponible.
-- - familia / presidente: partido que gobernaba a 1 de julio (seed
--   gobiernos_presidentes) en el ámbito estatal y autonómico; null en el local.
-- - Cobertura: los menores de PLACSP existen desde 2018 y solo de los perfiles alojados
--   en PLACSP; los de las plataformas autonómicas se añaden desde sus datos abiertos
--   (fuente_plataforma <> 'placsp': Cataluña, Euskadi, Junta de Andalucía, Xunta,
--   Gobierno de La Rioja, Ayuntamiento de Madrid, Barcelona 2018, Comunidad de Madrid y
--   Navarra). importe_autonomicas_eur_real = parte de importe_eur_real que viene de ellas.
--   parcial = año en curso.
with b as (
    select *,
        case when ambito = 'estatal' or nivel = 'estatal' or cod_ccaa is null then '00' else cod_ccaa end as cod_ambito
    from {{ ref('medios_contratos_base') }}
    where anio >= 2018
),

agregado as (
    select anio, nivel, ambito, cod_ambito as cod_ccaa, categoria,
        sum(importe_adjudicado_sin_iva) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as importe_eur_nominal,
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as importe_eur_real,
        count(*) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as n_contratos,
        count(*) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso and es_menor) as n_menores,
        count(distinct nif_adjudicatario) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as n_adjudicatarios,
        count(distinct organo_clave) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as n_organos,
        sum(importe_eur_real) filter (where es_medio = 'gris' and not sospechoso) as importe_gris_eur_real,
        count(*) filter (where es_medio = 'gris' and not sospechoso) as n_contratos_gris,
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'publica' and not sospechoso) as importe_publicos_eur_real,
        count(*) filter (where es_medio = 'si' and titularidad = 'publica' and not sospechoso) as n_contratos_publicos,
        count(*) filter (where sospechoso) as n_sospechosos,
        -- parte que llega por las plataformas autonómicas y municipales (menores que PLACSP no trae)
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso and fuente_plataforma <> 'placsp') as importe_autonomicas_eur_real,
        count(*) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso and fuente_plataforma <> 'placsp') as n_contratos_autonomicas,
        string_agg(distinct fuente_plataforma, ', ' order by fuente_plataforma) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as fuente_plataforma
    from b
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

ultimo as (
    select max(anio) as anio_max from b
)

select
    a.anio,
    a.nivel,
    a.ambito,
    a.cod_ccaa,
    case when a.cod_ccaa = '00' then 'España' else t.nombre end as comunidad,
    a.categoria,
    coalesce(a.importe_eur_nominal, 0) as importe_eur_nominal,
    coalesce(a.importe_eur_real, 0) as importe_eur_real,
    coalesce(a.importe_eur_real, 0) / p.poblacion as eur_hab_real,
    cast(a.n_contratos as integer) as n_contratos,
    cast(a.n_menores as integer) as n_menores,
    cast(a.n_adjudicatarios as integer) as n_adjudicatarios,
    cast(a.n_organos as integer) as n_organos,
    coalesce(a.importe_gris_eur_real, 0) as importe_gris_eur_real,
    cast(a.n_contratos_gris as integer) as n_contratos_gris,
    coalesce(a.importe_publicos_eur_real, 0) as importe_publicos_eur_real,
    cast(a.n_contratos_publicos as integer) as n_contratos_publicos,
    cast(a.n_sospechosos as integer) as n_sospechosos,
    coalesce(a.importe_autonomicas_eur_real, 0) as importe_autonomicas_eur_real,
    cast(coalesce(a.n_contratos_autonomicas, 0) as integer) as n_contratos_autonomicas,
    a.fuente_plataforma,
    cast(p.poblacion as bigint) as poblacion,
    g.familia,
    g.presidente,
    a.anio = u.anio_max as parcial,
    case
        when a.nivel = 'estatal' or a.cod_ccaa = '00' then null
        when a.cod_ccaa = '09' then 'Cataluña: menores desde 2021 (Registre públic de contractes, casado por nombre, y PSCP con NIF); faltan los menores de 2018-2020 salvo los del Ayuntamiento de Barcelona de 2018'
        when a.cod_ccaa = '16' then 'Euskadi: menores de KontratazioA (Gobierno Vasco, diputaciones forales y entes locales que publican allí); faltan los de los entes con plataforma propia'
        when a.cod_ccaa = '01' and a.ambito = 'autonomico' then 'Andalucía: menores de la Junta y su sector público (plataforma de la Junta)'
        when a.cod_ccaa = '12' and a.ambito = 'autonomico' then 'Galicia: menores de la Xunta y su sector público (contratosdegalicia.gal, fecha de publicación; importe sin IVA estimado a partir del importe con IVA)'
        when a.cod_ccaa = '17' and a.ambito = 'autonomico' then 'La Rioja: menores del Gobierno de La Rioja desde 2021, importe sin IVA estimado a partir del importe con IVA'
        when a.cod_ccaa = '13' and a.ambito = 'autonomico' then 'Comunidad de Madrid: menores de las consejerías y su sector público (Metro, Canal de Isabel II...) del buscador del Portal de Contratación, buscados por NIF del adjudicatario'
        when a.cod_ccaa = '13' and a.ambito = 'local' then 'Madrid: incluye los menores del Ayuntamiento de Madrid (datos.madrid.es); faltan los de los demás ayuntamientos que publican en la plataforma de la Comunidad'
        when a.cod_ccaa = '15' then 'Navarra: menores de las relaciones trimestrales de facturas del Portal de Contratación (Gobierno, sociedades públicas y entidades locales que las publican); cada fila es una factura, casada casi siempre por nombre, con el importe sin IVA estimado'
        when a.cod_ccaa in ('01', '12', '17') and a.ambito = 'local' then 'Entes locales: menores solo de los que publican en PLACSP'
    end as nota
from agregado a
cross join ultimo u
cross join rango_pob r
left join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = a.cod_ccaa
left join pob p on p.cod = a.cod_ccaa and p.anio = greatest(least(a.anio, r.amax), r.amin)
left join gob g
    on a.ambito in ('estatal', 'autonomico')
    and g.nivel = a.ambito
    and g.cod = a.cod_ccaa
    and g.desde <= make_date(a.anio, 7, 1) and g.hasta > make_date(a.anio, 7, 1)
order by a.anio, a.nivel, a.cod_ccaa, a.categoria
