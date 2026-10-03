-- Contratos públicos adjudicados a empresas de medios de comunicación: una fila por
-- contrato (expediente × órgano × lote × adjudicatario) deduplicado.
-- Fuente: Plataforma de Contratación del Sector Público (PLACSP, Ministerio de
-- Hacienda), sindicación de datos abiertos: perfiles alojados (643), plataformas
-- autonómicas agregadas sin menores (1044) y contratos menores (1143), ficheros
-- anuales 2018-2025 y mensuales desde 2026 (ingestion/medios_contratos.py).
-- - Adjudicatario: solo NIF del padrón curado (seed medios_padron_nif, es_medio
--   'si' o 'gris'), que da grupo, tipo de medio y titularidad. Se unen las dos
--   tablas raw (padrón y candidatos por nombre) para que un NIF añadido después al
--   padrón entre sin volver a descargar.
-- - Deduplicado: la ingesta ya se queda con la última actualización por clave; aquí
--   se quita además el mismo contrato que llega por dos conjuntos (perfiles y
--   menores), quedándose con el de actualización más reciente.
-- - anio = año de adjudicación (AwardDate) si es verosímil (2010 .. año de la última
--   actualización); si falta (siempre en la agregación) o es una errata (años 16, 202,
--   2105...), el de la última actualización (fecha_es_actualizacion = true).
-- - Importe = adjudicado sin IVA (no pagado). Euros reales de 2025 con main.deflactor.
-- - sospechoso = importe > 5 M€ sin revisar (acuerdos marco con el importe total,
--   errores de tecleo) o acuerdo marco de 1 M€ o más en el que varios adjudicatarios
--   del mismo lote figuran con el mismo importe (cada uno con el total). Se excluye
--   de los totales. Los menores de más de 15.000 € (servicios) existen: suelen ser
--   suscripciones anuales mal tipificadas por el órgano y se mantienen.
-- - categoria (reglas de texto sobre el objeto, por este orden):
--   patrocinio_eventos (patrocinio, foro, jornada, congreso, premios, gala,
--   desayuno, encuentro, aniversario, gira, certamen, cumbre...), suscripciones_servicios_
--   informativos (suscripción, servicio de noticias o de agencia, teletipos,
--   prensa diaria), especiales_suplementos_revistas (suplemento, especial,
--   monográfico, revista, separata, anuario, guía), publicidad_inserciones
--   (inserción, anuncio, publicidad, campaña, cuña, spot, banner, difusión,
--   promoción, edicto) y otros.
-- - Plataformas autonómicas y municipales (fuente_plataforma <> 'placsp', id_conjunto =
--   'plataformas_autonomicas'; ingestion/medios_contratos_ccaa.py): contratos MENORES que PLACSP no
--   trae de Cataluña (cat_pscp con NIF; cat_rpc, Registre públic de contractes, casado por nombre:
--   metodo_casado = 'nombre'), Euskadi (eus_kontratazioa), Junta de Andalucía (and_junta), Xunta de
--   Galicia (gal_xunta), Gobierno de La Rioja (rio_car), Ayuntamiento de Madrid (mad_ayto),
--   Ajuntament de Barcelona 2018 (bcn_ayto), Comunidad de Madrid (mad_cm, buscador del Portal de
--   Contratación por NIF) y Navarra (nav_portal, relaciones trimestrales de facturas de menor cuantía:
--   una fila por factura, casada por nombre o NIF). Solo menores (los no menores de esas plataformas ya
--   llegan por la agregación de PLACSP). Se quitan (a) los menores del Registre que también están en la
--   PSCP (mismo NIF e importe, mismo ente o expediente, a 31 días o menos) y (b) los que ya llegan por
--   PLACSP (mismo NIF, importe a un 1 %, misma comunidad y ámbito, y mismo expediente o mismo
--   municipio con fecha a 3 días o menos).
--   importe_sin_iva_estimado = true en gal_xunta, rio_car, mad_ayto y nav_portal, que solo dan el importe con IVA
--   (se divide entre 1,04 en suscripciones y prensa y entre 1,21 en el resto). El municipio del órgano
--   solo se conserva si existe en el nomenclátor.
-- - Municipio del órgano: el que deduce la ingesta (DIR3 L01 + código INE o NIF del
--   ayuntamiento P+INE+00) y, si falta, el nombre «Ayuntamiento de X / Ajuntament
--   de X / Concello de X / X-ko Udala» casado con el nomenclátor de la misma comunidad.
with raw as (
    select * from {{ source('raw_medios_contratos', 'pcsp_contratos_medios') }}
    union all by name
    select * from {{ source('raw_medios_contratos', 'pcsp_candidatos_medios') }}
),

