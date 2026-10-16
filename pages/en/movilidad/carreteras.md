---
title: Roads
description: "Map of every road in Spain by who runs it (the State, the regions, provincial councils, Canary island councils and Balearic island councils) and by type (toll motorways, free motorways, multi-lane and conventional roads), the cars and trucks that use each section of the State network every day, km per inhabitant and per square kilometre in each province since 1970, and the comparison with Europe."
i18n_origen: 2b3f03137772
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const TITULAR = {
        estado: 'The State',
        comunidad: 'Regional governments',
        diputacion: 'Provincial and island councils'
    };
    const TIPO = {
        peaje: 'Toll motorways',
        autovia: 'Free motorways and dual carriageways',
        multicarril: 'Multi-lane roads',
        convencional: 'Conventional roads'
    };
    const COLOR_TITULAR = { estado: '#dc2626', comunidad: '#2563eb', diputacion: '#a3a3a3' };
    const COLOR_TIPO = { peaje: '#7c3aed', autovia: '#f97316', multicarril: '#0f766e', convencional: '#a3a3a3' };
    // Grosor del trazo en el mapa de la red según el tipo de vía
    const GROSOR = { peaje: 4, autovia: 4, multicarril: 2.5, convencional: 1 };
    // Tramos de vehículos al día para el color del mapa de tráfico
    const TRAMOS = [[2000, 'Fewer than 2,000 vehicles a day', '#fde68a'], [10000, '2,000 to 10,000', '#fbbf24'], [30000, '10,000 to 30,000', '#f97316'], [70000, '30,000 to 70,000', '#dc2626'], [Infinity, 'More than 70,000', '#7e22ce']];
    const tramoDe = (n) => TRAMOS.find((t) => n < t[0]);
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
    const enRed = (filas, vista) => Array.from(filas ?? [])
        .map((d) => ({
            ...d,
            categoria: vista === 'tipo' ? TIPO[d.tipo] : TITULAR[d.titular],
            color: vista === 'tipo' ? COLOR_TIPO[d.tipo] : COLOR_TITULAR[d.titular],
            orden: vista === 'tipo' ? d.tipo_orden : d.titular_orden,
            grosor: GROSOR[d.tipo],
            titular_texto: TITULAR[d.titular],
            tipo_texto: TIPO[d.tipo]
        }))
        .toSorted((a, b) => a.orden - b.orden);
</script>

```sql provincias
SELECT * FROM mother.movilidad_carreteras_provincia
```

```sql espana
-- Totales de España del último año: suma de las provincias
SELECT
    max(anio) AS anio,
    sum(km_total) AS km_total,
    sum(km_estado) AS km_estado,
    sum(km_comunidad) AS km_comunidad,
    sum(km_diputacion) AS km_diputacion,
    sum(km_gran_capacidad) AS km_gran_capacidad,
    sum(km_peaje) AS km_peaje,
    sum(km_peaje_estado) AS km_peaje_estado,
    100000.0 * sum(km_total) / sum(poblacion) AS km_por_100k_hab,
    100000.0 * sum(km_gran_capacidad) / sum(poblacion) AS km_gran_capacidad_por_100k_hab,
    100.0 * sum(km_peaje) / sum(km_gran_capacidad) AS peaje_pct
FROM ${provincias}
```

```sql tramo_max
SELECT carretera, imd, anio FROM mother.movilidad_carreteras_trafico ORDER BY imd DESC LIMIT 1
```

# 🛣️ Roads

Spain's {formatNumber(espana[0]?.km_total, 0)} km of intercity roads, by who pays for and maintains them: the State, the regional governments or the provincial councils (including the Basque provincial councils, the Canary island councils (cabildos) and the Balearic island councils (consells)), and which ones are toll motorways, free motorways or ordinary roads. Plus how many vehicles use each section of the State network every day.

