---
title: Public rental housing
description: "How much public rental housing there is in Spain per inhabitant and as a % of households, by region, province and municipality, compared with the Netherlands, Austria, Denmark, France and the European average, and by the party in government."
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
SELECT c.cod_ccaa, c.comunidad, '/en' || t.ruta AS ruta, c.autonomico_2019, c.autonomico_2023, c.variacion_pct_2019_2023,
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
SELECT p.cod_prov, p.provincia, p.comunidad, '/en' || t.ruta AS ruta, p.municipal_declarado, p.municipios_con_dato, p.municipios_20k,
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

# 🏘️ Public rental housing

How many homes owned by public administrations are let at below-market rents to people who meet certain requirements: those of the autonomous communities and their public companies, and those of local councils. Everything is shown **per 1,000 inhabitants or as a % of households**, so that regions and countries of very different sizes can be compared.

<Grid cols=4>
    <KpiCard
        title="Public rental homes"
        value={resumen[0]?.parque_1000}
        formattedValue="{formatNumber(resumen[0]?.parque_1000, 1)} per 1,000 inhab."
        period="Ministry estimate, 2023 · {formatCompact(resumen[0]?.parque, 0)} in total, {formatNumber(resumen[0]?.pct_hogares, 2)}% of households"
        direction="neutral"
        source="Ministry of Housing"
    />
    <KpiCard
        title="Owned by the regions"
        value={resumen[0]?.autonomico_1000_2023}
        formattedValue="{formatNumber(resumen[0]?.autonomico_1000_2023, 1)} per 1,000 inhab."
        period="2023 · {formatCompact(resumen[0]?.autonomico_2023, 0)} rental homes"
        change={resumen[0]?.autonomico_var?.toFixed(1)}
        changePeriod="vs 2019"
        direction="neutral"
        source="Ministry of Housing (social housing survey)"
        sparklineData={espana.filter(d => d.parque_autonomico_1000hab != null).map(d => d.parque_autonomico_1000hab)}
    />
    <KpiCard
        title="Households renting below market price"
        value={resumen[0]?.ecv_ultimo}
        formattedValue="{formatNumber(resumen[0]?.ecv_ultimo, 1)}%"
        period="of households, {resumen[0]?.ecv_anio} · includes reduced private rents"
        direction="neutral"
        source="INE (Living Conditions Survey)"
        sparklineData={espana.filter(d => d.ecv_pct_alquiler_inferior != null).map(d => d.ecv_pct_alquiler_inferior)}
    />
    <KpiCard
        title="Subsidised rental homes"
        value={resumen[0]?.calif_ultimo_100k}
        formattedValue="{formatNumber(resumen[0]?.calif_ultimo_100k, 1)} per 100,000 inhab."
        period="provisional approvals, {resumen[0]?.calif_anio} · {formatNumber(resumen[0]?.calif_ultimo, 0)} homes"
        direction="neutral"
        source="Ministry of Housing"
        sparklineData={calif.map(d => d.calif_alquiler_100k)}
    />
</Grid>

<Comparativa data={comparativa_internacional} decimales={1} />

## How many there are

In 2023 the Ministry of Housing asked the autonomous communities and the local councils of municipalities with more than 20,000 inhabitants how many homes they own and under what tenure. From those answers it estimates that Spain has some **{formatNumber(resumen[0]?.parque, 0)} public rental homes**: {formatNumber(resumen[0]?.autonomico_2023, 0)} owned by the regions (the sum of their answers) and about {formatNumber(resumen[0]?.municipal, 0)} owned by local councils (a figure scaled up by population, because many did not answer). That is {formatNumber(resumen[0]?.parque_1000, 1)} per 1,000 inhabitants, reaching {formatNumber(resumen[0]?.pct_hogares, 2)}% of households.

The regions' rental stock went from {formatNumber(resumen[0]?.autonomico_2019, 0)} homes in 2019 to {formatNumber(resumen[0]?.autonomico_2023, 0)} in 2023, {formatNumber(resumen[0]?.autonomico_var, 1)}% more. There is no annual series: the Ministry has only carried out these two surveys.

