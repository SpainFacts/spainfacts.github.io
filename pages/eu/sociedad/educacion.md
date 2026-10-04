---
title: Hezkuntza
description: "Eskola-uzte goiztiarra, helduen hezkuntza-maila, ez ikasten ez lanean ari diren gazteak, hezkuntza-gastua biztanleko eta ikasleko, ikasleak mailaka eta PISA, Espainia EBrekin alderatuta eta erkidegoka."
i18n_origen: 350e27897b13
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql ind
SELECT anio, nivel, indicador, valor
FROM mother.educacion_indicadores
WHERE nivel IN ('pais', 'ue')
ORDER BY anio
```

```sql resumen
-- Último año de cada indicador para España, con la UE y la variación sobre el año anterior
SELECT
    e.indicador,
    CAST(e.anio AS INTEGER) AS anio,
    e.valor,
    u.valor AS valor_ue,
    e.valor - a.valor AS cambio
FROM mother.educacion_indicadores e
LEFT JOIN mother.educacion_indicadores u ON u.nivel = 'ue' AND u.indicador = e.indicador AND u.anio = e.anio
LEFT JOIN mother.educacion_indicadores a ON a.nivel = 'pais' AND a.indicador = e.indicador AND a.anio = e.anio - 1
WHERE e.nivel = 'pais'
QUALIFY row_number() OVER (PARTITION BY e.indicador ORDER BY e.anio DESC) = 1
```

```sql abandono_es
SELECT anio, valor FROM mother.educacion_indicadores WHERE nivel = 'pais' AND indicador = 'abandono' ORDER BY anio
```

```sql superior_es
SELECT anio, valor FROM mother.educacion_indicadores WHERE nivel = 'pais' AND indicador = 'superior_25_64' ORDER BY anio
```

```sql neet_es
SELECT anio, valor FROM mother.educacion_indicadores WHERE nivel = 'pais' AND indicador = 'neet_15_29' ORDER BY anio
```

```sql gasto
SELECT anio, nivel, pct_pib, millones_eur, eur_hab_real, anio_base
FROM mother.educacion_gasto
WHERE funcion = 'Total'
ORDER BY anio
```

```sql gasto_es
SELECT g.anio, g.eur_hab_real AS valor, g.pct_pib, g.millones_eur, g.anio_base, u.pct_pib AS pct_pib_ue
FROM mother.educacion_gasto g
LEFT JOIN mother.educacion_gasto u ON u.nivel = 'ue' AND u.funcion = 'Total' AND u.anio = g.anio
WHERE g.nivel = 'pais' AND g.funcion = 'Total' AND g.eur_hab_real IS NOT NULL
ORDER BY g.anio
```

# 🎓 Hezkuntza

Zenbat gaztek uzten dioten goizegi ikasteari, zer prestakuntza duten helduek, zenbat gazte dauden ez ikasten ez lanean, zenbat gastatzen den hezkuntzan, zenbat ikasle dauden etapa bakoitzean eta zer emaitza ateratzen dituzten PISAn, beti Europar Batasuneko batez bestekoarekin alderatuta.

<Grid cols=4>
    <KpiCard
        title="Eskola-uzte goiztiarra"
        value={resumen.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="18 eta 24 urte bitarteko gazteena {urtean(resumen.find(d => d.indicador === 'abandono')?.anio)} · EB: {formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'abandono')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="aurreko urtearekiko"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={abandono_es}
    />
    <KpiCard
        title="Goi-mailako ikasketak dituzten helduak"
        value={resumen.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="25 eta 64 urte bitartekoak {urtean(resumen.find(d => d.indicador === 'superior_25_64')?.anio)} · EB: {formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'superior_25_64')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="aurreko urtearekiko"
        direction="positive-up"
        source="Eurostat / EPA"
        sparklineData={superior_es}
    />
    <KpiCard
        title="Ez ikasten ez lanean"
        value={resumen.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="15 eta 29 urte bitarteko gazteena {urtean(resumen.find(d => d.indicador === 'neet_15_29')?.anio)} · EB: {formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'neet_15_29')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="aurreko urtearekiko"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={neet_es}
    />
    <KpiCard
        title="Hezkuntzako gastu publikoa"
        value={gasto_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(gasto_es.slice(-1)[0]?.valor, 0)} € biztanleko"
        period="{urtean(gasto_es.slice(-1)[0]?.anio)}, {urteko(gasto_es.slice(-1)[0]?.anio_base)} eurotan · BPGaren {formatNumber(gasto_es.slice(-1)[0]?.pct_pib, 1)} % (EB: {formatNumber(gasto_es.slice(-1)[0]?.pct_pib_ue, 1)} %) · {formatCompact(gasto_es.slice(-1)[0]?.millones_eur * 1e6, 3)} € guztira"
        source="Eurostat / IGAE"
        sparklineData={gasto_es}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('estudios_terciarios', 'gasto_educacion_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'estudios_terciarios')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gasto_educacion_pib')} />


<p class="text-xs text-gray-500">Gazteen eta helduen adierazleak adin-talde bakoitzeko ehunekoak dira (Eurostatek harmonizatutako EPA). Gastua biztanleko edo ikasleko ematen da eta euro konstanteetan, inflazioa KPIarekin kenduta; guztizkoak, erreferentzia gisa soilik.</p>

## Eskola-uzte goiztiarra

```sql abandono_graf
SELECT anio, CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona, valor / 100 AS valor
FROM ${ind}
WHERE indicador = 'abandono'
ORDER BY anio
```

```sql abandono_hitos
SELECT
    CAST(min(anio) AS INTEGER) AS anio_ini,
    arg_min(valor, anio) AS valor_ini,
    max(valor) AS valor_max,
    CAST(arg_max(anio, valor) AS INTEGER) AS anio_max,
    CAST(max(anio) AS INTEGER) AS anio_ult,
    arg_max(valor, anio) AS valor_ult
