---
title: Proactive disclosure
description: "Do public administrations publish on their transparency portals what the law requires of them? Official assessments by entity (Council of Transparency and Good Governance and Canary Islands Transparency Commissioner), their evolution, the comparison by party and what cannot yet be measured."
i18n_origen: 6724b8e266cf
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql age
SELECT CAST(anio AS VARCHAR) AS anio, puntuacion AS icio, gobernante, familia, url_fuente
FROM mother.transparencia_publicidad_activa
WHERE tipo_administracion = 'Administración General del Estado'
ORDER BY anio
```

```sql ctbg_ccaa
SELECT entidad, familia,
    max(CASE WHEN anio = 2020 THEN puntuacion END) AS icio_2020,
    max(CASE WHEN anio = 2021 THEN puntuacion END) AS icio_2021,
    max(CASE WHEN anio = 2021 THEN puntuacion END) - max(CASE WHEN anio = 2020 THEN puntuacion END) AS mejora
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Comunidad autónoma'
GROUP BY entidad, familia
ORDER BY icio_2021 DESC
```

```sql ctbg_ccaa_largo
SELECT entidad, CAST(anio AS VARCHAR) AS evaluacion, puntuacion AS icio
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Comunidad autónoma'
ORDER BY entidad, anio
```

```sql ctbg_ayto
SELECT entidad,
    max(familia) FILTER (WHERE anio = 2021) AS familia,
    max(poblacion) AS poblacion,
    max(CASE WHEN anio = 2020 THEN puntuacion END) AS icio_2020,
    max(CASE WHEN anio = 2021 THEN puntuacion END) AS icio_2021,
    max(url_fuente) FILTER (WHERE anio = 2021) AS informe
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Ayuntamiento'
GROUP BY entidad
ORDER BY icio_2021 DESC
```

```sql ctbg_resumen
SELECT
    avg(puntuacion) FILTER (WHERE tipo_administracion = 'Comunidad autónoma' AND anio = 2021) AS media_ccaa,
    avg(puntuacion) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021) AS media_ayto,
    count(*) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021) AS n_ayto,
    count(*) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021 AND puntuacion < 50) AS ayto_menos_50
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
```

```sql itc
-- ITCanarias con etiqueta corta de periodo (los dos últimos no son años naturales)
SELECT *,
    CASE WHEN periodo LIKE '2022%' THEN '2022/23'
         WHEN periodo LIKE '%2023%2024%' THEN '2023/24'
         ELSE periodo END AS etiqueta
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Comisionado de Transparencia de Canarias'
```

```sql itc_ultimo
SELECT max(orden_periodo) AS orden, max(etiqueta) FILTER (WHERE orden_periodo = (SELECT max(orden_periodo) FROM ${itc})) AS etiqueta
FROM ${itc}
```

```sql itc_evolucion
SELECT CAST(orden_periodo AS INTEGER) AS orden, etiqueta, tipo_administracion,
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE estado = 'evaluada') AS evaluadas,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras
FROM ${itc}
WHERE tipo_administracion IN ('Ayuntamiento', 'Cabildo insular', 'Comunidad autónoma', 'Entes dependientes y otros')
GROUP BY ALL
ORDER BY orden, tipo_administracion
```

```sql itc_aytos_serie
SELECT CAST(orden_periodo AS INTEGER) AS orden, etiqueta,
    avg(puntuacion) AS media,
    median(puntuacion) AS mediana,
    quantile_cont(puntuacion, 0.25) AS p25,
    quantile_cont(puntuacion, 0.75) AS p75,
    count(*) FILTER (WHERE puntuacion >= 90) AS notable_alto,
    count(*) FILTER (WHERE puntuacion < 50 OR estado = 'incumplidora') AS suspenso,
    count(*) AS total
FROM ${itc}
WHERE tipo_administracion = 'Ayuntamiento'
GROUP BY ALL
ORDER BY orden
```

```sql itc_aytos_ultimo
SELECT
    cod_mun, entidad, regexp_replace(entidad, '^Ayuntamiento de ', '') AS municipio,
    provincia,
    poblacion, estado, puntuacion, puntuacion_original, familia, gobernante,
    CASE WHEN estado = 'incumplidora' THEN 'No rindió la evaluación' ELSE 'Evaluado' END AS situacion