The INE's Living Conditions Survey provides a long series, but a broader one: it counts households paying rent **below the market price**, which includes public housing but also company flats and reduced rents between private individuals (which is why it comes out higher).

<LineChart
    data={ecv}
    x=anio
    y=pct
    series=regimen
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% of households"
    title="Renting households by the price they pay (% of all households)"
/>

## How many are started each year

**Provisional approvals** are the first administrative step for a subsidised home: they show how many are launched each year and for what use. Between 2005 and 2008 an average of {formatNumber(resumen[0]?.calif_media_boom, 0)} subsidised rental homes were approved each year; between 2013 and 2017, {formatNumber(resumen[0]?.calif_media_crisis, 0)}; between 2019 and 2023, {formatNumber(resumen[0]?.calif_media_reciente, 0)}. Not all of them are public (private companies with subsidies also develop them) and not all end up being built.

<BarChart
    data={calif}
    x=anio
    y=calif_alquiler_100k
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 100,000 inhabitants"
    title="Subsidised rental homes approved each year per 100,000 inhabitants"
/>

<LineChart
    data={calif}
    x=anio
    y=pct_calif_alquiler
    xFmt='0'
    yFmt='0'
    yAxisTitle="% of approvals"
    title="Share of rental in subsidised housing approved each year (%)"
/>

## Spain compared with other countries

The OECD gathers the figures supplied by governments themselves: social rental homes (rent below market and allocated by rules, not by price) as a **% of the total housing stock**. Spain reported {formatNumber(resumen[0]?.ocde_viviendas, 0)} in 2019, {formatNumber(resumen[0]?.ocde_pct, 1)}% of the stock, among the lowest in the OECD; the EU average is {formatNumber(ocde_ue[0]?.ue, 1)}% and the OECD average {formatNumber(ocde_ue[0]?.ocde, 1)}%.

