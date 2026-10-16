---
title: Errepideak
description: "Espainiako errepide guztien mapa, nork kudeatzen dituen (Estatua, autonomia-erkidegoak, aldundiak, kabildoak eta kontseiluak) eta zer motatakoak diren (ordainpeko autopistak, autobiak, errei anitzekoak eta konbentzionalak) arabera; Estatuaren sareko zati bakoitzetik egunero igarotzen diren autoak eta kamioiak; probintzia bakoitzeko km-ak biztanleko eta azalerako 1970etik, eta Europarekiko alderaketa."
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
        estado: 'Estatua',
        comunidad: 'Autonomia-erkidegoak',
        diputacion: 'Aldundiak, kabildoak eta kontseiluak'
    };
    const TIPO = {
        peaje: 'Ordainpeko autopistak',
        autovia: 'Doako autopistak eta autobiak',
        multicarril: 'Errei anitzeko errepideak',
        convencional: 'Errepide konbentzionalak'
    };
    const COLOR_TITULAR = { estado: '#dc2626', comunidad: '#2563eb', diputacion: '#a3a3a3' };
    const COLOR_TIPO = { peaje: '#7c3aed', autovia: '#f97316', multicarril: '#0f766e', convencional: '#a3a3a3' };
    // Grosor del trazo en el mapa de la red según el tipo de vía
    const GROSOR = { peaje: 4, autovia: 4, multicarril: 2.5, convencional: 1 };
    // Tramos de vehículos al día para el color del mapa de tráfico
    const TRAMOS = [[2000, '2.000 ibilgailu baino gutxiago egunean', '#fde68a'], [10000, '2.000 - 10.000', '#fbbf24'], [30000, '10.000 - 30.000', '#f97316'], [70000, '30.000 - 70.000', '#dc2626'], [Infinity, '70.000 baino gehiago', '#7e22ce']];
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

# 🛣️ Errepideak

Espainiako hiri arteko errepideen {formatNumber(espana[0]?.km_total, 0)} km, nork ordaintzen eta mantentzen dituen arabera: Estatuak, autonomia-erkidegoek edo aldundiek (Euskadiko foru-aldundiak, Kanariar uharteetako kabildoak eta Balearretako kontseiluak barne). Eta zein diren ordainpeko autopistak, doako autobiak edo errepide arruntak. Gainera, Estatuaren sareko zati bakoitzetik egunero zenbat ibilgailu igarotzen diren.

<Grid cols=4>
    <KpiCard
        title="Errepide-sarea"
        value={espana[0]?.km_total}
        formattedValue="{formatNumber(espana[0]?.km_total, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 0)} km 100.000 biztanleko, {espana[0]?.anio}an"
        source="Garraio Ministerioa"
    />
    <KpiCard
        title="Autopistak, autobiak eta errei anitzekoak"
        value={espana[0]?.km_gran_capacidad}
        formattedValue="{formatNumber(espana[0]?.km_gran_capacidad, 0)} km"
        period="{formatNumber(espana[0]?.km_gran_capacidad_por_100k_hab, 1)} km 100.000 biztanleko"
        source="Garraio Ministerioa"
    />
    <KpiCard
        title="Ordainpekoak"
        value={espana[0]?.km_peaje}
        formattedValue="{formatNumber(espana[0]?.km_peaje, 0)} km"
        period="ahalmen handiko sarearen % {formatNumber(espana[0]?.peaje_pct, 0)}; {formatNumber(espana[0]?.km_peaje_estado, 0)} km Estatuarenak"
        source="Garraio Ministerioa"
    />
    <KpiCard
        title="Trafiko gehien duen zatia"
        value={tramo_max[0]?.imd}
        formattedValue={formatNumber(tramo_max[0]?.imd, 0)}
        unit=" ibilgailu egunean"
        period="{tramo_max[0]?.carretera ?? ''} ({tramo_max[0]?.anio})"
        source="Garraio Ministerioa"
    />
</Grid>

## Mapa

<ButtonGroup name=vista title="Koloreztatu honen arabera">
    <ButtonGroupItem valueLabel="Nork kudeatzen duen" value="titular" default />
    <ButtonGroupItem valueLabel="Bide mota" value="tipo" />
