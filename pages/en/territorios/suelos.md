---
title: Farm soils
description: "What kind of ground lies under Spain's crops: clayey, loamy and sandy soils, soil types (Calcisols, Cambisols, Luvisols, Vertisols...), pH and organic matter by region, province and municipality, a map every 10 km, which soil olive groves, vineyards, irrigated land and dehesa wood-pastures sit on, and the comparison with the rest of Europe."
i18n_origen: 936db82c6035
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
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

# 🟫 Farm soils

What kind of ground lies under Spain's crops: whether it is **clayey, loamy or sandy**, what **type of soil** it is, whether it is **calcareous or acidic** and how much **organic matter** it holds. Everything is measured over **farmland** ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} thousand km², almost half the country) in the layer that gets worked, the top 30 cm, and matched with what is grown on top. You can drill down by region and province to each municipality. The data come from a model (SoilGrids), not from tests of each field: they are good for comparing districts, provinces and countries.

<Grid cols=4>
    <KpiCard
        title="Most common texture"
        value={espana[0]?.pct_arcillosa}
        formattedValue={et(TEXTURA, espana[0]?.textura_dominante)}
        period="{formatNumber(clases_espana.filter((d) => d.dimension === 'textura' && d.clase === espana[0]?.textura_dominante)[0]?.pct, 0)} % of farmland · average clay: {formatNumber(espana[0]?.arcilla_pct, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="Average pH of farm soil"
        value={espana[0]?.ph}
        formattedValue={formatNumber(espana[0]?.ph, 1)}
        period="{formatNumber(espana[0]?.pct_basico, 0)} % alkaline or calcareous (EU: {formatNumber(europa_resumen[0]?.basico_ue, 0)} %) · {formatNumber(espana[0]?.pct_acido, 0)} % acidic"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Average organic matter"
        value={espana[0]?.materia_organica_pct}
        formattedValue="{formatNumber(espana[0]?.materia_organica_pct, 1)} %"
        period="EU: {formatNumber(europa_resumen[0]?.mo_ue, 1)} % · Spain: no. {formatNumber(europa_resumen[0]?.puesto_mo, 0)} lowest of {formatNumber(europa_resumen[0]?.paises, 0)} countries"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Most widespread soil type"
        value={espana[0]?.pct_calcisoles}
        formattedValue={et(WRB, espana[0]?.wrb_dominante)}
        period="{formatNumber(clases_espana.filter((d) => d.dimension === 'wrb' && d.clase === espana[0]?.wrb_dominante)[0]?.pct, 0)} % of farmland · Calcisols: {formatNumber(espana[0]?.pct_calcisoles, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC, WRB classification)"
    />
</Grid>

## The map

<ButtonGroup name=capa title="Colour by">
    <ButtonGroupItem valueLabel="Texture" value="textura" default />
    <ButtonGroupItem valueLabel="Soil type" value="wrb" />
    <ButtonGroupItem valueLabel="pH" value="ph" />
    <ButtonGroupItem valueLabel="Organic matter" value="mo" />
    <ButtonGroupItem valueLabel="Crop" value="cultivo" />
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
        {id: 'textura', title: 'Texture'},
        {id: 'wrb', title: 'Soil type'},
        {id: 'superficie_agraria_km2', title: 'Farmland km² in the cell', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Red: acidic soils (low pH), typical of the rainy north-west and of the granite and slate of the west. Blue: alkaline or calcareous soils (high pH), found across almost all of dry Spain, with limestone or gypsum underneath. pH decides which crops do well (chestnuts and blueberries want acidic ground; vines, almonds and olives tolerate limestone) and how much lime or sulphur has to be added.</p>

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
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Main crop'},
        {id: 'superficie_agraria_km2', title: 'Farmland km² in the cell', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Greener means more organic matter: the meadows of the north, with rain, grass and manure all year round. The rain-fed fields of the central plateau, the Ebro valley and the south-east, with heat, little rain and centuries of ploughing, have the farm soil poorest in organic matter in western Europe. SoilGrids tends to give somewhat more carbon than field tests in Mediterranean rain-fed land: use it to compare areas, not as a soil test.</p>

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
        {id: 'textura', title: 'Texture'},
        {id: 'arcilla_pct', title: 'Clay (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Soil type'},
        {id: 'cultivo', title: 'Main crop'},
        {id: 'superficie_agraria_km2', title: 'Farmland km² in the cell', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Each dot is a 10 × 10 km square with at least 5 km² of farmland, coloured by the texture, soil type or crop that covers the most farmland in it. Where there is no dot there is woodland or scrub, rock, water or town.</p>

{/if}

## Clayey, loamy and sandy

**Texture** is the mix of clay, silt and sand in the ground, and it is the first thing a farmer looks at: a **clayey** soil ("heavy") holds water and nutrients but gets waterlogged, cracks and is hard to plough; a **sandy** one ("light") is easy to work and warms up earlier in spring, but water and fertiliser drain away; a **loamy** soil, with the three in balance, is ideal for almost everything. Spain's farm soil averages {formatNumber(espana[0]?.arcilla_pct, 0)} % clay, {formatNumber(espana[0]?.limo_pct, 0)} % silt and {formatNumber(espana[0]?.arena_pct, 0)} % sand.

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'textura'), 'textura_texto', (d) => et(TEXTURA, d.clase))}
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

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
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

