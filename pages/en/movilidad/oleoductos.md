---
title: Oil and gas pipelines
description: "Map of the pipelines that carry petrol and diesel across Spain and of the gas pipelines and regasification plants, how much fuel Exolum's network moves by pipeline compared with ship and lorry, and where the gas we import comes from."
i18n_origen: c2a041040c39
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const ESTADO = { operating: 'In service', construction: 'Under construction', proposed: 'Proposed', shelved: 'Shelved', cancelled: 'Cancelled' };
    const COLOR_ESTADO = { 'In service': '#0f766e', 'Under construction': '#f59e0b', 'Proposed': '#a78bfa', 'Shelved': '#94a3b8', 'Cancelled': '#cbd5e1' };
    const OPERADOR = { 'Sin operador en OSM': 'No known operator' };
    const COLOR_OPERADOR = { 'Exolum': '#b45309', 'Repsol': '#dc2626', 'No known operator': '#94a3b8' };
    const MODO = { oleoducto: 'Pipeline', buque: 'Ship', camion: 'Lorry' };
    const ORIGEN = { 'Otros': 'Others', 'Sin especificar': 'Not specified' };
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

# 🛢️ Oil and gas pipelines

The petrol and diesel sold in Spain do not mainly travel by lorry: they leave refineries and ports through a network of some 4,000 kilometres of pipelines now operated by Exolum (formerly CLH, Compañía Logística de Hidrocarburos). Natural gas arrives by pipeline from Algeria and France, or liquefied by ship at the regasification plants on the coast.

<Grid cols=4>
    <KpiCard
        title="Mapped oil pipelines"
        value={totales[0]?.km_oleoductos}
        formattedValue="{formatNumber(totales[0]?.km_oleoductos, 0)} km"
        period="{formatNumber(totales[0]?.km_exolum, 0)} km operated by Exolum according to OpenStreetMap"
        source="OpenStreetMap"
    />
    <KpiCard
        title="Fuel moved by pipeline"
        value={exolum_ultimo[0]?.oleoducto_pct}
        formattedValue="{formatNumber(exolum_ultimo[0]?.oleoducto_pct, 1)}%"
        period="of Exolum's transport in {exolum_ultimo[0]?.anio}; the rest by ship and lorry"
        source="CNMC"
    />
    <KpiCard
        title="Gas transmission pipelines"
        value={totales[0]?.km_gasoductos}
        formattedValue="{formatNumber(totales[0]?.km_gasoductos, 0)} km"
        period="main lines in service, and {totales[0]?.regasificadoras} regasification plants"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Imported gas per inhabitant"
        value={gas_ultimo[0]?.m3_hab}
        formattedValue="{formatNumber(gas_ultimo[0]?.m3_hab, 0)} m³"
        period="in {gas_ultimo[0]?.anio}; {formatNumber(gas_ultimo[0]?.argelia_pct, 0)}% from Algeria"
        source="Eurostat"
    />
</Grid>

## Map of oil pipelines

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
        {id: 'operador_texto', title: 'Operator'},
        {id: 'diametro', title: 'Diameter (inches)'},
        {id: 'longitud_km', title: 'Section length (km)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Routes from OpenStreetMap, drawn by volunteers: they cover some {formatNumber(totales[0]?.km_oleoductos, 0)} km of the roughly 4,000 that Exolum reports, so some sections are missing. The network links the refineries (Cartagena, Puertollano, Tarragona, Castellón, Huelva, Algeciras, Bilbao, A Coruña) and the ports with the large inland storage depots. Nobody publishes how much fuel goes through each section.</p>

## How much the network moves

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
    title="How Exolum's fuel reaches its depots (% of transport)"
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
    title="Fuel leaving Exolum's depots, litres per inhabitant per year"
/>

<p class="text-xs text-gray-500">Data from the CNMC's annual supervision reports on Exolum. "Primary" transport: from refineries and ports to the depots. Outflows include petrol, diesel and jet fuel, which then leave by tanker lorry for petrol stations, airports and customers.</p>

## Gas pipelines and regasification plants

<ButtonGroup name=estado_gas title="Status">
    <ButtonGroupItem valueLabel="In service" value="servicio" default />
    <ButtonGroupItem valueLabel="All, including proposed and cancelled" value="todos" />
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
        {id: 'estado_texto', title: 'Status'},
        {id: 'anio_inicio', title: 'In service since'},
        {id: 'capacidad', title: 'Capacity (billion m³/year)', fmt: 'num1'},
        {id: 'propietario', title: 'Owner'}
    ]}
/>

<p class="text-xs text-gray-500">Line width by capacity, where Global Energy Monitor knows it (the international pipelines); the rest of Enagás's trunk network is drawn with a thin line. Medgaz brings gas from Algeria to Almería; the Maghreb pipeline, through Morocco to Tarifa, has been shut since November 2021.</p>

```sql terminales
SELECT nombre, estado_fuente, propietario, anio_inicio, capacidad
FROM mother.movilidad_gasoductos
WHERE tipo = 'terminal_gnl' AND en_servicio
ORDER BY capacidad DESC
```

<DataTable data={terminales} rows=10>
    <Column id=nombre title="Regasification plant" />
    <Column id=propietario title="Owner" />
    <Column id=anio_inicio title="Since" fmt="0" />
    <Column id=capacidad title="Capacity (Mt of LNG/year)" fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

## Where the gas comes from

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
    data={etiquetar(gas_origen_anual, 'origen', (d) => ORIGEN[d.origen] ?? d.origen)}
    x=anio
    y=cuota
    series=origen
    type=stacked
    yFmt=num0
    yMax={100}
    title="Natural gas imports by country of origin (% of total)"
/>

<p class="text-xs text-gray-500">Algeria has always been the main supplier. Russia and the United States, which send liquefied gas by ship, gained weight after the Maghreb pipeline was closed in 2021. Source: Eurostat.</p>

```sql gas_total
SELECT DISTINCT anio, total_m3_por_hab FROM mother.movilidad_gas_importaciones WHERE anio >= 1990 ORDER BY anio
```

<BarChart
    data={gas_total}
    x=anio
    y=total_m3_por_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Imported natural gas, m³ per inhabitant per year"
/>

---

## Sources and notes

- **Oil pipeline routes: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© OpenStreetMap contributors, ODbL licence), ways tagged as oil or petroleum product pipelines, downloaded with the Overpass API. Exolum does not publish the layout of its network or the traffic per section.
- **[National Markets and Competition Commission (CNMC)](https://www.cnmc.es/)**, annual supervision reports on Exolum's activity: outflows from the depots and the split of transport between pipeline, ship and lorry.
- **[Global Energy Monitor, Global Gas Infrastructure Tracker](https://globalenergymonitor.org/projects/global-gas-infrastructure-tracker/)** (CC BY 4.0 licence): gas pipelines with status, year and capacity, and liquefied natural gas terminals.
- **[Eurostat, natural gas imports by country of origin (nrg_ti_gas)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ti_gas/default/table)**, in millions of cubic metres; per inhabitant with the INE municipal register.

<LastRefreshed prefix="Data updated" />
