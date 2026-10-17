---
title: Sòls agraris
description: "Quina terra hi ha sota els conreus d'Espanya: sòls argilosos, francs i sorrencs, tipus de sòl (calcisòls, cambisòls, luvisòls, vertisòls...), pH i matèria orgànica per comunitat, província i municipi, mapa cada 10 km, quin sòl té l'oliverar, la vinya, el regadiu o la devesa i comparació amb la resta d'Europa."
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

# 🟫 Sòls agraris

Quina terra hi ha sota els conreus d'Espanya: si és **argilosa, franca o sorrenca**, quin **tipus de sòl** és, si és **calcària o àcida** i quanta **matèria orgànica** té. Tot es mesura sobre la **superfície agrària** ({formatNumber(espana[0]?.superficie_agraria_km2 / 1000, 0)} mil km², gairebé la meitat del país) a la capa que es treballa, els primers 30 cm, i es creua amb el que s'hi conrea a sobre. Es pot baixar per comunitat i província fins a cada municipi. Les dades surten d'un model (SoilGrids), no d'anàlisis de cada parcel·la: serveixen per comparar comarques, províncies i països.

<Grid cols=4>
    <KpiCard
        title="Textura més freqüent"
        value={espana[0]?.pct_arcillosa}
        formattedValue={et(TEXTURA, espana[0]?.textura_dominante)}
        period="{formatNumber(clases_espana.filter((d) => d.dimension === 'textura' && d.clase === espana[0]?.textura_dominante)[0]?.pct, 0)} % de la superfície agrària · argila mitjana: {formatNumber(espana[0]?.arcilla_pct, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC) · CORINE 2018"
    />
    <KpiCard
        title="pH mitjà del sòl agrari"
        value={espana[0]?.ph}
        formattedValue={formatNumber(espana[0]?.ph, 1)}
        period="{formatNumber(espana[0]?.pct_basico, 0)} % bàsic o calcari (UE: {formatNumber(europa_resumen[0]?.basico_ue, 0)} %) · {formatNumber(espana[0]?.pct_acido, 0)} % àcid"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Matèria orgànica mitjana"
        value={espana[0]?.materia_organica_pct}
        formattedValue="{formatNumber(espana[0]?.materia_organica_pct, 1)} %"
        period="UE: {formatNumber(europa_resumen[0]?.mo_ue, 1)} % · Espanya, {formatNumber(europa_resumen[0]?.puesto_mo, 0)}a amb menys de {formatNumber(europa_resumen[0]?.paises, 0)} països"
        direction="neutral"
        source="SoilGrids (ISRIC)"
    />
    <KpiCard
        title="Tipus de sòl més estès"
        value={espana[0]?.pct_calcisoles}
        formattedValue={et(WRB, espana[0]?.wrb_dominante)}
        period="{formatNumber(clases_espana.filter((d) => d.dimension === 'wrb' && d.clase === espana[0]?.wrb_dominante)[0]?.pct, 0)} % de la superfície agrària · calcisòls: {formatNumber(espana[0]?.pct_calcisoles, 0)} %"
        direction="neutral"
        source="SoilGrids (ISRIC, classificació WRB)"
    />
</Grid>

## El mapa

