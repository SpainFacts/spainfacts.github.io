---
title: Charging points
description: "Map of public charging points for electric cars in Spain by power and operator, and how many plug-in cars there are per point in each province."
i18n_origen: e8e801641524
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql totales
SELECT
    sum(puntos) AS puntos,
    sum(sitios) AS sitios,
    sum(puntos_rapidos) AS puntos_rapidos,
    sum(puntos_ultrarrapidos) AS puntos_ultrarrapidos,
    sum(turismos_enchufables) AS enchufables,
    sum(turismos_enchufables) / sum(puntos) AS enchufables_por_punto,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion
FROM mother.movilidad_recarga_provincia
```

```sql tramos
SELECT tramo, tramo_orden, count(*) AS sitios, sum(puntos) AS puntos
FROM mother.movilidad_recarga_sitios
GROUP BY ALL
ORDER BY tramo_orden
```

# 🔌 Public charging points

Where you can charge an electric car in Spain, according to the official register of publicly accessible charging points that the Ministry for the Ecological Transition publishes every day on the DGT's National Access Point.

<Grid cols=3>
    <KpiCard
        title="Public charging points"
        value={totales[0]?.puntos}
        formattedValue="{formatNumber(100000 * totales[0]?.puntos / totales[0]?.poblacion, 0)} per 100,000 people"
        period="{formatNumber(totales[0]?.puntos, 0)} points at {formatNumber(totales[0]?.sitios, 0)} sites"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Fast (50 kW or more)"
        value={totales[0]?.puntos_rapidos}
        formattedValue="{formatNumber(totales[0]?.puntos_rapidos / totales[0]?.puntos / 0.01, 1)}% of points"
        period="{formatNumber(totales[0]?.puntos_rapidos, 0)} fast points, {formatNumber(totales[0]?.puntos_ultrarrapidos, 0)} of them 150 kW or more"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Plug-in cars per point"
        value={totales[0]?.enchufables_por_punto}
        formattedValue={formatNumber(totales[0]?.enchufables_por_punto, 1)}
        period="{formatNumber(totales[0]?.enchufables, 0)} battery electric and plug-in hybrid cars"
        source="DGT"
    />
</Grid>

## Map

<ButtonGroup name=tramo title="Power">
    <ButtonGroupItem valueLabel="All" value="todos" default />
    <ButtonGroupItem valueLabel="Ultra-fast (≥150 kW)" value="Ultrarrápida (≥150 kW)" />
    <ButtonGroupItem valueLabel="Fast (50-149 kW)" value="Rápida (50-149 kW)" />
    <ButtonGroupItem valueLabel="Semi-fast (22-49 kW)" value="Semirrápida (22-49 kW)" />
    <ButtonGroupItem valueLabel="Slow (<22 kW)" value="Lenta (<22 kW)" />
</ButtonGroup>

```sql mapa
-- Primero un emplazamiento de cada tramo (en orden) para fijar los colores de
-- la leyenda; luego el resto, de menos a más potencia para que los rápidos queden encima.
SELECT *
FROM (
    SELECT sitio_id, sitio, operador, latitud, longitud, puntos, potencia_max_kw, tramo, tramo_orden,
        row_number() OVER (PARTITION BY tramo ORDER BY potencia_max_kw DESC, sitio_id) = 1 AS primera
    FROM mother.movilidad_recarga_sitios
    WHERE '${inputs.tramo}' = 'todos' OR tramo = '${inputs.tramo}'
)
ORDER BY primera DESC, CASE WHEN primera THEN tramo_orden END, potencia_max_kw
```

```sql colores
SELECT DISTINCT tramo, tramo_orden,
    CASE tramo_orden WHEN 1 THEN '#7c3aed' WHEN 2 THEN '#0f766e' WHEN 3 THEN '#14b8a6' ELSE '#a3e635' END AS color
FROM ${mapa}
ORDER BY tramo_orden
```

<MapaEspana
    data={mapa}
    lat=latitud
    long=longitud
    size=puntos
    sizeFmt=num0
    maxSize={14}
    value=tramo
    legendType=categorical
    colorPalette={colores?.length ? colores.map(d => d.color) : ['#7c3aed', '#0f766e', '#14b8a6', '#a3e635']}
    opacity={0.7}
    pointName=sitio
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Charging points: MITECO via NAP (DGT)"
    tooltip={[
        {id: 'sitio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'operador', title: 'Operator'},
        {id: 'puntos', title: 'Points', fmt: 'num0'},
        {id: 'potencia_max_kw', title: 'Maximum power (kW)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Each circle is a site (a charging station, a car park...) and its size is the number of points. Colour reflects the most powerful point at the site. The Canary Islands appear to the south-west: zoom out the map.</p>

<BarChart
    data={tramos}
    x=tramo
    y=puntos
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Charging points by power"
/>

## By province

```sql provincias
SELECT * FROM mother.movilidad_recarga_provincia ORDER BY puntos DESC
```

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="enchufables_por_punto"
    valueFmt="num1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: DGT and MITECO"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'enchufables_por_punto', title: 'Plug-ins per point', fmt: 'num1'},
        {id: 'puntos', title: 'Points', fmt: 'num0'},
        {id: 'puntos_por_100k_hab', title: 'Points per 100,000 people', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Darker = more plug-in cars per public point, i.e. more pressure on the charging network.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=puntos title="Points" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=puntos_rapidos title="Fast (≥50 kW)" fmt=num0 />
    <Column id=puntos_por_100k_hab title="Per 100,000 people" fmt=num0 />
    <Column id=turismos_enchufables title="Plug-in cars" fmt=num0 />
    <Column id=enchufables_por_punto title="Plug-ins per point" fmt=num1 />
</DataTable>

```sql operadores
SELECT operador, sum(puntos) AS puntos, count(*) AS sitios, sum(puntos) FILTER (WHERE potencia_max_kw >= 50) AS puntos_en_sitios_rapidos
FROM mother.movilidad_recarga_sitios
GROUP BY operador
ORDER BY puntos DESC
```

## Operators

<DataTable data={operadores} rows=15 search=true>
    <Column id=operador title="Operator" />
    <Column id=puntos title="Points" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=sitios title="Sites" fmt=num0 />
</DataTable>

---

## Sources and notes

- **[National Access Point for traffic and mobility (DGT) – Electric charging points](https://nap.dgt.es/dataset/puntos-de-recarga-electrica-para-vehiculos)**, data from the Ministry for the Ecological Transition based on what operators declare (Royal Decree 184/2022). Updated daily.
- Declaring points is only mandatory for those of 43 kW or more; slow points (hotels, shopping centres, garages) are declared voluntarily, so their number is a **minimum**. Private points in homes or businesses are not included.
- Municipality and province are assigned from the coordinates of each site. The power of a point = that of its most powerful connector.
- Plug-in cars: DGT fleet (battery electric and plug-in hybrids) for the latest month published, by province of the owner's address.

<LastRefreshed prefix="Data updated" />
