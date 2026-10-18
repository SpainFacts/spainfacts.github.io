---
title: Public procurement
description: "Public procurement volume in Spain, single-bidder tenders, negotiated procedures without prior publication, SME share and breakdown by administration level according to OIReScon."
i18n_origen: 11662929b821
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql licitacion_anual
SELECT * FROM (
    VALUES
        (2019, 134.2, 58.4, 31.0, 4.8, 63.2, 742.0),
        (2020, 118.5, 51.2, 33.0, 8.2, 62.1, 615.0),
        (2021, 152.8, 72.6, 32.0, 3.6, 64.5, 698.0),
        (2022, 169.4, 83.9, 34.0, 2.9, 64.8, 754.0),
        (2023, 181.6, 91.5, 35.0, 2.6, 65.1, 790.0),
        (2024, 186.3, 95.8, 34.5, 2.4, 65.4, 812.0)
) AS t(anio, contratos_miles, importe_mm_eur, pct_un_licitador, pct_sin_publicidad, pymes_pct, contratos_menores_miles)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${licitacion_anual} ORDER BY anio DESC LIMIT 1
```

```sql competencia_serie
SELECT anio, 'Un solo licitador (%)' AS indicador, pct_un_licitador AS pct FROM ${licitacion_anual}
UNION ALL
SELECT anio, 'Negociado sin publicidad (%)' AS indicador, pct_sin_publicidad AS pct FROM ${licitacion_anual}
ORDER BY anio, indicador
```

```sql por_administracion
SELECT * FROM (
    VALUES
        ('Comunidades Autónomas', 40.8, 36.5, 39.1, 108),
        ('Entidades Locales (Ayuntamientos y Diputaciones)', 34.5, 48.2, 33.1, 96),
        ('Administración General del Estado', 24.7, 15.3, 23.6, 114)
) AS t(administracion, pct_importe, pct_contratos, importe_mm_eur, plazo_medio_dias)
ORDER BY pct_importe DESC
```

# <span aria-hidden="true">📑</span> Public procurement

Public procurement accounts for nearly one in every ten euros of Spain's GDP. The **Independent Office for Regulation and Supervision of Procurement (OIReScon)** and the **European Commission's** Single Market Scoreboard assess actual competition in public tenders each year: total volume awarded, how many contracts attract **only a single bidder** (a low-competition warning), how many are awarded **without prior publication** and the weight of **minor contracts**.

<Grid cols=4>
    <KpiCard
        title="Awarded volume"
        value={ultimo[0]?.importe_mm_eur}
        formattedValue="{formatNumber(ultimo[0]?.importe_mm_eur, 1)} bn €"
        period="excl. VAT in {ultimo[0]?.anio} · {formatNumber(ultimo[0]?.contratos_miles, 1)}k ordinary contracts"
        direction="neutral"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.importe_mm_eur}))}
    />
    <KpiCard
        title="Single bidder"
        value={ultimo[0]?.pct_un_licitador}
        formattedValue="{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %"
        period="of tenders in {ultimo[0]?.anio}"
        direction="positive-down"
        source="OIReScon / European Commission"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_un_licitador}))}
    />
    <KpiCard
        title="Without prior publication"
        value={ultimo[0]?.pct_sin_publicidad}
        formattedValue="{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %"
        period="negotiated without publicity ({ultimo[0]?.anio})"
        direction="positive-down"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_sin_publicidad}))}
    />
    <KpiCard
        title="Awarded to SMEs"
        value={ultimo[0]?.pymes_pct}
        formattedValue="{formatNumber(ultimo[0]?.pymes_pct, 1)} %"
        period="of contracts awarded in {ultimo[0]?.anio}"
        direction="positive-up"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pymes_pct}))}
    />
</Grid>

## 1. Annual public procurement volume

Following the 2020 slowdown and subsequent rollout of European Recovery Plan funds, the annual volume awarded across all public administrations (excluding VAT) reached **{formatNumber(ultimo[0]?.importe_mm_eur, 1)} billion euros** in {ultimo[0]?.anio}, spread across {formatNumber(ultimo[0]?.contratos_miles, 1)} thousand ordinary contracts and over {formatNumber(ultimo[0]?.contratos_menores_miles, 0)} thousand registered minor contracts.

<BarChart
    data={licitacion_anual}
    x=anio
    y=importe_mm_eur
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Billions of € (excl. VAT)"
    title="Annual volume awarded in ordinary public procurement (€ bn)"
/>

## 2. Effective competition: one-third of tenders receive a single bid

Public Sector Contracts Law 9/2017 sharply curtailed the use of **negotiated procedures without prior publication** (down to **{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %** in {ultimo[0]?.anio}, after the temporary spike from emergency health procurement in 2020). However, the European Commission's primary warning indicator —the share of open tenders receiving **only a single bid**— remains around **{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %**.

<LineChart
    data={competencia_serie}
    x=anio
    y=pct
    series=indicador
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of contracts"
    title="Single-bidder tenders and negotiated procedures without publicity (%)"
/>

## 3. Who procures: regions and local councils account for three-quarters

Autonomous communities ({formatNumber(por_administracion[0]?.pct_importe, 1)} % of volume) and local authorities ({formatNumber(por_administracion[1]?.pct_importe, 1)} %) manage three out of every four euros tendered in Spain, while the central government represents {formatNumber(por_administracion[2]?.pct_importe, 1)} %.

<BarChart
    data={por_administracion}
    x=administracion
    y=pct_importe
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% of awarded volume"
    title="Share of awarded volume by administration level (%)"
/>

<DataTable data={por_administracion} search=false>
    <Column id=administracion title="Administration" />
    <Column id=importe_mm_eur title="Volume (€ bn)" fmt='0.0' />
    <Column id=pct_importe title="% of volume" fmt='0.0"%"' />
    <Column id=pct_contratos title="% of contracts" fmt='0.0"%"' />
    <Column id=plazo_medio_dias title="Avg. award time (days)" fmt='0' />
</DataTable>

---

**Sources and methodology:**
- [Independent Office for Regulation and Supervision of Procurement (OIReScon)](https://www.hacienda.gob.es/es-ES/Oirescon/Paginas/ias.aspx) — *Annual Public Procurement Supervision Report in Spain* (national aggregate of the Public Sector Procurement Platform and regional platforms).
- [European Commission — Single Market Scoreboard (Public Procurement)](https://single-market-scoreboard.ec.europa.eu/policy_areas/public-procurement_en).
