---
title: Alokairuko etxebizitza publikoa
description: "Zenbat alokairuko etxebizitza publiko dagoen Espainian biztanleko eta etxeen %an, erkidego, probintzia eta udalerriaren arabera, Herbehereekin, Austriarekin, Danimarkarekin, Frantziarekin eta Europako batez bestekoarekin alderatuta, eta gobernatzen zuen alderdiaren arabera."
i18n_origen: a5388d75d815
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import EnConstruccion from '../../../../../../../src/lib/components/EnConstruccion.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2010etik, 2020tik · 2023ra, 2005era
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql espana
SELECT anio, ecv_pct_alquiler_inferior, ecv_pct_alquiler_mercado, calif_alquiler, calif_total, pct_calif_alquiler,
       calif_alquiler_100k, parque_autonomico_alquiler, parque_autonomico_1000hab, parque_publico_alquiler,
       parque_municipal_estimado, parque_publico_1000hab, pct_hogares_mivau, ocde_viviendas_sociales, ocde_pct_parque
FROM mother.vivienda_publica_espana
ORDER BY anio
```

```sql ecv
SELECT anio, 'Alquiler por debajo del precio de mercado' AS regimen, ecv_pct_alquiler_inferior AS pct FROM mother.vivienda_publica_espana WHERE ecv_pct_alquiler_inferior IS NOT NULL
UNION ALL
SELECT anio, 'Alquiler a precio de mercado' AS regimen, ecv_pct_alquiler_mercado AS pct FROM mother.vivienda_publica_espana WHERE ecv_pct_alquiler_mercado IS NOT NULL
ORDER BY anio, regimen
```

```sql calif
SELECT anio, calif_alquiler, calif_total, pct_calif_alquiler, calif_alquiler_100k
FROM mother.vivienda_publica_espana
WHERE calif_alquiler IS NOT NULL
ORDER BY anio
```

```sql resumen
SELECT
    max(parque_publico_alquiler) AS parque,
    max(parque_publico_1000hab) AS parque_1000,
    max(pct_hogares_mivau) AS pct_hogares,
    max(parque_municipal_estimado) AS municipal,
    max(parque_autonomico_alquiler) FILTER (WHERE anio = 2023) AS autonomico_2023,
    max(parque_autonomico_alquiler) FILTER (WHERE anio = 2019) AS autonomico_2019,
    max(parque_autonomico_1000hab) FILTER (WHERE anio = 2023) AS autonomico_1000_2023,
    100 * (max(parque_autonomico_alquiler) FILTER (WHERE anio = 2023) / max(parque_autonomico_alquiler) FILTER (WHERE anio = 2019) - 1) AS autonomico_var,
    max(ocde_pct_parque) AS ocde_pct,
    max(ocde_viviendas_sociales) AS ocde_viviendas,
    arg_max(ecv_pct_alquiler_inferior, anio) FILTER (WHERE ecv_pct_alquiler_inferior IS NOT NULL) AS ecv_ultimo,
    max(anio) FILTER (WHERE ecv_pct_alquiler_inferior IS NOT NULL) AS ecv_anio,
    sum(calif_alquiler) FILTER (WHERE anio BETWEEN 2005 AND 2008) / 4 AS calif_media_boom,
    sum(calif_alquiler) FILTER (WHERE anio BETWEEN 2013 AND 2017) / 5 AS calif_media_crisis,
    sum(calif_alquiler) FILTER (WHERE anio BETWEEN 2019 AND 2023) / 5 AS calif_media_reciente,
    arg_max(calif_alquiler, anio) FILTER (WHERE calif_alquiler IS NOT NULL) AS calif_ultimo,
    arg_max(calif_alquiler_100k, anio) FILTER (WHERE calif_alquiler IS NOT NULL) AS calif_ultimo_100k,
    max(anio) FILTER (WHERE calif_alquiler IS NOT NULL) AS calif_anio
