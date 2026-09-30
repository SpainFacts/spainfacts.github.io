---
title: Council accounts reporting
description: "Public administrations that fail to meet their legal obligations to publish or submit information: who they are, where they are and who was in power when the deadline expired."
i18n_origen: 3425c0f0ac57
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // English date labels (the month labels built in the SQL queries are in Spanish)
    const mesEn = (d) => d ? new Date(d).toLocaleDateString('en-GB', {month: 'long', year: 'numeric', timeZone: 'UTC'}) : '';
    const trimEn = (d) => { if (!d) return ''; const x = new Date(d); return 'Q' + (Math.floor(x.getUTCMonth() / 3) + 1) + ' ' + x.getUTCFullYear(); };
</script>

```sql ultimo
SELECT max(anio) AS anio FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador)
```

```sql resumen
SELECT
    count(*) FILTER (WHERE incumple) AS incumplen,
    count(*) AS total,
    sum(poblacion) FILTER (WHERE incumple) AS poblacion_afectada,
    1000.0 * coalesce(sum(poblacion) FILTER (WHERE incumple), 0) / sum(poblacion) AS afectados_por_1000,
    count(*) FILTER (WHERE incumple AND poblacion >= 20000) AS grandes
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador)
WHERE anio = (SELECT anio FROM ${ultimo})
```

```sql rachas
-- Años consecutivos sin remitir hasta el último ejercicio (solo quien no remitió el último)
WITH marcado AS (
    SELECT cod_mun, anio, incumple,
        sum(CASE WHEN incumple THEN 0 ELSE 1 END) OVER (PARTITION BY cod_mun ORDER BY anio DESC) AS remisiones_posteriores
    FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador)
)
SELECT cod_mun, count(*) AS anios_seguidos
FROM marcado
WHERE incumple AND remisiones_posteriores = 0
GROUP BY cod_mun
```

```sql resumen_rachas
SELECT count(*) FILTER (WHERE anios_seguidos >= 3) AS tres_o_mas FROM ${rachas}
```

```sql liq_serie
SELECT
    anio,
    count(*) FILTER (WHERE incumple) AS incumplen,
    1000.0 * coalesce(sum(poblacion) FILTER (WHERE incumple), 0) / sum(poblacion) AS afectados_por_1000
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador)
GROUP BY anio
ORDER BY anio
```

# 🔍 Transparency: who fails to account for public money

Public administrations are **required by law** to submit certain financial information every year. Using official data, this page shows which administrations fail to do so, where they are and **who was in power when the deadline expired**.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">How to read this page</p>
<p class="mb-1">All data are official, verifiable records. An administration appearing here means that <b>the information is not recorded in the official source</b> on the publication date: it may have been submitted late or still be in process, so it is worth checking the source before drawing conclusions about a specific case.</p>
<p class="mb-0">Non-compliance is attributed to the government <b>in office on the day of the legal deadline</b>, not the current one. And because small municipalities, with fewer resources, fail to comply much more often, comparisons between parties are <b>adjusted for population size</b>.</p>
</div>

## Municipal budget outturn

Every town council must submit its budget outturn (what it actually collected and spent) to the Ministry of Finance **by 31 March of the following year** (art. 15.3 of Order HAP/2105/2012, implementing Organic Law 2/2012 on Budgetary Stability). Without that information there is no way of knowing what public money is spent on. (Álava and Navarre are excluded from this indicator because of their foral regime; see the methodology.)

