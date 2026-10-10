---
i18n_origen: beb0f070e1b9
title: Inflación (IPC)
description: "Inflación en España: IPC xeral e subxacente, prezos por grupos, prezo real da luz, o gas e os carburantes, canto subiron os prezos desde 2008 e 2019, IPC por comunidade e comparación coa zona euro."
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql ipc
SELECT *, strftime(mes, '%m/%Y') AS mes_txt
FROM mother.mercado_ipc_mensual
ORDER BY mes
```

```sql ipc_ult
SELECT
    u.*,
    strftime(u.mes, '%m/%Y') AS mes_txt,
    u.var_anual - p.var_anual AS dif_mes,
    u.subyacente - p.subyacente AS dif_sub_mes,
    u.energia - p.energia AS dif_energia_mes,
    u.indice_2019 - 100 AS subida_2019,
    u.indice_2008 - 100 AS subida_2008,
    100 * 100 / u.indice_2019 AS valor_100_2019
FROM mother.mercado_ipc_mensual u
LEFT JOIN mother.mercado_ipc_mensual p ON p.mes = u.mes - INTERVAL 1 MONTH
WHERE u.mes = (SELECT max(mes) FROM mother.mercado_ipc_mensual)
```

```sql ipc_anual
WITH a AS (
    SELECT anio, avg(indice) AS indice_medio, count(*) AS meses
    FROM mother.mercado_ipc_mensual
    GROUP BY anio
)
SELECT
    anio,
    meses,
    100 * (indice_medio / lag(indice_medio) OVER (ORDER BY anio) - 1) AS inflacion_media
FROM a
WHERE meses = 12
ORDER BY anio
```

```sql ipc_anual_serie
SELECT anio, inflacion_media FROM ${ipc_anual} WHERE inflacion_media IS NOT NULL ORDER BY anio
```

```sql hitos_ipc
SELECT
    max(var_anual) AS max_var,
    strftime(arg_max(mes, var_anual), '%m/%Y') AS mes_max,
    min(var_anual) AS min_var,
    strftime(arg_min(mes, var_anual), '%m/%Y') AS mes_min,
    max(energia) AS max_energia,
    strftime(arg_max(mes, energia), '%m/%Y') AS mes_max_energia
FROM mother.mercado_ipc_mensual
```

```sql general_sub
SELECT mes, 'IPC general' AS serie, var_anual AS tasa FROM mother.mercado_ipc_mensual
UNION ALL
SELECT mes, 'Subyacente (sin energía ni alimentos frescos)' AS serie, subyacente AS tasa FROM mother.mercado_ipc_mensual WHERE subyacente IS NOT NULL
ORDER BY mes, serie
```

```sql componentes
SELECT mes, 'Energía' AS serie, energia AS tasa FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2015-01-01'
UNION ALL
SELECT mes, 'Alimentos sin elaborar' AS serie, alimentos_sin_elaborar AS tasa FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2015-01-01'
UNION ALL
SELECT mes, 'Alimentos elaborados, bebidas y tabaco' AS serie, alimentos_elaborados AS tasa FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2015-01-01'
UNION ALL
SELECT mes, 'Bienes industriales sin energía' AS serie, bienes_industriales AS tasa FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2015-01-01'
UNION ALL
SELECT mes, 'Servicios' AS serie, servicios AS tasa FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2015-01-01'
ORDER BY mes, serie
```

```sql nivel
SELECT mes, 'Desde 2008 (media de 2008 = 100)' AS base, indice_2008 AS indice FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2008-01-01'
UNION ALL
SELECT mes, 'Desde 2019 (media de 2019 = 100)' AS base, indice_2019 AS indice FROM mother.mercado_ipc_mensual WHERE mes >= DATE '2019-01-01'
ORDER BY mes, base
```

```sql grupos_ult
-- Último mes CON datos por grupos: el IPC adelantado del INE solo trae el índice general
SELECT grupo_corto, var_anual, contribucion_aprox, ponderacion / 10 AS peso_pct, anio_ponderacion, strftime(mes, '%m/%Y') AS mes_txt
FROM mother.mercado_ipc_grupos
WHERE mes = (SELECT max(mes) FROM mother.mercado_ipc_grupos WHERE NOT es_general) AND NOT es_general
ORDER BY var_anual DESC
```

```sql grupos_contrib
SELECT * FROM ${grupos_ult} ORDER BY contribucion_aprox DESC
```

```sql grupos_contrib_top
SELECT
    (SELECT grupo_corto FROM ${grupos_contrib} ORDER BY contribucion_aprox DESC LIMIT 1) AS g1,
    (SELECT contribucion_aprox FROM ${grupos_contrib} ORDER BY contribucion_aprox DESC LIMIT 1) AS c1,
    (SELECT var_anual FROM ${grupos_contrib} ORDER BY contribucion_aprox DESC LIMIT 1) AS v1,
    (SELECT grupo_corto FROM ${grupos_contrib} ORDER BY var_anual DESC LIMIT 1) AS gmax,
    (SELECT var_anual FROM ${grupos_contrib} ORDER BY var_anual DESC LIMIT 1) AS vmax
