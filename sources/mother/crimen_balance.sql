-- Mart dbt crimen_balance (transform/models/marts/crimen_balance.sql)
SELECT * FROM crimen_balance
-- Ordenado por territorio: las fichas leen solo los grupos de filas del suyo
ORDER BY nivel, cod, anio, categoria