<Grid cols=3>
    <KpiCard
        title="Town councils without a {ultimo[0]?.anio} outturn"
        value={resumen[0]?.incumplen}
        formattedValue={formatNumber(resumen[0]?.incumplen, 0)}
        period="{formatNumber(resumen[0]?.incumplen / resumen[0]?.total / 0.01, 1)}% of {formatNumber(resumen[0]?.total, 0)} town councils"
        source="Ministry of Finance (CONPREL)"
        sparklineData={liq_serie.map(d => d.incumplen)}
    />
    <KpiCard
        title="Residents affected"
        value={resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(resumen[0]?.afectados_por_1000, 1)}
        unit="per 1,000 inhabitants"
        period="{formatNumber(resumen[0]?.poblacion_afectada, 0)} residents in total; {formatNumber(resumen[0]?.grandes, 0)} of those town councils have more than 20,000 inhabitants"
        sparklineData={liq_serie.map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Three or more years in a row"
        value={resumen_rachas[0]?.tres_o_mas}
        formattedValue={formatNumber(resumen_rachas[0]?.tres_o_mas, 0)}
        period="town councils that have gone at least three financial years without submitting it"
    />
</Grid>

### Those that did not submit it for {ultimo[0]?.anio}

```sql lista
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    coalesce(r.anios_seguidos, 0) AS anios_seguidos,
    t.alcalde_en_plazo,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/en/territorios/municipios?m=' || t.cod_mun AS enlace
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
LEFT JOIN ${rachas} r USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.anio = (SELECT anio FROM ${ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=anios_seguidos title="Consecutive years without submitting" contentType=colorscale colorMax=10 />
    <Column id=lista_en_plazo title="Mayor's list at the deadline" />
    <Column id=familia_en_plazo title="Political family" />
</DataTable>

<p class="text-xs text-gray-500">Sorted from most to fewest inhabitants. «At the deadline» = 31 March {ultimo[0]?.anio + 1}, the deadline for submitting the {ultimo[0]?.anio} outturn.</p>

### By region

```sql por_ccaa
SELECT
    c.nombre AS comunidad,
    '/en' || c.ruta AS ruta,
    count(*) FILTER (WHERE t.incumple) AS incumplen,
    count(*) AS municipios,
    count(*) FILTER (WHERE t.incumple)::DOUBLE / count(*) AS pct
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod_ccaa
WHERE t.anio = (SELECT anio FROM ${ultimo})
GROUP BY ALL
ORDER BY pct DESC
```

```sql por_provincia
SELECT
    t.cod_prov,
    p.nombre AS provincia,
    count(*) FILTER (WHERE t.incumple) AS incumplen,
    count(*) AS municipios,
    count(*) FILTER (WHERE t.incumple)::DOUBLE / count(*) AS pct
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.anio = (SELECT anio FROM ${ultimo})
GROUP BY ALL
```

<AreaMap
    data={por_provincia}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="pct"
    valueFmt="pct0"
    colorPalette={['#fef3c7', '#f59e0b', '#9a3412']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Boundaries © Instituto Geográfico Nacional"
    title="Town councils that did not submit the {ultimo[0]?.anio} outturn, by province"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: 'Did not submit it', fmt: 'pct1'},
        {id: 'incumplen', title: 'Town councils', fmt: 'num0'},
        {id: 'municipios', title: 'Out of a total of', fmt: 'num0'}
    ]}
/>

<DataTable data={por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Community" />
    <Column id=incumplen title="Did not submit it" fmt=num0 />
    <Column id=municipios title="Town councils" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### By governing party

Outturns not submitted between {ultimo[0]?.anio - 11} and {ultimo[0]?.anio} by the political family of the mayor at the deadline. The **adjusted ratio** compares each party with what would be expected of municipalities **of the same size, in the same community and the same year**: 1 = as expected; 2 = twice as much; 0.5 = half. If the confidence interval includes 1, the difference may be due to chance.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>What the data show:</b> once municipality size and autonomous community are taken into account, most parties come out very close to 1. What best explains a town council failing to submit its accounts is that it is small and where it is, rather than who governs it.
</div>

```sql por_familia
-- Tasa esperada (estandarización indirecta): para cada ayuntamiento-año, la tasa
-- de su mismo tramo de población, comunidad autónoma y año. Ratio = observados /
-- esperados; intervalo de confianza al 95 % aproximado (Poisson) sobre observados.
WITH base AS (
    SELECT t.*,
        avg(t.incumple::INT) OVER (PARTITION BY t.anio, t.tramo_orden) AS tasa_tramo,
        avg(t.incumple::INT) OVER (PARTITION BY t.anio, t.tramo_orden, t.cod_ccaa) AS tasa_tramo_ccaa
    FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
),
agg AS (
    SELECT
        familia_en_plazo AS familia,
        count(*) AS ayuntamientos_anio,
        sum(incumple::INT) AS incumplimientos,
        avg(incumple::INT) AS tasa,
        sum(tasa_tramo) AS esperados_tamano,
        sum(tasa_tramo_ccaa) AS esperados
    FROM base
    GROUP BY familia_en_plazo
    HAVING count(*) >= 300
)
SELECT
    familia,
    ayuntamientos_anio,
    incumplimientos,
    tasa,
    incumplimientos / nullif(esperados_tamano, 0) AS ratio_tamano,
    incumplimientos / nullif(esperados, 0) AS ratio_ajustado,
    greatest(incumplimientos - 1.96 * sqrt(incumplimientos), 0) / nullif(esperados, 0) AS ic_bajo,
    (incumplimientos + 1.96 * sqrt(incumplimientos)) / nullif(esperados, 0) AS ic_alto,
    CASE
        WHEN (incumplimientos + 1.96 * sqrt(incumplimientos)) / nullif(esperados, 0) < 1 THEN 'Menos de lo esperable'
        WHEN greatest(incumplimientos - 1.96 * sqrt(incumplimientos), 0) / nullif(esperados, 0) > 1 THEN 'Más de lo esperable'
        ELSE 'Sin diferencia clara'
    END AS lectura
FROM agg
ORDER BY ratio_ajustado DESC
```

<BarChart
    data={por_familia}
    x=familia
    y=ratio_ajustado
    swapXY=true
    yFmt=num2
    title="Non-compliance adjusted for size and community (1 = as expected)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={por_familia} rows=all>
    <Column id=familia title="Political family of the mayor at the deadline" />
    <Column id=ayuntamientos_anio title="Town councils × year" fmt=num0 />
    <Column id=incumplimientos title="Outturns not submitted" fmt=num0 />
    <Column id=tasa title="Raw rate" fmt=pct1 />
    <Column id=ratio_tamano title="Adjusted for size only" fmt=num2 />
    <Column id=ratio_ajustado title="Adjusted for size and community" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="95% CI (min.)" fmt=num2 />
    <Column id=ic_alto title="95% CI (max.)" fmt=num2 />
    <Column id=lectura title="Reading" />
</DataTable>

<p class="text-xs text-gray-500">Only families with at least 300 town council-years. «Sin detalle en la fuente» (no detail in the source) groups mayoralties whose list appears in the official register under a generic coalition label; «Independientes y locales» (independents and local parties) groups voter associations. The families govern very different municipalities (size, community, resources): the ratio adjusts for size, but not for other differences.</p>

### Trend

```sql evolucion
SELECT
    make_date(CAST(anio AS INTEGER), 1, 1) AS fecha,
    tramo_poblacion,
    avg(incumple::INT) AS tasa
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador)
GROUP BY ALL
ORDER BY fecha, min(tramo_orden)
```

<LineChart
    data={evolucion}
    x=fecha
    y=tasa
    series=tramo_poblacion
    yFmt=pct0
    title="Town councils that did not submit the outturn, by size"
/>

## General Account and internal control (Court of Audit)

```sql tcu
SELECT * FROM mother.transparencia_tcu
```

```sql tcu_ultimo
SELECT
    CAST(max(ejercicio) FILTER (WHERE obligacion = 'cuenta_general') AS INTEGER) AS cg,
    CAST(max(ejercicio) FILTER (WHERE obligacion = 'control_interno') AS INTEGER) AS ci,
    CAST(max(ejercicio) FILTER (WHERE obligacion = 'contratos') AS INTEGER) AS ct
FROM ${tcu}
WHERE aplica_indicador
```

```sql tcu_cobertura
SELECT
    count(DISTINCT cod_prov) AS provincias,
    count(DISTINCT cod_mun) AS ayuntamientos,
    strftime(max(fecha_extraccion), '%d/%m/%Y') AS extraccion,
    count(DISTINCT cod_prov) < 46 AS parcial
FROM ${tcu}
```

```sql tcu_resumen
SELECT
    count(*) FILTER (WHERE incumple) AS no_rendida,
    count(*) AS total,
    count(*) FILTER (WHERE estado = 'en_plazo') AS en_plazo,
    count(*) FILTER (WHERE estado = 'fuera_plazo') AS fuera_plazo,
    count(*) FILTER (WHERE estado IN ('en_plazo', 'fuera_plazo')) AS con_fecha,
    sum(poblacion) FILTER (WHERE incumple) AS poblacion_afectada,
    count(*) FILTER (WHERE incumple AND poblacion >= 20000) AS grandes
FROM ${tcu}
WHERE aplica_indicador AND obligacion = 'cuenta_general'
  AND ejercicio = (SELECT cg FROM ${tcu_ultimo})
```

```sql tcu_serie
-- Solo ejercicios con cobertura comparable (al menos la mitad de ayuntamientos del ejercicio mejor cubierto)
WITH por_ejercicio AS (
    SELECT
        CAST(ejercicio AS INTEGER) AS ejercicio,
        obligacion,
        count(*) FILTER (WHERE incumple) AS no_rendida,
        count(*) AS total
    FROM ${tcu}
    WHERE aplica_indicador AND obligacion IN ('cuenta_general', 'control_interno')
    GROUP BY CAST(ejercicio AS INTEGER), obligacion
)
SELECT ejercicio, obligacion, no_rendida
FROM por_ejercicio
WHERE total >= 0.5 * (SELECT max(p2.total) FROM por_ejercicio p2 WHERE p2.obligacion = por_ejercicio.obligacion)
ORDER BY obligacion, ejercicio
```

```sql tcu_resumen_ci
SELECT
    count(*) FILTER (WHERE incumple) AS no_rendida,
    count(*) AS total