FROM mother.vivienda_publica_espana
```

```sql ccaa
SELECT c.cod_ccaa, c.comunidad, '/eu' || t.ruta AS ruta, c.autonomico_2019, c.autonomico_2023, c.variacion_pct_2019_2023,
       c.autonomico_titularidad_2023, c.autonomico_ppp_2023, c.municipal_declarado, c.alquiler_publico_conocido,
       c.autonomico_1000hab, c.conocido_1000hab, c.conocido_pct_hogares, c.cobertura_municipal_pct,
       c.ecv_pct_alquiler_inferior_3a, c.ecv_anio, c.calif_alquiler_2005_2023, c.calif_alquiler_2005_2023_1000hab,
       c.venta_2023, c.opcion_compra_2023, c.otras_2023, c.familia_2019_2023, c.presidente_2019_2023
FROM mother.vivienda_publica_ccaa c
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod_ccaa
ORDER BY c.conocido_1000hab DESC
```

```sql ccaa_extremos
SELECT
    string_agg(comunidad, ', ' ORDER BY autonomico_1000hab DESC) FILTER (WHERE rk_mas <= 4) AS mas,
    string_agg(comunidad, ', ' ORDER BY autonomico_1000hab) FILTER (WHERE rk_menos <= 4) AS menos,
    string_agg(comunidad, ' y ' ORDER BY comunidad) FILTER (WHERE venta_2023 > autonomico_2023) AS mas_venta,
    max(100 * autonomico_ppp_2023 / autonomico_2023) FILTER (WHERE cod_ccaa = '16') AS ppp_pv,
    max(100 * autonomico_ppp_2023 / autonomico_2023) FILTER (WHERE cod_ccaa = '13') AS ppp_madrid
FROM (
    SELECT *,
        row_number() OVER (ORDER BY autonomico_1000hab DESC) AS rk_mas,
        row_number() OVER (ORDER BY autonomico_1000hab) AS rk_menos
    FROM mother.vivienda_publica_ccaa
    WHERE cod_ccaa NOT IN ('18', '19')
)
```

```sql ocde_ue
SELECT max(pct_parque_total) FILTER (WHERE cod_pais = 'EU27_2020') AS ue, max(pct_parque_total) FILTER (WHERE cod_pais = 'OECD') AS ocde
FROM mother.vivienda_publica_internacional
WHERE pct_parque_total IS NOT NULL AND es_ultimo
```

```sql provincias
SELECT p.cod_prov, p.provincia, p.comunidad, '/eu' || t.ruta AS ruta, p.municipal_declarado, p.municipios_con_dato, p.municipios_20k,
       p.cobertura_pct, p.municipal_1000hab, p.municipal_1000hab_con_dato, p.autonomico_2023, p.conocido_1000hab,
       CASE WHEN p.uniprovincial THEN 'Sí' ELSE 'No' END AS uniprovincial
FROM mother.vivienda_publica_provincias p
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod_prov
ORDER BY p.municipal_1000hab DESC
```

```sql uniprovinciales
SELECT provincia, autonomico_2023, municipal_declarado, conocido_1000hab
FROM ${provincias}
WHERE uniprovincial = 'Sí'
ORDER BY conocido_1000hab DESC
```

```sql municipios
SELECT municipio, provincia, CAST(poblacion AS INTEGER) AS poblacion, alquiler, alquiler_1000hab, total,
       CASE origen WHEN 'encuesta_2023' THEN '2023' ELSE '2019 (no respondió en 2023)' END AS dato
FROM mother.vivienda_publica_municipios
WHERE origen <> 'sin_respuesta'
ORDER BY alquiler DESC
```

```sql cobertura_mun
SELECT
    CAST(count(*) AS INTEGER) AS municipios,
    CAST(count(*) FILTER (WHERE origen = 'encuesta_2023') AS INTEGER) AS respondieron,
    CAST(count(*) FILTER (WHERE origen = 'boletin_2020') AS INTEGER) AS dato_2019,
    CAST(count(*) FILTER (WHERE origen = 'sin_respuesta') AS INTEGER) AS sin_dato,
    CAST(sum(alquiler) AS INTEGER) AS alquiler
