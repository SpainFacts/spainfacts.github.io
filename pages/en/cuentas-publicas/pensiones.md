---
title: Pensions
description: "Contributory pensions in Spain: average pension adjusted for inflation, contributors per pension, pension spending as a % of GDP compared with the EU, pensions per inhabitant and by region and province."
i18n_origen: 7c0311a74845
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // The month labels (mes_texto) come from the database in Spanish ("enero de 2024"): shown in English here
    const MESES_EN = {
        enero: 'January', febrero: 'February', marzo: 'March', abril: 'April', mayo: 'May', junio: 'June',
        julio: 'July', agosto: 'August', septiembre: 'September', octubre: 'October', noviembre: 'November', diciembre: 'December'
    };
    function mesEn(texto) {
        if (!texto) return texto;
        const partes = String(texto).split(' ');
        return (MESES_EN[partes[0]] ?? partes[0]) + ' ' + partes[partes.length - 1];
    }
</script>

```sql mensual
SELECT
    fecha,
    CAST(anio AS INTEGER) AS anio,
    CAST(mes AS INTEGER) AS mes,
    pensiones,
    pensiones_jubilacion,
    pension_media,
    pension_media_jubilacion,
    pension_media_real,
    pension_media_jubilacion_real,
    pension_media_viudedad_real,
    afiliados,
    afiliados_por_pension,
    interanual_jubilacion_nominal,
    interanual_jubilacion_real,
    CAST(anio_euros AS INTEGER) AS anio_euros,
    CASE CAST(mes AS INTEGER) WHEN 1 THEN 'enero' WHEN 2 THEN 'febrero' WHEN 3 THEN 'marzo' WHEN 4 THEN 'abril'
        WHEN 5 THEN 'mayo' WHEN 6 THEN 'junio' WHEN 7 THEN 'julio' WHEN 8 THEN 'agosto' WHEN 9 THEN 'septiembre'
        WHEN 10 THEN 'octubre' WHEN 11 THEN 'noviembre' ELSE 'diciembre' END || ' de ' || CAST(anio AS INTEGER) AS mes_texto
FROM mother.pensiones_mensual
ORDER BY fecha
```

```sql mensual_real
SELECT * FROM ${mensual} WHERE pension_media_jubilacion_real IS NOT NULL ORDER BY fecha
```

```sql mensual_ratio
SELECT * FROM ${mensual} WHERE afiliados_por_pension IS NOT NULL ORDER BY fecha
```

```sql pension_series
SELECT fecha, 'Jubilación' AS clase, pension_media_jubilacion_real AS pension FROM ${mensual_real}
UNION ALL
SELECT fecha, 'Media de todas las pensiones', pension_media_real FROM ${mensual_real}
UNION ALL
SELECT fecha, 'Viudedad', pension_media_viudedad_real FROM ${mensual_real}
ORDER BY fecha, clase
```

```sql jubilacion_real_nominal
SELECT fecha, 'Descontada la inflación' AS serie, pension_media_jubilacion_real AS pension FROM ${mensual_real}
UNION ALL
SELECT fecha, 'Sin descontar (euros de cada mes)', pension_media_jubilacion FROM ${mensual_real}
ORDER BY fecha, serie
```

```sql hitos
SELECT
    (SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha LIMIT 1) AS jub_real_ini,
    (SELECT mes_texto FROM ${mensual_real} ORDER BY fecha LIMIT 1) AS mes_ini,
    (SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1) AS jub_real_ult,
    (SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha LIMIT 1) AS jub_nom_ini,
    (SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1) AS jub_nom_ult,
    100 * ((SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1)
         / (SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha LIMIT 1) - 1) AS jub_real_var,
    100 * ((SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1)
         / (SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha LIMIT 1) - 1) AS jub_nom_var,
    (SELECT max(afiliados_por_pension) FROM ${mensual_ratio}) AS ratio_max,
    (SELECT mes_texto FROM ${mensual_ratio} ORDER BY afiliados_por_pension DESC LIMIT 1) AS ratio_max_mes,
    (SELECT min(afiliados_por_pension) FROM ${mensual_ratio}) AS ratio_min,
    (SELECT mes_texto FROM ${mensual_ratio} ORDER BY afiliados_por_pension LIMIT 1) AS ratio_min_mes,
    100 * ((SELECT pensiones FROM ${mensual} ORDER BY fecha DESC LIMIT 1)
         / (SELECT pensiones FROM ${mensual} ORDER BY fecha LIMIT 1) - 1) AS pensiones_var
```

