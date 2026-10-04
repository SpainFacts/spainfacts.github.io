{{ config(materialized='ephemeral') }}
-- Base común de medios_receptores y medios_receptores_duplicados (ver ambos).
-- Quién recibe qué: todo lo que cada medio de comunicación ha recibido de las
-- administraciones públicas, en formato largo (una fila por pago o concesión).
-- Une cuatro fuentes ya cargadas:
--   1. Publicidad del Estado por grupo o sociedad, 2025 (medios_publicidad_grupos:
--      Informe 2025 de la Comisión de Publicidad y Comunicación Institucional, anexo IV
--      institucional y anexo III comercial). Solo compra de medios; el informe da el
--      grupo o la sociedad, nunca la cabecera ni la campaña. Se asume IVA incluido
--      (importes múltiplos de 1,21).
--   2. Publicidad institucional de comunidades y ayuntamientos por medio
--      (medios_publicidad_territorial_gasto, filas con medio): importe tal cual lo
--      publica cada fuente, con su marca de IVA y su base (ejecutado/contratado).
--   3. Contratos adjudicados a empresas de medios (medios_contratos_base, PLACSP y
--      plataformas autonómicas, desde 2018): es_medio = 'si', sin sospechosos; importe
--      adjudicado sin IVA.
--   4. Subvenciones a medios privados (medios_subvenciones_concesiones: BDNS desde
--      2022 y, para el Gobierno Vasco, BOPV desde 2018): importe concedido; sin
--      personas físicas.
-- Asignación a un medio (seeds medios_cabeceras y medios_cabeceras_alias): por NIF
-- (contratos y subvenciones), por nombre normalizado exacto o contenido como palabras
-- (publicidad territorial y del Estado; gana el patrón más largo) y, si no casa nada,
-- por el grupo normalizado que ya trae la fuente. nivel_asignacion: 'cabecera' (la
-- fuente da el nombre del medio), 'sociedad' (da la empresa editora: NIF o razón
-- social) o 'grupo' (solo se sabe el grupo, o la sociedad edita varias cabeceras y no
-- se puede separar). Las filas que no casan con ningún medio no entran (ver %
-- asignado en el informe del tema).
-- duplicado_probable: contratos de publicidad o inserciones de una comunidad o
-- ayuntamiento cuya publicidad por medio ya está en la fuente 2 ese año (Castilla y
-- León, Aragón, Cataluña, C. Valenciana, Murcia, Navarra, País Vasco, Ayto. de
-- Madrid): no suman y se publican aparte en medios_receptores_duplicados. La Comunidad
-- de Madrid (planes de medios) no activa la marca: ver cobertura_terr.
-- importe_eur_real = nominal x factor del deflactor (euros de 2025).
with alias as (
    select medio_id, patron, tipo_patron, fuente,
        case tipo_patron when 'nif' then 1 when 'nombre_exacto' then 2 when 'contiene' then 3 else 4 end as prioridad
    from {{ ref('medios_cabeceras_alias') }}
),

cab as (select * from {{ ref('medios_cabeceras') }}),

gobiernos(cod_ccaa, gobierno) as (
    values ('01', 'Junta de Andalucía'), ('02', 'Gobierno de Aragón'), ('03', 'Principado de Asturias'),
        ('04', 'Govern de les Illes Balears'), ('05', 'Gobierno de Canarias'), ('06', 'Gobierno de Cantabria'),
        ('07', 'Junta de Castilla y León'), ('08', 'Junta de Comunidades de Castilla-La Mancha'),
        ('09', 'Generalitat de Catalunya'), ('10', 'Generalitat Valenciana'), ('11', 'Junta de Extremadura'),
        ('12', 'Xunta de Galicia'), ('13', 'Comunidad de Madrid'), ('14', 'Región de Murcia'),
        ('15', 'Gobierno de Navarra'), ('16', 'Gobierno Vasco'), ('17', 'Gobierno de La Rioja'),
        ('18', 'Ciudad de Ceuta'), ('19', 'Ciudad de Melilla')
),

