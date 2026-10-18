---
title: Reclamacions d'accés a la informació
description: "Quantes reclamacions de ciutadans per informació denegada o silenci administratiu resol el Consell de Transparència i Bon Govern, en quantes dóna la raó al ciutadà i quins ministeris n'acumulen més."
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

# <span aria-hidden="true">📨</span> Reclamacions d'accés a la informació

La Llei 19/2013 de Transparència reconeix el dret de qualsevol ciutadà a sol·licitar informació pública sense necessitat de motivar per què la demana. Quan un ministeri o organisme públic denega les dades o guarda silenci administratiu, el sol·licitant pot presentar una reclamació davant del **Consell de Transparència i Bon Govern (CTBG)**. Les seves memòries anuals mostren quantes vegades ha d'intervenir el regulador per obligar l'Administració a lliurar informació pública.

<Grid cols=4>
    <KpiCard
        title="Reclamacions presentades"
        value={ultimo[0]?.presentadas}
        formattedValue={formatNumber(ultimo[0]?.presentadas, 0)}
        unit="en l'any"
        period="àmbit estatal (AGE) el {ultimo[0]?.anio}"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.presentadas}))}
    />
    <KpiCard
        title="Reclamacions resoltes"
        value={ultimo[0]?.resueltas}
        formattedValue={formatNumber(ultimo[0]?.resueltas, 0)}
        unit="resolucions"
        period="dictades pel CTBG el {ultimo[0]?.anio}"
        direction="positive-up"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.resueltas}))}
    />
    <KpiCard
        title="A favor del ciutadà"
        value={ultimo[0]?.pct_estimadas_fondo}
        formattedValue="{formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} %"
        period="de les resolucions sobre el fons ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.pct_estimadas_fondo}))}
    />
    <KpiCard
        title="Estimades en l'any"
        value={ultimo[0]?.estimadas}
        formattedValue={formatNumber(ultimo[0]?.estimadas, 0)}
        unit="resolucions"
        period="obliguen a lliurar la informació ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.estimadas}))}
    />
</Grid>

## 1. En dos de cada tres recursos sobre el fons, el ciutadà tenia raó

Des de la posada en marxa del Consell de Transparència el 2015, el nombre de reclamacions presentades contra l'Administració General de l'Estat s'ha més que triplicat (de 513 el 2015 a **{formatNumber(ultimo[0]?.presentadas, 0)}** el {ultimo[0]?.anio}). Quan el Consell entra a valorar el fons de l'assumpte (descomptades les reclamacions inadmeses per presentar-se fora de termini o no tractar-se d'informació pública), **dóna la raó totalment o parcialment al ciutadà en el {formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} % dels casos**, ordenant a l'Administració lliurar les dades que havia negat o silenciat.

<BarChart
    data={sentido_resoluciones}
    x=anio
    y=resoluciones
    series=sentido
    type=stacked
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Resolucions anuals"
    title="Resolucions del Consell de Transparència sobre l'Administració de l'Estat segons el seu sentit"
/>

<LineChart
    data={reclamaciones_anual}
    x=anio
    y=pct_estimadas_fondo
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% a favor del ciutadà"
    startingAtZero={false}
    title="Percentatge de resolucions sobre el fons en què el CTBG dóna la raó al ciutadà (%)"
/>

## 2. Quins ministeris acumulen més reclamacions

Els ministeris d'**Interior**, **Hisenda i Funció Pública** i **Transports** concentren el volum més gran de reclamacions davant del Consell de Transparència, tant pel volum de sol·licituds que reben com per l'ús freqüent del silenci administratiu o de causes d'inadmissió que després el CTBG revoca.

<BarChart
    data={ministerios_reclamaciones}
    x=ministerio
    y=reclamaciones
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="Reclamacions anuals"
    title="Departaments ministerials amb més reclamacions davant del CTBG ({ultimo[0]?.anio})"
/>

<DataTable data={ministerios_reclamaciones} search=false>
    <Column id=ministerio title="Ministeri (i organismes adscrits)" />
    <Column id=reclamaciones title="Reclamacions" fmt='#,##0' />
    <Column id=pct_estimadas title="% estimades (sobre fons)" fmt='0.0"%"' />
</DataTable>

---

**Fonts i metodologia:**
- [Consell de Transparència i Bon Govern (CTBG)](https://www.consejodetransparencia.es/) — *Memòries anuals d'activitat* i estadístiques de reclamacions de l'àmbit estatal (art. 24 de la Llei 19/2013).
- Per consultar el compliment de les obligacions de publicitat activa dels portals públics, visita [Portals de transparència](/ca/transparencia/publicidad-activa).
