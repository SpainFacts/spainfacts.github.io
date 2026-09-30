---
title: Eleccions
description: "Resultats de les eleccions generals des de 1977, europees i municipals: participació, vot per partit i per bloc, fragmentació, vots per escó i guanyador a cada província i municipi, amb les dades oficials del Ministeri de l'Interior."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 52a869023a0e
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Les etiquetes de data arriben de SQL amb el mes abreujat en castellà ('abr. 2019')
    const MESOS = {'ene.': 'gen.', 'feb.': 'febr.', 'mar.': 'març', 'abr.': 'abr.', 'may.': 'maig', 'jun.': 'juny', 'jul.': 'jul.', 'ago.': 'ag.', 'sep.': 'set.', 'oct.': 'oct.', 'nov.': 'nov.', 'dic.': 'des.'};
    const mesCa = (s) => s == null ? s : String(s).replace(/^\S+\./, (m) => MESOS[m] ?? m);
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

# 🗳️ Eleccions

Quanta gent vota, a qui i com es reparteixen els escons: totes les eleccions generals des de 1977, a més de les europees i les municipals, amb els resultats oficials del Ministeri de l'Interior per comunitat, província i municipi.

<Grid cols=4>
    <KpiCard
        title="Participació en les generals"
        value={resumen[0]?.participacion}
        formattedValue="{formatNumber(resumen[0]?.participacion, 1)} %"
        period="{resumen[0]?.fecha_txt} · {formatCompact(resumen[0]?.votantes, 3)} votants de {formatCompact(resumen[0]?.censo, 3)} electors"
        change={resumen[0]?.dif_participacion}
        changeUnit="p.p."
        changePeriod="vs. {mesCa(resumen[0]?.etiqueta_anterior)}"
        direction="positive-up"
        source="Ministeri de l'Interior"
        sparklineData={generales}
    />
    <KpiCard
        title="Candidatura més votada"
        value={resumen[0]?.ganador_pct}
        formattedValue="{resumen[0]?.ganador_siglas} · {formatNumber(resumen[0]?.ganador_pct, 1)} %"
        period="{formatNumber(resumen[0]?.ganador_escanos, 0)} de 350 escons · segona: {resumen[0]?.segundo_siglas} ({formatNumber(resumen[0]?.segundo_pct, 1)} %)"
        source="Ministeri de l'Interior"
        sparklineData={generales.map(d => ({valor: d.ganador_pct}))}
    />
    <KpiCard
        title="Nombre efectiu de partits"
        value={resumen[0]?.nep_votos}
        formattedValue={formatNumber(resumen[0]?.nep_votos, 1)}
        period="en vots ({formatNumber(resumen[0]?.nep_escanos, 1)} en escons) · 2 = bipartidisme pur"
        change={resumen[0]?.dif_nep}
        changeUnit=""
        changePeriod="vs. {mesCa(resumen[0]?.etiqueta_anterior)}"
        source="Càlcul propi"
        sparklineData={generales.map(d => ({valor: d.nep_votos}))}
    />
    <KpiCard
        title="Vot a les dues més votades"
        value={resumen[0]?.dos_primeros}
        formattedValue="{formatNumber(resumen[0]?.dos_primeros, 1)} %"
        period="{resumen[0]?.ganador_siglas} + {resumen[0]?.segundo_siglas}, sobre els vots vàlids"
        change={resumen[0]?.dif_dos}
        changeUnit="p.p."
        changePeriod="vs. {mesCa(resumen[0]?.etiqueta_anterior)}"
        source="Ministeri de l'Interior"
        sparklineData={generales.map(d => ({valor: d.dos_primeros}))}
    />
</Grid>

<p class="text-xs text-gray-500">Els percentatges de vot es calculen sobre els vots vàlids (a candidatures i en blanc), com en els resultats oficials. La participació inclou el vot dels espanyols residents a l'estranger (CERA).</p>

## Participació

La participació en les generals ha anat del {formatNumber(resumen[0]?.min_part, 1)} % ({mesCa(resumen[0]?.min_part_etiqueta)}) al {formatNumber(resumen[0]?.max_part, 1)} % ({mesCa(resumen[0]?.max_part_etiqueta)}). En les europees i en les municipals la participació sol ser més baixa.

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
    title="Participació sobre el cens, en %"
/>

## Vot per bloc

<ButtonGroup name=tipo title="Elecció">
    <ButtonGroupItem valueLabel="Generals" value="02" default />
    <ButtonGroupItem valueLabel="Europees" value="07" />
    <ButtonGroupItem valueLabel="Municipals" value="04" />
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
    max(pct) FILTER (WHERE bloque = 'Centro y derecha') AS der,
    max(pct) FILTER (WHERE bloque = 'Nacionalistas y regionalistas') AS nac
