---
title: Farm soils
description: "What kind of ground lies under Spain's crops: clayey, loamy and sandy soils, soil types (Calcisols, Cambisols, Luvisols, Vertisols...), pH and organic matter by region, province and municipality, a map every 10 km, which soil olive groves, vineyards, irrigated land and dehesa wood-pastures sit on, and the comparison with the rest of Europe."
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
        'Toda la superficie agraria': 'All farmland',
        'Secano': 'Rain-fed crops',
        'Regadío': 'Irrigated land',
        'Arrozal': 'Rice fields',
        'Viñedo': 'Vineyards',
        'Frutales': 'Fruit trees',
        'Olivar': 'Olive groves',
        'Prados': 'Meadows',
        'Mosaico de cultivos': 'Mixed crops and market gardens',
        'Dehesa': 'Dehesas (wood-pastures)'
    };
    const GRUPO = {
        'Arenosa (ligera)': 'Sandy (light soil)',
        'Franca (media)': 'Loamy (medium soil)',
        'Franco-arcillosa': 'Clay loam (heavy-ish soil)',
        'Arcillosa (pesada)': 'Clayey (heavy soil)'
    };
    const TEXTURA = {
        'Arenosa': 'Sand', 'Arenoso-franca': 'Loamy sand', 'Franco-arenosa': 'Sandy loam',
        'Franca': 'Loam', 'Franco-limosa': 'Silt loam', 'Limosa': 'Silt',
        'Franco-arcillo-arenosa': 'Sandy clay loam', 'Franco-arcillosa': 'Clay loam',
        'Franco-arcillo-limosa': 'Silty clay loam', 'Arcillo-arenosa': 'Sandy clay',
        'Arcillo-limosa': 'Silty clay', 'Arcillosa': 'Clay'
    };
    const PH = {
        'Muy ácido (< 5,5)': 'Very acidic (below 5.5)',
        'Ácido (5,5-6,5)': 'Acidic (5.5 to 6.5)',
        'Neutro (6,5-7,5)': 'Neutral (6.5 to 7.5)',
        'Básico (7,5-8,5)': 'Alkaline or calcareous (7.5 to 8.5)',
        'Muy básico (> 8,5)': 'Very alkaline (above 8.5)'
    };
    const WRB = {
        'Calcisoles': 'Calcisols', 'Cambisoles': 'Cambisols', 'Luvisoles': 'Luvisols', 'Leptosoles': 'Leptosols',
        'Vertisoles': 'Vertisols', 'Regosoles': 'Regosols', 'Fluvisoles': 'Fluvisols', 'Kastanozems': 'Kastanozems',
        'Phaeozems': 'Phaeozems', 'Gipsisoles': 'Gypsisols', 'Arenosoles': 'Arenosols', 'Umbrisoles': 'Umbrisols',
        'Podzoles': 'Podzols', 'Chernozems': 'Chernozems', 'Gleysoles': 'Gleysols', 'Solonchaks': 'Solonchaks',
        'Albeluvisoles': 'Albeluvisols', 'Andosoles': 'Andosols', 'Acrisoles': 'Acrisols', 'Alisoles': 'Alisols',
        'Histosoles': 'Histosols', 'Planosoles': 'Planosols', 'Stagnosoles': 'Stagnosols', 'Solonetz': 'Solonetz'
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
        comunidad: 'Region',
        todaEspana: 'All of Spain',
        provincia: 'Province',
        todaComunidad: 'Whole region',
        municipio: 'Municipality',
        todaProvincia: 'Whole province'
    };
    const CAPAS = [
        { value: 'textura', label: 'Texture' },
        { value: 'wrb', label: 'Soil type' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Organic matter' },
        { value: 'cultivo', label: 'Crop' }
    ];
    const MEDIDAS = [
        { value: 'pct_fuertes', label: '% of heavy soils' },
        { value: 'arcilla_pct', label: 'Average clay (%)' },
        { value: 'ph', label: 'Average pH' },
        { value: 'pct_basico', label: '% alkaline or calcareous' },
        { value: 'materia_organica_pct', label: 'Organic matter (%)' },
        { value: 'pct_calcisoles', label: '% of Calcisols' },
        { value: 'pct_agraria', label: '% of farmland' }
    ];
    const ORDEN_TEXTURA = Object.keys(TEXTURA);

    // Mapa de Europa: capa del mapa de puntos y medida del mapa de regiones (con parámetro en la URL)
    const CAPAS_EU = [
        { value: 'textura', label: 'Texture' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Organic matter' }
    ];
    const MEDIDAS_EU = [
        { value: 'materia_organica_pct', label: 'Organic matter (model)' },
        { value: 'lucas_materia_organica_pct', label: 'Measured organic matter (LUCAS)' },
        { value: 'ph', label: 'pH' },
        { value: 'pct_fuertes', label: '% of heavy soils' },
        { value: 'erosion_t_ha', label: 'Erosion (t/ha per year)' },
        { value: 'pct_erosion_moderada_grave', label: '% with moderate or severe erosion' }
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

# 🟫 Farm soils

What kind of ground lies under the crops: whether it is **clayey, loamy or sandy**, what **type of soil** it is, whether it is **calcareous or acidic** and how much **organic matter** it holds. Everything is measured over **farmland** ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} thousand km² in Spain, almost half the country) in the layer that gets worked, the top 30 cm, and matched with what is grown on top. Choose a region, a province or a municipality and the whole page, maps included, switches to that area; the page link changes with your choice so you can share it. The data come from a model (SoilGrids), not from tests of each field: they are good for comparing areas.

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

## {terr[0]?.nivel === 'pais' ? 'Spain' : terr[0]?.nombre}

<Grid cols=4>
    <KpiCard
        title="Farmland"
        value={terr[0]?.pct_agraria}
        formattedValue="{formatNumber(terr[0]?.pct_agraria, 0)} %"
        period="of the area · {formatNumber(terr[0]?.superficie_agraria_km2, 0)} km² · Spain: {formatNumber(espana[0]?.pct_agraria, 0)} %"
        direction="neutral"
        source="CORINE Land Cover 2018"
    />
    <KpiCard
        title="Heavy soils (clay loam and clay)"
        value={terr[0]?.pct_fuertes}
        formattedValue="{formatNumber(terr[0]?.pct_fuertes, 0)} %"
        period="most common texture: {et(TEXTURA, terr[0]?.textura_dominante)} · Spain: {formatNumber(espana[0]?.pct_fuertes, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="Average pH of farm soil"
        value={terr[0]?.ph}
        formattedValue={formatNumber(terr[0]?.ph, 1)}
        period="{formatNumber(terr[0]?.pct_basico, 0)} % alkaline or calcareous · {terr[0]?.nivel === 'pais' ? 'EU: ' + formatNumber(europa_resumen[0]?.basico_ue, 0) + ' %' : 'Spain: pH ' + formatNumber(espana[0]?.ph, 1)}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Average organic matter"
        value={terr[0]?.materia_organica_pct}
        formattedValue="{formatNumber(terr[0]?.materia_organica_pct, 1)} %"
        period="{terr[0]?.nivel === 'pais' ? 'EU: ' + formatNumber(europa_resumen[0]?.mo_ue, 1) + ' % · Spain: no. ' + formatNumber(europa_resumen[0]?.puesto_mo, 0) + ' lowest of ' + formatNumber(europa_resumen[0]?.paises, 0) + ' countries' : 'Spain: ' + formatNumber(espana[0]?.materia_organica_pct, 1) + ' %'} · soil type: {et(WRB, terr[0]?.wrb_dominante)}{filas(lucas_terr).length ? ' · LUCAS: ' + formatNumber(lucas_terr[0]?.materia_organica_pct, 1) + ' %' : ''}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
</Grid>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">The CORINE 2018 land-use map shows no farmland in this area.</p>

{/if}

## The dot map

<BotonesUrl name="capa" titulo="Colour by" opciones={CAPAS} defecto="textura" />

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
        {id: 'textura', title: 'Texture'},
        {id: 'wrb', title: 'Soil type'}
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
        {id: 'textura', title: 'Texture'},
        {id: 'wrb', title: 'Soil type'},
        {id: 'superficie_agraria_km2', title: 'Farmland km² in the cell', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Red: acidic soils (low pH), typical of the rainy north-west and of the granite and slate of the west. Blue: alkaline or calcareous soils (high pH), found across almost all of dry Spain, with limestone or gypsum underneath. pH decides which crops do well (chestnuts and blueberries want acidic ground; vines, almonds and olives tolerate limestone) and how much lime or sulphur has to be added.</p>

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
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Main crop'}
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
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Main crop'},
        {id: 'superficie_agraria_km2', title: 'Farmland km² in the cell', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Greener means more organic matter: the meadows of the north, with rain, grass and manure all year round. The rain-fed fields of the central plateau, the Ebro valley and the south-east, with heat, little rain and centuries of ploughing, have the farm soil poorest in organic matter in western Europe. SoilGrids tends to give somewhat more carbon than field tests in Mediterranean rain-fed land: use it to compare areas, not as a soil test.</p>

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
        {id: 'textura', title: 'Texture'},
        {id: 'arcilla_pct', title: 'Clay (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Soil type'},
        {id: 'cultivo', title: 'Main crop'}
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
        {id: 'textura', title: 'Texture'},
        {id: 'arcilla_pct', title: 'Clay (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Soil type'},
        {id: 'cultivo', title: 'Main crop'},
        {id: 'superficie_agraria_km2', title: 'Farmland km² in the cell', fmt: 'num1'}
    ]}
/>

{/if}

{/if}

<p class="text-xs text-gray-500">Each dot is a square with farmland (10 km across for the whole of Spain, 5 km in a region, 2 km in a province and 250 m in a municipality), coloured by the texture, soil type or crop that covers the most farmland in it. Where there is no dot there is woodland or scrub, rock, water or town.</p>

{/if}

## Clayey, loamy and sandy

**Texture** is the mix of clay, silt and sand in the ground, and it is the first thing a farmer looks at: a **clayey** soil ("heavy") holds water and nutrients but gets waterlogged, cracks and is hard to plough; a **sandy** one ("light") is easy to work and warms up earlier in spring, but water and fertiliser drain away; a **loamy** soil, with the three in balance, is ideal for almost everything. The farm soil of {terr[0]?.nivel === 'pais' ? 'Spain' : (terr[0]?.nombre ?? '-')} averages {formatNumber(terr[0]?.arcilla_pct, 0)} % clay, {formatNumber(terr[0]?.limo_pct, 0)} % silt and {formatNumber(terr[0]?.arena_pct, 0)} % sand.

{#if filas(dist).filter((d) => d.dimension === 'textura').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'textura').toSorted((a, b) => ORDEN_TEXTURA.indexOf(a.clase) - ORDEN_TEXTURA.indexOf(b.clase)), 'textura_texto', (d) => et(TEXTURA, d.clase))}
    x=textura_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a5a34"
    title="Farmland by USDA texture class (%)"
/>

{/if}

<p class="text-xs text-gray-500">Classes from the soil texture triangle of the US Department of Agriculture (USDA), the ones farm laboratories use in Spain. SoilGrids is a model that smooths out the extremes: very clayey ground (the <i>bujeos</i>, heavy black clays of the Guadalquivir countryside, or the <i>tierras de barro</i>, "mud lands", of Tierra de Campos) shows up as clay loam, and very sandy ground as sandy loam. That is why there are few pure clay or sand classes, and clay loams and clays are best read together as "heavy soils".</p>

## Soil types

Besides texture, soil scientists classify soils by how they formed. In the international classification (WRB, from the FAO), Spain's farmland is mostly **Luvisols** (old soils with clay built up at the bottom, like the red soils of La Mancha and Extremadura), **Cambisols** (young, little-developed soils), **Calcisols** (with a layer of limestone, typical of dry Spain), **Leptosols** (thin soils over rock, on slopes) and **Vertisols** (clays that swell when wet and crack when they dry, the "black soils" of the Andalusian countryside).

{#if filas(dist).filter((d) => d.dimension === 'wrb').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
    x=wrb_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c4524b"
    title="Farmland by soil type (WRB, %)"
/>

{/if}

## pH and organic matter

{formatNumber(espana[0]?.pct_basico, 0)} % of Spain's farmland is **alkaline or calcareous** (pH 7.5 or higher), against {formatNumber(europa_resumen[0]?.basico_ue, 0)} % in the EU: limestone and gypsum underground and scarce rain, which does not wash the salts away, push the pH up. Only the Cantabrian coast, Galicia and the granite and slate west (Salamanca, Cáceres) have acidic soils.

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
    title={terr[0]?.nivel === 'pais' ? 'Farmland by soil pH, by region' : 'Farmland by soil pH, by province'}
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
    title="Farmland by soil pH (%)"
/>

{/if}

**Organic matter** (decomposed remains of plants, roots and manure) gives the soil structure, holds water and feeds the crops. With heat, little rain and centuries of ploughing, Spanish farm soil averages {formatNumber(espana[0]?.materia_organica_pct, 1)} %, against {formatNumber(europa_resumen[0]?.mo_ue, 1)} % in the EU. It ranks no. {formatNumber(europa_resumen[0]?.puesto_mo, 0)} poorest of the {formatNumber(europa_resumen[0]?.paises, 0)} European countries compared (the three with the least: {europa_resumen[0]?.menos_mo ?? '-'}).

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

<p>The <b>laboratory samples</b> of the European LUCAS programme (2018) show less organic matter than the model: on the farmland of {lucas_terr[0]?.nombre}, the median of its {formatNumber(lucas_terr[0]?.muestras, 0)} samples is {formatNumber(lucas_terr[0]?.materia_organica_pct, 1)} %, and {formatNumber(lucas_terr[0]?.pct_mo_menos_2, 0)} % are below 2 % ({formatNumber(lucas_terr[0]?.pct_mo_menos_1, 0)} % below 1 %). For organic matter, trust these tests more than the map: SoilGrids gives more carbon than is measured in rain-fed land.</p>

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
    title="Organic matter measured on the farmland of each region: median of the LUCAS 2018 samples (%)"
/>

{/if}

## Erosion

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
    '/en/territorios/suelos?provincia=' || t.slug AS enlace
FROM mother.suelos_erosion e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.suelos_erosion)
```

Every year rain washes away the fertile layer of fields on slopes, above all ploughed ones, left without plant cover and hit by heavy storms: a centimetre of soil takes centuries to form. According to the model of the European Commission's Joint Research Centre, the farmland of {erosion_terr.slice(-1)[0]?.nombre ?? '-'} loses an average of {formatNumber(erosion_terr.slice(-1)[0]?.erosion_t_ha, 1)} tonnes of soil per hectare per year ({erosion_terr.slice(-1)[0]?.anio ?? '-'}; Spain: {formatNumber(erosion_espana[0]?.erosion_t_ha, 1)}), and {formatNumber(erosion_terr.slice(-1)[0]?.pct_moderada_grave, 0)} % suffers moderate or severe erosion, more than 5 t/ha, which is more than the soil can rebuild.

{#if filas(erosion_terr).length > 1}

<LineChart
    data={erosion_terr}
    x=anio
    y=pct_moderada_grave
    xFmt="0"
    yFmt=num1
    markers=true
    title="% of farmland with moderate or severe erosion (more than 5 t/ha per year)"
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
        {id: 'pct_moderada_grave', title: '% with moderate or severe erosion', fmt: 'num1'},
        {id: 'pct_grave', title: '% with severe erosion (more than 10 t/ha)', fmt: 'num1'},
        {id: 'erosion_t_ha', title: 'Average loss (t/ha per year)', fmt: 'num1'}
    ]}
/>

{/if}

{#if filas(lucas_terr).length > 0}

<p class="text-xs text-gray-500">Erosion estimated with the JRC's RUSLE model (rainfall, slope, soil, crop and conservation practices) for farmland and natural grassland, published by Eurostat; the Balearic and Canary Islands are counted in their province. The signs seen in the field by LUCAS surveyors in 2018 (within 500 m of the point) point the same way: they appear at {formatNumber(lucas_terr[0]?.pct_erosion_visible, 0)} % of the farmland points of {lucas_terr[0]?.nombre} and there are gullies at {formatNumber(lucas_terr[0]?.pct_carcavas, 1)} %; that is a minimum, because a grown crop hides many signs.</p>

{/if}

## Comparing within the area

<BotonesUrl name="medida" titulo="Measure" opciones={MEDIDAS} defecto="pct_fuertes" />

```sql mapa_hijos
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT t.cod, t.nombre, '/en/territorios/suelos?provincia=' || tt.slug AS enlace, t.superficie_agraria_km2, t.textura_dominante,
    t.arcilla_pct, t.ph, t.materia_organica_pct, t.wrb_dominante, coalesce(t.pct_fuertes, 0) AS pct_fuertes,
    t.${inputs.medida} AS medida
FROM mother.suelos_territorio t
JOIN mother.territorios tt ON tt.nivel = t.nivel AND tt.cod = t.cod
JOIN f ON f.nivel = 'pais'
WHERE t.nivel = 'provincia' AND t.cultivo = 'Toda la superficie agraria' AND t.cod NOT IN ('51', '52')
UNION ALL
SELECT m.cod_mun, m.municipio, '/en/territorios/suelos?m=' || m.cod_mun AS enlace, m.superficie_agraria_km2, m.textura_dominante,
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
        {id: 'superficie_agraria_km2', title: 'Farmland km²', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Most common texture'},
        {id: 'pct_fuertes', title: '% heavy soils', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Soil type'}
    ]}
/>

<p class="text-xs text-gray-500">Provinces of Spain. Click one to see that province's soil here, with the map of its municipalities.</p>

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
        {id: 'superficie_agraria_km2', title: 'Farmland km²', fmt: 'num1'},
        {id: 'textura_dominante', title: 'Most common texture'},
        {id: 'pct_fuertes', title: '% heavy soils', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Soil type'}
    ]}
/>

<p class="text-xs text-gray-500">Municipalities. Click one to see its soil here, with its 250 m cell map. In grey, municipalities with no farmland on the CORINE map (woodland, town or plots under 25 ha).</p>

{/if}

<DataTable data={mapa_hijos} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=nombre title={terr[0]?.nivel === 'pais' ? 'Province' : 'Municipality'} />
    <Column id=superficie_agraria_km2 title="Farmland km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Most common texture" />
    <Column id=pct_fuertes title="% heavy soils" fmt=num0 />
    <Column id=arcilla_pct title="Clay (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Organic matter (%)" fmt=num1 />
    <Column id=wrb_dominante title="Soil type" />
</DataTable>

<p class="text-xs text-gray-500">Heavy soils = the six clay loam and clay textures of the USDA triangle (generally more than a quarter clay). For municipalities, farmland and soil come from each 250 m cell within the municipality (CORINE and SoilGrids at their original resolution). Ceuta and Melilla have almost no farmland.</p>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">A municipality is the smallest unit: its 250 m cell map is above. Choose "Whole province" in the filter to compare it with the other municipalities.</p>

{/if}

## Which soil each crop sits on

Farmland is split according to the CORINE 2018 land-use map. Each crop sits on a different kind of ground: in Spain, dehesa wood-pastures are on the sandy, acidic soils of the west; olive groves and irrigated land on the most clayey soils of the valleys; vineyards on the most calcareous and poorest soils.

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
    title="Soil texture under each crop"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Crop" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num1 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_de_la_agraria title="% of farmland" fmt=num1 />
    <Column id=textura_dominante title="Most common texture" />
    <Column id=arcilla_pct title="Clay (%)" fmt=num0 />
    <Column id=arena_pct title="Sand (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% alkaline" fmt=num0 />
    <Column id=materia_organica_pct title="Organic matter (%)" fmt=num1 />
    <Column id=wrb_dominante title="Soil type" />
</DataTable>

{/if}

<p class="text-xs text-gray-500">Crops from CORINE Land Cover 2018: rain-fed = arable land without irrigation (cereals, sunflower, pulses); irrigated = permanently irrigated arable land (maize, vegetables, cotton...); fruit trees include citrus, almonds and nuts; mixed = small plots of different crops side by side, market gardens and crops mixed with natural vegetation; dehesa = holm oak or cork oak woodland with pasture or crops underneath. CORINE does not map plots under 25 ha, which are added to whatever surrounds them.</p>

## Compared with Europe

Same method for every country: the SoilGrids model over CORINE 2018 farmland.

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(europa, 'grupo', (d) => (d.cod_pais === 'ES' ? 'Spain' : d.es_ue ? 'EU' : 'Rest of Europe'))}
    x=pais
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['Spain', 'EU', 'Rest of Europe']}
    colorPalette={['#c2410c', '#a8a29e', '#d6d3d1']}
    title="Average organic matter in farm soil (%)"
