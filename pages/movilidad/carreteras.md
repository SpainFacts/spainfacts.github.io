---
title: Carreteras
description: "Mapa de todas las carreteras de España según quién las gestiona (Estado, comunidades autónomas, diputaciones, cabildos y consells) y su tipo (autopistas de peaje, autovías, multicarril y convencionales), los coches y camiones que pasan cada día por cada tramo de la red del Estado, los km por habitante y por superficie de cada provincia desde 1970 y la comparación con Europa."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const TITULAR = {
        estado: 'Estado',
        comunidad: 'Comunidades autónomas',
        diputacion: 'Diputaciones, cabildos y consells'
    };
    const TIPO = {
        peaje: 'Autopistas de peaje',
        autovia: 'Autopistas libres y autovías',
        multicarril: 'Carreteras multicarril',
        convencional: 'Carreteras convencionales'
    };
    const COLOR_TITULAR = { estado: '#dc2626', comunidad: '#2563eb', diputacion: '#a3a3a3' };
    const COLOR_TIPO = { peaje: '#7c3aed', autovia: '#f97316', multicarril: '#0f766e', convencional: '#a3a3a3' };
    // Grosor del trazo en el mapa de la red según el tipo de vía
    const GROSOR = { peaje: 4, autovia: 4, multicarril: 2.5, convencional: 1 };
    // Tramos de vehículos al día para el color del mapa de tráfico
    const TRAMOS = [[2000, 'Menos de 2.000 vehículos al día', '#fde68a'], [10000, '2.000 a 10.000', '#fbbf24'], [30000, '10.000 a 30.000', '#f97316'], [70000, '30.000 a 70.000', '#dc2626'], [Infinity, 'Más de 70.000', '#7e22ce']];
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

# 🛣️ Carreteras

Las {formatNumber(espana[0]?.km_total, 0)} km de carreteras interurbanas de España según quién las paga y las mantiene: el Estado, las comunidades autónomas o las diputaciones (con las diputaciones forales vascas, los cabildos canarios y los consells de Baleares), y cuáles son autopistas de peaje, autovías gratuitas o carreteras normales. Además, cuántos vehículos pasan cada día por cada tramo de la red del Estado.

<Grid cols=4>
    <KpiCard
        title="Red de carreteras"
        value={espana[0]?.km_total}
        formattedValue="{formatNumber(espana[0]?.km_total, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 0)} km por 100.000 hab. en {espana[0]?.anio}"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="Autopistas, autovías y multicarril"
        value={espana[0]?.km_gran_capacidad}
        formattedValue="{formatNumber(espana[0]?.km_gran_capacidad, 0)} km"
        period="{formatNumber(espana[0]?.km_gran_capacidad_por_100k_hab, 1)} km por 100.000 hab."
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="De peaje"
        value={espana[0]?.km_peaje}
        formattedValue="{formatNumber(espana[0]?.km_peaje, 0)} km"
        period="el {formatNumber(espana[0]?.peaje_pct, 0)} % de la red de gran capacidad; {formatNumber(espana[0]?.km_peaje_estado, 0)} km del Estado"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="El tramo con más tráfico"
        value={tramo_max[0]?.imd}
        formattedValue={formatNumber(tramo_max[0]?.imd, 0)}
        unit=" vehículos al día"
        period="{tramo_max[0]?.carretera ?? ''} ({tramo_max[0]?.anio})"
        source="Ministerio de Transportes"
    />
</Grid>

## El mapa

<ButtonGroup name=vista title="Colorear por">
    <ButtonGroupItem valueLabel="Quién la gestiona" value="titular" default />
    <ButtonGroupItem valueLabel="Tipo de vía" value="tipo" />
</ButtonGroup>

<ButtonGroup name=filtro title="Mostrar">
    <ButtonGroupItem valueLabel="Todas" value="todas" />
    <ButtonGroupItem valueLabel="Solo autopistas, autovías y multicarril" value="gran_capacidad" default />
    <ButtonGroupItem valueLabel="Solo de peaje" value="peaje" />
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
        {id: 'titular_texto', title: 'La gestiona'},
        {id: 'tipo_texto', title: 'Tipo'},
        {id: 'provincia', title: 'Provincia'}
    ]}
/>

<p class="text-xs text-gray-500">Red del Estado: catálogo oficial del Ministerio de Transportes (2025). Comunidades, diputaciones, cabildos y consells: OpenStreetMap, con la titularidad deducida de la matrícula de cada carretera (CL- de la Junta de Castilla y León, BV- de la Diputació de Barcelona, DP- de una diputación gallega...) y el peaje marcado en el mapa; puede fallar en alguna carretera suelta. En el País Vasco todas las carreteras, también la A-8 y la AP-8, son de las diputaciones forales, y en Navarra, de la Comunidad Foral. No están las calles ni los caminos de los ayuntamientos (unos 360.000 km más, con el 10 % del tráfico).</p>

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
    title="Km de carretera según quién la gestiona y tipo de vía ({km_titular_tipo[0]?.anio})"