comunidades(cod_ccaa, comunidad) as (
    values ('01', 'Andalucía'), ('02', 'Aragón'), ('03', 'Asturias'), ('04', 'Illes Balears'), ('05', 'Canarias'),
        ('06', 'Cantabria'), ('07', 'Castilla y León'), ('08', 'Castilla-La Mancha'), ('09', 'Cataluña'),
        ('10', 'Comunitat Valenciana'), ('11', 'Extremadura'), ('12', 'Galicia'), ('13', 'Comunidad de Madrid'),
        ('14', 'Región de Murcia'), ('15', 'Navarra'), ('16', 'País Vasco'), ('17', 'La Rioja'),
        ('18', 'Ceuta'), ('19', 'Melilla')
),

municipios as (
    select cod_mun, any_value(municipio) as municipio
    from {{ ref('poblacion_municipios') }}
    group by cod_mun
),

-- ---------- 1. Publicidad del Estado 2025 (por grupo o sociedad)
age as (
    select 'age' as fuente_cod, row_number() over () as fila,
        cast(anio as integer) as anio,
        case tipo when 'institucional' then 'Publicidad institucional del Estado'
            else 'Publicidad comercial de empresas del Estado' end as via,
        case tipo when 'institucional' then 'Administración General del Estado (ministerios)'
            else 'Empresas y entidades comerciales del Estado' end as administracion,
        'Estado' as gobierno,
        'estatal' as nivel_admin,
        '00' as cod_ccaa,
        'estatal' as nivel_partido,
        null::varchar as cod_municipio,
        case tipo when 'institucional' then 'Compra de espacios de las campañas institucionales del año (el informe no da campañas)'
            else 'Compra de espacios de las campañas comerciales del año (el informe no da campañas)' end as concepto,
        grupo as nombre_fuente,
        null::varchar as nif,
        null::varchar as grupo_fuente,
        importe_eur_nominal,
        true as iva_incluido,
        'ejecutado' as base,
        split_part(fuente, ' (', 1) as url,
        'Comisión de Publicidad y Comunicación Institucional, Informe ' || cast(anio as varchar)
            || case tipo when 'institucional' then ', anexo IV (inversión por grupos)' else ' de publicidad comercial, anexo III (inversión por grupos)' end as fuente,
        'El informe del Estado solo da el grupo o la sociedad (no la cabecera) y solo desde 2025; IVA incluido supuesto.' as nota
    from {{ ref('medios_publicidad_grupos') }}
),

-- ---------- 2. Publicidad de comunidades y ayuntamientos (por medio)
terr as (
    select 'territorial' as fuente_cod, row_number() over () as fila,
        cast(t.anio as integer) as anio,
        'Publicidad institucional autonómica/local' as via,
        coalesce(t.organismo_pagador, case when t.nivel = 'local' and t.cod_municipio = '28079' then 'Ayuntamiento de Madrid'
            when t.nivel = 'local' and t.cod_municipio = '08019' then 'Ajuntament de Barcelona' else g.gobierno end) as administracion,
        case when t.nivel = 'local' and t.cod_municipio = '28079' then 'Ayuntamiento de Madrid'
            when t.nivel = 'local' and t.cod_municipio = '08019' then 'Ajuntament de Barcelona'
            else g.gobierno end as gobierno,
        case when t.es_empresa_publica then 'empresa_publica' else t.nivel end as nivel_admin,
        t.cod_ccaa,
        case when t.nivel = 'local' then 'local' else 'autonomico' end as nivel_partido,
        t.cod_municipio,
        t.campana as concepto,
        t.medio as nombre_fuente,
        null::varchar as nif,
        t.grupo as grupo_fuente,
        t.importe_eur as importe_eur_nominal,
        t.iva_incluido,
        t.base,
        null::varchar as url,
        t.fuente,
        t.nota
    from {{ ref('medios_publicidad_territorial_gasto') }} t
    left join gobiernos g on g.cod_ccaa = t.cod_ccaa
    where t.medio is not null and t.importe_eur is not null and t.importe_eur <> 0
),

