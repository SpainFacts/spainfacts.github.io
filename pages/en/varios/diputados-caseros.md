---
title: How many MPs are landlords?
description: "How many members of the Congress of Deputies declare rental income or own several homes, how many properties each MP and each party declares, according to their declarations of assets and income, and compared with all personal income tax filers."
i18n_origen: 5bedfc9c968f
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
    max(pct) FILTER (WHERE definicion_id = 'alquila') AS pct_alquila,
    max(n_cumplen) FILTER (WHERE definicion_id = 'alquila') AS n_alquila,
    max(pct) FILTER (WHERE definicion_id = 'dos_viviendas') AS pct_dos_viviendas,
    max(n_cumplen) FILTER (WHERE definicion_id = 'dos_viviendas') AS n_dos_viviendas,
    max(pct) FILTER (WHERE definicion_id = 'dos_urbanos') AS pct_dos_urbanos,
    max(pct) FILTER (WHERE definicion_id = 'dos_equivalentes') AS pct_dos_equivalentes,
    max(n_cumplen) FILTER (WHERE definicion_id = 'dos_equivalentes') AS n_dos_equivalentes,
    max(pct) FILTER (WHERE definicion_id = 'sin_urbanos') AS pct_sin_urbanos,
    max(n_validos) AS n_validos, max(n_diputados) AS n_diputados, max(n_excluidos) AS n_excluidos,
    max(mediana_urbanos) AS mediana_urbanos
FROM mother.diputados_inmuebles_resumen
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
SELECT grupo, 'Declara alquileres' AS medida, pct_alquila AS pct, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
UNION ALL
SELECT grupo, '2 o más viviendas', pct_dos_viviendas, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
ORDER BY n_validos DESC, medida
```

```sql partidos
SELECT partido, CAST(n_validos AS INTEGER) AS diputados, media_inmuebles, mediana_inmuebles, media_urbanos,
       media_viviendas, media_rusticos, pct_dos_viviendas, max_inmuebles, suma_inmuebles