FROM mother.vivienda_publica_municipios
WHERE cod_prov NOT IN ('51', '52')
```

```sql ocde
SELECT pais, anio, pct_parque_total AS valor, CAST(viviendas_sociales AS INTEGER) AS viviendas_sociales,
       CASE WHEN es_espana THEN 'España' WHEN es_agregado THEN 'Media UE / OCDE' ELSE 'Otros países' END AS grupo
FROM mother.vivienda_publica_internacional
WHERE pct_parque_total IS NOT NULL AND es_ultimo
ORDER BY valor DESC
```

```sql ocde_evolucion
SELECT pais, anio, pct_parque_total AS valor
FROM mother.vivienda_publica_internacional
WHERE pct_parque_total IS NOT NULL AND destacado AND NOT es_agregado
ORDER BY pais, anio
```

```sql ue_hogares
SELECT pais, anio, pct_viviendas_principales AS valor,
       CASE WHEN es_espana THEN 'España' WHEN es_agregado THEN 'Media UE' ELSE 'Otros países' END AS grupo
FROM mother.vivienda_publica_internacional
WHERE pct_viviendas_principales IS NOT NULL
ORDER BY valor DESC
```

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo WHERE indicador_id = 'vivienda_social_pct'
```

```sql gobiernos
SELECT familia AS partido, color, anios_comunidad, comunidades, calif_alquiler, calif_alquiler_100k_anio,
       cuota_calif, cuota_poblacion, ratio_observado_esperado, anio_desde, anio_hasta
FROM mother.vivienda_publica_gobiernos
ORDER BY cuota_poblacion DESC
```

```sql calif_partido_anio
SELECT anio, familia AS partido, CAST(sum(calif_alquiler) AS INTEGER) AS calif_alquiler
FROM mother.vivienda_publica_ccaa_anual
WHERE calif_alquiler IS NOT NULL AND familia IS NOT NULL
GROUP BY ALL
ORDER BY anio, partido
```

```sql parque_partido
SELECT
    familia_2019_2023 AS partido,
    CAST(count(*) AS INTEGER) AS comunidades,
    CAST(sum(autonomico_2019) AS INTEGER) AS parque_2019,
    CAST(sum(autonomico_2023) AS INTEGER) AS parque_2023,
    100 * (sum(autonomico_2023) / sum(autonomico_2019) - 1) AS variacion_pct,
    1000 * (sum(autonomico_2023) - sum(autonomico_2019)) / sum(poblacion) AS variacion_1000hab,
    string_agg(comunidad, ', ' ORDER BY comunidad) AS lista
FROM mother.vivienda_publica_ccaa
GROUP BY 1
ORDER BY sum(poblacion) DESC
```

```sql pp_psoe
SELECT
    max(ratio_observado_esperado) FILTER (WHERE familia = 'PP') AS pp,
    max(ratio_observado_esperado) FILTER (WHERE familia = 'PSOE') AS psoe,
    max(calif_alquiler_100k_anio) FILTER (WHERE familia = 'PP') AS pp_100k,
    max(calif_alquiler_100k_anio) FILTER (WHERE familia = 'PSOE') AS psoe_100k
FROM mother.vivienda_publica_gobiernos
```

# 🏘️ Alokairuko etxebizitza publikoa

Administrazioen zenbat etxebizitza alokatzen diren merkatuko prezioen azpitik zenbait baldintza betetzen dituztenei: autonomia-erkidegoenak eta haien enpresa publikoenak, eta udalenak. Dena **1.000 biztanleko edo etxeen %an** erakusten da, oso tamaina desberdineko erkidegoak eta herrialdeak alderatu ahal izateko.

