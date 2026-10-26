-- Índice propio de publicidad activa (elaboración propia, modelo dbt transparencia_cumplimiento):
-- una fila por entidad, obligación y periodo. Solo los últimos años para que la web pese poco
-- (la serie completa está en MotherDuck). Criterios: seed elaboracion_propia_indicadores.
SELECT obligacion, obligacion_nombre, tipo_entidad, cod_entidad, nombre_entidad, cod_mun, cod_prov, provincia,
       cod_ccaa, ccaa, periodo, anio, fecha_plazo, estado, dias_retraso, n_total, n_fuera_plazo, mediana_dias,
       aplica_indicador, motivo_no_aplica, poblacion, tramo_poblacion, tramo_orden, puntuacion, es_ultimo, vencido, bloque,
       incumplimiento_destacado, gobernante_en_plazo, familia_en_plazo, url_fuente
FROM transparencia_cumplimiento
WHERE anio >= year(current_date) - 6
