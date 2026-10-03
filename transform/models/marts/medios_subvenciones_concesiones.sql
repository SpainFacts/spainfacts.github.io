-- Concesiones de subvenciones a medios de comunicación privados, una fila por
-- concesión. Fuente: Base de Datos Nacional de Subvenciones (BDNS/SNPSAP, IGAE),
-- API /concesiones/busqueda filtrada por las convocatorias con incluir = true de
-- la seed medios_subvenciones_convocatorias (lista curada; criterio en su .yml).
-- - anio = año de la fecha de concesión (no el de la convocatoria).
-- - importe_eur = importe concedido; en préstamos y garantías se usa la ayuda
--   equivalente (el principal del préstamo no es una subvención).
-- - nivel y cod_ccaa salen de la seed (comunidad del ámbito del concedente;
--   '00' = Estado). Las locales llevan la comunidad del ayuntamiento/diputación.
-- - importe_eur_real = euros de 2025 con main.deflactor (IPC medio anual).
-- - Personas físicas: sin nombre (la ingesta ya lo guarda null); NIF enmascarado.
-- Concedido no es pagado: la BDNS no publica pagos ni siempre refleja reintegros.
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
)

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
    (case when upper(coalesce(c.instrumento, '')) like '%PR_STAMO%'
            or upper(coalesce(c.instrumento, '')) like '%GARANT%'
          then coalesce(c.ayuda_equivalente, 0)
          else coalesce(c.importe, 0) end) * d.factor as importe_eur_real
from conc c
join conv v on v.cod_bdns = c.cod_bdns
left join defl d on d.anio = cast(year(cast(c.fecha_concesion as date)) as integer)
