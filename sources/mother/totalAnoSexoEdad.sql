-- Pirámide nacional por grupos quinquenales (mart poblacion_piramide).
-- Antes sumaba los cuatro trimestres de cada año y multiplicaba los totales.
SELECT sexo AS Sexo, anio::VARCHAR AS Anio, rango_edad AS RangoEdad, orden_grupo AS Orden_Grupo, poblacion AS Total
FROM poblacion_piramide
ORDER BY Anio, Sexo, Orden_Grupo