```sql ph_ccaa
SELECT c.nombre, c.clase, c.orden, c.pct, t.ph
FROM mother.suelos_clases c
JOIN mother.suelos_territorio t ON t.nivel = c.nivel AND t.cod = c.cod AND t.cultivo = c.cultivo
WHERE c.nivel = 'ccaa' AND c.cultivo = 'Toda la superficie agraria' AND c.dimension = 'ph'
    AND t.superficie_agraria_km2 >= 100
ORDER BY t.ph DESC, c.orden
```

{formatNumber(espana[0]?.pct_basico, 0)} % of Spain's farmland is **alkaline or calcareous** (pH 7.5 or higher), against {formatNumber(europa_resumen[0]?.basico_ue, 0)} % in the EU: limestone and gypsum underground and scarce rain, which does not wash the salts away, push the pH up. Only the Cantabrian coast, Galicia and the granite and slate west (Salamanca, Cáceres) have acidic soils.

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
    title="Farmland by soil pH, by region"
/>

{/if}

**Organic matter** (decomposed remains of plants, roots and manure) gives the soil structure, holds water and feeds the crops. With heat, little rain and centuries of ploughing, Spanish farm soil averages {formatNumber(espana[0]?.materia_organica_pct, 1)} %, against {formatNumber(europa_resumen[0]?.mo_ue, 1)} % in the EU. It ranks no. {formatNumber(europa_resumen[0]?.puesto_mo, 0)} poorest of the {formatNumber(europa_resumen[0]?.paises, 0)} European countries compared (the three with the least: {europa_resumen[0]?.menos_mo ?? '-'}).

## By region and province

<ButtonGroup name=medida title="Measure">
    <ButtonGroupItem valueLabel="% of clayey or clay loam soils" value="fuertes" default />
    <ButtonGroupItem valueLabel="Average clay (%)" value="arcilla_pct" />
    <ButtonGroupItem valueLabel="Average pH" value="ph" />
    <ButtonGroupItem valueLabel="% of alkaline or calcareous soil" value="pct_basico" />
    <ButtonGroupItem valueLabel="Average organic matter (%)" value="materia_organica_pct" />
    <ButtonGroupItem valueLabel="% of Calcisols" value="pct_calcisoles" />
</ButtonGroup>

```sql fuertes
SELECT nivel, cod, sum(pct) AS pct_fuertes
FROM mother.suelos_clases
WHERE cultivo = 'Toda la superficie agraria' AND dimension = 'textura_grupo'
    AND clase IN ('Franco-arcillosa', 'Arcillosa (pesada)') AND nivel IN ('ccaa', 'provincia')
GROUP BY nivel, cod
```

```sql provincias
SELECT t.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.limo_pct,
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
        {id: 'superficie_agraria_km2', title: 'Farmland km²', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Most common texture'},
        {id: 'arcilla_pct', title: 'Clay (%)', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Organic matter (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Soil type'}
    ]}
/>

```sql ccaa
SELECT t.nombre AS comunidad, '/en' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.arena_pct, t.ph,
    t.materia_organica_pct, t.textura_dominante, t.wrb_dominante, coalesce(t.pct_basico, 0) AS pct_basico,
    coalesce(f.pct_fuertes, 0) AS fuertes
