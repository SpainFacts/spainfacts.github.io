---
title: Nekazaritza-lurzoruak
description: "Zer lur dagoen Espainiako laboreen azpian: lurzoru buztintsuak, frankoak eta hareatsuak, lurzoru motak (kaltzisolak, kanbisolak, luvisolak, vertisolak...), pHa eta materia organikoa erkidego, probintzia eta udalerrika, 10 km-ko mapa, zer lurzoru duten olibadiak, mahastiak, ureztatuak edo larre-basoak eta Europako gainerakoekin alderaketa."
i18n_origen: 4d7659092fda
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import MapaBarrios from '../../../../../../../src/lib/components/MapaBarrios.svelte';
    import { celdasMunicipio } from '../../../../../../../src/lib/suelos.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import FiltroTerritorio from '../../../../../../../src/lib/components/FiltroTerritorio.svelte';
    import BotonesUrl from '../../../../../../../src/lib/components/BotonesUrl.svelte';
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

    // Lurralde-iragazkiaren eta botoien testuak (orrialde bakoitzean itzultzen dira)
    const ETIQUETAS_FILTRO = {
        comunidad: 'Autonomia-erkidegoa',
        todaEspana: 'Espainia osoa',
        provincia: 'Probintzia',
        todaComunidad: 'Erkidego osoa',
        municipio: 'Udalerria',
        todaProvincia: 'Probintzia osoa'
    };
    const CAPAS = [
        { value: 'textura', label: 'Testura' },
        { value: 'wrb', label: 'Lurzoru mota' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Materia organikoa' },
        { value: 'cultivo', label: 'Laborea' }
    ];
    const MEDIDAS = [
        { value: 'pct_fuertes', label: 'Lur gogorren %' },
        { value: 'arcilla_pct', label: 'Batez besteko buztina (%)' },
        { value: 'ph', label: 'Batez besteko pHa' },
        { value: 'pct_basico', label: 'Basiko edo kareharritsuaren %' },
        { value: 'materia_organica_pct', label: 'Materia organikoa (%)' },
        { value: 'pct_calcisoles', label: 'Kaltzisolen %' },
        { value: 'pct_agraria', label: 'Nekazaritza-azaleraren %' }
    ];
    const ORDEN_TEXTURA = Object.keys(TEXTURA);

    // Europako mapa: puntu-maparen geruza eta eskualde-maparen neurria (URLko parametroarekin)
    const CAPAS_EU = [
        { value: 'textura', label: 'Testura' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Materia organikoa' }
    ];
    const MEDIDAS_EU = [
        { value: 'materia_organica_pct', label: 'Materia organikoa (eredua)' },
        { value: 'lucas_materia_organica_pct', label: 'Neurtutako materia organikoa (LUCAS)' },
        { value: 'ph', label: 'pH' },
        { value: 'pct_fuertes', label: 'Lur gogorren %' },
        { value: 'erosion_t_ha', label: 'Higadura (t/ha urteko)' },
        { value: 'pct_erosion_moderada_grave', label: 'Higadura ertaina edo larria duenaren %' }
    ];
    // Labore bakoitzaren azaleraren banaketa lau testura-taldeetan, ehunekoetatik abiatuta
    function gruposPorCultivo(q) {
        return filas(q).filter((d) => d.pct_fuertes !== null && d.pct_fuertes !== undefined).flatMap((d) => {
            const fuertes = d.pct_fuertes ?? 0, arcillosa = d.pct_arcillosa ?? 0, arenosa = d.pct_arenosa ?? 0;
            const partes = {
                'Arenosa (ligera)': arenosa,
                'Franca (media)': Math.max(0, 100 - fuertes - arenosa),
                'Franco-arcillosa': Math.max(0, fuertes - arcillosa),
                'Arcillosa (pesada)': arcillosa
            };
            return Object.entries(partes).map(([g, pct]) => ({ cultivo_texto: et(CULTIVO, d.cultivo), grupo_texto: et(GRUPO, g), pct }));
        });
    }
    // Mapen GeoJSONa eta poligono-iragazkia, aukeratutako lurraldearen arabera
    const geoDe = (t) => {
        const ccaa = t?.nivel === 'ccaa' ? t.cod : t?.cod_ccaa;
        return !t || t.nivel === 'pais' || !ccaa ? undefined : `/geo/municipios/${ccaa}.geojson`;
    };
    const filtroDe = (t) => (t?.nivel === 'provincia' ? { cod_prov: t.cod } : t?.nivel === 'municipio' ? { cod_mun: t.cod } : undefined);
    // Celdas de 250 m del municipio elegido (fichero estático, ver tools/geo/suelos250.py)
    let celdas = [];
    $: cargarCeldas(terr?.[0]?.nivel === 'municipio' ? terr[0].cod : null);
    function cargarCeldas(cod) {
        if (!cod) { celdas = []; return; }
        celdasMunicipio(cod).then((f) => { if (terr?.[0]?.cod === cod) celdas = f; });
    }
</script>

```sql lista_territorios
SELECT nivel, cod, nombre, slug, cod_ccaa FROM mother.territorios WHERE nivel IN ('ccaa', 'provincia')
```

```sql lista_municipios
SELECT cod_mun, municipio, cod_prov FROM mother.suelos_municipio
WHERE cultivo = 'Toda la superficie agraria' AND municipio IS NOT NULL
```

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

# 🟫 Nekazaritza-lurzoruak

Zer lur dagoen laboreen azpian: **buztintsua, frankoa edo hareatsua** den, zer **lurzoru mota** den, **kareharritsua edo azidoa** den eta zenbat **materia organiko** duen. Dena **nekazaritza-azaleraren** gainean neurtzen da ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} mila km² Espainian, herrialdearen ia erdia), lantzen den geruzan, lehen 30 cm-etan, eta gainean landatzen denarekin gurutzatzen da. Aukeratu erkidego, probintzia edo udalerri bat, eta orrialde osoa, mapak barne, lurralde horretara pasatuko da; orrialdearen esteka zure aukeraren arabera aldatzen da, partekatu ahal izateko. Datuak eredu batetik datoz (SoilGrids), ez lursail bakoitzaren analisietatik: eremuak alderatzeko balio dute.

