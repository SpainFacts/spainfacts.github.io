---
title: Inflación (IPC)
description: "Inflación en España: IPC general y subyacente, precios por grupos, precio real de la luz, el gas y los carburantes, cuánto han subido los precios desde 2008 y 2019, IPC por comunidad y comparación con la zona euro."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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
    t.ruta,
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

Cuánto suben los precios en España, qué se encarece más y cuánto poder de compra se ha perdido. El **Índice de Precios de Consumo (IPC)** del INE mide cada mes el precio de una cesta de bienes y servicios que representa el gasto de los hogares; la **inflación** es la subida de ese índice respecto al mismo mes del año anterior. Último dato: **{ipc_ult[0]?.mes_txt}**.

<Grid cols=4>
    <KpiCard
        title="Inflación"
        value={ipc_ult[0]?.var_anual}
        formattedValue="{formatNumber(ipc_ult[0]?.var_anual, 1)} %"
        period="IPC general, {ipc_ult[0]?.mes_txt} vs un año antes"
        change={ipc_ult[0]?.dif_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs el mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Inflación subyacente"
        value={ipc_ult[0]?.subyacente}
        formattedValue="{formatNumber(ipc_ult[0]?.subyacente, 1)} %"
        period="sin energía ni alimentos sin elaborar, los precios más volátiles"
        change={ipc_ult[0]?.dif_sub_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs el mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.subyacente != null).slice(-60).map(d => d.subyacente)}
    />
    <KpiCard
        title="Precios desde 2019"
        value={ipc_ult[0]?.subida_2019}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2019, 1)} %"
        period="lo que costaba 100 € de media en 2019 cuesta hoy {formatNumber(ipc_ult[0]?.indice_2019, 0)} €"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.anio >= 2019).map(d => d.indice_2019)}
    />
    <KpiCard
        title="Diferencia con la zona euro"
        value={diferencial.slice(-1)[0]?.diferencial}
        formattedValue="{diferencial.slice(-1)[0]?.diferencial >= 0 ? '+' : ''}{formatNumber(diferencial.slice(-1)[0]?.diferencial, 1)} pp"
        period="inflación armonizada: España {formatNumber(diferencial.slice(-1)[0]?.es, 1)} %, zona euro {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} % ({diferencial.slice(-1)[0]?.mes_txt})"
        direction="positive-down"
        source="Eurostat / IPCA"
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
        title="Energía"
        value={ipc_ult[0]?.energia}
        formattedValue="{ipc_ult[0]?.energia >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.energia, 1)} %"
        period="electricidad, gas y carburantes, {ipc_ult[0]?.mes_txt} vs un año antes"
        change={ipc_ult[0]?.dif_energia_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="vs el mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => d.energia)}
    />
    <KpiCard
        title="Alimentos sin elaborar"
        value={ipc_ult[0]?.alimentos_sin_elaborar}
        formattedValue="{ipc_ult[0]?.alimentos_sin_elaborar >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.alimentos_sin_elaborar, 1)} %"
        period="fruta, verdura, carne, pescado, huevos..., vs un año antes"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => d.alimentos_sin_elaborar)}
    />
    <KpiCard
        title="Inflación media anual"
        value={ipc_anual_serie.slice(-1)[0]?.inflacion_media}
        formattedValue="{formatNumber(ipc_anual_serie.slice(-1)[0]?.inflacion_media, 1)} %"
        period="media de {ipc_anual_serie.slice(-1)[0]?.anio} frente a la de {ipc_anual_serie.slice(-1)[0]?.anio - 1}"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc_anual_serie.map(d => d.inflacion_media)}
    />
    <KpiCard
        title="Precios desde 2008"
        value={ipc_ult[0]?.subida_2008}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2008, 1)} %"
        period="subida acumulada del IPC desde la media de 2008"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.anio >= 2008).map(d => d.indice_2008)}
    />
</Grid>

## La inflación mes a mes