padron as (
    select upper(trim(nif)) as nif, nombre as nombre_padron, grupo, tipo as tipo_medio,
        titularidad, es_medio
    from {{ ref('medios_padron_nif') }}
    where es_medio in ('si', 'gris')
),

clave as (
    select r.*, p.nombre_padron, p.grupo, p.tipo_medio, p.titularidad, p.es_medio,
        row_number() over (
            partition by r.id_conjunto, r.expediente, r.organo_clave, r.lote, r.nif_adjudicatario
            order by r.fecha_actualizacion desc
        ) as rn_conjunto
    from raw r
    join padron p on p.nif = r.nif_adjudicatario
    where coalesce(r.estado, '') <> 'ANUL'
),

unico as (
    select *,
        row_number() over (
            partition by expediente, organo_clave, lote, nif_adjudicatario
            order by fecha_actualizacion desc, case id_conjunto when 'menores' then 0 when 'perfiles' then 1 else 2 end
        ) as rn
    from clave
    where rn_conjunto = 1
),

munis as (
    -- nomenclátor: nombres normalizados (con «X, La» -> «la x» y variantes bilingües «A/B»)
    select cod_mun, cod_ccaa, municipio,
        trim(regexp_replace(lower(strip_accents(
            case when nom like '%, %' then split_part(nom, ', ', 2) || ' ' || split_part(nom, ', ', 1) else nom end
        )), '[^a-z0-9 ]', ' ', 'g')) as nom_norm
    from (
        select cod_mun, cod_ccaa, municipio, unnest(string_split(municipio, '/')) as nom
        from {{ ref('poblacion_municipios') }}
        where sexo = 'Total' and anio = (select max(anio) from {{ ref('poblacion_municipios') }})
    )
),

munis_unicos as (
    select cod_ccaa, regexp_replace(nom_norm, '\s+', ' ', 'g') as nom_norm, any_value(cod_mun) as cod_mun
    from munis
    group by all
    having count(distinct cod_mun) = 1
),

con_nombre as (
    select u.*,
        trim(regexp_replace(regexp_replace(lower(strip_accents(coalesce(
            nullif(regexp_extract(u.organo, '(?i)ayuntamiento de (.+)$', 1), ''),
            nullif(regexp_extract(u.organo, '(?i)ajuntament d(?:e |'')(.+)$', 1), ''),
            nullif(regexp_extract(u.organo, '(?i)concello d(?:e|a|o|as|os) (.+)$', 1), ''),
            nullif(regexp_extract(u.organo, '(?i)^(.+?)(?:ko|go) udala', 1), ''),
            nullif(regexp_extract(u.organo, '(?i)^(.+?) udala', 1), '')
        ))), '[^a-z0-9 ]', ' ', 'g'), '\s+', ' ', 'g')) as organo_mun_norm
    from unico u
    where u.rn = 1
),

base_placsp as (
    select c.*,
        coalesce(c.cod_municipio, case when c.nivel = 'local' and nullif(c.organo_mun_norm, '') is not null then m.cod_mun end) as cod_mun_final,
        lower(strip_accents(coalesce(c.objeto, ''))) as obj,
        'placsp' as fuente_plataforma,
        'nif' as metodo_casado,
        false as importe_sin_iva_estimado
    from con_nombre c
    left join munis_unicos m on m.cod_ccaa = c.cod_ccaa and m.nom_norm = c.organo_mun_norm
),

