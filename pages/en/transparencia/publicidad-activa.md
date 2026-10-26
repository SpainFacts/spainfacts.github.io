---
title: Proactive disclosure
description: "Do public administrations publish and submit on time what the law requires of them? Official assessments by entity (Council of Transparency, Canary Islands, Catalonia and Murcia) and SpainFacts' own measurement of the more than 8,100 municipal councils, the provincial councils and the autonomous communities, with non-compliance flagged and the comparison by party."
i18n_origen: e3ab0f3b8a10
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql age
SELECT CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio, puntuacion AS icio, gobernante, familia, url_fuente
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
SELECT entidad, CAST(CAST(anio AS INTEGER) AS VARCHAR) AS evaluacion, puntuacion AS icio
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

```sql mp_entidades
SELECT * FROM mother.transparencia_cumplimiento_entidad
```

```sql mp_resumen
SELECT
    count(*) FILTER (WHERE indice IS NOT NULL) AS entidades,
    count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND indice IS NOT NULL) AS ayuntamientos,
    count(*) FILTER (WHERE n_incumplimientos_destacados > 0) AS con_incumplimientos,
    count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND n_incumplimientos_destacados > 0) AS aytos_con_incumplimientos,
    100.0 * count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND n_incumplimientos_destacados > 0)
        / nullif(count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento'), 0) AS pct_aytos_incumplimientos,
    median(indice) FILTER (WHERE tipo_entidad = 'Ayuntamiento') AS mediana_aytos,
    count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND poblacion >= 20000 AND n_incumplimientos_destacados > 0) AS grandes_con_incumplimientos
FROM ${mp_entidades}
```

```sql mp_destacados
-- Lo que se señala arriba: comunidades, diputaciones y ayuntamientos de 20.000 habitantes o más
SELECT tipo_entidad, nombre_entidad, provincia, ccaa, poblacion, incumplimientos, n_incumplimientos_destacados,
    gobernante_actual, familia_actual, cod_mun
FROM ${mp_entidades}
WHERE n_incumplimientos_destacados > 0
  AND (tipo_entidad <> 'Ayuntamiento' OR poblacion >= 20000)
ORDER BY CASE tipo_entidad WHEN 'Comunidad autónoma' THEN 1 WHEN 'Diputación provincial' THEN 2 WHEN 'Cabildo o consell insular' THEN 3 ELSE 4 END,
    n_incumplimientos_destacados DESC, poblacion DESC
```

```sql mp_obligaciones
SELECT
    c.obligacion_nombre AS obligacion,
    c.tipo_entidad,
    max(c.periodo) AS ultimo_periodo,
    count(*) AS entidades,
    100.0 * avg(c.puntuacion) AS cumplimiento,
    count(*) FILTER (WHERE c.estado IN ('en_plazo', 'consta')) AS en_plazo,
    count(*) FILTER (WHERE c.estado = 'fuera_plazo' OR (c.estado = 'con_registros' AND c.n_fuera_plazo > 0)) AS con_retraso,
    count(*) FILTER (WHERE c.estado = 'no_consta') AS no_consta,
    coalesce(median(c.dias_retraso) FILTER (WHERE c.estado = 'fuera_plazo'), median(c.mediana_dias)) AS mediana_retraso,
    100.0 * count(*) / any_value(t.n) AS cobertura,
    CASE WHEN any_value(c.bloque) = 'pago' THEN 'No: mide si paga a tiempo, no si publica'
         WHEN count(*) >= 0.8 * any_value(t.n) THEN 'Sí'
         ELSE 'Todavía no (' || CAST(round(100.0 * count(*) / any_value(t.n)) AS INTEGER) || ' % medidas)' END AS en_indice
FROM mother.transparencia_cumplimiento c
JOIN (SELECT tipo_entidad, count(DISTINCT cod_entidad) AS n FROM mother.transparencia_cumplimiento GROUP BY 1) t USING (tipo_entidad)
WHERE c.es_ultimo
GROUP BY ALL
ORDER BY c.tipo_entidad, en_indice DESC, cumplimiento
```

