---
title: Inflation (CPI)
description: "Inflation in Spain: headline and core CPI, prices by group, the real price of electricity, gas and motor fuels, how much prices have risen since 2008 and 2019, CPI by region and comparison with the euro area."
i18n_origen: 68f3d36e2f60
---

<script>
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
    '/en' || t.ruta AS ruta,
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

# 🛒 Inflation (CPI)

How fast prices are rising in Spain, what is getting more expensive and how much purchasing power has been lost. The INE's **Consumer Price Index (CPI)** measures every month the price of a basket of goods and services that represents household spending; **inflation** is the rise in that index compared with the same month of the previous year. Latest figure: **{ipc_ult[0]?.mes_txt}**.

<Grid cols=4>
    <KpiCard
        title="Inflation"
        value={ipc_ult[0]?.var_anual}
        formattedValue="{formatNumber(ipc_ult[0]?.var_anual, 1)}%"
        period="headline CPI, {ipc_ult[0]?.mes_txt} vs a year earlier"
        change={ipc_ult[0]?.dif_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs previous month"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Core inflation"
        value={ipc_ult[0]?.subyacente}
        formattedValue="{formatNumber(ipc_ult[0]?.subyacente, 1)}%"
        period="excluding energy and unprocessed food, the most volatile prices"
        change={ipc_ult[0]?.dif_sub_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs previous month"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc.filter(d => d.subyacente != null).slice(-60).map(d => d.subyacente)}
    />
    <KpiCard
        title="Prices since 2019"
        value={ipc_ult[0]?.subida_2019}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2019, 1)}%"
        period="what cost €100 on average in 2019 costs €{formatNumber(ipc_ult[0]?.indice_2019, 0)} today"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc.filter(d => d.anio >= 2019).map(d => d.indice_2019)}
    />
    <KpiCard
        title="Gap with the euro area"
        value={diferencial.slice(-1)[0]?.diferencial}
        formattedValue="{diferencial.slice(-1)[0]?.diferencial >= 0 ? '+' : ''}{formatNumber(diferencial.slice(-1)[0]?.diferencial, 1)} pp"
        period="harmonised inflation: Spain {formatNumber(diferencial.slice(-1)[0]?.es, 1)}%, euro area {formatNumber(diferencial.slice(-1)[0]?.ea, 1)}% ({diferencial.slice(-1)[0]?.mes_txt})"
        direction="positive-down"
        source="Eurostat / HICP"
        sparklineData={diferencial.slice(-60).map(d => d.diferencial)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('inflacion')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'inflacion')} />


<Grid cols=4>
    <KpiCard
        title="Energy"
        value={ipc_ult[0]?.energia}
        formattedValue="{ipc_ult[0]?.energia >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.energia, 1)}%"
        period="electricity, gas and motor fuels, {ipc_ult[0]?.mes_txt} vs a year earlier"
        change={ipc_ult[0]?.dif_energia_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs previous month"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc.slice(-60).map(d => d.energia)}
    />
    <KpiCard
        title="Unprocessed food"
        value={ipc_ult[0]?.alimentos_sin_elaborar}
        formattedValue="{ipc_ult[0]?.alimentos_sin_elaborar >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.alimentos_sin_elaborar, 1)}%"
        period="fruit, vegetables, meat, fish, eggs..., vs a year earlier"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc.slice(-60).map(d => d.alimentos_sin_elaborar)}
    />
    <KpiCard
        title="Average annual inflation"
        value={ipc_anual_serie.slice(-1)[0]?.inflacion_media}
        formattedValue="{formatNumber(ipc_anual_serie.slice(-1)[0]?.inflacion_media, 1)}%"
        period="average for {ipc_anual_serie.slice(-1)[0]?.anio} vs {ipc_anual_serie.slice(-1)[0]?.anio - 1}"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc_anual_serie.map(d => d.inflacion_media)}
    />
    <KpiCard
        title="Prices since 2008"
        value={ipc_ult[0]?.subida_2008}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2008, 1)}%"
        period="cumulative CPI rise since the 2008 average"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={ipc.filter(d => d.anio >= 2008).map(d => d.indice_2008)}
    />
