---
title: Society
description: "Crime, health, immigration, income and poverty, education and elections in Spain with official data, per inhabitant and compared with the EU."
i18n_origen: b5a51b86957e
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql crimen
SELECT anio, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
ORDER BY anio DESC
LIMIT 1
```

```sql crimen_serie
-- Tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018), en orden cronológico
WITH b AS (
    SELECT anio, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
),
l AS (
    SELECT anio, max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND tipologia = 'TOTAL INFRACCIONES PENALES'
    GROUP BY 1
)
SELECT anio, tasa_1000 AS valor FROM b
UNION ALL
SELECT anio, tasa_1000 AS valor FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY anio
```

```sql vida
SELECT CAST(anio AS INTEGER) AS anio, anios AS valor
FROM mother.salud_esperanza_vida
WHERE (nivel = 'pais' OR cod = '00') AND sexo = 'Ambos sexos'
ORDER BY anio
```

```sql nacionalizaciones
SELECT CAST(anio AS INTEGER) AS anio, nacionalizaciones, por_1000_extranjeros AS valor
FROM mother.inmigracion_nacionalizaciones
WHERE cod = '00' AND nacionalidad_previa = 'Total'
ORDER BY anio
```

```sql renta
SELECT CAST(anio AS INTEGER) AS anio, CAST(anio_renta AS INTEGER) AS anio_renta, renta_persona_real AS valor
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND renta_persona_real IS NOT NULL
ORDER BY anio
```

```sql abandono
SELECT CAST(anio AS INTEGER) AS anio, valor
FROM mother.educacion_indicadores
WHERE nivel = 'pais' AND indicador = 'abandono'
ORDER BY anio
```

```sql participacion
SELECT fecha, CAST(anio AS INTEGER) AS anio, participacion AS valor
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '02'
ORDER BY fecha
```

# 👥 Society

How we live in Spain: safety, health, the population arriving from abroad, income, education and voting, with the official figures and the context needed to read them properly.

<Grid cols=3>
    <KpiCard
        title="Recorded criminal offences"
        value={crimen[0]?.infracciones}
        formattedValue="{formatNumber(crimen[0]?.tasa_1000, 1)} per 1,000 inhabitants"
        period="{formatCompact(crimen[0]?.infracciones, 2)} in total · {crimen[0]?.anio}"
        source="Ministry of the Interior"
        href="/en/sociedad/criminalidad"
        sparklineData={crimen_serie}
    />
    <KpiCard
        title="Life expectancy at birth"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} years"
        period="in {vida.slice(-1)[0]?.anio}, one of the highest in the world"
        change={vida.length > 1 ? vida.slice(-1)[0]?.valor - vida.slice(-2)[0]?.valor : null}
        changeUnit="years"
        changePeriod="vs previous year"
        direction="positive-up"
        source="INE"
        href="/en/sociedad/salud"
        sparklineData={vida}
    />
    <KpiCard
        title="Acquisitions of Spanish nationality"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 1)} per 1,000 foreign nationals"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} residents acquired Spanish nationality in {nacionalizaciones.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="INE"
        href="/en/sociedad/inmigracion"
        sparklineData={nacionalizaciones}
    />
    <KpiCard
        title="Average income per person"
        value={renta.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renta.slice(-1)[0]?.valor, 0)} € a year"
        period="{renta.slice(-1)[0]?.anio_renta} income, adjusted for inflation"
        change={renta.length > 1 ? 100 * (renta.slice(-1)[0]?.valor / renta.slice(-2)[0]?.valor - 1) : null}
        changePeriod="real vs previous year"
        direction="positive-up"
        source="INE / ECV"
        href="/en/sociedad/desigualdad"
        sparklineData={renta}
    />
    <KpiCard
        title="Early school leaving"
        value={abandono.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(abandono.slice(-1)[0]?.valor, 1)} %"
        period="of 18 to 24-year-olds in {abandono.slice(-1)[0]?.anio} · in {abandono[0]?.anio} it was {formatNumber(abandono[0]?.valor, 1)} %"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/en/sociedad/educacion"
        sparklineData={abandono}
    />
    <KpiCard
        title="Turnout in general elections"
        value={participacion.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(participacion.slice(-1)[0]?.valor, 1)} %"
        period="of the electorate voted in {participacion.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Ministry of the Interior"
        href="/en/sociedad/elecciones"
        sparklineData={participacion}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/en/sociedad/criminalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-red-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚨</span> Crime</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Recorded offences by type, region, province and municipality since 2010, cybercrime and convictions by nationality, with context.</p>
    </a>
    <a href="/en/sociedad/salud" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🩺</span> Health</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Life expectancy, causes of death and excess mortality, and the health system: waiting lists, doctors, hospital beds and spending.</p>
    </a>
    <a href="/en/sociedad/inmigracion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🌍</span> Immigration</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Foreign population by region and origin, net migration, irregular arrivals, asylum and naturalisations.</p>
    </a>
    <a href="/en/sociedad/desigualdad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Income, poverty and inequality</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Household income adjusted for inflation, at-risk-of-poverty rate, AROPE, Gini and S80/S20 by region, age and municipality, and comparison with the EU.</p>
    </a>
    <a href="/en/sociedad/educacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-indigo-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🎓</span> Education</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Early school leaving, adult educational attainment, young people not in education, employment or training, spending per inhabitant and per pupil, vocational training and PISA, against the EU and by region.</p>
    </a>
    <a href="/en/sociedad/publico-privado" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-orange-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏥</span> Public and private</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">How much of public healthcare and education is delivered through private companies and schools: healthcare contracts, concession hospitals, insurance, state-funded private schools, vocational training and private universities.</p>
    </a>
    <a href="/en/sociedad/elecciones" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗳️</span> Elections</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">General elections since 1977, European and local elections: turnout, votes by party and bloc, fragmentation, votes per seat and the winner in each province and municipality.</p>
    </a>
</div>

<LastRefreshed prefix="Data updated" />
