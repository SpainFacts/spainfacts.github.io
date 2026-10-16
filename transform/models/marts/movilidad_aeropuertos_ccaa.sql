-- Pasajeros de los aeropuertos de AENA por comunidad autónoma y año, por habitante (padrón
-- de la comunidad). Sale alto donde hay mucho turismo (Baleares, Canarias): los pasajeros se
-- cuentan en el aeropuerto, no por residencia. Solo comunidades con algún aeropuerto o
-- helipuerto de AENA.
with a as (
    select anio, cod_ccaa, sum(pasajeros) as pasajeros, sum(operaciones) as operaciones,
           sum(mercancia_t) as mercancia_t, max(meses) = 12 as completo, max(ultimo_mes) as ultimo_mes
    from {{ ref('movilidad_aeropuertos_anual') }}
    where red = 'espana'
    group by anio, cod_ccaa
),

pob as (
    select cast(anio as integer) as anio, cod as cod_ccaa, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
)

select
    a.anio,
    a.cod_ccaa,
    c.nombre as ccaa,
    cast(a.pasajeros as bigint) as pasajeros,
    cast(a.operaciones as bigint) as operaciones,
    a.mercancia_t,
    a.completo,
    a.ultimo_mes,
    p.poblacion,
    a.pasajeros / p.poblacion as pasajeros_por_hab
from a
join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = a.cod_ccaa
left join pob p on p.cod_ccaa = a.cod_ccaa
    and p.anio = least(a.anio, (select max(anio) from pob))
