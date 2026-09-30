---
title: Home sales and mortgages
description: "Home sales and mortgages on homes in Spain per 1,000 inhabitants, new builds versus second-hand and average mortgage amount adjusted for inflation, by region and province."
i18n_origen: f88105740a74
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql mensual
SELECT fecha, strftime(fecha, '%m/%Y') AS mes_texto, compraventas_12m, compraventas_12m_1000, hipotecas_12m, hipotecas_12m_1000,
       importe_medio, importe_medio_real, anio_base
FROM mother.vivienda_mercado_mensual
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql movil_largo
SELECT fecha, 'Compraventas' AS operacion, compraventas_12m_1000 AS por_1000 FROM ${mensual} WHERE compraventas_12m_1000 IS NOT NULL
UNION ALL
SELECT fecha, 'Hipotecas sobre viviendas' AS operacion, hipotecas_12m_1000 AS por_1000 FROM ${mensual} WHERE hipotecas_12m_1000 IS NOT NULL
ORDER BY fecha, operacion
```

```sql ultimo
SELECT
    u.mes_texto,
    u.compraventas_12m,
    u.compraventas_12m_1000,
    u.hipotecas_12m,
    u.hipotecas_12m_1000,
    100 * (u.compraventas_12m_1000 / a.compraventas_12m_1000 - 1) AS var_cv,
    100 * (u.hipotecas_12m_1000 / a.hipotecas_12m_1000 - 1) AS var_h
FROM ${mensual} u
LEFT JOIN ${mensual} a ON a.fecha = u.fecha - INTERVAL 1 YEAR
WHERE u.compraventas_12m_1000 IS NOT NULL
ORDER BY u.fecha DESC
LIMIT 1
```

```sql anual
SELECT anio, meses, compraventas, compraventas_1000, compraventas_nueva_1000, compraventas_segunda_mano_1000,
       hipotecas, hipotecas_1000, importe_medio, importe_medio_real, pct_nueva, pct_protegida, pct_hipoteca, anio_base
FROM mother.vivienda_mercado_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual_completo
SELECT * FROM ${anual} WHERE meses = 12
```

```sql nueva_usada
SELECT anio, 'Nueva' AS tipo, compraventas_nueva_1000 AS por_1000 FROM ${anual_completo}
UNION ALL
SELECT anio, 'Segunda mano' AS tipo, compraventas_segunda_mano_1000 AS por_1000 FROM ${anual_completo}
ORDER BY anio, tipo
```

```sql importe
SELECT anio, 'Descontada la inflación' AS serie, importe_medio_real AS importe FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses_hipotecas = 12
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, importe_medio AS importe FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses_hipotecas = 12
ORDER BY anio, serie
```

```sql importe_ult
SELECT anio, importe_medio_real, importe_medio, meses_hipotecas
FROM mother.vivienda_mercado_anual
WHERE nivel = 'pais' AND meses_hipotecas = 12
ORDER BY anio DESC
LIMIT 1
```

```sql hitos
SELECT
    arg_max(anio, compraventas_1000) AS anio_max,
    max(compraventas_1000) AS max_1000,
    arg_min(anio, compraventas_1000) AS anio_min,
    min(compraventas_1000) AS min_1000,
    arg_max(compraventas_1000, anio) AS ult_1000,
    max(anio) AS anio_ult,
    arg_max(pct_nueva, anio) AS pct_nueva_ult,
    max(pct_nueva) FILTER (WHERE anio = 2008) AS pct_nueva_2008