La inflación más alta desde 2002 fue la de {hitos_ipc[0]?.mes_max} ({formatNumber(hitos_ipc[0]?.max_var, 1)} %) y la más baja la de {hitos_ipc[0]?.mes_min} ({formatNumber(hitos_ipc[0]?.min_var, 1)} %). La subyacente deja fuera la energía y los alimentos sin elaborar, cuyos precios suben y bajan con fuerza; por eso se usa para ver la tendencia de fondo.

<LineChart
    data={general_sub}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% vs mismo mes del año anterior"
    title="IPC general y subyacente (tasa anual)"
/>

<BarChart
    data={ipc_anual_serie}
    x=anio
    y=inflacion_media
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% (media anual)"
    title="Inflación media de cada año"
/>

## Cuánto han subido los precios

El índice acumula las subidas: si vale 127, los mismos productos cuestan un 27 % más que en el año de referencia. Un sueldo, una pensión o unos ahorros que no hayan crecido desde la media de 2019 compran hoy un {formatNumber(ipc_ult[0]?.perdida_poder_compra_2019, 1)} % menos. Desde 2008 los precios han subido un {formatNumber(ipc_ult[0]?.subida_2008, 1)} %. La evolución de los sueldos descontada la inflación está en [Salarios](/economia/salarios).

<LineChart
    data={nivel}
    x=mes
    y=indice
    series=base
    yFmt='0.0'
    yAxisTitle="índice"
    startingAtZero={false}
    title="Nivel de precios acumulado (IPC general)"
/>

## Qué se encarece más

Tasa anual de cada grupo de gasto en {grupos_ult[0]?.mes_txt}. El grupo que más sube es {grupos_contrib_top[0]?.gmax} ({formatNumber(grupos_contrib_top[0]?.vmax, 1)} %).

<BarChart
    data={grupos_ult}
    x=grupo_corto
    y=var_anual
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Variación anual de los precios por grupo ({grupos_ult[0]?.mes_txt})"
/>

Lo que pesa en la inflación total depende de cuánto sube cada grupo y de cuánto gastan en él los hogares (su peso en la cesta de {grupos_ult[0]?.anio_ponderacion}). El que más aporta ahora es {grupos_contrib_top[0]?.g1}: sube un {formatNumber(grupos_contrib_top[0]?.v1, 1)} % y aporta unos {formatNumber(grupos_contrib_top[0]?.c1, 1)} puntos de los {formatNumber(ipc_ult[0]?.var_anual, 1)} de la inflación general (cálculo aproximado).

<BarChart
    data={grupos_contrib}
    x=grupo_corto
    y=contribucion_aprox
    swapXY=true
    sort=false
    yFmt='0.00'
    title="Contribución aproximada de cada grupo a la inflación (puntos)"
/>

<DataTable data={grupos_contrib} rows=all>
    <Column id=grupo_corto title="Grupo" />
    <Column id=peso_pct title="Peso en la cesta (%)" fmt=num1 />
    <Column id=var_anual title="Variación anual (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Contribución (puntos)" fmt=num2 contentType=bar barColor="#fecaca" />
</DataTable>

### Subida acumulada desde 2019 por grupo