FROM ${tcu}
WHERE aplica_indicador AND obligacion = 'control_interno'
  AND ejercicio = (SELECT ci FROM ${tcu_ultimo})
```

The **General Account** brings together all of a town council's accounts (budget, balance sheet, results, treasury). Once approved by the full council, it must be sent to the **Court of Audit** (or to the community's external audit body) **by 15 October of the following year** (arts. 212.5 and 223.2 of the [consolidated text of the Local Finance Act](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)). In addition, every town council must submit **by 30 April** its **internal control** information (decisions adopted despite objections from the comptroller and the main revenue anomalies; art. 218.3 of the same law) and, **before the end of February**, the **annual list of contracts** or, if there were none, a nil return (art. 335 of the Public Sector Contracts Act). The platform does not cover the Basque Country or Navarre, which have their own external audit bodies.

{#if tcu_cobertura[0]?.provincias < 40}

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-3 text-sm text-gray-700 dark:text-gray-300">
<b>In preparation.</b> The data are being downloaded gradually from the Court of Audit platform so as not to overload it, and this section will be published once it covers all of Spain (excluding the Basque Country and Navarre). With only a few provinces the figures would not be representative.
</div>

{:else}

{#if tcu_cobertura[0]?.parcial}
<div class="not-prose rounded-lg border border-amber-200 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-800 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
<b>Partial data:</b> downloads from the Court of Audit platform are made gradually so as not to overload it. For now this section covers <b>data from {tcu_cobertura[0]?.provincias} provinces</b> ({formatNumber(tcu_cobertura[0]?.ayuntamientos, 0)} town councils); the figures are not yet representative of Spain.
</div>
{/if}

<Grid cols=3>
    <KpiCard
        title="No {tcu_ultimo[0]?.cg} General Account"
        value={tcu_resumen[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen[0]?.no_rendida / tcu_resumen[0]?.total / 0.01, 1)}% of {formatNumber(tcu_resumen[0]?.total, 0)} town councils; not recorded as submitted at {tcu_cobertura[0]?.extraccion}"
        source="Court of Audit (rendiciondecuentas.es)"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'cuenta_general').map(d => d.no_rendida)}
    />
    <KpiCard
        title="Submitted on time"
        value={tcu_resumen[0]?.en_plazo}
        formattedValue="{formatNumber(tcu_resumen[0]?.en_plazo / tcu_resumen[0]?.total / 0.01, 1)}%"
        period="{formatNumber(tcu_resumen[0]?.en_plazo, 0)} town councils before 15/10/{tcu_ultimo[0]?.cg + 1}; {formatNumber(tcu_resumen[0]?.fuera_plazo, 0)} submitted it later"
    />
    <KpiCard
        title="No {tcu_ultimo[0]?.ci} internal control report"
        value={tcu_resumen_ci[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen_ci[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen_ci[0]?.no_rendida / tcu_resumen_ci[0]?.total / 0.01, 1)}% of {formatNumber(tcu_resumen_ci[0]?.total, 0)} town councils (deadline: 30/04/{tcu_ultimo[0]?.ci + 1})"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'control_interno').map(d => d.no_rendida)}
    />
</Grid>

### Those that have not submitted the {tcu_ultimo[0]?.cg} General Account

```sql tcu_lista
WITH cg AS (
    SELECT * FROM ${tcu} WHERE aplica_indicador AND obligacion = 'cuenta_general'
),
historial AS (
    SELECT cod_mun,
        string_agg(CAST(CAST(ejercicio AS INTEGER) AS VARCHAR), ', ' ORDER BY ejercicio) FILTER (WHERE incumple) AS ejercicios_sin_rendir,
        count(*) FILTER (WHERE incumple) AS n_sin_rendir
    FROM cg
    GROUP BY cod_mun
),
ci AS (
    SELECT cod_mun, estado AS estado_ci
    FROM ${tcu}
    WHERE aplica_indicador AND obligacion = 'control_interno' AND ejercicio = (SELECT ci FROM ${tcu_ultimo})
)
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    h.ejercicios_sin_rendir,
    h.n_sin_rendir,
    CASE WHEN ci.estado_ci = 'no_rendida' THEN 'No consta' WHEN ci.estado_ci IS NULL THEN '-' ELSE 'Consta' END AS control_interno,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/en/territorios/municipios?m=' || t.cod_mun AS enlace
