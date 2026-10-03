---
title: Tourism
description: "International tourists per inhabitant, their spending adjusted for inflation and as a % of GDP, overnight stays and hotel occupancy by region, countries of origin, seasonality and tourist flats by municipality, with INE data."
i18n_origen: 6bfff987dc63
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Month names in English (the queries build them in Spanish)
    const mesEn = (d) => d ? new Date(d).toLocaleDateString('en-GB', { month: 'long', year: 'numeric', timeZone: 'UTC' }) : '';
    const abrevEn = { ene: 'January', feb: 'February', mar: 'March', abr: 'April', may: 'May', jun: 'June', jul: 'July', ago: 'August', sep: 'September', oct: 'October', nov: 'November', dic: 'December' };
    const mesNombreEn = (m) => abrevEn[m] ?? m ?? '';
</script>

```sql mensual
SELECT
    *,
    ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(mes_num AS INTEGER)] || ' de ' || CAST(anio AS INTEGER) AS mes_txt,
    100 * (turistas_12m / lag(turistas_12m, 12) OVER (ORDER BY mes) - 1) AS turistas_12m_var,
    100 * (gasto_medio_persona_real_12m / lag(gasto_medio_persona_real_12m, 12) OVER (ORDER BY mes) - 1) AS gasto_persona_12m_var,
    gasto_pct_pib_12m - lag(gasto_pct_pib_12m, 12) OVER (ORDER BY mes) AS pct_pib_12m_var,
    100 * (pernoct_hotel_1000hab_12m / lag(pernoct_hotel_1000hab_12m, 12) OVER (ORDER BY mes) - 1) AS pernoct_12m_var
FROM mother.turismo_mensual
ORDER BY mes
```

```sql kpi_turistas
SELECT * FROM ${mensual} WHERE turistas_12m IS NOT NULL ORDER BY mes
```

```sql kpi_pib
SELECT * FROM ${mensual} WHERE gasto_pct_pib_12m IS NOT NULL ORDER BY mes
```

```sql kpi_hotel
SELECT * FROM ${mensual} WHERE pernoct_hotel_1000hab_12m IS NOT NULL ORDER BY mes
```

```sql anual
SELECT * FROM mother.turismo_anual ORDER BY anio
```

```sql anual_completo
SELECT * FROM mother.turismo_anual WHERE meses_frontur = 12 ORDER BY anio
```

```sql hitos
WITH a AS (SELECT * FROM mother.turismo_anual WHERE meses_frontur = 12),
ult AS (SELECT * FROM a ORDER BY anio DESC LIMIT 1),
a19 AS (SELECT * FROM a WHERE anio = 2019),
a20 AS (SELECT * FROM a WHERE anio = 2020)
SELECT
    CAST((SELECT anio FROM ult) AS INTEGER) AS anio_ult,
    (SELECT turistas FROM a19) AS t2019,
    (SELECT turistas FROM a20) AS t2020,
    (SELECT turistas FROM ult) AS t_ult,
    (SELECT turistas_por_hab FROM a19) AS tph2019,
    (SELECT turistas_por_hab FROM a20) AS tph2020,
    (SELECT turistas_por_hab FROM ult) AS tph_ult,
    100 * ((SELECT turistas FROM a20) / (SELECT turistas FROM a19) - 1) AS caida_turistas,
    100 * ((SELECT gasto_real_meur FROM a20) / (SELECT gasto_real_meur FROM a19) - 1) AS caida_gasto,
    100 * ((SELECT pernoct_hotel FROM a20) / (SELECT pernoct_hotel FROM a19) - 1) AS caida_hotel,
    (SELECT gasto_pct_pib FROM a19) AS pib2019,
    (SELECT gasto_pct_pib FROM a20) AS pib2020,
    (SELECT gasto_pct_pib FROM ult) AS pib_ult,
    (SELECT count(*) FROM mother.turismo_mensual WHERE anio = 2020 AND turistas = 0) AS meses_cero,
    CAST((SELECT min(anio) FROM a WHERE anio > 2020 AND turistas >= (SELECT turistas FROM a19)) AS INTEGER) AS anio_recupera,
    100 * ((SELECT turistas FROM ult) / (SELECT turistas FROM a19) - 1) AS var_turistas_2019,
    100 * ((SELECT turistas_por_hab FROM ult) / (SELECT turistas_por_hab FROM a19) - 1) AS var_tph_2019,
    100 * ((SELECT gasto_real_meur FROM ult) / (SELECT gasto_real_meur FROM a19) - 1) AS var_gasto_2019,
    100 * ((SELECT gasto_medio_persona_real FROM ult) / (SELECT gasto_medio_persona_real FROM a19) - 1) AS var_gasto_persona_2019,
    (SELECT gasto_medio_persona_real FROM a19) AS gmp2019,
    (SELECT gasto_medio_persona_real FROM ult) AS gmp_ult,
    (SELECT gasto_medio_diario_real FROM a19) AS gmd2019,
    (SELECT gasto_medio_diario_real FROM ult) AS gmd_ult,
    (SELECT duracion_media FROM a19) AS dur2019,
    (SELECT duracion_media FROM ult) AS dur_ult,
    (SELECT gasto_real_por_hab FROM ult) AS gph_ult,
    CAST((SELECT anio_base FROM ult) AS INTEGER) AS anio_base
```

