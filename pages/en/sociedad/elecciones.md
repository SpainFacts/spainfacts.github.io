---
title: Elections
description: "Results of general elections since 1977, European and municipal elections: turnout, votes by party and by bloc, fragmentation, votes per seat and the winner in each province and municipality, using official data from the Ministry of the Interior."
i18n_origen: c483ec970932
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql generales
SELECT
    proceso, fecha, CAST(anio AS INTEGER) AS anio,
    CASE WHEN count(*) OVER (PARTITION BY anio) > 1
        THEN ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'][month(fecha)] || ' ' || CAST(CAST(anio AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR)
    END AS etiqueta,
    strftime(fecha, '%-d/%-m/%Y') AS fecha_txt,
    censo, votantes, participacion, pct_blancos, nep_votos, nep_escanos, gallagher,
    ganador_siglas, ganador_pct, ganador_escanos, segundo_siglas, segundo_pct,
    ganador_pct + segundo_pct AS dos_primeros,
    participacion AS valor
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '02'
ORDER BY fecha
```

```sql resumen
-- Última elección y cambios frente a la anterior; máximos y mínimos de la serie
WITH g AS (SELECT * FROM ${generales})
SELECT
    u.*,
    round(u.participacion - a.participacion, 1) AS dif_participacion,
    round(u.nep_votos - a.nep_votos, 1) AS dif_nep,
    round(u.dos_primeros - a.dos_primeros, 1) AS dif_dos,
    a.etiqueta AS etiqueta_anterior,
    (SELECT arg_max(etiqueta, participacion) FROM g) AS max_part_etiqueta,
    (SELECT max(participacion) FROM g) AS max_part,
    (SELECT arg_min(etiqueta, participacion) FROM g) AS min_part_etiqueta,
    (SELECT min(participacion) FROM g) AS min_part,
    (SELECT arg_max(etiqueta, nep_votos) FROM g) AS max_nep_etiqueta,
    (SELECT max(nep_votos) FROM g) AS max_nep,
    (SELECT arg_min(etiqueta, nep_votos) FROM g) AS min_nep_etiqueta,
    (SELECT min(nep_votos) FROM g) AS min_nep
