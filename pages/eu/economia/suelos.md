---
title: Nekazaritza-lurzoruak
description: "Zer lur dagoen Espainiako laboreen azpian: lurzoru buztintsuak, frankoak eta hareatsuak, lurzoru motak (kaltzisolak, kanbisolak, luvisolak, vertisolak...), pHa eta materia organikoa erkidego eta probintziaka, 10 km-ko mapa, zer lurzoru duten olibadiak, mahastiak, ureztatuak edo larre-basoak eta Europako gainerakoekin alderaketa."
i18n_origen: 7a1d0195aa79
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiketa ikusgaiak: hemen eta ez SQLan, itzulpen guztietan berdina baita.
    // Gakoak datuen balioak dira (gaztelaniaz).
    const CULTIVO = {
        'Toda la superficie agraria': 'Nekazaritza-azalera osoa',
        'Secano': 'Lehorreko laboreak',
        'Regadío': 'Ureztatua',
        'Arrozal': 'Arrozak',
        'Viñedo': 'Mahastia',
        'Frutales': 'Fruta-arbolak',
        'Olivar': 'Olibadia',
        'Prados': 'Belardiak',
        'Mosaico de cultivos': 'Labore-mosaikoa eta baratzeak',
        'Dehesa': 'Larre-basoak (dehesak)'
    };
    const GRUPO = {
        'Arenosa (ligera)': 'Hareatsua (lur arina)',
        'Franca (media)': 'Frankoa (lur ertaina)',
        'Franco-arcillosa': 'Franko-buztintsua (lur gogorra)',
        'Arcillosa (pesada)': 'Buztintsua (lur astuna)'
    };
    const TEXTURA = {
        'Arenosa': 'Hareatsua', 'Arenoso-franca': 'Hareatsu-frankoa', 'Franco-arenosa': 'Franko-hareatsua',
        'Franca': 'Frankoa', 'Franco-limosa': 'Franko-limotsua', 'Limosa': 'Limotsua',
        'Franco-arcillo-arenosa': 'Franko-buztintsu-hareatsua', 'Franco-arcillosa': 'Franko-buztintsua',
        'Franco-arcillo-limosa': 'Franko-buztintsu-limotsua', 'Arcillo-arenosa': 'Buztintsu-hareatsua',
        'Arcillo-limosa': 'Buztintsu-limotsua', 'Arcillosa': 'Buztintsua'
    };
    const PH = {
        'Muy ácido (< 5,5)': 'Oso azidoa (5,5 baino gutxiago)',
        'Ácido (5,5-6,5)': 'Azidoa (5,5etik 6,5era)',
        'Neutro (6,5-7,5)': 'Neutroa (6,5etik 7,5era)',
        'Básico (7,5-8,5)': 'Basikoa edo kareharritsua (7,5etik 8,5era)',
        'Muy básico (> 8,5)': 'Oso basikoa (8,5 baino gehiago)'
    };
    const WRB = {
        'Calcisoles': 'Kaltzisolak', 'Cambisoles': 'Kanbisolak', 'Luvisoles': 'Luvisolak', 'Leptosoles': 'Leptosolak',
        'Vertisoles': 'Vertisolak', 'Regosoles': 'Regosolak', 'Fluvisoles': 'Fluvisolak', 'Kastanozems': 'Kastanozemak',
        'Phaeozems': 'Phaeozemak', 'Gipsisoles': 'Gipsisolak', 'Arenosoles': 'Arenosolak', 'Umbrisoles': 'Unbrisolak',
        'Podzoles': 'Podzolak', 'Chernozems': 'Txernozemak', 'Gleysoles': 'Gleisolak', 'Solonchaks': 'Solontxakak',
        'Albeluvisoles': 'Albeluvisolak', 'Andosoles': 'Andosolak', 'Acrisoles': 'Akrisolak', 'Alisoles': 'Alisolak',
        'Histosoles': 'Histosolak', 'Planosoles': 'Planosolak', 'Stagnosoles': 'Stagnosolak', 'Solonetz': 'Solonetzak'
    };
    const et = (dic, v) => dic[v] ?? v;
    const COLOR_GRUPO = {
        'Arenosa (ligera)': '#f2d48f',
        'Franca (media)': '#c8955a',
        'Franco-arcillosa': '#9a5a34',
        'Arcillosa (pesada)': '#5b2a17'
    };
    const COLOR_TEXTURA = ['#fbe7b2', '#f5d995', '#efcb7c', '#d9ab6c', '#cfa064', '#c4935c', '#b07a49', '#a06a3f', '#915d36', '#7a4528', '#6a3820', '#5b2a17'];
    const COLOR_WRB = {
        'Calcisoles': '#f1e2a6', 'Cambisoles': '#e8a45f', 'Luvisoles': '#c4524b', 'Leptosoles': '#9ca3af',
        'Vertisoles': '#5b3f8c', 'Regosoles': '#e9c9a6', 'Fluvisoles': '#4f9fd1', 'Kastanozems': '#8b6b3e',
        'Phaeozems': '#6b4f2f', 'Gipsisoles': '#f7f3d0', 'Arenosoles': '#fde68a', 'Umbrisoles': '#57534e'
    };
    const COLOR_CULTIVO = {
        'Secano': '#facc15', 'Regadío': '#38bdf8', 'Arrozal': '#14b8a6', 'Viñedo': '#7e22ce', 'Frutales': '#f97316',
        'Olivar': '#65a30d', 'Prados': '#86efac', 'Mosaico de cultivos': '#d6d3d1', 'Dehesa': '#a16207'
    };
    const ORDEN_GRUPO = Object.keys(GRUPO);
    const ORDEN_PH = Object.keys(PH);

    const filas = (q) => Array.from(q ?? []);
    const etiquetar = (q, columna, f) => filas(q).map((d) => ({ ...d, [columna]: f(d) }));
    // Puntu-mapa: kategoria ikusgaia eta bere kolorea, aukeratutako geruzaren arabera
    function enRejilla(q, capa) {
        return filas(q).map((d) => {
            if (capa === 'wrb') return { ...d, categoria: et(WRB, d.wrb), color: COLOR_WRB[d.wrb] ?? '#cbd5e1' };
            if (capa === 'cultivo') return { ...d, categoria: et(CULTIVO, d.cultivo), color: COLOR_CULTIVO[d.cultivo] ?? '#cbd5e1' };
            return { ...d, categoria: et(GRUPO, d.textura_grupo), color: COLOR_GRUPO[d.textura_grupo] ?? '#cbd5e1' };
        }).filter((d) => d.categoria);
    }
