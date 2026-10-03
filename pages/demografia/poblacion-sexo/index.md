---
title: Hombres y mujeres
description: "Cuántos hombres hay por cada 100 mujeres en España según la edad, desde 1971, y en cada comunidad y provincia (INE)."
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql grupos
SELECT CAST(anio AS INTEGER) AS anio, edad_desde, grupo,
    100.0 * max(poblacion) FILTER (WHERE sexo = 'Hombres') / max(poblacion) FILTER (WHERE sexo = 'Mujeres') AS ratio
FROM mother.demografia_piramide
WHERE nivel = 'pais'
GROUP BY ALL
ORDER BY anio, edad_desde
```

```sql espana
SELECT CAST(e.anio AS INTEGER) AS anio, e.hombres_por_100_mujeres, e.hombres_por_100_mujeres_65, e.poblacion,
    100.0 / (1 + e.hombres_por_100_mujeres / 100) AS pct_mujeres,
    g0.ratio AS ratio_0_4, g85.ratio AS ratio_85
FROM mother.demografia_envejecimiento e
LEFT JOIN ${grupos} g0 ON g0.anio = e.anio AND g0.edad_desde = 0
LEFT JOIN ${grupos} g85 ON g85.anio = e.anio AND g85.edad_desde = 85
WHERE e.nivel = 'pais'
ORDER BY 1
```

```sql cruce
-- Edad a partir de la cual todos los grupos (último año) tienen menos hombres que mujeres
SELECT min(edad_desde) AS edad
FROM ${grupos}
WHERE anio = (SELECT max(anio) FROM ${grupos})
  AND edad_desde > (SELECT max(edad_desde) FROM ${grupos} WHERE anio = (SELECT max(anio) FROM ${grupos}) AND ratio >= 100)
```

# ⚖️ Hombres y mujeres

En España nacen algo más de niños que de niñas, pero las mujeres viven más: por eso hay más hombres entre los jóvenes y más mujeres entre los mayores. Aquí se mide con el número de hombres por cada 100 mujeres.

<Grid cols=4>
    <KpiCard
        title="Hombres por cada 100 mujeres"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres, 1)}
        period="toda la población, {espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.pct_mujeres, 1)} % son mujeres"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres}))}
    />
    <KpiCard
        title="Entre los menores de 5 años"
        value={espana.slice(-1)[0]?.ratio_0_4}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_0_4, 1)}
        period="hombres por cada 100 mujeres de 0 a 4 años"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_0_4}))}
    />
    <KpiCard
        title="Entre los mayores de 65 años"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres_65}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres_65, 1)}
        period="hombres por cada 100 mujeres de 65 y más años"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres_65}))}
    />
    <KpiCard
        title="Entre los mayores de 85 años"
        value={espana.slice(-1)[0]?.ratio_85}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_85, 1)}
        period="hombres por cada 100 mujeres de 85 y más años"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_85}))}
    />
</Grid>

## Según la edad

```sql por_edad
SELECT grupo, edad_desde, CAST(anio AS VARCHAR) AS anio, ratio
FROM ${grupos}
WHERE anio IN (1975, (SELECT max(anio) FROM ${grupos}))
ORDER BY edad_desde, anio
```

<LineChart
    data={por_edad}
    x=grupo
    y=ratio
    series=anio
    sort=false
    yFmt=num0
    colorPalette={['#94a3b8', '#7c3aed']}
    yAxisTitle="hombres por cada 100 mujeres"
    title="Hombres por cada 100 mujeres en cada grupo de edad"
>
    <ReferenceLine y=100 color="#64748b" />
</LineChart>

<p class="text-xs text-gray-500">Por encima de 100 hay más hombres que mujeres; por debajo, más mujeres. Hoy las mujeres son mayoría en todos los grupos de edad a partir de los {cruce[0]?.edad} años.</p>

## Evolución

```sql evolucion
SELECT anio, 'Toda la población' AS grupo, hombres_por_100_mujeres AS ratio FROM ${espana}
UNION ALL
SELECT anio, '65 y más años', hombres_por_100_mujeres_65 FROM ${espana}
ORDER BY anio
```

<LineChart
    data={evolucion}
    x=anio
    y=ratio
    series=grupo
    yFmt=num1
    xFmt="####"
    colorPalette={['#7c3aed', '#c2410c']}
    yAxisTitle="hombres por cada 100 mujeres"
    title="Hombres por cada 100 mujeres, 1971-{espana.slice(-1)[0]?.anio}"
/>

## Por comunidad y provincia

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, t.ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, t.ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.edad_media
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

<Grid cols=2>
    <MapaEspana
        data={provincias}
        geoJsonUrl="/geo/provincias.geojson"
        geoId="cod_prov"
        areaCol="cod_prov"
        value="ratio"
        valueFmt="num1"
        link="ruta"
        colorPalette={['#7c3aed', '#f8fafc', '#0f766e']}
        height={420}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        title="Hombres por cada 100 mujeres en cada provincia"
        tooltip={[
            {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'ratio', title: 'Hombres por 100 mujeres', fmt: 'num1'},
            {id: 'ratio_65', title: 'Entre los mayores de 65', fmt: 'num1'},
            {id: 'edad_media', title: 'Edad media', fmt: 'num1'}
        ]}
    />
    <DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
        <Column id=comunidad title="Comunidad" />
        <Column id=ratio title="Hombres por 100 mujeres" fmt=num1 contentType=bar barColor="#ddd6fe" />
        <Column id=ratio_65 title="…entre los mayores de 65" fmt=num1 />
    </DataTable>
</Grid>

<p class="text-xs text-gray-500">En {provincias.filter(d => d.ratio < 100).length} de las {provincias.length} provincias hay más mujeres que hombres. La proporción más alta de hombres está en {provincias[0]?.provincia} ({formatNumber(provincias[0]?.ratio, 1)}) y la más baja en {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.ratio, 1)}).</p>

---

## Fuentes y notas

- **[INE – Estadística Continua de Población](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (tabla 56945): población a 1 de enero por provincia, sexo y edad simple desde 1971. Las comunidades suman sus provincias.

<LastRefreshed prefix="Datos actualizados" />