```sql anual
SELECT *, CAST(anio AS INTEGER) AS anio_i
FROM mother.pensiones_anual
ORDER BY anio
```

```sql anual_completo
SELECT * FROM ${anual} WHERE meses = 12 ORDER BY anio
```

```sql sustitucion
SELECT anio_i AS anio, 'Pensión media de jubilación (14 pagas prorrateadas en 12)' AS serie, pension_jubilacion_prorrateada_real AS euros FROM ${anual_completo} WHERE salario_real IS NOT NULL
UNION ALL
SELECT anio_i, 'Salario medio bruto (pagas extra prorrateadas)', salario_real FROM ${anual_completo} WHERE salario_real IS NOT NULL
ORDER BY anio, serie
```

```sql sustitucion_ult
SELECT * FROM ${anual_completo} WHERE tasa_sustitucion_aprox IS NOT NULL ORDER BY anio DESC LIMIT 1
```

```sql por_habitante
SELECT anio_i AS anio, 'Pensiones por 1.000 habitantes' AS indicador, pensiones_por_1000_hab AS valor FROM ${anual_completo}
UNION ALL
SELECT anio_i, 'Pensiones por 100 personas de 65 años o más', pensiones_por_100_mayores FROM ${anual_completo}
UNION ALL
SELECT anio_i, 'Pensiones de jubilación por 100 personas de 65 años o más', jubilaciones_por_100_mayores FROM ${anual_completo}
ORDER BY anio, indicador
```

```sql gasto
SELECT CAST(anio AS INTEGER) AS anio, pais, geo, gasto_vejez_pib, gasto_vejez_supervivientes_pib, gasto_pensiones_seepros_pib
FROM mother.pensiones_gasto_pib
WHERE geo IN ('ES', 'EU27_2020') AND gasto_vejez_supervivientes_pib IS NOT NULL
ORDER BY anio, geo
```

```sql gasto_es
SELECT * FROM ${gasto} WHERE geo = 'ES' ORDER BY anio
```

```sql gasto_ult
SELECT
    e.anio,
    e.gasto_vejez_supervivientes_pib AS es,
    u.gasto_vejez_supervivientes_pib AS ue,
    e.gasto_vejez_pib AS es_vejez,
    e.gasto_vejez_supervivientes_pib - p.gasto_vejez_supervivientes_pib AS dif_2007,
    (SELECT count(*) + 1 FROM mother.pensiones_gasto_pib g
        WHERE g.anio = e.anio AND g.es_miembro_ue AND g.gasto_vejez_supervivientes_pib > e.gasto_vejez_supervivientes_pib) AS puesto,
    (SELECT count(*) FROM mother.pensiones_gasto_pib g
        WHERE g.anio = e.anio AND g.es_miembro_ue AND g.gasto_vejez_supervivientes_pib IS NOT NULL) AS paises
FROM ${gasto_es} e
LEFT JOIN ${gasto} u ON u.anio = e.anio AND u.geo = 'EU27_2020'
LEFT JOIN ${gasto_es} p ON p.anio = 2007
ORDER BY e.anio DESC
LIMIT 1
```

```sql gasto_paises
SELECT
    pais,
    gasto_vejez_supervivientes_pib,
    CASE WHEN geo = 'ES' THEN 'España' WHEN es_ue THEN 'Media UE-27' ELSE 'Otros países de la UE' END AS grupo
FROM mother.pensiones_gasto_pib
WHERE anio = (SELECT max(anio) FROM ${gasto_es})
  AND gasto_vejez_supervivientes_pib IS NOT NULL
  AND (es_miembro_ue OR es_ue)
ORDER BY gasto_vejez_supervivientes_pib DESC
```

```sql regimenes
SELECT CAST(anio AS INTEGER) AS anio, regimen, pct_del_total
FROM mother.pensiones_afiliados_regimen
WHERE regimen <> 'Total' AND meses = 12
ORDER BY anio, regimen
```

```sql ccaa
SELECT
    p.cod,
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    CAST(p.anio AS INTEGER) AS anio,
    p.meses,
    p.pensiones,
    p.pension_media_jubilacion_real,
    p.pension_media_real,
    p.pensiones_por_1000_hab,
    p.pensiones_por_100_mayores,
    p.afiliados_por_pension
FROM mother.pensiones_territorio p
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod
WHERE p.nivel = 'ccaa' AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
ORDER BY p.pension_media_jubilacion_real DESC
```

