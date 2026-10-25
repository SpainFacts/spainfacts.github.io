---
title: Criminalidad
description: "Delitos conocidos en España por tipo, comunidad, provincia y municipio desde 2010, evolución de la cibercriminalidad y condenados por nacionalidad con su contexto."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
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
SELECT periodo, anio, infracciones, infracciones_anio_anterior, variacion_pct / 100 AS variacion
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
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => ({...d, y: d.tasa_1000}))}
    />
    <KpiCard
        title="Homicidios y asesinatos"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} por 100.000 hab."
        period="{formatNumber(resumen[0]?.homicidios, 0)} consumados en {resumen[0]?.anio}"
        source="Ministerio del Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => ({...d, y: d.tasa_1000 * 100}))}
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

## España en Europa y en el mundo

```sql mundo_ultimo
WITH u AS (
    SELECT delito_id, cod_pais, max(anio) AS anio
    FROM mother.crimen_mundo_delitos
    WHERE anio >= (SELECT max(anio) FROM mother.crimen_mundo_delitos) - 6
    GROUP BY ALL
)
SELECT m.*
FROM mother.crimen_mundo_delitos m
JOIN u USING (delito_id, cod_pais, anio)
```

```sql mundo_espana
WITH r AS (
    SELECT *, rank() OVER (PARTITION BY delito_id ORDER BY por_100k_hab) AS puesto_mundo,
           count(*) OVER (PARTITION BY delito_id) AS paises_mundo
    FROM ${mundo_ultimo}
),
e AS (
    SELECT delito_id, cod_pais, rank() OVER (PARTITION BY delito_id ORDER BY por_100k_hab) AS puesto_ue,
           count(*) OVER (PARTITION BY delito_id) AS paises_ue
    FROM ${mundo_ultimo}
    WHERE es_ue
),
m AS (
    SELECT delito_id,
           median(por_100k_hab) FILTER (WHERE es_ue) AS mediana_ue,
           median(por_100k_hab) FILTER (WHERE es_ocde) AS mediana_ocde
    FROM ${mundo_ultimo}
    GROUP BY delito_id
)
SELECT r.delito, r.orden, r.anio, r.por_100k_hab AS espana, m.mediana_ue, m.mediana_ocde,
       r.por_100k_hab / m.mediana_ue AS veces_ue,
       e.puesto_ue, e.paises_ue, r.puesto_mundo, r.paises_mundo,
       e.puesto_ue || ' de ' || e.paises_ue AS puesto_ue_texto,
       r.puesto_mundo || ' de ' || r.paises_mundo AS puesto_mundo_texto
FROM r
JOIN e USING (delito_id, cod_pais)
JOIN m USING (delito_id)
WHERE r.cod_pais = 'ES'
ORDER BY r.orden
```

```sql mundo_resumen
SELECT
    max(espana) FILTER (WHERE orden = 1) AS homicidios,
    max(anio) FILTER (WHERE orden = 1) AS homicidios_anio,
    max(mediana_ue) FILTER (WHERE orden = 1) AS homicidios_ue,
    max(puesto_mundo) FILTER (WHERE orden = 1) AS homicidios_puesto,
    max(paises_mundo) FILTER (WHERE orden = 1) AS homicidios_paises,
    max(puesto_ue) FILTER (WHERE orden = 1) AS homicidios_puesto_ue,
    max(espana) FILTER (WHERE orden = 16) AS presos,
    max(mediana_ue) FILTER (WHERE orden = 16) AS presos_ue,
    count(*) FILTER (WHERE veces_ue < 1 AND orden NOT IN (1, 16)) AS por_debajo,
    count(*) FILTER (WHERE veces_ue >= 1 AND orden NOT IN (1, 16)) AS por_encima
FROM ${mundo_espana}
```

```sql delitos_lista
SELECT DISTINCT delito, orden FROM ${mundo_ultimo} ORDER BY orden
```

```sql mundo_ranking
SELECT pais, por_100k_hab, anio,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM ${mundo_ultimo}
WHERE delito = '${inputs.delito_mundo.value}' AND (es_europa OR es_ocde)
ORDER BY por_100k_hab DESC
```

