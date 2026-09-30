---
title: Men and women
description: "How many men there are per 100 women in Spain by age, since 1971, and in each region and province (INE)."
i18n_origen: d21837969d2e
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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

# ⚖️ Men and women

Slightly more boys than girls are born in Spain, but women live longer: that is why there are more men among the young and more women among the old. Here it is measured as the number of men per 100 women.

<Grid cols=4>
    <KpiCard
        title="Men per 100 women"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres, 1)}
        period="whole population, {espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.pct_mujeres, 1)}% are women"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres}))}
    />
    <KpiCard
        title="Among under-5s"
        value={espana.slice(-1)[0]?.ratio_0_4}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_0_4, 1)}
        period="boys per 100 girls aged 0 to 4"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_0_4}))}
    />
    <KpiCard
        title="Among over-65s"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres_65}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres_65, 1)}
        period="men per 100 women aged 65 and over"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres_65}))}
    />
    <KpiCard
        title="Among over-85s"
        value={espana.slice(-1)[0]?.ratio_85}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_85, 1)}
        period="men per 100 women aged 85 and over"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_85}))}
    />
</Grid>

## By age

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
    yAxisTitle="men per 100 women"
    title="Men per 100 women in each age group"
>
    <ReferenceLine y=100 color="#64748b" />
</LineChart>

<p class="text-xs text-gray-500">Above 100 there are more men than women; below it, more women. Today women are the majority in every age group from {cruce[0]?.edad} upwards.</p>

## Over time

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
    yAxisTitle="men per 100 women"
    title="Men per 100 women, 1971-{espana.slice(-1)[0]?.anio}"
/>

## By region and province

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.edad_media
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

<Grid cols=2>
    <AreaMap
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
        attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
        title="Men per 100 women in each province"
        tooltip={[
            {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'ratio', title: 'Men per 100 women', fmt: 'num1'},
            {id: 'ratio_65', title: 'Among over-65s', fmt: 'num1'},
            {id: 'edad_media', title: 'Mean age', fmt: 'num1'}
        ]}
    />
    <DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
        <Column id=comunidad title="Region" />
        <Column id=ratio title="Men per 100 women" fmt=num1 contentType=bar barColor="#ddd6fe" />
        <Column id=ratio_65 title="…among over-65s" fmt=num1 />
    </DataTable>
</Grid>

<p class="text-xs text-gray-500">In {provincias.filter(d => d.ratio < 100).length} of the {provincias.length} provinces there are more women than men. The highest proportion of men is in {provincias[0]?.provincia} ({formatNumber(provincias[0]?.ratio, 1)}) and the lowest in {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.ratio, 1)}).</p>

---

## Sources and notes

- **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (table 56945): population on 1 January by province, sex and single year of age since 1971. Regional figures are the sum of their provinces.

<LastRefreshed prefix="Data updated" />