```sql evol_mensual
SELECT mes, turistas_1000hab, turistas
FROM mother.turismo_mensual
WHERE turistas IS NOT NULL
ORDER BY mes
```

```sql gasto_persona
SELECT anio, 'Gasto por turista y viaje' AS serie, gasto_medio_persona_real AS euros FROM ${anual_completo}
ORDER BY anio
```

```sql gasto_dia
SELECT anio, gasto_medio_diario_real AS euros, duracion_media FROM ${anual_completo} ORDER BY anio
```

```sql hotel_anual
SELECT anio, 'Hoteles' AS alojamiento, pernoct_hotel_1000hab AS por_1000 FROM mother.turismo_anual WHERE meses_hotel = 12
UNION ALL
SELECT anio, 'Apartamentos turísticos', pernoct_apart_1000hab FROM mother.turismo_anual WHERE meses_apart = 12
ORDER BY anio
```

```sql ocupacion_anual
SELECT anio, 'Hoteles' AS alojamiento, ocupacion_hotel AS ocupacion FROM mother.turismo_anual WHERE meses_hotel = 12
UNION ALL
SELECT anio, 'Apartamentos turísticos', ocupacion_apart FROM mother.turismo_anual WHERE meses_apart = 12
ORDER BY anio
```

```sql estacional
SELECT
    m.mes_num,
    ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][CAST(m.mes_num AS INTEGER)] AS mes_nombre,
    CAST(m.anio AS VARCHAR) AS anio_txt,
    m.turistas_1000hab,
    1000.0 * m.pernoct_hotel_residentes / m.poblacion AS residentes_1000,
    1000.0 * m.pernoct_hotel_extranjeros / m.poblacion AS extranjeros_1000,
    m.ocupacion_hotel
FROM mother.turismo_mensual m
WHERE m.anio IN (2019, (SELECT max(anio) FROM mother.turismo_anual WHERE meses_frontur = 12))
ORDER BY m.anio, m.mes_num
```

```sql estacional_ult
SELECT * FROM ${estacional} WHERE anio_txt = (SELECT max(anio_txt) FROM ${estacional}) ORDER BY mes_num
```

```sql estacional_hotel
SELECT mes_num, mes_nombre, 'Residentes en España' AS residencia, residentes_1000 AS por_1000 FROM ${estacional_ult}
UNION ALL
SELECT mes_num, mes_nombre, 'Residentes en el extranjero', extranjeros_1000 FROM ${estacional_ult}
ORDER BY mes_num
```

