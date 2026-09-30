---
title: Criminalidad
description: "Delitos conocidos en España por tipo, comunidad, provincia y municipio desde 2010, evolución de la cibercriminalidad y condenados por nacionalidad con su contexto."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, categoria, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais'
ORDER BY anio
```

```sql resumen
WITH u AS (SELECT max(anio) AS anio FROM ${espana})
SELECT
    u.anio,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS total,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS tasa,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = 2019) AS total_2019,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) AS homicidios,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) * 100 AS homicidios_100k,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Cibercriminalidad' AND e.anio = u.anio) AS ciber
FROM ${espana} e, u
GROUP BY u.anio
```

```sql serie_kpi
-- Historia para los sparklines, en tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018)
WITH b AS (
    SELECT anio, categoria, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria IN ('Total infracciones penales', 'Homicidios y asesinatos consumados')
),
l AS (
    SELECT
        anio,
        CASE WHEN tipologia = 'TOTAL INFRACCIONES PENALES' THEN 'Total infracciones penales' ELSE 'Homicidios y asesinatos consumados' END AS categoria,
        max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND (tipologia = 'TOTAL INFRACCIONES PENALES' OR codigo_tipologia = '1.1.1')
    GROUP BY 1, 2
)
SELECT anio, categoria, tasa_1000 FROM b
UNION ALL
SELECT anio, categoria, tasa_1000 FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY categoria, anio
```

```sql semestre
SELECT periodo, anio, infracciones, infracciones_anio_anterior, infracciones / infracciones_anio_anterior - 1 AS variacion
FROM mother.crimen_ultimo_periodo
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
```

# 🚨 Criminalidad

Los delitos que conocen la Policía Nacional, la Guardia Civil, los Mossos d'Esquadra, la Ertzaintza, la Policía Foral de Navarra y las policías locales, según el Ministerio del Interior.

<Grid cols=4>
    <KpiCard
        title="Infracciones penales conocidas"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(resumen[0]?.tasa, 1)} por 1.000 hab."
        period="{formatCompact(resumen[0]?.total, 2)} en total · {resumen[0]?.anio}"
        change={resumen[0]?.total_2019 ? (100 * (resumen[0].total / resumen[0].total_2019 - 1)).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="vs. 2019"
        direction="positive-down"
        source="Ministerio del Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => d.tasa_1000)}
    />
    <KpiCard
        title="Homicidios y asesinatos"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} por 100.000 hab."
        period="{formatNumber(resumen[0]?.homicidios, 0)} consumados en {resumen[0]?.anio}"
        source="Ministerio del Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => d.tasa_1000 * 100)}
    />
    <KpiCard
        title="Cibercriminalidad"
        value={resumen[0]?.ciber}
        formattedValue="{formatNumber(resumen[0]?.ciber / resumen[0]?.total / 0.01, 0)} %"
        period="{formatNumber(resumen[0]?.ciber / 1000, 0)} mil infracciones por internet, sobre todo estafas"
        source="Ministerio del Interior"
        sparklineData={espana.filter(d => d.categoria === 'Cibercriminalidad').map(d => 100 * d.infracciones / (espana.find(t => t.anio === d.anio && t.categoria === 'Total infracciones penales')?.infracciones ?? NaN)).filter(v => Number.isFinite(v))}
    />
    <KpiCard
        title="Este año ({semestre[0]?.periodo})"
        value={semestre[0]?.infracciones}
        formattedValue={formatCompact(semestre[0]?.infracciones, 2)}
        change={semestre[0]?.variacion != null ? (100 * semestre[0].variacion).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="vs. mismo periodo de {semestre[0]?.anio - 1}"
        direction="positive-down"
        source="Balance de Criminalidad"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('homicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'homicidios')} />


<p class="text-xs text-gray-500">Todas las cifras se dan por habitante para que la evolución no refleje solo el crecimiento de la población (España ganó unos 2 millones de habitantes entre 2019 y 2025); el total aparece como dato secundario. Son hechos <b>conocidos</b> (denunciados o descubiertos por la policía), no todos los delitos cometidos: una subida puede deberse a que se denuncia más (como ha pasado con los delitos sexuales o las estafas por internet). La tasa por habitante no tiene en cuenta a turistas y visitantes, que también sufren y cometen delitos: por eso sale alta en las zonas más turísticas.</p>

## Qué delitos y cómo evolucionan

```sql categorias
SELECT categoria, infracciones, tasa_1000 * 100 AS tasa_100k
FROM ${espana}
WHERE anio = (SELECT max(anio) FROM ${espana})
  AND categoria NOT IN ('Total infracciones penales', 'Criminalidad convencional', 'Cibercriminalidad', 'Resto de infracciones',
                        'Robos con fuerza en domicilios', 'Delitos contra la libertad sexual')