</Grid>

## Inflation month by month

The highest inflation since 2002 was in {hitos_ipc[0]?.mes_max} ({formatNumber(hitos_ipc[0]?.max_var, 1)}%) and the lowest in {hitos_ipc[0]?.mes_min} ({formatNumber(hitos_ipc[0]?.min_var, 1)}%). Core inflation leaves out energy and unprocessed food, whose prices swing sharply up and down; that is why it is used to gauge the underlying trend.

<LineChart
    data={general_sub}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% vs same month of previous year"
    title="Headline and core CPI (annual rate)"
/>

<BarChart
    data={ipc_anual_serie}
    x=anio
    y=inflacion_media
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% (annual average)"
    title="Average inflation each year"
/>

## How much prices have risen

The index accumulates the rises: if it stands at 127, the same products cost 27% more than in the reference year. A salary, a pension or savings that have not grown since the 2019 average buy {formatNumber(ipc_ult[0]?.perdida_poder_compra_2019, 1)}% less today. Since 2008 prices have risen by {formatNumber(ipc_ult[0]?.subida_2008, 1)}%. How wages have evolved after inflation is shown in [Wages](/en/economia/salarios).

<LineChart
    data={nivel}
    x=mes
    y=indice
    series=base
    yFmt='0.0'
    yAxisTitle="index"
    startingAtZero={false}
    title="Cumulative price level (headline CPI)"
/>

## What is getting more expensive

Annual rate for each spending group in {grupos_ult[0]?.mes_txt}. The group rising fastest is {grupos_contrib_top[0]?.gmax} ({formatNumber(grupos_contrib_top[0]?.vmax, 1)}%).

<BarChart
    data={grupos_ult}
    x=grupo_corto
    y=var_anual
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Annual change in prices by group ({grupos_ult[0]?.mes_txt})"
/>

How much each group weighs in overall inflation depends on how much it rises and how much households spend on it (its weight in the {grupos_ult[0]?.anio_ponderacion} basket). The biggest contributor right now is {grupos_contrib_top[0]?.g1}: it is up {formatNumber(grupos_contrib_top[0]?.v1, 1)}% and contributes about {formatNumber(grupos_contrib_top[0]?.c1, 1)} of the {formatNumber(ipc_ult[0]?.var_anual, 1)} points of headline inflation (approximate calculation).

<BarChart
    data={grupos_contrib}
    x=grupo_corto
    y=contribucion_aprox
    swapXY=true
    sort=false
    yFmt='0.00'
    title="Approximate contribution of each group to inflation (points)"
/>

<DataTable data={grupos_contrib} rows=all>
    <Column id=grupo_corto title="Group" />
    <Column id=peso_pct title="Weight in the basket (%)" fmt=num1 />
    <Column id=var_anual title="Annual change (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Contribution (points)" fmt=num2 contentType=bar barColor="#fecaca" />
</DataTable>

### Cumulative rise since 2019 by group

