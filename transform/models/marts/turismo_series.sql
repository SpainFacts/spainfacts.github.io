-- Series mensuales de turismo del INE normalizadas en formato largo, base de
-- los demás marts turismo_*. Fuentes (API Tempus3, ingestion/turismo.py):
--   FRONTUR  10822 (país de residencia) y 10823 (comunidad de destino principal):
--            turistas internacionales llegados en el mes.
--   EGATUR   10838 (país) y 10839 (comunidad): gasto total en millones de euros
--            corrientes, gasto medio por persona y por día (euros) y duración
--            media del viaje (días). FRONTUR/EGATUR solo desglosan las seis
--            comunidades con más turistas; el resto va en "Otras" (cod 'otras').
--   EOH      2074 (viajeros y pernoctaciones en hoteles por residencia) y 2066
--            (plazas y grado de ocupación por plazas), nacional y comunidades.
--   EOAP     1993 y 2021: ídem en apartamentos turísticos.
-- Solo se guardan los "datos base" (se descartan tasas y acumulados). En la 2074
-- las series con la palabra "Dato" son las provinciales (y la de Cantabria
-- provincia duplica a la comunidad): se descartan. El mes sale de la fecha
-- del INE (medianoche en hora de Madrid) sumando 12 horas antes de truncar.
{{ config(materialized='table') }}

with nombres as (
    select nombre_ine, cast(cod_ccaa as varchar) as cod_ccaa from {{ ref('ine_ccaa_nombres') }}
    union all select 'Nacional', '00'
    union all select 'Baleares (Illes)', '04'
    union all select 'Otras Comunidades Autónomas', 'otras'
),

crudo as (
    select 'frontur_pais' as fuente, serie, fecha, valor from {{ source('raw_turismo', 'ine_frontur_pais') }}
    union all select 'frontur_ccaa', serie, fecha, valor from {{ source('raw_turismo', 'ine_frontur_ccaa') }}
    union all select 'egatur_pais', serie, fecha, valor from {{ source('raw_turismo', 'ine_egatur_pais') }}
    union all select 'egatur_ccaa', serie, fecha, valor from {{ source('raw_turismo', 'ine_egatur_ccaa') }}
    union all select 'eoh_viajeros', serie, fecha, valor from {{ source('raw_turismo', 'ine_eoh_viajeros') }}
    union all select 'eoh_ocupacion', serie, fecha, valor from {{ source('raw_turismo', 'ine_eoh_ocupacion') }}
    union all select 'eoap_viajeros', serie, fecha, valor from {{ source('raw_turismo', 'ine_eoap_viajeros') }}
    union all select 'eoap_ocupacion', serie, fecha, valor from {{ source('raw_turismo', 'ine_eoap_ocupacion') }}
),

partes as (
    select
        fuente,
        cast(date_trunc('month', epoch_ms(fecha) + interval 12 hour) as date) as mes,
        list_filter(list_transform(string_split(serie, '. '), x -> trim(x, '. ')), x -> x <> '') as p,
        valor
    from crudo
    where valor is not null
),

filtrado as (
    select
        fuente, mes, p, valor,
        case
            when fuente like 'frontur%' then 'turistas'
            when list_contains(p, 'Gasto total') then 'gasto_meur'
            when list_contains(p, 'Gasto medio por persona') then 'gasto_medio_persona'
            when list_contains(p, 'Gasto medio diario por persona') then 'gasto_medio_diario'
            when list_contains(p, 'Duración media de los viajes') then 'duracion_media'
            when list_has_any(p, ['Viajeros', 'Viajero']) then 'viajeros'
            when list_contains(p, 'Pernoctaciones') then 'pernoctaciones'
            when list_contains(p, 'Grado de ocupación por plazas') then 'ocupacion_plazas'
            when list_contains(p, 'Número de plazas estimadas') then 'plazas'
        end as medida,
        case
            when list_contains(p, 'Residentes en España') then 'residentes'
            when list_has_any(p, ['Residentes en el extranjero', 'Residentes en el Extranjero']) then 'extranjeros'
            else 'total'
        end as residencia
    from partes
    where (fuente not like 'frontur%' and fuente not like 'egatur%' or list_contains(p, 'Dato base'))
      and not (fuente = 'eoh_viajeros' and list_contains(p, 'Dato'))
),

con_territorio as (
    select
        f.fuente, f.mes, f.medida, f.residencia, f.valor,
        case when f.fuente like '%_pais' then '00' else n.cod_ccaa end as cod_ccaa,
        case when f.fuente like '%_pais' then f.p[1] end as pais
    from filtrado f
    left join nombres n
        on f.fuente not like '%_pais' and list_contains(f.p, n.nombre_ine)
    where f.medida is not null
      -- el total nacional de las tablas por comunidad repite el de las tablas por país
      and not (f.fuente in ('frontur_ccaa', 'egatur_ccaa') and n.cod_ccaa = '00')
),

ipc as (
    select cast(date_trunc('month', periodo) as date) as mes, valor as ipc
    from {{ ref('metricas') }}
    where metrica_id = 'ipc_indice'
),

base_ipc as (
    select ipc_medio as ipc_base, anio_base from {{ ref('deflactor') }}
    where anio = anio_base
)

-- factor_real: multiplica los euros corrientes del mes para pasarlos a euros
-- constantes de anio_base (IPC general del mes frente a la media de anio_base).
select
    split_part(c.fuente, '_', 1) as operacion,
    c.mes,
    c.cod_ccaa,
    case when c.pais = 'Total' then null else c.pais end as pais,
    c.medida,
    c.residencia,
    c.valor,
    b.ipc_base / i.ipc as factor_real,
    b.anio_base
from con_territorio c
left join ipc i on i.mes = c.mes
cross join base_ipc b
where c.cod_ccaa is not null
