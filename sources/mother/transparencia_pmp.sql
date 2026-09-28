-- Periodo medio de pago a proveedores: ¿comunica el ayuntamiento su PMP cada
-- trimestre? Últimos 12 trimestres (ver el modelo dbt).
SELECT cod_mun, municipio, cod_prov, cod_ccaa, anio, trimestre, periodo,
       fecha_trimestre, poblacion, tramo_poblacion, tramo_orden,
       reporta, pmp_dias, supera_30, aplica_indicador,
       alcalde_en_plazo, lista_en_plazo, familia_en_plazo
FROM transparencia_pmp
WHERE fecha_trimestre >= (SELECT max(fecha_trimestre) FROM transparencia_pmp) - INTERVAL 33 MONTH
