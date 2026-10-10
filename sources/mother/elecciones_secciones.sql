-- Mart dbt elecciones_secciones (transform/models/marts/elecciones_secciones.sql)
-- ~100k filas (sección x elección), ordenadas por municipio para que la ficha de
-- municipio lea solo los grupos de filas de su municipio.
SELECT * FROM elecciones_secciones
ORDER BY cod_mun, proceso, cod_seccion