FROM ${bloques}
WHERE fecha = (SELECT max(fecha) FROM ${bloques})
GROUP BY etiqueta
```

Cada candidatura s'assigna a una família política i cada família a un de quatre blocs. En les últimes eleccions d'aquest tipus ({mesCa(bloques_ultima[0]?.etiqueta)}) l'esquerra estatal va sumar el {formatNumber(bloques_ultima[0]?.izq, 1)} % dels vots vàlids, el centre i la dreta estatals el {formatNumber(bloques_ultima[0]?.der, 1)} % i els partits nacionalistes i regionalistes el {formatNumber(bloques_ultima[0]?.nac, 1)} %.

<BarChart
    data={bloques}
    x=etiqueta
    y=pct
    series=bloque
    type=stacked
    sort=false
    yFmt='0"%"'
    yMax={100}
    seriesColors={{'Izquierda': '#dc2626', 'Centro y derecha': '#2563eb', 'Nacionalistas y regionalistas': '#ca8a04', 'Otros': '#9ca3af'}}
    title="Vot per bloc, en % dels vots vàlids (la resta fins a 100 és vot en blanc)"
/>

<p class="text-xs text-gray-500">Esquerra: PSOE i la família d'IU, Podem i Sumar (amb PCE, ICV, les confluències i Más País). Centre i dreta: UCD, CDS, AP-PP, Ciutadans, UPyD, Vox i UPN. Nacionalistes i regionalistes: partits d'àmbit autonòmic (CiU-Junts, ERC, PNB, EH Bildu, BNG, Coalició Canària, Compromís, PAR, PRC, Teruel Existe...). Altres: la resta de candidatures, sobretot petites i, en les municipals, agrupacions d'electors i independents. És una classificació de SpainFacts: el detall de quines sigles van a cada família és al codi del web (seed elecciones_partidos_reglas).</p>

## Vot per partit

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

Percentatge de vot de cada família política (les que alguna vegada han superat el 3 % a tot Espanya). Els partits s'agrupen amb les seves federacions i antecessors: el PSOE inclou el PSC; el PP, AP i les seves coalicions; IU, Podem i Sumar, el PCE i totes les seves confluències.

<LineChart
    data={familias_evol}
    x=fecha
    y=pct
    series=familia
    yFmt='0.0"%"'
    markers=true
    seriesColors={Object.fromEntries(colores_familias.map(d => [d.familia, d.color]))}
    title="Vot per família política, en % dels vots vàlids"
/>

## Fragmentació

El nombre efectiu de partits resumeix en una xifra quants partits «compten»: val 2 si dos partits es reparteixen el vot a parts iguals i creix com més repartit està. En les generals ha anat de {formatNumber(resumen[0]?.min_nep, 1)} ({mesCa(resumen[0]?.min_nep_etiqueta)}) a {formatNumber(resumen[0]?.max_nep, 1)} ({mesCa(resumen[0]?.max_nep_etiqueta)}).

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
    title="Nombre efectiu de partits en les generals (Laakso-Taagepera)"
/>

<p class="text-xs text-gray-500">Nombre efectiu de partits = 1 / suma dels quadrats de les quotes de vot (o d'escons) de cada candidatura. Es calcula amb les candidatures agrupades com en el recompte nacional (el PSC dins del PSOE, les llistes provincials de Sumar dins de Sumar...). Que sigui més baix en escons que en vots indica que el repartiment afavoreix els partits grans.</p>

## Vots per escó

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

Els 350 escons es reparteixen per províncies amb la regla D'Hondt, de manera que el nombre de vots que costa cada escó canvia molt d'un partit a un altre. En les últimes generals ({resumen[0]?.fecha_txt}) cada escó de {vpe_resumen[0]?.min_siglas} va costar {formatNumber(vpe_resumen[0]?.min_vpe, 0)} vots i cada un de {vpe_resumen[0]?.max_siglas}, {formatNumber(vpe_resumen[0]?.max_vpe, 0)}. Les candidatures que es van quedar sense escó van reunir el {formatNumber(vpe_sin[0]?.pct_sin_escano, 1)} % dels vots vàlids.

<BarChart
    data={ultima_partidos}
    x=siglas
    y=votos_por_escano
    yFmt=num0
    swapXY=true
    fillColor="#1d4ed8"
    title="Vots per escó en les últimes generals"
/>

<DataTable data={ultima_partidos} rows=20>
    <Column id=siglas title="Candidatura" />
    <Column id=pct title="% vot" fmt='0.00"%"' />
    <Column id=escanos title="Escons" fmt=num0 />
    <Column id=pct_escanos title="% escons" fmt='0.00"%"' />
    <Column id=ventaja title="Escons − vot (p.p.)" fmt='+0.00;-0.00' contentType=delta />
    <Column id=votos_por_escano title="Vots per escó" fmt=num0 />
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
    title="Desproporcionalitat entre vots i escons en les generals (índex de Gallagher)"
/>

<p class="text-xs text-gray-500">Índex de Gallagher = arrel de la meitat de la suma dels quadrats de les diferències entre el % de vot i el % d'escons de cada candidatura. 0 seria un repartiment perfectament proporcional.</p>

## Guanyador a cada província

```sql lista_generales
SELECT proceso, etiqueta, row_number() OVER (ORDER BY fecha DESC) AS orden FROM ${generales} ORDER BY fecha DESC
```

<Dropdown name=eleccion title="Eleccions generals" data={lista_generales} value=proceso label=etiqueta order=orden />

```sql provincias
SELECT
    p.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta,
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

