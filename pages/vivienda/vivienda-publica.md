---
title: Vivienda pública en alquiler
description: "Cuántas viviendas públicas en alquiler hay en España por habitante y en % de los hogares, por comunidad, provincia y municipio, comparadas con Países Bajos, Austria, Dinamarca, Francia y la media europea, y según el partido que gobernaba."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import EnConstruccion from '../../../../../../src/lib/components/EnConstruccion.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
SELECT c.cod_ccaa, c.comunidad, t.ruta, c.autonomico_2019, c.autonomico_2023, c.variacion_pct_2019_2023,
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
SELECT p.cod_prov, p.provincia, p.comunidad, t.ruta, p.municipal_declarado, p.municipios_con_dato, p.municipios_20k,
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

# 🏘️ Vivienda pública en alquiler

Cuántas viviendas de las administraciones se alquilan a precios por debajo de los de mercado a quien cumple ciertos requisitos: las de las comunidades autónomas y sus empresas públicas y las de los ayuntamientos. Todo se muestra **por cada 1.000 habitantes o en % de los hogares**, para poder comparar comunidades y países de tamaño muy distinto.

<Grid cols=4>
    <KpiCard
        title="Viviendas públicas en alquiler"
        value={resumen[0]?.parque_1000}
        formattedValue="{formatNumber(resumen[0]?.parque_1000, 1)} por 1.000 hab."
        period="estimación del Ministerio, 2023 · {formatCompact(resumen[0]?.parque, 0)} en total, el {formatNumber(resumen[0]?.pct_hogares, 2)} % de los hogares"
        direction="neutral"
        source="Ministerio de Vivienda"
    />
    <KpiCard
        title="De las comunidades autónomas"
        value={resumen[0]?.autonomico_1000_2023}
        formattedValue="{formatNumber(resumen[0]?.autonomico_1000_2023, 1)} por 1.000 hab."
        period="2023 · {formatCompact(resumen[0]?.autonomico_2023, 0)} viviendas en alquiler"
        change={resumen[0]?.autonomico_var?.toFixed(1)}
        changePeriod="vs 2019"
        direction="neutral"
        source="Ministerio de Vivienda (encuesta de vivienda social)"
        sparklineData={espana.filter(d => d.parque_autonomico_1000hab != null).map(d => d.parque_autonomico_1000hab)}
    />
    <KpiCard
        title="Hogares con alquiler por debajo de mercado"
        value={resumen[0]?.ecv_ultimo}
        formattedValue="{formatNumber(resumen[0]?.ecv_ultimo, 1)} %"
        period="de los hogares, {resumen[0]?.ecv_anio} · incluye alquileres reducidos privados"
        direction="neutral"
        source="INE (Encuesta de Condiciones de Vida)"
        sparklineData={espana.filter(d => d.ecv_pct_alquiler_inferior != null).map(d => d.ecv_pct_alquiler_inferior)}
    />
    <KpiCard
        title="Viviendas protegidas de alquiler"
        value={resumen[0]?.calif_ultimo_100k}
        formattedValue="{formatNumber(resumen[0]?.calif_ultimo_100k, 1)} por 100.000 hab."
        period="calificaciones provisionales, {resumen[0]?.calif_anio} · {formatNumber(resumen[0]?.calif_ultimo, 0)} viviendas"
        direction="neutral"
        source="Ministerio de Vivienda"
        sparklineData={calif.map(d => d.calif_alquiler_100k)}
    />
</Grid>

<Comparativa data={comparativa_internacional} decimales={1} />

## Cuántas hay

El Ministerio de Vivienda preguntó en 2023 a las comunidades autónomas y a los ayuntamientos de más de 20.000 habitantes cuántas viviendas tienen y en qué régimen. Con esas respuestas estima que en España hay unas **{formatNumber(resumen[0]?.parque, 0)} viviendas públicas en alquiler**: {formatNumber(resumen[0]?.autonomico_2023, 0)} de las comunidades (suma de sus respuestas) y unas {formatNumber(resumen[0]?.municipal, 0)} de los ayuntamientos (una cifra escalada por población, porque muchos no respondieron). Son {formatNumber(resumen[0]?.parque_1000, 1)} por cada 1.000 habitantes y alcanzan al {formatNumber(resumen[0]?.pct_hogares, 2)} % de los hogares.

El parque de las comunidades en alquiler pasó de {formatNumber(resumen[0]?.autonomico_2019, 0)} viviendas en 2019 a {formatNumber(resumen[0]?.autonomico_2023, 0)} en 2023, un {formatNumber(resumen[0]?.autonomico_var, 1)} % más. No hay una serie anual: el Ministerio solo ha hecho estas dos encuestas.