<ButtonGroup name=capa title="Acolorir per">
    <ButtonGroupItem valueLabel="Textura" value="textura" default />
    <ButtonGroupItem valueLabel="Tipus de sòl" value="wrb" />
    <ButtonGroupItem valueLabel="pH" value="ph" />
    <ButtonGroupItem valueLabel="Matèria orgànica" value="mo" />
    <ButtonGroupItem valueLabel="Conreu" value="cultivo" />
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
        {id: 'wrb', title: 'Tipus de sòl'},
        {id: 'superficie_agraria_km2', title: 'Km² agraris a la cel·la', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Vermell: sòls àcids (pH baix), típics del nord-oest plujós i dels granits i les pissarres de l'oest. Blau: sòls bàsics o calcaris (pH alt), els de gairebé tota l'Espanya seca, amb calcària o guix al subsòl. El pH decideix quins conreus hi van bé (el castanyer o el nabiu volen terra àcida; la vinya, l'ametller o l'olivera aguanten la calcària) i quanta calç o sofre cal tirar-hi.</p>

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
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'cultivo', title: 'Conreu principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agraris a la cel·la', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Com més verd, més matèria orgànica: els prats del nord, amb pluja, herba i fems tot l'any. Els secans de la Meseta, la vall de l'Ebre i el sud-est, amb calor, poca pluja i segles de llaurada, tenen el sòl agrari més pobre en matèria orgànica de l'Europa occidental. SoilGrids sol donar una mica més de carboni que les anàlisis de camp als secans mediterranis: compara zones, no prenguis la xifra com una anàlisi.</p>

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
        {id: 'arcilla_pct', title: 'Argila (%)', fmt: 'num0'},
        {id: 'wrb', title: 'Tipus de sòl'},
        {id: 'cultivo', title: 'Conreu principal'},
        {id: 'superficie_agraria_km2', title: 'Km² agraris a la cel·la', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Cada punt és un quadrat de 10 × 10 km amb almenys 5 km² de superfície agrària, acolorit segons la textura, el tipus de sòl o el conreu que hi ocupa més superfície agrària. On no hi ha punt hi ha bosc, roca, aigua o ciutat.</p>

{/if}

## Argilosos, francs i sorrencs

La **textura** és la proporció d'argila, llim i sorra de la terra, i és el primer que mira un pagès: una terra **argilosa** («forta» o «pesada») guarda l'aigua i els nutrients però s'entolla, s'esquerda i costa de llaurar; una **sorrenca** («lleugera») es treballa amb facilitat i s'escalfa abans a la primavera, però l'aigua i l'adob se li escapen; la **franca**, amb les tres coses equilibrades, és la ideal per a gairebé tot. El sòl agrari d'Espanya té de mitjana un {formatNumber(espana[0]?.arcilla_pct, 0)} % d'argila, un {formatNumber(espana[0]?.limo_pct, 0)} % de llim i un {formatNumber(espana[0]?.arena_pct, 0)} % de sorra.

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'textura'), 'textura_texto', (d) => et(TEXTURA, d.clase))}
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

