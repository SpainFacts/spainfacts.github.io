---
title: Carreteres
description: "Mapa de totes les carreteres d'Espanya segons qui les gestiona (Estat, comunitats autònomes, diputacions, cabildos i consells) i el seu tipus (autopistes de peatge, autovies, multicarril i convencionals), els cotxes i camions que passen cada dia per cada tram de la xarxa de l'Estat, els km per habitant i per superfície de cada província des de 1970 i la comparació amb Europa."
i18n_origen: 2b3f03137772
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const TITULAR = {
        estado: 'Estat',
        comunidad: 'Comunitats autònomes',
        diputacion: 'Diputacions, cabildos i consells'
    };
    const TIPO = {
        peaje: 'Autopistes de peatge',
        autovia: 'Autopistes lliures i autovies',
        multicarril: 'Carreteres multicarril',
        convencional: 'Carreteres convencionals'
    };
    const COLOR_TITULAR = { estado: '#dc2626', comunidad: '#2563eb', diputacion: '#a3a3a3' };
    const COLOR_TIPO = { peaje: '#7c3aed', autovia: '#f97316', multicarril: '#0f766e', convencional: '#a3a3a3' };
    // Grosor del trazo en el mapa de la red según el tipo de vía
    const GROSOR = { peaje: 4, autovia: 4, multicarril: 2.5, convencional: 1 };
    // Tramos de vehículos al día para el color del mapa de tráfico
    const TRAMOS = [[2000, 'Menys de 2.000 vehicles al dia', '#fde68a'], [10000, '2.000 a 10.000', '#fbbf24'], [30000, '10.000 a 30.000', '#f97316'], [70000, '30.000 a 70.000', '#dc2626'], [Infinity, 'Més de 70.000', '#7e22ce']];
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

# 🛣️ Carreteres

Els {formatNumber(espana[0]?.km_total, 0)} km de carreteres interurbanes d'Espanya segons qui les paga i les manté: l'Estat, les comunitats autònomes o les diputacions (amb les diputacions forals basques, els cabildos canaris i els consells de les Balears), i quines són autopistes de peatge, autovies gratuïtes o carreteres normals. A més, quants vehicles passen cada dia per cada tram de la xarxa de l'Estat.

<Grid cols=4>
    <KpiCard
        title="Xarxa de carreteres"
        value={espana[0]?.km_total}
        formattedValue="{formatNumber(espana[0]?.km_total, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 0)} km per 100.000 hab. el {espana[0]?.anio}"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="Autopistes, autovies i multicarril"
        value={espana[0]?.km_gran_capacidad}
        formattedValue="{formatNumber(espana[0]?.km_gran_capacidad, 0)} km"
        period="{formatNumber(espana[0]?.km_gran_capacidad_por_100k_hab, 1)} km per 100.000 hab."
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="De peatge"
        value={espana[0]?.km_peaje}
        formattedValue="{formatNumber(espana[0]?.km_peaje, 0)} km"
        period="el {formatNumber(espana[0]?.peaje_pct, 0)} % de la xarxa de gran capacitat; {formatNumber(espana[0]?.km_peaje_estado, 0)} km de l'Estat"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="El tram amb més trànsit"
        value={tramo_max[0]?.imd}
        formattedValue={formatNumber(tramo_max[0]?.imd, 0)}
        unit=" vehicles al dia"
        period="{tramo_max[0]?.carretera ?? ''} ({tramo_max[0]?.anio})"
        source="Ministerio de Transportes"
    />
</Grid>

## El mapa

<ButtonGroup name=vista title="Acolorir per">
    <ButtonGroupItem valueLabel="Qui la gestiona" value="titular" default />
    <ButtonGroupItem valueLabel="Tipus de via" value="tipo" />
</ButtonGroup>

<ButtonGroup name=filtro title="Mostrar">
    <ButtonGroupItem valueLabel="Totes" value="todas" />
    <ButtonGroupItem valueLabel="Només autopistes, autovies i multicarril" value="gran_capacidad" default />
    <ButtonGroupItem valueLabel="Només de peatge" value="peaje" />
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
        {id: 'tipo_texto', title: 'Tipus'},
        {id: 'provincia', title: 'Província'}
    ]}
/>

<p class="text-xs text-gray-500">Xarxa de l'Estat: catàleg oficial del Ministeri de Transports (2025). Comunitats, diputacions, cabildos i consells: OpenStreetMap, amb la titularitat deduïda de la matrícula de cada carretera (CL- de la Junta de Castella i Lleó, BV- de la Diputació de Barcelona, DP- d'una diputació gallega...) i el peatge marcat al mapa; pot fallar en alguna carretera solta. Al País Basc totes les carreteres, també l'A-8 i l'AP-8, són de les diputacions forals, i a Navarra, de la Comunitat Foral. No hi ha els carrers ni els camins dels ajuntaments (uns 360.000 km més, amb el 10 % del trànsit).</p>

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
    title="Km de carretera segons qui la gestiona i tipus de via ({km_titular_tipo[0]?.anio})"
