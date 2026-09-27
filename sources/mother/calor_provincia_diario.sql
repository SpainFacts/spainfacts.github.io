-- Últimos ~2 años: suficiente para el mapa por fecha y la serie del año en curso
SELECT * FROM calor_provincia_diario
WHERE fecha >= (SELECT max(fecha) FROM calor_provincia_diario) - INTERVAL 800 DAY
