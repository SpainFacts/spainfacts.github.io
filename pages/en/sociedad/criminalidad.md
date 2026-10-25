---
title: Crime
description: "Recorded crime in Spain by type, region, province and municipality since 2010, the rise of cybercrime and convictions by nationality, with context."
i18n_origen: 7a9a98e7cc4a
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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

# 🚨 Crime

Offences known to the National Police, the Guardia Civil, the Mossos d'Esquadra, the Ertzaintza, the Foral Police of Navarre and local police forces, according to the Ministry of the Interior.

<Grid cols=4>
    <KpiCard
        title="Recorded criminal offences"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(resumen[0]?.tasa, 1)} per 1,000 inhabitants"
        period="{formatCompact(resumen[0]?.total, 2)} in total · {resumen[0]?.anio}"
        change={resumen[0]?.total_2019 ? (100 * (resumen[0].total / resumen[0].total_2019 - 1)).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="vs. 2019"
        direction="positive-down"
        source="Ministry of the Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => ({...d, y: d.tasa_1000}))}
    />
    <KpiCard
        title="Homicides and murders"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} per 100,000 inhabitants"
        period="{formatNumber(resumen[0]?.homicidios, 0)} completed in {resumen[0]?.anio}"
        source="Ministry of the Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => ({...d, y: d.tasa_1000 * 100}))}
    />
    <KpiCard
        title="Cybercrime"
        value={resumen[0]?.ciber}
        formattedValue="{formatNumber(resumen[0]?.ciber / resumen[0]?.total / 0.01, 0)} %"
        period="{formatNumber(resumen[0]?.ciber / 1000, 0)} thousand online offences, mostly fraud"
        source="Ministry of the Interior"
        sparklineData={espana.filter(d => d.categoria === 'Cibercriminalidad').map(d => 100 * d.infracciones / (espana.find(t => t.anio === d.anio && t.categoria === 'Total infracciones penales')?.infracciones ?? NaN)).filter(v => Number.isFinite(v))}
    />
    <KpiCard
        title="This year ({semestre[0]?.periodo})"
        value={semestre[0]?.infracciones}
        formattedValue={formatCompact(semestre[0]?.infracciones, 2)}
        change={semestre[0]?.variacion != null ? (100 * semestre[0].variacion).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="vs. same period of {semestre[0]?.anio - 1}"
        direction="positive-down"
        source="Crime Report (Balance de Criminalidad)"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('homicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'homicidios')} />


<p class="text-xs text-gray-500">All figures are given per inhabitant so that trends do not simply reflect population growth (Spain gained around 2 million inhabitants between 2019 and 2025); the total appears as a secondary figure. These are <b>recorded</b> offences (reported to or discovered by the police), not all crimes committed: an increase may be due to more reporting (as has happened with sexual offences and online fraud). The rate per inhabitant does not take into account tourists and visitors, who also suffer and commit crimes: that is why it comes out high in the most touristic areas.</p>

## Which offences and how they are changing

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
    yAxisTitle="per 100,000 inhabitants"
    fillColor="#b91c1c"
    title="Main recorded offences in {resumen[0]?.anio}, per 100,000 inhabitants"
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
    yAxisTitle="per 1,000 inhabitants"
    xFmt="####"
    colorPalette={['#b91c1c', '#7c3aed']}
    title="Conventional and online crime, per 1,000 inhabitants"
/>

<p class="text-xs text-gray-500">2020 was the year of the lockdown. Since 2019 the Ministry has counted cybercrime (fraud and other offences committed online) separately; it has grown far faster than the rest.</p>

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
    yAxisTitle="per 100,000 inhabitants"
    xFmt="####"
    yLog=true
    legend=true
    title="Selected offences since 2010 per 100,000 inhabitants (logarithmic scale)"
/>

<p class="text-xs text-gray-500">Logarithmic scale, so that offences of very different frequency can be seen together: the same slope means the same rate of growth. Online fraud has multiplied since 2016, burglaries of homes have fallen and recorded rapes (sexual assaults with penetration) have risen, partly because more are reported.</p>

## Spain in Europe and the world

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

Homicide is the figure that compares best between countries, and Spain is among the countries with the fewest cases in the world: {formatNumber(mundo_resumen[0]?.homicidios, 1)} per 100,000 inhabitants in {mundo_resumen[0]?.homicidios_anio} (EU median: {formatNumber(mundo_resumen[0]?.homicidios_ue, 1)}). That is number {mundo_resumen[0]?.homicidios_puesto} out of {mundo_resumen[0]?.homicidios_paises} countries, and number {mundo_resumen[0]?.homicidios_puesto_ue} in the EU, counting from the lowest. For the other offences the police record, Spain is below the EU median in {mundo_resumen[0]?.por_debajo} and above it in {mundo_resumen[0]?.por_encima}. It has {formatNumber(mundo_resumen[0]?.presos, 0)} prisoners per 100,000 inhabitants (EU median: {formatNumber(mundo_resumen[0]?.presos_ue, 0)}).

<DataTable data={mundo_espana} rows=all>
    <Column id=delito title="Offence" />
    <Column id=anio title="Year" fmt="####" />
    <Column id=espana title="Spain" fmt=num1 />
    <Column id=mediana_ue title="EU median" fmt=num1 />
    <Column id=mediana_ocde title="OECD median" fmt=num1 />
    <Column id=veces_ue title="Spain / EU median" fmt='0.0"×"' />
    <Column id=puesto_ue_texto title="Rank in the EU" />
    <Column id=puesto_mundo_texto title="Rank in the world" />
</DataTable>

<p class="text-xs text-gray-500">Per 100,000 inhabitants, latest year for each country within the last seven. Rank 1 = the country with the lowest figure. Offences recorded by the police that each country reports to the United Nations (UNODC; in Europe this is the same data collection as Eurostat's); homicides from the World Bank, based on UNODC data; prisoners from UNODC.</p>

<Dropdown data={delitos_lista} name=delito_mundo value=delito title="Offence" defaultValue="Homicidios intencionados" />

<BarChart
    data={mundo_ranking}
    x=pais
    y=por_100k_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="per 100,000 inhabitants"
    title="{inputs.delito_mundo.value}: countries in Europe and the OECD (latest year for each country)"
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
    yAxisTitle="per 100,000 inhabitants"
    title="{inputs.delito_mundo.value}: trend in Spain and other countries"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Why these comparisons need care</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Homicides are the most reliable figure</b>: almost all are recorded, and the definition is similar everywhere.</li>
<li><b>The rest are recorded offences, not committed ones.</b> They depend on how many are reported, which is more where people trust the police or insurance requires a report (this is why the Nordic countries record many thefts), and on how each country counts them.</li>
<li><b>Definitions differ.</b> In Spain, robbery with violence or intimidation includes bag snatching, which other countries may count as theft. Sweden has one of the broadest definitions of rape in Europe. Spain records every report of online fraud as a fraud offence, and these have grown a lot since 2019.</li>
<li><b>Few recorded cases of corruption or money laundering do not mean little corruption</b>: they mostly measure how much is investigated.</li>
<li>There is no total number of offences that can be compared between countries: each one includes different minor offences. This is why the comparison is made offence by offence.</li>
</ul>
</div>

## By area

```sql ccaa
SELECT b.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta, b.infracciones, b.tasa_1000
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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of the Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_1000', title: 'Offences per 1,000 inhabitants', fmt: 'num1'},
        {id: 'infracciones', title: 'Offences', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=infracciones title="Recorded offences" fmt=num0 />
    <Column id=tasa_1000 title="Per 1,000 inhabitants" fmt=num1 contentType=bar barColor="#fecaca" />
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
    '/en/territorios/municipios?m=' || b.cod AS enlace
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = left(b.cod, 2)
WHERE b.nivel = 'municipio'
GROUP BY ALL
ORDER BY tasa_1000 DESC
```

### Municipalities with more than 20,000 inhabitants ({resumen[0]?.anio})

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=tasa_1000 title="Offences per 1,000 inhabitants" fmt=num1 contentType=bar barColor="#fecaca" />
    <Column id=hurtos_1000 title="Thefts" fmt=num1 />
    <Column id=robos_violencia_1000 title="Robberies with violence" fmt=num1 />
    <Column id=robos_domicilios_1000 title="Home burglaries" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">The top of the list is made up of municipalities with an airport, a port or heavy tourism (El Prat de Llobregat, Adeje, Sant Josep de sa Talaia, Calvià...): many offences against visitors and passengers are reported there, but the rate is divided only by registered residents. Rates per 1,000 registered residents.</p>

## Convictions by nationality

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

According to the INE's Convictions Statistics, in {condenados_ultimo[0]?.anio} {formatNumber(condenados_ultimo[0]?.espanoles, 0)} adults of Spanish nationality and {formatNumber(condenados_ultimo[0]?.extranjeros, 0)} of foreign nationality received a final conviction ({formatNumber(condenados_ultimo[0]?.pct_condenados_extranjeros, 0)} % of the total), while foreign nationals make up {formatNumber(condenados_ultimo[0]?.pct_poblacion_extranjera, 0)} % of adult residents.

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
    yAxisTitle="convicted per 1,000 residents aged 18+"
    title="Convicted per 1,000 adult residents of the same sex and nationality"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">How to read this comparison</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>The rate for foreign nationals is overestimated.</b> Those convicted with foreign nationality include tourists and people passing through who do not live in Spain: they are in the numerator but not in the denominator, which counts only residents. Foreign nationals in an irregular situation, on the other hand, are usually in the denominator, because the municipal register does not ask for a residence permit.</li>
<li><b>Age and sex matter a great deal.</b> In every country the vast majority of those convicted are young men, and the foreign population has more young men than the Spanish population. That is why men are compared with men and women with women here ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} versus {formatNumber(condenados_ultimo[0]?.h_esp, 1)} per thousand among men; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} versus {formatNumber(condenados_ultimo[0]?.m_esp, 1)} among women). Further down, the rate is also adjusted for age and for foreign nationals who do not live in Spain.</li>
<li><b>Other factors</b> not captured by these statistics, which studies find explain part of the difference: income level, employment, educational attainment and neighbourhood of residence.</li>
<li>These are people who have been convicted, not arrested or investigated: a trial has already taken place. They are counted in the region of the convicting court.</li>
</ul>
</div>

