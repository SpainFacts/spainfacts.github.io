-- Stock mensual de ayuntamientos retenidos por sección, con el importe
-- retenido ese mes (euros; repartido si hay varias secciones el mismo mes),
-- en euros constantes (anio_base) y por habitante.
SELECT CAST(periodo AS DATE) AS fecha, anio, seccion, ejercicio_referencia,
       cod_mun, municipio, cod_prov, provincia, por_dependientes,
       importe_eur, importe_eur_real, importe_eur_hab, importe_eur_hab_real, anio_base
FROM transparencia_pie_mensual