<FiltroTerritorio territorios={lista_territorios} municipios={lista_municipios} name="territorio" etiquetas={ETIQUETAS_FILTRO} />

```sql sel
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT s.nivel, s.cod, s.nombre, s.cod_ccaa, s.cultivo, s.superficie_agraria_km2, s.pct_agraria, s.pct_de_la_agraria,
    s.arcilla_pct, s.limo_pct, s.arena_pct, s.ph, s.materia_organica_pct, s.textura_dominante, s.wrb_dominante,
    s.pct_fuertes, s.pct_arcillosa, s.pct_arenosa, s.pct_basico, s.pct_acido, s.pct_calcisoles
FROM mother.suelos_territorio s, f
WHERE s.nivel = f.nivel AND s.cod = f.cod
UNION ALL
SELECT 'municipio', m.cod_mun, m.municipio, m.cod_ccaa, m.cultivo, m.superficie_agraria_km2, m.pct_agraria, m.pct_de_la_agraria,
    m.arcilla_pct, m.limo_pct, m.arena_pct, m.ph, m.materia_organica_pct, m.textura_dominante, m.wrb_dominante,
    m.pct_fuertes, m.pct_arcillosa, m.pct_arenosa, m.pct_basico, m.pct_acido, m.pct_calcisoles
FROM mother.suelos_municipio m, f
WHERE f.nivel = 'municipio' AND m.cod_mun = f.cod
```

```sql terr
SELECT * FROM ${sel} WHERE cultivo = 'Toda la superficie agraria'
```

```sql dist
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT c.dimension, c.clase, c.pct
FROM mother.suelos_clases c, f
WHERE c.nivel = f.nivel AND c.cod = f.cod AND c.cultivo = 'Toda la superficie agraria' AND f.nivel <> 'municipio'
UNION ALL
SELECT c.dimension, c.clase, c.pct
FROM mother.suelos_municipio_clases c, f
WHERE f.nivel = 'municipio' AND c.cod_mun = f.cod
```

{#if filas(terr).length > 0}

## {terr[0]?.nivel === 'pais' ? 'Espainia' : terr[0]?.nombre}

<Grid cols=4>
    <KpiCard
        title="Nekazaritza-azalera"
        value={terr[0]?.pct_agraria}
        formattedValue="{formatNumber(terr[0]?.pct_agraria, 0)} %"
        period="lurraldearena · {formatNumber(terr[0]?.superficie_agraria_km2, 0)} km² · Espainia: {formatNumber(espana[0]?.pct_agraria, 0)} %"
        direction="neutral"
        source="CORINE Land Cover 2018"
    />
    <KpiCard
        title="Lur gogorrak (franko-buztintsuak eta buztintsuak)"
        value={terr[0]?.pct_fuertes}
        formattedValue="{formatNumber(terr[0]?.pct_fuertes, 0)} %"
        period="testura ohikoena: {et(TEXTURA, terr[0]?.textura_dominante)} · Espainia: {formatNumber(espana[0]?.pct_fuertes, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="Nekazaritza-lurzoruaren batez besteko pHa"
        value={terr[0]?.ph}
        formattedValue={formatNumber(terr[0]?.ph, 1)}
        period="{formatNumber(terr[0]?.pct_basico, 0)} % basikoa edo kareharritsua · {terr[0]?.nivel === 'pais' ? 'EB: ' + formatNumber(europa_resumen[0]?.basico_ue, 0) + ' %' : 'Espainia: pH ' + formatNumber(espana[0]?.ph, 1)}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Batez besteko materia organikoa"
        value={terr[0]?.materia_organica_pct}
        formattedValue="{formatNumber(terr[0]?.materia_organica_pct, 1)} %"
        period="{terr[0]?.nivel === 'pais' ? 'EB: ' + formatNumber(europa_resumen[0]?.mo_ue, 1) + ' % · Espainia, gutxien duten ' + formatNumber(europa_resumen[0]?.puesto_mo, 0) + '.a ' + formatNumber(europa_resumen[0]?.paises, 0) + ' herrialdetatik' : 'Espainia: ' + formatNumber(espana[0]?.materia_organica_pct, 1) + ' %'} · lurzoru mota: {et(WRB, terr[0]?.wrb_dominante)}{filas(lucas_terr).length ? ' · LUCAS: ' + formatNumber(lucas_terr[0]?.materia_organica_pct, 1) + ' %' : ''}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
</Grid>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">CORINE 2018 lurzoru-erabileren mapak ez du nekazaritza-azalerarik markatzen lurralde honetan.</p>

{/if}

## Puntu-mapa

<BotonesUrl name="capa" titulo="Koloreztatu honen arabera" opciones={CAPAS} defecto="textura" />

```sql puntos
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT r.celda, r.celda_km, r.lon, r.lat, r.provincia AS lugar, r.superficie_agraria_km2, r.textura, r.textura_grupo, r.wrb,
    r.cultivo, r.arcilla_pct, r.ph, r.materia_organica_pct
FROM mother.suelos_rejilla r, f
WHERE (f.nivel = 'pais' AND r.escala = 'espana')
    OR (f.nivel = 'ccaa' AND r.escala = 'ccaa' AND r.cod_ccaa = f.cod)
    OR (f.nivel = 'provincia' AND r.escala = 'provincia' AND r.cod_prov = f.cod)
```

{#if filas(puntos).length > 0 || celdas.length > 0}

{#if String(inputs.capa?.value ?? inputs.capa) === 'ph'}

{#if terr[0]?.nivel === 'municipio'}

<MapaBarrios
    data={celdas}
    lat=lat
    long=lon
    value=ph
    valueFmt=num1
    min={5}
    max={8.3}
    colorPalette={['#b91c1c', '#fde68a', '#f5f5f4', '#93c5fd', '#1e3a8a']}
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    celdaKm={0.25}
    height={600}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'textura', title: 'Testura'},
        {id: 'wrb', title: 'Lurzoru mota'}
    ]}
/>

{:else}

<MapaEspana
    data={puntos}
    lat=lat
    long=lon
    value=ph
    valueFmt=num1
    min={5}
    max={8.3}
    colorPalette={['#b91c1c', '#fde68a', '#f5f5f4', '#93c5fd', '#1e3a8a']}
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    celdaKm={puntos[0]?.celda_km}
    pointName=lugar
    opacity={0.9}
    height={600}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'textura', title: 'Testura'},
        {id: 'wrb', title: 'Lurzoru mota'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km² gelaxkan', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Gorria: lurzoru azidoak (pH baxua), ipar-mendebalde euritsukoak eta mendebaldeko granito eta arbelezkoak. Urdina: lurzoru basikoak edo kareharritsuak (pH altua), Espainia lehor ia osokoak, lurpean kareharria edo igeltsua dutenak. pHak erabakitzen du zer labore datozen ondo (gaztainondoak edo ahabiak lur azidoa nahi dute; mahatsondoak, almendrondoak edo olibondoak kareharria jasaten dute) eta zenbat kare edo sufre bota behar den.</p>

{:else if String(inputs.capa?.value ?? inputs.capa) === 'mo'}

{#if terr[0]?.nivel === 'municipio'}

<MapaBarrios
    data={celdas}
    lat=lat
    long=lon
    value=materia_organica_pct
    valueFmt=num1
    min={1.5}
    max={8}
    colorPalette={['#fef3c7', '#bef264', '#16a34a', '#14532d']}
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    celdaKm={0.25}
    height={600}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Labore nagusia'}
    ]}