### Adjusting for age, sex and non-resident foreign nationals

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

The INE does publish convictions by sex, age and nationality together, so each group can be compared with its peers. With every possible adjustment, in {ajuste_ultimo[0]?.anio} the conviction rate of foreign adults goes from {formatNumber(ajuste_ultimo[0]?.v1, 1)} times that of Spanish nationals to {formatNumber(ajuste_ultimo[0]?.v3, 1)} times.

<BarChart
    data={ajuste_barras}
    x=ajuste
    y=veces
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    labels=true
    fillColor="#b91c1c"
    yAxisTitle="times the rate of Spanish nationals"
    title="How many times higher the conviction rate of foreign nationals is, by adjustment ({ajuste_ultimo[0]?.anio})"
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
    yAxisTitle="convicted per 1,000 residents"
    title="Convicted per 1,000 residents of the same sex, age and nationality ({ajuste_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">At every age the rate for foreign nationals is higher, but the gap is widest among young people and narrows with age. {formatNumber(edad_estructura[0]?.ext_jovenes, 0)} % of foreign adults are aged 18 to 30, compared with {formatNumber(edad_estructura[0]?.esp_jovenes, 0)} % of Spanish adults.</p>

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
    yAxisTitle="times the rate of Spanish nationals"
    title="Conviction rate of foreign nationals compared with Spanish nationals, with each adjustment"
