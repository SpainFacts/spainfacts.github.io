---
title: Inflació (IPC)
description: "Inflació a Espanya: IPC general i subjacent, preus per grups, preu real de la llum, el gas i els carburants, quant han pujat els preus des del 2008 i el 2019, IPC per comunitat i comparació amb la zona euro."
i18n_origen: c732f0a70537
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
    '/ca' || t.ruta AS ruta,
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

# 🛒 Inflació (IPC)

Quant pugen els preus a Espanya, què s'encareix més i quant poder de compra s'ha perdut. L'**Índex de Preus de Consum (IPC)** de l'INE mesura cada mes el preu d'una cistella de béns i serveis que representa la despesa de les llars; la **inflació** és la pujada d'aquest índex respecte al mateix mes de l'any anterior. Última dada: **{ipc_ult[0]?.mes_txt}**.

<Grid cols=4>
    <KpiCard
        title="Inflació"
        value={ipc_ult[0]?.var_anual}
        formattedValue="{formatNumber(ipc_ult[0]?.var_anual, 1)} %"
        period="IPC general, {ipc_ult[0]?.mes_txt} respecte a un any abans"
        change={ipc_ult[0]?.dif_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte al mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Inflació subjacent"
        value={ipc_ult[0]?.subyacente}
        formattedValue="{formatNumber(ipc_ult[0]?.subyacente, 1)} %"
        period="sense energia ni aliments sense elaborar, els preus més volàtils"
        change={ipc_ult[0]?.dif_sub_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte al mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.subyacente != null).slice(-60).map(d => d.subyacente)}
    />
    <KpiCard
        title="Preus des del 2019"
        value={ipc_ult[0]?.subida_2019}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2019, 1)} %"
        period="el que costava 100 € de mitjana el 2019 avui costa {formatNumber(ipc_ult[0]?.indice_2019, 0)} €"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.anio >= 2019).map(d => d.indice_2019)}
    />
    <KpiCard
        title="Diferència amb la zona euro"
        value={diferencial.slice(-1)[0]?.diferencial}
        formattedValue="{diferencial.slice(-1)[0]?.diferencial >= 0 ? '+' : ''}{formatNumber(diferencial.slice(-1)[0]?.diferencial, 1)} pp"
        period="inflació harmonitzada: Espanya {formatNumber(diferencial.slice(-1)[0]?.es, 1)} %, zona euro {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} % ({diferencial.slice(-1)[0]?.mes_txt})"
        direction="positive-down"
        source="Eurostat / IPCH"
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
        title="Energia"
        value={ipc_ult[0]?.energia}
        formattedValue="{ipc_ult[0]?.energia >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.energia, 1)} %"
        period="electricitat, gas i carburants, {ipc_ult[0]?.mes_txt} respecte a un any abans"
        change={ipc_ult[0]?.dif_energia_mes?.toFixed(1)}
        changeUnit=" pp"
        changePeriod="respecte al mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => d.energia)}
    />
    <KpiCard
        title="Aliments sense elaborar"
        value={ipc_ult[0]?.alimentos_sin_elaborar}
        formattedValue="{ipc_ult[0]?.alimentos_sin_elaborar >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.alimentos_sin_elaborar, 1)} %"
        period="fruita, verdura, carn, peix, ous..., respecte a un any abans"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.slice(-60).map(d => d.alimentos_sin_elaborar)}
    />
    <KpiCard
        title="Inflació mitjana anual"
        value={ipc_anual_serie.slice(-1)[0]?.inflacion_media}
        formattedValue="{formatNumber(ipc_anual_serie.slice(-1)[0]?.inflacion_media, 1)} %"
        period="mitjana del {ipc_anual_serie.slice(-1)[0]?.anio} respecte a la del {ipc_anual_serie.slice(-1)[0]?.anio - 1}"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc_anual_serie.map(d => d.inflacion_media)}
    />
    <KpiCard
        title="Preus des del 2008"
        value={ipc_ult[0]?.subida_2008}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2008, 1)} %"
        period="pujada acumulada de l'IPC des de la mitjana del 2008"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={ipc.filter(d => d.anio >= 2008).map(d => d.indice_2008)}
    />
