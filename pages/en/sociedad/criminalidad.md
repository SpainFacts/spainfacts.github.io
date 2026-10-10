---
title: Crime
description: "Recorded crime in Spain by type, region, province and municipality since 2010, the rise of cybercrime and convictions by nationality, with context."
i18n_origen: 675d5e735dd8
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
<li><b>The rate for foreign nationals is overestimated.</b> Those convicted with foreign nationality include tourists, people in transit and people in an irregular situation who are not on the municipal register, so they are in the numerator but not in the denominator.</li>
<li><b>Age and sex matter a great deal.</b> In every country the vast majority of those convicted are young men, and the foreign population has more young men than the Spanish population. That is why men are compared with men and women with women here ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} versus {formatNumber(condenados_ultimo[0]?.h_esp, 1)} per thousand among men; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} versus {formatNumber(condenados_ultimo[0]?.m_esp, 1)} among women). Adjusting for age is not possible: the INE does not cross-tabulate the age and nationality of those convicted.</li>
<li><b>Other factors</b> not captured by these statistics, which studies find explain part of the difference: income level, employment, educational attainment and neighbourhood of residence.</li>
<li>These are people who have been convicted, not arrested or investigated: a trial has already taken place. They are counted in the region of the convicting court.</li>
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
    <Column id=delito title="Offence" />
    <Column id=total title="Offences with a conviction" fmt=num0 />
    <Column id=cuota_extranjera title="With a foreign national convicted" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">Offences for which convictions were handed down in {condenados_ultimo[0]?.anio} (one person may be convicted of several offences) and the percentage in which the convicted person had foreign nationality. Naturalised Spanish citizens count as Spanish.</p>

---

## Sources and notes

- **[Ministry of the Interior – Crime Statistics Portal](https://estadisticasdecriminalidad.ses.mir.es/)**: annual series of recorded criminal offences by region and province since 2010, and the quarterly Crime Report (Balance de Criminalidad) covering municipalities with more than 20,000 inhabitants (full year since 2019). The Crime Report classification changed in 2019, so it is not compared with earlier years.
- **[INE – Convictions Statistics: adults](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (tables 25704 and 49050), based on the Central Register of Convicted Persons, and **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (table 56942) for population by nationality, sex and age at 1 January. Population aged 18 or over approximated from five-year age groups.

<LastRefreshed prefix="Data updated" />