FROM ${abandono_es}
```

Gehienez DBH amaitu eta ikasten edo prestakuntzan jarraitzen ez duten 18 eta 24 urte bitarteko gazteen ehunekoa da. {urtean(abandono_hitos[0]?.anio_ini)} {formatNumber(abandono_hitos[0]?.valor_ini, 1)} % zen, eta {urtean(abandono_hitos[0]?.anio_ult)} {formatNumber(abandono_hitos[0]?.valor_ult, 1)} % izan zen{#if resumen.find(d => d.indicador === 'abandono')?.valor > resumen.find(d => d.indicador === 'abandono')?.valor_ue}, oraindik Europako batez bestekoaren gainetik{:else}, dagoeneko Europako batez bestekoaren azpitik{/if}. EBren 2030erako helburua 9 %-tik behera jaistea da.

<LineChart
    data={abandono_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Hezkuntza eta prestakuntza goiz uztea (18-24 urtekoen %)"
/>

```sql abandono_ccaa
SELECT i.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS abandono
FROM mother.educacion_indicadores i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
WHERE i.nivel = 'ccaa' AND i.indicador = 'abandono'
QUALIFY row_number() OVER (PARTITION BY i.cod ORDER BY i.anio DESC) = 1
ORDER BY abandono DESC
```

<MapaEspana
    data={abandono_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="abandono"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fef2f2', '#f87171', '#991b1b']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Eurostat"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'abandono', title: 'Uzte goiztiarra', fmt: 'pct1'},
        {id: 'anio', title: 'Urtea', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Erkidego bakoitzeko eskuragarri dagoen azken urtea ({abandono_ccaa[0]?.anio}). Eskualdeko zifrak lagin txikiago batetik ateratzen dira eta urte batetik bestera aldatzen dira; Ceutakoak eta Melillakoak bereziki ezegonkorrak dira.</p>

## Zer ikasketa dituzten helduek

```sql nivel_ult
SELECT
    CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona,
    CASE indicador
        WHEN 'basica_25_64' THEN '1. Hasta la ESO'
        WHEN 'segunda_25_64' THEN '2. Bachillerato o FP de grado medio'
        ELSE '3. Estudios superiores'
    END AS estudios,
    valor / 100 AS valor
FROM ${ind}
WHERE indicador IN ('basica_25_64', 'segunda_25_64', 'superior_25_64')
  AND anio = (SELECT max(anio) FROM ${ind} WHERE indicador = 'superior_25_64' AND nivel = 'pais')
