---
title: Foreign trade
description: "Spain's exports and imports of goods and services: share of GDP, external balance and real change per inhabitant."
i18n_origen: d44a780dbaed
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql comercio_trim
SELECT
    trimestre,
    CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo,
    max(CASE WHEN componente = 'P6' THEN pct_pib END) AS export_pct,
    max(CASE WHEN componente = 'P7' THEN pct_pib END) AS import_pct,
    max(CASE WHEN componente = 'P6' THEN pct_pib END) - max(CASE WHEN componente = 'P7' THEN pct_pib END) AS saldo_pct,
    max(CASE WHEN componente = 'P6' THEN interanual END) AS export_interanual,
    max(CASE WHEN componente = 'P7' THEN interanual END) AS import_interanual,
    max(CASE WHEN componente = 'P6' THEN por_habitante_real END) AS export_hab,
    max(CASE WHEN componente = 'P7' THEN por_habitante_real END) AS import_hab,
    max(CASE WHEN componente = 'P6' THEN nominal_meur END) AS export_meur,
    max(CASE WHEN componente = 'P7' THEN nominal_meur END) AS import_meur,
    max(anio_base) AS anio_base
FROM mother.economia_pib_trimestral
WHERE componente IN ('P6', 'P7')
GROUP BY trimestre, anio, trim
ORDER BY trimestre
```

```sql comercio_largo
SELECT trimestre, CASE componente WHEN 'P6' THEN 'Exportaciones' ELSE 'Importaciones' END AS flujo, pct_pib, por_habitante_real AS euros_hab, interanual
FROM mother.economia_pib_trimestral
WHERE componente IN ('P6', 'P7')
ORDER BY trimestre, flujo
```

```sql saldo_anual
SELECT
    anio,
    100 * (sum(CASE WHEN componente = 'P6' THEN nominal_meur END) - sum(CASE WHEN componente = 'P7' THEN nominal_meur END))
        / sum(CASE WHEN componente = 'B1GQ' THEN nominal_meur END) AS saldo_pct,
    100 * sum(CASE WHEN componente = 'P6' THEN nominal_meur END) / sum(CASE WHEN componente = 'B1GQ' THEN nominal_meur END) AS export_pct,
    CASE WHEN (sum(CASE WHEN componente = 'P6' THEN nominal_meur END) - sum(CASE WHEN componente = 'P7' THEN nominal_meur END)) >= 0
         THEN 'Superávit' ELSE 'Déficit' END AS signo
FROM mother.economia_pib_trimestral
WHERE componente IN ('P6', 'P7', 'B1GQ')
GROUP BY anio
HAVING count(*) = 12
ORDER BY anio
```

```sql hitos_comercio
SELECT
    max(CASE WHEN anio = 1995 THEN export_pct END) AS exp1995,
    max(CASE WHEN anio = 2007 THEN saldo_pct END) AS saldo2007,
    max(export_pct) FILTER (WHERE anio = (SELECT max(anio) FROM ${saldo_anual})) AS exp_ult,
    max(saldo_pct) FILTER (WHERE anio = (SELECT max(anio) FROM ${saldo_anual})) AS saldo_ult,
    min(anio) FILTER (WHERE saldo_pct >= 0 AND anio > 2008) AS primer_superavit,
    max(anio) AS anio_ult
FROM ${saldo_anual}
```

# 🚢 Foreign trade

What Spain sells to the rest of the world (exports) and what it buys abroad (imports), **of both goods and services**: spending by foreign tourists counts as an export. It is measured as a share of GDP, so that it does not grow merely because of inflation or the size of the economy.

<Grid cols=4>
    <KpiCard
        title="Exports"
        value={comercio_trim.slice(-1)[0]?.export_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_pct, 1)}% of GDP"
        period="{comercio_trim.slice(-1)[0]?.periodo} · €{formatNumber(comercio_trim.slice(-1)[0]?.export_meur / 1000, 0)}bn in the quarter"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => d.export_pct)}
    />
    <KpiCard
        title="Imports"
        value={comercio_trim.slice(-1)[0]?.import_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.import_pct, 1)}% of GDP"
        period="{comercio_trim.slice(-1)[0]?.periodo} · €{formatNumber(comercio_trim.slice(-1)[0]?.import_meur / 1000, 0)}bn in the quarter"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => d.import_pct)}
    />
    <KpiCard
        title="External balance"
        value={saldo_anual.slice(-1)[0]?.saldo_pct}
        formattedValue="{saldo_anual.slice(-1)[0]?.saldo_pct >= 0 ? '+' : ''}{formatNumber(saldo_anual.slice(-1)[0]?.saldo_pct, 1)}% of GDP"
        period="exports minus imports in {saldo_anual.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={saldo_anual.map(d => d.saldo_pct)}
    />
    <KpiCard
        title="Real exports"
        value={comercio_trim.slice(-1)[0]?.export_interanual}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_interanual, 1)}%"
        period="year-on-year change in volume, {comercio_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-24).map(d => d.export_interanual)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('exportaciones_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'exportaciones_pib')} />


## Share of GDP

Exports rose from {formatNumber(hitos_comercio[0]?.exp1995, 1)}% of GDP in 1995 to {formatNumber(hitos_comercio[0]?.exp_ult, 1)}% in {hitos_comercio[0]?.anio_ult}. The big leap came after the 2008 crisis: from {formatNumber(saldo_anual.find(d => d.anio === 2009)?.export_pct, 0)}% in 2009 to {formatNumber(saldo_anual.find(d => d.anio === 2013)?.export_pct, 0)}% in 2013, while domestic demand was falling.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=pct_pib
    series=flujo
    yAxisTitle="% of GDP"
    yFmt='0.0"%"'
    startingAtZero={false}
    title="Exports and imports of goods and services (% of GDP)"
/>

## External balance

In 2007 Spain bought far more abroad than it sold: the deficit reached {formatNumber(-hitos_comercio[0]?.saldo2007, 1)}% of GDP. Since {hitos_comercio[0]?.primer_superavit} the balance has been positive every year.

<BarChart
    data={saldo_anual}
    x=anio
    y=saldo_pct
    series=signo
    colorPalette={['#dc2626', '#16a34a']}
    xFmt='0'
    yAxisTitle="% of GDP"
    yFmt='0.0"%"'
    title="External balance of goods and services (% of GDP)"
/>

## Real change per inhabitant

Exports and imports in constant {comercio_trim[0]?.anio_base} euros per inhabitant, at an annual rate (the quarter multiplied by four): this shows how much trade is really growing, stripping out inflation and population growth.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=euros_hab
    series=flujo
    yAxisTitle="€ per inhabitant (real)"
    yFmt='#,##0" €"'
    title="Foreign trade per inhabitant, {comercio_trim[0]?.anio_base} euros at an annual rate"
/>

---

**Source:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table): exports (P6) and imports (P7) of goods and services from the quarterly national accounts, seasonally adjusted. Shares of GDP at current prices.