-- Comunidades y ayuntamientos cuya publicidad institucional por medio ya está en (2):
-- sus contratos de publicidad e inserciones del mismo año son, con toda probabilidad,
-- las mismas campañas, y se marcan como duplicado_probable (fuera de los totales).
-- Solo cuentan las fuentes de lo gastado o contratado por la propia administración: no los
-- PLANES de medios (Comunidad de Madrid y Canal de Isabel II, que compran a través del
-- contrato de la agencia de medios, así que sus contratos menores con medios son otras
-- compras: anuncios de fundaciones, hospitales, la delegación de Canal en Cáceres...) ni las
-- empresas públicas sueltas (Canal 2019 no cubre a la Comunidad).
cobertura_terr as (
    select distinct cod_ccaa, nivel, coalesce(cod_municipio, '') as cod_municipio, cast(anio as integer) as anio
    from {{ ref('medios_publicidad_territorial_gasto') }}
    where medio is not null and base <> 'planificado' and not es_empresa_publica
),

-- ---------- 3. Contratos
contr as (
    select 'contratos' as fuente_cod, row_number() over () as fila,
        cast(c.anio as integer) as anio,
        'Contrato' as via,
        c.organo as administracion,
        case when c.ambito = 'estatal' or c.nivel = 'estatal' then 'Estado'
            when c.ambito = 'autonomico' then coalesce(g.gobierno, 'Comunidades autónomas')
            when c.ambito = 'local' and mu.municipio is not null then 'Ayuntamiento de ' || mu.municipio
            when c.ambito = 'local' then 'Diputaciones y otras entidades locales' || coalesce(' de ' || cm.comunidad, '')
            else 'Otros (universidades, órganos constitucionales, mutuas)' end as gobierno,
        c.nivel as nivel_admin,
        case when c.ambito = 'estatal' or c.nivel = 'estatal' or c.cod_ccaa is null then '00' else c.cod_ccaa end as cod_ccaa,
        case when c.ambito = 'estatal' or c.nivel = 'estatal' then 'estatal'
            when c.ambito = 'autonomico' then 'autonomico'
            when c.ambito = 'local' then 'local' end as nivel_partido,
        c.cod_municipio,
        c.objeto as concepto,
        c.adjudicatario as nombre_fuente,
        upper(replace(c.nif_adjudicatario, ' ', '')) as nif,
        c.grupo as grupo_fuente,
        c.importe_adjudicado_sin_iva as importe_eur_nominal,
        false as iva_incluido,
        'adjudicado' as base,
        c.url,
        case when c.fuente_plataforma = 'placsp' then 'Plataforma de Contratación del Sector Público'
            else 'Plataforma de contratación autonómica o municipal (' || c.fuente_plataforma || ')' end as fuente,
        case when c.importe_sin_iva_estimado then 'Importe sin IVA estimado: la fuente solo da el importe con IVA.' end as nota,
        c.categoria in ('publicidad_inserciones', 'especiales_suplementos_revistas') and exists (
            select 1 from cobertura_terr ct
            where ct.anio = c.anio and ct.cod_ccaa = c.cod_ccaa
                and ((ct.nivel = 'autonomico' and c.ambito = 'autonomico')
                  or (ct.nivel = 'local' and ct.cod_municipio = coalesce(c.cod_municipio, '-')))
        ) as duplicado_probable
    from {{ ref('medios_contratos_base') }} c
    left join gobiernos g on g.cod_ccaa = c.cod_ccaa
    left join comunidades cm on cm.cod_ccaa = c.cod_ccaa
    left join municipios mu on mu.cod_mun = c.cod_municipio
    where c.es_medio = 'si' and not coalesce(c.sospechoso, false)
        and c.importe_adjudicado_sin_iva is not null and c.importe_adjudicado_sin_iva > 0
        and c.anio >= 2018
),