/>

{/if}

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(filas(europa).toSorted((a, b) => b.ph - a.ph), 'grupo', (d) => (d.cod_pais === 'ES' ? 'Spain' : d.es_ue ? 'EU' : 'Rest of Europe'))}
    x=pais
    y=ph
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    yMin={4}
    seriesOrder={['Spain', 'EU', 'Rest of Europe']}
    colorPalette={['#1e3a8a', '#a8a29e', '#d6d3d1']}
    title="Average pH of farm soil"
/>

{/if}

<DataTable data={europa} rows=12 search=true>
    <Column id=pais title="Country" />
    <Column id=superficie_agraria_km2 title="Farmland km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Most common texture" />
    <Column id=arcilla_pct title="Clay (%)" fmt=num0 />
    <Column id=arena_pct title="Sand (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% alkaline" fmt=num0 />
    <Column id=materia_organica_pct title="Organic matter (%)" fmt=num1 />
    <Column id=wrb_dominante title="Soil type" />
</DataTable>

<p class="text-xs text-gray-500">Cyprus, Greece, Spain, Italy and Turkey have the most alkaline farm soils, and {europa_resumen[0]?.menos_mo ?? '-'} those with the least organic matter; the north (Ireland, the Nordic countries, the United Kingdom, the Netherlands) has the most acidic and organic ones, with wet meadows and, in some, peat. Countries with at least 1,000 km² of farmland in CORINE (excluding Malta). Below, the LUCAS laboratory samples, which confirm Spain's position.</p>

