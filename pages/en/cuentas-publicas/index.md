---
description: "Revenue, spending, deficit and debt of Spain's general government, per inhabitant, adjusted for inflation and as a percentage of GDP."
title: Public Accounts · Spain's Annual Report
i18n_origen: 6a6b81df44af
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCurrency, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import SankeyPresupuesto from '../../../../../../src/lib/components/SankeyPresupuesto.svelte';
</script>

# Spain's public accounts: the annual report

Like a company's annual report, but for general government as a whole (central government, regions, local councils and Social Security): *how much does the State take in? What is taxpayers' money spent on? What is the annual deficit and how is public debt evolving?*

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql balance_reciente
-- Importes por habitante y en euros constantes (ya calculados en la tabla)
SELECT
    b.anio,
    b.ingresos_totales_mrd,
    b.gastos_totales_mrd,
    b.saldo_deficit_mrd,
    b.saldo_deficit_pib,
    b.deuda_publica_mrd,
    b.deuda_pib,
    b.ingresos_eur_hab_real AS ingresos_hab_real,
    b.gastos_eur_hab_real AS gastos_hab_real
FROM mother.cuentas_balance_anual b
ORDER BY b.anio DESC
LIMIT 2
```

```sql serie_balance_historico
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    b.anio AS año,
    b.ingresos_eur_hab_real AS "Ingresos por habitante",
    b.gastos_eur_hab_real AS "Gastos por habitante",
    b.saldo_eur_hab_real AS "Déficit / Superávit por habitante"
FROM mother.cuentas_balance_anual b
WHERE b.ingresos_eur_hab_real IS NOT NULL
ORDER BY año ASC
```

```sql serie_deficit_pib
SELECT
    anio AS año,
    saldo_deficit_pib AS deficit_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql serie_deuda_pib
SELECT
    anio AS año,
    deuda_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql sankey_anio
-- Último ejercicio con desglose publicado tanto de ingresos como de gastos
SELECT least(
    (SELECT max(anio) FROM mother.cuentas_ingresos),
    (SELECT max(anio) FROM mother.cuentas_gastos)
) AS anio
```

```sql ingresos_sankey
SELECT
    categoria,
    millones_euros
FROM mother.cuentas_ingresos
WHERE anio = (SELECT least(max(i.anio), (SELECT max(g.anio) FROM mother.cuentas_gastos g)) FROM mother.cuentas_ingresos i)
ORDER BY millones_euros DESC
```

```sql gastos_sankey
SELECT
    funcion_cofog,
    millones_euros
FROM mother.cuentas_gastos
WHERE anio = (SELECT least(max(g.anio), (SELECT max(i.anio) FROM mother.cuentas_ingresos i)) FROM mother.cuentas_gastos g)
ORDER BY millones_euros DESC
```

```sql subsectores_ultimo
SELECT
    s.anio,
    s.subsector,
    s.gasto_mrd,
    s.ingreso_mrd,
    s.saldo_deficit_mrd,
    s.peso_gasto_pct,
    s.gasto_eur_hab_real AS gasto_hab_real,
    s.saldo_eur_hab_real AS saldo_hab_real
FROM mother.cuentas_subsectores s
WHERE s.anio = (SELECT max(anio) FROM mother.cuentas_subsectores)
ORDER BY s.gasto_mrd DESC
```

```sql rango_historico
-- Rango de la serie en euros constantes por habitante
SELECT min(año) AS desde, max(año) AS hasta
FROM ${serie_balance_historico}
```

```sql serie_balance_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    año AS anio,
    "Ingresos por habitante" AS ingresos_hab_real,
    "Gastos por habitante" AS gastos_hab_real
