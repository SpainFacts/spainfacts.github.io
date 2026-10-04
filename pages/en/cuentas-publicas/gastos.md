---
description: "What Spain spends public money on: spending by function (pensions, health, education...), per inhabitant and adjusted for inflation, and its weight in GDP."
title: Public Spending and Where the Budget Goes
i18n_origen: 21ec6e00fe32
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql gastos_ultimo
SELECT
    g.anio,
    g.funcion_cofog,
    g.categoria_macro,
    g.millones_euros,
    g.porcentaje_gasto_total,
    g.porcentaje_pib,
    g.gasto_eur_hab_real AS gasto_hab_real
FROM mother.cuentas_gastos g
WHERE g.anio = (SELECT max(anio) FROM mother.cuentas_gastos)
ORDER BY g.millones_euros DESC
```

```sql resumen_gastos
-- Por habitante en euros constantes (gasto_eur_hab_real, ya calculado en la tabla)
SELECT
    g.anio,
    sum(g.millones_euros) AS total_mio,
    sum(g.gasto_eur_hab_real) AS total_hab_real,
    sum(g.porcentaje_pib) AS total_pib,
    sum(CASE WHEN g.categoria_macro = 'Gasto Social' THEN g.porcentaje_gasto_total END) AS social_pct,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.millones_euros END) AS pens_mio,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.gasto_eur_hab_real END) AS pens_hab,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.porcentaje_gasto_total END) AS pens_pct,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.millones_euros END) AS san_mio,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.gasto_eur_hab_real END) AS san_hab,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.porcentaje_gasto_total END) AS san_pct,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.millones_euros END) AS edu_mio,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.gasto_eur_hab_real END) AS edu_hab,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.porcentaje_gasto_total END) AS edu_pct,
    max(CASE WHEN g.funcion_cofog = 'Intereses de la Deuda' THEN g.porcentaje_gasto_total END) AS int_pct,
    max(CASE WHEN g.funcion_cofog = 'Asuntos Económicos y Transporte' THEN g.porcentaje_gasto_total END) AS eco_pct,
    max(CASE WHEN g.funcion_cofog = 'Orden Público y Seguridad' THEN g.porcentaje_gasto_total END) AS seg_pct,
    max(CASE WHEN g.funcion_cofog = 'Defensa' THEN g.porcentaje_gasto_total END) AS def_pct
FROM mother.cuentas_gastos g
WHERE g.anio = (SELECT max(anio) FROM mother.cuentas_gastos)
GROUP BY g.anio
```

```sql poblacion_ultimo
SELECT poblacion / 1e6 AS poblacion_m
FROM mother.cuentas_balance_anual
WHERE anio = (SELECT max(anio) FROM mother.cuentas_gastos)
```

```sql serie_gastos_macro
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    g.anio AS año,
    g.categoria_macro,
    sum(g.gasto_eur_hab_real) AS eur_hab_real
FROM mother.cuentas_gastos g
WHERE g.gasto_eur_hab_real IS NOT NULL
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_gastos_funcion
SELECT
    g.anio AS año,
    g.funcion_cofog,
    g.gasto_eur_hab_real AS eur_hab_real
FROM mother.cuentas_gastos g
WHERE g.gasto_eur_hab_real IS NOT NULL
ORDER BY 1 ASC, 3 DESC
```

```sql serie_gastos_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    año AS anio,
    funcion_cofog,
    eur_hab_real
FROM ${serie_gastos_funcion}
WHERE funcion_cofog IN ('Protección Social y Pensiones', 'Sanidad Pública', 'Educación')
  AND eur_hab_real IS NOT NULL
