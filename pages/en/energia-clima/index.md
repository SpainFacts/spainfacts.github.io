---
title: Energy and Climate
description: The ecological transition, the electricity generation mix and greenhouse gas emissions in Spain.
i18n_origen: 0b1048f4b3b1
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatDecimal } from '../../../../../../src/lib/utils.js';
</script>

# 🌱 Energy, Climate and the Ecological Transition

In {resumen_ultimo[0]?.anio}, renewables generated {formatDecimal(resumen_ultimo[0]?.cuota_renovable_pct)}% of Spain's electricity, according to Red Eléctrica. This section presents the official figures for the electricity system, greenhouse gas emissions and the growth of installed renewable capacity.

```sql resumen_ultimo
SELECT * FROM mother.energia_resumen_anual_mix
ORDER BY anio DESC
LIMIT 1
```

```sql resumen_previo
SELECT * FROM mother.energia_resumen_anual_mix
ORDER BY anio DESC
LIMIT 2
```

```sql resumen_serie
SELECT anio, cuota_renovable_pct AS valor
FROM mother.energia_resumen_anual_mix
ORDER BY anio ASC
```

```sql emisiones_totales
SELECT
    anio,
    sum(millones_toneladas_co2eq) AS total_emisiones
FROM mother.energia_emisiones_gei
GROUP BY anio
ORDER BY anio DESC
```

```sql potencia_solar
SELECT potencia_mw, anio
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica'
  AND anio = (SELECT max(anio) FROM mother.energia_potencia_instalada)
```

```sql potencia_eolica
SELECT potencia_mw, anio
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Eólica'
  AND anio = (SELECT max(anio) FROM mother.energia_potencia_instalada)
```

```sql potencia_serie
SELECT
    anio,
    sum(potencia_mw) FILTER (WHERE tecnologia = 'Solar Fotovoltaica') AS solar_mw,
    sum(potencia_mw) FILTER (WHERE tecnologia = 'Eólica') AS eolica_mw
FROM mother.energia_potencia_instalada
GROUP BY anio
ORDER BY anio ASC
```

<Grid cols=4>
    <KpiCard
        title="Renewable share"
        value={resumen_ultimo[0]?.cuota_renovable_pct}
        unit="%"
        period={resumen_ultimo[0]?.anio}
        change={resumen_previo.length > 1 ? (resumen_previo[0].cuota_renovable_pct - resumen_previo[1].cuota_renovable_pct).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs prev. year"
        direction="positive-up"
        source="Red Eléctrica de España (REE)"
        href="/en/energia-clima/mix-electrico"
        sparklineData={resumen_serie}
    />
    <KpiCard
        title="Total CO₂eq emissions"
        value={emisiones_totales[0]?.total_emisiones}
        unit=" Mt"
        change={emisiones_totales.length > 1 ? (emisiones_totales[0].total_emisiones - emisiones_totales[1].total_emisiones).toFixed(1) : null}
        changeUnit=" Mt"
        changePeriod="vs prev. year"
        direction="positive-down"
        period={emisiones_totales[0]?.anio}
        source="GHG Inventory (MITECO) via Eurostat"
        href="/en/energia-clima/emisiones"
        sparklineData={[...emisiones_totales].reverse().map(d => ({...d, valor: d.total_emisiones}))}
    />
    <KpiCard
        title="Solar PV capacity"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_solar[0]?.anio}
        source="Eurostat (nrg_inf_epc)"
        href="/en/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({...d, valor: d.solar_mw / 1000}))}
    />
    <KpiCard
        title="Wind capacity"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_eolica[0]?.anio}
        source="Eurostat (nrg_inf_epc)"
        href="/en/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({...d, valor: d.eolica_mw / 1000}))}
    />
</Grid>

---

## How the National Electricity Mix Has Changed

```sql mix_hitos
SELECT
    anio,
    round(sum(cuota_pct) FILTER (WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica')), 1) AS pct_eolica_solar,
    round(sum(cuota_pct) FILTER (WHERE tecnologia = 'Carbón'), 1) AS pct_carbon
FROM mother.energia_mix_electrico
WHERE anio IN ((SELECT min(anio) FROM mother.energia_mix_electrico), (SELECT max(anio) FROM mother.energia_mix_electrico))
GROUP BY anio
ORDER BY anio ASC
```

