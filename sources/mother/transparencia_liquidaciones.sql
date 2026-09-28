-- Remisión de la liquidación municipal a Hacienda por año (ver el modelo dbt).
-- aplica_indicador = false en territorios forales (motivo_exclusion).
SELECT cod_mun, municipio, cod_prov, cod_ccaa, anio, poblacion, tramo_poblacion, tramo_orden,
       remitida, incumple, aplica_indicador, motivo_exclusion,
       alcalde_en_plazo, lista_en_plazo, familia_en_plazo, color_familia
FROM transparencia_liquidaciones
