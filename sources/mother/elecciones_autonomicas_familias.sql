-- Mart dbt elecciones_autonomicas_familias (transform/models/marts/elecciones_autonomicas_familias.sql)
SELECT * FROM elecciones_autonomicas_familias
ORDER BY cod_ccaa, fecha, votos DESC
