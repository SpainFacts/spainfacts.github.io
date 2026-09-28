-- Serie anual por municipio (2010-hoy) solo con totales, para el gráfico de
-- evolución. El detalle por capítulos y áreas está en municipios_cuentas.sql
-- (últimos años) para no descargar 13 MB en cada visita.
SELECT
    cod_mun, anio, provisional, tiene_datos, poblacion,
    round(ingresos_total)::BIGINT AS ingresos_total,
    round(gastos_total)::BIGINT AS gastos_total,
    round(saldo_no_financiero)::BIGINT AS saldo_no_financiero,
    round(gasto_hab)::INTEGER AS gasto_hab,
    round(ingreso_hab)::INTEGER AS ingreso_hab
FROM municipios_cuentas