```

```sql grupos_2019
WITH b AS (
    SELECT grupo, avg(indice) AS media_2019
    FROM mother.mercado_ipc_grupos
    WHERE year(mes) = 2019
    GROUP BY grupo
)
SELECT
    g.grupo_corto,
    g.es_general,
    100 * (g.indice / b.media_2019 - 1) AS subida
FROM mother.mercado_ipc_grupos g
JOIN b USING (grupo)
WHERE g.mes = (SELECT max(mes) FROM mother.mercado_ipc_grupos WHERE NOT es_general)
ORDER BY subida DESC
```

```sql grupos_2019_resumen
SELECT
    (SELECT grupo_corto FROM ${grupos_2019} WHERE NOT es_general ORDER BY subida DESC LIMIT 1) AS gmax,
    (SELECT subida FROM ${grupos_2019} WHERE NOT es_general ORDER BY subida DESC LIMIT 1) AS smax,
    (SELECT grupo_corto FROM ${grupos_2019} WHERE NOT es_general ORDER BY subida ASC LIMIT 1) AS gmin,
    (SELECT subida FROM ${grupos_2019} WHERE NOT es_general ORDER BY subida ASC LIMIT 1) AS smin,
    (SELECT subida FROM ${grupos_2019} WHERE grupo_corto = 'Alimentos') AS alimentos
```

```sql grupos_evol
SELECT mes, grupo_corto, var_anual
FROM mother.mercado_ipc_grupos
WHERE grupo_corto IN ('Alimentos', 'Vivienda y energía', 'Transporte', 'Restaurantes y hoteles')
  AND mes >= DATE '2019-01-01'
ORDER BY mes, grupo_corto
```

```sql ccaa
SELECT
    c.cod_ccaa,
    t.nombre AS comunidad,
    '/gl' || t.ruta AS ruta,
    c.var_anual / 100 AS var_anual,
    c.subida_desde_2019 / 100 AS subida_desde_2019,
    strftime(c.mes, '%m/%Y') AS mes_txt
FROM mother.mercado_ipc_ccaa c
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod_ccaa
WHERE c.mes = (SELECT max(mes) FROM mother.mercado_ipc_ccaa)
ORDER BY var_anual DESC
```

```sql ccaa_resumen
SELECT
    (SELECT comunidad FROM ${ccaa} ORDER BY subida_desde_2019 DESC LIMIT 1) AS cmax,
    (SELECT subida_desde_2019 FROM ${ccaa} ORDER BY subida_desde_2019 DESC LIMIT 1) AS smax,
    (SELECT comunidad FROM ${ccaa} ORDER BY subida_desde_2019 ASC LIMIT 1) AS cmin,
    (SELECT subida_desde_2019 FROM ${ccaa} ORDER BY subida_desde_2019 ASC LIMIT 1) AS smin
```

```sql ue
SELECT mes, pais, tasa_anual, indice_2019
FROM mother.mercado_ipca_ue
WHERE mes >= DATE '2015-01-01' AND geo IN ('ES', 'EA20', 'DE', 'FR', 'IT', 'PT')
ORDER BY mes, pais
```

```sql ue_nivel
SELECT mes, pais, indice_2019 FROM ${ue} WHERE mes >= DATE '2019-01-01' ORDER BY mes, pais
```

```sql diferencial
SELECT
    e.mes,
    e.tasa_anual AS es,
    z.tasa_anual AS ea,
    e.tasa_anual - z.tasa_anual AS diferencial,
    e.indice_2019 AS es_2019,
    z.indice_2019 AS ea_2019,
    strftime(e.mes, '%m/%Y') AS mes_txt
