---
title: Education
description: "Early school leaving, adult educational attainment, young people neither in employment nor in education, education spending per inhabitant and per pupil, enrolment by level and PISA, comparing Spain with the EU and by region."
i18n_origen: 724dbfd150f1
---

<script>
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

# 🎓 Education

How many young people leave education too early, what qualifications adults hold, how many young people are neither working nor studying, how much is spent on education, how many pupils there are at each stage and how they perform in PISA, always compared with the European Union average.

<Grid cols=4>
    <KpiCard
        title="Early school leaving"
        value={resumen.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="of 18 to 24-year-olds in {resumen.find(d => d.indicador === 'abandono')?.anio} · EU: {formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'abandono')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs previous year"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={abandono_es}
    />
    <KpiCard
        title="Adults with tertiary education"
        value={resumen.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="aged 25 to 64 in {resumen.find(d => d.indicador === 'superior_25_64')?.anio} · EU: {formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'superior_25_64')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs previous year"
        direction="positive-up"
        source="Eurostat / EPA"
        sparklineData={superior_es}
    />
    <KpiCard
        title="Neither in work nor in education"
        value={resumen.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="of 15 to 29-year-olds in {resumen.find(d => d.indicador === 'neet_15_29')?.anio} · EU: {formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'neet_15_29')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs previous year"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={neet_es}
    />
    <KpiCard
        title="Public spending on education"
        value={gasto_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(gasto_es.slice(-1)[0]?.valor, 0)} € per inhabitant"
        period="in {gasto_es.slice(-1)[0]?.anio}, {gasto_es.slice(-1)[0]?.anio_base} euros · {formatNumber(gasto_es.slice(-1)[0]?.pct_pib, 1)} % of GDP (EU: {formatNumber(gasto_es.slice(-1)[0]?.pct_pib_ue, 1)} %) · {formatCompact(gasto_es.slice(-1)[0]?.millones_eur * 1e6, 3)} € in total"
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


<p class="text-xs text-gray-500">The indicators for young people and adults are percentages of each age group (Spanish Labour Force Survey, EPA, harmonised by Eurostat). Spending is shown per inhabitant or per pupil and in constant euros, adjusted for inflation with the CPI; totals are given for reference only.</p>

## Early school leaving

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

This is the percentage of 18 to 24-year-olds who have completed at most lower secondary education (ESO) and are no longer in education or training. In {abandono_hitos[0]?.anio_ini} it stood at {formatNumber(abandono_hitos[0]?.valor_ini, 1)} % and in {abandono_hitos[0]?.anio_ult} it was {formatNumber(abandono_hitos[0]?.valor_ult, 1)} %{#if resumen.find(d => d.indicador === 'abandono')?.valor > resumen.find(d => d.indicador === 'abandono')?.valor_ue}, still above the European average{:else}, now below the European average{/if}. The EU target for 2030 is to bring it below 9 %.

<LineChart
    data={abandono_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Early leavers from education and training (% of 18-24-year-olds)"
/>

```sql abandono_ccaa
SELECT i.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS abandono
FROM mother.educacion_indicadores i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
WHERE i.nivel = 'ccaa' AND i.indicador = 'abandono'
QUALIFY row_number() OVER (PARTITION BY i.cod ORDER BY i.anio DESC) = 1
ORDER BY abandono DESC
```

<AreaMap
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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Eurostat"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'abandono', title: 'Early school leaving', fmt: 'pct1'},
        {id: 'anio', title: 'Year', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Latest year available for each region ({abandono_ccaa[0]?.anio}). Regional figures come from a smaller sample and fluctuate from year to year; those for Ceuta and Melilla are particularly unstable.</p>

## What qualifications adults hold

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

Spain has a highly polarised distribution: in {nivel_hitos[0]?.anio_ult}, {formatNumber(nivel_hitos[0]?.basica_es, 1)} % of adults aged 25 to 64 had gone no further than lower secondary (ESO) (EU: {formatNumber(nivel_hitos[0]?.basica_ue, 1)} %) and only {formatNumber(nivel_hitos[0]?.segunda_es, 1)} % had upper secondary (Bachillerato or intermediate vocational training) as their highest level (EU: {formatNumber(nivel_hitos[0]?.segunda_ue, 1)} %){#if resumen.find(d => d.indicador === 'superior_25_64')?.valor > resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue}, but the share with tertiary education is above the European average{/if}. In {nivel_hitos[0]?.anio_ini}, those with no more than lower secondary made up {formatNumber(nivel_hitos[0]?.basica_es_ini, 1)} %.

<BarChart
    data={nivel_ult}
    x=zona
    y=valor
    series=estudios
    type=stacked100
    swapXY=true
    yFmt=pct0
    colorPalette={['#fca5a5', '#fcd34d', '#2563eb']}
    title="Population aged 25 to 64 by highest level of education completed ({nivel_hitos[0]?.anio_ult})"
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
    title="Adults aged 25 to 64 with tertiary education and with lower secondary (ESO) at most"
/>

<p class="text-xs text-gray-500">Tertiary education: higher vocational training, bachelor's degrees, master's degrees and doctorates (levels 5 to 8 of the International Standard Classification of Education, ISCED 2011). Eurostat changed classification in 2014, which may cause small breaks in the series.</p>

## Young people neither in work nor in education

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

These are young people aged 15 to 29 who are neither in employment nor in education or training (NEET). They peaked at {formatNumber(neet_hitos[0]?.valor_max, 1)} % in {neet_hitos[0]?.anio_max} and in {neet_hitos[0]?.anio_ult} stood at {formatNumber(neet_hitos[0]?.valor_ult, 1)} %.

<LineChart
    data={neet_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#94a3b8']}
    title="Young people aged 15 to 29 neither in work nor in education (%)"
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
    title="Young people aged 15 to 29 neither in work nor in education, by region ({neet_ccaa[0]?.anio})"
/>

## How much is spent on education

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

In {gasto_hitos[0]?.anio_ult}, all levels of government (central, regional and local) spent {formatNumber(gasto_hitos[0]?.valor_ult, 0)} € per inhabitant on education, in {gasto_hitos[0]?.anio_base} euros. In 2009 the figure was {formatNumber(gasto_hitos[0]?.v2009, 0)} €, and it then fell to {formatNumber(gasto_hitos[0]?.v_min_crisis, 0)} € in {gasto_hitos[0]?.anio_min_crisis}{#if gasto_hitos[0]?.valor_ult < gasto_hitos[0]?.v2009}: after adjusting for inflation, it has still not returned to its 2009 level{/if}. {#if gasto_es.slice(-1)[0]?.pct_pib < gasto_es.slice(-1)[0]?.pct_pib_ue}Relative to the size of its economy, Spain spends less than the EU average.{:else}Relative to the size of its economy, Spain spends as much as the EU average or more.{/if}

<Grid cols=2>
    <LineChart
        data={gasto_es}
        x=anio
        y=valor
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#0f766e']}
        title="Public spending on education per inhabitant ({gasto_hitos[0]?.anio_base} euros)"
    />
    <LineChart
        data={gasto_pib}
        x=anio
        y=pct_pib
        series=zona
        yFmt=pct1
        xFmt="####"
        colorPalette={['#0f766e', '#94a3b8']}
        title="Public spending on education as % of GDP"
    />
</Grid>

<p class="text-xs text-gray-500">Eurostat's classification of government expenditure by function (COFOG, function 09 Education), with data from the IGAE (Spain's General Comptroller of the State Administration). It includes spending by all levels of government on public schools, publicly funded private schools, grants and universities. Adjusted for inflation with the INE's annual average CPI.</p>

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

Spending on educational institutions (public and private) came to {formatNumber(alumno_hitos[0]?.real_ult, 0)} € per pupil in {alumno_hitos[0]?.anio_ult}, in {alumno_hitos[0]?.anio_base} euros, compared with {formatNumber(alumno_hitos[0]?.real_ini, 0)} € in {alumno_hitos[0]?.anio_ini}. For comparison with Europe, the second chart uses euros adjusted for each country's price level (purchasing power standard).

<Grid cols=2>
    <LineChart
        data={alumno_es}
        x=anio
        y=eur_real
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#7c3aed']}
        title="Spending per pupil, from pre-primary to university ({alumno_hitos[0]?.anio_base} euros)"
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
        title="Spending per pupil by stage, in purchasing power ({alumno_niveles[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Annual spending on educational institutions per full-time equivalent pupil, from all sources of funding (UNESCO-OECD-Eurostat). Pre-primary refers to the second cycle (ages 3 to 5). Figures in purchasing power standards (PPS) are not adjusted for inflation and are only meant for comparing countries in the same year.</p>

## Pupils at each stage

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

In the {matric_total[0]?.curso} school year there were {formatNumber(matric_total[0]?.por_1000, 0)} pupils per 1,000 inhabitants, from pre-primary to university ({formatCompact(matric_total[0]?.alumnos, 3)} in total).

<BarChart
    data={matric}
    x=curso
    y=por_1000_hab
    series=nivel
    type=stacked
    sort=false
    yFmt=num0
    colorPalette={['#fcd34d', '#fb923c', '#f87171', '#60a5fa', '#34d399', '#059669', '#6366f1']}
    title="Enrolled pupils per 1,000 inhabitants, by stage"
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
    title="Pupils by type of school ownership, {matric_ult[0]?.curso} school year"
/>

<p class="text-xs text-gray-500">Concertada: private schools funded mainly from public money (Eurostat's “government-dependent private” institutions). Pre-primary includes the first cycle (ages 0 to 2). Intermediate and basic vocational training (FP de grado medio y básica): vocational programmes at upper secondary level. The university block also includes other higher education (arts, sports). The year shown is the one in which the school year ends.</p>

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

In the {fp_hitos[0]?.curso_ult} school year, {formatNumber(fp_hitos[0]?.es_ult / 0.01, 1)} % of upper secondary pupils were in vocational training (FP), compared with {formatNumber(fp_hitos[0]?.es_ini / 0.01, 1)} % in {fp_hitos[0]?.curso_ini}; in the EU, {formatNumber(fp_hitos[0]?.ue_ult / 0.01, 1)} %.{#if fp_hitos[0]?.es_ult > fp_hitos[0]?.es_ini} Vocational training is gaining ground.{/if}

<LineChart
    data={fp}
    x=curso
    y=pct_fp
    series=zona
    yFmt=pct0
    colorPalette={['#059669', '#94a3b8']}
    title="Vocational training pupils as % of upper secondary (Bachillerato + vocational)"
/>

## PISA: low-achieving 15-year-olds

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

The OECD's PISA survey assesses 15-year-old pupils every three years. This section shows the share who do not reach the baseline level of proficiency (level 2). In {pisa_hitos[0]?.anio_ult}, in Spain this was {formatNumber(pisa_hitos[0]?.mat_es / 0.01, 1)} % in mathematics (EU: {formatNumber(pisa_hitos[0]?.mat_ue / 0.01, 1)} %), {formatNumber(pisa_hitos[0]?.lec_es / 0.01, 1)} % in reading (EU: {formatNumber(pisa_hitos[0]?.lec_ue / 0.01, 1)} %) and {formatNumber(pisa_hitos[0]?.cie_es / 0.01, 1)} % in science (EU: {formatNumber(pisa_hitos[0]?.cie_ue / 0.01, 1)} %).

<BarChart
    data={pisa_ult}
    x=materia
    y=valor
    series=zona
    type=grouped
    yFmt=pct0
    colorPalette={['#db2777', '#94a3b8']}
    title="15-year-old pupils below baseline proficiency in PISA {pisa_ult[0]?.anio}"
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
    title="Spain: 15-year-old pupils below baseline proficiency, by PISA round"
/>

<p class="text-xs text-gray-500">The round planned for 2021 took place in 2022 because of the pandemic. The OECD did not publish Spain's reading result for 2018 owing to anomalies in the responses of some pupils. Eurostat publishes the percentage of low-achieving pupils, not the mean score.</p>

---

## Sources and notes

- **[Eurostat – Early leavers from education and training](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_14/default/table)** (edat_lfse_14 and, by region, edat_lfse_16), based on the INE's Labour Force Survey (EPA).
- **[Eurostat – Population by educational attainment level](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03/default/table)** (edat_lfse_03 and, by region, edat_lfse_04).
- **[Eurostat – Young people neither in employment nor in education and training (NEET)](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_20/default/table)** (edat_lfse_20 and, by region, edat_lfse_22).
- **[Eurostat – General government expenditure by function (COFOG)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table)** (gov_10a_exp, function 09 Education).
- **[Eurostat – Expenditure on educational institutions per pupil](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_fini04/default/table)** (educ_uoe_fini04).
- **[Eurostat – Pupils and students enrolled](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_enra01/default/table)** (educ_uoe_enra01 and educ_uoe_enrs04).
- **[Eurostat – Low achievement in PISA](https://ec.europa.eu/eurostat/databrowser/view/educ_outc_pisa/default/table)** (educ_outc_pisa), with OECD data.
- Deflator: INE annual average CPI. Population: INE and Eurostat.

<LastRefreshed prefix="Data updated" />
