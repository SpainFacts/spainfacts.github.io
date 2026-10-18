---
title: "The gap between housing and wages: how many years of pay it takes to buy or rent"
description: "Analysis of the real evolution of purchase and rental prices compared to gross wages in Spain and by autonomous community, with data from the Ministry of Housing and the INE."
i18n_origen: 3001d864626b
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT
    anio,
    anios_salario,
    pct_alquiler,
    precio_90m2,
    salario_anual,
    alquiler_mes_mediana,
    precio_90m2_real,
    salario_anual_real,
    CAST(anio_base AS INTEGER) AS anio_base,
    100.0 * precio_90m2_real / first_value(precio_90m2_real) OVER (ORDER BY anio) AS idx_precio_real,
    100.0 * salario_anual_real / first_value(salario_anual_real) OVER (ORDER BY anio) AS idx_salario_real
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql indices
SELECT anio, 'Vivienda 90 m² (euros reales)' AS serie, idx_precio_real AS indice FROM ${espana}
UNION ALL
SELECT anio, 'Salario bruto medio (euros reales)' AS serie, idx_salario_real AS indice FROM ${espana}
ORDER BY anio, serie
```

```sql alquiler
SELECT anio, pct_alquiler, alquiler_mes_mediana, alquiler_mes_mediana_real
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND pct_alquiler IS NOT NULL
ORDER BY anio
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    min(anio) AS anio_ini,
    arg_max(anios_salario, anio) AS anios_ult,
    arg_max(precio_90m2, anio) AS precio_ult,
    arg_max(salario_anual, anio) AS salario_ult,
    max(anios_salario) AS anios_max,
    arg_max(anio, anios_salario) AS anio_max,
    min(anios_salario) AS anios_min,
    arg_min(anio, anios_salario) AS anio_min,
    100.0 * (arg_max(precio_90m2_real, anio) / arg_min(precio_90m2_real, anio) - 1) AS var_precio_real,
    100.0 * (arg_max(salario_anual_real, anio) / arg_min(salario_anual_real, anio) - 1) AS var_salario_real,
    max(anio_base) AS anio_base
FROM ${espana}
```

```sql ccaa
SELECT
    e.cod,
    e.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    e.anio,
    e.anios_salario,
    e.precio_90m2,
    e.salario_anual,
    a.anio AS anio_alquiler,
    a.pct_alquiler,
    a.alquiler_mes_mediana,
    e.anios_salario - (SELECT anios_ult FROM ${hitos}) AS dif_vs_espana
FROM mother.vivienda_esfuerzo e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
LEFT JOIN mother.vivienda_esfuerzo a
  ON a.nivel = 'ccaa' AND a.cod = e.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
WHERE e.nivel = 'ccaa'
  AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND anios_salario IS NOT NULL)
ORDER BY e.anios_salario DESC
```

```sql ccaa_extremos
SELECT anio, nombre, anios_salario
FROM mother.vivienda_esfuerzo
WHERE anios_salario IS NOT NULL
  AND (nivel = 'pais' OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario DESC LIMIT 3) OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario ASC LIMIT 2))
