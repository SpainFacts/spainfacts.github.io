---
title: Eleccións
description: "Resultados das eleccións xerais desde 1977, europeas e municipais: participación, voto por partido e por bloque, fragmentación, votos por escano e gañador en cada provincia e municipio, cos datos oficiais do Ministerio do Interior."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 52a869023a0e
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // As etiquetas de data veñen do SQL cos meses abreviados en castelán
    const mesesGl = {'ene.': 'xan.', 'feb.': 'feb.', 'mar.': 'mar.', 'abr.': 'abr.', 'may.': 'mai.', 'jun.': 'xuñ.', 'jul.': 'xul.', 'ago.': 'ago.', 'sep.': 'set.', 'oct.': 'out.', 'nov.': 'nov.', 'dic.': 'dec.'};
    const mesGl = (t) => (t == null ? t : String(t).replace(/^(\S+\.)/, (m) => mesesGl[m] ?? m));
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

# 🗳️ Eleccións

Canta xente vota, a quen e como se reparten os escanos: todas as eleccións xerais desde 1977, ademais das europeas e das municipais, cos resultados oficiais do Ministerio do Interior por comunidade, provincia e municipio.

<Grid cols=4>
    <KpiCard
        title="Participación nas xerais"
        value={resumen[0]?.participacion}
        formattedValue="{formatNumber(resumen[0]?.participacion, 1)} %"
        period="{resumen[0]?.fecha_txt} · {formatCompact(resumen[0]?.votantes, 3)} votantes de {formatCompact(resumen[0]?.censo, 3)} electores"
        change={resumen[0]?.dif_participacion}
        changeUnit="p.p."
        changePeriod="fronte a {mesGl(resumen[0]?.etiqueta_anterior)}"
        direction="positive-up"
        source="Ministerio do Interior"
        sparklineData={generales}
    />
    <KpiCard
        title="Candidatura máis votada"
        value={resumen[0]?.ganador_pct}
        formattedValue="{resumen[0]?.ganador_siglas} · {formatNumber(resumen[0]?.ganador_pct, 1)} %"
        period="{formatNumber(resumen[0]?.ganador_escanos, 0)} de 350 escanos · segunda: {resumen[0]?.segundo_siglas} ({formatNumber(resumen[0]?.segundo_pct, 1)} %)"
        source="Ministerio do Interior"
        sparklineData={generales.map(d => ({valor: d.ganador_pct}))}
    />
    <KpiCard
        title="Número efectivo de partidos"
        value={resumen[0]?.nep_votos}
        formattedValue={formatNumber(resumen[0]?.nep_votos, 1)}
        period="en votos ({formatNumber(resumen[0]?.nep_escanos, 1)} en escanos) · 2 = bipartidismo puro"
        change={resumen[0]?.dif_nep}
        changeUnit=""
        changePeriod="fronte a {mesGl(resumen[0]?.etiqueta_anterior)}"
        source="Cálculo propio"
        sparklineData={generales.map(d => ({valor: d.nep_votos}))}
    />
    <KpiCard
        title="Voto ás dúas máis votadas"
        value={resumen[0]?.dos_primeros}
        formattedValue="{formatNumber(resumen[0]?.dos_primeros, 1)} %"
        period="{resumen[0]?.ganador_siglas} + {resumen[0]?.segundo_siglas}, sobre os votos válidos"
        change={resumen[0]?.dif_dos}
        changeUnit="p.p."
        changePeriod="fronte a {mesGl(resumen[0]?.etiqueta_anterior)}"
        source="Ministerio do Interior"
        sparklineData={generales.map(d => ({valor: d.dos_primeros}))}
    />
</Grid>

<p class="text-xs text-gray-500">As porcentaxes de voto calcúlanse sobre os votos válidos (a candidaturas e en branco), como nos resultados oficiais. A participación inclúe o voto dos españois residentes no estranxeiro (CERA).</p>

## Participación

A participación nas xerais foi do {formatNumber(resumen[0]?.min_part, 1)} % ({mesGl(resumen[0]?.min_part_etiqueta)}) ao {formatNumber(resumen[0]?.max_part, 1)} % ({mesGl(resumen[0]?.max_part_etiqueta)}). Nas europeas e nas municipais a participación adoita ser menor.

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
    title="Participación sobre o censo, en %"
/>

## Voto por bloque

