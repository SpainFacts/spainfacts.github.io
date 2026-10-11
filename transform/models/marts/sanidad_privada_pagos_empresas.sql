-- Qué empresas cobran del Servicio Madrileño de Salud (SERMAS) cada año: gasto ejecutado
-- (obligaciones reconocidas) de la Cuenta General de la Comunidad de Madrid, 2016-.
-- Fuente: mart gasto_oculto_ejecucion (estado E.1 «Liquidación del presupuesto de gastos» del
-- SERMAS, por subconcepto). Cada hospital de gestión privada tiene su propio subconcepto
-- (25200 Rey Juan Carlos, 25202 Fundación Jiménez Díaz, 25206 Infanta Elena, 25208 Torrejón,
-- 25210 Villalba); la empresa que lo controlaba cada año sale del seed
-- sanidad_privada_empresas_hospital (con su fuente). El resto de conciertos de asistencia
-- sanitaria con entidades privadas (diálisis, ambulancias, pruebas, laboratorios...) no lleva la
-- empresa en la Cuenta General y va en 'Otras empresas (sin desglose)'. No incluye lo que se paga
-- a otras administraciones (instituciones del Estado, corporaciones locales) ni el canon de los
-- hospitales construidos por concesión de obra (PFI).
--   importe_eur_real: euros constantes de anio_base; eur_hab_real: por habitante de la Comunidad.
with base as (
    select
        e.anio,
        e.subconcepto,
        e.descripcion,
        e.partida,
        e.obligaciones_eur,
        e.obligaciones_eur_real,
        e.obligaciones_eur_hab_real,
        e.anio_base
    from {{ ref('gasto_oculto_ejecucion') }} e
    where e.cod_ccaa = '13'
      and e.entidad ilike '%SERMAS%'
      and not e.es_parcial
      and (
          e.partida in ('Conciertos con la Fundación Jiménez Díaz', 'Hospitales de gestión privada (concesiones)')
          or (e.partida = 'Conciertos de asistencia sanitaria'
              and e.descripcion not ilike '%INSTITUCIONES DEL ESTADO%'
              and e.descripcion not ilike '%CORPORACIONES LOCALES%'
              and e.descripcion not ilike '%OTRAS INSTITUCIONES%'
              and e.descripcion not ilike '%REINTEGRO%')
      )
),

con_empresa as (
    select
        b.*,
        h.hospital,
        coalesce(h.empresa, 'Otras empresas (sin desglose)') as empresa,
        h.grupo_empresarial,
        h.hospital is not null as empresa_identificada
    from base b
    left join {{ ref('sanidad_privada_empresas_hospital') }} h
        on cast(h.subconcepto as varchar) = b.subconcepto
       and b.anio >= h.desde
       and b.anio <= coalesce(h.hasta, 9999)
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    cast(anio as integer) as anio,
    empresa,
    max(grupo_empresarial) as grupo_empresarial,
    bool_and(empresa_identificada) as empresa_identificada,
    string_agg(distinct hospital, ', ' order by hospital) as hospitales,
    sum(obligaciones_eur) / 1e6 as importe_meur,
    sum(obligaciones_eur_real) / 1e6 as importe_meur_real,
    sum(obligaciones_eur_hab_real) as eur_hab_real,
    max(anio_base) as anio_base
from con_empresa
group by all
