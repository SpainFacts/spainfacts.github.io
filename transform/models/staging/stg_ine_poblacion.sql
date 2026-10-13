-- Población a 1 de enero por provincia, sexo y edad simple (INE, tabla 56945).
-- El INE incluye "85 y más años" además de las edades 85..99 y "100 y más":
-- es un subtotal y se descarta para que las sumas por edad cuadren con el total.
-- Pero en 1971-1980 no hay detalle por encima de 84 y "85 y más" es el último
-- grupo: ahí se conserva (mismo criterio que demografia_edad_simple).
with base as (
    select
        *,
        bool_or(edad between 85 and 99 and not edad_abierta)
            over (partition by anio, cod_prov, sexo) as hay_detalle_85
    from {{ source('raw', 'ine_poblacion_provincias') }}
    where poblacion is not null
)

select
    anio,
    cod_prov,
    provincia,
    cod_prov is null as es_total_nacional,
    sexo,
    edad,
    edad_etiqueta,
    edad is null as es_todas_las_edades,
    poblacion
from base
where not (edad_abierta and edad < 100 and hay_detalle_85)
