-- Gasolineras por grupo empresarial: cuántas tiene cada uno, su cuota de la red y su precio
-- medio frente a la media de España en el momento de la foto (sin pesar por ventas: el
-- Ministerio no publica litros por estación).
with base as (
    select * from {{ ref('movilidad_gasolineras') }}
),

media as (
    select avg(precio_gasoleo_a) as gasoleo_a, avg(precio_gasolina_95) as gasolina_95 from base
)

select
    b.grupo,
    b.tipo,
    count(*) as estaciones,
    100.0 * count(*) / sum(count(*)) over () as cuota_pct,
    count(distinct b.cod_prov) as provincias,
    avg(b.precio_gasoleo_a) as precio_gasoleo_a,
    avg(b.precio_gasolina_95) as precio_gasolina_95,
    avg(b.precio_gasoleo_a) - any_value(m.gasoleo_a) as dif_gasoleo_a,
    avg(b.precio_gasolina_95) - any_value(m.gasolina_95) as dif_gasolina_95
from base b
cross join media m
group by b.grupo, b.tipo