FROM (SELECT * FROM g ORDER BY fecha DESC LIMIT 1) u
CROSS JOIN (SELECT * FROM g ORDER BY fecha DESC LIMIT 1 OFFSET 1) a
```

# 🗳️ Elections

How many people vote, for whom, and how the seats are shared out: every general election since 1977, plus European and municipal elections, with official results from the Ministry of the Interior by region, province and municipality.

<Grid cols=4>
    <KpiCard
        title="Turnout in general elections"
        value={resumen[0]?.participacion}
        formattedValue="{formatNumber(resumen[0]?.participacion, 1)} %"
        period="{resumen[0]?.fecha_txt} · {formatCompact(resumen[0]?.votantes, 3)} voters out of {formatCompact(resumen[0]?.censo, 3)} registered electors"
        change={resumen[0]?.dif_participacion}
        changeUnit="pp"
        changePeriod="vs {resumen[0]?.etiqueta_anterior}"
        direction="positive-up"
        source="Ministry of the Interior"
        sparklineData={generales}
    />
    <KpiCard
        title="Most-voted list"
        value={resumen[0]?.ganador_pct}
        formattedValue="{resumen[0]?.ganador_siglas} · {formatNumber(resumen[0]?.ganador_pct, 1)} %"
        period="{formatNumber(resumen[0]?.ganador_escanos, 0)} of 350 seats · runner-up: {resumen[0]?.segundo_siglas} ({formatNumber(resumen[0]?.segundo_pct, 1)} %)"
        source="Ministry of the Interior"
        sparklineData={generales.map(d => ({...d, valor: d.ganador_pct}))}
    />
    <KpiCard
        title="Effective number of parties"
        value={resumen[0]?.nep_votos}
        formattedValue={formatNumber(resumen[0]?.nep_votos, 1)}
        period="by votes ({formatNumber(resumen[0]?.nep_escanos, 1)} by seats) · 2 = pure two-party system"
        change={resumen[0]?.dif_nep}
        changeUnit=""
        changePeriod="vs {resumen[0]?.etiqueta_anterior}"
        source="Own calculation"
        sparklineData={generales.map(d => ({...d, valor: d.nep_votos}))}
    />
    <KpiCard
        title="Vote share of the top two"
        value={resumen[0]?.dos_primeros}
        formattedValue="{formatNumber(resumen[0]?.dos_primeros, 1)} %"
        period="{resumen[0]?.ganador_siglas} + {resumen[0]?.segundo_siglas}, of valid votes"
        change={resumen[0]?.dif_dos}
        changeUnit="pp"
        changePeriod="vs {resumen[0]?.etiqueta_anterior}"
        source="Ministry of the Interior"
        sparklineData={generales.map(d => ({...d, valor: d.dos_primeros}))}
    />
</Grid>

<p class="text-xs text-gray-500">Vote shares are calculated over valid votes (for lists plus blank votes), as in the official results. Turnout includes votes cast by Spaniards living abroad (CERA).</p>

## Turnout

Turnout in general elections has ranged from {formatNumber(resumen[0]?.min_part, 1)} % ({resumen[0]?.min_part_etiqueta}) to {formatNumber(resumen[0]?.max_part, 1)} % ({resumen[0]?.max_part_etiqueta}). Turnout is usually lower in European and municipal elections.

```sql participacion_tipos
SELECT fecha, tipo_nombre AS eleccion, participacion
FROM mother.elecciones_participacion
WHERE nivel = 'pais'
ORDER BY fecha
```

<LineChart
    data={participacion_tipos}
    x=fecha
    y=participacion
    series=eleccion
    yFmt='0.0"%"'
    yMin={30}
    markers=true
    seriesColors={{'Congreso': '#1d4ed8', 'Municipales': '#0f766e', 'Parlamento Europeo': '#a16207'}}
    title="Turnout as % of the electoral roll"
/>

## Votes by bloc

<ButtonGroup name=tipo title="Election">
    <ButtonGroupItem valueLabel="General" value="02" default />
    <ButtonGroupItem valueLabel="European" value="07" />
    <ButtonGroupItem valueLabel="Municipal" value="04" />
</ButtonGroup>

```sql etiquetas
SELECT
    proceso, fecha,
    CASE WHEN count(*) OVER (PARTITION BY anio) > 1
        THEN ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'][month(fecha)] || ' ' || CAST(CAST(anio AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR)
    END AS etiqueta
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '${inputs.tipo}'
```

```sql bloques
SELECT fecha, etiqueta, bloque, pct, escanos
FROM (
    SELECT e.fecha, e.etiqueta, f.bloque, sum(f.pct) AS pct, sum(f.escanos) AS escanos, min(f.orden_familia) AS orden
    FROM mother.elecciones_familias f
    JOIN ${etiquetas} e USING (proceso)
    WHERE f.nivel = 'pais' AND f.tipo = '${inputs.tipo}'
    GROUP BY e.fecha, e.etiqueta, f.bloque
)
ORDER BY fecha, orden
```

```sql bloques_ultima
SELECT
    etiqueta,
    max(pct) FILTER (WHERE bloque = 'Izquierda') AS izq,
    max(pct) FILTER (WHERE bloque = 'Derecha') AS der,
    coalesce(max(pct) FILTER (WHERE bloque = 'Centro'), 0) AS cen,
    max(pct) FILTER (WHERE bloque = 'Nacionalistas y regionalistas') AS nac