ORDER BY zona, estudios
```

```sql nivel_hitos
SELECT
    CAST(max(anio) AS INTEGER) AS anio_ult,
    max(valor) FILTER (WHERE indicador = 'basica_25_64' AND nivel = 'pais' AND anio = (SELECT max(anio) FROM ${ind} WHERE indicador = 'basica_25_64')) AS basica_es,
    max(valor) FILTER (WHERE indicador = 'basica_25_64' AND nivel = 'ue' AND anio = (SELECT max(anio) FROM ${ind} WHERE indicador = 'basica_25_64')) AS basica_ue,
    max(valor) FILTER (WHERE indicador = 'segunda_25_64' AND nivel = 'pais' AND anio = (SELECT max(anio) FROM ${ind} WHERE indicador = 'segunda_25_64')) AS segunda_es,
    max(valor) FILTER (WHERE indicador = 'segunda_25_64' AND nivel = 'ue' AND anio = (SELECT max(anio) FROM ${ind} WHERE indicador = 'segunda_25_64')) AS segunda_ue,
    max(valor) FILTER (WHERE indicador = 'basica_25_64' AND nivel = 'pais' AND anio = (SELECT min(anio) FROM ${ind} WHERE indicador = 'basica_25_64' AND nivel = 'pais')) AS basica_es_ini,
    CAST(min(anio) FILTER (WHERE indicador = 'basica_25_64' AND nivel = 'pais') AS INTEGER) AS anio_ini
FROM ${ind}
```

Espainiak banaketa oso polarizatua du: {urtean(nivel_hitos[0]?.anio_ult)}, 25 eta 64 urte bitarteko helduen {formatNumber(nivel_hitos[0]?.basica_es, 1)} % ez zen DBHtik harago iritsi (EB: {formatNumber(nivel_hitos[0]?.basica_ue, 1)} %), eta {formatNumber(nivel_hitos[0]?.segunda_es, 1)} %-k baino ez du gehienez batxilergoa edo erdi-mailako LH (EB: {formatNumber(nivel_hitos[0]?.segunda_ue, 1)} %){#if resumen.find(d => d.indicador === 'superior_25_64')?.valor > resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue}, baina goi-mailako ikasketak dituztenen proportzioak Europako batez bestekoa gainditzen du{/if}. {urtean(nivel_hitos[0]?.anio_ini)}, DBHtik harago iristen ez zirenak {formatNumber(nivel_hitos[0]?.basica_es_ini, 1)} % ziren.

<BarChart
    data={nivel_ult}
    x=zona
    y=valor
    series=estudios
    type=stacked100
    swapXY=true
    yFmt=pct0
    colorPalette={['#fca5a5', '#fcd34d', '#2563eb']}
    title="25 eta 64 urte bitarteko biztanleria, amaitutako ikasketa-mailaren arabera ({nivel_hitos[0]?.anio_ult})"
/>

```sql nivel_evol
SELECT
    anio,
    CASE indicador WHEN 'basica_25_64' THEN 'Hasta la ESO' ELSE 'Estudios superiores' END
        || ' · ' || CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS serie,
    valor / 100 AS valor
FROM ${ind}
WHERE indicador IN ('basica_25_64', 'superior_25_64')
ORDER BY anio, serie
```

<LineChart
    data={nivel_evol}
    x=anio
    y=valor
    series=serie
    yFmt=pct0
    xFmt="####"
    colorPalette={['#2563eb', '#93c5fd', '#dc2626', '#fca5a5']}
    title="25 eta 64 urte bitarteko helduak, goi-mailako ikasketekin eta, gehienez, DBHrekin"
/>

<p class="text-xs text-gray-500">Goi-mailako ikasketak: goi-mailako LH, unibertsitate-graduak, masterrak eta doktoregoak (nazioarteko CINE 2011 sailkapenaren 5.etik 8.era bitarteko mailak). Eurostatek sailkapena aldatu zuen 2014an, eta horrek jauzi txikiak eragin ditzake seriean.</p>

## Ez ikasten ez lanean ari diren gazteak

```sql neet_graf
SELECT anio, CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona, valor / 100 AS valor
FROM ${ind}
WHERE indicador = 'neet_15_29'
ORDER BY anio
```

```sql neet_hitos
SELECT max(valor) AS valor_max, CAST(arg_max(anio, valor) AS INTEGER) AS anio_max,
       arg_max(valor, anio) AS valor_ult, CAST(max(anio) AS INTEGER) AS anio_ult
