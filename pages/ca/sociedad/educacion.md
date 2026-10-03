---
title: Educació
description: "Abandonament escolar prematur, nivell educatiu dels adults, joves que ni estudien ni treballen, despesa en educació per habitant i per alumne, alumnat per nivell i PISA, amb Espanya davant la UE i per comunitat."
i18n_origen: 1ee091a54980
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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

# 🎓 Educació

Quants joves deixen d'estudiar massa aviat, quina formació tenen els adults, quants joves ni estudien ni treballen, quant es gasta en educació, quants alumnes hi ha a cada etapa i quins resultats treuen a PISA, sempre davant de la mitjana de la Unió Europea.

<Grid cols=4>
    <KpiCard
        title="Abandonament escolar prematur"
        value={resumen.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="dels joves de 18 a 24 anys el {resumen.find(d => d.indicador === 'abandono')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'abandono')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs. any anterior"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={abandono_es}
    />
    <KpiCard
        title="Adults amb estudis superiors"
        value={resumen.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="de 25 a 64 anys el {resumen.find(d => d.indicador === 'superior_25_64')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'superior_25_64')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs. any anterior"
        direction="positive-up"
        source="Eurostat / EPA"
        sparklineData={superior_es}
    />
    <KpiCard
        title="Ni estudien ni treballen"
        value={resumen.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="dels joves de 15 a 29 anys el {resumen.find(d => d.indicador === 'neet_15_29')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'neet_15_29')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs. any anterior"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={neet_es}
    />
    <KpiCard
        title="Despesa pública en educació"
        value={gasto_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(gasto_es.slice(-1)[0]?.valor, 0)} € per habitant"
        period="el {gasto_es.slice(-1)[0]?.anio}, euros de {gasto_es.slice(-1)[0]?.anio_base} · {formatNumber(gasto_es.slice(-1)[0]?.pct_pib, 1)} % del PIB (UE: {formatNumber(gasto_es.slice(-1)[0]?.pct_pib_ue, 1)} %) · {formatCompact(gasto_es.slice(-1)[0]?.millones_eur * 1e6, 3)} € en total"
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


<p class="text-xs text-gray-500">Els indicadors de joves i adults són percentatges de cada grup d'edat (EPA harmonitzada per Eurostat). La despesa es dona per habitant o per alumne i en euros constants, descomptada la inflació amb l'IPC; els totals, només com a referència.</p>

## Abandonament escolar prematur

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

És el percentatge de joves de 18 a 24 anys que, com a molt, han acabat l'ESO i no continuen estudiant ni formant-se. El {abandono_hitos[0]?.anio_ini} era el {formatNumber(abandono_hitos[0]?.valor_ini, 1)} % i el {abandono_hitos[0]?.anio_ult} va ser del {formatNumber(abandono_hitos[0]?.valor_ult, 1)} %{#if resumen.find(d => d.indicador === 'abandono')?.valor > resumen.find(d => d.indicador === 'abandono')?.valor_ue}, encara per sobre de la mitjana europea{:else}, ja per sota de la mitjana europea{/if}. L'objectiu de la UE per al 2030 és baixar del 9 %.

<LineChart
    data={abandono_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Abandonament prematur de l'educació i la formació (% de 18-24 anys)"
/>

```sql abandono_ccaa
SELECT i.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS abandono
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Eurostat"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'abandono', title: 'Abandonament prematur', fmt: 'pct1'},
        {id: 'anio', title: 'Any', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Últim any disponible de cada comunitat ({abandono_ccaa[0]?.anio}). Les xifres regionals surten d'una mostra més petita i oscil·len d'un any a l'altre; les de Ceuta i Melilla són especialment inestables.</p>

## Quins estudis tenen els adults

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

Espanya té un repartiment molt polaritzat: el {nivel_hitos[0]?.anio_ult}, el {formatNumber(nivel_hitos[0]?.basica_es, 1)} % dels adults de 25 a 64 anys no va passar de l'ESO (UE: {formatNumber(nivel_hitos[0]?.basica_ue, 1)} %) i només el {formatNumber(nivel_hitos[0]?.segunda_es, 1)} % té com a màxim batxillerat o FP de grau mitjà (UE: {formatNumber(nivel_hitos[0]?.segunda_ue, 1)} %){#if resumen.find(d => d.indicador === 'superior_25_64')?.valor > resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue}, però la proporció amb estudis superiors supera la mitjana europea{/if}. El {nivel_hitos[0]?.anio_ini} els qui no passaven de l'ESO eren el {formatNumber(nivel_hitos[0]?.basica_es_ini, 1)} %.

<BarChart
    data={nivel_ult}
    x=zona
    y=valor
    series=estudios
    type=stacked100
    swapXY=true
    yFmt=pct0
    colorPalette={['#fca5a5', '#fcd34d', '#2563eb']}
    title="Població de 25 a 64 anys per nivell d'estudis acabat ({nivel_hitos[0]?.anio_ult})"
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
    title="Adults de 25 a 64 anys amb estudis superiors i amb, com a molt, l'ESO"
/>

<p class="text-xs text-gray-500">Estudis superiors: FP de grau superior, graus universitaris, màsters i doctorats (nivells 5 a 8 de la classificació internacional CINE 2011). Eurostat va canviar de classificació el 2014, cosa que pot causar petits salts a la sèrie.</p>

## Joves que ni estudien ni treballen

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

Són els joves de 15 a 29 anys que ni tenen feina ni reben educació o formació. Van arribar al {formatNumber(neet_hitos[0]?.valor_max, 1)} % el {neet_hitos[0]?.anio_max} i el {neet_hitos[0]?.anio_ult} eren el {formatNumber(neet_hitos[0]?.valor_ult, 1)} %.

<LineChart
    data={neet_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#94a3b8']}
    title="Joves de 15 a 29 anys que ni estudien ni treballen (%)"
/>

```sql neet_ccaa
SELECT t.nombre AS comunidad, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS neet
FROM mother.educacion_indicadores i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
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
    title="Joves de 15 a 29 anys que ni estudien ni treballen, per comunitat ({neet_ccaa[0]?.anio})"
/>

## Quant es gasta en educació

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

Totes les administracions (Estat, comunitats, ajuntaments) van gastar el {gasto_hitos[0]?.anio_ult} {formatNumber(gasto_hitos[0]?.valor_ult, 0)} € per habitant en educació, en euros de {gasto_hitos[0]?.anio_base}. El 2009 eren {formatNumber(gasto_hitos[0]?.v2009, 0)} € i després van baixar a {formatNumber(gasto_hitos[0]?.v_min_crisis, 0)} € el {gasto_hitos[0]?.anio_min_crisis}{#if gasto_hitos[0]?.valor_ult < gasto_hitos[0]?.v2009}: descomptada la inflació, encara no s'ha recuperat el nivell del 2009{/if}. {#if gasto_es.slice(-1)[0]?.pct_pib < gasto_es.slice(-1)[0]?.pct_pib_ue}En proporció a la mida de la seva economia, Espanya gasta menys que la mitjana de la UE.{:else}En proporció a la mida de la seva economia, Espanya gasta com la mitjana de la UE o més.{/if}

<Grid cols=2>
    <LineChart
        data={gasto_es}
        x=anio
        y=valor
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#0f766e']}
        title="Despesa pública en educació per habitant (euros de {gasto_hitos[0]?.anio_base})"
    />
    <LineChart
        data={gasto_pib}
        x=anio
        y=pct_pib
        series=zona
        yFmt=pct1
        xFmt="####"
        colorPalette={['#0f766e', '#94a3b8']}
        title="Despesa pública en educació en % del PIB"
    />
</Grid>

<p class="text-xs text-gray-500">Classificació funcional de la despesa pública (COFOG, funció 09 Educació) d'Eurostat, amb dades de la IGAE. Inclou la despesa de totes les administracions en ensenyament públic, concerts, beques i universitats. Descomptada la inflació amb l'IPC mitjà anual de l'INE.</p>

```sql alumno_es
SELECT anio, eur_real, eur, anio_base
FROM mother.educacion_gasto_alumno
WHERE nivel_geo = 'pais' AND isced11 = 'ED02-8' AND eur_real IS NOT NULL
ORDER BY anio
```

```sql alumno_niveles
SELECT
    a.nivel,
    CASE a.isced11 WHEN 'ED02' THEN 1 WHEN 'ED1' THEN 2 WHEN 'ED2' THEN 3 WHEN 'ED34_44' THEN 4 WHEN 'ED35_45' THEN 5 ELSE 6 END AS orden,
    CASE a.nivel_geo WHEN 'pais' THEN 'España' ELSE 'UE-27' END AS zona,
    a.pps,
    CAST(a.anio AS INTEGER) AS anio
FROM mother.educacion_gasto_alumno a
WHERE a.isced11 IN ('ED02', 'ED1', 'ED2', 'ED34_44', 'ED35_45', 'ED5-8')
  AND a.anio = (SELECT max(anio) FROM mother.educacion_gasto_alumno WHERE nivel_geo = 'ue' AND pps IS NOT NULL)
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

La despesa en centres educatius (públics i privats) va ser de {formatNumber(alumno_hitos[0]?.real_ult, 0)} € per alumne el {alumno_hitos[0]?.anio_ult}, en euros de {alumno_hitos[0]?.anio_base}, davant de {formatNumber(alumno_hitos[0]?.real_ini, 0)} € el {alumno_hitos[0]?.anio_ini}. Per comparar amb Europa, el segon gràfic fa servir euros ajustats pel nivell de preus de cada país (estàndard de poder adquisitiu).

<Grid cols=2>
    <LineChart
        data={alumno_es}
        x=anio
        y=eur_real
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#7c3aed']}
        title="Despesa per alumne, d'infantil a la universitat (euros de {alumno_hitos[0]?.anio_base})"
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
        title="Despesa per alumne per etapa, en poder adquisitiu ({alumno_niveles[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Despesa anual en centres educatius per alumne equivalent a temps complet, de totes les fonts de finançament (UNESCO-OCDE-Eurostat). Infantil es refereix al segon cicle (3 a 5 anys). Les xifres en poder adquisitiu (PPS) no estan descomptades d'inflació i només serveixen per comparar països en un mateix any.</p>

## Alumnes a cada etapa

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

El curs {matric_total[0]?.curso} hi havia {formatNumber(matric_total[0]?.por_1000, 0)} alumnes per cada 1.000 habitants, d'infantil a la universitat ({formatCompact(matric_total[0]?.alumnos, 3)} en total).

<BarChart
    data={matric}
    x=curso
    y=por_1000_hab
    series=nivel
    type=stacked
    sort=false
    yFmt=num0
    colorPalette={['#fcd34d', '#fb923c', '#f87171', '#60a5fa', '#34d399', '#059669', '#6366f1']}
    title="Alumnes matriculats per 1.000 habitants, per etapa"
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
    title="Alumnat per titularitat del centre, curs {matric_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">Concertada: centres privats finançats principalment amb fons públics (Eurostat, «privats dependents de l'Estat»). Infantil inclou el primer cicle (0 a 2 anys). FP de grau mitjà i bàsica: programes professionals de la segona etapa de secundària. El bloc universitari inclou també altres ensenyaments superiors (artístics, esportius). L'any és el del final del curs.</p>

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

El curs {fp_hitos[0]?.curso_ult} el {formatNumber(fp_hitos[0]?.es_ult / 0.01, 1)} % dels alumnes de la segona etapa de secundària estudiava FP, davant del {formatNumber(fp_hitos[0]?.es_ini / 0.01, 1)} % el {fp_hitos[0]?.curso_ini}; a la UE, el {formatNumber(fp_hitos[0]?.ue_ult / 0.01, 1)} %.{#if fp_hitos[0]?.es_ult > fp_hitos[0]?.es_ini} La formació professional guanya pes.{/if}

<LineChart
    data={fp}
    x=curso
    y=pct_fp
    series=zona
    yFmt=pct0
    colorPalette={['#059669', '#94a3b8']}
    title="Alumnes d'FP en % de la segona etapa de secundària (batxillerat + FP)"
/>

## PISA: alumnes de 15 anys amb baix rendiment

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

L'informe PISA de l'OCDE avalua cada tres anys alumnes de 15 anys. Aquí es mostra quina part no arriba al nivell bàsic de competència (nivell 2). El {pisa_hitos[0]?.anio_ult}, a Espanya van ser el {formatNumber(pisa_hitos[0]?.mat_es / 0.01, 1)} % en matemàtiques (UE: {formatNumber(pisa_hitos[0]?.mat_ue / 0.01, 1)} %), el {formatNumber(pisa_hitos[0]?.lec_es / 0.01, 1)} % en lectura (UE: {formatNumber(pisa_hitos[0]?.lec_ue / 0.01, 1)} %) i el {formatNumber(pisa_hitos[0]?.cie_es / 0.01, 1)} % en ciències (UE: {formatNumber(pisa_hitos[0]?.cie_ue / 0.01, 1)} %).

<BarChart
    data={pisa_ult}
    x=materia
    y=valor
    series=zona
    type=grouped
    yFmt=pct0
    colorPalette={['#db2777', '#94a3b8']}
    title="Alumnes de 15 anys per sota del nivell bàsic a PISA {pisa_ult[0]?.anio}"
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
    title="Espanya: alumnes de 15 anys per sota del nivell bàsic, per edició de PISA"
/>

<p class="text-xs text-gray-500">L'edició prevista per al 2021 es va fer el 2022 per la pandèmia. L'OCDE no va publicar el resultat de lectura d'Espanya del 2018 per anomalies en les respostes d'una part dels alumnes. Eurostat publica el percentatge d'alumnes amb baix rendiment, no la puntuació mitjana.</p>

---

## Fonts i notes

- **[Eurostat – Abandonament prematur de l'educació i la formació](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_14/default/table)** (edat_lfse_14 i, per regió, edat_lfse_16), a partir de l'EPA de l'INE.
- **[Eurostat – Població per nivell educatiu](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03/default/table)** (edat_lfse_03 i, per regió, edat_lfse_04).
- **[Eurostat – Joves que ni treballen ni estudien (NEET)](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_20/default/table)** (edat_lfse_20 i, per regió, edat_lfse_22).
- **[Eurostat – Despesa de les AP per funció (COFOG)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table)** (gov_10a_exp, funció 09 Educació).
- **[Eurostat – Despesa en centres educatius per alumne](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_fini04/default/table)** (educ_uoe_fini04).
- **[Eurostat – Alumnat matriculat](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_enra01/default/table)** (educ_uoe_enra01 i educ_uoe_enrs04).
- **[Eurostat – Baix rendiment a PISA](https://ec.europa.eu/eurostat/databrowser/view/educ_outc_pisa/default/table)** (educ_outc_pisa), amb dades de l'OCDE.
- Deflactor: IPC mitjà anual de l'INE. Població: INE i Eurostat.

<LastRefreshed prefix="Dades actualitzades" />