La Encuesta de Condiciones de Vida del INE da una serie larga, pero más amplia: cuenta los hogares que pagan un alquiler **por debajo del precio de mercado**, lo que incluye la vivienda pública pero también pisos de empresa o alquileres reducidos entre particulares (por eso sale más alta).

<LineChart
    data={ecv}
    x=anio
    y=pct
    series=regimen
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% de los hogares"
    title="Hogares en alquiler según el precio que pagan (% de todos los hogares)"
/>

## Cuántas se promueven cada año

Las **calificaciones provisionales** son el primer paso administrativo de una vivienda protegida: cuántas se ponen en marcha cada año y con qué destino. Entre 2005 y 2008 se calificaban de media {formatNumber(resumen[0]?.calif_media_boom, 0)} viviendas protegidas de alquiler al año; entre 2013 y 2017, {formatNumber(resumen[0]?.calif_media_crisis, 0)}; entre 2019 y 2023, {formatNumber(resumen[0]?.calif_media_reciente, 0)}. No todas son públicas (también las promueven empresas privadas con ayudas) ni todas acaban construyéndose.

<BarChart
    data={calif}
    x=anio
    y=calif_alquiler_100k
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 100.000 habitantes"
    title="Viviendas protegidas de alquiler calificadas cada año por 100.000 habitantes"
/>

<LineChart
    data={calif}
    x=anio
    y=pct_calif_alquiler
    xFmt='0'
    yFmt='0'
    yAxisTitle="% de las calificaciones"
    title="Peso del alquiler en la vivienda protegida calificada cada año (%)"
/>

## España frente a otros países

La OCDE reúne las cifras que dan los propios gobiernos: viviendas sociales en alquiler (renta por debajo de mercado y adjudicadas por reglas, no por precio) en **% de todo el parque de viviendas**. España declaró {formatNumber(resumen[0]?.ocde_viviendas, 0)} en 2019, el {formatNumber(resumen[0]?.ocde_pct, 1)} % del parque, entre los más bajos de la OCDE; la media de la UE es el {formatNumber(ocde_ue[0]?.ue, 1)} % y la de la OCDE, el {formatNumber(ocde_ue[0]?.ocde, 1)} %.

