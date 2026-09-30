---
title: Mix de Generación Eléctrica
description: "El mix eléctrico español desde 2007 según Red Eléctrica: cuota renovable, cierre del carbón, emisiones por kWh generado y consumo eléctrico por habitante."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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
    año,
    tecnologia,
    tipo_fuente,
    generacion_twh,
    porcentaje_total
FROM mother.energia_mix_electrico
ORDER BY año ASC, tecnologia ASC
```

```sql mix_pct
SELECT
    CAST(año AS INTEGER) AS anio,
    tecnologia,
    porcentaje_total,
    generacion_twh
FROM mother.energia_mix_electrico
ORDER BY anio, tecnologia
```

# ⚡ Mix de Generación Eléctrica en España

De dónde sale la electricidad que se genera en España y cuánto CO₂ cuesta cada kWh, año a año desde {elec_kpi[0]?.anio_inicio}, el primer año que publica la API de datos de Red Eléctrica. Las cifras son el balance nacional (península, Baleares, Canarias, Ceuta y Melilla) medido en barras de central, solo con años completos. Como el volumen total depende del tamaño del país, las tecnologías se muestran en **porcentaje de la generación** y el consumo **por habitante**.

<Grid cols=4>
    <KpiCard
        title="Electricidad renovable"
        value={elec_kpi[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_renovable_pct, 1)} %"
        period="de la generación en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.renov_inicio, 1)} % en {elec_kpi[0]?.anio_inicio}"
        change={elec_kpi[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs año anterior"
        direction="positive-up"
        source="REE"
        sparklineData={elec.map(d => d.cuota_renovable_pct)}
    />
    <KpiCard
        title="CO₂ por kWh generado"
        value={elec_kpi[0]?.g_co2_kwh}
        formattedValue="{formatNumber(elec_kpi[0]?.g_co2_kwh, 0)} g CO₂eq/kWh"
        period="en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.g_inicio, 0)} g en {elec_kpi[0]?.anio_inicio} · {formatNumber(elec_kpi[0]?.emisiones_mt, 1)} Mt en total"
        change={elec_kpi[0]?.g_var?.toFixed(1)}
        changePeriod="vs año anterior"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => d.g_co2_kwh)}
    />
    <KpiCard
        title="Consumo por habitante"
        value={elec_kpi[0]?.demanda_kwh_hab}
        formattedValue="{formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh"
        period="demanda eléctrica por habitante en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.demanda_twh, 1)} TWh en total"
        change={elec_kpi[0]?.dem_var?.toFixed(1)}
        changePeriod="vs año anterior"
        direction="neutral"
        source="REE / Eurostat"
        sparklineData={elec.map(d => d.demanda_kwh_hab)}
    />
    <KpiCard
        title="Carbón"
        value={elec_kpi[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_carbon_pct, 1)} %"
        period="de la generación en {elec_kpi[0]?.anio} · {formatNumber(elec_kpi[0]?.carbon_inicio, 1)} % en {elec_kpi[0]?.anio_inicio}"
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


## Peso de cada tecnología en la generación

La renovable superó por primera vez la mitad de la generación en {hitos_renov[0]?.primer_anio_50}, y su máximo anual es del {formatNumber(hitos_renov[0]?.renov_max, 1)} % ({hitos_renov[0]?.anio_renov_max}). En {elec_kpi[0]?.anio}, el {formatNumber(elec_kpi[0]?.cuota_libre_emisiones_pct, 1)} % de la electricidad fue libre de emisiones directas (renovable más nuclear).

<AreaChart
    data={mix_pct}
    x=anio
    y=porcentaje_total
    series=tecnologia
    type=stacked
    xFmt='0'
    yFmt='0"%"'
    yMax=100
    yAxisTitle="% de la generación"
    title="Estructura de la generación eléctrica por tecnología"
/>

<DownloadCsvButton data={mix_completo} filename="spainfacts_mix_electrico_detalle.csv" label="Descargar datos completos del mix (CSV)" />

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
    yAxisTitle="% de la generación"
    title="Cuota de generación limpia"
    colorPalette={['#3b82f6', '#16a34a']}
/>

## Cuánto CO₂ emite cada kWh

Gramos de CO₂ equivalente emitidos por las centrales por cada kWh generado en el sistema. Red Eléctrica asigna emisiones a las centrales térmicas (carbón, ciclos combinados, cogeneración, motores, turbinas y residuos no renovables); la nuclear y las renovables cuentan cero. El mínimo de la serie es de {formatNumber(hitos_renov[0]?.g_min, 0)} g/kWh en {hitos_renov[0]?.anio_g_min}; desde {elec_kpi[0]?.anio_inicio} el factor ha variado un {formatNumber(elec_kpi[0]?.g_var_inicio, 0)} %.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq por kWh"
    title="Intensidad de emisiones de la generación eléctrica"
    colorPalette={['#dc2626']}
/>

<LineChart
    data={elec}
    x=anio
    y=emisiones_t_hab
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="t CO₂eq por habitante"
    title="Emisiones de la generación eléctrica por habitante"
    colorPalette={['#f97316']}
/>

## El desplome del carbón y el auge de la solar

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

En {cruce_solar_carbon[0]?.primer_anio} la solar fotovoltaica superó por primera vez al carbón en generación anual. En {cruce_solar_carbon[0]?.ultimo_anio} la solar produjo **{cruce_solar_carbon[0]?.ratio_ultimo} veces** más electricidad que el carbón.

<LineChart
    data={carbon_vs_solar}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% de la generación"
    title="Carbón, gas, eólica y solar fotovoltaica"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#facc15']}
/>

## Consumo eléctrico por habitante

Demanda nacional en barras de central dividida por la población media del año. En {elec_kpi[0]?.anio} fue de {formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh por habitante, un {formatNumber(Math.abs(elec_kpi[0]?.dem_var_inicio), 0)} % {#if elec_kpi[0]?.dem_var_inicio < 0}menos{:else}más{/if} que en {elec_kpi[0]?.anio_inicio} ({formatNumber(elec_kpi[0]?.dem_inicio, 0)} kWh).

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

## Peso de cada tecnología (último año completo)

```sql mix_ultimo
SELECT
    año,
    tecnologia,
    generacion_twh,
    porcentaje_total / 100.0 AS porcentaje_total