</Grid>

## La inflació mes a mes

La inflació més alta des del 2002 va ser la de {hitos_ipc[0]?.mes_max} ({formatNumber(hitos_ipc[0]?.max_var, 1)} %) i la més baixa la de {hitos_ipc[0]?.mes_min} ({formatNumber(hitos_ipc[0]?.min_var, 1)} %). La subjacent deixa fora l'energia i els aliments sense elaborar, els preus dels quals pugen i baixen amb força; per això s'utilitza per veure la tendència de fons.

<LineChart
    data={general_sub}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% respecte al mateix mes de l'any anterior"
    title="IPC general i subjacent (taxa anual)"
/>

<BarChart
    data={ipc_anual_serie}
    x=anio
    y=inflacion_media
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% (mitjana anual)"
    title="Inflació mitjana de cada any"
/>

## Quant han pujat els preus

L'índex acumula les pujades: si val 127, els mateixos productes costen un 27 % més que l'any de referència. Un sou, una pensió o uns estalvis que no hagin crescut des de la mitjana del 2019 compren avui un {formatNumber(ipc_ult[0]?.perdida_poder_compra_2019, 1)} % menys. Des del 2008 els preus han pujat un {formatNumber(ipc_ult[0]?.subida_2008, 1)} %. L'evolució dels sous descomptada la inflació és a [Salaris](/ca/economia/salarios).

<LineChart
    data={nivel}
    x=mes
    y=indice
    series=base
    yFmt='0.0'
    yAxisTitle="índex"
    startingAtZero={false}
    title="Nivell de preus acumulat (IPC general)"
/>

## Què s'encareix més

Taxa anual de cada grup de despesa el {grupos_ult[0]?.mes_txt}. El grup que més puja és {grupos_contrib_top[0]?.gmax} ({formatNumber(grupos_contrib_top[0]?.vmax, 1)} %).

<BarChart
    data={grupos_ult}
    x=grupo_corto
    y=var_anual
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Variació anual dels preus per grup ({grupos_ult[0]?.mes_txt})"
/>

El que pesa en la inflació total depèn de quant puja cada grup i de quant hi gasten les llars (el seu pes en la cistella del {grupos_ult[0]?.anio_ponderacion}). El que més aporta ara és {grupos_contrib_top[0]?.g1}: puja un {formatNumber(grupos_contrib_top[0]?.v1, 1)} % i aporta uns {formatNumber(grupos_contrib_top[0]?.c1, 1)} punts dels {formatNumber(ipc_ult[0]?.var_anual, 1)} de la inflació general (càlcul aproximat).

<BarChart
    data={grupos_contrib}
    x=grupo_corto
    y=contribucion_aprox
    swapXY=true
    sort=false
    yFmt='0.00'
    title="Contribució aproximada de cada grup a la inflació (punts)"
/>

<DataTable data={grupos_contrib} rows=all>
    <Column id=grupo_corto title="Grup" />
    <Column id=peso_pct title="Pes en la cistella (%)" fmt=num1 />
    <Column id=var_anual title="Variació anual (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Contribució (punts)" fmt=num2 contentType=bar barColor="#fecaca" />
</DataTable>

### Pujada acumulada des del 2019 per grup

Des de la mitjana del 2019, el que més s'ha encarit és {grupos_2019_resumen[0]?.gmax} (+{formatNumber(grupos_2019_resumen[0]?.smax, 1)} %) i el que menys {grupos_2019_resumen[0]?.gmin} ({#if grupos_2019_resumen[0]?.smin >= 0}+{/if}{formatNumber(grupos_2019_resumen[0]?.smin, 1)} %). Els aliments costen un {formatNumber(grupos_2019_resumen[0]?.alimentos, 1)} % més.

<BarChart
    data={grupos_2019}
    x=grupo_corto
    y=subida
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Pujada de preus des de la mitjana del 2019, per grup"
/>

<LineChart
    data={grupos_evol}
    x=mes
    y=var_anual
    series=grupo_corto
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflació d'aliments, habitatge i energia, transport i restaurants"
/>