ORDER BY anio
```

# What does the State spend on, and how much does it cost per citizen?

Consolidated public spending in Spain reached **€{formatNumber(resumen_gastos[0]?.total_hab_real, 0)} per inhabitant** in {resumen_gastos[0]?.anio} (€{formatNumber(resumen_gastos[0]?.total_mio / 1000, 1)}bn in total, {formatNumber(resumen_gastos[0]?.total_pib, 1)}% of GDP). Most of the budget goes to the functions of the **welfare state**: social protection and pensions, health and education account for **{formatNumber(resumen_gastos[0].social_pct, 1)}% of all public spending**.

<Grid cols=3>
    <KpiCard
        title="Pensions and Social Protection"
        value={resumen_gastos[0]?.pens_hab}
        formattedValue="€{formatNumber(resumen_gastos[0]?.pens_hab, 0)}"
        unit="/ inhab."
        period="€{formatNumber(resumen_gastos[0]?.pens_mio / 1000, 1)}bn in total · {formatNumber(resumen_gastos[0]?.pens_pct, 1)}% of spending · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF10)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Protección Social y Pensiones').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Public Healthcare"
        value={resumen_gastos[0]?.san_hab}
        formattedValue="€{formatNumber(resumen_gastos[0]?.san_hab, 0)}"
        unit="/ inhab."
        period="€{formatNumber(resumen_gastos[0]?.san_mio / 1000, 1)}bn in total · {formatNumber(resumen_gastos[0]?.san_pct, 1)}% of spending · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF07)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Sanidad Pública').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Education"
        value={resumen_gastos[0]?.edu_hab}
        formattedValue="€{formatNumber(resumen_gastos[0]?.edu_hab, 0)}"
        unit="/ inhab."
        period="€{formatNumber(resumen_gastos[0]?.edu_mio / 1000, 1)}bn in total · {formatNumber(resumen_gastos[0]?.edu_pct, 1)}% of spending · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF09)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Educación').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">A principle of this website: amounts are shown <b>per inhabitant</b> and <b>adjusted for inflation</b>, in {base_deflactor[0]?.anio_base} euros using the INE's annual average CPI, so that figures from different years are comparable. Totals in current euros appear as secondary figures; percentages (of spending or of GDP) need no adjustment.</p>

---

## 1. Annual Spending per Inhabitant in Spain ({resumen_gastos[0].anio})

Dividing the spending on each function by Spain's ~{formatNumber(poblacion_ultimo[0].poblacion_m, 1)} million residents (annual average population) gives the average annual cost per inhabitant of each public service:

<BarChart
    data={gastos_ultimo}
    x=funcion_cofog
    y=gasto_hab_real
    yAxisTitle="Euros per inhabitant per year ({base_deflactor[0]?.anio_base} euros)"
    yFmt=num0
    title="Public spending per inhabitant per year by function ({resumen_gastos[0]?.anio}, {base_deflactor[0]?.anio_base} euros)"
    swapXY={true}
/>

<DataTable data={gastos_ultimo} title="Functional Classification of Spending (COFOG {resumen_gastos[0].anio})">
    <Column id=funcion_cofog title="Spending Function" />
    <Column id=categoria_macro title="Macro-Category" />
    <Column id=gasto_hab_real title="Per Inhabitant" fmt='#,##0 €' />
    <Column id=porcentaje_gasto_total title="% of Total Spending" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% of GDP" fmt='0.0"%"' />
    <Column id=millones_euros title="Total (current € million)" fmt='#,##0' />
</DataTable>

---

## 2. Spending Trends by Main Block

Spending per inhabitant in each block, in {base_deflactor[0]?.anio_base} euros (adjusted for inflation), since 1996, the first year with annual CPI available:

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=eur_hab_real
    series=categoria_macro
    yAxisTitle="Euros per inhabitant ({base_deflactor[0]?.anio_base} euros)"
    yFmt=num0
    title="Public spending per inhabitant by functional block ({base_deflactor[0]?.anio_base} euros, adjusted for inflation)"
/>

---

## 3. Breakdown of the Main Spending Functions ({resumen_gastos[0].anio})

- **Social Protection and Pensions ({formatNumber(resumen_gastos[0].pens_pct, 1)}%):** The public sector's largest outlay, covering contributory retirement, survivors' and disability pensions, as well as unemployment and long-term care benefits.
- **Public Healthcare ({formatNumber(resumen_gastos[0].san_pct, 1)}%):** Managed mainly by the 17 Autonomous Communities to fund hospitals, health centres, medical staff and pharmaceutical spending.
- **Education ({formatNumber(resumen_gastos[0].edu_pct, 1)}%):** Funding for pre-primary, primary and secondary education, vocational training and public universities.
- **Interest on Public Debt ({formatNumber(resumen_gastos[0].int_pct, 1)}%):** Regular interest payments to investors holding government bonds and obligations (COFOG GF0107, shown here separately from General Public Services), a financial cost that provides no direct service but constrains budgetary capacity.
- **Economy, Transport and Infrastructure ({formatNumber(resumen_gastos[0].eco_pct, 1)}%):** Investment in the rail network (AVE high-speed and Cercanías commuter lines), roads, airports, agriculture and the energy transition.
- **Public Safety and Justice ({formatNumber(resumen_gastos[0].seg_pct, 1)}%):** Upkeep of the security forces (National Police, Guardia Civil, regional police forces), courts and prisons.
- **Defence ({formatNumber(resumen_gastos[0].def_pct, 1)}%):** Upkeep of the Armed Forces (Army, Navy and Air and Space Force) and military modernisation programmes.

---

## Official Sources
- **[COFOG Functional Classification of Expenditure (Eurostat gov_10a_exp)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp):** Consolidated general government spending by function under the standard classification of the United Nations and the European Union.
- **[GDP at current prices (Eurostat nama_10_gdp)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp) and [average population (nama_10_pe)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe):** Denominators for the percentages of GDP and spending per inhabitant.
- **[General State Budget (Ministry of Finance)](https://www.sepg.pap.hacienda.gob.es/):** Spending series for ministries and public bodies.