FROM mother.mercado_ipca_ue e
JOIN mother.mercado_ipca_ue z ON z.mes = e.mes AND z.geo = 'EA20'
WHERE e.geo = 'ES' AND e.tasa_anual IS NOT NULL AND z.tasa_anual IS NOT NULL
ORDER BY e.mes
```

# 🛒 Inflación (IPC)

Canto soben os prezos en España, que se encarece máis e canto poder de compra se perdeu. O **Índice de Prezos de Consumo (IPC)** do INE mide cada mes o prezo dunha cesta de bens e servizos que representa o gasto dos fogares; a **inflación** é a suba dese índice respecto ao mesmo mes do ano anterior. Último dato: **{ipc_ult[0]?.mes_txt}**.

<Grid cols=4>
    <KpiCard
        title="Inflación"
        value={ipc_ult[0]?.var_anual}
        formattedValue="{formatNumber(ipc_ult[0]?.var_anual, 1)} %"
        period="IPC xeral, {ipc_ult[0]?.mes_txt} vs. un ano antes"
        change={ipc_ult[0]?.dif_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs. o mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => ({...d, y: d.var_anual}))}
    />
    <KpiCard
        title="Inflación subxacente"
        value={ipc_ult[0]?.subyacente}
        formattedValue="{formatNumber(ipc_ult[0]?.subyacente, 1)} %"
        period="sen enerxía nin alimentos sen elaborar, os prezos máis volátiles"
        change={ipc_ult[0]?.dif_sub_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs. o mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.subyacente != null).slice(-60).map(d => ({...d, y: d.subyacente}))}
    />
    <KpiCard
        title="Prezos desde 2019"
        value={ipc_ult[0]?.subida_2019}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2019, 1)} %"
        period="o que custaba 100 € de media en 2019 custa hoxe {formatNumber(ipc_ult[0]?.indice_2019, 0)} €"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.anio >= 2019).map(d => ({...d, y: d.indice_2019}))}
    />
    <KpiCard
        title="Diferenza coa zona euro"
        value={diferencial.slice(-1)[0]?.diferencial}
        formattedValue="{diferencial.slice(-1)[0]?.diferencial >= 0 ? '+' : ''}{formatNumber(diferencial.slice(-1)[0]?.diferencial, 1)} pp"
        period="inflación harmonizada: España {formatNumber(diferencial.slice(-1)[0]?.es, 1)} %, zona euro {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} % ({diferencial.slice(-1)[0]?.mes_txt})"
        direction="positive-down"
        source="Eurostat / IPCH"
        sparklineData={diferencial.slice(-60).map(d => ({...d, y: d.diferencial}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('inflacion')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'inflacion')} />


<Grid cols=4>
    <KpiCard
        title="Enerxía"
        value={ipc_ult[0]?.energia}
        formattedValue="{ipc_ult[0]?.energia >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.energia, 1)} %"
        period="electricidade, gas e carburantes, {ipc_ult[0]?.mes_txt} vs. un ano antes"
        change={ipc_ult[0]?.dif_energia_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs. o mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => ({...d, y: d.energia}))}
    />
    <KpiCard
        title="Alimentos sen elaborar"
        value={ipc_ult[0]?.alimentos_sin_elaborar}
        formattedValue="{ipc_ult[0]?.alimentos_sin_elaborar >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.alimentos_sin_elaborar, 1)} %"
        period="froita, verdura, carne, peixe, ovos..., vs. un ano antes"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => ({...d, y: d.alimentos_sin_elaborar}))}
    />
    <KpiCard
        title="Inflación media anual"
        value={ipc_anual_serie.slice(-1)[0]?.inflacion_media}
        formattedValue="{formatNumber(ipc_anual_serie.slice(-1)[0]?.inflacion_media, 1)} %"
        period="media de {ipc_anual_serie.slice(-1)[0]?.anio} fronte á de {ipc_anual_serie.slice(-1)[0]?.anio - 1}"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc_anual_serie.map(d => ({...d, y: d.inflacion_media}))}
    />
    <KpiCard
        title="Prezos desde 2008"
        value={ipc_ult[0]?.subida_2008}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2008, 1)} %"
        period="suba acumulada do IPC desde a media de 2008"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.anio >= 2008).map(d => ({...d, y: d.indice_2008}))}
    />
</Grid>

## A inflación mes a mes

A inflación máis alta desde 2002 foi a de {hitos_ipc[0]?.mes_max} ({formatNumber(hitos_ipc[0]?.max_var, 1)} %) e a máis baixa a de {hitos_ipc[0]?.mes_min} ({formatNumber(hitos_ipc[0]?.min_var, 1)} %). A subxacente deixa fóra a enerxía e os alimentos sen elaborar, cuxos prezos soben e baixan con forza; por iso se usa para ver a tendencia de fondo.

<LineChart
    data={general_sub}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% vs. mesmo mes do ano anterior"
    title="IPC xeral e subxacente (taxa anual)"
/>

<BarChart
    data={ipc_anual_serie}
    x=anio
    y=inflacion_media
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% (media anual)"
    title="Inflación media de cada ano"
/>

## Canto subiron os prezos

O índice acumula as subas: se vale 127, os mesmos produtos custan un 27 % máis ca no ano de referencia. Un soldo, unha pensión ou uns aforros que non medrasen desde a media de 2019 compran hoxe un {formatNumber(ipc_ult[0]?.perdida_poder_compra_2019, 1)} % menos. Desde 2008 os prezos subiron un {formatNumber(ipc_ult[0]?.subida_2008, 1)} %. A evolución dos soldos descontada a inflación está en [Salarios](/gl/economia/salarios).

<LineChart
    data={nivel}
    x=mes
    y=indice
    series=base
    yFmt='0.0'
    yAxisTitle="índice"
    startingAtZero={false}
    title="Nivel de prezos acumulado (IPC xeral)"
/>

## Que se encarece máis

Taxa anual de cada grupo de gasto en {grupos_ult[0]?.mes_txt}. O grupo que máis sobe é {grupos_contrib_top[0]?.gmax} ({formatNumber(grupos_contrib_top[0]?.vmax, 1)} %).

<BarChart
    data={grupos_ult}
    x=grupo_corto
    y=var_anual
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Variación anual dos prezos por grupo ({grupos_ult[0]?.mes_txt})"
/>

O que pesa na inflación total depende de canto sobe cada grupo e de canto gastan nel os fogares (o seu peso na cesta de {grupos_ult[0]?.anio_ponderacion}). O que máis achega agora é {grupos_contrib_top[0]?.g1}: sobe un {formatNumber(grupos_contrib_top[0]?.v1, 1)} % e achega uns {formatNumber(grupos_contrib_top[0]?.c1, 1)} puntos dos {formatNumber(ipc_ult[0]?.var_anual, 1)} da inflación xeral (cálculo aproximado).

<BarChart
    data={grupos_contrib}
    x=grupo_corto
    y=contribucion_aprox
    swapXY=true
    sort=false
    yFmt='0.00'
    title="Contribución aproximada de cada grupo á inflación (puntos)"
/>

<DataTable data={grupos_contrib} rows=all>
    <Column id=grupo_corto title="Grupo" />
    <Column id=peso_pct title="Peso na cesta (%)" fmt=num1 />
    <Column id=var_anual title="Variación anual (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Contribución (puntos)" fmt=num2 contentType=bar barColor="#fecaca" />
</DataTable>

### Suba acumulada desde 2019 por grupo

Desde a media de 2019, o que máis se encareceu é {grupos_2019_resumen[0]?.gmax} (+{formatNumber(grupos_2019_resumen[0]?.smax, 1)} %) e o que menos {grupos_2019_resumen[0]?.gmin} ({#if grupos_2019_resumen[0]?.smin >= 0}+{/if}{formatNumber(grupos_2019_resumen[0]?.smin, 1)} %). Os alimentos custan un {formatNumber(grupos_2019_resumen[0]?.alimentos, 1)} % máis.

<BarChart
    data={grupos_2019}
    x=grupo_corto
    y=subida
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Suba de prezos desde a media de 2019, por grupo"
/>

<LineChart
    data={grupos_evol}
    x=mes
    y=var_anual
    series=grupo_corto
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflación de alimentos, vivenda e enerxía, transporte e restaurantes"
/>

<LineChart
    data={componentes}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflación por tipo de produto (grupos especiais do INE)"
/>

A enerxía chegou a subir un {formatNumber(hitos_ipc[0]?.max_energia, 1)} % interanual en {hitos_ipc[0]?.mes_max_energia}.

## ⚡ Prezo da enerxía

```sql en_ult
SELECT
    producto,
    var_anual,
    indice_2019,
    indice_2019 - 100 AS subida_2019,
    contribucion_aprox,
    ponderacion / 10 AS peso_pct,
    strftime(mes, '%m/%Y') AS mes_txt