FROM ${serie_balance_historico}
ORDER BY anio
```

<!-- KPI Ribbon: Resumen Anual del Estado -->
<Grid cols=4>
    <KpiCard
        title="Revenue per inhabitant"
        value={balance_reciente[0]?.ingresos_hab_real}
        formattedValue="€{formatNumber(balance_reciente[0]?.ingresos_hab_real, 0)}"
        unit="/ inhab."
        period="€{formatNumber(balance_reciente[0]?.ingresos_totales_mrd, 1)}bn in total · {balance_reciente[0]?.anio} ({base_deflactor[0]?.anio_base} euros)"
        change={(((balance_reciente[0]?.ingresos_hab_real - balance_reciente[1]?.ingresos_hab_real) / balance_reciente[1]?.ingresos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="year on year, adjusted for inflation"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.ingresos_hab_real != null).map(d => ({...d, y: d.ingresos_hab_real}))}
        href="/en/cuentas-publicas/ingresos"
    />

    <KpiCard
        title="Spending per inhabitant"
        value={balance_reciente[0]?.gastos_hab_real}
        formattedValue="€{formatNumber(balance_reciente[0]?.gastos_hab_real, 0)}"
        unit="/ inhab."
        period="€{formatNumber(balance_reciente[0]?.gastos_totales_mrd, 1)}bn in total · {balance_reciente[0]?.anio} ({base_deflactor[0]?.anio_base} euros)"
        change={(((balance_reciente[0]?.gastos_hab_real - balance_reciente[1]?.gastos_hab_real) / balance_reciente[1]?.gastos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="year on year, adjusted for inflation"
        direction="neutral"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.gastos_hab_real != null).map(d => ({...d, y: d.gastos_hab_real}))}
        href="/en/cuentas-publicas/gastos"
    />

    <KpiCard
        title="Annual Fiscal Deficit"
        value={balance_reciente[0].saldo_deficit_pib}
        formattedValue="{formatNumber(balance_reciente[0].saldo_deficit_pib, 1)}% of GDP"
        period="Fiscal year {balance_reciente[0].anio}"
        change={(balance_reciente[0].saldo_deficit_pib - balance_reciente[1].saldo_deficit_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="vs previous year"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_deficit_pib.filter(d => d.deficit_pib != null).map(d => ({...d, y: d.deficit_pib}))}
    />

    <KpiCard
        title="Public Debt / GDP"
        value={balance_reciente[0].deuda_pib}
        formattedValue="{formatNumber(balance_reciente[0].deuda_pib, 1)}%"
        period="€{formatNumber(balance_reciente[0].deuda_publica_mrd, 1)}bn · {balance_reciente[0].anio}"
        change={(balance_reciente[0].deuda_pib - balance_reciente[1].deuda_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="vs previous year"
        direction="positive-down"
        source="Eurostat (EDP)"
        sparklineData={serie_deuda_pib.filter(d => d.deuda_pib != null).map(d => ({...d, y: d.deuda_pib}))}
        href="/en/varios/indicadores/deuda_publica_pib"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('deuda_publica')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'deuda_publica')} />


<p class="text-xs text-gray-500">A principle of this website: amounts in euros are shown <b>per inhabitant</b> (so they do not grow merely because the population grows) and <b>adjusted for inflation</b>, in {base_deflactor[0]?.anio_base} euros using the INE's annual average CPI. Totals in current euros appear as secondary figures. Percentages of GDP need no adjustment.</p>

---

## 1. The Path of Public Money (Budget Flow {sankey_anio[0].anio})

This flow diagram shows where general government revenue comes from and which specific items it is spent on (latest year with a full breakdown published by Eurostat). The difference between the two sides is the year's deficit, which is financed with debt:

<SankeyPresupuesto
    dataIngresos={ingresos_sankey}
    dataGastos={gastos_sankey}
    title="Flow of Spain's Public Accounts ({sankey_anio[0].anio})"
    subtitle="From taxes and social contributions to the State's spending functions (€ million)"
    height="540px"
/>

<Grid cols=2>
    <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800">
        <h3 class="font-bold text-blue-900 dark:text-blue-300 mb-1"><span aria-hidden="true">📥</span> Want to dig deeper into revenue?</h3>
        <p class="text-xs text-blue-700 dark:text-blue-400 mb-2">See what is collected through personal income tax, VAT, corporation tax, social contributions and public fees.</p>
        <a href="/en/cuentas-publicas/ingresos" class="text-xs font-bold text-blue-600 dark:text-blue-300 hover:underline">
            See the full Public Revenue report →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800">
        <h3 class="font-bold text-purple-900 dark:text-purple-300 mb-1"><span aria-hidden="true">📤</span> Want to see spending in detail?</h3>
        <p class="text-xs text-purple-700 dark:text-purple-400 mb-2">Find out how much the State spends per inhabitant on health, pensions, education and defence.</p>
        <a href="/en/cuentas-publicas/gastos" class="text-xs font-bold text-purple-600 dark:text-purple-300 hover:underline">
            See the full report on Spending and Cost per Inhabitant →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-800">
        <h3 class="font-bold text-teal-900 dark:text-teal-300 mb-1"><span aria-hidden="true">🏛️</span> How many public employees are there?</h3>
        <p class="text-xs text-teal-700 dark:text-teal-400 mb-2">How many work in each administration and region, how their numbers have changed, what they earn compared with the private sector and how much they cost.</p>
        <a href="/en/cuentas-publicas/empleo-publico" class="text-xs font-bold text-teal-700 dark:text-teal-300 hover:underline">
            See the Public Employment report →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800">
        <h3 class="font-bold text-amber-900 dark:text-amber-300 mb-1"><span aria-hidden="true">👵</span> How much do pensions cost?</h3>
        <p class="text-xs text-amber-700 dark:text-amber-400 mb-2">Average pension adjusted for inflation, contributors per pension, spending as a % of GDP compared with the EU and differences between regions.</p>
        <a href="/en/cuentas-publicas/pensiones" class="text-xs font-bold text-amber-700 dark:text-amber-300 hover:underline">
            See the Pensions report →
        </a>
    </div>
</Grid>

---

## 2. The Historical Balance: Revenue vs Spending ({rango_historico[0].desde} - {rango_historico[0].hasta})

The annual difference between what the public sector takes in and what it pays out defines the **budget balance** (a surplus if positive, a deficit if negative). To make comparisons between years fair, figures are expressed per inhabitant and in {base_deflactor[0]?.anio_base} euros (the series starts in {rango_historico[0]?.desde}, the first year with annual CPI available):

<LineChart
    data={serie_balance_historico}
    x=año
    y={["Ingresos por habitante", "Gastos por habitante"]}
    yAxisTitle="Euros per inhabitant ({base_deflactor[0]?.anio_base} euros)"
    yFmt=num0
    title="Public revenue and spending per inhabitant ({base_deflactor[0]?.anio_base} euros, adjusted for inflation)"
    startingAtZero={false}
/>

<BarChart
    data={serie_deficit_pib}
    x=año
    y=deficit_pib
    yAxisTitle="Deficit / Surplus (% of GDP)"
    title="General Government Net Lending (+) or Net Borrowing (-) (% of GDP)"
/>

---

## 3. Who manages public spending in Spain?

Spain is a decentralised state in which spending responsibilities are shared among four institutional subsectors. Each subsector's figures are not consolidated with the others (they include transfers between administrations), so their shares of total spending add up to more than 100%:

<Grid cols=2>

<DataTable data={subsectores_ultimo} title="Breakdown by Level of Government ({subsectores_ultimo[0]?.anio})">
    <Column id=subsector title="Institutional Subsector" />
    <Column id=gasto_hab_real title="Spending per inhabitant" fmt='#,##0 €' />
    <Column id=peso_gasto_pct title="% of Spending" fmt='0.0"%"' />
    <Column id=saldo_hab_real title="Balance per inhabitant" fmt='#,##0 €' />
    <Column id=gasto_mrd title="Total spending (€bn)" fmt='#,##0.0' />
</DataTable>

<div>
    <BarChart
        data={subsectores_ultimo}
        x=subsector
        y=gasto_hab_real
        yAxisTitle="Euros per inhabitant"
        yFmt=num0
        title="Spending per inhabitant by subsector ({subsectores_ultimo[0]?.anio}, {base_deflactor[0]?.anio_base} euros)"
        swapXY={true}
    />
</div>

</Grid>

- **Central Government (the State):** Funds the ministries, the National Police, defence, infrastructure of general interest and most interest payments on the debt.
- **Autonomous Communities (regions):** Manage the two main pillars of citizens' welfare: **public healthcare** and **education**.
- **Social Security Funds:** The body specialising in paying pensions and benefits to workers and retirees.
- **Local Government (Town Councils and Provincial Councils):** Responsible for urban planning, waste collection, urban transport and municipal services.

---

## 4. Public Debt as a Share of GDP

The deficit accumulated over the years is financed by issuing **Public Debt** (Treasury bills, bonds and obligations):

<LineChart
    data={serie_deuda_pib}
    x=año
    y=deuda_pib
    yAxisTitle="Public Debt (% of GDP)"
    title="Evolution of Spain's Public Debt (% of GDP, EDP definition)"
    startingAtZero={false}
/>

---

## Official Sources and Traceability
- **[Intervención General de la Administración del Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Spain's General Comptroller of the State Administration; national accounts of the public sector.
- **[Banco de España - Statistical Bulletin](https://www.bde.es/):** Historical series of public debt and general government financial liabilities.
- **[Eurostat - Government Finance Statistics (gov_10a_main)](https://ec.europa.eu/eurostat/web/government-finance-statistics):** Harmonised consolidated accounts under the European System of Accounts (ESA 2010).
