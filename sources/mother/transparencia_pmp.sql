-- Periodo medio de pago a proveedores: ¿comunica el ayuntamiento su PMP cada
-- trimestre? Últimos 12 trimestres (ver el modelo dbt).
-- fecha = primer día del trimestre. supera_30_pct: 100 si el PMP supera los 30 días, 0 si no,
-- NULL si no aplica o no se mide con la metodología actual.
SELECT cod_mun, municipio, cod_prov, provincia, cod_ccaa, ccaa, anio, trimestre, periodo,
       fecha_trimestre AS fecha, poblacion, tramo_poblacion, tramo_orden,
       reporta, pmp_dias, supera_30, supera_30_pct, aplica_indicador,
       alcalde_en_plazo, lista_en_plazo, familia_en_plazo
FROM transparencia_pmp
WHERE fecha_trimestre >= (SELECT max(fecha_trimestre) FROM transparencia_pmp) - INTERVAL 33 MONTH
