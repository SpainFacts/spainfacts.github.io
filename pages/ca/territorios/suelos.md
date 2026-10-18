---
title: Sòls agraris
description: "Quina terra hi ha sota els conreus d'Espanya: sòls argilosos, francs i sorrencs, tipus de sòl (calcisòls, cambisòls, luvisòls, vertisòls...), pH i matèria orgànica per comunitat, província i municipi, mapa cada 10 km, quin sòl té l'oliverar, la vinya, el regadiu o la devesa i comparació amb la resta d'Europa."
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

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones.
    // Las claves son los valores de los datos (en castellano).
    const CULTIVO = {
        'Toda la superficie agraria': 'Tota la superfície agrària',
        'Secano': 'Conreus de secà',
        'Regadío': 'Regadiu',
        'Arrozal': 'Arrossars',
        'Viñedo': 'Vinya',
        'Frutales': 'Fruiters',
        'Olivar': 'Oliverar',
        'Prados': 'Prats',
        'Mosaico de cultivos': 'Mosaic de conreus i hortes',
        'Dehesa': 'Deveses'
    };
    const GRUPO = {
        'Arenosa (ligera)': 'Sorrenca (terra lleugera)',
        'Franca (media)': 'Franca (terra mitjana)',
        'Franco-arcillosa': 'Franca argilosa (terra forta)',
        'Arcillosa (pesada)': 'Argilosa (terra pesada)'
    };
    const TEXTURA = {
        'Arenosa': 'Sorrenca', 'Arenoso-franca': 'Sorrenca franca', 'Franco-arenosa': 'Franca sorrenca',
        'Franca': 'Franca', 'Franco-limosa': 'Franca llimosa', 'Limosa': 'Llimosa',
        'Franco-arcillo-arenosa': 'Franca argilosa sorrenca', 'Franco-arcillosa': 'Franca argilosa',
        'Franco-arcillo-limosa': 'Franca argilosa llimosa', 'Arcillo-arenosa': 'Argilosa sorrenca',
        'Arcillo-limosa': 'Argilosa llimosa', 'Arcillosa': 'Argilosa'
    };
    const PH = {
        'Muy ácido (< 5,5)': 'Molt àcid (menys de 5,5)',
        'Ácido (5,5-6,5)': 'Àcid (5,5 a 6,5)',
        'Neutro (6,5-7,5)': 'Neutre (6,5 a 7,5)',
        'Básico (7,5-8,5)': 'Bàsic o calcari (7,5 a 8,5)',
        'Muy básico (> 8,5)': 'Molt bàsic (més de 8,5)'
    };
    const WRB = {
        'Calcisoles': 'Calcisòls', 'Cambisoles': 'Cambisòls', 'Luvisoles': 'Luvisòls', 'Leptosoles': 'Leptosòls',
        'Vertisoles': 'Vertisòls', 'Regosoles': 'Regosòls', 'Fluvisoles': 'Fluvisòls', 'Kastanozems': 'Kastanozems',
        'Phaeozems': 'Phaeozems', 'Gipsisoles': 'Gipsisòls', 'Arenosoles': 'Arenosòls', 'Umbrisoles': 'Umbrisòls',
        'Podzoles': 'Podzòls', 'Chernozems': 'Chernozems', 'Gleysoles': 'Gleisòls', 'Solonchaks': 'Solontxacs',
        'Albeluvisoles': 'Albeluvisòls', 'Andosoles': 'Andosòls', 'Acrisoles': 'Acrisòls', 'Alisoles': 'Alisòls',
        'Histosoles': 'Histosòls', 'Planosoles': 'Planosòls', 'Stagnosoles': 'Stagnosòls', 'Solonetz': 'Solonetz'
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
    // Mapa de puntos: categoría visible y su color según la capa elegida
    function enRejilla(q, capa) {
        return filas(q).map((d) => {
            if (capa === 'wrb') return { ...d, categoria: et(WRB, d.wrb), color: COLOR_WRB[d.wrb] ?? '#cbd5e1' };
            if (capa === 'cultivo') return { ...d, categoria: et(CULTIVO, d.cultivo), color: COLOR_CULTIVO[d.cultivo] ?? '#cbd5e1' };
            return { ...d, categoria: et(GRUPO, d.textura_grupo), color: COLOR_GRUPO[d.textura_grupo] ?? '#cbd5e1' };
        }).filter((d) => d.categoria);
    }

    // Textos del filtro de territorio y de los botones (se traducen en cada página)
    const ETIQUETAS_FILTRO = {
        comunidad: 'Comunitat autònoma',
        todaEspana: 'Tota Espanya',
        provincia: 'Província',
        todaComunidad: 'Tota la comunitat',
        municipio: 'Municipi',
        todaProvincia: 'Tota la província'
    };
    const CAPAS = [
        { value: 'textura', label: 'Textura' },
        { value: 'wrb', label: 'Tipus de sòl' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Matèria orgànica' },
        { value: 'cultivo', label: 'Conreu' }
    ];
    const MEDIDAS = [
        { value: 'pct_fuertes', label: '% de terres fortes' },
        { value: 'arcilla_pct', label: 'Argila mitjana (%)' },
        { value: 'ph', label: 'pH mitjà' },
        { value: 'pct_basico', label: '% bàsic o calcari' },
        { value: 'materia_organica_pct', label: 'Matèria orgànica (%)' },
        { value: 'pct_calcisoles', label: '% de calcisòls' },
        { value: 'pct_agraria', label: '% de superfície agrària' }
    ];
    const ORDEN_TEXTURA = Object.keys(TEXTURA);

    // Mapa de Europa: capa del mapa de puntos y medida del mapa de regiones (con parámetro en la URL)
    const CAPAS_EU = [
        { value: 'textura', label: 'Textura' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Matèria orgànica' }
    ];
    const MEDIDAS_EU = [
        { value: 'materia_organica_pct', label: 'Matèria orgànica (model)' },
        { value: 'lucas_materia_organica_pct', label: 'Matèria orgànica mesurada (LUCAS)' },
        { value: 'ph', label: 'pH' },
        { value: 'pct_fuertes', label: '% de terres fortes' },
        { value: 'erosion_t_ha', label: 'Erosió (t/ha i any)' },
        { value: 'pct_erosion_moderada_grave', label: '% amb erosió moderada o greu' }
    ];
    // Reparto de la superficie de cada cultivo en los cuatro grupos de textura a partir de los %
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
    // GeoJSON y filtro de polígonos de los mapas según el territorio elegido
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

# 🟫 Sòls agraris

Quina terra hi ha sota els conreus: si és **argilosa, franca o sorrenca**, quin **tipus de sòl** és, si és **calcària o àcida** i quanta **matèria orgànica** té. Tot es mesura sobre la **superfície agrària** ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} mil km² a Espanya, gairebé la meitat del país) a la capa que es treballa, els primers 30 cm, i es creua amb el que s'hi conrea a sobre. Tria una comunitat, una província o un municipi i tota la pàgina, mapes inclosos, passa a aquest territori; l'enllaç de la pàgina canvia amb la teva tria perquè el puguis compartir. Les dades surten d'un model (SoilGrids), no d'anàlisis de cada parcel·la: serveixen per comparar zones.

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

## {terr[0]?.nivel === 'pais' ? 'Espanya' : terr[0]?.nombre}

<Grid cols=4>
    <KpiCard
        title="Superfície agrària"
        value={terr[0]?.pct_agraria}
        formattedValue="{formatNumber(terr[0]?.pct_agraria, 0)} %"
        period="del territori · {formatNumber(terr[0]?.superficie_agraria_km2, 0)} km² · Espanya: {formatNumber(espana[0]?.pct_agraria, 0)} %"
        direction="neutral"
        source="CORINE Land Cover 2018"
    />
    <KpiCard
        title="Terres fortes (franques argiloses i argiloses)"
        value={terr[0]?.pct_fuertes}
        formattedValue="{formatNumber(terr[0]?.pct_fuertes, 0)} %"
        period="textura més freqüent: {et(TEXTURA, terr[0]?.textura_dominante)} · Espanya: {formatNumber(espana[0]?.pct_fuertes, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="pH mitjà del sòl agrari"
        value={terr[0]?.ph}
        formattedValue={formatNumber(terr[0]?.ph, 1)}
        period="{formatNumber(terr[0]?.pct_basico, 0)} % bàsic o calcari · {terr[0]?.nivel === 'pais' ? 'UE: ' + formatNumber(europa_resumen[0]?.basico_ue, 0) + ' %' : 'Espanya: pH ' + formatNumber(espana[0]?.ph, 1)}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Matèria orgànica mitjana"
        value={terr[0]?.materia_organica_pct}
        formattedValue="{formatNumber(terr[0]?.materia_organica_pct, 1)} %"
        period="{terr[0]?.nivel === 'pais' ? 'UE: ' + formatNumber(europa_resumen[0]?.mo_ue, 1) + ' % · Espanya, ' + formatNumber(europa_resumen[0]?.puesto_mo, 0) + 'a amb menys de ' + formatNumber(europa_resumen[0]?.paises, 0) + ' països' : 'Espanya: ' + formatNumber(espana[0]?.materia_organica_pct, 1) + ' %'} · tipus de sòl: {et(WRB, terr[0]?.wrb_dominante)}{filas(lucas_terr).length ? ' · LUCAS: ' + formatNumber(lucas_terr[0]?.materia_organica_pct, 1) + ' %' : ''}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
</Grid>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">El mapa d'usos del sòl CORINE 2018 no marca superfície agrària en aquest territori.</p>

{/if}

## El mapa de punts

<BotonesUrl name="capa" titulo="Acolorir per" opciones={CAPAS} defecto="textura" />

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
        {id: 'textura', title: 'Textura'},
        {id: 'wrb', title: 'Tipus de sòl'}
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
        {id: 'textura', title: 'Textura'},
        {id: 'wrb', title: 'Tipus de sòl'},
        {id: 'superficie_agraria_km2', title: 'Km² agraris a la cel·la', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Vermell: sòls àcids (pH baix), típics del nord-oest plujós i dels granits i les pissarres de l'oest. Blau: sòls bàsics o calcaris (pH alt), els de gairebé tota l'Espanya seca, amb calcària o guix al subsòl. El pH decideix quins conreus hi van bé (el castanyer o el nabiu volen terra àcida; la vinya, l'ametller o l'olivera aguanten la calcària) i quanta calç o sofre cal tirar-hi.</p>

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
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Conreu principal'}
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
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Conreu principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agraris a la cel·la', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Com més verd, més matèria orgànica: els prats del nord, amb pluja, herba i fems tot l'any. Els secans de la Meseta, la vall de l'Ebre i el sud-est, amb calor, poca pluja i segles de llaurada, tenen el sòl agrari més pobre en matèria orgànica de l'Europa occidental. SoilGrids sol donar una mica més de carboni que les anàlisis de camp als secans mediterranis: compara zones, no prenguis la xifra com una anàlisi.</p>

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
        {id: 'textura', title: 'Textura'},
        {id: 'arcilla_pct', title: 'Argila (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipus de sòl'},
        {id: 'cultivo', title: 'Conreu principal'}
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
        {id: 'textura', title: 'Textura'},
        {id: 'arcilla_pct', title: 'Argila (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipus de sòl'},
        {id: 'cultivo', title: 'Conreu principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agraris a la cel·la', fmt: 'num1'}
    ]}