```sql mundo_serie
SELECT pais, anio, por_100k_hab
FROM mother.crimen_mundo_delitos
WHERE delito = '${inputs.delito_mundo.value}'
  AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'GB', 'US', 'SE')
  AND anio >= 2005
ORDER BY anio
```

En homicidios, que es la cifra que mejor se compara entre países, España está entre los países con menos casos del mundo: {formatNumber(mundo_resumen[0]?.homicidios, 1)} por cada 100.000 habitantes en {mundo_resumen[0]?.homicidios_anio} (mediana de la UE: {formatNumber(mundo_resumen[0]?.homicidios_ue, 1)}), el puesto {mundo_resumen[0]?.homicidios_puesto} entre {mundo_resumen[0]?.homicidios_paises} países y el {mundo_resumen[0]?.homicidios_puesto_ue} de la UE empezando por el más bajo. En los demás delitos que registra la policía, España está por debajo de la mediana de la UE en {mundo_resumen[0]?.por_debajo} y por encima en {mundo_resumen[0]?.por_encima}. Tiene {formatNumber(mundo_resumen[0]?.presos, 0)} presos por cada 100.000 habitantes (mediana de la UE: {formatNumber(mundo_resumen[0]?.presos_ue, 0)}).

<DataTable data={mundo_espana} rows=all>
    <Column id=delito title="Delito" />
    <Column id=anio title="Año" fmt="####" />
    <Column id=espana title="España" fmt=num1 />
    <Column id=mediana_ue title="Mediana UE" fmt=num1 />
    <Column id=mediana_ocde title="Mediana OCDE" fmt=num1 />
    <Column id=veces_ue title="España / mediana UE" fmt='0.0"×"' />
    <Column id=puesto_ue_texto title="Puesto en la UE" />
    <Column id=puesto_mundo_texto title="Puesto en el mundo" />
</DataTable>

<p class="text-xs text-gray-500">Por 100.000 habitantes, último año de cada país en los últimos siete. Puesto 1 = el país con menos. Delitos registrados por la policía que cada país comunica a Naciones Unidas (UNODC; en Europa es la misma recogida que la de Eurostat); homicidios del Banco Mundial con datos de UNODC; presos, de UNODC.</p>

<Dropdown data={delitos_lista} name=delito_mundo value=delito title="Delito" defaultValue="Homicidios intencionados" />

<BarChart
    data={mundo_ranking}
    x=pais
    y=por_100k_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="por 100.000 habitantes"
    title="{inputs.delito_mundo.value}: países de Europa y de la OCDE (último año de cada país)"
/>

<LineChart
    data={mundo_serie}
    x=anio
    y=por_100k_hab
    series=pais
    yFmt=num1
    xFmt="####"
    legend=true
    yMin=0
    yAxisTitle="por 100.000 habitantes"
    title="{inputs.delito_mundo.value}: evolución en España y otros países"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Por qué hay que comparar con cuidado</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Los homicidios son la cifra más fiable</b>: casi siempre se registran y la definición es parecida en todas partes.</li>
<li><b>El resto son delitos registrados, no cometidos.</b> Dependen de cuánto se denuncia, que es más donde la gente confía en la policía o el seguro exige la denuncia (por eso los países nórdicos registran muchos hurtos), y de cómo los cuenta cada país.</li>
<li><b>Las definiciones cambian.</b> En España, el robo con violencia o intimidación incluye los tirones, que en otros países pueden contarse como hurtos. Suecia tiene una de las definiciones de violación más amplias de Europa. España registra como estafa cada denuncia de estafa por internet, y estas han crecido mucho desde 2019.</li>
<li><b>Pocos casos registrados de corrupción o blanqueo no quieren decir poca corrupción</b>: miden sobre todo cuánto se investiga.</li>
<li>No hay una cifra total de delitos comparable entre países: cada uno incluye faltas y delitos leves distintos. Por eso se compara delito a delito.</li>
</ul>
</div>

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

