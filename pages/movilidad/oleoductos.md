---
title: Oleoductos y gasoductos
description: "Mapa de los oleoductos que llevan la gasolina y el gasóleo por España y de los gasoductos y regasificadoras, cuánto combustible mueve la red de Exolum por oleoducto frente al barco y el camión, y de dónde viene el gas que importamos."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const ESTADO = { operating: 'En servicio', construction: 'En construcción', proposed: 'Propuesto', shelved: 'Paralizado', cancelled: 'Cancelado' };
    const COLOR_ESTADO = { 'En servicio': '#0f766e', 'En construcción': '#f59e0b', 'Propuesto': '#a78bfa', 'Paralizado': '#94a3b8', 'Cancelado': '#cbd5e1' };
    const OPERADOR = { 'Sin operador en OSM': 'Sin operador conocido' };
    const COLOR_OPERADOR = { 'Exolum': '#b45309', 'Repsol': '#dc2626', 'Sin operador conocido': '#94a3b8' };
    const MODO = { oleoducto: 'Oleoducto', buque: 'Barco', camion: 'Camión' };
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
</script>

```sql totales
SELECT
    (SELECT sum(longitud_km) FROM mother.movilidad_oleoductos) AS km_oleoductos,
    (SELECT sum(longitud_km) FROM mother.movilidad_oleoductos WHERE operador = 'Exolum') AS km_exolum,
    (SELECT sum(longitud_km_espana) FROM mother.movilidad_gasoductos WHERE en_servicio AND tipo = 'gasoducto') AS km_gasoductos,
    (SELECT count(*) FROM mother.movilidad_gasoductos WHERE en_servicio AND tipo = 'terminal_gnl') AS regasificadoras
```

```sql gas_ultimo
SELECT anio, max(total_m3_por_hab) AS m3_hab, max(total_millones_m3) AS total,
    max(cuota_pct) FILTER (WHERE cod_pais = 'DZ') AS argelia_pct,
    max(cuota_pct) FILTER (WHERE cod_pais = 'RU') AS rusia_pct,
    max(cuota_pct) FILTER (WHERE cod_pais = 'US') AS eeuu_pct
FROM mother.movilidad_gas_importaciones
WHERE anio = (SELECT max(anio) FROM mother.movilidad_gas_importaciones)
GROUP BY anio
```

```sql exolum
SELECT * FROM mother.movilidad_oleoductos_exolum ORDER BY anio
```

```sql exolum_ultimo
SELECT * FROM ${exolum} WHERE oleoducto_pct IS NOT NULL ORDER BY anio DESC LIMIT 1
```

# 🛢️ Oleoductos y gasoductos

La gasolina y el gasóleo que se venden en España no viajan sobre todo en camión: salen de las refinerías y los puertos por una red de unos 4.000 kilómetros de oleoductos que hoy explota Exolum (la antigua CLH, Compañía Logística de Hidrocarburos). El gas natural llega por gasoducto desde Argelia y Francia o en barco, licuado, a las regasificadoras de la costa.

<Grid cols=4>
    <KpiCard
        title="Oleoductos cartografiados"
        value={totales[0]?.km_oleoductos}
        formattedValue="{formatNumber(totales[0]?.km_oleoductos, 0)} km"
        period="{formatNumber(totales[0]?.km_exolum, 0)} km de Exolum según OpenStreetMap"
        source="OpenStreetMap"
    />
    <KpiCard
        title="Combustible que viaja por oleoducto"
        value={exolum_ultimo[0]?.oleoducto_pct}
        formattedValue="{formatNumber(exolum_ultimo[0]?.oleoducto_pct, 1)} %"
        period="del transporte de Exolum en {exolum_ultimo[0]?.anio}; el resto, barco y camión"
        source="CNMC"
    />
    <KpiCard
        title="Gasoductos de transporte"
        value={totales[0]?.km_gasoductos}
        formattedValue="{formatNumber(totales[0]?.km_gasoductos, 0)} km"
        period="principales, en servicio, y {totales[0]?.regasificadoras} regasificadoras"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Gas importado por habitante"
        value={gas_ultimo[0]?.m3_hab}
        formattedValue="{formatNumber(gas_ultimo[0]?.m3_hab, 0)} m³"
        period="en {gas_ultimo[0]?.anio}; {formatNumber(gas_ultimo[0]?.argelia_pct, 0)} % de Argelia"
        source="Eurostat"
    />