FROM ${itc}
WHERE tipo_administracion = 'Ayuntamiento' AND orden_periodo = (SELECT orden FROM ${itc_ultimo})
ORDER BY puntuacion DESC NULLS LAST
```

```sql itc_resumen
SELECT
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE puntuacion >= 90) AS altos,
    count(*) FILTER (WHERE puntuacion < 50 OR estado = 'incumplidora') AS bajos,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras,
    count(*) AS total
FROM ${itc_aytos_ultimo}
```

```sql itc_institucionales
SELECT entidad, tipo_administracion,
    max(puntuacion) FILTER (WHERE orden_periodo = (SELECT orden FROM ${itc_ultimo})) AS ultima,
    max(puntuacion) FILTER (WHERE orden_periodo = 2) AS en_2017,
    max(familia) FILTER (WHERE orden_periodo = (SELECT orden FROM ${itc_ultimo})) AS familia
FROM ${itc}
WHERE tipo_administracion IN ('Cabildo insular', 'Comunidad autónoma')
GROUP BY ALL
ORDER BY ultima DESC
```

```sql itc_entes
SELECT tipo_entidad,
    count(*) AS entidades,
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras
FROM ${itc}
WHERE tipo_administracion = 'Entes dependientes y otros' AND orden_periodo = (SELECT orden FROM ${itc_ultimo})
GROUP BY tipo_entidad
HAVING count(*) >= 3
ORDER BY media
```

```sql itc_familia
-- Observado frente a esperado: el esperado de cada ayuntamiento y evaluación es la media
-- de los ayuntamientos canarios de su mismo tramo de población en esa misma evaluación.
-- El intervalo usa el número de municipios distintos (no de evaluaciones), porque el
-- mismo ayuntamiento aparece varios años y sus notas no son independientes.
WITH base AS (
    SELECT *,
        CASE WHEN poblacion < 5000 THEN 'a' WHEN poblacion < 20000 THEN 'b' ELSE 'c' END AS tramo
    FROM ${itc}
    WHERE tipo_administracion = 'Ayuntamiento' AND estado = 'evaluada'
),
esperado AS (
    SELECT *, avg(puntuacion) OVER (PARTITION BY orden_periodo, tramo) AS esperada
    FROM base
)
SELECT
    coalesce(familia, 'Sin atribuir') AS familia,
    count(*) AS evaluaciones,
    count(DISTINCT cod_mun) AS municipios,
    avg(puntuacion) AS observada,
    avg(esperada) AS esperada,
    avg(puntuacion - esperada) AS diferencia,
    avg(puntuacion - esperada) - 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) AS ic_bajo,
    avg(puntuacion - esperada) + 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) AS ic_alto,
    CASE
        WHEN count(DISTINCT cod_mun) < 10 THEN 'Muestra pequeña: no concluyente'
        WHEN avg(puntuacion - esperada) + 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) < 0 THEN 'Por debajo de lo esperable'
        WHEN avg(puntuacion - esperada) - 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) > 0 THEN 'Por encima de lo esperable'
        ELSE 'Dentro de lo esperable'
    END AS lectura
