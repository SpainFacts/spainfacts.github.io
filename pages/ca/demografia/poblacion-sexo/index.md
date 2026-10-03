---
title: Homes i dones
description: "Quants homes hi ha per cada 100 dones a Espanya segons l'edat, des de 1971, i a cada comunitat i província (INE)."
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

# ⚖️ Homes i dones

A Espanya neixen una mica més de nens que de nenes, però les dones viuen més: per això hi ha més homes entre els joves i més dones entre la gent gran. Aquí es mesura amb el nombre d'homes per cada 100 dones.

<Grid cols=4>
    <KpiCard
        title="Homes per cada 100 dones"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres, 1)}
        period="tota la població, {espana.slice(-1)[0]?.anio} · el {formatNumber(espana.slice(-1)[0]?.pct_mujeres, 1)} % són dones"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres}))}
    />
    <KpiCard
        title="Entre els menors de 5 anys"
        value={espana.slice(-1)[0]?.ratio_0_4}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_0_4, 1)}
        period="homes per cada 100 dones de 0 a 4 anys"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_0_4}))}
    />
    <KpiCard
        title="Entre els més grans de 65 anys"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres_65}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres_65, 1)}
        period="homes per cada 100 dones de 65 anys o més"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres_65}))}
    />
    <KpiCard
        title="Entre els més grans de 85 anys"
        value={espana.slice(-1)[0]?.ratio_85}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_85, 1)}
        period="homes per cada 100 dones de 85 anys o més"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_85}))}
    />
</Grid>

## Segons l'edat

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
    yAxisTitle="homes per cada 100 dones"
    title="Homes per cada 100 dones a cada grup d'edat"
>
    <ReferenceLine y=100 color="#64748b" />
</LineChart>

<p class="text-xs text-gray-500">Per sobre de 100 hi ha més homes que dones; per sota, més dones. Avui les dones són majoria en tots els grups d'edat a partir dels {cruce[0]?.edad} anys.</p>

## Evolució

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
    yAxisTitle="homes per cada 100 dones"
    title="Homes per cada 100 dones, 1971-{espana.slice(-1)[0]?.anio}"
/>

## Per comunitat i província

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.edad_media
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
        attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
        title="Homes per cada 100 dones a cada província"
        tooltip={[
            {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'ratio', title: 'Homes per 100 dones', fmt: 'num1'},
            {id: 'ratio_65', title: 'Entre els més grans de 65', fmt: 'num1'},
            {id: 'edad_media', title: 'Edat mitjana', fmt: 'num1'}
        ]}
    />
    <DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
        <Column id=comunidad title="Comunitat" />
        <Column id=ratio title="Homes per 100 dones" fmt=num1 contentType=bar barColor="#ddd6fe" />
        <Column id=ratio_65 title="…entre els més grans de 65" fmt=num1 />
    </DataTable>
</Grid>

<p class="text-xs text-gray-500">En {provincias.filter(d => d.ratio < 100).length} de les {provincias.length} províncies hi ha més dones que homes. La proporció més alta d'homes és a {provincias[0]?.provincia} ({formatNumber(provincias[0]?.ratio, 1)}) i la més baixa, a {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.ratio, 1)}).</p>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (taula 56945): població a 1 de gener per província, sexe i edat simple des de 1971. Les comunitats sumen les seves províncies.

<LastRefreshed prefix="Dades actualitzades" />
