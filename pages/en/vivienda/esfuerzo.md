---
title: Affordability of buying or renting
description: "How many years of gross salary a 90 m² home costs in Spain and in each region, and what share of pay goes on rent, with data from the Ministry of Housing and the INE."
i18n_origen: 5b404f87105a
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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
SELECT e.cod, e.nombre AS comunidad, '/en' || t.ruta AS ruta, e.anio, e.anios_salario, e.precio_90m2, e.salario_anual,
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

# ⚖️ Affordability of buying or renting

How much housing weighs on pay. For buying: **how many years of total gross salary** it takes to pay for a 90 m² flat at the average appraised value, not counting taxes, fees or interest. For renting: **what share of gross salary** goes on the median rent for a flat. Since euros from the same year are compared, inflation does not affect the result.

<Grid cols=4>
    <KpiCard
        title="Years of salary for 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} years"
        period="Spain, {hitos[0]?.anio_ult} · peak: {formatNumber(hitos[0]?.anios_max, 1)} in {hitos[0]?.anio_max}"
        direction="positive-down"
        source="Ministry of Housing / INE"
        sparklineData={compra.map(d => d.anios_salario)}
    />
    <KpiCard
        title="Rent as a share of salary"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="of the average gross salary, {alquiler.slice(-1)[0]?.anio} · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} € per month"
        direction="positive-down"
        source="Ministry of Housing / INE"
        sparklineData={alquiler.map(d => d.pct_alquiler)}
    />
    <KpiCard
        title="Where buying costs most"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} years"
        period="{ccaa[0]?.comunidad}, {ccaa[0]?.anio} · where it costs least: {ccaa.slice(-1)[0]?.comunidad}, {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)}"
        direction="positive-down"
        source="Ministry of Housing / INE"
        sparklineData={ccaa_serie.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => d.anios_salario)}
    />
    <KpiCard
        title="Average gross salary"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} € per year"
        period="Spain, {hitos[0]?.anio_ult} · a 90 m² flat is appraised at {formatNumber(hitos[0]?.precio_ult, 0)} €"
        source="INE / ETCL"
        sparklineData={compra.map(d => d.salario_anual)}
    />
</Grid>

## Buying: years of salary

Between {hitos[0]?.anio_ini} and {hitos[0]?.anio_ult} the appraised value of a 90 m² flat changed by {formatNumber(hitos[0]?.var_precio, 1)} % and the average gross salary by {formatNumber(hitos[0]?.var_salario, 1)} %, both in euros of each year. The low point of the series was in {hitos[0]?.anio_min}, at {formatNumber(hitos[0]?.anios_min, 1)} years of salary.

<LineChart
    data={compra}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="years of gross salary"
    startingAtZero={false}
    title="Years of average gross salary to pay for a 90 m² home in Spain"
/>

<LineChart
    data={ccaa_serie}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="years of gross salary"
    title="The three least affordable regions, the most affordable one and Spain"
/>

## Renting: share of salary

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of gross salary"
    startingAtZero={false}
    title="Median rent for a flat as a share of the average gross salary in Spain"
/>

## By region

Buying: data for {ccaa[0]?.anio}; renting: for {ccaa[0]?.anio_alquiler}, the latest year published. The salary used is that of each region, so the comparison takes into account that pay is higher in some regions than in others.

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="years of gross salary"
    title="Years of salary to pay for 90 m² by region, {ccaa[0]?.anio}"
/>

<BarChart
    data={ccaa_alquiler}
    x=comunidad
    y=pct_alquiler
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% of gross salary"
    title="Median rent as a share of salary by region, {ccaa_alquiler[0]?.anio}"
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=anios_salario title="Years of salary (90 m²)" fmt='0.0' />
    <Column id=precio_90m2 title="90 m² flat (€)" fmt='#,##0' />
    <Column id=salario_anual title="Annual gross salary (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Rent / salary %" fmt='0.0' />
    <Column id=alquiler_mes_mediana title="Median rent (€/month)" fmt='#,##0' />
</DataTable>

Ceuta and Melilla are not shown because the Labour Cost Survey does not provide their salary.

---

**Calculation:** years of salary = average appraised value of open-market housing for the year (average of its four quarters, [Ministry of Housing](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)) × 90 m² ÷ (total wage cost per worker per month × 12, [INE, Quarterly Labour Cost Survey, table 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061), industry, construction and services). Rent as a share of salary = median monthly rent for a flat ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) × 12 ÷ that same annual salary. These are average gross salaries per worker, not household incomes.