ORDER BY infracciones DESC
```

<BarChart
    data={categorias}
    x=categoria
    y=tasa_100k
    swapXY=true
    sort=false
    yFmt=num0
    yAxisTitle="por 100.000 habitantes"
    fillColor="#b91c1c"
    title="Principales delitos conocidos en {resumen[0]?.anio}, por 100.000 habitantes"
/>

```sql convencional_ciber
SELECT anio, categoria, infracciones, tasa_1000
FROM ${espana}
WHERE categoria IN ('Criminalidad convencional', 'Cibercriminalidad')
ORDER BY anio
```

<BarChart
    data={convencional_ciber}
    x=anio
    y=tasa_1000
    series=categoria
    type=stacked
    yFmt=num1
    yAxisTitle="por 1.000 habitantes"
    xFmt="####"
    colorPalette={['#b91c1c', '#7c3aed']}
    title="Criminalidad convencional y por internet, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">2020 es el año del confinamiento. Desde 2019 el Ministerio cuenta aparte la cibercriminalidad (estafas y otros delitos cometidos por internet), que ha crecido mucho más que el resto.</p>

```sql serie_larga
SELECT anio, tipologia, infracciones, tasa_1000 * 100 AS tasa_100k
FROM mother.crimen_serie_larga
WHERE nivel = 'pais' AND codigo_tipologia IN ('1.1.1', '3.2', '5.1', '5.2.2', '5.3', '5.5.1', '6.1')
ORDER BY anio
```

<LineChart
    data={serie_larga}
    x=anio
    y=tasa_100k
    series=tipologia
    yFmt=num1
    yAxisTitle="por 100.000 habitantes"
    xFmt="####"
    yLog=true
    legend=true
    title="Algunos delitos desde 2010 por 100.000 habitantes (escala logarítmica)"
/>

<p class="text-xs text-gray-500">Escala logarítmica para ver juntos delitos muy distintos en número: una pendiente igual es un mismo ritmo de crecimiento. Las estafas informáticas se han multiplicado desde 2016, los robos en viviendas han bajado y las agresiones sexuales con penetración conocidas han aumentado, en parte porque se denuncian más.</p>

## Por territorio

```sql ccaa
SELECT b.cod, t.nombre AS comunidad, t.ruta, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = b.cod
WHERE b.nivel = 'ccaa' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
ORDER BY b.tasa_1000 DESC
```

```sql provincias
SELECT b.cod, t.nombre AS provincia, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = b.cod
WHERE b.nivel = 'provincia' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
```

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod"
    value="tasa_1000"
    valueFmt="num1"
    colorPalette={['#fef2f2', '#f87171', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio del Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_1000', title: 'Infracciones por 1.000 hab.', fmt: 'num1'},
        {id: 'infracciones', title: 'Infracciones', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=infracciones title="Infracciones conocidas" fmt=num0 />
    <Column id=tasa_1000 title="Por 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
</DataTable>

```sql municipios
WITH u AS (SELECT max(anio) AS anio FROM mother.crimen_balance WHERE nivel = 'municipio')
SELECT
    b.cod AS cod_mun,
    b.territorio AS municipio,
    p.nombre AS provincia,
    b.poblacion,
    max(b.infracciones) FILTER (WHERE b.categoria = 'Total infracciones penales') AS infracciones,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Total infracciones penales') AS tasa_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Hurtos') AS hurtos_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con violencia o intimidación') AS robos_violencia_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con fuerza en domicilios') AS robos_domicilios_1000,
    '/territorios/municipios?m=' || b.cod AS enlace
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = left(b.cod, 2)
WHERE b.nivel = 'municipio'
GROUP BY ALL
ORDER BY tasa_1000 DESC
```

### Municipios de más de 20.000 habitantes ({resumen[0]?.anio})

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=tasa_1000 title="Infracciones por 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
    <Column id=hurtos_1000 title="Hurtos" fmt=num1 />
    <Column id=robos_violencia_1000 title="Robos con violencia" fmt=num1 />
    <Column id=robos_domicilios_1000 title="Robos en domicilios" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Encabezan la lista municipios con aeropuerto, puerto o mucho turismo (El Prat de Llobregat, Adeje, Sant Josep de sa Talaia, Calvià...): allí se denuncian muchos delitos contra visitantes y pasajeros, pero la tasa se divide solo entre los vecinos empadronados. Tasas por 1.000 habitantes empadronados.</p>

## Condenados por nacionalidad

```sql condenados
SELECT anio, sexo, nacionalidad, condenados, poblacion_18, tasa_1000
FROM mother.crimen_condenados
WHERE cod_ccaa = '00' AND nacionalidad IN ('Española', 'Extranjera')
ORDER BY anio
```

```sql condenados_ultimo
SELECT
    max(anio) AS anio,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS extranjeros,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS espanoles,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS pob_extranjera,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS pob_espanola,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Extranjera') AS h_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Española') AS h_esp,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Extranjera') AS m_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Española') AS m_esp,
    100.0 * max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(condenados) FILTER (WHERE sexo = 'Total') AS pct_condenados_extranjeros,
    100.0 * max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(poblacion_18) FILTER (WHERE sexo = 'Total') AS pct_poblacion_extranjera