</ButtonGroup>

<ButtonGroup name=filtro title="Erakutsi">
    <ButtonGroupItem valueLabel="Guztiak" value="todas" />
    <ButtonGroupItem valueLabel="Autopistak, autobiak eta errei anitzekoak soilik" value="gran_capacidad" default />
    <ButtonGroupItem valueLabel="Ordainpekoak soilik" value="peaje" />
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
        {id: 'titular_texto', title: 'Nork kudeatzen duen'},
        {id: 'tipo_texto', title: 'Mota'},
        {id: 'provincia', title: 'Probintzia'}
    ]}
/>

<p class="text-xs text-gray-500">Estatuaren sarea: Garraio Ministerioaren katalogo ofiziala (2025). Erkidegoak, aldundiak, kabildoak eta kontseiluak: OpenStreetMap, titulartasuna errepide bakoitzaren matrikulatik ondorioztatuta (CL- Gaztela eta Leongo Juntarena, BV- Bartzelonako Diputaciórena, DP- Galiziako aldundi batena...) eta ordainpeko tartea mapan markatuta; errepide solteren batean huts egin dezake. Euskadin errepide guztiak, A-8 eta AP-8 barne, foru-aldundienak dira, eta Nafarroan, Foru Erkidegoarenak. Ez daude udalen kaleak eta bideak (beste 360.000 km inguru, trafikoaren % 10 dutenak).</p>

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
    title="Errepide-km nork kudeatzen dituen eta bide motaren arabera ({km_titular_tipo[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estatuak km-en % {formatNumber(100 * espana[0]?.km_estado / espana[0]?.km_total, 0)} baino ez du kudeatzen, baina ia autobia eta autopista guztiak ditu, eta horiek dute trafikoaren erdia. Erkidegoek % {formatNumber(100 * espana[0]?.km_comunidad / espana[0]?.km_total, 0)} dute, eta aldundiek, kabildoek eta kontseiluek % {formatNumber(100 * espana[0]?.km_diputacion / espana[0]?.km_total, 0)}, ia guztiak errepide konbentzionalak.</p>

## Ordainpekoak

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
    <Column id=carretera title="Errepidea" />
    <Column id=titular_texto title="Nork kudeatzen duen" />
    <Column id=km title="Ordainpeko km-ak" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=provincias title="Probintziak" />
</DataTable>

<p class="text-xs text-gray-500">Ordainpeko km-ak Estatuaren katalogotik hartuta; gainerakoetan, OpenStreetMap-en neurtuta (gutxi gorabeherakoak: batzuetan bi galtzadak edo loturak zenbatzen dira). 2018 eta 2021 artean amaitzen ziren Estatuaren autopistak (AP-1, AP-4, AP-7 La Jonquera-Alacant tartea eta AP-2) doako autobia bihurtu ziren; ordainpekoak dira, besteak beste, AP-6, AP-9, AP-68 eta Madrilgo erradialak. Euskadiko foru-autopistak (AP-1, AP-8), Nafarroako AP-15, Generalitatekoak (C-16, C-32) eta Xuntakoak (AG-55, AG-57) beren gobernuek edo emakidadunek kobratzen dituzte.</p>

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
    title="Autopisten, autobien eta errei anitzeko errepideen km-ak 1970etik"
/>

<p class="text-xs text-gray-500">Lehen autopistak (1970eko hamarkadan) ordainpekoak izan ziren; 1980ko hamarkadatik aurrera, eraikitzen den ia guztia doako autobiak dira. Ordainpekoak 2017an 3.000 km inguru izatetik 2.000 km baino gutxiagora jaitsi ziren, Estatuaren autopista handien emakidak amaitu zirenean. 1985era arte serieak bost urtean behin ematen ditu datuak, eta 1990era arte ez ditu kontatzen aldundien errepideak.</p>

## Zati bakoitzetik zenbat ibilgailu igarotzen diren

