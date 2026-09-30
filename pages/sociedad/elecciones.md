---
title: Elecciones
description: "Resultados de las elecciones generales desde 1977, europeas y municipales: participación, voto por partido y por bloque, fragmentación, votos por escaño y ganador en cada provincia y municipio, con los datos oficiales del Ministerio del Interior."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🗳️ Elecciones

Cuánta gente vota, a quién y cómo se reparten los escaños: todas las elecciones generales desde 1977, además de las europeas y las municipales, con los resultados oficiales del Ministerio del Interior por comunidad, provincia y municipio.

<Grid cols=4>
    <KpiCard
        title="Participación en las generales"
        value={resumen[0]?.participacion}
        formattedValue="{formatNumber(resumen[0]?.participacion, 1)} %"
        period="{resumen[0]?.fecha_txt} · {formatCompact(resumen[0]?.votantes, 3)} votantes de {formatCompact(resumen[0]?.censo, 3)} electores"
        change={resumen[0]?.dif_participacion}
        changeUnit="p.p."
        changePeriod="vs. {resumen[0]?.etiqueta_anterior}"
        direction="positive-up"
        source="Ministerio del Interior"
        sparklineData={generales}
    />
    <KpiCard
        title="Candidatura más votada"
        value={resumen[0]?.ganador_pct}
        formattedValue="{resumen[0]?.ganador_siglas} · {formatNumber(resumen[0]?.ganador_pct, 1)} %"
        period="{formatNumber(resumen[0]?.ganador_escanos, 0)} de 350 escaños · segunda: {resumen[0]?.segundo_siglas} ({formatNumber(resumen[0]?.segundo_pct, 1)} %)"
        source="Ministerio del Interior"
        sparklineData={generales.map(d => ({valor: d.ganador_pct}))}
    />
    <KpiCard
        title="Número efectivo de partidos"
        value={resumen[0]?.nep_votos}
        formattedValue={formatNumber(resumen[0]?.nep_votos, 1)}
        period="en votos ({formatNumber(resumen[0]?.nep_escanos, 1)} en escaños) · 2 = bipartidismo puro"
        change={resumen[0]?.dif_nep}
        changeUnit=""
        changePeriod="vs. {resumen[0]?.etiqueta_anterior}"
        source="Cálculo propio"
        sparklineData={generales.map(d => ({valor: d.nep_votos}))}
    />
    <KpiCard
        title="Voto a las dos más votadas"
        value={resumen[0]?.dos_primeros}
        formattedValue="{formatNumber(resumen[0]?.dos_primeros, 1)} %"
        period="{resumen[0]?.ganador_siglas} + {resumen[0]?.segundo_siglas}, sobre los votos válidos"
        change={resumen[0]?.dif_dos}
        changeUnit="p.p."
        changePeriod="vs. {resumen[0]?.etiqueta_anterior}"
        source="Ministerio del Interior"
        sparklineData={generales.map(d => ({valor: d.dos_primeros}))}
    />
</Grid>

<p class="text-xs text-gray-500">Los porcentajes de voto se calculan sobre los votos válidos (a candidaturas y en blanco), como en los resultados oficiales. La participación incluye el voto de los españoles residentes en el extranjero (CERA).</p>

## Participación

La participación en las generales ha ido del {formatNumber(resumen[0]?.min_part, 1)} % ({resumen[0]?.min_part_etiqueta}) al {formatNumber(resumen[0]?.max_part, 1)} % ({resumen[0]?.max_part_etiqueta}). En las europeas y en las municipales la participación suele ser menor.

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
    title="Participación sobre el censo, en %"
/>

## Voto por bloque

<ButtonGroup name=tipo title="Elección">
    <ButtonGroupItem valueLabel="Generales" value="02" default />
    <ButtonGroupItem valueLabel="Europeas" value="07" />
    <ButtonGroupItem valueLabel="Municipales" value="04" />
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

Cada candidatura se asigna a una familia política y cada familia a uno de cuatro bloques. En las últimas elecciones de este tipo ({bloques_ultima[0]?.etiqueta}) la izquierda estatal sumó el {formatNumber(bloques_ultima[0]?.izq, 1)} % de los votos válidos, el centro y la derecha estatales el {formatNumber(bloques_ultima[0]?.der, 1)} % y los partidos nacionalistas y regionalistas el {formatNumber(bloques_ultima[0]?.nac, 1)} %.

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
    title="Voto por bloque, en % de los votos válidos (el resto hasta 100 es voto en blanco)"