FROM ${neet_es}
```

Enplegurik ez duten eta hezkuntzarik edo prestakuntzarik jasotzen ez duten 15 eta 29 urte bitarteko gazteak dira. {formatNumber(neet_hitos[0]?.valor_max, 1)} %-ra iritsi ziren {urtean(neet_hitos[0]?.anio_max)}, eta {urtean(neet_hitos[0]?.anio_ult)} {formatNumber(neet_hitos[0]?.valor_ult, 1)} % ziren.

<LineChart
    data={neet_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#94a3b8']}
    title="Ez ikasten ez lanean ari diren 15 eta 29 urte bitarteko gazteak (%)"
/>

```sql neet_ccaa
SELECT i.nombre AS comunidad, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS neet
FROM mother.educacion_indicadores i
WHERE i.nivel = 'ccaa' AND i.indicador = 'neet_15_29'
QUALIFY row_number() OVER (PARTITION BY i.cod ORDER BY i.anio DESC) = 1
ORDER BY neet DESC
```

<BarChart
    data={neet_ccaa}
    x=comunidad
    y=neet
    swapXY=true
    yFmt=pct1
    sort=false
    fillColor="#d97706"
    title="Ez ikasten ez lanean ari diren 15 eta 29 urte bitarteko gazteak, erkidegoka ({neet_ccaa[0]?.anio})"
/>

## Zenbat gastatzen den hezkuntzan

```sql gasto_pib
SELECT anio, CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona, pct_pib / 100 AS pct_pib
FROM ${gasto}
WHERE anio >= 1995 AND pct_pib IS NOT NULL
ORDER BY anio
```

```sql gasto_hitos
SELECT
    CAST(max(anio) AS INTEGER) AS anio_ult,
    arg_max(valor, anio) AS valor_ult,
    max(valor) FILTER (WHERE anio = 2009) AS v2009,
    min(valor) FILTER (WHERE anio BETWEEN 2010 AND 2016) AS v_min_crisis,
    CAST(arg_min(anio, valor) FILTER (WHERE anio BETWEEN 2010 AND 2016) AS INTEGER) AS anio_min_crisis,
    max(anio_base) AS anio_base
FROM ${gasto_es}
```

Administrazio guztiek (Estatuak, erkidegoek, udalek) {formatNumber(gasto_hitos[0]?.valor_ult, 0)} € gastatu zituzten biztanleko hezkuntzan {urtean(gasto_hitos[0]?.anio_ult)}, {urteko(gasto_hitos[0]?.anio_base)} eurotan. 2009an {formatNumber(gasto_hitos[0]?.v2009, 0)} € ziren, eta gero {formatNumber(gasto_hitos[0]?.v_min_crisis, 0)} €-ra jaitsi ziren {urtean(gasto_hitos[0]?.anio_min_crisis)}{#if gasto_hitos[0]?.valor_ult < gasto_hitos[0]?.v2009}: inflazioa kenduta, oraindik ez da 2009ko maila berreskuratu{/if}. {#if gasto_es.slice(-1)[0]?.pct_pib < gasto_es.slice(-1)[0]?.pct_pib_ue}Bere ekonomiaren tamainaren arabera, Espainiak EBko batez bestekoak baino gutxiago gastatzen du.{:else}Bere ekonomiaren tamainaren arabera, Espainiak EBko batez bestekoak adina edo gehiago gastatzen du.{/if}

<Grid cols=2>
    <LineChart
        data={gasto_es}
        x=anio
        y=valor
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#0f766e']}
        title="Hezkuntzako gastu publikoa biztanleko ({urteko(gasto_hitos[0]?.anio_base)} euroak)"
    />
    <LineChart
        data={gasto_pib}
        x=anio
        y=pct_pib
        series=zona
        yFmt=pct1
        xFmt="####"
        colorPalette={['#0f766e', '#94a3b8']}
        title="Hezkuntzako gastu publikoa, BPGaren ehunekotan"
    />
</Grid>

<p class="text-xs text-gray-500">Eurostaten gastu publikoaren sailkapen funtzionala (COFOG, 09 funtzioa, Hezkuntza), IGAEren datuekin. Administrazio guztiek irakaskuntza publikoan, itunpekoetan, bekatan eta unibertsitateetan egiten duten gastua barne hartzen du. Inflazioa INEren urteko batez besteko KPIarekin kenduta.</p>

```sql alumno_es
SELECT anio, eur_real, eur, anio_base
FROM mother.educacion_gasto_alumno
WHERE cod_pais = 'ES' AND isced11 = 'ED02-8' AND eur_real IS NOT NULL
ORDER BY anio
```

```sql alumno_niveles
SELECT
    a.nivel_educativo AS nivel,
    CASE a.isced11 WHEN 'ED02' THEN 1 WHEN 'ED1' THEN 2 WHEN 'ED2' THEN 3 WHEN 'ED34_44' THEN 4 WHEN 'ED35_45' THEN 5 ELSE 6 END AS orden,
    CASE a.cod_pais WHEN 'ES' THEN 'España' ELSE 'UE-27' END AS zona,
    a.pps,
    CAST(a.anio AS INTEGER) AS anio
