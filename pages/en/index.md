---
title: SpainFacts · The State of Spain in Official Data
description: "Spain in official data: population, economy, public finances, energy, mobility, society and transparency, from the whole country down to each municipality. Independent and politically neutral."
i18n_origen: 55bec392edfc
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorInicio from '../../../../../src/lib/components/BuscadorInicio.svelte';
    import Chat from '../../../../../src/lib/components/Chat.svelte';
</script>

```sql lista_municipios
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion
FROM mother.poblacion_municipios m
JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
```

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'pais' AND sexo = 'Total' AND anio >= 2000
ORDER BY anio
```

```sql metricas
SELECT metrica_id, periodo, valor
FROM mother.metricas
WHERE metrica_id IN ('tasa_paro', 'ipc_variacion_anual', 'deuda_publica_pib')
ORDER BY periodo
```

```sql ultimas_metricas
SELECT
    metrica_id,
    arg_max(valor, periodo) AS valor,
    arg_max(periodo, periodo) AS periodo,
    CASE WHEN metrica_id = 'ipc_variacion_anual' THEN strftime(max(periodo), '%m/%Y')
         ELSE CAST(CAST(year(max(periodo)) AS INTEGER) AS VARCHAR) || '-T' || CAST(CAST(quarter(max(periodo)) AS INTEGER) AS VARCHAR) END AS periodo_txt
FROM ${metricas}
GROUP BY metrica_id
```

```sql renovables_mes
SELECT
    date_trunc('month', fecha) AS mes,
    sum(renovable_mwh) / sum(generacion_total_mwh) AS valor