</script>

```sql espana
SELECT * FROM mother.suelos_territorio
WHERE nivel = 'pais' AND cultivo = 'Toda la superficie agraria'
```

```sql europa
SELECT * FROM mother.suelos_europa ORDER BY materia_organica_pct
```

```sql europa_resumen
SELECT
    max(puesto_mo_menor) FILTER (WHERE cod_pais = 'ES') AS puesto_mo,
    max(puesto_ph_mayor) FILTER (WHERE cod_pais = 'ES') AS puesto_ph,
    max(paises) AS paises,
    sum(materia_organica_pct * superficie_agraria_km2) FILTER (WHERE es_ue) / sum(superficie_agraria_km2) FILTER (WHERE es_ue) AS mo_ue,
    sum(ph * superficie_agraria_km2) FILTER (WHERE es_ue) / sum(superficie_agraria_km2) FILTER (WHERE es_ue) AS ph_ue,
    sum(arcilla_pct * superficie_agraria_km2) FILTER (WHERE es_ue) / sum(superficie_agraria_km2) FILTER (WHERE es_ue) AS arcilla_ue,
    sum(pct_basico * superficie_agraria_km2) FILTER (WHERE es_ue) / sum(superficie_agraria_km2) FILTER (WHERE es_ue) AS basico_ue,
    sum(superficie_agraria_km2) FILTER (WHERE es_ue) AS km2_ue,
    string_agg(pais, ', ' ORDER BY materia_organica_pct) FILTER (WHERE puesto_mo_menor <= 3) AS menos_mo
FROM ${europa}
```

