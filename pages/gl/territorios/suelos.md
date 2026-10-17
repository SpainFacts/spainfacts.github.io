---
title: Solos agrarios
description: "Que terra hai debaixo dos cultivos de España: solos arxilosos, francos e areosos, tipos de solo (calcisolos, cambisolos, luvisolos, vertisolos...), pH e materia orgánica por comunidade, provincia e municipio, mapa cada 10 km, que solo ten o olivar, o viñedo, o regadío ou a devesa e comparación co resto de Europa."
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
        'Toda la superficie agraria': 'Toda a superficie agraria',
        'Secano': 'Cultivos de secaño',
        'Regadío': 'Regadío',
        'Arrozal': 'Arrozais',
        'Viñedo': 'Viñedo',
        'Frutales': 'Froiteiras',
        'Olivar': 'Olivar',
        'Prados': 'Prados',
        'Mosaico de cultivos': 'Mosaico de cultivos e hortas',
        'Dehesa': 'Devesas'
    };
    const GRUPO = {
        'Arenosa (ligera)': 'Areosa (terra lixeira)',
        'Franca (media)': 'Franca (terra media)',
        'Franco-arcillosa': 'Franco-arxilosa (terra forte)',
        'Arcillosa (pesada)': 'Arxilosa (terra pesada)'
    };
    const TEXTURA = {
        'Arenosa': 'Areosa', 'Arenoso-franca': 'Areoso-franca', 'Franco-arenosa': 'Franco-areosa',
        'Franca': 'Franca', 'Franco-limosa': 'Franco-limosa', 'Limosa': 'Limosa',
        'Franco-arcillo-arenosa': 'Franco-arxilo-areosa', 'Franco-arcillosa': 'Franco-arxilosa',
        'Franco-arcillo-limosa': 'Franco-arxilo-limosa', 'Arcillo-arenosa': 'Arxilo-areosa',
        'Arcillo-limosa': 'Arxilo-limosa', 'Arcillosa': 'Arxilosa'
    };
    const PH = {
        'Muy ácido (< 5,5)': 'Moi ácido (menos de 5,5)',
        'Ácido (5,5-6,5)': 'Ácido (5,5 a 6,5)',
        'Neutro (6,5-7,5)': 'Neutro (6,5 a 7,5)',
        'Básico (7,5-8,5)': 'Básico ou calcario (7,5 a 8,5)',
        'Muy básico (> 8,5)': 'Moi básico (máis de 8,5)'
    };
    const WRB = {
        'Calcisoles': 'Calcisolos', 'Cambisoles': 'Cambisolos', 'Luvisoles': 'Luvisolos', 'Leptosoles': 'Leptosolos',
        'Vertisoles': 'Vertisolos', 'Regosoles': 'Regosolos', 'Fluvisoles': 'Fluvisolos', 'Kastanozems': 'Kastanozems',
        'Phaeozems': 'Phaeozems', 'Gipsisoles': 'Xipsisolos', 'Arenosoles': 'Arenosolos', 'Umbrisoles': 'Umbrisolos',
        'Podzoles': 'Podzolos', 'Chernozems': 'Chernozems', 'Gleysoles': 'Gleisolos', 'Solonchaks': 'Solonchaks',
        'Albeluvisoles': 'Albeluvisolos', 'Andosoles': 'Andosolos', 'Acrisoles': 'Acrisolos', 'Alisoles': 'Alisolos',
        'Histosoles': 'Histosolos', 'Planosoles': 'Planosolos', 'Stagnosoles': 'Stagnosolos', 'Solonetz': 'Solonetz'
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

# 🟫 Solos agrarios

Que terra hai debaixo dos cultivos de España: se é **arxilosa, franca ou areosa**, que **tipo de solo** é, se é **calcaria ou ácida** e canta **materia orgánica** ten. Todo se mide sobre a **superficie agraria** ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} mil km², case a metade do país) na capa que se traballa, os primeiros 30 cm, e crúzase co que se cultiva enriba. Pódese baixar por comunidade e provincia ata cada municipio. Os datos saen dun modelo (SoilGrids), non de análises de cada parcela: serven para comparar comarcas, provincias e países.

