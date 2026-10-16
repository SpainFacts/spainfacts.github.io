---
title: Railway network
description: "Map of Spain's entire railway network (high speed, Iberian gauge electrified or not, and narrow gauge) and of how many passenger trains run each day on every section and through every station, with km of network per inhabitant in each province and the comparison with Europe."
i18n_origen: 8013be110436
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const TIPO = {
        alta_velocidad: 'High speed',
        estandar: 'Conventional standard gauge',
        iberica_electrificada: 'Electrified Iberian gauge',
        iberica_sin_electrificar: 'Non-electrified Iberian gauge',
        metrica: 'Narrow gauge (metre gauge)'
    };
    const COLOR_TIPO = ['#dc2626', '#f97316', '#0f766e', '#a3a3a3', '#7c3aed'];
    const CLASE = {
        trenes_dia: 'All passenger trains',
        trenes_cercanias: 'Cercanías and Rodalies commuter trains',
        trenes_media_distancia: 'Medium-distance and regional',
        trenes_larga_distancia: 'High speed and long distance',
        trenes_autonomico: 'FGC, Euskotren and FGV'
    };
    // Tramos de trenes al día para el color del mapa de tráfico
    const TRAMOS = [[10, '1 to 10 trains a day', '#fde68a'], [50, '11 to 50', '#fbbf24'], [100, '51 to 100', '#f97316'], [250, '101 to 250', '#dc2626'], [Infinity, 'More than 250', '#7e22ce']];
    const tramoDe = (n) => TRAMOS.find((t) => n <= t[0]);
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
</script>

```sql red_tipos
SELECT tipo, tipo_orden, sum(longitud_km) AS km
FROM mother.movilidad_ferrocarril_red
GROUP BY tipo, tipo_orden
ORDER BY tipo_orden
```

```sql europa_ultimo
-- Último año con dato de cada indicador y país
SELECT
    cod_pais,
    pais,
    arg_max(km_lineas, anio) FILTER (WHERE km_lineas IS NOT NULL) AS km_lineas,
    max(anio) FILTER (WHERE km_lineas IS NOT NULL) AS anio_km,
    arg_max(km_por_100k_hab, anio) FILTER (WHERE km_por_100k_hab IS NOT NULL) AS km_por_100k_hab,
    arg_max(km_alta_velocidad_dedicada, anio) FILTER (WHERE km_alta_velocidad_dedicada > 0) AS km_alta_velocidad,
    max(anio) FILTER (WHERE km_alta_velocidad_dedicada > 0) AS anio_av,
    arg_max(viajeros_km_hab, anio) FILTER (WHERE viajeros_km_hab IS NOT NULL) AS viajeros_km_hab,
    max(anio) FILTER (WHERE viajeros_km_hab IS NOT NULL) AS anio_viajeros,
    arg_max(toneladas_km_hab, anio) FILTER (WHERE toneladas_km_hab IS NOT NULL) AS toneladas_km_hab,
    arg_max(electrificadas_pct, anio) FILTER (WHERE electrificadas_pct IS NOT NULL) AS electrificadas_pct
FROM mother.movilidad_ferrocarril_europa
WHERE anio >= 2015
GROUP BY cod_pais, pais
```

```sql espana
SELECT * FROM ${europa_ultimo} WHERE cod_pais = 'ES'
```

```sql tramo_max
SELECT trenes_dia, nombre, strftime(fecha_horarios, '%d/%m/%Y') AS fecha
FROM mother.movilidad_ferrocarril_trafico
ORDER BY trenes_dia DESC
LIMIT 1
```

```sql estacion_max
SELECT nombre, trenes_dia FROM mother.movilidad_ferrocarril_estaciones ORDER BY trenes_dia DESC LIMIT 1
```

# 🚆 Railway network

Every railway line in Spain and how many passenger trains run on it each day. Adif, which manages the state network, does not publish the traffic on each section, so here it is calculated from the timetables of Renfe, FGC, Euskotren and FGV for a working day: each train is drawn on the tracks it uses to go from one stop to the next.

<Grid cols=4>
    <KpiCard
        title="Railway lines"
        value={espana[0]?.km_lineas}
        formattedValue="{formatNumber(espana[0]?.km_lineas, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 1)} km per 100,000 people in {espana[0]?.anio_km}"
        source="Eurostat"
    />
    <KpiCard
        title="High speed"
        value={espana[0]?.km_alta_velocidad}
        formattedValue="{formatNumber(espana[0]?.km_alta_velocidad, 0)} km"
        period="lines built for high speed in {espana[0]?.anio_av}: the largest network in the EU"
        source="Eurostat"
    />
    <KpiCard
        title="The busiest section"
        value={tramo_max[0]?.trenes_dia}
        formattedValue={formatNumber(tramo_max[0]?.trenes_dia, 0)}
        unit=" trains a day"
        period="{tramo_max[0]?.nombre ?? ''} ({tramo_max[0]?.fecha})"
        source="Renfe, FGC, Euskotren and FGV"
    />
    <KpiCard
        title="The busiest station"
        value={estacion_max[0]?.trenes_dia}
        formattedValue={formatNumber(estacion_max[0]?.trenes_dia, 0)}
        unit=" trains a day"
        period={estacion_max[0]?.nombre}
        source="Renfe, FGC, Euskotren and FGV"
    />
