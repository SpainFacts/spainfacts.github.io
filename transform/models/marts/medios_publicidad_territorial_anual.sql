-- Publicidad institucional por comunidad autónoma y gran ayuntamiento y año,
-- separando la administración (consejerías, departamentos, organismos) de las
-- empresas públicas (FGC, Loteries de Catalunya, ICF, FGV, CACSA, Canal de
-- Isabel II, EMT, Madrid Destino, TMB...). Base: medios_publicidad_territorial_gasto
-- (filas con cuenta_en_total), que reúne Cataluña, Castilla y León, Aragón,
-- Navarra, Murcia, Comunitat Valenciana, País Vasco, la Comunidad de Madrid (planes de
-- medios 2020-, base 'planificado') con Canal de Isabel II (planes 2019-) y los
-- Ayuntamientos de Madrid y Barcelona (más TMB). Solo años completos (hasta 2025).
-- Euros constantes del año base del deflactor (main.deflactor: real = nominal *
-- factor) por habitante con el padrón a 1 de enero: comunidad
-- (main.poblacion_territorios, nivel 'ccaa') o municipio (main.poblacion_municipios),
-- acotando el año al rango disponible. total_sin_iva_eur_hab_real homogeneiza
-- el IVA (÷1,21 donde la fuente da importes con IVA; tal cual si los da sin IVA o
-- no lo indica). Las bases no son iguales (ejecutado frente a contratado, neto sin
-- comisión de agencia en Cataluña, planes de medios en la Comunidad de Madrid):
-- comparable_entre_territorios marca las filas homogéneas (ejecutado y con el IVA
-- conocido o tratado) y nota explica cada caso. Partido que gobierna a 1 de julio:
-- comunidades con la semilla gobiernos_presidentes (nivel 'autonomico');
-- ayuntamientos con main.alcaldes_historia (familia del alcalde a 1 de julio).
with base as (
    select * from {{ ref('medios_publicidad_territorial_gasto') }}
    where cuenta_en_total and anio <= 2025
),

agg as (
    select
        cod_ccaa,
        nivel,
        coalesce(cod_municipio, '') as cod_municipio,
        anio,
        sum(importe_eur) filter (where not es_empresa_publica) as administracion_eur,
        sum(importe_eur) filter (where es_empresa_publica) as empresas_eur,
        sum(importe_eur) as total_eur,
        sum(importe_sin_iva_eur) as total_sin_iva_eur,
        -- un único criterio por territorio y año, o nulo si se mezclan
        case when count(distinct coalesce(cast(iva_incluido as varchar), 'nd')) = 1
            then any_value(iva_incluido) end as iva_incluido,
        string_agg(distinct coalesce(cast(iva_incluido as varchar), 'no indicado'), ' / ') as iva_fuentes,
        string_agg(distinct base, ' / ') as base,
        string_agg(distinct origen, ' / ') as origen,
        count(distinct organismo_pagador) as organismos,
        bool_or(organismo_pagador ilike '%canal de isabel%') as incluye_canal,
        bool_or(organismo_pagador ilike '%TMB%') as incluye_tmb,
        bool_and(organismo_pagador ilike '%canal de isabel%' or organismo_pagador ilike '%TMB%') as solo_empresa_aparte
    from base
    group by 1, 2, 3, 4
),

pob_ccaa as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