/>

{/if}

{/if}

<p class="text-xs text-gray-500">Cada punt és un quadrat amb superfície agrària (de 10 km de costat per a tota Espanya, de 5 km en una comunitat, de 2 km en una província i de 250 m en un municipi), acolorit segons la textura, el tipus de sòl o el conreu que hi ocupa més superfície agrària. On no hi ha punt hi ha bosc, roca, aigua o ciutat.</p>

{/if}

## Argilosos, francs i sorrencs

La **textura** és la proporció d'argila, llim i sorra de la terra, i és el primer que mira un pagès: una terra **argilosa** («forta» o «pesada») guarda l'aigua i els nutrients però s'entolla, s'esquerda i costa de llaurar; una **sorrenca** («lleugera») es treballa amb facilitat i s'escalfa abans a la primavera, però l'aigua i l'adob se li escapen; la **franca**, amb les tres coses equilibrades, és la ideal per a gairebé tot. El sòl agrari de {terr[0]?.nivel === 'pais' ? 'Espanya' : (terr[0]?.nombre ?? '-')} té de mitjana un {formatNumber(terr[0]?.arcilla_pct, 0)} % d'argila, un {formatNumber(terr[0]?.limo_pct, 0)} % de llim i un {formatNumber(terr[0]?.arena_pct, 0)} % de sorra.