FROM mother.energia_mix_electrico
WHERE año = (SELECT max(año) FROM mother.energia_mix_electrico)
ORDER BY generacion_twh DESC
```

<BarChart
    data={mix_ultimo}
    x=tecnologia
    y=porcentaje_total
    yFmt='0.0%'
    yAxisTitle="% de la generación"
    title="Generación por tecnología en {elec_kpi[0]?.anio}"
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnología" />
    <Column id=porcentaje_total title="% del total" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
    <Column id=generacion_twh title="Generación (TWh)" fmt="num1" />
</DataTable>

## Potencia instalada por tecnología

La capacidad instalada refleja las decisiones de inversión. La solar FV ha pasado de {formatNumber(solar_hitos[0]?.potencia_mw, 0)} MW en {solar_hitos[0]?.año} a **{formatNumber(solar_hitos[1]?.potencia_mw, 0)} MW** en {solar_hitos[1]?.año}, multiplicándose por {formatNumber(solar_hitos[1]?.potencia_mw / solar_hitos[0]?.potencia_mw, 1)}.

```sql solar_hitos
SELECT CAST(año AS INTEGER) AS año, potencia_mw
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica'
  AND año IN ((SELECT min(año) FROM mother.energia_potencia_instalada), (SELECT max(año) FROM mother.energia_potencia_instalada))
ORDER BY año ASC
```

```sql potencia
SELECT
    año,
    tecnologia,
    potencia_mw,
    tipo,
    fuente
FROM mother.energia_potencia_instalada
ORDER BY año ASC, potencia_mw DESC
```

<BarChart
    data={potencia}
    x=año
    y=potencia_mw
    series=tecnologia
    type=grouped
    xFmt='0'
    yAxisTitle="MW instalados"
    title="Potencia instalada por tecnología (MW)"
/>

<DownloadCsvButton data={potencia} filename="spainfacts_potencia_instalada.csv" label="Descargar potencia instalada (CSV)" />

<DownloadCsvButton data={elec} filename="spainfacts_electricidad_anual.csv" label="Descargar cuotas, emisiones y demanda por año (CSV)" />

---

## Fuentes

**Red Eléctrica de España (REE)**, operador del sistema eléctrico, API [REData](https://www.ree.es/es/datos/apidatos):
- Generación anual por tecnología (`generacion/estructura-generacion`) y demanda (`demanda/evolucion`), desde 2007, primer año disponible en la API. Balance medido en barras de central, sistema nacional. Solo años completos.
- Emisiones de CO₂ equivalente de la generación no renovable (`generacion/no-renovables-detalle-emisiones-CO2`); el factor en g/kWh divide esas emisiones entre la generación total.
- Licencia: reutilización de información del sector público / datos abiertos.

**Población media anual:** Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table).

**Potencia instalada:** Eurostat [nrg_inf_epc](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) (capacidad eléctrica neta máxima reportada por España), usada mientras el servicio de potencia instalada de la API de REE no está disponible; la columna `fuente` del CSV indica el origen. En esta estadística el gas natural agrupa ciclos combinados y cogeneración, y la solar FV incluye autoconsumo.

Las emisiones totales del país, por habitante y por sector están en [Emisiones y descarbonización](/energia-clima/emisiones).

<LastRefreshed prefix="Última sincronización de datos" />