pob_mun as (
    select cod_mun, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

rango as (
    select (select min(anio) from pob_ccaa) as cmin, (select max(anio) from pob_ccaa) as cmax,
        (select min(anio) from pob_mun) as mmin, (select max(anio) from pob_mun) as mmax
),

gob as (
    select cod, desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'autonomico'
),

alc as (
    select cod_mun, fecha_posesion, coalesce(fecha_fin, date '2100-01-01') as fecha_fin,
        alcalde, familia, color, municipio
    from {{ ref('alcaldes_historia') }}
),

colores as (
    select familia, any_value(color) as color
    from {{ ref('partidos_familias') }}
    where familia = partido_original and color is not null
    group by familia
),

datos as (
    select a.*,
        t.nombre as comunidad,
        case when a.nivel = 'local' then pm.poblacion else pc.poblacion end as poblacion,
        d.factor
    from agg a
    cross join rango r
    join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = a.cod_ccaa
    left join pob_ccaa pc on a.nivel = 'autonomico' and pc.cod = a.cod_ccaa
        and pc.anio = greatest(least(a.anio, r.cmax), r.cmin)
    left join pob_mun pm on a.nivel = 'local' and pm.cod_mun = a.cod_municipio
        and pm.anio = greatest(least(a.anio, r.mmax), r.mmin)
    left join {{ ref('deflactor') }} d on d.anio = a.anio
)

select
    d.cod_ccaa,
    d.comunidad,
    d.nivel,
    nullif(d.cod_municipio, '') as cod_municipio,
    case when d.nivel = 'local' then case d.cod_municipio when '28079' then 'Madrid' when '08019' then 'Barcelona'
        else d.cod_municipio end else d.comunidad end as territorio,
    d.anio,
    d.administracion_eur * d.factor / d.poblacion as administracion_eur_hab_real,
    d.empresas_eur * d.factor / d.poblacion as empresas_publicas_eur_hab_real,
    d.total_eur * d.factor / d.poblacion as total_eur_hab_real,
    d.total_sin_iva_eur * d.factor / d.poblacion as total_sin_iva_eur_hab_real,
    d.administracion_eur as administracion_eur_nominal,
    d.empresas_eur as empresas_publicas_eur_nominal,
    d.total_eur as total_eur_nominal,
    d.total_eur * d.factor as total_eur_real,
    d.iva_incluido,
    d.iva_fuentes,
    d.base,
    -- homogéneo: ejecutado, sin mezcla de criterios y no limitado a una empresa suelta
    (d.base = 'ejecutado' and not d.solo_empresa_aparte) as comparable_entre_territorios,
    cast(d.organismos as integer) as organismos,
    cast(d.poblacion as bigint) as poblacion,
    d.factor as factor_deflactor,
    case when d.nivel = 'local' then al.familia else g.familia end as familia,
    case when d.nivel = 'local' then al.alcalde else g.presidente end as presidente_o_alcalde,
    coalesce(case when d.nivel = 'local' then al.color else c.color end, '#94a3b8') as color,
    case
        when d.cod_ccaa = '09' and d.nivel = 'autonomico' then 'Generalitat de Catalunya y su sector público (incluye FGC, Loteries de Catalunya/EAJA, ICF, Ports...). Importe neto: sin IVA ni comisión de agencia; incluye creatividad. Ejecutado.'
        when d.cod_ccaa = '07' then 'Junta de Castilla y León por consejería y medio. Ejecutado; la fuente no dice si lleva IVA (un 21 % de los importes son múltiplos exactos de 1,21: probablemente con IVA). No separa empresas públicas.'
        when d.cod_ccaa = '02' then 'Gobierno de Aragón: importes adjudicados a cada medio (contratado), con IVA. 2018: incluye 17.663 € que la hoja resumen oficial no suma (importe escrito como texto).'
        when d.cod_ccaa = '15' then 'Gobierno de Navarra: suma de la tabla por departamentos (2012 y 2016-2025; 2013-2015 la tabla es incompleta y se omiten). Ejecutado; IVA no indicado.'
        when d.cod_ccaa = '14' then 'Región de Murcia: contratos de publicidad (contratado), con IVA. Antes de 2017 la serie es incompleta.'
        when d.cod_ccaa = '10' then 'Generalitat Valenciana: consellerias y sector público instrumental (Turisme CV, FGV, CACSA, IVF, Aerocas...). Expedientes tramitados, sin IVA; sin total oficial con el que cuadrar.'
        when d.cod_ccaa = '16' then 'Gobierno Vasco (departamentos), según gobiernovasco.marketing (J. Gómez-Obregón, CC BY 4.0) a partir de las memorias al Parlamento. IVA no indicado (probablemente sin IVA). Sin sociedades públicas aparte.'
        when d.cod_ccaa = '13' and d.nivel = 'autonomico' and d.anio < 2020 then 'Solo Canal de Isabel II: su PDF de campañas de 2019 (importe ejecutado por soporte; IVA no indicado). La Comunidad de Madrid publica sus planes de medios desde 2020.'
        when d.cod_ccaa = '13' and d.nivel = 'autonomico' then 'Comunidad de Madrid: PLANES de medios (lo previsto, no lo ejecutado) de las consejerías y organismos (ZIP de Excel del Portal de Transparencia), neto sin IVA y sin constar la comisión de agencia; más los planes de medios de Canal de Isabel II por soporte (neto sin IVA), en empresas públicas, junto con el Consorcio Regional de Transportes. No comparable con las comunidades que publican ejecución. La cuenta 627 de Canal (con RRPP y patrocinios) no se suma.'
        when d.cod_municipio = '28079' then 'Ayuntamiento de Madrid, organismos autónomos y empresas municipales (EMT, EMVS, Madrid Destino), campañas nacionales e internacionales. Ejecutado, sin IVA (la fuente da también el importe con IVA).'
        when d.cod_municipio = '08019' then 'Ajuntament de Barcelona por campaña y tipo de medio (incluye creatividad y producción), más TMB desde 2021 (empresa de la AMB, asignada a Barcelona). Ejecutado; IVA no indicado.'
    end
    as nota
from datos d
left join gob g on d.nivel = 'autonomico' and g.cod = d.cod_ccaa
    and g.desde <= make_date(d.anio, 7, 1) and g.hasta > make_date(d.anio, 7, 1)
left join colores c on c.familia = g.familia
left join alc al on d.nivel = 'local' and al.cod_mun = d.cod_municipio
    and al.fecha_posesion <= make_date(d.anio, 7, 1) and al.fecha_fin > make_date(d.anio, 7, 1)
where d.total_eur > 0
    -- Barcelona 2025: solo hay TMB (el CSV municipal llega a 2024); la fila confundiría
    and not (d.cod_municipio = '08019' and d.solo_empresa_aparte)
order by d.cod_ccaa, d.nivel, d.cod_municipio, d.anio
