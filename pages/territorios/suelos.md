---
title: Suelos agrarios
description: "Qué tierra hay debajo de los cultivos de España: suelos arcillosos, francos y arenosos, tipos de suelo (calcisoles, cambisoles, luvisoles, vertisoles...), pH y materia orgánica por comunidad, provincia y municipio, mapa cada 10 km, qué suelo tiene el olivar, el viñedo, el regadío o la dehesa y comparación con el resto de Europa."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import MapaBarrios from '../../../../../../src/lib/components/MapaBarrios.svelte';
    import { celdasMunicipio } from '../../../../../../src/lib/suelos.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import FiltroTerritorio from '../../../../../../src/lib/components/FiltroTerritorio.svelte';
    import BotonesUrl from '../../../../../../src/lib/components/BotonesUrl.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones.
    // Las claves son los valores de los datos (en castellano).
    const CULTIVO = {
        'Toda la superficie agraria': 'Toda la superficie agraria',
        'Secano': 'Cultivos de secano',
        'Regadío': 'Regadío',
        'Arrozal': 'Arrozales',
        'Viñedo': 'Viñedo',
        'Frutales': 'Frutales',
        'Olivar': 'Olivar',
        'Prados': 'Prados',
        'Mosaico de cultivos': 'Mosaico de cultivos y huertas',
        'Dehesa': 'Dehesas'
    };
    const GRUPO = {
        'Arenosa (ligera)': 'Arenosa (tierra ligera)',
        'Franca (media)': 'Franca (tierra media)',
        'Franco-arcillosa': 'Franco-arcillosa (tierra fuerte)',
        'Arcillosa (pesada)': 'Arcillosa (tierra pesada)'
    };
    const TEXTURA = {
        'Arenosa': 'Arenosa', 'Arenoso-franca': 'Arenoso-franca', 'Franco-arenosa': 'Franco-arenosa',
        'Franca': 'Franca', 'Franco-limosa': 'Franco-limosa', 'Limosa': 'Limosa',
        'Franco-arcillo-arenosa': 'Franco-arcillo-arenosa', 'Franco-arcillosa': 'Franco-arcillosa',
        'Franco-arcillo-limosa': 'Franco-arcillo-limosa', 'Arcillo-arenosa': 'Arcillo-arenosa',
        'Arcillo-limosa': 'Arcillo-limosa', 'Arcillosa': 'Arcillosa'
    };
    const PH = {
        'Muy ácido (< 5,5)': 'Muy ácido (menos de 5,5)',
        'Ácido (5,5-6,5)': 'Ácido (5,5 a 6,5)',
        'Neutro (6,5-7,5)': 'Neutro (6,5 a 7,5)',
        'Básico (7,5-8,5)': 'Básico o calizo (7,5 a 8,5)',
        'Muy básico (> 8,5)': 'Muy básico (más de 8,5)'
    };
    const WRB = {
        'Calcisoles': 'Calcisoles', 'Cambisoles': 'Cambisoles', 'Luvisoles': 'Luvisoles', 'Leptosoles': 'Leptosoles',
        'Vertisoles': 'Vertisoles', 'Regosoles': 'Regosoles', 'Fluvisoles': 'Fluvisoles', 'Kastanozems': 'Kastanozems',
        'Phaeozems': 'Phaeozems', 'Gipsisoles': 'Gipsisoles', 'Arenosoles': 'Arenosoles', 'Umbrisoles': 'Umbrisoles',
        'Podzoles': 'Podzoles', 'Chernozems': 'Chernozems', 'Gleysoles': 'Gleysoles', 'Solonchaks': 'Solonchaks',
        'Albeluvisoles': 'Albeluvisoles', 'Andosoles': 'Andosoles', 'Acrisoles': 'Acrisoles', 'Alisoles': 'Alisoles',
        'Histosoles': 'Histosoles', 'Planosoles': 'Planosoles', 'Stagnosoles': 'Stagnosoles', 'Solonetz': 'Solonetz'
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
        comunidad: 'Comunidad autónoma',
        todaEspana: 'Toda España',
        provincia: 'Provincia',
        todaComunidad: 'Toda la comunidad',
        municipio: 'Municipio',
        todaProvincia: 'Toda la provincia'
    };
    const CAPAS = [
        { value: 'textura', label: 'Textura' },
        { value: 'wrb', label: 'Tipo de suelo' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Materia orgánica' },
        { value: 'cultivo', label: 'Cultivo' }
    ];
    const MEDIDAS = [
        { value: 'pct_fuertes', label: '% de tierras fuertes' },
        { value: 'arcilla_pct', label: 'Arcilla media (%)' },
        { value: 'ph', label: 'pH medio' },
        { value: 'pct_basico', label: '% básico o calizo' },
        { value: 'materia_organica_pct', label: 'Materia orgánica (%)' },
        { value: 'pct_calcisoles', label: '% de calcisoles' },
        { value: 'pct_agraria', label: '% de superficie agraria' }
    ];
    const ORDEN_TEXTURA = Object.keys(TEXTURA);

    // Mapa de Europa: capa del mapa de puntos y medida del mapa de regiones (con parámetro en la URL)
    const CAPAS_EU = [
        { value: 'textura', label: 'Textura' },
        { value: 'ph', label: 'pH' },
        { value: 'mo', label: 'Materia orgánica' }
    ];
    const MEDIDAS_EU = [
        { value: 'materia_organica_pct', label: 'Materia orgánica (modelo)' },
        { value: 'lucas_materia_organica_pct', label: 'Materia orgánica medida (LUCAS)' },
        { value: 'ph', label: 'pH' },
        { value: 'pct_fuertes', label: '% de tierras fuertes' },
        { value: 'erosion_t_ha', label: 'Erosión (t/ha y año)' },
        { value: 'pct_erosion_moderada_grave', label: '% con erosión moderada o grave' }
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

# 🟫 Suelos agrarios

Qué tierra hay debajo de los cultivos: si es **arcillosa, franca o arenosa**, qué **tipo de suelo** es, si es **caliza o ácida** y cuánta **materia orgánica** tiene. Todo se mide sobre la **superficie agraria** ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} mil km² en España, casi la mitad del país) en la capa que se trabaja, los primeros 30 cm, y se cruza con lo que se cultiva encima. Elige una comunidad, una provincia o un municipio y toda la página, mapas incluidos, pasa a ese territorio; el enlace de la página cambia con tu elección para que puedas compartirlo. Los datos salen de un modelo (SoilGrids), no de análisis de cada parcela: sirven para comparar zonas.

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

