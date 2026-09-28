-- Gasto de cada ayuntamiento por política de gasto (Hacienda, CONPREL), solo el
-- último ejercicio con liquidación definitiva, en euros y euros por habitante
SELECT cod_mun, anio, cod_area, area_nombre, cod_politica, politica_nombre, importe, importe_hab
FROM municipios_politicas
WHERE anio = (SELECT max(anio) FROM municipios_politicas)