<ButtonGroup name=tipo title="Elección">
    <ButtonGroupItem valueLabel="Xerais" value="02" default />
    <ButtonGroupItem valueLabel="Europeas" value="07" />
    <ButtonGroupItem valueLabel="Municipais" value="04" />
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

Cada candidatura asígnase a unha familia política e cada familia a un de catro bloques. Nas últimas eleccións deste tipo ({mesGl(bloques_ultima[0]?.etiqueta)}) a esquerda estatal sumou o {formatNumber(bloques_ultima[0]?.izq, 1)} % dos votos válidos, o centro e a dereita estatais o {formatNumber(bloques_ultima[0]?.der, 1)} % e os partidos nacionalistas e rexionalistas o {formatNumber(bloques_ultima[0]?.nac, 1)} %.

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
    title="Voto por bloque, en % dos votos válidos (o resto ata 100 é voto en branco)"
/>

<p class="text-xs text-gray-500">Esquerda: PSOE e a familia de IU, Podemos e Sumar (con PCE, ICV, as confluencias e Más País). Centro e dereita: UCD, CDS, AP-PP, Ciudadanos, UPyD, Vox e UPN. Nacionalistas e rexionalistas: partidos de ámbito autonómico (CiU-Junts, ERC, PNV, EH Bildu, BNG, Coalición Canaria, Compromís, PAR, PRC, Teruel Existe...). Outros: o resto de candidaturas, sobre todo pequenas e, nas municipais, agrupacións de electores e independentes. É unha clasificación de SpainFacts: o detalle de que siglas van a cada familia está no código da web (seed elecciones_partidos_reglas).</p>

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

Porcentaxe de voto de cada familia política (as que algunha vez superaron o 3 % en toda España). Os partidos agrúpanse coas súas federacións e antecesores: o PSOE inclúe o PSC; o PP, AP e as súas coalicións; IU, Podemos e Sumar, o PCE e todas as súas confluencias.

<LineChart
    data={familias_evol}
    x=fecha
    y=pct
    series=familia
    yFmt='0.0"%"'
    markers=true
    seriesColors={Object.fromEntries(colores_familias.map(d => [d.familia, d.color]))}
    title="Voto por familia política, en % dos votos válidos"
/>

## Fragmentación

O número efectivo de partidos resume nunha cifra cantos partidos «contan»: vale 2 se dous partidos se reparten o voto a partes iguais e medra canto máis repartido está. Nas xerais foi de {formatNumber(resumen[0]?.min_nep, 1)} ({mesGl(resumen[0]?.min_nep_etiqueta)}) a {formatNumber(resumen[0]?.max_nep, 1)} ({mesGl(resumen[0]?.max_nep_etiqueta)}).

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
    title="Número efectivo de partidos nas xerais (Laakso-Taagepera)"
/>

<p class="text-xs text-gray-500">Número efectivo de partidos = 1 / suma dos cadrados das cotas de voto (ou de escanos) de cada candidatura. Calcúlase coas candidaturas agrupadas como no reconto nacional (o PSC dentro do PSOE, as listas provinciais de Sumar dentro de Sumar...). Que sexa menor en escanos ca en votos indica que o reparto favorece os partidos grandes.</p>

## Votos por escano

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

Os 350 escanos repártense por provincias coa regra D'Hondt, así que o número de votos que custa cada escano cambia moito dun partido a outro. Nas últimas xerais ({resumen[0]?.fecha_txt}) cada escano de {vpe_resumen[0]?.min_siglas} custou {formatNumber(vpe_resumen[0]?.min_vpe, 0)} votos e cada un de {vpe_resumen[0]?.max_siglas}, {formatNumber(vpe_resumen[0]?.max_vpe, 0)}. As candidaturas que quedaron sen escano reuniron o {formatNumber(vpe_sin[0]?.pct_sin_escano, 1)} % dos votos válidos.

<BarChart
    data={ultima_partidos}
    x=siglas
    y=votos_por_escano
    yFmt=num0
    swapXY=true
    fillColor="#1d4ed8"
    title="Votos por escano nas últimas xerais"
/>

<DataTable data={ultima_partidos} rows=20>
    <Column id=siglas title="Candidatura" />
    <Column id=pct title="% voto" fmt='0.00"%"' />
    <Column id=escanos title="Escanos" fmt=num0 />
    <Column id=pct_escanos title="% escanos" fmt='0.00"%"' />
    <Column id=ventaja title="Escanos − voto (p.p.)" fmt='+0.00;-0.00' contentType=delta />
    <Column id=votos_por_escano title="Votos por escano" fmt=num0 />
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
    title="Desproporcionalidade entre votos e escanos nas xerais (índice de Gallagher)"
