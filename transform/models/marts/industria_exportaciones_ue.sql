-- Exportaciones industriales de España frente a las de los 27 (Eurostat, Comext DS-045409,
-- raw.eurostat_industria_comext). Una fila por partida HS, destino y año (2015-último).
--   destino: código ('WORLD' / 'EXT_EU27_2020') y destino_nombre: 'WORLD' = todas las exportaciones (incluye las ventas a otros países de la UE) o
--     'EXT_EU27_2020' = solo fuera de la UE.
--   exportacion_ue_eur: suma de las exportaciones de los 27 países (Comext publica todos).
--   cuota_pct / puesto: España sobre los 27 (puesto 1 = mayor exportador).
--   OJO, trampa de Países Bajos (y Bélgica): exportan mucho de lo que importan por Róterdam y
--   Amberes (reexportación), así que su exportación no es producción propia; se da también
--   puesto_sin_nl_be (puesto de España si no se cuentan NL ni BE).
--   veces_peso_poblacion: cuota / peso de España en la población de la UE.
--   exportacion_es_real_meur y exportacion_es_real_eur_hab: exportaciones de España en millones de
--     euros constantes de anio_base, en total y por habitante (población de España, poblacion_territorios).
--   Se excluyen los años en los que algún país no tiene el total de bienes (año incompleto).
with c as (
    select cast(anio as integer) as anio, pais, destino, partida, partida_nombre, valor_eur, cantidad_100kg
    from {{ source('raw_industria', 'eurostat_industria_comext') }}
),

anios_completos as (
    select anio from c
    where partida = 'TOTAL' and destino = 'WORLD' and valor_eur > 0
    group by 1 having count(distinct pais) = 27
),

agregado as (
    select
        anio,
        destino,
        partida,
        max(partida_nombre) as partida_nombre,
        max(case when pais = 'ES' then valor_eur end) as exportacion_es_eur,
        sum(valor_eur) as exportacion_ue_eur,
        max(case when pais = 'ES' then cantidad_100kg end) / 10.0 as exportacion_es_t,
        sum(cantidad_100kg) / 10.0 as exportacion_ue_t,
        arg_max(pais, valor_eur) as lider
    from c
    where anio in (select anio from anios_completos)
    group by all
),

puestos as (
    select
        a.anio, a.destino, a.partida,
        1 + count(*) filter (where c.pais <> 'ES' and c.valor_eur > a.exportacion_es_eur) as puesto,
        1 + count(*) filter (where c.pais not in ('ES', 'NL', 'BE') and c.valor_eur > a.exportacion_es_eur) as puesto_sin_nl_be,
        sum(c.valor_eur) filter (where c.pais in ('NL', 'BE')) as exportacion_nl_be_eur
    from agregado a
    join c using (anio, destino, partida)
    group by all
),

poblacion as (
    select
        cast(anio as integer) as anio,
        100.0 * max(case when pais = 'ES' then miles end) / max(case when pais = 'EU27_2020' then miles end)
            as cuota_poblacion_pct
    from {{ source('raw_industria', 'eurostat_industria_poblacion') }}
    group by 1
),

-- población del último año disponible para los años que aún no tienen dato
poblacion_completa as (
    select a.anio, coalesce(p.cuota_poblacion_pct,
        (select cuota_poblacion_pct from poblacion where cuota_poblacion_pct is not null order by anio desc limit 1))
        as cuota_poblacion_pct
    from (select distinct anio from agregado) a
    left join poblacion p using (anio)
)

select
    a.partida,
    a.partida_nombre,
    length(a.partida) = 2 as es_capitulo,
    a.destino,
    case a.destino when 'WORLD' then 'Mundo (incluye UE)' else 'Fuera de la UE' end as destino_nombre,
    a.anio,
    a.anio = max(a.anio) over () as es_ultimo_anio,
    a.exportacion_es_eur / 1e6 * d.factor as exportacion_es_real_meur,
    a.exportacion_es_eur * d.factor / pe.poblacion as exportacion_es_real_eur_hab,
    d.anio_base,
    100.0 * a.exportacion_es_eur / nullif(a.exportacion_ue_eur, 0) as cuota_pct,
    pu.puesto,
    pu.puesto_sin_nl_be,
    a.lider,
    nl.pais_nombre as lider_nombre,
    100.0 * pu.exportacion_nl_be_eur / nullif(a.exportacion_ue_eur, 0) as cuota_nl_be_pct,
    a.exportacion_es_t,
    a.exportacion_ue_t,
    100.0 * a.exportacion_es_t / nullif(a.exportacion_ue_t, 0) as cuota_volumen_pct,
    p.cuota_poblacion_pct,
    (100.0 * a.exportacion_es_eur / nullif(a.exportacion_ue_eur, 0)) / p.cuota_poblacion_pct as veces_peso_poblacion,
    100.0 * a.exportacion_es_eur / nullif(t.exportacion_es_eur, 0) as peso_en_exportacion_es_pct
from agregado a
left join puestos pu using (anio, destino, partida)
left join poblacion_completa p using (anio)
left join agregado t on t.anio = a.anio and t.destino = a.destino and t.partida = 'TOTAL'
left join {{ ref('deflactor') }} d on d.anio = a.anio
left join {{ ref('poblacion_territorios') }} pe
    on pe.nivel = 'pais' and pe.cod = '00' and pe.sexo = 'Total' and pe.anio = a.anio
left join {{ ref('industria_paises') }} nl on nl.pais = a.lider
where a.exportacion_es_eur is not null