## {terr[0]?.nivel === 'pais' ? 'España' : terr[0]?.nombre}

<Grid cols=4>
    <KpiCard
        title="Superficie agraria"
        value={terr[0]?.pct_agraria}
        formattedValue="{formatNumber(terr[0]?.pct_agraria, 0)} %"
        period="del territorio · {formatNumber(terr[0]?.superficie_agraria_km2, 0)} km² · España: {formatNumber(espana[0]?.pct_agraria, 0)} %"
        direction="neutral"
        source="CORINE Land Cover 2018"
    />
    <KpiCard
        title="Tierras fuertes (franco-arcillosas y arcillosas)"
        value={terr[0]?.pct_fuertes}
        formattedValue="{formatNumber(terr[0]?.pct_fuertes, 0)} %"
        period="textura más frecuente: {et(TEXTURA, terr[0]?.textura_dominante)} · España: {formatNumber(espana[0]?.pct_fuertes, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="pH medio del suelo agrario"
        value={terr[0]?.ph}
        formattedValue={formatNumber(terr[0]?.ph, 1)}
        period="{formatNumber(terr[0]?.pct_basico, 0)} % básico o calizo · {terr[0]?.nivel === 'pais' ? 'UE: ' + formatNumber(europa_resumen[0]?.basico_ue, 0) + ' %' : 'España: pH ' + formatNumber(espana[0]?.ph, 1)}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Materia orgánica media"
        value={terr[0]?.materia_organica_pct}
        formattedValue="{formatNumber(terr[0]?.materia_organica_pct, 1)} %"
        period="{terr[0]?.nivel === 'pais' ? 'UE: ' + formatNumber(europa_resumen[0]?.mo_ue, 1) + ' % · España, ' + formatNumber(europa_resumen[0]?.puesto_mo, 0) + '.ª con menos de ' + formatNumber(europa_resumen[0]?.paises, 0) + ' países' : 'España: ' + formatNumber(espana[0]?.materia_organica_pct, 1) + ' %'} · tipo de suelo: {et(WRB, terr[0]?.wrb_dominante)}{filas(lucas_terr).length ? ' · LUCAS: ' + formatNumber(lucas_terr[0]?.materia_organica_pct, 1) + ' %' : ''}"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
