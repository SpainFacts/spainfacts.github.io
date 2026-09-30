---
title: Unemployment and employment
description: "Unemployment rate in Spain by sex, age, nationality, education and territory, youth and long-term unemployment, temporary employment, monthly registered unemployment and comparison with the EU."
i18n_origen: 610c3b85d67c
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql epa
SELECT *
FROM mother.mercado_paro_trimestral
ORDER BY trimestre
```

```sql epa_ult
SELECT
    u.*,
    a.tasa_paro AS tasa_paro_hace1,
    a.tasa_paro_menor25 AS menor25_hace1,
    a.tasa_empleo AS tasa_empleo_hace1,
    a.tasa_temporalidad AS temporalidad_hace1,
    u.tasa_paro - a.tasa_paro AS dif_paro,
    u.tasa_paro_menor25 - a.tasa_paro_menor25 AS dif_menor25,
    u.tasa_empleo - a.tasa_empleo AS dif_empleo,
    u.tasa_temporalidad - a.tasa_temporalidad AS dif_temporalidad,
    u.tasa_paro_larga - a.tasa_paro_larga AS dif_larga,
    u.pct_hogares_todos_parados - a.pct_hogares_todos_parados AS dif_hogares,
    u.pct_parcial_involuntario - a.pct_parcial_involuntario AS dif_parcial
FROM mother.mercado_paro_trimestral u
LEFT JOIN mother.mercado_paro_trimestral a ON a.trimestre = u.trimestre - INTERVAL 1 YEAR
WHERE u.trimestre = (SELECT max(trimestre) FROM mother.mercado_paro_trimestral)
```

```sql hitos
SELECT
    max(tasa_paro) AS paro_max,
    arg_max(periodo, tasa_paro) AS periodo_max,
    min(tasa_paro) AS paro_min,
    arg_min(periodo, tasa_paro) AS periodo_min,
    max(tasa_paro_menor25) AS menor25_max,
    arg_max(periodo, tasa_paro_menor25) AS periodo_menor25_max,
    arg_max(periodo, trimestre) FILTER (WHERE trimestre < (SELECT max(trimestre) FROM mother.mercado_paro_trimestral)
        AND tasa_paro <= (SELECT tasa_paro FROM mother.mercado_paro_trimestral ORDER BY trimestre DESC LIMIT 1)) AS ultimo_periodo_igual,
    max(tasa_temporalidad) AS temporalidad_max,
    arg_max(periodo, tasa_temporalidad) AS periodo_temporalidad_max,
    avg(tasa_temporalidad) FILTER (WHERE anio = 2021) AS temporalidad_2021
FROM mother.mercado_paro_trimestral
```

```sql tasas_largo
SELECT trimestre, 'Tasa de paro' AS indicador, tasa_paro AS tasa FROM mother.mercado_paro_trimestral
UNION ALL
SELECT trimestre, 'Tasa de empleo' AS indicador, tasa_empleo AS tasa FROM mother.mercado_paro_trimestral
UNION ALL
SELECT trimestre, 'Tasa de actividad' AS indicador, tasa_actividad AS tasa FROM mother.mercado_paro_trimestral
ORDER BY trimestre, indicador
```

```sql grupos_sexo
SELECT trimestre, grupo, tasa_paro FROM mother.mercado_paro_grupos WHERE dimension = 'Sexo' ORDER BY trimestre, orden
```

```sql grupos_edad
SELECT trimestre, grupo, tasa_paro FROM mother.mercado_paro_grupos
WHERE dimension = 'Edad' AND grupo <> 'Menores de 25 años'
ORDER BY trimestre, orden
```

```sql grupos_nac
SELECT trimestre, grupo, tasa_paro FROM mother.mercado_paro_grupos
WHERE dimension = 'Nacionalidad' AND grupo <> 'Extranjera (total)'
ORDER BY trimestre, orden
```

```sql grupos_ult
SELECT
    max(tasa_paro) FILTER (WHERE grupo = 'Hombres') AS hombres,
    max(tasa_paro) FILTER (WHERE grupo = 'Mujeres') AS mujeres,
    max(tasa_paro) FILTER (WHERE grupo = '16 a 19 años') AS e16_19,
    max(tasa_paro) FILTER (WHERE grupo = '25 a 54 años') AS e25_54,
    max(tasa_paro) FILTER (WHERE grupo = 'Española') AS espanola,
    max(tasa_paro) FILTER (WHERE grupo = 'Extranjera de fuera de la UE') AS no_ue,
    max(tasa_paro) FILTER (WHERE grupo = 'Extranjera de la UE') AS ue
