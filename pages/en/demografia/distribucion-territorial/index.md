---
title: Territorial distribution of the population
description: "How Spain's population is distributed across regions and provinces since 1975: concentration, provinces losing inhabitants and the percentage of foreign-born residents in each province (INE)."
i18n_origen: d77c92bbc1bf
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql prov_serie
SELECT CAST(e.anio AS INTEGER) AS anio, e.cod, e.poblacion, a.poblacion AS poblacion_antes,
    e.poblacion / sum(e.poblacion) OVER (PARTITION BY e.anio) AS cuota,
    row_number() OVER (PARTITION BY e.anio ORDER BY e.poblacion DESC) AS puesto
FROM mother.demografia_envejecimiento e
LEFT JOIN mother.demografia_envejecimiento a ON a.nivel = 'provincia' AND a.cod = e.cod AND a.anio = e.anio - 1
WHERE e.nivel = 'provincia'
```

```sql concentracion
SELECT anio,
    count(*) FILTER (WHERE poblacion < poblacion_antes) AS pierden,
    100 * sum(cuota) FILTER (WHERE puesto <= 5) AS pct_top5,
    count(*) FILTER (WHERE acumulada - cuota < 0.5) AS provincias_mitad
FROM (SELECT *, sum(cuota) OVER (PARTITION BY anio ORDER BY puesto) AS acumulada FROM ${prov_serie})
WHERE anio >= 1975
GROUP BY anio
ORDER BY anio
```

```sql origen
SELECT CAST(anio AS INTEGER) AS anio, pct_nacidos_extranjero, nacidos_extranjero, pct_extranjeros
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais' AND pct_nacidos_extranjero IS NOT NULL
ORDER BY anio
```

# 🗺️ Territorial distribution of the population

Where Spain's population lives, which regions and provinces are gaining and losing weight, and in which provinces the share of people born abroad is highest.

<Grid cols=4>
    <KpiCard
        title="Half the population lives in"
        value={concentracion.slice(-1)[0]?.provincias_mitad}
        formattedValue="{concentracion.slice(-1)[0]?.provincias_mitad} provinces"
        period="out of 52, as at 1 January {concentracion.slice(-1)[0]?.anio} · {concentracion[0]?.provincias_mitad} in {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.provincias_mitad}))}
    />
    <KpiCard
        title="The 5 most populous provinces"
        value={concentracion.slice(-1)[0]?.pct_top5}
        formattedValue="{formatNumber(concentracion.slice(-1)[0]?.pct_top5, 1)}%"
        period="of the population · {formatNumber(concentracion[0]?.pct_top5, 1)}% in {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pct_top5}))}
    />
    <KpiCard
        title="Provinces losing population"
        value={concentracion.slice(-1)[0]?.pierden}
        formattedValue="{concentracion.slice(-1)[0]?.pierden} of 52"
        period="had fewer inhabitants on 1 January {concentracion.slice(-1)[0]?.anio} than a year earlier"
        direction="positive-down"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pierden}))}
    />
    <KpiCard
        title="Born abroad"
        value={origen.slice(-1)[0]?.pct_nacidos_extranjero}
        formattedValue="{formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)}%"
        period="of the population · {formatCompact(origen.slice(-1)[0]?.nacidos_extranjero, 2)} people in {origen.slice(-1)[0]?.anio}"
        source="INE"
        href="/en/sociedad/inmigracion"
        sparklineData={origen.map(d => ({anio: d.anio, valor: d.pct_nacidos_extranjero}))}
    />
</Grid>

<p class="text-xs text-gray-500">Population on 1 January according to the Continuous Population Statistics. Provinces are ranked from most to least populous to count how many are needed to add up to half of all inhabitants.</p>

## The weight of each region

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    e.poblacion / p.poblacion AS peso,
    e75.poblacion / p75.poblacion AS peso_1975,
    100.0 * (e.poblacion / p.poblacion - e75.poblacion / p75.poblacion) AS cambio_pp,
    100.0 * (e.poblacion / e75.poblacion - 1) AS crec_1975,
    e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento p ON p.nivel = 'pais' AND p.anio = e.anio
JOIN mother.demografia_envejecimiento e75 ON e75.nivel = 'ccaa' AND e75.cod = e.cod AND e75.anio = 1975
JOIN mother.demografia_envejecimiento p75 ON p75.nivel = 'pais' AND p75.anio = 1975
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY cambio_pp DESC
```

Since 1975, the region that has gained the most weight in Spain's population is {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.cambio_pp, 1)} points) and the one that has lost the most is {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.cambio_pp, 1)} points).

<BarChart
    data={ccaa}
    x=comunidad
    y=cambio_pp
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#059669"
    title="Change in each region's share of Spain's population since 1975 (percentage points)"
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=peso title="Current share" fmt=pct1 contentType=bar barColor="#a7f3d0" />
    <Column id=peso_1975 title="Share in 1975" fmt=pct1 />
    <Column id=cambio_pp title="Change (p.p.)" fmt=num2 contentType=delta />
    <Column id=crec_1975 title="Growth since 1975 (%)" fmt=num1 />
    <Column id=poblacion title="Population" fmt=num0 />
</DataTable>

## Provinces gaining and losing population

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta, e.poblacion,
    100.0 * (e.poblacion / e75.poblacion - 1) AS crec_1975,
    e.pct_nacidos_extranjero / 100 AS nacidos_extranjero,
    e.pct_extranjeros / 100 AS extranjeros
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e75 ON e75.nivel = 'provincia' AND e75.cod = e.cod AND e75.anio = 1975
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY crec_1975 DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE crec_1975 < 0) AS pierden_1975,
    arg_max(provincia, nacidos_extranjero) AS max_prov, max(nacidos_extranjero) AS max_pct,
    arg_min(provincia, nacidos_extranjero) AS min_prov, min(nacidos_extranjero) AS min_pct
FROM ${provincias}
```

{provincias_resumen[0]?.pierden_1975} provinces have fewer inhabitants today than in 1975. The one that has grown the most is {provincias[0]?.provincia} ({formatNumber(provincias[0]?.crec_1975, 0)}%) and the one that has lost the most is {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.crec_1975, 0)}%).

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="crec_1975"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#b91c1c', '#f8fafc', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="Population change since 1975 (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_1975', title: 'Change since 1975 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Population', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">The most recent trend (last 10 years) is in <a href="/en/demografia/evolucion-poblacion">Population trends</a>, and municipal detail is in the <a href="/en/territorios">regional profiles</a>.</p>

## Foreign-born residents by province

The share of residents born in another country ranges from {formatNumber(provincias_resumen[0]?.max_pct / 0.01, 1)}% in {provincias_resumen[0]?.max_prov} to {formatNumber(provincias_resumen[0]?.min_pct / 0.01, 1)}% in {provincias_resumen[0]?.min_prov}.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="nacidos_extranjero"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="Foreign-born population (% of population)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'nacidos_extranjero', title: 'Born abroad', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Foreign nationality', fmt: 'pct1'}
    ]}
/>

<p class="text-xs text-gray-500">Born abroad is not the same as foreign: it includes people who have acquired Spanish nationality and children of Spaniards born outside Spain. In Spain, {formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)}% of the population was born abroad and {formatNumber(origen.slice(-1)[0]?.pct_extranjeros, 1)}% has foreign nationality.</p>

---

## Sources and notes

- **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (table 56945): population on 1 January by province since 1971.
- **[INE – Population by place of birth](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (table 56948) and **[by nationality](https://www.ine.es/jaxiT3/Tabla.htm?t=56947)** (table 56947), by province, since 2002.

<LastRefreshed prefix="Data updated" />
