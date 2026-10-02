---
title: Inflazioa (KPI)
description: "Inflazioa Espainian: KPI orokorra eta azpikoa, prezioak taldeka, argindarraren, gasaren eta erregaien prezio erreala, prezioak zenbat igo diren 2008tik eta 2019tik, KPI erkidegoka eta euroguneko alderaketa."
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
    '/eu' || t.ruta AS ruta,
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

# 🛒 Inflazioa (KPI)

Zenbat igotzen diren prezioak Espainian, zer garestitzen den gehien eta zenbat erosahalmen galdu den. INEren **Kontsumoko Prezioen Indizeak (KPI)** hilero neurtzen du etxeen gastua ordezkatzen duen ondasun eta zerbitzuen saski baten prezioa; **inflazioa** indize horrek aurreko urteko hilabete berarekiko duen igoera da. Azken datua: **{ipc_ult[0]?.mes_txt}**.

<Grid cols=4>
    <KpiCard
        title="Inflazioa"
        value={ipc_ult[0]?.var_anual}
        formattedValue="{formatNumber(ipc_ult[0]?.var_anual, 1)} %"
        period="KPI orokorra, {ipc_ult[0]?.mes_txt}, duela urtebeterekin alderatuta"
        change={ipc_ult[0]?.dif_mes?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="aurreko hilabetearekin alderatuta"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Azpiko inflazioa"
        value={ipc_ult[0]?.subyacente}
        formattedValue="{formatNumber(ipc_ult[0]?.subyacente, 1)} %"
        period="energiarik eta landu gabeko elikagairik gabe, prezio aldakorrenak"
        change={ipc_ult[0]?.dif_sub_mes?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="aurreko hilabetearekin alderatuta"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc.filter(d => d.subyacente != null).slice(-60).map(d => d.subyacente)}
    />
    <KpiCard
        title="Prezioak 2019tik"
        value={ipc_ult[0]?.subida_2019}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2019, 1)} %"
        period="2019an batez beste 100 € balio zuenak gaur {formatNumber(ipc_ult[0]?.indice_2019, 0)} € balio du"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc.filter(d => d.anio >= 2019).map(d => d.indice_2019)}
    />
    <KpiCard
        title="Aldea eurogunearekin"
        value={diferencial.slice(-1)[0]?.diferencial}
        formattedValue="{diferencial.slice(-1)[0]?.diferencial >= 0 ? '+' : ''}{formatNumber(diferencial.slice(-1)[0]?.diferencial, 1)} p.p."
        period="inflazio harmonizatua: Espainia {formatNumber(diferencial.slice(-1)[0]?.es, 1)} %, eurogunea {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} % ({diferencial.slice(-1)[0]?.mes_txt})"
        direction="positive-down"
        source="Eurostat / HKPI"
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
        period="elektrizitatea, gasa eta erregaiak, {ipc_ult[0]?.mes_txt}, duela urtebeterekin alderatuta"
        change={ipc_ult[0]?.dif_energia_mes?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="aurreko hilabetearekin alderatuta"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc.slice(-60).map(d => d.energia)}
    />
    <KpiCard
        title="Landu gabeko elikagaiak"
        value={ipc_ult[0]?.alimentos_sin_elaborar}
        formattedValue="{ipc_ult[0]?.alimentos_sin_elaborar >= 0 ? '+' : ''}{formatNumber(ipc_ult[0]?.alimentos_sin_elaborar, 1)} %"
        period="fruta, barazkiak, haragia, arraina, arrautzak..., duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc.slice(-60).map(d => d.alimentos_sin_elaborar)}
    />
    <KpiCard
        title="Urteko batez besteko inflazioa"
        value={ipc_anual_serie.slice(-1)[0]?.inflacion_media}
        formattedValue="{formatNumber(ipc_anual_serie.slice(-1)[0]?.inflacion_media, 1)} %"
        period="{ipc_anual_serie.slice(-1)[0]?.anio}. urteko batez bestekoa, {ipc_anual_serie.slice(-1)[0]?.anio - 1}. urtekoarekin alderatuta"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc_anual_serie.map(d => d.inflacion_media)}
    />
    <KpiCard
        title="Prezioak 2008tik"
        value={ipc_ult[0]?.subida_2008}
        formattedValue="+{formatNumber(ipc_ult[0]?.subida_2008, 1)} %"
        period="KPIaren igoera metatua 2008ko batez bestekotik"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={ipc.filter(d => d.anio >= 2008).map(d => d.indice_2008)}
    />
