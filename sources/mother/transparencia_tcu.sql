-- Rendición de cuentas de los ayuntamientos al Tribunal de Cuentas por obligación
-- y ejercicio (ver el modelo dbt transparencia_tcu). aplica_indicador = false si
-- el plazo no ha vencido o la obligación no aplica. incumple_pct: 100 si no la rindió,
-- 0 si sí, NULL si no aplica. anio = ejercicio al que se refiere la rendición.
SELECT cod_mun, municipio, cod_prov, provincia, cod_ccaa, ccaa, id_entidad, obligacion, anio, fecha_limite,
       estado, dias_retraso, fecha_envio, poblacion, tramo_poblacion, tramo_orden,
       aplica_indicador, incumple, incumple_pct, alcalde_en_plazo, lista_en_plazo, familia_en_plazo,
       color_familia, fecha_extraccion
FROM transparencia_tcu