```sql clases_espana
SELECT dimension, clase, orden, superficie_km2, pct
FROM mother.suelos_clases
WHERE nivel = 'pais' AND cultivo = 'Toda la superficie agraria'
ORDER BY dimension, orden
```

# 🟫 Nekazaritza-lurzoruak

Zer lur dagoen Espainiako laboreen azpian: **buztintsua, frankoa edo hareatsua** den, zer **lurzoru mota** den, **kareharritsua edo azidoa** den eta zenbat **materia organiko** duen. Dena **nekazaritza-azaleraren** gainean neurtzen da ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} mila km², herrialdearen ia erdia), lantzen den geruzan, lehen 30 cm-etan, eta gainean landatzen denarekin gurutzatzen da. Datuak eredu batetik datoz (SoilGrids), ez lursail bakoitzaren analisietatik: eskualdeak, probintziak eta herrialdeak alderatzeko balio dute.

<Grid cols=4>
    <KpiCard
        title="Testura ohikoena"
        value={espana[0]?.pct_arcillosa}
        formattedValue={et(TEXTURA, espana[0]?.textura_dominante)}
        period="Nekazaritza-azaleraren {formatNumber(clases_espana.filter((d) => d.dimension === 'textura' && d.clase === espana[0]?.textura_dominante)[0]?.pct, 0)} % · batez besteko buztina: {formatNumber(espana[0]?.arcilla_pct, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="Nekazaritza-lurzoruaren batez besteko pHa"
        value={espana[0]?.ph}
        formattedValue={formatNumber(espana[0]?.ph, 1)}
        period="{formatNumber(espana[0]?.pct_basico, 0)} % basikoa edo kareharritsua (EB: {formatNumber(europa_resumen[0]?.basico_ue, 0)} %) · {formatNumber(espana[0]?.pct_acido, 0)} % azidoa"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Batez besteko materia organikoa"
        value={espana[0]?.materia_organica_pct}
        formattedValue="{formatNumber(espana[0]?.materia_organica_pct, 1)} %"
        period="EB: {formatNumber(europa_resumen[0]?.mo_ue, 1)} % · Espainia, gutxien duten {formatNumber(europa_resumen[0]?.puesto_mo, 0)}.a {formatNumber(europa_resumen[0]?.paises, 0)} herrialdetatik"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Lurzoru mota hedatuena"
        value={espana[0]?.pct_calcisoles}
        formattedValue={et(WRB, espana[0]?.wrb_dominante)}
        period="Nekazaritza-azaleraren {formatNumber(clases_espana.filter((d) => d.dimension === 'wrb' && d.clase === espana[0]?.wrb_dominante)[0]?.pct, 0)} % · kaltzisolak: {formatNumber(espana[0]?.pct_calcisoles, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC, WRB sailkapena)"
    />
</Grid>

## Mapa

<ButtonGroup name=capa title="Koloreztatu honen arabera">
    <ButtonGroupItem valueLabel="Testura" value="textura" default />
    <ButtonGroupItem valueLabel="Lurzoru mota" value="wrb" />
    <ButtonGroupItem valueLabel="pH" value="ph" />
    <ButtonGroupItem valueLabel="Materia organikoa" value="mo" />
    <ButtonGroupItem valueLabel="Laborea" value="cultivo" />
</ButtonGroup>

```sql rejilla
SELECT celda, lon, lat, provincia, superficie_agraria_km2, textura, textura_grupo, wrb, cultivo,
    arcilla_pct, ph, materia_organica_pct
FROM mother.suelos_rejilla
```