```sql mp_tramos
SELECT tramo_poblacion, min(tramo_orden) AS orden,
    count(*) FILTER (WHERE indice IS NOT NULL) AS ayuntamientos,
    avg(indice) AS indice_medio,
    100.0 * count(*) FILTER (WHERE n_incumplimientos_destacados > 0) / count(*) AS pct_incumplimientos
FROM (
    SELECT *, CASE tramo_poblacion WHEN '<1.000' THEN 1 WHEN '1.000-5.000' THEN 2 WHEN '5.000-20.000' THEN 3
        WHEN '20.000-100.000' THEN 4 ELSE 5 END AS tramo_orden
    FROM ${mp_entidades} WHERE tipo_entidad = 'Ayuntamiento'
)
GROUP BY ALL
ORDER BY orden
```

```sql mp_provincias
SELECT cod_prov, any_value(provincia) AS provincia,
    count(*) AS ayuntamientos,
    100.0 * count(*) FILTER (WHERE n_incumplimientos_destacados > 0) / count(*) AS pct_incumplimientos,
    avg(indice) AS indice_medio
FROM ${mp_entidades}
WHERE tipo_entidad = 'Ayuntamiento' AND cod_prov IS NOT NULL
GROUP BY cod_prov
```

```sql mp_ranking
SELECT nombre_entidad AS municipio, provincia, poblacion, indice, obligaciones_medidas, n_incumplimientos_destacados,
    incumplimientos, familia_actual, media_tramo_espana,
    '/en/territorios/municipios?m=' || cod_mun AS enlace
FROM ${mp_entidades}
WHERE tipo_entidad = 'Ayuntamiento' AND indice IS NOT NULL
ORDER BY indice, poblacion DESC
```

```sql mp_familia
-- Observado frente a esperado: lo esperado de cada obligación es la media de los
-- ayuntamientos de su mismo tramo de población y comunidad en ese mismo periodo.
-- IC con el número de municipios distintos (un mismo ayuntamiento aporta varias obligaciones).
WITH base AS (
    SELECT *, avg(puntuacion) OVER (PARTITION BY obligacion, periodo, tramo_poblacion, cod_ccaa) AS esperada
    FROM mother.transparencia_cumplimiento
    WHERE tipo_entidad = 'Ayuntamiento' AND puntuacion IS NOT NULL AND anio >= year(current_date) - 4
),
por_mun AS (
    SELECT coalesce(familia_en_plazo, 'Sin atribuir') AS familia, cod_mun,
        avg(puntuacion - esperada) AS dif, avg(puntuacion) AS obs, avg(esperada) AS esp, count(*) AS n
    FROM base GROUP BY ALL
)
SELECT familia,
    count(*) AS municipios,
    sum(n) AS mediciones,
    100 * avg(obs) AS observada,
    100 * avg(esp) AS esperada,
    100 * avg(dif) AS diferencia,
    100 * (avg(dif) - 1.96 * stddev_samp(dif) / sqrt(count(*))) AS ic_bajo,
    100 * (avg(dif) + 1.96 * stddev_samp(dif) / sqrt(count(*))) AS ic_alto,
    CASE
        WHEN count(*) < 30 THEN 'Muestra pequeña: no concluyente'
        WHEN avg(dif) + 1.96 * stddev_samp(dif) / sqrt(count(*)) < 0 THEN 'Por debajo de lo esperable'
        WHEN avg(dif) - 1.96 * stddev_samp(dif) / sqrt(count(*)) > 0 THEN 'Por encima de lo esperable'
        ELSE 'Dentro de lo esperable'
    END AS lectura
FROM por_mun
GROUP BY familia
HAVING count(*) >= 30
ORDER BY diferencia DESC
```

# 📋 Proactive disclosure: do public administrations publish what the law requires of them?