```sql lucas_europa
SELECT cod, nombre, es_ue, muestras, materia_organica_pct, pct_mo_menos_2, ph, puesto_mo_menor, territorios
FROM mother.suelos_lucas
WHERE nivel = 'pais' AND uso = 'Agraria' AND muestras >= 20
ORDER BY materia_organica_pct
```

{#if filas(lucas_europa).length > 0}

<BarChart
    data={etiquetar(lucas_europa, 'grupo', (d) => (d.cod === 'ES' ? 'Spain' : d.es_ue ? 'EU' : 'Rest of Europe'))}
    x=nombre
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['Spain', 'EU', 'Rest of Europe']}
    colorPalette={['#65a30d', '#a8a29e', '#d6d3d1']}
    title="Organic matter measured on farmland: median of the LUCAS 2018 samples (%)"
/>

<BarChart
    data={etiquetar(filas(lucas_europa).toSorted((a, b) => b.pct_mo_menos_2 - a.pct_mo_menos_2), 'grupo', (d) => (d.cod === 'ES' ? 'Spain' : d.es_ue ? 'EU' : 'Rest of Europe'))}
    x=nombre
    y=pct_mo_menos_2
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['Spain', 'EU', 'Rest of Europe']}
    colorPalette={['#a16207', '#a8a29e', '#d6d3d1']}
    title="% of farmland samples with less than 2 % organic matter (LUCAS 2018)"