{#if String(inputs.capa?.value ?? inputs.capa) === 'ph'}

<MapaEspana
    data={rejilla}
    lat=lat
    long=lon
    value=ph
    valueFmt=num1
    min={5}
    max={8.3}
    colorPalette={['#b91c1c', '#fde68a', '#f5f5f4', '#93c5fd', '#1e3a8a']}
    pointName=provincia
    opacity={0.9}
    height={600}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'textura', title: 'Testura'},
        {id: 'wrb', title: 'Lurzoru mota'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km² gelaxkan', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Gorria: lurzoru azidoak (pH baxua), ipar-mendebalde euritsukoak eta mendebaldeko granito eta arbelezkoak. Urdina: lurzoru basikoak edo kareharritsuak (pH altua), Espainia lehor ia osokoak, lurpean kareharria edo igeltsua dutenak. pHak erabakitzen du zer labore datozen ondo (gaztainondoak edo ahabiak lur azidoa nahi dute; mahatsondoak, almendrondoak edo olibondoak kareharria jasaten dute) eta zenbat kare edo sufre bota behar den.</p>

{:else if String(inputs.capa?.value ?? inputs.capa) === 'mo'}

<MapaEspana
    data={rejilla}
    lat=lat
    long=lon
    value=materia_organica_pct
    valueFmt=num1
    min={1.5}
    max={8}
    colorPalette={['#fef3c7', '#bef264', '#16a34a', '#14532d']}
    pointName=provincia
    opacity={0.9}
    height={600}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Labore nagusia'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km² gelaxkan', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Zenbat eta berdeago, orduan eta materia organiko gehiago: iparraldeko belardiak, urte osoan euria, belarra eta simaurra dituztenak. Mesetako, Ebro ibarreko eta hego-ekialdeko lehorreko laboreek, beroarekin, euri gutxirekin eta mendeetako lanketarekin, Mendebaldeko Europako nekazaritza-lurzoru pobreena dute materia organikotan. SoilGridsek landa-analisiek baino karbono apur bat gehiago ematen du Mediterraneoko lehorretan: alderatu eremuak, eta ez hartu zifra analisi bat balitz bezala.</p>

{:else}

<MapaEspana
    data={enRejilla(rejilla, String(inputs.capa?.value ?? inputs.capa))}
    lat=lat
    long=lon
    value=categoria
    colorCol=color
    legendType=categorical
    pointName=provincia
    opacity={0.95}
    height={600}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'textura', title: 'Testura'},
        {id: 'arcilla_pct', title: 'Buztina (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Lurzoru mota'},
        {id: 'cultivo', title: 'Labore nagusia'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km² gelaxkan', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Puntu bakoitza 10 × 10 km-ko karratu bat da, gutxienez 5 km² nekazaritza-azalera dituena, eta bertan nekazaritza-azalera gehien hartzen duen testuraren, lurzoru motaren edo laborearen arabera koloreztatuta dago. Punturik ez dagoen tokian mendia, harkaitza, ura edo hiria dago.</p>

{/if}

## Buztintsuak, frankoak eta hareatsuak

**Testura** lurraren buztin, limo eta harea proportzioa da, eta nekazari batek begiratzen duen lehen gauza: lur **buztintsu** batek («gogorra» edo «astuna») ura eta mantenugaiak gordetzen ditu, baina urez gainezka geratzen da, arrakalatu egiten da eta lantzen zaila da; **hareatsu** bat («arina») erraz lantzen da eta udaberrian lehenago berotzen da, baina ura eta ongarria ihes egiten zaizkio; **frankoa**, hiru osagaiak orekatuta dituena, ia guztirako aproposa da. Espainiako nekazaritza-lurzoruak, batez beste, {formatNumber(espana[0]?.arcilla_pct, 0)} % buztin, {formatNumber(espana[0]?.limo_pct, 0)} % limo eta {formatNumber(espana[0]?.arena_pct, 0)} % harea ditu.

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'textura'), 'textura_texto', (d) => et(TEXTURA, d.clase))}
    x=textura_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a5a34"
    title="Nekazaritza-azalera USDAren testura-klasearen arabera (%)"
/>

{/if}

