-- Contratos menores de los órganos sanitarios y posible fraccionamiento (troceo), por comunidad,
-- órgano y año de adjudicación, desde el 9-3-2018 (LCSP 2017).
-- Fuentes (ingestion/gasto_oculto.py): Andalucía, «Contratación menor publicada en la Plataforma
-- de Contratación de la Junta de Andalucía» (CSV anual, órganos sanitarios; el Servicio Andaluz
-- de Salud es un solo órgano de contratación y se separa por provincia de ejecución); Cataluña,
-- «Publicacions a la Plataforma de serveis de contractació pública» (Socrata ybgg-dgi6,
-- Departament de Salut e ICS, con detalle desde 2023). La Comunidad de Madrid no tiene descarga
-- abierta de sus contratos menores (la exportación del Portal de Contratación pide captcha).
-- Técnica: un contrato menor no puede pasar de 15.000 € sin IVA (servicios, suministros y
-- otros) o 40.000 € (obras), y la ley prohíbe fraccionar un contrato para no licitarlo (art. 99
-- y 118 LCSP). Se buscan grupos del mismo órgano + mismo adjudicatario (NIF) + mismo tipo de
-- contrato en el mismo año con dos o más menores que juntos pasan el umbral:
--   importe_posible_troceo_eur / posible_troceo_pct (0-100, sobre el importe de menores).
-- Criterio estricto (_objeto, el principal): además, mismo «objeto parecido»: grupo CPV de 3
-- cifras en Cataluña y, sin CPV (Andalucía), las dos primeras palabras con contenido del título
-- («BATA QUIRURGICA»). Es una señal para revisar, no una prueba: compras repetidas legítimas al
-- mismo proveedor también suman, y el Servicio Andaluz de Salud y el ICS son un solo órgano de
-- contratación con muchos hospitales, lo que infla el criterio amplio. Las personas físicas no
-- entran en los grupos. Cataluña solo desde 2023 (antes la PSCP no da el detalle de los menores).
-- Importes de adjudicación sin IVA; _real en euros constantes de anio_base.
with g as (
    select
        cod_ccaa, ccaa, fuente, cast(anio as integer) as anio, organo, nif_adjudicatario,
        tipo_contrato, clave_objeto, cast(n_contratos as integer) as n_contratos,
        importe_sin_iva_eur
    from {{ source('raw_gasto_oculto', 'gasto_oculto_menores_grupos') }}
    where cast(anio as integer) <= year(current_date)
      and (cod_ccaa <> '09' or cast(anio as integer) >= 2023)
),

umbral as (
    select *, case when tipo_contrato = 'Obras' then 40000 else 15000 end as umbral_eur
    from g
),

-- criterio 1: órgano + adjudicatario + tipo (agrupa los CPV)
grupo_tipo as (
    select cod_ccaa, anio, organo, nif_adjudicatario, tipo_contrato, max(umbral_eur) as umbral_eur,
        sum(n_contratos) as n, sum(importe_sin_iva_eur) as imp
    from umbral
    where nif_adjudicatario <> 'PERSONA_FISICA'
    group by all
),

-- criterio 2: órgano + adjudicatario + tipo + objeto parecido (CPV de 3 cifras o palabras del título)
grupo_objeto as (
    select cod_ccaa, anio, organo, nif_adjudicatario, tipo_contrato, clave_objeto, max(umbral_eur) as umbral_eur,
        sum(n_contratos) as n, sum(importe_sin_iva_eur) as imp
    from umbral
    where nif_adjudicatario <> 'PERSONA_FISICA' and clave_objeto is not null
    group by all
),

totales as (
    select cod_ccaa, ccaa, fuente, anio, organo,
        sum(n_contratos) as n_contratos,
        sum(importe_sin_iva_eur) as importe_eur,
        count(distinct nif_adjudicatario) filter (where nif_adjudicatario <> 'PERSONA_FISICA') as n_adjudicatarios,
        bool_or(clave_objeto like 'CPV %') as tiene_cpv
    from g
    group by all
),

troceo_tipo as (
    select cod_ccaa, anio, organo,
        count(*) as n_grupos_troceo,
        sum(n) as n_contratos_troceo,
        sum(imp) as importe_posible_troceo_eur
    from grupo_tipo
    where n >= 2 and imp > umbral_eur
    group by all
),

troceo_objeto as (
    select cod_ccaa, anio, organo,
        count(*) as n_grupos_troceo_objeto,
        sum(n) as n_contratos_troceo_objeto,
        sum(imp) as importe_posible_troceo_objeto_eur
    from grupo_objeto
    where n >= 2 and imp > umbral_eur
    group by all
)

select
    t.cod_ccaa,
    t.ccaa,
    t.fuente,
    t.anio,
    t.organo,
    t.n_contratos,
    t.n_adjudicatarios,
    t.importe_eur,
    t.importe_eur * d.factor as importe_eur_real,
    coalesce(a.n_grupos_troceo, 0) as n_grupos_troceo,
    coalesce(a.n_contratos_troceo, 0) as n_contratos_troceo,
    coalesce(a.importe_posible_troceo_eur, 0) as importe_posible_troceo_eur,
    coalesce(a.importe_posible_troceo_eur, 0) * d.factor as importe_posible_troceo_eur_real,
    case when t.importe_eur > 0 then 100 * coalesce(a.importe_posible_troceo_eur, 0) / t.importe_eur end as posible_troceo_pct,
    coalesce(c.n_grupos_troceo_objeto, 0) as n_grupos_troceo_objeto,
    coalesce(c.n_contratos_troceo_objeto, 0) as n_contratos_troceo_objeto,
    coalesce(c.importe_posible_troceo_objeto_eur, 0) as importe_posible_troceo_objeto_eur,
    coalesce(c.importe_posible_troceo_objeto_eur, 0) * d.factor as importe_posible_troceo_objeto_eur_real,
    case when t.importe_eur > 0 then 100 * coalesce(c.importe_posible_troceo_objeto_eur, 0) / t.importe_eur end as posible_troceo_objeto_pct,
    case when t.tiene_cpv then 'CPV (3 cifras)' else 'Palabras del título' end as criterio_objeto,
    d.anio_base,
    t.anio = year(current_date) as es_parcial
from totales as t
left join troceo_tipo as a
  on a.cod_ccaa = t.cod_ccaa and a.anio = t.anio and a.organo = t.organo
left join troceo_objeto as c
  on c.cod_ccaa = t.cod_ccaa and c.anio = t.anio and c.organo = t.organo
left join {{ ref('deflactor') }} as d
  on d.anio = t.anio
order by t.cod_ccaa, t.anio, t.importe_eur desc
