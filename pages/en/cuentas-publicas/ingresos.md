---
description: "Where public money comes from: taxes and social contributions in Spain, per inhabitant, adjusted for inflation and as a percentage of GDP."
title: Public Revenue and Tax Collection
i18n_origen: 41be22719404
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
</script>

# Where do Spain's public resources come from?

The Spanish public sector is financed mainly through three channels: **social contributions** paid by workers and employers, **direct taxes** on income and profits (personal income tax, IRPF, and corporation tax) and **indirect taxes** on consumption and production (VAT and excise duties).

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql ingresos_hab
-- Ingresos por habitante en euros constantes (ya calculados en la tabla)
SELECT
    i.anio,
    i.categoria,
    i.tipo_ingreso,
    i.millones_euros,
    i.porcentaje_pib,
    i.porcentaje_ingreso_total,
    i.ingreso_eur_hab_real AS eur_hab_real
FROM mother.cuentas_ingresos i
WHERE i.ingreso_eur_hab_real IS NOT NULL
```

```sql ultimos_ingresos_totales
SELECT
    anio,
    sum(millones_euros) AS total_ingresos,
    sum(eur_hab_real) AS total_hab_real,
    sum(porcentaje_pib) AS total_pib
FROM ${ingresos_hab}
WHERE anio = (SELECT max(anio) FROM mother.cuentas_ingresos)
GROUP BY anio
```

```sql resumen_tipos
SELECT
    sum(CASE WHEN tipo_ingreso = 'Cotizaciones' THEN porcentaje_ingreso_total END) AS cot_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Directos' THEN porcentaje_ingreso_total END) AS dir_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Indirectos' THEN porcentaje_ingreso_total END) AS ind_pct,
    sum(CASE WHEN tipo_ingreso = 'No Tributarios' THEN porcentaje_ingreso_total END) AS notrib_pct,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN millones_euros END) AS cot_mio,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN eur_hab_real END) AS cot_hab,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN millones_euros END) AS irpf_mio,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN eur_hab_real END) AS irpf_hab,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN porcentaje_ingreso_total END) AS irpf_pct,
    max(CASE WHEN categoria = 'IVA' THEN millones_euros END) AS iva_mio,
    max(CASE WHEN categoria = 'IVA' THEN eur_hab_real END) AS iva_hab,
    max(CASE WHEN categoria = 'IVA' THEN porcentaje_ingreso_total END) AS iva_pct
FROM ${ingresos_hab}
WHERE anio = (SELECT max(anio) FROM mother.cuentas_ingresos)
```

```sql ingresos_por_categoria_ultimo
SELECT
    categoria,
    tipo_ingreso,
    eur_hab_real,
    millones_euros,
    porcentaje_pib,
    porcentaje_ingreso_total
FROM ${ingresos_hab}
WHERE anio = (SELECT max(anio) FROM mother.cuentas_ingresos)
ORDER BY millones_euros DESC
```

```sql serie_ingresos_categoria
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    anio AS año,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
ORDER BY año ASC, eur_hab_real DESC
```

```sql serie_ingresos_tipo
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    anio AS año,
    tipo_ingreso,
    sum(eur_hab_real) AS eur_hab_real
FROM ${ingresos_hab}
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_ingresos_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    anio,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
WHERE categoria IN ('Cotizaciones Sociales', 'IRPF y Patrimonio', 'IVA')
  AND eur_hab_real IS NOT NULL
