SELECT indicador_id, nombre, tema, nivel, cod, territorio, CAST(anio AS INTEGER) AS anio, valor, unidad, sentido, fuente, url_fuente, pagina, nota
FROM mapas_indicadores