<Grid cols=4>
    <KpiCard
        title="Alokairuko etxebizitza publikoak"
        value={resumen[0]?.parque_1000}
        formattedValue="{formatNumber(resumen[0]?.parque_1000, 1)} 1.000 biztanleko"
        period="Ministerioaren kalkulua, 2023 · {formatCompact(resumen[0]?.parque, 0)} guztira, etxeen {formatNumber(resumen[0]?.pct_hogares, 2)} %"
        direction="neutral"
        source="Etxebizitza Ministerioa"
    />
    <KpiCard
        title="Autonomia-erkidegoenak"
        value={resumen[0]?.autonomico_1000_2023}
        formattedValue="{formatNumber(resumen[0]?.autonomico_1000_2023, 1)} 1.000 biztanleko"
        period="2023 · alokairuko {formatCompact(resumen[0]?.autonomico_2023, 0)} etxebizitza"
        change={resumen[0]?.autonomico_var?.toFixed(1)}
        changePeriod="2019arekin alderatuta"
        direction="neutral"
        source="Etxebizitza Ministerioa (etxebizitza sozialari buruzko inkesta)"
        sparklineData={espana.filter(d => d.parque_autonomico_1000hab != null).map(d => d.parque_autonomico_1000hab)}
    />
    <KpiCard
        title="Merkatuaren azpiko alokairua duten etxeak"
        value={resumen[0]?.ecv_ultimo}
        formattedValue="{formatNumber(resumen[0]?.ecv_ultimo, 1)} %"
        period="etxeen gainean, {resumen[0]?.ecv_anio} · alokairu pribatu murriztuak barne"
        direction="neutral"
        source="INE (Bizi Baldintzei buruzko Inkesta)"
        sparklineData={espana.filter(d => d.ecv_pct_alquiler_inferior != null).map(d => d.ecv_pct_alquiler_inferior)}
    />
    <KpiCard
        title="Alokairuko babes ofizialeko etxebizitzak"
        value={resumen[0]?.calif_ultimo_100k}
        formattedValue="{formatNumber(resumen[0]?.calif_ultimo_100k, 1)} 100.000 biztanleko"
        period="behin-behineko kalifikazioak, {resumen[0]?.calif_anio} · {formatNumber(resumen[0]?.calif_ultimo, 0)} etxebizitza"
        direction="neutral"
        source="Etxebizitza Ministerioa"
        sparklineData={calif.map(d => d.calif_alquiler_100k)}
    />
</Grid>

<Comparativa data={comparativa_internacional} decimales={1} />

## Zenbat dauden

Etxebizitza Ministerioak 2023an galdetu zien autonomia-erkidegoei eta 20.000 biztanletik gorako udalei zenbat etxebizitza dituzten eta zer araubidetan. Erantzun horiekin kalkulatzen du Espainian **alokairuko {formatNumber(resumen[0]?.parque, 0)} etxebizitza publiko** inguru daudela: erkidegoenak, {formatNumber(resumen[0]?.autonomico_2023, 0)} (haien erantzunen batura), eta udalenak, {formatNumber(resumen[0]?.municipal, 0)} inguru (biztanleriaren arabera eskalatutako zifra, askok ez baitzuten erantzun). 1.000 biztanleko {formatNumber(resumen[0]?.parque_1000, 1)} dira, eta etxeen {formatNumber(resumen[0]?.pct_hogares, 2)} % hartzen dute.

Erkidegoen alokairuko parkea hazi egin zen: 2019an {formatNumber(resumen[0]?.autonomico_2019, 0)} etxebizitza zeuden, eta 2023an, berriz, {formatNumber(resumen[0]?.autonomico_2023, 0)}; hau da, {formatNumber(resumen[0]?.autonomico_var, 1)} % gehiago. Ez dago urteko seriorik: Ministerioak bi inkesta horiek baino ez ditu egin.

INEren Bizi Baldintzei buruzko Inkestak serie luzea ematen du, baina zabalagoa: **merkatuko prezioaren azpitik** alokairua ordaintzen duten etxeak zenbatzen ditu; horrek etxebizitza publikoa hartzen du barne, baina baita enpresa-pisuak edo partikularren arteko alokairu murriztuak ere (horregatik ateratzen da handiagoa).

<LineChart
    data={ecv}
    x=anio
    y=pct
    series=regimen
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="etxeen %"
    title="Alokairuan dauden etxeak ordaintzen duten prezioaren arabera (etxe guztien %)"
