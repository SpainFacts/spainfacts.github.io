-- Concesiones de subvenciones a medios de comunicación privados, una fila por
-- concesión. Dos fuentes (columna fuente):
--   'bdns' Base de Datos Nacional de Subvenciones (BDNS/SNPSAP, IGAE), API
--          /concesiones/busqueda filtrada por las convocatorias con incluir = true de
--          la seed medios_subvenciones_convocatorias (lista curada; criterio en su .yml).
--   'bopv' Boletín Oficial del País Vasco: resoluciones de concesión del Gobierno Vasco,
--          que no publica en la BDNS sus ayudas a medios (ingestion/medios_subvenciones_pv.py):
--          Hedabideak (medios en euskera, plurianual), euskera en medios en castellano,
--          ayudas COVID-19 de 2021 y 2022 e IA generativa 2024-2025. Las plurianuales
--          (Hedabideak) van en una fila por anualidad: anio = ejercicio de la anualidad
--          y fecha_concesion = fecha de la resolución; solo se incluyen las anualidades
--          de 2018 al año en curso (raw guarda también 2016-2017 y las futuras, 2027-2028). Son concesiones del Gobierno Vasco: no se
--          solapan con las diputaciones forales y ayuntamientos vascos de la BDNS.
--          NIF: el BOPV casi nunca lo da; se toma de la seed medios_subvenciones_pv_nif
--          (nombre del BOPV -> NIF, revisada a mano). En la ayuda de IA de 2025 el importe
--          es el final tras la Orden de 21-1-2026 (que rebajó varias ayudas).
-- - anio = año de la fecha de concesión (no el de la convocatoria), salvo anualidades BOPV.
-- - importe_eur = importe concedido; en préstamos y garantías se usa la ayuda
--   equivalente (el principal del préstamo no es una subvención).
-- - nivel y cod_ccaa salen de la seed (comunidad del ámbito del concedente;
--   '00' = Estado). Las locales llevan la comunidad del ayuntamiento/diputación.
--   BOPV: nivel 'autonomico', cod_ccaa '16'.
-- - importe_eur_real = euros de 2025 con main.deflactor (IPC medio anual).
-- - Personas físicas: sin nombre (la ingesta ya lo guarda null); NIF enmascarado.
-- Concedido no es pagado: ni la BDNS ni el BOPV publican pagos ni siempre reflejan reintegros.
with conc as (
    select *
    from {{ source('raw_medios_subvenciones', 'bdns_concesiones_medios') }}
),

conv as (
    select cod_bdns, nivel, cod_ccaa, organo, tipo_ayuda, titulo
    from {{ ref('medios_subvenciones_convocatorias') }}
    where incluir
),

defl as (
    select cast(anio as integer) as anio, factor from {{ ref('deflactor') }}
),

pv_nif as (
    select nombre_bopv, any_value(nif) as nif
    from {{ ref('medios_subvenciones_pv_nif') }}
    where nif is not null
    group by 1
),

bdns as (
    select
        c.cod_concesion,
        c.cod_bdns,
        v.titulo as convocatoria,
        cast(c.fecha_concesion as date) as fecha_concesion,
        cast(year(cast(c.fecha_concesion as date)) as integer) as anio,
        v.nivel,
        v.cod_ccaa,
        v.tipo_ayuda,
        c.concedente_nivel1,
        c.concedente_nivel2,
        c.concedente_nivel3,
        upper(trim(c.beneficiario_nif)) as beneficiario_nif,
        case when c.es_persona_fisica then null else c.beneficiario_nombre end as beneficiario_nombre,
        coalesce(c.es_persona_fisica, false) as es_persona_fisica,
        c.instrumento,
        c.importe as importe_concedido_eur,
        c.ayuda_equivalente as ayuda_equivalente_eur,
        case when upper(coalesce(c.instrumento, '')) like '%PR_STAMO%'
               or upper(coalesce(c.instrumento, '')) like '%GARANT%'
             then coalesce(c.ayuda_equivalente, 0)
             else coalesce(c.importe, 0) end as importe_eur,
        'bdns' as fuente,
        'https://www.infosubvenciones.es/bdnstrans/GE/es/convocatorias/' || c.cod_bdns as url_fuente
    from conc c
    join conv v on v.cod_bdns = c.cod_bdns
),

bopv as (
    select
        p.cod_concesion,
        'BOPV ' || p.cod_bopv as cod_bdns,
        p.convocatoria,
        cast(p.fecha_concesion as date) as fecha_concesion,
        cast(p.anio as integer) as anio,
        'autonomico' as nivel,
        '16' as cod_ccaa,
        p.tipo_ayuda,
        p.concedente_nivel1,
        p.concedente_nivel2,
        p.concedente_nivel3,
        case when p.es_persona_fisica then null
             else upper(trim(coalesce(p.beneficiario_nif, n.nif))) end as beneficiario_nif,
        case when p.es_persona_fisica then null else p.beneficiario_nombre_bopv end as beneficiario_nombre,
        coalesce(p.es_persona_fisica, false) as es_persona_fisica,
        'SUBVENCIÓN y ENTREGA DINERARIA SIN CONTRAPRESTACIÓN' as instrumento,
        p.importe as importe_concedido_eur,
        p.importe as ayuda_equivalente_eur,
        coalesce(p.importe, 0) as importe_eur,
        'bopv' as fuente,
        p.url_bopv as url_fuente
    from {{ source('raw_medios_subvenciones_pv', 'pv_concesiones_medios') }} p
    left join pv_nif n on n.nombre_bopv = p.beneficiario_nombre_bopv
    where p.anio between 2018 and year(current_date)
),

todo as (
    select * from bdns
    union all by name
    select * from bopv
)

select
    t.cod_concesion,
    t.cod_bdns,
    t.convocatoria,
    t.fecha_concesion,
    t.anio,
    t.nivel,
    t.cod_ccaa,
    t.tipo_ayuda,
    t.concedente_nivel1,
    t.concedente_nivel2,
    t.concedente_nivel3,
    t.beneficiario_nif,
    t.beneficiario_nombre,
    t.es_persona_fisica,
    t.instrumento,
    t.importe_concedido_eur,
    t.ayuda_equivalente_eur,
    t.importe_eur,
    t.importe_eur * d.factor as importe_eur_real,
    t.fuente,
    t.url_fuente
from todo t
left join defl d on d.anio = t.anio
