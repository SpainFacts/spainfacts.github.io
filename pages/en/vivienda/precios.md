---
title: House prices
description: "House prices in Spain adjusted for inflation: appraised value per square metre by region, province and municipality and the INE House Price Index, new and second-hand."
i18n_origen: 058fd706b1df
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql precio
SELECT fecha, periodo, anio, euros_m2, euros_m2_real, precio_90m2_real, interanual_real, interanual_nominal, anio_base
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
ORDER BY fecha
```

```sql ipv
SELECT fecha, periodo, tipo, indice, indice_real, interanual_real, interanual_nominal
FROM mother.vivienda_ipv
WHERE nivel = 'pais'
ORDER BY fecha, tipo
```

```sql ipv_general
SELECT * FROM ${ipv} WHERE tipo = 'General' ORDER BY fecha
```

```sql ipv_interanual
SELECT fecha, 'Nominal' AS tipo, interanual_nominal AS variacion FROM ${ipv_general} WHERE interanual_nominal IS NOT NULL
UNION ALL
SELECT fecha, 'Real' AS tipo, interanual_real AS variacion FROM ${ipv_general} WHERE interanual_real IS NOT NULL
ORDER BY fecha, tipo
```

```sql ipv_hitos
SELECT
    arg_max(periodo, fecha) AS periodo_ult,
    arg_max(indice_real, fecha) AS real_ult,
    max(indice_real) AS real_max,
    arg_max(periodo, indice_real) AS periodo_max,
    100 * (arg_max(indice_real, fecha) / max(indice_real) - 1) AS vs_max,
    100 * (arg_max(indice, fecha) / max(indice) - 1) AS vs_max_nominal
FROM ${ipv_general}
```

```sql nueva_usada
SELECT
    max(interanual_real) FILTER (WHERE tipo = 'Nueva') AS nueva,
    max(interanual_real) FILTER (WHERE tipo = 'Segunda mano') AS usada,
    max(periodo) AS periodo
FROM ${ipv}
WHERE fecha = (SELECT max(fecha) FROM ${ipv})
```

```sql lista_ccaa
SELECT cod, nombre FROM mother.vivienda_resumen_territorios WHERE nivel = 'ccaa' ORDER BY nombre
```

<Dropdown name=ccaa_precio data={lista_ccaa} value=cod label=nombre defaultValue="13" title="Region" />

```sql ccaa_serie
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${inputs.ccaa_precio.value}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/en' || r.ruta AS ruta, r.precio_periodo, r.euros_m2_real, r.precio_90m2_real,
       r.precio_interanual_real, r.precio_vs_maximo_real, r.precio_periodo_maximo
FROM mother.vivienda_resumen_territorios r
WHERE r.nivel = 'provincia'
ORDER BY r.euros_m2_real DESC
```

```sql prov_extremos
SELECT
    arg_max(provincia, euros_m2_real) AS cara,
    max(euros_m2_real) AS cara_valor,
    arg_min(provincia, euros_m2_real) AS barata,
    min(euros_m2_real) AS barata_valor,
    max(euros_m2_real) / min(euros_m2_real) AS veces,
    count(*) FILTER (WHERE precio_vs_maximo_real >= 0) AS en_maximos,
    max(precio_periodo) AS periodo
