---
title: GDP and growth
description: "Spain's GDP per inhabitant adjusted for inflation, quarterly growth, components of demand and comparison with the EU."
i18n_origen: e052747ef102
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql pib_trim
SELECT
    trimestre,
    CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo,
    interanual,
    por_habitante_real AS valor,
    real_meur,
    nominal_meur,
    anio_base
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql pib_hab
SELECT
    anio,
    real_eur AS valor,
    100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento,
    indice_ue
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql hitos
SELECT
    max(CASE WHEN anio = 2007 THEN valor END) AS v2007,
    max(CASE WHEN anio = 2013 THEN valor END) AS v2013,
    max(CASE WHEN anio = 2019 THEN valor END) AS v2019,
    max(CASE WHEN anio = 2020 THEN valor END) AS v2020,
    max(valor) FILTER (WHERE anio = (SELECT max(anio) FROM ${pib_hab})) AS vult,
    max(anio) AS anio_ult,
    100 * (max(valor) FILTER (WHERE anio = (SELECT max(anio) FROM ${pib_hab})) / max(CASE WHEN anio = 2007 THEN valor END) - 1) AS vs2007,
    100 * (max(CASE WHEN anio = 2013 THEN valor END) / max(CASE WHEN anio = 2007 THEN valor END) - 1) AS caida_crisis
FROM ${pib_hab}
```

```sql demanda
SELECT trimestre, nombre, por_habitante_real AS euros_hab
FROM mother.economia_pib_trimestral
WHERE componente IN ('P31_S14_S15', 'P3_S13', 'P51G')
ORDER BY trimestre, nombre
```

```sql ue
SELECT anio, nombre, indice_ue
FROM mother.economia_pib_per_capita
WHERE indice_ue IS NOT NULL
ORDER BY anio, nombre
```

```sql ue_ult
SELECT anio, nombre, indice_ue
FROM mother.economia_pib_per_capita
WHERE anio = (SELECT max(anio) FROM mother.economia_pib_per_capita WHERE indice_ue IS NOT NULL)
  AND pais <> 'EU27_2020'
ORDER BY indice_ue DESC
```

# 📈 GDP and growth

Gross domestic product measures everything the economy produces. To see whether the country is genuinely getting richer, it is shown here **per inhabitant** (otherwise it grows simply by adding population) and **adjusted for inflation**, in {pib_trim[0]?.anio_base} euros.

<Grid cols=4>
    <KpiCard
        title="GDP per inhabitant"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="in {pib_hab.slice(-1)[0]?.anio}, in {pib_trim[0]?.anio_base} euros"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real, vs previous year"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab}
    />
    <KpiCard
        title="GDP growth"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)}%"
        period="real year-on-year, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => ({...d, y: d.interanual}))}
    />
    <KpiCard
        title="GDP per inhabitant, annual rate"
        value={pib_trim.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.valor, 0)} €"
        period="latest quarter ({pib_trim.slice(-1)[0]?.periodo}) multiplied by four · total GDP €{formatNumber(pib_trim.slice(-1)[0]?.real_meur / 1000, 0)}bn in the quarter"
        source="Eurostat"
        sparklineData={pib_trim.slice(-40)}
    />
    <KpiCard
        title="Living standards vs the EU"
        value={pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue}
        formattedValue={formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}
        period="GDP per inhabitant in purchasing power parity, EU = 100"
        source="Eurostat"
        sparklineData={pib_hab.filter(d => d.indice_ue != null).map(d => ({...d, y: d.indice_ue}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('pib_pc_ppa', 'crecimiento_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'pib_pc_ppa')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_pib')} />


## GDP per inhabitant since 1995

In constant {pib_trim[0]?.anio_base} euros. The 2008 crisis cut GDP per inhabitant by {formatNumber(-hitos[0]?.caida_crisis, 1)}% up to 2013; the pandemic sent it plunging in 2020, and in {hitos[0]?.anio_ult} it stands {formatNumber(hitos[0]?.vs2007, 1)}% above its 2007 peak.

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    yAxisTitle="€ per inhabitant (real)"
    yFmt='#,##0" €"'
    xFmt='0'
    startingAtZero={false}
    title="GDP per inhabitant in {pib_trim[0]?.anio_base} euros"
/>

## Quarterly growth

Change in real GDP compared with the same quarter of the previous year, seasonally adjusted. The 2020 collapse and the 2021 rebound go off the scale.

<BarChart
    data={pib_trim.filter(d => d.interanual != null)}
    x=trimestre
    y=interanual
    yAxisTitle="% year-on-year"
    yFmt='0.0"%"'
    title="Real GDP, year-on-year change (%)"
/>

## What the output is spent on

Household consumption, public consumption and investment per inhabitant, in constant euros at an annual rate (the quarter multiplied by four). Foreign trade has its own page: [exports and imports](/en/economia/comercio-exterior).

<LineChart
    data={demanda}
    x=trimestre
    y=euros_hab
    series=nombre
    yAxisTitle="€ per inhabitant (real)"
    yFmt='#,##0" €"'
    title="Demand per inhabitant, {pib_trim[0]?.anio_base} euros at an annual rate"
/>

## Comparison with Europe

GDP per inhabitant in purchasing power parity, which corrects for prices not being the same in every country (EU-27 = 100). In {ue_ult[0]?.anio} Spain stands at {formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}.

<LineChart
    data={ue}
    x=anio
    y=indice_ue
    series=nombre
    xFmt='0'
    yAxisTitle="EU-27 = 100"
    startingAtZero={false}
    title="GDP per inhabitant in PPS (EU-27 = 100)"
/>

<DataTable data={ue_ult} rows=10>
    <Column id=nombre title="Country"/>
    <Column id=indice_ue title="Index (EU = 100)" fmt='0.0'/>
</DataTable>

---

**Sources:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table) (quarterly national accounts, seasonally adjusted) and [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table) (GDP per inhabitant). Chain-linked volumes are re-expressed in {pib_trim[0]?.anio_base} euros; population is the Eurostat annual average.
