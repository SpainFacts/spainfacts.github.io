-- Mart dbt renta_municipios (transform/models/marts/renta_municipios.sql)
SELECT * FROM renta_municipios
-- Ordenado por municipio: la ficha de municipio lee solo los grupos de filas del suyo
ORDER BY cod_mun, anio
