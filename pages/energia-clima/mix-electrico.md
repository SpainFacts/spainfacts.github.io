---
title: Mix de Generación Eléctrica
description: Análisis en profundidad del mix eléctrico español, despliegue renovable y cierre del carbón.
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# ⚡ Mix de Generación Eléctrica en España

El sistema eléctrico español ha experimentado una transformación radical en la última década. El **carbón** ha pasado de representar el {carbon_hitos[0]?.pct_carbon}% de la generación en {carbon_hitos[0]?.año} al {carbon_hitos[1]?.pct_carbon}% en {carbon_hitos[1]?.año}, sustituido por un despliegue masivo de **energía eólica y solar fotovoltaica**.

```sql carbon_hitos
SELECT año, round(porcentaje_total, 1) AS pct_carbon
FROM mother.energia_mix_electrico
WHERE tecnologia = 'Carbón'
  AND año IN ((SELECT min(año) FROM mother.energia_mix_electrico), (SELECT max(año) FROM mother.energia_mix_electrico))
ORDER BY año ASC
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

```sql resumen_anual
SELECT *
FROM mother.energia_resumen_anual_mix
ORDER BY año ASC
```

---

## Generación por Tecnología (TWh)

```sql mix_por_tech
SELECT
    año,
    tecnologia,
    generacion_twh
FROM mother.energia_mix_electrico
WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica', 'Hidroeléctrica', 'Nuclear', 'Ciclos Combinados (Gas)', 'Carbón')
ORDER BY año ASC
```

<AreaChart
    data={mix_por_tech}
    x=año
    y=generacion_twh
    series=tecnologia
    yAxisTitle="TWh"
    title="Generación neta por tecnología (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

<DownloadCsvButton data={mix_completo} filename="spainfacts_mix_electrico_detalle.csv" label="Descargar datos completos del mix (CSV)" />

---

## El Desplome del Carbón y el Auge de la Solar FV

Dos de las tendencias más marcadas del sistema eléctrico español:

```sql carbon_vs_solar
SELECT
    m1.año,
    m1.generacion_twh AS "Carbón (TWh)",
    m2.generacion_twh AS "Solar FV (TWh)"
FROM mother.energia_mix_electrico m1
JOIN mother.energia_mix_electrico m2
    ON m1.año = m2.año
WHERE m1.tecnologia = 'Carbón'
  AND m2.tecnologia = 'Solar Fotovoltaica'
ORDER BY m1.año ASC
```

<LineChart
    data={carbon_vs_solar}
    x=año
    y={["Carbón (TWh)", "Solar FV (TWh)"]}
    yAxisTitle="TWh"
    title="El cruce histórico: Carbón vs. Solar Fotovoltaica"
    colorPalette={['#6b7280', '#facc15']}
/>

```sql cruce_solar_carbon
WITH s AS (
    SELECT
        año,
        sum(generacion_twh) FILTER (WHERE tecnologia = 'Solar Fotovoltaica') AS solar,
        sum(generacion_twh) FILTER (WHERE tecnologia = 'Carbón') AS carbon
    FROM mother.energia_mix_electrico
    GROUP BY año
)
SELECT
    min(año) FILTER (WHERE solar > carbon) AS primer_anio,
    max(año) AS ultimo_anio,
    round(arg_max(solar / nullif(carbon, 0), año), 0) AS ratio_ultimo
FROM s
```

> **Lectura clave:** En {cruce_solar_carbon[0]?.primer_anio} la solar fotovoltaica superó por primera vez al carbón en generación anual. En {cruce_solar_carbon[0]?.ultimo_anio} la solar produce **{cruce_solar_carbon[0]?.ratio_ultimo} veces** más electricidad que el carbón.

---

## Peso Relativo de Cada Tecnología (último año completo)

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
    y=generacion_twh
    yAxisTitle="TWh"
    title={`Generación por tecnología en ${mix_ultimo[0]?.año ?? ''}`}
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnología" />
    <Column id=generacion_twh title="Generación (TWh)" fmt="num1" />
    <Column id=porcentaje_total title="% del Total" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
</DataTable>

---

## Potencia Instalada por Tecnología

La capacidad instalada refleja las decisiones de inversión. La solar FV ha pasado de {solar_hitos[0]?.potencia_mw?.toLocaleString('es-ES')} MW en {solar_hitos[0]?.año} a **{solar_hitos[1]?.potencia_mw?.toLocaleString('es-ES')} MW** en {solar_hitos[1]?.año}, multiplicándose por {solar_hitos.length > 1 ? (solar_hitos[1].potencia_mw / solar_hitos[0].potencia_mw).toFixed(1) : null}.

```sql solar_hitos
SELECT año, potencia_mw
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
    yAxisTitle="MW instalados"
    title="Potencia instalada por tecnología (MW)"
/>

<DownloadCsvButton data={potencia} filename="spainfacts_potencia_instalada.csv" label="Descargar potencia instalada (CSV)" />

---

## Evolución de la Cuota Renovable

```sql cuota
SELECT
    año,
    cuota_renovable_pct AS "% Renovable",
    cuota_libre_emisiones_pct AS "% Libre de emisiones"
FROM mother.energia_resumen_anual_mix
ORDER BY año ASC
```

<LineChart
    data={cuota}
    x=año
    y={["% Renovable", "% Libre de emisiones"]}
    yAxisTitle="%"
    title="Cuota de generación limpia"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=30
    yMax=80
    labels=true
/>

> En **{resumen_anual[resumen_anual.length - 1]?.año}**, el **{resumen_anual[resumen_anual.length - 1]?.cuota_renovable_pct?.toFixed(1)}%** de la electricidad generada en España fue de origen renovable y el **{resumen_anual[resumen_anual.length - 1]?.cuota_libre_emisiones_pct?.toFixed(1)}%** fue libre de emisiones directas (renovable + nuclear).

---

## Fuente Primaria

**Red Eléctrica de España (REE)** – Operador del Sistema Eléctrico Nacional
- Portal de datos: [ree.es/es/datos/generacion](https://www.ree.es/es/datos/generacion) (API REData, generación y demanda anual)
- Balance medido en barras de central, sistema nacional (peninsular y no peninsular). Solo años completos.
- Licencia: Reutilización del Sector Público / Datos Abiertos.

**Potencia instalada:** Eurostat [nrg_inf_epc](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) (capacidad eléctrica neta máxima reportada por España), usada mientras el servicio de potencia instalada de la API de REE no está disponible; la columna `fuente` del CSV indica el origen. En esta estadística el gas natural agrupa ciclos combinados y cogeneración, y la solar FV incluye autoconsumo.

<LastRefreshed prefix="Última sincronización de datos" />