```sql provincias
SELECT
    p.cod AS cod_prov,
    p.nombre AS provincia,
    '/en' || t.ruta AS ruta,
    p.pension_media_jubilacion_real,
    p.pensiones_por_1000_hab,
    p.afiliados_por_pension
FROM mother.pensiones_territorio p
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod
WHERE p.nivel = 'provincia' AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
ORDER BY p.cod
```

```sql ccaa_extremos
SELECT
    (SELECT comunidad FROM ${ccaa} ORDER BY pension_media_jubilacion_real DESC LIMIT 1) AS max_nombre,
    (SELECT pension_media_jubilacion_real FROM ${ccaa} ORDER BY pension_media_jubilacion_real DESC LIMIT 1) AS max_valor,
    (SELECT comunidad FROM ${ccaa} ORDER BY pension_media_jubilacion_real LIMIT 1) AS min_nombre,
    (SELECT pension_media_jubilacion_real FROM ${ccaa} ORDER BY pension_media_jubilacion_real LIMIT 1) AS min_valor,
    (SELECT comunidad FROM ${ccaa} ORDER BY afiliados_por_pension DESC LIMIT 1) AS ratio_max_nombre,
    (SELECT afiliados_por_pension FROM ${ccaa} ORDER BY afiliados_por_pension DESC LIMIT 1) AS ratio_max_valor,
    (SELECT comunidad FROM ${ccaa} ORDER BY afiliados_por_pension LIMIT 1) AS ratio_min_nombre,
    (SELECT afiliados_por_pension FROM ${ccaa} ORDER BY afiliados_por_pension LIMIT 1) AS ratio_min_valor,
    (SELECT max(meses) FROM ${ccaa}) AS meses,
    (SELECT max(anio) FROM ${ccaa}) AS anio
```

# 👵 Pensions

