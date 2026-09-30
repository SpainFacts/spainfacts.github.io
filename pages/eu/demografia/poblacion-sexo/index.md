---
title: Gizonak eta emakumeak
description: "Zenbat gizon dauden 100 emakumeko Espainian adinaren arabera, 1971tik, eta erkidego eta probintzia bakoitzean (INE)."
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

# ⚖️ Gizonak eta emakumeak

Espainian neska baino mutil apur bat gehiago jaiotzen dira, baina emakumeak gehiago bizi dira: horregatik daude gizon gehiago gazteen artean eta emakume gehiago adinekoen artean. Hemen 100 emakumeko dagoen gizon kopuruarekin neurtzen da.

<Grid cols=4>
    <KpiCard
        title="Gizonak 100 emakumeko"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres, 1)}
        period="biztanleria osoa, {espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.pct_mujeres, 1)} % emakumeak dira"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres}))}
    />
    <KpiCard
        title="5 urtetik beherakoen artean"
        value={espana.slice(-1)[0]?.ratio_0_4}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_0_4, 1)}
        period="gizonak 0 eta 4 urte bitarteko 100 emakumeko"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_0_4}))}
    />
    <KpiCard
        title="65 urtetik gorakoen artean"
        value={espana.slice(-1)[0]?.hombres_por_100_mujeres_65}
        formattedValue={formatNumber(espana.slice(-1)[0]?.hombres_por_100_mujeres_65, 1)}
        period="gizonak 65 urteko eta gehiagoko 100 emakumeko"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.hombres_por_100_mujeres_65}))}
    />
    <KpiCard
        title="85 urtetik gorakoen artean"
        value={espana.slice(-1)[0]?.ratio_85}
        formattedValue={formatNumber(espana.slice(-1)[0]?.ratio_85, 1)}
        period="gizonak 85 urteko eta gehiagoko 100 emakumeko"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.ratio_85}))}
    />
</Grid>

## Adinaren arabera

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
    yAxisTitle="gizonak 100 emakumeko"
    title="Gizonak 100 emakumeko, adin-talde bakoitzean"
>
    <ReferenceLine y=100 color="#64748b" />
</LineChart>

<p class="text-xs text-gray-500">100etik gora, gizon gehiago daude emakumeak baino; behetik, emakume gehiago. Gaur egun emakumeak gehiengoa dira adin-talde guztietan, adin honetatik aurrera: {cruce[0]?.edad} urte.</p>

## Bilakaera

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
    yAxisTitle="gizonak 100 emakumeko"
    title="Gizonak 100 emakumeko, 1971-{espana.slice(-1)[0]?.anio}"
/>

## Erkidego eta probintziaka

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY ratio DESC
```

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta, e.hombres_por_100_mujeres AS ratio, e.hombres_por_100_mujeres_65 AS ratio_65, e.edad_media
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
        attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
        title="Gizonak 100 emakumeko probintzia bakoitzean"
        tooltip={[
            {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'ratio', title: 'Gizonak 100 emakumeko', fmt: 'num1'},
            {id: 'ratio_65', title: '65 urtetik gorakoen artean', fmt: 'num1'},
            {id: 'edad_media', title: 'Batez besteko adina', fmt: 'num1'}
        ]}
    />
    <DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
        <Column id=comunidad title="Erkidegoa" />
        <Column id=ratio title="Gizonak 100 emakumeko" fmt=num1 contentType=bar barColor="#ddd6fe" />
        <Column id=ratio_65 title="…65 urtetik gorakoen artean" fmt=num1 />
    </DataTable>
</Grid>

<p class="text-xs text-gray-500">{provincias.length} probintzietatik {provincias.filter(d => d.ratio < 100).length} probintziatan emakume gehiago daude gizonak baino. Gizonen proportzio altuena {provincias[0]?.provincia} probintzian dago ({formatNumber(provincias[0]?.ratio, 1)}), eta baxuena {provincias.slice(-1)[0]?.provincia} probintzian ({formatNumber(provincias.slice(-1)[0]?.ratio, 1)}).</p>

---

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (56945 taula): urtarrilaren 1eko biztanleria probintzia, sexu eta adin bakunaren arabera 1971tik. Erkidegoek beren probintziak batzen dituzte.

<LastRefreshed prefix="Datuak eguneratuta" />
