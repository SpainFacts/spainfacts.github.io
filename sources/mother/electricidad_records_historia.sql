-- Cada vez que se batió un récord (es_inicio_serie marca el primer año de cada serie,
-- en el que casi todo es récord; la página lo filtra)
SELECT codigo, categoria, sentido, sistema, periodo, fecha, valor, unidad, ts_local, valor_anterior, ts_anterior, mejora, n_record, es_inicio_serie, orden
FROM electricidad_records_historia
