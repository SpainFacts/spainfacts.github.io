---
title: Educación
description: "Abandono escolar temperán, nivel educativo dos adultos, mozos que nin estudan nin traballan, gasto en educación por habitante e por alumno, alumnado por nivel e PISA, con España fronte á UE e por comunidade."
i18n_origen: 350e27897b13
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

# 🎓 Educación

Cantos mozos deixan de estudar demasiado cedo, que formación teñen os adultos, cantos mozos nin estudan nin traballan, canto se gasta en educación, cantos alumnos hai en cada etapa e que resultados obteñen en PISA, sempre fronte á media da Unión Europea.

<Grid cols=4>
    <KpiCard
        title="Abandono escolar temperán"
        value={resumen.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="dos mozos de 18 a 24 anos en {resumen.find(d => d.indicador === 'abandono')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'abandono')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="fronte ao ano anterior"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={abandono_es}
    />
    <KpiCard
        title="Adultos con estudos superiores"
        value={resumen.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="de 25 a 64 anos en {resumen.find(d => d.indicador === 'superior_25_64')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'superior_25_64')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="fronte ao ano anterior"
        direction="positive-up"
        source="Eurostat / EPA"
        sparklineData={superior_es}
    />
    <KpiCard
        title="Nin estudan nin traballan"
        value={resumen.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="dos mozos de 15 a 29 anos en {resumen.find(d => d.indicador === 'neet_15_29')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'neet_15_29')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="fronte ao ano anterior"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={neet_es}
    />
    <KpiCard
        title="Gasto público en educación"
        value={gasto_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(gasto_es.slice(-1)[0]?.valor, 0)} € por habitante"
        period="en {gasto_es.slice(-1)[0]?.anio}, euros de {gasto_es.slice(-1)[0]?.anio_base} · {formatNumber(gasto_es.slice(-1)[0]?.pct_pib, 1)} % do PIB (UE: {formatNumber(gasto_es.slice(-1)[0]?.pct_pib_ue, 1)} %) · {formatCompact(gasto_es.slice(-1)[0]?.millones_eur * 1e6, 3)} € en total"
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


<p class="text-xs text-gray-500">Os indicadores de mozos e adultos son porcentaxes de cada grupo de idade (EPA harmonizada por Eurostat). O gasto dáse por habitante ou por alumno e en euros constantes, descontada a inflación co IPC; os totais, só como referencia.</p>

## Abandono escolar temperán

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

É a porcentaxe de mozos de 18 a 24 anos que, como moito, remataron a ESO e non seguen estudando nin formándose. En {abandono_hitos[0]?.anio_ini} era o {formatNumber(abandono_hitos[0]?.valor_ini, 1)} % e en {abandono_hitos[0]?.anio_ult} foi do {formatNumber(abandono_hitos[0]?.valor_ult, 1)} %{#if resumen.find(d => d.indicador === 'abandono')?.valor > resumen.find(d => d.indicador === 'abandono')?.valor_ue}, aínda por riba da media europea{:else}, xa por debaixo da media europea{/if}. O obxectivo da UE para 2030 é baixar do 9 %.

<LineChart
    data={abandono_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Abandono temperán da educación e a formación (% de 18-24 anos)"
/>

```sql abandono_ccaa
SELECT i.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS abandono
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Eurostat"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'abandono', title: 'Abandono temperán', fmt: 'pct1'},
        {id: 'anio', title: 'Ano', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Último ano dispoñible de cada comunidade ({abandono_ccaa[0]?.anio}). As cifras rexionais saen dunha mostra máis pequena e oscilan dun ano a outro; as de Ceuta e Melilla son especialmente inestables.</p>

## Que estudos teñen os adultos

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

España ten un reparto moi polarizado: en {nivel_hitos[0]?.anio_ult}, o {formatNumber(nivel_hitos[0]?.basica_es, 1)} % dos adultos de 25 a 64 anos non pasou da ESO (UE: {formatNumber(nivel_hitos[0]?.basica_ue, 1)} %) e só o {formatNumber(nivel_hitos[0]?.segunda_es, 1)} % ten como máximo bacharelato ou FP de grao medio (UE: {formatNumber(nivel_hitos[0]?.segunda_ue, 1)} %){#if resumen.find(d => d.indicador === 'superior_25_64')?.valor > resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue}, pero a proporción con estudos superiores supera a media europea{/if}. En {nivel_hitos[0]?.anio_ini} os que non pasaban da ESO eran o {formatNumber(nivel_hitos[0]?.basica_es_ini, 1)} %.

<BarChart
    data={nivel_ult}
    x=zona
    y=valor
    series=estudios
    type=stacked100
    swapXY=true
    yFmt=pct0
    colorPalette={['#fca5a5', '#fcd34d', '#2563eb']}
    title="Poboación de 25 a 64 anos por nivel de estudos rematado ({nivel_hitos[0]?.anio_ult})"
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
    title="Adultos de 25 a 64 anos con estudos superiores e con, como moito, a ESO"
/>

<p class="text-xs text-gray-500">Estudos superiores: FP de grao superior, graos universitarios, mestrados e doutoramentos (niveis 5 a 8 da clasificación internacional CINE 2011). Eurostat cambiou de clasificación en 2014, o que pode causar pequenos saltos na serie.</p>

## Mozos que nin estudan nin traballan

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

Son os mozos de 15 a 29 anos que nin teñen emprego nin reciben educación ou formación. Chegaron ao {formatNumber(neet_hitos[0]?.valor_max, 1)} % en {neet_hitos[0]?.anio_max} e en {neet_hitos[0]?.anio_ult} eran o {formatNumber(neet_hitos[0]?.valor_ult, 1)} %.

<LineChart
    data={neet_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#94a3b8']}
    title="Mozos de 15 a 29 anos que nin estudan nin traballan (%)"
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
    title="Mozos de 15 a 29 anos que nin estudan nin traballan, por comunidade ({neet_ccaa[0]?.anio})"
/>

## Canto se gasta en educación

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

Todas as administracións (Estado, comunidades, concellos) gastaron en {gasto_hitos[0]?.anio_ult} {formatNumber(gasto_hitos[0]?.valor_ult, 0)} € por habitante en educación, en euros de {gasto_hitos[0]?.anio_base}. En 2009 eran {formatNumber(gasto_hitos[0]?.v2009, 0)} € e despois baixaron a {formatNumber(gasto_hitos[0]?.v_min_crisis, 0)} € en {gasto_hitos[0]?.anio_min_crisis}{#if gasto_hitos[0]?.valor_ult < gasto_hitos[0]?.v2009}: descontada a inflación, aínda non se recuperou o nivel de 2009{/if}. {#if gasto_es.slice(-1)[0]?.pct_pib < gasto_es.slice(-1)[0]?.pct_pib_ue}En proporción ao tamaño da súa economía, España gasta menos que a media da UE.{:else}En proporción ao tamaño da súa economía, España gasta coma a media da UE ou máis.{/if}

<Grid cols=2>
    <LineChart
        data={gasto_es}
        x=anio
        y=valor
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#0f766e']}
        title="Gasto público en educación por habitante (euros de {gasto_hitos[0]?.anio_base})"
    />
    <LineChart
        data={gasto_pib}
        x=anio
        y=pct_pib
        series=zona
        yFmt=pct1
        xFmt="####"
        colorPalette={['#0f766e', '#94a3b8']}
        title="Gasto público en educación en % do PIB"
    />
</Grid>

<p class="text-xs text-gray-500">Clasificación funcional do gasto público (COFOG, función 09 Educación) de Eurostat, con datos da IGAE. Inclúe o gasto de todas as administracións en ensino público, concertos, bolsas e universidades. Descontada a inflación co IPC medio anual do INE.</p>

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

O gasto en centros educativos (públicos e privados) foi de {formatNumber(alumno_hitos[0]?.real_ult, 0)} € por alumno en {alumno_hitos[0]?.anio_ult}, en euros de {alumno_hitos[0]?.anio_base}, fronte a {formatNumber(alumno_hitos[0]?.real_ini, 0)} € en {alumno_hitos[0]?.anio_ini}. Para comparar con Europa, a segunda gráfica usa euros axustados polo nivel de prezos de cada país (estándar de poder de compra).

<Grid cols=2>
    <LineChart
        data={alumno_es}
        x=anio
        y=eur_real
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#7c3aed']}
        title="Gasto por alumno, de infantil á universidade (euros de {alumno_hitos[0]?.anio_base})"
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
        title="Gasto por alumno por etapa, en poder de compra ({alumno_niveles[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Gasto anual en centros educativos por alumno equivalente a tempo completo, de todas as fontes de financiamento (UNESCO-OCDE-Eurostat). Infantil refírese ao segundo ciclo (3 a 5 anos). As cifras en poder de compra (PPS) non están descontadas de inflación e só serven para comparar países nun mesmo ano.</p>

## Alumnos en cada etapa

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

No curso {matric_total[0]?.curso} había {formatNumber(matric_total[0]?.por_1000, 0)} alumnos por cada 1.000 habitantes, de infantil á universidade ({formatCompact(matric_total[0]?.alumnos, 3)} en total).

<BarChart
    data={matric}
    x=curso
    y=por_1000_hab
    series=nivel
    type=stacked
    sort=false
    yFmt=num0
    colorPalette={['#fcd34d', '#fb923c', '#f87171', '#60a5fa', '#34d399', '#059669', '#6366f1']}
    title="Alumnos matriculados por 1.000 habitantes, por etapa"
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
    title="Alumnado pola titularidade do centro, curso {matric_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">Concertada: centros privados financiados principalmente con fondos públicos (Eurostat, «privados dependentes do Estado»). Infantil inclúe o primeiro ciclo (0 a 2 anos). FP de grao medio e básica: programas profesionais da segunda etapa de secundaria. O bloque universitario inclúe tamén outros ensinos superiores (artísticos, deportivos). O ano é o do final do curso.</p>

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

No curso {fp_hitos[0]?.curso_ult} o {formatNumber(fp_hitos[0]?.es_ult / 0.01, 1)} % dos alumnos da segunda etapa de secundaria estudaba FP, fronte ao {formatNumber(fp_hitos[0]?.es_ini / 0.01, 1)} % en {fp_hitos[0]?.curso_ini}; na UE, o {formatNumber(fp_hitos[0]?.ue_ult / 0.01, 1)} %.{#if fp_hitos[0]?.es_ult > fp_hitos[0]?.es_ini} A formación profesional gaña peso.{/if}

<LineChart
    data={fp}
    x=curso
    y=pct_fp
    series=zona
    yFmt=pct0
    colorPalette={['#059669', '#94a3b8']}
    title="Alumnos de FP en % da segunda etapa de secundaria (bacharelato + FP)"
/>

## PISA: alumnos de 15 anos con baixo rendemento

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

O informe PISA da OCDE avalía cada tres anos a alumnos de 15 anos. Aquí amósase que parte non acada o nivel básico de competencia (nivel 2). En {pisa_hitos[0]?.anio_ult}, en España foron o {formatNumber(pisa_hitos[0]?.mat_es / 0.01, 1)} % en matemáticas (UE: {formatNumber(pisa_hitos[0]?.mat_ue / 0.01, 1)} %), o {formatNumber(pisa_hitos[0]?.lec_es / 0.01, 1)} % en lectura (UE: {formatNumber(pisa_hitos[0]?.lec_ue / 0.01, 1)} %) e o {formatNumber(pisa_hitos[0]?.cie_es / 0.01, 1)} % en ciencias (UE: {formatNumber(pisa_hitos[0]?.cie_ue / 0.01, 1)} %).

<BarChart
    data={pisa_ult}
    x=materia
    y=valor
    series=zona
    type=grouped
    yFmt=pct0
    colorPalette={['#db2777', '#94a3b8']}
    title="Alumnos de 15 anos por debaixo do nivel básico en PISA {pisa_ult[0]?.anio}"
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
    title="España: alumnos de 15 anos por debaixo do nivel básico, por edición de PISA"
/>

<p class="text-xs text-gray-500">A edición prevista para 2021 fíxose en 2022 pola pandemia. A OCDE non publicou o resultado de lectura de España en 2018 por anomalías nas respostas dunha parte dos alumnos. Eurostat publica a porcentaxe de alumnos con baixo rendemento, non a puntuación media.</p>

---

## Fontes e notas

- **[Eurostat – Abandono temperán da educación e a formación](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_14/default/table)** (edat_lfse_14 e, por rexión, edat_lfse_16), a partir da EPA do INE.
- **[Eurostat – Poboación por nivel educativo](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03/default/table)** (edat_lfse_03 e, por rexión, edat_lfse_04).
- **[Eurostat – Mozos que nin traballan nin estudan (NEET)](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_20/default/table)** (edat_lfse_20 e, por rexión, edat_lfse_22).
- **[Eurostat – Gasto das AAPP por función (COFOG)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table)** (gov_10a_exp, función 09 Educación).
- **[Eurostat – Gasto en centros educativos por alumno](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_fini04/default/table)** (educ_uoe_fini04).
- **[Eurostat – Alumnado matriculado](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_enra01/default/table)** (educ_uoe_enra01 e educ_uoe_enrs04).
- **[Eurostat – Baixo rendemento en PISA](https://ec.europa.eu/eurostat/databrowser/view/educ_outc_pisa/default/table)** (educ_outc_pisa), con datos da OCDE.
- Deflactor: IPC medio anual do INE. Poboación: INE e Eurostat.

<LastRefreshed prefix="Datos actualizados" />
