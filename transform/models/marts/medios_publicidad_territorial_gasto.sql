-- Publicidad institucional y de empresas públicas de comunidades autónomas y
-- grandes ayuntamientos, en formato largo y normalizado (una fila por
-- organismo × medio × campaña según lo que dé cada fuente). Base de los marts
-- medios_publicidad_territorial_anual, _medios y medios_publicidad_empresas_anual.
-- Une dos orígenes con las mismas columnas:
--   * raw.pubt_gasto (ingestion/medios_publicidad_territorial.py): Cataluña
--     (Socrata 8d5a-6vsk, neto sin IVA ni comisión), Castilla y León
--     (Opendatasoft, IVA no indicado), Aragón (Excel, con IVA, adjudicado),
--     Navarra (CKAN, IVA no indicado), Murcia (OData, contratos con IVA),
--     Ayuntamiento de Madrid (datos.madrid.es 300024, se guarda sin IVA) y
--     Ajuntament de Barcelona (Open Data BCN, por tipo de medio).
--   * raw.pubt_planes_cm (mismo módulo, ingestion/medios_planes_madrid.py): planes
--     de medios de la Comunidad de Madrid 2020- (ZIP de Excel del Portal de
--     Transparencia), neto sin IVA, base 'planificado'.
--   * seed medios_publicidad_territorial_manual: Comunitat Valenciana (PDF
--     gvaoberta, sin IVA), País Vasco (JSON de gobiernovasco.marketing, CC BY
--     4.0), Canal de Isabel II (cuenta 627, solo referencia: cuenta_en_total
--     false) y TMB (PDF de transparencia).
--   * seed medios_publicidad_canal_planes: planes de medios de Canal de Isabel II
--     2019-2025 por soporte (PDF de su portal), neto sin IVA, 'planificado'
--     (2019: 'ejecutado').
-- Añade: tipo_medio_norm (prensa, radio, television, digital, redes_sociales,
-- exterior, cine, creatividad_produccion, otros) a partir del texto de cada
-- fuente, y grupo mediático normalizado con el seed medios_grupos_equivalencias
-- (por el nombre del medio y, si no, por la empresa que da la fuente). Lo que
-- no está en la tabla de equivalencias conserva su nombre como grupo.
-- importe_sin_iva_eur: importe homogeneizado sin IVA (÷1,21 si la fuente lo da
-- con IVA; tal cual si lo da sin IVA o no lo indica, con aviso en iva_criterio).
with ingesta as (
    select
        cast(cod_ccaa as varchar) as cod_ccaa,
        cast(nivel as varchar) as nivel,
        cast(cod_municipio as varchar) as cod_municipio,
        cast(anio as integer) as anio,
        organismo_pagador, es_empresa_publica, medio, grupo as grupo_fuente, tipo_medio, campana,
        importe_eur, iva_incluido, base, cuenta_en_total, fuente, nota,
        'ingesta' as origen
    from {{ source('raw_medios_publicidad_territorial', 'pubt_gasto') }}
),

manual as (
    select
        cast(cod_ccaa as varchar) as cod_ccaa,
        cast(nivel as varchar) as nivel,
        nullif(cast(cod_municipio as varchar), '') as cod_municipio,
        cast(anio as integer) as anio,
        organismo_pagador, es_empresa_publica,
        nullif(medio, '') as medio, nullif(grupo, '') as grupo_fuente, nullif(tipo_medio, '') as tipo_medio,
        cast(null as varchar) as campana,
        importe_eur, iva_incluido, base, cuenta_en_total, fuente, nota,
        'seed' as origen
    from {{ ref('medios_publicidad_territorial_manual') }}
),

planes_cm as (
    select
        cast(cod_ccaa as varchar) as cod_ccaa,
        cast(nivel as varchar) as nivel,
        cast(cod_municipio as varchar) as cod_municipio,
        cast(anio as integer) as anio,
        organismo_pagador, es_empresa_publica, medio, grupo as grupo_fuente, tipo_medio, campana,
        importe_eur, iva_incluido, base, cuenta_en_total, fuente, nota,
        'ingesta' as origen
    from {{ source('raw_medios_publicidad_territorial', 'pubt_planes_cm') }}
),

