---
title: Economic sectors
description: "How much each sector of the Spanish economy produces and how many people it employs, its real growth and its productivity, since 1995."
i18n_origen: 2fb118d1e75d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql sectores
SELECT *
FROM mother.economia_sectores
ORDER BY anio, sector
```

```sql ultimo
SELECT
    s.sector,
    s.rama,
    s.es_subrama,
    s.peso_vab,
    s.crecimiento_real,
    s.ocupados_miles,
    s.ocupados_1000_hab,
    s.peso_empleo,
    s.productividad_real,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crec_desde_2019,
    s.anio,
    s.anio_euros
FROM mother.economia_sectores s
LEFT JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
ORDER BY s.rama = 'TOTAL', s.peso_vab DESC
```

```sql total
SELECT anio, crecimiento_real, ocupados_1000_hab, productividad_real, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql sin_total
SELECT *
FROM mother.economia_sectores
WHERE rama <> 'TOTAL' AND NOT es_subrama
ORDER BY anio, sector
```

```sql indice_vab
SELECT
    s.anio,
    s.sector,
    100 * s.vab_real_meur / b.vab_real_meur AS indice
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2008
WHERE s.rama IN ('B-E', 'F', 'G-I', 'J', 'M_N', 'O-Q', 'TOTAL')
ORDER BY s.anio, s.sector
```

# 🏭 Economic sectors

What the Spanish economy produces and who produces it. Each sector's value added is measured in constant {ultimo[0]?.anio_euros} euros, and employment as people in work per 1,000 inhabitants, so that it does not grow merely because there are more people.

<Grid cols=4>
    <KpiCard
        title="Real growth of the economy"
        value={total.slice(-1)[0]?.crecimiento_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.crecimiento_real, 1)}%"
        period="total value added in {total.slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={total.filter(d => d.crecimiento_real != null).map(d => d.crecimiento_real)}
    />
    <KpiCard
        title="Employed per 1,000 inhabitants"
        value={total.slice(-1)[0]?.ocupados_1000_hab}
        formattedValue={formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}
        period="{formatNumber(total.slice(-1)[0]?.ocupados_miles / 1000, 1)} million people in work in {total.slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={total.map(d => d.ocupados_1000_hab)}
    />
    <KpiCard
        title="Productivity per worker"
        value={total.slice(-1)[0]?.productividad_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.productividad_real, 0)} €"
        period="value added per person employed in {total.slice(-1)[0]?.anio}, {ultimo[0]?.anio_euros} euros"
        source="Eurostat"
        sparklineData={total.map(d => d.productividad_real)}
    />
    <KpiCard
        title="Fastest-growing sector since 2019"
        value={ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019}
        formattedValue="+{formatNumber(ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019, 1)}%"
        period="{ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.sector}, real value added"
        source="Eurostat"
    />
</Grid>

## Snapshot of {ultimo[0]?.anio}

Each sector's share of output and of employment. Where its share of output exceeds its share of employment, each worker generates more value (in real estate mainly because of rents, including those imputed to people who live in their own home).

<DataTable data={ultimo} rows=20>
    <Column id=sector title="Sector"/>
    <Column id=peso_vab title="% of output" fmt='0.0'/>
    <Column id=peso_empleo title="% of employment" fmt='0.0'/>
    <Column id=crecimiento_real title="Real growth (%)" fmt='0.0' contentType=delta/>
    <Column id=crec_desde_2019 title="Since 2019 (%)" fmt='0.0' contentType=delta/>
    <Column id=ocupados_1000_hab title="Employed per 1,000 inhab." fmt='0.0'/>
    <Column id=productividad_real title="Value added per worker (€)" fmt='#,##0'/>
</DataTable>

Manufacturing (Manufacturas) is part of Industry and energy (Industria y energía), which is why it is not added separately in the charts.

## Real growth by sector

Value added of each major sector in constant euros, with 2008 = 100. Construction has still not recovered the level it had before the property bubble burst.

<LineChart
    data={indice_vab}
    x=anio
    y=indice
    series=sector
    xFmt='0'
    yAxisTitle="2008 = 100"
    startingAtZero={false}
    title="Real value added by sector (2008 = 100)"
/>

## Employment by sector

People employed in each sector per 1,000 inhabitants; stacked, they give the total employed per 1,000 inhabitants. In {total.slice(-1)[0]?.anio} there were {formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}, compared with {formatNumber(total.find(d => d.anio === 2007)?.ocupados_1000_hab, 0)} in 2007.

<AreaChart
    data={sin_total}
    x=anio
    y=ocupados_1000_hab
    series=sector
    xFmt='0'
    yAxisTitle="Employed per 1,000 inhab."
    title="Employed per 1,000 inhabitants by sector"
/>

<LineChart
    data={sin_total}
    x=anio
    y=peso_empleo
    series=sector
    xFmt='0'
    yAxisTitle="% of employment"
    yFmt='0.0"%"'
    title="Each sector's share of employment (%)"
/>

## Productivity

Real value added per person employed across the whole economy, in {ultimo[0]?.anio_euros} euros.

<LineChart
    data={total}
    x=anio
    y=productividad_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per worker"
    startingAtZero={false}
    title="Apparent labour productivity ({ultimo[0]?.anio_euros} euros)"
/>

---

**Sources:** [Eurostat, nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (gross value added by industry) and [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (employment by industry, domestic concept). The ten broad industry groups of the NACE classification; Eurostat annual average population.
