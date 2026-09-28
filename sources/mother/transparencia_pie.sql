-- Retención de la participación en los tributos del Estado por no remitir
-- información (art. 36 Ley 2/2011): panel ayuntamiento x ejercicio x sección
-- (ver el modelo dbt). aplica_indicador = false en territorios forales.
SELECT cod_mun, municipio, cod_prov, cod_ccaa, anio, seccion, seccion_nombre,
       poblacion, tramo_poblacion, tramo_orden,
       retenido, meses_retenido, primer_mes, ultimo_mes, sigue_retenido,
       importe_retenido_eur, por_dependientes, ejercicio_inferido,
       campania_completa, aplica_indicador,
       alcalde, lista, familia, color_familia
FROM transparencia_pie
