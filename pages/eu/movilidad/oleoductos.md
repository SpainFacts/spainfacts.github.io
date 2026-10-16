---
title: Oliobideak eta gasbideak
description: "Espainian zehar gasolina eta gasolioa garraiatzen dituzten oliobideen mapa eta gasbideena eta birgasifikazio-plantena, Exolumen sareak zenbat erregai garraiatzen duen oliobidez itsasontziarekin eta kamioiarekin alderatuta, eta inportatzen dugun gasa nondik datorren."
i18n_origen: c2a041040c39
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const ESTADO = { operating: 'Martxan', construction: 'Eraikitzen', proposed: 'Proposatua', shelved: 'Geldituta', cancelled: 'Bertan behera utzia' };
    const COLOR_ESTADO = { 'Martxan': '#0f766e', 'Eraikitzen': '#f59e0b', 'Proposatua': '#a78bfa', 'Geldituta': '#94a3b8', 'Bertan behera utzia': '#cbd5e1' };
    const OPERADOR = { 'Sin operador en OSM': 'Operadore ezezaguna' };
    const COLOR_OPERADOR = { 'Exolum': '#b45309', 'Repsol': '#dc2626', 'Operadore ezezaguna': '#94a3b8' };
    const MODO = { oleoducto: 'Oliobidea', buque: 'Itsasontzia', camion: 'Kamioia' };
    const ORIGEN = { 'Otros': 'Besteak', 'Sin especificar': 'Zehaztu gabe' };
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

# 🛢️ Oliobideak eta gasbideak

Espainian saltzen diren gasolina eta gasolioa ez dira batez ere kamioiz garraiatzen: findegietatik eta portuetatik ateratzen dira, gaur egun Exolumek (lehengo CLH, Compañía Logística de Hidrocarburos) ustiatzen duen 4.000 kilometro inguruko oliobide-sare baten bidez. Gas naturala gasbidez iristen da Aljeriatik eta Frantziatik, edo itsasontziz, likidotuta, kostaldeko birgasifikazio-plantetara.

<Grid cols=4>
    <KpiCard
        title="Kartografiatutako oliobideak"
        value={totales[0]?.km_oleoductos}
        formattedValue="{formatNumber(totales[0]?.km_oleoductos, 0)} km"
        period="{formatNumber(totales[0]?.km_exolum, 0)} km Exolumenak, OpenStreetMapen arabera"
        source="OpenStreetMap"
    />
    <KpiCard
        title="Oliobidez garraiatzen den erregaia"
        value={exolum_ultimo[0]?.oleoducto_pct}
        formattedValue="% {formatNumber(exolum_ultimo[0]?.oleoducto_pct, 1)}"
        period="Exolumen garraioarena {exolum_ultimo[0]?.anio}. urtean; gainerakoa, itsasontziz eta kamioiz"
        source="CNMC"
    />
    <KpiCard
        title="Garraio-gasbideak"
        value={totales[0]?.km_gasoductos}
        formattedValue="{formatNumber(totales[0]?.km_gasoductos, 0)} km"
        period="nagusiak, martxan, eta {totales[0]?.regasificadoras} birgasifikazio-planta"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Inportatutako gasa biztanleko"
        value={gas_ultimo[0]?.m3_hab}
        formattedValue="{formatNumber(gas_ultimo[0]?.m3_hab, 0)} m³"
        period="{gas_ultimo[0]?.anio}. urtean; % {formatNumber(gas_ultimo[0]?.argelia_pct, 0)} Aljeriatik"
        source="Eurostat"
    />
</Grid>

