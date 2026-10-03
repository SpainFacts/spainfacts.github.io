-- Contratos adjudicados a empresas de medios por grupo mediático, año y nivel de la
-- administración contratante. Fuente: PLACSP (Ministerio de Hacienda) y plataformas
-- autonómicas y municipales de contratos menores (fuente_plataforma), ver medios_contratos_base. Grupo = seed medios_padron_nif (sociedades agrupadas por
-- propietario; los medios locales sin grupo van en «Medios locales independientes»).
-- - Solo es_medio = 'si' y sin importes sospechosos. Se incluyen los medios
--   públicos (titularidad = 'publica': EFE, RTVE, autonómicas) para poder
--   separarlos; los totales «privados» deben filtrar titularidad = 'privada'.
-- - eur_hab_real = euros de 2025 por habitante de España (todos los niveles
--   comparten denominador para que los grupos sean comparables).
with b as (
    select * from {{ ref('medios_contratos_base') }}
    where es_medio = 'si' and not sospechoso and anio >= 2018
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel = 'pais'
),

rango_pob as (
    select min(anio) as amin, max(anio) as amax from pob
)

select
    b.grupo,
    b.titularidad,
    b.anio,
    b.nivel,
    sum(b.importe_adjudicado_sin_iva) as importe_eur_nominal,
    sum(b.importe_eur_real) as importe_eur_real,
    sum(b.importe_eur_real) / any_value(p.poblacion) as eur_hab_real,
    cast(count(*) as integer) as n_contratos,
    cast(count(*) filter (where b.es_menor) as integer) as n_menores,
    sum(b.importe_eur_real) filter (where b.categoria = 'patrocinio_eventos') as importe_patrocinio_eventos_eur_real,
    sum(b.importe_eur_real) filter (where b.categoria = 'publicidad_inserciones') as importe_publicidad_eur_real,
    sum(b.importe_eur_real) filter (where b.categoria = 'suscripciones_servicios_informativos') as importe_suscripciones_eur_real,
    sum(b.importe_eur_real) filter (where b.categoria = 'especiales_suplementos_revistas') as importe_especiales_eur_real,
    cast(count(distinct b.nif_adjudicatario) as integer) as n_sociedades,
    cast(count(distinct b.organo_clave) as integer) as n_organos,
    -- parte que llega por las plataformas autonómicas y municipales (menores que PLACSP no trae)
    coalesce(sum(b.importe_eur_real) filter (where b.fuente_plataforma <> 'placsp'), 0) as importe_autonomicas_eur_real,
    cast(count(*) filter (where b.fuente_plataforma <> 'placsp') as integer) as n_contratos_autonomicas,
    string_agg(distinct b.fuente_plataforma, ', ' order by b.fuente_plataforma) as fuente_plataforma
from b
cross join rango_pob r
left join pob p on p.anio = greatest(least(b.anio, r.amax), r.amin)
group by b.grupo, b.titularidad, b.anio, b.nivel
order by b.anio, importe_eur_real desc