<LineChart
    data={componentes}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflació per tipus de producte (grups especials de l'INE)"
/>

L'energia va arribar a pujar un {formatNumber(hitos_ipc[0]?.max_energia, 1)} % interanual el {hitos_ipc[0]?.mes_max_energia}.

## ⚡ Preu de l'energia

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

El preu de l'energia ha estat una de les claus de la inflació dels últims anys. El {en_ult[0]?.mes_txt}, l'energia puja un {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.var_anual, 1)} % interanual i aporta uns {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.contribucion_aprox, 1)} punts dels {formatNumber(ipc_ult[0]?.var_anual, 1)} de la inflació general, tot i que pesa un {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.peso_pct, 1)} % de la cistella. Els preus majoristes de l'electricitat i la demanda en temps real són a [Electricitat en directe](/ca/energia-clima/directo) i [Rècords elèctrics](/ca/energia-clima/records).

<Grid cols=4>
    <KpiCard
        title="Electricitat (IPC)"
        value={en_ult.find(d => d.producto === 'Electricidad')?.var_anual}
        formattedValue="{en_ult.find(d => d.producto === 'Electricidad')?.var_anual >= 0 ? '+' : ''}{formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.var_anual, 1)} %"
        period="respecte a un any abans, {en_ult[0]?.mes_txt} · {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.indice_2019, 0)} si 2019 = 100"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={en_electricidad.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Gasolina 95"
        value={carb_ult[0]?.gasolina_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l"
        period="setmana del {carb_ult[0]?.semana_txt}, amb impostos, en euros de {carb_ult[0]?.anio_euros} · {formatNumber(carb_ult[0]?.gasolina, 3)} € a preu actual"
        direction="positive-down"
        source="Comissió Europea"
        sparklineData={carb_spark_gasolina.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Gasoil d'automoció"
        value={carb_ult[0]?.gasoleo_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasoleo_real, 2)} €/l"
        period="setmana del {carb_ult[0]?.semana_txt}, amb impostos, en euros de {carb_ult[0]?.anio_euros} · {formatNumber(carb_ult[0]?.gasoleo, 3)} € a preu actual"
        direction="positive-down"
        source="Comissió Europea"
        sparklineData={carb_spark_gasoleo.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Llum de les llars"
        value={hogares_ult[0]?.elec_es_real}
        formattedValue="{formatNumber(hogares_ult[0]?.elec_es_real, 3)} €/kWh"
        period="{hogares_ult[0]?.semestre}, amb impostos, en euros de {hogares_ult[0]?.anio_euros} · UE-27 {formatNumber(hogares_ult[0]?.elec_ue_real, 3)} €"
        direction="positive-down"
        source="Eurostat"
        sparklineData={hogares_es_elec.map(d => d.eur_kwh_real)}
    />
</Grid>

### Quant s'ha encarit cada energia

Nivell de preus de cada producte energètic respecte a l'IPC general, amb la mitjana del 2019 = 100. Des d'aleshores l'IPC general ha pujat un {formatNumber(en_ult.find(d => d.producto === 'IPC general')?.subida_2019, 1)} %; l'electricitat un {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.subida_2019, 1)} %, el gasoil d'automoció un {formatNumber(en_ult.find(d => d.producto === 'Gasóleo de automoción')?.subida_2019, 1)} % i la gasolina un {formatNumber(en_ult.find(d => d.producto === 'Gasolina')?.subida_2019, 1)} %.

<LineChart
    data={en_nivel}
    x=mes
    y=indice_2019
    series=producto
    yFmt='0'
    yAxisTitle="índex, mitjana del 2019 = 100"
    startingAtZero={false}
    title="Preus de l'energia respecte a l'IPC general (2019 = 100)"
/>

<DataTable data={en_ult} rows=all>
    <Column id=producto title="Producte" />
    <Column id=var_anual title="Variació anual (%)" fmt=num1 />
    <Column id=subida_2019 title="Pujada des del 2019 (%)" fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=peso_pct title="Pes en la cistella (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Aportació a la inflació (punts)" fmt=num2 />
</DataTable>

L'electricitat va arribar a pujar un {formatNumber(en_hitos[0]?.elec_max, 1)} % interanual el {en_hitos[0]?.elec_mes_max}. La màxima aportació de l'energia a la inflació va ser el {en_hitos[0]?.contrib_mes_max}: uns {formatNumber(en_hitos[0]?.contrib_max, 1)} punts d'una inflació general del {formatNumber(en_hitos[0]?.general_en_max, 1)} %.

<LineChart
    data={en_var}
    x=mes
    y=var_anual
    series=producto
    yFmt='0"%"'
    yAxisTitle="% respecte al mateix mes de l'any anterior"
    title="Variació anual dels preus de l'energia"
/>

<LineChart
    data={en_contrib}
    x=mes
    y=puntos
    series=serie
    yFmt='0.0'
    yAxisTitle="punts percentuals"
    title="Quant aporta l'energia a la inflació (aproximat)"
/>

### Carburants i gasoil de calefacció, en euros per litre

Preu mitjà setmanal al sortidor amb tots els impostos, segons el Butlletí Petrolier de la Comissió Europea, **descomptada la inflació** (euros de {carb_ult[0]?.anio_euros}). La gasolina 95 costa avui {formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l en euros de {carb_ult[0]?.anio_euros}, davant de {formatNumber(carb_ult[0]?.gasolina_real_2019, 2)} € de mitjana el 2019; el seu màxim real va ser de {formatNumber(carb_ult[0]?.gasolina_real_max, 2)} € ({carb_ult[0]?.gasolina_real_max_fecha}). El gasoil d'automoció és a {formatNumber(carb_ult[0]?.gasoleo_real, 2)} € (màxim real de {formatNumber(carb_ult[0]?.gasoleo_real_max, 2)} € el {carb_ult[0]?.gasoleo_real_max_fecha}).

<LineChart
    data={carb_es}
    x=semana
    y=eur_litro_real
    series=producto
    yFmt='0.00" €"'
    yAxisTitle="€/litre (euros de {carb_ult[0]?.anio_euros})"
    startingAtZero={false}
    title="Preu real dels carburants a Espanya"
/>

L'última setmana, la gasolina 95 costa a Espanya {formatNumber(carb_ult[0]?.gasolina, 3)} €/l davant de {formatNumber(carb_ult[0]?.gasolina_ue, 3)} € de mitjana a la UE, i el gasoil {formatNumber(carb_ult[0]?.gasoleo, 3)} € davant de {formatNumber(carb_ult[0]?.gasoleo_ue, 3)} € (preus del moment, sense deflactar).

<LineChart
    data={carb_ue}
    x=semana
    y=eur_litro_real
    series=serie
    yFmt='0.00" €"'
    yAxisTitle="€/litre (euros de {carb_ult[0]?.anio_euros})"
    startingAtZero={false}
    title="Gasolina i gasoil: Espanya respecte a la mitjana de la UE (preu real)"
/>

### Electricitat i gas de les llars, en euros per kWh

Preu mitjà per kWh que paga una llar de consum mitjà amb tots els impostos (Eurostat, semestral): electricitat per a un consum de 2.500 a 5.000 kWh l'any i gas natural de 20 a 199 GJ l'any, **descomptada la inflació** (euros de {hogares_ult[0]?.anio_euros}). El {hogares_ult[0]?.semestre} la llum costa a Espanya {formatNumber(hogares_ult[0]?.elec_es, 3)} €/kWh davant de {formatNumber(hogares_ult[0]?.elec_ue, 3)} € de mitjana a la UE, i el gas {formatNumber(hogares_ult[0]?.gas_es, 3)} € davant de {formatNumber(hogares_ult[0]?.gas_ue, 3)} € (preus del moment). El preu real de la llum més alt de la sèrie a Espanya va ser el del {hogares_ult[0]?.elec_es_real_max_sem} ({formatNumber(hogares_ult[0]?.elec_es_real_max, 3)} € del {hogares_ult[0]?.anio_euros}).

<LineChart
    data={hogares_elec}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh (euros de {hogares_ult[0]?.anio_euros})"
    title="Preu real de l'electricitat per a les llars"
/>

<LineChart
    data={hogares_gas}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh (euros de {hogares_ult[0]?.anio_euros})"
    title="Preu real del gas natural per a les llars"
/>

<p class="text-xs text-gray-500">Tots els preus es deflacten amb l'IPC general espanyol perquè la comparació entre països no canviï. Els preus d'Eurostat són mitjanes semestrals per kWh que inclouen tots els càrrecs de la factura (energia, xarxes, terme fix) i impostos.</p>


## Per comunitat autònoma

Inflació anual de cada comunitat el {ccaa[0]?.mes_txt} i pujada acumulada dels preus des del desembre del 2019. On més han pujat els preus des d'aleshores és a {ccaa_resumen[0]?.cmax} (+{formatNumber(ccaa_resumen[0]?.smax / 0.01, 1)} %) i on menys a {ccaa_resumen[0]?.cmin} (+{formatNumber(ccaa_resumen[0]?.smin / 0.01, 1)} %). L'IPC mesura quant canvien els preus a cada comunitat, no si una és més cara que una altra.

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
    attribution="Tessel·les © Esri · Límits © Institut Geogràfic Nacional · Dades: INE (IPC)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'var_anual', title: 'Inflació anual', fmt: 'pct1'},
        {id: 'subida_desde_2019', title: 'Pujada des de des. 2019', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=var_anual title="Inflació anual" fmt=pct1 contentType=bar barColor="#fecaca" />
    <Column id=subida_desde_2019 title="Pujada des de des. 2019" fmt=pct1 />
</DataTable>

## Espanya respecte a la zona euro

Per comparar països s'utilitza l'IPC harmonitzat (IPCH) d'Eurostat, amb una metodologia comuna; a Espanya difereix unes dècimes de l'IPC. El {diferencial.slice(-1)[0]?.mes_txt}, la inflació harmonitzada espanyola és del {formatNumber(diferencial.slice(-1)[0]?.es, 1)} % i la de la zona euro del {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} %. Des de la mitjana del 2019, els preus han pujat un {formatNumber(diferencial.slice(-1)[0]?.es_2019 - 100, 1)} % a Espanya i un {formatNumber(diferencial.slice(-1)[0]?.ea_2019 - 100, 1)} % a la zona euro.

<LineChart
    data={ue}
    x=mes
    y=tasa_anual
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Inflació harmonitzada (IPCH) a la zona euro"
/>

<LineChart
    data={ue_nivel}
    x=mes
    y=indice_2019
    series=pais
    yFmt='0.0'
    yAxisTitle="índex, mitjana del 2019 = 100"
    startingAtZero={false}
    title="Nivell de preus acumulat des del 2019 (IPCH)"
/>

---

**Fonts:** INE, Índex de Preus de Consum base 2025: [índexs nacionals per grups ECOICOP (76125)](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [grups especials (76130)](https://www.ine.es/jaxiT3/Tabla.htm?t=76130), [taxes per comunitat autònoma (76140)](https://www.ine.es/jaxiT3/Tabla.htm?t=76140) i [ponderacions (76156)](https://www.ine.es/jaxiT3/Tabla.htm?t=76156); energia: [subclasses ECOICOP (76128)](https://www.ine.es/jaxiT3/Tabla.htm?t=76128) i ponderacions [76159](https://www.ine.es/jaxiT3/Tabla.htm?t=76159) i [76161](https://www.ine.es/jaxiT3/Tabla.htm?t=76161). [Comissió Europea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en) (preus de carburants amb impostos). Eurostat, preus d'[electricitat (nrg_pc_204)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table) i [gas natural (nrg_pc_202)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_202/default/table) per a llars. [Eurostat, IPCH (prc_hicp_minr)](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table). La contribució de cada grup s'aproxima com a pes en la cistella per la variació anual del grup, ajustada pel seu nivell de preus de fa un any; la pujada per comunitat encadena les taxes mensuals publicades, arrodonides a un decimal.
