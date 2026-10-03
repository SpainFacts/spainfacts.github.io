-- Publicidad de las empresas públicas (y entes que venden bienes o servicios)
-- por año, entidad y ámbito, en euros constantes y por habitante del ámbito.
--   * estatal: seed medios_publicidad_empresas_age, capítulo «Campañas
--     comerciales no sujetas a la Ley 29/2005» de los Informes anuales de la
--     Comisión de Publicidad y Comunicación Institucional (2015-2025): coste total
--     de las campañas comerciales de SELAE (Loterías), AENA, Correos, Renfe,
--     Paradores, ICO, grupo SEPI... con tipo_entidad 'empresa_publica',
--     'organismo' (museos, UNED, BOE... que también venden algo) o 'rtve'
--     (Corporación RTVE: ya está en el bloque de televisión pública, no sumar).
--     Habitantes: España.
--   * autonomico y local: filas de medios_publicidad_territorial_gasto con
--     es_empresa_publica (FGC, Loteries de Catalunya/EAJA, ICF, Ports, INCASÒL,
--     Prodeca, TNC, SARGA, FGV, CACSA, IVF, Aerocas, Canal de Isabel II, EMT,
--     EMVS, Madrid Destino, TMB...), con el nombre normalizado. Habitantes: la
--     comunidad o el municipio (TMB se asigna a Barcelona aunque sirve al área
--     metropolitana).
-- es_loterias identifica SELAE y Loteries de Catalunya (la única lotería
-- autonómica), que distorsionan cualquier comparación. magnitud dice qué se
-- mide: no es lo mismo el coste total de campañas comerciales (AGE: producción,
-- medios y evaluación), la compra de medios de las campañas institucionales de
-- la comunidad o el ayuntamiento, o la cuenta 627 de Canal (con relaciones
-- públicas y patrocinios). Euros constantes con main.deflactor (real = nominal *
-- factor); padrón de main.poblacion_territorios / main.poblacion_municipios.
with estatal as (
    select
        cast(anio as integer) as anio,
        'estatal' as ambito,
        '00' as cod_territorio,
        'España' as territorio,
        entidad,
        tipo_entidad,
        importe_eur,
        cast(null as boolean) as iva_incluido,
        'ejecutado' as base,
        'coste_campanas_comerciales' as magnitud,
        nota
    from {{ ref('medios_publicidad_empresas_age') }}
),

terr as (
    select
        anio,
        nivel as ambito,
        case when nivel = 'local' then cod_municipio else cod_ccaa end as cod_territorio,
        cod_ccaa,
        upper(strip_accents(organismo_pagador)) as u,
        organismo_pagador,
        importe_eur,
        iva_incluido,
        base
    from {{ ref('medios_publicidad_territorial_gasto') }}
    where es_empresa_publica and cuenta_en_total and anio <= 2025
),

terr_norm as (
    select *,
        case
            when u like '%LOTERIES%' or u like '%JOCS I APOSTES%' then 'Loteries de Catalunya (EAJA hasta 2021)'
            when u like '%FERROCA%' and cod_ccaa = '09' then 'FGC (Ferrocarrils de la Generalitat de Catalunya)'
            when u like '%ACTIUS DE MUNTANYA%' then 'Actius de Muntanya (FGC Turisme)'
            when (u like '%FINANCES%' or u like '%(ICF)%') and cod_ccaa = '09' then 'Institut Català de Finances (ICF)'
            when u like '%PORTS DE LA GENERALITAT%' then 'Ports de la Generalitat'
            when u like '%INCASOL%' or u like '%INSTITUT CATALA DEL SOL%' then 'INCASÒL'
            when u like '%PRODECA%' then 'Prodeca'
            when u like '%TEATRE NACIONAL%' then 'Teatre Nacional de Catalunya'
            when u like '%CIMALSA%' then 'CIMALSA'
            when u like '%SARGA%' or u like '%GESTION AGROAMBIENTAL%' then 'SARGA'
            when u like '%PLATAFORMA LOGISTICA%' then 'Aragón Plataforma Logística'
            when u like '%ARAGON EXTERIOR%' then 'Aragón Exterior'
            when u like '%EMPRESA MUNICIPAL DE TRANSPORTES%' or u like 'EMT%' then 'EMT Madrid'
            when u like '%VIVIENDA Y SUELO%' or u like '%EMVS%' then 'EMVS (Empresa Municipal de Vivienda y Suelo)'
            when u like '%MADRID DESTINO%' then 'Madrid Destino'
            when u like '%MERCAMADRID%' then 'Mercamadrid'
            when u like '%CANAL DE ISABEL%' then 'Canal de Isabel II'
            when u like '%TMB%' then 'TMB (Transports Metropolitans de Barcelona)'
            else trim(regexp_replace(organismo_pagador, '^[^-]+ - ', ''))
        end as entidad
    from terr
),

