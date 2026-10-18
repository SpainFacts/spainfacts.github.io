---
title: Reclamacións de acceso á información
description: "Cantas reclamacións de cidadáns por información denegada ou silencio administrativo resolve o Consello de Transparencia e Bo Goberno, en cantas lle dá a razón ao cidadán e que ministerios acumulan máis."
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

# <span aria-hidden="true">📨</span> Reclamacións de acceso á información

A Lei 19/2013 de Transparencia recoñece o dereito de calquera cidadán a solicitar información pública sen necesidade de motivar por que a pide. Cando un ministerio ou organismo público denega os datos ou garda silencio administrativo, o solicitante pode presentar unha reclamación ante o **Consello de Transparencia e Bo Goberno (CTBG)**. As súas memorias anuais mostran cantas veces ten que intervir o regulador para obrigar a Administración a entregar información pública.

<Grid cols=4>
    <KpiCard
        title="Reclamacións presentadas"
        value={ultimo[0]?.presentadas}
        formattedValue={formatNumber(ultimo[0]?.presentadas, 0)}
        unit="no ano"
        period="ámbito estatal (AXE) en {ultimo[0]?.anio}"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.presentadas}))}
    />
    <KpiCard
        title="Reclamacións resoltas"
        value={ultimo[0]?.resueltas}
        formattedValue={formatNumber(ultimo[0]?.resueltas, 0)}
        unit="resolucións"
        period="ditadas polo CTBG en {ultimo[0]?.anio}"
        direction="positive-up"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.resueltas}))}
    />
    <KpiCard
        title="A favor do cidadán"
        value={ultimo[0]?.pct_estimadas_fondo}
        formattedValue="{formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} %"
        period="das resolucións sobre o fondo ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.pct_estimadas_fondo}))}
    />
    <KpiCard
        title="Estimadas no ano"
        value={ultimo[0]?.estimadas}
        formattedValue={formatNumber(ultimo[0]?.estimadas, 0)}
        unit="resolucións"
        period="obrigan a entregar a información ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.estimadas}))}
    />
</Grid>

## 1. En dous de cada tres recursos sobre o fondo, o cidadán tiña razón

Desde a posta en marcha do Consello de Transparencia en 2015, o número de reclamacións presentadas contra a Administración Xeral do Estado máis que se triplicou (de 513 en 2015 a **{formatNumber(ultimo[0]?.presentadas, 0)}** en {ultimo[0]?.anio}). Cando o Consello entra a valorar o fondo do asunto (descontadas as reclamacións inadmitidas por presentarse fóra de prazo ou non tratarse de información pública), **dálle a razón total ou parcialmente ao cidadán no {formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} % dos casos**, ordenando á Administración entregar os datos que negara ou silenciara.

<BarChart
    data={sentido_resoluciones}
    x=anio
    y=resoluciones
    series=sentido
    type=stacked
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Resolucións anuais"
    title="Resolucións do Consello de Transparencia sobre a Administración do Estado segundo o seu sentido"
/>

<LineChart
    data={reclamaciones_anual}
    x=anio
    y=pct_estimadas_fondo
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% a favor do cidadán"
    startingAtZero={false}
    title="Porcentaxe de resolucións sobre o fondo nas que o CTBG lle dá a razón ao cidadán (%)"
/>

## 2. Que ministerios acumulan máis reclamacións

Os ministerios de **Interior**, **Facenda e Función Pública** e **Transportes** concentran o maior volume de reclamacións ante o Consello de Transparencia, tanto polo volume de solicitudes que reciben como polo uso frecuente do silencio administrativo ou de causas de inadmisión que logo o CTBG revoga.

<BarChart
    data={ministerios_reclamaciones}
    x=ministerio
    y=reclamaciones
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="Reclamacións anuais"
    title="Departamentos ministeriais con máis reclamacións ante o CTBG ({ultimo[0]?.anio})"
/>

<DataTable data={ministerios_reclamaciones} search=false>
    <Column id=ministerio title="Ministerio (e organismos adscritos)" />
    <Column id=reclamaciones title="Reclamacións" fmt='#,##0' />
    <Column id=pct_estimadas title="% estimadas (sobre fondo)" fmt='0.0"%"' />
</DataTable>

---

**Fontes e metodoloxía:**
- [Consello de Transparencia e Bo Goberno (CTBG)](https://www.consejodetransparencia.es/) — *Memorias anuais de actividade* e estatísticas de reclamacións do ámbito estatal (art. 24 da Lei 19/2013).
- Para consultar o cumprimento das obrigas de publicidade activa dos portais públicos, visita [Portais de transparencia](/gl/transparencia/publicidad-activa).
