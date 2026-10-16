---
title: Red de ferrocarril
description: "Mapa de toda la red ferroviaria de España (alta velocidad, ancho ibérico electrificado o no y vía estrecha) y de cuántos trenes de viajeros pasan al día por cada tramo y estación, con los km de red por habitante de cada provincia y la comparación con Europa."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const TIPO = {
        alta_velocidad: 'Alta velocidad',
        estandar: 'Ancho estándar convencional',
        iberica_electrificada: 'Ancho ibérico electrificado',
        iberica_sin_electrificar: 'Ancho ibérico sin electrificar',
        metrica: 'Vía estrecha (ancho métrico)'
    };
    const COLOR_TIPO = ['#dc2626', '#f97316', '#0f766e', '#a3a3a3', '#7c3aed'];
    const CLASE = {
        trenes_dia: 'Todos los trenes de viajeros',
        trenes_cercanias: 'Cercanías y Rodalies',
        trenes_media_distancia: 'Media distancia y regionales',
        trenes_larga_distancia: 'Alta velocidad y larga distancia',
        trenes_autonomico: 'FGC, Euskotren y FGV'
    };
    // Tramos de trenes al día para el color del mapa de tráfico
    const TRAMOS = [[10, '1 a 10 trenes al día', '#fde68a'], [50, '11 a 50', '#fbbf24'], [100, '51 a 100', '#f97316'], [250, '101 a 250', '#dc2626'], [Infinity, 'Más de 250', '#7e22ce']];
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

# 🚆 Red de ferrocarril

Todas las vías de tren de España y cuántos trenes de viajeros pasan cada día por ellas. Adif, que gestiona la red estatal, no publica el tráfico de cada tramo, así que aquí se calcula a partir de los horarios de Renfe, FGC, Euskotren y FGV de un día laborable: cada tren se dibuja sobre las vías por las que va de una parada a la siguiente.

<Grid cols=4>
    <KpiCard
        title="Líneas de ferrocarril"
        value={espana[0]?.km_lineas}
        formattedValue="{formatNumber(espana[0]?.km_lineas, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 1)} km por 100.000 hab. en {espana[0]?.anio_km}"
        source="Eurostat"
    />
    <KpiCard
        title="Alta velocidad"
        value={espana[0]?.km_alta_velocidad}
        formattedValue="{formatNumber(espana[0]?.km_alta_velocidad, 0)} km"
        period="líneas construidas para alta velocidad en {espana[0]?.anio_av}: la mayor red de la UE"
        source="Eurostat"
    />
    <KpiCard
        title="El tramo con más trenes"
        value={tramo_max[0]?.trenes_dia}
        formattedValue={formatNumber(tramo_max[0]?.trenes_dia, 0)}
        unit=" trenes al día"
        period="{tramo_max[0]?.nombre ?? ''} ({tramo_max[0]?.fecha})"
        source="Renfe, FGC, Euskotren y FGV"
    />
    <KpiCard
        title="La estación con más trenes"
        value={estacion_max[0]?.trenes_dia}
        formattedValue={formatNumber(estacion_max[0]?.trenes_dia, 0)}
        unit=" trenes al día"
        period={estacion_max[0]?.nombre}
        source="Renfe, FGC, Euskotren y FGV"
    />
</Grid>

