---
title: Reparto territorial de la población
description: "Cómo se reparte la población de España entre comunidades y provincias desde 1975: concentración, provincias que pierden habitantes y porcentaje de nacidos en el extranjero en cada provincia (INE)."
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🗺️ Reparto territorial de la población

Dónde vive la población de España, qué comunidades y provincias ganan y pierden peso y en qué provincias es mayor la proporción de personas nacidas en el extranjero.

<Grid cols=4>
    <KpiCard
        title="La mitad de la población vive en"
        value={concentracion.slice(-1)[0]?.provincias_mitad}
        formattedValue="{concentracion.slice(-1)[0]?.provincias_mitad} provincias"
        period="de 52, a 1 de enero de {concentracion.slice(-1)[0]?.anio} · {concentracion[0]?.provincias_mitad} en {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.provincias_mitad}))}
    />
    <KpiCard
        title="Las 5 provincias más pobladas"
        value={concentracion.slice(-1)[0]?.pct_top5}
        formattedValue="{formatNumber(concentracion.slice(-1)[0]?.pct_top5, 1)} %"
        period="de la población · {formatNumber(concentracion[0]?.pct_top5, 1)} % en {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pct_top5}))}
    />
    <KpiCard
        title="Provincias que pierden población"
        value={concentracion.slice(-1)[0]?.pierden}
        formattedValue="{concentracion.slice(-1)[0]?.pierden} de 52"
        period="tenían menos habitantes a 1 de enero de {concentracion.slice(-1)[0]?.anio} que un año antes"
        direction="positive-down"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pierden}))}
    />
    <KpiCard
        title="Nacidos en el extranjero"
        value={origen.slice(-1)[0]?.pct_nacidos_extranjero}
        formattedValue="{formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} %"
        period="de la población · {formatCompact(origen.slice(-1)[0]?.nacidos_extranjero, 2)} personas en {origen.slice(-1)[0]?.anio}"
        source="INE"
        href="/sociedad/inmigracion"
        sparklineData={origen.map(d => ({anio: d.anio, valor: d.pct_nacidos_extranjero}))}
    />
</Grid>

<p class="text-xs text-gray-500">Población a 1 de enero según la Estadística Continua de Población. Las provincias se ordenan de mayor a menor población para contar cuántas hacen falta para sumar la mitad de los habitantes.</p>

## El peso de cada comunidad

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, t.ruta,
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

Desde 1975, la comunidad que más peso ha ganado en la población española es {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.cambio_pp, 1)} puntos) y la que más ha perdido, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.cambio_pp, 1)} puntos).

<BarChart
    data={ccaa}
    x=comunidad
    y=cambio_pp
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#059669"
    title="Cambio del peso de cada comunidad en la población de España desde 1975 (puntos porcentuales)"
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=peso title="Peso actual" fmt=pct1 contentType=bar barColor="#a7f3d0" />
    <Column id=peso_1975 title="Peso en 1975" fmt=pct1 />
    <Column id=cambio_pp title="Cambio (p.p.)" fmt=num2 contentType=delta />
    <Column id=crec_1975 title="Crecimiento desde 1975 (%)" fmt=num1 />
    <Column id=poblacion title="Población" fmt=num0 />
</DataTable>

## Provincias que ganan y pierden población

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, t.ruta, e.poblacion,
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

{provincias_resumen[0]?.pierden_1975} provincias tienen hoy menos habitantes que en 1975. La que más ha crecido es {provincias[0]?.provincia} ({formatNumber(provincias[0]?.crec_1975, 0)} %) y la que más ha perdido, {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.crec_1975, 0)} %).

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Variación de la población desde 1975 (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_1975', title: 'Variación desde 1975 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Población', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">La evolución más reciente (últimos 10 años) está en <a href="/demografia/evolucion-poblacion">Evolución de la población</a>, y el detalle por municipio en las fichas de <a href="/territorios">territorios</a>.</p>

## Nacidos en el extranjero por provincia

La proporción de residentes nacidos en otro país va del {formatNumber(provincias_resumen[0]?.max_pct / 0.01, 1)} % de {provincias_resumen[0]?.max_prov} al {formatNumber(provincias_resumen[0]?.min_pct / 0.01, 1)} % de {provincias_resumen[0]?.min_prov}.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Población nacida en el extranjero (% de la población)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'nacidos_extranjero', title: 'Nacidos en el extranjero', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Con nacionalidad extranjera', fmt: 'pct1'}
    ]}
/>

<p class="text-xs text-gray-500">Nacido en el extranjero no equivale a extranjero: incluye a quienes han obtenido la nacionalidad española y a los hijos de españoles nacidos fuera. En España, {formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % de la población nació fuera y {formatNumber(origen.slice(-1)[0]?.pct_extranjeros, 1)} % tiene nacionalidad extranjera.</p>

---

## Fuentes y notas

- **[INE – Estadística Continua de Población](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (tabla 56945): población a 1 de enero por provincia desde 1971.
- **[INE – Población por lugar de nacimiento](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (tabla 56948) y **[por nacionalidad](https://www.ine.es/jaxiT3/Tabla.htm?t=56947)** (tabla 56947), por provincia, desde 2002.

<LastRefreshed prefix="Datos actualizados" />
