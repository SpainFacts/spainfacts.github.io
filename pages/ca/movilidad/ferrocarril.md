---
title: Xarxa de ferrocarril
description: "Mapa de tota la xarxa ferroviària d'Espanya (alta velocitat, ample ibèric electrificat o no i via estreta) i de quants trens de viatgers passen cada dia per cada tram i estació, amb els km de xarxa per habitant de cada província i la comparació amb Europa."
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
        alta_velocidad: 'Alta velocitat',
        estandar: 'Ample estàndard convencional',
        iberica_electrificada: 'Ample ibèric electrificat',
        iberica_sin_electrificar: 'Ample ibèric sense electrificar',
        metrica: 'Via estreta (ample mètric)'
    };
    const COLOR_TIPO = ['#dc2626', '#f97316', '#0f766e', '#a3a3a3', '#7c3aed'];
    const CLASE = {
        trenes_dia: 'Tots els trens de viatgers',
        trenes_cercanias: 'Rodalies i Cercanías',
        trenes_media_distancia: 'Mitjana distància i regionals',
        trenes_larga_distancia: 'Alta velocitat i llarga distància',
        trenes_autonomico: 'FGC, Euskotren i FGV'
    };
    // Tramos de trenes al día para el color del mapa de tráfico
    const TRAMOS = [[10, '1 a 10 trens al dia', '#fde68a'], [50, '11 a 50', '#fbbf24'], [100, '51 a 100', '#f97316'], [250, '101 a 250', '#dc2626'], [Infinity, 'Més de 250', '#7e22ce']];
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

# 🚆 Xarxa de ferrocarril

Totes les vies de tren d'Espanya i quants trens de viatgers hi passen cada dia. Adif, que gestiona la xarxa estatal, no publica el trànsit de cada tram, així que aquí es calcula a partir dels horaris de Renfe, FGC, Euskotren i FGV d'un dia feiner: cada tren es dibuixa sobre les vies per on va d'una parada a la següent.

<Grid cols=4>
    <KpiCard
        title="Línies de ferrocarril"
        value={espana[0]?.km_lineas}
        formattedValue="{formatNumber(espana[0]?.km_lineas, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 1)} km per 100.000 hab. el {espana[0]?.anio_km}"
        source="Eurostat"
    />
    <KpiCard
        title="Alta velocitat"
        value={espana[0]?.km_alta_velocidad}
        formattedValue="{formatNumber(espana[0]?.km_alta_velocidad, 0)} km"
        period="línies construïdes per a alta velocitat el {espana[0]?.anio_av}: la xarxa més gran de la UE"
        source="Eurostat"
    />
    <KpiCard
        title="El tram amb més trens"
        value={tramo_max[0]?.trenes_dia}
        formattedValue={formatNumber(tramo_max[0]?.trenes_dia, 0)}
        unit=" trens al dia"
        period="{tramo_max[0]?.nombre ?? ''} ({tramo_max[0]?.fecha})"
        source="Renfe, FGC, Euskotren i FGV"
    />
    <KpiCard
        title="L'estació amb més trens"
        value={estacion_max[0]?.trenes_dia}
        formattedValue={formatNumber(estacion_max[0]?.trenes_dia, 0)}
        unit=" trens al dia"
        period={estacion_max[0]?.nombre}
        source="Renfe, FGC, Euskotren i FGV"
    />
</Grid>