```sql estacional_resumen
SELECT
    arg_max(mes_nombre, turistas_1000hab) AS mes_max,
    arg_min(mes_nombre, turistas_1000hab) AS mes_min,
    max(turistas_1000hab) / min(turistas_1000hab) AS ratio,
    max(ocupacion_hotel) AS ocup_max,
    arg_max(mes_nombre, ocupacion_hotel) AS mes_ocup_max,
    min(ocupacion_hotel) AS ocup_min,
    arg_min(mes_nombre, ocupacion_hotel) AS mes_ocup_min,
    max(anio_txt) AS anio
FROM ${estacional_ult}
```

```sql paises
SELECT *, CAST(anio AS INTEGER) AS anio_int
FROM mother.turismo_paises
WHERE pais <> 'Total' AND anio = (SELECT max(anio) FROM mother.turismo_paises WHERE meses = 12)
ORDER BY turistas DESC
```

```sql paises_gasto
SELECT pais, gasto_medio_persona_real FROM ${paises} WHERE gasto_medio_persona_real IS NOT NULL ORDER BY gasto_medio_persona_real DESC
```

```sql paises_evol
SELECT anio, pais, cuota
FROM mother.turismo_paises
WHERE meses = 12 AND pais IN ('Reino Unido', 'Francia', 'Alemania', 'Italia', 'Países Nórdicos', 'Estados Unidos de América', 'Países Bajos')
ORDER BY anio
```

```sql ccaa
SELECT * REPLACE ('/en' || ruta AS ruta)
FROM mother.turismo_ccaa
WHERE cod_ccaa NOT IN ('00', 'otras') AND anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_hotel = 12)
ORDER BY pernoct_1000hab DESC
```

```sql ccaa_espana
SELECT * FROM mother.turismo_ccaa
WHERE cod_ccaa = '00' AND anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_hotel = 12)
```

```sql ccaa_frontur
SELECT comunidad, turistas_por_hab, gasto_real_por_hab, gasto_medio_persona_real, turistas, CAST(anio AS INTEGER) AS anio
FROM mother.turismo_ccaa
WHERE turistas IS NOT NULL AND cod_ccaa <> '00' AND meses_frontur = 12
  AND anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_frontur = 12)
ORDER BY turistas_por_hab DESC
```

```sql vut_espana
SELECT *, ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(month(periodo) AS INTEGER)] || ' de ' || CAST(anio AS INTEGER) AS periodo_txt
FROM mother.turismo_viviendas
WHERE nivel = 'pais'
ORDER BY periodo
```

```sql vut_ccaa
SELECT cod, nombre, '/en' || ruta AS ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
FROM mother.turismo_viviendas
WHERE nivel = 'ccaa' AND periodo = (SELECT max(periodo) FROM mother.turismo_viviendas)
ORDER BY pct_viviendas DESC
```

```sql vut_prov
SELECT nombre, ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
FROM mother.turismo_viviendas
WHERE nivel = 'provincia' AND periodo = (SELECT max(periodo) FROM mother.turismo_viviendas)
ORDER BY pct_viviendas DESC
LIMIT 15
```

```sql vut_mun
SELECT v.municipio, p.nombre AS provincia, v.poblacion, v.viviendas, v.pct_viviendas / 100 AS pct, v.viviendas_1000hab, v.puesto
FROM mother.turismo_viviendas_municipios v
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = v.cod_prov
WHERE v.periodo = (SELECT max(periodo) FROM mother.turismo_viviendas_municipios)
  AND v.poblacion >= 1000
ORDER BY v.pct_viviendas DESC
LIMIT 25
```

```sql vut_grandes
SELECT v.municipio, v.poblacion, v.viviendas, v.pct_viviendas / 100 AS pct, v.viviendas_1000hab
FROM mother.turismo_viviendas_municipios v
WHERE v.periodo = (SELECT max(periodo) FROM mother.turismo_viviendas_municipios)
  AND v.poblacion >= 500000
ORDER BY v.pct_viviendas DESC
```

# 🏖️ Tourism