ORDER BY anio
```

<Grid cols=3>
    <KpiCard
        title="Social Contributions"
        value={resumen_tipos[0]?.cot_hab}
        formattedValue="€{formatNumber(resumen_tipos[0]?.cot_hab, 0)}"
        unit="/ inhab."
        period="€{formatNumber(resumen_tipos[0]?.cot_mio / 1000, 1)}bn in total · {formatNumber(resumen_tipos[0]?.cot_pct, 1)}% of revenue · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'Cotizaciones Sociales').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Personal Income Tax (IRPF) and Wealth Tax"
        value={resumen_tipos[0]?.irpf_hab}
        formattedValue="€{formatNumber(resumen_tipos[0]?.irpf_hab, 0)}"
        unit="/ inhab."
        period="€{formatNumber(resumen_tipos[0]?.irpf_mio / 1000, 1)}bn in total · {formatNumber(resumen_tipos[0]?.irpf_pct, 1)}% of revenue · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IRPF y Patrimonio').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="VAT (Consumption)"
        value={resumen_tipos[0]?.iva_hab}
        formattedValue="€{formatNumber(resumen_tipos[0]?.iva_hab, 0)}"
        unit="/ inhab."
        period="€{formatNumber(resumen_tipos[0]?.iva_mio / 1000, 1)}bn in total · {formatNumber(resumen_tipos[0]?.iva_pct, 1)}% of revenue · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IVA').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">A principle of this website: amounts are shown <b>per inhabitant</b> and <b>adjusted for inflation</b>, in {base_deflactor[0]?.anio_base} euros using the INE's annual average CPI, so that figures from different years are comparable. Totals in current euros appear as secondary figures; percentages (of revenue or of GDP) need no adjustment.</p>

---

## 1. Composition of Public Revenue in Spain ({ultimos_ingresos_totales[0].anio})

In {ultimos_ingresos_totales[0]?.anio}, general government revenue as a whole reached **€{formatNumber(ultimos_ingresos_totales[0]?.total_hab_real, 0)} per inhabitant** (in {base_deflactor[0]?.anio_base} euros; €{formatNumber(ultimos_ingresos_totales[0]?.total_ingresos / 1000, 1)}bn in total, {formatNumber(ultimos_ingresos_totales[0]?.total_pib, 1)}% of GDP).

<BarChart
    data={ingresos_por_categoria_ultimo}
    x=categoria
    y=eur_hab_real
    yAxisTitle="Euros per inhabitant ({base_deflactor[0]?.anio_base} euros)"
    yFmt=num0
    title="Revenue per inhabitant by revenue category ({ultimos_ingresos_totales[0]?.anio}, {base_deflactor[0]?.anio_base} euros)"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_ultimo} title="Revenue Breakdown ({ultimos_ingresos_totales[0].anio})">
    <Column id=categoria title="Revenue Category" />
    <Column id=tipo_ingreso title="Type of Levy" />
    <Column id=eur_hab_real title="Per inhabitant" fmt='#,##0 €' />
    <Column id=porcentaje_ingreso_total title="% of Total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% of GDP" fmt='0.0"%"' />
    <Column id=millones_euros title="Total collected (current € million)" fmt='#,##0' />
</DataTable>

---

## 2. Historical Trends in Revenue by Type of Levy

Revenue per inhabitant from each type, in {base_deflactor[0]?.anio_base} euros (adjusted for inflation), since 1996, the first year with annual CPI available:

<AreaChart
    data={serie_ingresos_tipo}
    x=año
    y=eur_hab_real
    series=tipo_ingreso
    yAxisTitle="Euros per inhabitant ({base_deflactor[0]?.anio_base} euros)"
    yFmt=num0
    title="Public revenue per inhabitant by type of levy ({base_deflactor[0]?.anio_base} euros, adjusted for inflation)"
/>

---

## 3. How is the tax burden distributed?

- **Social Security Contributions ({formatNumber(resumen_tipos[0].cot_pct, 1)}%):** The main source of public revenue, used to sustain contributory pensions and unemployment benefits.
- **Direct Taxes ({formatNumber(resumen_tipos[0].dir_pct, 1)}%):** Levied directly on citizens' income (IRPF), the profits declared by companies, wealth and inheritances.
- **Indirect Taxes ({formatNumber(resumen_tipos[0].ind_pct, 1)}%):** Levied on general consumption (VAT) and on specific products such as fuel, tobacco, alcohol and electricity (excise duties), plus other taxes on production.
- **Non-Tax Revenue and EU Funds ({formatNumber(resumen_tipos[0].notrib_pct, 1)}%):** Sales and fees for public services, property income (interest, dividends) and transfers received, including the Next Generation EU funds.

<small>Methodology: taxes and contributions come from Eurostat (gov_10a_taxag) and total revenue from gov_10a_main. The categories "Other taxes" and "Non-Tax Revenue and EU Funds" are calculated as residuals, so that the sum matches official total revenue.</small>

---

## Official Sources
- **[Eurostat - Taxes and social contributions by type (gov_10a_taxag)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_taxag):** Harmonised revenue under ESA 2010.
- **[Eurostat - General government accounts (gov_10a_main)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main):** Total general government revenue.
- **[Spanish Tax Agency (AEAT)](https://sede.agenciatributaria.gob.es/Sede/estadisticas/recaudacion-tributaria.html):** Annual and Monthly Tax Collection Reports.
- **[Intervención General de la Administración del Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Economic Accounts and National Accounts of the Public Sector.