</Grid>

## The network

```sql red
SELECT tipo, tipo_orden, linea_adif, coalesce(nombre, linea_adif, operador) AS nombre, operador, velocidad_maxima, longitud_km, trazado
FROM mother.movilidad_ferrocarril_red
ORDER BY tipo_orden DESC, longitud_km
```

<MapaEspana
    data={etiquetar(red, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo).toSorted((a, b) => a.tipo_orden - b.tipo_orden)}
    geom=trazado
    value=tipo_texto
    legendType=categorical
    colorPalette={COLOR_TIPO.filter((c, i) => red.some((d) => d.tipo_orden === i + 1))}
    opacity={0.9}
    pointName=nombre
    height={640}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tipo_texto', title: 'Type'},
        {id: 'linea_adif', title: 'Adif line'},
        {id: 'operador', title: 'Manager'},
        {id: 'velocidad_maxima', title: 'Maximum speed (km/h)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Routes from OpenStreetMap. High speed: standard gauge (1,435 mm) for 200 km/h or more. Iberian gauge (1,668 mm) is that of the conventional network; narrow gauge (1,000 mm) is that of the former FEVE along the Cantabrian coast and of FGC, Euskotren, FGV or the Sóller train. Sidings, yards and branches to industries or ports are excluded.</p>

<BarChart
    data={etiquetar(red_tipos, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    x=tipo_texto
    y=km
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km of corridor by type of track"
/>

<p class="text-xs text-gray-500">Km of corridor measured on the map: a double-track line counts once. The total ({formatNumber(red_tipos.reduce((s, d) => s + d.km, 0), 0)} km) is somewhat higher than Eurostat's ({formatNumber(espana[0]?.km_lineas, 0)} km) because it includes the regional networks and the track bundles of the large stations.</p>

## How many trains run on each section

<ButtonGroup name=clase title="Trains">
    <ButtonGroupItem valueLabel="All" value="trenes_dia" default />
    <ButtonGroupItem valueLabel="Commuter" value="trenes_cercanias" />
    <ButtonGroupItem valueLabel="Medium distance" value="trenes_media_distancia" />
    <ButtonGroupItem valueLabel="High speed and long distance" value="trenes_larga_distancia" />
    <ButtonGroupItem valueLabel="FGC, Euskotren and FGV" value="trenes_autonomico" />
</ButtonGroup>

```sql trafico
SELECT nombre, linea_adif, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico,
    ${inputs.clase} AS trenes, trazado, strftime(fecha_horarios, '%d/%m/%Y') AS fecha
FROM mother.movilidad_ferrocarril_trafico
WHERE ${inputs.clase} > 0
ORDER BY trenes
```

<MapaEspana
    data={etiquetar(trafico, 'tramo', (d) => tramoDe(d.trenes)[1])}
    geom=trazado
    value=tramo
    legendType=categorical
    colorPalette={TRAMOS.filter((t) => trafico.some((d) => tramoDe(d.trenes) === t)).map((t) => t[2])}
    width=trenes
    widthFmt=num0
    minWidth={1}
    maxWidth={7}
    opacity={0.9}
    pointName=nombre
    height={640}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'trenes_dia', title: 'Trains a day', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Commuter', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Medium distance', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'High speed and long distance', fmt: 'num0'},
        {id: 'trenes_autonomico', title: 'FGC, Euskotren and FGV', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Passenger trains scheduled on {trafico[0]?.fecha} (a Wednesday), adding up both directions. Thicker = more trains. Iryo and Ouigo trains are missing, as they do not publish their timetables openly, and so are all freight trains, so the high-speed corridors (Madrid-Barcelona, Madrid-Valencia, Madrid-Seville) and the freight lines carry more traffic than shown. FGV's underground metro sections and some of FGC and Euskotren do not appear.</p>

```sql pares
SELECT estacion_a || ' – ' || estacion_b AS tramo, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico, operadores
FROM mother.movilidad_ferrocarril_pares
ORDER BY trenes_dia DESC
```

### Which stations have the most trains between them

<DataTable data={pares} rows=15 search=true>
    <Column id=tramo title="Between" />
    <Column id=trenes_dia title="Trains a day" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Commuter" fmt=num0 />
    <Column id=trenes_media_distancia title="Medium distance" fmt=num0 />
    <Column id=trenes_larga_distancia title="Long distance" fmt=num0 />
    <Column id=trenes_autonomico title="Regional networks" fmt=num0 />
    <Column id=operadores title="Operators" />
</DataTable>

<p class="text-xs text-gray-500">Trains between two consecutive stops, in both directions. A non-stop train counts between its two stops even if it passes other stations without stopping.</p>

## Stations

```sql estaciones
SELECT nombre, operador, latitud, longitud, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico
FROM mother.movilidad_ferrocarril_estaciones
ORDER BY trenes_dia
```

<MapaEspana
    data={estaciones}
    lat=latitud
    long=longitud
    size=trenes_dia
    sizeFmt=num0
    maxSize={18}
    value=trenes_dia
    valueFmt=num0
    colorPalette={['#5eead4', '#0f766e', '#134e4a']}
    opacity={0.7}
    pointName=nombre
    height={600}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'operador', title: 'Operator'},
        {id: 'trenes_dia', title: 'Trains stopping per day', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Commuter', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Medium distance', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'High speed and long distance', fmt: 'num0'}
    ]}
