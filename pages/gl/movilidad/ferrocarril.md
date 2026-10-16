---
title: Rede de ferrocarril
description: "Mapa de toda a rede ferroviaria de España (alta velocidade, ancho ibérico electrificado ou non e vía estreita) e de cantos trens de viaxeiros pasan ao día por cada tramo e estación, cos km de rede por habitante de cada provincia e a comparación con Europa."
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
        alta_velocidad: 'Alta velocidade',
        estandar: 'Ancho estándar convencional',
        iberica_electrificada: 'Ancho ibérico electrificado',
        iberica_sin_electrificar: 'Ancho ibérico sen electrificar',
        metrica: 'Vía estreita (ancho métrico)'
    };
    const COLOR_TIPO = ['#dc2626', '#f97316', '#0f766e', '#a3a3a3', '#7c3aed'];
    const CLASE = {
        trenes_dia: 'Todos os trens de viaxeiros',
        trenes_cercanias: 'Cercanías e Rodalies',
        trenes_media_distancia: 'Media distancia e rexionais',
        trenes_larga_distancia: 'Alta velocidade e longa distancia',
        trenes_autonomico: 'FGC, Euskotren e FGV'
    };
    // Tramos de trenes al día para el color del mapa de tráfico
    const TRAMOS = [[10, '1 a 10 trens ao día', '#fde68a'], [50, '11 a 50', '#fbbf24'], [100, '51 a 100', '#f97316'], [250, '101 a 250', '#dc2626'], [Infinity, 'Máis de 250', '#7e22ce']];
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

# 🚆 Rede de ferrocarril

Todas as vías de tren de España e cantos trens de viaxeiros pasan cada día por elas. Adif, que xestiona a rede estatal, non publica o tráfico de cada tramo, así que aquí se calcula a partir dos horarios de Renfe, FGC, Euskotren e FGV dun día laborable: cada tren debúxase sobre as vías polas que vai dunha parada á seguinte.

<Grid cols=4>
    <KpiCard
        title="Liñas de ferrocarril"
        value={espana[0]?.km_lineas}
        formattedValue="{formatNumber(espana[0]?.km_lineas, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 1)} km por 100.000 hab. en {espana[0]?.anio_km}"
        source="Eurostat"
    />
    <KpiCard
        title="Alta velocidade"
        value={espana[0]?.km_alta_velocidad}
        formattedValue="{formatNumber(espana[0]?.km_alta_velocidad, 0)} km"
        period="liñas construídas para alta velocidade en {espana[0]?.anio_av}: a maior rede da UE"
        source="Eurostat"
    />
    <KpiCard
        title="O tramo con máis trens"
        value={tramo_max[0]?.trenes_dia}
        formattedValue={formatNumber(tramo_max[0]?.trenes_dia, 0)}
        unit=" trens ao día"
        period="{tramo_max[0]?.nombre ?? ''} ({tramo_max[0]?.fecha})"
        source="Renfe, FGC, Euskotren e FGV"
    />
    <KpiCard
        title="A estación con máis trens"
        value={estacion_max[0]?.trenes_dia}
        formattedValue={formatNumber(estacion_max[0]?.trenes_dia, 0)}
        unit=" trens ao día"
        period={estacion_max[0]?.nombre}
        source="Renfe, FGC, Euskotren e FGV"
    />
</Grid>