The Spanish electricity system has undergone a historic transformation: between {mix_hitos[0]?.anio} and {mix_hitos[1]?.anio}, wind and solar PV have gone from {formatDecimal(mix_hitos[0]?.pct_eolica_solar)}% to **{formatDecimal(mix_hitos[1]?.pct_eolica_solar)}%** of total generation, while coal has fallen from {formatDecimal(mix_hitos[0]?.pct_carbon)}% to {formatDecimal(mix_hitos[1]?.pct_carbon)}%.

```sql mix_areas
SELECT
    anio,
    tecnologia,
    generacion_twh
FROM mother.energia_mix_electrico
WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica', 'Hidroeléctrica', 'Nuclear', 'Ciclos Combinados (Gas)', 'Carbón')
ORDER BY anio ASC, tecnologia ASC
```

<AreaChart
    data={mix_areas}
    x=anio
    y=generacion_twh
    series=tecnologia
    yAxisTitle="Generation (TWh)"
    xAxisTitle="Year"
    title="Electricity generation by technology (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

<DownloadCsvButton data={mix_areas} filename="spainfacts_mix_electrico.csv" label="Download electricity mix (CSV)" />

---

## Renewable and Emission-Free Share

```sql cuota_anual
SELECT
    anio,
    cuota_renovable_pct AS "Renovable (%)",
    cuota_libre_emisiones_pct AS "Libre de emisiones (%) (Renovable + Nuclear)"
FROM mother.energia_resumen_anual_mix
ORDER BY anio ASC
```

<LineChart
    data={cuota_anual}
    x=anio
    y={["Renovable (%)", "Libre de emisiones (%) (Renovable + Nuclear)"]}
    yAxisTitle="Share of total (%)"
    title="Share of clean generation in total electricity"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=0
    yMax=85
/>

---

## Greenhouse Gas Emissions by Sector

```sql emisiones_hitos
SELECT
    anio,
    round(max(cuota_pct) FILTER (WHERE sector = 'Transporte'), 1) AS pct_transporte,
    max(millones_toneladas_co2eq) FILTER (WHERE sector = 'Generación Eléctrica') AS mt_electrica
FROM mother.energia_emisiones_gei
WHERE anio IN ((SELECT min(anio) FROM mother.energia_emisiones_gei), (SELECT max(anio) FROM mother.energia_emisiones_gei))
GROUP BY anio
ORDER BY anio ASC
```

**Transport** is the sector most resistant to decarbonisation: it accounts for **{formatDecimal(emisiones_hitos[1]?.pct_transporte)}%** of emissions in {emisiones_hitos[1]?.anio}. **Electricity generation**, by contrast, has cut its emissions by {emisiones_hitos.length > 1 ? ((1 - emisiones_hitos[1].mt_electrica / emisiones_hitos[0].mt_electrica) * 100).toFixed(0) : null}% since {emisiones_hitos[0]?.anio} thanks to the roll-out of renewables.

```sql emisiones_sector
SELECT
    anio,
    sector,
    millones_toneladas_co2eq,
    t_co2eq_hab
FROM mother.energia_emisiones_gei
ORDER BY anio ASC, sector ASC
```

<BarChart
    data={emisiones_sector}
    x=anio
    y=millones_toneladas_co2eq
    series=sector
    type=stacked
    yAxisTitle="Million tonnes of CO₂eq"
    title="GHG emissions by sector (Mt CO₂eq)"
/>

<BarChart
    data={emisiones_sector}
    x=anio
    y=t_co2eq_hab
    series=sector
    type=stacked
    yAxisTitle="Tonnes of CO₂eq per person"
    title="GHG emissions by sector, per person (t CO₂eq per person)"
/>

<DownloadCsvButton data={emisiones_sector} filename="spainfacts_emisiones_gei.csv" label="Download GHG emissions (CSV)" />

---

## Detailed Reports