<MapaEspana
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
    b.nombre AS municipio,
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
WHERE nivel = 'pais' AND nacionalidad IN ('Española', 'Extranjera')
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
<li><b>Esta tasa de los extranjeros está sobreestimada.</b> Entre los condenados de nacionalidad extranjera hay turistas y personas de paso que no viven en España: están en el numerador pero no en el denominador, que solo cuenta a los residentes. Los extranjeros en situación irregular, en cambio, sí suelen estar en el denominador, porque el padrón no pide permiso de residencia.</li>
<li><b>Edad y sexo pesan mucho.</b> En cualquier país la gran mayoría de los condenados son hombres jóvenes, y la población extranjera tiene más hombres jóvenes que la española. Por eso esta gráfica compara hombres con hombres y mujeres con mujeres ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} frente a {formatNumber(condenados_ultimo[0]?.h_esp, 1)} por mil en hombres; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} frente a {formatNumber(condenados_ultimo[0]?.m_esp, 1)} en mujeres). Más abajo se ajusta también por edad y por los extranjeros que no viven en España.</li>
<li><b>Otros factores</b> que esta estadística no recoge y que en los estudios explican parte de la diferencia: nivel de renta, empleo, nivel de estudios o el barrio de residencia.</li>
<li>Son personas condenadas, no detenidas ni investigadas: ya ha habido un juicio. Se cuenta en la comunidad del juzgado que condena.</li>
</ul>
</div>

### Ajustando por edad, sexo y extranjeros no residentes

```sql ajuste
SELECT anio, orden, ajuste, espanoles_por_1000_hab, extranjeros_por_1000_hab, veces,
       condenados_extranjeros, poblacion_extranjera_18, no_residentes_presentes
FROM mother.crimen_condenados_ajuste
WHERE procedencia = 'Total'
ORDER BY anio, orden
```

```sql ajuste_ultimo
SELECT
    max(anio) AS anio,
    max(veces) FILTER (WHERE orden = 1) AS v1,
    max(veces) FILTER (WHERE orden = 2) AS v2,
    max(veces) FILTER (WHERE orden = 3) AS v3,
    max(espanoles_por_1000_hab) FILTER (WHERE orden = 1) AS esp1,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 1) AS ext1,
    max(espanoles_por_1000_hab) FILTER (WHERE orden = 2) AS esp2,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 2) AS ext2,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 3) AS ext3,
    max(poblacion_extranjera_18) AS pob_ext,
    max(no_residentes_presentes) AS visitantes
FROM ${ajuste}
WHERE anio = (SELECT max(anio) FROM ${ajuste})
```

```sql ajuste_barras
SELECT ajuste, veces
FROM ${ajuste}
WHERE anio = (SELECT max(anio) FROM ${ajuste})
ORDER BY orden
```

```sql edad_estructura
SELECT
    100.0 * sum(poblacion) FILTER (WHERE nacionalidad = 'Extranjera' AND edad_desde <= 26) / sum(poblacion) FILTER (WHERE nacionalidad = 'Extranjera') AS ext_jovenes,
    100.0 * sum(poblacion) FILTER (WHERE nacionalidad = 'Española' AND edad_desde <= 26) / sum(poblacion) FILTER (WHERE nacionalidad = 'Española') AS esp_jovenes
FROM mother.crimen_condenados_edad
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenados_edad) AND procedencia IN ('España', 'Total')
```

```sql tasas_edad
SELECT replace(replace(replace(tramo_edad, 'De ', ''), ' años', ''), ' a ', '-') AS edad, edad_desde, sexo || ', ' || lower(nacionalidad) AS grupo, condenados_por_1000_hab
FROM mother.crimen_condenados_edad
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenados_edad) AND procedencia IN ('España', 'Total')
ORDER BY edad_desde, grupo
```

El INE sí publica los condenados por sexo, edad y nacionalidad a la vez, así que se puede comparar a cada grupo con sus iguales. Con todos los ajustes posibles, en {ajuste_ultimo[0]?.anio} la tasa de condenados de los extranjeros adultos pasa de ser {formatNumber(ajuste_ultimo[0]?.v1, 1)} veces la de los españoles a {formatNumber(ajuste_ultimo[0]?.v3, 1)} veces.

<BarChart
    data={ajuste_barras}
    x=ajuste
    y=veces
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    labels=true
    fillColor="#b91c1c"
    yAxisTitle="veces la tasa de los españoles"
    title="Cuántas veces es mayor la tasa de condenados de los extranjeros, según el ajuste ({ajuste_ultimo[0]?.anio})"
/>

