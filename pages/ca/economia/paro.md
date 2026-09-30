---
title: Atur i ocupació
description: "Taxa d'atur a Espanya per sexe, edat, nacionalitat, estudis i territori, atur juvenil i de llarga durada, temporalitat, atur registrat mensual i comparació amb la UE."
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
    '/ca' || t.ruta AS ruta,
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
    '/ca' || t.ruta AS ruta,
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

# 📉 Atur i ocupació

Quanta gent busca feina i no en troba, a qui afecta més, on i quant de temps dura. Gairebé totes les xifres són de l'**Enquesta de Població Activa (EPA)** de l'INE, que es publica cada trimestre i mesura l'atur amb els criteris internacionals: la **taxa d'atur** és el percentatge de la població activa (els qui treballen o busquen feina) que no té feina. La dada més recent és del **{epa_ult[0]?.periodo}**. Les dades trimestrals no estan desestacionalitzades, de manera que cada trimestre es compara amb el mateix de l'any anterior.

<Grid cols=4>
    <KpiCard
        title="Taxa d'atur"
        value={epa_ult[0]?.tasa_paro}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro, 1)} %"
        period="{epa_ult[0]?.periodo} · {formatNumber(epa_ult[0]?.parados / 1000000, 2)} milions d'aturats"
        change={epa_ult[0]?.dif_paro?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro)}
    />
    <KpiCard
        title="Atur juvenil (menors de 25)"
        value={epa_ult[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_menor25, 1)} %"
        period="dels actius de 16 a 24 anys, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_menor25?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Taxa d'ocupació"
        value={epa_ult[0]?.tasa_empleo}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_empleo, 1)} %"
        period="de la població de 16 anys i més treballa, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_empleo?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-up"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_empleo)}
    />
    <KpiCard
        title="Atur registrat"
        value={registrado.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(registrado.slice(-1)[0]?.por_100_16_64, 1)} per 100"
        period="habitants de 16 a 64 anys, {registrado.slice(-1)[0]?.mes_txt} · {formatNumber(registrado.slice(-1)[0]?.paro_registrado / 1000000, 2)} milions"
        change={registrado.slice(-1)[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="aturats registrats respecte a un any abans"
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
        title="Atur de llarga durada"
        value={epa_ult[0]?.tasa_paro_larga}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_larga, 1)} %"
        period="dels actius fa un any o més que busca feina ({formatNumber(epa_ult[0]?.pct_parados_larga, 0)} % dels aturats)"
        change={epa_ult[0]?.dif_larga?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_larga)}
    />
    <KpiCard
        title="Llars amb tothom a l'atur"
        value={epa_ult[0]?.pct_hogares_todos_parados}
        formattedValue="{formatNumber(epa_ult[0]?.pct_hogares_todos_parados, 1)} %"
        period="de les llars amb algun actiu tenen tots els actius a l'atur, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_hogares?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.pct_hogares_todos_parados)}
    />
    <KpiCard
        title="Temporalitat"
        value={epa_ult[0]?.tasa_temporalidad}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_temporalidad, 1)} %"
        period="dels assalariats té contracte temporal, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_temporalidad?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_temporalidad)}
    />
    <KpiCard
        title="Parcialitat involuntària"
        value={epa_ult[0]?.pct_parcial_involuntario}
        formattedValue="{formatNumber(epa_ult[0]?.pct_parcial_involuntario, 1)} %"
        period="dels qui treballen a temps parcial ho fan perquè no troben jornada completa"
        change={epa_ult[0]?.dif_parcial?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.filter(d => d.pct_parcial_involuntario != null).map(d => d.pct_parcial_involuntario)}
    />
</Grid>

## Atur, ocupació i activitat des del 2002

L'atur va tocar sostre el {hitos[0]?.periodo_max}, amb un {formatNumber(hitos[0]?.paro_max, 1)} % dels actius sense feina; el mínim de la sèrie és del {hitos[0]?.periodo_min} ({formatNumber(hitos[0]?.paro_min, 1)} %). {#if hitos[0]?.ultimo_periodo_igual}L'actual {formatNumber(epa_ult[0]?.tasa_paro, 1)} % és la taxa més baixa des del {hitos[0]?.ultimo_periodo_igual}.{:else}L'actual {formatNumber(epa_ult[0]?.tasa_paro, 1)} % és la taxa més baixa de tota la sèrie.{/if} La taxa d'ocupació mesura quina part de la població de 16 anys o més treballa, i la d'activitat quina part treballa o busca feina.

<LineChart
    data={tasas_largo}
    x=trimestre
    y=tasa
    series=indicador
    yFmt='0.0"%"'
    yAxisTitle="% de la població o dels actius"
    title="Taxes d'atur, ocupació i activitat (EPA, trimestral)"
/>

## A qui afecta més l'atur?