FROM ${anual_completo}
```

```sql ccaa
SELECT r.cod, r.nombre AS comunidad, '/en' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'ccaa' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'ccaa'
ORDER BY r.compraventas_12m_1000 DESC
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/en' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'provincia' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'provincia'
ORDER BY r.compraventas_12m_1000 DESC
```

# 📝 Home sales and mortgages

How many homes change hands each year and how many are bought with a mortgage. These are sales **registered in the property registries** (they usually arrive one or two months after signing) and mortgages taken out on homes, always **per 1,000 inhabitants**. The mortgage amount is shown **adjusted for inflation**, in {anual[0]?.anio_base} euros.

<Grid cols=4>
    <KpiCard
        title="Home sales"
        value={ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.compraventas_12m_1000, 1)} per 1,000 inhab."
        period="12 months to {ultimo[0]?.mes_texto} · {formatCompact(ultimo[0]?.compraventas_12m, 0)} in total"
        change={ultimo[0]?.var_cv?.toFixed(1)}
        changePeriod="vs a year earlier"
        source="INE / ETDP"
        sparklineData={mensual.filter(d => d.compraventas_12m_1000 != null).map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Mortgages on homes"
        value={ultimo[0]?.hipotecas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.hipotecas_12m_1000, 1)} per 1,000 inhab."
        period="12 months to {ultimo[0]?.mes_texto} · {formatCompact(ultimo[0]?.hipotecas_12m, 0)} in total"
        change={ultimo[0]?.var_h?.toFixed(1)}
        changePeriod="vs a year earlier"
        source="INE / Mortgages"
        sparklineData={mensual.filter(d => d.hipotecas_12m_1000 != null).map(d => d.hipotecas_12m_1000)}
    />
    <KpiCard
        title="Average mortgage"
        value={importe_ult[0]?.importe_medio_real}
        formattedValue="{formatNumber(importe_ult[0]?.importe_medio_real / 1000, 0)} thousand €"
        period="per home in {importe_ult[0]?.anio}, in {anual[0]?.anio_base} euros"
        source="INE / Mortgages"
        sparklineData={anual.filter(d => d.importe_medio_real != null).map(d => d.importe_medio_real)}
    />
    <KpiCard
        title="New homes"
        value={hitos[0]?.pct_nueva_ult}
        formattedValue="{formatNumber(hitos[0]?.pct_nueva_ult, 1)} %"
        period="of sales in {hitos[0]?.anio_ult} · {formatNumber(hitos[0]?.pct_nueva_2008, 0)} % in 2008"
        source="INE / ETDP"
        sparklineData={anual_completo.map(d => d.pct_nueva)}
    />
</Grid>

## Trend

Sum of the last 12 months, per 1,000 inhabitants. The year with the most sales per inhabitant in the series (since 2007) is {hitos[0]?.anio_max}, with {formatNumber(hitos[0]?.max_1000, 1)}; the lowest, {hitos[0]?.anio_min}, with {formatNumber(hitos[0]?.min_1000, 1)}. In {hitos[0]?.anio_ult} there were {formatNumber(hitos[0]?.ult_1000, 1)}.

<LineChart
    data={movil_largo}
    x=fecha
    y=por_1000
    series=operacion
    yFmt='0.0'
    yAxisTitle="per 1,000 inhab. (12 months)"
    title="Home sales and mortgages per 1,000 inhabitants, 12-month rolling sum"
/>

## New or second-hand

<BarChart
    data={nueva_usada}
    x=anio
    y=por_1000
    series=tipo
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1,000 inhabitants"
    title="Home sales per 1,000 inhabitants: new and second-hand"
/>

## How much is borrowed

Average amount of mortgages taken out on homes, with and without inflation. Mortgages per 100 sales: {formatNumber(anual_completo.slice(-1)[0]?.pct_hipoteca, 0)} in {anual_completo.slice(-1)[0]?.anio}. They are not the same transactions (homes that have not just been bought are also mortgaged), but it gives an idea of how many purchases are financed with a loan.

<LineChart
    data={importe}
    x=anio
    y=importe
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per mortgage"
    startingAtZero={false}
    title="Average amount of a home mortgage"
/>

<LineChart
    data={anual_completo}
    x=anio
    y=pct_hipoteca
    xFmt='0'
    yFmt='0'
    yAxisTitle="mortgages per 100 sales"
    title="Mortgages on homes per 100 sales"
/>

## By region

Sales over the last 12 months per 1,000 inhabitants.

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="compraventas_12m_1000"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#e0f2fe', '#38bdf8', '#075985']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Sales per 1,000 inhab.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Mortgages per 1,000 inhab.', fmt: 'num1'},
        {id: 'pct_nueva', title: '% new homes', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=compraventas_12m_1000 title="Sales per 1,000 inhab." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Mortgages per 1,000 inhab." fmt='0.0' />
    <Column id=pct_nueva title="% new" fmt='0.0' />
    <Column id=importe_medio_real title="Average mortgage (€, real)" fmt='#,##0' />
    <Column id=compraventas_12m title="Sales (12 months)" fmt='#,##0' />
</DataTable>

## By province

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="compraventas_12m_1000"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#e0f2fe', '#38bdf8', '#075985']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Sales per 1,000 inhab.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Mortgages per 1,000 inhab.', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Province" />
    <Column id=compraventas_12m_1000 title="Sales per 1,000 inhab." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Mortgages per 1,000 inhab." fmt='0.0' />
    <Column id=pct_nueva title="% new" fmt='0.0' />
    <Column id=importe_medio_real title="Average mortgage (€, real)" fmt='#,##0' />
</DataTable>

---

**Sources:** [INE, Property Rights Transfer Statistics, table 6150](https://www.ine.es/jaxiT3/Tabla.htm?t=6150) (registered home sales, monthly since 2007) and [INE, Mortgage Statistics, tables 13896](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) [and 3200](https://www.ine.es/jaxiT3/Tabla.htm?t=3200) (mortgages taken out on homes, since 2003). Population: INE, as at 1 January. Amounts deflated with the INE general CPI (base 2025), month by month.