</Grid>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">El mapa de usos del suelo CORINE 2018 no marca superficie agraria en este territorio.</p>

{/if}

## El mapa de puntos

<BotonesUrl name="capa" titulo="Colorear por" opciones={CAPAS} defecto="textura" />

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
        {id: 'wrb', title: 'Tipo de suelo'}
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
        {id: 'wrb', title: 'Tipo de suelo'},
        {id: 'superficie_agraria_km2', title: 'Km² agrarios en la celda', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Rojo: suelos ácidos (pH bajo), típicos del noroeste lluvioso y de los granitos y pizarras del oeste. Azul: suelos básicos o calizos (pH alto), los de casi toda la España seca, con caliza o yeso en el subsuelo. El pH decide qué cultivos van bien (el castaño o el arándano quieren tierra ácida; la vid, el almendro o el olivo aguantan la caliza) y cuánta cal o azufre hay que echar.</p>

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
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Cultivo principal'}
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
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Cultivo principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agrarios en la celda', fmt: 'num1'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Más verde, más materia orgánica: los prados del norte, con lluvia, hierba y estiércol todo el año. Los secanos de la meseta, el valle del Ebro y el sureste, con calor, poca lluvia y siglos de labranza, tienen el suelo agrario más pobre en materia orgánica de Europa occidental. SoilGrids suele dar algo más de carbono que los análisis de campo en los secanos mediterráneos: compara zonas, no tomes la cifra como un análisis.</p>

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
        {id: 'arcilla_pct', title: 'Arcilla (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipo de suelo'},
        {id: 'cultivo', title: 'Cultivo principal'}
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
        {id: 'arcilla_pct', title: 'Arcilla (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipo de suelo'},
        {id: 'cultivo', title: 'Cultivo principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agrarios en la celda', fmt: 'num1'}
    ]}
/>

{/if}

{/if}

<p class="text-xs text-gray-500">Cada punto es un cuadrado con superficie agraria (de 10 km de lado para toda España, de 5 km en una comunidad, de 2 km en una provincia y de 250 m en un municipio), coloreado por la textura, el tipo de suelo o el cultivo que más superficie agraria ocupa en él. Donde no hay punto hay monte, roca, agua o ciudad.</p>

{/if}

## Arcillosos, francos y arenosos

La **textura** es la proporción de arcilla, limo y arena de la tierra, y es lo primero que mira un agricultor: una tierra **arcillosa** («fuerte» o «pesada») guarda agua y nutrientes pero se encharca, se agrieta y cuesta labrarla; una **arenosa** («ligera») se trabaja con facilidad y se calienta antes en primavera, pero el agua y el abono se le escapan; la **franca**, con las tres cosas equilibradas, es la ideal para casi todo. El suelo agrario de {terr[0]?.nivel === 'pais' ? 'España' : (terr[0]?.nombre ?? '-')} tiene de media un {formatNumber(terr[0]?.arcilla_pct, 0)} % de arcilla, un {formatNumber(terr[0]?.limo_pct, 0)} % de limo y un {formatNumber(terr[0]?.arena_pct, 0)} % de arena.