<Grid cols=4>
    <KpiCard
        title="Textura máis frecuente"
        value={espana[0]?.pct_arcillosa}
        formattedValue={et(TEXTURA, espana[0]?.textura_dominante)}
        period="{formatNumber(clases_espana.filter((d) => d.dimension === 'textura' && d.clase === espana[0]?.textura_dominante)[0]?.pct, 0)} % da superficie agraria · arxila media: {formatNumber(espana[0]?.arcilla_pct, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="pH medio do solo agrario"
        value={espana[0]?.ph}
        formattedValue={formatNumber(espana[0]?.ph, 1)}
        period="{formatNumber(espana[0]?.pct_basico, 0)} % básico ou calcario (UE: {formatNumber(europa_resumen[0]?.basico_ue, 0)} %) · {formatNumber(espana[0]?.pct_acido, 0)} % ácido"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Materia orgánica media"
        value={espana[0]?.materia_organica_pct}
        formattedValue="{formatNumber(espana[0]?.materia_organica_pct, 1)} %"
        period="UE: {formatNumber(europa_resumen[0]?.mo_ue, 1)} % · España, {formatNumber(europa_resumen[0]?.puesto_mo, 0)}.º con menos de {formatNumber(europa_resumen[0]?.paises, 0)} países"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Tipo de solo máis estendido"
        value={espana[0]?.pct_calcisoles}
        formattedValue={et(WRB, espana[0]?.wrb_dominante)}
        period="{formatNumber(clases_espana.filter((d) => d.dimension === 'wrb' && d.clase === espana[0]?.wrb_dominante)[0]?.pct, 0)} % da superficie agraria · calcisolos: {formatNumber(espana[0]?.pct_calcisoles, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC, clasificación WRB)"
    />
</Grid>

## O mapa

<ButtonGroup name=capa title="Colorear por">
    <ButtonGroupItem valueLabel="Textura" value="textura" default />
    <ButtonGroupItem valueLabel="Tipo de solo" value="wrb" />
    <ButtonGroupItem valueLabel="pH" value="ph" />
    <ButtonGroupItem valueLabel="Materia orgánica" value="mo" />
    <ButtonGroupItem valueLabel="Cultivo" value="cultivo" />
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
        {id: 'textura', title: 'Textura'},
        {id: 'wrb', title: 'Tipo de solo'},
        {id: 'superficie_agraria_km2', title: 'Km² agrarios na cela', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Vermello: solos ácidos (pH baixo), típicos do noroeste chuvioso e dos granitos e lousas do oeste. Azul: solos básicos ou calcarios (pH alto), os de case toda a España seca, con calcaria ou xeso no subsolo. O pH decide que cultivos van ben (o castiñeiro ou o arando queren terra ácida; a vide, a amendoeira ou a oliveira aguantan a calcaria) e canto cal ou xofre hai que botar.</p>

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
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Cultivo principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agrarios na cela', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Máis verde, máis materia orgánica: os prados do norte, con chuvia, herba e esterco todo o ano. Os secaños da meseta, o val do Ebro e o sueste, con calor, pouca chuvia e séculos de labranza, teñen o solo agrario máis pobre en materia orgánica de Europa occidental. SoilGrids adoita dar algo máis de carbono que as análises de campo nos secaños mediterráneos: compara zonas, non tomes a cifra como unha análise.</p>

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
        {id: 'textura', title: 'Textura'},
        {id: 'arcilla_pct', title: 'Arxila (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipo de solo'},
        {id: 'cultivo', title: 'Cultivo principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agrarios na cela', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Cada punto é un cadrado de 10 × 10 km con polo menos 5 km² de superficie agraria, coloreado pola textura, o tipo de solo ou o cultivo que máis superficie agraria ocupa nel. Onde non hai punto hai monte, rocha, auga ou cidade.</p>

{/if}

## Arxilosos, francos e areosos

A **textura** é a proporción de arxila, limo e area da terra, e é o primeiro que mira un agricultor: unha terra **arxilosa** («forte» ou «pesada») garda auga e nutrientes pero encharca, greta e custa labrala; unha **areosa** («lixeira») trabállase con facilidade e quéntase antes na primavera, pero a auga e o abono escápanselle; a **franca**, coas tres cousas equilibradas, é a ideal para case todo. O solo agrario de España ten de media un {formatNumber(espana[0]?.arcilla_pct, 0)} % de arxila, un {formatNumber(espana[0]?.limo_pct, 0)} % de limo e un {formatNumber(espana[0]?.arena_pct, 0)} % de area.

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'textura'), 'textura_texto', (d) => et(TEXTURA, d.clase))}
    x=textura_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a5a34"
    title="Superficie agraria por clase de textura do USDA (%)"