/>

<p class="text-xs text-gray-500">LUCAS 2018 TOPSOIL (JRC): 0-20 cm samples from cropland and grassland tested in the laboratory; countries with 20 samples or more. As tests rather than a model, they show less organic matter than SoilGrids in southern Europe.</p>

{/if}

### Europe on the map

The same layers for the whole of Europe, with 25 km cells and the same method as in Spain.

<BotonesUrl name="capa_eu" titulo="Colour by" opciones={CAPAS_EU} defecto="textura" />

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
        {id: 'textura', title: 'Texture'},
        {id: 'wrb', title: 'Soil type'}
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
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Main crop'}
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
        {id: 'textura', title: 'Texture'},
        {id: 'arcilla_pct', title: 'Clay (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Soil type'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Each dot is a 25 × 25 km square with at least 25 km² of farmland according to CORINE 2018, with the soil from SoilGrids. The LUCAS laboratory samples are not drawn one by one: the JRC supplies them under terms of use that do not allow publishing them point by point; below they are summarised by region.</p>

{/if}

### Region by region

Comparing whole countries hides a lot: northern Italy is nothing like the south, nor Andalusia like Galicia. Here, each European region (NUTS 2) with the model, what LUCAS measured where there are at least 10 samples, and the estimated erosion.

<BotonesUrl name="medida_eu" titulo="Measure" opciones={MEDIDAS_EU} defecto="materia_organica_pct" />

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
        {id: 'pais', title: 'Country'},
        {id: 'materia_organica_pct', title: 'Organic matter, model (%)', fmt: 'num1'},
        {id: 'lucas_materia_organica_pct', title: 'Measured organic matter, LUCAS (%)', fmt: 'num1'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'pct_fuertes', title: '% heavy soils', fmt: 'num0'},
        {id: 'erosion_t_ha', title: 'Erosion (t/ha per year)', fmt: 'num1'},
        {id: 'pct_erosion_moderada_grave', title: '% with moderate or severe erosion', fmt: 'num0'}
    ]}