FROM mother.mercado_paro_grupos
WHERE trimestre = (SELECT max(trimestre) FROM mother.mercado_paro_grupos)
```

```sql formacion
SELECT anio, nivel_corto, orden, tasa_paro
FROM mother.mercado_paro_formacion
WHERE sexo = 'Ambos sexos' AND orden > 0
ORDER BY anio, orden
```

```sql formacion_ult
SELECT * FROM ${formacion} WHERE anio = (SELECT max(anio) FROM ${formacion}) ORDER BY orden
```

```sql formacion_evol
SELECT anio, nivel_corto, tasa_paro FROM ${formacion}
WHERE nivel_corto IN ('Primaria', 'ESO o similar', 'Bachillerato', 'FP de grado medio', 'Estudios superiores')
ORDER BY anio, orden
```

```sql larga
SELECT trimestre, 'Parados de un año o más (% de los activos)' AS serie, tasa_paro_larga AS valor FROM mother.mercado_paro_trimestral
UNION ALL
SELECT trimestre, 'Hogares con todos sus activos en paro (%)' AS serie, pct_hogares_todos_parados AS valor FROM mother.mercado_paro_trimestral
ORDER BY trimestre, serie
```

```sql calidad
SELECT trimestre, 'Asalariados con contrato temporal' AS serie, tasa_temporalidad AS valor FROM mother.mercado_paro_trimestral
UNION ALL
SELECT trimestre, 'Parciales que querrían jornada completa' AS serie, pct_parcial_involuntario AS valor FROM mother.mercado_paro_trimestral WHERE pct_parcial_involuntario IS NOT NULL
ORDER BY trimestre, serie
```

```sql ccaa
SELECT
    p.cod AS cod_ccaa,
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    p.media_4t_tasa_paro / 100 AS tasa_paro,
    p.tasa_paro / 100 AS tasa_paro_trim,
    p.media_4t_tasa_paro_menor25 / 100 AS tasa_paro_menor25,
    p.tasa_paro_extranjeros / 100 AS tasa_paro_extranjeros,
    p.media_4t_hogares_todos_parados / 100 AS hogares_todos_parados,
    p.tasa_paro_dif_anual AS dif_anual
FROM mother.mercado_paro_territorios p
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod
WHERE p.nivel = 'ccaa' AND p.trimestre = (SELECT max(trimestre) FROM mother.mercado_paro_territorios)
ORDER BY tasa_paro DESC
```

```sql provincias
SELECT
    p.cod AS cod_prov,
    t.nombre AS provincia,
    '/en' || t.ruta AS ruta,
    p.media_4t_tasa_paro / 100 AS tasa_paro,
    p.media_4t_tasa_empleo / 100 AS tasa_empleo,
    r.por_100_16_64 AS registrado_100,
    r.paro_registrado
FROM mother.mercado_paro_territorios p
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod
LEFT JOIN mother.mercado_paro_registrado r ON r.nivel = 'provincia' AND r.cod = p.cod
    AND r.mes = (SELECT max(mes) FROM mother.mercado_paro_registrado)
