---
title: Oleoductes i gasoductes
description: "Mapa dels oleoductes que porten la gasolina i el gasoil per Espanya i dels gasoductes i les regasificadores, quant combustible mou la xarxa d'Exolum per oleoducte davant el vaixell i el camió, i d'on ve el gas que importem."
i18n_origen: c2a041040c39
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const ESTADO = { operating: 'En servei', construction: 'En construcció', proposed: 'Proposat', shelved: 'Aturat', cancelled: 'Cancel·lat' };
    const COLOR_ESTADO = { 'En servei': '#0f766e', 'En construcció': '#f59e0b', 'Proposat': '#a78bfa', 'Aturat': '#94a3b8', 'Cancel·lat': '#cbd5e1' };
    const OPERADOR = { 'Sin operador en OSM': 'Sense operador conegut' };
    const COLOR_OPERADOR = { 'Exolum': '#b45309', 'Repsol': '#dc2626', 'Sense operador conegut': '#94a3b8' };
    const MODO = { oleoducto: 'Oleoducte', buque: 'Vaixell', camion: 'Camió' };
    const ORIGEN = { 'Otros': 'Altres', 'Sin especificar': 'Sense especificar' };
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

# 🛢️ Oleoductes i gasoductes

La gasolina i el gasoil que es venen a Espanya no viatgen sobretot en camió: surten de les refineries i els ports per una xarxa d'uns 4.000 quilòmetres d'oleoductes que avui explota Exolum (l'antiga CLH, Compañía Logística de Hidrocarburos). El gas natural arriba per gasoducte des d'Algèria i França o en vaixell, liquat, a les regasificadores de la costa.

<Grid cols=4>
    <KpiCard
        title="Oleoductes cartografiats"
        value={totales[0]?.km_oleoductos}
        formattedValue="{formatNumber(totales[0]?.km_oleoductos, 0)} km"
        period="{formatNumber(totales[0]?.km_exolum, 0)} km d'Exolum segons OpenStreetMap"
        source="OpenStreetMap"
    />
    <KpiCard
        title="Combustible que viatja per oleoducte"
        value={exolum_ultimo[0]?.oleoducto_pct}
        formattedValue="{formatNumber(exolum_ultimo[0]?.oleoducto_pct, 1)} %"
        period="del transport d'Exolum el {exolum_ultimo[0]?.anio}; la resta, vaixell i camió"
        source="CNMC"
    />
    <KpiCard
        title="Gasoductes de transport"
        value={totales[0]?.km_gasoductos}
        formattedValue="{formatNumber(totales[0]?.km_gasoductos, 0)} km"
        period="principals, en servei, i {totales[0]?.regasificadoras} regasificadores"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Gas importat per habitant"
        value={gas_ultimo[0]?.m3_hab}
        formattedValue="{formatNumber(gas_ultimo[0]?.m3_hab, 0)} m³"
        period="el {gas_ultimo[0]?.anio}; {formatNumber(gas_ultimo[0]?.argelia_pct, 0)} % d'Algèria"
        source="Eurostat"
    />
</Grid>

## Mapa d'oleoductes

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
        {id: 'diametro', title: 'Diàmetre (polzades)'},
        {id: 'longitud_km', title: 'Longitud del tram (km)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Traçats d'OpenStreetMap, dibuixats per voluntaris: recullen uns {formatNumber(totales[0]?.km_oleoductos, 0)} km dels prop de 4.000 que declara Exolum, de manera que hi falta algun tram. La xarxa uneix les refineries (Cartagena, Puertollano, Tarragona, Castelló, Huelva, Algesires, Bilbao, la Corunya) i els ports amb els grans magatzems de l'interior. Ningú no publica quant combustible passa per cada tram.</p>

## Quant mou la xarxa

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
    title="Com viatja el combustible d'Exolum fins als seus magatzems (% del transport)"
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
    title="Combustible que surt dels magatzems d'Exolum, litres per habitant i any"
/>

<p class="text-xs text-gray-500">Dades dels informes anuals de supervisió de la CNMC sobre Exolum. Transport «primari»: de refineries i ports als magatzems. Les sortides inclouen gasolines, gasoils i querosè d'aviació que després surten en camió cisterna cap a les gasolineres, els aeroports i els clients.</p>

## Gasoductes i regasificadores

<ButtonGroup name=estado_gas title="Estat">
    <ButtonGroupItem valueLabel="En servei" value="servicio" default />
    <ButtonGroupItem valueLabel="Tots, també proposats i cancel·lats" value="todos" />
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
        {id: 'estado_texto', title: 'Estat'},
        {id: 'anio_inicio', title: 'En servei des de'},
        {id: 'capacidad', title: 'Capacitat (milers de milions de m³/any)', fmt: 'num1'},
        {id: 'propietario', title: 'Propietari'}
    ]}
/>

<p class="text-xs text-gray-500">Gruix segons la capacitat, quan Global Energy Monitor la coneix (els gasoductes internacionals); la resta de la xarxa troncal d'Enagás va amb el traç fi. Medgaz porta gas d'Algèria a Almeria; el gasoducte del Magrib, pel Marroc fins a Tarifa, està aturat des del novembre del 2021.</p>

```sql terminales
SELECT nombre, estado_fuente, propietario, anio_inicio, capacidad
FROM mother.movilidad_gasoductos
WHERE tipo = 'terminal_gnl' AND en_servicio
ORDER BY capacidad DESC
```

<DataTable data={terminales} rows=10>
    <Column id=nombre title="Regasificadora" />
    <Column id=propietario title="Propietari" />
    <Column id=anio_inicio title="Des de" fmt="0" />
    <Column id=capacidad title="Capacitat (Mt de GNL/any)" fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

## D'on ve el gas

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
    title="Importacions de gas natural per país d'origen (% del total)"
/>

<p class="text-xs text-gray-500">Algèria sempre ha estat el primer proveïdor. Rússia i els Estats Units, que envien gas liquat en vaixell, van guanyar pes des que el 2021 es va tancar el gasoducte del Magrib. Font: Eurostat.</p>

```sql gas_total
SELECT DISTINCT anio, total_m3_por_hab FROM mother.movilidad_gas_importaciones WHERE anio >= 1990 ORDER BY anio
```

<BarChart
    data={gas_total}
    x=anio
    y=total_m3_por_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Gas natural importat, m³ per habitant i any"
/>

---

## Fonts i notes

- **Traçats d'oleoductes: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© col·laboradors d'OpenStreetMap, llicència ODbL), vies marcades com a canonada de petroli o de productes petrolífers, descarregades amb l'API Overpass. Exolum no publica el traçat de la seva xarxa ni el trànsit per tram.
- **[Comissió Nacional dels Mercats i la Competència (CNMC)](https://www.cnmc.es/)**, informes anuals de supervisió de l'activitat d'Exolum: sortides dels magatzems i repartiment del transport entre oleoducte, vaixell i camió.
- **[Global Energy Monitor, Global Gas Infrastructure Tracker](https://globalenergymonitor.org/projects/global-gas-infrastructure-tracker/)** (llicència CC BY 4.0): gasoductes amb estat, any i capacitat, i terminals de gas natural liquat.
- **[Eurostat, importacions de gas natural per país d'origen (nrg_ti_gas)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ti_gas/default/table)**, en milions de metres cúbics; per habitant amb el padró de l'INE.

<LastRefreshed prefix="Dades actualitzades" />
