-- Rendición de cuentas de los ayuntamientos al Tribunal de Cuentas por obligación
-- y ejercicio (ver el modelo dbt transparencia_tcu). aplica_indicador = false si
-- el plazo no ha vencido o la obligación no aplica.
SELECT cod_mun, municipio, cod_prov, cod_ccaa, id_entidad, obligacion, ejercicio, fecha_limite,
       estado, dias_retraso, fecha_envio, poblacion, tramo_poblacion, tramo_orden,
       aplica_indicador, incumple, alcalde_en_plazo, lista_en_plazo, familia_en_plazo,
       color_familia, fecha_extraccion
FROM transparencia_tcu