<p class="text-xs text-gray-500">AEBko Nekazaritza Sailaren (USDA) testura-triangeluko klaseak, Espainiako nekazaritza-laborategiek erabiltzen dituztenak. SoilGrids muturrak leuntzen dituen eredu bat da: oso lur buztintsuak (Guadalquivirko kanpiñako «bujeos» delakoak, Tierra de Camposeko «buztin-lurrak») franko-buztintsu gisa agertzen dira, eta oso hareatsuak, franko-hareatsu gisa. Horregatik dago buztin edo harea hutsezko klase gutxi, eta komeni da franko-buztintsuak eta buztintsuak batera irakurtzea, «lur gogor» gisa.</p>

## Lurzoru motak

Testuraz gain, edafologoek lurzoruak nola sortu diren kontuan hartuta sailkatzen dituzte. Nazioarteko sailkapenean (WRB, FAOrena), Espainiako nekazaritza-lurra batez ere **luvisolak** (buztina hondoan metatuta duten lurzoru zaharrak, Mantxako eta Extremadurako lur gorriak bezala), **kanbisolak** (lurzoru gazteak, gutxi eboluzionatuak), **kaltzisolak** (kareharri-geruza batekin, Espainia lehorrekoak), **leptosolak** (harkaitzaren gaineko lurzoru meheak, maldetan) eta **vertisolak** (urarekin puztu eta lehortzean arrakalatzen diren buztinak, Andaluziako kanpiñako «lur beltzak») dira.

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
    x=wrb_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c4524b"
    title="Nekazaritza-azalera lurzoru motaren arabera (WRB, %)"
/>

{/if}

## pHa eta materia organikoa

```sql ph_ccaa
SELECT c.nombre, c.clase, c.orden, c.pct, t.ph
FROM mother.suelos_clases c
JOIN mother.suelos_territorio t ON t.nivel = c.nivel AND t.cod = c.cod AND t.cultivo = c.cultivo
WHERE c.nivel = 'ccaa' AND c.cultivo = 'Toda la superficie agraria' AND c.dimension = 'ph'
    AND t.superficie_agraria_km2 >= 100
ORDER BY t.ph DESC, c.orden
```

Espainiako nekazaritza-lurraren {formatNumber(espana[0]?.pct_basico, 0)} % **basikoa edo kareharritsua** da (7,5eko edo gehiagoko pHa), EBko {formatNumber(europa_resumen[0]?.basico_ue, 0)} %aren aldean: lurpeko kareharriak eta igeltsuak eta gatzak garbitzen ez dituen euri urriak pHa igotzen dute. Kantauri itsasertzak, Galiziak eta mendebalde granitikoak eta arbeltsuak (Salamanca, Cáceres) bakarrik dituzte lurzoru azidoak.

