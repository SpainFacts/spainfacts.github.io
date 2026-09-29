{{ config(materialized='ephemeral') }}
-- Población a 1 de enero por provincia (o total nacional, cod '00'), sexo y edad
-- simple, sin duplicados, para los marts demografia_*.
-- Fuente: INE, Estadística Continua de Población, tabla 56945
-- (raw.ine_poblacion_provincias, cargada por ingestion/ine.py).
-- El INE publica "85 y más años" como subtotal de 85..99 y "100 y más", pero en
-- los primeros años de la serie (hasta finales de los 80) no hay detalle por
-- encima de 84 y solo existe ese grupo abierto. Aquí se conserva "85 y más"
-- cuando no hay detalle y se descarta cuando lo hay, para que las sumas cuadren
-- siempre con el total. (stg_ine_poblacion lo descarta siempre, lo que deja sin
-- los mayores de 84 los años antiguos.)
with base as (
    select
        cast(anio as integer) as anio,
        coalesce(cod_prov, '00') as cod,
        sexo,
        edad,
        edad_abierta,
        poblacion
    from {{ source('raw', 'ine_poblacion_provincias') }}
    where poblacion is not null and edad is not null
),

con_detalle as (
    select distinct anio, cod, sexo
    from base
    where edad between 85 and 99 and not edad_abierta
)

select
    b.anio,
    b.cod,
    b.sexo,
    b.edad,
    b.edad_abierta and b.edad = 85 as es_85_y_mas,
    b.poblacion
from base b
left join con_detalle d using (anio, cod, sexo)
where not (b.edad_abierta and b.edad < 100 and d.anio is not null)
