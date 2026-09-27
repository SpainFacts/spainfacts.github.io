-- Población nacional por sexo a 1 de enero
SELECT anio::VARCHAR AS Year, poblacion AS Total, sexo AS Sexo
FROM poblacion_anual
WHERE es_total_nacional AND sexo <> 'Total'
