---
title: Comercio exterior
description: "Exportaciones e importaciones de bienes y servicios de España: peso sobre el PIB, saldo exterior y evolución real por habitante."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

Lo que España vende al resto del mundo (exportaciones) y lo que compra fuera (importaciones), **de bienes y de servicios**: el turismo extranjero cuenta como exportación. Se mide sobre el PIB, para que no crezca solo por la inflación o por el tamaño de la economía.

<Grid cols=4>
    <KpiCard
        title="Exportaciones"
        value={comercio_trim.slice(-1)[0]?.export_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_pct, 1)} % del PIB"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.export_meur / 1000, 0)} mil M€ en el trimestre"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => d.export_pct)}
    />
    <KpiCard
        title="Importaciones"
        value={comercio_trim.slice(-1)[0]?.import_pct}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.import_pct, 1)} % del PIB"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.import_meur / 1000, 0)} mil M€ en el trimestre"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => d.import_pct)}
    />
    <KpiCard
        title="Saldo exterior"
        value={saldo_anual.slice(-1)[0]?.saldo_pct}
        formattedValue="{saldo_anual.slice(-1)[0]?.saldo_pct >= 0 ? '+' : ''}{formatNumber(saldo_anual.slice(-1)[0]?.saldo_pct, 1)} % del PIB"
        period="exportaciones menos importaciones en {saldo_anual.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={saldo_anual.map(d => d.saldo_pct)}
    />
    <KpiCard
        title="Exportaciones reales"
        value={comercio_trim.slice(-1)[0]?.export_interanual}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_interanual, 1)} %"
        period="variación interanual en volumen, {comercio_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-24).map(d => d.export_interanual)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('exportaciones_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'exportaciones_pib')} />


## Peso sobre el PIB

Las exportaciones pasaron del {formatNumber(hitos_comercio[0]?.exp1995, 1)} % del PIB en 1995 al {formatNumber(hitos_comercio[0]?.exp_ult, 1)} % en {hitos_comercio[0]?.anio_ult}. El gran salto llegó tras la crisis de 2008: del {formatNumber(saldo_anual.find(d => d.anio === 2009)?.export_pct, 0)} % en 2009 al {formatNumber(saldo_anual.find(d => d.anio === 2013)?.export_pct, 0)} % en 2013, mientras la demanda interna caía.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=pct_pib
    series=flujo
    yAxisTitle="% del PIB"
    yFmt='0.0"%"'
    startingAtZero={false}
    title="Exportaciones e importaciones de bienes y servicios (% del PIB)"
/>

## Saldo exterior

En 2007 España compraba fuera mucho más de lo que vendía: el déficit llegó al {formatNumber(-hitos_comercio[0]?.saldo2007, 1)} % del PIB. Desde {hitos_comercio[0]?.primer_superavit} el saldo es positivo todos los años.

<BarChart
    data={saldo_anual}
    x=anio
    y=saldo_pct
    series=signo
    colorPalette={['#dc2626', '#16a34a']}
    xFmt='0'
    yAxisTitle="% del PIB"
    yFmt='0.0"%"'
    title="Saldo exterior de bienes y servicios (% del PIB)"
/>

## Evolución real por habitante

Exportaciones e importaciones en euros constantes de {comercio_trim[0]?.anio_base} por habitante, a ritmo anual (el trimestre multiplicado por cuatro): muestra cuánto crece de verdad el comercio, sin la inflación ni el aumento de población.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=euros_hab
    series=flujo
    yAxisTitle="€ por habitante (reales)"
    yFmt='#,##0" €"'
    title="Comercio exterior por habitante, euros de {comercio_trim[0]?.anio_base} a ritmo anual"
/>

---

**Fuente:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table): exportaciones (P6) e importaciones (P7) de bienes y servicios de la contabilidad nacional trimestral, desestacionalizadas. Pesos sobre el PIB a precios corrientes.
