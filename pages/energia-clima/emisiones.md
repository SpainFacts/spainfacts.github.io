---
title: Emisiones y Descarbonización
description: Inventario oficial de emisiones de gases de efecto invernadero (GEI) en España, desglose por sectores y evolución hacia la neutralidad climática.
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🏭 Emisiones de Gases de Efecto Invernadero en España

España emitió en {emisiones_total_anual[emisiones_total_anual.length - 1]?.año} un total de **{emisiones_total_anual[emisiones_total_anual.length - 1]?.total_mt?.toFixed(1)} Mt de CO₂ equivalente** (inventario oficial, sin contar el sector de usos del suelo, LULUCF). Aunque las emisiones han descendido respecto al pico de 2007, el ritmo de descarbonización sigue siendo insuficiente para cumplir los compromisos del Acuerdo de París y la Ley Europea del Clima (reducción del 55% en 2030 respecto a 1990).

```sql emisiones_total_anual
SELECT
    año,
    sum(millones_toneladas_co2eq) AS total_mt
FROM mother.energia_emisiones_gei
GROUP BY año
ORDER BY año ASC
```

```sql emisiones_por_sector
SELECT
    año,
    sector,
    millones_toneladas_co2eq
FROM mother.energia_emisiones_gei
ORDER BY año ASC, sector ASC
```

---

## Evolución de las Emisiones Totales

```sql evolucion_total
SELECT
    año,
    sum(millones_toneladas_co2eq) AS "Emisiones Totales (Mt CO₂eq)"
FROM mother.energia_emisiones_gei
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
FROM mother.energia_emisiones_gei
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

```sql transporte_hitos
SELECT
    año,
    max(millones_toneladas_co2eq) FILTER (WHERE sector = 'Transporte') AS mt_transporte,
    round(max(porcentaje_total) FILTER (WHERE sector = 'Transporte'), 1) AS pct_transporte,
    max(millones_toneladas_co2eq) FILTER (WHERE sector = 'Generación Eléctrica') AS mt_electrica
FROM mother.energia_emisiones_gei
WHERE año IN ((SELECT min(año) FROM mother.energia_emisiones_gei), (SELECT max(año) FROM mother.energia_emisiones_gei))
GROUP BY año
ORDER BY año ASC
```

El transporte concentra el **{transporte_hitos[1]?.pct_transporte}%** de las emisiones españolas en {transporte_hitos[1]?.año} y no ha logrado reducir su huella respecto a {transporte_hitos[0]?.año}. El auge de la electrificación del parque automovilístico será clave para revertir esta tendencia.

```sql transporte_vs_electrica
SELECT
    e1.año,
    e1.millones_toneladas_co2eq AS "Transporte",
    e2.millones_toneladas_co2eq AS "Generación Eléctrica"
FROM mother.energia_emisiones_gei e1
JOIN mother.energia_emisiones_gei e2
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

> **Lectura clave:** Entre {transporte_hitos[0]?.año} y {transporte_hitos[1]?.año}, las emisiones de la generación eléctrica han variado un **{transporte_hitos.length > 1 ? ((transporte_hitos[1].mt_electrica / transporte_hitos[0].mt_electrica - 1) * 100).toFixed(0) : null}%**, mientras que las del transporte han variado un **{transporte_hitos.length > 1 ? ((transporte_hitos[1].mt_transporte / transporte_hitos[0].mt_transporte - 1) * 100).toFixed(0) : null}%**: el transporte continúa siendo el principal emisor del país.

---

## Composición Sectorial (último año disponible)

```sql composicion_ultimo
SELECT
    año,
    sector,
    millones_toneladas_co2eq,
    porcentaje_total / 100.0 AS porcentaje_total
FROM mother.energia_emisiones_gei
WHERE año = (SELECT max(año) FROM mother.energia_emisiones_gei)
ORDER BY millones_toneladas_co2eq DESC
```

<DataTable data={composicion_ultimo} search=false>
    <Column id=año title="Año" />
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
- Datos descargados de Eurostat [env_air_gge](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table), que publica el inventario de España por categoría CRF. Agrupación en sectores: Generación Eléctrica = 1A1a; Transporte = 1A3 (nacional, sin búnkeres internacionales); Industria y Procesos = 1A1b-c + 1A2 + 1B + 2 (salvo 2F y 2G); Residencial y Comercial = 1A4a-b; Agricultura y Ganadería = 3 + 1A4c; Residuos = 5; Gases Fluorados y Otros = 2F + 2G + 1A5 + 6.

<LastRefreshed prefix="Última sincronización de datos" />