</Grid>

## Inflazioa hilez hil

2002tik izandako inflaziorik handiena {hitos_ipc[0]?.mes_max} datakoa izan zen ({formatNumber(hitos_ipc[0]?.max_var, 1)} %), eta txikiena {hitos_ipc[0]?.mes_min} datakoa ({formatNumber(hitos_ipc[0]?.min_var, 1)} %). Azpiko inflazioak kanpoan uzten ditu energia eta landu gabeko elikagaiak, haien prezioak indarrez igotzen eta jaisten baitira; horregatik erabiltzen da oinarrizko joera ikusteko.

<LineChart
    data={general_sub}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% aurreko urteko hilabete berarekiko"
    title="KPI orokorra eta azpikoa (urteko tasa)"
/>

<BarChart
    data={ipc_anual_serie}
    x=anio
    y=inflacion_media
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% (urteko batez bestekoa)"
    title="Urte bakoitzeko batez besteko inflazioa"
/>

## Zenbat igo diren prezioak

Indizeak igoerak metatzen ditu: 127 balio badu, produktu berek erreferentziako urtean baino 27 % gehiago balio dute. 2019ko batez bestekotik hazi ez den soldata, pentsio edo aurrezki batek gaur {formatNumber(ipc_ult[0]?.perdida_poder_compra_2019, 1)} % gutxiago erosten du. 2008tik prezioak {formatNumber(ipc_ult[0]?.subida_2008, 1)} % igo dira. Soldaten bilakaera inflazioa kenduta [Soldatak](/eu/economia/salarios) atalean dago.

<LineChart
    data={nivel}
    x=mes
    y=indice
    series=base
    yFmt='0.0'
    yAxisTitle="indizea"
    startingAtZero={false}
    title="Prezio-maila metatua (KPI orokorra)"
/>

## Zer garestitzen den gehien

Gastu-talde bakoitzaren urteko tasa, {grupos_ult[0]?.mes_txt}. Gehien igotzen den taldea hau da: {grupos_contrib_top[0]?.gmax} ({formatNumber(grupos_contrib_top[0]?.vmax, 1)} %).

<BarChart
    data={grupos_ult}
    x=grupo_corto
    y=var_anual
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Prezioen urteko aldakuntza taldeka ({grupos_ult[0]?.mes_txt})"
/>

Inflazio osoan duen eragina talde bakoitza zenbat igotzen den eta etxeek bertan zenbat gastatzen duten (saskian duen pisua, {grupos_ult[0]?.anio_ponderacion}. urtekoa) araberakoa da. Orain gehien ekartzen duena hau da: {grupos_contrib_top[0]?.g1}; {formatNumber(grupos_contrib_top[0]?.v1, 1)} % igotzen da eta inflazio orokorraren {formatNumber(ipc_ult[0]?.var_anual, 1)} puntuetatik {formatNumber(grupos_contrib_top[0]?.c1, 1)} puntu inguru ekartzen ditu (gutxi gorabeherako kalkulua).

<BarChart
    data={grupos_contrib}
    x=grupo_corto
    y=contribucion_aprox
    swapXY=true
    sort=false
    yFmt='0.00'
    title="Talde bakoitzaren gutxi gorabeherako ekarpena inflazioari (puntuak)"
/>