{#if filas(dist).filter((d) => d.dimension === 'textura').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'textura').toSorted((a, b) => ORDEN_TEXTURA.indexOf(a.clase) - ORDEN_TEXTURA.indexOf(b.clase)), 'textura_texto', (d) => et(TEXTURA, d.clase))}
    x=textura_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a5a34"
    title="Superfície agrària per classe de textura de l'USDA (%)"
/>

{/if}

<p class="text-xs text-gray-500">Classes del triangle de textures del Departament d'Agricultura dels EUA (USDA), les que fan servir els laboratoris agraris a Espanya. SoilGrids és un model que suavitza els extrems: les terres molt argiloses (els «bujeos» de la campinya del Guadalquivir, les «tierras de barro» de Tierra de Campos) hi apareixen com a franques argiloses i les molt sorrenques, com a franques sorrenques. Per això hi ha poques classes pures d'argila o de sorra i convé llegir juntes les franques argiloses i les argiloses com a «terres fortes».</p>

## Tipus de sòl

A més de la textura, els edafòlegs classifiquen els sòls segons com s'han format. En la classificació internacional (WRB, de la FAO), l'Espanya agrària és sobretot de **luvisòls** (sòls vells amb argila acumulada al fons, com les terres vermelles de la Manxa i Extremadura), **cambisòls** (sòls joves, poc evolucionats), **calcisòls** (amb una capa de calcària, típics de l'Espanya seca), **leptosòls** (sòls prims sobre roca, als vessants) i **vertisòls** (argiles que s'inflen amb l'aigua i s'esquerden quan s'assequen, les «terres negres» de la campinya andalusa).

{#if filas(dist).filter((d) => d.dimension === 'wrb').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
    x=wrb_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c4524b"
    title="Superfície agrària per tipus de sòl (WRB, %)"
/>

{/if}

## pH i matèria orgànica

El {formatNumber(espana[0]?.pct_basico, 0)} % de la terra agrària d'Espanya és **bàsica o calcària** (pH de 7,5 o més), davant del {formatNumber(europa_resumen[0]?.basico_ue, 0)} % de la UE: la calcària i el guix del subsòl i la poca pluja, que no renta les sals, fan pujar el pH. Només la cornisa cantàbrica, Galícia i l'oest de granit i pissarra (Salamanca, Càceres) tenen sòls àcids.

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
    title={terr[0]?.nivel === 'pais' ? 'Superfície agrària segons el pH del sòl, per comunitat' : 'Superfície agrària segons el pH del sòl, per província'}
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
    title="Superfície agrària segons el pH del sòl (%)"
/>

{/if}

La **matèria orgànica** (restes de plantes, arrels i fems descompostos) dona estructura a la terra, reté l'aigua i alimenta els conreus. Amb calor, poca pluja i segles de llaurada, el sòl agrari espanyol té de mitjana un {formatNumber(espana[0]?.materia_organica_pct, 1)} %, davant del {formatNumber(europa_resumen[0]?.mo_ue, 1)} % de la UE. És el {formatNumber(europa_resumen[0]?.puesto_mo, 0)}è més pobre dels {formatNumber(europa_resumen[0]?.paises, 0)} països europeus comparats (els tres amb menys: {europa_resumen[0]?.menos_mo ?? '-'}).

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

<p>Les <b>mostres de laboratori</b> del programa europeu LUCAS (2018) donen menys matèria orgànica que el model: a la superfície agrària de {lucas_terr[0]?.nombre}, la mediana de les seves {formatNumber(lucas_terr[0]?.muestras, 0)} mostres és un {formatNumber(lucas_terr[0]?.materia_organica_pct, 1)} %, i el {formatNumber(lucas_terr[0]?.pct_mo_menos_2, 0)} % no arriba al 2 % (el {formatNumber(lucas_terr[0]?.pct_mo_menos_1, 0)} %, ni a l'1 %). Per a la matèria orgànica, fia't més d'aquestes anàlisis que del mapa: SoilGrids dona més carboni del que es mesura als secans.</p>

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
    title="Matèria orgànica mesurada a la superfície agrària de cada comunitat: mediana de les mostres LUCAS 2018 (%)"
/>

{/if}

## Erosió

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
    '/ca/territorios/suelos?provincia=' || t.slug AS enlace
FROM mother.suelos_erosion e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.suelos_erosion)
```

La pluja s'emporta cada any la capa fèrtil dels camps en pendent, sobretot els llaurats, sense coberta vegetal i amb tempestes fortes: un centímetre de sòl triga segles a formar-se. Segons el model del Centre Comú de Recerca de la Comissió Europea, la superfície agrària de {erosion_terr.slice(-1)[0]?.nombre ?? '-'} perd de mitjana {formatNumber(erosion_terr.slice(-1)[0]?.erosion_t_ha, 1)} tones de sòl per hectàrea i any ({erosion_terr.slice(-1)[0]?.anio ?? '-'}; Espanya: {formatNumber(erosion_espana[0]?.erosion_t_ha, 1)}), i el {formatNumber(erosion_terr.slice(-1)[0]?.pct_moderada_grave, 0)} % pateix erosió moderada o greu, més de 5 t/ha, que és més del que el sòl es regenera.

{#if filas(erosion_terr).length > 1}

<LineChart
    data={erosion_terr}
    x=anio
    y=pct_moderada_grave
    xFmt="0"
    yFmt=num1
    markers=true
    title="% de la superfície agrària amb erosió moderada o greu (més de 5 t/ha i any)"
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
        {id: 'pct_moderada_grave', title: '% amb erosió moderada o greu', fmt: 'num1'},
        {id: 'pct_grave', title: '% amb erosió greu (més de 10 t/ha)', fmt: 'num1'},
        {id: 'erosion_t_ha', title: 'Pèrdua mitjana (t/ha i any)', fmt: 'num1'}
    ]}
/>

{/if}

{#if filas(lucas_terr).length > 0}

<p class="text-xs text-gray-500">Erosió estimada amb el model RUSLE del JRC (pluja, pendent, sòl, conreu i pràctiques de conservació) per a la superfície agrària i les pastures naturals, publicada per Eurostat; les illes Balears i les Canàries se sumen a la seva província. Els senyals vistos al camp pels enquestadors de LUCAS el 2018 (a menys de 500 m del punt) apunten en la mateixa direcció: apareixen en el {formatNumber(lucas_terr[0]?.pct_erosion_visible, 0)} % dels punts agraris de {lucas_terr[0]?.nombre} i hi ha xaragalls en el {formatNumber(lucas_terr[0]?.pct_carcavas, 1)} %; és un mínim, perquè el conreu crescut tapa molts senyals.</p>

{/if}

## Comparar dins del territori

<BotonesUrl name="medida" titulo="Mesurar" opciones={MEDIDAS} defecto="pct_fuertes" />

```sql mapa_hijos
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT t.cod, t.nombre, '/ca/territorios/suelos?provincia=' || tt.slug AS enlace, t.superficie_agraria_km2, t.textura_dominante,
    t.arcilla_pct, t.ph, t.materia_organica_pct, t.wrb_dominante, coalesce(t.pct_fuertes, 0) AS pct_fuertes,
    t.${inputs.medida} AS medida
FROM mother.suelos_territorio t
JOIN mother.territorios tt ON tt.nivel = t.nivel AND tt.cod = t.cod
JOIN f ON f.nivel = 'pais'
WHERE t.nivel = 'provincia' AND t.cultivo = 'Toda la superficie agraria' AND t.cod NOT IN ('51', '52')
UNION ALL
SELECT m.cod_mun, m.municipio, '/ca/territorios/suelos?m=' || m.cod_mun AS enlace, m.superficie_agraria_km2, m.textura_dominante,
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
        {id: 'superficie_agraria_km2', title: 'Km² agraris', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Textura més freqüent'},
        {id: 'pct_fuertes', title: '% terres fortes', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Tipus de sòl'}
    ]}
/>

<p class="text-xs text-gray-500">Províncies d'Espanya. Fes clic en una per veure aquí el sòl d'aquesta província, amb el mapa dels seus municipis.</p>

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
        {id: 'superficie_agraria_km2', title: 'Km² agraris', fmt: 'num1'},
        {id: 'textura_dominante', title: 'Textura més freqüent'},
        {id: 'pct_fuertes', title: '% terres fortes', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Tipus de sòl'}
    ]}
/>

<p class="text-xs text-gray-500">Municipis. Fes clic en un per veure aquí el seu sòl, amb el seu mapa de cel·les de 250 m. En gris, els municipis sense superfície agrària al mapa CORINE (bosc, ciutat o parcel·les de menys de 25 ha).</p>

{/if}

<DataTable data={mapa_hijos} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=nombre title={terr[0]?.nivel === 'pais' ? 'Província' : 'Municipi'} />
    <Column id=superficie_agraria_km2 title="Km² agraris" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura més freqüent" />
    <Column id=pct_fuertes title="% terres fortes" fmt=num0 />
    <Column id=arcilla_pct title="Argila (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Matèria orgànica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipus de sòl" />
</DataTable>

<p class="text-xs text-gray-500">Terres fortes = les sis textures franques argiloses i argiloses del triangle de l'USDA (en general, més d'una quarta part d'argila). Als municipis, la superfície agrària i el sòl surten de cada cel·la de 250 m dins del terme (CORINE i SoilGrids a la seva resolució original). Ceuta i Melilla gairebé no tenen superfície agrària.</p>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">Un municipi és la unitat més petita: a dalt hi ha el seu mapa de cel·les de 250 m. Tria «Tota la província» al filtre per comparar-lo amb els altres municipis.</p>

{/if}

## Quin sòl té cada conreu

La superfície agrària es reparteix segons el mapa d'usos del sòl CORINE 2018. Cada conreu ocupa un tipus de terra: a Espanya, la devesa és sobre sòls sorrencs i àcids de l'oest; l'oliverar i el regadiu, a les terres més argiloses de les valls; la vinya, als sòls més calcaris i pobres.

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
    title="Textura del sòl de cada conreu"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Conreu" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num1 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_de_la_agraria title="% de la superfície agrària" fmt=num1 />
    <Column id=textura_dominante title="Textura més freqüent" />
    <Column id=arcilla_pct title="Argila (%)" fmt=num0 />
    <Column id=arena_pct title="Sorra (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% bàsic" fmt=num0 />
    <Column id=materia_organica_pct title="Matèria orgànica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipus de sòl" />
</DataTable>

{/if}

<p class="text-xs text-gray-500">Conreus de CORINE Land Cover 2018: secà = terres de conreu sense reg (cereal, gira-sol, lleguminoses); regadiu = terres de conreu regades permanentment (blat de moro, hortalisses, cotó...); fruiters inclou cítrics, ametller i fruita seca; mosaic = parcel·les petites de conreus diferents barrejades, hortes i conreus amb vegetació natural; devesa = alzinar o suredar amb pastura o conreu a sota. CORINE no dibuixa parcel·les de menys de 25 ha, que se sumen al que les envolta.</p>

## Davant d'Europa

El mateix mètode per a tots els països: el model SoilGrids sobre la superfície agrària de CORINE 2018.

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(europa, 'grupo', (d) => (d.cod_pais === 'ES' ? 'Espanya' : d.es_ue ? 'UE' : "Resta d'Europa"))}
    x=pais
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['Espanya', 'UE', "Resta d'Europa"]}
    colorPalette={['#c2410c', '#a8a29e', '#d6d3d1']}
    title="Matèria orgànica mitjana del sòl agrari (%)"