<BarChart
    data={ocde}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% del parque total de viviendas"
    seriesColors={{'España': '#dc2626', 'Media UE / OCDE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Viviendas sociales en alquiler, % del parque total (último dato de cada país)"
/>

Cada país define la vivienda social a su manera (en Países Bajos cuenta también alquiler privado por debajo de mercado; en Austria, solo viviendas principales), así que la comparación es orientativa. En los países con más vivienda social el peso ha bajado algo desde 2010:

<LineChart
    data={ocde_evolucion}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% del parque total"
    markers=true
    title="Vivienda social en alquiler hacia 2010 y hacia 2022 (% del parque total)"
/>

El Ministerio compara también en **% de los hogares** (viviendas principales) con datos de Housing Europe y Eurostat. Para España usa la ECV, que mide algo más amplio; se añade la cifra del parque público del propio Ministerio para verlas juntas:

<BarChart
    data={ue_hogares}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de los hogares"
    seriesColors={{'España': '#dc2626', 'Media UE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Vivienda en alquiler social en la UE, % de las viviendas principales (2023 o 2017)"
/>

## Por comunidad

Viviendas públicas en alquiler que se conocen por cada 1.000 habitantes: las de la comunidad (dato completo de 2023) más las de los ayuntamientos de más de 20.000 habitantes que respondieron a la encuesta (dato parcial). Pulsa en una comunidad para ver su ficha.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'conocido_1000hab', title: 'Por 1.000 hab. (comunidad + ayuntamientos)', fmt: '0.0'},
        {id: 'autonomico_1000hab', title: 'Solo de la comunidad, por 1.000 hab.', fmt: '0.0'},
        {id: 'conocido_pct_hogares', title: '% de los hogares', fmt: '0.00'},
        {id: 'variacion_pct_2019_2023', title: 'Parque autonómico, var. 2019-2023 (%)', fmt: '0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=conocido_1000hab title="Por 1.000 hab." fmt='0.0' />
    <Column id=conocido_pct_hogares title="% hogares" fmt='0.00' />
    <Column id=autonomico_2023 title="De la comunidad (2023)" fmt='#,##0' />
    <Column id=variacion_pct_2019_2023 title="Var. 2019-2023 %" fmt='0' contentType=delta />
    <Column id=municipal_declarado title="De ayuntamientos (declarado)" fmt='#,##0' />
    <Column id=cobertura_municipal_pct title="% población con dato municipal" fmt='0' />
    <Column id=ecv_pct_alquiler_inferior_3a title="% hogares bajo mercado (ECV, 3 años)" fmt='0.0' />
</DataTable>

Sin contar Ceuta y Melilla, los parques autonómicos en alquiler más grandes por habitante son los de {ccaa_extremos[0]?.mas}; los más pequeños, los de {ccaa_extremos[0]?.menos}. En {ccaa_extremos[0]?.mas_venta} la comunidad tiene más viviendas destinadas a la venta que al alquiler, y en otras pesa la colaboración público-privada (suelo público con derecho de superficie o concesión): es el {formatNumber(ccaa_extremos[0]?.ppp_pv, 0)} % del parque autonómico en alquiler del País Vasco y el {formatNumber(ccaa_extremos[0]?.ppp_madrid, 0)} % del de Madrid.

<BarChart
    data={ccaa}
    x=comunidad
    y=calif_alquiler_2005_2023_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Viviendas protegidas de alquiler calificadas entre 2005 y 2023, por 1.000 habitantes de hoy"
/>

## Por provincia

No existe un recuento oficial del parque autonómico por provincia: las comunidades lo declaran en bloque. Lo que sí se conoce por provincia es el **parque municipal en alquiler que declararon los ayuntamientos de más de 20.000 habitantes** ({cobertura_mun[0]?.respondieron} respondieron en 2023, {cobertura_mun[0]?.dato_2019} repiten su dato de 2019 y {cobertura_mun[0]?.sin_dato} no dieron cifras). El mapa lo muestra por 1.000 habitantes de la provincia; una provincia en blanco puede tener parque autonómico, o municipios que no respondieron.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'municipal_1000hab', title: 'Vivienda municipal en alquiler por 1.000 hab.', fmt: '0.00'},
        {id: 'municipal_declarado', title: 'Viviendas municipales declaradas', fmt: '#,##0'},
        {id: 'cobertura_pct', title: '% de la población en municipios con dato', fmt: '0'},
        {id: 'conocido_1000hab', title: 'Con el parque autonómico (uniprovinciales)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=comunidad title="Comunidad" />
    <Column id=municipal_1000hab title="Municipal por 1.000 hab." fmt='0.00' />
    <Column id=municipal_declarado title="Viviendas municipales" fmt='#,##0' />
    <Column id=municipios_con_dato title="Municipios con dato" fmt='0' />
    <Column id=municipios_20k title="Municipios de más de 20.000 hab." fmt='0' />
    <Column id=cobertura_pct title="% población con dato" fmt='0' />
</DataTable>

En las comunidades de una sola provincia (y en Ceuta y Melilla) el parque autonómico sí es provincial y se puede sumar al municipal:

<DataTable data={uniprovinciales} rows=9>
    <Column id=provincia title="Provincia" />
    <Column id=conocido_1000hab title="Por 1.000 hab. (comunidad + ayuntamientos)" fmt='0.0' />
    <Column id=autonomico_2023 title="De la comunidad" fmt='#,##0' />
    <Column id=municipal_declarado title="De ayuntamientos (declarado)" fmt='#,##0' />
</DataTable>

<EnConstruccion motivo="el parque de vivienda de las comunidades por provincia no se publica: la encuesta del Ministerio lo recoge solo por comunidad. Algunas empresas autonómicas (la Agència de l'Habitatge de Catalunya, Alokabide, la AVRA andaluza...) publican su parque por municipio en formatos distintos; integrarlas daría el mapa provincial completo." />

## Por municipio

Viviendas de los ayuntamientos y sus empresas municipales (no incluye las de la comunidad situadas en el municipio), en los municipios de más de 20.000 habitantes con dato.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=alquiler title="En alquiler" fmt='#,##0' />
    <Column id=alquiler_1000hab title="Por 1.000 hab." fmt='0.0' />
    <Column id=total title="Total del parque municipal" fmt='#,##0' />
    <Column id=poblacion title="Población" fmt='#,##0' />
    <Column id=dato title="Dato de" />
</DataTable>

## Por partido

La vivienda protegida la califican las comunidades autónomas, aunque buena parte se financia con los planes estatales de vivienda. Sumando comunidades y años entre {gobiernos[0]?.anio_desde} y {gobiernos[0]?.anio_hasta}, y atribuyendo cada año al partido que gobernaba la comunidad el 1 de julio, se compara la parte de las viviendas protegidas de alquiler calificadas con cada partido con la parte de la población que gobernó (si todos promovieran lo mismo por habitante, la razón sería 1). Con el PP la razón es {formatNumber(pp_psoe[0]?.pp, 2)} ({formatNumber(pp_psoe[0]?.pp_100k, 1)} viviendas por 100.000 habitantes y año) y con el PSOE, {formatNumber(pp_psoe[0]?.psoe, 2)} ({formatNumber(pp_psoe[0]?.psoe_100k, 1)}).

<DataTable data={gobiernos} rows=12>
    <Column id=partido title="Partido que gobernaba" />
    <Column id=anios_comunidad title="Años de gobierno (comunidad x año)" fmt='0' />
    <Column id=calif_alquiler title="Viviendas de alquiler calificadas" fmt='#,##0' />
    <Column id=calif_alquiler_100k_anio title="Por 100.000 hab. y año" fmt='0.0' />
    <Column id=cuota_calif title="% de las calificadas" fmt='0.0' />
    <Column id=cuota_poblacion title="% de la población gobernada" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observado / esperado" fmt='0.00' />
</DataTable>

<BarChart
    data={calif_partido_anio}
    x=anio
    y=calif_alquiler
    series=partido
    xFmt='0'
    yFmt='#,##0'
    seriesColors={Object.fromEntries(gobiernos.map(d => [d.partido, d.color]))}
    title="Viviendas protegidas de alquiler calificadas cada año, según el partido que gobernaba cada comunidad"
/>

Cambio del parque autonómico en alquiler entre 2019 y 2023, agrupando las comunidades por el partido que las gobernaba a mitad de ese periodo:

<DataTable data={parque_partido} rows=10>
    <Column id=partido title="Partido (julio de 2021)" />
    <Column id=comunidades title="Comunidades" fmt='0' />
    <Column id=parque_2019 title="Parque 2019" fmt='#,##0' />
    <Column id=parque_2023 title="Parque 2023" fmt='#,##0' />
    <Column id=variacion_pct title="Var. %" fmt='0.0' contentType=delta />
    <Column id=variacion_1000hab title="Var. por 1.000 hab." fmt='0.00' contentType=delta />
    <Column id=lista title="Comunidades" wrap=true />
</DataTable>

Hay que leerlo con cautela: son pocos años y pocas comunidades por partido, la vivienda tarda años en pasar de la calificación a la entrega (muchas viviendas de un mandato las decidió el anterior), y el parque también cambia por ventas a los inquilinos, traspasos entre administraciones o recuentos distintos en cada encuesta. Las viviendas no llegan una a una sino en promociones, así que no tiene sentido una prueba estadística como en otras páginas.

## Metodología y fuentes

- **Parque público en alquiler**: [Ministerio de Vivienda y Agenda Urbana, Observatorio de Vivienda y Suelo, Boletín especial Vivienda Social 2024](https://www.mivau.gob.es/urbanismo-y-suelo/suelo/observatorio-de-vivienda-y-suelo) (Encuesta sobre vivienda social de 2023 y, para 2019, la de 2019). «En alquiler» incluye las viviendas de titularidad pública y las de colaboración público-privada (suelo público con derecho de superficie o concesión), la cesión a bajo precio y el alojamiento temporal; no incluye el alquiler con opción de compra ni la venta. El total nacional de 2023 es la suma de las comunidades (el boletín da una cifra algo menor en su tabla de evolución). El parque municipal solo recoge a los ayuntamientos de más de 20.000 habitantes que respondieron (o su dato de 2019 si no lo hicieron); el Ministerio lo escala por población para su estimación nacional. En Ceuta y Melilla la ciudad es a la vez comunidad y ayuntamiento y su parque se cuenta una vez.
- **Calificaciones provisionales** de vivienda protegida por régimen de uso y comunidad, 2005-2023, del mismo boletín.
- **Hogares en alquiler por debajo de mercado**: [INE, Encuesta de Condiciones de Vida, tabla 9997](https://www.ine.es/jaxiT3/Tabla.htm?t=9997). Es una encuesta: en las comunidades pequeñas la muestra es reducida y se muestra la media de los tres últimos años.
- **Comparación internacional**: [OCDE, Affordable Housing Database, indicador PH4.2](https://www.oecd.org/en/data/datasets/oecd-affordable-housing-database.html) (% del parque total de viviendas, hacia 2010 y hacia 2022, con las medias UE y OCDE de la propia OCDE; para España puede incluir viviendas de empresa) y la tabla 2.1 del boletín del Ministerio (Housing Europe y Eurostat, % de las viviendas principales).
- **Población** del padrón (INE) a 1 de enero de 2023 y **hogares** de la Estadística Continua de Población; partido de cada Gobierno autonómico según la tabla de presidentes de SpainFacts.