FROM ${bloques}
WHERE fecha = (SELECT max(fecha) FROM ${bloques})
GROUP BY etiqueta
```

Each list is assigned to a political family and each family to one of five blocs. In the most recent election of this type ({bloques_ultima[0]?.etiqueta}), the nationwide left won {formatNumber(bloques_ultima[0]?.izq, 1)} % of valid votes, the nationwide right {formatNumber(bloques_ultima[0]?.der, 1)} %, centre parties {formatNumber(bloques_ultima[0]?.cen, 1)} % and nationalist and regionalist parties {formatNumber(bloques_ultima[0]?.nac, 1)} %.

<BarChart
    data={bloques}
    x=etiqueta
    y=pct
    series=bloque
    type=stacked
    sort=false
    yFmt='0"%"'
    yMax={100}
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04', 'Otros': '#9ca3af'}}
    title="Votes by bloc, as % of valid votes (the remainder up to 100 is blank votes)"
/>

<p class="text-xs text-gray-500">Left (Izquierda): PSOE and the IU, Podemos and Sumar family (with PCE, ICV, the regional confluences and Más País). Right (Derecha): AP-PP, Vox and UPN. Centre (Centro): UCD, CDS, Ciudadanos and UPyD. Nationalists and regionalists (Nacionalistas y regionalistas): parties operating within a single region (CiU-Junts, ERC, PNV, EH Bildu, BNG, Coalición Canaria, Compromís, PAR, PRC, Teruel Existe...). Others (Otros): all remaining lists, mostly small ones and, in municipal elections, groups of electors and independents. This is SpainFacts' own classification: the details of which party labels go into each family are in the website's code (seed elecciones_partidos_reglas).</p>

## Votes by party

```sql familias_evol
SELECT e.fecha, e.etiqueta, f.familia, f.siglas_familia, f.color, f.orden_familia, f.pct, f.escanos, f.votos
FROM mother.elecciones_familias f
JOIN ${etiquetas} e USING (proceso)
WHERE f.nivel = 'pais' AND f.tipo = '${inputs.tipo}'
  AND f.familia IN (
      SELECT familia FROM mother.elecciones_familias
      WHERE nivel = 'pais' AND tipo = '${inputs.tipo}' AND bloque <> 'Otros'
      GROUP BY familia HAVING max(pct) >= 3
  )
ORDER BY e.fecha, f.orden_familia
```

```sql colores_familias
SELECT DISTINCT familia, color, orden_familia FROM ${familias_evol} ORDER BY orden_familia
```

Vote share of each political family (those that have at some point exceeded 3 % across Spain). Parties are grouped with their federations and predecessors: PSOE includes PSC; PP includes AP and its coalitions; IU, Podemos and Sumar include PCE and all their regional confluences.

<LineChart
    data={familias_evol}
    x=fecha
    y=pct
    series=familia
    yFmt='0.0"%"'
    markers=true
    seriesColors={Object.fromEntries(colores_familias.map(d => [d.familia, d.color]))}
    title="Votes by political family, as % of valid votes"
/>

## Fragmentation

The effective number of parties sums up in a single figure how many parties “count”: it equals 2 if two parties split the vote equally and rises the more widely the vote is spread. In general elections it has ranged from {formatNumber(resumen[0]?.min_nep, 1)} ({resumen[0]?.min_nep_etiqueta}) to {formatNumber(resumen[0]?.max_nep, 1)} ({resumen[0]?.max_nep_etiqueta}).

```sql fragmentacion
SELECT fecha, 'En votos' AS medida, nep_votos AS nep FROM ${generales}
UNION ALL
SELECT fecha, 'En escaños' AS medida, nep_escanos AS nep FROM ${generales}
ORDER BY fecha
```

<LineChart
    data={fragmentacion}
    x=fecha
    y=nep
    series=medida
    yFmt='0.0'
    markers=true
    seriesColors={{'En votos': '#7c3aed', 'En escaños': '#c4b5fd'}}
    title="Effective number of parties in general elections (Laakso-Taagepera)"
/>

<p class="text-xs text-gray-500">Effective number of parties = 1 / sum of the squares of each list's share of votes (or seats). It is calculated with lists grouped as in the national count (PSC within PSOE, Sumar's provincial lists within Sumar...). A lower figure for seats than for votes indicates that the allocation favours large parties.</p>

## Votes per seat

```sql ultima_partidos
SELECT siglas, familia, color, votos, pct, escanos, pct_escanos, votos_por_escano, ventaja
FROM mother.elecciones_partidos
WHERE tipo = '02' AND proceso = (SELECT max(proceso) FROM mother.elecciones_partidos WHERE tipo = '02')
  AND escanos > 0
ORDER BY votos DESC
```

```sql vpe_resumen
SELECT
    arg_min(siglas, votos_por_escano) AS min_siglas, min(votos_por_escano) AS min_vpe,
    arg_max(siglas, votos_por_escano) AS max_siglas, max(votos_por_escano) AS max_vpe,
    (SELECT votos_candidaturas FROM mother.elecciones_participacion WHERE nivel = 'pais' AND tipo = '02'
       ORDER BY proceso DESC LIMIT 1) - sum(votos) AS votos_sin_escano,
    (SELECT validos FROM mother.elecciones_participacion WHERE nivel = 'pais' AND tipo = '02'
       ORDER BY proceso DESC LIMIT 1) AS validos