El {epa_ult[0]?.periodo}, la taxa d'atur és del {formatNumber(grupos_ult[0]?.mujeres, 1)} % entre les dones i del {formatNumber(grupos_ult[0]?.hombres, 1)} % entre els homes; del {formatNumber(grupos_ult[0]?.e16_19, 1)} % entre les persones de 16 a 19 anys que busquen feina davant del {formatNumber(grupos_ult[0]?.e25_54, 1)} % de 25 a 54 anys; i del {formatNumber(grupos_ult[0]?.no_ue, 1)} % entre els estrangers de fora de la UE davant del {formatNumber(grupos_ult[0]?.espanola, 1)} % dels espanyols.

<LineChart
    data={grupos_sexo}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% dels actius"
    title="Taxa d'atur per sexe"
/>

<LineChart
    data={grupos_edad}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% dels actius"
    title="Taxa d'atur per edat"
/>

L'atur juvenil més alt de la sèrie, un {formatNumber(hitos[0]?.menor25_max, 1)} % dels actius menors de 25 anys, es va assolir el {hitos[0]?.periodo_menor25_max}. Compte a l'hora de llegir-lo: entre els joves molts estudien i no són actius, de manera que la taxa es calcula sobre els qui sí que treballen o busquen feina.

<LineChart
    data={grupos_nac}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% dels actius"
    title="Taxa d'atur per nacionalitat"
/>

### Per nivell d'estudis

Com més estudis, menys atur. Mitjana anual del {formacion_ult[0]?.anio}, població de 16 anys o més.

<BarChart
    data={formacion_ult}
    x=nivel_corto
    y=tasa_paro
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% dels actius"
    title="Taxa d'atur per nivell d'estudis acabats el {formacion_ult[0]?.anio}"
/>

<LineChart
    data={formacion_evol}
    x=anio
    y=tasa_paro
    series=nivel_corto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dels actius"
    title="Evolució de l'atur per nivell d'estudis (mitjana anual)"
/>

## Atur de llarga durada i llars sense ingressos del treball

Un aturat de llarga durada fa un any o més que busca feina. Avui són el {formatNumber(epa_ult[0]?.pct_parados_larga, 0)} % dels aturats, un {formatNumber(epa_ult[0]?.tasa_paro_larga, 1)} % de tots els actius. La segona línia és el percentatge de llars amb almenys una persona activa en què totes les persones actives són a l'atur.

<LineChart
    data={larga}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Atur de llarga durada i llars amb tots els actius a l'atur"
/>

## Temporalitat i jornada parcial no desitjada

Percentatge d'assalariats amb contracte temporal i percentatge dels qui treballen a temps parcial perquè no han trobat una feina a jornada completa. La temporalitat va arribar al màxim el {hitos[0]?.periodo_temporalidad_max} ({formatNumber(hitos[0]?.temporalidad_max, 1)} %); el 2021, l'any anterior a l'entrada en vigor de la reforma laboral del 2022, va fer una mitjana del {formatNumber(hitos[0]?.temporalidad_2021, 1)} %, i avui és del {formatNumber(epa_ult[0]?.tasa_temporalidad, 1)} %. Els contractes fixos discontinus compten a l'EPA com a indefinits.

<LineChart
    data={calidad}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Temporalitat i parcialitat involuntària"
/>

## Per comunitat i província

