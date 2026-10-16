-- Tráfico total de la red española de AENA por mes desde 2004 (sin Luton, Leeds ni Aena
-- Brasil), con el año móvil (últimos 12 meses), la comparación con el mismo mes del año
-- anterior y de 2019 (antes de la pandemia) y los pasajeros por habitante.
-- Pasajeros = llegadas + salidas: un viaje de ida y vuelta Madrid-Palma cuenta 4 veces en la
-- red (sale y llega dos veces). Población: España, padrón del año (el último para los
-- años sin padrón).
with m as (
    select
        mes,
        sum(pasajeros) as pasajeros,
        sum(operaciones) as operaciones,
        sum(mercancia_t) as mercancia_t,
        bool_or(provisional) as provisional,
        count(*) filter (where pasajeros > 0) as aeropuertos_con_pasajeros
    from {{ ref('movilidad_aeropuertos_mensual') }}
    where red = 'espana'
    group by mes
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
),

con_12m as (
    select
        m.*,
        sum(pasajeros) over w as pasajeros_12m,
        sum(operaciones) over w as operaciones_12m,
        sum(mercancia_t) over w as mercancia_t_12m,
        count(*) over w as meses_12m
    from m
    window w as (order by mes range between interval 11 month preceding and current row)
)

select
    c.mes,
    cast(year(c.mes) as integer) as anio,
    cast(month(c.mes) as integer) as mes_num,
    cast(c.pasajeros as bigint) as pasajeros,
    cast(c.operaciones as bigint) as operaciones,
    c.mercancia_t,
    c.provisional,
    c.aeropuertos_con_pasajeros,
    c.pasajeros / nullif(c.operaciones, 0) as pasajeros_por_operacion,
    case when c.meses_12m = 12 then cast(c.pasajeros_12m as bigint) end as pasajeros_12m,
    case when c.meses_12m = 12 then cast(c.operaciones_12m as bigint) end as operaciones_12m,
    case when c.meses_12m = 12 then c.mercancia_t_12m end as mercancia_t_12m,
    cast(a.pasajeros as bigint) as pasajeros_anio_antes,
    c.pasajeros / nullif(a.pasajeros, 0) - 1 as var_anual,
    cast(p19.pasajeros as bigint) as pasajeros_2019,
    c.pasajeros / nullif(p19.pasajeros, 0) - 1 as var_2019,
    p.poblacion,
    1000.0 * c.pasajeros / p.poblacion as pasajeros_por_1000_hab,
    case when c.meses_12m = 12 then c.pasajeros_12m / p.poblacion end as pasajeros_12m_por_hab,
    case when c.meses_12m = 12 then 1000.0 * c.mercancia_t_12m / p.poblacion end as mercancia_kg_12m_por_hab
from con_12m c
left join con_12m a on a.mes = c.mes - interval 12 month
left join con_12m p19 on p19.mes = make_date(2019, cast(month(c.mes) as integer), 1)
left join pob p on p.anio = least(year(c.mes), (select max(anio) from pob))
