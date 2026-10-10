---
title: Pardons
description: "How many pardons each Spanish government has granted since 1977 according to the BOE, how they have changed and how each prime minister and each party compares given the time it has been in power."
i18n_origen: a455aff1d882
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresPartido = { 'PSOE': '#e30613', 'PP': '#1d84ce', 'UCD': '#2f9c95' };
</script>

```sql anual
SELECT
    CAST(anio AS INTEGER) AS anio,
    CAST(indultos AS INTEGER) AS indultos,
    presidente,
    familia AS partido,
    anio_en_curso
FROM mother.gobierno_actos_anual
ORDER BY anio
```

```sql anual_completo
SELECT * FROM ${anual} WHERE NOT anio_en_curso
```

```sql resumen
WITH u AS (SELECT max(anio) AS anio FROM ${anual_completo})
SELECT
    u.anio AS ultimo_anio,
    max(a.indultos) FILTER (WHERE a.anio = u.anio) AS ultimo,
    avg(a.indultos) FILTER (WHERE a.anio BETWEEN u.anio - 9 AND u.anio) AS media_10,
    avg(a.indultos) FILTER (WHERE a.anio BETWEEN 1996 AND 2005) AS media_9605,
    sum(a.indultos) AS total,
    max(a.indultos) AS maximo,
    arg_max(a.anio, a.indultos) AS anio_maximo,
    (SELECT max(indultos) FROM ${anual} WHERE anio_en_curso) AS en_curso,
    (SELECT max(anio) FROM ${anual}) AS anio_en_curso
FROM ${anual_completo} a, u
GROUP BY u.anio
```

```sql pico
SELECT CAST(anio AS INTEGER) AS anio, CAST(indultos AS INTEGER) AS indultos
FROM mother.gobierno_indultos_mensual
ORDER BY indultos DESC
LIMIT 1
```

```sql minimos
SELECT CAST(max(anio) + 1 AS INTEGER) AS desde FROM ${anual} WHERE indultos > 100
```

```sql presidencias
SELECT
    grupo AS presidente,
    familia AS partido,
    CAST(year(desde) AS INTEGER) AS desde,
    CASE WHEN hasta IS NULL THEN 'hoy' ELSE CAST(year(hasta) AS VARCHAR) END AS hasta,
    anios,
    CAST(indultos AS INTEGER) AS indultos,
    indultos_por_anio,
    indultos_esperados AS esperados,
    indultos_ratio AS ratio,
    orden
FROM mother.gobierno_presidencias_resumen
WHERE nivel = 'Presidente'
ORDER BY orden
```

```sql actual
SELECT * FROM ${presidencias} WHERE hasta = 'hoy'
```

```sql partidos
SELECT
    grupo AS partido,
    anios,
    CAST(indultos AS INTEGER) AS observados,
    indultos_esperados AS esperados,
    indultos_ratio AS ratio,
    indultos_por_anio
FROM mother.gobierno_presidencias_resumen
WHERE nivel = 'Partido'
ORDER BY orden
```

```sql partidos_resumen
SELECT
    max(ratio) FILTER (WHERE partido = 'PSOE') AS psoe,
    max(ratio) FILTER (WHERE partido = 'PP') AS pp,
    max(ratio) FILTER (WHERE partido = 'UCD') AS ucd
FROM ${partidos}
```

```sql misma_epoca
-- Años completos gobernados por un solo presidente desde 1997
SELECT
    familia AS partido,
    count(*) AS anios,
    avg(indultos) AS indultos_por_anio,
    median(indultos) AS mediana
FROM mother.gobierno_actos_anual
WHERE anio >= 1997 AND NOT anio_en_curso AND NOT cambio_de_gobierno
GROUP BY familia
ORDER BY familia
```

# ⚖️ Pardons

A **pardon** (indulto) is the act of clemency by which the Government remits, wholly or in part, the sentence imposed by a final judgment. It is granted by the Council of Ministers by royal decree, on the proposal of the Ministry of Justice and after a report from the court that handed down the sentence (Act of 18 June 1870, amended in 1988 and 2015). The Constitution prohibits general pardons (art. 62.i): all pardons are individual and all are published in the Official State Gazette (BOE). This page counts them.

