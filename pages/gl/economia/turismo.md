---
i18n_origen: caa9f015f151
title: Turismo
description: "Turistas internacionais por habitante, o seu gasto descontada a inflación e en % do PIB, pernoitas e ocupación hoteleira por comunidade, países de orixe, estacionalidade e vivendas turísticas por concello, con datos do INE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Nomes dos meses en galego (as consultas constrúenos en castelán)
    const mesGl = (d) => d ? new Date(d).toLocaleDateString('gl-ES', { month: 'long', year: 'numeric', timeZone: 'UTC' }) : '';
    const abrevGl = { ene: 'xaneiro', feb: 'febreiro', mar: 'marzo', abr: 'abril', may: 'maio', jun: 'xuño', jul: 'xullo', ago: 'agosto', sep: 'setembro', oct: 'outubro', nov: 'novembro', dic: 'decembro' };
    const mesNombreGl = (m) => abrevGl[m] ?? m ?? '';
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
SELECT * REPLACE ('/gl' || ruta AS ruta)
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
SELECT cod, nombre, '/gl' || ruta AS ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
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

# 🏖️ Turismo

Cantos turistas estranxeiros chegan a España en proporción á súa poboación, canto gastan descontada a inflación, que peso ten ese gasto na economía, onde dormen e cantas vivendas se anuncian como aloxamento turístico.