-- ---- Plataformas autonómicas y municipales (ingestion/medios_contratos_ccaa.py) ----------------
ccaa_raw as (
    select * from {{ source('raw_medios_contratos_ccaa', 'ccaa_contratos_medios') }}
    union all by name
    select * from {{ source('raw_medios_contratos_ccaa', 'ccaa_candidatos_medios') }}
),

ccaa_padron as (
    select r.*, p.nombre_padron, p.grupo, p.tipo_medio, p.titularidad, p.es_medio,
        try_cast(r.fecha_adjudicacion as date) as fa,
        upper(regexp_replace(coalesce(r.expediente, ''), '[^A-Za-z0-9]', '', 'g')) as exp_norm
    from ccaa_raw r
    join padron p on p.nif = r.nif_adjudicatario
    where try_cast(r.fecha_adjudicacion as date) is not null
        and year(try_cast(r.fecha_adjudicacion as date)) >= 2018
        and coalesce(r.estado, '') not in ('Desert', 'Desistiment', 'Renúncia', 'Anul·lació', 'Anulación', 'Desierto', 'Desistimiento', 'Renuncia')
        and coalesce(r.importe_sin_iva, 0) >= 0
),

-- El mismo menor en la PSCP y en el Registre públic de contractes (mismo NIF e importe, mismo ente
-- o expediente, fechas a 31 días o menos): se queda el de la PSCP, que trae el NIF.
ccaa_cat as (
    select c.*
    from ccaa_padron c
    where c.plataforma <> 'cat_rpc'
        or not exists (
            select 1 from ccaa_padron p
            where p.plataforma = 'cat_pscp'
                and p.nif_adjudicatario = c.nif_adjudicatario
                and abs(coalesce(p.importe_sin_iva, -1) - coalesce(c.importe_sin_iva, -2)) < 1
                and (p.organo_id = c.organo_id or (p.exp_norm = c.exp_norm and p.exp_norm <> ''))
                and abs(date_diff('day', p.fa, c.fa)) <= 31
        )
),

placsp_ref as (
    select nif_adjudicatario, cod_ccaa, id_conjunto, ambito, cod_mun_final as cod_mun,
        try_cast(fecha_adjudicacion as date) as fa,
        importe_adjudicado_sin_iva as imp_sin, importe_adjudicado_con_iva as imp_con,
        upper(regexp_replace(coalesce(expediente, ''), '[^A-Za-z0-9]', '', 'g')) as exp_norm
    from base_placsp
),

-- Contratos que ya llegan por PLACSP (menores de órganos que publican en los dos sitios, y no menores
-- que llegan por la agregación): mismo NIF, importe a un 1 % (sin IVA, o con IVA si la plataforma
-- solo da el importe con IVA), misma comunidad y ámbito, y mismo expediente o mismo municipio del
-- órgano con fecha de adjudicación a 3 días o menos. (Casar solo por NIF, importe y fecha daba
-- falsos duplicados: suscripciones al mismo precio de órganos distintos.)
ccaa_dedup as (
    select c.*,
        exists (
            select 1 from placsp_ref p
            where p.nif_adjudicatario = c.nif_adjudicatario
                and p.cod_ccaa = c.cod_ccaa
                and p.ambito = c.ambito
                and (
                    abs(p.imp_sin - c.importe_sin_iva) <= greatest(1, 0.01 * p.imp_sin)
                    or (c.importe_sin_iva_estimado and abs(p.imp_con - c.importe_con_iva) <= greatest(1, 0.01 * p.imp_con))
                )
                and (
                    (p.exp_norm = c.exp_norm and c.exp_norm <> '')
                    or (p.cod_mun = c.cod_municipio and abs(date_diff('day', p.fa, c.fa)) <= 3)
                )
        ) as ya_en_placsp
    from ccaa_cat c
),

munis_cod as (
    select distinct cod_mun from munis
),

