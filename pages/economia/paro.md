---
title: Paro y empleo
description: "Tasa de paro en España por sexo, edad, nacionalidad, estudios y territorio, paro juvenil y de larga duración, temporalidad, paro registrado mensual y comparación con la UE."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
    t.ruta,
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
    t.ruta,
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

# 📉 Paro y empleo

Cuánta gente busca trabajo y no lo encuentra, a quién afecta más, dónde y cuánto dura. Casi todas las cifras son de la **Encuesta de Población Activa (EPA)** del INE, que se publica cada trimestre y mide el paro con los criterios internacionales: la **tasa de paro** es el porcentaje de la población activa (quienes trabajan o buscan trabajo) que no tiene empleo. El dato más reciente es del **{epa_ult[0]?.periodo}**. Los datos trimestrales no están desestacionalizados, así que cada trimestre se compara con el mismo del año anterior.

<Grid cols=4>
    <KpiCard
        title="Tasa de paro"
        value={epa_ult[0]?.tasa_paro}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro, 1)} %"
        period="{epa_ult[0]?.periodo} · {formatNumber(epa_ult[0]?.parados / 1000000, 2)} millones de parados"
        change={epa_ult[0]?.dif_paro?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro)}
    />
    <KpiCard
        title="Paro juvenil (menores de 25)"
        value={epa_ult[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_menor25, 1)} %"
        period="de los activos de 16 a 24 años, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_menor25?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Tasa de empleo"
        value={epa_ult[0]?.tasa_empleo}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_empleo, 1)} %"
        period="de la población de 16 y más años trabaja, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_empleo?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-up"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_empleo)}
    />
    <KpiCard
        title="Paro registrado"
        value={registrado.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(registrado.slice(-1)[0]?.por_100_16_64, 1)} por 100"
        period="habitantes de 16 a 64 años, {registrado.slice(-1)[0]?.mes_txt} · {formatNumber(registrado.slice(-1)[0]?.paro_registrado / 1000000, 2)} millones"
        change={registrado.slice(-1)[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="parados registrados vs un año antes"
        direction="positive-down"
        source="SEPE"
        sparklineData={registrado.slice(-60).map(d => d.por_100_16_64)}
    />
</Grid>

<Grid cols=4>
    <KpiCard
        title="Paro de larga duración"
        value={epa_ult[0]?.tasa_paro_larga}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_larga, 1)} %"
        period="de los activos lleva un año o más buscando empleo ({formatNumber(epa_ult[0]?.pct_parados_larga, 0)} % de los parados)"
        change={epa_ult[0]?.dif_larga?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_larga)}
    />
    <KpiCard
        title="Hogares con todos en paro"
        value={epa_ult[0]?.pct_hogares_todos_parados}
        formattedValue="{formatNumber(epa_ult[0]?.pct_hogares_todos_parados, 1)} %"
        period="de los hogares con algún activo tienen a todos sus activos en paro, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_hogares?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.pct_hogares_todos_parados)}
    />
    <KpiCard
        title="Temporalidad"
        value={epa_ult[0]?.tasa_temporalidad}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_temporalidad, 1)} %"
        period="de los asalariados tiene contrato temporal, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_temporalidad?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_temporalidad)}
    />
    <KpiCard
        title="Parcialidad involuntaria"
        value={epa_ult[0]?.pct_parcial_involuntario}
        formattedValue="{formatNumber(epa_ult[0]?.pct_parcial_involuntario, 1)} %"
        period="de quienes trabajan a tiempo parcial lo hace por no encontrar jornada completa"
        change={epa_ult[0]?.dif_parcial?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs un año antes"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.filter(d => d.pct_parcial_involuntario != null).map(d => d.pct_parcial_involuntario)}
    />
</Grid>

## Paro, empleo y actividad desde 2002

El paro tocó techo en el {hitos[0]?.periodo_max}, con un {formatNumber(hitos[0]?.paro_max, 1)} % de los activos sin trabajo; el mínimo de la serie es del {hitos[0]?.periodo_min} ({formatNumber(hitos[0]?.paro_min, 1)} %). {#if hitos[0]?.ultimo_periodo_igual}El {formatNumber(epa_ult[0]?.tasa_paro, 1)} % actual es la tasa más baja desde el {hitos[0]?.ultimo_periodo_igual}.{:else}El {formatNumber(epa_ult[0]?.tasa_paro, 1)} % actual es la tasa más baja de toda la serie.{/if} La tasa de empleo mide qué parte de la población de 16 años o más trabaja, y la de actividad qué parte trabaja o busca trabajo.

<LineChart
    data={tasas_largo}
    x=trimestre
    y=tasa
    series=indicador
    yFmt='0.0"%"'
    yAxisTitle="% de la población o de los activos"
    title="Tasas de paro, empleo y actividad (EPA, trimestral)"
/>

## ¿A quién afecta más el paro?

En el {epa_ult[0]?.periodo}, la tasa de paro es del {formatNumber(grupos_ult[0]?.mujeres, 1)} % entre las mujeres y del {formatNumber(grupos_ult[0]?.hombres, 1)} % entre los hombres; del {formatNumber(grupos_ult[0]?.e16_19, 1)} % entre las personas de 16 a 19 años que buscan trabajo frente al {formatNumber(grupos_ult[0]?.e25_54, 1)} % de 25 a 54 años; y del {formatNumber(grupos_ult[0]?.no_ue, 1)} % entre los extranjeros de fuera de la UE frente al {formatNumber(grupos_ult[0]?.espanola, 1)} % de los españoles.

<LineChart
    data={grupos_sexo}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% de los activos"
    title="Tasa de paro por sexo"
/>

<LineChart
    data={grupos_edad}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% de los activos"
    title="Tasa de paro por edad"
/>

El paro juvenil más alto de la serie, un {formatNumber(hitos[0]?.menor25_max, 1)} % de los activos menores de 25 años, se alcanzó en el {hitos[0]?.periodo_menor25_max}. Ojo al leerlo: entre los jóvenes muchos estudian y no son activos, así que la tasa se calcula sobre los que sí trabajan o buscan trabajo.

<LineChart
    data={grupos_nac}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="% de los activos"
    title="Tasa de paro por nacionalidad"
/>

### Por nivel de estudios

Cuantos más estudios, menos paro. Media anual de {formacion_ult[0]?.anio}, población de 16 años o más.

<BarChart
    data={formacion_ult}
    x=nivel_corto
    y=tasa_paro
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% de los activos"
    title="Tasa de paro por nivel de estudios terminados en {formacion_ult[0]?.anio}"
/>

<LineChart
    data={formacion_evol}
    x=anio
    y=tasa_paro
    series=nivel_corto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de los activos"
    title="Evolución del paro por nivel de estudios (media anual)"
/>

## Paro de larga duración y hogares sin ingresos del trabajo

Un parado de larga duración lleva un año o más buscando empleo. Hoy son el {formatNumber(epa_ult[0]?.pct_parados_larga, 0)} % de los parados, un {formatNumber(epa_ult[0]?.tasa_paro_larga, 1)} % de todos los activos. La segunda línea es el porcentaje de hogares con al menos una persona activa en los que todas las personas activas están en paro.

<LineChart
    data={larga}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Paro de larga duración y hogares con todos sus activos en paro"
/>

## Temporalidad y jornada parcial no deseada

Porcentaje de asalariados con contrato temporal y porcentaje de quienes trabajan a tiempo parcial porque no han encontrado un empleo a jornada completa. La temporalidad llegó a su máximo en el {hitos[0]?.periodo_temporalidad_max} ({formatNumber(hitos[0]?.temporalidad_max, 1)} %); en 2021, el año anterior a la entrada en vigor de la reforma laboral de 2022, promedió un {formatNumber(hitos[0]?.temporalidad_2021, 1)} %, y hoy está en el {formatNumber(epa_ult[0]?.tasa_temporalidad, 1)} %. Los contratos fijos discontinuos cuentan en la EPA como indefinidos.

<LineChart
    data={calidad}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Temporalidad y parcialidad involuntaria"
/>

## Por comunidad y provincia

Media de los cuatro últimos trimestres, para suavizar el ruido de la muestra de la EPA en los territorios pequeños. La comunidad con más paro es {terr_resumen[0]?.ccaa_max} ({formatNumber(terr_resumen[0]?.ccaa_max_tasa / 0.01, 1)} %) y la que menos {terr_resumen[0]?.ccaa_min} ({formatNumber(terr_resumen[0]?.ccaa_min_tasa / 0.01, 1)} %). Por provincias, el rango va de {terr_resumen[0]?.prov_min} ({formatNumber(terr_resumen[0]?.prov_min_tasa / 0.01, 1)} %) a {terr_resumen[0]?.prov_max} ({formatNumber(terr_resumen[0]?.prov_max_tasa / 0.01, 1)} %). Pulsa en un territorio para ver su ficha.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (EPA)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: 'Tasa de paro (media 4 trim.)', fmt: 'pct1'},
        {id: 'tasa_paro_menor25', title: 'Menores de 25', fmt: 'pct1'},
        {id: 'hogares_todos_parados', title: 'Hogares con todos en paro', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=tasa_paro title="Tasa de paro" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_paro_trim title="Último trimestre" fmt=pct1 />
    <Column id=dif_anual title="Cambio anual (pp)" fmt=num1 contentType=delta downIsGood=true />
    <Column id=tasa_paro_menor25 title="Menores de 25" fmt=pct1 />
    <Column id=tasa_paro_extranjeros title="Extranjeros (trim.)" fmt=pct1 />
    <Column id=hogares_todos_parados title="Hogares todos en paro" fmt=pct1 />
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (EPA), SEPE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: 'Tasa de paro EPA (media 4 trim.)', fmt: 'pct1'},
        {id: 'tasa_empleo', title: 'Tasa de empleo', fmt: 'pct1'},
        {id: 'registrado_100', title: 'Paro registrado por 100 hab. 16-64', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} link=ruta rows=10 search=true showLinkCol=false>
    <Column id=provincia title="Provincia" />
    <Column id=tasa_paro title="Tasa de paro EPA" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_empleo title="Tasa de empleo" fmt=pct1 />
    <Column id=registrado_100 title="Paro registrado por 100 hab. 16-64" fmt=num1 />
    <Column id=paro_registrado title="Parados registrados" fmt=num0 />
</DataTable>

## El dato mensual: paro registrado

El SEPE cuenta cada mes a los demandantes de empleo inscritos como parados en las oficinas de empleo. No coincide con la EPA (hay parados que no se inscriben e inscritos que la EPA no considera parados), pero se publica antes, cada mes, y llega hasta el municipio. Aquí, por cada 100 habitantes de 16 a 64 años. En {registrado.slice(-1)[0]?.mes_txt} había {formatNumber(registrado.slice(-1)[0]?.paro_registrado, 0)} parados registrados, {#if registrado.slice(-1)[0]?.variacion_anual < 0}{formatNumber(-registrado.slice(-1)[0]?.variacion_anual, 0)} menos{:else}{formatNumber(registrado.slice(-1)[0]?.variacion_anual, 0)} más{/if} que un año antes.

<LineChart
    data={registrado}
    x=mes
    y=por_100_16_64
    yFmt='0.0'
    yAxisTitle="parados registrados por 100 hab. de 16 a 64"
    title="Paro registrado por cada 100 habitantes de 16 a 64 años"
/>

### Municipios de 20.000 habitantes o más

Parados registrados en {registrado.slice(-1)[0]?.mes_txt} por cada 100 habitantes (población total del padrón).

<DataTable data={municipios} rows=10 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=paro_registrado title="Parados registrados" fmt=num0 />
    <Column id=por_100_hab title="Por 100 habitantes" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=variacion_anual title="Cambio en un año" fmt=pct1 contentType=delta downIsGood=true />
</DataTable>

## España frente a Europa

Tasas de paro mensuales desestacionalizadas de Eurostat, comparables entre países. En {ue_resumen[0]?.mes_txt} la tasa española es del {formatNumber(ue_resumen[0]?.es, 1)} %, {formatNumber(ue_resumen[0]?.ratio, 1)} veces la media de la UE ({formatNumber(ue_resumen[0]?.ue, 1)} %); la de menores de 25 años, del {formatNumber(ue_resumen[0]?.es_joven, 1)} % frente al {formatNumber(ue_resumen[0]?.ue_joven, 1)} %.

<LineChart
    data={ue}
    x=mes
    y=tasa_paro
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% de los activos"
    title="Tasa de paro en la UE (mensual, desestacionalizada)"
/>

<LineChart
    data={ue}
    x=mes
    y=tasa_paro_menor25
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% de los activos menores de 25"
    title="Paro juvenil (menores de 25) en la UE"
/>

Los salarios están en [Salarios](/economia/salarios) y el empleo público en [Empleo público](/cuentas-publicas/empleo-publico).

---

**Fuentes:** INE, Encuesta de Población Activa: [tasas de paro por sexo y edad (65219)](https://www.ine.es/jaxiT3/Tabla.htm?t=65219), [tasas de actividad, paro y empleo por provincia (65349)](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [paro por edad y comunidad (65334)](https://www.ine.es/jaxiT3/Tabla.htm?t=65334), [paro por nacionalidad (65336)](https://www.ine.es/jaxiT3/Tabla.htm?t=65336), [paro por nivel de formación (66000)](https://www.ine.es/jaxiT3/Tabla.htm?t=66000), [parados por tiempo de búsqueda (65236)](https://www.ine.es/jaxiT3/Tabla.htm?t=65236), [incidencia del paro en los hogares (65276)](https://www.ine.es/jaxiT3/Tabla.htm?t=65276), [asalariados por tipo de contrato (65194)](https://www.ine.es/jaxiT3/Tabla.htm?t=65194) y [ocupados a tiempo parcial por motivo (65152)](https://www.ine.es/jaxiT3/Tabla.htm?t=65152). [SEPE, paro registrado por municipios (datos abiertos, CSV anual)](https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv); población de 16 a 64 años de la Estadística Continua de Población del INE. [Eurostat, une_rt_m](https://ec.europa.eu/eurostat/databrowser/view/une_rt_m/default/table). La tasa de paro de larga duración se calcula como tasa de paro por el porcentaje de parados que llevan un año o más buscando empleo.