<Grid cols=4>
    <KpiCard
        title="Road network"
        value={espana[0]?.km_total}
        formattedValue="{formatNumber(espana[0]?.km_total, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 0)} km per 100,000 inhabitants in {espana[0]?.anio}"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="Motorways, dual carriageways and multi-lane roads"
        value={espana[0]?.km_gran_capacidad}
        formattedValue="{formatNumber(espana[0]?.km_gran_capacidad, 0)} km"
        period="{formatNumber(espana[0]?.km_gran_capacidad_por_100k_hab, 1)} km per 100,000 inhabitants"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="Toll roads"
        value={espana[0]?.km_peaje}
        formattedValue="{formatNumber(espana[0]?.km_peaje, 0)} km"
        period="{formatNumber(espana[0]?.peaje_pct, 0)} % of the high-capacity network; {formatNumber(espana[0]?.km_peaje_estado, 0)} km run by the State"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="The busiest section"
        value={tramo_max[0]?.imd}
        formattedValue={formatNumber(tramo_max[0]?.imd, 0)}
        unit=" vehicles a day"
        period="{tramo_max[0]?.carretera ?? ''} ({tramo_max[0]?.anio})"
        source="Ministerio de Transportes"
    />
</Grid>

## The map

<ButtonGroup name=vista title="Colour by">
    <ButtonGroupItem valueLabel="Who runs it" value="titular" default />
    <ButtonGroupItem valueLabel="Type of road" value="tipo" />
</ButtonGroup>

<ButtonGroup name=filtro title="Show">
    <ButtonGroupItem valueLabel="All" value="todas" />
    <ButtonGroupItem valueLabel="Only motorways, dual carriageways and multi-lane" value="gran_capacidad" default />
    <ButtonGroupItem valueLabel="Only toll roads" value="peaje" />
</ButtonGroup>

```sql red
SELECT titular, titular_orden, tipo, tipo_orden, carretera, provincia, longitud_km, trazado
FROM mother.movilidad_carreteras_red
WHERE '${inputs.filtro}' = 'todas'
    OR ('${inputs.filtro}' = 'gran_capacidad' AND tipo <> 'convencional')
    OR ('${inputs.filtro}' = 'peaje' AND tipo = 'peaje')
```

<MapaEspana
    data={enRed(red, String(inputs.vista?.value ?? inputs.vista))}
    geom=trazado
    value=categoria
    colorCol=color
    legendType=categorical
    width=grosor
    minWidth={0.6}
    maxWidth={2.6}
    opacity={0.85}
    pointName=carretera
    height={680}
    tooltip={[
        {id: 'carretera', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'titular_texto', title: 'Run by'},
        {id: 'tipo_texto', title: 'Type'},
        {id: 'provincia', title: 'Province'}
    ]}
/>

<p class="text-xs text-gray-500">State network: official catalogue of the Ministry of Transport (2025). Regional governments, provincial councils, Canary island councils and Balearic island councils: OpenStreetMap, with ownership inferred from each road's code (CL- for the Junta de Castilla y León, BV- for the Diputació de Barcelona, DP- for a Galician provincial council...) and tolls marked on the map; a few individual roads may be wrong. In the Basque Country all roads, including the A-8 and AP-8, belong to the provincial councils (diputaciones forales), and in Navarre to the regional government. Streets and the roads run by town councils are not included (about 360,000 km more, carrying 10 % of the traffic).</p>

```sql km_titular_tipo
SELECT k.titular, k.tipo, k.titular_orden, k.tipo_orden, k.km, k.anio
FROM mother.movilidad_carreteras_espana k
WHERE k.anio = (SELECT max(anio) FROM mother.movilidad_carreteras_espana)
ORDER BY k.titular_orden, k.tipo_orden
```

<BarChart
    data={etiquetar(etiquetar(km_titular_tipo, 'titular_texto', (d) => TITULAR[d.titular]), 'tipo_texto', (d) => TIPO[d.tipo])}
    x=titular_texto
    y=km
    series=tipo_texto
    type=stacked
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={[TIPO.peaje, TIPO.autovia, TIPO.multicarril, TIPO.convencional]}
    colorPalette={[COLOR_TIPO.peaje, COLOR_TIPO.autovia, COLOR_TIPO.multicarril, COLOR_TIPO.convencional]}
    title="Km of road by who runs it and type of road ({km_titular_tipo[0]?.anio})"
/>

<p class="text-xs text-gray-500">The State runs only {formatNumber(100 * espana[0]?.km_estado / espana[0]?.km_total, 0)} % of the km, but almost all the motorways and dual carriageways, which carry half of the traffic. The regional governments have {formatNumber(100 * espana[0]?.km_comunidad / espana[0]?.km_total, 0)} % and the provincial and island councils {formatNumber(100 * espana[0]?.km_diputacion / espana[0]?.km_total, 0)} %, almost all of it conventional roads.</p>

## The ones you pay for