<Grid cols=4>
    <KpiCard
        title="Pardons in {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.ultimo}
        formattedValue={formatNumber(resumen[0]?.ultimo, 0)}
        period="{formatNumber(resumen[0]?.en_curso, 0)} so far in {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.indultos}))}
    />
    <KpiCard
        title="Average over the last ten years"
        value={resumen[0]?.media_10}
        formattedValue={formatNumber(resumen[0]?.media_10, 0)}
        unit="a year"
        period="compared with {formatNumber(resumen[0]?.media_9605, 0)} a year between 1996 and 2005"
        source="BOE"
    />
    <KpiCard
        title="Current government's pace"
        value={actual[0]?.indultos_por_anio}
        formattedValue={formatNumber(actual[0]?.indultos_por_anio, 0)}
        unit="a year"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.indultos, 0)} pardons since {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Year with most pardons"
        value={resumen[0]?.maximo}
        formattedValue={formatNumber(resumen[0]?.maximo, 0)}
        period="in {resumen[0]?.anio_maximo} · {formatNumber(resumen[0]?.total, 0)} in total since 1978"
        source="BOE"
    />
</Grid>

## How many are granted each year

Royal pardon decrees by year of approval by the Council of Ministers, coloured by the party of the prime minister who governed for longest that year. {resumen[0]?.anio_en_curso} only includes the year so far.

<BarChart
    data={anual}
    x=anio
    y=indultos
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Pardons"
    title="Pardons granted per year"
/>

The series has occasional spikes of pardons approved in batches: the largest, in December {pico[0]?.anio}, with {formatNumber(pico[0]?.indultos, 0)} royal pardon decrees approved in a single month. Since {minimos[0]?.desde} no year has exceeded 100 pardons, the lowest levels in the whole series.

## By government

Each pardon is attributed to the prime minister in office on the day the Council of Ministers approved the royal decree. To compare terms of different length, the table gives the **average per year in office**.

<BarChart
    data={presidencias}
    x=presidente
    y=indultos_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0'
    title="Pardons per year in office, by prime minister"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Prime minister"/>
    <Column id=partido title="Party"/>
    <Column id=desde title="From" fmt='0'/>
    <Column id=hasta title="To"/>
    <Column id=anios title="Years" fmt='0.0'/>
    <Column id=indultos title="Pardons" fmt='0'/>
    <Column id=indultos_por_anio title="Per year" fmt='0' contentType=bar barColor="#c4b5fd"/>
    <Column id=ratio title="Observed / expected" fmt='0.00'/>
</DataTable>

## By party: observed versus expected

The **expected** figures are the pardons each party would have granted if every government since 1977 had pardoned at the same pace, according to the time each one has governed. A ratio of 1 is what would be expected; 2, twice as many; 0.5, half.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Prime minister's party"/>
    <Column id=anios title="Years in office" fmt='0.0'/>
    <Column id=observados title="Observed" fmt='0'/>
    <Column id=esperados title="Expected given time in office" fmt='0'/>
    <Column id=ratio title="Observed / expected" fmt='0.00'/>
    <Column id=indultos_por_anio title="Per year" fmt='0'/>
</DataTable>

On this calculation, the PSOE has granted {formatNumber(partidos_resumen[0]?.psoe, 2)} times the pardons expected given its time in office, the PP {formatNumber(partidos_resumen[0]?.pp, 2)} times and the UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. As with any long series, the pace has not been constant: the number of people convicted, criminal law and the courts' approach when reporting have changed a great deal since 1977. That is why it is worth also looking at the comparison within the same period: since 1997, in the full years governed by a single prime minister.

<DataTable data={misma_epoca} rows=all>
    <Column id=partido title="Prime minister's party"/>
    <Column id=anios title="Full years (1997-)" fmt='0'/>
    <Column id=indultos_por_anio title="Pardons per year (average)" fmt='0'/>
    <Column id=mediana title="Median" fmt='0'/>
</DataTable>

## Methodology and sources

- **Source:** daily summaries of the [Official State Gazette (BOE)](https://www.boe.es/datosabiertos/), open data API, since July 1977: royal decrees in section III («Otras disposiciones», other provisions), heading «Indultos», whose title reads «por el que se indulta» (granting a pardon) or «por el que se conmuta» (commuting a sentence). Corrections of errors are not counted.
- **What is counted:** royal pardon decrees, not people. Some decrees pardon several people and some people receive more than one pardon. No distinction is made between full and partial pardons (the BOE states this in the text of the decree, not in the title). The names of the people pardoned are not stored.
- **Date and government:** the date is that of the royal decree (the Council of Ministers date, shown in the title), not the publication date, which may come weeks later; it is attributed to the prime minister in office that day, including when acting in a caretaker capacity. For the few undated titles (1977-1978) the publication date is used.
- **Expected:** total pardons since 5 July 1977 multiplied by the share of that time each party governed. It assumes a constant pace, which is not the case (see the text).
- **International comparison:** not included; the institution of pardon and how it is published vary greatly from one country to another and there is no consistent official statistic.
