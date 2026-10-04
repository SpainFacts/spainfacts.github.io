---
title: BPG eta hazkundea
description: "Espainiako BPGaren bilakaera biztanleko eta inflazioa kenduta, hiruhileko hazkundea, eskariaren osagaiak eta EBrekiko alderaketa."
i18n_origen: 0a70463d9329
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

# 📈 BPG eta hazkundea

Barne-produktu gordinak ekonomiak ekoizten duen guztia neurtzen du. Herrialdea benetan aberasten ari den ikusteko, hemen **biztanleko** erakusten da (bestela, biztanleria gehitze hutsarekin hazten da) eta **inflazioa kenduta**, {pib_trim[0]?.anio_base}. urteko eurotan.

<Grid cols=4>
    <KpiCard
        title="BPG biztanleko"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="{pib_hab.slice(-1)[0]?.anio}. urtean, {pib_trim[0]?.anio_base}. urteko eurotan"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="erreala, aurreko urtearekin alderatuta"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab}
    />
    <KpiCard
        title="BPGaren hazkundea"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="urtetik urterakoa, erreala, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => d.interanual)}
    />
    <KpiCard
        title="BPG biztanleko, urteko erritmoan"
        value={pib_trim.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.valor, 0)} €"
        period="azken hiruhilekoa ({pib_trim.slice(-1)[0]?.periodo}) bider lau · BPG osoa {formatNumber(pib_trim.slice(-1)[0]?.real_meur / 1000, 0)} mila M€ hiruhilekoan"
        source="Eurostat"
        sparklineData={pib_trim.slice(-40)}
    />
    <KpiCard
        title="Bizi-maila EBrekin alderatuta"
        value={pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue}
        formattedValue={formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}
        period="BPG biztanleko erosahalmen-parekotasunean, EB = 100"
        source="Eurostat"
        sparklineData={pib_hab.filter(d => d.indice_ue != null).map(d => d.indice_ue)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('pib_pc_ppa', 'crecimiento_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'pib_pc_ppa')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_pib')} />


## BPG biztanleko 1995etik

{pib_trim[0]?.anio_base}. urteko euro konstanteetan. 2008ko krisiak biztanleko BPGa {formatNumber(-hitos[0]?.caida_crisis, 1)} % murriztu zuen 2013ra arte; pandemiak 2020an hondoratu zuen, eta {hitos[0]?.anio_ult}. urtean 2007ko gehienekoa baino {formatNumber(hitos[0]?.vs2007, 1)} % gorago dago.

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    yAxisTitle="€ biztanleko (errealak)"
    yFmt='#,##0" €"'
    xFmt='0'
    startingAtZero={false}
    title="BPG biztanleko, {pib_trim[0]?.anio_base}. urteko eurotan"
/>

## Hiruhileko hazkundea

BPG errealaren aldakuntza aurreko urteko hiruhileko berarekin alderatuta, urtaroko doikuntzarekin. 2020ko amildegia eta 2021eko errebotea eskalatik kanpo geratzen dira.

<BarChart
    data={pib_trim.filter(d => d.interanual != null)}
    x=trimestre
    y=interanual
    yAxisTitle="% urtetik urtera"
    yFmt='0.0"%"'
    title="BPG erreala, urtetik urterako aldakuntza (%)"
/>

## Zertan gastatzen da ekoizten dena

Etxeen kontsumoa, kontsumo publikoa eta inbertsioa biztanleko, euro konstanteetan eta urteko erritmoan (hiruhilekoa bider lau). Kanpo-merkataritzak bere orria du: [esportazioak eta inportazioak](/eu/economia/comercio-exterior).

<LineChart
    data={demanda}
    x=trimestre
    y=euros_hab
    series=nombre
    yAxisTitle="€ biztanleko (errealak)"
    yFmt='#,##0" €"'
    title="Eskaria biztanleko, {pib_trim[0]?.anio_base}. urteko eurotan, urteko erritmoan"
/>

## Europarekin alderatuta

BPG biztanleko erosahalmen-parekotasunean; horrek zuzentzen du prezioak herrialde guztietan berdinak ez izatea (EB-27 = 100). {ue_ult[0]?.anio}. urtean Espainiaren indizea {formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)} da.

<LineChart
    data={ue}
    x=anio
    y=indice_ue
    series=nombre
    xFmt='0'
    yAxisTitle="EB-27 = 100"
    startingAtZero={false}
    title="BPG biztanleko, EAEtan (EB-27 = 100)"
/>

<DataTable data={ue_ult} rows=10>
    <Column id=nombre title="Herrialdea"/>
    <Column id=indice_ue title="Indizea (EB = 100)" fmt='0.0'/>
</DataTable>

---

**Iturriak:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table) (hiruhileko kontabilitate nazionala, urtaroko doikuntzarekin) eta [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table) (BPG biztanleko). Kateatutako bolumenak {pib_trim[0]?.anio_base}. urteko eurotan adierazten dira berriro; biztanleria Eurostaten urteko batez bestekoa da.