```sql peajes
SELECT carretera, titular,
    string_agg(DISTINCT provincia, ', ' ORDER BY provincia) AS provincias,
    sum(longitud_km) AS km
FROM mother.movilidad_carreteras_red
WHERE tipo = 'peaje'
GROUP BY carretera, titular
HAVING sum(longitud_km) >= 1
ORDER BY km DESC
```

<DataTable data={etiquetar(peajes, 'titular_texto', (d) => TITULAR[d.titular])} rows=15 search=true>
    <Column id=carretera title="Road" />
    <Column id=titular_texto title="Run by" />
    <Column id=km title="Km of toll road" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=provincias title="Provinces" />
</DataTable>

<p class="text-xs text-gray-500">Km of toll road from the State catalogue and, for the rest, measured on OpenStreetMap (approximate: sometimes both carriageways or the junctions are counted). The State motorways whose concessions expired between 2018 and 2021 (AP-1, AP-4, the AP-7 from La Jonquera to Alicante and the AP-2) became free dual carriageways; the AP-6, AP-9, AP-68 and the Madrid radial motorways, among others, are still tolled. The Basque ones (AP-1, AP-8), the AP-15 in Navarre and the Generalitat ones (C-16, C-32) and the Xunta ones (AG-55, AG-57) charge tolls through their governments or concessionaires.</p>

```sql serie_tipo
SELECT anio, tipo, tipo_orden, sum(km) AS km
FROM mother.movilidad_carreteras_espana
WHERE tipo <> 'convencional'
GROUP BY anio, tipo, tipo_orden
ORDER BY anio, tipo_orden
```

<BarChart
    data={etiquetar(serie_tipo, 'tipo_texto', (d) => TIPO[d.tipo])}
    x=anio
    y=km
    series=tipo_texto
    type=stacked
    xFmt="0"
    yFmt=num0
    seriesOrder={[TIPO.peaje, TIPO.autovia, TIPO.multicarril]}
    colorPalette={[COLOR_TIPO.peaje, COLOR_TIPO.autovia, COLOR_TIPO.multicarril]}
    title="Km of motorways, dual carriageways and multi-lane roads since 1970"
/>

<p class="text-xs text-gray-500">The first motorways (1970s) were toll roads; since the 1980s almost everything built has been free dual carriageways. Toll roads fell from about 3,000 km in 2017 to under 2,000 when the concessions of the big State motorways ended. Until 1985 the series gives data every five years, and until 1990 it does not count the roads of the provincial councils.</p>

## How many vehicles use each section

<ButtonGroup name=vehiculos title="Vehicles">
    <ButtonGroupItem valueLabel="All" value="imd" default />
    <ButtonGroupItem valueLabel="Only heavy vehicles (trucks and buses)" value="imd_pesados" />
</ButtonGroup>

```sql trafico
SELECT carretera, pk_inicio, pk_fin, imd, imd_pesados, pesados_pct, anio, titular,
    ${inputs.vehiculos} AS vehiculos, trazado
FROM mother.movilidad_carreteras_trafico
WHERE ${inputs.vehiculos} > 0
ORDER BY vehiculos
```

