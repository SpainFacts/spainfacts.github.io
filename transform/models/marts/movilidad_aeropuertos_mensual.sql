-- Tráfico de cada aeropuerto de AENA por mes desde 2004 (informe mensual de AENA): pasajeros
-- (llegadas + salidas, con tránsitos), operaciones (aterrizajes + despegues) y mercancía en
-- toneladas. Los nombres históricos se traducen al código OACI con el seed
-- aena_aeropuertos_nombres (un mes puede traer dos nombres del mismo aeropuerto, uno en cada
-- tabla del informe: se suman). `red`: espana, reino_unido (Luton, Leeds) o brasil.
-- *_12m: suma de los últimos 12 meses (año móvil) del aeropuerto; nulo si no los tiene todos.
with bruto as (
    select anio, mes, aeropuerto, pasajeros, operaciones, mercancia_kg, provisional
    from {{ source('raw_aena', 'aena_trafico_mensual') }}
    where not starts_with(aeropuerto, 'TOTAL_')
),

por_aeropuerto as (
    select
        make_date(cast(b.anio as integer), cast(b.mes as integer), 1) as mes,
        n.oaci,
        sum(b.pasajeros) as pasajeros,
        sum(b.operaciones) as operaciones,
        sum(b.mercancia_kg) / 1000 as mercancia_t,
        bool_or(b.provisional) as provisional
    from bruto b
    left join {{ ref('aena_aeropuertos_nombres') }} n on n.nombre_aena = b.aeropuerto
    group by 1, 2
)

select
    p.mes,
    cast(year(p.mes) as integer) as anio,
    p.oaci,
    a.iata,
    a.nombre as aeropuerto,
    a.tipo,
    a.red,
    a.cod_prov,
    pr.nombre as provincia,
    pr.cod_ccaa,
    c.nombre as ccaa,
    cast(p.pasajeros as bigint) as pasajeros,
    cast(p.operaciones as bigint) as operaciones,
    p.mercancia_t,
    p.provisional,
    case when count(*) over w = 12 then sum(p.pasajeros) over w end as pasajeros_12m,
    case when count(*) over w = 12 then sum(p.operaciones) over w end as operaciones_12m,
    case when count(*) over w = 12 then sum(p.mercancia_t) over w end as mercancia_t_12m
from por_aeropuerto p
left join {{ ref('aena_aeropuertos') }} a on a.oaci = p.oaci
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = a.cod_prov
left join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = pr.cod_ccaa
window w as (partition by p.oaci order by p.mes range between interval 11 month preceding and current row)
