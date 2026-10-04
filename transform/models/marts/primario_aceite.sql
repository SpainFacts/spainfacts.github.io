-- Producción de aceite de oliva por campaña (octubre-septiembre) desde 2013/14: España,
-- Italia, Grecia, Portugal y el resto de la UE, con la cuota de España en la UE y, donde
-- hay cifra del Consejo Oleícola Internacional, en el mundo.
-- Fuentes: Comisión Europea, Agri-food data portal (API oliveOil/production, miles de t,
-- con marca de estimación; pipeline dlt `primario`) y seed primario_mundo (COI, producción
-- mundial por campaña). cuota_mundo_pct = producción de España según la Comisión /
-- producción mundial del COI (las dos fuentes difieren poco: 2024/25 Comisión 1.421 kt,
-- COI 1.419 kt).
-- grupo: España, Italia, Grecia, Portugal, Resto de la UE (CY, FR, HR, MT, SI) y una fila
-- 'Mundo (COI)' cuando existe. kg_hab: producción por habitante del grupo (solo países).
with prod as (
    select
        campania,
        cast(anio_produccion as integer) as anio,
        case geo when 'ES' then 'España' when 'IT' then 'Italia' when 'EL' then 'Grecia'
                 when 'PT' then 'Portugal' else 'Resto de la UE' end as grupo,
        geo,
        produccion_miles_t,
        estimado
    from {{ source('raw_primario', 'primario_aceite_produccion') }}
    where produccion_miles_t is not null
),

pob as (
    select i.eurostat as geo, p.anio, p.poblacion / 1000 as poblacion_miles
    from {{ ref('poblacion_paises') }} p
    join {{ ref('paises_iso') }} i on i.cod_pais = p.cod_pais
),

grupos as (
    select p.campania, p.anio, p.grupo,
           sum(p.produccion_miles_t) as produccion_miles_t,
           bool_or(p.estimado) as estimado,
           sum(coalesce(po.poblacion_miles,
                        (select last(x.poblacion_miles order by x.anio) from pob x where x.geo = p.geo))) as poblacion_miles
    from prod p
    left join pob po on po.geo = p.geo and po.anio = p.anio
    group by all
),

totales as (
    select campania,
           sum(produccion_miles_t) as total_ue_miles_t,
           max(produccion_miles_t) filter (where grupo = 'España') as espana_miles_t
    from grupos group by campania
),

mundo as (
    select periodo as campania, anio, valor as mundo_miles_t
    from {{ ref('primario_mundo') }}
    where indicador = 'aceite_produccion' and cod = 'MUNDO'
)

select
    g.campania,
    g.anio,
    g.grupo,
    g.produccion_miles_t,
    g.estimado,
    t.total_ue_miles_t,
    round(100 * g.produccion_miles_t / t.total_ue_miles_t, 2) as cuota_ue_pct,
    m.mundo_miles_t,
    round(100 * g.produccion_miles_t / m.mundo_miles_t, 2) as cuota_mundo_pct,
    g.produccion_miles_t * 1000 / g.poblacion_miles as kg_hab
from grupos g
join totales t on t.campania = g.campania
left join mundo m on m.campania = g.campania

union all

select m.campania, m.anio, 'Mundo (COI)', m.mundo_miles_t, m.anio >= 2025, t.total_ue_miles_t,
       null, m.mundo_miles_t, 100.0, null
from mundo m
left join totales t on t.campania = m.campania
order by 1, 3
