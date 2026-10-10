---
title: Decree-laws
description: "How many royal decree-laws each Spanish government has passed since 1977, what share of law-ranking rules are made by decree, how many Congress validates or rejects and how each party compares given the time it has been in power."
i18n_origen: 2922ec7a33e0
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
    CAST(rdl AS INTEGER) AS decretos_ley,
    CAST(leyes AS INTEGER) AS leyes,
    pct_rdl,
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
    max(a.decretos_ley) FILTER (WHERE a.anio = u.anio) AS rdl_ultimo,
    max(a.pct_rdl) FILTER (WHERE a.anio = u.anio) AS pct_ultimo,
    avg(a.decretos_ley) FILTER (WHERE a.anio BETWEEN 1979 AND u.anio) AS media_rdl,
    100.0 * sum(a.decretos_ley) FILTER (WHERE a.anio BETWEEN 1979 AND u.anio)
        / sum(a.decretos_ley + a.leyes) FILTER (WHERE a.anio BETWEEN 1979 AND u.anio) AS pct_historico,
    (SELECT max(decretos_ley) FROM ${anual} WHERE anio_en_curso) AS rdl_en_curso,
    (SELECT max(anio) FROM ${anual}) AS anio_en_curso
FROM ${anual_completo} a, u
GROUP BY u.anio
```

```sql presidencias
SELECT
    grupo AS presidente,
    familia AS partido,
    CAST(year(desde) AS INTEGER) AS desde,
    CASE WHEN hasta IS NULL THEN 'hoy' ELSE CAST(year(hasta) AS VARCHAR) END AS hasta,
    anios,
    CAST(rdl AS INTEGER) AS decretos_ley,
    rdl_por_anio,
    leyes_por_anio,
    pct_rdl,
    CAST(rdl_derogados AS INTEGER) AS derogados,
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
    CAST(rdl AS INTEGER) AS observados,
    rdl_esperados AS esperados,
    rdl_ratio AS ratio,
    rdl_z AS z,
    rdl_por_anio,
    pct_rdl
FROM mother.gobierno_presidencias_resumen
WHERE nivel = 'Partido'
ORDER BY orden
```

```sql partidos_resumen
SELECT
    max(ratio) FILTER (WHERE partido = 'PSOE') AS psoe,
    max(ratio) FILTER (WHERE partido = 'PP') AS pp,
    max(ratio) FILTER (WHERE partido = 'UCD') AS ucd,
    max(rdl_por_anio) FILTER (WHERE partido = 'PSOE') AS psoe_anio,
    max(rdl_por_anio) FILTER (WHERE partido = 'PP') AS pp_anio,
    max(pct_rdl) FILTER (WHERE partido = 'PSOE') AS psoe_pct,
    max(pct_rdl) FILTER (WHERE partido = 'PP') AS pp_pct
FROM ${partidos}
```

```sql decadas
-- Mismo periodo, distinto partido: ritmo por año gobernado desde 1996, cuando PP y PSOE
-- se alternan en una época en que el decreto-ley ya es de uso habitual
SELECT
    familia AS partido,
    count(*) AS anios,
    avg(rdl) AS rdl_por_anio,
    100.0 * sum(rdl) / sum(rdl + leyes) AS pct_rdl
FROM mother.gobierno_actos_anual
WHERE anio >= 1997 AND NOT anio_en_curso AND NOT cambio_de_gobierno
GROUP BY familia
ORDER BY familia
```

```sql estados
SELECT
    estado,
    count(*) AS decretos_ley
FROM mother.gobierno_decretos_ley
WHERE fecha_disposicion >= DATE '1979-01-01'
GROUP BY estado
ORDER BY decretos_ley DESC
```

```sql estados_resumen
SELECT
    count(*) FILTER (WHERE estado = 'Derogado') AS derogados,
    count(*) FILTER (WHERE estado = 'Convalidado') AS convalidados,
    count(*) FILTER (WHERE estado = 'Sin resolución en el BOE') AS sin_resolucion,
    count(*) FILTER (WHERE estado = 'Sin resolución en el BOE' AND fecha_disposicion >= current_date - 60) AS recientes,
    count(*) AS total
FROM mother.gobierno_decretos_ley
WHERE fecha_disposicion >= DATE '1979-01-01'
```

```sql derogados
SELECT
    numero_oficial,
    fecha_disposicion,
    presidente,
    familia AS partido,
    titulo,
    url_html