/>

{:else}

<MapaEspana
    data={puntos}
    lat=lat
    long=lon
    value=materia_organica_pct
    valueFmt=num1
    min={1.5}
    max={8}
    colorPalette={['#fef3c7', '#bef264', '#16a34a', '#14532d']}
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    celdaKm={puntos[0]?.celda_km}
    pointName=lugar
    opacity={0.9}
    height={600}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Labore nagusia'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km² gelaxkan', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Zenbat eta berdeago, orduan eta materia organiko gehiago: iparraldeko belardiak, urte osoan euria, belarra eta simaurra dituztenak. Mesetako, Ebro ibarreko eta hego-ekialdeko lehorreko laboreek, beroarekin, euri gutxirekin eta mendeetako lanketarekin, Mendebaldeko Europako nekazaritza-lurzoru pobreena dute materia organikotan. SoilGridsek landa-analisiek baino karbono apur bat gehiago ematen du Mediterraneoko lehorretan: alderatu eremuak, eta ez hartu zifra analisi bat balitz bezala.</p>

{:else}

{#if terr[0]?.nivel === 'municipio'}

<MapaBarrios
    data={enRejilla(celdas, String(inputs.capa?.value ?? inputs.capa))}
    lat=lat
    long=lon
    value=categoria
    colorCol=color
    legendType=categorical
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    celdaKm={0.25}
    height={600}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'textura', title: 'Testura'},
        {id: 'arcilla_pct', title: 'Buztina (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Lurzoru mota'},
        {id: 'cultivo', title: 'Labore nagusia'}
    ]}
/>

{:else}

<MapaEspana
    data={enRejilla(puntos, String(inputs.capa?.value ?? inputs.capa))}
    lat=lat
    long=lon
    value=categoria
    colorCol=color
    legendType=categorical
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    celdaKm={puntos[0]?.celda_km}
    pointName=lugar
    opacity={0.95}
    height={600}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'textura', title: 'Testura'},
        {id: 'arcilla_pct', title: 'Buztina (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Lurzoru mota'},
        {id: 'cultivo', title: 'Labore nagusia'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km² gelaxkan', fmt: 'num1'}
    ]}
/>

{/if}

{/if}

<p class="text-xs text-gray-500">Puntu bakoitza nekazaritza-azalera duen karratu bat da (10 km-koa Espainia osorako, 5 km-koa erkidego batean, 2 km-koa probintzia batean eta 250 m-koa udalerri batean), eta bertan nekazaritza-azalera gehien hartzen duen testuraren, lurzoru motaren edo laborearen arabera koloreztatuta dago. Punturik ez dagoen tokian mendia, harkaitza, ura edo hiria dago.</p>

{/if}

## Buztintsuak, frankoak eta hareatsuak

**Testura** lurraren buztin, limo eta harea proportzioa da, eta nekazari batek begiratzen duen lehen gauza: lur **buztintsu** batek («gogorra» edo «astuna») ura eta mantenugaiak gordetzen ditu, baina urez gainezka geratzen da, arrakalatu egiten da eta lantzen zaila da; **hareatsu** bat («arina») erraz lantzen da eta udaberrian lehenago berotzen da, baina ura eta ongarria ihes egiten zaizkio; **frankoa**, hiru osagaiak orekatuta dituena, ia guztirako aproposa da. Lurralde honetako ({terr[0]?.nivel === 'pais' ? 'Espainia' : (terr[0]?.nombre ?? '-')}) nekazaritza-lurzoruak, batez beste, {formatNumber(terr[0]?.arcilla_pct, 0)} % buztin, {formatNumber(terr[0]?.limo_pct, 0)} % limo eta {formatNumber(terr[0]?.arena_pct, 0)} % harea ditu.