-- ---------- 4. Subvenciones
subv as (
    select 'subvenciones' as fuente_cod, row_number() over () as fila,
        cast(s.anio as integer) as anio,
        'Subvención' as via,
        coalesce(s.concedente_nivel3, s.concedente_nivel2, s.concedente_nivel1) as administracion,
        case s.nivel when 'estatal' then 'Estado'
            when 'autonomico' then coalesce(g.gobierno, s.concedente_nivel2)
            else case when regexp_matches(s.concedente_nivel2, '^(DIPUTACI|CABILDO|CONSELL|CONSEJO|COMARCA|MANCOMUN|CONSORCI|ENTIDAD|ÁREA|AREA|JUNTA)', 'i')
                    then s.concedente_nivel2
                    else 'Ayuntamiento de ' || s.concedente_nivel2 end end as gobierno,
        s.nivel as nivel_admin,
        s.cod_ccaa,
        s.nivel as nivel_partido,
        null::varchar as cod_municipio,
        s.convocatoria as concepto,
        s.beneficiario_nombre as nombre_fuente,
        upper(replace(s.beneficiario_nif, ' ', '')) as nif,
        p.grupo as grupo_fuente,
        s.importe_eur as importe_eur_nominal,
        null::boolean as iva_incluido,
        'concedido' as base,
        s.url_fuente as url,
        case s.fuente when 'bopv' then 'Boletín Oficial del País Vasco (resoluciones de concesión)'
             else 'Base de Datos Nacional de Subvenciones (IGAE)' end as fuente,
        case when s.instrumento is not null and s.importe_concedido_eur <> s.importe_eur
            then 'Importe = ayuda equivalente del préstamo o garantía.' end as nota
    from {{ ref('medios_subvenciones_concesiones') }} s
    left join gobiernos g on g.cod_ccaa = s.cod_ccaa
    left join {{ ref('medios_padron_nif') }} p on p.nif = upper(replace(s.beneficiario_nif, ' ', ''))
    where not s.es_persona_fisica and s.beneficiario_nif is not null and s.importe_eur > 0
),

todo as (
    select * from age
    union all by name select * from terr
    union all by name select * from contr
    union all by name select * from subv
),

-- ---------- Partido que gobernaba la administración que paga, a 1 de julio del año
-- (Gobierno de España o de la comunidad: semilla gobiernos_presidentes; ayuntamientos:
-- alcalde a esa fecha en alcaldes_historia). Diputaciones, cabildos y otras entidades
-- locales sin municipio quedan sin partido.
anios as (select range::integer as anio from range(1977, 2031)),

partido_gobierno as (
    select g.nivel, g.cod, a.anio, any_value(g.familia) as partido, any_value(g.presidente) as quien
    from {{ ref('gobiernos_presidentes') }} g
    join anios a on make_date(a.anio, 7, 1) >= try_cast(cast(g.desde as varchar) as date)
        and make_date(a.anio, 7, 1) < coalesce(try_cast(nullif(cast(g.hasta as varchar), '') as date), date '2100-01-01')
    group by all
),

partido_alcaldia as (
    select h.cod_mun, a.anio, arg_max(h.familia, h.fecha_posesion) as partido, arg_max(h.alcalde, h.fecha_posesion) as quien
    from {{ ref('alcaldes_historia') }} h
    join anios a on make_date(a.anio, 7, 1) >= h.fecha_posesion
        and make_date(a.anio, 7, 1) < coalesce(h.fecha_fin, date '2100-01-01')
    group by all
),

-- ---------- Casado (sobre los valores distintos, no fila a fila)
nombres as (
    select distinct fuente_cod,
        nombre_fuente,
        trim(regexp_replace(lower(strip_accents(nombre_fuente)), '[^a-z0-9]+', ' ', 'g')) as nombre_norm
    from todo where fuente_cod in ('age', 'territorial') and nombre_fuente is not null
),

-- Nombres que no se asignan a nadie: listas de varios medios en una sola fila
-- (planes de medios: «SER, COPE y Onda Cero. PRENSA IMPRESA: ...», «Diversos web
-- internacional (Meta, Google...)») y nombres que la tabla de equivalencias pone en un
-- grupo que no es el suyo (Planeta Calleja es de Cuatro; Nova Conca, revista local;
-- Popular TV Mediterráneo; Global Media & Entertainment, que el informe del Estado
-- distingue de Kiss Media; Marketing Espectacular, agencia de eventos del «Canal de la Navidad»).
no_asignar(nombre_norm) as (
    values ('planeta calleja zanskar aventura'), ('nova conca'), ('nova era publications'),
        ('popular tv mediterraneo'), ('castilla y leon en el mundo'), ('global'), ('global media'),
        ('global media produccion'), ('global media entertaiment s a u'), ('global media entertainment'),
        ('pepe radio madrid'), ('r plus radio madrid'),
        ('marketing espectacular')
),

