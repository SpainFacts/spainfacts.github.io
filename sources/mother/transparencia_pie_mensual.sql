-- Stock mensual de ayuntamientos retenidos por sección, con el importe
-- retenido ese mes (euros; repartido si hay varias secciones el mismo mes).
SELECT periodo, seccion, ejercicio_referencia, cod_mun, cod_prov,
       por_dependientes, importe_eur
FROM transparencia_pie_mensual
