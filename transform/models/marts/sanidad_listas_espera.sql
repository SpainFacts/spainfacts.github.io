-- Listas de espera del Sistema Nacional de Salud (Ministerio de Sanidad, SISLE-SNS), situación
-- a 30 de junio y 31 de diciembre de cada año, desde diciembre de 2013.
--   tipo 'quirurgica': pacientes en espera estructural para una operación programada, tasa por
--                      1.000 habitantes (población con tarjeta sanitaria), % que llevan más de
--                      6 meses esperando y tiempo medio de espera en días.
--   tipo 'consultas':  primera consulta externa de atención especializada: pacientes por 1.000
--                      hab., % con cita a más de 60 días y tiempo medio de espera en días.
-- nivel 'ccaa' (cod = código INE; tablas por comunidad desde diciembre de 2016) y 'pais'
-- (cod '00' = total SNS). El total SNS sale de la tabla por comunidades y, si no está (antes
-- de 2016 o donde el PDF no la trae), de la fila TOTAL de la tabla por especialidades; el %
-- de consultas a más de 60 días se toma primero de la tabla por especialidades (en diciembre
-- de 2020 la fila TOTAL de la tabla por comunidades trae un 0,5 % erróneo).
-- Los datos los aporta cada comunidad y el ministerio los agrega: hay cambios de criterio
-- (p. ej. Andalucía cambió su sistema de cómputo en 2018).
with ccaa as (
    select
        cast(fecha_corte as date) as fecha,
        tipo,
        cast(cod_ccaa as varchar) as cod,
        pacientes, tasa_1000, pct_espera_larga, dias_medio
    from {{ source('raw_sanidad', 'sanidad_sisle_ccaa') }}
),

esp_total as (
    select
        cast(fecha_corte as date) as fecha,
        tipo,
        pacientes, tasa_1000, pct_espera_larga, dias_medio
    from {{ source('raw_sanidad', 'sanidad_sisle_especialidad') }}
    where especialidad = 'TOTAL'
),

fechas as (
    select fecha, tipo from ccaa where cod = '00'
    union
    select fecha, tipo from esp_total
),

pais as (
    select
        f.fecha,
        f.tipo,
        '00' as cod,
        coalesce(c.pacientes, e.pacientes) as pacientes,
        coalesce(c.tasa_1000, e.tasa_1000) as tasa_1000,
        case when f.tipo = 'consultas' then coalesce(e.pct_espera_larga, c.pct_espera_larga)
             else coalesce(c.pct_espera_larga, e.pct_espera_larga) end as pct_espera_larga,
        coalesce(c.dias_medio, e.dias_medio) as dias_medio
    from fechas f
    left join ccaa c on c.fecha = f.fecha and c.tipo = f.tipo and c.cod = '00'
    left join esp_total e on e.fecha = f.fecha and e.tipo = f.tipo
),

unido as (
select
    fecha,
    cast(year(fecha) as integer) as anio,
    case when month(fecha) = 6 then 'junio' else 'diciembre' end as corte,
    tipo,
    'pais' as nivel,
    cod,
    pacientes, tasa_1000, pct_espera_larga, dias_medio
from pais
where fecha >= date '2013-12-31'

union all

select
    fecha,
    cast(year(fecha) as integer) as anio,
    case when month(fecha) = 6 then 'junio' else 'diciembre' end as corte,
    tipo,
    'ccaa' as nivel,
    cod,
    pacientes, tasa_1000, pct_espera_larga, dias_medio
from ccaa
where cod <> '00' and fecha >= date '2013-12-31'
)

select
    u.fecha, u.anio, u.corte, u.tipo, u.nivel, u.cod, t.nombre as nombre,
    u.pacientes, u.tasa_1000, u.pct_espera_larga, u.dias_medio
from unido u
left join {{ ref('territorios') }} t on t.nivel = u.nivel and t.cod = u.cod
