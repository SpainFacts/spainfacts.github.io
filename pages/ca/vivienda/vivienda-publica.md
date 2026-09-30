---
title: Habitatge públic de lloguer
description: "Quants habitatges públics de lloguer hi ha a Espanya per habitant i en % de les llars, per comunitat, província i municipi, comparats amb els Països Baixos, Àustria, Dinamarca, França i la mitjana europea, i segons el partit que governava."
i18n_origen: 4f3c32fd277f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import EnConstruccion from '../../../../../../../src/lib/components/EnConstruccion.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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
SELECT c.cod_ccaa, c.comunidad, '/ca' || t.ruta AS ruta, c.autonomico_2019, c.autonomico_2023, c.variacion_pct_2019_2023,
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
SELECT max(valor) FILTER (WHERE cod_pais = 'EUU') AS ue, max(valor) FILTER (WHERE cod_pais = 'OED') AS ocde
FROM mother.vivienda_publica_internacional
WHERE serie = 'ocde_pct_parque' AND es_ultimo
```

```sql provincias
SELECT p.cod_prov, p.provincia, p.comunidad, '/ca' || t.ruta AS ruta, p.municipal_declarado, p.municipios_con_dato, p.municipios_20k,
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
SELECT pais, anio, valor, CAST(viviendas_sociales AS INTEGER) AS viviendas_sociales,
       CASE WHEN es_espana THEN 'España' WHEN es_agregado THEN 'Media UE / OCDE' ELSE 'Otros países' END AS grupo
FROM mother.vivienda_publica_internacional
WHERE serie = 'ocde_pct_parque' AND es_ultimo
ORDER BY valor DESC
```

```sql ocde_evolucion
SELECT pais, anio, valor
FROM mother.vivienda_publica_internacional
WHERE serie = 'ocde_pct_parque' AND destacado AND NOT es_agregado
ORDER BY pais, anio
```

```sql ue_hogares
SELECT pais, anio, valor,
       CASE WHEN es_espana THEN 'España' WHEN es_agregado THEN 'Media UE' ELSE 'Otros países' END AS grupo
FROM mother.vivienda_publica_internacional
WHERE serie = 'ue_pct_hogares'
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

# 🏘️ Habitatge públic de lloguer

Quants habitatges de les administracions es lloguen a preus per sota dels de mercat a qui compleix determinats requisits: els de les comunitats autònomes i les seves empreses públiques i els dels ajuntaments. Tot es mostra **per cada 1.000 habitants o en % de les llars**, per poder comparar comunitats i països de mida molt diferent.

<Grid cols=4>
    <KpiCard
        title="Habitatges públics de lloguer"
        value={resumen[0]?.parque_1000}
        formattedValue="{formatNumber(resumen[0]?.parque_1000, 1)} per 1.000 hab."
        period="estimació del Ministeri, 2023 · {formatCompact(resumen[0]?.parque, 0)} en total, un {formatNumber(resumen[0]?.pct_hogares, 2)} % de les llars"
        direction="neutral"
        source="Ministeri d'Habitatge"
    />
    <KpiCard
        title="De les comunitats autònomes"
        value={resumen[0]?.autonomico_1000_2023}
        formattedValue="{formatNumber(resumen[0]?.autonomico_1000_2023, 1)} per 1.000 hab."
        period="2023 · {formatCompact(resumen[0]?.autonomico_2023, 0)} habitatges de lloguer"
        change={resumen[0]?.autonomico_var?.toFixed(1)}
        changePeriod="vs. 2019"
        direction="neutral"
        source="Ministeri d'Habitatge (enquesta d'habitatge social)"
        sparklineData={espana.filter(d => d.parque_autonomico_1000hab != null).map(d => d.parque_autonomico_1000hab)}
    />
    <KpiCard
        title="Llars amb lloguer per sota de mercat"
        value={resumen[0]?.ecv_ultimo}
        formattedValue="{formatNumber(resumen[0]?.ecv_ultimo, 1)} %"
        period="de les llars, {resumen[0]?.ecv_anio} · inclou lloguers reduïts privats"
        direction="neutral"
        source="INE (Enquesta de Condicions de Vida)"
        sparklineData={espana.filter(d => d.ecv_pct_alquiler_inferior != null).map(d => d.ecv_pct_alquiler_inferior)}
    />
    <KpiCard
        title="Habitatges protegits de lloguer"
        value={resumen[0]?.calif_ultimo_100k}
        formattedValue="{formatNumber(resumen[0]?.calif_ultimo_100k, 1)} per 100.000 hab."
        period="qualificacions provisionals, {resumen[0]?.calif_anio} · {formatNumber(resumen[0]?.calif_ultimo, 0)} habitatges"
        direction="neutral"
        source="Ministeri d'Habitatge"
        sparklineData={calif.map(d => d.calif_alquiler_100k)}
    />
