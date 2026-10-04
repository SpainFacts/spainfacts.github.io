-- Serie anual por municipio (2010-hoy) solo con totales, para el gráfico de
-- evolución. El detalle por capítulos y áreas está en municipios_cuentas.sql
-- (últimos años) para no descargar 13 MB en cada visita.
-- Los euros van corrientes (los de cada año) y en constantes (_real, de anio_base).
-- tramo_poblacion / tramo_orden: el mismo criterio que municipios_cuentas_medias.
SELECT
    cod_mun, municipio, cod_prov, provincia, anio, provisional, tiene_datos, poblacion,
    CASE
        WHEN poblacion < 1000 THEN '<1.000' WHEN poblacion < 5000 THEN '1.000-5.000'
        WHEN poblacion < 20000 THEN '5.000-20.000' WHEN poblacion < 50000 THEN '20.000-50.000'
        WHEN poblacion < 100000 THEN '50.000-100.000' WHEN poblacion < 500000 THEN '100.000-500.000'
        WHEN poblacion >= 500000 THEN '>500.000'
    END AS tramo_poblacion,
    CASE
        WHEN poblacion < 1000 THEN 1 WHEN poblacion < 5000 THEN 2 WHEN poblacion < 20000 THEN 3
        WHEN poblacion < 50000 THEN 4 WHEN poblacion < 100000 THEN 5 WHEN poblacion < 500000 THEN 6
        WHEN poblacion >= 500000 THEN 7
    END AS tramo_orden,
    round(ingresos_total)::BIGINT AS ingresos_total,
    round(gastos_total)::BIGINT AS gastos_total,
    round(saldo_no_financiero)::BIGINT AS saldo_no_financiero,
    round(gasto_hab)::INTEGER AS gasto_hab,
    round(ingreso_hab)::INTEGER AS ingreso_hab,
    round(ingresos_total_real)::BIGINT AS ingresos_total_real,
    round(gastos_total_real)::BIGINT AS gastos_total_real,
    round(gasto_hab_real)::INTEGER AS gasto_hab_real,
    round(ingreso_hab_real)::INTEGER AS ingreso_hab_real,
    round(saldo_hab_real)::INTEGER AS saldo_hab_real,
    anio_base
FROM municipios_cuentas