FROM mother.suelos_territorio t
LEFT JOIN ${fuertes} f ON f.nivel = t.nivel AND f.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.cultivo = 'Toda la superficie agraria' AND t.superficie_agraria_km2 >= 100
ORDER BY t.superficie_agraria_km2 DESC
```

<DataTable data={ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=superficie_agraria_km2 title="Farmland km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Most common texture" />
    <Column id=fuertes title="% heavy soils" fmt=num0 />
    <Column id=arcilla_pct title="Clay (%)" fmt=num0 />
    <Column id=arena_pct title="Sand (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% alkaline" fmt=num0 />
    <Column id=materia_organica_pct title="Organic matter (%)" fmt=num1 />
    <Column id=wrb_dominante title="Soil type" />
</DataTable>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Province" />
    <Column id=superficie_agraria_km2 title="Farmland km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Most common texture" />
    <Column id=fuertes title="% heavy soils" fmt=num0 />
    <Column id=arcilla_pct title="Clay (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Organic matter (%)" fmt=num1 />
    <Column id=wrb_dominante title="Soil type" />
</DataTable>

<p class="text-xs text-gray-500">Heavy soils = the six clay loam and clay textures of the USDA triangle (generally more than a quarter clay). Álava, Navarre, La Rioja, the countryside of Málaga, Cádiz, Jaén and Seville and the Ebro valley have the heaviest soils; Galicia, Cáceres, León and Badajoz the lightest, on granite and slate. Ceuta and Melilla have almost no farmland.</p>

## By municipality

```sql municipios_suelo
SELECT m.municipio, t.nombre AS provincia, '/en' || m.enlace AS enlace, m.superficie_agraria_km2, m.pct_agraria, m.textura_dominante,
    m.pct_fuertes, m.ph, m.materia_organica_pct, m.wrb_dominante
FROM mother.suelos_municipio m
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = m.cod_prov
WHERE m.cultivo = 'Toda la superficie agraria' AND m.superficie_agraria_km2 > 0
ORDER BY m.superficie_agraria_km2 DESC
```

Look up your municipality: its page shows the soil under each of its crops and the comparison with its province and with Spain. Each region and province page has the map of its municipalities.

<DataTable data={municipios_suelo} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=superficie_agraria_km2 title="Farmland km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_agraria title="% farmland" fmt=num0 />
    <Column id=textura_dominante title="Most common texture" />
    <Column id=pct_fuertes title="% heavy soils" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Organic matter (%)" fmt=num1 />
    <Column id=wrb_dominante title="Soil type" />
</DataTable>

<p class="text-xs text-gray-500">CORINE farmland within each municipality, sampled every 250 m; the soil is SoilGrids at 1 km, so in small municipalities it comes from very few cells.</p>

## Which soil each crop sits on

Farmland is split according to the CORINE 2018 land-use map. Each crop sits on a different kind of ground: dehesa wood-pastures on the sandy, acidic soils of the west; olive groves and irrigated land on the most clayey soils of the valleys; vineyards on the most calcareous and poorest soils.

```sql lista_territorios
SELECT nivel || '-' || cod AS clave, nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.suelos_territorio
WHERE cultivo = 'Toda la superficie agraria' AND nivel IN ('pais', 'ccaa') AND superficie_agraria_km2 >= 100
```

<Dropdown name=territorio data={lista_territorios} value=clave label=nombre title="Area" order="orden, nombre" defaultValue="pais-00" />

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
    title="Soil texture under each crop"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Crop" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
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

<p class="text-xs text-gray-500">Cyprus, Greece, Spain, Italy and Turkey have the most alkaline farm soils, and {europa_resumen[0]?.menos_mo ?? '-'} those with the least organic matter; the north (Ireland, the Nordic countries, the United Kingdom, the Netherlands) has the most acidic and organic ones, with wet meadows and, in some, peat. Countries with at least 1,000 km² of farmland in CORINE (excluding Malta). The comparison with laboratory samples from the European LUCAS programme (JRC) is still pending: its data are only provided on request.</p>

## Sources and notes

- **Soil: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, CC BY 4.0 licence). Clay, silt and sand, pH in water and organic carbon of the 0-5, 5-15 and 15-30 cm layers (1 km averages), weighted by thickness; most likely WRB soil group. It is a machine-learning model trained on thousands of soil profiles and satellite, climate and terrain maps: it smooths out the extremes and can be wrong for a particular district. Organic matter = organic carbon × 1.724.
- **Farmland and crops: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, European Environment Agency), agricultural classes (2xx), sampled every 250 m.
- **Borders: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) for countries and the IGN (Spain's National Geographic Institute) for provinces.
- Everything is calculated on a 1 × 1 km grid in an equal-area projection (ETRS89-LAEA), so every km² carries the same weight. Soil maps have no historical series: they are a snapshot of today's soil.

<LastRefreshed prefix="Data updated" />