<DataTable data={grupos_contrib} rows=all>
    <Column id=grupo_corto title="Taldea" />
    <Column id=peso_pct title="Pisua saskian (%)" fmt=num1 />
    <Column id=var_anual title="Urteko aldakuntza (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Ekarpena (puntuak)" fmt=num2 contentType=bar barColor="#fecaca" />
</DataTable>

### Igoera metatua 2019tik, taldeka

2019ko batez bestekotik, gehien garestitu dena hau da: {grupos_2019_resumen[0]?.gmax} (+{formatNumber(grupos_2019_resumen[0]?.smax, 1)} %), eta gutxien hau: {grupos_2019_resumen[0]?.gmin} ({#if grupos_2019_resumen[0]?.smin >= 0}+{/if}{formatNumber(grupos_2019_resumen[0]?.smin, 1)} %). Elikagaiek {formatNumber(grupos_2019_resumen[0]?.alimentos, 1)} % gehiago balio dute.

<BarChart
    data={grupos_2019}
    x=grupo_corto
    y=subida
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    title="Prezioen igoera 2019ko batez bestekotik, taldeka"
/>

<LineChart
    data={grupos_evol}
    x=mes
    y=var_anual
    series=grupo_corto
    yFmt='0.0"%"'
    yAxisTitle="% urtean"
    title="Elikagaien, etxebizitzaren eta energiaren, garraioaren eta jatetxeen inflazioa"
/>

<LineChart
    data={componentes}
    x=mes
    y=tasa
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="% urtean"
    title="Inflazioa produktu motaren arabera (INEren talde bereziak)"
/>

Energia urtetik urtera {formatNumber(hitos_ipc[0]?.max_energia, 1)} % igotzera iritsi zen {hitos_ipc[0]?.mes_max_energia} datan.

## ⚡ Energiaren prezioa

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

Energiaren prezioa azken urteetako inflazioaren gakoetako bat izan da. {en_ult[0]?.mes_txt} datan, energia urtetik urtera {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.var_anual, 1)} % igotzen da, eta inflazio orokorraren {formatNumber(ipc_ult[0]?.var_anual, 1)} puntuetatik {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.contribucion_aprox, 1)} puntu inguru ekartzen ditu, nahiz eta saskiaren {formatNumber(en_ult.find(d => d.producto === 'Energía (total)')?.peso_pct, 1)} % baino ez den. Elektrizitatearen handizkako prezioak eta denbora errealeko eskaria [Elektrizitatea zuzenean](/eu/energia-clima/directo) eta [Elektrizitate-errekorrak](/eu/energia-clima/records) ataletan daude.

