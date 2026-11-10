-- Mart dbt renta_distritos (transform/models/marts/renta_distritos.sql)
SELECT * FROM renta_distritos
-- Ordenado por municipio: la ficha de municipio lee solo los grupos de filas del suyo
ORDER BY cod_mun, anio, cod_distrito
