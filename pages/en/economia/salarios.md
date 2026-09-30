---
title: Wages
description: "Average wage in Spain adjusted for inflation, its real and nominal growth, by sector and working hours, and its distribution by decile."
i18n_origen: dc575af43c4c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT *
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql anual_largo
SELECT anio, 'Descontada la inflación' AS serie, salario_real AS salario FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total'
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, salario_nominal AS salario FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio, serie
```

```sql crecimientos
SELECT anio, 'Nominal' AS tipo, crecimiento_nominal AS crecimiento FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total' AND crecimiento_nominal IS NOT NULL
UNION ALL
SELECT anio, 'Real' AS tipo, crecimiento_real AS crecimiento FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total' AND crecimiento_real IS NOT NULL
ORDER BY anio, tipo
```

```sql trimestral
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, salario_total, salario_total_real, interanual_nominal, interanual_real, anio_euros
FROM mother.economia_salarios
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY trimestre
```

```sql interanual_largo
SELECT trimestre, 'Nominal' AS tipo, interanual_nominal AS variacion FROM mother.economia_salarios WHERE jornada = 'Todas' AND sector = 'Total' AND interanual_nominal IS NOT NULL
UNION ALL
SELECT trimestre, 'Real' AS tipo, interanual_real AS variacion FROM mother.economia_salarios WHERE jornada = 'Todas' AND sector = 'Total' AND interanual_real IS NOT NULL
ORDER BY trimestre, tipo
```

```sql por_sector
SELECT anio, sector, salario_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas'
ORDER BY anio, sector
```

```sql por_jornada
SELECT anio, jornada, salario_real
FROM mother.economia_salarios_anual
WHERE sector = 'Total'
ORDER BY anio, jornada
```

```sql hitos_salario
SELECT
    max(CASE WHEN anio = 2008 THEN salario_real END) AS r2008,
    max(salario_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) AS r_ult,
    max(salario_nominal) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) AS n_ult,
    max(CASE WHEN anio = 2008 THEN salario_nominal END) AS n2008,
    100 * (max(salario_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) / max(CASE WHEN anio = 2008 THEN salario_real END) - 1) AS real_vs2008,
    100 * (max(salario_nominal) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) / max(CASE WHEN anio = 2008 THEN salario_nominal END) - 1) AS nominal_vs2008,
    max(salario_real) AS r_max,
    arg_max(anio, salario_real) AS anio_max,
    max(anio) AS anio_ult
FROM ${anual}
```

```sql deciles
SELECT
    d.anio,
    d.decil,
    'D' || d.decil AS nombre_decil,
    d.salario_mensual,
    d.salario_mensual * f.factor AS salario_real,
    f.anio_base
FROM mother.empleo_salarios_deciles d
JOIN mother.deflactor f ON f.anio = d.anio
WHERE d.jornada = 'Total' AND d.sector = 'Total' AND d.decil > 0
ORDER BY d.anio, d.decil
```

```sql deciles_ult
SELECT * FROM ${deciles} WHERE anio = (SELECT max(anio) FROM ${deciles}) ORDER BY decil
```

```sql deciles_evol
SELECT anio, CASE decil WHEN 1 THEN '10 % peor pagado (D1)' WHEN 5 THEN 'Mitad de la tabla (D5)' ELSE '10 % mejor pagado (D10)' END AS grupo, salario_real
FROM ${deciles}
WHERE decil IN (1, 5, 10)
ORDER BY anio, grupo
```

# 💶 Wages

How much people earn in Spain, and whether their pay stretches further or less far than before. All amounts are **gross wage cost per worker per month**, with bonus payments spread over the year, and are shown **adjusted for inflation**, in {trimestral[0]?.anio_euros} euros.

<Grid cols=4>
    <KpiCard
        title="Average wage"
        value={anual.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.salario_real, 0)} €/month"
        period="gross in {anual.slice(-1)[0]?.anio} · {formatNumber(anual.slice(-1)[0]?.salario_anual_real, 0)} € a year"
        change={anual.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real, vs previous year"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => d.salario_real)}
    />
    <KpiCard
        title="Real rise in the latest quarter"
        value={trimestral.slice(-1)[0]?.interanual_real}
        formattedValue="{trimestral.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(trimestral.slice(-1)[0]?.interanual_real, 1)}%"
        period="{trimestral.slice(-1)[0]?.periodo} vs a year earlier · {formatNumber(trimestral.slice(-1)[0]?.interanual_nominal, 1)}% before adjusting for inflation"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={trimestral.filter(d => d.interanual_real != null).slice(-20).map(d => d.interanual_real)}
    />
    <KpiCard
        title="Compared with 2008"
        value={hitos_salario[0]?.real_vs2008}
        formattedValue="{hitos_salario[0]?.real_vs2008 >= 0 ? '+' : ''}{formatNumber(hitos_salario[0]?.real_vs2008, 1)}%"
        period="purchasing power of the average wage in {hitos_salario[0]?.anio_ult} · +{formatNumber(hitos_salario[0]?.nominal_vs2008, 0)}% in current euros"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => d.salario_real)}
    />
    <KpiCard
        title="Middle-decile wage"
        value={deciles_ult.find(d => d.decil === 5)?.salario_real}
        formattedValue="{formatNumber(deciles_ult.find(d => d.decil === 5)?.salario_real, 0)} €/month"
        period="what the typical employee earns (EPA decile 5) in {deciles_ult[0]?.anio}, {deciles_ult[0]?.anio_base} euros"
        source="INE / EPA"
        sparklineData={deciles.filter(d => d.decil === 5).map(d => d.salario_real)}
    />
</Grid>

## The average wage with and without inflation

Before adjusting for inflation, the average wage rose by {formatNumber(hitos_salario[0]?.nominal_vs2008, 0)}% between 2008 and {hitos_salario[0]?.anio_ult}. After adjusting for it, the average pay packet buys {#if hitos_salario[0]?.real_vs2008 < 0}{formatNumber(-hitos_salario[0]?.real_vs2008, 1)}% less{:else}{formatNumber(hitos_salario[0]?.real_vs2008, 1)}% more{/if} than in 2008, and the real peak of the series was in {hitos_salario[0]?.anio_max}.

<LineChart
    data={anual_largo}
    x=anio
    y=salario
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="Gross € per month"
    startingAtZero={false}
    title="Average monthly wage: {trimestral[0]?.anio_euros} euros vs current euros"
/>

## Wage growth

Annual rise in the average wage, with and without adjusting for inflation. When the real bar is negative, pay buys less than the year before even if it has gone up in euros.

<BarChart
    data={crecimientos}
    x=anio
    y=crecimiento
    series=tipo
    type=grouped
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% per year"
    title="Annual growth in the average wage: nominal and real"
/>

<LineChart
    data={interanual_largo}
    x=trimestre
    y=variacion
    series=tipo
    yFmt='0.0"%"'
    yAxisTitle="% year-on-year"
    title="Year-on-year change in wages by quarter"
/>

## By sector and working hours

Average monthly wage in {trimestral[0]?.anio_euros} euros. Part of the difference between sectors is because some have far more part-time employment.

<LineChart
    data={por_sector}
    x=anio
    y=salario_real
    series=sector
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per month (real)"
    startingAtZero={false}
    title="Real average wage by sector"
/>

<LineChart
    data={por_jornada}
    x=anio
    y=salario_real
    series=jornada
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per month (real)"
    title="Real average wage by type of working hours"
/>

```sql por_ccaa
SELECT
    s.cod,
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    s.salario_real,
    s.coste_laboral_real,
    s.crecimiento_real,
    s.indice_espana,
    100 * (s.salario_real / b.salario_real - 1) AS cambio_2008,
    CAST(s.anio AS INTEGER) AS anio,
    CAST(s.anio_euros AS INTEGER) AS anio_euros
