---
title: Kanpo-merkataritza
description: "Espainiako ondasun eta zerbitzuen esportazioak eta inportazioak: BPGarekiko pisua, kanpo-saldoa eta bilakaera erreala biztanleko."
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

# 🚢 Kanpo-merkataritza

Espainiak munduko gainerako herrialdeei saltzen diena (esportazioak) eta kanpoan erosten duena (inportazioak), **ondasunak eta zerbitzuak**: atzerriko turismoa esportaziotzat hartzen da. BPGarekiko neurtzen da, inflazioagatik edo ekonomiaren tamainagatik soilik hazi ez dadin.

<Grid cols=4>
    <KpiCard
        title="Esportazioak"
        value={comercio_trim.slice(-1)[0]?.export_pct}
        formattedValue="BPGaren {formatNumber(comercio_trim.slice(-1)[0]?.export_pct, 1)} %"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.export_meur / 1000, 0)} mila M€ hiruhilekoan"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => d.export_pct)}
    />
    <KpiCard
        title="Inportazioak"
        value={comercio_trim.slice(-1)[0]?.import_pct}
        formattedValue="BPGaren {formatNumber(comercio_trim.slice(-1)[0]?.import_pct, 1)} %"
        period="{comercio_trim.slice(-1)[0]?.periodo} · {formatNumber(comercio_trim.slice(-1)[0]?.import_meur / 1000, 0)} mila M€ hiruhilekoan"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-40).map(d => d.import_pct)}
    />
    <KpiCard
        title="Kanpo-saldoa"
        value={saldo_anual.slice(-1)[0]?.saldo_pct}
        formattedValue="BPGaren {saldo_anual.slice(-1)[0]?.saldo_pct >= 0 ? '+' : ''}{formatNumber(saldo_anual.slice(-1)[0]?.saldo_pct, 1)} %"
        period="esportazioak ken inportazioak, {saldo_anual.slice(-1)[0]?.anio}. urtean"
        direction="positive-up"
        source="Eurostat"
        sparklineData={saldo_anual.map(d => d.saldo_pct)}
    />
    <KpiCard
        title="Esportazio errealak"
        value={comercio_trim.slice(-1)[0]?.export_interanual}
        formattedValue="{formatNumber(comercio_trim.slice(-1)[0]?.export_interanual, 1)} %"
        period="urtetik urterako aldakuntza bolumenean, {comercio_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={comercio_trim.slice(-24).map(d => d.export_interanual)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('exportaciones_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'exportaciones_pib')} />


## BPGarekiko pisua

Esportazioak BPGaren {formatNumber(hitos_comercio[0]?.exp1995, 1)} % ziren 1995ean, eta {formatNumber(hitos_comercio[0]?.exp_ult, 1)} % {hitos_comercio[0]?.anio_ult}. urtean. Jauzi handia 2008ko krisiaren ondoren etorri zen: 2009an {formatNumber(saldo_anual.find(d => d.anio === 2009)?.export_pct, 0)} % ziren, eta 2013an {formatNumber(saldo_anual.find(d => d.anio === 2013)?.export_pct, 0)} %, barne-eskaria jaisten ari zen bitartean.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=pct_pib
    series=flujo
    yAxisTitle="BPGaren %"
    yFmt='0.0"%"'
    startingAtZero={false}
    title="Ondasun eta zerbitzuen esportazioak eta inportazioak (BPGaren %)"
/>

## Kanpo-saldoa

2007an Espainiak saltzen zuena baino askoz gehiago erosten zuen kanpoan: defizita BPGaren {formatNumber(-hitos_comercio[0]?.saldo2007, 1)} % izatera iritsi zen. {hitos_comercio[0]?.primer_superavit}. urteaz geroztik saldoa positiboa da urte guztietan.

<BarChart
    data={saldo_anual}
    x=anio
    y=saldo_pct
    series=signo
    colorPalette={['#dc2626', '#16a34a']}
    xFmt='0'
    yAxisTitle="BPGaren %"
    yFmt='0.0"%"'
    title="Ondasun eta zerbitzuen kanpo-saldoa (BPGaren %)"
/>

## Bilakaera erreala biztanleko

Esportazioak eta inportazioak {comercio_trim[0]?.anio_base}. urteko euro konstanteetan biztanleko, urteko erritmoan (hiruhilekoa bider lau): merkataritza benetan zenbat hazten den erakusten du, inflaziorik eta biztanleriaren hazkunderik gabe.

<LineChart
    data={comercio_largo}
    x=trimestre
    y=euros_hab
    series=flujo
    yAxisTitle="€ biztanleko (errealak)"
    yFmt='#,##0" €"'
    title="Kanpo-merkataritza biztanleko, {comercio_trim[0]?.anio_base}. urteko eurotan, urteko erritmoan"
/>

---

**Iturria:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table): hiruhileko kontabilitate nazionaleko ondasun eta zerbitzuen esportazioak (P6) eta inportazioak (P7), urtaroko doikuntzarekin. BPGarekiko pisuak prezio korronteetan.
