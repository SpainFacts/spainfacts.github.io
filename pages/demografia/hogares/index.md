---
title: Hogares
description: "Tamaño medio del hogar y porcentaje de hogares de una sola persona en España, por comunidad y provincia, desde 2021 (INE, Estadística Continua de Población)."
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT CAST(h.anio AS INTEGER) AS anio, h.hogares, h.tamano_medio, h.unipersonales, h.pct_unipersonales,
    h.pct_2, h.pct_3, h.pct_4_o_mas
FROM mother.demografia_hogares h
WHERE h.nivel = 'pais'
ORDER BY anio
```

# 🏠 Hogares

Cuántas personas viven de media en cada hogar y cuántos hogares están formados por una sola persona. Los datos son de la Estadística Continua de Población del INE, que los publica desde 2021.

<Grid cols=4>
    <KpiCard
        title="Personas por hogar"
        value={espana.slice(-1)[0]?.tamano_medio}
        formattedValue={formatNumber(espana.slice(-1)[0]?.tamano_medio, 2)}
        period="tamaño medio, 1 de enero de {espana.slice(-1)[0]?.anio} · {formatNumber(espana[0]?.tamano_medio, 2)} en {espana[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.tamano_medio}))}
    />
    <KpiCard
        title="Hogares de una persona"
        value={espana.slice(-1)[0]?.pct_unipersonales}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_unipersonales, 1)} %"
        period="de los hogares · {formatCompact(espana.slice(-1)[0]?.unipersonales, 2)} hogares"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_unipersonales}))}
    />
    <KpiCard
        title="Hogares de dos personas"
        value={espana.slice(-1)[0]?.pct_2}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_2, 1)} %"
        period="de los hogares, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_2}))}
    />
    <KpiCard
        title="Hogares de 4 o más personas"
        value={espana.slice(-1)[0]?.pct_4_o_mas}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_4_o_mas, 1)} %"
        period="de los hogares · {formatCompact(espana.slice(-1)[0]?.hogares, 3)} hogares en total"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_4_o_mas}))}
    />
</Grid>

<p class="text-xs text-gray-500">Hogares de personas que residen en viviendas familiares (no incluye residencias, cuarteles, conventos y otros establecimientos colectivos).</p>

## Hogares según el número de personas

```sql tamanos
SELECT anio, '1 persona' AS tamano, pct_unipersonales / 100 AS cuota FROM ${espana}
UNION ALL SELECT anio, '2 personas', pct_2 / 100 FROM ${espana}
UNION ALL SELECT anio, '3 personas', pct_3 / 100 FROM ${espana}
UNION ALL SELECT anio, '4 o más', pct_4_o_mas / 100 FROM ${espana}
ORDER BY anio
```

<BarChart
    data={tamanos}
    x=anio
    y=cuota
    series=tamano
    type=stacked
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#f59e0b', '#fcd34d', '#fef3c7']}
    title="Hogares por número de personas (% del total, a 1 de enero)"
/>

## Por comunidad autónoma

```sql ccaa
SELECT h.cod, t.nombre AS comunidad, t.ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales,
    h.pct_4_o_mas / 100 AS cuatro_o_mas, h.hogares
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod
WHERE h.nivel = 'ccaa' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.tamano_medio DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=tamano_medio title="Personas por hogar" fmt=num2 contentType=bar barColor="#fde68a" />
    <Column id=unipersonales title="Hogares de 1 persona" fmt=pct1 />
    <Column id=cuatro_o_mas title="Hogares de 4 o más" fmt=pct1 />
    <Column id=hogares title="Hogares" fmt=num0 />
</DataTable>

## Por provincia

```sql provincias
SELECT h.cod AS cod_prov, t.nombre AS provincia, t.ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = h.cod
WHERE h.nivel = 'provincia' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.pct_unipersonales DESC
```

Los hogares de una sola persona van del {formatNumber(provincias[0]?.unipersonales / 0.01, 1)} % de {provincias[0]?.provincia} al {formatNumber(provincias.slice(-1)[0]?.unipersonales / 0.01, 1)} % de {provincias.slice(-1)[0]?.provincia}.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="unipersonales"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fffbeb', '#f59e0b', '#78350f']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Hogares de una sola persona (% de los hogares)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'unipersonales', title: 'Hogares de 1 persona', fmt: 'pct1'},
        {id: 'tamano_medio', title: 'Personas por hogar', fmt: 'num2'}
    ]}
/>

---

## Fuentes y notas

- **[INE – Estadística Continua de Población: hogares](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)**: hogares por número de miembros por comunidad ([60131](https://www.ine.es/jaxiT3/Tabla.htm?t=60131)) y provincia ([60133](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)) y tamaño medio del hogar ([60132](https://www.ine.es/jaxiT3/Tabla.htm?t=60132) y [60134](https://www.ine.es/jaxiT3/Tabla.htm?t=60134)). Datos provisionales a 1 de enero; el INE los publica cada trimestre desde 2021. La antigua Encuesta Continua de Hogares (2013-2020) no se incluye porque su método es distinto.

<LastRefreshed prefix="Datos actualizados" />