/>

{/if}

<p class="text-xs text-gray-500">Clases do triángulo de texturas do Departamento de Agricultura dos EUA (USDA), as que usan os laboratorios agrarios en España. SoilGrids é un modelo que suaviza os extremos: as terras moi arxilosas (os «bujeos» da campiña do Guadalquivir, as «tierras de barro» de Tierra de Campos) aparecen como franco-arxilosas e as moi areosas, como franco-areosas. Por iso hai poucas clases puras de arxila ou area e convén ler xuntas as franco-arxilosas e as arxilosas como «terras fortes».</p>

## Tipos de solo

Ademais da textura, os edafólogos clasifican os solos por como se formaron. Na clasificación internacional (WRB, da FAO), a España agraria é sobre todo de **luvisolos** (solos vellos con arxila acumulada no fondo, como as terras vermellas da Mancha e Estremadura), **cambisolos** (solos novos, pouco evolucionados), **calcisolos** (cunha capa de calcaria, típicos da España seca), **leptosolos** (solos finos sobre rocha, en ladeiras) e **vertisolos** (arxilas que incham coa auga e gretan ao secar, as «terras negras» da campiña andaluza).

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
    x=wrb_texto
    y=pct
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c4524b"
    title="Superficie agraria por tipo de solo (WRB, %)"
/>

{/if}

## pH e materia orgánica

```sql ph_ccaa
SELECT c.nombre, c.clase, c.orden, c.pct, t.ph
FROM mother.suelos_clases c
JOIN mother.suelos_territorio t ON t.nivel = c.nivel AND t.cod = c.cod AND t.cultivo = c.cultivo
WHERE c.nivel = 'ccaa' AND c.cultivo = 'Toda la superficie agraria' AND c.dimension = 'ph'
    AND t.superficie_agraria_km2 >= 100
ORDER BY t.ph DESC, c.orden
```

O {formatNumber(espana[0]?.pct_basico, 0)} % da terra agraria de España é **básica ou calcaria** (pH de 7,5 ou máis), fronte ao {formatNumber(europa_resumen[0]?.basico_ue, 0)} % da UE: a calcaria e o xeso do subsolo e a pouca chuvia, que non lava os sales, soben o pH. Só a cornixa cantábrica, Galicia e o oeste de granito e lousa (Salamanca, Cáceres) teñen solos ácidos.

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
    title="Superficie agraria por pH do solo, por comunidade"
/>

{/if}

A **materia orgánica** (restos de plantas, raíces e esterco descompostos) dálle estrutura á terra, retén a auga e alimenta os cultivos. Con calor, pouca chuvia e séculos de labranza, o solo agrario español ten de media un {formatNumber(espana[0]?.materia_organica_pct, 1)} %, fronte ao {formatNumber(europa_resumen[0]?.mo_ue, 1)} % da UE. É o {formatNumber(europa_resumen[0]?.puesto_mo, 0)}.º máis pobre dos {formatNumber(europa_resumen[0]?.paises, 0)} países europeos comparados (os tres con menos: {europa_resumen[0]?.menos_mo ?? '-'}).

## Por comunidade e provincia