FROM ${ultima_partidos}
```

```sql vpe_sin
SELECT 100.0 * votos_sin_escano / validos AS pct_sin_escano FROM ${vpe_resumen}
```

The 350 seats are allocated province by province using the D'Hondt method, so the number of votes each seat costs varies widely from one party to another. In the last general election ({resumen[0]?.fecha_txt}), each seat won by {vpe_resumen[0]?.min_siglas} cost {formatNumber(vpe_resumen[0]?.min_vpe, 0)} votes and each one won by {vpe_resumen[0]?.max_siglas}, {formatNumber(vpe_resumen[0]?.max_vpe, 0)}. Lists that won no seats received {formatNumber(vpe_sin[0]?.pct_sin_escano, 1)} % of valid votes.

<BarChart
    data={ultima_partidos}
    x=siglas
    y=votos_por_escano
    yFmt=num0
    swapXY=true
    fillColor="#1d4ed8"
    title="Votes per seat in the last general election"
/>

<DataTable data={ultima_partidos} rows=20>
    <Column id=siglas title="List" />
    <Column id=pct title="% of vote" fmt='0.00"%"' />
    <Column id=escanos title="Seats" fmt=num0 />
    <Column id=pct_escanos title="% of seats" fmt='0.00"%"' />
    <Column id=ventaja title="Seats − votes (pp)" fmt='+0.00;-0.00' contentType=delta />
    <Column id=votos_por_escano title="Votes per seat" fmt=num0 />
</DataTable>

```sql gallagher
SELECT fecha, gallagher FROM ${generales} ORDER BY fecha
```

<LineChart
    data={gallagher}
    x=fecha
    y=gallagher
    yFmt='0.0'
    markers=true
    lineColor="#b45309"
    title="Disproportionality between votes and seats in general elections (Gallagher index)"
/>

<p class="text-xs text-gray-500">Gallagher index = square root of half the sum of the squared differences between each list's % of votes and % of seats. 0 would mean a perfectly proportional allocation.</p>

## Winner in each province

```sql lista_generales
SELECT proceso, etiqueta, row_number() OVER (ORDER BY fecha DESC) AS orden FROM ${generales} ORDER BY fecha DESC
```

<Dropdown name=eleccion title="General election" data={lista_generales} value=proceso label=etiqueta order=orden />

```sql provincias
SELECT
    p.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta,
    p.ganador_familia, p.ganador_siglas, p.ganador_pct / 100 AS ganador_pct,
    p.segundo_siglas, p.segundo_pct / 100 AS segundo_pct,
    p.participacion / 100 AS participacion, p.escanos,
    b.orden_familia, b.color
FROM mother.elecciones_participacion p
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod
LEFT JOIN (SELECT familia, any_value(orden_familia) AS orden_familia, any_value(color) AS color
           FROM mother.elecciones_familias GROUP BY familia) b ON b.familia = p.ganador_familia
WHERE p.nivel = 'provincia' AND p.proceso = '${inputs.eleccion.value}'
ORDER BY b.orden_familia, p.cod
```

```sql colores_mapa
SELECT p.ganador_familia, any_value(f.color) AS color, count(*) AS provincias, min(p.orden_familia) AS orden
FROM ${provincias} p
LEFT JOIN (SELECT DISTINCT familia, color FROM mother.elecciones_familias) f ON f.familia = p.ganador_familia
GROUP BY 1
ORDER BY orden
```

The political family of the most-voted list in each province (the constituency in general elections).

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="ganador_familia"
    legendType=categorical
    colorPalette={[...new Map(Array.from(provincias ?? []).map(d => [d.ganador_familia, d.color])).values()]}
    link="ruta"
    height={480}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of the Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ganador_siglas', title: 'Most voted'},
        {id: 'ganador_pct', title: '% of vote', fmt: 'pct1'},
        {id: 'segundo_siglas', title: 'Runner-up'},
        {id: 'segundo_pct', title: '% of vote', fmt: 'pct1'},
        {id: 'participacion', title: 'Turnout', fmt: 'pct1'},
        {id: 'escanos', title: 'Seats', fmt: 'num0'}
    ]}
/>

```sql ccaa
SELECT
    t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    p.participacion / 100 AS participacion,
    p.ganador_siglas, p.ganador_pct / 100 AS ganador_pct,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Izquierda'), 0) AS izq,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Derecha'), 0) AS der,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Centro'), 0) AS cen,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Nacionalistas y regionalistas'), 0) AS nac,
    p.nep_votos