</Grid>

## Mapa de oleoductos

```sql oleoductos
SELECT osm_id, operador, coalesce(nombre, operador) AS nombre, diametro, longitud_km, trazado, 1 AS grosor,
    CASE operador WHEN 'Exolum' THEN 1 WHEN 'Repsol' THEN 2 ELSE 3 END AS orden
FROM mother.movilidad_oleoductos
ORDER BY orden
```

<MapaEspana
    data={etiquetar(oleoductos, 'operador_texto', (d) => OPERADOR[d.operador] ?? d.operador)}
    geom=trazado
    width=grosor
    maxWidth={2.5}
    value=operador_texto
    legendType=categorical
    colorPalette={['#b45309', '#dc2626', '#94a3b8']}
    opacity={0.9}
    pointName=nombre
    height={600}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'operador_texto', title: 'Operador'},
        {id: 'diametro', title: 'Diámetro (pulgadas)'},
        {id: 'longitud_km', title: 'Longitud del tramo (km)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Trazados de OpenStreetMap, dibujados por voluntarios: recogen unos {formatNumber(totales[0]?.km_oleoductos, 0)} km de los cerca de 4.000 que declara Exolum, así que falta algún tramo. La red une las refinerías (Cartagena, Puertollano, Tarragona, Castellón, Huelva, Algeciras, Bilbao, A Coruña) y los puertos con los grandes almacenes del interior. Nadie publica cuánto combustible pasa por cada tramo.</p>

## Cuánto mueve la red

<BarChart
    data={etiquetar(exolum_modos, 'modo_texto', (d) => MODO[d.modo] ?? d.modo)}
    x=anio
    y=pct
    series=modo_texto
    type=stacked
    yFmt=num1
    yMax={100}
    seriesOrder={[MODO.oleoducto, MODO.buque, MODO.camion]}
    colorPalette={['#b45309', '#0ea5e9', '#94a3b8']}
    title="Cómo viaja el combustible de Exolum hasta sus almacenes (% del transporte)"
/>

```sql exolum_modos
SELECT anio, 'oleoducto' AS modo, oleoducto_pct AS pct FROM ${exolum} WHERE oleoducto_pct IS NOT NULL
UNION ALL
SELECT anio, 'buque', buque_pct FROM ${exolum} WHERE buque_pct IS NOT NULL
UNION ALL
SELECT anio, 'camion', camion_pct FROM ${exolum} WHERE camion_pct IS NOT NULL
ORDER BY anio, modo
```

```sql exolum_salidas
SELECT anio, salidas_litros_hab FROM ${exolum} WHERE salidas_litros_hab IS NOT NULL ORDER BY anio
```

<BarChart
    data={exolum_salidas}
    x=anio
    y=salidas_litros_hab
    yFmt=num0
    fillColor="#b45309"
    title="Combustible que sale de los almacenes de Exolum, litros por habitante y año"
/>

<p class="text-xs text-gray-500">Datos de los informes anuales de supervisión de la CNMC sobre Exolum. Transporte «primario»: de refinerías y puertos a los almacenes. Las salidas incluyen gasolinas, gasóleos y queroseno de aviación que luego salen en camión cisterna hacia las gasolineras, aeropuertos y clientes.</p>

## Gasoductos y regasificadoras

<ButtonGroup name=estado_gas title="Estado">
    <ButtonGroupItem valueLabel="En servicio" value="servicio" default />
    <ButtonGroupItem valueLabel="Todos, también propuestos y cancelados" value="todos" />
</ButtonGroup>

```sql gasoductos
SELECT nombre, estado_fuente, anio_inicio, capacidad, propietario, longitud_km_espana, trazado,
    CASE estado_fuente WHEN 'operating' THEN 1 WHEN 'construction' THEN 2 WHEN 'proposed' THEN 3 WHEN 'shelved' THEN 4 ELSE 5 END AS orden
FROM mother.movilidad_gasoductos
WHERE tipo = 'gasoducto' AND trazado IS NOT NULL
  AND ('${inputs.estado_gas}' = 'todos' OR en_servicio)
ORDER BY orden DESC
```

<MapaEspana
    data={etiquetar(gasoductos, 'estado_texto', (d) => ESTADO[d.estado_fuente] ?? d.estado_fuente)}
    geom=trazado
    value=estado_texto
    legendType=categorical
    colorPalette={[...new Set(etiquetar(gasoductos, 'estado_texto', (d) => ESTADO[d.estado_fuente] ?? d.estado_fuente).map((d) => d.estado_texto))].map((e) => COLOR_ESTADO[e] ?? '#94a3b8')}
    width=capacidad
    widthFmt=num1
    minWidth={1.2}
    maxWidth={5}
    pointName=nombre
    height={600}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'estado_texto', title: 'Estado'},
        {id: 'anio_inicio', title: 'En servicio desde'},
        {id: 'capacidad', title: 'Capacidad (miles de millones de m³/año)', fmt: 'num1'},
        {id: 'propietario', title: 'Propietario'}
    ]}