{#if filas(dist).filter((d) => d.dimension === 'textura').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'textura').toSorted((a, b) => ORDEN_TEXTURA.indexOf(a.clase) - ORDEN_TEXTURA.indexOf(b.clase)), 'textura_texto', (d) => et(TEXTURA, d.clase))}
    x=textura_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a5a34"
    title="Superficie agraria por clase de textura del USDA (%)"
/>

{/if}

<p class="text-xs text-gray-500">Clases del triángulo de texturas del Departamento de Agricultura de EE. UU. (USDA), las que usan los laboratorios agrarios en España. SoilGrids es un modelo que suaviza los extremos: las tierras muy arcillosas (los «bujeos» de la campiña del Guadalquivir, las «tierras de barro» de Tierra de Campos) aparecen como franco-arcillosas y las muy arenosas, como franco-arenosas. Por eso hay pocas clases puras de arcilla o arena y conviene leer juntas las franco-arcillosas y las arcillosas como «tierras fuertes».</p>

## Tipos de suelo

Además de la textura, los edafólogos clasifican los suelos por cómo se han formado. En la clasificación internacional (WRB, de la FAO), la España agraria es sobre todo de **luvisoles** (suelos viejos con arcilla acumulada en el fondo, como las tierras rojas de la Mancha y Extremadura), **cambisoles** (suelos jóvenes, poco evolucionados), **calcisoles** (con una capa de caliza, típicos de la España seca), **leptosoles** (suelos finos sobre roca, en laderas) y **vertisoles** (arcillas que se hinchan con el agua y se agrietan al secarse, las «tierras negras» de la campiña andaluza).

{#if filas(dist).filter((d) => d.dimension === 'wrb').length > 0}

<BarChart
    data={etiquetar(filas(dist).filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
    x=wrb_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c4524b"
    title="Superficie agraria por tipo de suelo (WRB, %)"
/>

{/if}

## pH y materia orgánica

El {formatNumber(espana[0]?.pct_basico, 0)} % de la tierra agraria de España es **básica o caliza** (pH de 7,5 o más), frente al {formatNumber(europa_resumen[0]?.basico_ue, 0)} % de la UE: la caliza y el yeso del subsuelo y la poca lluvia, que no lava las sales, suben el pH. Solo la cornisa cantábrica, Galicia y el oeste de granito y pizarra (Salamanca, Cáceres) tienen suelos ácidos.

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
    title={terr[0]?.nivel === 'pais' ? 'Superficie agraria por pH del suelo, por comunidad' : 'Superficie agraria por pH del suelo, por provincia'}
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
    title="Superficie agraria por pH del suelo (%)"
/>

{/if}

La **materia orgánica** (restos de plantas, raíces y estiércol descompuestos) da estructura a la tierra, retiene el agua y alimenta los cultivos. Con calor, poca lluvia y siglos de labranza, el suelo agrario español tiene de media un {formatNumber(espana[0]?.materia_organica_pct, 1)} %, frente al {formatNumber(europa_resumen[0]?.mo_ue, 1)} % de la UE. Es el {formatNumber(europa_resumen[0]?.puesto_mo, 0)}.º más pobre de los {formatNumber(europa_resumen[0]?.paises, 0)} países europeos comparados (los tres con menos: {europa_resumen[0]?.menos_mo ?? '-'}).

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

<p>Las <b>muestras de laboratorio</b> del programa europeo LUCAS (2018) dan menos materia orgánica que el modelo: en la superficie agraria de {lucas_terr[0]?.nombre}, la mediana de sus {formatNumber(lucas_terr[0]?.muestras, 0)} muestras es un {formatNumber(lucas_terr[0]?.materia_organica_pct, 1)} %, y el {formatNumber(lucas_terr[0]?.pct_mo_menos_2, 0)} % no llega al 2 % (el {formatNumber(lucas_terr[0]?.pct_mo_menos_1, 0)} %, ni al 1 %). Para la materia orgánica, fíate más de estos análisis que del mapa: SoilGrids da más carbono del que se mide en los secanos.</p>

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
    title="Materia orgánica medida en la superficie agraria de cada comunidad: mediana de las muestras LUCAS 2018 (%)"
/>

{/if}

## Erosión

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
    '/territorios/suelos?provincia=' || t.slug AS enlace
FROM mother.suelos_erosion e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.suelos_erosion)
```

La lluvia arrastra cada año la capa fértil de los campos en pendiente, sobre todo los labrados, sin cubierta vegetal y con tormentas fuertes: un centímetro de suelo tarda siglos en formarse. Según el modelo del Centro Común de Investigación de la Comisión Europea, la superficie agraria de {erosion_terr.slice(-1)[0]?.nombre ?? '-'} pierde de media {formatNumber(erosion_terr.slice(-1)[0]?.erosion_t_ha, 1)} toneladas de suelo por hectárea y año ({erosion_terr.slice(-1)[0]?.anio ?? '-'}; España: {formatNumber(erosion_espana[0]?.erosion_t_ha, 1)}), y el {formatNumber(erosion_terr.slice(-1)[0]?.pct_moderada_grave, 0)} % sufre erosión moderada o grave, más de 5 t/ha, que es más de lo que el suelo se regenera.

{#if filas(erosion_terr).length > 1}

<LineChart
    data={erosion_terr}
    x=anio
    y=pct_moderada_grave
    xFmt="0"
    yFmt=num1
    markers=true
    title="% de la superficie agraria con erosión moderada o grave (más de 5 t/ha y año)"
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
        {id: 'pct_moderada_grave', title: '% con erosión moderada o grave', fmt: 'num1'},
        {id: 'pct_grave', title: '% con erosión grave (más de 10 t/ha)', fmt: 'num1'},
        {id: 'erosion_t_ha', title: 'Pérdida media (t/ha y año)', fmt: 'num1'}
    ]}
/>

{/if}

{#if filas(lucas_terr).length > 0}

<p class="text-xs text-gray-500">Erosión estimada con el modelo RUSLE del JRC (lluvia, pendiente, suelo, cultivo y prácticas de conservación) para la superficie agraria y los pastos naturales, publicada por Eurostat; las islas de Baleares y Canarias se suman en su provincia. Las señales vistas en el campo por los encuestadores de LUCAS en 2018 (a menos de 500 m del punto) apuntan en la misma dirección: aparecen en el {formatNumber(lucas_terr[0]?.pct_erosion_visible, 0)} % de los puntos agrarios de {lucas_terr[0]?.nombre} y hay cárcavas en el {formatNumber(lucas_terr[0]?.pct_carcavas, 1)} %; es un mínimo, porque el cultivo crecido tapa muchas señales.</p>

{/if}

## Comparar dentro del territorio

<BotonesUrl name="medida" titulo="Medir" opciones={MEDIDAS} defecto="pct_fuertes" />

```sql mapa_hijos
WITH f AS (SELECT split_part('${inputs.territorio}', '-', 1) AS nivel, split_part('${inputs.territorio}', '-', 2) AS cod)
SELECT t.cod, t.nombre, '/territorios/suelos?provincia=' || tt.slug AS enlace, t.superficie_agraria_km2, t.textura_dominante,
    t.arcilla_pct, t.ph, t.materia_organica_pct, t.wrb_dominante, coalesce(t.pct_fuertes, 0) AS pct_fuertes,
    t.${inputs.medida} AS medida
FROM mother.suelos_territorio t
JOIN mother.territorios tt ON tt.nivel = t.nivel AND tt.cod = t.cod
JOIN f ON f.nivel = 'pais'
WHERE t.nivel = 'provincia' AND t.cultivo = 'Toda la superficie agraria' AND t.cod NOT IN ('51', '52')
UNION ALL
SELECT m.cod_mun, m.municipio, '/territorios/suelos?m=' || m.cod_mun AS enlace, m.superficie_agraria_km2, m.textura_dominante,
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
        {id: 'superficie_agraria_km2', title: 'Km² agrarios', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Textura más frecuente'},
        {id: 'pct_fuertes', title: '% tierras fuertes', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Tipo de suelo'}
    ]}
/>

<p class="text-xs text-gray-500">Provincias de España. Pulsa una para ver aquí el suelo de esa provincia, con el mapa de sus municipios.</p>

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
        {id: 'superficie_agraria_km2', title: 'Km² agrarios', fmt: 'num1'},
        {id: 'textura_dominante', title: 'Textura más frecuente'},
        {id: 'pct_fuertes', title: '% tierras fuertes', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Tipo de suelo'}
    ]}
/>

<p class="text-xs text-gray-500">Municipios. Pulsa uno para ver aquí su suelo, con su mapa de celdas de 250 m. En gris, los municipios sin superficie agraria en el mapa CORINE (monte, ciudad o parcelas de menos de 25 ha).</p>

{/if}

<DataTable data={mapa_hijos} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=nombre title={terr[0]?.nivel === 'pais' ? 'Provincia' : 'Municipio'} />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura más frecuente" />
    <Column id=pct_fuertes title="% tierras fuertes" fmt=num0 />
    <Column id=arcilla_pct title="Arcilla (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de suelo" />
</DataTable>

<p class="text-xs text-gray-500">Tierras fuertes = las seis texturas franco-arcillosas y arcillosas del triángulo del USDA (en general, más de una cuarta parte de arcilla). En los municipios, la superficie agraria y el suelo salen de cada celda de 250 m dentro del término (CORINE y SoilGrids a su resolución original). Ceuta y Melilla casi no tienen superficie agraria.</p>

{:else}

<p class="text-sm text-gray-600 dark:text-gray-400">Un municipio es la unidad más pequeña: arriba está su mapa de celdas de 250 m. Elige «Toda la provincia» en el filtro para compararlo con los demás municipios.</p>

{/if}

## Qué suelo tiene cada cultivo

La superficie agraria se reparte según el mapa de usos del suelo CORINE 2018. Cada cultivo ocupa un tipo de tierra: en España, la dehesa está sobre suelos arenosos y ácidos del oeste; el olivar y el regadío, en las tierras más arcillosas de los valles; el viñedo, en los suelos más calizos y pobres.

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
    title="Textura del suelo de cada cultivo"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Cultivo" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num1 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_de_la_agraria title="% de la superficie agraria" fmt=num1 />
    <Column id=textura_dominante title="Textura más frecuente" />
    <Column id=arcilla_pct title="Arcilla (%)" fmt=num0 />
    <Column id=arena_pct title="Arena (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% básico" fmt=num0 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de suelo" />
</DataTable>

{/if}

<p class="text-xs text-gray-500">Cultivos de CORINE Land Cover 2018: secano = tierras de labor sin riego (cereal, girasol, leguminosas); regadío = tierras de labor regadas permanentemente (maíz, hortalizas, algodón...); frutales incluye cítricos, almendro y frutos secos; mosaico = parcelas pequeñas de cultivos distintos mezcladas, huertas y cultivos con vegetación natural; dehesa = encinar o alcornocal con pasto o cultivo debajo. CORINE no dibuja parcelas de menos de 25 ha, que se suman a lo que las rodea.</p>

## Frente a Europa

Mismo método para todos los países: el modelo SoilGrids sobre la superficie agraria de CORINE 2018.

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(europa, 'grupo', (d) => (d.cod_pais === 'ES' ? 'España' : d.es_ue ? 'UE' : 'Resto de Europa'))}
    x=pais
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['España', 'UE', 'Resto de Europa']}
    colorPalette={['#c2410c', '#a8a29e', '#d6d3d1']}
    title="Materia orgánica media del suelo agrario (%)"
