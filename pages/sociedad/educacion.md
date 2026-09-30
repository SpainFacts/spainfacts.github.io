---
title: Educación
description: "Abandono escolar temprano, nivel educativo de los adultos, jóvenes que ni estudian ni trabajan, gasto en educación por habitante y por alumno, alumnado por nivel y PISA, con España frente a la UE y por comunidad."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

Cuántos jóvenes dejan de estudiar demasiado pronto, qué formación tienen los adultos, cuántos jóvenes ni estudian ni trabajan, cuánto se gasta en educación, cuántos alumnos hay en cada etapa y qué resultados sacan en PISA, siempre frente a la media de la Unión Europea.

<Grid cols=4>
    <KpiCard
        title="Abandono escolar temprano"
        value={resumen.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="de los jóvenes de 18 a 24 años en {resumen.find(d => d.indicador === 'abandono')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'abandono')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'abandono')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs año anterior"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={abandono_es}
    />
    <KpiCard
        title="Adultos con estudios superiores"
        value={resumen.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="de 25 a 64 años en {resumen.find(d => d.indicador === 'superior_25_64')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'superior_25_64')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs año anterior"
        direction="positive-up"
        source="Eurostat / EPA"
        sparklineData={superior_es}
    />
    <KpiCard
        title="Ni estudian ni trabajan"
        value={resumen.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="de los jóvenes de 15 a 29 años en {resumen.find(d => d.indicador === 'neet_15_29')?.anio} · UE: {formatNumber(resumen.find(d => d.indicador === 'neet_15_29')?.valor_ue, 1)} %"
        change={resumen.find(d => d.indicador === 'neet_15_29')?.cambio?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs año anterior"
        direction="positive-down"
        source="Eurostat / EPA"
        sparklineData={neet_es}
    />
    <KpiCard
        title="Gasto público en educación"
        value={gasto_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(gasto_es.slice(-1)[0]?.valor, 0)} € por habitante"
        period="en {gasto_es.slice(-1)[0]?.anio}, euros de {gasto_es.slice(-1)[0]?.anio_base} · {formatNumber(gasto_es.slice(-1)[0]?.pct_pib, 1)} % del PIB (UE: {formatNumber(gasto_es.slice(-1)[0]?.pct_pib_ue, 1)} %) · {formatCompact(gasto_es.slice(-1)[0]?.millones_eur * 1e6, 3)} € en total"
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


<p class="text-xs text-gray-500">Los indicadores de jóvenes y adultos son porcentajes de cada grupo de edad (EPA armonizada por Eurostat). El gasto se da por habitante o por alumno y en euros constantes, descontada la inflación con el IPC; los totales, solo como referencia.</p>

## Abandono escolar temprano

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

Es el porcentaje de jóvenes de 18 a 24 años que, como mucho, han terminado la ESO y no siguen estudiando ni formándose. En {abandono_hitos[0]?.anio_ini} era el {formatNumber(abandono_hitos[0]?.valor_ini, 1)} % y en {abandono_hitos[0]?.anio_ult} fue del {formatNumber(abandono_hitos[0]?.valor_ult, 1)} %{#if resumen.find(d => d.indicador === 'abandono')?.valor > resumen.find(d => d.indicador === 'abandono')?.valor_ue}, aún por encima de la media europea{:else}, ya por debajo de la media europea{/if}. El objetivo de la UE para 2030 es bajar del 9 %.

<LineChart
    data={abandono_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Abandono temprano de la educación y la formación (% de 18-24 años)"
/>

```sql abandono_ccaa
SELECT i.cod, t.nombre AS comunidad, t.ruta, CAST(i.anio AS INTEGER) AS anio, i.valor / 100 AS abandono
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Eurostat"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'abandono', title: 'Abandono temprano', fmt: 'pct1'},
        {id: 'anio', title: 'Año', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Último año disponible de cada comunidad ({abandono_ccaa[0]?.anio}). Las cifras regionales salen de una muestra más pequeña y oscilan de un año a otro; las de Ceuta y Melilla son especialmente inestables.</p>

## Qué estudios tienen los adultos

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

España tiene un reparto muy polarizado: en {nivel_hitos[0]?.anio_ult}, el {formatNumber(nivel_hitos[0]?.basica_es, 1)} % de los adultos de 25 a 64 años no pasó de la ESO (UE: {formatNumber(nivel_hitos[0]?.basica_ue, 1)} %) y solo el {formatNumber(nivel_hitos[0]?.segunda_es, 1)} % tiene como máximo bachillerato o FP de grado medio (UE: {formatNumber(nivel_hitos[0]?.segunda_ue, 1)} %){#if resumen.find(d => d.indicador === 'superior_25_64')?.valor > resumen.find(d => d.indicador === 'superior_25_64')?.valor_ue}, pero la proporción con estudios superiores supera la media europea{/if}. En {nivel_hitos[0]?.anio_ini} los que no pasaban de la ESO eran el {formatNumber(nivel_hitos[0]?.basica_es_ini, 1)} %.

<BarChart
    data={nivel_ult}
    x=zona
    y=valor
    series=estudios
    type=stacked100
    swapXY=true
    yFmt=pct0
    colorPalette={['#fca5a5', '#fcd34d', '#2563eb']}
    title="Población de 25 a 64 años por nivel de estudios terminado ({nivel_hitos[0]?.anio_ult})"
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
    title="Adultos de 25 a 64 años con estudios superiores y con, como mucho, la ESO"
/>

<p class="text-xs text-gray-500">Estudios superiores: FP de grado superior, grados universitarios, másteres y doctorados (niveles 5 a 8 de la clasificación internacional CINE 2011). Eurostat cambió de clasificación en 2014, lo que puede causar pequeños saltos en la serie.</p>

## Jóvenes que ni estudian ni trabajan

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

Son los jóvenes de 15 a 29 años que ni tienen empleo ni reciben educación o formación. Llegaron al {formatNumber(neet_hitos[0]?.valor_max, 1)} % en {neet_hitos[0]?.anio_max} y en {neet_hitos[0]?.anio_ult} eran el {formatNumber(neet_hitos[0]?.valor_ult, 1)} %.

<LineChart
    data={neet_graf}
    x=anio
    y=valor
    series=zona
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#94a3b8']}
    title="Jóvenes de 15 a 29 años que ni estudian ni trabajan (%)"
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
    title="Jóvenes de 15 a 29 años que ni estudian ni trabajan, por comunidad ({neet_ccaa[0]?.anio})"
/>

## Cuánto se gasta en educación

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

Todas las administraciones (Estado, comunidades, ayuntamientos) gastaron en {gasto_hitos[0]?.anio_ult} {formatNumber(gasto_hitos[0]?.valor_ult, 0)} € por habitante en educación, en euros de {gasto_hitos[0]?.anio_base}. En 2009 eran {formatNumber(gasto_hitos[0]?.v2009, 0)} € y después bajaron a {formatNumber(gasto_hitos[0]?.v_min_crisis, 0)} € en {gasto_hitos[0]?.anio_min_crisis}{#if gasto_hitos[0]?.valor_ult < gasto_hitos[0]?.v2009}: descontada la inflación, todavía no se ha recuperado el nivel de 2009{/if}. {#if gasto_es.slice(-1)[0]?.pct_pib < gasto_es.slice(-1)[0]?.pct_pib_ue}En proporción al tamaño de su economía, España gasta menos que la media de la UE.{:else}En proporción al tamaño de su economía, España gasta como la media de la UE o más.{/if}

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
        title="Gasto público en educación en % del PIB"
    />
</Grid>

<p class="text-xs text-gray-500">Clasificación funcional del gasto público (COFOG, función 09 Educación) de Eurostat, con datos de la IGAE. Incluye el gasto de todas las administraciones en enseñanza pública, conciertos, becas y universidades. Descontada la inflación con el IPC medio anual del INE.</p>

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

El gasto en centros educativos (público y privado) fue de {formatNumber(alumno_hitos[0]?.real_ult, 0)} € por alumno en {alumno_hitos[0]?.anio_ult}, en euros de {alumno_hitos[0]?.anio_base}, frente a {formatNumber(alumno_hitos[0]?.real_ini, 0)} € en {alumno_hitos[0]?.anio_ini}. Para comparar con Europa, la segunda gráfica usa euros ajustados por el nivel de precios de cada país (estándar de poder de compra).

<Grid cols=2>
    <LineChart
        data={alumno_es}
        x=anio
        y=eur_real
        yFmt='#,##0" €"'
        xFmt="####"
        colorPalette={['#7c3aed']}
        title="Gasto por alumno, de infantil a universidad (euros de {alumno_hitos[0]?.anio_base})"
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

<p class="text-xs text-gray-500">Gasto anual en centros educativos por alumno equivalente a tiempo completo, de todas las fuentes de financiación (UNESCO-OCDE-Eurostat). Infantil se refiere al segundo ciclo (3 a 5 años). Las cifras en poder de compra (PPS) no están descontadas de inflación y solo sirven para comparar países en un mismo año.</p>

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

En el curso {matric_total[0]?.curso} había {formatNumber(matric_total[0]?.por_1000, 0)} alumnos por cada 1.000 habitantes, de infantil a la universidad ({formatCompact(matric_total[0]?.alumnos, 3)} en total).

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
    title="Alumnado por titularidad del centro, curso {matric_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">Concertada: centros privados financiados principalmente con fondos públicos (Eurostat, «privados dependientes del Estado»). Infantil incluye el primer ciclo (0 a 2 años). FP de grado medio y básica: programas profesionales de la segunda etapa de secundaria. El bloque universitario incluye también otras enseñanzas superiores (artísticas, deportivas). El año es el del final del curso.</p>

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

En el curso {fp_hitos[0]?.curso_ult} el {formatNumber(fp_hitos[0]?.es_ult / 0.01, 1)} % de los alumnos de la segunda etapa de secundaria estudiaba FP, frente al {formatNumber(fp_hitos[0]?.es_ini / 0.01, 1)} % en {fp_hitos[0]?.curso_ini}; en la UE, el {formatNumber(fp_hitos[0]?.ue_ult / 0.01, 1)} %.{#if fp_hitos[0]?.es_ult > fp_hitos[0]?.es_ini} La formación profesional gana peso.{/if}

<LineChart
    data={fp}
    x=curso
    y=pct_fp
    series=zona
    yFmt=pct0
    colorPalette={['#059669', '#94a3b8']}
    title="Alumnos de FP en % de la segunda etapa de secundaria (bachillerato + FP)"
/>

## PISA: alumnos de 15 años con bajo rendimiento

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

El informe PISA de la OCDE evalúa cada tres años a alumnos de 15 años. Aquí se muestra qué parte no alcanza el nivel básico de competencia (nivel 2). En {pisa_hitos[0]?.anio_ult}, en España fueron el {formatNumber(pisa_hitos[0]?.mat_es / 0.01, 1)} % en matemáticas (UE: {formatNumber(pisa_hitos[0]?.mat_ue / 0.01, 1)} %), el {formatNumber(pisa_hitos[0]?.lec_es / 0.01, 1)} % en lectura (UE: {formatNumber(pisa_hitos[0]?.lec_ue / 0.01, 1)} %) y el {formatNumber(pisa_hitos[0]?.cie_es / 0.01, 1)} % en ciencias (UE: {formatNumber(pisa_hitos[0]?.cie_ue / 0.01, 1)} %).

<BarChart
    data={pisa_ult}
    x=materia
    y=valor
    series=zona
    type=grouped
    yFmt=pct0
    colorPalette={['#db2777', '#94a3b8']}
    title="Alumnos de 15 años por debajo del nivel básico en PISA {pisa_ult[0]?.anio}"
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
    title="España: alumnos de 15 años por debajo del nivel básico, por edición de PISA"
/>

<p class="text-xs text-gray-500">La edición prevista para 2021 se hizo en 2022 por la pandemia. La OCDE no publicó el resultado de lectura de España en 2018 por anomalías en las respuestas de una parte de los alumnos. Eurostat publica el porcentaje de alumnos con bajo rendimiento, no la puntuación media.</p>

---

## Fuentes y notas

- **[Eurostat – Abandono temprano de la educación y la formación](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_14/default/table)** (edat_lfse_14 y, por región, edat_lfse_16), a partir de la EPA del INE.
- **[Eurostat – Población por nivel educativo](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03/default/table)** (edat_lfse_03 y, por región, edat_lfse_04).
- **[Eurostat – Jóvenes que ni trabajan ni estudian (NEET)](https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_20/default/table)** (edat_lfse_20 y, por región, edat_lfse_22).
- **[Eurostat – Gasto de las AAPP por función (COFOG)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table)** (gov_10a_exp, función 09 Educación).
- **[Eurostat – Gasto en centros educativos por alumno](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_fini04/default/table)** (educ_uoe_fini04).
- **[Eurostat – Alumnado matriculado](https://ec.europa.eu/eurostat/databrowser/view/educ_uoe_enra01/default/table)** (educ_uoe_enra01 y educ_uoe_enrs04).
- **[Eurostat – Bajo rendimiento en PISA](https://ec.europa.eu/eurostat/databrowser/view/educ_outc_pisa/default/table)** (educ_outc_pisa), con datos de la OCDE.
- Deflactor: IPC medio anual del INE. Población: INE y Eurostat.

<LastRefreshed prefix="Datos actualizados" />