<BarChart
    data={tasas_edad}
    x=edad
    y=condenados_por_1000_hab
    series=grupo
    type=grouped
    sort=false
    yFmt=num1
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="condenados por 1.000 residentes"
    title="Condenados por 1.000 residentes de su mismo sexo, edad y nacionalidad ({ajuste_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">En todas las edades la tasa de los extranjeros es más alta, pero la distancia es mayor entre los jóvenes y se estrecha con la edad. El {formatNumber(edad_estructura[0]?.ext_jovenes, 0)} % de los extranjeros adultos tiene entre 18 y 30 años, frente al {formatNumber(edad_estructura[0]?.esp_jovenes, 0)} % de los españoles adultos.</p>

<LineChart
    data={ajuste}
    x=anio
    y=veces
    series=ajuste
    yFmt='0.0"×"'
    xFmt="####"
    legend=true
    yMin=0
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="veces la tasa de los españoles"
    title="Tasa de condenados de los extranjeros frente a la de los españoles, con cada ajuste"
/>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Qué se ha ajustado y cómo</p>
<ol class="list-decimal ml-5 space-y-1">
<li><b>Sin ajustar</b> ({formatNumber(ajuste_ultimo[0]?.v1, 1)} veces): condenados entre residentes de 18 o más años a mitad de año ({formatNumber(ajuste_ultimo[0]?.ext1, 1)} por mil extranjeros frente a {formatNumber(ajuste_ultimo[0]?.esp1, 1)} por mil españoles). Es la cifra de arriba con la población a mitad de año en vez de a 1 de enero, porque los condenados se cuentan durante todo el año y la población extranjera crece deprisa.</li>
<li><b>Edad y sexo</b> ({formatNumber(ajuste_ultimo[0]?.v2, 1)} veces): se calcula la tasa de cada grupo de sexo y edad (hombres de 18 a 20 años, mujeres de 21 a 25...) y se recompone como si españoles y extranjeros tuvieran la misma pirámide, la de toda la población adulta de España en {ajuste_ultimo[0]?.anio}. Así quedan {formatNumber(ajuste_ultimo[0]?.ext2, 1)} frente a {formatNumber(ajuste_ultimo[0]?.esp2, 1)} por mil. Este ajuste solo quita la parte de la diferencia que se debe a que los extranjeros son más jóvenes y hay más hombres.</li>
<li><b>Extranjeros no residentes</b> ({formatNumber(ajuste_ultimo[0]?.v3, 1)} veces): se suman al denominador los visitantes extranjeros que hay en España en un día medio, que pueden ser condenados pero no están empadronados. Con Frontur se suman las noches que pasan en España todos los visitantes no residentes del año y se dividen entre 365: salen unos {formatNumber(ajuste_ultimo[0]?.visitantes / 1e6, 1)} millones de adultos presentes en un día medio, frente a {formatNumber(ajuste_ultimo[0]?.pob_ext / 1e6, 1)} millones de extranjeros adultos empadronados. Así quedan {formatNumber(ajuste_ultimo[0]?.ext3, 1)} por mil. Solo hay datos desde 2016.</li>
</ol>
<p class="font-semibold mt-3 mb-1">Supuestos del tercer ajuste</p>
<ul class="list-disc ml-5 space-y-1">
<li>Frontur da cuántos visitantes se quedan 1 noche, de 2 a 3, de 4 a 7, de 8 a 15 o más de 15. Se toma el punto medio de cada tramo, 25 noches para «más de 15» y media jornada para quienes no pernoctan.</li>
<li>Frontur no publica la edad de los visitantes: se supone que el 85 % son adultos y que se reparten por sexo y edad como la población adulta de España.</li>
<li>Cada día de un visitante cuenta igual que un día de un residente. Un turista de una semana seguramente tiene menos ocasiones de delinquir (y de ser juzgado aquí) que un residente, así que este ajuste puede quedarse largo.</li>
<li>Frontur cuenta por país de residencia, no por nacionalidad: incluye a españoles que viven fuera y vienen de visita. También por eso puede quedarse largo.</li>
<li>En sentido contrario, los extranjeros que viven en España sin empadronarse no están en ningún denominador. No hay una cifra oficial. La estimación de unos 840.000 extranjeros en situación irregular a 1 de enero de 2025 (<a class="underline" href="https://www.funcas.es/wp-content/uploads/2026/01/Nota-Coyuntura-Social_Enero-2026.pdf">Funcas</a>) se hace precisamente con la población empadronada, así que esas personas ya están contadas.</li>
</ul>
<p class="mt-3">Con estos datos, la tasa de condenados de los extranjeros está entre {formatNumber(ajuste_ultimo[0]?.v3, 1)} y {formatNumber(ajuste_ultimo[0]?.v2, 1)} veces la de los españoles, según cuánto se cuente a los visitantes. Lo que estas estadísticas no permiten ajustar: renta, empleo, nivel de estudios o barrio de residencia, que en los estudios explican otra parte de la diferencia, ni las posibles diferencias de trato en la detención, la investigación o el juicio.</p>
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