</Grid>

<Comparativa data={comparativa_internacional} decimales={1} />

## Quants n'hi ha

El 2023 el Ministeri d'Habitatge va preguntar a les comunitats autònomes i als ajuntaments de més de 20.000 habitants quants habitatges tenen i en quin règim. Amb aquestes respostes estima que a Espanya hi ha uns **{formatNumber(resumen[0]?.parque, 0)} habitatges públics de lloguer**: {formatNumber(resumen[0]?.autonomico_2023, 0)} de les comunitats (suma de les seves respostes) i uns {formatNumber(resumen[0]?.municipal, 0)} dels ajuntaments (una xifra escalada per població, perquè molts no van respondre). Són {formatNumber(resumen[0]?.parque_1000, 1)} per cada 1.000 habitants i arriben a un {formatNumber(resumen[0]?.pct_hogares, 2)} % de les llars.

El parc de lloguer de les comunitats va créixer: {formatNumber(resumen[0]?.autonomico_2019, 0)} habitatges el 2019 i {formatNumber(resumen[0]?.autonomico_2023, 0)} el 2023, un {formatNumber(resumen[0]?.autonomico_var, 1)} % més. No hi ha una sèrie anual: el Ministeri només ha fet aquestes dues enquestes.

L'Enquesta de Condicions de Vida de l'INE dona una sèrie llarga, però més àmplia: compta les llars que paguen un lloguer **per sota del preu de mercat**, cosa que inclou l'habitatge públic però també pisos d'empresa o lloguers reduïts entre particulars (per això surt més alta).

<LineChart
    data={ecv}
    x=anio
    y=pct
    series=regimen
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% de les llars"
    title="Llars de lloguer segons el preu que paguen (% del total de llars)"
/>

## Quants se'n promouen cada any

Les **qualificacions provisionals** són el primer pas administratiu d'un habitatge protegit: quants se'n posen en marxa cada any i amb quina destinació. Entre 2005 i 2008 es qualificaven de mitjana {formatNumber(resumen[0]?.calif_media_boom, 0)} habitatges protegits de lloguer l'any; entre 2013 i 2017, {formatNumber(resumen[0]?.calif_media_crisis, 0)}; entre 2019 i 2023, {formatNumber(resumen[0]?.calif_media_reciente, 0)}. No tots són públics (també els promouen empreses privades amb ajudes) ni tots s'acaben construint.

<BarChart
    data={calif}
    x=anio
    y=calif_alquiler_100k
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 100.000 habitants"
    title="Habitatges protegits de lloguer qualificats cada any per 100.000 habitants"
/>

<LineChart
    data={calif}
    x=anio
    y=pct_calif_alquiler
    xFmt='0'
    yFmt='0'
    yAxisTitle="% de les qualificacions"
    title="Pes del lloguer en l'habitatge protegit qualificat cada any (%)"
/>

## Espanya davant d'altres països

L'OCDE aplega les xifres que donen els mateixos governs: habitatges socials de lloguer (renda per sota de mercat i adjudicats per regles, no per preu) en **% de tot el parc d'habitatges**. Espanya en va declarar {formatNumber(resumen[0]?.ocde_viviendas, 0)} el 2019, un {formatNumber(resumen[0]?.ocde_pct, 1)} % del parc, entre els més baixos de l'OCDE; la mitjana de la UE és un {formatNumber(ocde_ue[0]?.ue, 1)} % i la de l'OCDE, un {formatNumber(ocde_ue[0]?.ocde, 1)} %.