/>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">What was adjusted and how</p>
<ol class="list-decimal ml-5 space-y-1">
<li><b>Unadjusted</b> ({formatNumber(ajuste_ultimo[0]?.v1, 1)} times): people convicted among residents aged 18 or over at mid-year ({formatNumber(ajuste_ultimo[0]?.ext1, 1)} per thousand foreign nationals versus {formatNumber(ajuste_ultimo[0]?.esp1, 1)} per thousand Spanish nationals). This is the figure above, but with the population at mid-year instead of 1 January, because convictions are counted over the whole year and the foreign population is growing fast.</li>
<li><b>Age and sex</b> ({formatNumber(ajuste_ultimo[0]?.v2, 1)} times): the rate is calculated for each sex and age group (men aged 18 to 20, women aged 21 to 25...) and then recombined as if Spanish and foreign nationals had the same age pyramid, that of the whole adult population of Spain in {ajuste_ultimo[0]?.anio}. This gives {formatNumber(ajuste_ultimo[0]?.ext2, 1)} versus {formatNumber(ajuste_ultimo[0]?.esp2, 1)} per thousand. This adjustment only removes the part of the difference that is due to foreign nationals being younger and including more men.</li>
<li><b>Non-resident foreign nationals</b> ({formatNumber(ajuste_ultimo[0]?.v3, 1)} times): the foreign visitors who are in Spain on an average day are added to the denominator, since they can be convicted but are not on the municipal register. Using Frontur, the nights that all non-resident visitors spend in Spain over the year are added up and divided by 365: this gives about {formatNumber(ajuste_ultimo[0]?.visitantes / 1e6, 1)} million adults present on an average day, compared with {formatNumber(ajuste_ultimo[0]?.pob_ext / 1e6, 1)} million foreign adults on the register. The result is {formatNumber(ajuste_ultimo[0]?.ext3, 1)} per thousand. Data are only available from 2016.</li>
</ol>
<p class="font-semibold mt-3 mb-1">Assumptions of the third adjustment</p>
<ul class="list-disc ml-5 space-y-1">
<li>Frontur gives how many visitors stay 1 night, 2 to 3, 4 to 7, 8 to 15 or more than 15. The midpoint of each band is used, 25 nights for "more than 15" and half a day for those who do not stay overnight.</li>
<li>Frontur does not publish the age of visitors: 85 % are assumed to be adults, spread by sex and age like the adult population of Spain.</li>
<li>Each day of a visitor counts the same as a day of a resident. A tourist staying a week probably has fewer opportunities to commit an offence (and to be tried here) than a resident, so this adjustment may come out too high.</li>
<li>Frontur counts by country of residence, not by nationality: it includes Spanish nationals who live abroad and come to visit. That is another reason it may come out too high.</li>
<li>In the opposite direction, foreign nationals who live in Spain without being on the register are in no denominator. There is no official figure. The estimate of about 840,000 foreign nationals in an irregular situation on 1 January 2025 (<a class="underline" href="https://www.funcas.es/wp-content/uploads/2026/01/Nota-Coyuntura-Social_Enero-2026.pdf">Funcas</a>) is made precisely from the registered population, so those people are already counted.</li>
</ul>
<p class="mt-3">With these data, the conviction rate of foreign nationals is between {formatNumber(ajuste_ultimo[0]?.v3, 1)} and {formatNumber(ajuste_ultimo[0]?.v2, 1)} times that of Spanish nationals, depending on how much visitors are counted. What these statistics cannot adjust for: income, employment, educational attainment or neighbourhood of residence, which studies find explain another part of the difference, or possible differences in treatment during arrest, investigation or trial.</p>
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
    <Column id=delito title="Offence" />
    <Column id=total title="Offences with a conviction" fmt=num0 />
    <Column id=cuota_extranjera title="With a foreign national convicted" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">Offences for which convictions were handed down in {condenados_ultimo[0]?.anio} (one person may be convicted of several offences) and the percentage in which the convicted person had foreign nationality. Naturalised Spanish citizens count as Spanish.</p>