### Por procedencia

```sql procedencia_condenas
SELECT a.procedencia, a.ajuste, a.orden, a.veces, a.anio
FROM mother.crimen_condenados_ajuste a
JOIN (SELECT procedencia, veces AS v2 FROM mother.crimen_condenados_ajuste
      WHERE orden = 2 AND anio = (SELECT max(anio) FROM mother.crimen_condenados_ajuste)) r USING (procedencia)
WHERE a.procedencia <> 'Total' AND a.anio = (SELECT max(anio) FROM mother.crimen_condenados_ajuste)
ORDER BY r.v2 DESC, a.orden
```

```sql procedencia_resumen
SELECT
    max(anio) AS anio,
    max(veces) FILTER (WHERE procedencia = 'África' AND orden = 1) AS africa1,
    max(veces) FILTER (WHERE procedencia = 'África' AND orden = 3) AS africa3,
    max(veces) FILTER (WHERE procedencia = 'América' AND orden = 1) AS america1,
    max(veces) FILTER (WHERE procedencia = 'América' AND orden = 3) AS america3,
    max(veces) FILTER (WHERE procedencia = 'Unión Europea' AND orden = 1) AS ue1,
    max(veces) FILTER (WHERE procedencia = 'Unión Europea' AND orden = 3) AS ue3,
    max(veces) FILTER (WHERE procedencia = 'Resto de Europa' AND orden = 1) AS europa1,
    max(veces) FILTER (WHERE procedencia = 'Resto de Europa' AND orden = 3) AS europa3,
    max(veces) FILTER (WHERE procedencia = 'Asia y Oceanía' AND orden = 3) AS asia3
FROM ${procedencia_condenas}
```

No toda la inmigración es igual. Con los mismos tres ajustes, en {procedencia_resumen[0]?.anio} la tasa de condenados de los africanos residentes pasa de {formatNumber(procedencia_resumen[0]?.africa1, 1)} a {formatNumber(procedencia_resumen[0]?.africa3, 1)} veces la de los españoles; la de los americanos, de {formatNumber(procedencia_resumen[0]?.america1, 1)} a {formatNumber(procedencia_resumen[0]?.america3, 1)}; la de los ciudadanos de otros países de la UE, de {formatNumber(procedencia_resumen[0]?.ue1, 1)} a {formatNumber(procedencia_resumen[0]?.ue3, 1)}, y la del resto de Europa (con el Reino Unido), de {formatNumber(procedencia_resumen[0]?.europa1, 1)} a {formatNumber(procedencia_resumen[0]?.europa3, 1)}. Los asiáticos quedan por debajo de los españoles ({formatNumber(procedencia_resumen[0]?.asia3, 1)} veces).

<BarChart
    data={procedencia_condenas}
    x=procedencia
    y=veces
    series=ajuste
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="veces la tasa de los españoles"
    title="Condenados extranjeros por procedencia: veces la tasa de los españoles ({procedencia_resumen[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estadística de Condenados del INE, que solo agrupa por continentes: «América» junta a Hispanoamérica con EE. UU. y Canadá (pocos residentes), y «África» al norte de África con el resto del continente. Los visitantes se reparten por procedencia según el país de residencia de los turistas de Frontur. Unión Europea y Resto de Europa, desde 2020.</p>

#### Por país: detenciones e investigados