<ButtonGroup name=medida title="Medir">
    <ButtonGroupItem valueLabel="% de terras arxilosas ou franco-arxilosas" value="fuertes" default />
    <ButtonGroupItem valueLabel="Arxila media (%)" value="arcilla_pct" />
    <ButtonGroupItem valueLabel="pH medio" value="ph" />
    <ButtonGroupItem valueLabel="% de solo básico ou calcario" value="pct_basico" />
    <ButtonGroupItem valueLabel="Materia orgánica media (%)" value="materia_organica_pct" />
    <ButtonGroupItem valueLabel="% de calcisolos" value="pct_calcisoles" />
</ButtonGroup>

```sql fuertes
SELECT nivel, cod, sum(pct) AS pct_fuertes
FROM mother.suelos_clases
WHERE cultivo = 'Toda la superficie agraria' AND dimension = 'textura_grupo'
    AND clase IN ('Franco-arcillosa', 'Arcillosa (pesada)') AND nivel IN ('ccaa', 'provincia')
GROUP BY nivel, cod
```

```sql provincias
SELECT t.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.limo_pct,
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
        {id: 'superficie_agraria_km2', title: 'Km² agrarios', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Textura máis frecuente'},
        {id: 'arcilla_pct', title: 'Arxila (%)', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Tipo de solo'}
    ]}
/>

```sql ccaa
SELECT t.nombre AS comunidad, '/gl' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.arena_pct, t.ph,
    t.materia_organica_pct, t.textura_dominante, t.wrb_dominante, coalesce(t.pct_basico, 0) AS pct_basico,
    coalesce(f.pct_fuertes, 0) AS fuertes
FROM mother.suelos_territorio t
LEFT JOIN ${fuertes} f ON f.nivel = t.nivel AND f.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.cultivo = 'Toda la superficie agraria' AND t.superficie_agraria_km2 >= 100
ORDER BY t.superficie_agraria_km2 DESC
```

<DataTable data={ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura máis frecuente" />
    <Column id=fuertes title="% terras fortes" fmt=num0 />
    <Column id=arcilla_pct title="Arxila (%)" fmt=num0 />
    <Column id=arena_pct title="Area (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% básico" fmt=num0 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de solo" />
</DataTable>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura máis frecuente" />
    <Column id=fuertes title="% terras fortes" fmt=num0 />
    <Column id=arcilla_pct title="Arxila (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de solo" />
</DataTable>

<p class="text-xs text-gray-500">Terras fortes = as seis texturas franco-arxilosas e arxilosas do triángulo do USDA (en xeral, máis dunha cuarta parte de arxila). Álava, Navarra, A Rioxa, as campiñas de Málaga, Cádiz, Xaén e Sevilla e o val do Ebro teñen as terras máis fortes; Galicia, Cáceres, León e Badaxoz, as máis lixeiras, sobre granito e lousa. Ceuta e Melilla case non teñen superficie agraria.</p>

## Por municipio

```sql municipios_suelo
SELECT m.municipio, t.nombre AS provincia, '/gl' || m.enlace AS enlace, m.superficie_agraria_km2, m.pct_agraria, m.textura_dominante,
    m.pct_fuertes, m.ph, m.materia_organica_pct, m.wrb_dominante
