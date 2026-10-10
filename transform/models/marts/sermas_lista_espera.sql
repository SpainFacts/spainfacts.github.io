-- Lista de espera del Servicio Madrileño de Salud a 31 de diciembre de cada año, según la
-- Memoria anual del SERMAS (Consejería de Sanidad de la Comunidad de Madrid), capítulo
-- «Lista de espera»: el documento de rendición de cuentas más completo de la Consejería.
--   tipo 'consulta':   primera consulta de atención especializada (Total y 10 especialidades).
--   tipo 'prueba':     primera prueba diagnóstica (8 técnicas; 'Total' = suma de las 8, cálculo propio).
--   tipo 'quirurgica': lista de espera quirúrgica estructural (solo 'Total').
-- La memoria trae una fila que el informe mensual no publica: «Número de pacientes sin fecha
-- asignada» (pacientes que esperan sin cita, desde 2016). total = lista completa: el total
-- estructural de la memoria, que ya incluye a los sin cita salvo en la memoria de 2018 y en las
-- pruebas de 2019 (sin_cita_en_total_memoria = false), donde se suman aquí.
-- con_cita = total - sin_cita (los repartidos por tramos de espera según la fecha de la cita).
-- En la lista quirúrgica no hay «sin cita»: total = pacientes en espera estructural y aparte
-- los no estructurales (rechazo de derivación a otro centro y transitoriamente no programables).
-- Por 1.000 habitantes con la población del INE (poblacion_territorios, cod '13'); la memoria
-- usa la población con tarjeta sanitaria (poblacion_asignada).
with raw as (
    select
        cast(anio as integer) as anio,
        tipo,
        especialidad,
        estructural, sin_fecha, sin_fecha_en_total,
        t0_30, t31_60, t61_90, t_mas_90, t91_180, t_mas_180,
        control, rechazo_derivacion, tnp,
        tasa_1000, tiempo_medio_pendientes, demora_media, demora_prospectiva,
        entradas, salidas, atendidos,
        poblacion_asignada, fuente_url, fuente_doc
    from {{ source('raw_sermas', 'sermas_memoria_le') }}
    where estructural is not null
),

base as (
    select
        anio,
        tipo,
        especialidad,
        case
            when tipo = 'quirurgica' then estructural
            when sin_fecha_en_total = false then estructural + coalesce(sin_fecha, 0)
            else estructural
        end as total,
        case when tipo = 'quirurgica' then null else sin_fecha end as sin_cita,
        case when tipo = 'quirurgica' then null else sin_fecha_en_total end as sin_cita_en_total_memoria,
        t0_30, t31_60, t61_90,
        case when tipo = 'quirurgica' then t91_180 + t_mas_180 else t_mas_90 end as t_mas_90,
        t_mas_180,
        control as prueba_control,
        rechazo_derivacion, tnp,
        tasa_1000 as tasa_memoria_1000,
        coalesce(tiempo_medio_pendientes, demora_media) as tiempo_medio_pendientes_dias,
        demora_prospectiva as demora_prospectiva_dias,
        entradas,
        -- en la lista quirúrgica la memoria solo da las salidas de diciembre: fuera
        case when tipo = 'quirurgica' then null else salidas end as salidas,
        atendidos,
        poblacion_asignada, fuente_url, fuente_doc
    from raw
),

-- Total de pruebas: suma de las 8 técnicas (la memoria no lo da)
pruebas_total as (
    select
        anio, 'prueba' as tipo, 'Total' as especialidad,
        sum(total) as total, sum(sin_cita) as sin_cita,
        bool_and(sin_cita_en_total_memoria) as sin_cita_en_total_memoria,
        sum(t0_30), sum(t31_60), sum(t61_90), sum(t_mas_90), null::double,
        sum(prueba_control), null::double, null::double,
        null::double, null::double, null::double,
        sum(entradas), sum(salidas), sum(atendidos),
        max(poblacion_asignada), max(fuente_url), max(fuente_doc)
    from base
    where tipo = 'prueba'
    group by anio
),

unido as (
    select * from base
    union all
    select * from pruebas_total
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '13' and sexo = 'Total'
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    u.anio,
    make_date(u.anio, 12, 31) as fecha_corte,
    u.tipo,
    u.especialidad,
    cast(u.total as integer) as total,
    cast(u.total - u.sin_cita as integer) as con_cita,
    cast(u.sin_cita as integer) as sin_cita,
    round(100.0 * u.sin_cita / nullif(u.total, 0), 2) as sin_cita_pct,
    round(1000.0 * u.total / p.poblacion, 2) as total_por_1000_hab,
    round(1000.0 * u.sin_cita / p.poblacion, 3) as sin_cita_por_1000_hab,
    cast(u.t0_30 as integer) as con_cita_0_30_dias,
    cast(u.t31_60 as integer) as con_cita_31_60_dias,
    cast(u.t61_90 as integer) as con_cita_61_90_dias,
    cast(u.t_mas_90 as integer) as con_cita_mas_90_dias,
    cast(u.t_mas_180 as integer) as mas_180_dias,
    cast(u.prueba_control as integer) as prueba_control,
    cast(u.rechazo_derivacion as integer) as rechazo_derivacion,
    cast(u.tnp as integer) as transitoriamente_no_programables,
    u.tiempo_medio_pendientes_dias,
    u.demora_prospectiva_dias,
    u.tasa_memoria_1000,
    cast(u.entradas as integer) as entradas_anio,
    cast(u.salidas as integer) as salidas_anio,
    cast(u.poblacion_asignada as integer) as poblacion_asignada,
    cast(p.poblacion as integer) as poblacion,
    u.sin_cita_en_total_memoria,
    u.fuente_doc,
    u.fuente_url
from unido u
left join pob p on p.anio = u.anio
order by u.anio, u.tipo, u.especialidad