/>

{/if}

{#if filas(europa).length > 0}

<BarChart
    data={etiquetar(filas(europa).toSorted((a, b) => b.ph - a.ph), 'grupo', (d) => (d.cod_pais === 'ES' ? 'España' : d.es_ue ? 'UE' : 'Resto de Europa'))}
    x=pais
    y=ph
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    yMin={4}
    seriesOrder={['España', 'UE', 'Resto de Europa']}
    colorPalette={['#1e3a8a', '#a8a29e', '#d6d3d1']}
    title="pH medio del suelo agrario"
/>

{/if}

<DataTable data={europa} rows=12 search=true>
    <Column id=pais title="País" />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura más frecuente" />
    <Column id=arcilla_pct title="Arcilla (%)" fmt=num0 />
    <Column id=arena_pct title="Arena (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% básico" fmt=num0 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de suelo" />
</DataTable>

<p class="text-xs text-gray-500">Chipre, Grecia, España, Italia y Turquía tienen los suelos agrarios más básicos, y {europa_resumen[0]?.menos_mo ?? '-'}, los de menos materia orgánica; el norte (Irlanda, los países nórdicos, Reino Unido, Países Bajos) los más ácidos y orgánicos, con prados húmedos y, en algunos, turba. Países con al menos 1.000 km² agrarios en CORINE (sin Malta). Abajo, las muestras de laboratorio de LUCAS, que confirman el puesto de España.</p>

```sql lucas_europa
SELECT cod, nombre, es_ue, muestras, materia_organica_pct, pct_mo_menos_2, ph, puesto_mo_menor, territorios
FROM mother.suelos_lucas
WHERE nivel = 'pais' AND uso = 'Agraria' AND muestras >= 20
ORDER BY materia_organica_pct
```

{#if filas(lucas_europa).length > 0}

<BarChart
    data={etiquetar(lucas_europa, 'grupo', (d) => (d.cod === 'ES' ? 'España' : d.es_ue ? 'UE' : 'Resto de Europa'))}
    x=nombre
    y=materia_organica_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesOrder={['España', 'UE', 'Resto de Europa']}
    colorPalette={['#65a30d', '#a8a29e', '#d6d3d1']}
    title="Materia orgánica medida en la superficie agraria: mediana de las muestras LUCAS 2018 (%)"
/>

<BarChart
    data={etiquetar(filas(lucas_europa).toSorted((a, b) => b.pct_mo_menos_2 - a.pct_mo_menos_2), 'grupo', (d) => (d.cod === 'ES' ? 'España' : d.es_ue ? 'UE' : 'Resto de Europa'))}
    x=nombre
    y=pct_mo_menos_2
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['España', 'UE', 'Resto de Europa']}
    colorPalette={['#a16207', '#a8a29e', '#d6d3d1']}
    title="% de muestras de la superficie agraria con menos del 2 % de materia orgánica (LUCAS 2018)"
/>

<p class="text-xs text-gray-500">LUCAS 2018 TOPSOIL (JRC): muestras de 0-20 cm de tierras de cultivo y prados analizadas en laboratorio; países con 20 muestras o más. Al ser análisis y no un modelo, dan menos materia orgánica que SoilGrids en el sur de Europa.</p>

{/if}

### Europa en el mapa

Las mismas capas para toda Europa, con celdas de 25 km y el mismo método que en España.

<BotonesUrl name="capa_eu" titulo="Colorear por" opciones={CAPAS_EU} defecto="textura" />

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
        {id: 'wrb', title: 'Tipo de suelo'}
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
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Cultivo principal'}
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
        {id: 'arcilla_pct', title: 'Arcilla (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipo de suelo'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Cada punto es un cuadrado de 25 × 25 km con al menos 25 km² de superficie agraria según CORINE 2018, con el suelo de SoilGrids. Las muestras de laboratorio de LUCAS no se dibujan una a una: la JRC las entrega bajo condiciones de uso que no permiten publicarlas punto a punto; abajo van resumidas por región.</p>

{/if}

### Región a región

Comparar países enteros esconde mucho: el norte de Italia no se parece al sur ni Andalucía a Galicia. Aquí, cada región europea (NUTS 2) con el modelo, lo medido por LUCAS donde hay al menos 10 muestras y la erosión estimada.

<BotonesUrl name="medida_eu" titulo="Medir" opciones={MEDIDAS_EU} defecto="materia_organica_pct" />

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
        {id: 'materia_organica_pct', title: 'Materia orgánica, modelo (%)', fmt: 'num1'},
        {id: 'lucas_materia_organica_pct', title: 'Materia orgánica medida, LUCAS (%)', fmt: 'num1'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'pct_fuertes', title: '% tierras fuertes', fmt: 'num0'},
        {id: 'erosion_t_ha', title: 'Erosión (t/ha y año)', fmt: 'num1'},
        {id: 'pct_erosion_moderada_grave', title: '% con erosión moderada o grave', fmt: 'num0'}
    ]}