<Grid cols=2>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            ⚡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Electricity Generation Mix</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            An in-depth look at the electricity mix: the rise of wind and solar PV, the phase-out of coal, the reliance on natural gas and the role of nuclear power.
        </p>
    </div>
    <a href="/en/energia-clima/mix-electrico" class="text-sm font-semibold text-green-700 dark:text-green-400 hover:underline inline-flex items-center">
        See the electricity mix report →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏭
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Emissions and Decarbonisation</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Greenhouse gases broken down by sector: why transport is the big outstanding challenge and how electricity is already decarbonising.
        </p>
    </div>
    <a href="/en/energia-clima/emisiones" class="text-sm font-semibold text-amber-700 dark:text-amber-400 hover:underline inline-flex items-center">
        See the emissions report →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-sky-300 dark:hover:border-sky-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-sky-100 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            💧
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Water Reserves and Reservoirs</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            The weekly state of reservoirs by river basin: how much water there is, and how it compares with last year and with the average for the past decade.
        </p>
    </div>
    <a href="/en/energia-clima/embalses" class="text-sm font-semibold text-sky-700 dark:text-sky-400 hover:underline inline-flex items-center">
        See the state of the reservoirs →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-orange-300 dark:hover:border-orange-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-950/60 text-orange-600 dark:text-orange-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🌡️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Heat and Temperatures</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            The daily heat map by province: how far the maximum temperature departs from each day's historical average, the records and the trend since 1991.
        </p>
    </div>
    <a href="/en/energia-clima/calor" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        See the heat map →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-red-300 dark:hover:border-red-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔥
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Wildfires</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Hectares burnt each year since 2000, how much burns within the Natura 2000 network, a map of this year's fires and active fires detected by satellite.
        </p>
    </div>
    <a href="/en/energia-clima/incendios" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        See the wildfire map →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-teal-300 dark:hover:border-teal-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-teal-100 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            📡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">The Electricity System, Right Now</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Live every 5 minutes: demand, renewable % and CO₂ intensity for Spain, the Peninsula, the Balearic Islands, the Canary Islands, Ceuta and Melilla, exchanges with neighbouring countries and the electricity price.
        </p>
    </div>
    <a href="/en/energia-clima/directo" class="text-sm font-semibold text-teal-700 dark:text-teal-400 hover:underline inline-flex items-center">
        See the system live →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-yellow-300 dark:hover:border-yellow-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-yellow-100 dark:bg-yellow-950/60 text-yellow-600 dark:text-yellow-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏆
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Electricity System Records</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            All-time highs and lows since 2015 from REE's 5-minute data: demand, solar, wind, renewable share, emissions, prices and exchanges, and when each record was broken.
        </p>
    </div>
    <a href="/en/energia-clima/records" class="text-sm font-semibold text-yellow-700 dark:text-yellow-400 hover:underline inline-flex items-center">
        See the records →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🗺️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Power Plants</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            A map of every power plant in Spain by technology and capacity: those in operation, those under construction or in the permitting process and those already closed, with their owner and key dates.
        </p>
    </div>
    <a href="/en/energia-clima/centrales" class="text-sm font-semibold text-indigo-600 dark:text-indigo-400 hover:underline inline-flex items-center">
        See the power plant map →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-violet-300 dark:hover:border-violet-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-violet-100 dark:bg-violet-950/60 text-violet-600 dark:text-violet-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔋
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Storage</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Pumped hydro and batteries: how much energy they store and return, where they are, and the projects with grid connection permits compared with the 2030 target.
        </p>
    </div>
    <a href="/en/energia-clima/almacenamiento" class="text-sm font-semibold text-violet-600 dark:text-violet-400 hover:underline inline-flex items-center">
        See storage →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔌
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Electrification</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            How much of the energy used by industry, transport, households and services is already electricity, how homes are heated in each province and how many heat pumps there are.
        </p>
    </div>
    <a href="/en/energia-clima/electrificacion" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        See electrification →
    </a>
</div>

</Grid>

---

## Methodology and Primary Sources

| Body | Dataset | Code | Licence |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Annual generation and demand (REData API) | [REE-MIX](https://www.ree.es/es/datos/generacion) | Open Data / RISP |
| **MITECO / Eurostat** | National GHG Emissions Inventory (env_air_gge) | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) · [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) | RISP (Law 37/2007) / CC BY 4.0 |
| **Eurostat** | Installed electrical capacity (nrg_inf_epc) | [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) | CC BY 4.0 |

> Electricity generation data come from the national balance measured at power plant busbars by REE as System Operator (full years only). Emissions are those of Spain's official inventory (excluding LULUCF), calculated according to IPCC guidelines and reported to the United Nations Framework Convention on Climate Change (UNFCCC); Eurostat publishes them broken down by CRF category, which are grouped into sectors here.

<LastRefreshed prefix="Last data sync with official sources" />