/>

{/if}

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(filas(europa).toSorted((a, b) => b.ph - a.ph), 'grupo', (d) => (d.cod_pais === 'ES' ? 'Espanya' : d.es_ue ? 'UE' : "Resta d'Europa"))}
    x=pais
    y=ph
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    yMin={4}
    seriesOrder={['Espanya', 'UE', "Resta d'Europa"]}
    colorPalette={['#1e3a8a', '#a8a29e', '#d6d3d1']}
    title="pH mitjà del sòl agrari"
/>

{/if}

<DataTable data={europa} rows=12 search=true>
    <Column id=pais title="País" />
    <Column id=superficie_agraria_km2 title="Km² agraris" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura més freqüent" />
    <Column id=arcilla_pct title="Argila (%)" fmt=num0 />
    <Column id=arena_pct title="Sorra (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% bàsic" fmt=num0 />
    <Column id=materia_organica_pct title="Matèria orgànica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipus de sòl" />
</DataTable>

<p class="text-xs text-gray-500">Xipre, Grècia, Espanya, Itàlia i Turquia tenen els sòls agraris més bàsics, i {europa_resumen[0]?.menos_mo ?? '-'}, els de menys matèria orgànica; el nord (Irlanda, els països nòrdics, el Regne Unit, els Països Baixos), els més àcids i orgànics, amb prats humits i, en alguns, torba. Països amb almenys 1.000 km² agraris a CORINE (sense Malta). A sota, les mostres de laboratori de LUCAS, que confirmen el lloc d'Espanya.</p>