Since the 2019 average, the biggest price rise has been in {grupos_2019_resumen[0]?.gmax} (+{formatNumber(grupos_2019_resumen[0]?.smax, 1)}%) and the smallest in {grupos_2019_resumen[0]?.gmin} ({#if grupos_2019_resumen[0]?.smin >= 0}+{/if}{formatNumber(grupos_2019_resumen[0]?.smin, 1)}%). Food costs {formatNumber(grupos_2019_resumen[0]?.alimentos, 1)}% more.

<BarChart
    data={grupos_2019}
    x=grupo_corto
    y=subida
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Price rise since the 2019 average, by group"
/>

<LineChart
    data={grupos_evol}
    x=mes
    y=var_anual
    series=grupo_corto
    yFmt='0.0"%"'
    yAxisTitle="% annual"
    title="Inflation in food, housing and energy, transport and restaurants"
/>

<LineChart
    data={componentes}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% annual"
    title="Inflation by type of product (INE special groups)"
/>

Energy prices rose by as much as {formatNumber(hitos_ipc[0]?.max_energia, 1)}% year on year in {hitos_ipc[0]?.mes_max_energia}.

## ⚡ Energy prices

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
SELECT semana, territorio, producto, eur_litro, eur_litro_real, anio_euros
FROM mother.mercado_energia_carburantes
ORDER BY semana, territorio, producto
```

```sql carb_es
SELECT semana, producto, eur_litro_real
FROM ${carb}
WHERE territorio = 'España' AND producto IN ('Gasolina 95', 'Gasóleo de automoción', 'Gasóleo de calefacción')
ORDER BY semana, producto
```

```sql carb_ue
SELECT semana, territorio || ': ' || producto AS serie, eur_litro_real
FROM ${carb}
WHERE producto IN ('Gasolina 95', 'Gasóleo de automoción') AND semana >= DATE '2015-01-01'
ORDER BY semana, serie
```

```sql carb_ult
SELECT
    max(semana) AS semana,
    strftime(max(semana), '%d/%m/%Y') AS semana_txt,
    max(anio_euros) AS anio_euros,
    max(eur_litro) FILTER (WHERE territorio = 'España' AND producto = 'Gasolina 95' AND semana = (SELECT max(semana) FROM ${carb})) AS gasolina,
    max(eur_litro) FILTER (WHERE territorio = 'España' AND producto = 'Gasóleo de automoción' AND semana = (SELECT max(semana) FROM ${carb})) AS gasoleo,
    max(eur_litro) FILTER (WHERE territorio = 'España' AND producto = 'Gasóleo de calefacción' AND semana = (SELECT max(semana) FROM ${carb})) AS calefaccion,
    max(eur_litro) FILTER (WHERE territorio = 'Media UE' AND producto = 'Gasolina 95' AND semana = (SELECT max(semana) FROM ${carb})) AS gasolina_ue,
    max(eur_litro) FILTER (WHERE territorio = 'Media UE' AND producto = 'Gasóleo de automoción' AND semana = (SELECT max(semana) FROM ${carb})) AS gasoleo_ue,
    max(eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasolina 95') AS gasolina_real_max,
    strftime(arg_max(semana, eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasolina 95'), '%m/%Y') AS gasolina_real_max_fecha,
    max(eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasóleo de automoción') AS gasoleo_real_max,
    strftime(arg_max(semana, eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasóleo de automoción'), '%m/%Y') AS gasoleo_real_max_fecha,
    avg(eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasolina 95' AND year(semana) = 2019) AS gasolina_real_2019,
    avg(eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasóleo de automoción' AND year(semana) = 2019) AS gasoleo_real_2019,
    max(eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasolina 95' AND semana = (SELECT max(semana) FROM ${carb})) AS gasolina_real,
    max(eur_litro_real) FILTER (WHERE territorio = 'España' AND producto = 'Gasóleo de automoción' AND semana = (SELECT max(semana) FROM ${carb})) AS gasoleo_real
FROM ${carb}
```

```sql carb_spark_gasolina
SELECT semana, eur_litro_real FROM ${carb} WHERE territorio = 'España' AND producto = 'Gasolina 95' ORDER BY semana
```

```sql carb_spark_gasoleo
SELECT semana, eur_litro_real FROM ${carb} WHERE territorio = 'España' AND producto = 'Gasóleo de automoción' ORDER BY semana
```

```sql hogares
SELECT semestre_inicio, semestre, energia, pais, eur_kwh, eur_kwh_real, anio_euros
FROM mother.mercado_energia_hogares
ORDER BY semestre_inicio, energia, pais
```

```sql hogares_elec
SELECT semestre_inicio, pais, eur_kwh_real FROM ${hogares}
WHERE energia = 'Electricidad' AND pais IN ('España', 'UE-27', 'Alemania', 'Francia', 'Italia', 'Portugal')
ORDER BY semestre_inicio, pais
```

```sql hogares_gas
SELECT semestre_inicio, pais, eur_kwh_real FROM ${hogares}
WHERE energia = 'Gas natural' AND pais IN ('España', 'UE-27', 'Alemania', 'Francia', 'Italia', 'Portugal')
ORDER BY semestre_inicio, pais
```

```sql hogares_es_elec
SELECT semestre_inicio, eur_kwh_real FROM ${hogares} WHERE energia = 'Electricidad' AND pais = 'España' ORDER BY semestre_inicio
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

Energy prices have been one of the keys to inflation in recent years. In {en_ult[0]?.mes_txt}, energy is up {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.var_anual, 1)}% year on year and contributes about {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.contribucion_aprox, 1)} of the {formatNumber(ipc_ult[0]?.var_anual, 1)} points of headline inflation, although it accounts for {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.peso_pct, 1)}% of the basket. Wholesale electricity prices and real-time demand are in [Live electricity](/en/energia-clima/directo) and [Electricity records](/en/energia-clima/records).

<Grid cols=4>
    <KpiCard
        title="Electricity (CPI)"
        value={en_ult.find(d => d.producto === 'Electricidad')?.var_anual}
        formattedValue="{en_ult.find(d => d.producto === 'Electricidad')?.var_anual >= 0 ? '+' : ''}{formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.var_anual, 1)}%"
        period="vs a year earlier, {en_ult[0]?.mes_txt} · {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.indice_2019, 0)} with 2019 = 100"
        direction="positive-down"
        source="INE / CPI"
        sparklineData={en_electricidad.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Petrol (95 octane)"
        value={carb_ult[0]?.gasolina_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l"
        period="week of {carb_ult[0]?.semana_txt}, including taxes, in {carb_ult[0]?.anio_euros} euros · €{formatNumber(carb_ult[0]?.gasolina, 3)} at current prices"
        direction="positive-down"
        source="European Commission"
        sparklineData={carb_spark_gasolina.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Diesel"
        value={carb_ult[0]?.gasoleo_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasoleo_real, 2)} €/l"
        period="week of {carb_ult[0]?.semana_txt}, including taxes, in {carb_ult[0]?.anio_euros} euros · €{formatNumber(carb_ult[0]?.gasoleo, 3)} at current prices"
        direction="positive-down"
        source="European Commission"
        sparklineData={carb_spark_gasoleo.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Household electricity"
        value={hogares_ult[0]?.elec_es_real}
        formattedValue="{formatNumber(hogares_ult[0]?.elec_es_real, 3)} €/kWh"
        period="{hogares_ult[0]?.semestre}, including taxes, in {hogares_ult[0]?.anio_euros} euros · EU-27 €{formatNumber(hogares_ult[0]?.elec_ue_real, 3)}"
        direction="positive-down"
        source="Eurostat"
        sparklineData={hogares_es_elec.map(d => d.eur_kwh_real)}
    />
</Grid>

### How much more each form of energy costs

Price level of each energy product compared with headline CPI, with the 2019 average = 100. Since then headline CPI has risen by {formatNumber(en_ult.find(d => d.producto === 'IPC general')?.subida_2019, 1)}%; electricity by {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.subida_2019, 1)}%, diesel by {formatNumber(en_ult.find(d => d.producto === 'Gasóleo de automoción')?.subida_2019, 1)}% and petrol by {formatNumber(en_ult.find(d => d.producto === 'Gasolina')?.subida_2019, 1)}%.

<LineChart
    data={en_nivel}
    x=mes
    y=indice_2019
    series=producto
    yFmt='0'
    yAxisTitle="index, 2019 average = 100"
    startingAtZero={false}
    title="Energy prices compared with headline CPI (2019 = 100)"
/>

<DataTable data={en_ult} rows=all>
    <Column id=producto title="Product" />
    <Column id=var_anual title="Annual change (%)" fmt=num1 />
    <Column id=subida_2019 title="Rise since 2019 (%)" fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=peso_pct title="Weight in the basket (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Contribution to inflation (points)" fmt=num2 />
</DataTable>

Electricity prices rose by as much as {formatNumber(en_hitos[0]?.elec_max, 1)}% year on year in {en_hitos[0]?.elec_mes_max}. Energy's largest contribution to inflation came in {en_hitos[0]?.contrib_mes_max}: about {formatNumber(en_hitos[0]?.contrib_max, 1)} points out of headline inflation of {formatNumber(en_hitos[0]?.general_en_max, 1)}%.

<LineChart
    data={en_var}
    x=mes
    y=var_anual
    series=producto
    yFmt='0"%"'
    yAxisTitle="% vs same month of previous year"
    title="Annual change in energy prices"
/>

<LineChart
    data={en_contrib}
    x=mes
    y=puntos
    series=serie
    yFmt='0.0'
    yAxisTitle="percentage points"
    title="How much energy contributes to inflation (approximate)"
/>

### Motor fuels and heating oil, in euros per litre

Average weekly pump price including all taxes, according to the European Commission's Weekly Oil Bulletin, **adjusted for inflation** ({carb_ult[0]?.anio_euros} euros). Petrol (95 octane) costs {formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l today in {carb_ult[0]?.anio_euros} euros, compared with an average of €{formatNumber(carb_ult[0]?.gasolina_real_2019, 2)} in 2019; its real-terms peak was €{formatNumber(carb_ult[0]?.gasolina_real_max, 2)} ({carb_ult[0]?.gasolina_real_max_fecha}). Diesel stands at €{formatNumber(carb_ult[0]?.gasoleo_real, 2)} (real-terms peak of €{formatNumber(carb_ult[0]?.gasoleo_real_max, 2)} in {carb_ult[0]?.gasoleo_real_max_fecha}).

<LineChart
    data={carb_es}
    x=semana
    y=eur_litro_real
    series=producto
    yFmt='0.00" €"'
    yAxisTitle="€/litre ({carb_ult[0]?.anio_euros} euros)"
    startingAtZero={false}
    title="Real price of motor fuels in Spain"
/>

In the latest week, petrol (95 octane) costs {formatNumber(carb_ult[0]?.gasolina, 3)} €/l in Spain compared with an EU average of €{formatNumber(carb_ult[0]?.gasolina_ue, 3)}, and diesel €{formatNumber(carb_ult[0]?.gasoleo, 3)} compared with €{formatNumber(carb_ult[0]?.gasoleo_ue, 3)} (current prices, not deflated).

<LineChart
    data={carb_ue}
    x=semana
    y=eur_litro_real
    series=serie
    yFmt='0.00" €"'
    yAxisTitle="€/litre ({carb_ult[0]?.anio_euros} euros)"
    startingAtZero={false}
    title="Petrol and diesel: Spain compared with the EU average (real price)"
/>

### Household electricity and gas, in euros per kWh

Average price per kWh paid by a household with average consumption, including all taxes (Eurostat, half-yearly): electricity for consumption of 2,500 to 5,000 kWh a year and natural gas for 20 to 199 GJ a year, **adjusted for inflation** ({hogares_ult[0]?.anio_euros} euros). In {hogares_ult[0]?.semestre}, electricity costs {formatNumber(hogares_ult[0]?.elec_es, 3)} €/kWh in Spain compared with an EU average of €{formatNumber(hogares_ult[0]?.elec_ue, 3)}, and gas €{formatNumber(hogares_ult[0]?.gas_es, 3)} compared with €{formatNumber(hogares_ult[0]?.gas_ue, 3)} (current prices). The highest real price of electricity in the series in Spain was in {hogares_ult[0]?.elec_es_real_max_sem} (€{formatNumber(hogares_ult[0]?.elec_es_real_max, 3)} in {hogares_ult[0]?.anio_euros} euros).

<LineChart
    data={hogares_elec}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh ({hogares_ult[0]?.anio_euros} euros)"
    title="Real price of electricity for households"
/>

<LineChart
    data={hogares_gas}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh ({hogares_ult[0]?.anio_euros} euros)"
    title="Real price of natural gas for households"
/>

<p class="text-xs text-gray-500">All prices are deflated using the Spanish headline CPI so that the comparison between countries is not altered. Eurostat prices are half-yearly averages per kWh that include all charges on the bill (energy, networks, fixed charge) and taxes.</p>


## By region (autonomous community)

Annual inflation in each region in {ccaa[0]?.mes_txt} and cumulative price rise since December 2019. Prices have risen most since then in {ccaa_resumen[0]?.cmax} (+{formatNumber(ccaa_resumen[0]?.smax / 0.01, 1)}%) and least in {ccaa_resumen[0]?.cmin} (+{formatNumber(ccaa_resumen[0]?.smin / 0.01, 1)}%). The CPI measures how much prices change in each region, not whether one region is more expensive than another.

<AreaMap
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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE (CPI)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'var_anual', title: 'Annual inflation', fmt: 'pct1'},
        {id: 'subida_desde_2019', title: 'Rise since Dec. 2019', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=var_anual title="Annual inflation" fmt=pct1 contentType=bar barColor="#fecaca" />
    <Column id=subida_desde_2019 title="Rise since Dec. 2019" fmt=pct1 />
</DataTable>

## Spain compared with the euro area

To compare countries, Eurostat's Harmonised Index of Consumer Prices (HICP) is used, with a common methodology; in Spain it differs from the CPI by a few tenths of a point. In {diferencial.slice(-1)[0]?.mes_txt}, Spanish harmonised inflation is {formatNumber(diferencial.slice(-1)[0]?.es, 1)}% and euro-area inflation {formatNumber(diferencial.slice(-1)[0]?.ea, 1)}%. Since the 2019 average, prices have risen by {formatNumber(diferencial.slice(-1)[0]?.es_2019 - 100, 1)}% in Spain and by {formatNumber(diferencial.slice(-1)[0]?.ea_2019 - 100, 1)}% in the euro area.

<LineChart
    data={ue}
    x=mes
    y=tasa_anual
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% annual"
    title="Harmonised inflation (HICP) in the euro area"
/>

<LineChart
    data={ue_nivel}
    x=mes
    y=indice_2019
    series=pais
    yFmt='0.0'
    yAxisTitle="index, 2019 average = 100"
    startingAtZero={false}
    title="Cumulative price level since 2019 (HICP)"
/>

---

**Sources:** INE, Consumer Price Index base 2025: [national indices by ECOICOP group (76125)](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [special groups (76130)](https://www.ine.es/jaxiT3/Tabla.htm?t=76130), [rates by autonomous community (76140)](https://www.ine.es/jaxiT3/Tabla.htm?t=76140) and [weights (76156)](https://www.ine.es/jaxiT3/Tabla.htm?t=76156); energy: [ECOICOP subclasses (76128)](https://www.ine.es/jaxiT3/Tabla.htm?t=76128) and weights [76159](https://www.ine.es/jaxiT3/Tabla.htm?t=76159) and [76161](https://www.ine.es/jaxiT3/Tabla.htm?t=76161). [European Commission, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en) (motor fuel prices including taxes). Eurostat, household prices for [electricity (nrg_pc_204)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table) and [natural gas (nrg_pc_202)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_202/default/table). [Eurostat, HICP (prc_hicp_minr)](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table). The contribution of each group is approximated as its weight in the basket times the group's annual change, adjusted for its price level a year earlier; the rise by region chains the published monthly rates, rounded to one decimal place.
