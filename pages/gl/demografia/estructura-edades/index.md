---
title: Idades e avellentamento
description: "Pirámides de poboación de España, cada comunidade e cada provincia; porcentaxe de maiores de 65 e 80 anos, taxa de dependencia e idade media desde 1971 (INE)."
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

# 🔺 Idades e avellentamento

Como se reparte a poboación por idades, canto avellentou España desde 1971 e que comunidades e provincias teñen a poboación máis maior.

<Grid cols=4>
    <KpiCard
        title="Maiores de 65 anos"
        value={espana.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_65, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_65, 2)} persoas en {espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.pct_65, 1)} % en {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Maiores de 80 anos"
        value={espana.slice(-1)[0]?.pct_80}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_80, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_80, 2)} persoas · {formatNumber(inicio[0]?.pct_80, 1)} % en {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_80}))}
    />
    <KpiCard
        title="Taxa de dependencia"
        value={espana.slice(-1)[0]?.dependencia}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.dependencia, 1)} %"
        period="menores de 16 e maiores de 64 por cada 100 persoas de 16 a 64 anos, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.dependencia}))}
    />
    <KpiCard
        title="Idade media"
        value={espana.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.edad_media, 1)} anos"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.edad_media, 1)} anos en {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('poblacion_65')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'poblacion_65')} />


## A pirámide de poboación de España

Compara a forma da pirámide en dous anos. Cada barra é a porcentaxe da poboación total que ten esa idade e sexo, así que as pirámides de anos con distinta poboación pódense comparar directamente.

<Dropdown data={anios} name=anio_a value=anio_txt title="Primeiro ano" defaultValue="1975" />
<Dropdown data={anios} name=anio_b value=anio_txt title="Segundo ano" />

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
        title="España, {inputs.anio_a.value}"
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
        title="España, {inputs.anio_b.value}"
    />
</Grid>

## Pirámide de cada comunidade e provincia, por lugar de nacemento

```sql territorios_opciones
SELECT '00' AS id, 'España' AS nombre, 0 AS orden
UNION ALL
SELECT 'c' || cod, nombre, 1 FROM mother.territorios WHERE nivel = 'ccaa'
UNION ALL
SELECT 'p' || cod, nombre || ' (provincia)', 2 FROM mother.territorios WHERE nivel = 'provincia'
ORDER BY orden, nombre
```

<Dropdown data={territorios_opciones} name=terr value=id label=nombre order=orden title="Territorio" defaultValue="00" />

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
    title="Poboación por idade, sexo e lugar de nacemento, {piramide_terr[0]?.anio} (% do total)"
/>

<p class="text-xs text-gray-500">Neste territorio, a 1 de xaneiro de {terr_resumen[0]?.anio_int}: {formatNumber(terr_resumen[0]?.pct_65, 1)} % de maiores de 65 anos, idade media de {formatNumber(terr_resumen[0]?.edad_media, 1)} anos e {formatNumber(terr_resumen[0]?.pct_nacidos_extranjero, 1)} % de nados no estranxeiro. Nado no estranxeiro non equivale a estranxeiro: o {formatNumber(terr_resumen[0]?.pct_extranjeros, 1)} % da poboación ten nacionalidade estranxeira.</p>

## Como avellentou España

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
        title="Poboación por grandes grupos de idade (% do total)"
    />
    <LineChart
        data={dependencia}
        x=anio
        y=valor
        series=tasa
        yFmt=num1
        xFmt="####"
        colorPalette={['#1e293b', '#c2410c']}
        yAxisTitle="por cada 100 persoas de 16 a 64 anos"
        title="Taxa de dependencia"
    />
</Grid>

<p class="text-xs text-gray-500">En {cruce[0]?.anio} España pasou por primeira vez a ter máis maiores de 64 anos ca menores de 16; hoxe hai {formatNumber(espana.slice(-1)[0]?.indice_envejecimiento, 0)} maiores por cada 100 menores (índice de avellentamento). A taxa de dependencia tocou o seu mínimo en {dep_min[0]?.anio} ({formatNumber(dep_min[0]?.dependencia, 1)}); a parte que corresponde aos maiores pasou de {formatNumber(inicio[0]?.dependencia_mayores, 1)} a {formatNumber(espana.slice(-1)[0]?.dependencia_mayores, 1)} por cada 100 persoas de 16 a 64 anos.</p>

## Por comunidade autónoma

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.pct_menores_16 / 100 AS pct_menores_16, e.dependencia, e.indice_envejecimiento, e.edad_media,
    e.pct_65 - e10.pct_65 AS cambio_65
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = e.cod AND e10.anio = e.anio - 10
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=pct_65 title="65 e máis" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=pct_80 title="80 e máis" fmt=pct1 />
    <Column id=pct_menores_16 title="Menores de 16" fmt=pct1 />
    <Column id=dependencia title="Taxa de dependencia" fmt=num1 />
    <Column id=indice_envejecimiento title="Maiores por 100 menores" fmt=num0 />
    <Column id=edad_media title="Idade media" fmt=num1 />
    <Column id=cambio_65 title="65+ fronte a hai 10 anos (p.p.)" fmt=num1 contentType=delta />
</DataTable>

## Por provincia

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.edad_media, e.dependencia
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

A provincia máis avellentada é {provincias[0]?.provincia}, cun {formatNumber(provincias[0]?.pct_65 / 0.01, 1)} % de maiores de 65 anos e unha idade media de {formatNumber(provincias[0]?.edad_media, 1)} anos; a máis nova, {provincias.slice(-1)[0]?.provincia}, cun {formatNumber(provincias.slice(-1)[0]?.pct_65 / 0.01, 1)} %.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Maiores de 65 anos en % da poboación"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_65', title: '65 e máis', fmt: 'pct1'},
        {id: 'pct_80', title: '80 e máis', fmt: 'pct1'},
        {id: 'edad_media', title: 'Idade media', fmt: 'num1'},
        {id: 'dependencia', title: 'Taxa de dependencia', fmt: 'num1'}
    ]}
/>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (táboa 56945): poboación a 1 de xaneiro por provincia, sexo e idade simple desde 1971. As comunidades suman as súas provincias.
- **[INE – Poboación por lugar de nacemento](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (táboa 56948): nados en España e no estranxeiro por provincia, sexo e grupo de idade desde 2002.
- Definicións dos Indicadores Demográficos Básicos do INE: taxa de dependencia = (menores de 16 + maiores de 64) / poboación de 16 a 64 × 100; índice de avellentamento = maiores de 64 / menores de 16 × 100. A idade media calcúlase coa idade simple (o grupo de 100 e máis anos conta como 100,5), polo que pode diferir en décimas da que publica o INE.

<LastRefreshed prefix="Datos actualizados" />
