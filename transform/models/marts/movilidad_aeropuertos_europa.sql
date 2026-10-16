-- Pasajeros (llegadas + salidas) de los aeropuertos europeos por año (Eurostat avia_paoa),
-- con su puesto en Europa y el peso de los vuelos internacionales. El Reino Unido dejó de
-- enviar datos a Eurostat tras el Brexit: desde 2020 faltan Heathrow, Gatwick... Turquía
-- (Estambul, Antalya) sí está. Se excluyen los «Other airport» de cada país.
with e as (
    select
        cod_aeropuerto, pais, oaci, anio,
        any_value(nombre_legible) as nombre_legible,
        max(pasajeros) filter (where cobertura = 'TOTAL') as pasajeros,
        max(pasajeros) filter (where cobertura = 'NAT') as nacional
    from {{ source('raw_aena', 'aena_eurostat_aeropuertos') }}
    where oaci <> 'OTH'
    group by cod_aeropuerto, pais, oaci, anio
)

select
    e.anio,
    e.cod_aeropuerto,
    e.oaci,
    coalesce(a.nombre, e.nombre_legible) as aeropuerto,
    e.pais as cod_pais,
    coalesce(p.pais, e.pais) as pais,
    e.pais = 'ES' as es_espana,
    cast(e.pasajeros as bigint) as pasajeros,
    1 - e.nacional / nullif(e.pasajeros, 0) as cuota_internacional,
    rank() over (partition by e.anio order by e.pasajeros desc) as puesto
from e
left join {{ ref('aena_aeropuertos') }} a on a.oaci = e.oaci and e.pais = 'ES'
left join {{ ref('paises_iso') }} p on p.eurostat = e.pais
where e.pasajeros > 0
