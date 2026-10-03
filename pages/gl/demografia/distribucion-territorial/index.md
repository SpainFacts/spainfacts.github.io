---
title: Repartición territorial da poboación
description: "Como se reparte a poboación de España entre comunidades e provincias desde 1975: concentración, provincias que perden habitantes e porcentaxe de nados no estranxeiro en cada provincia (INE)."
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

# 🗺️ Repartición territorial da poboación

Onde vive a poboación de España, que comunidades e provincias gañan e perden peso e en que provincias é maior a proporción de persoas nadas no estranxeiro.

<Grid cols=4>
    <KpiCard
        title="A metade da poboación vive en"
        value={concentracion.slice(-1)[0]?.provincias_mitad}
        formattedValue="{concentracion.slice(-1)[0]?.provincias_mitad} provincias"
        period="de 52, a 1 de xaneiro de {concentracion.slice(-1)[0]?.anio} · {concentracion[0]?.provincias_mitad} en {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.provincias_mitad}))}
    />
    <KpiCard
        title="As 5 provincias máis poboadas"
        value={concentracion.slice(-1)[0]?.pct_top5}
        formattedValue="{formatNumber(concentracion.slice(-1)[0]?.pct_top5, 1)} %"
        period="da poboación · {formatNumber(concentracion[0]?.pct_top5, 1)} % en {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pct_top5}))}
    />
    <KpiCard
        title="Provincias que perden poboación"
        value={concentracion.slice(-1)[0]?.pierden}
        formattedValue="{concentracion.slice(-1)[0]?.pierden} de 52"
        period="tiñan menos habitantes a 1 de xaneiro de {concentracion.slice(-1)[0]?.anio} ca un ano antes"
        direction="positive-down"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pierden}))}
    />
    <KpiCard
        title="Nados no estranxeiro"
        value={origen.slice(-1)[0]?.pct_nacidos_extranjero}
        formattedValue="{formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} %"
        period="da poboación · {formatCompact(origen.slice(-1)[0]?.nacidos_extranjero, 2)} persoas en {origen.slice(-1)[0]?.anio}"
        source="INE"
        href="/gl/sociedad/inmigracion"
        sparklineData={origen.map(d => ({anio: d.anio, valor: d.pct_nacidos_extranjero}))}
    />
</Grid>

<p class="text-xs text-gray-500">Poboación a 1 de xaneiro segundo a Estatística Continua de Poboación. As provincias ordénanse de maior a menor poboación para contar cantas fan falta para sumar a metade dos habitantes.</p>

## O peso de cada comunidade

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta,
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

Desde 1975, a comunidade que máis peso gañou na poboación española é {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.cambio_pp, 1)} puntos) e a que máis perdeu, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.cambio_pp, 1)} puntos).

<BarChart
    data={ccaa}
    x=comunidad
    y=cambio_pp
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#059669"
    title="Cambio do peso de cada comunidade na poboación de España desde 1975 (puntos porcentuais)"
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=peso title="Peso actual" fmt=pct1 contentType=bar barColor="#a7f3d0" />
    <Column id=peso_1975 title="Peso en 1975" fmt=pct1 />
    <Column id=cambio_pp title="Cambio (p.p.)" fmt=num2 contentType=delta />
    <Column id=crec_1975 title="Crecemento desde 1975 (%)" fmt=num1 />
    <Column id=poblacion title="Poboación" fmt=num0 />
</DataTable>

## Provincias que gañan e perden poboación

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta, e.poblacion,
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

Hoxe hai {provincias_resumen[0]?.pierden_1975} provincias con menos habitantes ca en 1975. A que máis medrou é {provincias[0]?.provincia} ({formatNumber(provincias[0]?.crec_1975, 0)} %) e a que máis perdeu, {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.crec_1975, 0)} %).

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Variación da poboación desde 1975 (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_1975', title: 'Variación desde 1975 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Poboación', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">A evolución máis recente (últimos 10 anos) está en <a href="/gl/demografia/evolucion-poblacion">Evolución da poboación</a>, e o detalle por municipio nas fichas de <a href="/gl/territorios">territorios</a>.</p>

## Nados no estranxeiro por provincia

A proporción de residentes nados noutro país vai do {formatNumber(provincias_resumen[0]?.max_pct / 0.01, 1)} % de {provincias_resumen[0]?.max_prov} ao {formatNumber(provincias_resumen[0]?.min_pct / 0.01, 1)} % de {provincias_resumen[0]?.min_prov}.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Poboación nada no estranxeiro (% da poboación)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'nacidos_extranjero', title: 'Nados no estranxeiro', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Con nacionalidade estranxeira', fmt: 'pct1'}
    ]}
/>

<p class="text-xs text-gray-500">Nado no estranxeiro non equivale a estranxeiro: inclúe quen obtivo a nacionalidade española e os fillos de españois nados fóra. En España, o {formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % da poboación naceu fóra e o {formatNumber(origen.slice(-1)[0]?.pct_extranjeros, 1)} % ten nacionalidade estranxeira.</p>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (táboa 56945): poboación a 1 de xaneiro por provincia desde 1971.
- **[INE – Poboación por lugar de nacemento](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (táboa 56948) e **[por nacionalidade](https://www.ine.es/jaxiT3/Tabla.htm?t=56947)** (táboa 56947), por provincia, desde 2002.

<LastRefreshed prefix="Datos actualizados" />
