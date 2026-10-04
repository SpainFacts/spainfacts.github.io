-- Gasto de cada ayuntamiento por política de gasto (Hacienda, CONPREL), solo el
-- último ejercicio con liquidación definitiva, en euros corrientes y constantes
-- (_real, de anio_base), en total y por habitante
SELECT cod_mun, municipio, anio, cod_area, area_nombre, cod_politica, politica_nombre, poblacion,
    importe, importe_hab, importe_real, importe_hab_real, anio_base
FROM municipios_politicas
WHERE anio = (SELECT max(anio) FROM municipios_politicas)
