---
title: Homes e mulleres
description: "Cantos homes hai por cada 100 mulleres en España segundo a idade, desde 1971, e en cada comunidade e provincia (INE)."
i18n_origen: aabf373a979e
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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

# ⚖️ Homes e mulleres

En España nacen algo máis nenos ca nenas, pero as mulleres viven máis: por iso hai máis homes entre a xente nova e máis mulleres entre os maiores. Aquí mídese co número de homes por cada 100 mulleres.

<Grid cols=4>
    <KpiCard
        title="Homes por cada 100 mulleres"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres, 1)}
        period="toda a poboación, {espana.slice(-1)[0]?.anio} · o {formatNumber(espana.slice(-1)[0]?.pct_mujeres, 1)} % son mulleres"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres}))}
    />
    <KpiCard
        title="Entre os menores de 5 anos"
        value={espana.slice(-1)[0]?.ratio_0_4}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_0_4, 1)}
        period="homes por cada 100 mulleres de 0 a 4 anos"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_0_4}))}
    />
    <KpiCard
        title="Entre os maiores de 65 anos"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres_65}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres_65, 1)}
        period="homes por cada 100 mulleres de 65 e máis anos"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres_65}))}
    />
    <KpiCard
        title="Entre os maiores de 85 anos"
        value={espana.slice(-1)[0]?.ratio_85}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_85, 1)}
        period="homes por cada 100 mulleres de 85 e máis anos"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_85}))}
    />
</Grid>

## Segundo a idade

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
    yAxisTitle="homes por cada 100 mulleres"
    title="Homes por cada 100 mulleres en cada grupo de idade"
>
    <ReferenceLine y=100 color="#64748b" />
</LineChart>

<p class="text-xs text-gray-500">Por riba de 100 hai máis homes ca mulleres; por debaixo, máis mulleres. Hoxe as mulleres son maioría en todos os grupos de idade a partir dos {cruce[0]?.edad} anos.</p>

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
    yAxisTitle="homes por cada 100 mulleres"
    title="Homes por cada 100 mulleres, 1971-{espana.slice(-1)[0]?.anio}"
/>

## Por comunidade e provincia

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.edad_media
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
        attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        title="Homes por cada 100 mulleres en cada provincia"
        tooltip={[
            {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'ratio', title: 'Homes por 100 mulleres', fmt: 'num1'},
            {id: 'ratio_65', title: 'Entre os maiores de 65', fmt: 'num1'},
            {id: 'edad_media', title: 'Idade media', fmt: 'num1'}
        ]}
    />
    <DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
        <Column id=comunidad title="Comunidade" />
        <Column id=ratio title="Homes por 100 mulleres" fmt=num1 contentType=bar barColor="#ddd6fe" />
        <Column id=ratio_65 title="…entre os maiores de 65" fmt=num1 />
    </DataTable>
</Grid>

<p class="text-xs text-gray-500">En {provincias.filter(d => d.ratio < 100).length} das {provincias.length} provincias hai máis mulleres ca homes. A proporción máis alta de homes está en {provincias[0]?.provincia} ({formatNumber(provincias[0]?.ratio, 1)}) e a máis baixa en {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.ratio, 1)}).</p>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (táboa 56945): poboación a 1 de xaneiro por provincia, sexo e idade simple desde 1971. As comunidades suman as súas provincias.

<LastRefreshed prefix="Datos actualizados" />