FROM cg t
JOIN historial h USING (cod_mun)
LEFT JOIN ci USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.ejercicio = (SELECT cg FROM ${tcu_ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={tcu_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=ejercicios_sin_rendir title="Financial years without a General Account" />
    <Column id=control_interno title="Internal control {tcu_ultimo[0]?.ci}" />
    <Column id=lista_en_plazo title="Mayor's list at the deadline" />
    <Column id=familia_en_plazo title="Political family" />
</DataTable>

<p class="text-xs text-gray-500">Sorted from most to fewest inhabitants. «No consta» (not recorded) = the platform does not show it as submitted on the extraction date ({tcu_cobertura[0]?.extraccion}); it may have been sent later or still be in process. «At the deadline» = 15 October {tcu_ultimo[0]?.cg + 1}. The financial years column includes all available years whose deadline has passed.</p>

### By autonomous community

```sql tcu_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/en' || c.ruta AS ruta,
    count(*) FILTER (WHERE t.obligacion = 'cuenta_general' AND t.ejercicio = u.cg) AS ayuntamientos,
    avg(t.incumple::INT) FILTER (WHERE t.obligacion = 'cuenta_general' AND t.ejercicio = u.cg) AS pct_cg,
    avg((t.estado = 'en_plazo')::INT) FILTER (WHERE t.obligacion = 'cuenta_general' AND t.ejercicio = u.cg) AS pct_cg_en_plazo,
    avg(t.incumple::INT) FILTER (WHERE t.obligacion = 'control_interno' AND t.ejercicio = u.ci) AS pct_ci,
    avg(t.incumple::INT) FILTER (WHERE t.obligacion = 'contratos' AND t.ejercicio = u.ct) AS pct_ct
FROM ${tcu} t
CROSS JOIN ${tcu_ultimo} u
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod_ccaa
WHERE t.aplica_indicador
GROUP BY ALL
ORDER BY pct_cg DESC
```

<DataTable data={tcu_por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Community" />
    <Column id=ayuntamientos title="Town councils" fmt=num0 />
    <Column id=pct_cg title="No {tcu_ultimo[0]?.cg} General Account" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_cg_en_plazo title="General Account on time" fmt=pct1 />
    <Column id=pct_ci title="No {tcu_ultimo[0]?.ci} internal control report" fmt=pct1 />
    <Column id=pct_ct title="No {tcu_ultimo[0]?.ct} list of contracts" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">List of contracts: «no» means that neither the list nor a nil return stating that no contracts were awarded is recorded.</p>

### By governing party

General Accounts not submitted across all available financial years, by the political family of the mayor on 15 October of the following year. The **adjusted ratio** compares each party with what would be expected in municipalities **of the same size, the same community and the same financial year** (1 = as expected). If the confidence interval includes 1, the difference may be due to chance.

```sql tcu_por_familia
WITH base AS (
    SELECT t.*,
        avg(t.incumple::INT) OVER (PARTITION BY t.ejercicio, t.tramo_orden) AS tasa_tramo,
        avg(t.incumple::INT) OVER (PARTITION BY t.ejercicio, t.tramo_orden, t.cod_ccaa) AS tasa_tramo_ccaa
    FROM ${tcu} t
    WHERE t.aplica_indicador AND t.obligacion = 'cuenta_general'
),
agg AS (
    SELECT
        familia_en_plazo AS familia,
        count(*) AS ayuntamientos_anio,
        sum(incumple::INT) AS incumplimientos,
        avg(incumple::INT) AS tasa,
        sum(tasa_tramo) AS esperados_tamano,
        sum(tasa_tramo_ccaa) AS esperados
    FROM base
    GROUP BY familia_en_plazo
    HAVING count(*) >= 300
)
SELECT
    familia,
    ayuntamientos_anio,
    incumplimientos,
    tasa,
    incumplimientos / nullif(esperados_tamano, 0) AS ratio_tamano,
    incumplimientos / nullif(esperados, 0) AS ratio_ajustado,
    greatest(incumplimientos - 1.96 * sqrt(incumplimientos), 0) / nullif(esperados, 0) AS ic_bajo,
    (incumplimientos + 1.96 * sqrt(incumplimientos)) / nullif(esperados, 0) AS ic_alto,
    CASE
        WHEN (incumplimientos + 1.96 * sqrt(incumplimientos)) / nullif(esperados, 0) < 1 THEN 'Menos de lo esperable'
        WHEN greatest(incumplimientos - 1.96 * sqrt(incumplimientos), 0) / nullif(esperados, 0) > 1 THEN 'Más de lo esperable'
        ELSE 'Sin diferencia clara'
    END AS lectura
FROM agg
ORDER BY ratio_ajustado DESC
```

{#if tcu_por_familia.length > 0}

<BarChart
    data={tcu_por_familia}
    x=familia
    y=ratio_ajustado
    swapXY=true
    yFmt=num2
    title="General Account not submitted, adjusted for size and community (1 = as expected)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={tcu_por_familia} rows=all>
    <Column id=familia title="Political family of the mayor at the deadline" />
    <Column id=ayuntamientos_anio title="Town councils × financial year" fmt=num0 />
    <Column id=incumplimientos title="Accounts not submitted" fmt=num0 />
    <Column id=tasa title="Raw rate" fmt=pct1 />
    <Column id=ratio_tamano title="Adjusted for size only" fmt=num2 />
    <Column id=ratio_ajustado title="Adjusted for size and community" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="95% CI (min.)" fmt=num2 />
    <Column id=ic_alto title="95% CI (max.)" fmt=num2 />
    <Column id=lectura title="Reading" />
</DataTable>

<p class="text-xs text-gray-500">Only families with at least 300 town council-financial years. The ratio adjusts for size and community, but not for other differences between the municipalities each family governs.</p>

{:else}

<p class="text-sm text-gray-500">There are not yet enough data (at least 300 town council-financial years per political family) to compare parties reliably.</p>

{/if}

{/if}

---

## Withholding of central government funds for failing to submit information

When a town council fails to send its **budget outturn** to the Ministry of Finance, the Ministry **withholds the monthly payments of its share of central government taxes** (the main transfer it receives from the State) until it does so (art. 36 of Law 2/2011 on the Sustainable Economy). Since 2022 the same happens if it fails to send **the year's budget** by 1 July or the **main budget guidelines for the following year** by 15 September (87th additional provision of Law 22/2021). The Ministry publishes the list of town councils affected every month; all of them since October 2016 are gathered here. (There are no Basque or Navarrese town councils: under their foral regime they do not receive this share through the common system.)

```sql pie_ultimo
SELECT
    max(periodo) AS periodo,
    ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][month(max(periodo))]
        || ' de ' || year(max(periodo)) AS mes
FROM mother.transparencia_pie_mensual
```

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql pie_resumen
-- Importes en euros corrientes (eur_12m) y a precios constantes (eur_12m_real = importe por el factor del deflactor de su año)
SELECT
    count(DISTINCT p.cod_mun) FILTER (WHERE p.periodo = (SELECT periodo FROM ${pie_ultimo})) AS retenidos_mes,
    count(DISTINCT p.cod_mun) FILTER (WHERE p.periodo = (SELECT periodo FROM ${pie_ultimo}) AND p.seccion = 'liquidacion') AS retenidos_liquidacion,
    sum(p.importe_eur) FILTER (WHERE p.periodo > (SELECT periodo FROM ${pie_ultimo}) - INTERVAL 12 MONTH) AS eur_12m,
    sum(p.importe_eur * coalesce(d.factor, 1)) FILTER (WHERE p.periodo > (SELECT periodo FROM ${pie_ultimo}) - INTERVAL 12 MONTH) AS eur_12m_real,
    count(DISTINCT p.cod_mun) FILTER (WHERE p.periodo > (SELECT periodo FROM ${pie_ultimo}) - INTERVAL 12 MONTH) AS retenidos_12m
FROM mother.transparencia_pie_mensual p
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(year(p.periodo) AS INTEGER)
```

```sql pie_serie_12m
-- Últimos 24 meses: retenidos en el mes y acumulado móvil de 12 meses (misma definición que pie_resumen); euros a precios constantes con mother.deflactor
WITH meses AS (
    SELECT DISTINCT periodo FROM mother.transparencia_pie_mensual
)
SELECT
    m.periodo,
    count(DISTINCT p.cod_mun) FILTER (WHERE p.periodo = m.periodo) AS retenidos_mes,
    sum(p.importe_eur * coalesce(d.factor, 1)) AS eur_12m_real,
    count(DISTINCT p.cod_mun) AS retenidos_12m
FROM meses m
JOIN mother.transparencia_pie_mensual p
  ON p.periodo > m.periodo - INTERVAL 12 MONTH AND p.periodo <= m.periodo
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(year(p.periodo) AS INTEGER)
WHERE m.periodo > (SELECT max(periodo) FROM meses) - INTERVAL 24 MONTH
GROUP BY m.periodo
ORDER BY m.periodo
```

<Grid cols=3>
    <KpiCard
        title="Town councils with funds withheld in {mesEn(pie_ultimo[0]?.periodo)}"
        value={pie_resumen[0]?.retenidos_mes}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_mes, 0)}
        period="{formatNumber(pie_resumen[0]?.retenidos_liquidacion, 0)} of them for failing to submit the outturn"
        source="Ministry of Finance (OVEELL)"
        sparklineData={pie_serie_12m.map(d => d.retenidos_mes)}
    />
    <KpiCard
        title="Withheld in the last 12 months"
        value={pie_resumen[0]?.eur_12m_real}
        formattedValue={formatNumber(pie_resumen[0]?.eur_12m_real / 1e6, 1)}
        unit="€m ({base_deflactor[0]?.anio_base} euros)"
        period="share of central government taxes not transferred while the non-compliance lasted (€{formatNumber(pie_resumen[0]?.eur_12m / 1e6, 1)}m in current euros)"
        source="Monthly payments on account"
        sparklineData={pie_serie_12m.filter(d => d.eur_12m_real != null).map(d => d.eur_12m_real)}
    />
    <KpiCard
        title="Town councils with funds withheld in the last year"
        value={pie_resumen[0]?.retenidos_12m}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_12m, 0)}
        period="for at least one month in the last 12"
        sparklineData={pie_serie_12m.map(d => d.retenidos_12m)}
    />
</Grid>

```sql pie_serie
SELECT
    p.periodo,
    CASE p.seccion
        WHEN 'liquidacion' THEN 'Liquidación'
        WHEN 'presupuesto' THEN 'Presupuesto del año'
        ELSE 'Líneas fundamentales'
    END AS motivo,
    count(DISTINCT p.cod_mun) AS ayuntamientos,
    sum(p.importe_eur) AS importe,
    sum(p.importe_eur * coalesce(d.factor, 1)) AS importe_real
FROM mother.transparencia_pie_mensual p
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(year(p.periodo) AS INTEGER)
GROUP BY 1, 2
ORDER BY periodo, motivo
```

<BarChart
    data={pie_serie}
    x=periodo
    y=ayuntamientos
    series=motivo
    type=stacked
    title="Town councils with their share withheld each month, by reason"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<BarChart
    data={pie_serie}
    x=periodo
    y=importe_real
    series=motivo
    type=stacked
    yFmt=eur1m
    title="Euros withheld each month ({base_deflactor[0]?.anio_base} euros, adjusted for inflation)"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<p class="text-xs text-gray-500">Each monthly list is a snapshot: who is still having funds withheld that month. The outturn list is renewed around June (with the outturn from two years earlier) and shrinks as town councils submit it; the budget list appears in November and December, and the budget guidelines list from December to August. There are no amounts for the months in which the Ministry of Finance did not publish the payments-on-account spreadsheet (March and October 2019, November 2020 to January 2021 and February 2022). As elsewhere on the site, amounts are adjusted for inflation, in {base_deflactor[0]?.anio_base} euros (INE annual average CPI; for the current year, the average of the months published).</p>

### Funds withheld in {mesEn(pie_ultimo[0]?.periodo)}

```sql pie_rachas
-- Meses seguidos retenido (por cualquier motivo) hasta el último mes publicado
WITH m AS (
    SELECT DISTINCT cod_mun, periodo FROM mother.transparencia_pie_mensual
),
g AS (
    SELECT cod_mun, periodo,
        date_diff('month', DATE '2000-01-01', periodo) - row_number() OVER (PARTITION BY cod_mun ORDER BY periodo) AS grupo
    FROM m
),
actual AS (
    SELECT cod_mun, grupo FROM g WHERE periodo = (SELECT periodo FROM ${pie_ultimo})
)
SELECT g.cod_mun, count(*) AS meses_seguidos, min(g.periodo) AS desde
FROM g JOIN actual a ON a.cod_mun = g.cod_mun AND a.grupo = g.grupo
GROUP BY g.cod_mun
```

```sql pie_importe_real
-- Importe retenido de cada campaña (ayuntamiento, información y ejercicio) en euros constantes, sumando mes a mes
SELECT
    p.cod_mun,
    p.seccion,
    CAST(p.ejercicio_referencia AS INTEGER) AS anio,
    sum(p.importe_eur * coalesce(d.factor, 1)) AS importe_real
FROM mother.transparencia_pie_mensual p
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(year(p.periodo) AS INTEGER)
GROUP BY 1, 2, 3
```

```sql pie_lista
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    string_agg(t.seccion_nombre || ' ' || CAST(t.anio AS INTEGER), ' · ' ORDER BY t.seccion) AS motivo,
    r.meses_seguidos,
    r.desde,
    sum(t.importe_retenido_eur) AS importe,
    sum(ir.importe_real) AS importe_real,
    bool_or(t.por_dependientes) AS por_dependientes,
    arg_min(t.lista, t.primer_mes) AS lista,
    arg_min(t.familia, t.primer_mes) AS familia,
    '/en/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pie t
LEFT JOIN ${pie_importe_real} ir ON ir.cod_mun = t.cod_mun AND ir.seccion = t.seccion AND ir.anio = CAST(t.anio AS INTEGER)
LEFT JOIN ${pie_rachas} r ON r.cod_mun = t.cod_mun
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.sigue_retenido
GROUP BY t.cod_mun, t.municipio, p.nombre, t.poblacion, r.meses_seguidos, r.desde
ORDER BY t.poblacion DESC
```

<DataTable data={pie_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=motivo title="Outstanding information (financial year)" />
    <Column id=meses_seguidos title="Consecutive months withheld" contentType=colorscale colorMax=24 />
    <Column id=importe_real title="Withheld in this round ({base_deflactor[0]?.anio_base} €)" fmt=eur0 />
    <Column id=lista title="Mayor's list when withholding began" />
    <Column id=familia title="Political family" />
</DataTable>

<p class="text-xs text-gray-500">Sorted from most to fewest inhabitants. «Withheld in this round»: euros not transferred since withholding began for that information (if it overlaps with another, the monthly amount is split between them), adjusted for inflation month by month. Some have funds withheld because the Ministry of Finance has not received information from a body or company that depends on the town council, rather than from the council itself.</p>

### By autonomous community

```sql pie_por_ccaa
WITH universo AS (
    SELECT cod_mun, cod_ccaa
    FROM mother.transparencia_pie
    WHERE aplica_indicador AND seccion = 'liquidacion'
      AND anio = (SELECT max(anio) FROM mother.transparencia_pie WHERE seccion = 'liquidacion')
),
retenidos AS (
    SELECT DISTINCT cod_mun FROM mother.transparencia_pie_mensual
    WHERE periodo = (SELECT periodo FROM ${pie_ultimo})
)
SELECT
    c.nombre AS comunidad,
    '/en' || c.ruta AS ruta,
    count(r.cod_mun) AS retenidos,
    count(*) AS municipios,
    count(r.cod_mun)::DOUBLE / count(*) AS pct
FROM universo u
LEFT JOIN retenidos r USING (cod_mun)
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = u.cod_ccaa
GROUP BY ALL
ORDER BY pct DESC
```

<DataTable data={pie_por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Community" />
    <Column id=retenidos title="Withheld in {mesEn(pie_ultimo[0]?.periodo)}" fmt=num0 />
    <Column id=municipios title="Town councils" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### By governing party

Each withholding round (one per type of information and financial year) counts as one observation per town council: withheld or not. The political family is that of the mayor **when withholding began** (or, if the council was not affected, at the start of that round). As with the outturn, the **adjusted ratio** compares each family with what would be expected in municipalities of the same size, the same community and the same round.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>What the data show:</b> once size and community are adjusted for, the two parties that govern most town councils come out at practically 1 and no family is clearly above what would be expected. Some are below, especially parties present in only one community; with few town councils, the intervals are wide. Size matters far more: in municipalities with fewer than 1,000 inhabitants withholding is about five times as frequent as in those with more than 100,000.
</div>

```sql pie_por_familia
WITH base AS (
    SELECT t.*,
        avg(t.retenido::INT) OVER (PARTITION BY t.seccion, t.anio, t.tramo_orden) AS tasa_tramo,
        avg(t.retenido::INT) OVER (PARTITION BY t.seccion, t.anio, t.tramo_orden, t.cod_ccaa) AS tasa_tramo_ccaa
    FROM (SELECT * FROM mother.transparencia_pie WHERE aplica_indicador AND campania_completa) t
),
agg AS (
    SELECT
        familia,
        count(*) AS observaciones,
        sum(retenido::INT) AS retenciones,
        avg(retenido::INT) AS tasa,
        sum(tasa_tramo) AS esperados_tamano,
        sum(tasa_tramo_ccaa) AS esperados
    FROM base
    GROUP BY familia
    HAVING count(*) >= 300
)
SELECT
    familia,
    observaciones,
    retenciones,
    tasa,
    retenciones / nullif(esperados_tamano, 0) AS ratio_tamano,
    retenciones / nullif(esperados, 0) AS ratio_ajustado,
    greatest(retenciones - 1.96 * sqrt(retenciones), 0) / nullif(esperados, 0) AS ic_bajo,
    (retenciones + 1.96 * sqrt(retenciones)) / nullif(esperados, 0) AS ic_alto,
    CASE
        WHEN (retenciones + 1.96 * sqrt(retenciones)) / nullif(esperados, 0) < 1 THEN 'Menos de lo esperable'
        WHEN greatest(retenciones - 1.96 * sqrt(retenciones), 0) / nullif(esperados, 0) > 1 THEN 'Más de lo esperable'
        ELSE 'Sin diferencia clara'
    END AS lectura
FROM agg
ORDER BY ratio_ajustado DESC
```

<BarChart
    data={pie_por_familia}
    x=familia
    y=ratio_ajustado
    swapXY=true
    yFmt=num2
    title="Withholdings adjusted for size and community (1 = as expected)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pie_por_familia} rows=all>
    <Column id=familia title="Political family of the mayor" />
    <Column id=observaciones title="Town councils × round" fmt=num0 />
    <Column id=retenciones title="Withholdings" fmt=num0 />
    <Column id=tasa title="Raw rate" fmt=pct1 />
    <Column id=ratio_tamano title="Adjusted for size only" fmt=num2 />
    <Column id=ratio_ajustado title="Adjusted for size and community" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="95% CI (min.)" fmt=num2 />
    <Column id=ic_alto title="95% CI (max.)" fmt=num2 />
    <Column id=lectura title="Reading" />
</DataTable>

<p class="text-xs text-gray-500">Complete rounds since 2017 (outturns from 2015 to 2024, budgets from 2022 to 2025 and budget guidelines from 2023 to 2026). Only families with at least 300 town councils × round. Withholding for the outturn begins about two years after the deadline for submitting it, so the mayor when withholding began may not be the one who should have sent it (especially after the municipal elections of May 2019 and 2023).</p>

---

## Average supplier payment period

Every town council must calculate and **report its average supplier payment period to the Ministry of Finance each quarter** (PMP: how many days, on average, it takes to pay its invoices), by the last day of the following month (Royal Decree 635/2014 and art. 16.8 of Order HAP/2105/2012). The Ministry publishes the figures of those who report; any council that does not appear has not reported. The legal maximum for payment is **30 days** (art. 13.6 of Organic Law 2/2012). Navarre and, depending on the year, the Basque foral territories are excluded from the reporting indicator: their financial oversight is foral and most of their town councils do not appear in the publication.

```sql pmp_ultimo
SELECT
    max(fecha_trimestre) AS fecha,
    arg_max(periodo, fecha_trimestre) AS periodo,
    CAST(arg_max(trimestre, fecha_trimestre) AS INTEGER) || 'º trimestre de ' || CAST(arg_max(anio, fecha_trimestre) AS INTEGER) AS etiqueta
FROM mother.transparencia_pmp
```

```sql pmp_resumen
SELECT
    count(*) FILTER (WHERE aplica_indicador AND NOT reporta) AS no_comunican,
    count(*) FILTER (WHERE aplica_indicador) AS total,
    sum(poblacion) FILTER (WHERE aplica_indicador AND NOT reporta) AS poblacion_afectada,
    1000.0 * coalesce(sum(poblacion) FILTER (WHERE aplica_indicador AND NOT reporta), 0) / sum(poblacion) FILTER (WHERE aplica_indicador) AS afectados_por_1000,
    count(*) FILTER (WHERE aplica_indicador AND NOT reporta AND poblacion >= 5000) AS mas_5000,
    count(*) FILTER (WHERE supera_30) AS supera_30,
    count(*) FILTER (WHERE reporta) AS comunican,
    sum(poblacion) FILTER (WHERE supera_30) AS poblacion_supera_30
FROM mother.transparencia_pmp
WHERE fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo})
```

```sql pmp_serie
SELECT
    fecha_trimestre AS fecha,
    count(*) FILTER (WHERE aplica_indicador AND NOT reporta) AS no_comunican,
    1000.0 * coalesce(sum(poblacion) FILTER (WHERE aplica_indicador AND NOT reporta), 0) / sum(poblacion) FILTER (WHERE aplica_indicador) AS afectados_por_1000,
    count(*) FILTER (WHERE supera_30) AS supera_30
FROM mother.transparencia_pmp
GROUP BY fecha_trimestre
ORDER BY fecha_trimestre
```

<Grid cols=3>
    <KpiCard
        title="PMP not reported ({trimEn(pmp_ultimo[0]?.fecha)})"
        value={pmp_resumen[0]?.no_comunican}
        formattedValue={formatNumber(pmp_resumen[0]?.no_comunican, 0)}
        period="{formatNumber(pmp_resumen[0]?.no_comunican / pmp_resumen[0]?.total / 0.01, 1)}% of {formatNumber(pmp_resumen[0]?.total, 0)} town councils"
        source="Ministry of Finance (PMP_NET)"
        sparklineData={pmp_serie.map(d => d.no_comunican)}
    />
    <KpiCard
        title="Residents affected"
        value={pmp_resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(pmp_resumen[0]?.afectados_por_1000, 1)}
        unit="per 1,000 inhabitants"
        period="{formatNumber(pmp_resumen[0]?.poblacion_afectada, 0)} residents in total; {formatNumber(pmp_resumen[0]?.mas_5000, 0)} of those town councils have more than 5,000 inhabitants"
        sparklineData={pmp_serie.filter(d => d.afectados_por_1000 != null).map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Pay in more than 30 days"
        value={pmp_resumen[0]?.supera_30}
        formattedValue={formatNumber(pmp_resumen[0]?.supera_30, 0)}
        period="{formatNumber(pmp_resumen[0]?.supera_30 / pmp_resumen[0]?.comunican / 0.01, 1)}% of those that report it ({formatNumber(pmp_resumen[0]?.poblacion_supera_30, 0)} inhabitants)"
        sparklineData={pmp_serie.map(d => d.supera_30)}
    />
</Grid>

### Those that did not report it in {trimEn(pmp_ultimo[0]?.fecha)}

```sql pmp_lista
WITH historial AS (
    SELECT cod_mun,
        count(*) FILTER (WHERE NOT reporta) AS trimestres_sin,
        count(*) AS trimestres
    FROM mother.transparencia_pmp
    GROUP BY cod_mun
)
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    h.trimestres_sin,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/en/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
JOIN historial h USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.aplica_indicador AND NOT t.reporta
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=trimestres_sin title="Quarters not reported (of the last 12)" contentType=colorscale colorMax=12 />
    <Column id=lista_en_plazo title="Mayor's list at the deadline" />
    <Column id=familia_en_plazo title="Political family" />
</DataTable>

<p class="text-xs text-gray-500">Sorted from most to fewest inhabitants. «At the deadline» = the last day of the month following the quarter. A town council that reported late may not appear in that quarter's publication.</p>

### By autonomous community

```sql pmp_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/en' || c.ruta AS ruta,
    count(*) FILTER (WHERE NOT t.reporta) AS no_comunican,
    count(*) AS municipios,
    count(*) FILTER (WHERE NOT t.reporta)::DOUBLE / count(*) AS pct,
    count(*) FILTER (WHERE t.supera_30)::DOUBLE / nullif(count(*) FILTER (WHERE t.reporta), 0) AS pct_supera_30
FROM mother.transparencia_pmp t
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod_ccaa
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.aplica_indicador
GROUP BY ALL
ORDER BY pct DESC
```

<DataTable data={pmp_por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Community" />
    <Column id=no_comunican title="Did not report it" fmt=num0 />
    <Column id=municipios title="Town councils" fmt=num0 />
    <Column id=pct title="% not reporting" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_supera_30 title="% of those reporting that pay in more than 30 days" fmt=pct1 />
</DataTable>

```sql pmp_evolucion
SELECT
    fecha_trimestre AS fecha,
    'Sin comunicar el PMP' AS indicador,
    avg((NOT reporta)::INT) AS tasa
FROM mother.transparencia_pmp
WHERE aplica_indicador
GROUP BY ALL
UNION ALL
SELECT
    fecha_trimestre,
    'Pagan en más de 30 días (de los que lo comunican)',
    avg(supera_30::INT)
FROM mother.transparencia_pmp
WHERE reporta
GROUP BY ALL
ORDER BY fecha
```

<LineChart
    data={pmp_evolucion}
    x=fecha
    y=tasa
    series=indicador
    yFmt=pct0
    title="Town councils not reporting the PMP and with a PMP above 30 days, by quarter"
/>

### By governing party

Quarters without reporting the PMP over the last three years by the political family of the mayor at the deadline, compared with what would be expected in municipalities **of the same size, the same community and the same quarter**. Many small town councils fail to report it quarter after quarter, so the observations are not independent and the true interval is somewhat wider than shown.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>What the data show:</b> the two parties with the most mayoralties come out at around 1 after adjustment. The largest deviations, above and below, are for parties present in only one community, where adjusting for community and size captures differences between municipalities less well. Size matters far more: almost three in ten town councils with fewer than 1,000 inhabitants do not report it, compared with practically none above 50,000.
</div>

```sql pmp_por_familia
WITH base AS (
    SELECT t.*,
        (NOT t.reporta)::INT AS no_comunica,
        avg((NOT t.reporta)::INT) OVER (PARTITION BY t.periodo, t.tramo_orden) AS tasa_tramo,
        avg((NOT t.reporta)::INT) OVER (PARTITION BY t.periodo, t.tramo_orden, t.cod_ccaa) AS tasa_tramo_ccaa
    FROM (SELECT * FROM mother.transparencia_pmp WHERE aplica_indicador) t
),
agg AS (
    SELECT
        familia_en_plazo AS familia,
        count(*) AS observaciones,
        sum(no_comunica) AS incumplimientos,
        avg(no_comunica) AS tasa,
        sum(tasa_tramo) AS esperados_tamano,
        sum(tasa_tramo_ccaa) AS esperados
    FROM base
    GROUP BY familia_en_plazo
    HAVING count(*) >= 300
)
SELECT
    familia,
    observaciones,
    incumplimientos,
    tasa,
    incumplimientos / nullif(esperados_tamano, 0) AS ratio_tamano,
    incumplimientos / nullif(esperados, 0) AS ratio_ajustado,
    greatest(incumplimientos - 1.96 * sqrt(incumplimientos), 0) / nullif(esperados, 0) AS ic_bajo,
    (incumplimientos + 1.96 * sqrt(incumplimientos)) / nullif(esperados, 0) AS ic_alto,
    CASE
        WHEN (incumplimientos + 1.96 * sqrt(incumplimientos)) / nullif(esperados, 0) < 1 THEN 'Menos de lo esperable'
        WHEN greatest(incumplimientos - 1.96 * sqrt(incumplimientos), 0) / nullif(esperados, 0) > 1 THEN 'Más de lo esperable'
        ELSE 'Sin diferencia clara'
    END AS lectura
FROM agg
ORDER BY ratio_ajustado DESC
```

<BarChart
    data={pmp_por_familia}
    x=familia
    y=ratio_ajustado
    swapXY=true
    yFmt=num2
    title="PMP not reported, adjusted for size and community (1 = as expected)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pmp_por_familia} rows=all>
    <Column id=familia title="Political family of the mayor at the deadline" />
    <Column id=observaciones title="Town councils × quarter" fmt=num0 />
    <Column id=incumplimientos title="Quarters not reported" fmt=num0 />
    <Column id=tasa title="Raw rate" fmt=pct1 />
    <Column id=ratio_tamano title="Adjusted for size only" fmt=num2 />
    <Column id=ratio_ajustado title="Adjusted for size and community" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="95% CI (min.)" fmt=num2 />
    <Column id=ic_alto title="95% CI (max.)" fmt=num2 />
    <Column id=lectura title="Reading" />
</DataTable>

### Paying in more than 30 days

Among the town councils that do report their PMP, these are the ones that in {trimEn(pmp_ultimo[0]?.fecha)} declared an average payment period **above the legal maximum of 30 days**. The figure is calculated and signed off by the town council itself.

```sql pmp_mayor30
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    t.pmp_dias,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/en/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.supera_30
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_mayor30} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=pmp_dias title="PMP (days)" fmt=num1 contentType=colorscale colorMin=30 colorMax=180 />
    <Column id=lista_en_plazo title="Mayor's list at the deadline" />
    <Column id=familia_en_plazo title="Political family" />
</DataTable>

```sql pmp_30_familia
WITH base AS (
    SELECT t.*,
        t.supera_30::INT AS supera,
        avg(t.supera_30::INT) OVER (PARTITION BY t.periodo, t.tramo_orden) AS tasa_tramo,
        avg(t.supera_30::INT) OVER (PARTITION BY t.periodo, t.tramo_orden, t.cod_ccaa) AS tasa_tramo_ccaa
    FROM (SELECT * FROM mother.transparencia_pmp WHERE reporta AND supera_30 IS NOT NULL) t
),
agg AS (
    SELECT
        familia_en_plazo AS familia,
        count(*) AS observaciones,
        sum(supera) AS por_encima,
        avg(supera) AS tasa,
        sum(tasa_tramo_ccaa) AS esperados
    FROM base
    GROUP BY familia_en_plazo
    HAVING count(*) >= 300
)
SELECT
    familia,
    observaciones,
    por_encima,
    tasa,
    por_encima / nullif(esperados, 0) AS ratio_ajustado,
    greatest(por_encima - 1.96 * sqrt(por_encima), 0) / nullif(esperados, 0) AS ic_bajo,
    (por_encima + 1.96 * sqrt(por_encima)) / nullif(esperados, 0) AS ic_alto,
    CASE
        WHEN (por_encima + 1.96 * sqrt(por_encima)) / nullif(esperados, 0) < 1 THEN 'Menos de lo esperable'
        WHEN greatest(por_encima - 1.96 * sqrt(por_encima), 0) / nullif(esperados, 0) > 1 THEN 'Más de lo esperable'
        ELSE 'Sin diferencia clara'
    END AS lectura
FROM agg
ORDER BY ratio_ajustado DESC
```

<DataTable data={pmp_30_familia} rows=all>
    <Column id=familia title="Political family of the mayor at the deadline" />
    <Column id=observaciones title="Reporting town councils × quarter" fmt=num0 />
    <Column id=por_encima title="Quarters with PMP > 30 days" fmt=num0 />
    <Column id=tasa title="Raw rate" fmt=pct1 />
    <Column id=ratio_ajustado title="Adjusted for size and community" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="95% CI (min.)" fmt=num2 />
    <Column id=ic_alto title="95% CI (max.)" fmt=num2 />
    <Column id=lectura title="Reading" />
</DataTable>

<p class="text-xs text-gray-500">Last 12 quarters published. Only families with at least 300 town councils × quarter. Councils that do not report their PMP are not included in this calculation, so it is not known whether they pay on time.</p>

---

## Methodology and sources

- **[Ministry of Finance – CONPREL](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: the «N» (no data) information status of each body in the final publication of outturns. From 2013; before then the Ministry imputed data for many small municipalities. Provisional releases are not used, because councils that submit late do not yet appear in them.
- **[Ministry of Territorial Policy – Mayors and councillors](https://concejales.redsara.es/consulta/)**: mayor in office on the deadline and the list on which he or she was elected, grouped into political families.
- **Legal obligation**: art. 15.3 of [Order HAP/2105/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-12147), implementing art. 6 of [Organic Law 2/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-5730).
- **Foral territories**: in Álava and Navarre the municipal outturn is not channelled to CONPREL through the common system (financial oversight lies with the Provincial Council and the Government of Navarre), nor was it in Bizkaia and Gipuzkoa in 2013-2014. Those cases **are not counted as non-compliance**: they would show up at almost 100% because of the foral regime, not because of each town council.
- **[Court of Audit – Local Authority Accounts Platform](https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/)** (Court of Audit and regional external audit bodies): the status of each town council in the General Account, internal control and contracts queries, and the submission date of each General Account submitted. The platform does not offer bulk downloads: its pages are queried with pauses and only the statuses and dates are stored, together with the extraction date. Each body is matched to its INE code using its Ministry of Finance (MEH) and Common Directory (DIR3) codes, and by name and province where these are missing.
- **Deadlines**: General Account, 15 October of the following year (arts. 212.5 and 223.2 of the [TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)); internal control, 30 April (art. 218.3 of the TRLRHL and [2019 Court of Audit Instruction](https://www.boe.es/buscar/doc.php?id=BOE-A-2020-680)); list of contracts, end of February (art. 335 of the [LCSP](https://www.boe.es/buscar/act.php?id=BOE-A-2017-12902) and [2018 Instruction](https://www.boe.es/buscar/doc.php?id=BOE-A-2018-9585)). Only financial years whose deadline has passed are counted.
- «On time» is measured using the submission date shown by the platform; if an account is recorded as submitted but its date is unknown, it is classified neither as on time nor as late.
- **[Ministry of Finance – Local Authorities Virtual Office](https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx)**: monthly list (in PDF) of town councils whose share of central government taxes is withheld, since October 2016, and the monthly payments-on-account spreadsheet with the amount withheld from each. Until October 2022 the lists only give the name: they are matched to the INE code by name and province (all match; three with a typo in the name, by approximation). In those older lists the outturn year is not stated and is inferred from the round (the June round of year A corresponds to the outturn for A-2, as in later lists). The amounts in the PDFs and the spreadsheets agree on town councils almost month by month.
- **Withholding of funds**: art. 36 of [Law 2/2011 on the Sustainable Economy](https://www.boe.es/buscar/act.php?id=BOE-A-2011-4117) (outturn, in conjunction with art. 193.5 of the [TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)) and the 87th additional provision of [Law 22/2021 on the 2022 Budget](https://www.boe.es/buscar/act.php?id=BOE-A-2021-21653) (budget and budget guidelines). Each monthly list is a snapshot of who is still having funds withheld, not of who failed to comply that month. The foral territories do not appear because they do not receive the share through the common system.
- **[Ministry of Finance – PMP_NET](https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/)**: average payment period of each local authority by quarter, since the third quarter of 2014. «Not reporting» = the town council exists that year (INE Municipal Register) but does not appear in that quarter's publication. Obligation: [Royal Decree 635/2014](https://www.boe.es/buscar/act.php?id=BOE-A-2014-8121) (amended by [RD 1040/2017](https://www.boe.es/buscar/doc.php?id=BOE-A-2017-15492)) and art. 16.8 of Order HAP/2105/2012; maximum of 30 days, art. 13.6 of Organic Law 2/2012. The 30-day threshold only applies from the second quarter of 2018, when RD 1040/2017 changed the calculation (previously it deducted the 30-day approval period and could be negative). In Navarre (every year), Álava (until 2022) and Bizkaia and Gipuzkoa (until the second quarter of 2016) most town councils do not appear in the publication because of the foral channel: those cases are not counted as non-compliance.
- Only town councils are considered; provincial councils, associations of municipalities and minor local bodies have their own obligations and are not included here.

<LastRefreshed prefix="Data updated" />