/>

## Zenbat sustatzen diren urtero

**Behin-behineko kalifikazioak** babes ofizialeko etxebizitza baten lehen urrats administratiboa dira: urtero zenbat abiarazten diren eta zer helbururekin. 2005etik 2008ra, batez beste, alokairuko {formatNumber(resumen[0]?.calif_media_boom, 0)} babes ofizialeko etxebizitza kalifikatzen ziren urtean; 2013tik 2017ra, {formatNumber(resumen[0]?.calif_media_crisis, 0)}; 2019tik 2023ra, {formatNumber(resumen[0]?.calif_media_reciente, 0)}. Ez dira denak publikoak (laguntzak dituzten enpresa pribatuek ere sustatzen dituzte), eta ez dira denak eraikitzen.

<BarChart
    data={calif}
    x=anio
    y=calif_alquiler_100k
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="100.000 biztanleko"
    title="Urtero kalifikatutako alokairuko babes ofizialeko etxebizitzak 100.000 biztanleko"
/>

<LineChart
    data={calif}
    x=anio
    y=pct_calif_alquiler
    xFmt='0'
    yFmt='0'
    yAxisTitle="kalifikazioen %"
    title="Alokairuaren pisua urtero kalifikatutako babes ofizialeko etxebizitzetan (%)"
/>

## Espainia beste herrialde batzuen aldean

ELGAk gobernuek berek ematen dituzten zifrak biltzen ditu: alokairuko etxebizitza sozialak (merkatuaren azpiko errenta, eta arauen bidez esleituak, ez prezioaren bidez) **etxebizitza-parke osoaren %an**. Espainiak {formatNumber(resumen[0]?.ocde_viviendas, 0)} aitortu zituen 2019an, parkearen {formatNumber(resumen[0]?.ocde_pct, 1)} %, ELGAko baxuenen artean; EBko batez bestekoa {formatNumber(ocde_ue[0]?.ue, 1)} % da, eta ELGAkoa, {formatNumber(ocde_ue[0]?.ocde, 1)} %.