FROM mother.suelos_municipio m
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = m.cod_prov
WHERE m.cultivo = 'Toda la superficie agraria' AND m.superficie_agraria_km2 > 0
ORDER BY m.superficie_agraria_km2 DESC
```

Busca o teu municipio: na súa ficha está o solo de cada un dos seus cultivos e a comparación coa súa provincia e con España. As fichas de cada comunidade e provincia teñen o mapa dos seus municipios.

<DataTable data={municipios_suelo} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_agraria title="% agrario" fmt=num0 />
    <Column id=textura_dominante title="Textura máis frecuente" />
    <Column id=pct_fuertes title="% terras fortes" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de solo" />
</DataTable>

<p class="text-xs text-gray-500">Superficie agraria de CORINE dentro de cada termo municipal, mostraxeada cada 250 m; o solo é o de SoilGrids a 1 km, así que nos municipios pequenos sae de moi poucas celas.</p>

## Que solo ten cada cultivo

A superficie agraria repártese segundo o mapa de usos do solo CORINE 2018. Cada cultivo ocupa un tipo de terra: a devesa, sobre solos areosos e ácidos do oeste; o olivar e o regadío, nas terras máis arxilosas dos vales; o viñedo, nos solos máis calcarios e pobres.

```sql lista_territorios
SELECT nivel || '-' || cod AS clave, nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.suelos_territorio
WHERE cultivo = 'Toda la superficie agraria' AND nivel IN ('pais', 'ccaa') AND superficie_agraria_km2 >= 100
```

<Dropdown name=territorio data={lista_territorios} value=clave label=nombre title="Territorio" order="orden, nombre" defaultValue="pais-00" />

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
    title="Textura do solo de cada cultivo"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Cultivo" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_de_la_agraria title="% da superficie agraria" fmt=num1 />
    <Column id=textura_dominante title="Textura máis frecuente" />
    <Column id=arcilla_pct title="Arxila (%)" fmt=num0 />
    <Column id=arena_pct title="Area (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% básico" fmt=num0 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de solo" />
</DataTable>

{/if}

<p class="text-xs text-gray-500">Cultivos de CORINE Land Cover 2018: secaño = terras de labor sen rega (cereal, xirasol, leguminosas); regadío = terras de labor regadas permanentemente (millo, hortalizas, algodón...); froiteiras inclúe cítricos, amendoeira e froitos secos; mosaico = parcelas pequenas de cultivos distintos mesturadas, hortas e cultivos con vexetación natural; devesa = aciñeiral ou sobreiral con pasto ou cultivo debaixo. CORINE non debuxa parcelas de menos de 25 ha, que se suman ao que as rodea.</p>

## Fronte a Europa

O mesmo método para todos os países: o modelo SoilGrids sobre a superficie agraria de CORINE 2018.

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
    title="Materia orgánica media do solo agrario (%)"
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
    title="pH medio do solo agrario"
/>

{/if}

<DataTable data={europa} rows=12 search=true>
    <Column id=pais title="País" />
    <Column id=superficie_agraria_km2 title="Km² agrarios" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura máis frecuente" />
    <Column id=arcilla_pct title="Arxila (%)" fmt=num0 />
    <Column id=arena_pct title="Area (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% básico" fmt=num0 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipo de solo" />
</DataTable>

<p class="text-xs text-gray-500">Chipre, Grecia, España, Italia e Turquía teñen os solos agrarios máis básicos, e {europa_resumen[0]?.menos_mo ?? '-'}, os de menos materia orgánica; o norte (Irlanda, os países nórdicos, Reino Unido, Países Baixos), os máis ácidos e orgánicos, con prados húmidos e, nalgúns, turba. Países con polo menos 1.000 km² agrarios en CORINE (sen Malta). A comparación coas mostras de laboratorio do programa europeo LUCAS (JRC) queda pendente: os seus datos só se entregan baixo solicitude.</p>

## Fontes e notas

- **Solo: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, licenza CC BY 4.0). Arxila, limo e area, pH en auga e carbono orgánico das capas de 0-5, 5-15 e 15-30 cm (medias a 1 km), promediadas por grosor; grupo de solo WRB máis probable. É un modelo de aprendizaxe automática adestrado con miles de perfís de solo e mapas de satélite, clima e relevo: suaviza os extremos e pode fallar nunha comarca concreta. Materia orgánica = carbono orgánico × 1,724.
- **Superficie agraria e cultivos: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, Axencia Europea de Medio Ambiente), clases agrícolas (2xx), mostradas cada 250 m.
- **Fronteiras: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) para os países e o IGN para as provincias.
- Todo se calcula sobre unha reixa de 1 × 1 km nunha proxección de igual área (ETRS89-LAEA), así que cada km² pesa o mesmo. Os mapas de solo non teñen serie histórica: son unha foto do solo actual.

<LastRefreshed prefix="Datos actualizados" />