```sql lucas_europa
SELECT cod, nombre, es_ue, muestras, materia_organica_pct, pct_mo_menos_2, ph, puesto_mo_menor, territorios
FROM mother.suelos_lucas
WHERE nivel = 'pais' AND uso = 'Agraria' AND muestras >= 20
ORDER BY materia_organica_pct
```

{#if filas(lucas_europa).length > 0}

<BarChart
    data={etiquetar(lucas_europa, 'grupo', (d) => (d.cod === 'ES' ? 'Espanya' : d.es_ue ? 'UE' : "Resta d'Europa"))}
    x=nombre
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['Espanya', 'UE', "Resta d'Europa"]}
    colorPalette={['#65a30d', '#a8a29e', '#d6d3d1']}
    title="Matèria orgànica mesurada a la superfície agrària: mediana de les mostres LUCAS 2018 (%)"
/>

<BarChart
    data={etiquetar(filas(lucas_europa).toSorted((a, b) => b.pct_mo_menos_2 - a.pct_mo_menos_2), 'grupo', (d) => (d.cod === 'ES' ? 'Espanya' : d.es_ue ? 'UE' : "Resta d'Europa"))}
    x=nombre
    y=pct_mo_menos_2
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['Espanya', 'UE', "Resta d'Europa"]}
    colorPalette={['#a16207', '#a8a29e', '#d6d3d1']}
    title="% de mostres de la superfície agrària amb menys del 2 % de matèria orgànica (LUCAS 2018)"