### By origin

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

Not all immigration is the same. With the same three adjustments, in {procedencia_resumen[0]?.anio} the conviction rate of resident Africans goes from {formatNumber(procedencia_resumen[0]?.africa1, 1)} to {formatNumber(procedencia_resumen[0]?.africa3, 1)} times that of Spanish nationals; for Americans, from {formatNumber(procedencia_resumen[0]?.america1, 1)} to {formatNumber(procedencia_resumen[0]?.america3, 1)}; for citizens of other EU countries, from {formatNumber(procedencia_resumen[0]?.ue1, 1)} to {formatNumber(procedencia_resumen[0]?.ue3, 1)}; and for the rest of Europe (including the United Kingdom), from {formatNumber(procedencia_resumen[0]?.europa1, 1)} to {formatNumber(procedencia_resumen[0]?.europa3, 1)}. Asians come out below Spanish nationals ({formatNumber(procedencia_resumen[0]?.asia3, 1)} times).

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
    yAxisTitle="times the rate of Spanish nationals"
    title="Foreign nationals convicted, by origin: times the rate of Spanish nationals ({procedencia_resumen[0]?.anio})"
/>

<p class="text-xs text-gray-500">INE convictions statistics, which only group by continent: "América" puts Latin America together with the US and Canada (few residents), and "África" puts North Africa together with the rest of the continent. Visitors are split by origin according to the country of residence of the tourists in Frontur. European Union and Rest of Europe, from 2020.</p>

