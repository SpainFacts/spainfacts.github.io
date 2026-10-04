---
title: Mix de Generació Elèctrica
description: "El mix elèctric espanyol des del 2007 segons Red Eléctrica: quota renovable, tancament del carbó, emissions per kWh generat i consum elèctric per habitant."
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

# ⚡ Mix de Generació Elèctrica a Espanya

D'on surt l'electricitat que es genera a Espanya i quant CO₂ costa cada kWh, any rere any des del {elec_kpi[0]?.anio_inicio}, el primer any que publica l'API de dades de Red Eléctrica. Les xifres són el balanç nacional (península, Balears, Canàries, Ceuta i Melilla) mesurat en barres de central, només amb anys complets. Com que el volum total depèn de la mida del país, les tecnologies es mostren en **percentatge de la generació** i el consum **per habitant**.

<Grid cols=4>
    <KpiCard
        title="Electricitat renovable"
        value={elec_kpi[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_renovable_pct, 1)} %"
        period="de la generació el {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.renov_inicio, 1)} % el {elec_kpi[0]?.anio_inicio}"
        change={elec_kpi[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs. any anterior"
        direction="positive-up"
        source="REE"
        sparklineData={elec.map(d => d.cuota_renovable_pct)}
    />
    <KpiCard
        title="CO₂ per kWh generat"
        value={elec_kpi[0]?.g_co2_kwh}
        formattedValue="{formatNumber(elec_kpi[0]?.g_co2_kwh, 0)} g CO₂eq/kWh"
        period="el {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.g_inicio, 0)} g el {elec_kpi[0]?.anio_inicio} · {formatNumber(elec_kpi[0]?.emisiones_mt, 1)} Mt en total"
        change={elec_kpi[0]?.g_var?.toFixed(1)}
        changePeriod="vs. any anterior"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => d.g_co2_kwh)}
    />
    <KpiCard
        title="Consum per habitant"
        value={elec_kpi[0]?.demanda_kwh_hab}
        formattedValue="{formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh"
        period="demanda elèctrica per habitant el {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.demanda_twh, 1)} TWh en total"
        change={elec_kpi[0]?.dem_var?.toFixed(1)}
        changePeriod="vs. any anterior"
        direction="neutral"
        source="REE / Eurostat"
        sparklineData={elec.map(d => d.demanda_kwh_hab)}
    />
    <KpiCard
        title="Carbó"
        value={elec_kpi[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_carbon_pct, 1)} %"
        period="de la generació el {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.carbon_inicio, 1)} % el {elec_kpi[0]?.anio_inicio}"
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


## Pes de cada tecnologia en la generació

La renovable va superar per primera vegada la meitat de la generació el {hitos_renov[0]?.primer_anio_50}, i el seu màxim anual és del {formatNumber(hitos_renov[0]?.renov_max, 1)} % ({hitos_renov[0]?.anio_renov_max}). El {elec_kpi[0]?.anio}, el {formatNumber(elec_kpi[0]?.cuota_libre_emisiones_pct, 1)} % de l'electricitat va ser lliure d'emissions directes (renovable més nuclear).

<AreaChart
    data={mix_pct}
    x=anio
    y=cuota_pct
    series=tecnologia
    type=stacked
    xFmt='0'
    yFmt='0"%"'
    yMax=100
    yAxisTitle="% de la generació"
    title="Estructura de la generació elèctrica per tecnologia"
/>

<DownloadCsvButton data={mix_completo} filename="spainfacts_mix_electrico_detalle.csv" label="Descarregar les dades completes del mix (CSV)" />

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
    yAxisTitle="% de la generació"
    title="Quota de generació neta"
    colorPalette={['#3b82f6', '#16a34a']}
/>

## Quant CO₂ emet cada kWh

Grams de CO₂ equivalent emesos per les centrals per cada kWh generat en el sistema. Red Eléctrica assigna emissions a les centrals tèrmiques (carbó, cicles combinats, cogeneració, motors, turbines i residus no renovables); la nuclear i les renovables compten zero. El mínim de la sèrie és de {formatNumber(hitos_renov[0]?.g_min, 0)} g/kWh el {hitos_renov[0]?.anio_g_min}; des del {elec_kpi[0]?.anio_inicio} el factor ha variat un {formatNumber(elec_kpi[0]?.g_var_inicio, 0)} %.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq per kWh"
    title="Intensitat d'emissions de la generació elèctrica"
    colorPalette={['#dc2626']}