/>

<p class="text-xs text-gray-500">LUCAS 2018 TOPSOIL (JRC): mostres de 0-20 cm de terres de conreu i prats analitzades al laboratori; països amb 20 mostres o més. Com que són anàlisis i no un model, donen menys matèria orgànica que SoilGrids al sud d'Europa.</p>

{/if}

### Europa al mapa

Les mateixes capes per a tota Europa, amb cel·les de 25 km i el mateix mètode que a Espanya.

<BotonesUrl name="capa_eu" titulo="Acolorir per" opciones={CAPAS_EU} defecto="textura" />

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
        {id: 'textura', title: 'Textura'},
        {id: 'wrb', title: 'Tipus de sòl'}
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
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Conreu principal'}
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
        {id: 'textura', title: 'Textura'},
        {id: 'arcilla_pct', title: 'Argila (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipus de sòl'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Cada punt és un quadrat de 25 × 25 km amb almenys 25 km² de superfície agrària segons CORINE 2018, amb el sòl de SoilGrids. Les mostres de laboratori de LUCAS no es dibuixen una a una: el JRC les lliura amb unes condicions d'ús que no permeten publicar-les punt a punt; a sota van resumides per regió.</p>

{/if}

### Regió a regió

Comparar països sencers amaga molt: el nord d'Itàlia no s'assembla al sud ni Andalusia a Galícia. Aquí, cada regió europea (NUTS 2) amb el model, el que ha mesurat LUCAS on hi ha almenys 10 mostres i l'erosió estimada.

<BotonesUrl name="medida_eu" titulo="Mesurar" opciones={MEDIDAS_EU} defecto="materia_organica_pct" />

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
        {id: 'pais', title: 'País'},
        {id: 'materia_organica_pct', title: 'Matèria orgànica, model (%)', fmt: 'num1'},
        {id: 'lucas_materia_organica_pct', title: 'Matèria orgànica mesurada, LUCAS (%)', fmt: 'num1'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'pct_fuertes', title: '% terres fortes', fmt: 'num0'},
        {id: 'erosion_t_ha', title: 'Erosió (t/ha i any)', fmt: 'num1'},
        {id: 'pct_erosion_moderada_grave', title: '% amb erosió moderada o greu', fmt: 'num0'}
    ]}