Desde la media de 2019, lo que más se ha encarecido es {grupos_2019_resumen[0]?.gmax} (+{formatNumber(grupos_2019_resumen[0]?.smax, 1)} %) y lo que menos {grupos_2019_resumen[0]?.gmin} ({#if grupos_2019_resumen[0]?.smin >= 0}+{/if}{formatNumber(grupos_2019_resumen[0]?.smin, 1)} %). Los alimentos cuestan un {formatNumber(grupos_2019_resumen[0]?.alimentos, 1)} % más.

<BarChart
    data={grupos_2019}
    x=grupo_corto
    y=subida
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Subida de precios desde la media de 2019, por grupo"
/>

<LineChart
    data={grupos_evol}
    x=mes
    y=var_anual
    series=grupo_corto
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflación de alimentos, vivienda y energía, transporte y restaurantes"
/>

<LineChart
    data={componentes}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflación por tipo de producto (grupos especiales del INE)"
/>

La energía llegó a subir un {formatNumber(hitos_ipc[0]?.max_energia, 1)} % interanual en {hitos_ipc[0]?.mes_max_energia}.

## ⚡ Precio de la energía

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

El precio de la energía ha sido una de las claves de la inflación de los últimos años. En {en_ult[0]?.mes_txt}, la energía sube un {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.var_anual, 1)} % interanual y aporta unos {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.contribucion_aprox, 1)} puntos de los {formatNumber(ipc_ult[0]?.var_anual, 1)} de la inflación general, aunque pesa un {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.peso_pct, 1)} % de la cesta. Los precios mayoristas de la electricidad y la demanda en tiempo real están en [Electricidad en directo](/energia-clima/directo) y [Récords eléctricos](/energia-clima/records).