/>

<p class="text-xs text-gray-500">Grosor según la capacidad, cuando Global Energy Monitor la conoce (los gasoductos internacionales); el resto de la red troncal de Enagás va con el trazo fino. Medgaz trae gas de Argelia a Almería; el gasoducto del Magreb, por Marruecos hasta Tarifa, está parado desde noviembre de 2021.</p>

```sql terminales
SELECT nombre, estado_fuente, propietario, anio_inicio, capacidad
FROM mother.movilidad_gasoductos
WHERE tipo = 'terminal_gnl' AND en_servicio
ORDER BY capacidad DESC
```

<DataTable data={terminales} rows=10>
    <Column id=nombre title="Regasificadora" />
    <Column id=propietario title="Propietario" />
    <Column id=anio_inicio title="Desde" fmt="0" />
    <Column id=capacidad title="Capacidad (Mt de GNL/año)" fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

## De dónde viene el gas

```sql gas_origen
SELECT anio, coalesce(pais, 'Sin especificar') AS pais, millones_m3, cuota_pct,
    CASE WHEN cod_pais IN ('DZ', 'RU', 'US', 'NG', 'QA', 'FR') THEN pais ELSE 'Otros' END AS origen
FROM mother.movilidad_gas_importaciones
WHERE anio >= 2000
```

```sql gas_origen_anual
SELECT anio, origen, sum(cuota_pct) AS cuota
FROM ${gas_origen}
GROUP BY anio, origen
ORDER BY anio, origen
```

<BarChart
    data={gas_origen_anual}
    x=anio
    y=cuota
    series=origen
    type=stacked
    yFmt=num0
    yMax={100}
    title="Importaciones de gas natural por país de origen (% del total)"
/>

<p class="text-xs text-gray-500">Argelia ha sido siempre el primer proveedor. Rusia y Estados Unidos, que mandan gas licuado en barco, ganaron peso desde que en 2021 se cerró el gasoducto del Magreb. Fuente: Eurostat.</p>

```sql gas_total
SELECT DISTINCT anio, total_m3_por_hab FROM mother.movilidad_gas_importaciones WHERE anio >= 1990 ORDER BY anio
```

<BarChart
    data={gas_total}
    x=anio
    y=total_m3_por_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Gas natural importado, m³ por habitante y año"
/>

---

## Fuentes y notas

- **Trazados de oleoductos: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© colaboradores de OpenStreetMap, licencia ODbL), vías marcadas como tubería de petróleo o productos petrolíferos, descargadas con la API Overpass. Exolum no publica el trazado de su red ni el tráfico por tramo.
- **[Comisión Nacional de los Mercados y la Competencia (CNMC)](https://www.cnmc.es/)**, informes anuales de supervisión de la actividad de Exolum: salidas de los almacenes y reparto del transporte entre oleoducto, barco y camión.
- **[Global Energy Monitor, Global Gas Infrastructure Tracker](https://globalenergymonitor.org/projects/global-gas-infrastructure-tracker/)** (licencia CC BY 4.0): gasoductos con estado, año y capacidad, y terminales de gas natural licuado.
- **[Eurostat, importaciones de gas natural por país de origen (nrg_ti_gas)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ti_gas/default/table)**, en millones de metros cúbicos; por habitante con el padrón del INE.

<LastRefreshed prefix="Datos actualizados" />