<BarChart
    data={ocde}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% del parc total d'habitatges"
    seriesColors={{'España': '#dc2626', 'Media UE / OCDE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Habitatges socials de lloguer, % del parc total (última dada de cada país)"
/>

Cada país defineix l'habitatge social a la seva manera (als Països Baixos compta també lloguer privat per sota de mercat; a Àustria, només habitatges principals), de manera que la comparació és orientativa. Als països amb més habitatge social el pes ha baixat una mica des del 2010:

<LineChart
    data={ocde_evolucion}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% del parc total"
    markers=true
    title="Habitatge social de lloguer cap al 2010 i cap al 2022 (% del parc total)"
/>

El Ministeri també compara en **% de les llars** (habitatges principals) amb dades de Housing Europe i Eurostat. Per a Espanya fa servir l'ECV, que mesura una cosa més àmplia; s'hi afegeix la xifra del parc públic del mateix Ministeri per veure-les juntes:

<BarChart
    data={ue_hogares}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de les llars"
    seriesColors={{'España': '#dc2626', 'Media UE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Habitatge de lloguer social a la UE, % dels habitatges principals (2023 o 2017)"
/>

## Per comunitat

Habitatges públics de lloguer coneguts per cada 1.000 habitants: els de la comunitat (dada completa del 2023) més els dels ajuntaments de més de 20.000 habitants que van respondre l'enquesta (dada parcial). Fes clic en una comunitat per veure'n la fitxa.

<AreaMap
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'conocido_1000hab', title: 'Per 1.000 hab. (comunitat + ajuntaments)', fmt: '0.0'},
        {id: 'autonomico_1000hab', title: 'Només de la comunitat, per 1.000 hab.', fmt: '0.0'},
        {id: 'conocido_pct_hogares', title: '% de les llars', fmt: '0.00'},
        {id: 'variacion_pct_2019_2023', title: 'Parc autonòmic, var. 2019-2023 (%)', fmt: '0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=conocido_1000hab title="Per 1.000 hab." fmt='0.0' />
    <Column id=conocido_pct_hogares title="% llars" fmt='0.00' />
    <Column id=autonomico_2023 title="De la comunitat (2023)" fmt='#,##0' />
    <Column id=variacion_pct_2019_2023 title="Var. 2019-2023 %" fmt='0' contentType=delta />
    <Column id=municipal_declarado title="D'ajuntaments (declarat)" fmt='#,##0' />
    <Column id=cobertura_municipal_pct title="% població amb dada municipal" fmt='0' />
    <Column id=ecv_pct_alquiler_inferior_3a title="% llars sota mercat (ECV, 3 anys)" fmt='0.0' />
</DataTable>

Sense comptar Ceuta i Melilla, els parcs autonòmics de lloguer més grans per habitant són els de {ccaa_extremos[0]?.mas}; els més petits, els de {ccaa_extremos[0]?.menos}. A {ccaa_extremos[0]?.mas_venta?.replace(' y ', ' i ')} la comunitat té més habitatges destinats a la venda que al lloguer, i en altres pesa la col·laboració publicoprivada (sòl públic amb dret de superfície o concessió): és un {formatNumber(ccaa_extremos[0]?.ppp_pv, 0)} % del parc autonòmic de lloguer del País Basc i un {formatNumber(ccaa_extremos[0]?.ppp_madrid, 0)} % del de Madrid.

<BarChart
    data={ccaa}
    x=comunidad
    y=calif_alquiler_2005_2023_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="per 1.000 habitants"
    title="Habitatges protegits de lloguer qualificats entre 2005 i 2023, per 1.000 habitants d'avui"
/>

## Per província

No existeix un recompte oficial del parc autonòmic per província: les comunitats el declaren en bloc. El que sí que es coneix per província és el **parc municipal de lloguer que van declarar els ajuntaments de més de 20.000 habitants** ({cobertura_mun[0]?.respondieron} van respondre el 2023, {cobertura_mun[0]?.dato_2019} repeteixen la dada del 2019 i {cobertura_mun[0]?.sin_dato} no van donar xifres). El mapa el mostra per 1.000 habitants de la província; una província en blanc pot tenir parc autonòmic, o municipis que no van respondre.

<AreaMap
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'municipal_1000hab', title: 'Habitatge municipal de lloguer per 1.000 hab.', fmt: '0.00'},
        {id: 'municipal_declarado', title: 'Habitatges municipals declarats', fmt: '#,##0'},
        {id: 'cobertura_pct', title: '% de la població en municipis amb dada', fmt: '0'},
        {id: 'conocido_1000hab', title: 'Amb el parc autonòmic (uniprovincials)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Província" />
    <Column id=comunidad title="Comunitat" />
    <Column id=municipal_1000hab title="Municipal per 1.000 hab." fmt='0.00' />
    <Column id=municipal_declarado title="Habitatges municipals" fmt='#,##0' />
    <Column id=municipios_con_dato title="Municipis amb dada" fmt='0' />
    <Column id=municipios_20k title="Municipis de més de 20.000 hab." fmt='0' />
    <Column id=cobertura_pct title="% població amb dada" fmt='0' />
</DataTable>

A les comunitats d'una sola província (i a Ceuta i Melilla) el parc autonòmic sí que és provincial i es pot sumar al municipal:

<DataTable data={uniprovinciales} rows=9>
    <Column id=provincia title="Província" />
    <Column id=conocido_1000hab title="Per 1.000 hab. (comunitat + ajuntaments)" fmt='0.0' />
    <Column id=autonomico_2023 title="De la comunitat" fmt='#,##0' />
    <Column id=municipal_declarado title="D'ajuntaments (declarat)" fmt='#,##0' />
</DataTable>

<EnConstruccion motivo="el parc d'habitatge de les comunitats per província no es publica: l'enquesta del Ministeri el recull només per comunitat. Algunes empreses autonòmiques (l'Agència de l'Habitatge de Catalunya, Alokabide, l'AVRA andalusa...) publiquen el seu parc per municipi en formats diferents; integrar-les donaria el mapa provincial complet." />

## Per municipi

Habitatges dels ajuntaments i les seves empreses municipals (no inclou els de la comunitat situats al municipi), als municipis de més de 20.000 habitants amb dada.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=alquiler title="De lloguer" fmt='#,##0' />
    <Column id=alquiler_1000hab title="Per 1.000 hab." fmt='0.0' />
    <Column id=total title="Total del parc municipal" fmt='#,##0' />
    <Column id=poblacion title="Població" fmt='#,##0' />
    <Column id=dato title="Dada de" />
</DataTable>

## Per partit

L'habitatge protegit el qualifiquen les comunitats autònomes, tot i que bona part es finança amb els plans estatals d'habitatge. Sumant comunitats i anys entre {gobiernos[0]?.anio_desde} i {gobiernos[0]?.anio_hasta}, i atribuint cada any al partit que governava la comunitat l'1 de juliol, es compara la part dels habitatges protegits de lloguer qualificats amb cada partit amb la part de la població que va governar (si tots en promoguessin els mateixos per habitant, la raó seria 1). Amb el PP la raó és {formatNumber(pp_psoe[0]?.pp, 2)} ({formatNumber(pp_psoe[0]?.pp_100k, 1)} habitatges per 100.000 habitants i any) i amb el PSOE, {formatNumber(pp_psoe[0]?.psoe, 2)} ({formatNumber(pp_psoe[0]?.psoe_100k, 1)}).

<DataTable data={gobiernos} rows=12>
    <Column id=partido title="Partit que governava" />
    <Column id=anios_comunidad title="Anys de govern (comunitat x any)" fmt='0' />
    <Column id=calif_alquiler title="Habitatges de lloguer qualificats" fmt='#,##0' />
    <Column id=calif_alquiler_100k_anio title="Per 100.000 hab. i any" fmt='0.0' />
    <Column id=cuota_calif title="% dels qualificats" fmt='0.0' />
    <Column id=cuota_poblacion title="% de la població governada" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observat / esperat" fmt='0.00' />
</DataTable>

<BarChart
    data={calif_partido_anio}
    x=anio
    y=calif_alquiler
    series=partido
    xFmt='0'
    yFmt='#,##0'
    seriesColors={Object.fromEntries(gobiernos.map(d => [d.partido, d.color]))}
    title="Habitatges protegits de lloguer qualificats cada any, segons el partit que governava cada comunitat"
/>

Canvi del parc autonòmic de lloguer entre 2019 i 2023, agrupant les comunitats pel partit que les governava a la meitat d'aquest període:

<DataTable data={parque_partido} rows=10>
    <Column id=partido title="Partit (juliol de 2021)" />
    <Column id=comunidades title="Comunitats" fmt='0' />
    <Column id=parque_2019 title="Parc 2019" fmt='#,##0' />
    <Column id=parque_2023 title="Parc 2023" fmt='#,##0' />
    <Column id=variacion_pct title="Var. %" fmt='0.0' contentType=delta />
    <Column id=variacion_1000hab title="Var. per 1.000 hab." fmt='0.00' contentType=delta />
    <Column id=lista title="Comunitats" wrap=true />
</DataTable>

Cal llegir-ho amb cautela: són pocs anys i poques comunitats per partit, l'habitatge triga anys a passar de la qualificació al lliurament (molts habitatges d'un mandat els va decidir l'anterior), i el parc també canvia per vendes als inquilins, traspassos entre administracions o recomptes diferents en cada enquesta. Els habitatges no arriben un a un sinó en promocions, de manera que no té sentit una prova estadística com en altres pàgines.

## Metodologia i fonts

- **Parc públic de lloguer**: [Ministeri d'Habitatge i Agenda Urbana, Observatori d'Habitatge i Sòl, Butlletí especial Habitatge Social 2024](https://www.mivau.gob.es/urbanismo-y-suelo/suelo/observatorio-de-vivienda-y-suelo) (Enquesta sobre habitatge social del 2023 i, per al 2019, la del 2019). «De lloguer» inclou els habitatges de titularitat pública i els de col·laboració publicoprivada (sòl públic amb dret de superfície o concessió), la cessió a preu baix i l'allotjament temporal; no inclou el lloguer amb opció de compra ni la venda. El total nacional del 2023 és la suma de les comunitats (el butlletí dona una xifra una mica menor a la seva taula d'evolució). El parc municipal només recull els ajuntaments de més de 20.000 habitants que van respondre (o la seva dada del 2019 si no ho van fer); el Ministeri l'escala per població per a la seva estimació nacional. A Ceuta i Melilla la ciutat és alhora comunitat i ajuntament i el seu parc es compta una sola vegada.
- **Qualificacions provisionals** d'habitatge protegit per règim d'ús i comunitat, 2005-2023, del mateix butlletí.
- **Llars de lloguer per sota de mercat**: [INE, Enquesta de Condicions de Vida, taula 9997](https://www.ine.es/jaxiT3/Tabla.htm?t=9997). És una enquesta: a les comunitats petites la mostra és reduïda i es mostra la mitjana dels tres últims anys.
- **Comparació internacional**: [OCDE, Affordable Housing Database, indicador PH4.2](https://www.oecd.org/en/data/datasets/oecd-affordable-housing-database.html) (% del parc total d'habitatges, cap al 2010 i cap al 2022, amb les mitjanes UE i OCDE de la mateixa OCDE; per a Espanya pot incloure habitatges d'empresa) i la taula 2.1 del butlletí del Ministeri (Housing Europe i Eurostat, % dels habitatges principals).
- **Població** del padró (INE) a 1 de gener de 2023 i **llars** de l'Estadística Contínua de Població; partit de cada Govern autonòmic segons la taula de presidents de SpainFacts.
