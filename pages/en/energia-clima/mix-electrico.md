---
title: Electricity Generation Mix
description: "Spain's electricity mix since 2007 according to Red Eléctrica: renewable share, the coal phase-out, emissions per kWh generated and electricity consumption per person."
i18n_origen: 2c4bc7fa07e5
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql elec
SELECT *
FROM mother.clima_electricidad_anual
ORDER BY anio
```

```sql elec_kpi
WITH e AS (
    SELECT
        *,
        lag(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_prev,
        lag(g_co2_kwh) OVER (ORDER BY anio) AS g_prev,
        lag(demanda_kwh_hab) OVER (ORDER BY anio) AS dem_prev,
        first_value(g_co2_kwh) OVER (ORDER BY anio) AS g_inicio,
        first_value(cuota_carbon_pct) OVER (ORDER BY anio) AS carbon_inicio,
        first_value(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_inicio,
        first_value(demanda_kwh_hab) OVER (ORDER BY anio) AS dem_inicio,
        CAST(first_value(anio) OVER (ORDER BY anio) AS INTEGER) AS anio_inicio
    FROM mother.clima_electricidad_anual
)
SELECT
    CAST(anio AS INTEGER) AS anio,
    anio_inicio,
    cuota_renovable_pct,
    cuota_renovable_pct - renov_prev AS renov_var_pp,
    renov_inicio,
    cuota_libre_emisiones_pct,
    g_co2_kwh,
    100 * (g_co2_kwh / g_prev - 1) AS g_var,
    g_inicio,
    100 * (g_co2_kwh / g_inicio - 1) AS g_var_inicio,
    emisiones_mt,
    emisiones_t_hab,
    demanda_kwh_hab,
    100 * (demanda_kwh_hab / dem_prev - 1) AS dem_var,
    100 * (demanda_kwh_hab / dem_inicio - 1) AS dem_var_inicio,
    dem_inicio,
    demanda_twh,
    generacion_twh,
    cuota_carbon_pct,
    carbon_inicio
FROM e
WHERE anio = (SELECT max(anio) FROM mother.clima_electricidad_anual)
```

```sql hitos_renov
SELECT
    CAST(min(anio) FILTER (WHERE cuota_renovable_pct > 50) AS INTEGER) AS primer_anio_50,
    max(cuota_renovable_pct) AS renov_max,
    CAST(arg_max(anio, cuota_renovable_pct) AS INTEGER) AS anio_renov_max,
    min(g_co2_kwh) AS g_min,
    CAST(arg_min(anio, g_co2_kwh) AS INTEGER) AS anio_g_min
FROM mother.clima_electricidad_anual
```

```sql mix_completo
SELECT
    anio,
    tecnologia,
    tipo_fuente,
    generacion_twh,
    cuota_pct
FROM mother.energia_mix_electrico
ORDER BY anio ASC, tecnologia ASC
```

```sql mix_pct
SELECT
    CAST(anio AS INTEGER) AS anio,
    tecnologia,
    cuota_pct,
    generacion_twh
FROM mother.energia_mix_electrico
ORDER BY anio, tecnologia
```

# ⚡ Electricity Generation Mix in Spain

Where the electricity generated in Spain comes from and how much CO₂ each kWh costs, year by year since {elec_kpi[0]?.anio_inicio}, the first year published by the Red Eléctrica data API. The figures are the national balance (the Peninsula, the Balearic Islands, the Canary Islands, Ceuta and Melilla) measured at power plant busbars, for full years only. Because total volume depends on the size of the country, technologies are shown as a **percentage of generation** and consumption **per person**.

<Grid cols=4>
    <KpiCard
        title="Renewable electricity"
        value={elec_kpi[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_renovable_pct, 1)} %"
        period="of generation in {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.renov_inicio, 1)} % in {elec_kpi[0]?.anio_inicio}"
        change={elec_kpi[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs previous year"
        direction="positive-up"
        source="REE"
        sparklineData={elec.map(d => d.cuota_renovable_pct)}
    />
    <KpiCard
        title="CO₂ per kWh generated"
        value={elec_kpi[0]?.g_co2_kwh}
        formattedValue="{formatNumber(elec_kpi[0]?.g_co2_kwh, 0)} g CO₂eq/kWh"
        period="in {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.g_inicio, 0)} g in {elec_kpi[0]?.anio_inicio} · {formatNumber(elec_kpi[0]?.emisiones_mt, 1)} Mt in total"
        change={elec_kpi[0]?.g_var?.toFixed(1)}
        changePeriod="vs previous year"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => d.g_co2_kwh)}
    />
    <KpiCard
        title="Consumption per person"
        value={elec_kpi[0]?.demanda_kwh_hab}
        formattedValue="{formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh"
        period="electricity demand per person in {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.demanda_twh, 1)} TWh in total"
        change={elec_kpi[0]?.dem_var?.toFixed(1)}
        changePeriod="vs previous year"
        direction="neutral"
        source="REE / Eurostat"
        sparklineData={elec.map(d => d.demanda_kwh_hab)}
    />
    <KpiCard
        title="Coal"
        value={elec_kpi[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_carbon_pct, 1)} %"
        period="of generation in {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.carbon_inicio, 1)} % in {elec_kpi[0]?.anio_inicio}"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => d.cuota_carbon_pct)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('electricidad_renovable', 'consumo_electrico_pc')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'electricidad_renovable')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'consumo_electrico_pc')} />


## Share of each technology in generation

Renewables first exceeded half of generation in {hitos_renov[0]?.primer_anio_50}, and their annual peak is {formatNumber(hitos_renov[0]?.renov_max, 1)} % ({hitos_renov[0]?.anio_renov_max}). In {elec_kpi[0]?.anio}, {formatNumber(elec_kpi[0]?.cuota_libre_emisiones_pct, 1)} % of electricity was free of direct emissions (renewables plus nuclear).

<AreaChart
    data={mix_pct}
    x=anio
    y=cuota_pct
    series=tecnologia
    type=stacked
    xFmt='0'
    yFmt='0"%"'
    yMax=100
    yAxisTitle="% of generation"
    title="Structure of electricity generation by technology"
/>

<DownloadCsvButton data={mix_completo} filename="spainfacts_mix_electrico_detalle.csv" label="Download full mix data (CSV)" />

```sql cuota
SELECT anio, 'Renovable' AS serie, cuota_renovable_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Libre de emisiones (renovable + nuclear)' AS serie, cuota_libre_emisiones_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, serie
```

<LineChart
    data={cuota}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="% of generation"
    title="Share of clean generation"
    colorPalette={['#3b82f6', '#16a34a']}
/>

## How much CO₂ each kWh emits

Grams of CO₂ equivalent emitted by power plants for each kWh generated in the system. Red Eléctrica attributes emissions to thermal plants (coal, combined cycle, cogeneration, engines, turbines and non-renewable waste); nuclear and renewables count as zero. The lowest value in the series is {formatNumber(hitos_renov[0]?.g_min, 0)} g/kWh in {hitos_renov[0]?.anio_g_min}; since {elec_kpi[0]?.anio_inicio} the factor has changed by {formatNumber(elec_kpi[0]?.g_var_inicio, 0)} %.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq per kWh"
    title="Emissions intensity of electricity generation"
    colorPalette={['#dc2626']}
/>

<LineChart
    data={elec}
    x=anio
    y=emisiones_t_hab
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="t CO₂eq per person"
    title="Emissions from electricity generation per person"
    colorPalette={['#f97316']}
/>

## The collapse of coal and the rise of solar

```sql carbon_vs_solar
SELECT anio, 'Carbón' AS tecnologia, cuota_carbon_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Solar fotovoltaica' AS tecnologia, cuota_solar_fv_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Eólica' AS tecnologia, cuota_eolica_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Ciclos combinados (gas)' AS tecnologia, cuota_ciclo_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, tecnologia
```

```sql cruce_solar_carbon
SELECT
    CAST(min(anio) FILTER (WHERE cuota_solar_fv_pct > cuota_carbon_pct) AS INTEGER) AS primer_anio,
    CAST(max(anio) AS INTEGER) AS ultimo_anio,
    round(arg_max(cuota_solar_fv_pct / nullif(cuota_carbon_pct, 0), anio), 0) AS ratio_ultimo
FROM mother.clima_electricidad_anual
```

In {cruce_solar_carbon[0]?.primer_anio}, solar PV overtook coal in annual generation for the first time. In {cruce_solar_carbon[0]?.ultimo_anio}, solar produced **{cruce_solar_carbon[0]?.ratio_ultimo} times** as much electricity as coal.

<LineChart
    data={carbon_vs_solar}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% of generation"
    title="Coal, gas, wind and solar PV"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#facc15']}
/>

## Electricity consumption per person

National demand at power plant busbars divided by the average population for the year. In {elec_kpi[0]?.anio} it was {formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh per person, {formatNumber(Math.abs(elec_kpi[0]?.dem_var_inicio), 0)} % {#if elec_kpi[0]?.dem_var_inicio < 0}less{:else}more{/if} than in {elec_kpi[0]?.anio_inicio} ({formatNumber(elec_kpi[0]?.dem_inicio, 0)} kWh).

<LineChart
    data={elec}
    x=anio
    y=demanda_kwh_hab
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kWh per person"
    startingAtZero={false}
    title="Electricity demand per person"
    colorPalette={['#2563eb']}
/>

## Share of each technology (latest full year)

```sql mix_ultimo
SELECT
    anio,
    tecnologia,
    generacion_twh,
    cuota_pct / 100.0 AS cuota_pct
FROM mother.energia_mix_electrico
WHERE anio = (SELECT max(anio) FROM mother.energia_mix_electrico)
ORDER BY generacion_twh DESC
```

<BarChart
    data={mix_ultimo}
    x=tecnologia
    y=cuota_pct
    yFmt='0.0%'
    yAxisTitle="% of generation"
    title="Generation by technology in {elec_kpi[0]?.anio}"
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Technology" />
    <Column id=cuota_pct title="% of total" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
    <Column id=generacion_twh title="Generation (TWh)" fmt="num1" />
</DataTable>

## Installed capacity by technology

Installed capacity reflects investment decisions. Solar PV has grown from {formatNumber(solar_hitos[0]?.potencia_mw, 0)} MW in {solar_hitos[0]?.anio} to **{formatNumber(solar_hitos[1]?.potencia_mw, 0)} MW** in {solar_hitos[1]?.anio}, a {formatNumber(solar_hitos[1]?.potencia_mw / solar_hitos[0]?.potencia_mw, 1)}-fold increase.

```sql solar_hitos
SELECT CAST(anio AS INTEGER) AS anio, potencia_mw
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica'
  AND anio IN ((SELECT min(anio) FROM mother.energia_potencia_instalada), (SELECT max(anio) FROM mother.energia_potencia_instalada))
ORDER BY anio ASC
```

```sql potencia
SELECT
    anio,
    tecnologia,
    potencia_mw,
    tipo,
    fuente
FROM mother.energia_potencia_instalada
ORDER BY anio ASC, potencia_mw DESC
```

<BarChart
    data={potencia}
    x=anio
    y=potencia_mw
    series=tecnologia
    type=grouped
    xFmt='0'
    yAxisTitle="MW installed"
    title="Installed capacity by technology (MW)"
/>

<DownloadCsvButton data={potencia} filename="spainfacts_potencia_instalada.csv" label="Download installed capacity (CSV)" />

<DownloadCsvButton data={elec} filename="spainfacts_electricidad_anual.csv" label="Download shares, emissions and demand by year (CSV)" />

---

## Sources

**Red Eléctrica de España (REE)**, the electricity system operator, [REData](https://www.ree.es/es/datos/apidatos) API:
- Annual generation by technology (`generacion/estructura-generacion`) and demand (`demanda/evolucion`), from 2007, the first year available in the API. Balance measured at power plant busbars, national system. Full years only.
- CO₂ equivalent emissions from non-renewable generation (`generacion/no-renovables-detalle-emisiones-CO2`); the g/kWh factor divides those emissions by total generation.
- Licence: re-use of public sector information / open data.

**Average annual population:** Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table).

**Installed capacity:** Eurostat [nrg_inf_epc](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) (maximum net electrical capacity reported by Spain), used while the installed capacity service in the REE API is unavailable; the `fuente` column in the CSV shows the origin. In this dataset natural gas groups together combined cycle and cogeneration, and solar PV includes self-consumption.

The country's total emissions, per person and by sector, are on the [Emissions and decarbonisation](/en/energia-clima/emisiones) page.

<LastRefreshed prefix="Last data sync" />