base_ccaa as (
    select
        'plataformas_autonomicas' as id_conjunto,
        c.expediente,
        c.organo,
        coalesce(c.organo_id, c.organo) as organo_clave,
        c.nif_organo,
        c.dir3,
        cast(null as varchar) as id_plataforma_organo,
        c.plataforma,
        cast(null as varchar) as tipo_organo_code,
        c.organo_superior as organo_padres,
        c.nivel,
        c.ambito,
        c.cod_ccaa,
        coalesce(mc.cod_mun, case when c.ambito = 'local' and nullif(c.organo_mun_norm, '') is not null then mn.cod_mun end) as cod_mun_final,
        coalesce(c.lote, '') as lote,
        c.nif_adjudicatario,
        c.nombre_padron,
        c.nombre_adjudicatario,
        c.grupo, c.tipo_medio, c.titularidad, c.es_medio,
        c.objeto,
        c.cpv,
        case
            when regexp_matches(lower(strip_accents(coalesce(c.tipo_contrato, ''))), 'servei|servici|servizo|zerbitzu') then '2'
            when regexp_matches(lower(strip_accents(coalesce(c.tipo_contrato, ''))), 'subministr|suministr|subministracion|horni') then '1'
            when regexp_matches(lower(strip_accents(coalesce(c.tipo_contrato, ''))), 'obra') then '3'
            when regexp_matches(lower(strip_accents(coalesce(c.tipo_contrato, ''))), 'privad') then '8'
            when regexp_matches(lower(strip_accents(coalesce(c.tipo_contrato, ''))), 'especial') then '7'
            else c.tipo_contrato
        end as tipo_contrato,
        c.procedimiento,
        c.es_menor,
        c.estado,
        1 as n_adjudicatarios,
        c.importe_sin_iva as importe_adjudicado_sin_iva,
        cast(null as double) as presupuesto_sin_iva,
        c.fecha_adjudicacion,
        cast(c.cargado_en as varchar) as fecha_actualizacion,
        c.url,
        lower(strip_accents(coalesce(c.objeto, ''))) as obj,
        c.plataforma as fuente_plataforma,
        c.metodo_casado,
        coalesce(c.importe_sin_iva_estimado, false) as importe_sin_iva_estimado
    from (
        select d.*,
            trim(regexp_replace(regexp_replace(lower(strip_accents(coalesce(
                nullif(regexp_extract(d.organo, '(?i)ayuntamiento de (.+)$', 1), ''),
                nullif(regexp_extract(d.organo, '(?i)ajuntament d(?:e |'')(.+)$', 1), ''),
                nullif(regexp_extract(d.organo, '(?i)concello d(?:e|a|o|as|os) (.+)$', 1), ''),
                nullif(regexp_extract(d.organo, '(?i)^(.+?)(?:ko|go) udala', 1), ''),
                nullif(regexp_extract(d.organo, '(?i)^(.+?) udala', 1), '')
            ))), '[^a-z0-9 ]', ' ', 'g'), '\s+', ' ', 'g')) as organo_mun_norm
        from ccaa_dedup d
    ) c
    left join munis_cod mc on mc.cod_mun = c.cod_municipio
    left join munis_unicos mn on mn.cod_ccaa = c.cod_ccaa and mn.nom_norm = c.organo_mun_norm
    -- solo los menores (los no menores de estas plataformas llegan por la agregación de PLACSP) y
    -- sin los que ya están en PLACSP
    where c.es_menor and not c.ya_en_placsp
),

base as (
    select * from base_placsp
    union all by name
    select * from base_ccaa
),