/>

<p class="text-xs text-gray-500">El Estado gestiona solo el {formatNumber(100 * espana[0]?.km_estado / espana[0]?.km_total, 0)} % de los km, pero casi todas las autovías y autopistas, que llevan la mitad del tráfico. Las comunidades tienen el {formatNumber(100 * espana[0]?.km_comunidad / espana[0]?.km_total, 0)} % y las diputaciones, cabildos y consells, el {formatNumber(100 * espana[0]?.km_diputacion / espana[0]?.km_total, 0)} %, casi todo carreteras convencionales.</p>

## Las de pago

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
    <Column id=carretera title="Carretera" />
    <Column id=titular_texto title="La gestiona" />
    <Column id=km title="Km de peaje" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=provincias title="Provincias" />
</DataTable>

<p class="text-xs text-gray-500">Km de peaje del catálogo del Estado y, en el resto, medidos sobre OpenStreetMap (aproximados: a veces cuentan las dos calzadas o los enlaces). Las autopistas del Estado que vencían entre 2018 y 2021 (AP-1, AP-4, la AP-7 de La Jonquera a Alicante y la AP-2) pasaron a ser autovías gratuitas; quedan de peaje, entre otras, la AP-6, la AP-9, la AP-68 y las radiales de Madrid. Las forales vascas (AP-1, AP-8), la AP-15 de Navarra las de la Generalitat (C-16, C-32) y las de la Xunta (AG-55, AG-57) las cobran sus gobiernos o sus concesionarias.</p>

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
    title="Km de autopistas, autovías y multicarril desde 1970"
/>

<p class="text-xs text-gray-500">Las primeras autopistas (años 70) fueron de peaje; desde los 80 casi todo lo que se construye son autovías gratuitas. El peaje bajó de unos 3.000 km en 2017 a menos de 2.000 al acabar las concesiones de las grandes autopistas del Estado. Hasta 1985 la serie publica datos cada cinco años y hasta 1990 no cuenta las carreteras de las diputaciones.</p>

## Cuántos vehículos pasan por cada tramo

<ButtonGroup name=vehiculos title="Vehículos">
    <ButtonGroupItem valueLabel="Todos" value="imd" default />
    <ButtonGroupItem valueLabel="Solo pesados (camiones y autobuses)" value="imd_pesados" />
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
        {id: 'imd', title: 'Vehículos al día', fmt: 'num0'},
        {id: 'imd_pesados', title: 'Camiones y autobuses al día', fmt: 'num0'},
        {id: 'pesados_pct', title: '% de pesados', fmt: 'num1'},
        {id: 'pk_inicio', title: 'Desde el km', fmt: 'num1'},
        {id: 'pk_fin', title: 'Hasta el km', fmt: 'num1'},
        {id: 'anio', title: 'Año del dato', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Intensidad media diaria (IMD): vehículos que pasan un día medio del año sumando los dos sentidos, medida por las estaciones de aforo del Ministerio en la Red de Carreteras del Estado. Más grueso = más vehículos. Las comunidades y diputaciones publican sus aforos cada una por su lado (o no los publican), así que su red no aparece; según el Ministerio, por la red del Estado pasa el 53 % del tráfico y el 66 % del de camiones.</p>

```sql tramos_tabla
-- Tramos seguidos con la misma estación de aforo (misma IMD) en una sola fila
SELECT carretera, min(pk_inicio) AS pk_inicio, max(pk_fin) AS pk_fin, imd, max(imd_pesados) AS imd_pesados,
    max(pesados_pct) AS pesados_pct, anio
FROM mother.movilidad_carreteras_trafico
GROUP BY carretera, imd, anio
ORDER BY imd DESC
```

### Los tramos con más tráfico

<DataTable data={tramos_tabla} rows=15 search=true>
    <Column id=carretera title="Carretera" />
    <Column id=pk_inicio title="Del km" fmt=num1 />
    <Column id=pk_fin title="Al km" fmt=num1 />
    <Column id=imd title="Vehículos al día" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=imd_pesados title="Pesados al día" fmt=num0 />
    <Column id=pesados_pct title="% pesados" fmt=num1 />
    <Column id=anio title="Año" fmt="0" />
</DataTable>

## Por provincia

<ButtonGroup name=medida title="Medir">
    <ButtonGroupItem valueLabel="Km por 100 km² de superficie" value="km_por_100_km2" default />
    <ButtonGroupItem valueLabel="Km por 100.000 habitantes" value="km_por_100k_hab" />
    <ButtonGroupItem valueLabel="Autovías y autopistas por 100 km²" value="km_gran_capacidad_por_100_km2" />
    <ButtonGroupItem valueLabel="Autovías y autopistas por 100.000 hab." value="km_gran_capacidad_por_100k_hab" />
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
        {id: 'km_total', title: 'Km de carretera', fmt: 'num0'},
        {id: 'km_por_100_km2', title: 'Por 100 km²', fmt: 'num1'},
        {id: 'km_por_100k_hab', title: 'Por 100.000 hab.', fmt: 'num0'},
        {id: 'km_gran_capacidad', title: 'Autovías, autopistas y multicarril', fmt: 'num0'},
        {id: 'km_peaje', title: 'De peaje', fmt: 'num0'}
    ]}
