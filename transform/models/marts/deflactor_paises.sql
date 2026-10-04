-- Deflactor por país (IPCA anual de Eurostat, prc_hicp_aind, desde 1996): factor para pasar
-- euros (o moneda nacional) de cada año a precios del último año completo común, como
-- mother.deflactor hace para España con el IPC del INE. importe_real = importe * factor.
-- España también está aquí (con el IPCA, que difiere poco del IPC): para comparar países
-- entre sí se usa esta tabla en todos, España incluida.
with ipca as (
    select cast(h.anio as integer) as anio, p.cod_pais, p.pais, h.indice
    from {{ source('raw', 'eurostat_hicp_paises') }} h
    join {{ ref('paises_iso') }} p on p.eurostat = h.geo
    where h.indice is not null
),

base as (
    -- último año con dato de España y de la UE: el mismo año base para todos
    select min(m) as anio_base
    from (select max(anio) as m from ipca where cod_pais in ('ES', 'EU27_2020') group by cod_pais)
)

select
    i.cod_pais,
    i.pais,
    i.anio,
    b.anio_base,
    i.indice as ipca,
    (select indice from ipca x where x.cod_pais = i.cod_pais and x.anio = b.anio_base) / i.indice as factor
from ipca i
cross join base b
