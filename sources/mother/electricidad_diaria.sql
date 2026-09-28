-- Últimos 3 años de energía diaria por sistema
SELECT * FROM electricidad_diaria
WHERE fecha >= (SELECT max(fecha) FROM electricidad_diaria) - INTERVAL 3 YEAR