/>

<DataTable data={regiones_eu} rows=10 search=true>
    <Column id=nombre title="Region" />
    <Column id=pais title="Country" />
    <Column id=superficie_agraria_km2 title="Farmland km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=materia_organica_pct title="Organic matter, model (%)" fmt=num1 />
    <Column id=lucas_materia_organica_pct title="Organic matter, LUCAS (%)" fmt=num1 />
    <Column id=lucas_muestras title="LUCAS samples" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_fuertes title="% heavy soils" fmt=num0 />
    <Column id=erosion_t_ha title="Erosion (t/ha)" fmt=num1 />
    <Column id=pct_erosion_moderada_grave title="% moderate or severe erosion" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">2021 NUTS 2 regions (boundaries © EuroGeographics). LUCAS uses the 2016 ones: the few regions that changed between the two versions have no measured figure. Erosion: latest year published by Eurostat.</p>

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
    data={etiquetar(erosion_europa, 'grupo', (d) => (d.cod === 'ES' ? 'Spain' : d.es_ue ? 'EU' : 'Rest of Europe'))}
    x=nombre
    y=pct_moderada_grave
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['Spain', 'EU', 'Rest of Europe']}
    colorPalette={['#b45309', '#a8a29e', '#d6d3d1']}
    title="% of farmland with moderate or severe erosion, by country (JRC RUSLE model)"
