---
title: Emisiones y Descarbonización
description: Inventario oficial de emisiones de gases de efecto invernadero (GEI) en España, desglose por sectores y evolución hacia la neutralidad climática.
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🏭 Emisiones de Gases de Efecto Invernadero en España

España emitió en 2024 un total estimado de **258 Mt de CO₂ equivalente**. Aunque las emisiones han descendido respecto al pico de 2007, el ritmo de descarbonización sigue siendo insuficiente para cumplir los compromisos del Acuerdo de París y la Ley Europea del Clima (reducción del 55% en 2030 respecto a 1990).

```sql emisiones_total_anual
SELECT
    año,
    sum(millones_toneladas_co2eq) AS total_mt
FROM clima_energia.emisiones_gei
GROUP BY año
ORDER BY año ASC
```

```sql emisiones_por_sector
SELECT
    año,
    sector,
    millones_toneladas_co2eq
FROM clima_energia.emisiones_gei
ORDER BY año ASC, sector ASC
```

---

## Evolución de las Emisiones Totales

```sql evolucion_total
SELECT
    año,
    sum(millones_toneladas_co2eq) AS "Emisiones Totales (Mt CO₂eq)"
FROM clima_energia.emisiones_gei
GROUP BY año
ORDER BY año ASC
```

<LineChart
    data={evolucion_total}
    x=año
    y="Emisiones Totales (Mt CO₂eq)"
    yAxisTitle="Mt CO₂eq"
    title="Emisiones brutas totales de GEI en España"
    colorPalette={['#dc2626']}
    labels=true
/>

<DownloadCsvButton data={emisiones_por_sector} filename="spainfacts_emisiones_gei_sectorial.csv" label="Descargar emisiones por sector (CSV)" />

---

## Desglose por Sectores: ¿Quién Emite Más?

```sql sectores_stacked
SELECT
    año,
    sector,
    millones_toneladas_co2eq
FROM clima_energia.emisiones_gei
ORDER BY año ASC, sector ASC
```

<BarChart
    data={sectores_stacked}
    x=año
    y=millones_toneladas_co2eq
    series=sector
    type=stacked
    yAxisTitle="Mt CO₂eq"
    title="Emisiones de GEI por sector (Mt CO₂eq)"
/>

---

## El Transporte: el Sector más Resistente

El transporte concentra más de un **tercio** de las emisiones españolas en 2024, y apenas ha reducido su huella respecto a 2015. El auge de la electrificación del parque automovilístico será clave para revertir esta tendencia.

```sql transporte_vs_electrica
SELECT
    e1.año,
    e1.millones_toneladas_co2eq AS "Transporte",
    e2.millones_toneladas_co2eq AS "Generación Eléctrica"
FROM clima_energia.emisiones_gei e1
JOIN clima_energia.emisiones_gei e2
    ON e1.año = e2.año
WHERE e1.sector = 'Transporte'
  AND e2.sector = 'Generación Eléctrica'
ORDER BY e1.año ASC
```

<LineChart
    data={transporte_vs_electrica}
    x=año
    y={["Transporte", "Generación Eléctrica"]}
    yAxisTitle="Mt CO₂eq"
    title="Transporte vs. Generación Eléctrica: trayectorias divergentes"
    colorPalette={['#f97316', '#16a34a']}
    labels=true
/>

> **Lectura clave:** Mientras la generación eléctrica ha reducido sus emisiones un **70%** entre 2015 y 2024, el transporte solo las ha reducido un **10%**, y continúa siendo el principal emisor neto del país.

---

## Composición Sectorial en 2024

```sql composicion_2024
SELECT
    sector,
    millones_toneladas_co2eq,
    porcentaje_total
FROM clima_energia.emisiones_gei
WHERE año = 2024
ORDER BY millones_toneladas_co2eq DESC
```

<DataTable data={composicion_2024} search=false>
    <Column id=sector title="Sector" />
    <Column id=millones_toneladas_co2eq title="Mt CO₂eq" fmt="num1" />
    <Column id=porcentaje_total title="% del Total" fmt="pct1" contentType=colorscale colorScale={['#fef3c7', '#dc2626']} />
</DataTable>

---

## Contexto: Objetivos Europeos de Reducción

| Hito | Objetivo | Referencia |
|:---|:---|:---|
| **2030** | -55% respecto a 1990 | Ley Europea del Clima (Reglamento UE 2021/1119) |
| **2050** | Neutralidad climática (netas = 0) | Green Deal / PNIEC España |

> España sigue el marco regulatorio del **Plan Nacional Integrado de Energía y Clima (PNIEC)** 2021-2030, que prevé el cierre total del carbón, la electrificación del transporte y la rehabilitación energética del parque de viviendas.

---

## Fuente Primaria

**Ministerio para la Transición Ecológica y el Reto Demográfico (MITECO)**
- Inventario Nacional de Emisiones GEI: [MITECO – Inventario](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html)
- Metodología: Directrices del IPCC 2006 para inventarios nacionales de GEI.
- Reporte a la Convención Marco de Naciones Unidas sobre el Cambio Climático (CMNUCC).

<LastRefreshed prefix="Última sincronización de datos" />