lista as (
    select n.*,
        (n.fuente_cod = 'territorial' and (
            length(n.nombre_norm) > 60
            or n.nombre_norm like 'diversos %'
            or n.nombre_norm like 'mix %'
            or (length(n.nombre_fuente) - length(replace(n.nombre_fuente, ',', ''))) >= 2
            or n.nombre_fuente like '%:%'))
        or n.nombre_norm in (select nombre_norm from no_asignar) as no_asignable
    from nombres n
),

casa_nombre as (
    select n.fuente_cod, n.nombre_fuente, a.medio_id, a.tipo_patron
    from lista n
    join alias a
        on a.fuente in (n.fuente_cod, 'todas')
        and not n.no_asignable
        and ((a.tipo_patron = 'nombre_exacto' and n.nombre_norm = a.patron)
          or (a.tipo_patron = 'contiene' and (' ' || n.nombre_norm || ' ') like ('% ' || a.patron || ' %')))
    qualify row_number() over (partition by n.fuente_cod, n.nombre_fuente
        order by a.prioridad, length(a.patron) desc, a.medio_id) = 1
),

casa_nif as (
    select patron as nif, medio_id from alias where tipo_patron = 'nif'
    qualify row_number() over (partition by patron order by medio_id) = 1
),

casa_grupo as (
    select patron as grupo_fuente, medio_id from alias where tipo_patron = 'grupo'
    qualify row_number() over (partition by patron order by medio_id) = 1
),

asignado as (
    select t.*,
        coalesce(cn.medio_id, cnom.medio_id, cg.medio_id) as medio_id,
        case when cn.medio_id is not null then 'nif'
            when cnom.medio_id is not null then cnom.tipo_patron
            when cg.medio_id is not null then 'grupo' end as metodo_asignacion
    from todo t
    left join casa_nif cn on cn.nif = t.nif
    left join casa_nombre cnom on cnom.fuente_cod = t.fuente_cod and cnom.nombre_fuente = t.nombre_fuente
    left join lista l on l.fuente_cod = t.fuente_cod and l.nombre_fuente = t.nombre_fuente
    left join casa_grupo cg on cg.grupo_fuente = t.grupo_fuente and not coalesce(l.no_asignable, false)
)

select
    a.medio_id,
    c.medio,
    c.grupo,
    c.tipo as tipo_medio,
    c.titularidad,
    c.tipo = 'plataforma' as es_plataforma,
    case when c.tipo = 'grupo' then 'grupo'
        when a.fuente_cod = 'territorial' then 'cabecera'
        else 'sociedad' end as nivel_asignacion,
    a.metodo_asignacion,
    a.via,
    a.administracion,
    a.gobierno,
    a.nivel_admin,
    a.cod_ccaa,
    ter.nombre as ccaa,
    a.cod_municipio,
    mun.municipio,
    a.anio,
    coalesce(pe.partido, pa.partido, pl.partido) as partido,
    coalesce(pe.quien, pa.quien, pl.quien) as gobernaba,
    a.concepto,
    a.nombre_fuente,
    a.nif,
    a.importe_eur_nominal,
    a.importe_eur_nominal * d.factor as importe_eur_real,
    a.iva_incluido,
    a.base,
    a.url,
    a.fuente,
    a.fuente_cod,
    coalesce(a.duplicado_probable, false) as duplicado_probable,
    a.nota
from asignado a
join cab c on c.medio_id = a.medio_id
left join {{ ref('deflactor') }} d on d.anio = a.anio
left join {{ ref('territorios') }} ter on ter.cod = a.cod_ccaa and ter.nivel = case when a.cod_ccaa = '00' then 'pais' else 'ccaa' end
left join municipios mun on mun.cod_mun = a.cod_municipio
left join partido_gobierno pe on a.nivel_partido = 'estatal' and pe.nivel = 'estatal' and pe.anio = a.anio
left join partido_gobierno pa on a.nivel_partido = 'autonomico' and pa.nivel = 'autonomico' and pa.cod = a.cod_ccaa and pa.anio = a.anio
left join partido_alcaldia pl on a.nivel_partido = 'local' and pl.cod_mun = a.cod_municipio and pl.anio = a.anio
