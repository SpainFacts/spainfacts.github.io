-- Población total nacional a 1 de enero (INE ECP, mart poblacion_anual)
SELECT anio::VARCHAR AS Year, poblacion AS Total
FROM poblacion_anual
WHERE es_total_nacional AND sexo = 'Total'
ORDER BY Year DESC
