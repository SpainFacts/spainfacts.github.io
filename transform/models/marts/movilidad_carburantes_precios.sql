-- Precio medio mensual de venta al público de gasóleo A, gasolina 95 y GLP en España y en cada
-- provincia desde 2007 (media de los días 1, 8, 15 y 22 de la media de las estaciones), en euros
-- corrientes y en euros constantes del año base de mother.deflactor. Un año sin deflactor da
-- NULL en la columna real.
with dias as (
    select * from {{ source('raw_carburantes', 'carburantes_precios_dia') }}
),

mensual as (
    select
        date_trunc('month', fecha)::date as fecha,
        cod_prov,
        producto,
        avg(precio_medio) as precio_litro,
        avg(precio_mediano) as precio_mediano_litro,
        round(avg(estaciones)) as estaciones,
        count(*) as dias
    from dias
    group by 1, 2, 3
)

select
    m.fecha,
    year(m.fecha) as anio,
    case when m.cod_prov = '00' then 'pais' else 'provincia' end as nivel,
    m.cod_prov as cod,
    case when m.cod_prov = '00' then 'España' else p.nombre end as nombre,
    m.producto,
    case m.producto when 'gasoleo_a' then 'Gasóleo A' when 'gasolina_95' then 'Gasolina 95' else 'GLP (autogás)' end as carburante,
    m.precio_litro,
    m.precio_litro * d.factor as precio_litro_real,
    m.precio_mediano_litro,
    d.anio_base,
    m.estaciones::integer as estaciones,
    m.dias
from mensual m
left join {{ ref('territorios_provincias') }} p on p.cod_prov = m.cod_prov
left join {{ ref('deflactor') }} d on d.anio = year(m.fecha)
