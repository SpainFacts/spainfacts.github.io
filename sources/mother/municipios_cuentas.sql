-- Cuentas de los ayuntamientos (Hacienda, CONPREL) con detalle por capítulos y
-- áreas, SOLO para los tres últimos años definitivos y el avance provisional (la
-- serie completa de totales está en municipios_cuentas_serie.sql). Una fila por municipio
-- y año; importes nulos si tiene_datos = false. Para aligerar el navegador (~13 MB):
-- euros redondeados a enteros, por habitante sin decimales, y sin los subtotales
-- no financieros (= suma de los capítulos 1-7; saldo_no_financiero sí se incluye).
-- Los capítulos y áreas van en euros corrientes; las columnas _real (euros
-- constantes de anio_base) cubren los totales y el gasto/ingreso por habitante.
SELECT
    cod_mun, municipio, cod_prov, provincia, anio, provisional, poblacion, tiene_datos,
    round(ingresos_c1)::BIGINT AS ingresos_c1, round(ingresos_c2)::BIGINT AS ingresos_c2,
    round(ingresos_c3)::BIGINT AS ingresos_c3, round(ingresos_c4)::BIGINT AS ingresos_c4,
    round(ingresos_c5)::BIGINT AS ingresos_c5, round(ingresos_c6)::BIGINT AS ingresos_c6,
    round(ingresos_c7)::BIGINT AS ingresos_c7, round(ingresos_c8)::BIGINT AS ingresos_c8,
    round(ingresos_c9)::BIGINT AS ingresos_c9, round(ingresos_total)::BIGINT AS ingresos_total,
    round(gastos_c1)::BIGINT AS gastos_c1, round(gastos_c2)::BIGINT AS gastos_c2,
    round(gastos_c3)::BIGINT AS gastos_c3, round(gastos_c4)::BIGINT AS gastos_c4,
    round(gastos_c5)::BIGINT AS gastos_c5, round(gastos_c6)::BIGINT AS gastos_c6,
    round(gastos_c7)::BIGINT AS gastos_c7, round(gastos_c8)::BIGINT AS gastos_c8,
    round(gastos_c9)::BIGINT AS gastos_c9, round(gastos_total)::BIGINT AS gastos_total,
    round(gasto_area_0)::BIGINT AS gasto_area_0, round(gasto_area_1)::BIGINT AS gasto_area_1,
    round(gasto_area_2)::BIGINT AS gasto_area_2, round(gasto_area_3)::BIGINT AS gasto_area_3,
    round(gasto_area_4)::BIGINT AS gasto_area_4, round(gasto_area_9)::BIGINT AS gasto_area_9,
    round(saldo_no_financiero)::BIGINT AS saldo_no_financiero,
    round(gasto_hab)::INTEGER AS gasto_hab, round(ingreso_hab)::INTEGER AS ingreso_hab,
    round(gastos_total_real)::BIGINT AS gastos_total_real, round(ingresos_total_real)::BIGINT AS ingresos_total_real,
    round(saldo_no_financiero_real)::BIGINT AS saldo_no_financiero_real,
    round(gasto_hab_real)::INTEGER AS gasto_hab_real, round(ingreso_hab_real)::INTEGER AS ingreso_hab_real,
    anio_base
FROM municipios_cuentas
WHERE anio >= (SELECT max(anio) FROM municipios_cuentas WHERE NOT provisional) - 2
