---
title: Subvenciones
description: "Cuánto dinero público se concede en subvenciones en España, qué porcentaje se adjudica por concesión directa o nominativa frente a concurrencia competitiva y qué administración lo gestiona (BDNS / IGAE)."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql subvenciones_anual
SELECT * FROM (
    VALUES
        (2018, 19.8, 12.9, 6.9, 34.8, 920),
        (2019, 21.4, 13.7, 7.7, 36.0, 985),
        (2020, 31.6, 15.2, 16.4, 51.9, 1480),
        (2021, 35.8, 18.4, 17.4, 48.6, 1620),
        (2022, 38.2, 21.8, 16.4, 42.9, 1540),
        (2023, 39.5, 23.3, 16.2, 41.0, 1590),
        (2024, 37.9, 22.9, 15.0, 39.6, 1510)
) AS t(anio, importe_total_mm, concurrencia_mm, directa_mm, pct_directa, concesiones_miles)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${subvenciones_anual} ORDER BY anio DESC LIMIT 1
```

```sql modalidad_serie
SELECT anio, 'Concurrencia competitiva' AS modalidad, concurrencia_mm AS importe_mm FROM ${subvenciones_anual}
UNION ALL
SELECT anio, 'Concesión directa y nominativa' AS modalidad, directa_mm AS importe_mm FROM ${subvenciones_anual}
ORDER BY anio, modalidad
```

```sql subvenciones_admin
SELECT * FROM (
    VALUES
        ('Administración General del Estado', 19.4, 51.2, 43.5),
        ('Comunidades Autónomas', 14.2, 37.5, 36.8),
        ('Entidades Locales', 4.3, 11.3, 31.2)
) AS t(administracion, importe_mm, pct_total, pct_directa)
ORDER BY importe_mm DESC
```

# <span aria-hidden="true">💶</span> Subvenciones públicas

La Ley 38/2003 General de Subvenciones establece como procedimiento ordinario la **concurrencia competitiva** (convocatoria abierta en la que las solicitudes se comparan y bareman con criterios objetivos). La ley permite como excepción las subvenciones **nominativas** (con beneficiario fijado en los presupuestos) y las de **concesión directa** por razones de interés público, social o económico. Los registros de la **Base de Datos Nacional de Subvenciones (BDNS / IGAE)** permiten medir qué parte de los fondos se reparte por cada vía.

<Grid cols=4>
    <KpiCard
        title="Importe total concedido"
        value={ultimo[0]?.importe_total_mm}
        formattedValue="{formatNumber(ultimo[0]?.importe_total_mm, 1)} mil M€"
        period="registrado en la BDNS en {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.importe_total_mm}))}
    />
    <KpiCard
        title="Sin concurrencia competitiva"
        value={ultimo[0]?.pct_directa}
        formattedValue="{formatNumber(ultimo[0]?.pct_directa, 1)} %"
        period="concesión directa o nominativa ({ultimo[0]?.anio}) · {formatNumber(ultimo[0]?.directa_mm, 1)} mil M€"
        direction="positive-down"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.pct_directa}))}
    />
    <KpiCard
        title="En concurrencia competitiva"
        value={ultimo[0]?.concurrencia_mm}
        formattedValue="{formatNumber(ultimo[0]?.concurrencia_mm, 1)} mil M€"
        period="convocatorias abiertas en {ultimo[0]?.anio} ({formatNumber(100 - ultimo[0]?.pct_directa, 1)} %)"
        direction="positive-up"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concurrencia_mm}))}
    />
    <KpiCard
        title="Concesiones registradas"
        value={ultimo[0]?.concesiones_miles}
        formattedValue="{formatNumber(ultimo[0]?.concesiones_miles, 0)} mil"
        period="resoluciones individuales en {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concesiones_miles}))}
    />
</Grid>

## 1. Concurrencia competitiva frente a concesión directa

Cuatro de cada diez euros en subvenciones (**{formatNumber(ultimo[0]?.pct_directa, 1)} %** en {ultimo[0]?.anio}) se adjudican mediante procedimientos de concesión directa o nominativa. Durante la pandemia (2020–2021), las ayudas extraordinarias de emergencia elevaron temporalmente la vía directa por encima de la mitad del importe total; desde entonces el peso de la concurrencia competitiva se ha recuperado, pero el volumen total de subvenciones sigue siendo casi el doble que en 2018 por el despliegue de los fondos europeos PRTR.

<BarChart
    data={modalidad_serie}
    x=anio
    y=importe_mm
    series=modalidad
    type=stacked
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Miles de millones de €"
    title="Subvenciones concedidas según procedimiento: concurrencia competitiva vs. directa (miles de M€)"
/>

<LineChart
    data={subvenciones_anual}
    x=anio
    y=pct_directa
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del importe total"
    startingAtZero={false}
    title="Porcentaje del importe de subvenciones concedido sin concurrencia competitiva (%)"
/>

## 2. Reparto por nivel de administración

La Administración General del Estado concentra algo más de la mitad del importe registrado en la BDNS ({formatNumber(subvenciones_admin[0]?.pct_total, 1)} %) y presenta también la mayor proporción de concesiones directas y nominativas ({formatNumber(subvenciones_admin[0]?.pct_directa, 1)} %), seguida por las comunidades autónomas ({formatNumber(subvenciones_admin[1]?.pct_total, 1)} % del total) y los ayuntamientos y diputaciones ({formatNumber(subvenciones_admin[2]?.pct_total, 1)} %).

<DataTable data={subvenciones_admin} search=false>
    <Column id=administracion title="Administración concedente" />
    <Column id=importe_mm title="Importe (miles M€)" fmt='0.0' />
    <Column id=pct_total title="% del total nacional" fmt='0.0"%"' />
    <Column id=pct_directa title="% en concesión directa / nominativa" fmt='0.0"%"' />
</DataTable>

---

**Fuentes y metodología:**
- [Base de Datos Nacional de Subvenciones (BDNS) — Intervención General de la Administración del Estado (IGAE)](https://www.infosubvenciones.es/bdnstrans/GE/es/index) y controles de auditoría de subvenciones de la IGAE / AIReF (*Spending Review* de subvenciones públicas).
- Para consultar las subvenciones y publicidad institucional destinadas específicamente a prensa, radio y televisión, visita la sección de [Medios y dinero público](/medios/dinero-publico).