{#if filas(ph_ccaa).length > 0}

<BarChart
    data={etiquetar(ph_ccaa, 'ph_texto', (d) => et(PH, d.clase))}
    x=nombre
    y=pct
    series=ph_texto
    type=stacked100
    swapXY=true
    sort=false
    seriesOrder={ORDEN_PH.map((k) => PH[k])}
    colorPalette={['#b91c1c', '#f59e0b', '#d6d3d1', '#60a5fa', '#1e3a8a']}
    title="Nekazaritza-azalera lurzoruaren pHaren arabera, erkidegoka"
/>

{/if}

**Materia organikoak** (deskonposatutako landare-hondarrak, sustraiak eta simaurra) egitura ematen dio lurrari, ura atxikitzen du eta laboreak elikatzen ditu. Beroarekin, euri gutxirekin eta mendeetako lanketarekin, Espainiako nekazaritza-lurzoruak batez beste {formatNumber(espana[0]?.materia_organica_pct, 1)} % du, EBko {formatNumber(europa_resumen[0]?.mo_ue, 1)} %aren aldean. Alderatutako {formatNumber(europa_resumen[0]?.paises, 0)} Europako herrialdeetatik {formatNumber(europa_resumen[0]?.puesto_mo, 0)}. pobreena da (gutxien dutenak: {europa_resumen[0]?.menos_mo ?? '-'}).

## Erkidego eta probintziaka

<ButtonGroup name=medida title="Neurtu">
    <ButtonGroupItem valueLabel="Lur buztintsuen edo franko-buztintsuen %" value="fuertes" default />
    <ButtonGroupItem valueLabel="Batez besteko buztina (%)" value="arcilla_pct" />
    <ButtonGroupItem valueLabel="Batez besteko pHa" value="ph" />
    <ButtonGroupItem valueLabel="Lurzoru basiko edo kareharritsuaren %" value="pct_basico" />
    <ButtonGroupItem valueLabel="Batez besteko materia organikoa (%)" value="materia_organica_pct" />
    <ButtonGroupItem valueLabel="Kaltzisolen %" value="pct_calcisoles" />
</ButtonGroup>

```sql fuertes
SELECT nivel, cod, sum(pct) AS pct_fuertes
FROM mother.suelos_clases
WHERE cultivo = 'Toda la superficie agraria' AND dimension = 'textura_grupo'
    AND clase IN ('Franco-arcillosa', 'Arcillosa (pesada)') AND nivel IN ('ccaa', 'provincia')
GROUP BY nivel, cod
```

```sql provincias
SELECT t.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.limo_pct,
    t.arena_pct, t.ph, t.materia_organica_pct, t.textura_dominante, t.wrb_dominante,
    coalesce(t.pct_basico, 0) AS pct_basico, coalesce(t.pct_calcisoles, 0) AS pct_calcisoles,
    coalesce(f.pct_fuertes, 0) AS fuertes
FROM mother.suelos_territorio t
LEFT JOIN ${fuertes} f ON f.nivel = t.nivel AND f.cod = t.cod
WHERE t.nivel = 'provincia' AND t.cultivo = 'Toda la superficie agraria' AND t.cod NOT IN ('51', '52')
ORDER BY t.superficie_agraria_km2 DESC
```

```sql provincias_mapa
SELECT *, ${inputs.medida} AS medida FROM ${provincias}
```

<MapaEspana
    data={provincias_mapa}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="medida"
    valueFmt="num1"
    colorPalette={['#fdf6e3', '#c8955a', '#5b2a17']}
    link=ruta
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km²', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Testura ohikoena'},
        {id: 'arcilla_pct', title: 'Buztina (%)', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Lurzoru mota'}
    ]}
/>

```sql ccaa
SELECT t.nombre AS comunidad, '/eu' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.arena_pct, t.ph,
    t.materia_organica_pct, t.textura_dominante, t.wrb_dominante, coalesce(t.pct_basico, 0) AS pct_basico,
    coalesce(f.pct_fuertes, 0) AS fuertes
FROM mother.suelos_territorio t
LEFT JOIN ${fuertes} f ON f.nivel = t.nivel AND f.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.cultivo = 'Toda la superficie agraria' AND t.superficie_agraria_km2 >= 100
ORDER BY t.superficie_agraria_km2 DESC
```