FROM mother.mercado_energia_ipc
WHERE mes = (SELECT max(mes) FROM mother.mercado_energia_ipc)
ORDER BY indice_2019 DESC
```

```sql en_nivel
SELECT mes, producto, indice_2019
FROM mother.mercado_energia_ipc
WHERE mes >= DATE '2019-01-01'
  AND producto IN ('IPC general', 'Electricidad', 'Gas natural', 'Butano y propano', 'Gasóleo de calefacción', 'Gasóleo de automoción', 'Gasolina')
ORDER BY mes, producto
```

```sql en_var
SELECT mes, producto, var_anual
FROM mother.mercado_energia_ipc
WHERE mes >= DATE '2019-01-01' AND var_anual IS NOT NULL
  AND producto IN ('IPC general', 'Electricidad', 'Gas natural', 'Gasóleo de automoción', 'Gasolina')
ORDER BY mes, producto
```

```sql en_electricidad
SELECT mes, var_anual, indice_2019, contribucion_aprox
FROM mother.mercado_energia_ipc
WHERE producto = 'Electricidad'
ORDER BY mes
```

```sql en_contrib
SELECT mes, 'Inflación general' AS serie, var_anual AS puntos FROM mother.mercado_energia_ipc WHERE producto = 'IPC general' AND mes >= DATE '2019-01-01'
UNION ALL
SELECT mes, 'Aporte de la energía' AS serie, contribucion_aprox AS puntos FROM mother.mercado_energia_ipc WHERE producto = 'Energía (total)' AND mes >= DATE '2019-01-01' AND contribucion_aprox IS NOT NULL
ORDER BY mes, serie
```

```sql en_hitos
SELECT
    max(var_anual) FILTER (WHERE producto = 'Electricidad') AS elec_max,
    strftime(arg_max(mes, var_anual) FILTER (WHERE producto = 'Electricidad'), '%m/%Y') AS elec_mes_max,
    max(contribucion_aprox) FILTER (WHERE producto = 'Energía (total)') AS contrib_max,
    strftime(arg_max(mes, contribucion_aprox) FILTER (WHERE producto = 'Energía (total)'), '%m/%Y') AS contrib_mes_max,
    max(var_anual) FILTER (WHERE producto = 'IPC general' AND mes = (SELECT arg_max(mes, contribucion_aprox) FILTER (WHERE producto = 'Energía (total)') FROM mother.mercado_energia_ipc)) AS general_en_max