```sql detenidos_regiones
SELECT procedencia, veces, veces_edad_sexo, veces_visitantes, detenidos_por_1000_hab, espanoles_por_1000_hab, anio,
       row_number() OVER (ORDER BY veces_edad_sexo DESC) AS puesto
FROM mother.crimen_detenidos_procedencia
WHERE tipo IN ('total', 'region') AND anio = (SELECT max(anio) FROM mother.crimen_detenidos_procedencia)
```

```sql detenidos_regiones_largo
SELECT procedencia, puesto, 'Sin ajustar' AS ajuste, 1 AS orden, veces AS valor FROM ${detenidos_regiones}
UNION ALL
SELECT procedencia, puesto, 'Edad y sexo', 2, veces_edad_sexo FROM ${detenidos_regiones}
UNION ALL
SELECT procedencia, puesto, 'Edad, sexo y visitantes', 3, veces_visitantes FROM ${detenidos_regiones} WHERE veces_visitantes IS NOT NULL
ORDER BY puesto, orden
```

```sql detenidos_resumen
SELECT
    max(anio) AS anio,
    max(espanoles_por_1000_hab) AS espanoles,
    max(detenidos_por_1000_hab) FILTER (WHERE procedencia = 'Todos los extranjeros') AS extranjeros,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Todos los extranjeros') AS total2,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Norte de África') AS norte_africa,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'África subsahariana') AS subsahariana,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Hispanoamérica') AS hispanoamerica,
    max(veces_visitantes) FILTER (WHERE procedencia = 'Europa') AS europa3,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Asia') AS asia
FROM ${detenidos_regiones}
```

```sql detenidos_paises
SELECT procedencia AS pais, detenidos, poblacion_15, detenidos_por_1000_hab, veces, veces_edad_sexo, veces_visitantes
FROM mother.crimen_detenidos_procedencia
WHERE tipo = 'pais' AND anio = (SELECT max(anio) FROM mother.crimen_detenidos_procedencia)
  AND poblacion_15 >= 15000
ORDER BY veces_edad_sexo DESC
```

Para separar el norte de África del resto del continente, o Hispanoamérica, hay que usar las detenciones e investigados del Ministerio del Interior, que sí dan el país (pero cuentan detenciones, no condenas). En {detenidos_resumen[0]?.anio} hubo {formatNumber(detenidos_resumen[0]?.extranjeros, 0)} detenciones o investigaciones por cada 1.000 extranjeros de 15 o más años y {formatNumber(detenidos_resumen[0]?.espanoles, 0)} por cada 1.000 españoles. Corregido por edad y sexo, la tasa de los extranjeros es {formatNumber(detenidos_resumen[0]?.total2, 1)} veces la de los españoles: {formatNumber(detenidos_resumen[0]?.norte_africa, 1)} veces la de los norteafricanos, {formatNumber(detenidos_resumen[0]?.subsahariana, 1)} la de los subsaharianos, {formatNumber(detenidos_resumen[0]?.hispanoamerica, 1)} la de los hispanoamericanos y {formatNumber(detenidos_resumen[0]?.asia, 1)} la de los asiáticos. La de los europeos, contando a los turistas, es {formatNumber(detenidos_resumen[0]?.europa3, 1)} veces.

<BarChart
    data={detenidos_regiones_largo}
    x=procedencia
    y=valor
    series=ajuste
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="veces la tasa de los españoles"
    title="Detenciones e investigados por región de procedencia: veces la tasa de los españoles ({detenidos_resumen[0]?.anio})"
/>

<DataTable data={detenidos_paises} rows=15 search=true>
    <Column id=pais title="Nacionalidad" />
    <Column id=detenidos title="Detenciones e investigados" fmt=num0 />
    <Column id=poblacion_15 title="Residentes de 15+ años" fmt=num0 />
    <Column id=detenidos_por_1000_hab title="Por 1.000 residentes" fmt=num1 />
    <Column id=veces title="Veces la de los españoles" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Corregido por edad y sexo" fmt='0.0"×"' />
    <Column id=veces_visitantes title="Y con turistas" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Cómo leer las detenciones por país</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Son detenciones e investigaciones, no condenas ni personas.</b> Una misma persona puede contar varias veces en un año, y no todas acaban en condena. Los extranjeros salen más sobrerrepresentados en las detenciones que en las condenas.</li>