/>

<p class="text-xs text-gray-500">The list is headed by countries with mountains and plenty of rain (Slovenia, Italy, Austria). Spain is in the upper half: its fields are hit by storm rains, slopes, and olive groves and vineyards with bare soil between the rows. In 2000, 31 % of its farmland had moderate or severe erosion, and in 2016, 27 %.</p>

{/if}

## Sources and notes

- **Soil: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, CC BY 4.0 licence). Clay, silt and sand, pH in water and organic carbon of the 0-5, 5-15 and 15-30 cm layers (1 km averages for Spain, regions, provinces and Europe, and the original 250 m resolution for municipalities), weighted by thickness; most likely WRB soil group. It is a machine-learning model trained on thousands of soil profiles and satellite, climate and terrain maps: it smooths out the extremes and can be wrong for a particular district. Organic matter = organic carbon × 1.724.
- **Farmland and crops: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, European Environment Agency), agricultural classes (2xx), sampled every 250 m.
- **Borders: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) for countries and the IGN (Spain's National Geographic Institute) for provinces.
- **Laboratory samples: [LUCAS 2018 TOPSOIL](https://esdac.jrc.ec.europa.eu/content/lucas-2018-topsoil-data)** (European Soil Data Centre, ESDAC, esdac.jrc.ec.europa.eu, European Commission, Joint Research Centre). About 19,000 samples of 0-20 cm from across the EU tested in the laboratory; here, medians and percentages for cropland and grassland by country and by region with 10 samples or more (no Canary Islands). Panagos, P. et al. (2022), 'European Soil Data Centre 2.0', European Journal of Soil Science 73(6), e13315.
- **Erosion: [Eurostat, aei_pr_soiler](https://ec.europa.eu/eurostat/databrowser/view/aei_pr_soiler/default/table)**, soil loss by water estimated by the Joint Research Centre with the RUSLE model (rainfall, slope, soil, cover and conservation practices) in 2000, 2010, 2016 and 2023, for farmland and natural grassland, by country, region and province (Panagos, P. et al. (2015), 'The new assessment of soil loss by water erosion in Europe', Environmental Science & Policy 54).
- **Regions of Europe: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat), 2021 NUTS 2 regions (boundaries © EuroGeographics).
- Everything is calculated on a 1 × 1 km grid (250 × 250 m for municipalities) in an equal-area projection (ETRS89-LAEA), so every km² carries the same weight. Soil maps have no historical series: they are a snapshot of today's soil.

<LastRefreshed prefix="Data updated" />