#### By country: arrests and people investigated

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

To separate North Africa from the rest of the continent, or Latin America, we have to use the arrests and investigations of the Ministry of the Interior, which do give the country (but they count arrests, not convictions). In {detenidos_resumen[0]?.anio} there were {formatNumber(detenidos_resumen[0]?.extranjeros, 0)} arrests or investigations per 1,000 foreign nationals aged 15 or over and {formatNumber(detenidos_resumen[0]?.espanoles, 0)} per 1,000 Spanish nationals. Adjusted for age and sex, the rate for foreign nationals is {formatNumber(detenidos_resumen[0]?.total2, 1)} times that of Spanish nationals: {formatNumber(detenidos_resumen[0]?.norte_africa, 1)} times for North Africans, {formatNumber(detenidos_resumen[0]?.subsahariana, 1)} for sub-Saharan Africans, {formatNumber(detenidos_resumen[0]?.hispanoamerica, 1)} for Latin Americans and {formatNumber(detenidos_resumen[0]?.asia, 1)} for Asians. For Europeans, counting tourists, it is {formatNumber(detenidos_resumen[0]?.europa3, 1)} times.

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
    yAxisTitle="times the rate of Spanish nationals"
    title="Arrests and people investigated, by region of origin: times the rate of Spanish nationals ({detenidos_resumen[0]?.anio})"
/>

<DataTable data={detenidos_paises} rows=15 search=true>
    <Column id=pais title="Nationality" />
    <Column id=detenidos title="Arrests and people investigated" fmt=num0 />
    <Column id=poblacion_15 title="Residents aged 15+" fmt=num0 />
    <Column id=detenidos_por_1000_hab title="Per 1,000 residents" fmt=num1 />
    <Column id=veces title="Times the rate of Spanish nationals" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Adjusted for age and sex" fmt='0.0"×"' />
    <Column id=veces_visitantes title="And with tourists" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">How to read arrests by country</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>These are arrests and investigations, not convictions or people.</b> The same person can count several times in a year, and not all end in a conviction. Foreign nationals are more over-represented in arrests than in convictions.</li>
<li><b>They include people who do not live here.</b> Tourists, people passing through and newly arrived foreign nationals who are not yet on the register count in the arrests but not in the population. For nationalities with many recent irregular arrivals, such as Algerian, or with a lot of daily crossings through Ceuta and Melilla, such as Moroccan, the rate is more overestimated. The "And with tourists" column only exists for the countries that Frontur separates.</li>
<li><b>Adjustment for age and sex:</b> since the Interior Ministry does not give the age of those arrested, the curve of convictions by age and sex for Spain is applied to the age pyramid of each nationality, and what is observed is compared with what is expected.</li>
<li>Latin America means the Americas minus Brazil. In the arrests it includes the US and Canada, which the Interior Ministry does not separate, but they are removed from the population: about 100,000 residents against almost 4 million Latin Americans. Only countries with at least 15,000 residents aged 15 or over are shown.</li>
<li>In 2020 the Mossos d'Esquadra entered the statistics and in 2025 so did those investigated by the Ertzaintza: the figures jump in those years for all nationalities.</li>
</ul>
</div>

### Spain in Europe

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

Eurostat brings together the convictions by nationality that about twenty European countries publish. In {europa_espana[0]?.anio} the conviction rate of foreign nationals in Spain was {formatNumber(europa_espana[0]?.veces, 1)} times that of Spanish nationals, and {formatNumber(europa_espana[0]?.ajustado, 1)} times when adjusted for age and sex. Of the {formatNumber(europa_espana[0]?.paises, 0)} countries with at least 5 % foreign population, {formatNumber(europa_espana[0]?.por_encima, 0)} have a bigger gap than Spain (the median is {formatNumber(europa_espana[0]?.mediana, 1)} times).

