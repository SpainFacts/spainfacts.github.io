---
title: Oleodutos e gasodutos
description: "Mapa dos oleodutos que levan a gasolina e o gasóleo por España e dos gasodutos e regasificadoras, canto combustible move a rede de Exolum por oleoduto fronte ao barco e o camión, e de onde vén o gas que importamos."
i18n_origen: c2a041040c39
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const ESTADO = { operating: 'En servizo', construction: 'En construción', proposed: 'Proposto', shelved: 'Paralizado', cancelled: 'Cancelado' };
    const COLOR_ESTADO = { 'En servizo': '#0f766e', 'En construción': '#f59e0b', 'Proposto': '#a78bfa', 'Paralizado': '#94a3b8', 'Cancelado': '#cbd5e1' };
    const OPERADOR = { 'Sin operador en OSM': 'Sen operador coñecido' };
    const COLOR_OPERADOR = { 'Exolum': '#b45309', 'Repsol': '#dc2626', 'Sen operador coñecido': '#94a3b8' };
    const MODO = { oleoducto: 'Oleoduto', buque: 'Barco', camion: 'Camión' };
    const ORIGEN = { 'Otros': 'Outros', 'Sin especificar': 'Sen especificar' };
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

# 🛢️ Oleodutos e gasodutos

A gasolina e o gasóleo que se venden en España non viaxan sobre todo en camión: saen das refinarías e dos portos por unha rede duns 4.000 quilómetros de oleodutos que hoxe explota Exolum (a antiga CLH, Compañía Logística de Hidrocarburos). O gas natural chega por gasoduto desde Alxeria e Francia ou en barco, licuado, ás regasificadoras da costa.

<Grid cols=4>
    <KpiCard
        title="Oleodutos cartografados"
        value={totales[0]?.km_oleoductos}
        formattedValue="{formatNumber(totales[0]?.km_oleoductos, 0)} km"
        period="{formatNumber(totales[0]?.km_exolum, 0)} km de Exolum segundo OpenStreetMap"
        source="OpenStreetMap"
    />
    <KpiCard
        title="Combustible que viaxa por oleoduto"
        value={exolum_ultimo[0]?.oleoducto_pct}
        formattedValue="{formatNumber(exolum_ultimo[0]?.oleoducto_pct, 1)} %"
        period="do transporte de Exolum en {exolum_ultimo[0]?.anio}; o resto, barco e camión"
        source="CNMC"
    />
    <KpiCard
        title="Gasodutos de transporte"
        value={totales[0]?.km_gasoductos}
        formattedValue="{formatNumber(totales[0]?.km_gasoductos, 0)} km"
        period="principais, en servizo, e {totales[0]?.regasificadoras} regasificadoras"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Gas importado por habitante"
        value={gas_ultimo[0]?.m3_hab}
        formattedValue="{formatNumber(gas_ultimo[0]?.m3_hab, 0)} m³"
        period="en {gas_ultimo[0]?.anio}; {formatNumber(gas_ultimo[0]?.argelia_pct, 0)} % de Alxeria"
        source="Eurostat"
    />
</Grid>

## Mapa de oleodutos

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
        {id: 'diametro', title: 'Diámetro (polgadas)'},
        {id: 'longitud_km', title: 'Lonxitude do tramo (km)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Trazados de OpenStreetMap, debuxados por voluntarios: recollen uns {formatNumber(totales[0]?.km_oleoductos, 0)} km dos preto de 4.000 que declara Exolum, así que falta algún tramo. A rede une as refinarías (Cartagena, Puertollano, Tarragona, Castelló, Huelva, Alxeciras, Bilbao, A Coruña) e os portos cos grandes almacéns do interior. Ninguén publica canto combustible pasa por cada tramo.</p>

## Canto move a rede

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
    title="Como viaxa o combustible de Exolum ata os seus almacéns (% do transporte)"
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
    title="Combustible que sae dos almacéns de Exolum, litros por habitante e ano"
/>

<p class="text-xs text-gray-500">Datos dos informes anuais de supervisión da CNMC sobre Exolum. Transporte «primario»: de refinarías e portos aos almacéns. As saídas inclúen gasolinas, gasóleos e queroseno de aviación que logo saen en camión cisterna cara ás gasolineiras, aeroportos e clientes.</p>

## Gasodutos e regasificadoras

<ButtonGroup name=estado_gas title="Estado">
    <ButtonGroupItem valueLabel="En servizo" value="servicio" default />
    <ButtonGroupItem valueLabel="Todos, tamén propostos e cancelados" value="todos" />
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
        {id: 'anio_inicio', title: 'En servizo desde'},
        {id: 'capacidad', title: 'Capacidade (miles de millóns de m³/ano)', fmt: 'num1'},
        {id: 'propietario', title: 'Propietario'}
    ]}
/>

<p class="text-xs text-gray-500">Grosor segundo a capacidade, cando Global Energy Monitor a coñece (os gasodutos internacionais); o resto da rede troncal de Enagás vai co trazo fino. Medgaz trae gas de Alxeria a Almería; o gasoduto do Magreb, por Marrocos ata Tarifa, está parado desde novembro de 2021.</p>

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
    <Column id=capacidad title="Capacidade (Mt de GNL/ano)" fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

## De onde vén o gas

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
    title="Importacións de gas natural por país de orixe (% do total)"
/>

<p class="text-xs text-gray-500">Alxeria foi sempre o primeiro provedor. Rusia e os Estados Unidos, que mandan gas licuado en barco, gañaron peso desde que en 2021 se pechou o gasoduto do Magreb. Fonte: Eurostat.</p>

```sql gas_total
SELECT DISTINCT anio, total_m3_por_hab FROM mother.movilidad_gas_importaciones WHERE anio >= 1990 ORDER BY anio
```

<BarChart
    data={gas_total}
    x=anio
    y=total_m3_por_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Gas natural importado, m³ por habitante e ano"
/>

---

## Fontes e notas

- **Trazados de oleodutos: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© colaboradores de OpenStreetMap, licenza ODbL), vías marcadas como tubaxe de petróleo ou de produtos petrolíferos, descargadas coa API Overpass. Exolum non publica o trazado da súa rede nin o tráfico por tramo.
- **[Comisión Nacional dos Mercados e a Competencia (CNMC)](https://www.cnmc.es/)**, informes anuais de supervisión da actividade de Exolum: saídas dos almacéns e reparto do transporte entre oleoduto, barco e camión.
- **[Global Energy Monitor, Global Gas Infrastructure Tracker](https://globalenergymonitor.org/projects/global-gas-infrastructure-tracker/)** (licenza CC BY 4.0): gasodutos con estado, ano e capacidade, e terminais de gas natural licuado.
- **[Eurostat, importacións de gas natural por país de orixe (nrg_ti_gas)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ti_gas/default/table)**, en millóns de metros cúbicos; por habitante co padrón do INE.

<LastRefreshed prefix="Datos actualizados" />
