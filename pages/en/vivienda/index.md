---
title: Housing
description: "House prices in Spain adjusted for inflation, rents, sales and mortgages per 1,000 inhabitants, new builds and how many years of salary a home costs, by region and province."
i18n_origen: a02abfec5da9
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql precio
SELECT fecha, periodo, euros_m2, euros_m2_real, precio_90m2_real, interanual_real, interanual_nominal, anio_base
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql precio_largo
SELECT fecha, 'Descontada la inflación' AS serie, euros_m2_real AS euros_m2 FROM mother.vivienda_precio_tasado WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
UNION ALL
SELECT fecha, 'Sin descontar (euros de cada año)' AS serie, euros_m2 FROM mother.vivienda_precio_tasado WHERE nivel = 'pais' AND anio >= 2002
ORDER BY fecha, serie
```

```sql resumen
SELECT * FROM mother.vivienda_resumen_territorios WHERE nivel = 'pais'
```

```sql alquiler
SELECT anio, alquiler_mes_mediana, alquiler_mes_mediana_real, variacion_real, anio_base
FROM mother.vivienda_alquiler
WHERE nivel = 'pais' AND tipologia = 'Colectiva'
ORDER BY anio
```

```sql mercado_mes
SELECT fecha, compraventas_12m, compraventas_12m_1000, hipotecas_12m_1000
FROM mother.vivienda_mercado_mensual
WHERE nivel = 'pais' AND compraventas_12m_1000 IS NOT NULL
ORDER BY fecha
```

```sql mercado_ultimo
SELECT
    u.fecha,
    strftime(u.fecha, '%m/%Y') AS mes_texto,
    u.compraventas_12m,
    u.compraventas_12m_1000,
    u.hipotecas_12m_1000,
    100 * (u.compraventas_12m_1000 / a.compraventas_12m_1000 - 1) AS var_anual
FROM mother.vivienda_mercado_mensual u
LEFT JOIN mother.vivienda_mercado_mensual a
  ON a.nivel = 'pais' AND a.fecha = u.fecha - INTERVAL 1 YEAR
WHERE u.nivel = 'pais' AND u.compraventas_12m_1000 IS NOT NULL
ORDER BY u.fecha DESC
LIMIT 1
```

```sql esfuerzo
SELECT anio, anios_salario, pct_alquiler, precio_90m2, salario_anual
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql mercado_anual
SELECT anio, 'Compraventas' AS operacion, compraventas_1000 AS por_1000 FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses = 12
UNION ALL
SELECT anio, 'Hipotecas sobre viviendas' AS operacion, hipotecas_1000 AS por_1000 FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses_hipotecas = 12
ORDER BY anio, operacion
```

```sql ccaa
SELECT cod, nombre AS comunidad, '/en' || ruta AS ruta, euros_m2_real, precio_interanual_real, precio_vs_maximo_real,
       alquiler_mes_mediana_real, compraventas_12m_1000, anios_salario