<ButtonGroup name=vehiculos title="Ibilgailuak">
    <ButtonGroupItem valueLabel="Guztiak" value="imd" default />
    <ButtonGroupItem valueLabel="Astunak soilik (kamioiak eta autobusak)" value="imd_pesados" />
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
        {id: 'imd', title: 'Ibilgailuak egunean', fmt: 'num0'},
        {id: 'imd_pesados', title: 'Kamioiak eta autobusak egunean', fmt: 'num0'},
        {id: 'pesados_pct', title: 'Astunen %', fmt: 'num1'},
        {id: 'pk_inicio', title: 'Km honetatik', fmt: 'num1'},
        {id: 'pk_fin', title: 'Km honetara', fmt: 'num1'},
        {id: 'anio', title: 'Datuaren urtea', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Eguneko batez besteko intentsitatea (IMD): urteko egun arrunt batean igarotzen diren ibilgailuak, bi norabideak batuta, Ministerioak Estatuko Errepide Sarean dituen neurketa-geltokiek neurtuta. Lodiagoa = ibilgailu gehiago. Erkidegoek eta aldundiek beren neurketak aparte argitaratzen dituzte (edo ez dituzte argitaratzen), beraz haien sarea ez dago hemen; Ministerioaren arabera, Estatuaren sareatik trafikoaren % 53 eta kamioi-trafikoaren % 66 igarotzen da.</p>

```sql tramos_tabla
-- Tramos seguidos con la misma estación de aforo (misma IMD) en una sola fila
SELECT carretera, min(pk_inicio) AS pk_inicio, max(pk_fin) AS pk_fin, imd, max(imd_pesados) AS imd_pesados,
    max(pesados_pct) AS pesados_pct, anio
FROM mother.movilidad_carreteras_trafico
GROUP BY carretera, imd, anio
ORDER BY imd DESC
```

### Trafiko gehien duten zatiak

<DataTable data={tramos_tabla} rows=15 search=true>
    <Column id=carretera title="Errepidea" />
    <Column id=pk_inicio title="Km honetatik" fmt=num1 />
    <Column id=pk_fin title="Km honetara" fmt=num1 />
    <Column id=imd title="Ibilgailuak egunean" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=imd_pesados title="Astunak egunean" fmt=num0 />
    <Column id=pesados_pct title="% astunak" fmt=num1 />
    <Column id=anio title="Urtea" fmt="0" />
</DataTable>

## Probintziaka

<ButtonGroup name=medida title="Neurtu">
    <ButtonGroupItem valueLabel="Km 100 km²-ko azalerako" value="km_por_100_km2" default />
    <ButtonGroupItem valueLabel="Km 100.000 biztanleko" value="km_por_100k_hab" />
    <ButtonGroupItem valueLabel="Autobiak eta autopistak 100 km²-ko" value="km_gran_capacidad_por_100_km2" />
    <ButtonGroupItem valueLabel="Autobiak eta autopistak 100.000 biztanleko" value="km_gran_capacidad_por_100k_hab" />
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
        {id: 'km_total', title: 'Errepide-km-ak', fmt: 'num0'},
        {id: 'km_por_100_km2', title: '100 km²-ko', fmt: 'num1'},
        {id: 'km_por_100k_hab', title: '100.000 biztanleko', fmt: 'num0'},
        {id: 'km_gran_capacidad', title: 'Autobiak, autopistak eta errei anitzekoak', fmt: 'num0'},
        {id: 'km_peaje', title: 'Ordainpekoak', fmt: 'num0'}
    ]}
/>

```sql provincias_tabla
SELECT * FROM ${provincias} ORDER BY km_total DESC
```

<DataTable data={provincias_tabla} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=km_total title="Km" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=km_estado title="Estatua" fmt=num0 />
    <Column id=km_comunidad title="Erkidegoa" fmt=num0 />
    <Column id=km_diputacion title="Aldundia" fmt=num0 />
    <Column id=km_gran_capacidad title="Ahalmen handikoak" fmt=num0 />
    <Column id=km_peaje title="Ordainpekoak" fmt=num0 />
    <Column id=km_por_100_km2 title="100 km²-ko" fmt=num1 />
    <Column id=km_por_100k_hab title="100.000 biztanleko" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km-ak Garraio Ministerioaren Urtekarietatik hartuta (erkidegoek eta aldundiek urtebeteko atzerapenarekin bidaltzen dituzte datuak). Azaleraren arabera, nabarmentzen dira Galizia (Pontevedra, Lugo, A Coruña), mila auzune dituelako eta aldundien sarea oso trinkoa delako, Gipuzkoa, Bizkaia eta Tenerife; biztanleko, probintzia handi eta hutsak (Soria, Teruel, Cuenca, Zamora), jende oso gutxirentzat errepide asko dituztenak.</p>