FROM mother.diputados_inmuebles_partidos
WHERE partido <> 'Total'
ORDER BY media_inmuebles DESC
```

```sql partidos_largo
SELECT partido, 'Viviendas' AS tipo, media_viviendas AS media, 1 AS orden_tipo, media_inmuebles, n_validos FROM mother.diputados_inmuebles_partidos WHERE partido <> 'Total' AND n_validos >= 5
UNION ALL
SELECT partido, 'Garajes, locales y otros urbanos', round(media_urbanos - media_viviendas, 2), 2, media_inmuebles, n_validos FROM mother.diputados_inmuebles_partidos WHERE partido <> 'Total' AND n_validos >= 5
UNION ALL
SELECT partido, 'Fincas rústicas', media_rusticos, 3, media_inmuebles, n_validos FROM mother.diputados_inmuebles_partidos WHERE partido <> 'Total' AND n_validos >= 5
ORDER BY media_inmuebles DESC, orden_tipo
```

```sql ranking
SELECT row_number() OVER (ORDER BY n_inmuebles DESC, n_urbanos DESC, nombre) AS puesto,
       nombre, partido, circunscripcion, n_inmuebles, n_urbanos, n_viviendas_urbanas, n_rusticos,
       n_inmuebles_sociedad, urbanos_equivalentes,
       CASE WHEN alquila THEN 'Sí' ELSE 'No' END AS alquila,
       CASE WHEN revisado_a_mano THEN 'Sí' WHEN inmuebles_sin_contar THEN 'No: hay más en Observaciones' ELSE '' END AS revisado,
       url_pdf
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
ORDER BY puesto
```

```sql ranking_top
SELECT nombre || ' (' || partido || ')' AS diputado, n_inmuebles, puesto FROM ${ranking} WHERE puesto <= 15 ORDER BY puesto
```

# <span aria-hidden="true">🏘️</span> How many MPs are landlords?

When they take their seats, members of the Congress of Deputies submit a declaration of assets and income that is published on their profile page. We have read those of the {kpi[0]?.n_diputados} sitting MPs of the 15th Legislature to count how many declare income from letting out property how many own more than one home and how many properties each one declares. Everything that follows is what their declarations state.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declare rental income"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="of MPs"
        period={`${kpi[0].n_alquila} of ${kpi[0].n_validos} · income tax: ${formatNumber(irpf[0].pct_todos, 1)} % of filers`}
        source="Congress of Deputies"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="Own 2 or more homes"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="of MPs"
        period={`${kpi[0].n_dos_viviendas} MPs`}
        source="Congress of Deputies"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="2 or more whole urban properties"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="of MPs"
        period={`Adding up their share of each property · ${kpi[0].n_dos_equivalentes} MPs`}
        source="Congress of Deputies"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="No urban property at all"
        value={kpi[0].pct_sin_urbanos}
        formattedValue={formatNumber(kpi[0].pct_sin_urbanos, 1) + ' %'}
        unit="of MPs"
        period={`Median: ${formatNumber(kpi[0].mediana_urbanos, 0)} urban properties per MP`}
        source="Congress of Deputies"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    {/if}
</div>

## What being a landlord means

There is no single way to measure it, so several are given. The strictest is declaring rental income: {formatNumber(kpi[0]?.pct_alquila, 1)} % of MPs do so. Counting those who own at least two homes (even if they do not declare letting them out: they may be second homes or empty), the figure is {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Also counting garages, storage rooms and commercial premises, {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declare two or more urban properties; but many share them with their partner or siblings, and adding up only their share of each one, {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % reach two whole properties.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definition" />
    <Column id=n_cumplen title="MPs" fmt='0' />
    <Column id=pct title="% of MPs" fmt='0.0' />
</DataTable>

## Compared with other taxpayers

The Spanish Tax Agency publishes how many personal income tax returns include income from let property. In the 2022 tax year, the same as most of the MPs' declarations, it was {formatNumber(irpf[0]?.pct_todos, 1)} % of all returns. But letting is far more common the more people earn: among those declaring income of 60,000 to 150,000 euros it is {formatNumber(irpf[0]?.pct_tramo, 1)} %. MPs declare rental income somewhat more often than taxpayers as a whole and considerably less than those in that income bracket.

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
    seriesColors={{'Declara alquileres': '#2563eb', '2 o más viviendas': '#93c5fd'}}
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

As parties vary greatly in size, they are compared per MP: how many properties each of their MPs declares on average. Properties in their own name are counted, urban (homes, garages, storage rooms, commercial premises, building plots) and rural, whatever their ownership share; those of companies in which they hold a stake are counted separately, in the ranking of MPs. MPs are grouped by the party they were elected for, with the PSC and the other federations within the PSOE.

<BarChart
    data={partidos_largo}
    x=partido
    y=media
    series=tipo
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Properties per MP (average)"
    seriesColors={{'Viviendas': '#1d4ed8', 'Garajes, locales y otros urbanos': '#60a5fa', 'Fincas rústicas': '#a3a3a3'}}
    title="Properties declared per MP, parties with 5 or more MPs"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Party" />
    <Column id=diputados title="MPs" fmt='0' />
    <Column id=media_inmuebles title="Properties per MP (average)" fmt='0.0' />
    <Column id=mediana_inmuebles title="Median" fmt='0.0' />
    <Column id=media_urbanos title="Urban (average)" fmt='0.0' />
    <Column id=media_viviendas title="Homes (average)" fmt='0.0' />
    <Column id=media_rusticos title="Rural (average)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 or more homes" fmt='0.0' />
    <Column id=max_inmuebles title="Maximum for one MP" fmt='0' />
    <Column id=suma_inmuebles title="Party total" fmt='0' />
</DataTable>

The average is pushed up by a few MPs with many plots of land: the median tells how many properties the typical MP of each party owns. Parties with one or two MPs (BNG, UPN, CC) depend entirely on that person.

## The MPs with the most properties

<BarChart
    data={ranking_top}
    x=diputado
    y=n_inmuebles
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Properties in their name (urban and rural)"
    title="The 15 MPs declaring the most properties"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="MP" />
    <Column id=partido title="Party" />
    <Column id=circunscripcion title="Constituency" />
    <Column id=n_inmuebles title="Properties" fmt='0' />
    <Column id=n_urbanos title="Urban" fmt='0' />
    <Column id=n_viviendas_urbanas title="Homes" fmt='0' />
    <Column id=n_rusticos title="Rural" fmt='0' />
    <Column id=n_inmuebles_sociedad title="From their companies" fmt='0' />
    <Column id=urbanos_equivalentes title="Whole urban" fmt='0.0' />
    <Column id=alquila title="Declares rental income" />
    <Column id=revisado title="Checked by hand" />
    <Column id=url_pdf title="Declaration" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

Properties in their name count even if only partly owned: a flat inherited among four siblings counts as one. The «Whole urban» column adds up only their share of each urban property. Many rural plots tend to be small inherited parcels, especially in Galicia and Asturias. Each row links to the original declaration on the Congress website.

## Methodology and sources

- **Declarations**: [Congress of Deputies, MPs' profile pages](https://www.congreso.es/es/busqueda-de-diputados), initial declaration of assets and income of each sitting MP of the 15th Legislature (submitted between {resumen[0]?.primera} and {resumen[0]?.ultima}). Later amendments are not used because they are usually partial. {kpi[0]?.n_excluidos} declarations that cannot be read or that refer back to an earlier one are excluded.
- **Reading**: the documents are scans; they were read with optical character recognition and a sample of 22 declarations from all groups was checked by hand: the number of urban properties and whether rental income was declared matched in 21 of the 22. Rows that name several assets («home, parking space and storage room») are counted asset by asset. The 42 MPs who declare seven or more properties, and those who continue the list in the Remarks box, have been checked by hand against the PDF («Checked by hand»), and their figures replace the automatically read ones; elsewhere there may be occasional errors, and each MP links to their declaration so it can be checked.
- **Rental income**: the form has no box for it; it is detected from the description of each income item («alquiler», «arrendamiento», «capital inmobiliario»...). Amounts are as declared, some net, others gross and a few monthly, so they are neither added up nor compared. Imputed income from homes available for own use does not count as rent.
- **Whole properties**: sum of the ownership share of each urban property; when it is recorded as marital property or co-owned without a percentage, half is counted.
- **Taxpayers**: [Spanish Tax Agency, Personal income tax filers statistics](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), item 102 (income from let property), common-regime territory. The unit is the return, which may be joint, not the person.