/>

<LineChart
    data={elec}
    x=anio
    y=emisiones_t_hab
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="t CO₂eq per habitant"
    title="Emissions de la generació elèctrica per habitant"
    colorPalette={['#f97316']}
/>

## L'enfonsament del carbó i l'auge de la solar

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

El {cruce_solar_carbon[0]?.primer_anio} la solar fotovoltaica va superar per primera vegada el carbó en generació anual. El {cruce_solar_carbon[0]?.ultimo_anio} la solar va produir **{cruce_solar_carbon[0]?.ratio_ultimo} vegades** més electricitat que el carbó.

<LineChart
    data={carbon_vs_solar}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% de la generació"
    title="Carbó, gas, eòlica i solar fotovoltaica"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#facc15']}
/>

## Consum elèctric per habitant

Demanda nacional en barres de central dividida per la població mitjana de l'any. El {elec_kpi[0]?.anio} va ser de {formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh per habitant, un {formatNumber(Math.abs(elec_kpi[0]?.dem_var_inicio), 0)} % {#if elec_kpi[0]?.dem_var_inicio < 0}menys{:else}més{/if} que el {elec_kpi[0]?.anio_inicio} ({formatNumber(elec_kpi[0]?.dem_inicio, 0)} kWh).

<LineChart
    data={elec}
    x=anio
    y=demanda_kwh_hab
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kWh per habitant"
    startingAtZero={false}
    title="Demanda elèctrica per habitant"
    colorPalette={['#2563eb']}
/>

## Pes de cada tecnologia (últim any complet)

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
    yAxisTitle="% de la generació"
    title="Generació per tecnologia el {elec_kpi[0]?.anio}"
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnologia" />
    <Column id=cuota_pct title="% del total" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
    <Column id=generacion_twh title="Generació (TWh)" fmt="num1" />
</DataTable>

## Potència instal·lada per tecnologia

La capacitat instal·lada reflecteix les decisions d'inversió. La solar FV ha passat de {formatNumber(solar_hitos[0]?.potencia_mw, 0)} MW el {solar_hitos[0]?.anio} a **{formatNumber(solar_hitos[1]?.potencia_mw, 0)} MW** el {solar_hitos[1]?.anio}, i s'ha multiplicat per {formatNumber(solar_hitos[1]?.potencia_mw / solar_hitos[0]?.potencia_mw, 1)}.

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
    yAxisTitle="MW instal·lats"
    title="Potència instal·lada per tecnologia (MW)"
/>

<DownloadCsvButton data={potencia} filename="spainfacts_potencia_instalada.csv" label="Descarregar la potència instal·lada (CSV)" />

<DownloadCsvButton data={elec} filename="spainfacts_electricidad_anual.csv" label="Descarregar quotes, emissions i demanda per any (CSV)" />

---

## Fonts

**Red Eléctrica de España (REE)**, operador del sistema elèctric, API [REData](https://www.ree.es/es/datos/apidatos):
- Generació anual per tecnologia (`generacion/estructura-generacion`) i demanda (`demanda/evolucion`), des del 2007, primer any disponible a l'API. Balanç mesurat en barres de central, sistema nacional. Només anys complets.
- Emissions de CO₂ equivalent de la generació no renovable (`generacion/no-renovables-detalle-emisiones-CO2`); el factor en g/kWh divideix aquestes emissions entre la generació total.
- Llicència: reutilització d'informació del sector públic / dades obertes.

**Població mitjana anual:** Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table).

**Potència instal·lada:** Eurostat [nrg_inf_epc](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) (capacitat elèctrica neta màxima reportada per Espanya), utilitzada mentre el servei de potència instal·lada de l'API de REE no està disponible; la columna `fuente` del CSV indica l'origen. En aquesta estadística el gas natural agrupa cicles combinats i cogeneració, i la solar FV inclou l'autoconsum.

Les emissions totals del país, per habitant i per sector són a [Emissions i descarbonització](/ca/energia-clima/emisiones).

<LastRefreshed prefix="Última sincronització de dades" />
