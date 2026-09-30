---
title: Age and ageing
description: "Population pyramids for Spain, each region and each province; percentage of people over 65 and over 80, dependency ratio and mean age since 1971 (INE)."
i18n_origen: 2565fd7bf5bc
---

<script>
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

# 🔺 Age and ageing

How the population is distributed by age, how much Spain has aged since 1971 and which regions and provinces have the oldest populations.

<Grid cols=4>
    <KpiCard
        title="Aged 65 and over"
        value={espana.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_65, 1)}%"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_65, 2)} people in {espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.pct_65, 1)}% in {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Aged 80 and over"
        value={espana.slice(-1)[0]?.pct_80}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_80, 1)}%"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_80, 2)} people · {formatNumber(inicio[0]?.pct_80, 1)}% in {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_80}))}
    />
    <KpiCard
        title="Dependency ratio"
        value={espana.slice(-1)[0]?.dependencia}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.dependencia, 1)}%"
        period="under-16s and over-64s per 100 people aged 16 to 64, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.dependencia}))}
    />
    <KpiCard
        title="Mean age"
        value={espana.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.edad_media, 1)} years"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.edad_media, 1)} years in {inicio[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('poblacion_65')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'poblacion_65')} />


## Spain's population pyramid

Compare the shape of the pyramid in two years. Each bar is the percentage of the total population of that age and sex, so pyramids for years with different population sizes can be compared directly.

<Dropdown data={anios} name=anio_a value=anio_txt title="First year" defaultValue="1975" />
<Dropdown data={anios} name=anio_b value=anio_txt title="Second year" />

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
        title="Spain, {inputs.anio_a.value}"
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
        title="Spain, {inputs.anio_b.value}"
    />
</Grid>

## Pyramid for each region and province, by place of birth

```sql territorios_opciones
SELECT '00' AS id, 'España' AS nombre, 0 AS orden
UNION ALL
SELECT 'c' || cod, nombre, 1 FROM mother.territorios WHERE nivel = 'ccaa'
UNION ALL
SELECT 'p' || cod, nombre || ' (provincia)', 2 FROM mother.territorios WHERE nivel = 'provincia'
ORDER BY orden, nombre
```

<Dropdown data={territorios_opciones} name=terr value=id label=nombre order=orden title="Territory" defaultValue="00" />

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
    title="Population by age, sex and place of birth, {piramide_terr[0]?.anio} (% of total)"
/>

<p class="text-xs text-gray-500">In this territory, as at 1 January {terr_resumen[0]?.anio_int}: {formatNumber(terr_resumen[0]?.pct_65, 1)}% aged over 65, a mean age of {formatNumber(terr_resumen[0]?.edad_media, 1)} years and {formatNumber(terr_resumen[0]?.pct_nacidos_extranjero, 1)}% born abroad. Born abroad is not the same as foreign: {formatNumber(terr_resumen[0]?.pct_extranjeros, 1)}% of the population has foreign nationality.</p>

## How Spain has aged

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
        title="Population by broad age group (% of total)"
    />
    <LineChart
        data={dependencia}
        x=anio
        y=valor
        series=tasa
        yFmt=num1
        xFmt="####"
        colorPalette={['#1e293b', '#c2410c']}
        yAxisTitle="per 100 people aged 16 to 64"
        title="Dependency ratio"
    />
</Grid>

<p class="text-xs text-gray-500">In {cruce[0]?.anio} Spain had more people over 64 than under 16 for the first time; today there are {formatNumber(espana.slice(-1)[0]?.indice_envejecimiento, 0)} older people for every 100 young people (ageing index). The dependency ratio reached its low point in {dep_min[0]?.anio} ({formatNumber(dep_min[0]?.dependencia, 1)}); the part attributable to older people has risen from {formatNumber(inicio[0]?.dependencia_mayores, 1)} to {formatNumber(espana.slice(-1)[0]?.dependencia_mayores, 1)} per 100 people aged 16 to 64.</p>

## By autonomous community

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.pct_menores_16 / 100 AS pct_menores_16, e.dependencia, e.indice_envejecimiento, e.edad_media,
    e.pct_65 - e10.pct_65 AS cambio_65
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = e.cod AND e10.anio = e.anio - 10
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=pct_65 title="65 and over" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=pct_80 title="80 and over" fmt=pct1 />
    <Column id=pct_menores_16 title="Under 16" fmt=pct1 />
    <Column id=dependencia title="Dependency ratio" fmt=num1 />
    <Column id=indice_envejecimiento title="Older people per 100 young" fmt=num0 />
    <Column id=edad_media title="Mean age" fmt=num1 />
    <Column id=cambio_65 title="65+ vs 10 years ago (p.p.)" fmt=num1 contentType=delta />
</DataTable>

## By province

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.edad_media, e.dependencia
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

The oldest province is {provincias[0]?.provincia}, with {formatNumber(provincias[0]?.pct_65 / 0.01, 1)}% of its population over 65 and a mean age of {formatNumber(provincias[0]?.edad_media, 1)} years; the youngest is {provincias.slice(-1)[0]?.provincia}, with {formatNumber(provincias.slice(-1)[0]?.pct_65 / 0.01, 1)}%.

<AreaMap
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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="People aged over 65 as % of the population"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_65', title: '65 and over', fmt: 'pct1'},
        {id: 'pct_80', title: '80 and over', fmt: 'pct1'},
        {id: 'edad_media', title: 'Mean age', fmt: 'num1'},
        {id: 'dependencia', title: 'Dependency ratio', fmt: 'num1'}
    ]}
/>

---

## Sources and notes

- **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (table 56945): population on 1 January by province, sex and single year of age since 1971. Regional figures are the sum of their provinces.
- **[INE – Population by place of birth](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (table 56948): people born in Spain and abroad by province, sex and age group since 2002.
- Definitions from the INE Basic Demographic Indicators: dependency ratio = (under-16s + over-64s) / population aged 16 to 64 × 100; ageing index = over-64s / under-16s × 100. Mean age is calculated from single years of age (the 100-and-over group counts as 100.5), so it may differ by a few tenths from the figure published by the INE.

<LastRefreshed prefix="Data updated" />
