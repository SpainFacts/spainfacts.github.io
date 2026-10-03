-- Precio en origen del aceite de oliva por mes, categoría y país (España, Italia, Grecia,
-- Portugal), desde 2010, en euros por kilo corrientes y reales.
-- Fuente: Comisión Europea, Agri-food data portal (API oliveOil/prices: precios semanales
-- por mercado representativo, EUR/100 kg; pipeline dlt `primario`). Precio del mes = media
-- de las cotizaciones semanales de todos los mercados del país (en España: Jaén, Córdoba,
-- Sevilla, Granada...); n_cotizaciones = cuántas entran en la media.
-- eur_kg_real: en euros constantes con el IPC general de España (main.metricas,
-- ipc_indice, base 2025, mensual): real = nominal x IPC del último mes / IPC del mes. Se
-- aplica también a los demás países para leerlos como «euros de hoy» en España.
-- categoria: Virgen extra (<= 0,8°), Virgen (<= 2°), Lampante (2°).
with semanal as (
    select geo,
           case producto
               when 'Extra virgin olive oil (up to 0.8%)' then 'Virgen extra'
               when 'Virgin olive oil (up to 2%)' then 'Virgen'
               when 'Lampante olive oil (2%)' then 'Lampante'
           end as categoria,
           date_trunc('month', cast(fecha_inicio as date)) as mes,
           precio_eur_100kg
    from {{ source('raw_primario', 'primario_aceite_precios') }}
    where precio_eur_100kg is not null and fecha_inicio is not null
),

ipc as (
    select cast(periodo as date) as mes, valor as ipc
    from {{ ref('metricas') }}
    where metrica_id = 'ipc_indice'
),

ipc_ultimo as (
    select ipc as ipc_ultimo, mes as mes_base from ipc order by mes desc limit 1
)

select
    s.geo,
    coalesce(p.pais, s.geo) as pais,
    s.categoria,
    cast(s.mes as date) as mes,
    avg(s.precio_eur_100kg) / 100 as eur_kg,
    avg(s.precio_eur_100kg) / 100 * u.ipc_ultimo / i.ipc as eur_kg_real,
    count(*) as n_cotizaciones,
    u.mes_base
from semanal s
cross join ipc_ultimo u
left join ipc i on i.mes = s.mes
left join {{ ref('primario_paises') }} p on p.geo = s.geo
where s.categoria is not null
group by s.geo, p.pais, s.categoria, s.mes, u.ipc_ultimo, i.ipc, u.mes_base
order by s.geo, s.categoria, s.mes
