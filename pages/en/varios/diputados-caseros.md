---
title: How many MPs are landlords?
description: "How many members of the Congress of Deputies declare rental income or own several homes, what real estate they declare, how many whole urban properties each MP and each party owns, according to their declarations of assets and income, and compared with all personal income tax filers."
i18n_origen: dbee8acb0fd6
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql resumen
SELECT orden, definicion_id, definicion, n_cumplen, pct, n_diputados, n_validos, n_excluidos,
       mediana_urbanos, CAST(ejercicio_rentas AS INTEGER) AS ejercicio_rentas,
       strftime(primera_declaracion, '%d/%m/%Y') AS primera, strftime(ultima_declaracion, '%d/%m/%Y') AS ultima
FROM mother.diputados_inmuebles_resumen
ORDER BY orden
```

```sql kpi
SELECT
    max(r.pct) FILTER (WHERE r.definicion_id = 'alquila') AS pct_alquila,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'alquila') AS n_alquila,
    max(r.pct) FILTER (WHERE r.definicion_id = 'dos_viviendas') AS pct_dos_viviendas,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'dos_viviendas') AS n_dos_viviendas,
    max(r.pct) FILTER (WHERE r.definicion_id = 'dos_urbanos') AS pct_dos_urbanos,
    max(r.pct) FILTER (WHERE r.definicion_id = 'dos_equivalentes') AS pct_dos_equivalentes,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'dos_equivalentes') AS n_dos_equivalentes,
    max(r.pct) FILTER (WHERE r.definicion_id = 'sin_urbanos') AS pct_sin_urbanos,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'sin_urbanos') AS n_sin_urbanos,
    max(r.n_validos) AS n_validos, max(r.n_diputados) AS n_diputados, max(r.n_excluidos) AS n_excluidos,
    max(r.mediana_urbanos) AS mediana_urbanos,
    max(p.media_urbanos_equivalentes) AS media_completos,
    max(p.mediana_urbanos_equivalentes) AS mediana_completos
FROM mother.diputados_inmuebles_resumen r
CROSS JOIN (SELECT * FROM mother.diputados_inmuebles_partidos WHERE partido = 'Total') p
```

```sql irpf
SELECT
    max(pct) FILTER (WHERE colectivo = 'Declarantes IRPF (todos)' AND indicador_id = 'alquila') AS pct_todos,
    max(pct) FILTER (WHERE tramo = '(60 - 150]' AND indicador_id = 'alquila') AS pct_tramo,
    max(pct) FILTER (WHERE colectivo = 'Declarantes IRPF (todos)' AND indicador_id = 'inmuebles_a_disposicion') AS pct_disposicion
FROM mother.diputados_inmuebles_poblacion
WHERE anio = 2022
```

```sql irpf_tramos
SELECT tramo, pct, n, total
FROM mother.diputados_inmuebles_poblacion
WHERE anio = 2022 AND indicador_id = 'alquila' AND colectivo LIKE 'Declarantes IRPF, rendimientos%' AND tramo <> 'Negativo y Cero'
ORDER BY CASE tramo WHEN '(0 - 1,5]' THEN 1 WHEN '(1,5 - 6]' THEN 2 WHEN '(6 - 12]' THEN 3 WHEN '(12 - 21]' THEN 4 WHEN '(21 - 30]' THEN 5
                    WHEN '(30 - 60]' THEN 6 WHEN '(60 - 150]' THEN 7 WHEN '(150 - 601]' THEN 8 ELSE 9 END
```

```sql comparacion
SELECT 'Diputados del Congreso' AS colectivo, pct, 1 AS orden FROM mother.diputados_inmuebles_poblacion WHERE anio = 2022 AND colectivo LIKE 'Diputados%' AND indicador_id = 'alquila'
UNION ALL
SELECT 'Todos los declarantes del IRPF', pct, 2 FROM mother.diputados_inmuebles_poblacion WHERE anio = 2022 AND colectivo = 'Declarantes IRPF (todos)' AND indicador_id = 'alquila'
UNION ALL
SELECT 'Declarantes con rendimientos de 60.000 a 150.000 €', pct, 3 FROM mother.diputados_inmuebles_poblacion WHERE anio = 2022 AND tramo = '(60 - 150]' AND indicador_id = 'alquila'
ORDER BY orden
```

```sql grupos
SELECT grupo, grupo_parlamentario, CAST(n_validos AS INTEGER) AS diputados, pct_alquila, pct_dos_viviendas, pct_dos_urbanos,
       pct_dos_equivalentes, pct_sin_urbanos, mediana_urbanos, mediana_alquiler_real_eur
