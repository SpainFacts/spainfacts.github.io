---
title: Freedom of information appeals
description: "How many citizen appeals over denied information or administrative silence are resolved by the Council for Transparency and Good Governance (CTBG), how often the citizen wins and which ministries receive the most complaints."
i18n_origen: 654d28429763
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql reclamaciones_anual
SELECT * FROM (
    VALUES
        (2015, 513, 392, 145, 112, 135, 56.4),
        (2016, 520, 488, 212, 134, 142, 61.3),
        (2017, 709, 645, 298, 168, 179, 63.9),
        (2018, 922, 810, 384, 210, 216, 64.6),
        (2019, 987, 895, 428, 232, 235, 64.8),
        (2020, 1084, 940, 452, 248, 240, 64.6),
        (2021, 1168, 1025, 510, 265, 250, 65.8),
        (2022, 1342, 1180, 602, 294, 284, 67.2),
        (2023, 1590, 1345, 704, 331, 310, 68.0),
        (2024, 1740, 1490, 792, 362, 336, 68.6)
) AS t(anio, presentadas, resueltas, estimadas, desestimadas, inadmitidas_otras, pct_estimadas_fondo)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${reclamaciones_anual} ORDER BY anio DESC LIMIT 1
```

```sql sentido_resoluciones
SELECT anio, 'Estimadas (a favor del ciudadano)' AS sentido, estimadas AS resoluciones FROM ${reclamaciones_anual}
UNION ALL
SELECT anio, 'Desestimadas (a favor de la Administración)' AS sentido, desestimadas AS resoluciones FROM ${reclamaciones_anual}
UNION ALL
SELECT anio, 'Inadmitidas o archivadas' AS sentido, inadmitidas_otras AS resoluciones FROM ${reclamaciones_anual}
ORDER BY anio, sentido
```

```sql ministerios_reclamaciones
SELECT * FROM (
    VALUES
        ('Interior', 248, 69.4),
        ('Hacienda y Función Pública', 215, 66.5),
        ('Transportes y Movilidad Sostenible', 164, 71.3),
        ('Sanidad', 142, 68.3),
        ('Presidencia, Justicia y Relaciones con las Cortes', 138, 64.5),
        ('Trabajo y Economía Social', 112, 67.0),
        ('Transición Ecológica y Reto Demográfico', 104, 72.1),
        ('Educación, FP y Deportes', 86, 65.1)
) AS t(ministerio, reclamaciones, pct_estimadas)
ORDER BY reclamaciones DESC
```

# <span aria-hidden="true">📨</span> Freedom of information appeals

Transparency Law 19/2013 recognises the right of any person to request public information without having to justify why they are asking. When a ministry or public body denies access or fails to reply within the legal deadline, the applicant can file an appeal before the **Council for Transparency and Good Governance (CTBG)**. Its annual reports reveal how often the regulator must step in to order the Administration to release public records.

<Grid cols=4>
    <KpiCard
        title="Appeals filed"
        value={ultimo[0]?.presentadas}
        formattedValue={formatNumber(ultimo[0]?.presentadas, 0)}
        unit="in the year"
        period="central government (AGE) in {ultimo[0]?.anio}"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.presentadas}))}
    />
    <KpiCard
        title="Appeals resolved"
        value={ultimo[0]?.resueltas}
        formattedValue={formatNumber(ultimo[0]?.resueltas, 0)}
        unit="rulings"
        period="issued by CTBG in {ultimo[0]?.anio}"
        direction="positive-up"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.resueltas}))}
    />
    <KpiCard
        title="In favour of the citizen"
        value={ultimo[0]?.pct_estimadas_fondo}
        formattedValue="{formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} %"
        period="of rulings on the merits ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.pct_estimadas_fondo}))}
    />
    <KpiCard
        title="Upheld in the year"
        value={ultimo[0]?.estimadas}
        formattedValue={formatNumber(ultimo[0]?.estimadas, 0)}
        unit="rulings"
        period="ordering disclosure ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.estimadas}))}
    />
</Grid>

## 1. In two out of three substantive rulings, the citizen was right

Since the Transparency Council began operating in 2015, the number of appeals filed against the central government has more than tripled (from 513 in 2015 to **{formatNumber(ultimo[0]?.presentadas, 0)}** in {ultimo[0]?.anio}). When the Council rules on the merits of the case (excluding appeals declared inadmissible for late filing or non-public scope), **it rules wholly or partially in favour of the citizen in {formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} % of cases**, ordering the Administration to release the information it had denied or ignored.

<BarChart
    data={sentido_resoluciones}
    x=anio
    y=resoluciones
    series=sentido
    type=stacked
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Annual rulings"
    title="Transparency Council rulings on the central government by outcome"
/>

<LineChart
    data={reclamaciones_anual}
    x=anio
    y=pct_estimadas_fondo
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% in favour of the citizen"
    startingAtZero={false}
    title="Share of substantive rulings in which the CTBG sides with the citizen (%)"
/>

## 2. Which ministries accumulate the most appeals

The ministries of the **Interior**, **Finance and Civil Service** and **Transport** account for the largest volume of appeals before the Transparency Council, due both to the high number of requests they receive and to the frequent use of administrative silence or inadmissibility grounds subsequently overturned by the CTBG.

<BarChart
    data={ministerios_reclamaciones}
    x=ministerio
    y=reclamaciones
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="Annual appeals"
    title="Ministerial departments with the most appeals before the CTBG ({ultimo[0]?.anio})"
/>

<DataTable data={ministerios_reclamaciones} search=false>
    <Column id=ministerio title="Ministry (and attached bodies)" />
    <Column id=reclamaciones title="Appeals" fmt='#,##0' />
    <Column id=pct_estimadas title="% upheld (on merits)" fmt='0.0"%"' />
</DataTable>

---

**Sources and methodology:**
- [Council for Transparency and Good Governance (CTBG)](https://www.consejodetransparencia.es/) — *Annual Activity Reports* and central government appeal statistics (Article 24 of Law 19/2013).
- For compliance with proactive disclosure obligations on public portals, see [Transparency portals](/en/transparencia/publicidad-activa).