FROM mother.electricidad_diaria
WHERE fecha < date_trunc('month', (SELECT max(fecha) FROM mother.electricidad_diaria))
GROUP BY 1
ORDER BY 1
```

```sql renovables_30
SELECT sum(renovable_mwh) / sum(generacion_total_mwh) AS cuota
FROM mother.electricidad_diaria
WHERE fecha > (SELECT max(fecha) FROM mother.electricidad_diaria) - INTERVAL 30 DAY
```

```sql embalses
SELECT fecha, pct_llenado AS valor
FROM mother.embalses_semanal
WHERE nivel = 'pais' AND fecha >= (SELECT max(fecha) FROM mother.embalses_semanal WHERE nivel = 'pais') - INTERVAL 3 YEAR
ORDER BY fecha
```

```sql embalses_hoy
SELECT pct_llenado, dif_vs_media_10_anios, strftime(fecha, '%d/%m/%Y') AS fecha_txt
FROM mother.embalses_estado_actual
WHERE nivel = 'pais'
```

```sql enchufables
SELECT
    mes,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS valor
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N' AND mes >= (SELECT max(mes) FROM mother.movilidad_matriculaciones_mensual) - INTERVAL 36 MONTH
GROUP BY mes
ORDER BY mes
```

```sql vida
SELECT anio, anios AS valor
FROM mother.salud_esperanza_vida
WHERE nivel = 'pais' AND sexo = 'Ambos sexos' AND anio >= 2000
ORDER BY anio
```

<div class="not-prose rounded-3xl bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 text-white px-6 py-10 md:px-12 md:py-14 mb-10 shadow-xl border border-slate-800">
    <div class="max-w-3xl">
        <p class="inline-flex items-center gap-2 rounded-full border border-blue-400/30 bg-blue-500/15 px-3 py-1 text-xs font-semibold text-blue-200 mb-5">
            <span class="h-2 w-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Official data · independent · politically neutral
        </p>
        <h1 class="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight mb-4">
            Spain, <span class="text-blue-300">in data</span>.<br class="hidden sm:inline"/> From the whole country to your municipality.
        </h1>
        <p class="text-base md:text-lg text-slate-300 leading-relaxed mb-7">
            How many of us there are, what public money is spent on, how electricity is produced, which cars we buy, how long we live and which public administrations fail to meet their obligations: figures from official bodies, updated every day and explained in context.
        </p>
        <BuscadorInicio opciones={lista_municipios} />
        <div class="mt-5 flex flex-wrap gap-2 text-sm">
            <a href="/en/territorios" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🗺️</span> Regions</a>
            <a href="/en/energia-clima/directo" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">⚡</span> Electricity now</a>
            <a href="/en/movilidad/marcas-y-modelos" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🚗</span> Best-selling cars</a>
            <a href="/en/transparencia" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🔎</span> Transparency</a>
        </div>
    </div>
</div>

## Ask the data

Type a question and an AI model running in your browser will look for the answer among the site’s tables. [More about the chat and how to use it with Claude or Ollama](/en/chat).

<Chat perezoso />

## Spain today

<Grid cols=4>
    <KpiCard
        title="Population"
        value={poblacion.slice(-1)[0]?.valor}
        formattedValue={formatCompact(poblacion.slice(-1)[0]?.valor, 2)}
        unit="people"
        period="1 January {poblacion.slice(-1)[0]?.anio}"
        change={poblacion.slice(-2)[1]?.valor && poblacion.slice(-2)[0]?.valor ? (100 * (poblacion.slice(-2)[1].valor / poblacion.slice(-2)[0].valor - 1)).toFixed(1) : null}
        changeUnit="%"
        changePeriod="in one year"
        direction="neutral"
        source="INE"
        href="/en/demografia"
        sparklineData={poblacion}
    />
    <KpiCard
        title="Unemployment rate"
        value={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.periodo_txt}
        source="INE (EPA)"
        href="/en/economia/paro"
        sparklineData={metricas.filter(d => d.metrica_id === 'tasa_paro')}
    />
    <KpiCard
        title="Inflation"
        value={ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor, 1)} %"
        period="Annual CPI · {ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.periodo_txt}"
        source="INE"
        href="/en/economia/ipc"
        sparklineData={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-60)}
    />
    <KpiCard
        title="Public debt"
        value={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor, 1)} % of GDP"
        period={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.periodo_txt}
        source="Eurostat / BdE"
        href="/en/cuentas-publicas"
        sparklineData={metricas.filter(d => d.metrica_id === 'deuda_publica_pib')}
    />
    <KpiCard
        title="Renewable electricity"
        value={renovables_30[0]?.cuota}
        formattedValue="{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %"
        period="of generation in the last 30 days"
        source="REE"
        href="/en/energia-clima/mix-electrico"
        sparklineData={renovables_mes.slice(-36)}
    />
    <KpiCard
        title="Reservoir water reserves"
        value={embalses_hoy[0]?.pct_llenado}
        formattedValue="{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %"
        period="{embalses_hoy[0]?.fecha_txt} · {embalses_hoy[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(embalses_hoy[0]?.dif_vs_media_10_anios, 1)} pp vs. 10-year average"
        source="MITECO"
        href="/en/energia-clima/embalses"
        sparklineData={embalses}
    />
    <KpiCard
        title="New plug-in cars"
        value={enchufables.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %"
        period="electric + plug-in hybrid · last month"
        source="DGT"
        href="/en/movilidad/coche-electrico"
        sparklineData={enchufables}
    />
    <KpiCard
        title="Life expectancy"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} years"
        period="at birth · {vida.slice(-1)[0]?.anio}"
        source="INE / Eurostat"
        href="/en/sociedad/salud"
        sparklineData={vida}
    />
</Grid>

## Compare the regions

```sql mapa_ccaa
WITH ccaa AS (
    SELECT cod, nombre, ruta FROM mother.territorios WHERE nivel = 'ccaa'
),
crimen AS (
    SELECT cod, tasa_1000 AS valor FROM mother.crimen_balance
    WHERE nivel = 'ccaa' AND categoria = 'Total infracciones penales' AND anio = (SELECT max(anio) FROM mother.crimen_balance)
),
vida AS (
    SELECT cod, anios AS valor FROM mother.salud_esperanza_vida
    WHERE nivel = 'ccaa' AND sexo = 'Ambos sexos' AND anio = (SELECT max(anio) FROM mother.salud_esperanza_vida WHERE nivel = 'ccaa')
),
empleo AS (
    SELECT cod, por_1000_hab AS valor FROM mother.empleo_territorio
    WHERE nivel = 'ccaa' AND administracion = 'Total' AND fecha = (SELECT max(fecha) FROM mother.empleo_territorio)
),
deuda AS (
    SELECT cod_ccaa AS cod, deuda_pct_pib AS valor FROM mother.ccaa_deuda WHERE fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
),
enchufables AS (
    SELECT cod_ccaa AS cod,
        100.0 * sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS valor
    FROM mother.movilidad_matriculaciones_provincia
    WHERE nuevo_usado = 'N' AND mes > (SELECT max(mes) FROM mother.movilidad_matriculaciones_provincia) - INTERVAL 12 MONTH
    GROUP BY cod_ccaa
),
crecimiento AS (
    SELECT a.cod, 100.0 * (a.poblacion / b.poblacion - 1) AS valor
    FROM mother.poblacion_territorios a
    JOIN mother.poblacion_territorios b ON b.nivel = a.nivel AND b.cod = a.cod AND b.sexo = a.sexo AND b.anio = a.anio - 10
    WHERE a.nivel = 'ccaa' AND a.sexo = 'Total' AND a.anio = (SELECT max(anio) FROM mother.poblacion_territorios)
)
SELECT c.cod, c.nombre, '/en' || c.ruta AS ruta, x.valor
FROM ccaa c
LEFT JOIN (
    SELECT 'crimen' AS indicador, * FROM crimen
    UNION ALL SELECT 'vida', * FROM vida
    UNION ALL SELECT 'empleo', * FROM empleo
    UNION ALL SELECT 'deuda', * FROM deuda
    UNION ALL SELECT 'enchufables', * FROM enchufables
    UNION ALL SELECT 'crecimiento', * FROM crecimiento
) x ON x.cod = c.cod AND x.indicador = '${inputs.indicador_mapa}'
```

<ButtonGroup name=indicador_mapa>
    <ButtonGroupItem valueLabel="Population growth" value="crecimiento" default />
    <ButtonGroupItem valueLabel="Life expectancy" value="vida" />
    <ButtonGroupItem valueLabel="Crime" value="crimen" />
    <ButtonGroupItem valueLabel="Public employees" value="empleo" />
    <ButtonGroupItem valueLabel="Plug-in cars" value="enchufables" />
    <ButtonGroupItem valueLabel="Debt" value="deuda" />
</ButtonGroup>

<MapaEspana
    data={mapa_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="valor"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'valor', title: 'Value', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">
{#if inputs.indicador_mapa === 'crecimiento'}Population growth over the last 10 years (%), INE municipal register.{/if}
{#if inputs.indicador_mapa === 'vida'}Life expectancy at birth (years), INE.{/if}
{#if inputs.indicador_mapa === 'crimen'}Recorded criminal offences per 1,000 inhabitants in the last year, Ministry of the Interior. Tourist regions score higher because visitors are not counted in the denominator.{/if}
{#if inputs.indicador_mapa === 'empleo'}Employees of the three tiers of government working in the region per 1,000 inhabitants, Central Personnel Register.{/if}
{#if inputs.indicador_mapa === 'enchufables'}Share of battery electric and plug-in hybrid cars among new passenger cars over the last 12 months, DGT.{/if}
{#if inputs.indicador_mapa === 'deuda'}Debt of the autonomous community as a % of its GDP, Banco de España. Ceuta and Melilla have no regional debt of their own.{/if}
Click on a region to open its profile.
</p>

## Explore

```sql cabeceras
SELECT
    (SELECT count(*) FROM mother.territorios WHERE nivel = 'provincia') AS provincias,
    (SELECT count(*) FROM mother.trazabilidad_fuentes) AS fuentes,
    (SELECT sum(efectivos) FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = (SELECT max(fecha) FROM mother.empleo_territorio)) AS empleados,
    (SELECT sum(puntos) FROM mother.movilidad_recarga_provincia) AS puntos_recarga,
    (SELECT tasa_1000 FROM mother.crimen_balance WHERE nivel = 'pais' AND categoria = 'Total infracciones penales' ORDER BY anio DESC LIMIT 1) AS delitos_1000