FROM ${condenados}
WHERE anio = (SELECT max(anio) FROM ${condenados})
```

Según la Estadística de Condenados del INE, en {condenados_ultimo[0]?.anio} fueron condenados en firme {formatNumber(condenados_ultimo[0]?.espanoles, 0)} adultos de nacionalidad española y {formatNumber(condenados_ultimo[0]?.extranjeros, 0)} de nacionalidad extranjera ({formatNumber(condenados_ultimo[0]?.pct_condenados_extranjeros, 0)} % del total), cuando los extranjeros son el {formatNumber(condenados_ultimo[0]?.pct_poblacion_extranjera, 0)} % de los residentes adultos.

```sql tasas_sexo
SELECT anio, sexo || ', ' || lower(nacionalidad) AS grupo, tasa_1000
FROM ${condenados}
WHERE sexo IN ('Hombres', 'Mujeres')
ORDER BY anio
```

<LineChart
    data={tasas_sexo}
    x=anio
    y=tasa_1000
    series=grupo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="condenados por 1.000 residentes de 18+ años"
    title="Condenados por 1.000 residentes adultos de su mismo sexo y nacionalidad"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Cómo leer esta comparación</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>La tasa de los extranjeros está sobreestimada.</b> Entre los condenados de nacionalidad extranjera hay turistas, personas en tránsito y personas en situación irregular que no figuran en el padrón, así que están en el numerador pero no en el denominador.</li>
<li><b>Edad y sexo pesan mucho.</b> En cualquier país la gran mayoría de los condenados son hombres jóvenes, y la población extranjera tiene más hombres jóvenes que la española. Por eso aquí se comparan hombres con hombres y mujeres con mujeres ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} frente a {formatNumber(condenados_ultimo[0]?.h_esp, 1)} por mil en hombres; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} frente a {formatNumber(condenados_ultimo[0]?.m_esp, 1)} en mujeres). No es posible ajustar por edad: el INE no cruza la edad y la nacionalidad de los condenados.</li>
<li><b>Otros factores</b> que esta estadística no recoge y que en los estudios explican parte de la diferencia: nivel de renta, empleo, nivel de estudios o el barrio de residencia.</li>
<li>Son personas condenadas, no detenidas ni investigadas: ya ha habido un juicio. Se cuenta en la comunidad del juzgado que condena.</li>
</ul>
</div>

```sql delitos_nacionalidad
SELECT delito, total, extranjera / total AS cuota_extranjera
FROM mother.crimen_condenas_delito
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenas_delito)
  AND delito IN ('Homicidio y sus formas', 'Lesiones', 'Contra la libertad', 'Contra la libertad e indemnidad sexuales', 'Hurtos', 'Robos',
                 'Contra la seguridad vial', 'Contra la salud pública', 'Defraudaciones', 'Contra la Administración de Justicia', 'Quebrantamiento de condena',
                 'Contra las relaciones familiares', 'Falsedades')
ORDER BY total DESC
```

<DataTable data={delitos_nacionalidad} rows=all>
    <Column id=delito title="Delito" />
    <Column id=total title="Delitos condenados" fmt=num0 />
    <Column id=cuota_extranjera title="Con condenado extranjero" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">Delitos por los que se condenó en {condenados_ultimo[0]?.anio} (un condenado puede serlo por varios delitos) y porcentaje en los que el condenado tenía nacionalidad extranjera. Los nacionalizados españoles cuentan como españoles.</p>

---

## Fuentes y notas

- **[Ministerio del Interior – Portal Estadístico de Criminalidad](https://estadisticasdecriminalidad.ses.mir.es/)**: serie anual de infracciones penales conocidas por comunidad y provincia desde 2010, y Balance de Criminalidad trimestral con los municipios de más de 20.000 habitantes (año completo desde 2019). En 2019 cambió la clasificación del Balance, así que no se compara con años anteriores.
- **[INE – Estadística de Condenados: adultos](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (tablas 25704 y 49050), a partir del Registro Central de Penados, y **[INE – Estadística Continua de Población](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (tabla 56942) para la población por nacionalidad, sexo y edad a 1 de enero. Población de 18 o más años aproximada a partir de grupos de edad de cinco años.

<LastRefreshed prefix="Datos actualizados" />
