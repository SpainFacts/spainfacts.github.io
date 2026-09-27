-- Población a 1 de enero por provincia, sexo y edad simple (INE, tabla 56945).
-- El INE incluye "85 y más años" además de las edades 85..99 y "100 y más":
-- es un subtotal y se descarta para que las sumas por edad cuadren con el total.
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
from {{ source('raw', 'ine_poblacion_provincias') }}
where poblacion is not null
  and not (edad_abierta and edad < 100)
