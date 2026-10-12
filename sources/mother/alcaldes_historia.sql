-- ~105k periodos de alcalde desde 1979 (todos los mandatos), ordenados por municipio
-- para que la ficha de municipio lea solo los grupos de filas del suyo.
SELECT
    cod_mun, mandato, orden, es_actual, municipio, alcalde, cargo,
    fecha_posesion, fecha_fin, partido_original, familia, siglas_familia, color,
    familia_inferida, clave
FROM alcaldes_historia
ORDER BY cod_mun, fecha_posesion