Mitjana dels quatre últims trimestres, per suavitzar el soroll de la mostra de l'EPA als territoris petits. La comunitat amb més atur és {terr_resumen[0]?.ccaa_max} ({formatNumber(terr_resumen[0]?.ccaa_max_tasa / 0.01, 1)} %) i la que menys {terr_resumen[0]?.ccaa_min} ({formatNumber(terr_resumen[0]?.ccaa_min_tasa / 0.01, 1)} %). Per províncies, el rang va de {terr_resumen[0]?.prov_min} ({formatNumber(terr_resumen[0]?.prov_min_tasa / 0.01, 1)} %) a {terr_resumen[0]?.prov_max} ({formatNumber(terr_resumen[0]?.prov_max_tasa / 0.01, 1)} %). Fes clic en un territori per veure'n la fitxa.

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
    attribution="Tessel·les © Esri · Límits © Institut Geogràfic Nacional · Dades: INE (EPA)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: "Taxa d'atur (mitjana 4 trim.)", fmt: 'pct1'},
        {id: 'tasa_paro_menor25', title: 'Menors de 25', fmt: 'pct1'},
        {id: 'hogares_todos_parados', title: "Llars amb tothom a l'atur", fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=tasa_paro title="Taxa d'atur" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_paro_trim title="Últim trimestre" fmt=pct1 />
    <Column id=dif_anual title="Canvi anual (pp)" fmt=num1 contentType=delta downIsGood=true />
    <Column id=tasa_paro_menor25 title="Menors de 25" fmt=pct1 />
    <Column id=tasa_paro_extranjeros title="Estrangers (trim.)" fmt=pct1 />
    <Column id=hogares_todos_parados title="Llars amb tothom a l'atur" fmt=pct1 />
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
    attribution="Tessel·les © Esri · Límits © Institut Geogràfic Nacional · Dades: INE (EPA), SEPE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: "Taxa d'atur EPA (mitjana 4 trim.)", fmt: 'pct1'},
        {id: 'tasa_empleo', title: "Taxa d'ocupació", fmt: 'pct1'},
        {id: 'registrado_100', title: 'Atur registrat per 100 hab. 16-64', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} link=ruta rows=10 search=true showLinkCol=false>
    <Column id=provincia title="Província" />
    <Column id=tasa_paro title="Taxa d'atur EPA" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_empleo title="Taxa d'ocupació" fmt=pct1 />
    <Column id=registrado_100 title="Atur registrat per 100 hab. 16-64" fmt=num1 />
    <Column id=paro_registrado title="Aturats registrats" fmt=num0 />
</DataTable>

## La dada mensual: atur registrat

El SEPE compta cada mes els demandants d'ocupació inscrits com a aturats a les oficines d'ocupació. No coincideix amb l'EPA (hi ha aturats que no s'inscriuen i inscrits que l'EPA no considera aturats), però es publica abans, cada mes, i arriba fins al municipi. Aquí, per cada 100 habitants de 16 a 64 anys. El {registrado.slice(-1)[0]?.mes_txt} hi havia {formatNumber(registrado.slice(-1)[0]?.paro_registrado, 0)} aturats registrats, {#if registrado.slice(-1)[0]?.variacion_anual < 0}{formatNumber(-registrado.slice(-1)[0]?.variacion_anual, 0)} menys{:else}{formatNumber(registrado.slice(-1)[0]?.variacion_anual, 0)} més{/if} que un any abans.

<LineChart
    data={registrado}
    x=mes
    y=por_100_16_64
    yFmt='0.0'
    yAxisTitle="aturats registrats per 100 hab. de 16 a 64"
    title="Atur registrat per cada 100 habitants de 16 a 64 anys"
/>

### Municipis de 20.000 habitants o més

Aturats registrats el {registrado.slice(-1)[0]?.mes_txt} per cada 100 habitants (població total del padró).

<DataTable data={municipios} rows=10 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=paro_registrado title="Aturats registrats" fmt=num0 />
    <Column id=por_100_hab title="Per 100 habitants" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=variacion_anual title="Canvi en un any" fmt=pct1 contentType=delta downIsGood=true />
</DataTable>

## Espanya respecte a Europa

Taxes d'atur mensuals desestacionalitzades d'Eurostat, comparables entre països. El {ue_resumen[0]?.mes_txt} la taxa espanyola és del {formatNumber(ue_resumen[0]?.es, 1)} %, {formatNumber(ue_resumen[0]?.ratio, 1)} vegades la mitjana de la UE ({formatNumber(ue_resumen[0]?.ue, 1)} %); la dels menors de 25 anys, del {formatNumber(ue_resumen[0]?.es_joven, 1)} % davant del {formatNumber(ue_resumen[0]?.ue_joven, 1)} %.

<LineChart
    data={ue}
    x=mes
    y=tasa_paro
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% dels actius"
    title="Taxa d'atur a la UE (mensual, desestacionalitzada)"
/>

<LineChart
    data={ue}
    x=mes
    y=tasa_paro_menor25
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% dels actius menors de 25"
    title="Atur juvenil (menors de 25) a la UE"
/>

Els salaris són a [Salaris](/ca/economia/salarios) i l'ocupació pública a [Ocupació pública](/ca/cuentas-publicas/empleo-publico).

---

**Fonts:** INE, Enquesta de Població Activa: [taxes d'atur per sexe i edat (65219)](https://www.ine.es/jaxiT3/Tabla.htm?t=65219), [taxes d'activitat, atur i ocupació per província (65349)](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [atur per edat i comunitat (65334)](https://www.ine.es/jaxiT3/Tabla.htm?t=65334), [atur per nacionalitat (65336)](https://www.ine.es/jaxiT3/Tabla.htm?t=65336), [atur per nivell de formació (66000)](https://www.ine.es/jaxiT3/Tabla.htm?t=66000), [aturats per temps de cerca (65236)](https://www.ine.es/jaxiT3/Tabla.htm?t=65236), [incidència de l'atur a les llars (65276)](https://www.ine.es/jaxiT3/Tabla.htm?t=65276), [assalariats per tipus de contracte (65194)](https://www.ine.es/jaxiT3/Tabla.htm?t=65194) i [ocupats a temps parcial per motiu (65152)](https://www.ine.es/jaxiT3/Tabla.htm?t=65152). [SEPE, atur registrat per municipis (dades obertes, CSV anual)](https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv); població de 16 a 64 anys de l'Estadística Contínua de Població de l'INE. [Eurostat, une_rt_m](https://ec.europa.eu/eurostat/databrowser/view/une_rt_m/default/table). La taxa d'atur de llarga durada es calcula com a taxa d'atur pel percentatge d'aturats que fa un any o més que busquen feina.
