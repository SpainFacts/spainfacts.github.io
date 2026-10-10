---
i18n_origen: 7cce8c387246
title: Mix de xeración eléctrica
description: "O mix eléctrico español desde 2007 segundo Red Eléctrica: cota renovable, peche do carbón, emisións por kWh xerado e consumo eléctrico por habitante."
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

# ⚡ Mix de xeración eléctrica en España

De onde sae a electricidade que se xera en España e canto CO₂ custa cada kWh, ano a ano desde {elec_kpi[0]?.anio_inicio}, o primeiro ano que publica a API de datos de Red Eléctrica. As cifras son o balance nacional (península, Baleares, Canarias, Ceuta e Melilla) medido en barras de central, só con anos completos. Como o volume total depende do tamaño do país, as tecnoloxías móstranse en **porcentaxe da xeración** e o consumo **por habitante**.

<Grid cols=4>
    <KpiCard
        title="Electricidade renovable"
        value={elec_kpi[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_renovable_pct, 1)} %"
        period="da xeración en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.renov_inicio, 1)} % en {elec_kpi[0]?.anio_inicio}"
        change={elec_kpi[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs. ano anterior"
        direction="positive-up"
        source="REE"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="CO₂ por kWh xerado"
        value={elec_kpi[0]?.g_co2_kwh}
        formattedValue="{formatNumber(elec_kpi[0]?.g_co2_kwh, 0)} g CO₂eq/kWh"
        period="en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.g_inicio, 0)} g en {elec_kpi[0]?.anio_inicio} · {formatNumber(elec_kpi[0]?.emisiones_mt, 1)} Mt en total"
        change={elec_kpi[0]?.g_var?.toFixed(1)}
        changePeriod="vs. ano anterior"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Consumo por habitante"
        value={elec_kpi[0]?.demanda_kwh_hab}
        formattedValue="{formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh"
        period="demanda eléctrica por habitante en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.demanda_twh, 1)} TWh en total"
        change={elec_kpi[0]?.dem_var?.toFixed(1)}
        changePeriod="vs. ano anterior"
        direction="neutral"
        source="REE / Eurostat"
        sparklineData={elec.map(d => ({...d, y: d.demanda_kwh_hab}))}
    />
    <KpiCard
        title="Carbón"
        value={elec_kpi[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_carbon_pct, 1)} %"
        period="da xeración en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.carbon_inicio, 1)} % en {elec_kpi[0]?.anio_inicio}"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('electricidad_renovable', 'consumo_electrico_pc')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'electricidad_renovable')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'consumo_electrico_pc')} />


## Peso de cada tecnoloxía na xeración

A renovable superou por primeira vez a metade da xeración en {hitos_renov[0]?.primer_anio_50}, e o seu máximo anual é do {formatNumber(hitos_renov[0]?.renov_max, 1)} % ({hitos_renov[0]?.anio_renov_max}). En {elec_kpi[0]?.anio}, o {formatNumber(elec_kpi[0]?.cuota_libre_emisiones_pct, 1)} % da electricidade foi libre de emisións directas (renovable máis nuclear).

<AreaChart
    data={mix_pct}
    x=anio
    y=cuota_pct
    series=tecnologia
    type=stacked
    xFmt='0'
    yFmt='0"%"'
    yMax=100
    yAxisTitle="% da xeración"
    title="Estrutura da xeración eléctrica por tecnoloxía"
/>

<DownloadCsvButton data={mix_completo} filename="spainfacts_mix_electrico_detalle.csv" label="Descargar datos completos do mix (CSV)" />

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
    yAxisTitle="% da xeración"
    title="Cota de xeración limpa"
    colorPalette={['#3b82f6', '#16a34a']}
/>

## Canto CO₂ emite cada kWh

Gramos de CO₂ equivalente emitidos polas centrais por cada kWh xerado no sistema. Red Eléctrica asigna emisións ás centrais térmicas (carbón, ciclos combinados, coxeración, motores, turbinas e residuos non renovables); a nuclear e as renovables contan cero. O mínimo da serie é de {formatNumber(hitos_renov[0]?.g_min, 0)} g/kWh en {hitos_renov[0]?.anio_g_min}; desde {elec_kpi[0]?.anio_inicio} o factor variou un {formatNumber(elec_kpi[0]?.g_var_inicio, 0)} %.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq por kWh"
    title="Intensidade de emisións da xeración eléctrica"
    colorPalette={['#dc2626']}
