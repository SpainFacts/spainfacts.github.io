-- Alertas de la Plataforma del Consejo de Europa para la protección del periodismo y la
-- seguridad de los periodistas (fom.coe.int), por país y año desde 2015.
--
-- Una alerta es una amenaza grave a la libertad de prensa (agresiones, detenciones,
-- acoso, presiones legales o políticas, etc.) que publican las organizaciones de
-- periodistas socias de la plataforma tras verificarla; el Estado afectado puede
-- responder. No es un recuento exhaustivo de incidentes: depende de lo que las
-- organizaciones socias deciden registrar. Año: el de la alerta según el filtro del
-- portal. La API del portal da por separado las alertas activas (nbAlerte) y las
-- resueltas (nbAlerteResolu): alertas = activas + resueltas, que es el total publicado
-- ese año (cuadra con las 282 alertas de 2021 del informe anual de las organizaciones
-- socias). sin_respuesta: alertas de ese año que el Estado no ha respondido. La situación
-- (activa, resuelta, respondida) es la de la fecha de descarga, no la del año.
-- Por habitante (principio de SpainFacts): alertas_por_10m_hab = alertas por cada 10
-- millones de habitantes, con la población media anual de Eurostat (demo_gind; para los
-- años sin dato todavía, la del último año disponible). EU27_2020: suma de los 27 países
-- que hoy forman la UE, dividida por su población. Países: cod_pais ISO alfa-2 (seed
-- paises_iso); solo los países miembros del Consejo de Europa presentes en ese seed.
with alertas as (
    select n.cod_pais, cast(a.anio as integer) as anio,
           cast(a.alertas + a.resueltas as integer) as alertas,
           cast(a.alertas as integer) as activas,
           cast(a.sin_respuesta as integer) as sin_respuesta,
           cast(a.resueltas as integer) as resueltas,
           cast(a.periodistas_asesinados as integer) as periodistas_asesinados
    from {{ source('raw_medios_libertad', 'medios_libertad_coe_alertas') }} a
    join {{ ref('medios_libertad_paises_nombres') }} n on n.nombre_fuente = a.pais_fuente
),

poblacion as (
    select geo, cast(anio as integer) as anio, cast(poblacion as double) as poblacion
    from {{ source('raw', 'eurostat_poblacion_media_paises') }}
    where poblacion is not null
),

rango as (
    select geo, max(anio) as anio_max from poblacion group by geo
),

paises as (
    select a.*, p.pais, p.es_ue, pb.poblacion
    from alertas a
    join {{ ref('paises_iso') }} p on p.cod_pais = a.cod_pais
    left join rango r on r.geo = p.eurostat
    left join poblacion pb on pb.geo = p.eurostat and pb.anio = least(a.anio, r.anio_max)
),

ue as (
    select 'EU27_2020' as cod_pais, a.anio, sum(a.alertas) as alertas, sum(a.activas) as activas, sum(a.sin_respuesta) as sin_respuesta,
           sum(a.resueltas) as resueltas, sum(a.periodistas_asesinados) as periodistas_asesinados,
           'Unión Europea (27)' as pais, false as es_ue, sum(a.poblacion) as poblacion
    from paises a
    where a.es_ue
    group by a.anio
    having count(*) = 27 and count(a.poblacion) = 27
),

todo as (
    select cod_pais, pais, false as es_agregado, es_ue, anio, alertas, activas, sin_respuesta, resueltas, periodistas_asesinados, poblacion
    from paises
    union all
    select cod_pais, pais, true, false, anio, alertas, activas, sin_respuesta, resueltas, periodistas_asesinados, poblacion
    from ue
),

con_tasa as (
    select *, alertas / poblacion * 1e7 as alertas_por_10m_hab from todo
)

select
    t.cod_pais,
    t.pais,
    t.es_agregado,
    t.es_ue,
    t.cod_pais in ('ES', 'FR', 'DE', 'IT', 'PT', 'NL', 'HU', 'GR', 'PL', 'EU27_2020') as es_referencia,
    t.anio,
    t.alertas,
    t.activas,
    t.sin_respuesta,
    t.resueltas,
    t.periodistas_asesinados,
    cast(round(t.poblacion) as bigint) as poblacion,
    round(t.alertas_por_10m_hab, 3) as alertas_por_10m_hab,
    case when t.es_ue then cast(rank() over (partition by t.anio, t.es_ue order by t.alertas_por_10m_hab) as integer) end as puesto_ue,
    case when t.es_ue then cast(count(*) over (partition by t.anio, t.es_ue) as integer) end as n_ue,
    t.anio = year(current_date) as parcial
from con_tasa t