## Oliobideen mapa

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
        {id: 'operador_texto', title: 'Operadorea'},
        {id: 'diametro', title: 'Diametroa (hazbeteak)'},
        {id: 'longitud_km', title: 'Zatiaren luzera (km)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">OpenStreetMapeko trazadurak, boluntarioek marraztuak: Exolumek aitortzen dituen 4.000 inguruetatik {formatNumber(totales[0]?.km_oleoductos, 0)} km inguru jasotzen dituzte, beraz zatiren bat falta da. Sareak findegiak (Cartagena, Puertollano, Tarragona, Castelló, Huelva, Algeciras, Bilbo, A Coruña) eta portuak barnealdeko biltegi handiekin lotzen ditu. Inork ez du argitaratzen zati bakoitzetik zenbat erregai igarotzen den.</p>

## Zenbat garraiatzen duen sareak

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
    title="Nola iristen den Exolumen erregaia bere biltegietara (garraioaren %)"
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
    title="Exolumen biltegietatik ateratzen den erregaia, litroak biztanleko eta urteko"
/>

<p class="text-xs text-gray-500">CNMCk Exolumi buruz egiten dituen urteko ikuskapen-txostenetako datuak. Garraio «primarioa»: findegietatik eta portuetatik biltegietara. Irteeretan sartzen dira gasolinak, gasolioak eta hegazkinetako kerosenoa, gero kamioi zisternetan gasolindegietara, aireportuetara eta bezeroengana doazenak.</p>

## Gasbideak eta birgasifikazio-plantak

<ButtonGroup name=estado_gas title="Egoera">
    <ButtonGroupItem valueLabel="Martxan" value="servicio" default />
    <ButtonGroupItem valueLabel="Guztiak, proposatuak eta bertan behera utziak barne" value="todos" />
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
        {id: 'estado_texto', title: 'Egoera'},
        {id: 'anio_inicio', title: 'Martxan noiztik'},
        {id: 'capacidad', title: 'Ahalmena (mila milioi m³/urteko)', fmt: 'num1'},
        {id: 'propietario', title: 'Jabea'}
    ]}
/>

<p class="text-xs text-gray-500">Lodiera ahalmenaren araberakoa da, Global Energy Monitorrek ezagutzen duenean (nazioarteko gasbideak); Enagásen gainerako sare nagusia marra mehearekin dago. Medgazek Aljeriatik Almeriara dakar gasa; Magrebeko gasbidea, Marokotik Tarifaraino, geldirik dago 2021eko azaroaz geroztik.</p>

```sql terminales
SELECT nombre, estado_fuente, propietario, anio_inicio, capacidad
FROM mother.movilidad_gasoductos
WHERE tipo = 'terminal_gnl' AND en_servicio
ORDER BY capacidad DESC
```

<DataTable data={terminales} rows=10>
    <Column id=nombre title="Birgasifikazio-planta" />
    <Column id=propietario title="Jabea" />
    <Column id=anio_inicio title="Noiztik" fmt="0" />
    <Column id=capacidad title="Ahalmena (GNL Mt/urteko)" fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

## Nondik datorren gasa

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
    title="Gas naturalaren inportazioak jatorrizko herrialdearen arabera (guztizkoaren %)"
/>

<p class="text-xs text-gray-500">Aljeria izan da beti hornitzaile nagusia. Errusiak eta Estatu Batuek, gas likidotua itsasontziz bidaltzen dutenek, pisua irabazi zuten 2021ean Magrebeko gasbidea itxi zenetik. Iturria: Eurostat.</p>

```sql gas_total
SELECT DISTINCT anio, total_m3_por_hab FROM mother.movilidad_gas_importaciones WHERE anio >= 1990 ORDER BY anio
```

<BarChart
    data={gas_total}
    x=anio
    y=total_m3_por_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Inportatutako gas naturala, m³ biztanleko eta urteko"
/>

---

## Iturriak eta oharrak

- **Oliobideen trazadurak: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© OpenStreetMapen laguntzaileak, ODbL lizentzia), petrolio-hodi edo petrolio-produktuen hodi gisa markatutako bideak, Overpass APIarekin deskargatuak. Exolumek ez du argitaratzen bere sarearen trazadura, ezta zati bakoitzeko trafikoa ere.
- **[Merkatuen eta Lehiaren Batzorde Nazionala (CNMC)](https://www.cnmc.es/)**, Exolumen jardueraren urteko ikuskapen-txostenak: biltegietako irteerak eta garraioaren banaketa oliobidearen, itsasontziaren eta kamioiaren artean.
- **[Global Energy Monitor, Global Gas Infrastructure Tracker](https://globalenergymonitor.org/projects/global-gas-infrastructure-tracker/)** (CC BY 4.0 lizentzia): gasbideak egoerarekin, urtearekin eta ahalmenarekin, eta gas natural likidotuaren terminalak.
- **[Eurostat, gas naturalaren inportazioak jatorrizko herrialdearen arabera (nrg_ti_gas)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ti_gas/default/table)**, milioi metro kubikotan; biztanleko, INEren erroldarekin.

<LastRefreshed prefix="Datuak eguneratuta" />