<MapaEspana
    data={etiquetar(trafico, 'tramo', (d) => tramoDe(d.vehiculos)[1])}
    geom=trazado
    value=tramo
    legendType=categorical
    colorPalette={TRAMOS.filter((t) => trafico.some((d) => tramoDe(d.vehiculos) === t)).map((t) => t[2])}
    width=vehiculos
    widthFmt=num0
    minWidth={0.8}
    maxWidth={7}
    opacity={0.9}
    pointName=carretera
    height={680}
    tooltip={[
        {id: 'carretera', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'imd', title: 'Vehicles a day', fmt: 'num0'},
        {id: 'imd_pesados', title: 'Trucks and buses a day', fmt: 'num0'},
        {id: 'pesados_pct', title: '% heavy vehicles', fmt: 'num1'},
        {id: 'pk_inicio', title: 'From km', fmt: 'num1'},
        {id: 'pk_fin', title: 'To km', fmt: 'num1'},
        {id: 'anio', title: 'Year of the data', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Average daily traffic (IMD): vehicles using the road on an average day of the year, both directions added together, measured by the Ministry's counting stations on the State road network. Thicker line = more vehicles. The regional governments and provincial councils publish their own counts separately (or not at all), so their roads do not appear; according to the Ministry, the State network carries 53 % of all traffic and 66 % of truck traffic.</p>

```sql tramos_tabla
-- Tramos seguidos con la misma estación de aforo (misma IMD) en una sola fila
SELECT carretera, min(pk_inicio) AS pk_inicio, max(pk_fin) AS pk_fin, imd, max(imd_pesados) AS imd_pesados,
    max(pesados_pct) AS pesados_pct, anio
FROM mother.movilidad_carreteras_trafico
GROUP BY carretera, imd, anio
ORDER BY imd DESC
```

### The sections with the most traffic

<DataTable data={tramos_tabla} rows=15 search=true>
    <Column id=carretera title="Road" />
    <Column id=pk_inicio title="From km" fmt=num1 />
    <Column id=pk_fin title="To km" fmt=num1 />
    <Column id=imd title="Vehicles a day" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=imd_pesados title="Heavy vehicles a day" fmt=num0 />
    <Column id=pesados_pct title="% heavy" fmt=num1 />
    <Column id=anio title="Year" fmt="0" />
</DataTable>

## By province

<ButtonGroup name=medida title="Measure">
    <ButtonGroupItem valueLabel="Km per 100 km² of area" value="km_por_100_km2" default />
    <ButtonGroupItem valueLabel="Km per 100,000 inhabitants" value="km_por_100k_hab" />
    <ButtonGroupItem valueLabel="Motorways and dual carriageways per 100 km²" value="km_gran_capacidad_por_100_km2" />
    <ButtonGroupItem valueLabel="Motorways and dual carriageways per 100,000 inhabitants" value="km_gran_capacidad_por_100k_hab" />
</ButtonGroup>

```sql provincias_mapa
-- Sin Ceuta y Melilla: con 20 km² de superficie se salen de la escala
SELECT *, ${inputs.medida} AS medida FROM ${provincias} WHERE cod_prov NOT IN ('51', '52')
```

<MapaEspana
    data={provincias_mapa}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="medida"
    valueFmt="num1"
    colorPalette={['#fff7ed', '#fb923c', '#9a3412']}
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'km_total', title: 'Km of road', fmt: 'num0'},
        {id: 'km_por_100_km2', title: 'Per 100 km²', fmt: 'num1'},
        {id: 'km_por_100k_hab', title: 'Per 100,000 inhabitants', fmt: 'num0'},
        {id: 'km_gran_capacidad', title: 'Motorways, dual carriageways and multi-lane', fmt: 'num0'},
        {id: 'km_peaje', title: 'Toll roads', fmt: 'num0'}
    ]}
/>

```sql provincias_tabla
SELECT * FROM ${provincias} ORDER BY km_total DESC
```

<DataTable data={provincias_tabla} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=km_total title="Km" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=km_estado title="State" fmt=num0 />
    <Column id=km_comunidad title="Region" fmt=num0 />
    <Column id=km_diputacion title="Provincial council" fmt=num0 />
    <Column id=km_gran_capacidad title="High capacity" fmt=num0 />
    <Column id=km_peaje title="Toll" fmt=num0 />
    <Column id=km_por_100_km2 title="Per 100 km²" fmt=num1 />
    <Column id=km_por_100k_hab title="Per 100,000 inhabitants" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km from the Statistical Yearbook of the Ministry of Transport (regional governments and provincial councils report their data a year late). By area, the densest networks are in Galicia (Pontevedra, Lugo, A Coruña), with a very dense provincial-council network serving thousands of small villages, in Gipuzkoa, Bizkaia and Tenerife. Per inhabitant, the big empty provinces lead (Soria, Teruel, Cuenca, Zamora), where there are many roads for very few people.</p>

## How it has grown since 1970

```sql serie_titular
SELECT anio, titular, titular_orden, sum(km) AS km, sum(km_por_100k_hab) AS km_por_100k_hab
FROM mother.movilidad_carreteras_espana
GROUP BY anio, titular, titular_orden
ORDER BY anio, titular_orden
```

<BarChart
    data={etiquetar(serie_titular, 'titular_texto', (d) => TITULAR[d.titular])}
    x=anio
    y=km
    series=titular_texto
    type=stacked
    xFmt="0"
    yFmt=num0
    seriesOrder={[TITULAR.estado, TITULAR.comunidad, TITULAR.diputacion]}
    colorPalette={[COLOR_TITULAR.estado, COLOR_TITULAR.comunidad, COLOR_TITULAR.diputacion]}
    title="Km of road by who runs it"
/>