<BarChart
    data={ocde}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="etxebizitza-parke osoaren %"
    seriesColors={{'España': '#dc2626', 'Media UE / OCDE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Alokairuko etxebizitza sozialak, parke osoaren % (herrialde bakoitzaren azken datua)"
/>

Herrialde bakoitzak bere erara definitzen du etxebizitza soziala (Herbehereetan merkatuaren azpiko alokairu pribatua ere zenbatzen da; Austrian, ohiko etxebizitzak soilik), beraz, konparazioa orientagarria da. Etxebizitza sozial gehien duten herrialdeetan pisua zertxobait jaitsi da 2010etik:

<LineChart
    data={ocde_evolucion}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="parke osoaren %"
    markers=true
    title="Alokairuko etxebizitza soziala 2010 eta 2022 inguruan (parke osoaren %)"
/>

Ministerioak **etxeen %an** ere alderatzen du (ohiko etxebizitzak), Housing Europe eta Eurostaten datuekin. Espainiarako ECV erabiltzen du, zerbait zabalagoa neurtzen duena; Ministerioaren beraren parke publikoaren zifra gehitzen da, biak batera ikusteko:

<BarChart
    data={ue_hogares}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="etxeen %"
    seriesColors={{'España': '#dc2626', 'Media UE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Alokairu sozialeko etxebizitza EBn, ohiko etxebizitzen % (2023 edo 2017)"
/>

## Erkidegoka

Ezagutzen diren alokairuko etxebizitza publikoak 1.000 biztanleko: erkidegoarenak (2023ko datu osoa) gehi inkestari erantzun zioten 20.000 biztanletik gorako udalenak (datu partziala). Sakatu erkidego batean haren fitxa ikusteko.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="conocido_1000hab"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#ecfdf5', '#10b981', '#064e3b']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'conocido_1000hab', title: '1.000 biztanleko (erkidegoa + udalak)', fmt: '0.0'},
        {id: 'autonomico_1000hab', title: 'Erkidegoarenak soilik, 1.000 biztanleko', fmt: '0.0'},
        {id: 'conocido_pct_hogares', title: 'Etxeen %', fmt: '0.00'},
        {id: 'variacion_pct_2019_2023', title: 'Parke autonomikoa, aldaketa 2019-2023 (%)', fmt: '0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=conocido_1000hab title="1.000 biztanleko" fmt='0.0' />
    <Column id=conocido_pct_hogares title="Etxeen %" fmt='0.00' />
    <Column id=autonomico_2023 title="Erkidegoarenak (2023)" fmt='#,##0' />
    <Column id=variacion_pct_2019_2023 title="Aldaketa 2019-2023 %" fmt='0' contentType=delta />
    <Column id=municipal_declarado title="Udalenak (aitortuak)" fmt='#,##0' />
    <Column id=cobertura_municipal_pct title="Udal-datua duen biztanleriaren %" fmt='0' />
    <Column id=ecv_pct_alquiler_inferior_3a title="Merkatuaren azpiko etxeen % (ECV, 3 urte)" fmt='0.0' />
</DataTable>

Ceuta eta Melilla kontuan hartu gabe, biztanleko alokairuko parke autonomiko handienak erkidego hauenak dira: {ccaa_extremos[0]?.mas}; txikienak, berriz, hauenak: {ccaa_extremos[0]?.menos}. Erkidego hauetan, erkidegoak alokairurako baino etxebizitza gehiago ditu salmentarako: {ccaa_extremos[0]?.mas_venta?.replace(' y ', ' eta ')}. Beste batzuetan lankidetza publiko-pribatuak du pisua (lurzoru publikoa, azalera-eskubidearekin edo emakidarekin): Euskadiko alokairuko parke autonomikoaren {formatNumber(ccaa_extremos[0]?.ppp_pv, 0)} % da, eta Madrilgoaren {formatNumber(ccaa_extremos[0]?.ppp_madrid, 0)} %.

<BarChart
    data={ccaa}
    x=comunidad
    y=calif_alquiler_2005_2023_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="1.000 biztanleko"
    title="2005etik 2023ra kalifikatutako alokairuko babes ofizialeko etxebizitzak, gaur egungo 1.000 biztanleko"
/>

## Probintziaka

Ez dago parke autonomikoaren zenbaketa ofizialik probintziaka: erkidegoek multzoan aitortzen dute. Probintziaka ezagutzen dena **20.000 biztanletik gorako udalek aitortutako alokairuko udal-parkea** da (2023an {cobertura_mun[0]?.respondieron} udalek erantzun zuten, {cobertura_mun[0]?.dato_2019} udalek 2019ko datua errepikatzen dute eta {cobertura_mun[0]?.sin_dato} udalek ez zuten zifrarik eman). Mapak probintziako 1.000 biztanleko erakusten du; zuriz dagoen probintzia batek parke autonomikoa izan dezake, edo erantzun ez zuten udalerriak.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="municipal_1000hab"
    valueFmt='0.00'
    link="ruta"
    colorPalette={['#ecfdf5', '#10b981', '#064e3b']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'municipal_1000hab', title: 'Alokairuko udal-etxebizitza 1.000 biztanleko', fmt: '0.00'},
        {id: 'municipal_declarado', title: 'Aitortutako udal-etxebizitzak', fmt: '#,##0'},
        {id: 'cobertura_pct', title: 'Datua duten udalerrietako biztanleriaren %', fmt: '0'},
        {id: 'conocido_1000hab', title: 'Parke autonomikoarekin (probintzia bakarrekoak)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=comunidad title="Erkidegoa" />
    <Column id=municipal_1000hab title="Udalenak 1.000 biztanleko" fmt='0.00' />
    <Column id=municipal_declarado title="Udal-etxebizitzak" fmt='#,##0' />
    <Column id=municipios_con_dato title="Datua duten udalerriak" fmt='0' />
    <Column id=municipios_20k title="20.000 biztanletik gorako udalerriak" fmt='0' />
    <Column id=cobertura_pct title="Datua duen biztanleriaren %" fmt='0' />
</DataTable>

Probintzia bakarreko erkidegoetan (eta Ceutan eta Melillan) parke autonomikoa probintziakoa da, eta udal-parkeari gehi dakioke:

<DataTable data={uniprovinciales} rows=9>
    <Column id=provincia title="Probintzia" />
    <Column id=conocido_1000hab title="1.000 biztanleko (erkidegoa + udalak)" fmt='0.0' />
    <Column id=autonomico_2023 title="Erkidegoarenak" fmt='#,##0' />
    <Column id=municipal_declarado title="Udalenak (aitortuak)" fmt='#,##0' />
</DataTable>

<EnConstruccion motivo="erkidegoen etxebizitza-parkea ez da probintziaka argitaratzen: Ministerioaren inkestak erkidegoka soilik jasotzen du. Enpresa autonomiko batzuek (Agència de l'Habitatge de Catalunya, Alokabide, Andaluziako AVRA...) beren parkea udalerrika argitaratzen dute, formatu desberdinetan; horiek integratuta probintzien mapa osoa lortuko litzateke." />

## Udalerrika

Udalen eta haien udal-enpresen etxebizitzak (ez dira sartzen udalerrian dauden erkidegoarenak), datua duten 20.000 biztanletik gorako udalerrietan.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=alquiler title="Alokairuan" fmt='#,##0' />
    <Column id=alquiler_1000hab title="1.000 biztanleko" fmt='0.0' />
    <Column id=total title="Udal-parkea guztira" fmt='#,##0' />
    <Column id=poblacion title="Biztanleria" fmt='#,##0' />
    <Column id=dato title="Datuaren urtea" />
</DataTable>

## Alderdika

Babes ofizialeko etxebizitza autonomia-erkidegoek kalifikatzen dute, nahiz eta zati handi bat estatuko etxebizitza-planekin finantzatzen den. {urtetik(gobiernos[0]?.anio_desde)} {urtera(gobiernos[0]?.anio_hasta)} bitarteko erkidegoak eta urteak batuta, eta urte bakoitza uztailaren 1ean erkidegoa gobernatzen zuen alderdiari egotzita, alderdi bakoitzarekin kalifikatutako alokairuko babes ofizialeko etxebizitzen zatia alderatzen da alderdi horrek gobernatu zuen biztanleriaren zatiarekin (denek biztanleko gauza bera sustatuko balute, arrazoia 1 izango litzateke). PPrekin arrazoia {formatNumber(pp_psoe[0]?.pp, 2)} da ({formatNumber(pp_psoe[0]?.pp_100k, 1)} etxebizitza 100.000 biztanleko eta urteko), eta PSOErekin, {formatNumber(pp_psoe[0]?.psoe, 2)} ({formatNumber(pp_psoe[0]?.psoe_100k, 1)}).

<DataTable data={gobiernos} rows=12>
    <Column id=partido title="Gobernatzen zuen alderdia" />
    <Column id=anios_comunidad title="Gobernu-urteak (erkidegoa x urtea)" fmt='0' />
    <Column id=calif_alquiler title="Kalifikatutako alokairuko etxebizitzak" fmt='#,##0' />
    <Column id=calif_alquiler_100k_anio title="100.000 biztanleko eta urteko" fmt='0.0' />
    <Column id=cuota_calif title="Kalifikatuen %" fmt='0.0' />
    <Column id=cuota_poblacion title="Gobernatutako biztanleriaren %" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Behatua / espero zena" fmt='0.00' />
</DataTable>

<BarChart
    data={calif_partido_anio}
    x=anio
    y=calif_alquiler
    series=partido
    xFmt='0'
    yFmt='#,##0'
    seriesColors={Object.fromEntries(gobiernos.map(d => [d.partido, d.color]))}
    title="Urtero kalifikatutako alokairuko babes ofizialeko etxebizitzak, erkidego bakoitza gobernatzen zuen alderdiaren arabera"
/>

Alokairuko parke autonomikoaren aldaketa 2019tik 2023ra, erkidegoak aldi horren erdian gobernatzen zituen alderdiaren arabera multzokatuta:

<DataTable data={parque_partido} rows=10>
    <Column id=partido title="Alderdia (2021eko uztaila)" />
    <Column id=comunidades title="Erkidegoak" fmt='0' />
    <Column id=parque_2019 title="Parkea 2019" fmt='#,##0' />
    <Column id=parque_2023 title="Parkea 2023" fmt='#,##0' />
    <Column id=variacion_pct title="Aldaketa %" fmt='0.0' contentType=delta />
    <Column id=variacion_1000hab title="Aldaketa 1.000 biztanleko" fmt='0.00' contentType=delta />
    <Column id=lista title="Erkidegoak" wrap=true />
</DataTable>

Kontuz irakurri behar da: urte gutxi eta alderdi bakoitzeko erkidego gutxi dira, etxebizitzak urteak behar ditu kalifikaziotik entregara igarotzeko (agintaldi bateko etxebizitza asko aurreko agintaldian erabaki ziren), eta parkea ere aldatzen da maizterrei egindako salmentengatik, administrazioen arteko eskualdaketengatik edo inkesta bakoitzean zenbaketa desberdinak egiteagatik. Etxebizitzak ez dira banan-banan iristen, sustapenetan baizik; beraz, ez du zentzurik beste orri batzuetan bezalako proba estatistiko bat egiteak.

## Metodologia eta iturriak

- **Alokairuko parke publikoa**: [Etxebizitza eta Hiri Agenda Ministerioa, Etxebizitza eta Lurzoru Behatokia, Etxebizitza Sozialari buruzko 2024ko buletin berezia](https://www.mivau.gob.es/urbanismo-y-suelo/suelo/observatorio-de-vivienda-y-suelo) (2023ko etxebizitza sozialari buruzko inkesta eta, 2019rako, 2019koa). «Alokairuan» kategorian sartzen dira titulartasun publikoko etxebizitzak eta lankidetza publiko-pribatukoak (lurzoru publikoa, azalera-eskubidearekin edo emakidarekin), prezio baxuko lagapena eta aldi baterako ostatua; ez dira sartzen erosteko aukera duen alokairua eta salmenta. 2023ko estatuko guztizkoa erkidegoen batura da (buletinak zifra zertxobait txikiagoa ematen du bilakaeraren taulan). Udal-parkeak erantzun zuten 20.000 biztanletik gorako udalak baino ez ditu jasotzen (edo haien 2019ko datua, erantzun ez bazuten); Ministerioak biztanleriaren arabera eskalatzen du estatuko kalkulurako. Ceutan eta Melillan hiria erkidegoa eta udala da aldi berean, eta haren parkea behin zenbatzen da.
- Babes ofizialeko etxebizitzaren **behin-behineko kalifikazioak**, erabilera-araubidearen eta erkidegoaren arabera, 2005-2023, buletin beretik.
- **Merkatuaren azpiko alokairuan dauden etxeak**: [INE, Bizi Baldintzei buruzko Inkesta, 9997 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=9997). Inkesta bat da: erkidego txikietan lagina txikia da, eta azken hiru urteetako batez bestekoa erakusten da.
- **Nazioarteko konparazioa**: [ELGA, Affordable Housing Database, PH4.2 adierazlea](https://www.oecd.org/en/data/datasets/oecd-affordable-housing-database.html) (etxebizitza-parke osoaren %, 2010 eta 2022 inguruan, ELGAk berak kalkulatutako EBko eta ELGAko batez bestekoekin; Espainiarako enpresa-etxebizitzak ere sar daitezke) eta Ministerioaren buletineko 2.1 taula (Housing Europe eta Eurostat, ohiko etxebizitzen %).
- **Biztanleria** erroldatik (INE), 2023ko urtarrilaren 1ean, eta **etxeak** Biztanleriaren Estatistika Jarraitutik; autonomia-gobernu bakoitzaren alderdia SpainFactsen presidenteen taularen arabera.