<li><b>Incluyen a quien no vive aquí.</b> Turistas, personas de paso y extranjeros recién llegados que aún no están empadronados cuentan en las detenciones pero no en la población. En nacionalidades con muchas llegadas irregulares recientes, como la argelina, o con mucho paso diario por Ceuta y Melilla, como la marroquí, la tasa está más sobreestimada. La columna «Y con turistas» solo existe para los países que Frontur separa.</li>
<li><b>Corrección por edad y sexo:</b> como Interior no da la edad de los detenidos, se aplica a la pirámide de cada nacionalidad la curva de condenados por edad y sexo de España, y se compara lo observado con lo esperado.</li>
<li>Hispanoamérica es América menos Brasil. En las detenciones incluye a EE. UU. y Canadá, que Interior no separa, pero en la población se quitan: son unos 100.000 residentes frente a casi 4 millones de hispanoamericanos. Solo se muestran países con al menos 15.000 residentes de 15 o más años.</li>
<li>En 2020 entraron en la estadística los Mossos d'Esquadra y en 2025 los investigados por la Ertzaintza: las cifras suben de golpe esos años para todas las nacionalidades.</li>
</ul>
</div>

### España en Europa

```sql europa
SELECT pais, cod_pais, anio, veces, veces_edad_sexo, factor_edad_sexo, extranjeros_poblacion_pct, extranjeros_condenados_pct, veces_presos,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.crimen_europa_nacionalidad e
WHERE anio = (SELECT max(anio) FROM mother.crimen_europa_nacionalidad x WHERE x.cod_pais = e.cod_pais)
  AND anio >= 2018 AND extranjeros_poblacion_pct >= 5 AND cod_pais <> 'LV'
ORDER BY veces_edad_sexo DESC
```

```sql europa_espana
SELECT
    max(anio) FILTER (WHERE cod_pais = 'ES') AS anio,
    max(veces) FILTER (WHERE cod_pais = 'ES') AS veces,
    max(veces_edad_sexo) FILTER (WHERE cod_pais = 'ES') AS ajustado,
    count(*) AS paises,
    count(*) FILTER (WHERE veces_edad_sexo > (SELECT veces_edad_sexo FROM ${europa} WHERE cod_pais = 'ES')) AS por_encima,
    median(veces_edad_sexo) AS mediana
FROM ${europa}
```

```sql europa_serie
SELECT pais, anio, veces_edad_sexo
FROM mother.crimen_europa_nacionalidad
WHERE cod_pais IN ('ES', 'DE', 'FR', 'IT', 'PT', 'AT', 'CH', 'DK') AND anio >= 2010
ORDER BY anio
```

Eurostat reúne los condenados por nacionalidad que publican unos veinte países europeos. En {europa_espana[0]?.anio} la tasa de condenados de los extranjeros en España era {formatNumber(europa_espana[0]?.veces, 1)} veces la de los españoles, y {formatNumber(europa_espana[0]?.ajustado, 1)} veces corregida por edad y sexo. De los {formatNumber(europa_espana[0]?.paises, 0)} países con al menos un 5 % de población extranjera, {formatNumber(europa_espana[0]?.por_encima, 0)} tienen una diferencia mayor que la de España (la mediana es {formatNumber(europa_espana[0]?.mediana, 1)} veces).

<BarChart
    data={europa}
    x=pais
    y=veces_edad_sexo
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="veces la tasa de los nacionales, corregida por edad y sexo"
    title="Condenados extranjeros frente a nacionales en Europa, corregido por edad y sexo (último año de cada país)"
/>

<LineChart
    data={europa_serie}
    x=anio
    y=veces_edad_sexo
    series=pais
    yFmt='0.0"×"'
    xFmt="####"
    legend=true
    yMin=0
    yAxisTitle="veces, corregido por edad y sexo"
    title="Evolución en algunos países: condenados extranjeros frente a nacionales, corregido por edad y sexo"
/>

