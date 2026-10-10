-- Modificaciones de crédito de la Comunidad de Madrid por entidad y aplicación económica
-- (subconcepto), 2016 en adelante: el detalle que dice de qué partidas sale el dinero que
-- acaba en el SERMAS.
-- Fuente: Cuenta General de la Comunidad de Madrid, nota 23.1.1.a «Modificaciones de crédito»
-- de cada entidad (PDF; ingestion/gasto_oculto.py). Solo publican esta nota la Administración
-- de la Comunidad (EO050) y el SERMAS (EO049); AMAS, Agencia de Vivienda Social y demás
-- organismos no la traen en sus cuentas, y sus créditos llegan como transferencias de la
-- Administración General (capítulos 4 y 7 de esta), que es donde se ve si se recortan.
-- La pista que deja: en la Administración General las bajas por transferencia salen sobre todo
-- de partidas globales (22900 «Imprevistos e insuficiencias», 50000 fondo de contingencia,
-- 18013 incremento retributivo) que se presupuestan sin destino y se reparten durante el año.
-- - origen_destino: 'Cede' (transferencias negativas), 'Recibe' (positivas) o 'Sin transferencias'.
-- - _real: euros constantes de anio_base.
with m as (
    select
        cast(anio as integer) as anio,
        entidad_cod,
        case
            when entidad ilike '%SERMAS%' then 'Servicio Madrileño de Salud (SERMAS)'
            when entidad ilike 'Administraci_n de la Comunidad%' then 'Administración de la Comunidad de Madrid'
            else trim(entidad)
        end as entidad,
        cast(aplicacion as varchar) as subconcepto,
        descripcion,
        coalesce(creditos_extraordinarios, 0) as creditos_extraordinarios,
        coalesce(suplementos, 0) as suplementos,
        coalesce(ampliaciones, 0) as ampliaciones,
        coalesce(transferencias, 0) as transferencias,
        coalesce(incorporaciones, 0) as incorporaciones,
        coalesce(generados_ingresos, 0) as generados_ingresos,
        coalesce(otras, 0) as otras,
        coalesce(total, 0) as total,
        url
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_modificaciones') }}
    where length(cast(aplicacion as varchar)) = 5
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    m.anio,
    m.entidad_cod,
    m.entidad,
    cast(substr(m.subconcepto, 1, 1) as integer) as capitulo,
    substr(m.subconcepto, 1, 3) as concepto,
    m.subconcepto,
    m.descripcion,
    case when m.transferencias < 0 then 'Cede' when m.transferencias > 0 then 'Recibe' else 'Sin transferencias' end as origen_destino,
    m.creditos_extraordinarios as creditos_extraordinarios_eur,
    m.suplementos as suplementos_eur,
    m.ampliaciones as ampliaciones_eur,
    m.transferencias as transferencias_eur,
    m.incorporaciones as incorporaciones_eur,
    m.generados_ingresos as generados_ingresos_eur,
    m.otras as otras_eur,
    m.total as total_modificaciones_eur,
    m.transferencias * d.factor as transferencias_eur_real,
    m.total * d.factor as total_modificaciones_eur_real,
    d.anio_base,
    m.url as fuente_url
from m
left join {{ ref('deflactor') }} as d
  on d.anio = m.anio
order by m.anio, m.entidad, m.subconcepto
