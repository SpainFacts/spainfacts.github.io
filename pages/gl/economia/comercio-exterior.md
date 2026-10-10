---
i18n_origen: 57519a9f7dc4
title: Comercio exterior
description: "Exportacións e importacións de bens e servizos de España: peso sobre o PIB, saldo exterior e evolución real por habitante."
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

# 🚢 Comercio exterior

O que España vende ao resto do mundo (exportacións) e o que compra fóra (importacións), **de bens e de servizos**: o turismo estranxeiro conta como exportación. Mídese sobre o PIB, para que non medre só pola inflación ou polo tamaño da economía.

<Grid cols=4>
    <KpiCard
        title="Exportacións"
        value={comercio_trim.slice(-1)[0]?.export_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_pct, 1)} % do PIB"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.export_meur / 1000, 0)} mil M€ no trimestre"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => ({...d, y: d.export_pct}))}
    />
    <KpiCard
        title="Importacións"
        value={comercio_trim.slice(-1)[0]?.import_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.import_pct, 1)} % do PIB"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.import_meur / 1000, 0)} mil M€ no trimestre"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => ({...d, y: d.import_pct}))}
    />
    <KpiCard
        title="Saldo exterior"
        value={saldo_anual.slice(-1)[0]?.saldo_pct}
        formattedValue="{saldo_anual.slice(-1)[0]?.saldo_pct >= 0 ? '+' : ''}{formatNumber(saldo_anual.slice(-1)[0]?.saldo_pct, 1)} % do PIB"
        period="exportacións menos importacións en {saldo_anual.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={saldo_anual.map(d => ({...d, y: d.saldo_pct}))}
    />
    <KpiCard
        title="Exportacións reais"
        value={comercio_trim.slice(-1)[0]?.export_interanual}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_interanual, 1)} %"
        period="variación interanual en volume, {comercio_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-24).map(d => ({...d, y: d.export_interanual}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('exportaciones_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'exportaciones_pib')} />


## Peso sobre o PIB

As exportacións pasaron do {formatNumber(hitos_comercio[0]?.exp1995, 1)} % do PIB en 1995 ao {formatNumber(hitos_comercio[0]?.exp_ult, 1)} % en {hitos_comercio[0]?.anio_ult}. O gran salto chegou despois da crise de 2008: do {formatNumber(saldo_anual.find(d => d.anio === 2009)?.export_pct, 0)} % en 2009 ao {formatNumber(saldo_anual.find(d => d.anio === 2013)?.export_pct, 0)} % en 2013, mentres a demanda interna caía.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=pct_pib
    series=flujo
    yAxisTitle="% do PIB"
    yFmt='0.0"%"'
    startingAtZero={false}
    title="Exportacións e importacións de bens e servizos (% do PIB)"
/>

## Saldo exterior

En 2007 España compraba fóra moito máis do que vendía: o déficit chegou ao {formatNumber(-hitos_comercio[0]?.saldo2007, 1)} % do PIB. Desde {hitos_comercio[0]?.primer_superavit} o saldo é positivo todos os anos.

<BarChart
    data={saldo_anual}
    x=anio
    y=saldo_pct
    series=signo
    colorPalette={['#dc2626', '#16a34a']}
    xFmt='0'
    yAxisTitle="% do PIB"
    yFmt='0.0"%"'
    title="Saldo exterior de bens e servizos (% do PIB)"
/>

## Evolución real por habitante

Exportacións e importacións en euros constantes de {comercio_trim[0]?.anio_base} por habitante, a ritmo anual (o trimestre multiplicado por catro): mostra canto medra de verdade o comercio, sen a inflación nin o aumento de poboación.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=euros_hab
    series=flujo
    yAxisTitle="€ por habitante (reais)"
    yFmt='#,##0" €"'
    title="Comercio exterior por habitante, euros de {comercio_trim[0]?.anio_base} a ritmo anual"
/>

---

**Fonte:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table): exportacións (P6) e importacións (P7) de bens e servizos da contabilidade nacional trimestral, desestacionalizadas. Pesos sobre o PIB a prezos correntes.
