---
title: Puntos de recarga
description: "Mapa de los puntos de recarga públicos para coches eléctricos en España por potencia y operador, y cuántos coches enchufables hay por cada punto en cada provincia."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 🔌 Puntos de recarga públicos

Dónde se puede cargar un coche eléctrico en España, según el registro oficial de puntos de recarga de acceso público que el Ministerio para la Transición Ecológica publica cada día en el Punto de Acceso Nacional de la DGT.

<Grid cols=3>
    <KpiCard
        title="Puntos de recarga públicos"
        value={totales[0]?.puntos}
        formattedValue="{formatNumber(100000 * totales[0]?.puntos / totales[0]?.poblacion, 0)} por 100.000 hab."
        period="{formatNumber(totales[0]?.puntos, 0)} puntos en {formatNumber(totales[0]?.sitios, 0)} emplazamientos"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Rápidos (50 kW o más)"
        value={totales[0]?.puntos_rapidos}
        formattedValue="{formatNumber(totales[0]?.puntos_rapidos / totales[0]?.puntos / 0.01, 1)} % de los puntos"
        period="{formatNumber(totales[0]?.puntos_rapidos, 0)} puntos rápidos, {formatNumber(totales[0]?.puntos_ultrarrapidos, 0)} de ellos de 150 kW o más"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Coches enchufables por punto"
        value={totales[0]?.enchufables_por_punto}
        formattedValue={formatNumber(totales[0]?.enchufables_por_punto, 1)}
        period="{formatNumber(totales[0]?.enchufables, 0)} turismos eléctricos e híbridos enchufables"
        source="DGT"
    />
</Grid>

## Mapa

<ButtonGroup name=tramo title="Potencia">
    <ButtonGroupItem valueLabel="Todos" value="todos" default />
    <ButtonGroupItem valueLabel="Ultrarrápidos (≥150 kW)" value="Ultrarrápida (≥150 kW)" />
    <ButtonGroupItem valueLabel="Rápidos (50-149 kW)" value="Rápida (50-149 kW)" />
    <ButtonGroupItem valueLabel="Semirrápidos (22-49 kW)" value="Semirrápida (22-49 kW)" />
    <ButtonGroupItem valueLabel="Lentos (<22 kW)" value="Lenta (<22 kW)" />
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Puntos de recarga: MITECO vía NAP (DGT)"
    tooltip={[
        {id: 'sitio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'operador', title: 'Operador'},
        {id: 'puntos', title: 'Puntos', fmt: 'num0'},
        {id: 'potencia_max_kw', title: 'Potencia máxima (kW)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Cada círculo es un emplazamiento (una electrolinera, un aparcamiento...) y su tamaño, el número de puntos. Color según el punto más potente del emplazamiento. Canarias aparece al suroeste: amplía el mapa.</p>

<BarChart
    data={tramos}
    x=tramo
    y=puntos
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Puntos de recarga por potencia"
/>

## Por provincia

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: DGT y MITECO"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'enchufables_por_punto', title: 'Enchufables por punto', fmt: 'num1'},
        {id: 'puntos', title: 'Puntos', fmt: 'num0'},
        {id: 'puntos_por_100k_hab', title: 'Puntos por 100.000 hab.', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Más oscuro = más coches enchufables por cada punto público, es decir, más presión sobre la red de recarga.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=puntos title="Puntos" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=puntos_rapidos title="Rápidos (≥50 kW)" fmt=num0 />
    <Column id=puntos_por_100k_hab title="Por 100.000 hab." fmt=num0 />
    <Column id=turismos_enchufables title="Turismos enchufables" fmt=num0 />
    <Column id=enchufables_por_punto title="Enchufables por punto" fmt=num1 />
</DataTable>

```sql operadores
SELECT operador, sum(puntos) AS puntos, count(*) AS sitios, sum(puntos) FILTER (WHERE potencia_max_kw >= 50) AS puntos_en_sitios_rapidos
FROM mother.movilidad_recarga_sitios
GROUP BY operador
ORDER BY puntos DESC
```

## Operadores

<DataTable data={operadores} rows=15 search=true>
    <Column id=operador title="Operador" />
    <Column id=puntos title="Puntos" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=sitios title="Emplazamientos" fmt=num0 />
</DataTable>

---

## Fuentes y notas

- **[Punto de Acceso Nacional de tráfico y movilidad (DGT) – Puntos de recarga eléctrica](https://nap.dgt.es/dataset/puntos-de-recarga-electrica-para-vehiculos)**, datos del Ministerio para la Transición Ecológica a partir de lo que declaran los operadores (Real Decreto 184/2022). Se actualiza cada día.
- Solo es obligatorio declarar los puntos de 43 kW o más; los lentos (hoteles, centros comerciales, garajes) se declaran de forma voluntaria, así que su número es un **mínimo**. No incluye puntos privados en viviendas o empresas.
- Municipio y provincia asignados por las coordenadas de cada emplazamiento. Potencia de un punto = la del conector más potente.
- Turismos enchufables: parque de la DGT (eléctricos puros e híbridos enchufables) del último mes publicado, por provincia del domicilio.

<LastRefreshed prefix="Datos actualizados" />