<Grid cols=4>
    <KpiCard
        title="Turistas internacionais"
        value={kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m, 2)} por habitante"
        period="{formatCompact(kpi_turistas.slice(-1)[0]?.turistas_12m, 3)} turistas nos 12 meses ata {mesGl(kpi_turistas.slice(-1)[0]?.mes)}"
        change={kpi_turistas.slice(-1)[0]?.turistas_12m_var?.toFixed(1)}
        changePeriod="vs. 12 meses anteriores"
        direction="neutral"
        source="INE / FRONTUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.turistas_por_hab_12m}))}
    />
    <KpiCard
        title="Gasto por turista"
        value={kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m, 0)} €"
        period="por viaxe, en euros de {kpi_turistas.slice(-1)[0]?.anio_base}, 12 meses ata {mesGl(kpi_turistas.slice(-1)[0]?.mes)}"
        change={kpi_turistas.slice(-1)[0]?.gasto_persona_12m_var?.toFixed(1)}
        changePeriod="real vs. 12 meses anteriores"
        direction="positive-up"
        source="INE / EGATUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.gasto_medio_persona_real_12m}))}
    />
    <KpiCard
        title="Gasto dos turistas"
        value={kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m}
        formattedValue="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m, 1)} % do PIB"
        period="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_real_por_hab_12m, 0)} € por habitante nos 12 meses ata {mesGl(kpi_pib.slice(-1)[0]?.mes)}"
        change={kpi_pib.slice(-1)[0]?.pct_pib_12m_var?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs. un ano antes"
        direction="neutral"
        source="INE / EGATUR, Eurostat"
        sparklineData={kpi_pib.map(d => ({x: d.mes, y: d.gasto_pct_pib_12m}))}
    />
    <KpiCard
        title="Noites de hotel"
        value={kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m}
        formattedValue="{formatNumber(kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m, 0)} por 1.000 hab."
        period="{formatCompact(kpi_hotel.slice(-1)[0]?.pernoct_hotel_12m, 3)} pernoitas nos 12 meses ata {mesGl(kpi_hotel.slice(-1)[0]?.mes)}"
        change={kpi_hotel.slice(-1)[0]?.pernoct_12m_var?.toFixed(1)}
        changePeriod="vs. 12 meses anteriores"
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


<p class="text-xs text-gray-500">Turistas: visitantes non residentes que pasan polo menos unha noite en España (FRONTUR). O gasto (EGATUR) inclúe transporte internacional, aloxamento, comida e demais compras da viaxe, e dáse en euros constantes de {hitos[0]?.anio_base}. A porcentaxe do PIB compara ese gasto co PIB nominal: é unha referencia de tamaño, non a achega do turismo ao PIB, porque parte do gasto págase a empresas de fóra de España (billetes de avión, paquetes). Os totais absolutos aparecen só como referencia no texto pequeno.</p>

## Evolución: do afundimento de 2020 ao récord

En 2019 chegaron {formatNumber(hitos[0]?.tph2019, 2)} turistas internacionais por habitante. En 2020 a cifra caeu un {formatNumber(-hitos[0]?.caida_turistas, 0)} %, ata {formatNumber(hitos[0]?.tph2020, 2)} por habitante, con {hitos[0]?.meses_cero} meses (abril e maio) sen ningunha chegada rexistrada; o gasto real afundiuse un {formatNumber(-hitos[0]?.caida_gasto, 0)} % e as noites de hotel, un {formatNumber(-hitos[0]?.caida_hotel, 0)} %. {#if hitos[0]?.anio_recupera}O número de turistas volveu superar o de 2019 en {hitos[0]?.anio_recupera}{/if} e en {hitos[0]?.anio_ult} foi un {formatNumber(hitos[0]?.var_turistas_2019, 1)} % maior ca antes da pandemia ({formatNumber(hitos[0]?.tph_ult, 2)} por habitante, un {formatNumber(hitos[0]?.var_tph_2019, 1)} % máis, porque a poboación tamén medrou). Descontada a inflación, o seu gasto foi un {formatNumber(hitos[0]?.var_gasto_2019, 1)} % superior ao de 2019.

<BarChart
    data={anual_completo}
    x=anio
    y=turistas_por_hab
    xFmt='0'
    yFmt='0.00'
    fillColor="#0f766e"
    yAxisTitle="Turistas por habitante"
    title="Turistas internacionais por habitante e ano"
/>

<LineChart
    data={evol_mensual}
    x=mes
    y=turistas_1000hab
    yFmt='#,##0'
    lineColor="#0f766e"
    yAxisTitle="Por 1.000 habitantes"
    title="Turistas internacionais chegados cada mes, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">FRONTUR empeza en outubro de 2015. En abril e maio de 2020 o INE rexistrou cero turistas polo peche de fronteiras.</p>

## Canto gastan

En {hitos[0]?.anio_ult} cada turista gastou de media {formatNumber(hitos[0]?.gmp_ult, 0)} € por viaxe (euros de {hitos[0]?.anio_base}), fronte a {formatNumber(hitos[0]?.gmp2019, 0)} € en 2019, e {formatNumber(hitos[0]?.gmd_ult, 0)} € por día, fronte a {formatNumber(hitos[0]?.gmd2019, 0)} €. A estadía media pasou de {formatNumber(hitos[0]?.dur2019, 1)} a {formatNumber(hitos[0]?.dur_ult, 1)} días. En conxunto, o gasto dos turistas estranxeiros equivaleu ao {formatNumber(hitos[0]?.pib_ult, 1)} % do PIB ({formatNumber(hitos[0]?.pib2019, 1)} % en 2019 e {formatNumber(hitos[0]?.pib2020, 1)} % en 2020), uns {formatNumber(hitos[0]?.gph_ult, 0)} € por habitante.

<Grid cols=2>
<LineChart
    data={gasto_dia}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ por día (reais)"
    title="Gasto medio diario por turista, euros de {hitos[0]?.anio_base}"
/>
<BarChart
    data={anual_completo}
    x=anio
    y=gasto_pct_pib
    xFmt='0'
    yFmt='0.0"%"'
    fillColor="#b45309"
    yAxisTitle="% do PIB"
    title="Gasto dos turistas internacionais en % do PIB"
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
    yAxisTitle="€ por viaxe (reais)"
    title="Gasto medio por turista e viaxe, euros de {hitos[0]?.anio_base}"
/>

## Hoteis e apartamentos

Pernoitas de viaxeiros residentes e non residentes por cada 1.000 habitantes. A serie hoteleira empeza en 1999 e permite ver a crise de 2009 e a caída de 2020.

<LineChart
    data={hotel_anual}
    x=anio
    y=por_1000
    series=alojamiento
    xFmt='0'
    yFmt='#,##0'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="Pernoitas por 1.000 hab."
    title="Pernoitas ao ano por 1.000 habitantes"
/>

<LineChart
    data={ocupacion_anual}
    x=anio
    y=ocupacion
    series=alojamiento
    xFmt='0'
    yFmt='0.0"%"'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="% de prazas ocupadas"
    title="Grao de ocupación por prazas (media anual ponderada)"
/>

<p class="text-xs text-gray-500">En {anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.anio} o {formatNumber(anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.pct_extranjeros_hotel, 1)} % das noites de hotel foron de residentes no estranxeiro. Grao de ocupación: pernoitas divididas entre prazas dispoñibles por días do mes. As enquisas de ocupación non cobren as vivendas turísticas.</p>

## Estacionalidade

Turistas internacionais chegados cada mes por 1.000 habitantes, en {estacional_resumen[0]?.anio} fronte a 2019. En {estacional_resumen[0]?.anio} o mes con máis chegadas ({mesNombreGl(estacional_resumen[0]?.mes_max)}) recibiu {formatNumber(estacional_resumen[0]?.ratio, 1)} veces máis turistas ca o de menos ({mesNombreGl(estacional_resumen[0]?.mes_min)}). A ocupación hoteleira foi do {formatNumber(estacional_resumen[0]?.ocup_max, 0)} % en {mesNombreGl(estacional_resumen[0]?.mes_ocup_max)} e do {formatNumber(estacional_resumen[0]?.ocup_min, 0)} % en {mesNombreGl(estacional_resumen[0]?.mes_ocup_min)}.

<BarChart
    data={estacional}
    x=mes_nombre
    y=turistas_1000hab
    series=anio_txt
    type=grouped
    sort=false
    yFmt='#,##0'
    colorPalette={['#94a3b8', '#0f766e']}
    yAxisTitle="Por 1.000 habitantes"
    title="Turistas internacionais por mes, por 1.000 habitantes"
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
    yAxisTitle="Pernoitas por 1.000 hab."
    title="Noites de hotel por mes e residencia do viaxeiro en {estacional_resumen[0]?.anio}, por 1.000 habitantes"
/>

## De onde veñen

Repartición dos turistas de {paises[0]?.anio_int} por país de residencia e variación fronte a 2019.

<Grid cols=2>
<BarChart
    data={paises}
    x=pais
    y=cuota
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#0f766e"
    title="% dos turistas internacionais en {paises[0]?.anio_int}"
/>
<BarChart
    data={paises}
    x=pais
    y=var_2019
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#94a3b8"
    title="Variación do número de turistas fronte a 2019"
/>
</Grid>

<BarChart
    data={paises_gasto}
    x=pais
    y=gasto_medio_persona_real
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Gasto medio por turista e viaxe en {paises[0]?.anio_int} (euros de {hitos[0]?.anio_base})"
/>

<p class="text-xs text-gray-500">EGATUR só desagrega o gasto do Reino Unido, Francia, Alemaña, Italia e os países nórdicos. "Resto de Europa", "Resto de América" e "Resto do Mundo" son agrupacións do INE.</p>

<LineChart
    data={paises_evol}
    x=anio
    y=cuota
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dos turistas"
    title="Peso dos principais mercados"
/>

## Por comunidade

Pernoitas en hoteis e apartamentos turísticos por 1.000 habitantes en {ccaa[0]?.anio}. No conxunto de España foron {formatNumber(ccaa_espana[0]?.pernoct_1000hab, 0)}; {ccaa[0]?.comunidad} chegou a {formatNumber(ccaa[0]?.pernoct_1000hab, 0)} e {ccaa.slice(-1)[0]?.comunidad} quedou en {formatNumber(ccaa.slice(-1)[0]?.pernoct_1000hab, 0)}.

<AreaMap
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pernoct_1000hab', title: 'Pernoitas por 1.000 hab.', fmt: 'num0'},
        {id: 'ocupacion_hotel', title: 'Ocupación hoteleira (%)', fmt: 'num1'},
        {id: 'pct_extranjeros_hotel', title: 'Noites de hotel de non residentes (%)', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=pernoct_1000hab title="Pernoitas por 1.000 hab." fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=ocupacion_hotel title="Ocupación hoteleira (%)" fmt=num1 />
    <Column id=pct_extranjeros_hotel title="Noites de hotel de non residentes (%)" fmt=num1 />
</DataTable>

FRONTUR e EGATUR só desagregan as seis comunidades que máis turistas estranxeiros reciben (destino principal da viaxe). Por habitante:

<Grid cols=2>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=turistas_por_hab
    swapXY=true
    yFmt='0.0'
    fillColor="#0f766e"
    title="Turistas internacionais por habitante en {ccaa_frontur[0]?.anio}"
/>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=gasto_real_por_hab
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Gasto dos turistas por habitante en {ccaa_frontur[0]?.anio} (euros de {hitos[0]?.anio_base})"
/>
</Grid>

## Vivendas turísticas

O INE conta as vivendas anunciadas como aloxamento turístico nas grandes plataformas (medición experimental). En {mesGl(vut_espana.slice(-1)[0]?.periodo)} había {formatNumber(vut_espana.slice(-1)[0]?.viviendas_1000hab, 1)} vivendas turísticas por cada 1.000 habitantes, o {formatNumber(vut_espana.slice(-1)[0]?.pct_viviendas, 2)} % do total de vivendas ({formatNumber(vut_espana.slice(-1)[0]?.viviendas, 0)} vivendas). {#if vut_espana.slice(-1)[0]?.var_interanual < 0}Son un {formatNumber(-vut_espana.slice(-1)[0]?.var_interanual, 1)} % menos ca no mesmo mes do ano anterior.{:else}Son un {formatNumber(vut_espana.slice(-1)[0]?.var_interanual, 1)} % máis ca no mesmo mes do ano anterior.{/if}

<LineChart
    data={vut_espana}
    x=periodo
    y=viviendas_1000hab
    yFmt='0.0'
    lineColor="#a21caf"
    startingAtZero={false}
    yAxisTitle="Por 1.000 habitantes"
    title="Vivendas turísticas por 1.000 habitantes en España"
/>

<p class="text-xs text-gray-500">Medición semestral: febreiro e agosto ata 2024, maio e novembro desde entón. Como hai tempada (no verán anúncianse máis), convén comparar cada dato co do mesmo mes doutro ano.</p>

<AreaMap
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Vivendas turísticas en % do total de vivendas, por comunidade"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: '% das vivendas', fmt: 'pct2'},
        {id: 'viviendas_1000hab', title: 'Por 1.000 habitantes', fmt: 'num1'},
        {id: 'viviendas', title: 'Vivendas turísticas', fmt: 'num0'}
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
    title="As 15 provincias con máis vivendas turísticas (% do total)"
/>
<BarChart
    data={vut_grandes}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#d946ef"
    title="Cidades de máis de 500.000 habitantes (% de vivendas turísticas)"
/>
</Grid>

Os concellos de polo menos 1.000 habitantes con maior proporción de vivendas turísticas:

<DataTable data={vut_mun} rows=25>
    <Column id=puesto title="#" />
    <Column id=municipio title="Concello" />
    <Column id=provincia title="Provincia" />
    <Column id=pct title="% das vivendas" fmt=pct1 contentType=bar barColor="#f5d0fe" />
    <Column id=viviendas_1000hab title="Por 1.000 hab." fmt=num0 />
    <Column id=viviendas title="Vivendas turísticas" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Busca calquera concello en <a href="/gl/territorios/municipios">O teu concello en datos</a>.</p>

---

**Fontes:** INE — [FRONTUR, turistas por país de residencia](https://www.ine.es/jaxiT3/Tabla.htm?t=10822) e [por comunidade de destino](https://www.ine.es/jaxiT3/Tabla.htm?t=10823); [EGATUR, gasto por país](https://www.ine.es/jaxiT3/Tabla.htm?t=10838) e [por comunidade](https://www.ine.es/jaxiT3/Tabla.htm?t=10839); Coyuntura Turística Hotelera ([pernoitas](https://www.ine.es/jaxiT3/Tabla.htm?t=2074), [ocupación](https://www.ine.es/jaxiT3/Tabla.htm?t=2066)); Encuesta de Ocupación en Apartamentos Turísticos ([pernoitas](https://www.ine.es/jaxiT3/Tabla.htm?t=1993), [ocupación](https://www.ine.es/jaxiT3/Tabla.htm?t=2021)); [vivendas turísticas por concello](https://www.ine.es/jaxiT3/Tabla.htm?t=39363) e [% sobre as vivendas](https://www.ine.es/jaxiT3/Tabla.htm?t=39366) (medición experimental); [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76125) e poboación. PIB: Eurostat ([namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table)).
