---
title: Economy
description: "GDP per inhabitant, growth, foreign trade, sectors, employment, wages, unemployment and inflation in Spain, adjusted for inflation and in proportion to population."
i18n_origen: a21903b3070d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql pib_hab
SELECT anio, real_eur AS valor, 100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql pib_trim
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, interanual, anio_euros
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql exportaciones
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, pct_pib
FROM mother.economia_pib_trimestral
WHERE componente = 'P6'
ORDER BY trimestre
```

```sql salario
SELECT anio, salario_real, crecimiento_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql empleo
SELECT anio, ocupados_1000_hab, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql serie_paro
SELECT periodo, valor AS paro, strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo
```

```sql serie_ipc
SELECT periodo, valor AS ipc, strftime(periodo, '%Y-%m') AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo
```

```sql sectores_crec
SELECT
    s.sector,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crecimiento,
    s.anio
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
  AND s.rama <> 'TOTAL' AND NOT s.es_subrama
ORDER BY crecimiento DESC
```

# 📊 Economy

How the Spanish economy is changing. In line with the approach used across the whole site, anything that depends on the size of the country is shown **per inhabitant**, and anything measured in euros is shown **adjusted for inflation** (in {pib_trim[0]?.anio_euros} euros).

<Grid cols=3>
    <KpiCard
        title="GDP per inhabitant"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="in {pib_hab.slice(-1)[0]?.anio}, in {pib_trim[0]?.anio_euros} euros"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real, vs previous year"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab.map(d => d.valor)}
        href="/en/economia/pib"
    />
    <KpiCard
        title="GDP growth"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)}%"
        period="real year-on-year, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => d.interanual)}
        href="/en/economia/pib"
    />
    <KpiCard
        title="Exports"
        value={exportaciones.slice(-1)[0]?.pct_pib}
        formattedValue="{formatNumber(exportaciones.slice(-1)[0]?.pct_pib, 1)}% of GDP"
        period="goods and services, {exportaciones.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={exportaciones.slice(-40).map(d => d.pct_pib)}
        href="/en/economia/comercio-exterior"
    />
    <KpiCard
        title="Average wage"
        value={salario.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(salario.slice(-1)[0]?.salario_real, 0)} €/month"
        period="gross in {salario.slice(-1)[0]?.anio}, adjusted for inflation"
        change={salario.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real, vs previous year"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={salario.map(d => d.salario_real)}
        href="/en/economia/salarios"
    />
    <KpiCard
        title="Unemployment rate"
        value={serie_paro.slice(-1)[0]?.paro}
        formattedValue="{formatNumber(serie_paro.slice(-1)[0]?.paro, 1)}%"
        period={serie_paro.slice(-1)[0]?.periodo_txt}
        change={serie_paro.length > 1 ? (serie_paro.slice(-1)[0]?.paro - serie_paro.slice(-2)[0]?.paro).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs previous quarter"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={serie_paro.slice(-40).map(d => d.paro)}
        href="/en/economia/paro"
    />
    <KpiCard
        title="Inflation"
        value={serie_ipc.slice(-1)[0]?.ipc}
        formattedValue="{formatNumber(serie_ipc.slice(-1)[0]?.ipc, 1)}%"
        period="CPI year-on-year, {serie_ipc.slice(-1)[0]?.periodo_txt}"
        change={serie_ipc.length > 1 ? (serie_ipc.slice(-1)[0]?.ipc - serie_ipc.slice(-2)[0]?.ipc).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs previous month"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={serie_ipc.slice(-36).map(d => d.ipc)}
        href="/en/economia/ipc"
    />
</Grid>

## GDP per inhabitant

What the economy produces for each inhabitant, in constant euros. [Quarterly growth, demand and comparison with Europe →](/en/economia/pib)

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per inhabitant (real)"
    startingAtZero={false}
    title="GDP per inhabitant in {pib_trim[0]?.anio_euros} euros"
/>

## Sectors

Real growth in the value added of each major sector since 2019. [Employment, weight and productivity by sector →](/en/economia/sectores)

<BarChart
    data={sectores_crec}
    x=sector
    y=crecimiento
    swapXY=true
    yFmt='0.0"%"'
    title="Real growth in value added between 2019 and {sectores_crec[0]?.anio} (%)"
/>

## Employment

People in work per 1,000 inhabitants: it rises when jobs are created faster than the population grows. [Unemployment rate →](/en/economia/paro)

<LineChart
    data={empleo}
    x=anio
    y=ocupados_1000_hab
    xFmt='0'
    yAxisTitle="Employed per 1,000 inhab."
    startingAtZero={false}
    title="Employed people per 1,000 inhabitants"
/>

## Wages

Average gross monthly wage adjusted for inflation. [Growth, sectors and deciles →](/en/economia/salarios)

<LineChart
    data={salario}
    x=anio
    y=salario_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per month (real)"
    startingAtZero={false}
    title="Average monthly wage in {pib_trim[0]?.anio_euros} euros"
/>

## Unemployment and inflation

<Grid cols=2>
<LineChart
    data={serie_paro}
    x=periodo
    y=paro
    yAxisTitle="% of the labour force"
    title="Unemployment rate (EPA, Labour Force Survey)"
    startingAtZero={false}
/>
<LineChart
    data={serie_ipc}
    x=periodo
    y=ipc
    yAxisTitle="% year-on-year"
    title="Inflation (CPI, annual change)"
    startingAtZero={false}
/>
</Grid>

<Grid cols=3>
    <a href="/en/economia/comercio-exterior" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🚢</span> Foreign trade</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Exports, imports and external balance as a share of GDP</div>
    </a>
    <a href="/en/economia/paro" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">👷</span> Unemployment</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Historical series from the EPA (Labour Force Survey)</div>
    </a>
    <a href="/en/economia/ipc" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🛒</span> Inflation</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Consumer price index and energy prices</div>
    </a>
    <a href="/en/economia/turismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏖️</span> Tourism</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Tourists per inhabitant, their real spending and as a % of GDP, hotels and tourist flats</div>
    </a>
    <a href="/en/economia/empresas" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏢</span> Businesses, entrepreneurship and R&D</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Businesses per inhabitant and by size, companies created and dissolved, insolvencies, self-employed workers and R&D spending compared with Europe</div>
    </a>
</Grid>

---

**Sources:** Eurostat (national accounts: [namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table), [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table)) and INE ([EPA, Labour Force Survey](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918), [CPI](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [Quarterly Labour Cost Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=6038)).