<Grid cols=4>
    <KpiCard
        title="Elektrizitatea (KPI)"
        value={en_ult.find(d => d.producto === 'Electricidad')?.var_anual}
        formattedValue="{en_ult.find(d => d.producto === 'Electricidad')?.var_anual >= 0 ? '+' : ''}{formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.var_anual, 1)} %"
        period="duela urtebeterekin alderatuta, {en_ult[0]?.mes_txt} · {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.indice_2019, 0)}, 2019 = 100 bada"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={en_electricidad.slice(-60).map(d => d.var_anual)}
    />
    <KpiCard
        title="Gasolina 95"
        value={carb_ult[0]?.gasolina_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l"
        period="{carb_ult[0]?.semana_txt} asteaz geroztik, zergekin, {carb_ult[0]?.anio_euros}. urteko eurotan · {formatNumber(carb_ult[0]?.gasolina, 3)} € egungo prezioan"
        direction="positive-down"
        source="Europako Batzordea"
        sparklineData={carb_spark_gasolina.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Automobilgintzako gasolioa"
        value={carb_ult[0]?.gasoleo_real}
        formattedValue="{formatNumber(carb_ult[0]?.gasoleo_real, 2)} €/l"
        period="{carb_ult[0]?.semana_txt} asteaz geroztik, zergekin, {carb_ult[0]?.anio_euros}. urteko eurotan · {formatNumber(carb_ult[0]?.gasoleo, 3)} € egungo prezioan"
        direction="positive-down"
        source="Europako Batzordea"
        sparklineData={carb_spark_gasoleo.slice(-104).map(d => d.eur_litro_real)}
    />
    <KpiCard
        title="Etxeetako argindarra"
        value={hogares_ult[0]?.elec_es_real}
        formattedValue="{formatNumber(hogares_ult[0]?.elec_es_real, 3)} €/kWh"
        period="{hogares_ult[0]?.semestre}, zergekin, {hogares_ult[0]?.anio_euros}. urteko eurotan · EB-27 {formatNumber(hogares_ult[0]?.elec_ue_real, 3)} €"
        direction="positive-down"
        source="Eurostat"
        sparklineData={hogares_es_elec.map(d => d.eur_kwh_real)}
    />
</Grid>

### Zenbat garestitu den energia bakoitza

Energia-produktu bakoitzaren prezio-maila KPI orokorrarekin alderatuta, 2019ko batez bestekoa = 100 hartuta. Harrezkero KPI orokorra {formatNumber(en_ult.find(d => d.producto === 'IPC general')?.subida_2019, 1)} % igo da; elektrizitatea, {formatNumber(en_ult.find(d => d.producto === 'Electricidad')?.subida_2019, 1)} %; automobilgintzako gasolioa, {formatNumber(en_ult.find(d => d.producto === 'Gasóleo de automoción')?.subida_2019, 1)} %; eta gasolina, {formatNumber(en_ult.find(d => d.producto === 'Gasolina')?.subida_2019, 1)} %.

<LineChart
    data={en_nivel}
    x=mes
    y=indice_2019
    series=producto
    yFmt='0'
    yAxisTitle="indizea, 2019ko batez bestekoa = 100"
    startingAtZero={false}
    title="Energiaren prezioak KPI orokorrarekin alderatuta (2019 = 100)"
/>

<DataTable data={en_ult} rows=all>
    <Column id=producto title="Produktua" />
    <Column id=var_anual title="Urteko aldakuntza (%)" fmt=num1 />
    <Column id=subida_2019 title="Igoera 2019tik (%)" fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=peso_pct title="Pisua saskian (%)" fmt=num1 />
    <Column id=contribucion_aprox title="Ekarpena inflazioari (puntuak)" fmt=num2 />
</DataTable>

Elektrizitatea urtetik urtera {formatNumber(en_hitos[0]?.elec_max, 1)} % igotzera iritsi zen {en_hitos[0]?.elec_mes_max} datan. Energiak inflazioari egindako ekarpenik handiena {en_hitos[0]?.contrib_mes_max} datan izan zen: {formatNumber(en_hitos[0]?.contrib_max, 1)} puntu inguru, {formatNumber(en_hitos[0]?.general_en_max, 1)} %-ko inflazio orokor batetik.

<LineChart
    data={en_var}
    x=mes
    y=var_anual
    series=producto
    yFmt='0"%"'
    yAxisTitle="% aurreko urteko hilabete berarekiko"
    title="Energiaren prezioen urteko aldakuntza"
/>

<LineChart
    data={en_contrib}
    x=mes
    y=puntos
    series=serie
    yFmt='0.0'
    yAxisTitle="puntu portzentualak"
    title="Zenbat ekartzen dion energiak inflazioari (gutxi gorabehera)"
/>

### Erregaiak eta berokuntzako gasolioa, euro litroko

Asteko batez besteko prezioa hornigunean, zerga guztiekin, Europako Batzordearen Petrolio Buletinaren arabera, **inflazioa kenduta** ({carb_ult[0]?.anio_euros}. urteko eurotan). 95 gasolinak gaur {formatNumber(carb_ult[0]?.gasolina_real, 2)} €/l balio du {carb_ult[0]?.anio_euros}. urteko eurotan, 2019ko batez besteko {formatNumber(carb_ult[0]?.gasolina_real_2019, 2)} €-en aldean; haren gehieneko erreala {formatNumber(carb_ult[0]?.gasolina_real_max, 2)} € izan zen ({carb_ult[0]?.gasolina_real_max_fecha}). Automobilgintzako gasolioa {formatNumber(carb_ult[0]?.gasoleo_real, 2)} €-an dago (gehieneko erreala: {formatNumber(carb_ult[0]?.gasoleo_real_max, 2)} €, {carb_ult[0]?.gasoleo_real_max_fecha} datan).

<LineChart
    data={carb_es}
    x=semana
    y=eur_litro_real
    series=producto
    yFmt='0.00" €"'
    yAxisTitle="€/litro ({carb_ult[0]?.anio_euros}. urteko eurotan)"
    startingAtZero={false}
    title="Erregaien prezio erreala Espainian"
/>

Azken astean, 95 gasolinak {formatNumber(carb_ult[0]?.gasolina, 3)} €/l balio du Espainian, EBko batez besteko {formatNumber(carb_ult[0]?.gasolina_ue, 3)} €-en aldean, eta gasolioak {formatNumber(carb_ult[0]?.gasoleo, 3)} €, {formatNumber(carb_ult[0]?.gasoleo_ue, 3)} €-en aldean (uneko prezioak, deflaktatu gabe).

<LineChart
    data={carb_ue}
    x=semana
    y=eur_litro_real
    series=serie
    yFmt='0.00" €"'
    yAxisTitle="€/litro ({carb_ult[0]?.anio_euros}. urteko eurotan)"
    startingAtZero={false}
    title="Gasolina eta gasolioa: Espainia EBko batez bestekoarekin alderatuta (prezio erreala)"
/>

### Etxeetako elektrizitatea eta gasa, euro kWh-ko

Batez besteko kontsumoko etxe batek kWh bakoitzeko ordaintzen duen batez besteko prezioa, zerga guztiekin (Eurostat, seihilekoa): elektrizitatea urtean 2.500 eta 5.000 kWh arteko kontsumorako, eta gas naturala urtean 20 eta 199 GJ arterako, **inflazioa kenduta** ({hogares_ult[0]?.anio_euros}. urteko eurotan). {hogares_ult[0]?.semestre} aldian, argindarrak {formatNumber(hogares_ult[0]?.elec_es, 3)} €/kWh balio du Espainian, EBko batez besteko {formatNumber(hogares_ult[0]?.elec_ue, 3)} €-en aldean, eta gasak {formatNumber(hogares_ult[0]?.gas_es, 3)} €, {formatNumber(hogares_ult[0]?.gas_ue, 3)} €-en aldean (uneko prezioak). Espainian argindarraren serieko prezio errealik altuena {hogares_ult[0]?.elec_es_real_max_sem} aldikoa izan zen ({formatNumber(hogares_ult[0]?.elec_es_real_max, 3)} €, {hogares_ult[0]?.anio_euros}. urteko eurotan).

<LineChart
    data={hogares_elec}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh ({hogares_ult[0]?.anio_euros}. urteko eurotan)"
    title="Etxeetako elektrizitatearen prezio erreala"
/>

<LineChart
    data={hogares_gas}
    x=semestre_inicio
    y=eur_kwh_real
    series=pais
    yFmt='0.000" €"'
    yAxisTitle="€/kWh ({hogares_ult[0]?.anio_euros}. urteko eurotan)"
    title="Etxeetako gas naturalaren prezio erreala"
/>

<p class="text-xs text-gray-500">Prezio guztiak Espainiako KPI orokorrarekin deflaktatzen dira, herrialdeen arteko alderaketa alda ez dadin. Eurostaten prezioak kWh bakoitzeko seihileko batez bestekoak dira, eta fakturako kargu guztiak (energia, sareak, termino finkoa) eta zergak barne hartzen dituzte.</p>


## Autonomia-erkidegoen arabera

Erkidego bakoitzeko urteko inflazioa, {ccaa[0]?.mes_txt}, eta prezioen igoera metatua 2019ko abendutik. Harrezkero prezioak gehien igo diren tokia {ccaa_resumen[0]?.cmax} da (+{formatNumber(ccaa_resumen[0]?.smax / 0.01, 1)} %), eta gutxien igo direna {ccaa_resumen[0]?.cmin} (+{formatNumber(ccaa_resumen[0]?.smin / 0.01, 1)} %). KPIak neurtzen du prezioak zenbat aldatzen diren erkidego bakoitzean, ez erkidego bat bestea baino garestiagoa den.

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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE (KPI)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'var_anual', title: 'Urteko inflazioa', fmt: 'pct1'},
        {id: 'subida_desde_2019', title: 'Igoera 2019ko abendutik', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=var_anual title="Urteko inflazioa" fmt=pct1 contentType=bar barColor="#fecaca" />
    <Column id=subida_desde_2019 title="Igoera 2019ko abendutik" fmt=pct1 />
</DataTable>

## Espainia eurogunearekin alderatuta

Herrialdeak alderatzeko, Eurostaten KPI harmonizatua (HKPI) erabiltzen da, metodologia komun batekin; Espainian hamarren batzuk aldentzen da KPItik. {diferencial.slice(-1)[0]?.mes_txt} datan, Espainiako inflazio harmonizatua {formatNumber(diferencial.slice(-1)[0]?.es, 1)} % da, eta eurogunekoa {formatNumber(diferencial.slice(-1)[0]?.ea, 1)} %. 2019ko batez bestekotik, prezioak {formatNumber(diferencial.slice(-1)[0]?.es_2019 - 100, 1)} % igo dira Espainian eta {formatNumber(diferencial.slice(-1)[0]?.ea_2019 - 100, 1)} % eurogunean.

<LineChart
    data={ue}
    x=mes
    y=tasa_anual
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="% urtean"
    title="Inflazio harmonizatua (HKPI) eurogunean"
/>

<LineChart
    data={ue_nivel}
    x=mes
    y=indice_2019
    series=pais
    yFmt='0.0'
    yAxisTitle="indizea, 2019ko batez bestekoa = 100"
    startingAtZero={false}
    title="Prezio-maila metatua 2019tik (HKPI)"
/>

---

**Iturriak:** INE, Kontsumoko Prezioen Indizea, 2025 oinarria: [indize nazionalak ECOICOP taldeka (76125)](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [talde bereziak (76130)](https://www.ine.es/jaxiT3/Tabla.htm?t=76130), [tasak autonomia-erkidegoka (76140)](https://www.ine.es/jaxiT3/Tabla.htm?t=76140) eta [haztapenak (76156)](https://www.ine.es/jaxiT3/Tabla.htm?t=76156); energia: [ECOICOP azpiklaseak (76128)](https://www.ine.es/jaxiT3/Tabla.htm?t=76128) eta haztapenak [76159](https://www.ine.es/jaxiT3/Tabla.htm?t=76159) eta [76161](https://www.ine.es/jaxiT3/Tabla.htm?t=76161). [Europako Batzordea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en) (erregaien prezioak zergekin). Eurostat, etxeentzako [elektrizitatearen (nrg_pc_204)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table) eta [gas naturalaren (nrg_pc_202)](https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_202/default/table) prezioak. [Eurostat, HKPI (prc_hicp_minr)](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table). Talde bakoitzaren ekarpena honela hurbiltzen da: saskiko pisua bider taldearen urteko aldakuntza, duela urtebeteko prezio-mailaren arabera doituta; erkidegoko igoerak argitaratutako hileko tasak kateatzen ditu, hamartar batera biribilduta.