canal as (
    select
        cast(cod_ccaa as varchar) as cod_ccaa,
        cast(nivel as varchar) as nivel,
        nullif(cast(cod_municipio as varchar), '') as cod_municipio,
        cast(anio as integer) as anio,
        organismo_pagador, es_empresa_publica,
        nullif(medio, '') as medio, nullif(grupo, '') as grupo_fuente, nullif(tipo_medio, '') as tipo_medio,
        nullif(campana, '') as campana,
        importe_eur, iva_incluido, base, cuenta_en_total, fuente, nota,
        'seed' as origen
    from {{ ref('medios_publicidad_canal_planes') }}
),

todo as (
    select * from ingesta
    union all
    select * from manual
    union all
    select * from planes_cm
    union all
    select * from canal
),

equiv as (
    select upper(regexp_replace(trim(nombre_fuente), '\s+', ' ', 'g')) as clave,
        any_value(grupo_normalizado) as grupo, any_value(tipo_grupo) as tipo_grupo,
        bool_or(es_publico) as es_publico
    from {{ ref('medios_grupos_equivalencias') }}
    group by 1
),

norm as (
    select t.*,
        upper(strip_accents(coalesce(t.tipo_medio, ''))) as tu,
        upper(regexp_replace(trim(t.medio), '\s+', ' ', 'g')) as clave_medio,
        upper(regexp_replace(trim(t.grupo_fuente), '\s+', ' ', 'g')) as clave_grupo
    from todo t
)

select
    n.cod_ccaa,
    n.nivel,
    n.cod_municipio,
    n.anio,
    n.organismo_pagador,
    coalesce(n.es_empresa_publica, false) as es_empresa_publica,
    n.medio,
    n.grupo_fuente,
    coalesce(em.grupo, eg.grupo, n.grupo_fuente, n.medio) as grupo,
    coalesce(em.tipo_grupo, eg.tipo_grupo) as tipo_grupo,
    coalesce(em.es_publico, eg.es_publico, false) as es_medio_publico,
    n.tipo_medio,
    case
        when n.tu = '' then null
        when n.tu like '%CREATIV%' or n.tu like '%PRODUC%' then 'creatividad_produccion'
        when n.tu like '%REDES%' or n.tu like '%XARXES%' or n.tu like '%SOCIAL%' then 'redes_sociales'
        when n.tu like '%DIGITAL%' or n.tu like '%INTERNET%' or n.tu like '%ONLINE%' or n.tu like '%WEB%'
            or n.tu like '%PROGRAMAT%' or n.tu like '%APLICACION%' or n.tu like '%APPS%' then 'digital'
        when n.tu like '%TELEVIS%' or n.tu like '%TV%' then 'television'
        when n.tu like '%RADIO%' or n.tu like '%EMISSORES%' then 'radio'
        when n.tu like '%CINE%' then 'cine'
        when n.tu like '%EXTERIOR%' or n.tu like '%MARQUESIN%' or n.tu like '%TRANSPORTE%'
            or n.tu like '%MOBILIARIO%' or n.tu like '%CARTEL%' then 'exterior'
        when n.tu like '%PRENSA%' or n.tu like '%PREMSA%' or n.tu like '%IMPRES%' or n.tu like '%DIARIO%'
            or n.tu like '%REVIST%' or n.tu like '%PERIOD%' or n.tu like '%PROXIMITAT%' then 'prensa'
        else 'otros'
    end as tipo_medio_norm,
    n.campana,
    n.importe_eur,
    case when n.iva_incluido then n.importe_eur / 1.21 else n.importe_eur end as importe_sin_iva_eur,
    n.iva_incluido,
    case
        when n.iva_incluido then 'con IVA en la fuente: se divide entre 1,21'
        when n.iva_incluido = false then 'sin IVA en la fuente'
        else 'la fuente no indica el IVA: se toma tal cual'
    end as iva_criterio,
    n.base,
    n.cuenta_en_total,
    n.fuente,
    n.nota,
    n.origen
from norm n
left join equiv em on em.clave = n.clave_medio
left join equiv eg on eg.clave = n.clave_grupo