<Grid cols=4>
    <KpiCard
        title="Electricidad (IPC)"
        value={en_ult.find(d => d.producto === 'Electricidad')?.var_anual}
        formattedValue="{en_ult.find(d => d.producto === 'Electricidad')?.var_anual >= 0 ? '+' : ''}{formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.var_anual, 1)} %"
        period="vs un año antes, {en_ult[0]?.mes_txt} · {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.indice_2019, 0)} si 2019 = 100"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={en_electricidad.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Gasolina 95"
        value={carb_ult[0]?.gasolina_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l"
        period="semana del {carb_ult[0]?.semana_txt}, con impuestos, en euros de {carb_ult[0]?.anio_euros} · {formatNumber(carb_ult[0]?.gasolina, 3)} € a precio actual"
        direction="positive-down"
        source="Comisión Europea"
        sparklineData={carb_spark_gasolina.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Gasóleo de automoción"
        value={carb_ult[0]?.gasoleo_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasoleo_real, 2)} €/l"
        period="semana del {carb_ult[0]?.semana_txt}, con impuestos, en euros de {carb_ult[0]?.anio_euros} · {formatNumber(carb_ult[0]?.gasoleo, 3)} € a precio actual"
        direction="positive-down"
        source="Comisión Europea"
        sparklineData={carb_spark_gasoleo.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Luz de los hogares"
        value={hogares_ult[0]?.elec_es_real}
        formattedValue="{formatNumber(hogares_ult[0]?.elec_es_real, 3)} €/kWh"
        period="{hogares_ult[0]?.semestre}, con impuestos, en euros de {hogares_ult[0]?.anio_euros} · UE-27 {formatNumber(hogares_ult[0]?.elec_ue_real, 3)} €"
        direction="positive-down"
        source="Eurostat"
        sparklineData={hogares_es_elec.map(d => d.eur_kwh_real)}
    />
</Grid>

### Cuánto se ha encarecido cada energía

Nivel de precios de cada producto energético frente al IPC general, con la media de 2019 = 100. Desde entonces el IPC general ha subido un {formatNumber(en_ult.find(d => d.producto === 'IPC general')?.subida_2019, 1)} %; la electricidad un {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.subida_2019, 1)} %, el gasóleo de automoción un {formatNumber(en_ult.find(d => d.producto === 'Gasóleo de automoción')?.subida_2019, 1)} % y la gasolina un {formatNumber(en_ult.find(d => d.producto === 'Gasolina')?.subida_2019, 1)} %.

<LineChart
    data={en_nivel}
    x=mes
    y=indice_2019
    series=producto
    yFmt='0'
    yAxisTitle="índice, media de 2019 = 100"
    startingAtZero={false}
    title="Precios de la energía frente al IPC general (2019 = 100)"
/>

<DataTable data={en_ult} rows=all>
    <Column id=producto title="Producto" />
    <Column id=var_anual title="Variación anual (%)" fmt=num1 />
    <Column id=subida_2019 title="Subida desde 2019 (%)" fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=peso_pct title="Peso en la cesta (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Aporte a la inflación (puntos)" fmt=num2 />
</DataTable>

La electricidad llegó a subir un {formatNumber(en_hitos[0]?.elec_max, 1)} % interanual en {en_hitos[0]?.elec_mes_max}. El mayor aporte de la energía a la inflación fue en {en_hitos[0]?.contrib_mes_max}: unos {formatNumber(en_hitos[0]?.contrib_max, 1)} puntos de una inflación general del {formatNumber(en_hitos[0]?.general_en_max, 1)} %.

<LineChart
    data={en_var}
    x=mes
    y=var_anual
    series=producto
    yFmt='0"%"'
    yAxisTitle="% vs mismo mes del año anterior"
    title="Variación anual de los precios de la energía"
/>

<LineChart
    data={en_contrib}
    x=mes
    y=puntos
    series=serie
    yFmt='0.0'
    yAxisTitle="puntos porcentuales"
    title="Cuánto aporta la energía a la inflación (aproximado)"
/>

### Carburantes y gasóleo de calefacción, en euros por litro

Precio medio semanal en surtidor con todos los impuestos, según el Boletín Petrolero de la Comisión Europea, **descontada la inflación** (euros de {carb_ult[0]?.anio_euros}). La gasolina 95 cuesta hoy {formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l en euros de {carb_ult[0]?.anio_euros}, frente a {formatNumber(carb_ult[0]?.gasolina_real_2019, 2)} € de media en 2019; su máximo real fue de {formatNumber(carb_ult[0]?.gasolina_real_max, 2)} € ({carb_ult[0]?.gasolina_real_max_fecha}). El gasóleo de automoción está en {formatNumber(carb_ult[0]?.gasoleo_real, 2)} € (máximo real de {formatNumber(carb_ult[0]?.gasoleo_real_max, 2)} € en {carb_ult[0]?.gasoleo_real_max_fecha}).

<LineChart
    data={carb_es}
    x=semana
    y=eur_litro_real
    series=producto
    yFmt='0.00" €"'
    yAxisTitle="€/litro (euros de {carb_ult[0]?.anio_euros})"
    startingAtZero={false}
    title="Precio real de los carburantes en España"
/>

En la última semana, la gasolina 95 cuesta en España {formatNumber(carb_ult[0]?.gasolina, 3)} €/l frente a {formatNumber(carb_ult[0]?.gasolina_ue, 3)} € de media en la UE, y el gasóleo {formatNumber(carb_ult[0]?.gasoleo, 3)} € frente a {formatNumber(carb_ult[0]?.gasoleo_ue, 3)} € (precios del momento, sin deflactar).

<LineChart
    data={carb_ue}
    x=semana
    y=eur_litro_real
    series=serie
    yFmt='0.00" €"'
    yAxisTitle="€/litro (euros de {carb_ult[0]?.anio_euros})"
    startingAtZero={false}
    title="Gasolina y gasóleo: España frente a la media de la UE (precio real)"
/>

### Electricidad y gas de los hogares, en euros por kWh

Precio medio por kWh que paga un hogar de consumo medio con todos los impuestos (Eurostat, semestral): electricidad para un consumo de 2.500 a 5.000 kWh al año y gas natural de 20 a 199 GJ al año, **descontada la inflación** (euros de {hogares_ult[0]?.anio_euros}). En {hogares_ult[0]?.semestre} la luz cuesta en España {formatNumber(hogares_ult[0]?.elec_es, 3)} €/kWh frente a {formatNumber(hogares_ult[0]?.elec_ue, 3)} € de media en la UE, y el gas {formatNumber(hogares_ult[0]?.gas_es, 3)} € frente a {formatNumber(hogares_ult[0]?.gas_ue, 3)} € (precios del momento). El precio real de la luz más alto de la serie en España fue el de {hogares_ult[0]?.elec_es_real_max_sem} ({formatNumber(hogares_ult[0]?.elec_es_real_max, 3)} € de {hogares_ult[0]?.anio_euros}).

<LineChart
    data={hogares_elec}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh (euros de {hogares_ult[0]?.anio_euros})"
    title="Precio real de la electricidad para los hogares"
/>

<LineChart
    data={hogares_gas}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh (euros de {hogares_ult[0]?.anio_euros})"
    title="Precio real del gas natural para los hogares"
/>

<p class="text-xs text-gray-500">Todos los precios se deflactan con el IPC general español para que la comparación entre países no cambie. Los precios de Eurostat son medias semestrales por kWh que incluyen todos los cargos de la factura (energía, redes, término fijo) e impuestos.</p>


## Por comunidad autónoma

Inflación anual de cada comunidad en {ccaa[0]?.mes_txt} y subida acumulada de los precios desde diciembre de 2019. Donde más han subido los precios desde entonces es en {ccaa_resumen[0]?.cmax} (+{formatNumber(ccaa_resumen[0]?.smax / 0.01, 1)} %) y donde menos en {ccaa_resumen[0]?.cmin} (+{formatNumber(ccaa_resumen[0]?.smin / 0.01, 1)} %). El IPC mide cuánto cambian los precios en cada comunidad, no si una es más cara que otra.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (IPC)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'var_anual', title: 'Inflación anual', fmt: 'pct1'},
        {id: 'subida_desde_2019', title: 'Subida desde dic. 2019', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=var_anual title="Inflación anual" fmt=pct1 contentType=bar barColor="#fecaca" />
    <Column id=subida_desde_2019 title="Subida desde dic. 2019" fmt=pct1 />
</DataTable>

## España frente a la zona euro

Para comparar países se usa el IPC armonizado (IPCA) de Eurostat, con una metodología común; en España difiere unas décimas del IPC. En {diferencial.slice(-1)[0]?.mes_txt}, la inflación armonizada española es del {formatNumber(diferencial.slice(-1)[0]?.es, 1)} % y la de la zona euro del {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} %. Desde la media de 2019, los precios han subido un {formatNumber(diferencial.slice(-1)[0]?.es_2019 - 100, 1)} % en España y un {formatNumber(diferencial.slice(-1)[0]?.ea_2019 - 100, 1)} % en la zona euro.

<LineChart
    data={ue}
    x=mes
    y=tasa_anual
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflación armonizada (IPCA) en la zona euro"
/>

<LineChart
    data={ue_nivel}
    x=mes
    y=indice_2019
    series=pais
    yFmt='0.0'
    yAxisTitle="índice, media de 2019 = 100"
    startingAtZero={false}
    title="Nivel de precios acumulado desde 2019 (IPCA)"
/>

---

**Fuentes:** INE, Índice de Precios de Consumo base 2025: [índices nacionales por grupos ECOICOP (76125)](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [grupos especiales (76130)](https://www.ine.es/jaxiT3/Tabla.htm?t=76130), [tasas por comunidad autónoma (76140)](https://www.ine.es/jaxiT3/Tabla.htm?t=76140) y [ponderaciones (76156)](https://www.ine.es/jaxiT3/Tabla.htm?t=76156); energía: [subclases ECOICOP (76128)](https://www.ine.es/jaxiT3/Tabla.htm?t=76128) y ponderaciones [76159](https://www.ine.es/jaxiT3/Tabla.htm?t=76159) y [76161](https://www.ine.es/jaxiT3/Tabla.htm?t=76161). [Comisión Europea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en) (precios de carburantes con impuestos). Eurostat, precios de [electricidad (nrg_pc_204)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table) y [gas natural (nrg_pc_202)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_202/default/table) para hogares. [Eurostat, IPCA (prc_hicp_minr)](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table). La contribución de cada grupo se aproxima como peso en la cesta por la variación anual del grupo, ajustada por su nivel de precios de hace un año; la subida por comunidad encadena las tasas mensuales publicadas, redondeadas a un decimal.
