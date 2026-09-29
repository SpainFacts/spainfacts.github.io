---
title: Turismo
description: "Turistas internacionales por habitante, su gasto descontada la inflación y en % del PIB, pernoctaciones y ocupación hotelera por comunidad, países de origen, estacionalidad y viviendas turísticas por municipio, con datos del INE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
SELECT *
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
SELECT cod, nombre, ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
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

Cuántos turistas extranjeros llegan a España en proporción a su población, cuánto gastan descontada la inflación, qué peso tiene ese gasto en la economía, dónde duermen y cuántas viviendas se anuncian como alojamiento turístico.

<Grid cols=4>
    <KpiCard
        title="Turistas internacionales"
        value={kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m, 2)} por habitante"
        period="{formatCompact(kpi_turistas.slice(-1)[0]?.turistas_12m, 3)} turistas en los 12 meses hasta {kpi_turistas.slice(-1)[0]?.mes_txt}"
        change={kpi_turistas.slice(-1)[0]?.turistas_12m_var?.toFixed(1)}
        changePeriod="vs 12 meses anteriores"
        direction="neutral"
        source="INE / FRONTUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.turistas_por_hab_12m}))}
    />
    <KpiCard
        title="Gasto por turista"
        value={kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m, 0)} €"
        period="por viaje, en euros de {kpi_turistas.slice(-1)[0]?.anio_base}, 12 meses hasta {kpi_turistas.slice(-1)[0]?.mes_txt}"
        change={kpi_turistas.slice(-1)[0]?.gasto_persona_12m_var?.toFixed(1)}
        changePeriod="real vs 12 meses anteriores"
        direction="positive-up"
        source="INE / EGATUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.gasto_medio_persona_real_12m}))}
    />
    <KpiCard
        title="Gasto de los turistas"
        value={kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m}
        formattedValue="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m, 1)} % del PIB"
        period="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_real_por_hab_12m, 0)} € por habitante en los 12 meses hasta {kpi_pib.slice(-1)[0]?.mes_txt}"
        change={kpi_pib.slice(-1)[0]?.pct_pib_12m_var?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs un año antes"
        direction="neutral"
        source="INE / EGATUR, Eurostat"
        sparklineData={kpi_pib.map(d => ({x: d.mes, y: d.gasto_pct_pib_12m}))}
    />
    <KpiCard
        title="Noches de hotel"
        value={kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m}
        formattedValue="{formatNumber(kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m, 0)} por 1.000 hab."
        period="{formatCompact(kpi_hotel.slice(-1)[0]?.pernoct_hotel_12m, 3)} pernoctaciones en los 12 meses hasta {kpi_hotel.slice(-1)[0]?.mes_txt}"
        change={kpi_hotel.slice(-1)[0]?.pernoct_12m_var?.toFixed(1)}
        changePeriod="vs 12 meses anteriores"
        direction="neutral"
        source="INE / EOH"
        sparklineData={kpi_hotel.slice(-120).map(d => ({x: d.mes, y: d.pernoct_hotel_1000hab_12m}))}
    />
</Grid>

<p class="text-xs text-gray-500">Turistas: visitantes no residentes que pasan al menos una noche en España (FRONTUR). El gasto (EGATUR) incluye transporte internacional, alojamiento, comida y demás compras del viaje, y se da en euros constantes de {hitos[0]?.anio_base}. El porcentaje del PIB compara ese gasto con el PIB nominal: es una referencia de tamaño, no la aportación del turismo al PIB, porque parte del gasto se paga a empresas de fuera de España (billetes de avión, paquetes). Los totales absolutos aparecen solo como referencia en el texto pequeño.</p>

## Evolución: del hundimiento de 2020 al récord

En 2019 llegaron {formatNumber(hitos[0]?.tph2019, 2)} turistas internacionales por habitante. En 2020 la cifra cayó un {formatNumber(-hitos[0]?.caida_turistas, 0)} %, hasta {formatNumber(hitos[0]?.tph2020, 2)} por habitante, con {hitos[0]?.meses_cero} meses (abril y mayo) sin ninguna llegada registrada; el gasto real se hundió un {formatNumber(-hitos[0]?.caida_gasto, 0)} % y las noches de hotel, un {formatNumber(-hitos[0]?.caida_hotel, 0)} %. {#if hitos[0]?.anio_recupera}El número de turistas volvió a superar el de 2019 en {hitos[0]?.anio_recupera}{/if} y en {hitos[0]?.anio_ult} fue un {formatNumber(hitos[0]?.var_turistas_2019, 1)} % mayor que antes de la pandemia ({formatNumber(hitos[0]?.tph_ult, 2)} por habitante, un {formatNumber(hitos[0]?.var_tph_2019, 1)} % más, porque la población también ha crecido). Descontada la inflación, su gasto fue un {formatNumber(hitos[0]?.var_gasto_2019, 1)} % superior al de 2019.

<BarChart
    data={anual_completo}
    x=anio
    y=turistas_por_hab
    xFmt='0'
    yFmt='0.00'
    fillColor="#0f766e"
    yAxisTitle="Turistas por habitante"
    title="Turistas internacionales por habitante y año"
/>

<LineChart
    data={evol_mensual}
    x=mes
    y=turistas_1000hab
    yFmt='#,##0'
    lineColor="#0f766e"
    yAxisTitle="Por 1.000 habitantes"
    title="Turistas internacionales llegados cada mes, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">FRONTUR empieza en octubre de 2015. En abril y mayo de 2020 el INE registró cero turistas por el cierre de fronteras.</p>

## Cuánto gastan

En {hitos[0]?.anio_ult} cada turista gastó de media {formatNumber(hitos[0]?.gmp_ult, 0)} € por viaje (euros de {hitos[0]?.anio_base}), frente a {formatNumber(hitos[0]?.gmp2019, 0)} € en 2019, y {formatNumber(hitos[0]?.gmd_ult, 0)} € por día, frente a {formatNumber(hitos[0]?.gmd2019, 0)} €. La estancia media pasó de {formatNumber(hitos[0]?.dur2019, 1)} a {formatNumber(hitos[0]?.dur_ult, 1)} días. En conjunto, el gasto de los turistas extranjeros equivalió al {formatNumber(hitos[0]?.pib_ult, 1)} % del PIB ({formatNumber(hitos[0]?.pib2019, 1)} % en 2019 y {formatNumber(hitos[0]?.pib2020, 1)} % en 2020), unos {formatNumber(hitos[0]?.gph_ult, 0)} € por habitante.

<Grid cols=2>
<LineChart
    data={gasto_dia}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ por día (reales)"
    title="Gasto medio diario por turista, euros de {hitos[0]?.anio_base}"
/>
<BarChart
    data={anual_completo}
    x=anio
    y=gasto_pct_pib
    xFmt='0'
    yFmt='0.0"%"'
    fillColor="#b45309"
    yAxisTitle="% del PIB"
    title="Gasto de los turistas internacionales en % del PIB"
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
    yAxisTitle="€ por viaje (reales)"
    title="Gasto medio por turista y viaje, euros de {hitos[0]?.anio_base}"
/>

## Hoteles y apartamentos

Pernoctaciones de viajeros residentes y no residentes por cada 1.000 habitantes. La serie hotelera empieza en 1999 y permite ver la crisis de 2009 y el desplome de 2020.

<LineChart
    data={hotel_anual}
    x=anio
    y=por_1000
    series=alojamiento
    xFmt='0'
    yFmt='#,##0'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="Pernoctaciones por 1.000 hab."
    title="Pernoctaciones al año por 1.000 habitantes"
/>

<LineChart
    data={ocupacion_anual}
    x=anio
    y=ocupacion
    series=alojamiento
    xFmt='0'
    yFmt='0.0"%"'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="% de plazas ocupadas"
    title="Grado de ocupación por plazas (media anual ponderada)"
/>

<p class="text-xs text-gray-500">En {anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.anio} el {formatNumber(anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.pct_extranjeros_hotel, 1)} % de las noches de hotel fueron de residentes en el extranjero. Grado de ocupación: pernoctaciones divididas entre plazas disponibles por días del mes. Las encuestas de ocupación no cubren las viviendas turísticas.</p>

## Estacionalidad

Turistas internacionales llegados cada mes por 1.000 habitantes, en {estacional_resumen[0]?.anio} frente a 2019. En {estacional_resumen[0]?.anio} el mes con más llegadas ({estacional_resumen[0]?.mes_max}) recibió {formatNumber(estacional_resumen[0]?.ratio, 1)} veces más turistas que el de menos ({estacional_resumen[0]?.mes_min}). La ocupación hotelera fue del {formatNumber(estacional_resumen[0]?.ocup_max, 0)} % en {estacional_resumen[0]?.mes_ocup_max} y del {formatNumber(estacional_resumen[0]?.ocup_min, 0)} % en {estacional_resumen[0]?.mes_ocup_min}.

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
    title="Turistas internacionales por mes, por 1.000 habitantes"
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
    yAxisTitle="Pernoctaciones por 1.000 hab."
    title="Noches de hotel por mes y residencia del viajero en {estacional_resumen[0]?.anio}, por 1.000 habitantes"
/>

## De dónde vienen

Reparto de los turistas de {paises[0]?.anio_int} por país de residencia y variación frente a 2019.

<Grid cols=2>
<BarChart
    data={paises}
    x=pais
    y=cuota
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#0f766e"
    title="% de los turistas internacionales en {paises[0]?.anio_int}"
/>
<BarChart
    data={paises}
    x=pais
    y=var_2019
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#94a3b8"
    title="Variación del número de turistas frente a 2019"
/>
</Grid>

<BarChart
    data={paises_gasto}
    x=pais
    y=gasto_medio_persona_real
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Gasto medio por turista y viaje en {paises[0]?.anio_int} (euros de {hitos[0]?.anio_base})"
/>

<p class="text-xs text-gray-500">EGATUR solo desglosa el gasto de Reino Unido, Francia, Alemania, Italia y los países nórdicos. "Resto de Europa", "Resto América" y "Resto del Mundo" son agrupaciones del INE.</p>

<LineChart
    data={paises_evol}
    x=anio
    y=cuota
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de los turistas"
    title="Peso de los principales mercados"
/>

## Por comunidad

Pernoctaciones en hoteles y apartamentos turísticos por 1.000 habitantes en {ccaa[0]?.anio}. En el conjunto de España fueron {formatNumber(ccaa_espana[0]?.pernoct_1000hab, 0)}; {ccaa[0]?.comunidad} llegó a {formatNumber(ccaa[0]?.pernoct_1000hab, 0)} y {ccaa.slice(-1)[0]?.comunidad} se quedó en {formatNumber(ccaa.slice(-1)[0]?.pernoct_1000hab, 0)}.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pernoct_1000hab', title: 'Pernoctaciones por 1.000 hab.', fmt: 'num0'},
        {id: 'ocupacion_hotel', title: 'Ocupación hotelera (%)', fmt: 'num1'},
        {id: 'pct_extranjeros_hotel', title: 'Noches de hotel de no residentes (%)', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=pernoct_1000hab title="Pernoctaciones por 1.000 hab." fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=ocupacion_hotel title="Ocupación hotelera (%)" fmt=num1 />
    <Column id=pct_extranjeros_hotel title="Noches de hotel de no residentes (%)" fmt=num1 />
</DataTable>

FRONTUR y EGATUR solo desglosan las seis comunidades que más turistas extranjeros reciben (destino principal del viaje). Por habitante:

<Grid cols=2>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=turistas_por_hab
    swapXY=true
    yFmt='0.0'
    fillColor="#0f766e"
    title="Turistas internacionales por habitante en {ccaa_frontur[0]?.anio}"
/>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=gasto_real_por_hab
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Gasto de los turistas por habitante en {ccaa_frontur[0]?.anio} (euros de {hitos[0]?.anio_base})"
/>
</Grid>

## Viviendas turísticas

El INE cuenta las viviendas anunciadas como alojamiento turístico en las grandes plataformas (medición experimental). En {vut_espana.slice(-1)[0]?.periodo_txt} había {formatNumber(vut_espana.slice(-1)[0]?.viviendas_1000hab, 1)} viviendas turísticas por cada 1.000 habitantes, el {formatNumber(vut_espana.slice(-1)[0]?.pct_viviendas, 2)} % del total de viviendas ({formatNumber(vut_espana.slice(-1)[0]?.viviendas, 0)} viviendas). {#if vut_espana.slice(-1)[0]?.var_interanual < 0}Son un {formatNumber(-vut_espana.slice(-1)[0]?.var_interanual, 1)} % menos que en el mismo mes del año anterior.{:else}Son un {formatNumber(vut_espana.slice(-1)[0]?.var_interanual, 1)} % más que en el mismo mes del año anterior.{/if}

<LineChart
    data={vut_espana}
    x=periodo
    y=viviendas_1000hab
    yFmt='0.0'
    lineColor="#a21caf"
    startingAtZero={false}
    yAxisTitle="Por 1.000 habitantes"
    title="Viviendas turísticas por 1.000 habitantes en España"
/>

<p class="text-xs text-gray-500">Medición semestral: febrero y agosto hasta 2024, mayo y noviembre desde entonces. Como hay temporada (en verano se anuncian más), conviene comparar cada dato con el del mismo mes de otro año.</p>

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Viviendas turísticas en % del total de viviendas, por comunidad"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: '% de las viviendas', fmt: 'pct2'},
        {id: 'viviendas_1000hab', title: 'Por 1.000 habitantes', fmt: 'num1'},
        {id: 'viviendas', title: 'Viviendas turísticas', fmt: 'num0'}
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
    title="Las 15 provincias con más viviendas turísticas (% del total)"
/>
<BarChart
    data={vut_grandes}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#d946ef"
    title="Ciudades de más de 500.000 habitantes (% de viviendas turísticas)"
/>
</Grid>

Los municipios de al menos 1.000 habitantes con mayor proporción de viviendas turísticas:

<DataTable data={vut_mun} rows=25>
    <Column id=puesto title="#" />
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=pct title="% de las viviendas" fmt=pct1 contentType=bar barColor="#f5d0fe" />
    <Column id=viviendas_1000hab title="Por 1.000 hab." fmt=num0 />
    <Column id=viviendas title="Viviendas turísticas" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Busca cualquier municipio en <a href="/territorios/municipios">Tu municipio en datos</a>.</p>

---

**Fuentes:** INE — [FRONTUR, turistas por país de residencia](https://www.ine.es/jaxiT3/Tabla.htm?t=10822) y [por comunidad de destino](https://www.ine.es/jaxiT3/Tabla.htm?t=10823); [EGATUR, gasto por país](https://www.ine.es/jaxiT3/Tabla.htm?t=10838) y [por comunidad](https://www.ine.es/jaxiT3/Tabla.htm?t=10839); Coyuntura Turística Hotelera ([pernoctaciones](https://www.ine.es/jaxiT3/Tabla.htm?t=2074), [ocupación](https://www.ine.es/jaxiT3/Tabla.htm?t=2066)); Encuesta de Ocupación en Apartamentos Turísticos ([pernoctaciones](https://www.ine.es/jaxiT3/Tabla.htm?t=1993), [ocupación](https://www.ine.es/jaxiT3/Tabla.htm?t=2021)); [viviendas turísticas por municipio](https://www.ine.es/jaxiT3/Tabla.htm?t=39363) y [% sobre las viviendas](https://www.ine.es/jaxiT3/Tabla.htm?t=39366) (medición experimental); [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76125) y población. PIB: Eurostat ([namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table)).
