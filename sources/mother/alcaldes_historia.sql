-- ~100k periodos desde 1979: a Evidence solo llegan los 5 últimos mandatos (2007-hoy)
SELECT
    cod_mun, mandato, orden, es_actual, municipio, alcalde, cargo,
    fecha_posesion, fecha_fin, partido_original, familia, siglas_familia, color,
    familia_inferida, clave
FROM alcaldes_historia
WHERE mandato >= '2007'
