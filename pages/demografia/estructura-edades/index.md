---
title: Edades y envejecimiento
description: "Pirámides de población de España, cada comunidad y cada provincia; porcentaje de mayores de 65 y 80 años, tasa de dependencia y edad media desde 1971 (INE)."
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🔺 Edades y envejecimiento

Cómo se reparte la población por edades, cuánto ha envejecido España desde 1971 y qué comunidades y provincias tienen la población más mayor.

<Grid cols=4>
    <KpiCard
        title="Mayores de 65 años"
        value={espana.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_65, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_65, 2)} personas en {espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.pct_65, 1)} % en {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Mayores de 80 años"
        value={espana.slice(-1)[0]?.pct_80}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_80, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_80, 2)} personas · {formatNumber(inicio[0]?.pct_80, 1)} % en {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_80}))}
    />
    <KpiCard
        title="Tasa de dependencia"
        value={espana.slice(-1)[0]?.dependencia}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.dependencia, 1)} %"
        period="menores de 16 y mayores de 64 por cada 100 personas de 16 a 64 años, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.dependencia}))}
    />
    <KpiCard
        title="Edad media"
        value={espana.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.edad_media, 1)} años"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.edad_media, 1)} años en {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('poblacion_65')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'poblacion_65')} />


## La pirámide de población de España

Compara la forma de la pirámide en dos años. Cada barra es el porcentaje de la población total que tiene esa edad y sexo, así que las pirámides de años con distinta población se pueden comparar directamente.

<Dropdown data={anios} name=anio_a value=anio_txt title="Primer año" defaultValue="1975" />
<Dropdown data={anios} name=anio_b value=anio_txt title="Segundo año" />

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

## Pirámide de cada comunidad y provincia, por lugar de nacimiento

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
    title="Población por edad, sexo y lugar de nacimiento, {piramide_terr[0]?.anio} (% del total)"
/>

<p class="text-xs text-gray-500">En este territorio, a 1 de enero de {terr_resumen[0]?.anio_int}: {formatNumber(terr_resumen[0]?.pct_65, 1)} % de mayores de 65 años, edad media de {formatNumber(terr_resumen[0]?.edad_media, 1)} años y {formatNumber(terr_resumen[0]?.pct_nacidos_extranjero, 1)} % de nacidos en el extranjero. Nacido en el extranjero no equivale a extranjero: {formatNumber(terr_resumen[0]?.pct_extranjeros, 1)} % de la población tiene nacionalidad extranjera.</p>

## Cómo ha envejecido España

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
        title="Población por grandes grupos de edad (% del total)"
    />
    <LineChart
        data={dependencia}
        x=anio
        y=valor
        series=tasa
        yFmt=num1
        xFmt="####"
        colorPalette={['#1e293b', '#c2410c']}
        yAxisTitle="por cada 100 personas de 16 a 64 años"
        title="Tasa de dependencia"
    />
</Grid>

<p class="text-xs text-gray-500">En {cruce[0]?.anio} España pasó por primera vez a tener más mayores de 64 años que menores de 16; hoy hay {formatNumber(espana.slice(-1)[0]?.indice_envejecimiento, 0)} mayores por cada 100 menores (índice de envejecimiento). La tasa de dependencia tocó su mínimo en {dep_min[0]?.anio} ({formatNumber(dep_min[0]?.dependencia, 1)}); la parte que corresponde a los mayores ha pasado de {formatNumber(inicio[0]?.dependencia_mayores, 1)} a {formatNumber(espana.slice(-1)[0]?.dependencia_mayores, 1)} por cada 100 personas de 16 a 64 años.</p>

## Por comunidad autónoma

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, t.ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.pct_menores_16 / 100 AS pct_menores_16, e.dependencia, e.indice_envejecimiento, e.edad_media,
    e.pct_65 - e10.pct_65 AS cambio_65
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = e.cod AND e10.anio = e.anio - 10
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=pct_65 title="65 y más" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=pct_80 title="80 y más" fmt=pct1 />
    <Column id=pct_menores_16 title="Menores de 16" fmt=pct1 />
    <Column id=dependencia title="Tasa de dependencia" fmt=num1 />
    <Column id=indice_envejecimiento title="Mayores por 100 menores" fmt=num0 />
    <Column id=edad_media title="Edad media" fmt=num1 />
    <Column id=cambio_65 title="65+ vs hace 10 años (p.p.)" fmt=num1 contentType=delta />
</DataTable>

## Por provincia

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, t.ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.edad_media, e.dependencia
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

La provincia más envejecida es {provincias[0]?.provincia}, con un {formatNumber(provincias[0]?.pct_65 / 0.01, 1)} % de mayores de 65 años y una edad media de {formatNumber(provincias[0]?.edad_media, 1)} años; la más joven, {provincias.slice(-1)[0]?.provincia}, con un {formatNumber(provincias.slice(-1)[0]?.pct_65 / 0.01, 1)} %.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Mayores de 65 años en % de la población"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_65', title: '65 y más', fmt: 'pct1'},
        {id: 'pct_80', title: '80 y más', fmt: 'pct1'},
        {id: 'edad_media', title: 'Edad media', fmt: 'num1'},
        {id: 'dependencia', title: 'Tasa de dependencia', fmt: 'num1'}
    ]}
/>

---

## Fuentes y notas

- **[INE – Estadística Continua de Población](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (tabla 56945): población a 1 de enero por provincia, sexo y edad simple desde 1971. Las comunidades suman sus provincias.
- **[INE – Población por lugar de nacimiento](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (tabla 56948): nacidos en España y en el extranjero por provincia, sexo y grupo de edad desde 2002.
- Definiciones de los Indicadores Demográficos Básicos del INE: tasa de dependencia = (menores de 16 + mayores de 64) / población de 16 a 64 × 100; índice de envejecimiento = mayores de 64 / menores de 16 × 100. La edad media se calcula con la edad simple (el grupo de 100 y más años cuenta como 100,5), por lo que puede diferir en décimas de la que publica el INE.

<LastRefreshed prefix="Datos actualizados" />
