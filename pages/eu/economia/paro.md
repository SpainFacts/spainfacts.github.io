---
title: Langabezia eta enplegua
description: "Espainiako langabezia-tasa sexuaren, adinaren, nazionalitatearen, ikasketen eta lurraldearen arabera, gazteen langabezia eta iraupen luzekoa, behin-behinekotasuna, hileko erregistratutako langabezia eta EBrekiko alderaketa."
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
    '/eu' || t.ruta AS ruta,
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
    '/eu' || t.ruta AS ruta,
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

# 📉 Langabezia eta enplegua

Zenbat pertsonak bilatzen duten lana aurkitu gabe, nori eragiten dion gehien, non eta zenbat irauten duen. Ia datu guztiak INEren **Biztanleria Aktiboaren Inkestatik (EPA)** datoz; hiruhilero argitaratzen da eta nazioarteko irizpideekin neurtzen du langabezia: **langabezia-tasa** enplegurik ez duen biztanleria aktiboaren (lan egiten dutenak edo lana bilatzen dutenak) ehunekoa da. Daturik berriena hiruhileko honetakoa da: **{epa_ult[0]?.periodo}**. Hiruhileko datuak urtaroko doikuntzarik gabeak dira; beraz, hiruhileko bakoitza aurreko urteko hiruhileko berarekin alderatzen da.

