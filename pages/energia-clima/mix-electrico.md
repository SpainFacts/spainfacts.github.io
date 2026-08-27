---
title: Mix de Generación Eléctrica
description: Análisis en profundidad del mix eléctrico español, despliegue renovable y cierre del carbón.
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# ⚡ Mix de Generación Eléctrica en España

El sistema eléctrico español ha experimentado una transformación radical en la última década. El **carbón** ha pasado de representar casi el 20% de la generación en 2015 a menos del 1% en 2024, sustituido por un despliegue masivo de **energía eólica y solar fotovoltaica**.

```sql mix_completo
SELECT
    año,
    tecnologia,
    tipo_fuente,
    generacion_twh,
    porcentaje_total
FROM clima_energia.mix_electrico
ORDER BY año ASC, tecnologia ASC
```

```sql resumen_anual
SELECT *
FROM clima_energia.resumen_anual_mix
ORDER BY año ASC
```

---

## Generación por Tecnología (TWh)

```sql mix_por_tech
SELECT
    año,
    tecnologia,
    generacion_twh
FROM clima_energia.mix_electrico
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
FROM clima_energia.mix_electrico m1
JOIN clima_energia.mix_electrico m2
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

> **Lectura clave:** En 2020 la solar fotovoltaica superó por primera vez al carbón en generación anual. En 2024 la solar produce **28 veces** más electricidad que el carbón.

---

## Peso Relativo de Cada Tecnología (2024)

```sql mix_2024
SELECT
    tecnologia,
    generacion_twh,
    porcentaje_total
FROM clima_energia.mix_electrico
WHERE año = 2024
ORDER BY generacion_twh DESC
```

<BarChart
    data={mix_2024}
    x=tecnologia
    y=generacion_twh
    yAxisTitle="TWh"
    title="Generación por tecnología en 2024"
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_2024} search=false>
    <Column id=tecnologia title="Tecnología" />
    <Column id=generacion_twh title="Generación (TWh)" fmt="num1" />
    <Column id=porcentaje_total title="% del Total" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
</DataTable>

---

## Potencia Instalada por Tecnología

La capacidad instalada refleja las decisiones de inversión. La solar FV ha pasado de ~4.700 MW en 2018 a casi **29.500 MW** en 2024, multiplicándose por 6 en seis años.

```sql potencia
SELECT
    año,
    tecnologia,
    potencia_mw,
    tipo
FROM clima_energia.potencia_instalada
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
FROM clima_energia.resumen_anual_mix
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

> En **2024**, el **57%** de la electricidad generada en España fue de origen renovable y el **77%** fue libre de emisiones directas (renovable + nuclear).

---

## Fuente Primaria

**Red Eléctrica de España (REE)** – Operador del Sistema Eléctrico Nacional
- Portal de datos: [ree.es/es/datos/generacion](https://www.ree.es/es/datos/generacion)
- Balance medido en barras de central, sistema peninsular y no peninsular.
- Licencia: Reutilización del Sector Público / Datos Abiertos.

<LastRefreshed prefix="Última sincronización de datos" />