/>

<p class="text-xs text-gray-500">Índice de Gallagher = raíz da metade da suma dos cadrados das diferenzas entre a % de voto e a % de escanos de cada candidatura. 0 sería un reparto perfectamente proporcional.</p>

## Gañador en cada provincia

```sql lista_generales
SELECT proceso, etiqueta, row_number() OVER (ORDER BY fecha DESC) AS orden FROM ${generales} ORDER BY fecha DESC
```

<Dropdown name=eleccion title="Eleccións xerais" data={lista_generales} value=proceso label=etiqueta order=orden />

```sql provincias
SELECT
    p.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta,
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

A familia política da candidatura máis votada en cada provincia (a circunscrición das xerais).

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio do Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ganador_siglas', title: 'Máis votada'},
        {id: 'ganador_pct', title: '% voto', fmt: 'pct1'},
        {id: 'segundo_siglas', title: 'Segunda'},
        {id: 'segundo_pct', title: '% voto', fmt: 'pct1'},
        {id: 'participacion', title: 'Participación', fmt: 'pct1'},
        {id: 'escanos', title: 'Escanos', fmt: 'num0'}
    ]}
/>

```sql ccaa
SELECT
    t.nombre AS comunidad, '/gl' || t.ruta AS ruta,
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
    <Column id=comunidad title="Comunidade" />
    <Column id=participacion title="Participación" fmt=pct1 />
    <Column id=ganador_siglas title="Máis votada" />
    <Column id=ganador_pct title="% voto" fmt=pct1 />
    <Column id=izq title="Esquerda" fmt=pct1 />
    <Column id=der title="Centro e dereita" fmt=pct1 />
    <Column id=nac title="Nacionalistas e rex." fmt=pct1 />
    <Column id=nep_votos title="N.º efectivo de partidos" fmt='0.0' />
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
    '/gl' || enlace AS enlace
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

Resultado das últimas xerais nos {formatNumber(municipios_resumen[0]?.n, 0)} municipios. {municipios_resumen[0]?.mas_gana} foi a candidatura máis votada en {formatNumber(municipios_resumen[0]?.n_mas_gana, 0)} deles. Busca o teu e preme para ver a súa ficha, coa evolución desde 1977.

<DataTable data={municipios} rows=15 search=true link=enlace>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=ganador_siglas title="Máis votada" />
    <Column id=ganador_pct title="% voto" fmt=pct1 />
    <Column id=participacion title="Participación" fmt=pct1 />
    <Column id=dif_participacion title="fronte ás anteriores (p.p.)" fmt='+0.0;-0.0' contentType=delta />
    <Column id=izq title="Esquerda" fmt=pct1 />
    <Column id=der title="Centro e dereita" fmt=pct1 />
    <Column id=nac title="Nacionalistas e rex." fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Os resultados por municipio non inclúen o voto dos residentes no estranxeiro (CERA), que se conta á parte en cada provincia. Nalgúns municipios pequenos de 1977 e 1979 os votantes rexistrados superan o censo por erros da fonte: nesos casos non se dá participación.</p>

---

## Fontes e notas

- **[Ministerio do Interior – Área de descargas de resultados electorais](https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/)**: ficheiros oficiais de cada proceso (formato de texto de lonxitude fixa descrito no documento FICHEROS que acompaña cada descarga). Xerais (Congreso) desde 1977, europeas desde 1987 e municipais desde 1979, con datos por municipio, provincia e comunidade.
- Nas municipais só se inclúen os municipios de máis de 250 habitantes (listas pechadas); os de concello aberto ou listas abertas publícanse noutros ficheiros.
- As siglas agrúpanse en familias políticas cos mesmos criterios e cores que a páxina de [alcaldes](/gl/territorios/municipios); a asignación de cada candidatura a unha familia e a un bloque é de SpainFacts e pode discutirse en coalicións (por exemplo, UPN-PP conta como UPN e Ahora Repúblicas, nas europeas, como ERC no total nacional).
- Porcentaxes de voto sobre votos válidos (candidaturas e en branco). Participación = votantes / censo de escrutinio.

<LastRefreshed prefix="Datos actualizados" />