/>

<DataTable data={regiones_eu} rows=10 search=true>
    <Column id=nombre title="Regió" />
    <Column id=pais title="País" />
    <Column id=superficie_agraria_km2 title="Km² agraris" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=materia_organica_pct title="Matèria orgànica, model (%)" fmt=num1 />
    <Column id=lucas_materia_organica_pct title="Matèria orgànica, LUCAS (%)" fmt=num1 />
    <Column id=lucas_muestras title="Mostres LUCAS" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_fuertes title="% terres fortes" fmt=num0 />
    <Column id=erosion_t_ha title="Erosió (t/ha)" fmt=num1 />
    <Column id=pct_erosion_moderada_grave title="% erosió moderada o greu" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Regions NUTS 2 del 2021 (límits © EuroGeographics). LUCAS fa servir les del 2016: les poques regions que van canviar entre una versió i l'altra surten sense dada mesurada. Erosió: últim any publicat per Eurostat.</p>

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
    data={etiquetar(erosion_europa, 'grupo', (d) => (d.cod === 'ES' ? 'Espanya' : d.es_ue ? 'UE' : "Resta d'Europa"))}
    x=nombre
    y=pct_moderada_grave
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['Espanya', 'UE', "Resta d'Europa"]}
    colorPalette={['#b45309', '#a8a29e', '#d6d3d1']}
    title="% de la superfície agrària amb erosió moderada o greu, per país (model RUSLE del JRC)"