<BarChart
    data={europa}
    x=pais
    y=veces_edad_sexo
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="times the rate of nationals, adjusted for age and sex"
    title="Foreign nationals convicted compared with nationals in Europe, adjusted for age and sex (latest year for each country)"
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
    yAxisTitle="times, adjusted for age and sex"
    title="Trend in selected countries: foreign nationals convicted compared with nationals, adjusted for age and sex"
/>

<DataTable data={europa} rows=all>
    <Column id=pais title="Country" />
    <Column id=anio title="Year" fmt="####" />
    <Column id=extranjeros_poblacion_pct title="Foreign nationals in the population (15+)" fmt='0.0"%"' />
    <Column id=extranjeros_condenados_pct title="Foreign nationals among those convicted" fmt='0.0"%"' />
    <Column id=veces title="Times, unadjusted" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Adjusted for age and sex" fmt='0.0"×"' />
    <Column id=veces_presos title="Prisoners: times" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">How the European comparison was made</p>
<ul class="list-disc ml-5 space-y-1">
<li>Eurostat convictions by nationality (crim_just_ctz) divided by the population aged 15 or over of the same nationality (migr_pop1ctz). The comparison is "how many times" within each country, because each country counts convictions in its own way (in Germany, for example, they include immigration offences that only a foreign national can commit; in Spain being in an irregular situation is not an offence).</li>
<li>Eurostat does not give the age of those convicted. To adjust for age and sex, the curve of convictions by age and sex for Spain is applied to the age pyramid of nationals and foreign nationals in each country. This gives how many convictions would be expected in each group just because of its age and sex. For Spain, this method gives {formatNumber(europa_espana[0]?.ajustado, 1)} times, almost the same as the direct adjustment with the full INE data.</li>
<li>There is no adjustment for tourists in any country. Spain, Austria, Greece or Portugal receive many visitors per inhabitant, so their figure is somewhat more inflated than that of others.</li>
<li>Only countries with at least 5 % foreign nationals and with data since 2018. Latvia is left out: there, most of the "foreign nationals" are lifelong residents without Latvian citizenship. "Prisoners: times" compares prisoners (including those on remand) in the same way, without adjusting for age.</li>
<li>Countries such as Sweden or the Netherlands do not publish this figure in Eurostat. In addition, many immigrants there become citizens early and stop counting as foreign nationals, just as those naturalised in Spain count as Spanish.</li>
</ul>
</div>

---

## Sources and notes

- **[Ministry of the Interior – Crime Statistics Portal](https://estadisticasdecriminalidad.ses.mir.es/)**: annual series of recorded criminal offences by region and province since 2010, and the quarterly Crime Report (Balance de Criminalidad) covering municipalities with more than 20,000 inhabitants (full year since 2019). The Crime Report classification changed in 2019, so it is not compared with earlier years.
- **[INE – Convictions Statistics: adults](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (tables 25704 and 49050), based on the Central Register of Convicted Persons, and **[INE – Convictions by sex, age and nationality](https://www.ine.es/jaxiT3/Tabla.htm?t=25645)** (table 25645) for the age adjustment, and **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (table 56942) for population by nationality, sex and age at 1 January. Population aged 18 or over and of each age band approximated from five-year age groups.
- **[INE – Frontur](https://www.ine.es/jaxiT3/Tabla.htm?t=23987)** (tables 23987 and 23984): non-resident visitors by length of stay and tourists by country of residence, used to estimate how many are in Spain on an average day and where they come from.
- **[Ministry of the Interior – Arrests and people investigated](https://estadisticasdecriminalidad.ses.mir.es/)** (tables 03007 and 03001): foreign nationals arrested or investigated by nationality, and the total, and **[INE – Population by country of nationality](https://www.ine.es/jaxiT3/Tabla.htm?t=56936)** (table 56936) for the denominator.
- **[United Nations – UNODC](https://dataunodc.un.org/)**: offences recorded by the police by type, and prisoners, in every country that answers the UN-CTS survey, and intentional homicides from the **[World Bank](https://data.worldbank.org/indicator/VC.IHR.PSRC.P5)** based on UNODC data.
- **[Eurostat](https://ec.europa.eu/eurostat/databrowser/view/crim_just_ctz)**: convictions (crim_just_ctz) and prisoners (crim_pris_ctz) by nationality in each European country, and population by nationality, sex and age (migr_pop1ctz).

<LastRefreshed prefix="Data updated" />