FROM mother.diputados_inmuebles_grupos
WHERE grupo <> 'Total'
ORDER BY n_validos DESC
```

```sql grupos_largo
SELECT grupo, 'Declara ingresos por alquiler' AS medida, pct_alquila AS pct, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
UNION ALL
SELECT grupo, '2 o más viviendas', pct_dos_viviendas, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
ORDER BY n_validos DESC, medida
```

```sql distribucion
SELECT CASE WHEN urbanos_equivalentes = 0 THEN 'Ninguno'
            WHEN urbanos_equivalentes < 1 THEN 'Menos de 1'
            WHEN urbanos_equivalentes < 2 THEN 'De 1 a menos de 2'
            WHEN urbanos_equivalentes < 3 THEN 'De 2 a menos de 3'
            WHEN urbanos_equivalentes < 5 THEN 'De 3 a menos de 5'
            WHEN urbanos_equivalentes < 10 THEN 'De 5 a menos de 10'
            ELSE '10 o más' END AS tramo,
       CASE WHEN urbanos_equivalentes = 0 THEN 1 WHEN urbanos_equivalentes < 1 THEN 2 WHEN urbanos_equivalentes < 2 THEN 3
            WHEN urbanos_equivalentes < 3 THEN 4 WHEN urbanos_equivalentes < 5 THEN 5 WHEN urbanos_equivalentes < 10 THEN 6 ELSE 7 END AS orden,
       count(*) AS diputados
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
GROUP BY ALL
ORDER BY orden
```

```sql tipos_total
SELECT categoria, por_diputado, pct, unidades
FROM mother.diputados_inmuebles_composicion
WHERE partido = 'Total' AND desglose = 'tipo'
ORDER BY orden
```

```sql adquisicion
SELECT c.partido, c.categoria, c.pct, c.orden, p.media_urbanos_equivalentes
FROM mother.diputados_inmuebles_composicion c
JOIN mother.diputados_inmuebles_partidos p ON p.partido = c.partido
WHERE c.desglose = 'adquisicion' AND (p.n_validos >= 5 OR c.partido = 'Total')
ORDER BY c.orden_total, p.media_urbanos_equivalentes DESC, c.orden
```

```sql adquisicion_total
SELECT max(pct) FILTER (WHERE categoria = 'Herencia o donación') AS pct_herencia,
       max(pct) FILTER (WHERE categoria = 'Compra') AS pct_compra
FROM mother.diputados_inmuebles_composicion
WHERE partido = 'Total' AND desglose = 'adquisicion'
```

```sql partidos
SELECT partido, CAST(n_validos AS INTEGER) AS diputados, media_urbanos_equivalentes, mediana_urbanos_equivalentes,
       media_urbanos, media_viviendas, media_rusticos, pct_dos_viviendas, max_urbanos_equivalentes
