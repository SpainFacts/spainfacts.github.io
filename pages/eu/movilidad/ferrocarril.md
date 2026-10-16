---
title: Trenbide-sarea
description: "Espainiako trenbide-sare osoaren mapa (abiadura handia, zabalera iberiarra, elektrifikatua edo ez, eta bide estua) eta egunean zati eta geltoki bakoitzetik zenbat bidaiari-tren igarotzen diren, probintzia bakoitzeko biztanleko sare-km-ekin eta Europarekiko alderaketarekin."
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
        alta_velocidad: 'Abiadura handia',
        estandar: 'Zabalera estandar konbentzionala',
        iberica_electrificada: 'Zabalera iberiar elektrifikatua',
        iberica_sin_electrificar: 'Zabalera iberiar elektrifikatu gabea',
        metrica: 'Bide estua (zabalera metrikoa)'
    };
    const COLOR_TIPO = ['#dc2626', '#f97316', '#0f766e', '#a3a3a3', '#7c3aed'];
    const CLASE = {
        trenes_dia: 'Bidaiari-tren guztiak',
        trenes_cercanias: 'Aldiriko trenak (Cercanías eta Rodalies)',
        trenes_media_distancia: 'Distantzia ertainekoak eta erregionalak',
        trenes_larga_distancia: 'Abiadura handia eta distantzia luzea',
        trenes_autonomico: 'FGC, Euskotren eta FGV'
    };
    // Tramos de trenes al día para el color del mapa de tráfico
    const TRAMOS = [[10, 'Egunean 1-10 tren', '#fde68a'], [50, '11-50', '#fbbf24'], [100, '51-100', '#f97316'], [250, '101-250', '#dc2626'], [Infinity, '250 baino gehiago', '#7e22ce']];
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

# 🚆 Trenbide-sarea

Espainiako trenbide guztiak eta egunero haietatik zenbat bidaiari-tren igarotzen diren. Adifek, estatuko sarea kudeatzen duenak, ez du argitaratzen zati bakoitzeko trafikoa; beraz, hemen Renfe, FGC, Euskotren eta FGVren lanegun bateko ordutegietatik kalkulatzen da: tren bakoitza geltoki batetik hurrengora igarotzen den bideen gainean marrazten da.

<Grid cols=4>
    <KpiCard
        title="Trenbide-lineak"
        value={espana[0]?.km_lineas}
        formattedValue="{formatNumber(espana[0]?.km_lineas, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 1)} km 100.000 biz. bakoitzeko, {espana[0]?.anio_km}. urtean"
        source="Eurostat"
    />
    <KpiCard
        title="Abiadura handia"
        value={espana[0]?.km_alta_velocidad}
        formattedValue="{formatNumber(espana[0]?.km_alta_velocidad, 0)} km"
        period="abiadura handirako eraikitako lineak {espana[0]?.anio_av}. urtean: EBko sarerik handiena"
        source="Eurostat"
    />
    <KpiCard
        title="Tren gehien dituen zatia"
        value={tramo_max[0]?.trenes_dia}
        formattedValue={formatNumber(tramo_max[0]?.trenes_dia, 0)}
        unit=" tren egunean"
        period="{tramo_max[0]?.nombre ?? ''} ({tramo_max[0]?.fecha})"
        source="Renfe, FGC, Euskotren eta FGV"
    />
    <KpiCard
        title="Tren gehien dituen geltokia"
        value={estacion_max[0]?.trenes_dia}
        formattedValue={formatNumber(estacion_max[0]?.trenes_dia, 0)}
        unit=" tren egunean"
        period={estacion_max[0]?.nombre}
        source="Renfe, FGC, Euskotren eta FGV"
    />
</Grid>

