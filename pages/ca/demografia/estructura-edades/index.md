---
title: Edats i envelliment
description: "Piràmides de població d'Espanya, de cada comunitat i de cada província; percentatge de més grans de 65 i 80 anys, taxa de dependència i edat mitjana des de 1971 (INE)."
i18n_origen: 4e6c769248eb
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT CAST(anio AS INTEGER) AS anio, poblacion, mayores_65, mayores_80, pct_menores_16, pct_65, pct_80,
    dependencia, dependencia_mayores, indice_envejecimiento, edad_media
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql inicio
SELECT * FROM ${espana} ORDER BY anio LIMIT 1
```

```sql anios
SELECT DISTINCT CAST(anio AS INTEGER) AS anio, CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio_txt
FROM mother.demografia_envejecimiento
ORDER BY anio DESC
```

# 🔺 Edats i envelliment

Com es reparteix la població per edats, quant ha envellit Espanya des de 1971 i quines comunitats i províncies tenen la població més gran.

<Grid cols=4>
    <KpiCard
        title="Més grans de 65 anys"
        value={espana.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_65, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_65, 2)} persones el {espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.pct_65, 1)} % el {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Més grans de 80 anys"
        value={espana.slice(-1)[0]?.pct_80}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_80, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_80, 2)} persones · {formatNumber(inicio[0]?.pct_80, 1)} % el {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_80}))}
    />
    <KpiCard
        title="Taxa de dependència"
        value={espana.slice(-1)[0]?.dependencia}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.dependencia, 1)} %"
        period="menors de 16 i més grans de 64 per cada 100 persones de 16 a 64 anys, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.dependencia}))}
    />
    <KpiCard
        title="Edat mitjana"
        value={espana.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.edad_media, 1)} anys"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.edad_media, 1)} anys el {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('poblacion_65')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'poblacion_65')} />


## La piràmide de població d'Espanya

Compara la forma de la piràmide en dos anys. Cada barra és el percentatge de la població total que té aquella edat i sexe, de manera que les piràmides d'anys amb una població diferent es poden comparar directament.

<Dropdown data={anios} name=anio_a value=anio_txt title="Primer any" defaultValue="1975" />
<Dropdown data={anios} name=anio_b value=anio_txt title="Segon any" />

```sql piramide_a
SELECT grupo, edad_desde, sexo, CASE WHEN sexo = 'Hombres' THEN -pct ELSE pct END AS pct
FROM mother.demografia_piramide
WHERE nivel = 'pais' AND CAST(anio AS INTEGER) = CAST('${inputs.anio_a.value}' AS INTEGER)
ORDER BY edad_desde, sexo
```

```sql piramide_b
SELECT grupo, edad_desde, sexo, CASE WHEN sexo = 'Hombres' THEN -pct ELSE pct END AS pct
FROM mother.demografia_piramide
WHERE nivel = 'pais' AND CAST(anio AS INTEGER) = CAST('${inputs.anio_b.value}' AS INTEGER)
ORDER BY edad_desde, sexo
```

<Grid cols=2>
    <BarChart
        data={piramide_a}
        x=grupo
        y=pct
        series=sexo
        swapXY=true
        type=stacked
        sort=false
        yFmt='0.0"%";0.0"%"'
        colorPalette={['#0f766e', '#7c3aed']}
        title="Espanya, {inputs.anio_a.value}"
    />
    <BarChart
        data={piramide_b}
        x=grupo
        y=pct
        series=sexo
        swapXY=true
        type=stacked
        sort=false
        yFmt='0.0"%";0.0"%"'
        colorPalette={['#0f766e', '#7c3aed']}
        title="Espanya, {inputs.anio_b.value}"
    />
</Grid>

## Piràmide de cada comunitat i província, per lloc de naixement

```sql territorios_opciones
SELECT '00' AS id, 'España' AS nombre, 0 AS orden
UNION ALL
SELECT 'c' || cod, nombre, 1 FROM mother.territorios WHERE nivel = 'ccaa'
UNION ALL
SELECT 'p' || cod, nombre || ' (provincia)', 2 FROM mother.territorios WHERE nivel = 'provincia'
ORDER BY orden, nombre
```

<Dropdown data={territorios_opciones} name=terr value=id label=nombre order=orden title="Territori" defaultValue="00" />

```sql piramide_terr
WITH p AS (
    SELECT * FROM mother.demografia_piramide
    WHERE anio = (SELECT max(anio) FROM mother.demografia_piramide WHERE nacidos_extranjero IS NOT NULL)
      AND CASE WHEN '${inputs.terr.value}' = '00' THEN nivel = 'pais'
               WHEN left('${inputs.terr.value}', 1) = 'c' THEN nivel = 'ccaa' AND cod = substr('${inputs.terr.value}', 2)
               ELSE nivel = 'provincia' AND cod = substr('${inputs.terr.value}', 2) END
)
SELECT grupo, edad_desde, CAST(anio AS INTEGER) AS anio,
    CASE WHEN sexo = 'Hombres' THEN 'Hombres nacidos en España' ELSE 'Mujeres nacidas en España' END AS serie,
    CASE WHEN sexo = 'Hombres' THEN -1 ELSE 1 END * (pct - pct_nacidos_extranjero) AS pct,
    CASE WHEN sexo = 'Hombres' THEN 1 ELSE 3 END AS orden_serie