FROM mother.diputados_inmuebles_partidos
WHERE partido <> 'Total'
ORDER BY media_urbanos_equivalentes DESC
```

```sql partidos_grafico
SELECT partido, media_urbanos_equivalentes FROM mother.diputados_inmuebles_partidos
WHERE partido <> 'Total' AND n_validos >= 5
ORDER BY media_urbanos_equivalentes DESC
```

```sql partidos_tipos
SELECT c.partido, c.categoria, c.por_diputado, c.orden, p.media_urbanos_equivalentes
FROM mother.diputados_inmuebles_composicion c
JOIN mother.diputados_inmuebles_partidos p ON p.partido = c.partido
WHERE c.desglose = 'tipo' AND c.partido <> 'Total' AND p.n_validos >= 5
ORDER BY p.media_urbanos_equivalentes DESC, c.orden
```

```sql ranking
SELECT row_number() OVER (ORDER BY urbanos_equivalentes DESC, n_urbanos DESC, nombre) AS puesto,
       nombre, partido, circunscripcion, urbanos_equivalentes, n_urbanos, n_viviendas_urbanas, n_rusticos,
       n_inmuebles_sociedad,
       CASE WHEN alquila THEN 'Sí' ELSE 'No' END AS alquila,
       CASE WHEN revisado_a_mano THEN 'Sí' WHEN inmuebles_sin_contar THEN 'No: hay más en Observaciones' ELSE '' END AS revisado,
       url_pdf
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
ORDER BY puesto
```

```sql ranking_top
SELECT nombre || ' (' || partido || ')' AS diputado, urbanos_equivalentes, puesto FROM ${ranking} WHERE puesto <= 15 ORDER BY puesto
```

# <span aria-hidden="true">🏘️</span> How many MPs are landlords?

When they take their seats, members of the Congress of Deputies submit a declaration of assets and income that is published on their profile page. We have read those of the {kpi[0]?.n_diputados} sitting MPs of the 15th Legislature to count how many declare rental income, how many own more than one home and what properties each one declares. Everything that follows is what their declarations state.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declare rental income"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="of MPs"
        period={`${kpi[0].n_alquila} of ${kpi[0].n_validos} · income tax: ${formatNumber(irpf[0].pct_todos, 1)} % of filers`}
        source="Congress of Deputies"
    />
    <KpiCard
        title="Own 2 or more homes"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="of MPs"
        period={`${kpi[0].n_dos_viviendas} of ${kpi[0].n_validos} MPs`}
        source="Congress of Deputies"
    />
    <KpiCard
        title="2 or more whole urban properties"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="of MPs"
        period={`Adding up their share of each property · ${kpi[0].n_dos_equivalentes} MPs`}
        source="Congress of Deputies"
    />
    <KpiCard
        title="Whole urban properties per MP"
        value={kpi[0].media_completos}
        formattedValue={formatNumber(kpi[0].media_completos, 1)}
        unit="on average"
        period={`Median: ${formatNumber(kpi[0].mediana_completos, 1)} · ${kpi[0].n_sin_urbanos} MPs with none`}
        source="Congress of Deputies"
    />
    {/if}
</div>

## What being a landlord means

There is no single way to measure it, so several are given. The strictest is declaring rental income, which is not exactly the same as having something let out: someone may have it and not itemise it as separate income. {formatNumber(kpi[0]?.pct_alquila, 1)} % of MPs declare it. Counting those who own at least two homes (even if they declare no income from them: they may be second homes or empty), the figure is {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Also counting garages, storage rooms and commercial premises, {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declare two or more urban properties; but many share them with their partner or siblings, and adding up only their share of each one, {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % reach two whole properties. At the other end, {formatNumber(kpi[0]?.pct_sin_urbanos, 1)} % declare no urban property at all.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definition" />
    <Column id=n_cumplen title="MPs" fmt='0' />
    <Column id=pct title="% of MPs" fmt='0.0' />
</DataTable>

## Compared with other taxpayers

The Spanish Tax Agency publishes how many personal income tax returns include income from let property. In the 2022 tax year, the same as most of the MPs' declarations, it was {formatNumber(irpf[0]?.pct_todos, 1)} % of all returns. But declaring rental income is far more common the more people earn: among those declaring income of 60,000 to 150,000 euros it is {formatNumber(irpf[0]?.pct_tramo, 1)} %. MPs declare rental income somewhat more often than taxpayers as a whole and considerably less often than those in that income bracket.

<BarChart
    data={comparacion}
    x=colectivo
    y=pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% declaring rental income"
    title="Declare income from letting property (2022 tax year)"
/>

<BarChart
    data={irpf_tramos}
    x=tramo
    y=pct
    sort=false
    yFmt='0"%"'
    xAxisTitle="Declared income (thousands of euros)"
    yAxisTitle="% of returns"
    title="Income tax returns with rental income, by how much people earn (2022)"
/>

## What real estate they declare

The Congress form does not ask for the value of the properties, only their type, where they are, when they were acquired and what share belongs to the MP. That is why wealth is measured by what they own, not by what it is worth. The fairest measure is that of **whole urban properties**: the sum of their share of each home, garage, commercial premises or building plot (a flat shared half and half with a partner counts as a half). Rural plots are counted separately, because many are small inherited parcels in the countryside, especially in Galicia and Asturias, and say little about their owner's wealth.

<BarChart
    data={distribucion}
    x=tramo
    y=diputados
    sort=false
    yFmt='0'
    xAxisTitle="Whole urban properties"
    yAxisTitle="MPs"
    title="MPs by the whole urban properties they declare"
/>

<BarChart
    data={tipos_total}
    x=categoria
    y=por_diputado
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="Properties per MP (average)"
    title="What properties they declare: average per MP, counting each property even if only partly owned"
/>

Inherited or bought? {formatNumber(adquisicion_total[0]?.pct_compra, 0)} % of the urban properties declared were bought and {formatNumber(adquisicion_total[0]?.pct_herencia, 0)} % came by inheritance or gift; for the rest the declaration does not say.

<BarChart
    data={adquisicion}
    x=partido
    y=pct
    series=categoria
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% of urban properties"
    seriesColors={{'Compra': '#2563eb', 'Herencia o donación': '#f59e0b', 'No consta': '#d4d4d4'}}
    title="How they acquired their urban properties, parties with 5 or more MPs"
/>

## By parliamentary group

<BarChart
    data={grupos_largo}
    x=grupo
    y=pct
    series=medida
    type=grouped
    sort=false
    yFmt='0"%"'
    yAxisTitle="% of the group's MPs"
    seriesColors={{'Declara ingresos por alquiler': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="MPs declaring rental income or several homes, groups with 20 or more MPs"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Group" />
    <Column id=diputados title="MPs" fmt='0' />
    <Column id=pct_alquila title="% declare rental income" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 or more homes" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 or more urban" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 or more whole" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% no urban" fmt='0.0' />
    <Column id=mediana_urbanos title="Median urban properties" fmt='0' />
</DataTable>

In small groups each MP moves the percentage a lot: with seven MPs, a single one is 14 points.

## Ranking by party

As parties vary greatly in size, they are compared per MP: how many whole urban properties each of their MPs declares on average. MPs are grouped by the party they were elected for, with the PSC and the other federations within the PSOE.

<BarChart
    data={partidos_grafico}
    x=partido
    y=media_urbanos_equivalentes
    sort=false
    yFmt='0.0'
    yAxisTitle="Whole urban properties per MP (average)"
    title="Whole urban properties per MP, parties with 5 or more MPs"
/>

<BarChart
    data={partidos_tipos}
    x=partido
    y=por_diputado
    series=categoria
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Properties per MP (average)"
    seriesColors={{'Vivienda': '#1d4ed8', 'Garaje o trastero': '#60a5fa', 'Local, oficina o nave': '#7c3aed', 'Otros urbanos (solares, edificios...)': '#c4b5fd', 'Finca rústica': '#a3a3a3'}}
    title="What properties their MPs declare, counting each property even if only partly owned"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Party" />
    <Column id=diputados title="MPs" fmt='0' />
    <Column id=media_urbanos_equivalentes title="Whole urban per MP (average)" fmt='0.0' />
    <Column id=mediana_urbanos_equivalentes title="Median" fmt='0.0' />
    <Column id=media_urbanos title="Urban (average)" fmt='0.0' />
    <Column id=media_viviendas title="Homes (average)" fmt='0.0' />
    <Column id=media_rusticos title="Rural plots (average)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 or more homes" fmt='0.0' />
    <Column id=max_urbanos_equivalentes title="Maximum for one MP" fmt='0.0' />
</DataTable>

The average is pushed up by a few MPs with many properties: the median tells how many the typical MP of each party owns. Parties with one or two MPs (BNG, UPN, CC) depend entirely on that person.

## The MPs with the most whole urban properties

<BarChart
    data={ranking_top}
    x=diputado
    y=urbanos_equivalentes
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Whole urban properties (sum of their share of each one)"
    title="The 15 MPs with the most whole urban properties"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="MP" />
    <Column id=partido title="Party" />
    <Column id=circunscripcion title="Constituency" />
    <Column id=urbanos_equivalentes title="Whole urban" fmt='0.0' />
    <Column id=n_urbanos title="Urban (even if partly owned)" fmt='0' />
    <Column id=n_viviendas_urbanas title="Homes" fmt='0' />
    <Column id=n_rusticos title="Rural plots" fmt='0' />
    <Column id=n_inmuebles_sociedad title="From their companies" fmt='0' />
    <Column id=alquila title="Declares rental income" />
    <Column id=revisado title="Checked by hand" />
    <Column id=url_pdf title="Declaration" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

The order is set by the «Whole urban» column: a flat inherited among four siblings counts as a quarter, and one shared half and half with a partner, as a half. Rural plots and the properties of companies in which they hold a stake are shown but do not count towards the position. Each row links to the original declaration on the Congress website.

## Methodology and sources

- **Declarations**: [Congress of Deputies, MPs' profile pages](https://www.congreso.es/es/busqueda-de-diputados), initial declaration of assets and income of each sitting MP of the 15th Legislature (submitted between {resumen[0]?.primera} and {resumen[0]?.ultima}). Later amendments are not used because they are usually partial. {kpi[0]?.n_excluidos} declarations that cannot be read or that refer back to an earlier one are excluded.
- **Reading**: the documents are scans; they were read with optical character recognition. Rows that name several assets («home, parking space and storage room») are counted asset by asset. All MPs who declare seven or more properties or four or more whole urban properties, and those who continue the list in the Remarks box, have been checked by hand against the PDF («Checked by hand»), and their figures replace the automatically read ones; elsewhere there may be occasional errors, and each MP links to their declaration so it can be checked. The breakdown by type of property and by form of acquisition is calculated row by row from the automatic reading, so its totals do not exactly match those of each MP.
- **Rental income**: the form has no box for it; it is detected from the description of each income item («alquiler», «arrendamiento», «capital inmobiliario»...). Amounts are as declared, some net, others gross and a few monthly, so they are neither added up nor compared. Imputed income from homes available for own use does not count as rental income.
- **Whole urban properties**: sum of the ownership share of each urban property (homes, garages, storage rooms, commercial premises, building plots); when it is recorded as marital property or co-owned without a percentage, half is counted. The form does not ask for the value of the properties, so a flat in central Madrid and a house in a village count the same.
- **Taxpayers**: [Spanish Tax Agency, Personal income tax filers statistics](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), item 102 (income from let property), common-regime territory. The unit is the return, which may be joint, not the person.