/>

```sql provincias_tabla
SELECT * FROM ${provincias} ORDER BY km_total DESC
```

<DataTable data={provincias_tabla} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=km_total title="Km" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=km_estado title="Estado" fmt=num0 />
    <Column id=km_comunidad title="Comunidad" fmt=num0 />
    <Column id=km_diputacion title="Diputación" fmt=num0 />
    <Column id=km_gran_capacidad title="Gran capacidad" fmt=num0 />
    <Column id=km_peaje title="Peaje" fmt=num0 />
    <Column id=km_por_100_km2 title="Por 100 km²" fmt=num1 />
    <Column id=km_por_100k_hab title="Por 100.000 hab." fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km del Anuario del Ministerio de Transportes (las comunidades y diputaciones mandan sus datos con un año de retraso). Por superficie destacan Galicia (Pontevedra, Lugo, A Coruña), con una red de diputación muy densa por sus miles de aldeas, Gipuzkoa, Bizkaia y Tenerife; por habitante, las provincias grandes y vacías (Soria, Teruel, Cuenca, Zamora), donde hay muchas carreteras para muy poca gente.</p>

## Cómo ha crecido desde 1970

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
    title="Km de carretera según quién la gestiona"
/>

<p class="text-xs text-gray-500">En 1984 el Estado traspasó a las comunidades autónomas buena parte de su red: por eso pasa de unos 80.000 km a 20.000. Las carreteras de las diputaciones solo se cuentan desde 1990. Desde entonces el total apenas cambia (unos 165.000 km); lo que crece son las autovías.</p>

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
    title="Km de autopistas, autovías y multicarril por 100.000 habitantes"
/>

## Frente a Europa

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
    title="Km de autopistas y autovías (último año publicado)"
/>

<BarChart
    data={europa.filter((d) => d.km_por_100k_hab > 0).toSorted((a, b) => b.km_por_100k_hab - a.km_por_100k_hab)}
    x=pais
    y=km_por_100k_hab
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c2410c"
    title="Km de autopistas y autovías por 100.000 habitantes"
/>

<BarChart
    data={europa.filter((d) => d.km_por_1000_km2 > 0).toSorted((a, b) => b.km_por_1000_km2 - a.km_por_1000_km2)}
    x=pais
    y=km_por_1000_km2
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a3412"
    title="Km de autopistas y autovías por 1.000 km² de superficie"
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
    title="Km de autopistas y autovías desde 1990"
/>

<p class="text-xs text-gray-500">España tiene la red de autopistas y autovías más larga de la UE y una de las más largas por habitante. Por superficie está en la media: el país es grande y está poco poblado por dentro. Eurostat cuenta como autopista también las autovías; el último año publicado varía según el país.</p>

---

## Fuentes y notas

- **Km por titularidad y tipo de vía: [Anuario Estadístico del Ministerio de Transportes](https://otle.transportes.gob.es/datos-graficos-mapas/datos-anuales/capital-infraestructuras/infraestructura-basica/carretera/conjunto-redes-carreteras-estado-comunidades-autonomas-diputaciones-cabildos)**, a través del Observatorio del Transporte y la Logística (OTLE): por provincia desde 2012 y para toda España desde 1970. Las diputaciones incluyen las forales vascas, los cabildos de Canarias y los consells de Baleares.
- **Red del Estado: [Catálogo de la Red de Carreteras del Estado](https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras)** (Ministerio de Transportes), con el tipo de cada tramo y si es de peaje.
- **Redes de comunidades, diputaciones, cabildos y consells: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© colaboradores de OpenStreetMap, licencia ODbL), carreteras con matrícula descargadas con la API Overpass. La titularidad se deduce de la matrícula; los km oficiales son los del Anuario.
- **Tráfico: IMD por tramo de la red del Estado** del visor [Hermes](https://hermes.transportes.gob.es/) del Ministerio de Transportes (mapa de tráfico; último año publicado de cada carretera).
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: km de autopistas por país (road_if_motorwa), población y superficie.

<LastRefreshed prefix="Datos actualizados" />