FROM p
UNION ALL
SELECT grupo, edad_desde, CAST(anio AS INTEGER),
    CASE WHEN sexo = 'Hombres' THEN 'Hombres nacidos en el extranjero' ELSE 'Mujeres nacidas en el extranjero' END,
    CASE WHEN sexo = 'Hombres' THEN -1 ELSE 1 END * pct_nacidos_extranjero,
    CASE WHEN sexo = 'Hombres' THEN 2 ELSE 4 END
FROM p
ORDER BY edad_desde, orden_serie
```

```sql terr_resumen
SELECT e.*, CAST(e.anio AS INTEGER) AS anio_int
FROM mother.demografia_envejecimiento e
WHERE anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
  AND CASE WHEN '${inputs.terr.value}' = '00' THEN nivel = 'pais'
           WHEN left('${inputs.terr.value}', 1) = 'c' THEN nivel = 'ccaa' AND cod = substr('${inputs.terr.value}', 2)
           ELSE nivel = 'provincia' AND cod = substr('${inputs.terr.value}', 2) END
```

<BarChart
    data={piramide_terr}
    x=grupo
    y=pct
    series=serie
    swapXY=true
    type=stacked
    sort=false
    yFmt='0.0"%";0.0"%"'
    colorPalette={['#0f766e', '#5eead4', '#7c3aed', '#c4b5fd']}
    height=460
    title="Població per edat, sexe i lloc de naixement, {piramide_terr[0]?.anio} (% del total)"
/>

<p class="text-xs text-gray-500">En aquest territori, a 1 de gener de {terr_resumen[0]?.anio_int}: {formatNumber(terr_resumen[0]?.pct_65, 1)} % de més grans de 65 anys, edat mitjana de {formatNumber(terr_resumen[0]?.edad_media, 1)} anys i {formatNumber(terr_resumen[0]?.pct_nacidos_extranjero, 1)} % de nascuts a l'estranger. Nascut a l'estranger no equival a estranger: el {formatNumber(terr_resumen[0]?.pct_extranjeros, 1)} % de la població té nacionalitat estrangera.</p>

## Com ha envellit Espanya

```sql grandes_grupos
SELECT anio, 'Menores de 16' AS grupo, pct_menores_16 / 100 AS cuota FROM ${espana}
UNION ALL
SELECT anio, 'De 16 a 64', (100 - pct_menores_16 - pct_65) / 100 FROM ${espana}
UNION ALL
SELECT anio, 'De 65 a 79', (pct_65 - pct_80) / 100 FROM ${espana}
UNION ALL
SELECT anio, '80 y más', pct_80 / 100 FROM ${espana}
ORDER BY anio
```

```sql dependencia
SELECT anio, 'Total (menores de 16 y mayores de 64)' AS tasa, dependencia AS valor FROM ${espana}
UNION ALL
SELECT anio, 'Solo mayores de 64', dependencia_mayores FROM ${espana}
ORDER BY anio
```

```sql dep_min
SELECT anio, dependencia FROM ${espana} ORDER BY dependencia LIMIT 1
```

```sql cruce
SELECT min(anio) AS anio FROM ${espana} WHERE indice_envejecimiento >= 100
```

<Grid cols=2>
    <AreaChart
        data={grandes_grupos}
        x=anio
        y=cuota
        series=grupo
        type=stacked
        yFmt=pct0
        xFmt="####"
        colorPalette={['#60a5fa', '#94a3b8', '#fb923c', '#c2410c']}
        title="Població per grans grups d'edat (% del total)"
    />
    <LineChart
        data={dependencia}
        x=anio
        y=valor
        series=tasa
        yFmt=num1
        xFmt="####"
        colorPalette={['#1e293b', '#c2410c']}
        yAxisTitle="per cada 100 persones de 16 a 64 anys"
        title="Taxa de dependència"
    />
</Grid>

<p class="text-xs text-gray-500">El {cruce[0]?.anio} Espanya va passar per primera vegada a tenir més persones de més de 64 anys que menors de 16; avui n'hi ha {formatNumber(espana.slice(-1)[0]?.indice_envejecimiento, 0)} de grans per cada 100 menors (índex d'envelliment). La taxa de dependència va tocar el mínim el {dep_min[0]?.anio} ({formatNumber(dep_min[0]?.dependencia, 1)}); la part que correspon a la gent gran ha passat de {formatNumber(inicio[0]?.dependencia_mayores, 1)} a {formatNumber(espana.slice(-1)[0]?.dependencia_mayores, 1)} per cada 100 persones de 16 a 64 anys.</p>

## Per comunitat autònoma

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.pct_menores_16 / 100 AS pct_menores_16, e.dependencia, e.indice_envejecimiento, e.edad_media,
    e.pct_65 - e10.pct_65 AS cambio_65
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = e.cod AND e10.anio = e.anio - 10
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=pct_65 title="65 i més" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=pct_80 title="80 i més" fmt=pct1 />
    <Column id=pct_menores_16 title="Menors de 16" fmt=pct1 />
    <Column id=dependencia title="Taxa de dependència" fmt=num1 />
    <Column id=indice_envejecimiento title="Grans per 100 menors" fmt=num0 />
    <Column id=edad_media title="Edat mitjana" fmt=num1 />
    <Column id=cambio_65 title="65+ vs. fa 10 anys (p.p.)" fmt=num1 contentType=delta />
</DataTable>

## Per província

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.edad_media, e.dependencia
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

La província més envellida és {provincias[0]?.provincia}, amb un {formatNumber(provincias[0]?.pct_65 / 0.01, 1)} % de més grans de 65 anys i una edat mitjana de {formatNumber(provincias[0]?.edad_media, 1)} anys; la més jove, {provincias.slice(-1)[0]?.provincia}, amb un {formatNumber(provincias.slice(-1)[0]?.pct_65 / 0.01, 1)} %.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="pct_65"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fff7ed', '#fb923c', '#7c2d12']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Més grans de 65 anys en % de la població"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_65', title: '65 i més', fmt: 'pct1'},
        {id: 'pct_80', title: '80 i més', fmt: 'pct1'},
        {id: 'edad_media', title: 'Edat mitjana', fmt: 'num1'},
        {id: 'dependencia', title: 'Taxa de dependència', fmt: 'num1'}
    ]}
/>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (taula 56945): població a 1 de gener per província, sexe i edat simple des de 1971. Les comunitats sumen les seves províncies.
- **[INE – Població per lloc de naixement](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (taula 56948): nascuts a Espanya i a l'estranger per província, sexe i grup d'edat des del 2002.
- Definicions dels Indicadors Demogràfics Bàsics de l'INE: taxa de dependència = (menors de 16 + més grans de 64) / població de 16 a 64 × 100; índex d'envelliment = més grans de 64 / menors de 16 × 100. L'edat mitjana es calcula amb l'edat simple (el grup de 100 anys o més compta com a 100,5), per la qual cosa pot diferir en dècimes de la que publica l'INE.

<LastRefreshed prefix="Dades actualitzades" />