FROM mother.mercado_energia_ipc
```

```sql carb
SELECT fecha, pais, producto, eur_litro, eur_litro_real, anio_euros
FROM mother.mercado_energia_carburantes
ORDER BY fecha, pais, producto
```

```sql carb_es
SELECT fecha, producto, eur_litro_real
FROM ${carb}
WHERE pais = 'España' AND producto IN ('Gasolina 95', 'Gasóleo de automoción', 'Gasóleo de calefacción')
ORDER BY fecha, producto
```

```sql carb_ue
SELECT fecha, pais || ': ' || producto AS serie, eur_litro_real
FROM ${carb}
WHERE producto IN ('Gasolina 95', 'Gasóleo de automoción') AND fecha >= DATE '2015-01-01'
ORDER BY fecha, serie
```

```sql carb_ult
SELECT
    max(fecha) AS fecha,
    strftime(max(fecha), '%d/%m/%Y') AS semana_txt,
    max(anio_euros) AS anio_euros,
    max(eur_litro) FILTER (WHERE pais = 'España' AND producto = 'Gasolina 95' AND fecha = (SELECT max(fecha) FROM ${carb})) AS gasolina,
    max(eur_litro) FILTER (WHERE pais = 'España' AND producto = 'Gasóleo de automoción' AND fecha = (SELECT max(fecha) FROM ${carb})) AS gasoleo,
    max(eur_litro) FILTER (WHERE pais = 'España' AND producto = 'Gasóleo de calefacción' AND fecha = (SELECT max(fecha) FROM ${carb})) AS calefaccion,
    max(eur_litro) FILTER (WHERE pais = 'Media UE' AND producto = 'Gasolina 95' AND fecha = (SELECT max(fecha) FROM ${carb})) AS gasolina_ue,
    max(eur_litro) FILTER (WHERE pais = 'Media UE' AND producto = 'Gasóleo de automoción' AND fecha = (SELECT max(fecha) FROM ${carb})) AS gasoleo_ue,
    max(eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasolina 95') AS gasolina_real_max,
    strftime(arg_max(fecha, eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasolina 95'), '%m/%Y') AS gasolina_real_max_fecha,
    max(eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasóleo de automoción') AS gasoleo_real_max,
    strftime(arg_max(fecha, eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasóleo de automoción'), '%m/%Y') AS gasoleo_real_max_fecha,
    avg(eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasolina 95' AND year(fecha) = 2019) AS gasolina_real_2019,
    avg(eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasóleo de automoción' AND year(fecha) = 2019) AS gasoleo_real_2019,
    max(eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasolina 95' AND fecha = (SELECT max(fecha) FROM ${carb})) AS gasolina_real,
    max(eur_litro_real) FILTER (WHERE pais = 'España' AND producto = 'Gasóleo de automoción' AND fecha = (SELECT max(fecha) FROM ${carb})) AS gasoleo_real
FROM ${carb}
```

```sql carb_spark_gasolina
SELECT fecha, eur_litro_real FROM ${carb} WHERE pais = 'España' AND producto = 'Gasolina 95' ORDER BY fecha
```

```sql carb_spark_gasoleo
SELECT fecha, eur_litro_real FROM ${carb} WHERE pais = 'España' AND producto = 'Gasóleo de automoción' ORDER BY fecha
```

```sql hogares
SELECT fecha, semestre, energia, pais, eur_kwh, eur_kwh_real, anio_euros
FROM mother.mercado_energia_hogares
ORDER BY fecha, energia, pais
```

```sql hogares_elec
SELECT fecha, pais, eur_kwh_real FROM ${hogares}
WHERE energia = 'Electricidad' AND pais IN ('España', 'UE-27', 'Alemania', 'Francia', 'Italia', 'Portugal')
ORDER BY fecha, pais
```

```sql hogares_gas
SELECT fecha, pais, eur_kwh_real FROM ${hogares}
WHERE energia = 'Gas natural' AND pais IN ('España', 'UE-27', 'Alemania', 'Francia', 'Italia', 'Portugal')
ORDER BY fecha, pais
```

```sql hogares_es_elec
SELECT fecha, eur_kwh_real FROM ${hogares} WHERE energia = 'Electricidad' AND pais = 'España' ORDER BY fecha
```

```sql hogares_ult
SELECT
    max(semestre) AS semestre,
    max(anio_euros) AS anio_euros,
    max(eur_kwh) FILTER (WHERE energia = 'Electricidad' AND pais = 'España' AND semestre = (SELECT max(semestre) FROM ${hogares})) AS elec_es,
    max(eur_kwh) FILTER (WHERE energia = 'Electricidad' AND pais = 'UE-27' AND semestre = (SELECT max(semestre) FROM ${hogares})) AS elec_ue,
    max(eur_kwh) FILTER (WHERE energia = 'Gas natural' AND pais = 'España' AND semestre = (SELECT max(semestre) FROM ${hogares})) AS gas_es,
    max(eur_kwh) FILTER (WHERE energia = 'Gas natural' AND pais = 'UE-27' AND semestre = (SELECT max(semestre) FROM ${hogares})) AS gas_ue,
    max(eur_kwh_real) FILTER (WHERE energia = 'Electricidad' AND pais = 'España' AND semestre = (SELECT max(semestre) FROM ${hogares})) AS elec_es_real,
    max(eur_kwh_real) FILTER (WHERE energia = 'Electricidad' AND pais = 'UE-27' AND semestre = (SELECT max(semestre) FROM ${hogares})) AS elec_ue_real,
    max(eur_kwh_real) FILTER (WHERE energia = 'Electricidad' AND pais = 'España') AS elec_es_real_max,
    arg_max(semestre, eur_kwh_real) FILTER (WHERE energia = 'Electricidad' AND pais = 'España') AS elec_es_real_max_sem,
    avg(eur_kwh_real) FILTER (WHERE energia = 'Electricidad' AND pais = 'España' AND semestre LIKE '2019%') AS elec_es_real_2019
FROM ${hogares}
```

O prezo da enerxía foi unha das claves da inflación dos últimos anos. En {en_ult[0]?.mes_txt}, a enerxía sobe un {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.var_anual, 1)} % interanual e achega uns {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.contribucion_aprox, 1)} puntos dos {formatNumber(ipc_ult[0]?.var_anual, 1)} da inflación xeral, aínda que pesa un {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.peso_pct, 1)} % da cesta. Os prezos maioristas da electricidade e a demanda en tempo real están en [Electricidade en directo](/gl/energia-clima/directo) e [Récords eléctricos](/gl/energia-clima/records).

<Grid cols=4>
    <KpiCard
        title="Electricidade (IPC)"
        value={en_ult.find(d => d.producto === 'Electricidad')?.var_anual}
        formattedValue="{en_ult.find(d => d.producto === 'Electricidad')?.var_anual >= 0 ? '+' : ''}{formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.var_anual, 1)} %"
        period="vs. un ano antes, {en_ult[0]?.mes_txt} · {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.indice_2019, 0)} si 2019 = 100"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={en_electricidad.slice(-60).map(d => ({...d, y: d.var_anual}))}
    />
    <KpiCard
        title="Gasolina 95"
        value={carb_ult[0]?.gasolina_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l"
        period="semana do {carb_ult[0]?.semana_txt}, con impostos, en euros de {carb_ult[0]?.anio_euros} · {formatNumber(carb_ult[0]?.gasolina, 3)} € a prezo actual"
        direction="positive-down"
        source="Comisión Europea"
        sparklineData={carb_spark_gasolina.slice(-104).map(d => ({...d, y: d.eur_litro_real}))}
    />
    <KpiCard
        title="Gasóleo de automoción"
        value={carb_ult[0]?.gasoleo_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasoleo_real, 2)} €/l"
        period="semana do {carb_ult[0]?.semana_txt}, con impostos, en euros de {carb_ult[0]?.anio_euros} · {formatNumber(carb_ult[0]?.gasoleo, 3)} € a prezo actual"
        direction="positive-down"
        source="Comisión Europea"
        sparklineData={carb_spark_gasoleo.slice(-104).map(d => ({...d, y: d.eur_litro_real}))}
    />
    <KpiCard
        title="Luz dos fogares"
        value={hogares_ult[0]?.elec_es_real}
        formattedValue="{formatNumber(hogares_ult[0]?.elec_es_real, 3)} €/kWh"
        period="{hogares_ult[0]?.semestre}, con impostos, en euros de {hogares_ult[0]?.anio_euros} · UE-27 {formatNumber(hogares_ult[0]?.elec_ue_real, 3)} €"
        direction="positive-down"
        source="Eurostat"
        sparklineData={hogares_es_elec.map(d => ({...d, y: d.eur_kwh_real}))}
    />
</Grid>

### Canto se encareceu cada enerxía

Nivel de prezos de cada produto enerxético fronte ao IPC xeral, coa media de 2019 = 100. Desde entón o IPC xeral subiu un {formatNumber(en_ult.find(d => d.producto === 'IPC general')?.subida_2019, 1)} %; a electricidade un {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.subida_2019, 1)} %, o gasóleo de automoción un {formatNumber(en_ult.find(d => d.producto === 'Gasóleo de automoción')?.subida_2019, 1)} % e a gasolina un {formatNumber(en_ult.find(d => d.producto === 'Gasolina')?.subida_2019, 1)} %.

<LineChart
    data={en_nivel}
    x=mes
    y=indice_2019
    series=producto
    yFmt='0'
    yAxisTitle="índice, media de 2019 = 100"
    startingAtZero={false}
    title="Prezos da enerxía fronte ao IPC xeral (2019 = 100)"
/>

<DataTable data={en_ult} rows=all>
    <Column id=producto title="Produto" />
    <Column id=var_anual title="Variación anual (%)" fmt=num1 />
    <Column id=subida_2019 title="Suba desde 2019 (%)" fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=peso_pct title="Peso na cesta (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Achega á inflación (puntos)" fmt=num2 />
</DataTable>

A electricidade chegou a subir un {formatNumber(en_hitos[0]?.elec_max, 1)} % interanual en {en_hitos[0]?.elec_mes_max}. A maior achega da enerxía á inflación foi en {en_hitos[0]?.contrib_mes_max}: uns {formatNumber(en_hitos[0]?.contrib_max, 1)} puntos dunha inflación xeral do {formatNumber(en_hitos[0]?.general_en_max, 1)} %.

<LineChart
    data={en_var}
    x=mes
    y=var_anual
    series=producto
    yFmt='0"%"'
    yAxisTitle="% vs. mesmo mes do ano anterior"
    title="Variación anual dos prezos da enerxía"
/>

<LineChart
    data={en_contrib}
    x=mes
    y=puntos
    series=serie
    yFmt='0.0'
    yAxisTitle="puntos porcentuales"
    title="Canto achega a enerxía á inflación (aproximado)"
/>

### Carburantes e gasóleo de calefacción, en euros por litro

Prezo medio semanal en surtidor con todos os impostos, segundo o Boletín Petroleiro da Comisión Europea, **descontada a inflación** (euros de {carb_ult[0]?.anio_euros}). A gasolina 95 custa hoxe {formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l en euros de {carb_ult[0]?.anio_euros}, fronte a {formatNumber(carb_ult[0]?.gasolina_real_2019, 2)} € de media en 2019; o seu máximo real foi de {formatNumber(carb_ult[0]?.gasolina_real_max, 2)} € ({carb_ult[0]?.gasolina_real_max_fecha}). O gasóleo de automoción está en {formatNumber(carb_ult[0]?.gasoleo_real, 2)} € (máximo real de {formatNumber(carb_ult[0]?.gasoleo_real_max, 2)} € en {carb_ult[0]?.gasoleo_real_max_fecha}).

<LineChart
    data={carb_es}
    x=fecha
    y=eur_litro_real
    series=producto
    yFmt='0.00" €"'
    yAxisTitle="€/litro (euros de {carb_ult[0]?.anio_euros})"
    startingAtZero={false}
    title="Prezo real dos carburantes en España"
/>

Na última semana, a gasolina 95 custa en España {formatNumber(carb_ult[0]?.gasolina, 3)} €/l fronte a {formatNumber(carb_ult[0]?.gasolina_ue, 3)} € de media na UE, e o gasóleo {formatNumber(carb_ult[0]?.gasoleo, 3)} € fronte a {formatNumber(carb_ult[0]?.gasoleo_ue, 3)} € (prezos do momento, sen deflactar).

<LineChart
    data={carb_ue}
    x=fecha
    y=eur_litro_real
    series=serie
    yFmt='0.00" €"'
    yAxisTitle="€/litro (euros de {carb_ult[0]?.anio_euros})"
    startingAtZero={false}
    title="Gasolina e gasóleo: España fronte á media da UE (prezo real)"
/>

### Electricidade e gas dos fogares, en euros por kWh

Prezo medio por kWh que paga un fogar de consumo medio con todos os impostos (Eurostat, semestral): electricidade para un consumo de 2.500 a 5.000 kWh ao ano e gas natural de 20 a 199 GJ ao ano, **descontada a inflación** (euros de {hogares_ult[0]?.anio_euros}). En {hogares_ult[0]?.semestre} a luz custa en España {formatNumber(hogares_ult[0]?.elec_es, 3)} €/kWh fronte a {formatNumber(hogares_ult[0]?.elec_ue, 3)} € de media na UE, e o gas {formatNumber(hogares_ult[0]?.gas_es, 3)} € fronte a {formatNumber(hogares_ult[0]?.gas_ue, 3)} € (prezos do momento). O prezo real da luz máis alto da serie en España foi o de {hogares_ult[0]?.elec_es_real_max_sem} ({formatNumber(hogares_ult[0]?.elec_es_real_max, 3)} € de {hogares_ult[0]?.anio_euros}).

<LineChart
    data={hogares_elec}
    x=fecha
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh (euros de {hogares_ult[0]?.anio_euros})"
    title="Prezo real da electricidade para os fogares"
/>

<LineChart
    data={hogares_gas}
    x=fecha
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh (euros de {hogares_ult[0]?.anio_euros})"
    title="Prezo real do gas natural para os fogares"
/>

<p class="text-xs text-gray-500">Todos os prezos se deflactan co IPC xeral español para que a comparación entre países non cambie. Os prezos de Eurostat son medias semestrais por kWh que inclúen todos os cargos da factura (enerxía, redes, termo fixo) e impostos.</p>


## Por comunidade autónoma

Inflación anual de cada comunidade en {ccaa[0]?.mes_txt} e suba acumulada dos prezos desde decembro de 2019. Onde máis subiron os prezos desde entón é en {ccaa_resumen[0]?.cmax} (+{formatNumber(ccaa_resumen[0]?.smax / 0.01, 1)} %) e onde menos en {ccaa_resumen[0]?.cmin} (+{formatNumber(ccaa_resumen[0]?.smin / 0.01, 1)} %). O IPC mide canto cambian os prezos en cada comunidade, non se unha é máis cara ca outra.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="var_anual"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fef9c3', '#f87171', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (IPC)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'var_anual', title: 'Inflación anual', fmt: 'pct1'},
        {id: 'subida_desde_2019', title: 'Suba desde dec. 2019', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=var_anual title="Inflación anual" fmt=pct1 contentType=bar barColor="#fecaca" />
    <Column id=subida_desde_2019 title="Suba desde dec. 2019" fmt=pct1 />
</DataTable>

## España fronte á zona euro

Para comparar países úsase o IPC harmonizado (IPCH) de Eurostat, cunha metodoloxía común; en España difire unhas décimas do IPC. En {diferencial.slice(-1)[0]?.mes_txt}, a inflación harmonizada española é do {formatNumber(diferencial.slice(-1)[0]?.es, 1)} % e a da zona euro do {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} %. Desde a media de 2019, os prezos subiron un {formatNumber(diferencial.slice(-1)[0]?.es_2019 - 100, 1)} % en España e un {formatNumber(diferencial.slice(-1)[0]?.ea_2019 - 100, 1)} % na zona euro.

<LineChart
    data={ue}
    x=mes
    y=tasa_anual
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflación harmonizada (IPCH) na zona euro"
/>

<LineChart
    data={ue_nivel}
    x=mes
    y=indice_2019
    series=pais
    yFmt='0.0'
    yAxisTitle="índice, media de 2019 = 100"
    startingAtZero={false}
    title="Nivel de prezos acumulado desde 2019 (IPCH)"
/>

---

**Fontes:** INE, Índice de Prezos de Consumo base 2025: [índices nacionais por grupos ECOICOP (76125)](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [grupos especiais (76130)](https://www.ine.es/jaxiT3/Tabla.htm?t=76130), [taxas por comunidade autónoma (76140)](https://www.ine.es/jaxiT3/Tabla.htm?t=76140) e [ponderacións (76156)](https://www.ine.es/jaxiT3/Tabla.htm?t=76156); enerxía: [subclases ECOICOP (76128)](https://www.ine.es/jaxiT3/Tabla.htm?t=76128) e ponderacións [76159](https://www.ine.es/jaxiT3/Tabla.htm?t=76159) e [76161](https://www.ine.es/jaxiT3/Tabla.htm?t=76161). [Comisión Europea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en) (prezos de carburantes con impostos). Eurostat, prezos de [electricidade (nrg_pc_204)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table) e [gas natural (nrg_pc_202)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_202/default/table) para fogares. [Eurostat, IPCH (prc_hicp_minr)](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table). A contribución de cada grupo aproxímase como peso na cesta pola variación anual do grupo, axustada polo seu nivel de prezos de hai un ano; a suba por comunidade encadea as taxas mensuais publicadas, arredondadas a un decimal.