<DataTable data={ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=superficie_agraria_km2 title="Nekazaritza-km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Testura ohikoena" />
    <Column id=fuertes title="% lur gogorrak" fmt=num0 />
    <Column id=arcilla_pct title="Buztina (%)" fmt=num0 />
    <Column id=arena_pct title="Harea (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% basikoa" fmt=num0 />
    <Column id=materia_organica_pct title="Materia organikoa (%)" fmt=num1 />
    <Column id=wrb_dominante title="Lurzoru mota" />
</DataTable>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=superficie_agraria_km2 title="Nekazaritza-km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Testura ohikoena" />
    <Column id=fuertes title="% lur gogorrak" fmt=num0 />
    <Column id=arcilla_pct title="Buztina (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Materia organikoa (%)" fmt=num1 />
    <Column id=wrb_dominante title="Lurzoru mota" />
</DataTable>

<p class="text-xs text-gray-500">Lur gogorrak = USDAren triangeluko sei testura franko-buztintsu eta buztintsuak (oro har, laurden bat baino buztin gehiago). Arabak, Nafarroak, Errioxak, Malagako, Cádizko, Jaéngo eta Sevillako kanpiñek eta Ebro ibarrak dituzte lur gogorrenak; Galiziak, Cácereseko, Leongo eta Badajozko probintziek, arinenak, granito eta arbel gainean. Ceutak eta Melillak ia ez dute nekazaritza-azalerarik.</p>

## Zer lurzoru duen labore bakoitzak

Nekazaritza-azalera CORINE 2018 lurzoru-erabileren maparen arabera banatzen da. Labore bakoitzak lur mota bat hartzen du: larre-basoak, mendebaldeko lurzoru hareatsu eta azidoetan; olibadiak eta ureztatuak, ibarretako lur buztintsuenetan; mahastiak, lurzoru kareharritsuenetan eta pobreenetan.

```sql lista_territorios
SELECT nivel || '-' || cod AS clave, nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.suelos_territorio
WHERE cultivo = 'Toda la superficie agraria' AND nivel IN ('pais', 'ccaa') AND superficie_agraria_km2 >= 100
```

<Dropdown name=territorio data={lista_territorios} value=clave label=nombre title="Lurraldea" order="orden, nombre" defaultValue="pais-00" />

```sql cultivos
SELECT cultivo, superficie_agraria_km2, pct_de_la_agraria, arcilla_pct, arena_pct, ph, materia_organica_pct,
    textura_dominante, wrb_dominante, coalesce(pct_basico, 0) AS pct_basico, coalesce(pct_arcillosa, 0) AS pct_arcillosa
FROM mother.suelos_territorio
WHERE nivel || '-' || cod = '${inputs.territorio.value}' AND cultivo <> 'Toda la superficie agraria'
    AND superficie_agraria_km2 >= 1
ORDER BY superficie_agraria_km2 DESC
```

```sql cultivos_textura
SELECT c.cultivo, c.clase, c.orden, c.pct, t.superficie_agraria_km2
FROM mother.suelos_clases c
JOIN mother.suelos_territorio t ON t.nivel = c.nivel AND t.cod = c.cod AND t.cultivo = c.cultivo
WHERE c.nivel || '-' || c.cod = '${inputs.territorio.value}' AND c.dimension = 'textura_grupo'
    AND c.cultivo <> 'Toda la superficie agraria' AND t.superficie_agraria_km2 >= 1
ORDER BY t.superficie_agraria_km2 DESC, c.orden
```

{#if filas(cultivos).length > 0 && filas(cultivos_textura).length > 0}

<BarChart
    data={etiquetar(etiquetar(cultivos_textura, 'grupo_texto', (d) => et(GRUPO, d.clase)), 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))}
    x=cultivo_texto
    y=pct
    series=grupo_texto
    type=stacked100
    swapXY=true
    sort=false
    seriesOrder={ORDEN_GRUPO.map((k) => GRUPO[k])}
    colorPalette={ORDEN_GRUPO.map((k) => COLOR_GRUPO[k])}
    title="Labore bakoitzaren lurzoruaren testura"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Laborea" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_de_la_agraria title="Nekazaritza-azaleraren %" fmt=num1 />
    <Column id=textura_dominante title="Testura ohikoena" />
    <Column id=arcilla_pct title="Buztina (%)" fmt=num0 />
    <Column id=arena_pct title="Harea (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% basikoa" fmt=num0 />
    <Column id=materia_organica_pct title="Materia organikoa (%)" fmt=num1 />
    <Column id=wrb_dominante title="Lurzoru mota" />
</DataTable>

{/if}

<p class="text-xs text-gray-500">CORINE Land Cover 2018ko laboreak: lehorrekoak = ureztatu gabeko lur landuak (zereala, ekilorea, lekaleak); ureztatua = etengabe ureztatutako lur landuak (artoa, barazkiak, kotoia...); fruta-arboletan sartzen dira zitrikoak, almendrondoak eta fruitu lehorrak; mosaikoa = labore desberdinetako lursail txiki nahasiak, baratzeak eta landaretza naturalarekin nahasitako laboreak; larre-basoa (dehesa) = artadi edo artelatz-basoa, azpian larrea edo laborea duena. CORINEk ez ditu 25 ha baino gutxiagoko lursailak marrazten; inguruan dutenari gehitzen zaizkio.</p>

## Europarekin alderatuta

Metodo bera herrialde guztientzat: SoilGrids eredua CORINE 2018ko nekazaritza-azaleraren gainean.

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(europa, 'grupo', (d) => (d.cod_pais === 'ES' ? 'Espainia' : d.es_ue ? 'EB' : 'Europako gainerakoak'))}
    x=pais
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['Espainia', 'EB', 'Europako gainerakoak']}
    colorPalette={['#c2410c', '#a8a29e', '#d6d3d1']}
    title="Nekazaritza-lurzoruaren batez besteko materia organikoa (%)"
