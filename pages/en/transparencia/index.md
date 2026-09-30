---
title: Transparency
description: "How Spanish public administrations are held to account: councils' reporting obligations, decree-laws, pardons, rolled-over budgets and Spain's position in international integrity indices, by government and by party."
i18n_origen: 9ea4661f7e55
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

# <span aria-hidden="true">🔍</span> Transparency and accountability

A democracy can also be measured by how it is held to account: whether public administrations publish
what they must, whether the Government legislates through the ordinary procedure or by decree, how it
uses the prerogative of mercy and how international integrity indices see Spain. Each subsection
attributes the data to the party in power and compares it with the time each one has spent in office.

```sql actos
SELECT anio, rdl, leyes, pct_rdl, indultos, presidente, familia
FROM mother.gobierno_actos_anual
WHERE NOT anio_en_curso
ORDER BY anio
```

```sql actos_ult
SELECT * FROM ${actos} ORDER BY anio DESC LIMIT 1
```

```sql cpi
SELECT anio, valor, puesto_ue, n_ue
FROM mother.transparencia_internacional
WHERE indicador_id = 'cpi' AND cod_pais = 'ESP'
ORDER BY anio
```

```sql cpi_ult
SELECT * FROM ${cpi} ORDER BY anio DESC LIMIT 1
```

```sql liquidaciones
SELECT CAST(year(periodo) AS INTEGER) AS anio, valor
FROM mother.metricas
WHERE metrica_id = 'transparencia_liquidaciones_sin_remitir'
ORDER BY periodo
```

```sql liquidaciones_ult
SELECT * FROM ${liquidaciones} ORDER BY anio DESC LIMIT 1
```

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if actos_ult.length}
    <KpiCard
        title="Decree-laws"
        value={actos_ult[0].rdl}
        formattedValue={formatNumber(actos_ult[0].rdl, 0)}
        unit="in the year"
        period={`${actos_ult[0].anio} · ${formatNumber(actos_ult[0].pct_rdl, 0)}% of laws and law-ranking rules`}
        source="BOE"
        direction="positive-down"
        href="/en/transparencia/decretos-ley"
        sparklineData={actos.map(d => d.rdl)}
    />
    <KpiCard
        title="Pardons"
        value={actos_ult[0].indultos}
        formattedValue={formatNumber(actos_ult[0].indultos, 0)}
        unit="decrees"
        period={`${actos_ult[0].anio}`}
        source="BOE"
        direction="neutral"
        href="/en/transparencia/indultos"
        sparklineData={actos.map(d => d.indultos)}
    />
    {/if}
    {#if cpi_ult.length}
    <KpiCard
        title="Perceived corruption"
        value={cpi_ult[0].valor}
        formattedValue={formatNumber(cpi_ult[0].valor, 0)}
        unit="out of 100"
        period={`${cpi_ult[0].anio} · ranked ${cpi_ult[0].puesto_ue} of ${cpi_ult[0].n_ue} in the EU`}
        source="Transparency International"
        direction="positive-up"
        href="/en/transparencia/comparacion-internacional"
        sparklineData={cpi.map(d => d.valor)}
    />
    {/if}
    {#if liquidaciones_ult.length}
    <KpiCard
        title="Councils without budget outturn"
        value={liquidaciones_ult[0].valor}
        formattedValue={formatNumber(liquidaciones_ult[0].valor, 0)}
        unit="did not submit it"
        period={`${liquidaciones_ult[0].anio} budget`}
        source="Ministry of Finance"
        direction="positive-down"
        href="/en/transparencia/cuentas-municipales"
        sparklineData={liquidaciones.map(d => d.valor)}
    />
    {/if}
</div>

## Subsections

<Grid cols=2>
    <a href="/en/transparencia/cuentas-municipales" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🏛️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Council accounts reporting</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Which councils fail to send the Ministry of Finance their budget outturn, General Account or average payment period, where they are and who was in power when the deadline expired.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">See the councils →</span>
    </a>
    <a href="/en/transparencia/decretos-ley" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📜</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Decree-laws</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">How many royal decree-laws each government has passed since 1977, what share of law-ranking rules are made by decree and how many Congress rejects.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">See the decree-laws →</span>
    </a>
    <a href="/en/transparencia/indultos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">⚖️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Pardons</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">How many pardons each government grants according to the BOE, how they have changed over time and how each prime minister and each party compares.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">See the pardons →</span>
    </a>
    <a href="/en/transparencia/presupuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📅</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Rolled-over budgets</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">In which years the State started without an approved General State Budget, how many days the rollover lasted and which government was due to present it.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">See the budgets →</span>
    </a>
    <a href="/en/transparencia/comparacion-internacional" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🌍</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Spain compared with other countries</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Corruption perception, governance, rule of law and open government indices: where Spain stands relative to the EU and the OECD and how this has changed under each government.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">See the comparison →</span>
    </a>
</Grid>

## What else could be measured

There are other parts of accountability with public data that are not here yet because their sources
are not published in reusable formats or require much more work: the rulings of the Council of
Transparency and Good Governance (only in HTML and PDF listings), public procurement (thousands of XML
files from the Public Sector Procurement Platform) and directly awarded grants (National Grants
Database). Spain's open data sources are listed in
[Open data in Spain](/en/varios/datos-abiertos).
