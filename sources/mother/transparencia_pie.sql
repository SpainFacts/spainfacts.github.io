-- Retención de la participación en los tributos del Estado por no remitir
-- información (art. 36 Ley 2/2011): panel ayuntamiento x ejercicio x sección
-- (ver el modelo dbt). aplica_indicador = false en territorios forales.
-- es_parcial = campaña ya empezada cuando arranca la serie (solo se ven sus últimos meses).
SELECT cod_mun, municipio, cod_prov, provincia, cod_ccaa, ccaa, anio, seccion, seccion_nombre,
       poblacion, tramo_poblacion, tramo_orden,
       retenido, retenido_pct, meses_retenido, primer_mes, ultimo_mes, sigue_retenido,
       importe_retenido_eur, importe_retenido_eur_real, importe_retenido_eur_hab,
       importe_retenido_eur_hab_real, anio_base,
       por_dependientes, ejercicio_inferido,
       NOT campania_completa AS es_parcial, aplica_indicador,
       alcalde, lista, familia, color_familia
FROM transparencia_pie