## La xarxa

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
        {id: 'tipo_texto', title: 'Tipus'},
        {id: 'linea_adif', title: "Línia d'Adif"},
        {id: 'operador', title: 'Gestor'},
        {id: 'velocidad_maxima', title: 'Velocitat màxima (km/h)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Traçats d'OpenStreetMap. Alta velocitat: ample estàndard (1.435 mm) per a 200 km/h o més. L'ample ibèric (1.668 mm) és el de la xarxa convencional; la via estreta (1.000 mm) és la de l'antiga FEVE a la cornisa cantàbrica i la d'FGC, Euskotren, FGV o el tren de Sóller. Sense apartadors, platges de vies ni ramals d'indústries o ports.</p>

<BarChart
    data={etiquetar(red_tipos, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    x=tipo_texto
    y=km
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km de corredor per tipus de via"
/>

<p class="text-xs text-gray-500">Km de corredor mesurats sobre el mapa: una línia de via doble compta una vegada. La xifra total ({formatNumber(red_tipos.reduce((s, d) => s + d.km, 0), 0)} km) és una mica més alta que la d'Eurostat ({formatNumber(espana[0]?.km_lineas, 0)} km) perquè inclou les xarxes autonòmiques i els feixos de vies de les grans estacions.</p>

## Quants trens passen per cada tram

<ButtonGroup name=clase title="Trens">
    <ButtonGroupItem valueLabel="Tots" value="trenes_dia" default />
    <ButtonGroupItem valueLabel="Rodalies" value="trenes_cercanias" />
    <ButtonGroupItem valueLabel="Mitjana distància" value="trenes_media_distancia" />
    <ButtonGroupItem valueLabel="Alta velocitat i llarga distància" value="trenes_larga_distancia" />
    <ButtonGroupItem valueLabel="FGC, Euskotren i FGV" value="trenes_autonomico" />
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
        {id: 'trenes_dia', title: 'Trens al dia', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Rodalies', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Mitjana distància', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Alta velocitat i llarga distància', fmt: 'num0'},
        {id: 'trenes_autonomico', title: 'FGC, Euskotren i FGV', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Trens de viatgers programats el {trafico[0]?.fecha} (un dimecres), sumant els dos sentits. Més gruixut = més trens. Hi falten els trens d'Iryo i Ouigo, que no publiquen els horaris en obert, i tots els de mercaderies, de manera que els corredors d'alta velocitat (Madrid-Barcelona, Madrid-València, Madrid-Sevilla) i les línies de mercaderies tenen més trànsit del que es veu. Els trams de metro en túnel d'FGV i alguns d'FGC i Euskotren no hi apareixen.</p>

```sql pares
SELECT estacion_a || ' – ' || estacion_b AS tramo, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico, operadores
FROM mother.movilidad_ferrocarril_pares
ORDER BY trenes_dia DESC
```

### Entre quines estacions hi ha més trens

<DataTable data={pares} rows=15 search=true>
    <Column id=tramo title="Entre" />
    <Column id=trenes_dia title="Trens al dia" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Rodalies" fmt=num0 />
    <Column id=trenes_media_distancia title="Mitjana distància" fmt=num0 />
    <Column id=trenes_larga_distancia title="Llarga distància" fmt=num0 />
    <Column id=trenes_autonomico title="Autonòmics" fmt=num0 />
    <Column id=operadores title="Operadors" />
</DataTable>

<p class="text-xs text-gray-500">Trens entre dues parades seguides, en els dos sentits. Un tren directe compta entre les seves dues parades encara que passi per altres estacions sense aturar-s'hi.</p>

## Estacions

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
        {id: 'trenes_dia', title: "Trens que s'hi aturen cada dia", fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Rodalies', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Mitjana distància', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Alta velocitat i llarga distància', fmt: 'num0'}
    ]}
/>

```sql estaciones_tabla
SELECT * FROM ${estaciones} ORDER BY trenes_dia DESC
```

<DataTable data={estaciones_tabla} rows=10 search=true>
    <Column id=nombre title="Estació" />
    <Column id=operador title="Operador" />
    <Column id=trenes_dia title="Trens al dia" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Rodalies" fmt=num0 />
    <Column id=trenes_media_distancia title="Mitjana distància" fmt=num0 />
    <Column id=trenes_larga_distancia title="Llarga distància" fmt=num0 />
    <Column id=trenes_autonomico title="Autonòmics" fmt=num0 />
</DataTable>

## Per província

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
        {id: 'km_por_100k_hab', title: 'Km de via per 100.000 hab.', fmt: 'num0'},
        {id: 'km_red', title: 'Km de xarxa', fmt: 'num0'},
        {id: 'km_alta_velocidad', title: "D'alta velocitat", fmt: 'num0'},
        {id: 'sin_electrificar_pct', title: "% d'ample ibèric sense electrificar", fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=km_red title="Km de xarxa" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=km_por_100k_hab title="Per 100.000 hab." fmt=num0 />
    <Column id=km_alta_velocidad title="Alta velocitat" fmt=num0 />
    <Column id=km_iberica_electrificada title="Ibèric electrificat" fmt=num0 />
    <Column id=km_iberica_sin_electrificar title="Ibèric sense electrificar" fmt=num0 />
    <Column id=km_metrica title="Via estreta" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km de corredor que passen per cada província, mesurats sobre el mapa d'OpenStreetMap. Les províncies grans i poc poblades per on passen diverses línies (Palència, Zamora, Sòria) tenen més via per habitant.</p>

## Davant Europa

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
    title="Km de línies construïdes per a alta velocitat (últim any publicat)"
/>

<BarChart
    data={europa.filter((d) => d.viajeros_km_hab > 0).toSorted((a, b) => b.viajeros_km_hab - a.viajeros_km_hab)}
    x=pais
    y=viajeros_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km recorreguts en tren per habitant i any"
/>

<BarChart
    data={europa.filter((d) => d.toneladas_km_hab > 0).toSorted((a, b) => b.toneladas_km_hab - a.toneladas_km_hab)}
    x=pais
    y=toneladas_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Mercaderies per tren: tones-km per habitant i any"
/>

<p class="text-xs text-gray-500">Espanya té la xarxa d'alta velocitat més llarga de la UE, però els seus habitants viatgen en tren menys km que els de França, Alemanya o Àustria, i per les seves vies hi passen moltes menys mercaderies: el transport de mercaderies a Espanya va gairebé tot per carretera. Dades d'Eurostat, últim any publicat per cada país.</p>

---

## Fonts i notes

- **Xarxa: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© col·laboradors d'OpenStreetMap, llicència ODbL), vies de tren i de via estreta descarregades amb l'API Overpass. Les dues vies d'una línia de via doble es fonen en una de sola (reixa d'uns 100 m) per mesurar km de corredor i no repartir els trens entre totes dues.
- **Trens: horaris oberts (GTFS) de [Renfe](https://data.renfe.com/)** (alta velocitat, llarga i mitjana distància, i Rodalies i Cercanías; CC BY 4.0), **[FGC](https://www.fgc.cat/)**, **Euskotren** i **FGV** (aquests tres, a través de [Mobility Database](https://mobilitydatabase.org/)). Es compten els trens d'un dimecres feiner i cada parell de parades es traça pel camí més curt sobre la xarxa, respectant l'ample de via de cada servei. No hi ha dades obertes d'Iryo, Ouigo ni dels trens de mercaderies, ni de viatgers per tram.
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: longitud de línies (rail_if_line_sp, rail_if_line_ga), viatgers-km (rail_pa_total) i tones-km (rail_go_total); per habitant amb la població d'Eurostat.

<LastRefreshed prefix="Dades actualitzades" />