FROM mother.vivienda_resumen_territorios
WHERE nivel = 'ccaa'
ORDER BY euros_m2_real DESC
```

```sql hitos
SELECT
    max(euros_m2_real) AS max_real,
    arg_max(periodo, euros_m2_real) AS periodo_max,
    min(euros_m2_real) FILTER (WHERE anio >= 2008) AS min_real,
    arg_min(periodo, euros_m2_real) FILTER (WHERE anio >= 2008) AS periodo_min,
    100 * (arg_max(euros_m2_real, fecha) / max(euros_m2_real) - 1) AS vs_max,
    100 * (arg_max(euros_m2_real, fecha) / min(euros_m2_real) FILTER (WHERE anio >= 2008) - 1) AS vs_min
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
```

# 🏠 Housing

How much it costs to buy or rent a home in Spain, how many are sold and how many are built. Prices are shown **adjusted for inflation** (in {precio[0]?.anio_base} euros) and transactions **per 1,000 inhabitants**, so that years and areas can be compared.

<Grid cols=4>
    <KpiCard
        title="House price"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="appraised value, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} thousand € for a 90 m² flat"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real vs a year earlier"
        direction="neutral"
        source="Ministry of Housing"
        href="/en/vivienda/precios"
        sparklineData={precio.filter(d => d.euros_m2_real != null).map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Median rent for a flat"
        value={alquiler.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/month"
        period="leases declared in income tax returns, {alquiler.slice(-1)[0]?.anio}"
        change={alquiler.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real vs previous year"
        direction="neutral"
        source="Ministry of Housing (SERPAVI)"
        href="/en/vivienda/alquiler"
        sparklineData={alquiler.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Home sales"
        value={mercado_ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(mercado_ultimo[0]?.compraventas_12m_1000, 1)} per 1,000 inhab."
        period="12 months to {mercado_ultimo[0]?.mes_texto} · {formatCompact(mercado_ultimo[0]?.compraventas_12m, 0)} in total"
        change={mercado_ultimo[0]?.var_anual?.toFixed(1)}
        changePeriod="vs a year earlier"
        direction="neutral"
        source="INE / ETDP"
        href="/en/vivienda/compraventas"
        sparklineData={mercado_mes.map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Years of salary for 90 m²"
        value={esfuerzo.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.anios_salario, 1)} years"
        period="average gross salary, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministry of Housing / INE"
        href="/en/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.anios_salario)}
    />
</Grid>

## Prices, with and without inflation

Average appraised value of open-market housing in euros per square metre. Adjusted for inflation, the series peaked in {hitos[0]?.periodo_max} and bottomed out after the crisis in {hitos[0]?.periodo_min}. Today the square metre is {#if hitos[0]?.vs_max < 0}{formatNumber(-hitos[0]?.vs_max, 0)} % below that peak{:else}at a record high{/if} and {formatNumber(hitos[0]?.vs_min, 0)} % above the low.

<LineChart
    data={precio_largo}
    x=fecha
    y=euros_m2
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€/m²"
    startingAtZero={false}
    title="Appraised value of open-market housing in Spain: {precio[0]?.anio_base} euros versus euros of each year"
/>

## How many are bought and how many are mortgaged

Home sales registered in the property registries and mortgages taken out on homes, per 1,000 inhabitants per year.

<BarChart
    data={mercado_anual}
    x=anio
    y=por_1000
    series=operacion
    type=grouped
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1,000 inhabitants"
    title="Home sales and mortgages per 1,000 inhabitants"
/>

## By region

Real price per square metre in the latest quarter. Click on a region to see its profile.

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="euros_m2_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing, INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Real annual change (%)', fmt: '0.0'},
        {id: 'alquiler_mes_mediana_real', title: 'Median rent (€/month)', fmt: '#,##0'},
        {id: 'anios_salario', title: 'Years of salary (90 m²)', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Real annual chg. %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Vs. real peak %" fmt='0.0' />
    <Column id=alquiler_mes_mediana_real title="Rent €/month" fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Sales per 1,000 inhab." fmt='0.0' />
    <Column id=anios_salario title="Years of salary" fmt='0.0' />
</DataTable>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/en/vivienda/precios" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Prices</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Appraised value by region, province and municipality and the INE House Price Index, new and second-hand, adjusted for inflation.</p>
    </a>
    <a href="/en/vivienda/alquiler" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔑</span> Rent</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Median rent by region, province and municipality from income tax data, and how many homes are rented out.</p>
    </a>
    <a href="/en/vivienda/compraventas" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📝</span> Sales and mortgages</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Homes sold and mortgaged per 1,000 inhabitants, new builds versus second-hand and average mortgage amount.</p>
    </a>
    <a href="/en/vivienda/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏗️</span> New builds</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Open-market homes started and completed each year per 1,000 inhabitants, since 1991.</p>
    </a>
    <a href="/en/vivienda/esfuerzo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Affordability</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">How many years of salary a home costs and what share of pay goes on rent, by region.</p>
    </a>
    <a href="/en/vivienda/vivienda-publica" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏘️</span> Public rental housing</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Public rental homes per 1,000 inhabitants by region, province and municipality, compared with the Netherlands, Austria, France and the European average, and by party.</p>
    </a>
</div>

---

**Sources:** [Ministry of Housing and Urban Agenda, statistical bulletin](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (appraised value and new builds), [State Rental Price Reference System (SERPAVI)](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi), [INE, Property Rights Transfer Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=6150), [INE, Mortgage Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) and [INE, Quarterly Labour Cost Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflated with the INE general CPI (base 2025).
