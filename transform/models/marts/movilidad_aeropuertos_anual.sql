-- Tráfico de cada aeropuerto de AENA por año (informe mensual de AENA sumado), con la
-- variación frente al año anterior y frente a 2019, pasajeros por operación y el reparto de
-- los pasajeros entre vuelos nacionales, a la UE-27 y fuera de la UE-27 que publica Eurostat
-- (avia_paoa, desde 2020, cuando el Reino Unido ya cuenta fuera de la UE).
-- `completo` = el año tiene los 12 meses; el año en curso va hasta el último mes publicado
-- y se compara con los mismos meses del año anterior (var_anual_mismos_meses).
with m as (
    select * from {{ ref('movilidad_aeropuertos_mensual') }}
),

anual as (
    select
        anio, oaci, any_value(iata) as iata, any_value(aeropuerto) as aeropuerto,
        any_value(tipo) as tipo, any_value(red) as red, any_value(cod_prov) as cod_prov,
        any_value(provincia) as provincia, any_value(cod_ccaa) as cod_ccaa, any_value(ccaa) as ccaa,
        sum(pasajeros) as pasajeros, sum(operaciones) as operaciones, sum(mercancia_t) as mercancia_t,
        count(*) as meses, max(cast(month(mes) as integer)) as ultimo_mes, bool_or(provisional) as provisional
    from m
    group by anio, oaci
),

mismos_meses as (
    -- año anterior hasta el mismo mes que el año en curso
    select a.anio, a.oaci, sum(m.pasajeros) as pasajeros
    from anual a
    join m on m.oaci = a.oaci and m.anio = a.anio - 1 and month(m.mes) <= a.ultimo_mes
    group by a.anio, a.oaci
),

eurostat as (
    select
        oaci, anio,
        max(pasajeros) filter (where cobertura = 'NAT') as nacional,
        max(pasajeros) filter (where cobertura = 'INTL_IEU27_2020') as ue,
        max(pasajeros) filter (where cobertura = 'INTL_XEU27_2020') as fuera_ue
    from {{ source('raw_aena', 'aena_eurostat_aeropuertos') }}
    where pais = 'ES'
    group by oaci, anio
)

select
    a.anio, a.oaci, a.iata, a.aeropuerto, a.tipo, a.red, a.cod_prov, a.provincia, a.cod_ccaa, a.ccaa,
    s.lat, s.lon,
    cast(a.pasajeros as bigint) as pasajeros,
    cast(a.operaciones as bigint) as operaciones,
    a.mercancia_t,
    a.meses,
    a.meses = 12 as completo,
    a.ultimo_mes,
    a.provisional,
    a.pasajeros / nullif(a.operaciones, 0) as pasajeros_por_operacion,
    rank() over (partition by a.anio, a.red order by a.pasajeros desc) as puesto,
    cast(p.pasajeros as bigint) as pasajeros_anio_antes,
    case when a.meses = 12 then a.pasajeros / nullif(p.pasajeros, 0) - 1 end as var_anual,
    a.pasajeros / nullif(mm.pasajeros, 0) - 1 as var_anual_mismos_meses,
    cast(p19.pasajeros as bigint) as pasajeros_2019,
    case when a.meses = 12 then a.pasajeros / nullif(p19.pasajeros, 0) - 1 end as var_2019,
    e.nacional / nullif(e.nacional + e.ue + e.fuera_ue, 0) as cuota_nacional,
    e.ue / nullif(e.nacional + e.ue + e.fuera_ue, 0) as cuota_ue,
    e.fuera_ue / nullif(e.nacional + e.ue + e.fuera_ue, 0) as cuota_fuera_ue
from anual a
left join anual p on p.oaci = a.oaci and p.anio = a.anio - 1
left join anual p19 on p19.oaci = a.oaci and p19.anio = 2019
left join mismos_meses mm on mm.oaci = a.oaci and mm.anio = a.anio
left join eurostat e on e.oaci = a.oaci and e.anio = a.anio and a.anio >= 2020
left join {{ ref('aena_aeropuertos') }} s on s.oaci = a.oaci