/>

{/if}

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(filas(europa).toSorted((a, b) => b.ph - a.ph), 'grupo', (d) => (d.cod_pais === 'ES' ? 'Espainia' : d.es_ue ? 'EB' : 'Europako gainerakoak'))}
    x=pais
    y=ph
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    yMin={4}
    seriesOrder={['Espainia', 'EB', 'Europako gainerakoak']}
    colorPalette={['#1e3a8a', '#a8a29e', '#d6d3d1']}
    title="Nekazaritza-lurzoruaren batez besteko pHa"
/>

{/if}

<DataTable data={europa} rows=12 search=true>
    <Column id=pais title="Herrialdea" />
    <Column id=superficie_agraria_km2 title="Nekazaritza-km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Testura ohikoena" />
    <Column id=arcilla_pct title="Buztina (%)" fmt=num0 />
    <Column id=arena_pct title="Harea (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% basikoa" fmt=num0 />
    <Column id=materia_organica_pct title="Materia organikoa (%)" fmt=num1 />
    <Column id=wrb_dominante title="Lurzoru mota" />
</DataTable>

<p class="text-xs text-gray-500">Zipre, Grezia, Espainia, Italia eta Turkia dira nekazaritza-lurzoru basikoenak dituztenak, eta {europa_resumen[0]?.menos_mo ?? '-'}, materia organiko gutxien dutenak; iparraldeak (Irlanda, herrialde nordikoak, Erresuma Batua, Herbehereak) ditu azidoenak eta organikoenak, belardi hezeekin eta, batzuetan, zohikatzarekin. CORINEn gutxienez 1.000 nekazaritza-km² dituzten herrialdeak (Malta gabe). Europako LUCAS programaren (JRC) laborategi-laginekin egindako alderaketa egiteke dago: haren datuak eskaera bidez bakarrik ematen dira.</p>

## Iturriak eta oharrak

- **Lurzorua: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, CC BY 4.0 lizentzia). Buztina, limoa eta harea, uretako pHa eta karbono organikoa 0-5, 5-15 eta 15-30 cm-ko geruzetan (1 km-ko batez bestekoak), lodieraren arabera batez bestekoa eginda; WRB lurzoru-talde probableena. Ikaskuntza automatikoko eredu bat da, milaka lurzoru-profilekin eta satelite-, klima- eta erliebe-mapekin entrenatua: muturrak leuntzen ditu eta eskualde jakin batean huts egin dezake. Materia organikoa = karbono organikoa × 1,724.
- **Nekazaritza-azalera eta laboreak: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, Europako Ingurumen Agentzia), nekazaritza-klaseak (2xx), 250 m-tik behin laginduak.
- **Mugak: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) herrialdeentzat eta IGN probintzientzat.
- Dena 1 × 1 km-ko sare batean kalkulatzen da, azalera berdineko proiekzio batean (ETRS89-LAEA), beraz km² bakoitzak pisu bera du. Lurzoru-mapek ez dute serie historikorik: egungo lurzoruaren argazki bat dira.

<LastRefreshed prefix="Datuak eguneratuta" />