## Sarea

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
        {id: 'tipo_texto', title: 'Mota'},
        {id: 'linea_adif', title: 'Adifen linea'},
        {id: 'operador', title: 'Kudeatzailea'},
        {id: 'velocidad_maxima', title: 'Gehieneko abiadura (km/h)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">OpenStreetMapeko trazadurak. Abiadura handia: zabalera estandarra (1.435 mm), 200 km/h-rako edo gehiagorako. Zabalera iberiarra (1.668 mm) sare konbentzionalarena da; bide estua (1.000 mm), berriz, Kantauri itsasertzeko FEVE zaharrarena eta FGC, Euskotren, FGV edo Sóllerreko trenarena. Saihesbideak, trenbide-guneak eta industria edo portuetarako adarrak kanpoan geratzen dira.</p>

<BarChart
    data={etiquetar(red_tipos, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    x=tipo_texto
    y=km
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Korridore-km bide motaren arabera"
/>

<p class="text-xs text-gray-500">Korridore-km mapan neurtuta: bide bikoitzeko linea batek behin zenbatzen du. Guztizko zifra ({formatNumber(red_tipos.reduce((s, d) => s + d.km, 0), 0)} km) Eurostatena ({formatNumber(espana[0]?.km_lineas, 0)} km) baino zertxobait handiagoa da, autonomia-erkidegoetako sareak eta geltoki handietako bide-sortak barne hartzen dituelako.</p>

## Zenbat tren igarotzen diren zati bakoitzetik

<ButtonGroup name=clase title="Trenak">
    <ButtonGroupItem valueLabel="Guztiak" value="trenes_dia" default />
    <ButtonGroupItem valueLabel="Aldirikoak" value="trenes_cercanias" />
    <ButtonGroupItem valueLabel="Distantzia ertaina" value="trenes_media_distancia" />
    <ButtonGroupItem valueLabel="Abiadura handia eta distantzia luzea" value="trenes_larga_distancia" />
    <ButtonGroupItem valueLabel="FGC, Euskotren eta FGV" value="trenes_autonomico" />
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
        {id: 'trenes_dia', title: 'Trenak egunean', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Aldirikoak', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Distantzia ertaina', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Abiadura handia eta distantzia luzea', fmt: 'num0'},
        {id: 'trenes_autonomico', title: 'FGC, Euskotren eta FGV', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">{trafico[0]?.fecha} egunerako (asteazkena) programatutako bidaiari-trenak, bi noranzkoak batuta. Lodiago = tren gehiago. Iryoren eta Ouigoren trenak falta dira, ez baitituzte ordutegiak modu irekian argitaratzen, baita merkantzia-tren guztiak ere; beraz, abiadura handiko korridoreek (Madril-Bartzelona, Madril-Valentzia, Madril-Sevilla) eta merkantzia-lineek ikusten dena baino trafiko handiagoa dute. FGVren tunel barneko metro-zatiak eta FGCren eta Euskotrenen zati batzuk ez dira agertzen.</p>

```sql pares
SELECT estacion_a || ' – ' || estacion_b AS tramo, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico, operadores
FROM mother.movilidad_ferrocarril_pares
ORDER BY trenes_dia DESC
```

### Zein geltokiren artean dagoen tren gehien

<DataTable data={pares} rows=15 search=true>
    <Column id=tramo title="Nondik nora" />
    <Column id=trenes_dia title="Trenak egunean" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Aldirikoak" fmt=num0 />
    <Column id=trenes_media_distancia title="Distantzia ertaina" fmt=num0 />
    <Column id=trenes_larga_distancia title="Distantzia luzea" fmt=num0 />
    <Column id=trenes_autonomico title="Erkidegoetakoak" fmt=num0 />
    <Column id=operadores title="Operadoreak" />
</DataTable>

<p class="text-xs text-gray-500">Jarraian dauden bi geltokiren arteko trenak, bi noranzkoetan. Tren zuzen batek bere bi geldialdien artean zenbatzen du, nahiz eta beste geltoki batzuetatik gelditu gabe igaro.</p>

## Geltokiak

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
        {id: 'operador', title: 'Operadorea'},
        {id: 'trenes_dia', title: 'Egunean gelditzen diren trenak', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Aldirikoak', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Distantzia ertaina', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Abiadura handia eta distantzia luzea', fmt: 'num0'}
    ]}
/>

```sql estaciones_tabla
SELECT * FROM ${estaciones} ORDER BY trenes_dia DESC
```

<DataTable data={estaciones_tabla} rows=10 search=true>
    <Column id=nombre title="Geltokia" />
    <Column id=operador title="Operadorea" />
    <Column id=trenes_dia title="Trenak egunean" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Aldirikoak" fmt=num0 />
    <Column id=trenes_media_distancia title="Distantzia ertaina" fmt=num0 />
    <Column id=trenes_larga_distancia title="Distantzia luzea" fmt=num0 />
    <Column id=trenes_autonomico title="Erkidegoetakoak" fmt=num0 />
</DataTable>

## Probintziaka

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
        {id: 'km_por_100k_hab', title: 'Bide-km 100.000 biz. bakoitzeko', fmt: 'num0'},
        {id: 'km_red', title: 'Sare-km', fmt: 'num0'},
        {id: 'km_alta_velocidad', title: 'Abiadura handikoak', fmt: 'num0'},
        {id: 'sin_electrificar_pct', title: 'Zabalera iberiar elektrifikatu gabearen %', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=km_red title="Sare-km" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=km_por_100k_hab title="100.000 biz. bakoitzeko" fmt=num0 />
    <Column id=km_alta_velocidad title="Abiadura handia" fmt=num0 />
    <Column id=km_iberica_electrificada title="Iberiarra, elektrifikatua" fmt=num0 />
    <Column id=km_iberica_sin_electrificar title="Iberiarra, elektrifikatu gabea" fmt=num0 />
    <Column id=km_metrica title="Bide estua" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Probintzia bakoitzetik igarotzen diren korridore-km, OpenStreetMapeko mapan neurtuta. Hainbat linea igarotzen diren probintzia handi eta biztanle gutxikoek (Palentzia, Zamora, Soria) bide gehiago dute biztanleko.</p>

## Europarekin alderatuta

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
    title="Abiadura handirako eraikitako lineen km (argitaratutako azken urtea)"
/>

<BarChart
    data={europa.filter((d) => d.viajeros_km_hab > 0).toSorted((a, b) => b.viajeros_km_hab - a.viajeros_km_hab)}
    x=pais
    y=viajeros_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Trenez egindako km biztanleko eta urteko"
/>

<BarChart
    data={europa.filter((d) => d.toneladas_km_hab > 0).toSorted((a, b) => b.toneladas_km_hab - a.toneladas_km_hab)}
    x=pais
    y=toneladas_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Merkantziak trenez: tona-km biztanleko eta urteko"
/>

<p class="text-xs text-gray-500">Espainiak du EBko abiadura handiko sarerik luzeena, baina bertako biztanleek Frantziakoek, Alemaniakoek edo Austriakoek baino km gutxiago egiten dituzte trenez, eta haren trenbideetatik askoz merkantzia gutxiago igarotzen da: Espainian merkantzien garraioa ia osorik errepidez egiten da. Eurostaten datuak, herrialde bakoitzak argitaratutako azken urtekoak.</p>

---

## Iturriak eta oharrak

- **Sarea: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© OpenStreetMapen laguntzaileak, ODbL lizentzia), tren-bideak eta bide estukoak, Overpass APIarekin deskargatuak. Bide bikoitzeko linea baten bi bideak bakar batean bateratzen dira (100 m inguruko sareta) korridore-km neurtzeko eta trenak haien artean ez banatzeko.
- **Trenak: [Renferen](https://data.renfe.com/)** ordutegi irekiak (GTFS) (abiadura handia, distantzia luzea eta ertaina, eta Cercanías eta Rodalies; CC BY 4.0), **[FGC](https://www.fgc.cat/)**, **Euskotren** eta **FGV** (azken hirurak [Mobility Databaseren](https://mobilitydatabase.org/) bidez). Lanegun bateko asteazkeneko trenak zenbatzen dira, eta geltoki-bikote bakoitza sareko biderik laburrenetik trazatzen da, zerbitzu bakoitzaren bide-zabalera errespetatuz. Ez dago Iryoren, Ouigoren edo merkantzia-trenen datu irekirik, ezta zati bakoitzeko bidaiariena ere.
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: lineen luzera (rail_if_line_sp, rail_if_line_ga), bidaiari-km (rail_pa_total) eta tona-km (rail_go_total); biztanleko, Eurostaten biztanleriarekin.

<LastRefreshed prefix="Datuak eguneratuta" />