```

<div class="not-prose grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-4">
    <a href="/en/territorios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🗺️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Regions</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Every autonomous community, province and municipality: population, accounts, debt, who governs, public employment and safety.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">19 regions · {cabeceras[0]?.provincias} provinces · 8,100+ municipalities →</p>
    </a>
    <a href="/en/demografia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👪</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Demography</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Population change, births and fertility, ageing, households and the population pyramid of any province.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(poblacion.slice(-1)[0]?.valor, 2)} inhabitants →</p>
    </a>
    <a href="/en/economia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">💼</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Economy</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">GDP per person, sectors, foreign trade, real wages, unemployment, inflation and energy prices, tourism and businesses.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Unemployment: {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} % →</p>
    </a>
    <a href="/en/vivienda" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏠</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Housing</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Purchase prices and rents adjusted for inflation, how many years of salary a home costs, sales, mortgages and new builds.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Prices, rents and affordability →</p>
    </a>
    <a href="/en/cuentas-publicas" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏛️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Public finances</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Revenue, spending, deficit and debt of every public administration, pensions and public employment: how many public employees there are, what they earn and what they cost.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(cabeceras[0]?.empleados, 2)} public employees →</p>
    </a>
    <a href="/en/energia-clima" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">⚡</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Energy and climate</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Live electricity and its records, power plants, storage, electrification, emissions, reservoirs, wildfires and heat.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(100 * renovables_30[0]?.cuota, 0)} % renewable in the last month →</p>
    </a>
    <a href="/en/movilidad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🚗</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Mobility</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">The cars that are sold and on the road, the rise of electric vehicles, makes and models, charging points and public transport.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.puntos_recarga, 0)} public charging points →</p>
    </a>
    <a href="/en/sociedad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👥</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Society</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Crime, health, immigration, income and poverty down to municipal level, and education.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.delitos_1000, 1)} recorded offences per 1,000 inhabitants →</p>
    </a>
    <a href="/en/medios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📰</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">The media</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">How much public money the media receive: public broadcasters, institutional advertising and subsidies, by region and by party.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Public money in the media →</p>
    </a>
    <a href="/en/transparencia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🔎</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Transparency</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Which town councils fail to report their accounts to the Treasury, whose central government funding is withheld and who pays suppliers late.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">By municipality and by party →</p>
    </a>
    <a href="/en/fuentes" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📚</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Sources</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Where each figure comes from: the body, the official table, frequency, licence and methodology.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{cabeceras[0]?.fuentes} official datasets →</p>
    </a>
</div>

## How we work

<div class="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-4">
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Official sources only</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">INE, Banco de España, Eurostat, government ministries, REE, DGT, AEMET… Every chart links to its source table.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Context, not opinion</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">We explain what each figure measures and what it does not, without political judgements: you draw the conclusions.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Open and automated</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">The data are downloaded and published automatically every day; the code is public and anyone can review it.</p>
    </div>
</div>

<LastRefreshed prefix="Data last updated" />