FROM mother.elecciones_participacion p
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod
LEFT JOIN (
    SELECT cod, bloque, sum(pct) / 100 AS pct
    FROM mother.elecciones_familias
    WHERE nivel = 'ccaa' AND proceso = '${inputs.eleccion.value}'
    GROUP BY ALL
) f ON f.cod = p.cod
WHERE p.nivel = 'ccaa' AND p.proceso = '${inputs.eleccion.value}'
GROUP BY ALL
ORDER BY 3 DESC
```

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=participacion title="Turnout" fmt=pct1 />
    <Column id=ganador_siglas title="Most voted" />
    <Column id=ganador_pct title="% of vote" fmt=pct1 />
    <Column id=izq title="Left" fmt=pct1 />
    <Column id=der title="Right" fmt=pct1 />
    <Column id=cen title="Centre" fmt=pct1 />
    <Column id=nac title="Nationalist and reg." fmt=pct1 />
    <Column id=nep_votos title="Effective no. of parties" fmt='0.0' />
</DataTable>

## Results by municipality

```sql municipios
SELECT
    municipio, provincia, poblacion, ganador_siglas,
    ganador_pct / 100 AS ganador_pct,
    participacion / 100 AS participacion,
    (participacion - participacion_anterior) AS dif_participacion,
    pct_izquierda / 100 AS izq,
    pct_derecha / 100 AS der,
    pct_centro / 100 AS cen,
    pct_nacionalistas / 100 AS nac,
    '/en' || enlace AS enlace
FROM mother.elecciones_municipios_congreso
ORDER BY poblacion DESC NULLS LAST
```

```sql municipios_resumen
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    count(*) AS n,
    arg_max(ganador_siglas, n_gana) AS mas_gana, max(n_gana) AS n_mas_gana
FROM (
    SELECT anio, ganador_siglas, count(*) OVER (PARTITION BY ganador_siglas) AS n_gana
    FROM mother.elecciones_municipios_congreso
)
```

Results of the last general election in all {formatNumber(municipios_resumen[0]?.n, 0)} municipalities. {municipios_resumen[0]?.mas_gana} was the most-voted list in {formatNumber(municipios_resumen[0]?.n_mas_gana, 0)} of them. Search for yours and click to open its profile, with results going back to 1977.

<DataTable data={municipios} rows=15 search=true link=enlace>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=ganador_siglas title="Most voted" />
    <Column id=ganador_pct title="% of vote" fmt=pct1 />
    <Column id=participacion title="Turnout" fmt=pct1 />
    <Column id=dif_participacion title="vs previous (pp)" fmt='+0.0;-0.0' contentType=delta />
    <Column id=izq title="Left" fmt=pct1 />
    <Column id=der title="Right" fmt=pct1 />
    <Column id=cen title="Centre" fmt=pct1 />
    <Column id=nac title="Nationalist and reg." fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Results by municipality do not include the votes of residents abroad (CERA), which are counted separately in each province. In some small municipalities in 1977 and 1979, the number of recorded voters exceeds the electoral roll because of errors in the source: turnout is not shown in those cases.</p>

---

## Sources and notes

- **[Ministry of the Interior – Election results download area](https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/)**: official files for each election (fixed-width text format described in the FICHEROS document included with each download). General elections (Congress of Deputies) since 1977, European elections since 1987 and municipal elections since 1979, with data by municipality, province and region.
- Municipal elections only include municipalities with more than 250 inhabitants (closed lists); those with open council (concejo abierto) or open lists are published in other files.
- Party labels are grouped into political families using the same criteria and colours as the [mayors](/en/territorios/municipios) page; the assignment of each list to a family and a bloc is SpainFacts' own and may be debatable for coalitions (for example, UPN-PP counts as UPN and, in European elections, Ahora Repúblicas counts as ERC in the national total).
- Vote shares are over valid votes (lists plus blank votes). Turnout = voters / electoral roll at the count.

<LastRefreshed prefix="Data updated" />
