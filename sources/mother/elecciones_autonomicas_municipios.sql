-- Mart dbt elecciones_autonomicas_municipios (transform/models/marts/elecciones_autonomicas_municipios.sql)
-- Resultado de cada autonómica en cada municipio, ordenado por comunidad para que la
-- página de cada una lea solo sus grupos de filas.
SELECT * FROM elecciones_autonomicas_municipios
ORDER BY cod_ccaa, proceso, cod_mun
