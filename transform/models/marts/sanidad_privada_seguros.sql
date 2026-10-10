-- Población con seguro sanitario privado por comunidad (INE, encuestas de salud: «modalidad de la
-- cobertura sanitaria (exclusiva)»). ENSE 2006, 2011-12 y 2017 (Encuesta Nacional de Salud,
-- población de todas las edades, tablas de cifras relativas) y EESE 2020 (Encuesta Europea de
-- Salud en España, población de 15 y más años, tabla 47450 en miles de personas: aquí se pasa a %
-- sobre el total sin «No consta», igual que las tablas relativas de la ENSE).
--   publica_exclusiva_pct  solo sanidad pública (SNS o mutualidad con asistencia pública)
--   privada_exclusiva_pct  solo seguro privado (sobre todo mutualistas que eligen entidad privada)
--   mixta_pct              doble cobertura: pública y seguro privado
--   con_seguro_privado_pct privada exclusivamente + mixta
-- Las encuestas no son del todo comparables entre sí (población de referencia y cuestionario);
-- cod_ccaa '00' = España.
with base as (
    select
        encuesta,
        cast(anio as integer) as anio,
        ambito_poblacion,
        case upper(sexo) when 'AMBOS SEXOS' then 'Ambos sexos'
                         when 'VARONES' then 'Hombres' when 'HOMBRES' then 'Hombres'
                         when 'MUJERES' then 'Mujeres' end as sexo,
        cast(cod_ccaa as varchar) as cod_ccaa,
        unidad,
        lower(cobertura) as cobertura,
        valor
    from {{ source('raw_sanidad_privada', 'ine_sp_cobertura') }}
),

ancho as (
    select
        encuesta, anio, ambito_poblacion, sexo, cod_ccaa, any_value(unidad) as unidad,
        max(case when cobertura = 'total' then valor end) as total,
        max(case when cobertura = 'no consta' then valor end) as no_consta,
        max(case when cobertura = 'pública exclusivamente' then valor end) as publica,
        max(case when cobertura = 'privada exclusivamente' then valor end) as privada,
        max(case when cobertura = 'mixta' then valor end) as mixta,
        max(case when cobertura = 'otras situaciones' then valor end) as otras
    from base
    group by all
),

pct as (
    select *,
        case when unidad = 'pct' then 100.0 else total - coalesce(no_consta, 0) end as denom
    from ancho
)

select
    p.cod_ccaa,
    case when p.cod_ccaa = '00' then 'España' else t.nombre end as ccaa,
    p.anio,
    p.encuesta,
    p.ambito_poblacion,
    p.sexo,
    100.0 * p.publica / p.denom as publica_exclusiva_pct,
    100.0 * p.privada / p.denom as privada_exclusiva_pct,
    100.0 * p.mixta / p.denom as mixta_pct,
    100.0 * p.otras / p.denom as otras_pct,
    100.0 * (p.privada + p.mixta) / p.denom as con_seguro_privado_pct
from pct p
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = p.cod_ccaa