## Nola hazi den 1970etik

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
    title="Errepide-km-ak nork kudeatzen dituen arabera"
/>

<p class="text-xs text-gray-500">1984an Estatuak bere sarearen zati handi bat autonomia-erkidegoei transferitu zien: horregatik jaisten da 80.000 km ingurutik 20.000ra. Aldundien errepideak 1990etik aurrera soilik kontatzen dira. Ordutik, guztizkoak ia ez du aldatu (165.000 km inguru); hazten direnak autobiak dira.</p>

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
    title="Autopisten, autobien eta errei anitzeko errepideen km-ak 100.000 biztanleko"
/>

## Europarekin alderatuta

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
    title="Autopisten eta autobien km-ak (argitaratutako azken urtea)"
/>

<BarChart
    data={europa.filter((d) => d.km_por_100k_hab > 0).toSorted((a, b) => b.km_por_100k_hab - a.km_por_100k_hab)}
    x=pais
    y=km_por_100k_hab
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c2410c"
    title="Autopisten eta autobien km-ak 100.000 biztanleko"
/>

<BarChart
    data={europa.filter((d) => d.km_por_1000_km2 > 0).toSorted((a, b) => b.km_por_1000_km2 - a.km_por_1000_km2)}
    x=pais
    y=km_por_1000_km2
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a3412"
    title="Autopisten eta autobien km-ak 1.000 km²-ko azalerako"
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
    title="Autopisten eta autobien km-ak 1990etik"
/>

<p class="text-xs text-gray-500">Espainiak EBko autopista- eta autobia-sarerik luzeena du, eta biztanleko luzeenetako bat. Azaleraren arabera, batez bestekoan dago: herrialdea handia da eta barnealdea oso gutxi populatuta dago. Eurostatek autopistatzat autobiak ere kontatzen ditu; argitaratutako azken urtea herrialdearen arabera aldatzen da.</p>

---

## Iturriak eta oharrak

- **Km-ak titulartasunaren eta bide motaren arabera: [Garraio Ministerioaren Urtekari Estatistikoa](https://otle.transportes.gob.es/datos-graficos-mapas/datos-anuales/capital-infraestructuras/infraestructura-basica/carretera/conjunto-redes-carreteras-estado-comunidades-autonomas-diputaciones-cabildos)**, Garraio eta Logistikaren Behatokiaren (OTLE) bidez: probintziaka 2012tik eta Espainia osoarentzat 1970etik. Aldundien artean daude Euskadiko foru-aldundiak, Kanariar uharteetako kabildoak eta Balearretako kontseiluak.
- **Estatuaren sarea: [Estatuko Errepide Sarearen Katalogoa](https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras)** (Garraio Ministerioa), zati bakoitzaren motarekin eta ordainpekoa den ala ez adierazita.
- **Erkidegoen, aldundien, kabildoen eta kontseiluen sareak: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© OpenStreetMapen laguntzaileak, ODbL lizentzia), matrikula duten errepideak, Overpass APIarekin deskargatuak. Titulartasuna matrikulatik ondorioztatzen da; km ofizialak Urtekariak ematen dituenak dira.
- **Trafikoa: Estatuaren sareko zati bakoitzaren IMD** Garraio Ministerioaren [Hermes](https://hermes.transportes.gob.es/) ikustailetik (trafiko-mapa; errepide bakoitzaren argitaratutako azken urtea).
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: herrialde bakoitzeko autopisten km-ak (road_if_motorwa), biztanleria eta azalera.

<LastRefreshed prefix="Datuak eguneratuta" />