WHERE p.nivel = 'provincia' AND p.trimestre = (SELECT max(trimestre) FROM mother.mercado_paro_territorios)
ORDER BY tasa_paro DESC
```

```sql terr_resumen
SELECT
    (SELECT comunidad FROM ${ccaa} ORDER BY tasa_paro DESC LIMIT 1) AS ccaa_max,
    (SELECT tasa_paro FROM ${ccaa} ORDER BY tasa_paro DESC LIMIT 1) AS ccaa_max_tasa,
    (SELECT comunidad FROM ${ccaa} ORDER BY tasa_paro ASC LIMIT 1) AS ccaa_min,
    (SELECT tasa_paro FROM ${ccaa} ORDER BY tasa_paro ASC LIMIT 1) AS ccaa_min_tasa,
    (SELECT provincia FROM ${provincias} ORDER BY tasa_paro DESC LIMIT 1) AS prov_max,
    (SELECT tasa_paro FROM ${provincias} ORDER BY tasa_paro DESC LIMIT 1) AS prov_max_tasa,
    (SELECT provincia FROM ${provincias} ORDER BY tasa_paro ASC LIMIT 1) AS prov_min,
    (SELECT tasa_paro FROM ${provincias} ORDER BY tasa_paro ASC LIMIT 1) AS prov_min_tasa
```

```sql registrado
SELECT mes, strftime(mes, '%Y-%m') AS mes_txt, paro_registrado, por_100_16_64, variacion_mensual, variacion_anual, variacion_anual_pct, paro_menor25
FROM mother.mercado_paro_registrado
WHERE nivel = 'pais'
ORDER BY mes
```

```sql municipios
SELECT
    m.municipio,
    p.nombre AS provincia,
    m.poblacion,
    m.paro_registrado,
    m.por_100_hab / 100 AS por_100_hab,
    m.variacion_anual_pct / 100 AS variacion_anual
FROM mother.mercado_paro_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.poblacion >= 20000 AND m.paro_registrado IS NOT NULL
ORDER BY por_100_hab DESC
```

```sql ue
SELECT mes, pais, tasa_paro, tasa_paro_menor25
FROM mother.mercado_paro_ue
WHERE mes >= DATE '2000-01-01'
ORDER BY mes, pais
```

```sql ue_ult
SELECT
    pais,
    tasa_paro,
    tasa_paro_menor25,
    strftime(mes, '%m/%Y') AS mes_txt
FROM mother.mercado_paro_ue
WHERE mes = (SELECT max(mes) FROM mother.mercado_paro_ue WHERE geo = 'ES')
ORDER BY tasa_paro DESC
```

```sql ue_resumen
SELECT
    max(tasa_paro) FILTER (WHERE pais = 'España') AS es,
    max(tasa_paro) FILTER (WHERE pais = 'UE-27') AS ue,
    max(tasa_paro_menor25) FILTER (WHERE pais = 'España') AS es_joven,
    max(tasa_paro_menor25) FILTER (WHERE pais = 'UE-27') AS ue_joven,
    max(tasa_paro) FILTER (WHERE pais = 'España') / max(tasa_paro) FILTER (WHERE pais = 'UE-27') AS ratio,
    max(mes_txt) AS mes_txt