/>

<p class="text-xs text-gray-500">L'Estat gestiona només el {formatNumber(100 * espana[0]?.km_estado / espana[0]?.km_total, 0)} % dels km, però quasi totes les autovies i autopistes, que porten la meitat del trànsit. Les comunitats en tenen el {formatNumber(100 * espana[0]?.km_comunidad / espana[0]?.km_total, 0)} % i les diputacions, cabildos i consells, el {formatNumber(100 * espana[0]?.km_diputacion / espana[0]?.km_total, 0)} %, quasi tot carreteres convencionals.</p>

## Les de pagament

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
    <Column id=km title="Km de peatge" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=provincias title="Províncies" />
</DataTable>

<p class="text-xs text-gray-500">Km de peatge del catàleg de l'Estat i, a la resta, mesurats sobre OpenStreetMap (aproximats: de vegades compten les dues calçades o els enllaços). Les autopistes de l'Estat que vencien entre 2018 i 2021 (AP-1, AP-4, l'AP-7 de la Jonquera a Alacant i l'AP-2) han passat a ser autovies gratuïtes; continuen de peatge, entre d'altres, l'AP-6, l'AP-9, l'AP-68 i les radials de Madrid. Les forals basques (AP-1, AP-8), l'AP-15 de Navarra les de la Generalitat (C-16, C-32) i les de la Xunta (AG-55, AG-57) les cobren els seus governs o les seves concessionàries.</p>

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
    title="Km d'autopistes, autovies i multicarril des de 1970"
/>

<p class="text-xs text-gray-500">Les primeres autopistes (anys 70) van ser de peatge; des dels 80 quasi tot el que es construeix són autovies gratuïtes. El peatge va baixar d'uns 3.000 km el 2017 a menys de 2.000 en acabar les concessions de les grans autopistes de l'Estat. Fins al 1985 la sèrie publica dades cada cinc anys i fins al 1990 no compta les carreteres de les diputacions.</p>

## Quants vehicles passen per cada tram

<ButtonGroup name=vehiculos title="Vehicles">
    <ButtonGroupItem valueLabel="Tots" value="imd" default />
    <ButtonGroupItem valueLabel="Només pesants (camions i autobusos)" value="imd_pesados" />
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
        {id: 'imd', title: 'Vehicles al dia', fmt: 'num0'},
        {id: 'imd_pesados', title: 'Camions i autobusos al dia', fmt: 'num0'},
        {id: 'pesados_pct', title: '% de pesants', fmt: 'num1'},
        {id: 'pk_inicio', title: 'Des del km', fmt: 'num1'},
        {id: 'pk_fin', title: 'Fins al km', fmt: 'num1'},
        {id: 'anio', title: 'Any de la dada', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Intensitat mitjana diària (IMD): vehicles que passen un dia mitjà de l'any sumant els dos sentits, mesurada per les estacions d'aforament del Ministeri a la Xarxa de Carreteres de l'Estat. Més gruixut = més vehicles. Les comunitats i les diputacions publiquen els seus aforaments cadascuna per la seva banda (o no els publiquen), de manera que la seva xarxa no apareix; segons el Ministeri, per la xarxa de l'Estat passa el 53 % del trànsit i el 66 % del de camions.</p>

```sql tramos_tabla
-- Tramos seguidos con la misma estación de aforo (misma IMD) en una sola fila
SELECT carretera, min(pk_inicio) AS pk_inicio, max(pk_fin) AS pk_fin, imd, max(imd_pesados) AS imd_pesados,
    max(pesados_pct) AS pesados_pct, anio
FROM mother.movilidad_carreteras_trafico
GROUP BY carretera, imd, anio
ORDER BY imd DESC
```

### Els trams amb més trànsit

<DataTable data={tramos_tabla} rows=15 search=true>
    <Column id=carretera title="Carretera" />
    <Column id=pk_inicio title="Del km" fmt=num1 />
    <Column id=pk_fin title="Al km" fmt=num1 />
    <Column id=imd title="Vehicles al dia" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=imd_pesados title="Pesants al dia" fmt=num0 />
    <Column id=pesados_pct title="% pesants" fmt=num1 />
    <Column id=anio title="Any" fmt="0" />
</DataTable>

## Per província

<ButtonGroup name=medida title="Mesurar">
    <ButtonGroupItem valueLabel="Km per 100 km² de superfície" value="km_por_100_km2" default />
    <ButtonGroupItem valueLabel="Km per 100.000 habitants" value="km_por_100k_hab" />
    <ButtonGroupItem valueLabel="Autovies i autopistes per 100 km²" value="km_gran_capacidad_por_100_km2" />
    <ButtonGroupItem valueLabel="Autovies i autopistes per 100.000 hab." value="km_gran_capacidad_por_100k_hab" />
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
        {id: 'km_por_100_km2', title: 'Per 100 km²', fmt: 'num1'},
        {id: 'km_por_100k_hab', title: 'Per 100.000 hab.', fmt: 'num0'},
        {id: 'km_gran_capacidad', title: 'Autovies, autopistes i multicarril', fmt: 'num0'},
        {id: 'km_peaje', title: 'De peatge', fmt: 'num0'}
    ]}