FROM esperado
GROUP BY ALL
HAVING count(*) >= 20
ORDER BY diferencia DESC
```

```sql itc_incumplidoras
SELECT etiqueta AS evaluacion, entidad, tipo_entidad, entidad_principal
FROM ${itc}
WHERE estado = 'incumplidora' AND orden_periodo >= (SELECT orden FROM ${itc_ultimo}) - 1
ORDER BY orden_periodo DESC, tipo_entidad, entidad
```

# 📋 Proactive disclosure: do public administrations publish what the law requires of them?

Since 2014, the [Transparency Law 19/2013](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) has required every public administration to **publish on its own initiative**, without anyone asking, a list of information on its transparency portal: who is in charge and how much they earn, what rules it is preparing, what contracts and grants it awards, its budgets and accounts, its assets. This is known as **proactive disclosure** (<i>publicidad activa</i>). This page brings together the **official assessments** that show, entity by entity, to what extent the law is complied with.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">The short answer</p>
<p class="mb-1">There is no <b>single, uniform</b> assessment covering every public administration in Spain. Each oversight body (the Council of Transparency and Good Governance and the regional councils or commissioners) assesses <b>its own remit</b>, with its own method and timetable, and almost all publish the results in PDF or Word reports, not as data.</p>
<p class="mb-0">With reusable official data it is currently possible to see: the <b>Transparency Portal of the General State Administration</b> (2021-2025), <b>eight autonomous communities and cities</b> and <b>eleven municipal councils</b> assessed by the Council of Transparency (2020-2021), and <b>the entire public sector of the Canary Islands</b>, including its 88 municipal councils, since 2016. Scores from different assessors <b>are not comparable with each other</b>.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="General State Administration portal"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="of mandatory information complied with in {age[age.length - 1]?.anio} (ICIO)"
        source="Council of Transparency and Good Governance"
        sparklineData={age.map(d => d.icio)}
    />
    <KpiCard
        title="Communities assessed by the CTBG"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="average ICIO of the 8 with an agreement, 2021 review"
        source="Council of Transparency and Good Governance"
    />
    <KpiCard
        title="Canary Islands municipal councils"
        value={itc_resumen[0]?.media}
        formattedValue="{formatNumber(itc_resumen[0]?.media / 10, 2)} out of 10"
        period="average score in the Canary Islands Transparency Index ({itc_ultimo[0]?.etiqueta})"
        source="Canary Islands Transparency Commissioner"
        sparklineData={itc_aytos_serie.map(d => d.media / 10)}
    />
    <KpiCard
        title="Canary Islands councils with a low score"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="out of {formatNumber(itc_resumen[0]?.total, 0)}: below 5 or did not submit to the assessment ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => d.suspenso)}
    />
</Grid>

## What the law requires

Law 19/2013 (arts. 5 to 8) groups the obligations into three blocks, and the regional transparency laws add others for their administrations and municipal councils:

- **Institutional, organisational and planning information**: functions, regulations, organisation chart, officials and their career history, plans and programmes with their degree of completion.
- **Information of legal relevance**: guidelines and instructions, preliminary draft bills and draft regulations, reports and memoranda from the rule-making files.
- **Economic, budgetary and statistical information**: contracts (including minor contracts), agreements, commissions to in-house entities, grants and aid, budgets and their execution, accounts and audit reports, pay of senior officials, compatibility of posts, property assets and statistics on the quality of services.

The information must be **clear, structured, up to date and reusable** (art. 5). Repeated failure to meet these obligations is a serious infringement under national law (art. 9.3), but in practice penalties are exceptional: the oversight bodies **recommend and assess**; they do not fine.

## Who assesses and what they publish

| Oversight body | Who it assesses | What it publishes per entity | Used here? |
|---|---|---|---|
| [Council of Transparency and Good Governance](https://consejodetransparencia.es/evaluacion) (CTBG) | General State Administration and national public sector, constitutional bodies, parties, trade unions, subsidised entities; and the autonomous communities and cities with an agreement (Asturias, Cantabria, Castilla-La Mancha, Extremadura, La Rioja, Ceuta and Melilla; Madrid in 2020-2021) and some of their municipal councils | Mandatory Information Compliance Index (ICIO, 0-100 %, MESTA methodology) in a Word report per entity; no data table | Yes: General State Administration portal, 8 communities and 11 municipal councils |
| [Canary Islands Transparency Commissioner](https://transparenciacanarias.org/evaluacion/puntuaciones/) | The entire Canary Islands public sector (Government, island councils, municipal councils, universities and their entities) and subsidised private entities | Canary Islands Transparency Index (ITCanarias, 0-10) in an Excel table with every entity since 2016 (CC BY 4.0) | Yes: public sector |
| [Transparency Council of the Region of Murcia](https://comisionadotransparencia.carm.es/) | Regional administration, municipal councils and their public sector (verified self-assessment, based on MESTA) | Executive report in PDF with results aggregated by type of entity; scores per municipal council only appear in charts | No: no reusable data per entity |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/) (Catalan Ombudsman) | Catalan administrations (Law 19/2014) | Annual report and individual reports in PDF; proactive disclosure development index (IDPAC) in a pilot phase since 2024 | No: PDF reports per entity, no table |
| Councils and commissioners of Andalusia, Aragon, Castile and León, the Valencian Community, Galicia, Navarre, the Basque Country and others | Their community and its local authorities | Annual reports, control and inspection plans and rulings, in PDF; we have not found a published compliance index per entity | No |

There are also civil society rankings (Dyntra, the Infoparticipa Map of the Autonomous University of Barcelona, the former indices of Transparency International Spain). **They are not used here**: they are not official sources and we have not verified that their licence allows the data to be reused.

## General State Administration

Every year the CTBG assesses the General State Administration's [Transparency Portal](https://transparencia.gob.es/). For each obligation, the ICIO measures whether the information is published and with what quality (form, update date, accessibility, reusability).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="General State Administration Transparency Portal: compliance index (%)"
    markers=true
    sort=false
/>

All five assessments relate to governments of Pedro Sánchez, so **they do not allow parties to be compared** in central government. The CTBG also separately assesses hundreds of bodies, companies and foundations of the national public sector every year; their scores are in individual reports and have not yet been incorporated.

## Autonomous communities and municipal councils assessed by the CTBG

The communities that did not create their own oversight body signed an agreement for the CTBG to monitor their transparency. In 2020 the CTBG assessed their portals and in 2021 it reviewed whether they had applied its recommendations.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Mandatory Information Compliance Index (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Autonomous community or city" />
    <Column id=familia title="President's party" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Improvement (points)" fmt=num1 contentType=delta />
</DataTable>

All of them improved after the recommendations. With only eight communities, governed by four different parties, **comparing parties makes no sense**: any difference could be down to a single community.

The municipal councils assessed by the CTBG are few and do not form a representative sample (the Council chose them). Even so, they show how far a large council can be from compliance: {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} of {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} were still below 50 % in the 2021 review.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Municipal council" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=familia title="Mayor's party (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Canary Islands: the entire public sector, entity by entity

The Canary Islands are the only community that publishes **every year and as open data** the score of all its administrations. The Transparency Commissioner sends a questionnaire on the obligations of the Canary Islands law (more demanding than the national one), checks the answers against the portals and calculates the Canary Islands Transparency Index (0 to 10). An entity that does not complete the assessment is listed as **non-compliant**.

<LineChart
    data={itc_evolucion}
    x=etiqueta
    y=media
    series=tipo_administracion
    yFmt=num1
    yMin=0
    yMax=100
    sort=false
    markers=true
    title="Canary Islands Transparency Index, average score (out of 100)"
/>

<p class="text-xs text-gray-500">The last two assessments are not calendar years: «2022/23» covers 2022 and the first half of 2023; «2023/24», the second half of 2023 and 2024. The score is shown out of 100 to compare it with the chart's scale (7.5 out of 10 = 75).</p>

The improvement is clear: the average score of municipal councils rose from {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} in the first assessment to {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)} in the latest. Part of the rise reflects entities learning how to answer the questionnaire, and many are already at the maximum, so high scores do little to distinguish between them.

### Municipal councils, {itc_ultimo[0]?.etiqueta}

<MapaEspana
    data={itc_aytos_ultimo}
    geoJsonUrl="/geo/municipios/05.geojson"
    geoId="cod_mun"
    areaCol="cod_mun"
    value="puntuacion"
    valueFmt="num1"
    min={50}
    max={100}
    colorPalette={['#b91c1c', '#fde68a', '#15803d']}
    height={420}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Boundaries © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Score (out of 100)', fmt: 'num1'},
        {id: 'familia', title: "Mayor's party"},
        {id: 'situacion', title: 'Status'}
    ]}
/>

<p class="text-xs text-gray-500">The colour scale starts at 50: anything below that appears in red. A municipality in grey did not submit to the assessment.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=puntuacion_original title="Score (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Status" />
    <Column id=familia title="Mayor's party" />
</DataTable>

### Government of the Canary Islands and island councils

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Entity" />
    <Column id=tipo_administracion title="Type" />
    <Column id=en_2017 title="2017 score (out of 100)" fmt=num1 />
    <Column id=ultima title="Latest score (out of 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="President's party" />
</DataTable>

<p class="text-xs text-gray-500">Island councils (cabildos) are not attributed to a party: SpainFacts does not yet have an official register of their presidents.</p>

### Public companies, bodies and foundations

Non-compliance is highest not in the administrations themselves but in their **dependent entities**: public companies, foundations, consortia and public-law corporations, which are also bound by the law.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Type of entity" />
    <Column id=entidades title="Entities" fmt=num0 />
    <Column id=media title="Average score (out of 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="Did not submit to the assessment" fmt=num0 />
</DataTable>

<details>
<summary>Entities that did not submit to the assessment in the last two editions</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Assessment" />
    <Column id=entidad title="Entity" />
    <Column id=tipo_entidad title="Type" />
    <Column id=entidad_principal title="Depends on" />
</DataTable>

</details>

## By party

The comparison is only possible with the **Canary Islands municipal councils**: there are 88 of them, all are assessed, with the same method, since 2016. For each council and assessment, the **expected** score is calculated: the average of Canary Islands councils of the same size (under 5,000, 5,000 to 20,000 and over 20,000 inhabitants) in that same assessment. The average score of the councils governed by each party is then compared with its expected score.

```sql itc_familia_grafico
SELECT familia, diferencia FROM ${itc_familia}
```

<BarChart
    data={itc_familia_grafico}
    x=familia
    y=diferencia
    swapXY=true
    yFmt=num1
    title="Observed minus expected score (points out of 100)"
    fillColor="#0f766e"
    sort=false
/>

<DataTable data={itc_familia} rows=all>
    <Column id=familia title="Mayor's party" />
    <Column id=evaluaciones title="Assessments" fmt=num0 />
    <Column id=municipios title="Distinct municipalities" fmt=num0 />
    <Column id=observada title="Average score" fmt=num1 />
    <Column id=esperada title="Expected" fmt=num1 />
    <Column id=diferencia title="Difference" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="95 % CI (min.)" fmt=num1 />
    <Column id=ic_alto title="95 % CI (max.)" fmt=num1 />
    <Column id=lectura title="Reading" />
</DataTable>

<p class="text-xs text-gray-500">Only parties with at least 20 assessments; councils that did not submit to the assessment have no score and are not included in the calculation. The confidence interval is calculated with the number of distinct municipalities, not assessments, because the scores of the same council in consecutive years are not independent. «Sin detalle en la fuente» (no detail in the source) groups mayoralties elected on lists that the official register labels generically; «Independientes y locales» (independents and local parties), voter associations. A difference between parties does not prove it is due to the party: staffing, technical resources, the island and the person in charge all play a part.</p>

For the autonomous communities and central government **there is not a large enough sample**: a single assessment per community and year, and in the case of the State a single government throughout the period assessed.

## What is missing

- **There is no uniform assessment for the whole of Spain.** Each oversight body assesses its own remit with its own method: the score of a Canary Islands council (ITCanarias) and that of a Cantabrian one (CTBG ICIO) cannot be compared.
- **Most regional bodies do not publish scores per entity as open data.** Murcia, Catalonia, Andalusia, Castile and León and others publish annual reports and documents in PDF, sometimes with the scores only in charts. If any of them publishes its results per entity in a reusable format, they will be added.
- **Spain's more than 8,100 municipal councils are not assessed systematically**, except in the Canary Islands. The CTBG assessed 11 in 2020-2021.
- **The national public sector** (bodies, companies and foundations) does have a score per entity in the CTBG reports, but in individual documents. In 2025 the CTBG assessed 225 of these entities, with an average ICIO of only 38.9 % ([CTBG press release](https://consejodetransparencia.es/comunicacion/noticias/hemeroteca/2025/20251114)). This is the next feasible extension.
- The assessments measure **whether the information is published and how**, not whether its content is accurate or complete.

---

## Methodology and sources

- **[Council of Transparency and Good Governance – Assessment](https://consejodetransparencia.es/evaluacion)**: Mandatory Information Compliance Index (ICIO) of the [MESTA methodology](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), read from the text of each **final report** (.docx): General State Administration Transparency Portal (2021-2025), autonomous communities and cities with an agreement (2020 assessment and 2021 review) and their assessed municipal councils. The CTBG reviews each portal directly and scores, for each obligation, whether the content is published and its quality attributes (form, updating, accessibility, reusability). Data source: Council of Transparency and Good Governance (reuse under Law 37/2007).
- **[Canary Islands Transparency Commissioner – Scores](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: master table of public sector scores of the Canary Islands Transparency Index (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), since the 2016 assessment. It combines compliance with mandatory information, the quality of the web platform and voluntary transparency ([methodology](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). The entity fills in a questionnaire and the Commissioner verifies it. It is shown out of 100 (score times 10) only to plot it alongside the ICIO; **the two scales are not equivalent**.
- **Municipalities**: the Commissioner's names are matched to the INE code by name (six with a different form, by hand). Population from the INE municipal register for the year assessed.
- **Attribution to parties**: for municipal councils, the mayor in office at the end of the period assessed according to the [register of mayors of the Ministry of Territorial Policy](https://concejales.redsara.es/consulta/) (for the «2022/23» assessment, 1 June 2023, before the councils formed after the May elections); for communities and the State, the president or prime minister in office on 31 December of the year assessed (ITCanarias) or on 30 June of the assessment year (CTBG). Parties are grouped into political families.
- **Legal obligations**: arts. 5 to 9 of [Law 19/2013 on transparency, access to public information and good governance](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); in the Canary Islands, [Law 12/2014 on transparency and access to public information](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Data updated" />