terr_agg as (
    select anio, ambito, cod_territorio, any_value(cod_ccaa) as cod_ccaa, entidad,
        sum(importe_eur) as importe_eur,
        case when count(distinct coalesce(cast(iva_incluido as varchar), 'nd')) = 1 then any_value(iva_incluido) end as iva_incluido,
        string_agg(distinct base, ' / ') as base
    from terr_norm
    group by 1, 2, 3, 5
),

terr_fin as (
    select
        a.anio, a.ambito, a.cod_territorio,
        case when a.ambito = 'local' then case a.cod_territorio when '28079' then 'Madrid' when '08019' then 'Barcelona'
            else a.cod_territorio end else t.nombre end as territorio,
        a.entidad,
        'empresa_publica' as tipo_entidad,
        a.importe_eur,
        a.iva_incluido,
        a.base,
        case when a.entidad = 'Canal de Isabel II' then 'cuenta_627'
            else 'publicidad_institucional_en_medios' end as magnitud,
        case
            when a.entidad = 'Canal de Isabel II' then 'Cuenta 627 de sus cuentas anuales: publicidad, propaganda y relaciones públicas (incluye RRPP y patrocinios).'
            when a.cod_territorio = '09' then 'Dataset de la Generalitat: importe neto sin IVA ni comisión de agencia.'
            when a.cod_territorio = '10' then 'PDF del sector público instrumental (gvaoberta): sin IVA, expedientes tramitados.'
            when a.cod_territorio = '28079' then 'Excel del Ayuntamiento de Madrid (unidad = empresa municipal): sin IVA, ejecutado.'
            when a.entidad like 'TMB%' then 'PDF de transparencia de TMB: inversión en medios de sus campañas; IVA no indicado.'
            when a.cod_territorio = '02' then 'Excel del Gobierno de Aragón: adjudicado, con IVA.'
        end as nota
    from terr_agg a
    left join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = a.cod_ccaa
),

todo as (
    select anio, ambito, cod_territorio, territorio, entidad, tipo_entidad, importe_eur, iva_incluido, base, magnitud, nota
    from estatal
    union all
    select anio, ambito, cod_territorio, territorio, entidad, tipo_entidad, importe_eur, iva_incluido, base, magnitud, nota
    from terr_fin
),

pob as (
    select 'estatal' as ambito, cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }} where nivel = 'pais' and cod = '00' and sexo = 'Total'
    union all
    select 'autonomico', cod, cast(anio as integer), poblacion
    from {{ ref('poblacion_territorios') }} where nivel = 'ccaa' and sexo = 'Total'
    union all
    select 'local', cod_mun, cast(anio as integer), poblacion
    from {{ ref('poblacion_municipios') }} where sexo = 'Total'
),

rango as (
    select ambito, min(anio) as amin, max(anio) as amax from pob group by 1
)

select
    t.anio,
    t.ambito,
    t.cod_territorio,
    t.territorio,
    t.entidad,
    t.tipo_entidad,
    (t.entidad ilike '%loter%' or t.entidad ilike '%SELAE%') as es_loterias,
    t.importe_eur as importe_eur_nominal,
    t.importe_eur * d.factor as importe_eur_real,
    t.importe_eur * d.factor / p.poblacion as eur_hab_real,
    cast(p.poblacion as bigint) as poblacion,
    t.iva_incluido,
    t.base,
    t.magnitud,
    t.nota
from todo t
join rango r on r.ambito = t.ambito
left join pob p on p.ambito = t.ambito and p.cod = t.cod_territorio
    and p.anio = greatest(least(t.anio, r.amax), r.amin)
left join {{ ref('deflactor') }} d on d.anio = t.anio
order by t.anio, t.ambito, t.cod_territorio, t.importe_eur desc
