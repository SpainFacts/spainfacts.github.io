---
title: Esfuerzo para comprar o alquilar
description: "Cuántos años de salario bruto cuesta una vivienda de 90 m² en España y en cada comunidad, y qué parte del sueldo se va en el alquiler, con datos del Ministerio de Vivienda y del INE."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, anios_salario, pct_alquiler, precio_90m2, salario_anual, alquiler_mes_mediana
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais'
ORDER BY anio
```

```sql compra
SELECT * FROM ${espana} WHERE anios_salario IS NOT NULL ORDER BY anio
```

```sql alquiler
SELECT * FROM ${espana} WHERE pct_alquiler IS NOT NULL ORDER BY anio
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(anios_salario, anio) AS anios_ult,
    arg_max(precio_90m2, anio) AS precio_ult,
    arg_max(salario_anual, anio) AS salario_ult,
    max(anios_salario) AS anios_max,
    arg_max(anio, anios_salario) AS anio_max,
    min(anios_salario) AS anios_min,
    arg_min(anio, anios_salario) AS anio_min,
    100 * (arg_max(precio_90m2, anio) / arg_min(precio_90m2, anio) - 1) AS var_precio,
    100 * (arg_max(salario_anual, anio) / arg_min(salario_anual, anio) - 1) AS var_salario,
    min(anio) AS anio_ini
FROM ${compra}
```

```sql ccaa
SELECT e.cod, e.nombre AS comunidad, t.ruta, e.anio, e.anios_salario, e.precio_90m2, e.salario_anual,
       a.anio AS anio_alquiler, a.pct_alquiler, a.alquiler_mes_mediana
FROM mother.vivienda_esfuerzo e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
LEFT JOIN mother.vivienda_esfuerzo a
  ON a.nivel = 'ccaa' AND a.cod = e.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND anios_salario IS NOT NULL)
ORDER BY e.anios_salario DESC
```

```sql ccaa_alquiler
SELECT e.cod, e.nombre AS comunidad, e.anio, e.pct_alquiler
FROM mother.vivienda_esfuerzo e
WHERE e.nivel = 'ccaa' AND e.pct_alquiler IS NOT NULL
  AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
ORDER BY e.pct_alquiler DESC
```

```sql ccaa_serie
SELECT anio, nombre, anios_salario
FROM mother.vivienda_esfuerzo
WHERE anios_salario IS NOT NULL
  AND (nivel = 'pais' OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario DESC LIMIT 3) OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario LIMIT 1))
ORDER BY anio, nombre
```

# ⚖️ Esfuerzo para comprar o alquilar

Cuánto pesa la vivienda en el sueldo. Para comprar: **cuántos años de salario bruto íntegro** hacen falta para pagar un piso de 90 m² al valor tasado medio, sin contar impuestos, gastos ni intereses. Para alquilar: **qué parte del salario bruto** se va en el alquiler mediano de un piso. Como se comparan euros del mismo año, la inflación no altera el resultado.

<Grid cols=4>
    <KpiCard
        title="Años de salario para 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} años"
        period="España, {hitos[0]?.anio_ult} · máximo: {formatNumber(hitos[0]?.anios_max, 1)} en {hitos[0]?.anio_max}"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        sparklineData={compra.map(d => d.anios_salario)}
    />
    <KpiCard
        title="Alquiler sobre el salario"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="del salario bruto medio, {alquiler.slice(-1)[0]?.anio} · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} € al mes"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        sparklineData={alquiler.map(d => d.pct_alquiler)}
    />
    <KpiCard
        title="Donde más cuesta comprar"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} años"
        period="{ccaa[0]?.comunidad}, {ccaa[0]?.anio} · donde menos: {ccaa.slice(-1)[0]?.comunidad}, {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)}"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        sparklineData={ccaa_serie.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => d.anios_salario)}
    />
    <KpiCard
        title="Salario bruto medio"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} € al año"
        period="España, {hitos[0]?.anio_ult} · un piso de 90 m² se tasa en {formatNumber(hitos[0]?.precio_ult, 0)} €"
        source="INE / ETCL"
        sparklineData={compra.map(d => d.salario_anual)}
    />
</Grid>

## Comprar: años de salario

Entre {hitos[0]?.anio_ini} y {hitos[0]?.anio_ult} el valor tasado de un piso de 90 m² cambió un {formatNumber(hitos[0]?.var_precio, 1)} % y el salario bruto medio, un {formatNumber(hitos[0]?.var_salario, 1)} %, ambos en euros de cada año. El mínimo de la serie fue en {hitos[0]?.anio_min}, con {formatNumber(hitos[0]?.anios_min, 1)} años de salario.

<LineChart
    data={compra}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="años de salario bruto"
    startingAtZero={false}
    title="Años de salario bruto medio para pagar una vivienda de 90 m² en España"
/>

<LineChart
    data={ccaa_serie}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="años de salario bruto"
    title="Las tres comunidades con más esfuerzo, la de menos y España"
/>

## Alquilar: parte del salario

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del salario bruto"
    startingAtZero={false}
    title="Alquiler mediano de un piso sobre el salario bruto medio en España"
/>

## Por comunidad

Compra: datos de {ccaa[0]?.anio}; alquiler: de {ccaa[0]?.anio_alquiler}, último año publicado. El salario es el de cada comunidad, así que la comparación tiene en cuenta que en unas se cobra más que en otras.

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="años de salario bruto"
    title="Años de salario para pagar 90 m² por comunidad, {ccaa[0]?.anio}"
/>

<BarChart
    data={ccaa_alquiler}
    x=comunidad
    y=pct_alquiler
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% del salario bruto"
    title="Alquiler mediano sobre el salario por comunidad, {ccaa_alquiler[0]?.anio}"
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=anios_salario title="Años de salario (90 m²)" fmt='0.0' />
    <Column id=precio_90m2 title="Piso de 90 m² (€)" fmt='#,##0' />
    <Column id=salario_anual title="Salario bruto anual (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Alquiler / salario %" fmt='0.0' />
    <Column id=alquiler_mes_mediana title="Alquiler mediano (€/mes)" fmt='#,##0' />
</DataTable>

Ceuta y Melilla no aparecen porque la Encuesta de Coste Laboral no da su salario.

---

**Cálculo:** años de salario = valor tasado medio de la vivienda libre del año (media de sus cuatro trimestres, [Ministerio de Vivienda](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)) × 90 m² ÷ (coste salarial total por trabajador y mes × 12, [INE, Encuesta Trimestral de Coste Laboral, tabla 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061), industria, construcción y servicios). Alquiler sobre salario = alquiler mensual mediano de un piso ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) × 12 ÷ ese mismo salario anual. Son salarios brutos medios por trabajador, no ingresos por hogar.