How much pensioners in Spain receive, how many workers contribute for each pension and how much weight pensions carry in the economy. These are **Social Security contributory pensions** (retirement, permanent disability, survivors' (widows' and widowers'), orphans' and dependent relatives' pensions), excluding the civil service pension scheme (clases pasivas) and non-contributory pensions. Amounts are the gross pension for each of the 14 annual payments and are shown **adjusted for inflation**, in {mensual[0]?.anio_euros} euros.

<Grid cols=4>
    <KpiCard
        title="Average retirement pension"
        value={mensual_real.slice(-1)[0]?.pension_media_jubilacion_real}
        formattedValue="€{formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion_real, 0)}/month"
        period="{mesEn(mensual_real.slice(-1)[0]?.mes_texto)}, {mensual[0]?.anio_euros} euros · €{formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion, 0)} in current euros, 14 payments"
        change={mensual_real.slice(-1)[0]?.interanual_jubilacion_real?.toFixed(1)}
        changeUnit="%"
        changePeriod="real, vs a year earlier"
        direction="positive-up"
        source="Social Security"
        sparklineData={mensual_real.map(d => ({...d, y: d.pension_media_jubilacion_real}))}
    />
    <KpiCard
        title="Contributors per pension"
        value={mensual_ratio.slice(-1)[0]?.afiliados_por_pension}
        formattedValue={formatNumber(mensual_ratio.slice(-1)[0]?.afiliados_por_pension, 2)}
        period="{mesEn(mensual_ratio.slice(-1)[0]?.mes_texto)} · {formatNumber(mensual_ratio.slice(-1)[0]?.afiliados / 1e6, 1)} million contributors and {formatNumber(mensual_ratio.slice(-1)[0]?.pensiones / 1e6, 1)} million pensions"
        direction="positive-up"
        source="Social Security"
        sparklineData={mensual_ratio.map(d => ({...d, y: d.afiliados_por_pension}))}
    />
    <KpiCard
        title="Pension spending"
        value={gasto_ult[0]?.es}
        formattedValue="{formatNumber(gasto_ult[0]?.es, 1)}% of GDP"
        period="{gasto_ult[0]?.anio} · old age and survivors, all levels of government · EU-27 average: {formatNumber(gasto_ult[0]?.ue, 1)}%"
        direction="positive-down"
        source="Eurostat (COFOG)"
        sparklineData={gasto_es.map(d => ({...d, y: d.gasto_vejez_supervivientes_pib}))}
    />
    <KpiCard
        title="Pensions per 1,000 inhabitants"
        value={anual_completo.slice(-1)[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_1000_hab, 0)}
        period="{anual_completo.slice(-1)[0]?.anio_i}, annual average · {formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_100_mayores, 0)} per 100 people aged 65 or over"
        source="Social Security / INE"
        sparklineData={anual_completo.map(d => ({...d, y: d.pensiones_por_1000_hab}))}
    />
</Grid>

## The average pension, adjusted for inflation

Between {mesEn(hitos[0]?.mes_ini)} and {mesEn(mensual_real.slice(-1)[0]?.mes_texto)} the average retirement pension rose from €{formatNumber(hitos[0]?.jub_nom_ini, 0)} to €{formatNumber(hitos[0]?.jub_nom_ult, 0)} a month, {formatNumber(hitos[0]?.jub_nom_var, 0)}% more in euros of each period. Adjusted for inflation, the change is {#if hitos[0]?.jub_real_var >= 0}an increase of {formatNumber(hitos[0]?.jub_real_var, 0)}%{:else}negative: {formatNumber(-hitos[0]?.jub_real_var, 0)}% less{/if}.

<LineChart
    data={jubilacion_real_nominal}
    x=fecha
    y=pension
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€ per month (per payment)"
    startingAtZero={false}
    seriesColors={{'Descontada la inflación': '#0f766e', 'Sin descontar (euros de cada mes)': '#94a3b8'}}
    title="Average retirement pension: {mensual[0]?.anio_euros} euros vs euros of each month"
/>

<LineChart
    data={pension_series}
    x=fecha
    y=pension
    series=clase
    yFmt='#,##0" €"'
    yAxisTitle="€ per month, {mensual[0]?.anio_euros} euros"
    colorPalette={['#0f766e', '#1d4ed8', '#f59e0b']}
    title="Real average pension by type of pension"
/>

The jumps each January are the annual uprating of pensions; between upratings, inflation erodes purchasing power month by month.

## How many contributors there are for each pension

This is the figure most often used to discuss the sustainability of the system: how many people contribute to Social Security (registered contributors, monthly average) for each contributory pension in payment. Since {mesEn(hitos[0]?.mes_ini)}, the peak was {formatNumber(hitos[0]?.ratio_max, 2)} in {mesEn(hitos[0]?.ratio_max_mes)} and the low {formatNumber(hitos[0]?.ratio_min, 2)} in {mesEn(hitos[0]?.ratio_min_mes)}. The number of pensions has grown by {formatNumber(hitos[0]?.pensiones_var, 0)}% over that period.

<LineChart
    data={mensual_ratio}
    x=fecha
    y=afiliados_por_pension
    yFmt='0.00'
    yAxisTitle="contributors per pension"
    startingAtZero={false}
    colorPalette={['#1d4ed8']}
    title="Social Security contributors per contributory pension"
/>

<BarChart
    data={regimenes}
    x=anio
    y=pct_del_total
    series=regimen
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of contributors"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#64748b']}
    title="Contributors by scheme (% of total, annual average)"
/>

## Pensions compared with wages

Average retirement pension and average gross wage in {mensual[0]?.anio_euros} euros. To compare them, the pension is spread over 12 months (it is paid in 14 instalments), in the same way as the wage from the Quarterly Labour Cost Survey. In {sustitucion_ult[0]?.anio_i} the average retirement pension was equivalent to {formatNumber(sustitucion_ult[0]?.tasa_sustitucion_aprox, 0)}% of the average wage. This is an **approximate replacement rate**: it compares the average pension of all retirees with the average wage of that year, not each person's first pension with their last salary.

<LineChart
    data={sustitucion}
    x=anio
    y=euros
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="Gross € per month (real)"
    seriesColors={{'Pensión media de jubilación (14 pagas prorrateadas en 12)': '#0f766e', 'Salario medio bruto (pagas extra prorrateadas)': '#94a3b8'}}
    title="Average retirement pension and average wage, adjusted for inflation"
/>

<LineChart
    data={anual_completo.filter(d => d.tasa_sustitucion_aprox != null)}
    x=anio_i
    y=tasa_sustitucion_aprox
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% of average wage"
    startingAtZero={false}
    colorPalette={['#0f766e']}
    title="Average retirement pension as a % of the average wage"
/>

## How much Spain spends on pensions

Spending by all levels of government on the old-age and survivors' (widows' and orphans') functions under Eurostat's COFOG classification, which also includes civil service (clases pasivas) and non-contributory pensions. In {gasto_ult[0]?.anio} it was {formatNumber(gasto_ult[0]?.es, 1)}% of GDP, compared with {formatNumber(gasto_ult[0]?.ue, 1)}% for the EU-27 average{#if gasto_ult[0]?.dif_2007 != null} and {formatNumber(Math.abs(gasto_ult[0]?.dif_2007), 1)} points {#if gasto_ult[0]?.dif_2007 >= 0}more{:else}less{/if} than in 2007{/if}. Spain ranks number {gasto_ult[0]?.puesto} of the {gasto_ult[0]?.paises} EU countries with data for this spending as a percentage of GDP.

<LineChart
    data={gasto}
    x=anio
    y=gasto_vejez_supervivientes_pib
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of GDP"
    startingAtZero={false}
    seriesColors={{'España': '#b91c1c', 'UE-27': '#94a3b8'}}
    title="Public spending on old age and survivors, % of GDP: Spain and EU-27"
/>

<BarChart
    data={gasto_paises}
    x=pais
    y=gasto_vejez_supervivientes_pib
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    seriesColors={{'España': '#b91c1c', 'Media UE-27': '#1d4ed8', 'Otros países de la UE': '#94a3b8'}}
    title="Public spending on old age and survivors by country in {gasto_ult[0]?.anio} (% of GDP)"
/>

## More pensions for an ageing population

Number of pensions per 1,000 inhabitants and per 100 people aged 65 or over (INE municipal register). One person can receive more than one pension (for example, retirement and survivor's), so these figures count pensions, not pensioners.

<LineChart
    data={por_habitante}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0'
    yAxisTitle="pensions"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Pensions per inhabitant and per older person"
/>

## By autonomous community

Data for {ccaa_extremos[0]?.anio}{#if ccaa_extremos[0]?.meses < 12} (average of the {ccaa_extremos[0]?.meses} months published){/if}, in {mensual[0]?.anio_euros} euros. The highest average retirement pension is in {ccaa_extremos[0]?.max_nombre} (€{formatNumber(ccaa_extremos[0]?.max_valor, 0)}) and the lowest in {ccaa_extremos[0]?.min_nombre} (€{formatNumber(ccaa_extremos[0]?.min_valor, 0)}). Contributors per pension range from {formatNumber(ccaa_extremos[0]?.ratio_max_valor, 2)} in {ccaa_extremos[0]?.ratio_max_nombre} to {formatNumber(ccaa_extremos[0]?.ratio_min_valor, 2)} in {ccaa_extremos[0]?.ratio_min_nombre}.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pension_media_jubilacion_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Social Security"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pension_media_jubilacion_real', title: 'Average retirement pension', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pensions per 1,000 inhab.', fmt: 'num0'},
        {id: 'afiliados_por_pension', title: 'Contributors per pension', fmt: 'num2'}
    ]}
/>

<DataTable data={ccaa} rows=all link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=pension_media_jubilacion_real title="Average retirement pension (€/month)" fmt='#,##0' contentType=colorscale colorScale=positive />
    <Column id=pension_media_real title="Average pension, all types (€/month)" fmt='#,##0' />
    <Column id=pensiones_por_1000_hab title="Pensions per 1,000 inhab." fmt='#,##0' />
    <Column id=pensiones_por_100_mayores title="Pensions per 100 people aged 65+" fmt='#,##0' />
    <Column id=afiliados_por_pension title="Contributors per pension" fmt='0.00' contentType=colorscale colorScale=positive />
</DataTable>

### By province

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="afiliados_por_pension"
    valueFmt='0.00'
    link="ruta"
    colorPalette={['#fef3c7', '#93c5fd', '#1d4ed8']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Social Security"
    title="Contributors per pension in each province"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'afiliados_por_pension', title: 'Contributors per pension', fmt: 'num2'},
        {id: 'pension_media_jubilacion_real', title: 'Average retirement pension', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pensions per 1,000 inhab.', fmt: 'num0'}
    ]}
/>

More on State spending by function in [Spending](/en/cuentas-publicas/gastos) and on pay in [Wages](/en/economia/salarios).

---

**Sources:** [Social Security, statistics on contributory pensions in payment](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24) (monthly books by region and province, as at the 1st of each month, and [their historical series since 2008](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/2575)); [Social Security, average monthly registrations](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8/EST10/EST290/EST291) (series by scheme since 2001 and by province since 2021); [Eurostat, general government expenditure by function, gov_10a_exp](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table) (COFOG GF1002 old age and GF1003 survivors, % of GDP); [INE, municipal register](https://www.ine.es/jaxiT3/Tabla.htm?t=29005) and [Quarterly Labour Cost Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=6038). Amounts deflated with the INE's general CPI (base 2025).