<BarChart
    data={ocde}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of the total housing stock"
    seriesColors={{'España': '#dc2626', 'Media UE / OCDE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Social rental housing, % of the total stock (latest figure for each country)"
/>

Each country defines social housing in its own way (in the Netherlands it also covers below-market private rentals; in Austria, only main residences), so the comparison is only a guide. In the countries with the most social housing its share has fallen somewhat since 2010:

<LineChart
    data={ocde_evolucion}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% of the total stock"
    markers=true
    title="Social rental housing around 2010 and around 2022 (% of the total stock)"
/>

The Ministry also compares as a **% of households** (main residences) using data from Housing Europe and Eurostat. For Spain it uses the Living Conditions Survey, which measures something broader; the Ministry's own public stock figure is added so the two can be seen together:

<BarChart
    data={ue_hogares}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of households"
    seriesColors={{'España': '#dc2626', 'Media UE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Social rental housing in the EU, % of main residences (2023 or 2017)"
/>

## By region

Known public rental homes per 1,000 inhabitants: those of the region (complete 2023 figure) plus those of the councils of municipalities with more than 20,000 inhabitants that answered the survey (partial figure). Click on a region to see its profile.

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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'conocido_1000hab', title: 'Per 1,000 inhab. (region + councils)', fmt: '0.0'},
        {id: 'autonomico_1000hab', title: 'Region only, per 1,000 inhab.', fmt: '0.0'},
        {id: 'conocido_pct_hogares', title: '% of households', fmt: '0.00'},
        {id: 'variacion_pct_2019_2023', title: 'Regional stock, change 2019-2023 (%)', fmt: '0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=conocido_1000hab title="Per 1,000 inhab." fmt='0.0' />
    <Column id=conocido_pct_hogares title="% households" fmt='0.00' />
    <Column id=autonomico_2023 title="Owned by the region (2023)" fmt='#,##0' />
    <Column id=variacion_pct_2019_2023 title="Change 2019-2023 %" fmt='0' contentType=delta />
    <Column id=municipal_declarado title="Owned by councils (reported)" fmt='#,##0' />
    <Column id=cobertura_municipal_pct title="% population with council data" fmt='0' />
    <Column id=ecv_pct_alquiler_inferior_3a title="% households below market (LCS, 3 years)" fmt='0.0' />
</DataTable>

Excluding Ceuta and Melilla, the largest regional rental stocks per inhabitant are those of {ccaa_extremos[0]?.mas}; the smallest, those of {ccaa_extremos[0]?.menos}. In {ccaa_extremos[0]?.mas_venta?.replace(' y ', ' and ')} the region has more homes intended for sale than for rent, and in others public-private partnership carries weight (public land with surface rights or a concession): it accounts for {formatNumber(ccaa_extremos[0]?.ppp_pv, 0)}% of the regional rental stock in the Basque Country and {formatNumber(ccaa_extremos[0]?.ppp_madrid, 0)}% in Madrid.

<BarChart
    data={ccaa}
    x=comunidad
    y=calif_alquiler_2005_2023_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="per 1,000 inhabitants"
    title="Subsidised rental homes approved between 2005 and 2023, per 1,000 current inhabitants"
/>

## By province

There is no official count of the regional stock by province: the regions report it as a single block. What is known by province is the **municipal rental stock reported by the councils of municipalities with more than 20,000 inhabitants** ({cobertura_mun[0]?.respondieron} answered in 2023, {cobertura_mun[0]?.dato_2019} repeat their 2019 figure and {cobertura_mun[0]?.sin_dato} gave no figures). The map shows it per 1,000 inhabitants of the province; a blank province may have regional stock, or municipalities that did not answer.

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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'municipal_1000hab', title: 'Municipal rental housing per 1,000 inhab.', fmt: '0.00'},
        {id: 'municipal_declarado', title: 'Municipal homes reported', fmt: '#,##0'},
        {id: 'cobertura_pct', title: '% of population in municipalities with data', fmt: '0'},
        {id: 'conocido_1000hab', title: 'Including the regional stock (single-province regions)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Province" />
    <Column id=comunidad title="Region" />
    <Column id=municipal_1000hab title="Municipal per 1,000 inhab." fmt='0.00' />
    <Column id=municipal_declarado title="Municipal homes" fmt='#,##0' />
    <Column id=municipios_con_dato title="Municipalities with data" fmt='0' />
    <Column id=municipios_20k title="Municipalities over 20,000 inhab." fmt='0' />
    <Column id=cobertura_pct title="% population with data" fmt='0' />
</DataTable>

In the single-province regions (and in Ceuta and Melilla) the regional stock is provincial and can be added to the municipal stock:

<DataTable data={uniprovinciales} rows=9>
    <Column id=provincia title="Province" />
    <Column id=conocido_1000hab title="Per 1,000 inhab. (region + councils)" fmt='0.0' />
    <Column id=autonomico_2023 title="Owned by the region" fmt='#,##0' />
    <Column id=municipal_declarado title="Owned by councils (reported)" fmt='#,##0' />
</DataTable>

<EnConstruccion motivo="the regions' housing stock by province is not published: the Ministry's survey only collects it by region. Some regional housing companies (the Agència de l'Habitatge de Catalunya, Alokabide, the Andalusian AVRA...) publish their stock by municipality in different formats; integrating them would give the complete provincial map." />

## By municipality

Homes owned by local councils and their municipal companies (not including regional homes located in the municipality), in municipalities with more than 20,000 inhabitants with data.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=alquiler title="For rent" fmt='#,##0' />
    <Column id=alquiler_1000hab title="Per 1,000 inhab." fmt='0.0' />
    <Column id=total title="Total municipal stock" fmt='#,##0' />
    <Column id=poblacion title="Population" fmt='#,##0' />
    <Column id=dato title="Figure from" />
</DataTable>

## By party

Subsidised housing is approved by the autonomous communities, although much of it is funded through the state housing plans. Adding up regions and years between {gobiernos[0]?.anio_desde} and {gobiernos[0]?.anio_hasta}, and assigning each year to the party governing the region on 1 July, the share of subsidised rental homes approved under each party is compared with the share of the population it governed (if all of them promoted the same amount per inhabitant, the ratio would be 1). Under the PP the ratio is {formatNumber(pp_psoe[0]?.pp, 2)} ({formatNumber(pp_psoe[0]?.pp_100k, 1)} homes per 100,000 inhabitants per year) and under the PSOE, {formatNumber(pp_psoe[0]?.psoe, 2)} ({formatNumber(pp_psoe[0]?.psoe_100k, 1)}).

<DataTable data={gobiernos} rows=12>
    <Column id=partido title="Party in government" />
    <Column id=anios_comunidad title="Years in government (region x year)" fmt='0' />
    <Column id=calif_alquiler title="Rental homes approved" fmt='#,##0' />
    <Column id=calif_alquiler_100k_anio title="Per 100,000 inhab. per year" fmt='0.0' />
    <Column id=cuota_calif title="% of approvals" fmt='0.0' />
    <Column id=cuota_poblacion title="% of population governed" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observed / expected" fmt='0.00' />
</DataTable>

<BarChart
    data={calif_partido_anio}
    x=anio
    y=calif_alquiler
    series=partido
    xFmt='0'
    yFmt='#,##0'
    seriesColors={Object.fromEntries(gobiernos.map(d => [d.partido, d.color]))}
    title="Subsidised rental homes approved each year, by the party governing each region"
/>

Change in the regional rental stock between 2019 and 2023, grouping the regions by the party that governed them halfway through that period:

<DataTable data={parque_partido} rows=10>
    <Column id=partido title="Party (July 2021)" />
    <Column id=comunidades title="Regions" fmt='0' />
    <Column id=parque_2019 title="Stock 2019" fmt='#,##0' />
    <Column id=parque_2023 title="Stock 2023" fmt='#,##0' />
    <Column id=variacion_pct title="Change %" fmt='0.0' contentType=delta />
    <Column id=variacion_1000hab title="Change per 1,000 inhab." fmt='0.00' contentType=delta />
    <Column id=lista title="Regions" wrap=true />
</DataTable>

This should be read with caution: there are few years and few regions per party, housing takes years to go from approval to handover (many homes delivered in one term were decided in the previous one), and the stock also changes through sales to tenants, transfers between administrations or different counts in each survey. Homes do not arrive one by one but in developments, so a statistical test like those on other pages makes no sense.

## Methodology and sources

- **Public rental stock**: [Ministry of Housing and Urban Agenda, Housing and Land Observatory, Special Bulletin on Social Housing 2024](https://www.mivau.gob.es/urbanismo-y-suelo/suelo/observatorio-de-vivienda-y-suelo) (2023 social housing survey and, for 2019, the 2019 survey). "For rent" includes publicly owned homes and those under public-private partnership (public land with surface rights or a concession), low-cost assignment and temporary accommodation; it excludes rent-to-buy and sale. The 2023 national total is the sum of the regions (the bulletin gives a slightly lower figure in its trend table). The municipal stock only covers the councils of municipalities with more than 20,000 inhabitants that answered (or their 2019 figure if they did not); the Ministry scales it up by population for its national estimate. In Ceuta and Melilla the city is both region and council, and its stock is counted once.
- **Provisional approvals** of subsidised housing by tenure and region, 2005-2023, from the same bulletin.
- **Households renting below market price**: [INE, Living Conditions Survey, table 9997](https://www.ine.es/jaxiT3/Tabla.htm?t=9997). It is a survey: in the small regions the sample is small and the average of the last three years is shown.
- **International comparison**: [OECD, Affordable Housing Database, indicator PH4.2](https://www.oecd.org/en/data/datasets/oecd-affordable-housing-database.html) (% of the total housing stock, around 2010 and around 2022, with the OECD's own EU and OECD averages; for Spain it may include company housing) and table 2.1 of the Ministry's bulletin (Housing Europe and Eurostat, % of main residences).
- **Population** from the municipal register (INE) at 1 January 2023 and **households** from the Continuous Population Statistics; party of each regional government according to the SpainFacts table of presidents.