<p class="text-xs text-gray-500">In 1984 the State transferred a large part of its network to the regional governments, which is why it drops from about 80,000 km to 20,000. The provincial councils' roads are only counted from 1990. Since then the total has barely changed (about 165,000 km); what grows is the motorways.</p>

```sql serie_hab
SELECT anio, sum(km_por_100k_hab) FILTER (WHERE tipo <> 'convencional') AS km_por_100k_hab
FROM mother.movilidad_carreteras_espana
GROUP BY anio
HAVING sum(km_por_100k_hab) IS NOT NULL
ORDER BY anio
```

<LineChart
    data={serie_hab}
    x=anio
    y=km_por_100k_hab
    xFmt="0"
    yFmt=num1
    colorPalette={['#f97316']}
    title="Km of motorways, dual carriageways and multi-lane roads per 100,000 inhabitants"
/>

## Compared with Europe

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'autopistas_100k'
```

<Comparativa data={comparativa_internacional} decimales={1} />

```sql europa
SELECT cod_pais, pais,
    arg_max(km_autopistas, anio) AS km_autopistas,
    arg_max(km_por_100k_hab, anio) FILTER (WHERE km_por_100k_hab IS NOT NULL) AS km_por_100k_hab,
    arg_max(km_por_1000_km2, anio) AS km_por_1000_km2,
    max(anio) AS anio
FROM mother.movilidad_carreteras_europa
WHERE anio >= 2015
    AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'NL', 'BE', 'AT', 'SE', 'PL', 'CZ', 'CH', 'GB', 'DK', 'FI', 'NO', 'IE', 'GR', 'HU', 'RO', 'HR', 'SI', 'SK', 'LU')
GROUP BY cod_pais, pais
```

<BarChart
    data={europa.filter((d) => d.km_autopistas > 0).toSorted((a, b) => b.km_autopistas - a.km_autopistas)}
    x=pais
    y=km_autopistas
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#f97316"
    title="Km of motorways and dual carriageways (latest year published)"
/>

<BarChart
    data={europa.filter((d) => d.km_por_100k_hab > 0).toSorted((a, b) => b.km_por_100k_hab - a.km_por_100k_hab)}
    x=pais
    y=km_por_100k_hab
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c2410c"
    title="Km of motorways and dual carriageways per 100,000 inhabitants"
/>

<BarChart
    data={europa.filter((d) => d.km_por_1000_km2 > 0).toSorted((a, b) => b.km_por_1000_km2 - a.km_por_1000_km2)}
    x=pais
    y=km_por_1000_km2
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a3412"
    title="Km of motorways and dual carriageways per 1,000 km² of area"
/>

```sql europa_serie
SELECT anio, pais, km_autopistas
FROM mother.movilidad_carreteras_europa
WHERE cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'GB', 'PL') AND anio >= 1990
ORDER BY anio
```

<LineChart
    data={europa_serie}
    x=anio
    y=km_autopistas
    series=pais
    xFmt="0"
    yFmt=num0
    title="Km of motorways and dual carriageways since 1990"
/>

<p class="text-xs text-gray-500">Spain has the longest network of motorways and dual carriageways in the EU and one of the longest per inhabitant. By area it is about average: the country is large and sparsely populated inland. Eurostat counts dual carriageways as motorways too; the latest year published varies by country.</p>

---

## Sources and notes

- **Km by ownership and type of road: [Statistical Yearbook of the Ministry of Transport](https://otle.transportes.gob.es/datos-graficos-mapas/datos-anuales/capital-infraestructuras/infraestructura-basica/carretera/conjunto-redes-carreteras-estado-comunidades-autonomas-diputaciones-cabildos)**, via the Transport and Logistics Observatory (OTLE): by province since 2012 and for all of Spain since 1970. The provincial councils include the Basque ones (diputaciones forales), the Canary island councils (cabildos) and the Balearic island councils (consells).
- **State network: [Catalogue of the State Road Network](https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras)** (Ministry of Transport), with the type of each section and whether it is tolled.
- **Networks of the regional governments, provincial councils and island councils: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© OpenStreetMap contributors, ODbL licence), roads with a code downloaded through the Overpass API. Ownership is inferred from the road code; the official km are those of the Yearbook.
- **Traffic: IMD by section of the State network** from the Ministry of Transport's [Hermes](https://hermes.transportes.gob.es/) viewer (traffic map; latest year published for each road).
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: km of motorways by country (road_if_motorwa), population and area.

<LastRefreshed prefix="Data updated" />