{#if filas(dist).filter((d) => d.dimension === 'textura').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'textura').toSorted((a, b) => ORDEN_TEXTURA.indexOf(a.clase) - ORDEN_TEXTURA.indexOf(b.clase)), 'textura_texto', (d) => et(TEXTURA, d.clase))}
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

{#if filas(dist).filter((d) => d.dimension === 'wrb').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
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

Espainiako nekazaritza-lurraren {formatNumber(espana[0]?.pct_basico, 0)} % **basikoa edo kareharritsua** da (7,5eko edo gehiagoko pHa), EBko {formatNumber(europa_resumen[0]?.basico_ue, 0)} %aren aldean: lurpeko kareharriak eta igeltsuak eta gatzak garbitzen ez dituen euri urriak pHa igotzen dute. Kantauri itsasertzak, Galiziak eta mendebalde granitikoak eta arbeltsuak (Salamanca, Cáceres) bakarrik dituzte lurzoru azidoak.

```sql ph_hijos
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT c.nombre, c.clase, c.orden, c.pct, t.ph
FROM mother.suelos_clases c
JOIN mother.suelos_territorio t ON t.nivel = c.nivel AND t.cod = c.cod AND t.cultivo = c.cultivo
JOIN f ON (f.nivel = 'pais' AND c.nivel = 'ccaa') OR (f.nivel = 'ccaa' AND c.nivel = 'provincia' AND t.cod_ccaa = f.cod)
WHERE c.cultivo = 'Toda la superficie agraria' AND c.dimension = 'ph' AND t.superficie_agraria_km2 >= 100
ORDER BY t.ph DESC, c.orden
```

{#if filas(ph_hijos).length > 0}

<BarChart
    data={etiquetar(ph_hijos, 'ph_texto', (d) => et(PH, d.clase))}
    x=nombre
    y=pct
    series=ph_texto
    type=stacked100
    swapXY=true
    sort=false
    seriesOrder={ORDEN_PH.map((k) => PH[k])}
    colorPalette={['#b91c1c', '#f59e0b', '#d6d3d1', '#60a5fa', '#1e3a8a']}
    title={terr[0]?.nivel === 'pais' ? 'Nekazaritza-azalera lurzoruaren pHaren arabera, erkidegoka' : 'Nekazaritza-azalera lurzoruaren pHaren arabera, probintziaka'}
/>

{:else if filas(dist).filter((d) => d.dimension === 'ph').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'ph').toSorted((a, b) => ORDEN_PH.indexOf(a.clase) - ORDEN_PH.indexOf(b.clase)), 'ph_texto', (d) => et(PH, d.clase))}
    x=ph_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#60a5fa"
    title="Nekazaritza-azalera lurzoruaren pHaren arabera (%)"
/>

{/if}

**Materia organikoak** (deskonposatutako landare-hondarrak, sustraiak eta simaurra) egitura ematen dio lurrari, ura atxikitzen du eta laboreak elikatzen ditu. Beroarekin, euri gutxirekin eta mendeetako lanketarekin, Espainiako nekazaritza-lurzoruak batez beste {formatNumber(espana[0]?.materia_organica_pct, 1)} % du, EBko {formatNumber(europa_resumen[0]?.mo_ue, 1)} %aren aldean. Alderatutako {formatNumber(europa_resumen[0]?.paises, 0)} Europako herrialdeetatik {formatNumber(europa_resumen[0]?.puesto_mo, 0)}. pobreena da (gutxien dutenak: {europa_resumen[0]?.menos_mo ?? '-'}).

```sql lucas_terr
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT l.nombre, l.muestras, l.materia_organica_pct, l.pct_mo_menos_2, l.pct_mo_menos_1, l.ph, l.pct_calizo,
    l.pct_erosion_visible, l.pct_carcavas
FROM mother.suelos_lucas l, f
WHERE l.uso = 'Agraria'
    AND ((f.nivel = 'pais' AND l.nivel = 'pais' AND l.cod = 'ES')
        OR (f.nivel <> 'pais' AND l.nivel = 'ccaa' AND l.cod = (SELECT max(cod_ccaa) FROM ${terr})))
```

```sql lucas_ccaa
SELECT nombre, muestras, materia_organica_pct, pct_mo_menos_2, ph, pct_calizo
FROM mother.suelos_lucas
WHERE nivel = 'ccaa' AND uso = 'Agraria'
ORDER BY materia_organica_pct
```

{#if filas(lucas_terr).length > 0}

<p>Europako LUCAS programaren (2018) <b>laborategi-laginek</b> ereduak baino materia organiko gutxiago ematen dute: {lucas_terr[0]?.nombre}(e)ko nekazaritza-azaleran, bere {formatNumber(lucas_terr[0]?.muestras, 0)} laginen mediana % {formatNumber(lucas_terr[0]?.materia_organica_pct, 1)} da, eta laginen % {formatNumber(lucas_terr[0]?.pct_mo_menos_2, 0)} ez da % 2ra iristen (% {formatNumber(lucas_terr[0]?.pct_mo_menos_1, 0)} ez da % 1era ere iristen). Materia organikoari dagokionez, fidatu gehiago analisi hauetaz mapaz baino: SoilGridsek lehorreko lurretan neurtzen dena baino karbono gehiago ematen du.</p>

{/if}

{#if filas(lucas_ccaa).length > 0}

<BarChart
    data={lucas_ccaa}
    x=nombre
    y=materia_organica_pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#65a30d"
    title="Erkidego bakoitzeko nekazaritza-azaleran neurtutako materia organikoa: LUCAS 2018 laginen mediana (%)"
/>

{/if}

## Higadura

```sql erosion_terr
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT e.nombre, e.anio, e.erosion_t_ha, e.pct_moderada_grave, e.pct_grave, e.nivel
FROM mother.suelos_erosion e, f
WHERE (f.nivel = 'pais' AND e.nivel = 'pais' AND e.cod = 'ES')
    OR (f.nivel IN ('ccaa', 'provincia') AND e.nivel = f.nivel AND e.cod = f.cod)
    OR (f.nivel = 'municipio' AND e.nivel = 'provincia' AND e.cod = left(f.cod, 2))
ORDER BY e.anio
```

```sql erosion_espana
SELECT anio, erosion_t_ha, pct_moderada_grave FROM mother.suelos_erosion
WHERE nivel = 'pais' AND cod = 'ES' AND anio = (SELECT max(anio) FROM mother.suelos_erosion)
```

```sql erosion_provincias
SELECT e.cod, e.nombre, e.erosion_t_ha, e.pct_moderada_grave, e.pct_grave, e.anio,
    '/eu/territorios/suelos?provincia=' || t.slug AS enlace
FROM mother.suelos_erosion e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.suelos_erosion)
```

Euriak urtero eramaten du maldako soroen geruza emankorra, batez ere landuta, landare-estalkirik gabe eta ekaitz bortitzekin daudenena: lurzoru-zentimetro bat sortzeko mendeak behar dira. Europako Batzordearen Ikerketa Zentro Bateratuaren ereduaren arabera, {erosion_terr.slice(-1)[0]?.nombre ?? '-'}(e)ko nekazaritza-azalerak batez beste {formatNumber(erosion_terr.slice(-1)[0]?.erosion_t_ha, 1)} tona lurzoru galtzen ditu hektareako eta urteko ({erosion_terr.slice(-1)[0]?.anio ?? '-'}; Espainia: {formatNumber(erosion_espana[0]?.erosion_t_ha, 1)}), eta azaleraren {formatNumber(erosion_terr.slice(-1)[0]?.pct_moderada_grave, 0)} %-k higadura ertaina edo larria jasaten du, 5 t/ha baino gehiago, hau da, lurzorua berritzen dena baino gehiago.

{#if filas(erosion_terr).length > 1}

<LineChart
    data={erosion_terr}
    x=anio
    y=pct_moderada_grave
    xFmt="0"
    yFmt=num1
    markers=true
    title="Higadura ertaina edo larria duen nekazaritza-azaleraren % (urteko 5 t/ha baino gehiago)"
/>

{/if}

{#if filas(erosion_provincias).length > 0}

<MapaEspana
    data={erosion_provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod"
    value="pct_moderada_grave"
    valueFmt="num0"
    colorPalette={['#fefce8', '#f59e0b', '#7c2d12']}
    link=enlace
    height={460}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_moderada_grave', title: '% higadura ertaina edo larriarekin', fmt: 'num1'},
        {id: 'pct_grave', title: '% higadura larriarekin (10 t/ha baino gehiago)', fmt: 'num1'},
        {id: 'erosion_t_ha', title: 'Batez besteko galera (t/ha urteko)', fmt: 'num1'}
    ]}
/>

{/if}

{#if filas(lucas_terr).length > 0}

<p class="text-xs text-gray-500">JRCren RUSLE ereduarekin (euria, malda, lurzorua, laborea eta kontserbazio-praktikak) nekazaritza-azalerarako eta larre naturaletarako kalkulatutako higadura, Eurostatek argitaratua; Balear eta Kanariar uharteak beren probintzian batzen dira. LUCASen inkestatzaileek 2018an landan ikusitako zantzuek (puntutik 500 m baino gutxiagora) norabide bera adierazten dute: {lucas_terr[0]?.nombre}(e)ko nekazaritza-puntuen {formatNumber(lucas_terr[0]?.pct_erosion_visible, 0)} %-n agertzen dira, eta {formatNumber(lucas_terr[0]?.pct_carcavas, 1)} %-n higadura-sakanak (karkabak) daude; gutxieneko bat da, hazitako laboreak zantzu asko estaltzen baititu.</p>

{/if}

## Lurraldearen barruan alderatuta

<BotonesUrl name="medida" titulo="Neurtu" opciones={MEDIDAS} defecto="pct_fuertes" />

```sql mapa_hijos
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT t.cod, t.nombre, '/eu/territorios/suelos?provincia=' || tt.slug AS enlace, t.superficie_agraria_km2, t.textura_dominante,
    t.arcilla_pct, t.ph, t.materia_organica_pct, t.wrb_dominante, coalesce(t.pct_fuertes, 0) AS pct_fuertes,
    t.${inputs.medida} AS medida
FROM mother.suelos_territorio t
JOIN mother.territorios tt ON tt.nivel = t.nivel AND tt.cod = t.cod
JOIN f ON f.nivel = 'pais'
WHERE t.nivel = 'provincia' AND t.cultivo = 'Toda la superficie agraria' AND t.cod NOT IN ('51', '52')
UNION ALL
SELECT m.cod_mun, m.municipio, '/eu/territorios/suelos?m=' || m.cod_mun AS enlace, m.superficie_agraria_km2, m.textura_dominante,
    m.arcilla_pct, m.ph, m.materia_organica_pct, m.wrb_dominante, m.pct_fuertes,
    m.${inputs.medida} AS medida
FROM mother.suelos_municipio m
JOIN f ON (f.nivel = 'ccaa' AND m.cod_ccaa = f.cod) OR (f.nivel = 'provincia' AND m.cod_prov = f.cod)
WHERE m.cultivo = 'Toda la superficie agraria'
ORDER BY superficie_agraria_km2 DESC
```

{#if filas(mapa_hijos).length > 0}

{#if terr[0]?.nivel === 'pais'}

<MapaEspana
    data={mapa_hijos}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod"
    value="medida"
    valueFmt="num1"
    colorPalette={['#fdf6e3', '#c8955a', '#5b2a17']}
    link=enlace
    height={460}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km²', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Testura ohikoena'},
        {id: 'pct_fuertes', title: '% lur gogorrak', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Lurzoru mota'}
    ]}
/>

<p class="text-xs text-gray-500">Espainiako probintziak. Sakatu bat probintzia horren lurzorua hemen ikusteko, bere udalerrien maparekin.</p>

{:else}

<MapaEspana
    data={mapa_hijos}
    geoJsonUrl={geoDe(terr[0])}
    filtroGeo={filtroDe(terr[0])}
    geoId="cod_mun"
    areaCol="cod"
    value="medida"
    valueFmt="num1"
    colorPalette={['#fdf6e3', '#c8955a', '#5b2a17']}
    link=enlace
    height={520}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'superficie_agraria_km2', title: 'Nekazaritza-km²', fmt: 'num1'},
        {id: 'textura_dominante', title: 'Testura ohikoena'},
        {id: 'pct_fuertes', title: '% lur gogorrak', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Lurzoru mota'}
    ]}
/>

<p class="text-xs text-gray-500">Udalerriak. Sakatu bat bere lurzorua hemen ikusteko, 250 m-ko gelaxken maparekin. Grisez, CORINE mapan nekazaritza-azalerarik ez duten udalerriak (mendia, hiria edo 25 ha baino gutxiagoko lursailak).</p>

{/if}

<DataTable data={mapa_hijos} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=nombre title={terr[0]?.nivel === 'pais' ? 'Probintzia' : 'Udalerria'} />
    <Column id=superficie_agraria_km2 title="Nekazaritza-km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Testura ohikoena" />
    <Column id=pct_fuertes title="% lur gogorrak" fmt=num0 />
    <Column id=arcilla_pct title="Buztina (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Materia organikoa (%)" fmt=num1 />
    <Column id=wrb_dominante title="Lurzoru mota" />
</DataTable>

<p class="text-xs text-gray-500">Lur gogorrak = USDAren triangeluko sei testura franko-buztintsu eta buztintsuak (oro har, laurden bat baino buztin gehiago). Udalerrietan, nekazaritza-azalera eta lurzorua udal-mugartearen barruko 250 m-ko gelaxka bakoitzetik ateratzen dira (CORINE eta SoilGrids, jatorrizko bereizmenean). Ceutak eta Melillak ia ez dute nekazaritza-azalerarik.</p>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">Udalerria da unitaterik txikiena: goian dago bere 250 m-ko gelaxken mapa. Aukeratu «Probintzia osoa» iragazkian, gainerako udalerriekin alderatzeko.</p>

{/if}

## Zer lurzoru duen labore bakoitzak

Nekazaritza-azalera CORINE 2018 lurzoru-erabileren maparen arabera banatzen da. Labore bakoitzak lur mota bat hartzen du: Espainian, larre-basoak mendebaldeko lurzoru hareatsu eta azidoetan daude; olibadiak eta ureztatuak, ibarretako lur buztintsuenetan; mahastiak, lurzoru kareharritsuenetan eta pobreenetan.

```sql cultivos
SELECT cultivo, superficie_agraria_km2, pct_de_la_agraria, arcilla_pct, arena_pct, ph, materia_organica_pct,
    textura_dominante, wrb_dominante, coalesce(pct_basico, 0) AS pct_basico, pct_fuertes, pct_arcillosa, pct_arenosa
FROM ${sel}
WHERE cultivo <> 'Toda la superficie agraria' AND superficie_agraria_km2 >= 0.0625
ORDER BY superficie_agraria_km2 DESC
```

{#if filas(cultivos).length > 0}

<BarChart
    data={gruposPorCultivo(cultivos)}
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
    <Column id=superficie_agraria_km2 title="Km²" fmt=num1 contentType=bar barColor="#e7d3b5" />
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

<p class="text-xs text-gray-500">Zipre, Grezia, Espainia, Italia eta Turkia dira nekazaritza-lurzoru basikoenak dituztenak, eta {europa_resumen[0]?.menos_mo ?? '-'}, materia organiko gutxien dutenak; iparraldeak (Irlanda, herrialde nordikoak, Erresuma Batua, Herbehereak) ditu azidoenak eta organikoenak, belardi hezeekin eta, batzuetan, zohikatzarekin. CORINEn gutxienez 1.000 nekazaritza-km² dituzten herrialdeak (Malta gabe). Behean, LUCASen laborategi-laginak, Espainiaren postua berresten dutenak.</p>

```sql lucas_europa
SELECT cod, nombre, es_ue, muestras, materia_organica_pct, pct_mo_menos_2, ph, puesto_mo_menor, territorios
FROM mother.suelos_lucas
WHERE nivel = 'pais' AND uso = 'Agraria' AND muestras >= 20
ORDER BY materia_organica_pct
```

{#if filas(lucas_europa).length > 0}

<BarChart
    data={etiquetar(lucas_europa, 'grupo', (d) => (d.cod === 'ES' ? 'Espainia' : d.es_ue ? 'EB' : 'Europako gainerakoak'))}
    x=nombre
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['Espainia', 'EB', 'Europako gainerakoak']}
    colorPalette={['#65a30d', '#a8a29e', '#d6d3d1']}
    title="Nekazaritza-azaleran neurtutako materia organikoa: LUCAS 2018 laginen mediana (%)"
/>

<BarChart
    data={etiquetar(filas(lucas_europa).toSorted((a, b) => b.pct_mo_menos_2 - a.pct_mo_menos_2), 'grupo', (d) => (d.cod === 'ES' ? 'Espainia' : d.es_ue ? 'EB' : 'Europako gainerakoak'))}
    x=nombre
    y=pct_mo_menos_2
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['Espainia', 'EB', 'Europako gainerakoak']}
    colorPalette={['#a16207', '#a8a29e', '#d6d3d1']}
    title="Materia organikoa % 2 baino gutxiago duten nekazaritza-azalerako laginen % (LUCAS 2018)"
/>

<p class="text-xs text-gray-500">LUCAS 2018 TOPSOIL (JRC): laborategian aztertutako labore-lur eta belardietako 0-20 cm-ko laginak; 20 lagin edo gehiago dituzten herrialdeak. Analisiak direnez eta ez eredu bat, SoilGridsek baino materia organiko gutxiago ematen dute Europa hegoaldean.</p>

{/if}

### Europa mapan

Geruza berak Europa osorako, 25 km-ko gelaxkekin eta Espainian bezalako metodoarekin.

<BotonesUrl name="capa_eu" titulo="Koloreztatu honen arabera" opciones={CAPAS_EU} defecto="textura" />

```sql puntos_europa
SELECT celda, celda_km, lon, lat, provincia AS lugar, superficie_agraria_km2, textura, textura_grupo, wrb,
    cultivo, arcilla_pct, ph, materia_organica_pct
FROM mother.suelos_rejilla
WHERE escala = 'europa'
```

{#if filas(puntos_europa).length > 0}

{#if String(inputs.capa_eu?.value ?? inputs.capa_eu) === 'ph'}

<MapaEspana
    data={puntos_europa}
    lat=lat
    long=lon
    value=ph
    valueFmt=num1
    min={5}
    max={8.3}
    colorPalette={['#b91c1c', '#fde68a', '#f5f5f4', '#93c5fd', '#1e3a8a']}
    geoJsonUrl="/geo/nuts2_europa.geojson"
    celdaKm={25}
    pointName=lugar
    opacity={0.9}
    height={640}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'textura', title: 'Testura'},
        {id: 'wrb', title: 'Lurzoru mota'}
    ]}
/>

{:else if String(inputs.capa_eu?.value ?? inputs.capa_eu) === 'mo'}

<MapaEspana
    data={puntos_europa}
    lat=lat
    long=lon
    value=materia_organica_pct
    valueFmt=num1
    min={1.5}
    max={12}
    colorPalette={['#fef3c7', '#bef264', '#16a34a', '#14532d']}
    geoJsonUrl="/geo/nuts2_europa.geojson"
    celdaKm={25}
    pointName=lugar
    opacity={0.9}
    height={640}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'materia_organica_pct', title: 'Materia organikoa (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Labore nagusia'}
    ]}
