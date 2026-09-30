---
title: Demography
description: "Spain's population from official INE data: growth, births and fertility, ageing, territorial distribution, men and women, and households, by autonomous community and province."
i18n_origen: 306ecbcd10ab
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql edades
SELECT CAST(anio AS INTEGER) AS anio, poblacion, pct_65, pct_80, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, tasa_natalidad, tasa_mortalidad,
    vegetativo_1000, fecundidad, crecimiento_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql poblacion_serie
SELECT anio, poblacion / 1e6 AS valor FROM ${edades}
```

```sql crecimiento_ultimo
SELECT anio, crecimiento_1000, vegetativo_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000,
    100.0 * resto / crecimiento AS pct_resto
FROM ${anual}
WHERE crecimiento IS NOT NULL
ORDER BY anio DESC
LIMIT 1
```

```sql primer_negativo
SELECT min(anio) AS anio FROM ${anual} WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👪 Demography

How many of us there are, how many are born and die, how much the population grows and why, how it is ageing and how it is spread across the country. All figures are official INE data and are given per inhabitant or as percentages so that years and territories can be compared.

<Grid cols=4>
    <KpiCard
        title="Population"
        value={edades.slice(-1)[0]?.poblacion}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.poblacion / 1e6, 2)} million"
        period="as at 1 January {edades.slice(-1)[0]?.anio}"
        change={100 * (edades.slice(-1)[0]?.poblacion / edades.slice(-2)[0]?.poblacion - 1)}
        changeUnit="%"
        changePeriod="in one year"
        direction="neutral"
        source="INE"
        href="/en/demografia/evolucion-poblacion"
        sparklineData={poblacion_serie}
    />
    <KpiCard
        title="Birth rate"
        value={anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.tasa_natalidad, 2)} per 1,000 inhab."
        period="{formatNumber(anual.slice(-1)[0]?.nacimientos, 0)} births in {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/en/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Children per woman"
        value={anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(anual.slice(-1)[0]?.fecundidad, 2)}
        period="total fertility rate, {anual.slice(-1)[0]?.anio} (replacement level is 2.1)"
        source="INE"
        href="/en/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Aged 65 and over"
        value={edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.pct_65, 1)}%"
        period="of the population · mean age {formatNumber(edades.slice(-1)[0]?.edad_media, 1)} years"
        source="INE"
        href="/en/demografia/estructura-edades"
        sparklineData={edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
</Grid>

## Where population growth comes from

The population changes in two ways: the difference between births and deaths (natural change) and the difference between people who come to live in Spain and those who leave (net migration).

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
ORDER BY anio
```

<BarChart
    data={componentes}
    x=anio
    y=por_1000
    series=componente
    type=stacked
    yFmt=num1
    xFmt="####"
    colorPalette={['#be185d', '#0f766e']}
    yAxisTitle="per 1,000 inhabitants"
    title="Annual population growth per 1,000 inhabitants and its components"
/>

<p class="text-xs text-gray-500">Growth = population on 1 January of the following year minus that of the current year, according to the Continuous Population Statistics. "Migración y ajustes" (migration and adjustments) is the part of growth not explained by births and deaths ("Nacimientos menos defunciones"). It matches almost exactly the net migration with other countries measured by the Migration Statistics since 2021: in {crecimiento_ultimo[0]?.anio}, {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} versus {formatNumber(crecimiento_ultimo[0]?.saldo_exterior_1000, 1)} per 1,000 inhabitants (see <a href="/en/sociedad/inmigracion">Immigration</a>).</p>

{#if crecimiento_ultimo[0]?.vegetativo_1000 < 0}

In {crecimiento_ultimo[0]?.anio} the population grew by {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} people per 1,000 inhabitants ({formatNumber(crecimiento_ultimo[0]?.crecimiento, 0)} in total). More people died than were born ({formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} per 1,000), as has happened every year since {primer_negativo[0]?.anio}, so all of the growth comes from migration.

{:else}

In {crecimiento_ultimo[0]?.anio} the population grew by {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} people per 1,000 inhabitants: {formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} from births minus deaths and {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} from migration and adjustments.

{/if}

## Explore

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/en/demografia/evolucion-poblacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📈</span> Population trends</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Population since 1971, annual growth per 1,000 inhabitants and how much births, deaths and migration contribute in each region.</p>
    </a>
    <a href="/en/demografia/natalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-pink-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">👶</span> Births and fertility</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Births and deaths per 1,000 inhabitants, children per woman, mothers' age and births to foreign mothers, by region and province.</p>
    </a>
    <a href="/en/demografia/estructura-edades" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-rose-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔺</span> Age and ageing</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Population pyramids for Spain, each region and each province; people over 65 and over 80, dependency and median age.</p>
    </a>
    <a href="/en/demografia/distribucion-territorial" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-emerald-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗺️</span> Territorial distribution</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Which provinces gain and lose population, the weight of each region and the percentage of foreign-born residents in each province.</p>
    </a>
    <a href="/en/demografia/poblacion-sexo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-purple-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Men and women</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Men per 100 women by age, over time and in each province.</p>
    </a>
    <a href="/en/demografia/hogares" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏠</span> Households</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Average household size and one-person households, by region and province.</p>
    </a>
</div>

---

## Sources and notes

- **[INE – Continuous Population Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177095)**: population on 1 January by province, age and sex (table 56945), by place of birth (56948) and nationality (56947), and households (60131 to 60134).
- **[INE – Vital Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: births (table 6524) and deaths (6561) by province of residence.
- **[INE – Basic Demographic Indicators](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: birth and death rates, fertility, mean age at motherhood and births to foreign mothers.
- **[INE – Migration and Change of Residence Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)**: net migration with other countries since 2021 (see [Immigration](/en/sociedad/inmigracion)).

<LastRefreshed prefix="Data updated" />