/>

<LineChart
    data={elec}
    x=anio
    y=emisiones_t_hab
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="t CO₂eq por habitante"
    title="Emisións da xeración eléctrica por habitante"
    colorPalette={['#f97316']}
/>

## O desplome do carbón e o auxe da solar

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

En {cruce_solar_carbon[0]?.primer_anio} a solar fotovoltaica superou por primeira vez o carbón en xeración anual. En {cruce_solar_carbon[0]?.ultimo_anio} a solar produciu **{cruce_solar_carbon[0]?.ratio_ultimo} veces** máis electricidade ca o carbón.

<LineChart
    data={carbon_vs_solar}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% da xeración"
    title="Carbón, gas, eólica e solar fotovoltaica"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#facc15']}
/>

## Consumo eléctrico por habitante

Demanda nacional en barras de central dividida pola poboación media do ano. En {elec_kpi[0]?.anio} foi de {formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh por habitante, un {formatNumber(Math.abs(elec_kpi[0]?.dem_var_inicio), 0)} % {#if elec_kpi[0]?.dem_var_inicio < 0}menos{:else}máis{/if} ca en {elec_kpi[0]?.anio_inicio} ({formatNumber(elec_kpi[0]?.dem_inicio, 0)} kWh).

<LineChart
    data={elec}
    x=anio
    y=demanda_kwh_hab
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kWh por habitante"
    startingAtZero={false}
    title="Demanda eléctrica por habitante"
    colorPalette={['#2563eb']}
/>

## Peso de cada tecnoloxía (último ano completo)

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
    yAxisTitle="% da xeración"
    title="Xeración por tecnoloxía en {elec_kpi[0]?.anio}"
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnoloxía" />
    <Column id=cuota_pct title="% do total" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
    <Column id=generacion_twh title="Xeración (TWh)" fmt="num1" />
</DataTable>

## Potencia instalada por tecnoloxía

A capacidade instalada reflicte as decisións de investimento. A solar FV pasou de {formatNumber(solar_hitos[0]?.potencia_mw, 0)} MW en {solar_hitos[0]?.anio} a **{formatNumber(solar_hitos[1]?.potencia_mw, 0)} MW** en {solar_hitos[1]?.anio}, multiplicándose por {formatNumber(solar_hitos[1]?.potencia_mw / solar_hitos[0]?.potencia_mw, 1)}.

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
    yAxisTitle="MW instalados"
    title="Potencia instalada por tecnoloxía (MW)"
/>

<DownloadCsvButton data={potencia} filename="spainfacts_potencia_instalada.csv" label="Descargar potencia instalada (CSV)" />

<DownloadCsvButton data={elec} filename="spainfacts_electricidad_anual.csv" label="Descargar cotas, emisións e demanda por ano (CSV)" />

---

## Fontes

**Red Eléctrica de España (REE)**, operador do sistema eléctrico, API [REData](https://www.ree.es/es/datos/apidatos):
- Xeración anual por tecnoloxía (`generacion/estructura-generacion`) e demanda (`demanda/evolucion`), desde 2007, primeiro ano dispoñible na API. Balance medido en barras de central, sistema nacional. Só anos completos.
- Emisións de CO₂ equivalente da xeración non renovable (`generacion/no-renovables-detalle-emisiones-CO2`); o factor en g/kWh divide esas emisións entre a xeración total.
- Licenza: reutilización de información do sector público / datos abertos.

**Poboación media anual:** Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table).

**Potencia instalada:** Eurostat [nrg_inf_epc](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) (capacidade eléctrica neta máxima comunicada por España), usada mentres o servizo de potencia instalada da API de REE non está dispoñible; a columna `fuente` do CSV indica a orixe. Nesta estatística o gas natural agrupa ciclos combinados e coxeración, e a solar FV inclúe autoconsumo.

As emisións totais do país, por habitante e por sector están en [Emisións e descarbonización](/gl/energia-clima/emisiones).

<LastRefreshed prefix="Última sincronización de datos" />