## A rede

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
        {id: 'linea_adif', title: 'Liña de Adif'},
        {id: 'operador', title: 'Xestor'},
        {id: 'velocidad_maxima', title: 'Velocidade máxima (km/h)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Trazados de OpenStreetMap. Alta velocidade: ancho estándar (1.435 mm) para 200 km/h ou máis. O ancho ibérico (1.668 mm) é o da rede convencional; a vía estreita (1.000 mm) é a da antiga FEVE na cornixa cantábrica e a de FGC, Euskotren, FGV ou o tren de Sóller. Sen vías de apartado, zonas de manobras nin ramais de industrias ou portos.</p>

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

<p class="text-xs text-gray-500">Km de corredor medidos sobre o mapa: unha liña de vía dobre conta unha vez. A cifra total ({formatNumber(red_tipos.reduce((s, d) => s + d.km, 0), 0)} km) é algo maior ca a de Eurostat ({formatNumber(espana[0]?.km_lineas, 0)} km) porque inclúe as redes autonómicas e os feixes de vías das grandes estacións.</p>

## Cantos trens pasan por cada tramo

<ButtonGroup name=clase title="Trens">
    <ButtonGroupItem valueLabel="Todos" value="trenes_dia" default />
    <ButtonGroupItem valueLabel="Cercanías" value="trenes_cercanias" />
    <ButtonGroupItem valueLabel="Media distancia" value="trenes_media_distancia" />
    <ButtonGroupItem valueLabel="Alta velocidade e longa distancia" value="trenes_larga_distancia" />
    <ButtonGroupItem valueLabel="FGC, Euskotren e FGV" value="trenes_autonomico" />
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
        {id: 'trenes_dia', title: 'Trens ao día', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Cercanías', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Media distancia', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Alta velocidade e longa distancia', fmt: 'num0'},
        {id: 'trenes_autonomico', title: 'FGC, Euskotren e FGV', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Trens de viaxeiros programados o {trafico[0]?.fecha} (un mércores), sumando os dous sentidos. Máis groso = máis trens. Faltan os trens de Iryo e Ouigo, que non publican os seus horarios en aberto, e todos os de mercadorías, así que os corredores de alta velocidade (Madrid-Barcelona, Madrid-Valencia, Madrid-Sevilla) e as liñas de mercadorías teñen máis tráfico do que se ve. Os tramos de metro en túnel de FGV e algúns de FGC e Euskotren non aparecen.</p>

```sql pares
SELECT estacion_a || ' – ' || estacion_b AS tramo, trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico, operadores
FROM mother.movilidad_ferrocarril_pares
ORDER BY trenes_dia DESC
```

### Entre que estacións hai máis trens

<DataTable data={pares} rows=15 search=true>
    <Column id=tramo title="Entre" />
    <Column id=trenes_dia title="Trens ao día" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Cercanías" fmt=num0 />
    <Column id=trenes_media_distancia title="Media distancia" fmt=num0 />
    <Column id=trenes_larga_distancia title="Longa distancia" fmt=num0 />
    <Column id=trenes_autonomico title="Autonómicos" fmt=num0 />
    <Column id=operadores title="Operadores" />
</DataTable>

<p class="text-xs text-gray-500">Trens entre dúas paradas seguidas, nos dous sentidos. Un tren directo conta entre as súas dúas paradas aínda que pase por outras estacións sen parar.</p>

## Estacións

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
        {id: 'trenes_dia', title: 'Trens que paran ao día', fmt: 'num0'},
        {id: 'trenes_cercanias', title: 'Cercanías', fmt: 'num0'},
        {id: 'trenes_media_distancia', title: 'Media distancia', fmt: 'num0'},
        {id: 'trenes_larga_distancia', title: 'Alta velocidade e longa distancia', fmt: 'num0'}
    ]}
/>

```sql estaciones_tabla
SELECT * FROM ${estaciones} ORDER BY trenes_dia DESC
```

<DataTable data={estaciones_tabla} rows=10 search=true>
    <Column id=nombre title="Estación" />
    <Column id=operador title="Operador" />
    <Column id=trenes_dia title="Trens ao día" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=trenes_cercanias title="Cercanías" fmt=num0 />
    <Column id=trenes_media_distancia title="Media distancia" fmt=num0 />
    <Column id=trenes_larga_distancia title="Longa distancia" fmt=num0 />
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
        {id: 'km_red', title: 'Km de rede', fmt: 'num0'},
        {id: 'km_alta_velocidad', title: 'De alta velocidade', fmt: 'num0'},
        {id: 'sin_electrificar_pct', title: '% de ancho ibérico sen electrificar', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=km_red title="Km de rede" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=km_por_100k_hab title="Por 100.000 hab." fmt=num0 />
    <Column id=km_alta_velocidad title="Alta velocidade" fmt=num0 />
    <Column id=km_iberica_electrificada title="Ibérico electrificado" fmt=num0 />
    <Column id=km_iberica_sin_electrificar title="Ibérico sen electrificar" fmt=num0 />
    <Column id=km_metrica title="Vía estreita" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km de corredor que pasan por cada provincia, medidos sobre o mapa de OpenStreetMap. As provincias grandes e pouco poboadas polas que pasan varias liñas (Palencia, Zamora, Soria) teñen máis vía por habitante.</p>

## Fronte a Europa

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
    title="Km de liñas construídas para alta velocidade (último ano publicado)"
/>

<BarChart
    data={europa.filter((d) => d.viajeros_km_hab > 0).toSorted((a, b) => b.viajeros_km_hab - a.viajeros_km_hab)}
    x=pais
    y=viajeros_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Km percorridos en tren por habitante e ano"
/>

<BarChart
    data={europa.filter((d) => d.toneladas_km_hab > 0).toSorted((a, b) => b.toneladas_km_hab - a.toneladas_km_hab)}
    x=pais
    y=toneladas_km_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Mercadorías por tren: toneladas-km por habitante e ano"
/>

<p class="text-xs text-gray-500">España ten a rede de alta velocidade máis longa da UE, pero os seus habitantes viaxan en tren menos km ca os de Francia, Alemaña ou Austria, e polas súas vías pasan moitas menos mercadorías: o transporte de mercadorías en España vai case todo por estrada. Datos de Eurostat, último ano publicado por cada país.</p>

---

## Fontes e notas

- **Rede: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© colaboradores de OpenStreetMap, licenza ODbL), vías de tren e de vía estreita descargadas coa API Overpass. As dúas vías dunha liña de vía dobre fúndense nunha soa (grella duns 100 m) para medir km de corredor e non repartir os trens entre elas.
- **Trens: horarios abertos (GTFS) de [Renfe](https://data.renfe.com/)** (alta velocidade, longa e media distancia, e Cercanías e Rodalies; CC BY 4.0), **[FGC](https://www.fgc.cat/)**, **Euskotren** e **FGV** (estes tres, a través de [Mobility Database](https://mobilitydatabase.org/)). Cóntanse os trens dun mércores laborable e cada par de paradas trázase polo camiño máis curto sobre a rede, respectando o ancho de vía de cada servizo. Non hai datos abertos de Iryo, Ouigo nin dos trens de mercadorías, nin de viaxeiros por tramo.
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: lonxitude de liñas (rail_if_line_sp, rail_if_line_ga), viaxeiros-km (rail_pa_total) e toneladas-km (rail_go_total); por habitante coa poboación de Eurostat.

<LastRefreshed prefix="Datos actualizados" />
