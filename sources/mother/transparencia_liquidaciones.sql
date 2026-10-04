-- Remisión de la liquidación municipal a Hacienda por año (ver el modelo dbt).
-- aplica_indicador = false en territorios forales (motivo_exclusion).
-- incumple_pct: 100 si no la remitió, 0 si sí, NULL si no aplica (avg(incumple_pct) es el % de ayuntamientos).
SELECT cod_mun, municipio, cod_prov, provincia, cod_ccaa, ccaa, anio, poblacion, tramo_poblacion, tramo_orden,
       remitida, incumple, incumple_pct, aplica_indicador, motivo_exclusion,
       alcalde_en_plazo, lista_en_plazo, familia_en_plazo, color_familia
FROM transparencia_liquidaciones