FROM mother.gobierno_decretos_ley
WHERE estado = 'Derogado'
ORDER BY fecha_disposicion DESC
```

```sql listado
SELECT
    numero_oficial,
    fecha_disposicion,
    presidente,
    familia AS partido,
    estado,
    titulo,
    url_html
FROM mother.gobierno_decretos_ley
ORDER BY fecha_disposicion DESC, numero DESC
```

# 📜 Decree-laws: governing by decree

A **royal decree-law** is a rule with the force of law passed by the Government, not by Parliament (the Cortes). The Constitution (art. 86) only allows it in cases of **extraordinary and urgent need**, bars it from certain matters (fundamental rights, State institutions, electoral law...) and requires Congress to **validate or reject** it within the following 30 working days. Using the Official State Gazette (BOE), this page counts how many each government passes and what share of legislation is made this way.

<Grid cols=4>
    <KpiCard
        title="Decree-laws in {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.rdl_ultimo}
        formattedValue={formatNumber(resumen[0]?.rdl_ultimo, 0)}
        period="average since 1979: {formatNumber(resumen[0]?.media_rdl, 1)} a year · {formatNumber(resumen[0]?.rdl_en_curso, 0)} so far in {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.decretos_ley}))}
    />
    <KpiCard
        title="Share of law-ranking rules"
        value={resumen[0]?.pct_ultimo}
        formattedValue="{formatNumber(resumen[0]?.pct_ultimo, 0)}%"
        period="decree-laws over decree-laws + laws in {resumen[0]?.ultimo_anio} · {formatNumber(resumen[0]?.pct_historico, 0)}% since 1979"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.pct_rdl}))}
    />
    <KpiCard
        title="Current government's pace"
        value={actual[0]?.rdl_por_anio}
        formattedValue={formatNumber(actual[0]?.rdl_por_anio, 1)}
        unit="a year"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.decretos_ley, 0)} decree-laws since {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Rejected by Congress"
        value={estados_resumen[0]?.derogados}
        formattedValue={formatNumber(estados_resumen[0]?.derogados, 0)}
        period="out of {formatNumber(estados_resumen[0]?.total, 0)} decree-laws since 1979; the rest were validated or are pending"
        source="BOE (Congress resolutions)"
    />
</Grid>

## How many are passed each year

Decree-laws passed each year, coloured by the party of the prime minister who governed for longest that year. {resumen[0]?.anio_en_curso} only includes the year so far.

<BarChart
    data={anual}
    x=anio
    y=decretos_ley
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Decree-laws"
    title="Royal decree-laws passed per year"
/>

The number of decree-laws does not depend only on who is in government: the years with the most decrees often coincide with crises (2012, in the depths of the financial crisis; 2020, with the pandemic), and election years, with Parliament dissolved for part of the year, have fewer laws and therefore a higher share of decree-laws.

## What share of legislation is made by decree

So as not to depend on how much legislation is passed each year, the chart shows the **percentage of decree-laws out of all the State's law-ranking rules** (decree-laws plus laws and organic laws passed by Parliament). 50% means that for every law passed by Parliament the Government passed one decree-law.

<LineChart
    data={anual_completo}
    x=anio
    y=pct_rdl
    xFmt='0'
    yFmt='0'
    yAxisTitle="% decree-laws"
    title="Decree-laws as a share of all law-ranking rules (%)"
/>

## By government

Each decree-law is attributed to the prime minister in office on the day the Council of Ministers approved it (the date in its title). To compare terms of different length, the table gives the **average per year in office**.

<BarChart
    data={presidencias}
    x=presidente
    y=rdl_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0.0'
    title="Decree-laws per year in office, by prime minister"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Prime minister"/>
    <Column id=partido title="Party"/>
    <Column id=desde title="From" fmt='0'/>
    <Column id=hasta title="To"/>
    <Column id=anios title="Years" fmt='0.0'/>
    <Column id=decretos_ley title="Decree-laws" fmt='0'/>
    <Column id=rdl_por_anio title="Per year" fmt='0.0' contentType=bar barColor="#fca5a5"/>
    <Column id=leyes_por_anio title="Laws per year" fmt='0.0'/>
    <Column id=pct_rdl title="% decree-laws" fmt='0'/>
    <Column id=derogados title="Rejected" fmt='0'/>
</DataTable>

## By party: observed versus expected

A simple count favours whoever has governed least. The table compares each party's decree-laws with those **expected** if every government since 1977 had passed decree-laws at the same pace, shared out according to the time each one has governed. A ratio of 1 is what would be expected; 2, twice as many; 0.5, half.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Prime minister's party"/>
    <Column id=anios title="Years in office" fmt='0.0'/>
    <Column id=observados title="Observed" fmt='0'/>
    <Column id=esperados title="Expected given time in office" fmt='0.0'/>
    <Column id=ratio title="Observed / expected" fmt='0.00'/>
    <Column id=pct_rdl title="% decree-laws" fmt='0'/>
</DataTable>

The PSOE has passed {formatNumber(partidos_resumen[0]?.psoe, 2)} times the decree-laws that would correspond to its time in office, the PP {formatNumber(partidos_resumen[0]?.pp, 2)} times and the UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. This comparison has an important limitation: the use of decree-laws **has grown over the years**, so more recent governments come off worse than the earliest ones. That is why it is worth also looking at the comparison within the same period: since 1997, in the full years governed by a single prime minister, the PP and the PSOE have alternated in power.

<DataTable data={decadas} rows=all>
    <Column id=partido title="Prime minister's party"/>
    <Column id=anios title="Full years (1997-)" fmt='0'/>
    <Column id=rdl_por_anio title="Decree-laws per year" fmt='0.0'/>
    <Column id=pct_rdl title="% decree-laws" fmt='0'/>
</DataTable>

## Validated and rejected

Congress must vote on each decree-law within 30 working days of its publication. If it **validates** it, it remains in force (and Congress may also process it as a bill in order to amend it); if it **rejects** it, it ceases to be in force. Since 1979, Congress has rejected {formatNumber(estados_resumen[0]?.derogados, 0)} decree-laws. In {formatNumber(estados_resumen[0]?.sin_resolucion, 0)} cases the Congress resolution could not be found in the BOE: {formatNumber(estados_resumen[0]?.recientes, 0)} are from the last 60 days (awaiting a vote) and the rest mostly from the early years, when the resolution was not always published in the BOE under that title.

<DataTable data={derogados} rows=all link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decree-law"/>
    <Column id=fecha_disposicion title="Date" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Prime minister"/>
    <Column id=partido title="Party"/>
    <Column id=titulo title="Title" wrap=true/>
</DataTable>

## All decree-laws

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decree-law"/>
    <Column id=fecha_disposicion title="Date" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Prime minister"/>
    <Column id=partido title="Party"/>
    <Column id=estado title="Congress"/>
    <Column id=titulo title="Title" wrap=true/>
</DataTable>

## Methodology and sources

- **Source:** daily summaries of the [Official State Gazette (BOE)](https://www.boe.es/datosabiertos/), open data API, since July 1977. We take the royal decree-laws and laws from section I (Head of State) and the resolutions of the Congress of Deputies ordering publication of the validation or rejection of each decree-law. Each rule is counted once even if the BOE publishes it in several parts.
- **Date and government:** the date is that of the provision (the Council of Ministers date, shown in the title), not the publication date; the decree is attributed to the prime minister in office that day, including when acting in a caretaker capacity. Premierships: Adolfo Suárez (UCD) until 26 February 1981, Leopoldo Calvo-Sotelo (UCD), Felipe González (PSOE), José María Aznar (PP), José Luis Rodríguez Zapatero (PSOE), Mariano Rajoy (PP) and Pedro Sánchez (PSOE; in coalition with Unidas Podemos and later Sumar since January 2020).
- **Force of law:** the percentage compares decree-laws with laws and organic laws passed by Parliament (including the budget act). It does not include legislative decrees (consolidated texts the Government approves under powers delegated by Parliament) or regional laws.
- **Expected:** total decree-laws since 5 July 1977 multiplied by the share of that time each party governed. It assumes a constant pace, which is not the case (see the text).
- **Validation:** before the Constitution (29 December 1978) decree-laws did not need to be validated by Congress; that is why the status counts start in 1979.
- **International comparison:** not included. Each country has different instruments (decreti-legge in Italy, ordonnances in France, medidas provisórias in Brazil...) and there is no consistent official statistic.