/>

<p class="text-xs text-gray-500">Izquierda: PSOE y la familia de IU, Podemos y Sumar (con PCE, ICV, las confluencias y Más País). Centro y derecha: UCD, CDS, AP-PP, Ciudadanos, UPyD, Vox y UPN. Nacionalistas y regionalistas: partidos de ámbito autonómico (CiU-Junts, ERC, PNV, EH Bildu, BNG, Coalición Canaria, Compromís, PAR, PRC, Teruel Existe...). Otros: el resto de candidaturas, sobre todo pequeñas y, en las municipales, agrupaciones de electores e independientes. Es una clasificación de SpainFacts: el detalle de qué siglas van a cada familia está en el código de la web (seed elecciones_partidos_reglas).</p>

## Voto por partido

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

Porcentaje de voto de cada familia política (las que alguna vez han superado el 3 % en toda España). Los partidos se agrupan con sus federaciones y antecesores: el PSOE incluye al PSC; el PP, a AP y sus coaliciones; IU, Podemos y Sumar, al PCE y a todas sus confluencias.

<LineChart
    data={familias_evol}
    x=fecha
    y=pct
    series=familia
    yFmt='0.0"%"'
    markers=true
    seriesColors={Object.fromEntries(colores_familias.map(d => [d.familia, d.color]))}
    title="Voto por familia política, en % de los votos válidos"
/>

## Fragmentación

El número efectivo de partidos resume en una cifra cuántos partidos «cuentan»: vale 2 si dos partidos se reparten el voto a partes iguales y crece cuanto más repartido está. En las generales ha ido de {formatNumber(resumen[0]?.min_nep, 1)} ({resumen[0]?.min_nep_etiqueta}) a {formatNumber(resumen[0]?.max_nep, 1)} ({resumen[0]?.max_nep_etiqueta}).

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
    title="Número efectivo de partidos en las generales (Laakso-Taagepera)"
/>

<p class="text-xs text-gray-500">Número efectivo de partidos = 1 / suma de los cuadrados de las cuotas de voto (o de escaños) de cada candidatura. Se calcula con las candidaturas agrupadas como en el recuento nacional (el PSC dentro del PSOE, las listas provinciales de Sumar dentro de Sumar...). Que sea menor en escaños que en votos indica que el reparto favorece a los partidos grandes.</p>

## Votos por escaño

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

Los 350 escaños se reparten por provincias con la regla D'Hondt, así que el número de votos que cuesta cada escaño cambia mucho de un partido a otro. En las últimas generales ({resumen[0]?.fecha_txt}) cada escaño de {vpe_resumen[0]?.min_siglas} costó {formatNumber(vpe_resumen[0]?.min_vpe, 0)} votos y cada uno de {vpe_resumen[0]?.max_siglas}, {formatNumber(vpe_resumen[0]?.max_vpe, 0)}. Las candidaturas que se quedaron sin escaño reunieron el {formatNumber(vpe_sin[0]?.pct_sin_escano, 1)} % de los votos válidos.

<BarChart
    data={ultima_partidos}
    x=siglas
    y=votos_por_escano
    yFmt=num0
    swapXY=true
    fillColor="#1d4ed8"
    title="Votos por escaño en las últimas generales"
/>

<DataTable data={ultima_partidos} rows=20>
    <Column id=siglas title="Candidatura" />
    <Column id=pct title="% voto" fmt='0.00"%"' />
    <Column id=escanos title="Escaños" fmt=num0 />
    <Column id=pct_escanos title="% escaños" fmt='0.00"%"' />
    <Column id=ventaja title="Escaños − voto (p.p.)" fmt='+0.00;-0.00' contentType=delta />
    <Column id=votos_por_escano title="Votos por escaño" fmt=num0 />
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
    title="Desproporcionalidad entre votos y escaños en las generales (índice de Gallagher)"
/>

<p class="text-xs text-gray-500">Índice de Gallagher = raíz de la mitad de la suma de los cuadrados de las diferencias entre el % de voto y el % de escaños de cada candidatura. 0 sería un reparto perfectamente proporcional.</p>