FROM mother.economia_salarios_ccaa s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
LEFT JOIN mother.economia_salarios_ccaa b ON b.cod = s.cod AND b.anio = 2008
WHERE s.cod <> '00' AND s.anio = (SELECT max(anio) FROM mother.economia_salarios_ccaa)
ORDER BY s.salario_real DESC
```

## By region (autonomous community)

Average gross monthly wage in {por_ccaa[0]?.anio}, in {por_ccaa[0]?.anio_euros} euros. {por_ccaa[0]?.comunidad} tops the list with {formatNumber(por_ccaa[0]?.salario_real, 0)} € and {por_ccaa.slice(-1)[0]?.comunidad} comes last with {formatNumber(por_ccaa.slice(-1)[0]?.salario_real, 0)} €. These euros are not adjusted for the cost of living, which also varies between regions. Ceuta and Melilla are not published separately.

<AreaMap
    data={por_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="salario_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'salario_real', title: 'Average wage', fmt: '#,##0" €"'},
        {id: 'indice_espana', title: 'Spain = 100', fmt: '0.0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Region"/>
    <Column id=salario_real title="Wage (€/month)" fmt='#,##0'/>
    <Column id=indice_espana title="Spain = 100" fmt='0.0'/>
    <Column id=crecimiento_real title="Real growth, last year (%)" fmt='0.0' contentType=delta/>
    <Column id=cambio_2008 title="Real change since 2008 (%)" fmt='0.0' contentType=delta/>
    <Column id=coste_laboral_real title="Total cost to the employer (€/month)" fmt='#,##0'/>
</DataTable>

## How it is distributed: deciles

The average is pushed up by the highest salaries. The EPA (Labour Force Survey) ranks all employees from lowest to highest wage and splits them into ten equal groups (deciles); decile 5 is the typical wage. Data for {deciles_ult[0]?.anio}, adjusted for inflation.

<BarChart
    data={deciles_ult}
    x=nombre_decil
    y=salario_real
    yFmt='#,##0" €"'
    yAxisTitle="Gross € per month"
    title="Average wage in each decile in {deciles_ult[0]?.anio} ({deciles_ult[0]?.anio_base} euros)"
/>

<LineChart
    data={deciles_evol}
    x=anio
    y=salario_real
    series=grupo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per month (real)"
    title="Real change in low, middle and high wages"
/>

Public-sector pay and its cost are covered in [Public employment](/en/cuentas-publicas/empleo-publico).

---

**Sources:** [INE, Quarterly Labour Cost Survey (ETCL), table 6038](https://www.ine.es/jaxiT3/Tabla.htm?t=6038) (wage cost per worker per month in industry, construction and services; the annual figure is the average of its four quarters) and [INE, EPA (Labour Force Survey), wages by decile, table 66250](https://www.ine.es/jaxiT3/Tabla.htm?t=66250); by region, [ETCL, table 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflated using INE's general CPI (base 2025).