/>

```sql provincias_tabla
SELECT * FROM ${provincias} ORDER BY km_total DESC
```

<DataTable data={provincias_tabla} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=km_total title="Km" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=km_estado title="Estat" fmt=num0 />
    <Column id=km_comunidad title="Comunitat" fmt=num0 />
    <Column id=km_diputacion title="Diputació" fmt=num0 />
    <Column id=km_gran_capacidad title="Gran capacitat" fmt=num0 />
    <Column id=km_peaje title="Peatge" fmt=num0 />
    <Column id=km_por_100_km2 title="Per 100 km²" fmt=num1 />
    <Column id=km_por_100k_hab title="Per 100.000 hab." fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km de l'Anuari del Ministeri de Transports (les comunitats i les diputacions envien les dades amb un any de retard). Per superfície destaquen Galícia (Pontevedra, Lugo, la Corunya), amb una xarxa de diputació molt densa pels seus milers de llogarets, Gipuzkoa, Bizkaia i Tenerife; per habitant, les províncies grans i buides (Sòria, Terol, Conca, Zamora), on hi ha moltes carreteres per a molt poca gent.</p>

## Com ha crescut des de 1970

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
    title="Km de carretera segons qui la gestiona"
/>

<p class="text-xs text-gray-500">El 1984 l'Estat va traspassar a les comunitats autònomes bona part de la seva xarxa: per això passa d'uns 80.000 km a 20.000. Les carreteres de les diputacions només es compten des del 1990. Des d'aleshores el total gairebé no canvia (uns 165.000 km); el que creix són les autovies.</p>

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
    title="Km d'autopistes, autovies i multicarril per 100.000 habitants"
/>

## Davant d'Europa

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
    title="Km d'autopistes i autovies (darrer any publicat)"
/>

<BarChart
    data={europa.filter((d) => d.km_por_100k_hab > 0).toSorted((a, b) => b.km_por_100k_hab - a.km_por_100k_hab)}
    x=pais
    y=km_por_100k_hab
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c2410c"
    title="Km d'autopistes i autovies per 100.000 habitants"
/>

<BarChart
    data={europa.filter((d) => d.km_por_1000_km2 > 0).toSorted((a, b) => b.km_por_1000_km2 - a.km_por_1000_km2)}
    x=pais
    y=km_por_1000_km2
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a3412"
    title="Km d'autopistes i autovies per 1.000 km² de superfície"
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
    title="Km d'autopistes i autovies des de 1990"
/>

<p class="text-xs text-gray-500">Espanya té la xarxa d'autopistes i autovies més llarga de la UE i una de les més llargues per habitant. Per superfície està en la mitjana: el país és gran i té l'interior poc poblat. Eurostat compta com a autopista també les autovies; el darrer any publicat varia segons el país.</p>

---

## Fonts i notes

- **Km per titularitat i tipus de via: [Anuari Estadístic del Ministeri de Transports](https://otle.transportes.gob.es/datos-graficos-mapas/datos-anuales/capital-infraestructuras/infraestructura-basica/carretera/conjunto-redes-carreteras-estado-comunidades-autonomas-diputaciones-cabildos)**, a través de l'Observatori del Transport i la Logística (OTLE): per província des del 2012 i per a tot Espanya des del 1970. Les diputacions inclouen les forals basques, els cabildos de Canàries i els consells de les Balears.
- **Xarxa de l'Estat: [Catàleg de la Xarxa de Carreteres de l'Estat](https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras)** (Ministeri de Transports), amb el tipus de cada tram i si és de peatge.
- **Xarxes de comunitats, diputacions, cabildos i consells: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© col·laboradors d'OpenStreetMap, llicència ODbL), carreteres amb matrícula descarregades amb l'API Overpass. La titularitat es dedueix de la matrícula; els km oficials són els de l'Anuari.
- **Trànsit: IMD per tram de la xarxa de l'Estat** del visor [Hermes](https://hermes.transportes.gob.es/) del Ministeri de Transports (mapa de trànsit; darrer any publicat de cada carretera).
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: km d'autopistes per país (road_if_motorwa), població i superfície.

<LastRefreshed prefix="Dades actualitzades" />