## Ganador en cada provincia

```sql lista_generales
SELECT proceso, etiqueta, row_number() OVER (ORDER BY fecha DESC) AS orden FROM ${generales} ORDER BY fecha DESC
```

<Dropdown name=eleccion title="Elecciones generales" data={lista_generales} value=proceso label=etiqueta order=orden />

```sql provincias
SELECT
    p.cod AS cod_prov, t.nombre AS provincia, t.ruta,
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

La familia política de la candidatura más votada en cada provincia (la circunscripción de las generales).

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio del Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ganador_siglas', title: 'Más votada'},
        {id: 'ganador_pct', title: '% voto', fmt: 'pct1'},
        {id: 'segundo_siglas', title: 'Segunda'},
        {id: 'segundo_pct', title: '% voto', fmt: 'pct1'},
        {id: 'participacion', title: 'Participación', fmt: 'pct1'},
        {id: 'escanos', title: 'Escaños', fmt: 'num0'}
    ]}
/>

```sql ccaa
SELECT
    t.nombre AS comunidad, t.ruta,
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
    <Column id=comunidad title="Comunidad" />
    <Column id=participacion title="Participación" fmt=pct1 />
    <Column id=ganador_siglas title="Más votada" />
    <Column id=ganador_pct title="% voto" fmt=pct1 />
    <Column id=izq title="Izquierda" fmt=pct1 />
    <Column id=der title="Centro y derecha" fmt=pct1 />
    <Column id=nac title="Nacionalistas y reg." fmt=pct1 />
    <Column id=nep_votos title="Nº efectivo de partidos" fmt='0.0' />
</DataTable>

## Resultados por municipio

```sql municipios
SELECT
    municipio, provincia, poblacion, ganador_siglas,
    ganador_pct / 100 AS ganador_pct,
    participacion / 100 AS participacion,
    (participacion - participacion_anterior) AS dif_participacion,
    pct_izquierda / 100 AS izq,
    pct_derecha / 100 AS der,
    pct_nacionalistas / 100 AS nac,
    enlace
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

Resultado de las últimas generales en los {formatNumber(municipios_resumen[0]?.n, 0)} municipios. {municipios_resumen[0]?.mas_gana} fue la candidatura más votada en {formatNumber(municipios_resumen[0]?.n_mas_gana, 0)} de ellos. Busca el tuyo y pulsa para ver su ficha, con la evolución desde 1977.

<DataTable data={municipios} rows=15 search=true link=enlace>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=ganador_siglas title="Más votada" />
    <Column id=ganador_pct title="% voto" fmt=pct1 />
    <Column id=participacion title="Participación" fmt=pct1 />
    <Column id=dif_participacion title="vs. anteriores (p.p.)" fmt='+0.0;-0.0' contentType=delta />
    <Column id=izq title="Izquierda" fmt=pct1 />
    <Column id=der title="Centro y derecha" fmt=pct1 />
    <Column id=nac title="Nacionalistas y reg." fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Los resultados por municipio no incluyen el voto de los residentes en el extranjero (CERA), que se cuenta aparte en cada provincia. En algunos municipios pequeños de 1977 y 1979 los votantes registrados superan al censo por errores de la fuente: en esos casos no se da participación.</p>

---

## Fuentes y notas

- **[Ministerio del Interior – Área de descargas de resultados electorales](https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/)**: ficheros oficiales de cada proceso (formato de texto de longitud fija descrito en el documento FICHEROS que acompaña a cada descarga). Generales (Congreso) desde 1977, europeas desde 1987 y municipales desde 1979, con datos por municipio, provincia y comunidad.
- En las municipales solo se incluyen los municipios de más de 250 habitantes (listas cerradas); los de concejo abierto o listas abiertas se publican en otros ficheros.
- Las siglas se agrupan en familias políticas con los mismos criterios y colores que la página de [alcaldes](/territorios/municipios); la asignación de cada candidatura a una familia y a un bloque es de SpainFacts y puede discutirse en coaliciones (por ejemplo, UPN-PP cuenta como UPN y Ahora Repúblicas, en las europeas, como ERC en el total nacional).
- Porcentajes de voto sobre votos válidos (candidaturas y en blanco). Participación = votantes / censo de escrutinio.

<LastRefreshed prefix="Datos actualizados" />
