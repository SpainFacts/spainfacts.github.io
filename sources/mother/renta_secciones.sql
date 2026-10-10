-- Mart dbt renta_secciones (transform/models/marts/renta_secciones.sql)
-- Solo el último año: los mapas de barrio pintan la renta más reciente (las secciones
-- cambian de un año a otro y su serie apenas se compara).
SELECT * FROM renta_secciones
WHERE anio = (SELECT max(anio) FROM renta_secciones)
ORDER BY cod_mun, cod_seccion