/>

{:else}

<MapaEspana
    data={enRejilla(puntos_europa, 'textura')}
    lat=lat
    long=lon
    value=categoria
    colorCol=color
    legendType=categorical
    geoJsonUrl="/geo/nuts2_europa.geojson"
    celdaKm={25}
    pointName=lugar
    opacity={0.95}
    height={640}
    tooltip={[
        {id: 'lugar', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'textura', title: 'Testura'},
        {id: 'arcilla_pct', title: 'Buztina (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Lurzoru mota'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Puntu bakoitza 25 × 25 km-ko karratu bat da, CORINE 2018ren arabera gutxienez 25 km² nekazaritza-azalera dituena, SoilGridsen lurzoruarekin. LUCASen laborategi-laginak ez dira banan-banan marrazten: JRCk puntuz puntu argitaratzea baimentzen ez duten erabilera-baldintzekin ematen ditu; behean, eskualdeka laburbilduta daude.</p>

{/if}

### Eskualdez eskualde

Herrialde osoak alderatzeak asko ezkutatzen du: Italia iparraldea ez da hegoaldearen antzekoa, ezta Andaluzia Galiziaren antzekoa ere. Hemen, Europako eskualde bakoitza (NUTS 2), ereduarekin, LUCASek neurtutakoarekin gutxienez 10 lagin dauden tokietan, eta kalkulatutako higadurarekin.

<BotonesUrl name="medida_eu" titulo="Neurtu" opciones={MEDIDAS_EU} defecto="materia_organica_pct" />

```sql regiones_eu
SELECT nuts2, nombre, pais, cod_pais, superficie_agraria_km2, materia_organica_pct, lucas_materia_organica_pct,
    lucas_muestras, ph, pct_fuertes, erosion_t_ha, pct_erosion_moderada_grave, textura_dominante, wrb_dominante,
    ${inputs.medida_eu} AS medida
FROM mother.suelos_regiones
ORDER BY medida DESC NULLS LAST
```

{#if filas(regiones_eu).length > 0}

<MapaEspana
    data={regiones_eu}
    geoJsonUrl="/geo/nuts2_europa.geojson"
    geoId="nuts2"
    areaCol="nuts2"
    value="medida"
    valueFmt="num1"
    colorPalette={['#fdf6e3', '#c8955a', '#5b2a17']}
    height={640}
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pais', title: 'Herrialdea'},
        {id: 'materia_organica_pct', title: 'Materia organikoa, eredua (%)', fmt: 'num1'},
        {id: 'lucas_materia_organica_pct', title: 'Neurtutako materia organikoa, LUCAS (%)', fmt: 'num1'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'pct_fuertes', title: '% lur gogorrak', fmt: 'num0'},
        {id: 'erosion_t_ha', title: 'Higadura (t/ha urteko)', fmt: 'num1'},
        {id: 'pct_erosion_moderada_grave', title: '% higadura ertaina edo larriarekin', fmt: 'num0'}
    ]}
/>

<DataTable data={regiones_eu} rows=10 search=true>
    <Column id=nombre title="Eskualdea" />
    <Column id=pais title="Herrialdea" />
    <Column id=superficie_agraria_km2 title="Nekazaritza-km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=materia_organica_pct title="Materia organikoa, eredua (%)" fmt=num1 />
    <Column id=lucas_materia_organica_pct title="Materia organikoa, LUCAS (%)" fmt=num1 />
    <Column id=lucas_muestras title="LUCAS laginak" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_fuertes title="% lur gogorrak" fmt=num0 />
    <Column id=erosion_t_ha title="Higadura (t/ha)" fmt=num1 />
    <Column id=pct_erosion_moderada_grave title="% higadura ertaina edo larria" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">2021eko NUTS 2 eskualdeak (mugak © EuroGeographics). LUCASek 2016koak erabiltzen ditu: bertsio batetik bestera aldatu ziren eskualde gutxiak neurtutako daturik gabe agertzen dira. Higadura: Eurostatek argitaratutako azken urtea.</p>

{/if}

```sql erosion_europa
SELECT e.cod, e.nombre, e.erosion_t_ha, e.pct_moderada_grave, p.es_ue
FROM mother.suelos_erosion e
LEFT JOIN mother.suelos_europa p ON p.cod_pais = e.cod
WHERE e.nivel = 'pais' AND e.anio = (SELECT max(anio) FROM mother.suelos_erosion)
ORDER BY e.pct_moderada_grave DESC
```

{#if filas(erosion_europa).length > 0}

<BarChart
    data={etiquetar(erosion_europa, 'grupo', (d) => (d.cod === 'ES' ? 'Espainia' : d.es_ue ? 'EB' : 'Europako gainerakoak'))}
    x=nombre
    y=pct_moderada_grave
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['Espainia', 'EB', 'Europako gainerakoak']}
    colorPalette={['#b45309', '#a8a29e', '#d6d3d1']}
    title="Higadura ertaina edo larria duen nekazaritza-azaleraren %, herrialdeka (JRCren RUSLE eredua)"
/>

<p class="text-xs text-gray-500">Zerrendaren buruan mendia eta euri ugari duten herrialdeak daude (Eslovenia, Italia, Austria). Espainia goiko erdian dago: bere soroetan ekaitz-euriek, maldek eta ilaren artean lurzorua biluzik duten olibadi eta mahastiek pisu handia dute. 2000. urtean, nekazaritza-azaleraren % 31k zuen higadura ertaina edo larria, eta 2016an, % 27k.</p>

{/if}

## Iturriak eta oharrak

- **Lurzorua: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, CC BY 4.0 lizentzia). Buztina, limoa eta harea, uretako pHa eta karbono organikoa 0-5, 5-15 eta 15-30 cm-ko geruzetan (1 km-ko batez bestekoak Espainiarako, erkidegoetarako, probintzietarako eta Europarako, eta 250 m-ko jatorrizko bereizmena udalerrietarako), lodieraren arabera batez bestekoa eginda; WRB lurzoru-talde probableena. Ikaskuntza automatikoko eredu bat da, milaka lurzoru-profilekin eta satelite-, klima- eta erliebe-mapekin entrenatua: muturrak leuntzen ditu eta eskualde jakin batean huts egin dezake. Materia organikoa = karbono organikoa × 1,724.
- **Nekazaritza-azalera eta laboreak: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, Europako Ingurumen Agentzia), nekazaritza-klaseak (2xx), 250 m-tik behin laginduak.
- **Mugak: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) herrialdeentzat eta IGN probintzientzat.
- **Laborategi-laginak: [LUCAS 2018 TOPSOIL](https://esdac.jrc.ec.europa.eu/content/lucas-2018-topsoil-data)** (European Soil Data Centre, ESDAC, esdac.jrc.ec.europa.eu, Europako Batzordea, Ikerketa Zentro Bateratua). EB osoko 0-20 cm-ko 19.000 lagin inguru laborategian aztertuak; hemen, labore-lur eta belardietakoen medianak eta ehunekoak, herrialdeka eta erkidegoka, 10 lagin edo gehiago dituztenean (Kanariak gabe). Panagos, P. et al. (2022), «European Soil Data Centre 2.0», European Journal of Soil Science 73(6), e13315.
- **Higadura: [Eurostat, aei_pr_soiler](https://ec.europa.eu/eurostat/databrowser/view/aei_pr_soiler/default/table)**, urak eragindako lurzoru-galera, Ikerketa Zentro Bateratuak RUSLE ereduarekin (euria, malda, lurzorua, estalkia eta kontserbazio-praktikak) kalkulatua 2000, 2010, 2016 eta 2023an, nekazaritza-azalerarako eta larre naturaletarako, herrialdeka, eskualdeka eta probintziaka (Panagos, P. et al. (2015), «The new assessment of soil loss by water erosion in Europe», Environmental Science & Policy 54).
- **Europako eskualdeak: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat), 2021eko NUTS 2 eskualdeak (mugak © EuroGeographics).
- Dena 1 × 1 km-ko sare batean (udalerrietan, 250 × 250 m-koan) kalkulatzen da, azalera berdineko proiekzio batean (ETRS89-LAEA), beraz km² bakoitzak pisu bera du. Lurzoru-mapek ez dute serie historikorik: egungo lurzoruaren argazki bat dira.

<LastRefreshed prefix="Datuak eguneratuta" />