/>

```sql estaciones_tabla
SELECT * FROM ${estaciones} ORDER BY trenes_dia DESC
```

<DataTable data={estaciones_tabla} rows=10 search=true>
    <Column id=nombre title="Station" />
    <Column id=operador title="Operator" />
    <Column id=trenes_dia title="Trains a day" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Commuter" fmt=num0 />
    <Column id=trenes_media_distancia title="Medium distance" fmt=num0 />
    <Column id=trenes_larga_distancia title="Long distance" fmt=num0 />
    <Column id=trenes_autonomico title="Regional networks" fmt=num0 />
</DataTable>

## By province

```sql provincias
SELECT * FROM mother.movilidad_ferrocarril_provincia ORDER BY km_por_100k_hab DESC
```

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="km_por_100k_hab"
    valueFmt="num0"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'km_por_100k_hab', title: 'Km of track per 100,000 people', fmt: 'num0'},
        {id: 'km_red', title: 'Km of network', fmt: 'num0'},
        {id: 'km_alta_velocidad', title: 'High speed', fmt: 'num0'},
        {id: 'sin_electrificar_pct', title: '% of non-electrified Iberian gauge', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=km_red title="Km of network" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=km_por_100k_hab title="Per 100,000 people" fmt=num0 />
    <Column id=km_alta_velocidad title="High speed" fmt=num0 />
    <Column id=km_iberica_electrificada title="Electrified Iberian" fmt=num0 />
    <Column id=km_iberica_sin_electrificar title="Non-electrified Iberian" fmt=num0 />
    <Column id=km_metrica title="Narrow gauge" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km of corridor running through each province, measured on the OpenStreetMap map. Large, sparsely populated provinces crossed by several lines (Palencia, Zamora, Soria) have more track per inhabitant.</p>

## Compared with Europe

```sql europa
SELECT * FROM ${europa_ultimo}
WHERE cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'NL', 'BE', 'AT', 'SE', 'PL', 'CZ', 'CH', 'GB', 'DK', 'FI', 'NO', 'IE', 'GR', 'HU', 'RO')
```

<BarChart
    data={europa.filter((d) => d.km_alta_velocidad > 0).toSorted((a, b) => b.km_alta_velocidad - a.km_alta_velocidad)}
    x=pais
    y=km_alta_velocidad
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#dc2626"
    title="Km of lines built for high speed (latest year published)"
/>

<BarChart
    data={europa.filter((d) => d.viajeros_km_hab > 0).toSorted((a, b) => b.viajeros_km_hab - a.viajeros_km_hab)}
    x=pais
    y=viajeros_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km travelled by train per inhabitant per year"
/>

<BarChart
    data={europa.filter((d) => d.toneladas_km_hab > 0).toSorted((a, b) => b.toneladas_km_hab - a.toneladas_km_hab)}
    x=pais
    y=toneladas_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Rail freight: tonne-km per inhabitant per year"
/>

<p class="text-xs text-gray-500">Spain has the longest high-speed network in the EU, but its inhabitants travel fewer km by train than those of France, Germany or Austria, and far less freight runs on its tracks: freight transport in Spain goes almost entirely by road. Eurostat data, latest year published for each country.</p>

---

## Sources and notes

- **Network: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© OpenStreetMap contributors, ODbL licence), railway and narrow-gauge tracks downloaded with the Overpass API. The two tracks of a double-track line are merged into one (a grid of about 100 m) to measure km of corridor and avoid splitting trains between them.
- **Trains: open timetables (GTFS) from [Renfe](https://data.renfe.com/)** (high speed, long and medium distance, and Cercanías and Rodalies; CC BY 4.0), **[FGC](https://www.fgc.cat/)**, **Euskotren** and **FGV** (these three via [Mobility Database](https://mobilitydatabase.org/)). Trains on a working Wednesday are counted and each pair of stops is routed along the shortest path on the network, respecting each service's track gauge. There is no open data for Iryo, Ouigo or freight trains, nor for passengers per section.
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: length of lines (rail_if_line_sp, rail_if_line_ga), passenger-km (rail_pa_total) and tonne-km (rail_go_total); per inhabitant with Eurostat population.

<LastRefreshed prefix="Data updated" />