How many foreign tourists come to Spain relative to its population, how much they spend after adjusting for inflation, how much weight that spending carries in the economy, where they sleep and how many homes are advertised as tourist accommodation.

<Grid cols=4>
    <KpiCard
        title="International tourists"
        value={kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m, 2)} per inhabitant"
        period="{formatCompact(kpi_turistas.slice(-1)[0]?.turistas_12m, 3)} tourists in the 12 months to {mesEn(kpi_turistas.slice(-1)[0]?.mes)}"
        change={kpi_turistas.slice(-1)[0]?.turistas_12m_var?.toFixed(1)}
        changePeriod="vs previous 12 months"
        direction="neutral"
        source="INE / FRONTUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.turistas_por_hab_12m}))}
    />
    <KpiCard
        title="Spending per tourist"
        value={kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m, 0)} €"
        period="per trip, in {kpi_turistas.slice(-1)[0]?.anio_base} euros, 12 months to {mesEn(kpi_turistas.slice(-1)[0]?.mes)}"
        change={kpi_turistas.slice(-1)[0]?.gasto_persona_12m_var?.toFixed(1)}
        changePeriod="real, vs previous 12 months"
        direction="positive-up"
        source="INE / EGATUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.gasto_medio_persona_real_12m}))}
    />
    <KpiCard
        title="Tourist spending"
        value={kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m}
        formattedValue="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m, 1)}% of GDP"
        period="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_real_por_hab_12m, 0)} € per inhabitant in the 12 months to {mesEn(kpi_pib.slice(-1)[0]?.mes)}"
        change={kpi_pib.slice(-1)[0]?.pct_pib_12m_var?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs a year earlier"
        direction="neutral"
        source="INE / EGATUR, Eurostat"
        sparklineData={kpi_pib.map(d => ({x: d.mes, y: d.gasto_pct_pib_12m}))}
    />
    <KpiCard
        title="Hotel nights"
        value={kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m}
        formattedValue="{formatNumber(kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m, 0)} per 1,000 inhab."
        period="{formatCompact(kpi_hotel.slice(-1)[0]?.pernoct_hotel_12m, 3)} overnight stays in the 12 months to {mesEn(kpi_hotel.slice(-1)[0]?.mes)}"
        change={kpi_hotel.slice(-1)[0]?.pernoct_12m_var?.toFixed(1)}
        changePeriod="vs previous 12 months"
        direction="neutral"
        source="INE / EOH"
        sparklineData={kpi_hotel.slice(-120).map(d => ({x: d.mes, y: d.pernoct_hotel_1000hab_12m}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('turistas_por_habitante')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'turistas_por_habitante')} />


<p class="text-xs text-gray-500">Tourists: non-resident visitors who spend at least one night in Spain (FRONTUR). Spending (EGATUR) includes international transport, accommodation, food and other purchases made on the trip, and is given in constant {hitos[0]?.anio_base} euros. The percentage of GDP compares that spending with nominal GDP: it is a yardstick of size, not tourism's contribution to GDP, because part of the spending goes to companies outside Spain (plane tickets, package holidays). Absolute totals appear only as a reference in the small print.</p>

## Trend: from the 2020 collapse to a record

In 2019 there were {formatNumber(hitos[0]?.tph2019, 2)} international tourist arrivals per inhabitant. In 2020 the figure fell by {formatNumber(-hitos[0]?.caida_turistas, 0)}%, to {formatNumber(hitos[0]?.tph2020, 2)} per inhabitant, with {hitos[0]?.meses_cero} months (April and May) without a single recorded arrival; real spending plunged by {formatNumber(-hitos[0]?.caida_gasto, 0)}% and hotel nights by {formatNumber(-hitos[0]?.caida_hotel, 0)}%. {#if hitos[0]?.anio_recupera}The number of tourists overtook the 2019 figure again in {hitos[0]?.anio_recupera}{/if} and in {hitos[0]?.anio_ult} it was {formatNumber(hitos[0]?.var_turistas_2019, 1)}% higher than before the pandemic ({formatNumber(hitos[0]?.tph_ult, 2)} per inhabitant, {formatNumber(hitos[0]?.var_tph_2019, 1)}% more, because the population has also grown). Adjusted for inflation, their spending was {formatNumber(hitos[0]?.var_gasto_2019, 1)}% higher than in 2019.

<BarChart
    data={anual_completo}
    x=anio
    y=turistas_por_hab
    xFmt='0'
    yFmt='0.00'
    fillColor="#0f766e"
    yAxisTitle="Tourists per inhabitant"
    title="International tourists per inhabitant per year"
/>

<LineChart
    data={evol_mensual}
    x=mes
    y=turistas_1000hab
    yFmt='#,##0'
    lineColor="#0f766e"
    yAxisTitle="Per 1,000 inhabitants"
    title="International tourists arriving each month, per 1,000 inhabitants"
/>

<p class="text-xs text-gray-500">FRONTUR begins in October 2015. In April and May 2020 INE recorded zero tourists because the borders were closed.</p>

## How much they spend

In {hitos[0]?.anio_ult} each tourist spent an average of {formatNumber(hitos[0]?.gmp_ult, 0)} € per trip ({hitos[0]?.anio_base} euros), compared with {formatNumber(hitos[0]?.gmp2019, 0)} € in 2019, and {formatNumber(hitos[0]?.gmd_ult, 0)} € per day, compared with {formatNumber(hitos[0]?.gmd2019, 0)} €. The average stay went from {formatNumber(hitos[0]?.dur2019, 1)} to {formatNumber(hitos[0]?.dur_ult, 1)} days. Overall, spending by foreign tourists was equivalent to {formatNumber(hitos[0]?.pib_ult, 1)}% of GDP ({formatNumber(hitos[0]?.pib2019, 1)}% in 2019 and {formatNumber(hitos[0]?.pib2020, 1)}% in 2020), around {formatNumber(hitos[0]?.gph_ult, 0)} € per inhabitant.

<Grid cols=2>
<LineChart
    data={gasto_dia}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ per day (real)"
    title="Average daily spending per tourist, {hitos[0]?.anio_base} euros"
/>
<BarChart
    data={anual_completo}
    x=anio
    y=gasto_pct_pib
    xFmt='0'
    yFmt='0.0"%"'
    fillColor="#b45309"
    yAxisTitle="% of GDP"
    title="Spending by international tourists as a % of GDP"
/>
</Grid>

<LineChart
    data={gasto_persona}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ per trip (real)"
    title="Average spending per tourist per trip, {hitos[0]?.anio_base} euros"
/>

## Hotels and apartments

Overnight stays by resident and non-resident travellers per 1,000 inhabitants. The hotel series begins in 1999 and shows the 2009 crisis and the 2020 collapse.

<LineChart
    data={hotel_anual}
    x=anio
    y=por_1000
    series=alojamiento
    xFmt='0'
    yFmt='#,##0'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="Overnight stays per 1,000 inhab."
    title="Overnight stays per year per 1,000 inhabitants"
/>

<LineChart
    data={ocupacion_anual}
    x=anio
    y=ocupacion
    series=alojamiento
    xFmt='0'
    yFmt='0.0"%"'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="% of bed-places occupied"
    title="Bed-place occupancy rate (weighted annual average)"
/>

<p class="text-xs text-gray-500">In {anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.anio}, {formatNumber(anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.pct_extranjeros_hotel, 1)}% of hotel nights were spent by people resident abroad. Occupancy rate: overnight stays divided by available bed-places times the days in the month. The occupancy surveys do not cover tourist flats.</p>

## Seasonality

International tourists arriving each month per 1,000 inhabitants, in {estacional_resumen[0]?.anio} compared with 2019. In {estacional_resumen[0]?.anio} the month with the most arrivals ({mesNombreEn(estacional_resumen[0]?.mes_max)}) received {formatNumber(estacional_resumen[0]?.ratio, 1)} times as many tourists as the month with the fewest ({mesNombreEn(estacional_resumen[0]?.mes_min)}). Hotel occupancy was {formatNumber(estacional_resumen[0]?.ocup_max, 0)}% in {mesNombreEn(estacional_resumen[0]?.mes_ocup_max)} and {formatNumber(estacional_resumen[0]?.ocup_min, 0)}% in {mesNombreEn(estacional_resumen[0]?.mes_ocup_min)}.

<BarChart
    data={estacional}
    x=mes_nombre
    y=turistas_1000hab
    series=anio_txt
    type=grouped
    sort=false
    yFmt='#,##0'
    colorPalette={['#94a3b8', '#0f766e']}
    yAxisTitle="Per 1,000 inhabitants"
    title="International tourists by month, per 1,000 inhabitants"
/>

<BarChart
    data={estacional_hotel}
    x=mes_nombre
    y=por_1000
    series=residencia
    type=stacked
    sort=false
    yFmt='#,##0'
    colorPalette={['#60a5fa', '#1d4ed8']}
    yAxisTitle="Overnight stays per 1,000 inhab."
    title="Hotel nights by month and traveller's country of residence in {estacional_resumen[0]?.anio}, per 1,000 inhabitants"
/>

## Where they come from

Breakdown of tourists in {paises[0]?.anio_int} by country of residence, and change compared with 2019.

<Grid cols=2>
<BarChart
    data={paises}
    x=pais
    y=cuota
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#0f766e"
    title="% of international tourists in {paises[0]?.anio_int}"
/>
<BarChart
    data={paises}
    x=pais
    y=var_2019
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#94a3b8"
    title="Change in the number of tourists compared with 2019"
/>
</Grid>

<BarChart
    data={paises_gasto}
    x=pais
    y=gasto_medio_persona_real
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Average spending per tourist per trip in {paises[0]?.anio_int} ({hitos[0]?.anio_base} euros)"
/>

<p class="text-xs text-gray-500">EGATUR only breaks down spending for the United Kingdom, France, Germany, Italy and the Nordic countries. "Resto de Europa" (rest of Europe), "Resto América" (rest of the Americas) and "Resto del Mundo" (rest of the world) are INE groupings.</p>

<LineChart
    data={paises_evol}
    x=anio
    y=cuota
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of tourists"
    title="Share of the main source markets"
/>

## By region

Overnight stays in hotels and tourist apartments per 1,000 inhabitants in {ccaa[0]?.anio}. For Spain as a whole the figure was {formatNumber(ccaa_espana[0]?.pernoct_1000hab, 0)}; {ccaa[0]?.comunidad} reached {formatNumber(ccaa[0]?.pernoct_1000hab, 0)} and {ccaa.slice(-1)[0]?.comunidad} stood at just {formatNumber(ccaa.slice(-1)[0]?.pernoct_1000hab, 0)}.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="pernoct_1000hab"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pernoct_1000hab', title: 'Overnight stays per 1,000 inhab.', fmt: 'num0'},
        {id: 'ocupacion_hotel', title: 'Hotel occupancy (%)', fmt: 'num1'},
        {id: 'pct_extranjeros_hotel', title: 'Hotel nights by non-residents (%)', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=pernoct_1000hab title="Overnight stays per 1,000 inhab." fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=ocupacion_hotel title="Hotel occupancy (%)" fmt=num1 />
    <Column id=pct_extranjeros_hotel title="Hotel nights by non-residents (%)" fmt=num1 />
</DataTable>

FRONTUR and EGATUR only break down the six regions that receive the most foreign tourists (main destination of the trip). Per inhabitant:

<Grid cols=2>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=turistas_por_hab
    swapXY=true
    yFmt='0.0'
    fillColor="#0f766e"
    title="International tourists per inhabitant in {ccaa_frontur[0]?.anio}"
/>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=gasto_real_por_hab
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Tourist spending per inhabitant in {ccaa_frontur[0]?.anio} ({hitos[0]?.anio_base} euros)"
/>
</Grid>

## Tourist flats

INE counts the homes advertised as tourist accommodation on the major platforms (experimental statistics). In {mesEn(vut_espana.slice(-1)[0]?.periodo)} there were {formatNumber(vut_espana.slice(-1)[0]?.viviendas_1000hab, 1)} tourist flats per 1,000 inhabitants, {formatNumber(vut_espana.slice(-1)[0]?.pct_viviendas, 2)}% of all dwellings ({formatNumber(vut_espana.slice(-1)[0]?.viviendas, 0)} homes). {#if vut_espana.slice(-1)[0]?.var_interanual < 0}That is {formatNumber(-vut_espana.slice(-1)[0]?.var_interanual, 1)}% fewer than in the same month of the previous year.{:else}That is {formatNumber(vut_espana.slice(-1)[0]?.var_interanual, 1)}% more than in the same month of the previous year.{/if}

<LineChart
    data={vut_espana}
    x=periodo
    y=viviendas_1000hab
    yFmt='0.0'
    lineColor="#a21caf"
    startingAtZero={false}
    yAxisTitle="Per 1,000 inhabitants"
    title="Tourist flats per 1,000 inhabitants in Spain"
/>

<p class="text-xs text-gray-500">Measured twice a year: February and August until 2024, May and November since then. Because the figures are seasonal (more homes are advertised in summer), each figure is best compared with the same month of another year.</p>

<MapaEspana
    data={vut_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pct"
    valueFmt="pct2"
    link="ruta"
    colorPalette={['#fdf4ff', '#e879f9', '#86198f']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="Tourist flats as a % of all dwellings, by region"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: '% of dwellings', fmt: 'pct2'},
        {id: 'viviendas_1000hab', title: 'Per 1,000 inhabitants', fmt: 'num1'},
        {id: 'viviendas', title: 'Tourist flats', fmt: 'num0'}
    ]}
/>

<Grid cols=2>
<BarChart
    data={vut_prov}
    x=nombre
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#a21caf"
    title="The 15 provinces with the most tourist flats (% of all dwellings)"
/>
<BarChart
    data={vut_grandes}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#d946ef"
    title="Cities with more than 500,000 inhabitants (% of tourist flats)"
/>
</Grid>

Municipalities with at least 1,000 inhabitants and the highest proportion of tourist flats:

<DataTable data={vut_mun} rows=25>
    <Column id=puesto title="#" />
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=pct title="% of dwellings" fmt=pct1 contentType=bar barColor="#f5d0fe" />
    <Column id=viviendas_1000hab title="Per 1,000 inhab." fmt=num0 />
    <Column id=viviendas title="Tourist flats" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Look up any municipality in <a href="/en/territorios/municipios">Your municipality in data</a>.</p>

---

**Sources:** INE — [FRONTUR, tourists by country of residence](https://www.ine.es/jaxiT3/Tabla.htm?t=10822) and [by region of destination](https://www.ine.es/jaxiT3/Tabla.htm?t=10823); [EGATUR, spending by country](https://www.ine.es/jaxiT3/Tabla.htm?t=10838) and [by region](https://www.ine.es/jaxiT3/Tabla.htm?t=10839); Hotel Occupancy Survey ([overnight stays](https://www.ine.es/jaxiT3/Tabla.htm?t=2074), [occupancy](https://www.ine.es/jaxiT3/Tabla.htm?t=2066)); Tourist Apartment Occupancy Survey ([overnight stays](https://www.ine.es/jaxiT3/Tabla.htm?t=1993), [occupancy](https://www.ine.es/jaxiT3/Tabla.htm?t=2021)); [tourist flats by municipality](https://www.ine.es/jaxiT3/Tabla.htm?t=39363) and [as a % of dwellings](https://www.ine.es/jaxiT3/Tabla.htm?t=39366) (experimental statistics); [CPI](https://www.ine.es/jaxiT3/Tabla.htm?t=76125) and population. GDP: Eurostat ([namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table)).
