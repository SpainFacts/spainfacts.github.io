---
title: "Spain's electricity transformation: from coal to over 50% renewable"
description: "How Spain's electricity mix has changed since 2007 according to Red Eléctrica: wind and solar deployment, the coal phase-out and the collapse of CO₂ emissions per kWh."
i18n_origen: db82420b35b1
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql elec
SELECT *
FROM mother.clima_electricidad_anual
ORDER BY anio
```

```sql hitos
WITH e AS (
    SELECT
        *,
        lag(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_prev,
        lag(g_co2_kwh) OVER (ORDER BY anio) AS g_prev,
        first_value(g_co2_kwh) OVER (ORDER BY anio) AS g_inicio,
        first_value(cuota_carbon_pct) OVER (ORDER BY anio) AS carbon_inicio,
        first_value(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_inicio,
        first_value(cuota_solar_fv_pct) OVER (ORDER BY anio) AS solar_inicio,
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
    100.0 * (g_co2_kwh / g_prev - 1) AS g_var,
    g_inicio,
    100.0 * (g_co2_kwh / g_inicio - 1) AS g_var_inicio,
    emisiones_mt,
    emisiones_t_hab,
    cuota_carbon_pct,
    carbon_inicio,
    cuota_solar_fv_pct,
    solar_inicio,
    cuota_eolica_pct,
    (SELECT CAST(min(anio) FILTER (WHERE cuota_renovable_pct > 50) AS INTEGER) FROM mother.clima_electricidad_anual) AS primer_anio_50,
    (SELECT CAST(min(anio) FILTER (WHERE cuota_solar_fv_pct > cuota_carbon_pct) AS INTEGER) FROM mother.clima_electricidad_anual) AS anio_cruce_solar
FROM e
WHERE anio = (SELECT max(anio) FROM mother.clima_electricidad_anual)
```

```sql tecnologias_clave
SELECT CAST(anio AS INTEGER) AS anio, 'Eólica' AS tecnologia, cuota_eolica_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Solar fotovoltaica' AS tecnologia, cuota_solar_fv_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Ciclos combinados (gas)' AS tecnologia, cuota_ciclo_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Carbón' AS tecnologia, cuota_carbon_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, tecnologia
```

```sql cuota_limpia
SELECT CAST(anio AS INTEGER) AS anio, 'Renovable' AS serie, cuota_renovable_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Libre de emisiones (renovable + nuclear)' AS serie, cuota_libre_emisiones_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, serie
```

```sql mix_ultimo
SELECT
    CAST(anio AS INTEGER) AS anio,
    tecnologia,
    tipo_fuente,
    generacion_twh,
    cuota_pct
FROM mother.energia_mix_electrico
WHERE anio = (SELECT max(anio) FROM mother.energia_mix_electrico)
ORDER BY generacion_twh DESC
```

```sql comparativa_ue
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electricidad_renovable'
```

<div class="not-prose mb-4 flex flex-wrap items-center gap-2 text-xs font-semibold text-gray-500 dark:text-gray-400">
    <a href="/en/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Data Analysis</a>
    <span>·</span>
    <span class="rounded-full bg-emerald-100 dark:bg-emerald-950/60 px-2.5 py-0.5 text-emerald-800 dark:text-emerald-300">Energy & Transition</span>
    <span>·</span>
    <a href="/en/energia-clima/mix-electrico" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">View permanent electricity mix dashboard →</a>
</div>

# ⚡ Spain's electricity transformation: from coal to over 50% renewable

In less than two decades, Spain's power system has undergone one of the fastest structural shifts in Europe. According to official series from **Red Eléctrica de España (REE)** since {hitos[0]?.anio_inicio}, renewable generation has risen from **{formatNumber(hitos[0]?.renov_inicio, 1)} %** to **{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %** in {hitos[0]?.anio}, while coal —which supplied a quarter of the country's electricity ({formatNumber(hitos[0]?.carbon_inicio, 1)} %)— has become residual ({formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %).

<Grid cols=4>
    <KpiCard
        title="Renewable share"
        value={hitos[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %"
        period="annual generation ({hitos[0]?.anio}) · {formatNumber(hitos[0]?.renov_inicio, 1)} % in {hitos[0]?.anio_inicio}"
        change={hitos[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs previous year"
        direction="positive-up"
        source="REE"
        href="/en/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="Emission-free"
        value={hitos[0]?.cuota_libre_emisiones_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %"
        period="renewable + nuclear ({hitos[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/en/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_libre_emisiones_pct}))}
    />
    <KpiCard
        title="CO₂ intensity"
        value={hitos[0]?.g_co2_kwh}
        formattedValue="{formatNumber(hitos[0]?.g_co2_kwh, 0)} g/kWh"
        period="{formatNumber(hitos[0]?.g_var_inicio, 0)} % since {hitos[0]?.anio_inicio} ({formatNumber(hitos[0]?.g_inicio, 0)} g/kWh)"
        change={hitos[0]?.g_var?.toFixed(1)}
        changePeriod="vs previous year"
        direction="positive-down"
        source="REE"
        href="/en/energia-clima/emisiones"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Coal share"
        value={hitos[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %"
        period="in {hitos[0]?.anio} · vs. {formatNumber(hitos[0]?.carbon_inicio, 1)} % in {hitos[0]?.anio_inicio}"
        direction="positive-down"
        source="REE"
        href="/en/energia-clima/centrales"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

## 1. The technological handover: two renewable waves and the coal phase-out

Spain's power transition is explained by two successive surges and a scheduled closure:

1. **The first wave was wind power:** now consolidated as the country's leading generation source, supplying **{formatNumber(hitos[0]?.cuota_eolica_pct, 1)} %** of all electricity in {hitos[0]?.anio}.
2. **The second wave is solar PV:** growing from barely {formatNumber(hitos[0]?.solar_inicio, 1)} % in {hitos[0]?.anio_inicio} to **{formatNumber(hitos[0]?.cuota_solar_fv_pct, 1)} %** in {hitos[0]?.anio}, overtaking coal for the first time in {hitos[0]?.anio_cruce_solar}.
3. **Closure of coal-fired plants:** between 2019 and 2020 most of the coal fleet was disconnected due to higher European CO₂ allowance prices and the end of its regulatory lifespan.

<LineChart
    data={tecnologias_clave}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% of national generation"
    title="The historic crossover: wind and solar PV vs. coal and combined-cycle gas"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#eab308']}
/>

## 2. Over half renewable and more than three-quarters emission-free

In **{hitos[0]?.primer_anio_50}** Spain crossed the **50 % annual renewable generation** threshold for the first time. Adding nuclear generation (which emits no greenhouse gases directly but produces radioactive waste), **{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %** of the kilowatt-hours generated in {hitos[0]?.anio} were free of direct CO₂ emissions.

<LineChart
    data={cuota_limpia}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="% of generation"
    title="Share of renewable and direct emission-free generation in Spain"
    colorPalette={['#3b82f6', '#16a34a']}
/>

<Comparativa data={comparativa_ue} />

## 3. Direct climate impact: each kWh emits one-third the CO₂ of {hitos[0]?.anio_inicio}

Replacing coal and gas with wind and solar has slashed the carbon footprint of electricity in Spain:

- In {hitos[0]?.anio_inicio}, generating one kilowatt-hour emitted **{formatNumber(hitos[0]?.g_inicio, 0)} grams of CO₂ equivalent**.
- In {hitos[0]?.anio}, that figure fell to **{formatNumber(hitos[0]?.g_co2_kwh, 0)} g CO₂eq/kWh** (a **{formatNumber(Math.abs(hitos[0]?.g_var_inicio), 0)} %** reduction).
- This multiplies the climate benefit of electrifying transport ([electric vehicles](/en/movilidad/coche-electrico)) or heating (heat pumps), as the grid powering them gets cleaner every year.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq per kWh"
    title="CO₂ emissions intensity of electricity generation in Spain (g CO₂eq/kWh)"
    colorPalette={['#dc2626']}
/>

## 4. Full breakdown of the latest complete year ({hitos[0]?.anio})

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Technology" />
    <Column id=tipo_fuente title="Source type" />
    <Column id=cuota_pct title="% of generation" fmt='0.0"%"' />
    <Column id=generacion_twh title="Generation (TWh)" fmt='0.0' />
</DataTable>

---

**Methodology and sources:**
- **Generation and emissions data:** [Red Eléctrica de España (REE) — REData](https://www.ree.es/es/datos/apidatos), national electricity balance at power plant busbars (complete years).
- **European comparison:** [Eurostat (`nrg_ind_ren`)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ind_ren/default/table).
- **Further exploration:** See [Live electricity](/en/energia-clima/directo), [Electricity mix](/en/energia-clima/mix-electrico), [Storage and pumped hydro](/en/energia-clima/almacenamiento), [Electrification](/en/energia-clima/electrificacion) and [Spain's total emissions](/en/energia-clima/emisiones).
