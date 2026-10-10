---
title: Comerç exterior
description: "Exportacions i importacions de béns i serveis d'Espanya: pes sobre el PIB, saldo exterior i evolució real per habitant."
i18n_origen: 57519a9f7dc4
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

# 🚢 Comerç exterior

El que Espanya ven a la resta del món (exportacions) i el que compra fora (importacions), **de béns i de serveis**: el turisme estranger compta com a exportació. Es mesura sobre el PIB, perquè no creixi només per la inflació o per la mida de l'economia.

<Grid cols=4>
    <KpiCard
        title="Exportacions"
        value={comercio_trim.slice(-1)[0]?.export_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_pct, 1)} % del PIB"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.export_meur / 1000, 0)} mil M€ en el trimestre"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => ({...d, y: d.export_pct}))}
    />
    <KpiCard
        title="Importacions"
        value={comercio_trim.slice(-1)[0]?.import_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.import_pct, 1)} % del PIB"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.import_meur / 1000, 0)} mil M€ en el trimestre"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => ({...d, y: d.import_pct}))}
    />
    <KpiCard
        title="Saldo exterior"
        value={saldo_anual.slice(-1)[0]?.saldo_pct}
        formattedValue="{saldo_anual.slice(-1)[0]?.saldo_pct >= 0 ? '+' : ''}{formatNumber(saldo_anual.slice(-1)[0]?.saldo_pct, 1)} % del PIB"
        period="exportacions menys importacions el {saldo_anual.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={saldo_anual.map(d => ({...d, y: d.saldo_pct}))}
    />
    <KpiCard
        title="Exportacions reals"
        value={comercio_trim.slice(-1)[0]?.export_interanual}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_interanual, 1)} %"
        period="variació interanual en volum, {comercio_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-24).map(d => ({...d, y: d.export_interanual}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('exportaciones_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'exportaciones_pib')} />


## Pes sobre el PIB

Les exportacions van passar del {formatNumber(hitos_comercio[0]?.exp1995, 1)} % del PIB el 1995 al {formatNumber(hitos_comercio[0]?.exp_ult, 1)} % el {hitos_comercio[0]?.anio_ult}. El gran salt va arribar després de la crisi del 2008: del {formatNumber(saldo_anual.find(d => d.anio === 2009)?.export_pct, 0)} % el 2009 al {formatNumber(saldo_anual.find(d => d.anio === 2013)?.export_pct, 0)} % el 2013, mentre la demanda interna queia.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=pct_pib
    series=flujo
    yAxisTitle="% del PIB"
    yFmt='0.0"%"'
    startingAtZero={false}
    title="Exportacions i importacions de béns i serveis (% del PIB)"
/>

## Saldo exterior

El 2007 Espanya comprava fora molt més del que venia: el dèficit va arribar al {formatNumber(-hitos_comercio[0]?.saldo2007, 1)} % del PIB. Des del {hitos_comercio[0]?.primer_superavit} el saldo és positiu cada any.

<BarChart
    data={saldo_anual}
    x=anio
    y=saldo_pct
    series=signo
    colorPalette={['#dc2626', '#16a34a']}
    xFmt='0'
    yAxisTitle="% del PIB"
    yFmt='0.0"%"'
    title="Saldo exterior de béns i serveis (% del PIB)"
/>

## Evolució real per habitant

Exportacions i importacions en euros constants del {comercio_trim[0]?.anio_base} per habitant, a ritme anual (el trimestre multiplicat per quatre): mostra quant creix de debò el comerç, sense la inflació ni l'augment de població.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=euros_hab
    series=flujo
    yAxisTitle="€ per habitant (reals)"
    yFmt='#,##0" €"'
    title="Comerç exterior per habitant, euros del {comercio_trim[0]?.anio_base} a ritme anual"
/>

---

**Font:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table): exportacions (P6) i importacions (P7) de béns i serveis de la comptabilitat nacional trimestral, desestacionalitzades. Pesos sobre el PIB a preus corrents.