FROM ${provincias}
```

```sql municipios
SELECT m.municipio, p.nombre AS provincia, m.poblacion, m.euros_m2_real, m.precio_90m2_real, m.variacion_real, m.tasaciones, m.anio
FROM mother.vivienda_precio_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.vivienda_precio_municipios WHERE trimestres = 4)
ORDER BY m.euros_m2_real DESC
```

# 💶 House prices

How much it costs to buy a home in Spain and how that has changed. There are two complementary official sources: the Ministry of Housing's **appraised value**, which gives euros per square metre and goes down to provinces and municipalities, and the INE's **House Price Index**, which tracks the prices of notarised sales at constant quality. Everything is shown **adjusted for inflation**, in {precio[0]?.anio_base} euros.

<Grid cols=4>
    <KpiCard
        title="Appraised value"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="Spain, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.euros_m2, 0)} €/m² not adjusted for inflation"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real vs a year earlier"
        source="Ministry of Housing"
        sparklineData={precio.map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Real price growth"
        value={ipv_general.slice(-1)[0]?.interanual_real}
        formattedValue="{ipv_general.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(ipv_general.slice(-1)[0]?.interanual_real, 1)} %"
        period="HPI, {ipv_general.slice(-1)[0]?.periodo} vs a year earlier · {formatNumber(ipv_general.slice(-1)[0]?.interanual_nominal, 1)} % not adjusted for inflation"
        source="INE / HPI"
        sparklineData={ipv_general.filter(d => d.interanual_real != null).map(d => d.interanual_real)}
    />
    <KpiCard
        title="Versus the bubble peak"
        value={ipv_hitos[0]?.vs_max}
        formattedValue="{ipv_hitos[0]?.vs_max >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max, 1)} %"
        period="real price vs {ipv_hitos[0]?.periodo_max} (HPI) · {ipv_hitos[0]?.vs_max_nominal >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max_nominal, 1)} % in euros of each year"
        source="INE / HPI"
        sparklineData={ipv_general.map(d => d.indice_real)}
    />
    <KpiCard
        title="90 m² flat"
        value={precio.slice(-1)[0]?.precio_90m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} thousand €"
        period="at Spain's average appraised value, {precio.slice(-1)[0]?.periodo}"
        source="Ministry of Housing"
        sparklineData={precio.map(d => d.precio_90m2_real)}
    />
</Grid>

## Real price trend

INE House Price Index adjusted for inflation (2015 = 100). The real peak of the series, which starts in 2007, was in {ipv_hitos[0]?.periodo_max}; in {ipv_hitos[0]?.periodo_ult} the real price is {#if ipv_hitos[0]?.vs_max < 0}{formatNumber(-ipv_hitos[0]?.vs_max, 1)} % below it{:else}at a record high{/if}. In the latest quarter, new homes rose by {formatNumber(nueva_usada[0]?.nueva, 1)} % in real terms and second-hand homes by {formatNumber(nueva_usada[0]?.usada, 1)} %.

<LineChart
    data={ipv}
    x=fecha
    y=indice_real
    series=tipo
    yFmt='0.0'
    yAxisTitle="real index, 2015 = 100"
    startingAtZero={false}
    title="House Price Index adjusted for inflation (2015 = 100)"
/>

<BarChart
    data={ipv_interanual}
    x=fecha
    y=variacion
    series=tipo
    type=grouped
    yFmt='0.0"%"'
    yAxisTitle="% year on year"
    title="Year-on-year change in house prices: nominal and real (general HPI)"
/>

## By region

Appraised value per square metre in the selected region compared with Spain, in {precio[0]?.anio_base} euros.

<LineChart
    data={ccaa_serie}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (real)"
    startingAtZero={false}
    title="Real appraised value: region compared with Spain"
/>

## By province

In {prov_extremos[0]?.periodo} the province with the most expensive square metre is {prov_extremos[0]?.cara} ({formatNumber(prov_extremos[0]?.cara_valor, 0)} €/m²) and the cheapest is {prov_extremos[0]?.barata} ({formatNumber(prov_extremos[0]?.barata_valor, 0)} €/m²): a square metre in the former costs {formatNumber(prov_extremos[0]?.veces, 1)} times as much. {#if prov_extremos[0]?.en_maximos == 1}Only one province is{:else}{prov_extremos[0]?.en_maximos} provinces are{/if} at their highest real level since 2002.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="euros_m2_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Real annual change (%)', fmt: '0.0'},
        {id: 'precio_vs_maximo_real', title: 'Versus its real peak (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Province" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="90 m² flat (€)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Real annual chg. %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Vs. real peak %" fmt='0.0' />
    <Column id=precio_periodo_maximo title="Real peak in" />
</DataTable>

## Municipalities with more than 25,000 inhabitants

Average appraised value for {municipios[0]?.anio} (average of its four quarters, weighted by the number of appraisals), in {precio[0]?.anio_base} euros. With few appraisals the figure is less reliable.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="90 m² flat (€)" fmt='#,##0' />
    <Column id=variacion_real title="Real annual chg. %" fmt='0.0' contentType=delta />
    <Column id=tasaciones title="Appraisals" fmt='#,##0' />
    <Column id=poblacion title="Inhabitants" fmt='#,##0' />
</DataTable>

---

**Sources:** [Ministry of Housing and Urban Agenda, appraised value of open-market housing](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (tables 1 and 5, based on mortgage appraisals; average value of all open-market housing, new and used) and [INE, House Price Index, table 25171](https://www.ine.es/jaxiT3/Tabla.htm?t=25171) (base 2015, based on notarised sales). Deflated with the INE general CPI (base 2025), quarter by quarter.