FROM mother.educacion_gasto_alumno a
WHERE a.isced11 IN ('ED02', 'ED1', 'ED2', 'ED34_44', 'ED35_45', 'ED5-8')
  AND a.anio = (SELECT max(anio) FROM mother.educacion_gasto_alumno WHERE cod_pais = 'EU27_2020' AND pps IS NOT NULL)
  AND a.pps IS NOT NULL
ORDER BY orden, zona
```

```sql alumno_hitos
SELECT
    CAST(max(anio) AS INTEGER) AS anio_ult,
    arg_max(eur_real, anio) AS real_ult,
    arg_max(eur, anio) AS eur_ult,
    CAST(min(anio) AS INTEGER) AS anio_ini,
    arg_min(eur_real, anio) AS real_ini,
    max(anio_base) AS anio_base
FROM ${alumno_es}
```

Ikastetxeetako gastua (publikoa eta pribatua) {formatNumber(alumno_hitos[0]?.real_ult, 0)} € izan zen ikasleko {urtean(alumno_hitos[0]?.anio_ult)}, {urteko(alumno_hitos[0]?.anio_base)} eurotan; {urtean(alumno_hitos[0]?.anio_ini)}, berriz, {formatNumber(alumno_hitos[0]?.real_ini, 0)} €. Europarekin alderatzeko, bigarren grafikoak herrialde bakoitzeko prezio-mailaren arabera doitutako euroak erabiltzen ditu (erosteko ahalmenaren estandarra).

<Grid cols=2>
    <LineChart
        data={alumno_es}
        x=anio
        y=eur_real
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#7c3aed']}
        title="Ikasleko gastua, haur hezkuntzatik unibertsitatera ({urteko(alumno_hitos[0]?.anio_base)} euroak)"
    />
    <BarChart
        data={alumno_niveles}
        x=nivel
        y=pps
        series=zona
        type=grouped
        sort=false
        yFmt='#,##0'
        colorPalette={['#7c3aed', '#94a3b8']}
        title="Ikasleko gastua etaparen arabera, erosteko ahalmenean ({alumno_niveles[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Ikastetxeetako urteko gastua lanaldi osoko ikasle baliokideko, finantzaketa-iturri guztietakoa (UNESCO-ELGA-Eurostat). Haur hezkuntza bigarren zikloari dagokio (3 eta 5 urte bitartean). Erosteko ahalmeneko zifrei (PPS) ez zaie inflazioa kendu, eta urte berean herrialdeak alderatzeko baino ez dute balio.</p>

## Ikasleak etapa bakoitzean

```sql matric
SELECT anio, curso, nivel, orden, alumnos, por_1000_hab, pct_publica / 100 AS pct_publica, pct_concertada / 100 AS pct_concertada, pct_privada / 100 AS pct_privada
FROM mother.educacion_matriculados
WHERE nivel <> 'Postsecundaria no superior'
ORDER BY anio, orden
```

```sql matric_ult
SELECT * FROM ${matric} WHERE anio = (SELECT max(anio) FROM ${matric}) ORDER BY orden
```

```sql matric_total
SELECT
    max(curso) AS curso,
    sum(alumnos) AS alumnos,
    sum(por_1000_hab) AS por_1000