clasif as (
    select *,
        case
            when regexp_matches(obj, 'patrocin|\bforo|jornada|congreso|premio|\bgala\b|desayuno|encuentro|aniversario|\bgira\b|summit|ceremonia|certamen|cumbre|homenaje|\bawards\b')
                then 'patrocinio_eventos'
            when regexp_matches(obj, 'suscrip|subscrip|servicio(s)? de (noticias|agencia|informacion)|servei(s)? de (noticies|agencia)|teletipo|agencia de noticias|noticias de agencia|transmision de noticias|suministro (de|del) (la )?(prensa|periodicos?|noticias|diarios?|revistas?)|servicios? informativos|agencias? de noticias|noticias (texto|de ambito)|serveis informatius|prensa diaria|ejemplares|acceso (a|al) (la )?(edicion|hemeroteca|servicio)|hemeroteca|kiosko|kiosco')
                then 'suscripciones_servicios_informativos'
            when regexp_matches(obj, 'suplement|\bespecial|monografi|revista|separata|anuario|\bguia\b|encarte|cuadernillo|libro de fiestas|programa de fiestas|publicacion especial')
                then 'especiales_suplementos_revistas'
            when regexp_matches(obj, 'inserci|anunci|publicidad|publicitari|campana|cuna|\bspot|banner|difusion|promocion|edicto|faldon|robapagina|publirreportaje|reportaje|microespacio|programa|emision|retransmi|comunicacion institucional|informacion institucional|divulgaci|visibilidad|plan de medios|espacios? (en|de)')
                then 'publicidad_inserciones'
            else 'otros'
        end as categoria,
        -- acuerdo marco: varios adjudicatarios del mismo lote con el mismo importe (cada uno figura con el total)
        count(*) over (partition by expediente, organo_clave, lote, importe_adjudicado_sin_iva) as n_iguales,
        -- año: el de adjudicación si es verosímil (2010 .. año de la última actualización); si no, el de actualización
        case when year(try_cast(fecha_adjudicacion as date)) between 2010 and year(try_cast(fecha_actualizacion as timestamp))
             then year(try_cast(fecha_adjudicacion as date))
             else year(try_cast(fecha_actualizacion as timestamp)) end as anio_calc
    from base
)

select
    c.id_conjunto,
    c.expediente,
    c.organo,
    c.organo_clave,
    c.nif_organo,
    c.dir3,
    c.id_plataforma_organo,
    c.plataforma,
    c.tipo_organo_code,
    c.organo_padres,
    c.nivel,
    c.ambito,
    c.cod_ccaa,
    c.cod_mun_final as cod_municipio,
    c.lote,
    c.nif_adjudicatario,
    coalesce(c.nombre_padron, c.nombre_adjudicatario) as adjudicatario,
    c.nombre_adjudicatario,
    c.grupo,
    c.tipo_medio,
    c.titularidad,
    c.es_medio,
    -- objeto sin entidades HTML que algunos órganos dejan en el texto (&nbsp;, &#34;, &lt;br /&gt;...)
    trim(replace(replace(replace(replace(regexp_replace(c.objeto, '&nbsp;|&lt;br ?/?&gt;|<br ?/?>', ' ', 'g'),
        '&#34;', '"'), '&quot;', '"'), '&amp;', '&'), '&#39;', '''')) as objeto,
    c.categoria,
    c.cpv,
    c.tipo_contrato,
    case c.tipo_contrato when '1' then 'suministros' when '2' then 'servicios' when '3' then 'obras'
        when '7' then 'administrativo especial' when '8' then 'privado' when '21' then 'gestion de servicios publicos'
        when '22' then 'concesion de servicios' when '31' then 'concesion de obras' when '40' then 'colaboracion publico-privada'
        when '50' then 'patrimonial' else c.tipo_contrato end as tipo_contrato_nombre,
    c.procedimiento,
    c.es_menor,
    c.estado,
    c.n_adjudicatarios,
    c.importe_adjudicado_sin_iva,
    c.importe_adjudicado_sin_iva * d.factor as importe_eur_real,
    c.presupuesto_sin_iva,
    try_cast(c.fecha_adjudicacion as date) as fecha_adjudicacion,
    try_cast(c.fecha_actualizacion as timestamp) as fecha_actualizacion,
    cast(c.anio_calc as integer) as anio,
    c.anio_calc is distinct from year(try_cast(c.fecha_adjudicacion as date)) as fecha_es_actualizacion,
    (c.importe_adjudicado_sin_iva > 5000000 or (c.n_iguales > 1 and c.importe_adjudicado_sin_iva >= 1000000)) as sospechoso,
    c.url,
    c.fuente_plataforma,
    c.metodo_casado,
    c.importe_sin_iva_estimado
from clasif c
left join {{ ref('deflactor') }} d
    on d.anio = c.anio_calc