## La red

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
        {id: 'tipo_texto', title: 'Tipo'},
        {id: 'linea_adif', title: 'Línea de Adif'},
        {id: 'operador', title: 'Gestor'},
        {id: 'velocidad_maxima', title: 'Velocidad máxima (km/h)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Trazados de OpenStreetMap. Alta velocidad: ancho estándar (1.435 mm) para 200 km/h o más. El ancho ibérico (1.668 mm) es el de la red convencional; la vía estrecha (1.000 mm) es la de la antigua FEVE en la cornisa cantábrica y la de FGC, Euskotren, FGV o el tren de Sóller. Sin apartaderos, playas de vías ni ramales de industrias o puertos.</p>

<BarChart
    data={etiquetar(red_tipos, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    x=tipo_texto
    y=km
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km de corredor por tipo de vía"
/>

<p class="text-xs text-gray-500">Km de corredor medidos sobre el mapa: una línea de vía doble cuenta una vez. La cifra total ({formatNumber(red_tipos.reduce((s, d) => s + d.km, 0), 0)} km) es algo mayor que la de Eurostat ({formatNumber(espana[0]?.km_lineas, 0)} km) porque incluye las redes autonómicas y los haces de vías de las grandes estaciones.</p>

## Cuántos trenes pasan por cada tramo

<ButtonGroup name=clase title="Trenes">
    <ButtonGroupItem valueLabel="Todos" value="trenes_dia" default />
    <ButtonGroupItem valueLabel="Cercanías" value="trenes_cercanias" />
    <ButtonGroupItem valueLabel="Media distancia" value="trenes_media_distancia" />
    <ButtonGroupItem valueLabel="Alta velocidad y larga distancia" value="trenes_larga_distancia" />
    <ButtonGroupItem valueLabel="FGC, Euskotren y FGV" value="trenes_autonomico" />
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
        {id: 'trenes_dia', title: 'Trenes al día', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Cercanías', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Media distancia', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Alta velocidad y larga distancia', fmt: 'num0'},
        {id: 'trenes_autonomico', title: 'FGC, Euskotren y FGV', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Trenes de viajeros programados el {trafico[0]?.fecha} (un miércoles), sumando los dos sentidos. Más grueso = más trenes. Faltan los trenes de Iryo y Ouigo, que no publican sus horarios en abierto, y todos los de mercancías, así que los corredores de alta velocidad (Madrid-Barcelona, Madrid-Valencia, Madrid-Sevilla) y las líneas de mercancías tienen más tráfico del que se ve. Los tramos de metro en túnel de FGV y algunos de FGC y Euskotren no aparecen.</p>

```sql pares
SELECT estacion_a || ' – ' || estacion_b AS tramo, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico, operadores
FROM mother.movilidad_ferrocarril_pares
ORDER BY trenes_dia DESC
```

### Entre qué estaciones hay más trenes

<DataTable data={pares} rows=15 search=true>
    <Column id=tramo title="Entre" />
    <Column id=trenes_dia title="Trenes al día" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Cercanías" fmt=num0 />
    <Column id=trenes_media_distancia title="Media distancia" fmt=num0 />
    <Column id=trenes_larga_distancia title="Larga distancia" fmt=num0 />
    <Column id=trenes_autonomico title="Autonómicos" fmt=num0 />
    <Column id=operadores title="Operadores" />
</DataTable>

<p class="text-xs text-gray-500">Trenes entre dos paradas seguidas, en los dos sentidos. Un tren directo cuenta entre sus dos paradas aunque pase por otras estaciones sin parar.</p>

## Estaciones

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
        {id: 'operador', title: 'Operador'},
        {id: 'trenes_dia', title: 'Trenes que paran al día', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Cercanías', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Media distancia', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Alta velocidad y larga distancia', fmt: 'num0'}
    ]}
/>

```sql estaciones_tabla
SELECT * FROM ${estaciones} ORDER BY trenes_dia DESC
```

<DataTable data={estaciones_tabla} rows=10 search=true>
    <Column id=nombre title="Estación" />
    <Column id=operador title="Operador" />
    <Column id=trenes_dia title="Trenes al día" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Cercanías" fmt=num0 />
    <Column id=trenes_media_distancia title="Media distancia" fmt=num0 />
    <Column id=trenes_larga_distancia title="Larga distancia" fmt=num0 />
    <Column id=trenes_autonomico title="Autonómicos" fmt=num0 />
</DataTable>

## Por provincia

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
        {id: 'km_por_100k_hab', title: 'Km de vía por 100.000 hab.', fmt: 'num0'},
        {id: 'km_red', title: 'Km de red', fmt: 'num0'},
        {id: 'km_alta_velocidad', title: 'De alta velocidad', fmt: 'num0'},
        {id: 'sin_electrificar_pct', title: '% de ancho ibérico sin electrificar', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=km_red title="Km de red" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=km_por_100k_hab title="Por 100.000 hab." fmt=num0 />
    <Column id=km_alta_velocidad title="Alta velocidad" fmt=num0 />
    <Column id=km_iberica_electrificada title="Ibérico electrificado" fmt=num0 />
    <Column id=km_iberica_sin_electrificar title="Ibérico sin electrificar" fmt=num0 />
    <Column id=km_metrica title="Vía estrecha" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km de corredor que pasan por cada provincia, medidos sobre el mapa de OpenStreetMap. Las provincias grandes y poco pobladas por las que pasan varias líneas (Palencia, Zamora, Soria) tienen más vía por habitante.</p>

## Frente a Europa

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
    title="Km de líneas construidas para alta velocidad (último año publicado)"
/>

<BarChart
    data={europa.filter((d) => d.viajeros_km_hab > 0).toSorted((a, b) => b.viajeros_km_hab - a.viajeros_km_hab)}
    x=pais
    y=viajeros_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km recorridos en tren por habitante y año"
/>

<BarChart
    data={europa.filter((d) => d.toneladas_km_hab > 0).toSorted((a, b) => b.toneladas_km_hab - a.toneladas_km_hab)}
    x=pais
    y=toneladas_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Mercancías por tren: toneladas-km por habitante y año"
/>

<p class="text-xs text-gray-500">España tiene la red de alta velocidad más larga de la UE, pero sus habitantes viajan en tren menos km que los de Francia, Alemania o Austria, y por sus vías pasan muchas menos mercancías: el transporte de mercancías en España va casi todo por carretera. Datos de Eurostat, último año publicado por cada país.</p>

---

## Fuentes y notas

- **Red: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© colaboradores de OpenStreetMap, licencia ODbL), vías de tren y de vía estrecha descargadas con la API Overpass. Las dos vías de una línea de vía doble se funden en una sola (rejilla de unos 100 m) para medir km de corredor y no repartir los trenes entre ellas.
- **Trenes: horarios abiertos (GTFS) de [Renfe](https://data.renfe.com/)** (alta velocidad, larga y media distancia, y Cercanías y Rodalies; CC BY 4.0), **[FGC](https://www.fgc.cat/)**, **Euskotren** y **FGV** (estos tres, a través de [Mobility Database](https://mobilitydatabase.org/)). Se cuentan los trenes de un miércoles laborable y cada par de paradas se traza por el camino más corto sobre la red, respetando el ancho de vía de cada servicio. No hay datos abiertos de Iryo, Ouigo ni de los trenes de mercancías, ni de viajeros por tramo.
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: longitud de líneas (rail_if_line_sp, rail_if_line_ga), viajeros-km (rail_pa_total) y toneladas-km (rail_go_total); por habitante con la población de Eurostat.

<LastRefreshed prefix="Datos actualizados" />