FROM ${matric_ult}
```

1.000 biztanleko {formatNumber(matric_total[0]?.por_1000, 0)} ikasle zeuden {matric_total[0]?.curso} ikasturtean, haur hezkuntzatik unibertsitatera ({formatCompact(matric_total[0]?.alumnos, 3)} guztira).

<BarChart
    data={matric}
    x=curso
    y=por_1000_hab
    series=nivel
    type=stacked
    sort=false
    yFmt=num0
    colorPalette={['#fcd34d', '#fb923c', '#f87171', '#60a5fa', '#34d399', '#059669', '#6366f1']}
    title="Matrikulatutako ikasleak 1.000 biztanleko, etaparen arabera"
/>

```sql titularidad
SELECT nivel, orden, 'Pública' AS titularidad, pct_publica AS cuota FROM ${matric_ult}
UNION ALL
SELECT nivel, orden, 'Concertada' AS titularidad, pct_concertada AS cuota FROM ${matric_ult}
UNION ALL
SELECT nivel, orden, 'Privada' AS titularidad, pct_privada AS cuota FROM ${matric_ult}
ORDER BY orden
```

<BarChart
    data={titularidad}
    x=nivel
    y=cuota
    series=titularidad
    type=stacked100
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#2563eb', '#a78bfa', '#f59e0b']}
    title="Ikasleak ikastetxearen titulartasunaren arabera, {matric_ult[0]?.curso} ikasturtea"
/>

<p class="text-xs text-gray-500">Itunpekoa: batez ere funts publikoekin finantzatutako ikastetxe pribatuak (Eurostat, «Estatuaren mendeko pribatuak»). Haur hezkuntzak lehen zikloa barne hartzen du (0 eta 2 urte bitartean). Erdi-mailako eta oinarrizko LH: bigarren hezkuntzako bigarren etapako lanbide-programak. Unibertsitate-blokeak beste goi-mailako irakaskuntza batzuk ere barne hartzen ditu (artistikoak, kirolekoak). Urtea ikasturtearen amaierakoa da.</p>

```sql fp
SELECT anio, CAST(anio - 1 AS INTEGER) || '-' || right(CAST(CAST(anio AS INTEGER) AS VARCHAR), 2) AS curso,
       CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona, pct_fp / 100 AS pct_fp
FROM mother.educacion_fp
ORDER BY anio
```

```sql fp_hitos
SELECT
    max(curso) FILTER (WHERE zona = 'España' AND anio = (SELECT max(anio) FROM ${fp})) AS curso_ult,
    max(pct_fp) FILTER (WHERE zona = 'España' AND anio = (SELECT max(anio) FROM ${fp})) AS es_ult,
    max(pct_fp) FILTER (WHERE zona = 'UE-27' AND anio = (SELECT max(anio) FROM ${fp})) AS ue_ult,
    max(pct_fp) FILTER (WHERE zona = 'España' AND anio = (SELECT min(anio) FROM ${fp})) AS es_ini,
    min(curso) AS curso_ini
FROM ${fp}
```

Bigarren hezkuntzako bigarren etapako ikasleen {formatNumber(fp_hitos[0]?.es_ult / 0.01, 1)} % LH ikasten ari zen {fp_hitos[0]?.curso_ult} ikasturtean; {fp_hitos[0]?.curso_ini} ikasturtean, berriz, {formatNumber(fp_hitos[0]?.es_ini / 0.01, 1)} %; EBn, {formatNumber(fp_hitos[0]?.ue_ult / 0.01, 1)} %.{#if fp_hitos[0]?.es_ult > fp_hitos[0]?.es_ini} Lanbide-heziketak pisua irabazten du.{/if}

<LineChart
    data={fp}
    x=curso
    y=pct_fp
    series=zona
    yFmt=pct0
    colorPalette={['#059669', '#94a3b8']}
    title="LHko ikasleak bigarren hezkuntzako bigarren etaparen ehunekotan (batxilergoa + LH)"
/>

## PISA: errendimendu txikiko 15 urteko ikasleak

```sql pisa
SELECT anio, materia, CASE nivel WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona, pct_bajo_rendimiento / 100 AS valor
FROM mother.educacion_pisa
WHERE sexo = 'Total'
ORDER BY anio
```

```sql pisa_ult
SELECT materia, zona, valor, CAST(anio AS INTEGER) AS anio
FROM ${pisa}
WHERE anio = (SELECT max(anio) FROM ${pisa})
ORDER BY materia, zona
```

```sql pisa_hitos
SELECT
    CAST(max(anio) AS INTEGER) AS anio_ult,
    max(valor) FILTER (WHERE zona = 'España' AND materia = 'Matemáticas' AND anio = (SELECT max(anio) FROM ${pisa})) AS mat_es,
    max(valor) FILTER (WHERE zona = 'UE-27' AND materia = 'Matemáticas' AND anio = (SELECT max(anio) FROM ${pisa})) AS mat_ue,
    max(valor) FILTER (WHERE zona = 'España' AND materia = 'Lectura' AND anio = (SELECT max(anio) FROM ${pisa})) AS lec_es,
    max(valor) FILTER (WHERE zona = 'UE-27' AND materia = 'Lectura' AND anio = (SELECT max(anio) FROM ${pisa})) AS lec_ue,
    max(valor) FILTER (WHERE zona = 'España' AND materia = 'Ciencias' AND anio = (SELECT max(anio) FROM ${pisa})) AS cie_es,
    max(valor) FILTER (WHERE zona = 'UE-27' AND materia = 'Ciencias' AND anio = (SELECT max(anio) FROM ${pisa})) AS cie_ue