FROM ${ue_ult}
```

# 📉 Unemployment and employment

How many people are looking for work and cannot find it, who is hit hardest, where and for how long. Almost all the figures come from the INE's **Labour Force Survey (EPA)**, which is published every quarter and measures unemployment using international criteria: the **unemployment rate** is the percentage of the labour force (people who are working or looking for work) who do not have a job. The latest figure is for **{epa_ult[0]?.periodo}**. The quarterly data are not seasonally adjusted, so each quarter is compared with the same quarter of the previous year.

<Grid cols=4>
    <KpiCard
        title="Unemployment rate"
        value={epa_ult[0]?.tasa_paro}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro, 1)}%"
        period="{epa_ult[0]?.periodo} · {formatNumber(epa_ult[0]?.parados / 1000000, 2)} million unemployed"
        change={epa_ult[0]?.dif_paro?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro)}
    />
    <KpiCard
        title="Youth unemployment (under 25)"
        value={epa_ult[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_menor25, 1)}%"
        period="of the labour force aged 16 to 24, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_menor25?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Employment rate"
        value={epa_ult[0]?.tasa_empleo}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_empleo, 1)}%"
        period="of the population aged 16 and over is in work, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_empleo?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-up"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_empleo)}
    />
    <KpiCard
        title="Registered unemployment"
        value={registrado.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(registrado.slice(-1)[0]?.por_100_16_64, 1)} per 100"
        period="inhabitants aged 16 to 64, {registrado.slice(-1)[0]?.mes_txt} · {formatNumber(registrado.slice(-1)[0]?.paro_registrado / 1000000, 2)} million"
        change={registrado.slice(-1)[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="registered unemployed vs a year earlier"
        direction="positive-down"
        source="SEPE"
        sparklineData={registrado.slice(-60).map(d => d.por_100_16_64)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('paro', 'paro_juvenil', 'tasa_empleo')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'paro')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'paro_juvenil')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'tasa_empleo')} />


<Grid cols=4>
    <KpiCard
        title="Long-term unemployment"
        value={epa_ult[0]?.tasa_paro_larga}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_larga, 1)}%"
        period="of the labour force has been looking for work for a year or more ({formatNumber(epa_ult[0]?.pct_parados_larga, 0)}% of the unemployed)"
        change={epa_ult[0]?.dif_larga?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_larga)}
    />
    <KpiCard
        title="Households with everyone unemployed"
        value={epa_ult[0]?.pct_hogares_todos_parados}
        formattedValue="{formatNumber(epa_ult[0]?.pct_hogares_todos_parados, 1)}%"
        period="of households with at least one economically active member have all of them unemployed, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_hogares?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.pct_hogares_todos_parados)}
    />
    <KpiCard
        title="Temporary employment"
        value={epa_ult[0]?.tasa_temporalidad}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_temporalidad, 1)}%"
        period="of employees have a temporary contract, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_temporalidad?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_temporalidad)}
    />
    <KpiCard
        title="Involuntary part-time work"
        value={epa_ult[0]?.pct_parcial_involuntario}
        formattedValue="{formatNumber(epa_ult[0]?.pct_parcial_involuntario, 1)}%"
        period="of part-time workers do so because they cannot find a full-time job"
        change={epa_ult[0]?.dif_parcial?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.filter(d => d.pct_parcial_involuntario != null).map(d => d.pct_parcial_involuntario)}
    />
</Grid>

## Unemployment, employment and activity since 2002

Unemployment peaked in {hitos[0]?.periodo_max}, with {formatNumber(hitos[0]?.paro_max, 1)}% of the labour force out of work; the lowest point in the series was in {hitos[0]?.periodo_min} ({formatNumber(hitos[0]?.paro_min, 1)}%). {#if hitos[0]?.ultimo_periodo_igual}The current {formatNumber(epa_ult[0]?.tasa_paro, 1)}% is the lowest rate since {hitos[0]?.ultimo_periodo_igual}.{:else}The current {formatNumber(epa_ult[0]?.tasa_paro, 1)}% is the lowest rate in the whole series.{/if} The employment rate measures what share of the population aged 16 or over is in work, and the activity rate what share is working or looking for work.

<LineChart
    data={tasas_largo}
    x=trimestre
    y=tasa
    series=indicador
    yFmt='0.0"%"'
    yAxisTitle="% of the population or of the labour force"
    title="Unemployment, employment and activity rates (EPA, quarterly)"
/>

## Who is hit hardest by unemployment?

In {epa_ult[0]?.periodo}, the unemployment rate is {formatNumber(grupos_ult[0]?.mujeres, 1)}% among women and {formatNumber(grupos_ult[0]?.hombres, 1)}% among men; {formatNumber(grupos_ult[0]?.e16_19, 1)}% among 16- to 19-year-olds looking for work compared with {formatNumber(grupos_ult[0]?.e25_54, 1)}% among those aged 25 to 54; and {formatNumber(grupos_ult[0]?.no_ue, 1)}% among non-EU foreign nationals compared with {formatNumber(grupos_ult[0]?.espanola, 1)}% among Spanish nationals.

<LineChart
    data={grupos_sexo}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment rate by sex"
/>

<LineChart
    data={grupos_edad}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment rate by age"
/>

The highest youth unemployment in the series, {formatNumber(hitos[0]?.menor25_max, 1)}% of the labour force under 25, was reached in {hitos[0]?.periodo_menor25_max}. A word of caution: many young people are studying and are not in the labour force, so the rate is calculated only on those who are working or looking for work.

<LineChart
    data={grupos_nac}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment rate by nationality"
/>

### By level of education

The more education, the less unemployment. Annual average for {formacion_ult[0]?.anio}, population aged 16 or over.

<BarChart
    data={formacion_ult}
    x=nivel_corto
    y=tasa_paro
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment rate by highest level of education completed in {formacion_ult[0]?.anio}"
/>

<LineChart
    data={formacion_evol}
    x=anio
    y=tasa_paro
    series=nivel_corto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment by level of education over time (annual average)"
/>

## Long-term unemployment and households with no income from work

A long-term unemployed person has been looking for work for a year or more. Today they make up {formatNumber(epa_ult[0]?.pct_parados_larga, 0)}% of the unemployed, or {formatNumber(epa_ult[0]?.tasa_paro_larga, 1)}% of the whole labour force. The second line is the percentage of households with at least one economically active member in which all active members are unemployed.

<LineChart
    data={larga}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Long-term unemployment and households with all active members unemployed"
/>

## Temporary contracts and unwanted part-time work

Percentage of employees on a temporary contract and percentage of part-time workers who work part time because they have not found a full-time job. Temporary employment peaked in {hitos[0]?.periodo_temporalidad_max} ({formatNumber(hitos[0]?.temporalidad_max, 1)}%); in 2021, the year before the 2022 labour reform came into force, it averaged {formatNumber(hitos[0]?.temporalidad_2021, 1)}%, and today it stands at {formatNumber(epa_ult[0]?.tasa_temporalidad, 1)}%. Intermittent permanent contracts (fijos discontinuos) count as permanent in the EPA.

<LineChart
    data={calidad}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Temporary employment and involuntary part-time work"
/>

## By region and province

Average of the last four quarters, to smooth out sampling noise in the EPA for small territories. The region with the highest unemployment is {terr_resumen[0]?.ccaa_max} ({formatNumber(terr_resumen[0]?.ccaa_max_tasa / 0.01, 1)}%) and the one with the lowest {terr_resumen[0]?.ccaa_min} ({formatNumber(terr_resumen[0]?.ccaa_min_tasa / 0.01, 1)}%). By province, the range runs from {terr_resumen[0]?.prov_min} ({formatNumber(terr_resumen[0]?.prov_min_tasa / 0.01, 1)}%) to {terr_resumen[0]?.prov_max} ({formatNumber(terr_resumen[0]?.prov_max_tasa / 0.01, 1)}%). Click on a territory to see its profile.

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="tasa_paro"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fef3c7', '#f97316', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE (EPA)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: 'Unemployment rate (4-quarter avg.)', fmt: 'pct1'},
        {id: 'tasa_paro_menor25', title: 'Under 25', fmt: 'pct1'},
        {id: 'hogares_todos_parados', title: 'Households with everyone unemployed', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=tasa_paro title="Unemployment rate" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_paro_trim title="Latest quarter" fmt=pct1 />
    <Column id=dif_anual title="Annual change (pp)" fmt=num1 contentType=delta downIsGood=true />
    <Column id=tasa_paro_menor25 title="Under 25" fmt=pct1 />
    <Column id=tasa_paro_extranjeros title="Foreign nationals (qtr.)" fmt=pct1 />
    <Column id=hogares_todos_parados title="Households all unemployed" fmt=pct1 />
</DataTable>

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="tasa_paro"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fef3c7', '#f97316', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE (EPA), SEPE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: 'EPA unemployment rate (4-quarter avg.)', fmt: 'pct1'},
        {id: 'tasa_empleo', title: 'Employment rate', fmt: 'pct1'},
        {id: 'registrado_100', title: 'Registered unemployed per 100 inhab. aged 16-64', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} link=ruta rows=10 search=true showLinkCol=false>
    <Column id=provincia title="Province" />
    <Column id=tasa_paro title="EPA unemployment rate" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_empleo title="Employment rate" fmt=pct1 />
    <Column id=registrado_100 title="Registered unemployed per 100 inhab. aged 16-64" fmt=num1 />
    <Column id=paro_registrado title="Registered unemployed" fmt=num0 />
</DataTable>

## The monthly figure: registered unemployment

Every month the SEPE (Public Employment Service) counts the jobseekers registered as unemployed at employment offices. This does not match the EPA (some unemployed people do not register, and some registered people are not counted as unemployed by the EPA), but it is published sooner, every month, and is available down to municipality level. Here, per 100 inhabitants aged 16 to 64. In {registrado.slice(-1)[0]?.mes_txt} there were {formatNumber(registrado.slice(-1)[0]?.paro_registrado, 0)} registered unemployed, {#if registrado.slice(-1)[0]?.variacion_anual < 0}{formatNumber(-registrado.slice(-1)[0]?.variacion_anual, 0)} fewer{:else}{formatNumber(registrado.slice(-1)[0]?.variacion_anual, 0)} more{/if} than a year earlier.

<LineChart
    data={registrado}
    x=mes
    y=por_100_16_64
    yFmt='0.0'
    yAxisTitle="registered unemployed per 100 inhab. aged 16 to 64"
    title="Registered unemployment per 100 inhabitants aged 16 to 64"
/>

### Municipalities with 20,000 or more inhabitants

Registered unemployed in {registrado.slice(-1)[0]?.mes_txt} per 100 inhabitants (total population from the municipal register).

<DataTable data={municipios} rows=10 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=paro_registrado title="Registered unemployed" fmt=num0 />
    <Column id=por_100_hab title="Per 100 inhabitants" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=variacion_anual title="Change over a year" fmt=pct1 contentType=delta downIsGood=true />
</DataTable>

## Spain compared with Europe

Eurostat's seasonally adjusted monthly unemployment rates, comparable across countries. In {ue_resumen[0]?.mes_txt} the Spanish rate is {formatNumber(ue_resumen[0]?.es, 1)}%, {formatNumber(ue_resumen[0]?.ratio, 1)} times the EU average ({formatNumber(ue_resumen[0]?.ue, 1)}%); for under-25s it is {formatNumber(ue_resumen[0]?.es_joven, 1)}% compared with {formatNumber(ue_resumen[0]?.ue_joven, 1)}%.

<LineChart
    data={ue}
    x=mes
    y=tasa_paro
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment rate in the EU (monthly, seasonally adjusted)"
/>

<LineChart
    data={ue}
    x=mes
    y=tasa_paro_menor25
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force under 25"
    title="Youth unemployment (under 25) in the EU"
/>

Wages are covered in [Wages](/en/economia/salarios) and public-sector employment in [Public employment](/en/cuentas-publicas/empleo-publico).

---

**Sources:** INE, Labour Force Survey (EPA): [unemployment rates by sex and age (65219)](https://www.ine.es/jaxiT3/Tabla.htm?t=65219), [activity, unemployment and employment rates by province (65349)](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [unemployment by age and autonomous community (65334)](https://www.ine.es/jaxiT3/Tabla.htm?t=65334), [unemployment by nationality (65336)](https://www.ine.es/jaxiT3/Tabla.htm?t=65336), [unemployment by level of education (66000)](https://www.ine.es/jaxiT3/Tabla.htm?t=66000), [unemployed by duration of job search (65236)](https://www.ine.es/jaxiT3/Tabla.htm?t=65236), [unemployment in households (65276)](https://www.ine.es/jaxiT3/Tabla.htm?t=65276), [employees by type of contract (65194)](https://www.ine.es/jaxiT3/Tabla.htm?t=65194) and [part-time workers by reason (65152)](https://www.ine.es/jaxiT3/Tabla.htm?t=65152). [SEPE, registered unemployment by municipality (open data, annual CSV)](https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv); population aged 16 to 64 from the INE's Continuous Population Statistics. [Eurostat, une_rt_m](https://ec.europa.eu/eurostat/databrowser/view/une_rt_m/default/table). The long-term unemployment rate is calculated as the unemployment rate times the percentage of the unemployed who have been looking for work for a year or more.
