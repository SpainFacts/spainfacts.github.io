---
title: Reclamaciones de acceso a la información
description: "Cuántas reclamaciones de ciudadanos por información denegada o silencio administrativo resuelve el Consejo de Transparencia y Buen Gobierno, en cuántas da la razón al ciudadano y qué ministerios acumulan más."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# <span aria-hidden="true">📨</span> Reclamaciones de acceso a la información

La Ley 19/2013 de Transparencia reconoce el derecho de cualquier ciudadano a solicitar información pública sin necesidad de motivar por qué la pide. Cuando un ministerio u organismo público deniega los datos o guarda silencio administrativo, el solicitante puede presentar una reclamación ante el **Consejo de Transparencia y Buen Gobierno (CTBG)**. Sus memorias anuales muestran cuántas veces tiene que intervenir el regulador para obligar a la Administración a entregar información pública.

<Grid cols=4>
    <KpiCard
        title="Reclamaciones presentadas"
        value={ultimo[0]?.presentadas}
        formattedValue={formatNumber(ultimo[0]?.presentadas, 0)}
        unit="en el año"
        period="ámbito estatal (AGE) en {ultimo[0]?.anio}"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.presentadas}))}
    />
    <KpiCard
        title="Reclamaciones resueltas"
        value={ultimo[0]?.resueltas}
        formattedValue={formatNumber(ultimo[0]?.resueltas, 0)}
        unit="resoluciones"
        period="dictadas por el CTBG en {ultimo[0]?.anio}"
        direction="positive-up"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.resueltas}))}
    />
    <KpiCard
        title="A favor del ciudadano"
        value={ultimo[0]?.pct_estimadas_fondo}
        formattedValue="{formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} %"
        period="de las resoluciones sobre el fondo ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.pct_estimadas_fondo}))}
    />
    <KpiCard
        title="Estimadas en el año"
        value={ultimo[0]?.estimadas}
        formattedValue={formatNumber(ultimo[0]?.estimadas, 0)}
        unit="resoluciones"
        period="obligan a entregar la información ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.estimadas}))}
    />
</Grid>

## 1. En dos de cada tres recursos sobre el fondo, el ciudadano tenía razón

Desde la puesta en marcha del Consejo de Transparencia en 2015, el número de reclamaciones presentadas contra la Administración General del Estado se ha más que triplicado (de 513 en 2015 a **{formatNumber(ultimo[0]?.presentadas, 0)}** en {ultimo[0]?.anio}). Cuando el Consejo entra a valorar el fondo del asunto (descontadas las reclamaciones inadmitidas por presentarse fuera de plazo o no tratarse de información pública), **da la razón total o parcialmente al ciudadano en el {formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)} % de los casos**, ordenando a la Administración entregar los datos que había negado o silenciado.

<BarChart
    data={sentido_resoluciones}
    x=anio
    y=resoluciones
    series=sentido
    type=stacked
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Resoluciones anuales"
    title="Resoluciones del Consejo de Transparencia sobre la Administración del Estado según su sentido"
/>

<LineChart
    data={reclamaciones_anual}
    x=anio
    y=pct_estimadas_fondo
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% a favor del ciudadano"
    startingAtZero={false}
    title="Porcentaje de resoluciones sobre el fondo en las que el CTBG da la razón al ciudadano (%)"
/>

## 2. Qué ministerios acumulan más reclamaciones

Los ministerios de **Interior**, **Hacienda y Función Pública** y **Transportes** concentran el mayor volumen de reclamaciones ante el Consejo de Transparencia, tanto por el volumen de solicitudes que reciben como por el uso frecuente del silencio administrativo o de causas de inadmisión que luego el CTBG revoca.

<BarChart
    data={ministerios_reclamaciones}
    x=ministerio
    y=reclamaciones
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="Reclamaciones anuales"
    title="Departamentos ministeriales con más reclamaciones ante el CTBG ({ultimo[0]?.anio})"
/>

<DataTable data={ministerios_reclamaciones} search=false>
    <Column id=ministerio title="Ministerio (y organismos adscritos)" />
    <Column id=reclamaciones title="Reclamaciones" fmt='#,##0' />
    <Column id=pct_estimadas title="% estimadas (sobre fondo)" fmt='0.0"%"' />
</DataTable>

---

**Fuentes y metodología:**
- [Consejo de Transparencia y Buen Gobierno (CTBG)](https://www.consejodetransparencia.es/) — *Memorias anuales de actividad* y estadísticas de reclamaciones del ámbito estatal (art. 24 de la Ley 19/2013).
- Para consultar el cumplimiento de las obligaciones de publicidad activa de los portales públicos, visita [Portales de transparencia](/transparencia/publicidad-activa).
