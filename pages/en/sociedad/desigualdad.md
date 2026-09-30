---
title: Income, poverty and inequality
description: "Average household income in Spain adjusted for inflation, at-risk-of-poverty rate, AROPE, material deprivation, Gini index and S80/S20 ratio, by region, age and municipality, and compared with the EU."
i18n_origen: 9952ace4d46b
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql nac
SELECT *
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND anio >= 2008
ORDER BY anio
```

```sql ue_ultimo
SELECT
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 'gini') AS gini_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 'gini') AS gini_ue,
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 'arope') AS arope_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 'arope') AS arope_ue,
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 's80_s20') AS s80_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 's80_s20') AS s80_ue,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.renta_ue
WHERE anio = (SELECT max(anio) FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini')
```

```sql hitos
WITH n AS (SELECT * FROM mother.renta_ecv_ccaa WHERE cod = '00' AND renta_persona_real IS NOT NULL),
u AS (SELECT * FROM n WHERE anio = (SELECT max(anio) FROM n)),
p AS (SELECT * FROM n WHERE anio = 2008),
m AS (SELECT * FROM n ORDER BY renta_persona_real LIMIT 1)
SELECT
    CAST(u.anio AS INTEGER) AS anio,
    CAST(u.anio_renta AS INTEGER) AS anio_renta,
    CAST(u.anio_base AS INTEGER) AS anio_base,
    u.renta_persona_real, u.renta_persona, u.renta_hogar_real, u.renta_uc_real,
    u.tasa_pobreza, u.arope, u.carencia_severa, u.fin_mes_dificultad, u.gini, u.s80_s20,
    CAST(p.anio_renta AS INTEGER) AS anio_renta_2008,
    100 * (u.renta_persona_real / p.renta_persona_real - 1) AS var_real_2008,
    CAST(m.anio_renta AS INTEGER) AS anio_renta_min,
    m.renta_persona_real AS renta_min,
    100 * (u.renta_persona_real / m.renta_persona_real - 1) AS var_real_min,
    p.tasa_pobreza AS pobreza_2008,
    p.gini AS gini_2008,
    (SELECT max(tasa_pobreza) FROM n) AS pobreza_max,
    (SELECT CAST(arg_max(anio, tasa_pobreza) AS INTEGER) FROM n) AS anio_pobreza_max,
    (SELECT max(gini) FROM n) AS gini_max,
    (SELECT CAST(arg_max(anio, gini) AS INTEGER) FROM n) AS anio_gini_max
FROM u, p, m
```

```sql arope_serie
SELECT anio, arope AS valor FROM ${nac} WHERE arope IS NOT NULL ORDER BY anio
```

```sql gini_serie
SELECT anio, gini AS valor FROM ${nac} WHERE gini IS NOT NULL ORDER BY anio
```

# 💶 Income, poverty and inequality

How much households in Spain earn on average once inflation is taken into account, what share of the population is at risk of poverty or social exclusion, how unequally income is distributed and how all of this varies across regions, age groups and municipalities.

<Grid cols=4>
    <KpiCard
        title="Net income per person"
        value={hitos[0]?.renta_persona_real}
        formattedValue="€{formatNumber(hitos[0]?.renta_persona_real, 0)}"
        period="per year, {hitos[0]?.anio_renta} income in {hitos[0]?.anio_base} euros · €{formatNumber(hitos[0]?.renta_persona, 0)} in current euros"
        change={hitos[0]?.var_real_2008}
        changeUnit="%"
        changePeriod="vs {hitos[0]?.anio_renta_2008}, adjusted for inflation"
        direction="positive-up"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio_renta, valor: d.renta_persona_real}))}
    />
    <KpiCard
        title="At risk of poverty"
        value={hitos[0]?.tasa_pobreza}
        formattedValue="{formatNumber(hitos[0]?.tasa_pobreza, 1)} %"
        period="of the population, below 60 % of median income (ECV {hitos[0]?.anio})"
        change={hitos[0]?.tasa_pobreza - hitos[0]?.pobreza_2008}
        changeUnit=" pp"
        changePeriod="vs ECV 2008"
        direction="positive-down"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio, valor: d.tasa_pobreza}))}
    />
    <KpiCard
        title="At risk of poverty or social exclusion (AROPE)"
        value={hitos[0]?.arope}
        formattedValue="{formatNumber(hitos[0]?.arope, 1)} %"
        period="of the population in {hitos[0]?.anio} · EU-27: {formatNumber(ue_ultimo[0]?.arope_ue, 1)} % ({ue_ultimo[0]?.anio})"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={arope_serie}
    />
    <KpiCard
        title="Gini index"
        value={hitos[0]?.gini}
        formattedValue={formatNumber(hitos[0]?.gini, 1)}
        period="0 = everyone equal, 100 = one person has everything · EU-27: {formatNumber(ue_ultimo[0]?.gini_ue, 1)} ({ue_ultimo[0]?.anio})"
        change={hitos[0]?.gini - hitos[0]?.gini_2008}
        changeUnit=" points"
        changePeriod="vs ECV 2008"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={gini_serie}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('riesgo_pobreza', 'gini')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'riesgo_pobreza')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gini')} />


<p class="text-xs text-gray-500">Each year's Living Conditions Survey (ECV) asks about the previous year's income: the {hitos[0]?.anio} ECV covers {hitos[0]?.anio_renta} income. Poverty, the Gini index and the S80/S20 ratio are calculated from that income. All amounts are in {hitos[0]?.anio_base} euros, adjusted for inflation using the CPI.</p>

## Real household income

```sql renta_grafico
SELECT anio_renta AS anio, 'Por persona' AS medida, renta_persona_real AS euros FROM ${nac} WHERE renta_persona_real IS NOT NULL
UNION ALL
SELECT anio_renta, 'Por unidad de consumo', renta_uc_real FROM ${nac} WHERE renta_uc_real IS NOT NULL
ORDER BY anio, medida
```

Net income per person, adjusted for inflation, bottomed out with {hitos[0]?.anio_renta_min} income (€{formatNumber(hitos[0]?.renta_min, 0)}) and has since risen by {formatNumber(hitos[0]?.var_real_min, 1)} %. Compared with {hitos[0]?.anio_renta_2008} income, the difference is {formatNumber(hitos[0]?.var_real_2008, 1)} %.

<LineChart
    data={renta_grafico}
    x=anio
    y=euros
    series=medida
    xFmt="0"
    yFmt='#,##0" €"'
    colorPalette={['#1d4ed8', '#0f766e']}
    title="Average annual net income, in {hitos[0]?.anio_base} euros (income year)"
/>

<p class="text-xs text-gray-500">Income per consumption unit takes into account that household members share expenses: the first adult counts as 1, other people aged 14 and over as 0.5 and children as 0.3. It is the measure used to compare households of different sizes and to calculate poverty. Average income per household was €{formatNumber(hitos[0]?.renta_hogar_real, 0)}.</p>

## Poverty and social exclusion

```sql pobreza_grafico
SELECT anio, 'Riesgo de pobreza' AS indicador, tasa_pobreza AS pct FROM ${nac} WHERE tasa_pobreza IS NOT NULL
UNION ALL
SELECT anio, 'AROPE (pobreza o exclusión)', arope FROM ${nac} WHERE arope IS NOT NULL
UNION ALL
SELECT anio, 'Carencia material y social severa', carencia_severa FROM ${nac} WHERE carencia_severa IS NOT NULL
UNION ALL
SELECT anio, 'Llega a fin de mes con dificultad', fin_mes_dificultad FROM ${nac} WHERE fin_mes_dificultad IS NOT NULL
ORDER BY anio, indicador
```

In the {hitos[0]?.anio} ECV, {formatNumber(hitos[0]?.tasa_pobreza, 1)} % of the population was at risk of poverty (the series peak was {formatNumber(hitos[0]?.pobreza_max, 1)} % in {hitos[0]?.anio_pobreza_max}), {formatNumber(hitos[0]?.carencia_severa, 1)} % suffered severe material and social deprivation and {formatNumber(hitos[0]?.fin_mes_dificultad, 1)} % said they made ends meet with difficulty or with great difficulty.

<LineChart
    data={pobreza_grafico}
    x=anio
    y=pct
    series=indicador
    xFmt="0"
    yFmt='0.0"%"'
    colorPalette={['#b91c1c', '#f59e0b', '#7c3aed', '#64748b']}
    title="% of the population (survey year)"
/>

<p class="text-xs text-gray-500">At risk of poverty: income per consumption unit below 60 % of the Spanish median; it is a relative measure, so it falls if poor people move closer to the median, not if everyone's income rises. AROPE adds together those who are at risk of poverty, suffer severe material and social deprivation or live in households with very low work intensity (Europe 2030 definition, from 2014). Severe material and social deprivation: being unable to afford at least 7 of 13 basic items (heating the home, an unexpected expense, eating meat or fish every other day, new clothes...).</p>

```sql edad
SELECT edad, orden, arope, tasa_pobreza, carencia_severa, renta_uc_real, CAST(anio AS INTEGER) AS anio
FROM mother.renta_ecv_edad
WHERE anio = (SELECT max(anio) FROM mother.renta_ecv_edad) AND orden BETWEEN 1 AND 5
ORDER BY orden
```

```sql edad_grafico
SELECT edad, orden, 'AROPE' AS indicador, arope AS pct FROM ${edad}
UNION ALL
SELECT edad, orden, 'Riesgo de pobreza', tasa_pobreza FROM ${edad}
UNION ALL
SELECT edad, orden, 'Carencia severa', carencia_severa FROM ${edad}
ORDER BY orden
```

```sql edad_extremos
SELECT lower(arg_max(edad, tasa_pobreza)) AS edad_max, max(tasa_pobreza) AS pobreza_max,
    lower(arg_min(edad, tasa_pobreza)) AS edad_min, min(tasa_pobreza) AS pobreza_min
FROM ${edad}
```

### By age

In the {edad[0]?.anio} ECV, the age group most at risk of poverty was "{edad_extremos[0]?.edad_max}" ({formatNumber(edad_extremos[0]?.pobreza_max, 1)} %) and the least at risk was "{edad_extremos[0]?.edad_min}" ({formatNumber(edad_extremos[0]?.pobreza_min, 1)} %).

<BarChart
    data={edad_grafico}
    x=edad
    y=pct
    series=indicador
    type=grouped
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#f59e0b', '#b91c1c', '#7c3aed']}
    title="% of each age group (ECV {edad[0]?.anio})"
/>

<p class="text-xs text-gray-500">Older people's income includes their pensions, but not their accumulated savings or the rent saved by those who own their home outright (these figures exclude imputed rent).</p>

## Inequality

```sql desigualdad_grafico
SELECT anio, 'España (INE)' AS territorio, gini FROM ${nac} WHERE gini IS NOT NULL
UNION ALL
SELECT anio, 'UE-27 (Eurostat)', valor FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini'
ORDER BY anio, territorio
```

Spain's Gini index was {formatNumber(hitos[0]?.gini, 1)} in the {hitos[0]?.anio} ECV (series peak: {formatNumber(hitos[0]?.gini_max, 1)} in {hitos[0]?.anio_gini_max}). The richest 20 % of the population receives {formatNumber(hitos[0]?.s80_s20, 1)} times as much income as the poorest 20 % (S80/S20 ratio; EU-27: {formatNumber(ue_ultimo[0]?.s80_ue, 1)} in {ue_ultimo[0]?.anio}).

<LineChart
    data={desigualdad_grafico}
    x=anio
    y=gini
    series=territorio
    xFmt="0"
    yFmt="0.0"
    yMin=25
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Gini index of equivalised disposable income (0-100)"
/>

```sql gini_paises
SELECT pais, valor AS gini, CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.renta_ue
WHERE indicador = 'gini' AND anio = (SELECT max(anio) FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini')
ORDER BY valor DESC
```

<BarChart
    data={gini_paises}
    x=pais
    y=gini
    series=grupo
    swapXY=true
    sort=false
    yFmt="0.0"
    colorPalette={['#94a3b8', '#b91c1c', '#1d4ed8']}
    height={560}
    title="Gini index in the EU ({ue_ultimo[0]?.anio})"
/>

## By autonomous community

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    e.renta_persona_real, e.renta_uc_real, e.tasa_pobreza, e.arope, e.carencia_severa, e.fin_mes_dificultad, e.gini,
    CAST(e.anio AS INTEGER) AS anio, CAST(e.anio_renta AS INTEGER) AS anio_renta
FROM mother.renta_ecv_ccaa e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.renta_ecv_ccaa WHERE tasa_pobreza IS NOT NULL)
ORDER BY e.tasa_pobreza DESC
```

```sql ccaa_extremos
SELECT
    arg_max(comunidad, tasa_pobreza) AS mas_pobreza, max(tasa_pobreza) AS max_pobreza,
    arg_min(comunidad, tasa_pobreza) AS menos_pobreza, min(tasa_pobreza) AS min_pobreza,
    arg_max(comunidad, renta_persona_real) AS mas_renta, max(renta_persona_real) AS max_renta,
    arg_min(comunidad, renta_persona_real) AS menos_renta, min(renta_persona_real) AS min_renta
FROM ${ccaa}
```

The differences between regions are large: in the {ccaa[0]?.anio} ECV the at-risk-of-poverty rate ranged from {formatNumber(ccaa_extremos[0]?.min_pobreza, 1)} % in {ccaa_extremos[0]?.menos_pobreza} to {formatNumber(ccaa_extremos[0]?.max_pobreza, 1)} % in {ccaa_extremos[0]?.mas_pobreza}, and net income per person from €{formatNumber(ccaa_extremos[0]?.min_renta, 0)} in {ccaa_extremos[0]?.menos_renta} to €{formatNumber(ccaa_extremos[0]?.max_renta, 0)} in {ccaa_extremos[0]?.mas_renta}. The poverty threshold is the same for the whole of Spain, with no adjustment for each region's cost of living.

<Grid cols=2>
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="tasa_pobreza"
        valueFmt='0.0"%"'
        link="ruta"
        colorPalette={['#fef2f2', '#f87171', '#991b1b']}
        height={420}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'tasa_pobreza', title: 'At risk of poverty', fmt: '0.0"%"'},
            {id: 'arope', title: 'AROPE', fmt: '0.0"%"'},
            {id: 'renta_persona_real', title: 'Income per person', fmt: '#,##0" €"'}
        ]}
    />
    <BarChart
        data={ccaa}
        x=comunidad
        y=renta_persona_real
        swapXY=true
        yFmt='#,##0" €"'
        fillColor="#1d4ed8"
        height={420}
        title="Net income per person ({ccaa[0]?.anio_renta} income, {hitos[0]?.anio_base} euros)"
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=renta_persona_real title="Income per person" fmt='#,##0" €"' />
    <Column id=tasa_pobreza title="At risk of poverty" fmt='0.0"%"' contentType=bar barColor="#fecaca" />
    <Column id=arope title="AROPE" fmt='0.0"%"' />
    <Column id=carencia_severa title="Severe deprivation" fmt='0.0"%"' />
    <Column id=fin_mes_dificultad title="Difficulty making ends meet" fmt='0.0"%"' />
    <Column id=gini title="Gini" fmt="0.0" />