{#if filas(clases_espana).length > 0}

<BarChart
    data={etiquetar(clases_espana.filter((d) => d.dimension === 'wrb' && d.pct >= 0.1).toSorted((a, b) => b.pct - a.pct), 'wrb_texto', (d) => et(WRB, d.clase))}
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

```sql ph_ccaa
SELECT c.nombre, c.clase, c.orden, c.pct, t.ph
FROM mother.suelos_clases c
JOIN mother.suelos_territorio t ON t.nivel = c.nivel AND t.cod = c.cod AND t.cultivo = c.cultivo
WHERE c.nivel = 'ccaa' AND c.cultivo = 'Toda la superficie agraria' AND c.dimension = 'ph'
    AND t.superficie_agraria_km2 >= 100
ORDER BY t.ph DESC, c.orden
```

El {formatNumber(espana[0]?.pct_basico, 0)} % de la terra agrària d'Espanya és **bàsica o calcària** (pH de 7,5 o més), davant del {formatNumber(europa_resumen[0]?.basico_ue, 0)} % de la UE: la calcària i el guix del subsòl i la poca pluja, que no renta les sals, fan pujar el pH. Només la cornisa cantàbrica, Galícia i l'oest de granit i pissarra (Salamanca, Càceres) tenen sòls àcids.

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
    title="Superfície agrària segons el pH del sòl, per comunitat"
/>

{/if}

La **matèria orgànica** (restes de plantes, arrels i fems descompostos) dona estructura a la terra, reté l'aigua i alimenta els conreus. Amb calor, poca pluja i segles de llaurada, el sòl agrari espanyol té de mitjana un {formatNumber(espana[0]?.materia_organica_pct, 1)} %, davant del {formatNumber(europa_resumen[0]?.mo_ue, 1)} % de la UE. És el {formatNumber(europa_resumen[0]?.puesto_mo, 0)}è més pobre dels {formatNumber(europa_resumen[0]?.paises, 0)} països europeus comparats (els tres amb menys: {europa_resumen[0]?.menos_mo ?? '-'}).

## Per comunitat i província

<ButtonGroup name=medida title="Mesurar">
    <ButtonGroupItem valueLabel="% de terres argiloses o franques argiloses" value="fuertes" default />
    <ButtonGroupItem valueLabel="Argila mitjana (%)" value="arcilla_pct" />
    <ButtonGroupItem valueLabel="pH mitjà" value="ph" />
    <ButtonGroupItem valueLabel="% de sòl bàsic o calcari" value="pct_basico" />
    <ButtonGroupItem valueLabel="Matèria orgànica mitjana (%)" value="materia_organica_pct" />
    <ButtonGroupItem valueLabel="% de calcisòls" value="pct_calcisoles" />
</ButtonGroup>

```sql fuertes
SELECT nivel, cod, sum(pct) AS pct_fuertes
FROM mother.suelos_clases
WHERE cultivo = 'Toda la superficie agraria' AND dimension = 'textura_grupo'
    AND clase IN ('Franco-arcillosa', 'Arcillosa (pesada)') AND nivel IN ('ccaa', 'provincia')
GROUP BY nivel, cod
```

```sql provincias
SELECT t.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.limo_pct,
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
        {id: 'superficie_agraria_km2', title: 'Km² agraris', fmt: 'num0'},
        {id: 'textura_dominante', title: 'Textura més freqüent'},
        {id: 'arcilla_pct', title: 'Argila (%)', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Matèria orgànica (%)', fmt: 'num1'},
        {id: 'wrb_dominante', title: 'Tipus de sòl'}
    ]}
/>

```sql ccaa
SELECT t.nombre AS comunidad, '/ca' || t.ruta AS ruta, t.superficie_agraria_km2, t.arcilla_pct, t.arena_pct, t.ph,
    t.materia_organica_pct, t.textura_dominante, t.wrb_dominante, coalesce(t.pct_basico, 0) AS pct_basico,
    coalesce(f.pct_fuertes, 0) AS fuertes
FROM mother.suelos_territorio t
LEFT JOIN ${fuertes} f ON f.nivel = t.nivel AND f.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.cultivo = 'Toda la superficie agraria' AND t.superficie_agraria_km2 >= 100
ORDER BY t.superficie_agraria_km2 DESC
```

<DataTable data={ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=superficie_agraria_km2 title="Km² agraris" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura més freqüent" />
    <Column id=fuertes title="% terres fortes" fmt=num0 />
    <Column id=arcilla_pct title="Argila (%)" fmt=num0 />
    <Column id=arena_pct title="Sorra (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=pct_basico title="% bàsic" fmt=num0 />
    <Column id=materia_organica_pct title="Matèria orgànica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipus de sòl" />
</DataTable>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Província" />
    <Column id=superficie_agraria_km2 title="Km² agraris" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=textura_dominante title="Textura més freqüent" />
    <Column id=fuertes title="% terres fortes" fmt=num0 />
    <Column id=arcilla_pct title="Argila (%)" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Matèria orgànica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipus de sòl" />
</DataTable>

<p class="text-xs text-gray-500">Terres fortes = les sis textures franques argiloses i argiloses del triangle de l'USDA (en general, més d'una quarta part d'argila). Àlaba, Navarra, la Rioja, les campinyes de Màlaga, Cadis, Jaén i Sevilla i la vall de l'Ebre tenen les terres més fortes; Galícia, Càceres, Lleó i Badajoz, les més lleugeres, sobre granit i pissarra. Ceuta i Melilla gairebé no tenen superfície agrària.</p>

## Per municipi

```sql municipios_suelo
SELECT m.municipio, t.nombre AS provincia, '/ca' || m.enlace AS enlace, m.superficie_agraria_km2, m.pct_agraria, m.textura_dominante,
    m.pct_fuertes, m.ph, m.materia_organica_pct, m.wrb_dominante
FROM mother.suelos_municipio m
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = m.cod_prov
WHERE m.cultivo = 'Toda la superficie agraria' AND m.superficie_agraria_km2 > 0
ORDER BY m.superficie_agraria_km2 DESC
```

Busca el teu municipi: a la seva fitxa hi ha el sòl de cadascun dels seus conreus i la comparació amb la seva província i amb Espanya. Les fitxes de cada comunitat i província tenen el mapa dels seus municipis.

<DataTable data={municipios_suelo} rows=10 search=true link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=superficie_agraria_km2 title="Km² agraris" fmt=num0 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_agraria title="% agrari" fmt=num0 />
    <Column id=textura_dominante title="Textura més freqüent" />
    <Column id=pct_fuertes title="% terres fortes" fmt=num0 />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Matèria orgànica (%)" fmt=num1 />
    <Column id=wrb_dominante title="Tipus de sòl" />
</DataTable>

<p class="text-xs text-gray-500">Superfície agrària de CORINE dins de cada terme municipal, mostrejada cada 250 m; el sòl és el de SoilGrids a 1 km, de manera que als municipis petits surt de molt poques cel·les.</p>

## Quin sòl té cada conreu

La superfície agrària es reparteix segons el mapa d'usos del sòl CORINE 2018. Cada conreu ocupa un tipus de terra: la devesa, sobre sòls sorrencs i àcids de l'oest; l'oliverar i el regadiu, a les terres més argiloses de les valls; la vinya, als sòls més calcaris i pobres.

```sql lista_territorios
SELECT nivel || '-' || cod AS clave, nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.suelos_territorio
WHERE cultivo = 'Toda la superficie agraria' AND nivel IN ('pais', 'ccaa') AND superficie_agraria_km2 >= 100
```

<Dropdown name=territorio data={lista_territorios} value=clave label=nombre title="Territori" order="orden, nombre" defaultValue="pais-00" />

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
    title="Textura del sòl de cada conreu"
/>

<DataTable data={etiquetar(cultivos, 'cultivo_texto', (d) => et(CULTIVO, d.cultivo))} rows=10>
    <Column id=cultivo_texto title="Conreu" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num0 contentType=bar barColor="#e7d3b5" />
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

<p class="text-xs text-gray-500">Xipre, Grècia, Espanya, Itàlia i Turquia tenen els sòls agraris més bàsics, i {europa_resumen[0]?.menos_mo ?? '-'}, els de menys matèria orgànica; el nord (Irlanda, els països nòrdics, el Regne Unit, els Països Baixos), els més àcids i orgànics, amb prats humits i, en alguns, torba. Països amb almenys 1.000 km² agraris a CORINE (sense Malta). La comparació amb les mostres de laboratori del programa europeu LUCAS (JRC) queda pendent: les seves dades només es lliuren amb sol·licitud prèvia.</p>

## Fonts i notes

- **Sòl: [SoilGrids 2.0](https://soilgrids.org)** (ISRIC - World Soil Information, llicència CC BY 4.0). Argila, llim i sorra, pH en aigua i carboni orgànic de les capes de 0-5, 5-15 i 15-30 cm (mitjanes a 1 km), ponderades pel gruix; grup de sòl WRB més probable. És un model d'aprenentatge automàtic entrenat amb milers de perfils de sòl i mapes de satèl·lit, clima i relleu: suavitza els extrems i pot fallar en una comarca concreta. Matèria orgànica = carboni orgànic × 1,724.
- **Superfície agrària i conreus: [CORINE Land Cover 2018](https://land.copernicus.eu/en/products/corine-land-cover/clc2018)** (Copernicus, Agència Europea de Medi Ambient), classes agrícoles (2xx), mostrejades cada 250 m.
- **Fronteres: [GISCO](https://ec.europa.eu/eurostat/web/gisco)** (Eurostat) per als països i l'IGN per a les províncies.
- Tot es calcula sobre una graella d'1 × 1 km en una projecció d'àrea igual (ETRS89-LAEA), de manera que cada km² pesa el mateix. Els mapes de sòl no tenen sèrie històrica: són una foto del sòl actual.

<LastRefreshed prefix="Dades actualitzades" />