{#if mp_destacados.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Administrations not on record as up to date with what they must submit</p>
    <p class="mt-2 text-red-900 dark:text-red-100">Autonomous communities, provincial councils and municipal councils with 20,000 inhabitants or more that have an obligation whose deadline passed more than three months ago and of which <b>nothing is on record</b> in the official register. In total, {formatNumber(mp_resumen[0]?.con_incumplimientos, 0)} administrations of all sizes are in that situation.</p>
    {#each mp_destacados.slice(0, 12) as d}
    <div class="mt-4">
        <p class="text-xl font-extrabold leading-tight text-red-700 dark:text-red-300">{#if d.cod_mun}<a class="underline" href="/en/territorios/municipios?m={d.cod_mun}">{d.nombre_entidad}</a>{:else}{d.nombre_entidad}{/if} <span class="whitespace-nowrap text-base font-semibold">({d.tipo_entidad}{d.provincia ? ', ' + d.provincia : ''}{d.poblacion ? ', ' + formatNumber(d.poblacion, 0) + ' inhab.' : ''})</span></p>
        <p class="mt-1 text-red-900 dark:text-red-100">Not on record: {d.incumplimientos}.</p>
    </div>
    {/each}
    {#if mp_destacados.length > 12}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">And {mp_destacados.length - 12} more of that size. They are all in the <a class="font-semibold underline" href="#own-measurement-all-administrations">table of SpainFacts' own measurement</a>.</p>
    {/if}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">«Not on record» means that it does not appear in the official source as of the date of the latest download, not that it has been proven that it was not done. Each case links to its profile with the source.</p>
</div>
{/if}

Since 2014, the [Transparency Law 19/2013](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) has required every public administration to **publish on its own initiative**, without anyone asking, a list of information on its transparency portal: who is in charge and how much they earn, what rules it is preparing, what contracts and grants it awards, its budgets and accounts, its assets. This is known as **proactive disclosure** (<i>publicidad activa</i>). In addition, they must **submit** their accounts, budgets, contracts and grants to official registers within deadlines set by law. This page brings together the **official assessments** that exist and **SpainFacts' own measurement** of every administration.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">The short answer</p>
<p class="mb-1">There is no <b>single, uniform</b> official assessment covering every public administration. Each oversight body assesses <b>its own remit</b>, with its own method. Only four publish scores per entity: the Council of Transparency and Good Governance (the State and its public sector), the Canary Islands Commissioner, the Síndic de Greuges de Catalunya (Catalan Ombudsman) and the Murcia Council. That covers the <b>municipal councils of the Canary Islands, Catalonia and Murcia</b> and hardly anyone else.</p>
<p class="mb-0">To reach the rest, SpainFacts <b>measures on its own</b> the more than 8,100 municipal councils, the provincial councils and the autonomous communities. It checks in the official registers whether each obligation is on record and whether it arrived on time. Today {formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} municipal councils ({formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %) have an obligation that fell due more than three months ago of which nothing is on record. Scores from different assessors <b>are not comparable with each other</b>, nor with SpainFacts' own measurement.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="General State Administration portal"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="of mandatory information complied with in {age[age.length - 1]?.anio} (ICIO)"
        source="Council of Transparency and Good Governance"
        sparklineData={age.map(d => ({...d, y: d.icio}))}
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
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.media / 10}))}
    />
    <KpiCard
        title="Canary Islands councils with a low score"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="out of {formatNumber(itc_resumen[0]?.total, 0)}: below 5 or did not submit to the assessment ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.suspenso}))}
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
| [Council of Transparency and Good Governance](https://consejodetransparencia.es/evaluacion) (CTBG) | General State Administration and national public sector, constitutional bodies, parties, trade unions, subsidised entities; and the autonomous communities and cities with an agreement (Asturias, Cantabria, Castilla-La Mancha, Extremadura, La Rioja, Ceuta and Melilla; Madrid in 2020-2021) and some of their municipal councils | Mandatory Information Compliance Index (ICIO, 0-100 %, MESTA methodology) in a Word report per entity; no data table | Yes: General State Administration portal, 8 communities, 11 municipal councils and, since 2022, the table in the aggregate reports (national public sector, private entities, corporations) |
| [Canary Islands Transparency Commissioner](https://transparenciacanarias.org/evaluacion/puntuaciones/) | The entire Canary Islands public sector (Government, island councils, municipal councils, universities and their entities) and subsidised private entities | Canary Islands Transparency Index (ITCanarias, 0-10) in an Excel table with every entity since 2016 (CC BY 4.0) | Yes: public sector |
| [Transparency Council of the Region of Murcia](https://comisionadotransparencia.carm.es/informes-de-evaluacion) | Regional administration, its 45 municipal councils and its public sector, parties, trade unions, federations… | Proactive disclosure compliance index (ICPA, 0-10) from 2020 to 2023, in a table in the annex to the 2023 report (PDF). It is a voluntary self-assessment verified by the Council | Yes: annex table |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/ca/page.asp?id=904) (Catalan Ombudsman) | The 947 Catalan municipal councils, provincial councils, county councils, departments of the Generalitat, universities and oversight bodies | Proactive disclosure development index (IDPAC, 0-100), reviewed by the Síndic itself, as open data (CSV, CC0) since the 2026 edition | Yes |
| Councils and commissioners of Andalusia, Aragon, Castile and León, the Valencian Community, Galicia, Madrid, Navarre, the Basque Country and others | Their community and its local authorities | Annual reports, control plans and rulings, in PDF. We have not found an index published per entity. Madrid has begun assessing all its municipal councils (results expected in its 2026 annual report) | No |

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

```sql sindic_aytos
SELECT cod_mun, municipio, provincia, poblacion, puntuacion, familia, gobernante,
    '/en/territorios/municipios?m=' || cod_mun AS enlace
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Síndic de Greuges de Catalunya' AND tipo_administracion = 'Ayuntamiento'
ORDER BY puntuacion DESC
```

```sql sindic_tramos
SELECT CASE WHEN poblacion < 1000 THEN '<1.000' WHEN poblacion < 5000 THEN '1.000-5.000'
            WHEN poblacion < 20000 THEN '5.000-20.000' WHEN poblacion < 100000 THEN '20.000-100.000' ELSE '>100.000' END AS tramo,
    min(poblacion) AS orden, count(*) AS ayuntamientos, avg(puntuacion) AS media,
    count(*) FILTER (WHERE puntuacion < 50) AS menos_50
FROM ${sindic_aytos}
GROUP BY 1 ORDER BY orden
```

```sql sindic_otros
SELECT entidad, tipo_administracion, tipo_entidad, puntuacion
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Síndic de Greuges de Catalunya' AND tipo_administracion <> 'Ayuntamiento'
ORDER BY tipo_administracion, puntuacion
```

```sql murcia_aytos
SELECT cod_mun, municipio, poblacion,
    max(puntuacion) FILTER (WHERE anio = 2020) AS n2020,
    max(puntuacion) FILTER (WHERE anio = 2021) AS n2021,
    max(puntuacion) FILTER (WHERE anio = 2022) AS n2022,
    max(puntuacion) FILTER (WHERE anio = 2023) AS n2023,
    count(*) FILTER (WHERE estado = 'no_participo') AS no_participo,
    max(familia) FILTER (WHERE anio = 2023) AS familia
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de la Transparencia de la Región de Murcia' AND tipo_administracion = 'Ayuntamiento'
GROUP BY ALL
ORDER BY n2023 DESC NULLS LAST
```

```sql murcia_serie
SELECT CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    count(*) FILTER (WHERE estado = 'evaluada') AS evaluados,
    count(*) FILTER (WHERE estado = 'no_participo') AS no_participaron,
    avg(puntuacion) AS media
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de la Transparencia de la Región de Murcia' AND tipo_administracion = 'Ayuntamiento'
GROUP BY ALL ORDER BY anio
```

```sql spe_serie
SELECT CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio, tipo_entidad AS grupo, avg(puntuacion) AS media, count(*) AS entidades
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
  AND tipo_administracion IN ('Sector público estatal', 'Entidades privadas')
  AND periodo NOT LIKE '%evaluación)'
GROUP BY ALL ORDER BY anio, grupo
```

```sql spe_ultimo
SELECT entidad, tipo_entidad AS grupo, CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio, puntuacion AS icio
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
  AND tipo_administracion IN ('Sector público estatal', 'Entidades privadas', 'Corporaciones de derecho público')
QUALIFY row_number() OVER (PARTITION BY entidad ORDER BY anio DESC, periodo DESC) = 1
ORDER BY icio
```

## Catalonia: all 947 municipal councils, reviewed by the Síndic

The Síndic de Greuges (Catalan Ombudsman) reviews **itself** the portal of every Catalan municipal council and publishes the result as open data: it is the only external assessment of all the municipal councils of a community. The proactive disclosure development index (IDPAC, 0-100) combines mandatory content (70 %) and the quality of the website (30 %). The 2026 edition was carried out between January and May.

<DataTable data={sindic_tramos} rows=all>
    <Column id=tramo title="Inhabitants" />
    <Column id=ayuntamientos title="Municipal councils" fmt=num0 />
    <Column id=media title="Average IDPAC" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=menos_50 title="Below 50" fmt=num0 />
</DataTable>

<DataTable data={sindic_aytos} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=familia title="Mayor's party" />
</DataTable>

<details>
<summary>Generalitat, provincial councils, county councils and others</summary>

<DataTable data={sindic_otros} search=true rows=15>
    <Column id=entidad title="Entity" />
    <Column id=tipo_entidad title="Type" />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
</DataTable>

</details>

## Region of Murcia

The Transparency Council of the Region of Murcia publishes the proactive disclosure compliance index (ICPA) of each entity that agrees to be assessed. The entity fills in the assessment on a platform and the Council verifies it. **It is voluntary**: a municipal council that did not take part is listed as «did not take part», never with a zero.

<BarChart
    data={murcia_serie}
    x=anio
    y={['evaluados', 'no_participaron']}
    type=stacked
    title="Murcia municipal councils assessed and that did not take part"
    sort=false
/>

<DataTable data={murcia_aytos} search=true rows=15>
    <Column id=municipio title="Municipality" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=n2020 title="2020" fmt=num1 />
    <Column id=n2021 title="2021" fmt=num1 />
    <Column id=n2022 title="2022" fmt=num1 />
    <Column id=n2023 title="2023 (out of 100)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
    <Column id=no_participo title="Years without taking part" fmt=num0 />
    <Column id=familia title="Mayor's party (2023)" />
</DataTable>

<p class="text-xs text-gray-500">Original score 0-10, shown out of 100. Empty cell: did not take part or had not been invited.</p>

## National public sector

Every year the Council of Transparency assesses national bodies, companies and foundations, private entities that receive grants and corporations such as professional associations. Its aggregate reports include a table with the compliance index (ICIO) of each one.

<LineChart
    data={spe_serie}
    x=anio
    y=media
    series=grupo
    yFmt=num1
    yMin=0
    yMax=100
    markers=true
    sort=false
    title="Average ICIO of the entities assessed (%)"
/>

<p class="text-xs text-gray-500">Different entities are assessed each year (225 from the public sector in 2025, compared with 74 in 2022), so the average does not always follow the same ones.</p>

<DataTable data={spe_ultimo} search=true rows=15>
    <Column id=entidad title="Entity" />
    <Column id=grupo title="Group" />
    <Column id=anio title="Latest assessment" />
    <Column id=icio title="ICIO (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## By party in the Canary Islands

With the official assessments, the comparison is only possible with the **Canary Islands municipal councils**: there are 88 of them, all are assessed, with the same method, since 2016. For each council and assessment, the **expected** score is calculated: the average of Canary Islands councils of the same size (under 5,000, 5,000 to 20,000 and over 20,000 inhabitants) in that same assessment. The average score of the councils governed by each party is then compared with its expected score.

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

## Own measurement: all administrations

As almost nobody assesses most administrations, **we measure it ourselves** with the same method for all of them. We do not score the website by eye. We check in the **official registers that carry a date** whether each legal obligation is on record and whether it arrived within its deadline. The registers are the National Grants Database (BDNS), the Public Sector Procurement Platform, the Court of Audit (Tribunal de Cuentas) and the Ministry of Finance. Each obligation scores 1 if it is on record on time, 0.5 if it is on record late and 0 if it is not on record once the deadline has passed. Each administration's index (0-100) is the average of its latest measured period. The criteria, legal basis and code of each indicator are in [Sources › Data from SpainFacts' own measurement](/en/fuentes#data-from-spainfacts-own-measurement).

<Grid cols=4>
    <KpiCard
        title="Administrations measured"
        value={mp_resumen[0]?.entidades}
        formattedValue={formatNumber(mp_resumen[0]?.entidades, 0)}
        period="{formatNumber(mp_resumen[0]?.ayuntamientos, 0)} municipal councils and {formatNumber(mp_resumen[0]?.entidades - mp_resumen[0]?.ayuntamientos, 0)} provincial councils, island councils and communities"
        source="SpainFacts (own measurement)"
    />
    <KpiCard
        title="Municipal councils with something overdue not on record"
        value={mp_resumen[0]?.pct_aytos_incumplimientos}
        formattedValue="{formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %"
        period="{formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} municipal councils, more than 3 months after the deadline"
        source="SpainFacts (own measurement)"
    />
    <KpiCard
        title="With 20,000 inhabitants or more"
        value={mp_resumen[0]?.grandes_con_incumplimientos}
        formattedValue={formatNumber(mp_resumen[0]?.grandes_con_incumplimientos, 0)}
        period="large municipal councils with an overdue obligation not on record"
        source="SpainFacts (own measurement)"
    />
    <KpiCard
        title="Median index of municipal councils"
        value={mp_resumen[0]?.mediana_aytos}
        formattedValue="{formatNumber(mp_resumen[0]?.mediana_aytos, 1)} out of 100"
        period="average of the latest period of each obligation"
        source="SpainFacts (own measurement)"
    />
</Grid>

### Obligation by obligation

<DataTable data={mp_obligaciones} rows=all groupBy=tipo_entidad>
    <Column id=tipo_entidad title="Administration" />
    <Column id=obligacion title="Obligation" />
    <Column id=ultimo_periodo title="Latest period" />
    <Column id=entidades title="Measured" fmt=num0 />
    <Column id=cumplimiento title="Compliance (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=con_retraso title="Late" fmt=num0 />
    <Column id=no_consta title="Not on record" fmt=num0 />
    <Column id=mediana_retraso title="Days (median)" fmt=num0 />
    <Column id=en_indice title="In the index" />
</DataTable>

<p class="text-xs text-gray-500">«Days (median)»: for one-off obligations, the delay of those that arrived late; for contracts and grants, how long the typical administration takes to publish or register them. The latest period of each administration with the deadline passed is counted. Administrations that the source does not measure (for example, those that submit through the foral channel) are not counted. An obligation enters the index and the list of non-compliance when it measures at least 80 % of the administrations of its type; until then, like the Court of Audit crawl that goes province by province, it is only shown here and in each profile.</p>

### By size and province

Small municipal councils are the ones that fall short most often: many do not even have a full-time secretary. That is why each council is always compared with those of its size.

<DataTable data={mp_tramos} rows=all>
    <Column id=tramo_poblacion title="Inhabitants" />
    <Column id=ayuntamientos title="Municipal councils" fmt=num0 />
    <Column id=indice_medio title="Average index" fmt=num1 contentType=colorscale colorMin=70 colorMax=100 />
    <Column id=pct_incumplimientos title="With something overdue not on record (%)" fmt=num1 />
</DataTable>

<MapaEspana
    data={mp_provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="pct_incumplimientos"
    valueFmt="num1"
    colorPalette={['#f0fdf4', '#fde68a', '#b91c1c']}
    height={420}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_incumplimientos', title: 'Municipal councils with something overdue not on record (%)', fmt: 'num1'},
        {id: 'indice_medio', title: 'Average index', fmt: 'num1'},
        {id: 'ayuntamientos', title: 'Municipal councils', fmt: 'num0'}
    ]}
/>

### All municipal councils

Sorted from lowest to highest index. Search for yours or open its profile to see each obligation, with its deadline, the date and who was governing at the time.

<DataTable data={mp_ranking} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=indice title="Index (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=media_tramo_espana title="Average for its size" fmt=num1 />
    <Column id=n_incumplimientos_destacados title="Overdue, not on record" fmt=num0 />
    <Column id=incumplimientos title="What is not on record" />
    <Column id=familia_actual title="Mayor's party today" />
</DataTable>

### By party

For each municipal council, obligation and period, the **expected** score is calculated: the average of councils of the same size and community in that period. The score of the councils governed by each party **on the day of the deadline** is then compared with the expected score. The last five years are used.

<DataTable data={mp_familia} rows=all>
    <Column id=familia title="Mayor's party on the day of the deadline" />
    <Column id=municipios title="Municipalities" fmt=num0 />
    <Column id=observada title="Average score" fmt=num1 />
    <Column id=esperada title="Expected" fmt=num1 />
    <Column id=diferencia title="Difference" fmt=num2 contentType=delta />
    <Column id=ic_bajo title="95 % CI (min.)" fmt=num2 />
    <Column id=ic_alto title="95 % CI (max.)" fmt=num2 />
    <Column id=lectura title="Reading" />
</DataTable>

<p class="text-xs text-gray-500">Only parties with at least 30 municipalities. A municipality counts once per party even if it contributes several obligations, and the interval is calculated with the number of municipalities. A difference between parties does not prove that the party causes it: staffing, the secretary-auditor, the resources of the provincial council and the person in charge all play a part.</p>

## What is missing

- **There is no uniform official assessment for the whole of Spain.** Each oversight body assesses its own remit with its own method: the score of a Canary Islands council (ITCanarias), that of a Catalan one (IDPAC) and that of a Murcian one (ICPA) cannot be compared with each other.
- **SpainFacts' own measurement measures what is submitted to official registers, not the transparency portal itself.** Having the general account or the contracts on record does not guarantee that the portal publishes the organisation chart or salaries. For that we are preparing a robot that reviews the portals, with a hand-checked sample to measure its error. Its results will be published once that error has been measured.
- **Procurement in Catalonia, the Basque Country and Navarre.** Their administrations publish on their own platform, not on the State's; where it is not covered, they are not counted in that indicator.
- **Andalusia, Castile and León, Aragon, the Valencian Community, Galicia, Navarre or the Basque Country** do not publish scores per entity. Madrid has begun assessing all its municipal councils. They will be added as soon as there are data.
- Neither the assessments nor SpainFacts' own measurement say **whether the information is accurate or complete**: only whether it is published or submitted, and when.

---

## Methodology and sources

- **[Council of Transparency and Good Governance – Assessment](https://consejodetransparencia.es/evaluacion)**: Mandatory Information Compliance Index (ICIO) of the [MESTA methodology](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), read from the text of each **final report** (.docx): General State Administration Transparency Portal (2021-2025), autonomous communities and cities with an agreement (2020 assessment and 2021 review) and their assessed municipal councils. The CTBG reviews each portal directly and scores, for each obligation, whether the content is published and its quality attributes (form, updating, accessibility, reusability). Data source: Council of Transparency and Good Governance (reuse under Law 37/2007).
- **[Canary Islands Transparency Commissioner – Scores](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: master table of public sector scores of the Canary Islands Transparency Index (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), since the 2016 assessment. It combines compliance with mandatory information, the quality of the web platform and voluntary transparency ([methodology](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). The entity fills in a questionnaire and the Commissioner verifies it. It is shown out of 100 (score times 10) only to plot it alongside the ICIO; **the two scales are not equivalent**.
- **[Síndic de Greuges de Catalunya – IDPAC](https://www.sindic.cat/ca/page.asp?id=904)**: [open data CSV](https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3) (CC0), 2026 edition. The Síndic reviews each portal; the IDPAC (0-100) weights mandatory content (70 %) and the website (30 %) ([methodological guide](https://www.sindic.cat/site/files/informe_transparencia/guia_metodologica_municipis_no_rurals_2026.pdf)). Municipalities are matched to the INE by name and province.
- **[Transparency Council of the Region of Murcia – Assessment reports](https://comisionadotransparencia.carm.es/informes-de-evaluacion)**: Annex I of the 2023 report (PDF), ICPA 0-10 from 2020 to 2023 = 70 % ICIO (MESTA) + 30 % web platform. Voluntary self-assessment verified by the Council; «did not take part» is not counted as zero. Shown out of 100.
- **[CTBG – Aggregate assessment reports](https://consejodetransparencia.es/evaluacion)** (2022-2026): annex table with the ICIO of each entity of the national institutional public sector, subsidised private entities, public-law corporations and constitutional bodies. The aggregate report rounds to one decimal place.
- **SpainFacts' own measurement**: submission obligations with a legal deadline checked in official registers; criteria, legal basis and code of each indicator in [Sources › Data from SpainFacts' own measurement](/en/fuentes#data-from-spainfacts-own-measurement). It is attributed to the government in office on the day of the deadline.
- **Municipalities**: the Commissioner's names are matched to the INE code by name (six with a different form, by hand). Population from the INE municipal register for the year assessed.
- **Attribution to parties**: for municipal councils, the mayor in office at the end of the period assessed according to the [register of mayors of the Ministry of Territorial Policy](https://concejales.redsara.es/consulta/) (for the «2022/23» assessment, 1 June 2023, before the councils formed after the May elections); for communities and the State, the president or prime minister in office on 31 December of the year assessed (ITCanarias) or on 30 June of the assessment year (CTBG). Parties are grouped into political families.
- **Legal obligations**: arts. 5 to 9 of [Law 19/2013 on transparency, access to public information and good governance](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); in the Canary Islands, [Law 12/2014 on transparency and access to public information](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Data updated" />
