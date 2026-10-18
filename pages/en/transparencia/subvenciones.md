---
title: Public subsidies
description: "How much public money is granted in subsidies in Spain, what percentage is awarded directly or nominatively versus competitive calls, and which administration manages it (BDNS / IGAE)."
i18n_origen: 9dbf4f2110e5
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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

# <span aria-hidden="true">💶</span> Public subsidies

General Subsidies Law 38/2003 establishes **competitive calls** as the ordinary procedure (open calls in which applications are compared and scored using objective criteria). As exceptions, the law allows **nominative subsidies** (with a named beneficiary in the budget) and **direct awards** for reasons of public, social or economic interest. Records from the **National Subsidies Database (BDNS / IGAE)** show what share of funds is distributed through each channel.

<Grid cols=4>
    <KpiCard
        title="Total amount granted"
        value={ultimo[0]?.importe_total_mm}
        formattedValue="{formatNumber(ultimo[0]?.importe_total_mm, 1)} bn €"
        period="registered in BDNS in {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.importe_total_mm}))}
    />
    <KpiCard
        title="Without competitive call"
        value={ultimo[0]?.pct_directa}
        formattedValue="{formatNumber(ultimo[0]?.pct_directa, 1)} %"
        period="direct or nominative award ({ultimo[0]?.anio}) · {formatNumber(ultimo[0]?.directa_mm, 1)} bn €"
        direction="positive-down"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.pct_directa}))}
    />
    <KpiCard
        title="Competitive calls"
        value={ultimo[0]?.concurrencia_mm}
        formattedValue="{formatNumber(ultimo[0]?.concurrencia_mm, 1)} bn €"
        period="open calls in {ultimo[0]?.anio} ({formatNumber(100 - ultimo[0]?.pct_directa, 1)} %)"
        direction="positive-up"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concurrencia_mm}))}
    />
    <KpiCard
        title="Registered grants"
        value={ultimo[0]?.concesiones_miles}
        formattedValue="{formatNumber(ultimo[0]?.concesiones_miles, 0)}k"
        period="individual awards in {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concesiones_miles}))}
    />
</Grid>

## 1. Competitive calls vs. direct awards

Four out of every ten euros in subsidies (**{formatNumber(ultimo[0]?.pct_directa, 1)} %** in {ultimo[0]?.anio}) are awarded through direct or nominative procedures. During the pandemic (2020–2021), extraordinary emergency aid temporarily pushed direct awards above half of the total volume; since then the share of competitive calls has recovered, while total subsidy volume remains nearly twice the 2018 level due to the rollout of European recovery funds (PRTR).

<BarChart
    data={modalidad_serie}
    x=anio
    y=importe_mm
    series=modalidad
    type=stacked
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Billions of €"
    title="Subsidies granted by procedure: competitive calls vs. direct awards (€ bn)"
/>

<LineChart
    data={subvenciones_anual}
    x=anio
    y=pct_directa
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of total volume"
    startingAtZero={false}
    title="Share of subsidy volume granted without a competitive call (%)"
/>

## 2. Breakdown by administration level

The central government accounts for slightly over half of the volume registered in BDNS ({formatNumber(subvenciones_admin[0]?.pct_total, 1)} %) and also shows the highest share of direct and nominative grants ({formatNumber(subvenciones_admin[0]?.pct_directa, 1)} %), followed by the autonomous communities ({formatNumber(subvenciones_admin[1]?.pct_total, 1)} % of the total) and local councils and provincial authorities ({formatNumber(subvenciones_admin[2]?.pct_total, 1)} %).

<DataTable data={subvenciones_admin} search=false>
    <Column id=administracion title="Granting administration" />
    <Column id=importe_mm title="Amount (€ bn)" fmt='0.0' />
    <Column id=pct_total title="% of national total" fmt='0.0"%"' />
    <Column id=pct_directa title="% direct / nominative award" fmt='0.0"%"' />
</DataTable>

---

**Sources and methodology:**
- [National Subsidies Database (BDNS) — Office of the Comptroller General of the State Administration (IGAE)](https://www.infosubvenciones.es/bdnstrans/GE/es/index) and IGAE / AIReF subsidy audit reports (*Spending Review* on public subsidies).
- For subsidies and institutional advertising specifically awarded to press, radio and television, see the [Media & public money section](/en/medios/dinero-publico).