/>

<DataTable data={regiones_eu} rows=10 search=true>
    <Column id=nombre title="Región" />
    <Column id=pais title="País" />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=materia_organica_pct title="Materia orgánica, modelo (%)" fmt=num1 />
    <Column id=lucas_materia_organica_pct title="Materia orgánica, LUCAS (%)" fmt=num1 />
    <Column id=lucas_muestras title="Muestras LUCAS" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_fuertes title="% tierras fuertes" fmt=num0 />
    <Column id=erosion_t_ha title="Erosión (t/ha)" fmt=num1 />
    <Column id=pct_erosion_moderada_grave title="% erosión moderada o grave" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Regiones NUTS 2 de 2021 (límites © EuroGeographics). LUCAS usa las de 2016: las pocas regiones que cambiaron entre una y otra versión salen sin dato medido. Erosión: último año publicado por Eurostat.</p>

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
    data={etiquetar(erosion_europa, 'grupo', (d) => (d.cod === 'ES' ? 'España' : d.es_ue ? 'UE' : 'Resto de Europa'))}
    x=nombre
    y=pct_moderada_grave
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={['España', 'UE', 'Resto de Europa']}
    colorPalette={['#b45309', '#a8a29e', '#d6d3d1']}
    title="% de la superficie agraria con erosión moderada o grave, por país (modelo RUSLE del JRC)"
