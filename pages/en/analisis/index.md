---
title: Data Analysis & Investigative Reports
description: "Data investigations and deep-dive reports on Spain from official sources: housing and wages, landlord MPs, fleet tax havens, decree-laws, public-private services and the renewable transition."
i18n_origen: 39f9545ba89f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql caseros_kpi
SELECT
    max(pct) FILTER (WHERE definicion_id = 'alquila') AS pct_alquila,
    max(n_cumplen) FILTER (WHERE definicion_id = 'alquila') AS n_alquila,
    max(pct) FILTER (WHERE definicion_id = 'dos_viviendas') AS pct_dos_viviendas
FROM mother.diputados_inmuebles_resumen
```

```sql esfuerzo_kpi
SELECT anio, anios_salario, pct_alquiler
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql renovables_kpi
SELECT anio, cuota_renovable_pct AS valor
FROM mother.energia_resumen_anual_mix
ORDER BY anio
```

```sql decretos_kpi
SELECT anio, rdl, leyes, pct_rdl
FROM mother.gobierno_actos_anual
WHERE NOT anio_en_curso
ORDER BY anio
```

# 📰 Data analysis & investigative reports

While SpainFacts' core topic hubs keep Spain's structural series permanently visible, this section brings together **in-depth investigations and cross-dataset analyses** on specific questions in the public debate. Every piece follows the same standard: documented official sources, figures adjusted for population and inflation, and context without partisan spin.

<Grid cols=4>
    <KpiCard
        title="MPs declaring rental income"
        value={caseros_kpi[0]?.pct_alquila}
        formattedValue="{formatNumber(caseros_kpi[0]?.pct_alquila, 1)}%"
        period="{formatNumber(caseros_kpi[0]?.n_alquila, 0)} MPs · {formatNumber(caseros_kpi[0]?.pct_dos_viviendas, 1)}% own 2+ homes"
        source="Congress / AEAT"
        href="/en/varios/diputados-caseros"
    />
    <KpiCard
        title="Housing affordability effort"
        value={esfuerzo_kpi.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo_kpi.slice(-1)[0]?.anios_salario, 1)} years"
        period="of gross annual salary for 90 m² ({esfuerzo_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/en/analisis/brecha-vivienda-salarios"
        sparklineData={esfuerzo_kpi.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Renewable electricity share"
        value={renovables_kpi.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renovables_kpi.slice(-1)[0]?.valor, 1)}%"
        period="of annual power mix in {renovables_kpi.slice(-1)[0]?.anio} (up from {formatNumber(renovables_kpi[0]?.valor, 1)}% in {renovables_kpi[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/en/analisis/revolucion-renovable"
        sparklineData={renovables_kpi}
    />
    <KpiCard
        title="Laws passed by decree-law"
        value={decretos_kpi.slice(-1)[0]?.pct_rdl}
        formattedValue="{formatNumber(decretos_kpi.slice(-1)[0]?.pct_rdl, 0)}%"
        period="{formatNumber(decretos_kpi.slice(-1)[0]?.rdl, 0)} royal decree-laws in {decretos_kpi.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="BOE"
        href="/en/transparencia/decretos-ley"
        sparklineData={decretos_kpi.map(d => ({...d, y: d.pct_rdl}))}
    />
</Grid>

## Featured · New deep dives

<div class="not-prose grid grid-cols-1 lg:grid-cols-2 gap-6 my-6">
    <a href="/en/analisis/brecha-vivienda-salarios" class="group flex flex-col justify-between rounded-2xl border border-amber-200 dark:border-amber-800/80 bg-gradient-to-br from-amber-50/70 via-white to-white dark:from-amber-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-amber-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
                <span>🔑 Housing & wages</span>
                <span>·</span>
                <span>Data special</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-amber-700 dark:group-hover:text-amber-400">
                The housing gap: how many years of salary it takes to buy or rent a home
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Comparing real wage growth against appraised house prices per square metre and median IRPF rents across Spain's 17 regions.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-amber-700 dark:text-amber-400">
            Read the full analysis →
        </span>
    </a>

    <a href="/en/analisis/revolucion-renovable" class="group flex flex-col justify-between rounded-2xl border border-emerald-200 dark:border-emerald-800/80 bg-gradient-to-br from-emerald-50/70 via-white to-white dark:from-emerald-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-emerald-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                <span>☀️ Energy & climate</span>
                <span>·</span>
                <span>Data special</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-400">
                The great power shift: how solar and wind displaced coal in Spain
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                In fifteen years Spain phased out nearly all coal power and multiplied solar and wind generation, slashing grid emissions—while transport now accounts for nearly a third of all national CO₂.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-emerald-700 dark:text-emerald-400">
            Read the full analysis →
        </span>
    </a>
</div>

## Investigations on institutions, taxes and public services

<div class="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 my-6">
    <a href="/en/varios/diputados-caseros" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-blue-50 dark:bg-blue-950/60 px-2.5 py-0.5 text-xs font-semibold text-blue-700 dark:text-blue-300">Congress & tax data</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏘️ How many MPs are landlords?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Asset and income declarations of all 350 MPs broken down by party and compared with income-tax brackets.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/movilidad/flotas-e-impuestos" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-teal-50 dark:bg-teal-950/60 px-2.5 py-0.5 text-xs font-semibold text-teal-700 dark:text-teal-300">Local taxation · DGT</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏝️ The municipal tax havens for car fleets</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Why villages of fewer than 500 residents register tens of thousands of rental and company cars thanks to road-tax cuts.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/sociedad/publico-privado" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-purple-50 dark:bg-purple-950/60 px-2.5 py-0.5 text-xs font-semibold text-purple-700 dark:text-purple-300">Healthcare & education</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏥 Public and private in public services</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Healthcare outsourcing, private health insurance, state-subsidised private schools, vocational training and private universities.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/transparencia/decretos-ley" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 text-xs font-semibold text-indigo-700 dark:text-indigo-300">Executive power · BOE</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📜 Ruling by decree since 1977</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                How many royal decree-laws each Prime Minister passes per year in office and their share of total primary legislation.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/medios/dinero-publico" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-rose-50 dark:bg-rose-950/60 px-2.5 py-0.5 text-xs font-semibold text-rose-700 dark:text-rose-300">Media & public money</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📢 Institutional advertising and the media</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                How much central and regional governments spend on institutional advertising campaigns and how it is distributed.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/varios/observatorios" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-xs font-semibold text-slate-700 dark:text-slate-300">Public administration</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🔭 Census of public observatories</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                How many public observatories exist in Spain, which administration created them and how many remain active.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/transparencia/contratacion" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-amber-50 dark:bg-amber-950/60 px-2.5 py-0.5 text-xs font-semibold text-amber-700 dark:text-amber-300">Procurement · OIReScon</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📑 Public tenders, single bidders & minor contracts</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Over 9% of GDP flows through public procurement: how much is awarded without prior publication or with a single bid.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/transparencia/subvenciones" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-300">Subsidies · BDNS</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">💶 Public subsidies: competitive vs direct grants</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                How public grants are split between central, regional and local governments and what share is awarded directly.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>

    <a href="/en/vivienda/vivienda-publica" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-cyan-50 dark:bg-cyan-950/60 px-2.5 py-0.5 text-xs font-semibold text-cyan-700 dark:text-cyan-300">European comparison</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏗️ Why does Spain have so little social rental housing?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                How Spain built hundreds of thousands of subsidised homes for sale while leaving its public rental stock among the lowest in Europe.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Read investigation →</span>
    </a>
</div>

---

## Looking for permanent topic series?

SpainFacts' core topic hubs are always accessible in the top navigation bar: [Regions](/en/territorios), [Population](/en/demografia), [Economy](/en/economia), [Housing](/en/vivienda), [Public Finances](/en/cuentas-publicas), [Energy & Climate](/en/energia-clima), [Mobility](/en/movilidad), [Society](/en/sociedad), [Media](/en/medios) and [Transparency](/en/transparencia), or ask any open question in [Ask the data](/en/chat).