ORDER BY anio, nombre
```

<div class="not-prose mb-4 flex flex-wrap items-center gap-2 text-xs font-semibold text-gray-500 dark:text-gray-400">
    <a href="/en/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Data Analysis</a>
    <span>·</span>
    <span class="rounded-full bg-amber-100 dark:bg-amber-950/60 px-2.5 py-0.5 text-amber-800 dark:text-amber-300">Housing & Wages</span>
    <span>·</span>
    <a href="/en/vivienda/esfuerzo" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">View permanent affordability dashboard →</a>
</div>

# 🏠 The gap between housing and wages: how many years of pay it takes to buy or rent

The debate over housing affordability in Spain often mixes nominal figures that ignore inflation with national averages that hide vast differences across regions. By combining the **appraised value of a standard 90 m² flat** (Ministry of Housing), the **median rent declared in income tax** (SERPAVI) and the **average annual gross salary** in each territory (INE Quarterly Labour Cost Survey), we can measure exactly how much wage effort housing requires today compared to the last two decades.

<Grid cols=4>
    <KpiCard
        title="Years of pay for 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} years"
        period="full gross salary in {hitos[0]?.anio_ult} · peak: {formatNumber(hitos[0]?.anios_max, 1)} in {hitos[0]?.anio_max}"
        direction="positive-down"
        source="MIVAU / INE"
        href="/en/vivienda/esfuerzo"
        sparklineData={espana.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Salary spent on rent"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="of average gross salary ({alquiler.slice(-1)[0]?.anio}) · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/month"
        direction="positive-down"
        source="SERPAVI / INE"
        href="/en/vivienda/alquiler"
        sparklineData={alquiler.map(d => ({...d, y: d.pct_alquiler}))}
    />
    <KpiCard
        title="Least affordable region"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} years"
        period="{ccaa[0]?.comunidad} ({ccaa[0]?.anio}) · vs. {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} in {ccaa.slice(-1)[0]?.comunidad}"
        direction="positive-down"
        source="MIVAU / INE"
        sparklineData={ccaa_extremos.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Average gross salary"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} €/year"
        period="Spain ({hitos[0]?.anio_ult}) · 90 m² flat: {formatNumber(hitos[0]?.precio_ult, 0)} €"
        direction="positive-up"
        source="INE (ETCL)"
        href="/en/economia/salarios"
        sparklineData={espana.map(d => ({...d, y: d.salario_anual_real}))}
    />
</Grid>

## 1. Three stages in two decades: bubble, correction and renewed pressure

Adjusting for inflation (constant {hitos[0]?.anio_base} euros) and setting {hitos[0]?.anio_ini} as base 100, the Spanish housing market has gone through three distinct stages:

1. **The bubble peak ({hitos[0]?.anio_max}):** buying a 90 m² home required **{formatNumber(hitos[0]?.anios_max, 1)} years** of full gross salary.
2. **Post-crisis correction ({hitos[0]?.anio_min}):** real price declines brought the effort down to a low of **{formatNumber(hitos[0]?.anios_min, 1)} years** of pay.
3. **The last decade ({hitos[0]?.anio_min}–{hitos[0]?.anio_ult}):** while real gross wages have remained largely stagnant ({formatNumber(hitos[0]?.var_salario_real, 1)} % cumulative change since {hitos[0]?.anio_ini}), real purchase and rental prices have risen again in major cities and tourist areas, placing the national average at **{formatNumber(hitos[0]?.anios_ult, 1)} years** of gross pay.

<LineChart
    data={indices}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Real index (base 100 = first year)"
    startingAtZero={false}
    title="Real evolution of the price of a 90 m² home vs. average gross salary (base 100)"
/>

<LineChart
    data={espana}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Years of gross salary"
    startingAtZero={false}
    title="Years of full gross salary needed to buy a 90 m² flat in Spain"
/>

## 2. The regional gap doubles between coastal/capital markets and inland Spain

The national average ({formatNumber(hitos[0]?.anios_ult, 1)} years) masks a more than two-fold gap across regions, even accounting for higher wages in Madrid, the Basque Country or Catalonia:

- In **{ccaa[0]?.comunidad}** ({formatNumber(ccaa[0]?.anios_salario, 1)} years), **{ccaa[1]?.comunidad}** ({formatNumber(ccaa[1]?.anios_salario, 1)} years) and **{ccaa[2]?.comunidad}** ({formatNumber(ccaa[2]?.anios_salario, 1)} years), buying an average 90 m² flat requires well over a decade of net pay.
- At the other end, in **{ccaa.slice(-1)[0]?.comunidad}** ({formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} years) and **{ccaa.slice(-2)[0]?.comunidad}** ({formatNumber(ccaa.slice(-2)[0]?.anios_salario, 1)} years), the required effort is less than half that of the tightest markets.

<LineChart
    data={ccaa_extremos}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Years of gross salary"
    startingAtZero={false}
    title="Evolution of buying effort: the 3 most expensive regions, the 2 most affordable and Spain"
/>

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="Years of gross salary"
    title="Years of local gross salary to buy a 90 m² home ({ccaa[0]?.anio})"
/>

## 3. Rent now absorbs a quarter of the median gross salary

For renters, the Ministry of Housing benchmark (actual contracts declared in personal income tax) shows that the median rent for a flat represents **{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %** of the national average gross salary ({formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/month), exceeding the 30 % threshold in the tightest regions when measured against net pay.

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of gross salary"
    startingAtZero={false}
    title="Share of average gross salary spent on median rent in Spain"
/>

## 4. Comparative table by autonomous community

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=anios_salario title="Years of pay (90 m²)" fmt='0.0' />
    <Column id=dif_vs_espana title="Vs. Spain avg. (years)" fmt='+0.0;-0.0;0.0' contentType=delta />
    <Column id=precio_90m2 title="90 m² flat (€)" fmt='#,##0' />
    <Column id=salario_anual title="Annual gross salary (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Rent / salary (%)" fmt='0.0"%"' />
    <Column id=alquiler_mes_mediana title="Median rent (€/mo)" fmt='#,##0' />
</DataTable>

---

**Methodology and sources:**
- **Purchase price:** Average appraised value of free-market housing ([Ministry of Housing and Urban Agenda](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)), multiplied by a standard 90 m² floor area (excluding transfer taxes and mortgage interest).
- **Rent:** Median monthly rent for multi-family housing from the State Reference System for Rental Prices ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) based on AEAT tax filings.
- **Wages:** Total gross annual wage cost per worker from the Quarterly Labour Cost Survey ([INE, table 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061)).
- **Further exploration:** See the permanent dashboards on [Housing](/en/vivienda), [Affordability by province](/en/vivienda/esfuerzo), [Public rental housing](/en/vivienda/vivienda-publica) and [Real wages](/en/economia/salarios).