FROM ${pisa}
```

ELGAren PISA txostenak hiru urtean behin ebaluatzen ditu 15 urteko ikasleak. Hemen erakusten da zer zatik ez duen lortzen gaitasun-maila oinarrizkoa (2. maila). {urtean(pisa_hitos[0]?.anio_ult)}, Espainian {formatNumber(pisa_hitos[0]?.mat_es / 0.01, 1)} % izan ziren matematikan (EB: {formatNumber(pisa_hitos[0]?.mat_ue / 0.01, 1)} %), {formatNumber(pisa_hitos[0]?.lec_es / 0.01, 1)} % irakurmenean (EB: {formatNumber(pisa_hitos[0]?.lec_ue / 0.01, 1)} %) eta {formatNumber(pisa_hitos[0]?.cie_es / 0.01, 1)} % zientzietan (EB: {formatNumber(pisa_hitos[0]?.cie_ue / 0.01, 1)} %).

<BarChart
    data={pisa_ult}
    x=materia
    y=valor
    series=zona
    type=grouped
    yFmt=pct0
    colorPalette={['#db2777', '#94a3b8']}
    title="Oinarrizko mailatik behera dauden 15 urteko ikasleak, PISA {pisa_ult[0]?.anio}"
/>

```sql pisa_es
SELECT anio, materia, valor FROM ${pisa} WHERE zona = 'España' ORDER BY anio
```

<LineChart
    data={pisa_es}
    x=anio
    y=valor
    series=materia
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#0891b2', '#db2777', '#65a30d']}
    title="Espainia: oinarrizko mailatik behera dauden 15 urteko ikasleak, PISA edizioka"
/>

<p class="text-xs text-gray-500">2021erako aurreikusitako edizioa 2022an egin zen, pandemiagatik. ELGAk ez zuen argitaratu Espainiaren 2018ko irakurmen-emaitza, ikasleen zati baten erantzunetan anomaliak zeudelako. Eurostatek errendimendu txikiko ikasleen ehunekoa argitaratzen du, ez batez besteko puntuazioa.</p>

---

## Iturriak eta oharrak

- **[Eurostat – Hezkuntza eta prestakuntza goiz uztea](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_14/default/table)** (edat_lfse_14 eta, eskualdeka, edat_lfse_16), INEren EPAtik abiatuta.
- **[Eurostat – Biztanleria hezkuntza-mailaren arabera](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03/default/table)** (edat_lfse_03 eta, eskualdeka, edat_lfse_04).
- **[Eurostat – Ez lanean ez ikasten ari diren gazteak (NEET)](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_20/default/table)** (edat_lfse_20 eta, eskualdeka, edat_lfse_22).
- **[Eurostat – Administrazio publikoen gastua funtzioaren arabera (COFOG)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table)** (gov_10a_exp, 09 funtzioa, Hezkuntza).
- **[Eurostat – Ikastetxeetako gastua ikasleko](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_fini04/default/table)** (educ_uoe_fini04).
- **[Eurostat – Matrikulatutako ikasleak](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_enra01/default/table)** (educ_uoe_enra01 eta educ_uoe_enrs04).
- **[Eurostat – Errendimendu txikia PISAn](https://ec.europa.eu/eurostat/databrowser/view/educ_outc_pisa/default/table)** (educ_outc_pisa), ELGAren datuekin.
- Deflatorea: INEren urteko batez besteko KPIa. Biztanleria: INE eta Eurostat.

<LastRefreshed prefix="Datuak eguneratuta" />