<Grid cols=4>
    <KpiCard
        title="Langabezia-tasa"
        value={epa_ult[0]?.tasa_paro}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro, 1)} %"
        period="{epa_ult[0]?.periodo} · {formatNumber(epa_ult[0]?.parados / 1000000, 2)} milioi langabe"
        change={epa_ult[0]?.dif_paro?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro)}
    />
    <KpiCard
        title="Gazteen langabezia (25 urtetik beherakoak)"
        value={epa_ult[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_menor25, 1)} %"
        period="16 eta 24 urte bitarteko aktiboena, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_menor25?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Enplegu-tasa"
        value={epa_ult[0]?.tasa_empleo}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_empleo, 1)} %"
        period="16 urteko eta gehiagoko biztanleriarena lanean ari da, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_empleo?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-up"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_empleo)}
    />
    <KpiCard
        title="Erregistratutako langabezia"
        value={registrado.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(registrado.slice(-1)[0]?.por_100_16_64, 1)} 100eko"
        period="16 eta 64 urte bitarteko biztanleak, {registrado.slice(-1)[0]?.mes_txt} · {formatNumber(registrado.slice(-1)[0]?.paro_registrado / 1000000, 2)} milioi"
        change={registrado.slice(-1)[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="erregistratutako langabeak, duela urtebeterekin alderatuta"
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
        title="Iraupen luzeko langabezia"
        value={epa_ult[0]?.tasa_paro_larga}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_paro_larga, 1)} %"
        period="aktiboena, urtebete edo gehiago daramate lana bilatzen (langabeen {formatNumber(epa_ult[0]?.pct_parados_larga, 0)} %)"
        change={epa_ult[0]?.dif_larga?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_paro_larga)}
    />
    <KpiCard
        title="Denak langabezian dituzten etxeak"
        value={epa_ult[0]?.pct_hogares_todos_parados}
        formattedValue="{formatNumber(epa_ult[0]?.pct_hogares_todos_parados, 1)} %"
        period="aktiboren bat duten etxeetatik, aktibo guztiak langabezian dituztenak, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_hogares?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.pct_hogares_todos_parados)}
    />
    <KpiCard
        title="Behin-behinekotasuna"
        value={epa_ult[0]?.tasa_temporalidad}
        formattedValue="{formatNumber(epa_ult[0]?.tasa_temporalidad, 1)} %"
        period="soldatapekoena, aldi baterako kontratua dute, {epa_ult[0]?.periodo}"
        change={epa_ult[0]?.dif_temporalidad?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.map(d => d.tasa_temporalidad)}
    />
    <KpiCard
        title="Nahi gabeko lanaldi partziala"
        value={epa_ult[0]?.pct_parcial_involuntario}
        formattedValue="{formatNumber(epa_ult[0]?.pct_parcial_involuntario, 1)} %"
        period="lanaldi partzialean ari direnetatik, lanaldi osoko lanik aurkitu ez dutelako ari direnak"
        change={epa_ult[0]?.dif_parcial?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={epa.filter(d => d.pct_parcial_involuntario != null).map(d => d.pct_parcial_involuntario)}
    />
</Grid>

## Langabezia, enplegua eta jarduera 2002tik

Langabeziak goia jo zuen hiruhileko honetan: {hitos[0]?.periodo_max}; aktiboen {formatNumber(hitos[0]?.paro_max, 1)} % lanik gabe zegoen. Serieko minimoa hiruhileko honetakoa da: {hitos[0]?.periodo_min} ({formatNumber(hitos[0]?.paro_min, 1)} %). {#if hitos[0]?.ultimo_periodo_igual}Egungo {formatNumber(epa_ult[0]?.tasa_paro, 1)} % tasa hauxe da baxuena hiruhileko honetaz geroztik: {hitos[0]?.ultimo_periodo_igual}.{:else}Egungo {formatNumber(epa_ult[0]?.tasa_paro, 1)} % tasa serie osoko baxuena da.{/if} Enplegu-tasak 16 urteko edo gehiagoko biztanleriaren zein zatik lan egiten duen neurtzen du, eta jarduera-tasak zein zatik lan egiten duen edo lana bilatzen duen.

<LineChart
    data={tasas_largo}
    x=trimestre
    y=tasa
    series=indicador
    yFmt='0.0"%"'
    yAxisTitle="Biztanleriaren edo aktiboen %"
    title="Langabezia-, enplegu- eta jarduera-tasak (EPA, hiruhilekoa)"
/>

## Nori eragiten dio gehien langabeziak?

{epa_ult[0]?.periodo} hiruhilekoan, langabezia-tasa {formatNumber(grupos_ult[0]?.mujeres, 1)} % da emakumeen artean eta {formatNumber(grupos_ult[0]?.hombres, 1)} % gizonen artean; {formatNumber(grupos_ult[0]?.e16_19, 1)} % lana bilatzen duten 16 eta 19 urte bitartekoen artean, 25 eta 54 urte bitartekoen {formatNumber(grupos_ult[0]?.e25_54, 1)} %-aren aldean; eta {formatNumber(grupos_ult[0]?.no_ue, 1)} % EBtik kanpoko atzerritarren artean, espainiarren {formatNumber(grupos_ult[0]?.espanola, 1)} %-aren aldean.

<LineChart
    data={grupos_sexo}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="Aktiboen %"
    title="Langabezia-tasa sexuaren arabera"
/>

<LineChart
    data={grupos_edad}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="Aktiboen %"
    title="Langabezia-tasa adinaren arabera"
/>

Serieko gazteen langabeziarik handiena, 25 urtetik beherako aktiboen {formatNumber(hitos[0]?.menor25_max, 1)} %, hiruhileko honetan izan zen: {hitos[0]?.periodo_menor25_max}. Kontuz irakurtzean: gazte askok ikasten dute eta ez dira aktiboak; beraz, tasa lan egiten duten edo lana bilatzen dutenen gainean kalkulatzen da.

<LineChart
    data={grupos_nac}
    x=trimestre
    y=tasa_paro
    series=grupo
    yFmt='0.0"%"'
    yAxisTitle="Aktiboen %"
    title="Langabezia-tasa nazionalitatearen arabera"
/>

### Ikasketa-mailaren arabera

Zenbat eta ikasketa gehiago, orduan eta langabezia gutxiago. {formacion_ult[0]?.anio}. urteko batez bestekoa, 16 urteko edo gehiagoko biztanleria.

<BarChart
    data={formacion_ult}
    x=nivel_corto
    y=tasa_paro
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="Aktiboen %"
    title="Langabezia-tasa amaitutako ikasketa-mailaren arabera, {formacion_ult[0]?.anio}. urtean"
/>

<LineChart
    data={formacion_evol}
    x=anio
    y=tasa_paro
    series=nivel_corto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Aktiboen %"
    title="Langabeziaren bilakaera ikasketa-mailaren arabera (urteko batez bestekoa)"
/>

## Iraupen luzeko langabezia eta lan-diru sarrerarik gabeko etxeak

Iraupen luzeko langabe batek urtebete edo gehiago darama lana bilatzen. Gaur egun langabeen {formatNumber(epa_ult[0]?.pct_parados_larga, 0)} % dira, aktibo guztien {formatNumber(epa_ult[0]?.tasa_paro_larga, 1)} %. Bigarren lerroa gutxienez pertsona aktibo bat duten etxeen ehunekoa da, pertsona aktibo guztiak langabezian dituztenena.

<LineChart
    data={larga}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Iraupen luzeko langabezia eta aktibo guztiak langabezian dituzten etxeak"
/>

## Behin-behinekotasuna eta nahi gabeko lanaldi partziala

Aldi baterako kontratua duten soldatapekoen ehunekoa, eta lanaldi osoko lanik aurkitu ez dutelako lanaldi partzialean ari direnen ehunekoa. Behin-behinekotasunak gehienekoa hiruhileko honetan izan zuen: {hitos[0]?.periodo_temporalidad_max} ({formatNumber(hitos[0]?.temporalidad_max, 1)} %); 2021ean, 2022ko lan-erreforma indarrean sartu aurreko urtean, batez beste {formatNumber(hitos[0]?.temporalidad_2021, 1)} % izan zen, eta gaur {formatNumber(epa_ult[0]?.tasa_temporalidad, 1)} % da. Aldizkako kontratu finkoak mugagabetzat hartzen dira EPAn.

<LineChart
    data={calidad}
    x=trimestre
    y=valor
    series=serie
    yFmt='0.0"%"'
    yAxisTitle="%"
    title="Behin-behinekotasuna eta nahi gabeko lanaldi partziala"
/>

## Erkidegoen eta probintzien arabera

Azken lau hiruhilekoen batez bestekoa, lurralde txikietan EPAren laginaren zarata leuntzeko. Langabezia gehien duen erkidegoa {terr_resumen[0]?.ccaa_max} da ({formatNumber(terr_resumen[0]?.ccaa_max_tasa / 0.01, 1)} %), eta gutxien duena {terr_resumen[0]?.ccaa_min} ({formatNumber(terr_resumen[0]?.ccaa_min_tasa / 0.01, 1)} %). Probintziei dagokienez, tartea {terr_resumen[0]?.prov_min} ({formatNumber(terr_resumen[0]?.prov_min_tasa / 0.01, 1)} %) eta {terr_resumen[0]?.prov_max} ({formatNumber(terr_resumen[0]?.prov_max_tasa / 0.01, 1)} %) artekoa da. Sakatu lurralde batean haren fitxa ikusteko.

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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE (EPA)"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: 'Langabezia-tasa (4 hiruhil. batez bestekoa)', fmt: 'pct1'},
        {id: 'tasa_paro_menor25', title: '25 urtetik beherakoak', fmt: 'pct1'},
        {id: 'hogares_todos_parados', title: 'Denak langabezian dituzten etxeak', fmt: 'pct1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=tasa_paro title="Langabezia-tasa" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_paro_trim title="Azken hiruhilekoa" fmt=pct1 />
    <Column id=dif_anual title="Urteko aldaketa (p.p.)" fmt=num1 contentType=delta downIsGood=true />
    <Column id=tasa_paro_menor25 title="25 urtetik beherakoak" fmt=pct1 />
    <Column id=tasa_paro_extranjeros title="Atzerritarrak (hiruhil.)" fmt=pct1 />
    <Column id=hogares_todos_parados title="Denak langabezian dituzten etxeak" fmt=pct1 />
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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE (EPA), SEPE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_paro', title: 'EPAren langabezia-tasa (4 hiruhil. batez bestekoa)', fmt: 'pct1'},
        {id: 'tasa_empleo', title: 'Enplegu-tasa', fmt: 'pct1'},
        {id: 'registrado_100', title: 'Erregistratutako langabezia 16-64 urteko 100 biztanleko', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} link=ruta rows=10 search=true showLinkCol=false>
    <Column id=provincia title="Probintzia" />
    <Column id=tasa_paro title="EPAren langabezia-tasa" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=tasa_empleo title="Enplegu-tasa" fmt=pct1 />
    <Column id=registrado_100 title="Erregistratutako langabezia 16-64 urteko 100 biztanleko" fmt=num1 />
    <Column id=paro_registrado title="Erregistratutako langabeak" fmt=num0 />
</DataTable>

## Hileko datua: erregistratutako langabezia

SEPEk hilero zenbatzen ditu enplegu-bulegoetan langabe gisa izena emanda dauden enplegu-eskatzaileak. Ez dator bat EPArekin (badira izena ematen ez duten langabeak eta EPAk langabetzat hartzen ez dituen izen-emaileak), baina lehenago argitaratzen da, hilero, eta udalerri mailaraino iristen da. Hemen, 16 eta 64 urte bitarteko 100 biztanleko. {registrado.slice(-1)[0]?.mes_txt} hilabetean {formatNumber(registrado.slice(-1)[0]?.paro_registrado, 0)} langabe zeuden erregistratuta, urtebete lehenago baino {#if registrado.slice(-1)[0]?.variacion_anual < 0}{formatNumber(-registrado.slice(-1)[0]?.variacion_anual, 0)} gutxiago{:else}{formatNumber(registrado.slice(-1)[0]?.variacion_anual, 0)} gehiago{/if}.

<LineChart
    data={registrado}
    x=mes
    y=por_100_16_64
    yFmt='0.0'
    yAxisTitle="erregistratutako langabeak 16-64 urteko 100 biztanleko"
    title="Erregistratutako langabezia 16 eta 64 urte bitarteko 100 biztanleko"
/>

### 20.000 biztanle edo gehiagoko udalerriak

Erregistratutako langabeak 100 biztanleko (erroldako biztanleria osoa), data honetan: {registrado.slice(-1)[0]?.mes_txt}.

<DataTable data={municipios} rows=10 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=paro_registrado title="Erregistratutako langabeak" fmt=num0 />
    <Column id=por_100_hab title="100 biztanleko" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=variacion_anual title="Aldaketa urtebetean" fmt=pct1 contentType=delta downIsGood=true />
</DataTable>

## Espainia Europarekin alderatuta

Eurostaten hileko langabezia-tasak, urtaroko doikuntzarekin, herrialdeen artean alderagarriak. {ue_resumen[0]?.mes_txt} datan Espainiako tasa {formatNumber(ue_resumen[0]?.es, 1)} % da, EBko batez bestekoa ({formatNumber(ue_resumen[0]?.ue, 1)} %) bider {formatNumber(ue_resumen[0]?.ratio, 1)}; 25 urtetik beherakoena, berriz, {formatNumber(ue_resumen[0]?.es_joven, 1)} %, EBko {formatNumber(ue_resumen[0]?.ue_joven, 1)} %-aren aldean.

<LineChart
    data={ue}
    x=mes
    y=tasa_paro
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="Aktiboen %"
    title="Langabezia-tasa EBn (hilekoa, urtaroko doikuntzarekin)"
/>

<LineChart
    data={ue}
    x=mes
    y=tasa_paro_menor25
    series=pais
    yFmt='0.0"%"'
    yAxisTitle="25 urtetik beherako aktiboen %"
    title="Gazteen langabezia (25 urtetik beherakoak) EBn"
/>

Soldatak [Soldatak](/eu/economia/salarios) atalean daude, eta enplegu publikoa [Enplegu publikoa](/eu/cuentas-publicas/empleo-publico) atalean.

---

**Iturriak:** INE, Biztanleria Aktiboaren Inkesta: [langabezia-tasak sexuaren eta adinaren arabera (65219)](https://www.ine.es/jaxiT3/Tabla.htm?t=65219), [jarduera-, langabezia- eta enplegu-tasak probintziaka (65349)](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [langabezia adinaren eta erkidegoaren arabera (65334)](https://www.ine.es/jaxiT3/Tabla.htm?t=65334), [langabezia nazionalitatearen arabera (65336)](https://www.ine.es/jaxiT3/Tabla.htm?t=65336), [langabezia prestakuntza-mailaren arabera (66000)](https://www.ine.es/jaxiT3/Tabla.htm?t=66000), [langabeak bilaketa-denboraren arabera (65236)](https://www.ine.es/jaxiT3/Tabla.htm?t=65236), [langabeziaren eragina etxeetan (65276)](https://www.ine.es/jaxiT3/Tabla.htm?t=65276), [soldatapekoak kontratu motaren arabera (65194)](https://www.ine.es/jaxiT3/Tabla.htm?t=65194) eta [lanaldi partzialeko landunak arrazoiaren arabera (65152)](https://www.ine.es/jaxiT3/Tabla.htm?t=65152). [SEPE, erregistratutako langabezia udalerrika (datu irekiak, urteko CSVa)](https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv); 16 eta 64 urte bitarteko biztanleria, INEren Biztanleriaren Etengabeko Estatistikatik. [Eurostat, une_rt_m](https://ec.europa.eu/eurostat/databrowser/view/une_rt_m/default/table). Iraupen luzeko langabezia-tasa honela kalkulatzen da: langabezia-tasa bider urtebete edo gehiago lana bilatzen daramaten langabeen ehunekoa.