La família política de la candidatura més votada a cada província (la circumscripció de les generals).

<AreaMap
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri de l'Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ganador_siglas', title: 'Més votada'},
        {id: 'ganador_pct', title: '% vot', fmt: 'pct1'},
        {id: 'segundo_siglas', title: 'Segona'},
        {id: 'segundo_pct', title: '% vot', fmt: 'pct1'},
        {id: 'participacion', title: 'Participació', fmt: 'pct1'},
        {id: 'escanos', title: 'Escons', fmt: 'num0'}
    ]}
/>

```sql ccaa
SELECT
    t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
    p.participacion / 100 AS participacion,
    p.ganador_siglas, p.ganador_pct / 100 AS ganador_pct,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Izquierda'), 0) AS izq,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Centro y derecha'), 0) AS der,
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
    <Column id=comunidad title="Comunitat" />
    <Column id=participacion title="Participació" fmt=pct1 />
    <Column id=ganador_siglas title="Més votada" />
    <Column id=ganador_pct title="% vot" fmt=pct1 />
    <Column id=izq title="Esquerra" fmt=pct1 />
    <Column id=der title="Centre i dreta" fmt=pct1 />
    <Column id=nac title="Nacionalistes i reg." fmt=pct1 />
    <Column id=nep_votos title="Nre. efectiu de partits" fmt='0.0' />
</DataTable>

## Resultats per municipi

```sql municipios
SELECT
    municipio, provincia, poblacion, ganador_siglas,
    ganador_pct / 100 AS ganador_pct,
    participacion / 100 AS participacion,
    (participacion - participacion_anterior) AS dif_participacion,
    pct_izquierda / 100 AS izq,
    pct_derecha / 100 AS der,
    pct_nacionalistas / 100 AS nac,
    '/ca' || enlace AS enlace
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

Resultat de les últimes generals als {formatNumber(municipios_resumen[0]?.n, 0)} municipis. {municipios_resumen[0]?.mas_gana} va ser la candidatura més votada en {formatNumber(municipios_resumen[0]?.n_mas_gana, 0)} d'aquests. Cerca el teu i fes-hi clic per veure'n la fitxa, amb l'evolució des de 1977.

<DataTable data={municipios} rows=15 search=true link=enlace>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=ganador_siglas title="Més votada" />
    <Column id=ganador_pct title="% vot" fmt=pct1 />
    <Column id=participacion title="Participació" fmt=pct1 />
    <Column id=dif_participacion title="vs. anteriors (p.p.)" fmt='+0.0;-0.0' contentType=delta />
    <Column id=izq title="Esquerra" fmt=pct1 />
    <Column id=der title="Centre i dreta" fmt=pct1 />
    <Column id=nac title="Nacionalistes i reg." fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Els resultats per municipi no inclouen el vot dels residents a l'estranger (CERA), que es compta a part a cada província. En alguns municipis petits del 1977 i el 1979 els votants registrats superen el cens per errors de la font: en aquests casos no es dona participació.</p>

---

## Fonts i notes

- **[Ministeri de l'Interior – Àrea de descàrregues de resultats electorals](https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/)**: fitxers oficials de cada procés (format de text de longitud fixa descrit en el document FICHEROS que acompanya cada descàrrega). Generals (Congrés) des de 1977, europees des de 1987 i municipals des de 1979, amb dades per municipi, província i comunitat.
- En les municipals només s'inclouen els municipis de més de 250 habitants (llistes tancades); els de consell obert o llistes obertes es publiquen en altres fitxers.
- Les sigles s'agrupen en famílies polítiques amb els mateixos criteris i colors que la pàgina d'[alcaldes](/ca/territorios/municipios); l'assignació de cada candidatura a una família i a un bloc és de SpainFacts i es pot discutir en coalicions (per exemple, UPN-PP compta com a UPN i Ahora Repúblicas, en les europees, com a ERC en el total nacional).
- Percentatges de vot sobre vots vàlids (candidatures i en blanc). Participació = votants / cens d'escrutini.

<LastRefreshed prefix="Dades actualitzades" />