</DataTable>

<p class="text-xs text-gray-500">Map: at-risk-of-poverty rate (%). The samples for Ceuta and Melilla are small, so their figures have a wide margin of error.</p>

## Richest and poorest municipalities

```sql mun_base
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion, m.renta_persona_real, m.renta_hogar_real,
    m.renta_uc_mediana_real, CAST(m.anio AS INTEGER) AS anio, '/en/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.renta_municipios) AND m.poblacion > 20000 AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

```sql mun_ricos
SELECT * FROM ${mun_base} ORDER BY renta_persona_real DESC LIMIT 15
```

```sql mun_pobres
SELECT * FROM ${mun_base} ORDER BY renta_persona_real ASC LIMIT 15
```

```sql mun_resumen
SELECT count(*) AS n, max(renta_persona_real) / min(renta_persona_real) AS ratio,
    arg_max(municipio, renta_persona_real) AS mas_rico, arg_min(municipio, renta_persona_real) AS mas_pobre
FROM ${mun_base}
```

INE's Household Income Distribution Atlas, compiled from tax data, goes down to municipal level. Among the {formatNumber(mun_resumen[0]?.n, 0)} municipalities with more than 20,000 inhabitants, income per person in {mun_resumen[0]?.mas_rico} is {formatNumber(mun_resumen[0]?.ratio, 1)} times that of {mun_resumen[0]?.mas_pobre} ({mun_ricos[0]?.anio} income).

<Grid cols=2>
    <DataTable data={mun_ricos} link=enlace rows=15 showLinkCol=false title="Highest income per person">
        <Column id=municipio title="Municipality" />
        <Column id=provincia title="Province" />
        <Column id=renta_persona_real title="Per person" fmt='#,##0" €"' contentType=bar barColor="#bfdbfe" />
        <Column id=renta_hogar_real title="Per household" fmt='#,##0" €"' />
    </DataTable>
    <DataTable data={mun_pobres} link=enlace rows=15 showLinkCol=false title="Lowest income per person">
        <Column id=municipio title="Municipality" />
        <Column id=provincia title="Province" />
        <Column id=renta_persona_real title="Per person" fmt='#,##0" €"' contentType=bar barColor="#fecaca" />
        <Column id=renta_hogar_real title="Per household" fmt='#,##0" €"' />
    </DataTable>
</Grid>

<DataTable data={mun_base} link=enlace rows=10 search=true showLinkCol=false title="All municipalities with more than 20,000 inhabitants">
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=renta_persona_real title="Income per person" fmt='#,##0" €"' />
    <Column id=renta_hogar_real title="Income per household" fmt='#,##0" €"' />
    <Column id=renta_uc_mediana_real title="Median per consumption unit" fmt='#,##0" €"' />
</DataTable>

<p class="text-xs text-gray-500">Net income (after taxes and social contributions) calculated by INE from tax data, in {hitos[0]?.anio_base} euros; population from the municipal register at 1 January. For some small municipalities INE does not publish the figure, especially before 2020. Look up any municipality in <a href="/en/territorios/municipios">Your municipality in data</a>.</p>

---

## Official sources

- **[INE – Living Conditions Survey (ECV)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176807&menu=ultiDatos&idp=1254735976608)**: tables [9947](https://www.ine.es/jaxiT3/Tabla.htm?t=9947) and [9949](https://www.ine.es/jaxiT3/Tabla.htm?t=9949) (income), [9963](https://www.ine.es/jaxiT3/Tabla.htm?t=9963) (risk of poverty), [76847](https://www.ine.es/jaxiT3/Tabla.htm?t=76847) and [67240](https://www.ine.es/jaxiT3/Tabla.htm?t=67240) (AROPE), [9990](https://www.ine.es/jaxiT3/Tabla.htm?t=9990) (making ends meet), [76846](https://www.ine.es/jaxiT3/Tabla.htm?t=76846) (Gini and S80/S20) and [76844](https://www.ine.es/jaxiT3/Tabla.htm?t=76844) (income by age).
- **[INE – Household Income Distribution Atlas](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)**: income by municipality and district ([table 30824](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)) and by region and province ([table 53689](https://www.ine.es/jaxiT3/Tabla.htm?t=53689)).
- **[Eurostat – EU-SILC](https://ec.europa.eu/eurostat/web/income-and-living-conditions)**: Gini ([ilc_di12](https://ec.europa.eu/eurostat/databrowser/view/ilc_di12/default/table)), S80/S20 ([ilc_di11](https://ec.europa.eu/eurostat/databrowser/view/ilc_di11/default/table)) and AROPE ([ilc_peps01n](https://ec.europa.eu/eurostat/databrowser/view/ilc_peps01n/default/table)).
- **INE – Consumer Price Index (CPI)**: used to express amounts in constant euros.

<LastRefreshed prefix="Data updated" />