/>

<p class="text-xs text-gray-500">Encapçalen la llista els països amb muntanya i pluja abundant (Eslovènia, Itàlia, Àustria). Espanya és a la meitat alta: als seus camps hi pesen les pluges de tempesta, els pendents i les oliveres i vinyes amb el sòl nu entre les files. El 2000 tenia erosió moderada o greu el 31 % de la seva superfície agrària i el 2016, el 27 %.</p>

{/if}

## Fonts i notes

- **Sòl: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, llicència CC BY 4.0). Argila, llim i sorra, pH en aigua i carboni orgànic de les capes de 0-5, 5-15 i 15-30 cm (mitjanes a 1 km per a Espanya, comunitats, províncies i Europa, i la resolució original de 250 m per als municipis), ponderades pel gruix; grup de sòl WRB més probable. És un model d'aprenentatge automàtic entrenat amb milers de perfils de sòl i mapes de satèl·lit, clima i relleu: suavitza els extrems i pot fallar en una comarca concreta. Matèria orgànica = carboni orgànic × 1,724.
- **Superfície agrària i conreus: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, Agència Europea de Medi Ambient), classes agrícoles (2xx), mostrejades cada 250 m.
- **Fronteres: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) per als països i l'IGN per a les províncies.
- **Mostres de laboratori: [LUCAS 2018 TOPSOIL](https://esdac.jrc.ec.europa.eu/content/lucas-2018-topsoil-data)** (European Soil Data Centre, ESDAC, esdac.jrc.ec.europa.eu, Comissió Europea, Centre Comú de Recerca). Unes 19.000 mostres de 0-20 cm de tota la UE analitzades al laboratori; aquí, medianes i percentatges de les de terres de conreu i prats per país i per comunitat amb 10 mostres o més (sense Canàries). Panagos, P. et al. (2022), «European Soil Data Centre 2.0», European Journal of Soil Science 73(6), e13315.
- **Erosió: [Eurostat, aei_pr_soiler](https://ec.europa.eu/eurostat/databrowser/view/aei_pr_soiler/default/table)**, pèrdua de sòl per l'aigua estimada pel Centre Comú de Recerca amb el model RUSLE (pluja, pendent, sòl, coberta i pràctiques de conservació) el 2000, el 2010, el 2016 i el 2023, per a la superfície agrària i les pastures naturals, per país, regió i província (Panagos, P. et al. (2015), «The new assessment of soil loss by water erosion in Europe», Environmental Science & Policy 54).
- **Regions d'Europa: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat), regions NUTS 2 del 2021 (límits © EuroGeographics).
- Tot es calcula sobre una graella d'1 × 1 km (de 250 × 250 m als municipis) en una projecció d'àrea igual (ETRS89-LAEA), de manera que cada km² pesa el mateix. Els mapes de sòl no tenen sèrie històrica: són una foto del sòl actual.

<LastRefreshed prefix="Dades actualitzades" />