/>

<p class="text-xs text-gray-500">Encabezan la lista los países con montaña y lluvia abundante (Eslovenia, Italia, Austria). España está en la mitad alta: en sus campos pesan las lluvias de tormenta, las pendientes y los olivares y viñedos con el suelo desnudo entre las filas. En 2000 tenía erosión moderada o grave el 31 % de su superficie agraria y en 2016, el 27 %.</p>

{/if}

## Fuentes y notas

- **Suelo: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, licencia CC BY 4.0). Arcilla, limo y arena, pH en agua y carbono orgánico de las capas de 0-5, 5-15 y 15-30 cm (medias a 1 km para España, comunidades, provincias y Europa, y la resolución original de 250 m para los municipios), promediadas por espesor; grupo de suelo WRB más probable. Es un modelo de aprendizaje automático entrenado con miles de perfiles de suelo y mapas de satélite, clima y relieve: suaviza los extremos y puede fallar en una comarca concreta. Materia orgánica = carbono orgánico × 1,724.
- **Superficie agraria y cultivos: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, Agencia Europea de Medio Ambiente), clases agrícolas (2xx), muestreadas cada 250 m.
- **Fronteras: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) para los países y el IGN para provincias.
- **Muestras de laboratorio: [LUCAS 2018 TOPSOIL](https://esdac.jrc.ec.europa.eu/content/lucas-2018-topsoil-data)** (European Soil Data Centre, ESDAC, esdac.jrc.ec.europa.eu, Comisión Europea, Centro Común de Investigación). Unas 19.000 muestras de 0-20 cm de toda la UE analizadas en laboratorio; aquí, medianas y porcentajes de las de tierras de cultivo y prados por país y por comunidad con 10 muestras o más (sin Canarias). Panagos, P. et al. (2022), «European Soil Data Centre 2.0», European Journal of Soil Science 73(6), e13315.
- **Erosión: [Eurostat, aei_pr_soiler](https://ec.europa.eu/eurostat/databrowser/view/aei_pr_soiler/default/table)**, pérdida de suelo por el agua estimada por el Centro Común de Investigación con el modelo RUSLE (lluvia, pendiente, suelo, cubierta y prácticas de conservación) en 2000, 2010, 2016 y 2023, para la superficie agraria y los pastos naturales, por país, región y provincia (Panagos, P. et al. (2015), «The new assessment of soil loss by water erosion in Europe», Environmental Science & Policy 54).
- **Regiones de Europa: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat), regiones NUTS 2 de 2021 (límites © EuroGeographics).
- Todo se calcula sobre una rejilla de 1 × 1 km (de 250 × 250 m en los municipios) en una proyección de igual área (ETRS89-LAEA), así que cada km² pesa lo mismo. Los mapas de suelo no tienen serie histórica: son una foto del suelo actual.

<LastRefreshed prefix="Datos actualizados" />