<DataTable data={europa} rows=all>
    <Column id=pais title="País" />
    <Column id=anio title="Año" fmt="####" />
    <Column id=extranjeros_poblacion_pct title="Extranjeros en la población (15+)" fmt='0.0"%"' />
    <Column id=extranjeros_condenados_pct title="Extranjeros entre los condenados" fmt='0.0"%"' />
    <Column id=veces title="Veces, sin ajustar" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Corregido por edad y sexo" fmt='0.0"×"' />
    <Column id=veces_presos title="Presos: veces" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Cómo se ha hecho la comparación europea</p>
<ul class="list-disc ml-5 space-y-1">
<li>Condenados por nacionalidad de Eurostat (crim_just_ctz) divididos entre la población de 15 o más años de la misma nacionalidad (migr_pop1ctz). Se compara «cuántas veces» dentro de cada país, porque cada país cuenta las condenas a su manera (en Alemania, por ejemplo, incluyen delitos de extranjería que solo puede cometer un extranjero; en España estar en situación irregular no es delito).</li>
<li>Eurostat no da la edad de los condenados. Para corregir por edad y sexo se aplica a la pirámide de nacionales y extranjeros de cada país la curva de condenados por edad y sexo de España. Así se calcula cuántos condenados cabría esperar en cada grupo solo por su edad y su sexo. En España, este método da {formatNumber(europa_espana[0]?.ajustado, 1)} veces, casi lo mismo que el ajuste directo con los datos completos del INE.</li>
<li>No se ajusta por turistas en ningún país. España, Austria, Grecia o Portugal reciben muchos visitantes por habitante, así que su cifra está algo más inflada que la de otros.</li>
<li>Solo países con al menos un 5 % de extranjeros y con datos desde 2018. Queda fuera Letonia: allí la mayoría de los «extranjeros» son residentes de toda la vida sin nacionalidad letona. «Presos: veces» compara a los presos (incluidos los preventivos) de la misma forma, sin corregir por edad.</li>
<li>Países como Suecia o Países Bajos no publican este dato en Eurostat. Además, allí muchos inmigrantes se nacionalizan pronto y dejan de contar como extranjeros, igual que los nacionalizados en España cuentan como españoles.</li>
</ul>
</div>

---

## Fuentes y notas

- **[Ministerio del Interior – Portal Estadístico de Criminalidad](https://estadisticasdecriminalidad.ses.mir.es/)**: serie anual de infracciones penales conocidas por comunidad y provincia desde 2010, y Balance de Criminalidad trimestral con los municipios de más de 20.000 habitantes (año completo desde 2019). En 2019 cambió la clasificación del Balance, así que no se compara con años anteriores.
- **[INE – Estadística de Condenados: adultos](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (tablas 25704 y 49050), a partir del Registro Central de Penados, **[INE – Condenados según sexo, edad y nacionalidad](https://www.ine.es/jaxiT3/Tabla.htm?t=25645)** (tabla 25645) para el ajuste por edad, y **[INE – Estadística Continua de Población](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (tabla 56942) para la población por nacionalidad, sexo y edad a 1 de enero. Población de 18 o más años y de cada tramo de edad aproximada a partir de grupos de edad de cinco años.
- **[INE – Frontur](https://www.ine.es/jaxiT3/Tabla.htm?t=23987)** (tablas 23987 y 23984): visitantes no residentes por duración de la estancia y turistas por país de residencia, para estimar cuántos hay en España en un día medio y de dónde vienen.
- **[Ministerio del Interior – Detenciones e investigados](https://estadisticasdecriminalidad.ses.mir.es/)** (tablas 03007 y 03001): detenciones e investigados extranjeros por nacionalidad y el total, y **[INE – Población por país de nacionalidad](https://www.ine.es/jaxiT3/Tabla.htm?t=56936)** (tabla 56936) para el denominador.
- **[Naciones Unidas – UNODC](https://dataunodc.un.org/)**: delitos registrados por la policía por tipo y presos en todos los países que responden a la encuesta UN-CTS, y homicidios intencionados del **[Banco Mundial](https://data.worldbank.org/indicator/VC.IHR.PSRC.P5)** con datos de UNODC.
- **[Eurostat](https://ec.europa.eu/eurostat/databrowser/view/crim_just_ctz)**: condenados (crim_just_ctz) y presos (crim_pris_ctz) por nacionalidad en cada país europeo, y población por nacionalidad, sexo y edad (migr_pop1ctz).

<LastRefreshed prefix="Datos actualizados" />
