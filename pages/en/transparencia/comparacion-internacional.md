---
title: Spain compared with other countries
description: "International indices of corruption, integrity and open government: where Spain stands relative to the EU, the OECD and benchmark countries, and how it has changed under each government."
i18n_origen: 43c868242525
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql esp
-- Último dato de España en cada índice, con el anterior, el primero de la serie y la media UE
WITH e AS (
    SELECT *,
        lag(valor) OVER (PARTITION BY indicador_id ORDER BY anio) AS valor_anterior,
        lag(anio) OVER (PARTITION BY indicador_id ORDER BY anio) AS anio_anterior,
        row_number() OVER (PARTITION BY indicador_id ORDER BY anio DESC) AS rn
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ES'
)
SELECT e.indicador_id, e.nombre_corto, e.unidad, e.sentido, e.fuente, e.orden_indicador,
    CAST(e.anio AS INTEGER) AS anio, e.valor, e.valor_anterior, CAST(e.anio_anterior AS INTEGER) AS anio_anterior,
    e.valor - e.valor_anterior AS cambio,
    CAST(e.puesto_mundial AS INTEGER) AS puesto_mundial,
    CAST(e.puesto_ue AS INTEGER) AS puesto_ue, CAST(e.n_ue AS INTEGER) AS n_ue,
    CAST(e.puesto_ocde AS INTEGER) AS puesto_ocde, CAST(e.n_ocde AS INTEGER) AS n_ocde,
    ue.valor AS valor_ue
FROM e
LEFT JOIN mother.transparencia_internacional ue
    ON ue.indicador_id = e.indicador_id AND ue.anio = e.anio AND ue.cod_pais = 'EU27_2020'
WHERE e.rn = 1
ORDER BY e.orden_indicador
```

```sql esp_cpi
SELECT * FROM ${esp} WHERE indicador_id = 'cpi'
```

```sql esp_wgi
SELECT * FROM ${esp} WHERE indicador_id = 'wgi_control_corrupcion'
```

```sql esp_wjp
SELECT * FROM ${esp} WHERE indicador_id = 'wjp_gobierno_abierto'
```

```sql esp_vdem
SELECT * FROM ${esp} WHERE indicador_id = 'vdem_corrupcion_politica'
```

```sql rango
SELECT CAST(min(puesto_ue) AS INTEGER) AS mejor, CAST(max(puesto_ue) AS INTEGER) AS peor FROM ${esp}
```

```sql cpi_inicio
SELECT CAST(anio AS INTEGER) AS anio, valor, CAST(puesto_ue AS INTEGER) AS puesto_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id = 'cpi'
ORDER BY anio
LIMIT 1
```

```sql serie_esp
SELECT indicador_id, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES'
ORDER BY indicador_id, anio
```

```sql referencia
-- Países de referencia y medias UE/OCDE, todas las series
SELECT indicador_id, pais, cod_pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE es_referencia AND anio >= 1996
ORDER BY indicador_id, orden_pais, anio
```

```sql ranking_ue
-- Países de la UE en el último año con dato de España, España destacada
SELECT t.indicador_id, t.pais, t.valor, CAST(t.anio AS INTEGER) AS anio,
    CASE WHEN t.cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.transparencia_internacional t
JOIN (
    SELECT indicador_id, max(anio) AS anio
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ES'
    GROUP BY indicador_id
) u ON u.indicador_id = t.indicador_id AND u.anio = t.anio
WHERE t.es_ue
ORDER BY t.indicador_id, t.valor DESC
```

```sql puesto_ue_serie
SELECT indicador_id, nombre_corto, CAST(anio AS INTEGER) AS anio, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id IN ('cpi', 'wgi_control_corrupcion', 'wjp_estado_derecho') AND anio >= 1996
ORDER BY indicador_id, anio
```

```sql tabla_paises
-- Último dato de cada país de referencia en los índices principales
WITH u AS (
    SELECT t.* FROM mother.transparencia_internacional t
    JOIN (
        SELECT indicador_id, cod_pais, max(anio) AS anio
        FROM mother.transparencia_internacional
        GROUP BY indicador_id, cod_pais
    ) m ON m.indicador_id = t.indicador_id AND m.cod_pais = t.cod_pais AND m.anio = t.anio
    WHERE t.es_referencia
)
SELECT
    pais,
    min(orden_pais) AS orden,
    max(CASE WHEN indicador_id = 'cpi' THEN valor END) AS cpi,
    max(CASE WHEN indicador_id = 'wgi_control_corrupcion' THEN valor END) AS wgi_cc,
    max(CASE WHEN indicador_id = 'wgi_voz_rendicion_cuentas' THEN valor END) AS wgi_va,
    max(CASE WHEN indicador_id = 'wgi_eficacia_gobierno' THEN valor END) AS wgi_ge,
    max(CASE WHEN indicador_id = 'wjp_gobierno_abierto' THEN valor END) AS wjp_ga,
    max(CASE WHEN indicador_id = 'vdem_corrupcion_politica' THEN valor END) AS vdem_cp
FROM u
GROUP BY pais
ORDER BY orden, pais
```

```sql gobiernos
SELECT
    CAST(year(CAST(desde AS DATE)) AS INTEGER) AS anio_desde,
    CAST(coalesce(year(CAST(hasta AS DATE)), year(current_date)) AS INTEGER) AS anio_hasta,
    presidente, familia
FROM mother.gobiernos_presidentes
WHERE nivel = 'estatal'
ORDER BY anio_desde
```

```sql gob_psoe
SELECT * FROM ${gobiernos} WHERE familia = 'PSOE'
```

```sql gob_pp
SELECT * FROM ${gobiernos} WHERE familia = 'PP'
```

```sql gob_ucd
SELECT * FROM ${gobiernos} WHERE familia = 'UCD'
```

```sql larga_vdem
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'vdem_corrupcion_politica' AND cod_pais IN ('ES', 'EU27_2020', 'OECD') AND anio >= 1977
ORDER BY cod_pais, anio
```

```sql larga_wgi
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'wgi_control_corrupcion' AND cod_pais IN ('ES', 'EU27_2020', 'OECD')
ORDER BY cod_pais, anio
```

```sql mandatos
-- Cambio de la distancia de España a la media de la UE atribuido a cada Gobierno.
-- Media de la UE: media simple de los países de la UE con serie completa desde
-- 1976 (o desde el inicio del índice), para que la composición no cambie con los
-- años. Cada año se asigna a quien gobernaba el 1 de julio; el cambio de un año es
-- la variación de la brecha respecto al año anterior con dato. Signo positivo =
-- España mejora respecto a la UE (en V-Dem, donde más es peor, se invierte).
WITH g AS (
    SELECT presidente, familia, CAST(desde AS DATE) AS desde,
        coalesce(CAST(hasta AS DATE), current_date + INTERVAL 1 DAY) AS hasta
    FROM mother.gobiernos_presidentes
    WHERE nivel = 'estatal'
),
base AS (
    SELECT indicador_id, sentido, cod_pais, es_ue, CAST(anio AS INTEGER) AS anio, valor
    FROM mother.transparencia_internacional
    WHERE indicador_id IN ('vdem_corrupcion_politica', 'wgi_control_corrupcion')
      AND anio >= 1976 AND NOT es_agregado
),
anios_esp AS (
    SELECT indicador_id, count(*) AS n FROM base WHERE cod_pais = 'ES' GROUP BY indicador_id
),
panel AS (
    SELECT b.indicador_id, b.cod_pais
    FROM base b JOIN anios_esp a ON a.indicador_id = b.indicador_id
    WHERE b.es_ue AND b.cod_pais <> 'ES'
    GROUP BY b.indicador_id, b.cod_pais, a.n
    HAVING count(*) = a.n
),
n_panel AS (
    SELECT indicador_id, CAST(count(*) AS INTEGER) AS n_panel FROM panel GROUP BY indicador_id
),
media AS (
    SELECT b.indicador_id, b.anio, avg(b.valor) AS valor
    FROM base b JOIN panel p ON p.indicador_id = b.indicador_id AND p.cod_pais = b.cod_pais
    GROUP BY b.indicador_id, b.anio
),
brecha AS (
    SELECT e.indicador_id, e.sentido, e.anio, e.valor - m.valor AS brecha
    FROM base e JOIN media m ON m.indicador_id = e.indicador_id AND m.anio = e.anio
    WHERE e.cod_pais = 'ES'
),
cambios AS (
    SELECT *,
        (brecha - lag(brecha) OVER (PARTITION BY indicador_id ORDER BY anio))
            * CASE WHEN sentido = 'negativo' THEN -1 ELSE 1 END AS mejora
    FROM brecha
)
SELECT
    c.indicador_id,
    CASE WHEN c.indicador_id = 'vdem_corrupcion_politica' THEN 'Corrupción política (V-Dem, puntos)' ELSE 'Control de la corrupción (Banco Mundial, puntos)' END AS indice,
    CASE g.presidente
        WHEN 'Adolfo Suárez / Leopoldo Calvo-Sotelo' THEN 'Suárez y Calvo-Sotelo'
        WHEN 'Felipe González' THEN 'González'
        WHEN 'José María Aznar' THEN 'Aznar'
        WHEN 'José Luis Rodríguez Zapatero' THEN 'Zapatero'
        WHEN 'Mariano Rajoy' THEN 'Rajoy'
        WHEN 'Pedro Sánchez' THEN 'Sánchez'
        ELSE g.presidente END || ' (' || CAST(year(g.desde) AS VARCHAR) || '-' ||
        CASE WHEN g.hasta > current_date THEN 'hoy' ELSE CAST(year(g.hasta) AS VARCHAR) END || ')' AS mandato,
    g.familia,
    year(g.desde) AS orden,
    CAST(count(c.mejora) AS INTEGER) AS anios,
    CAST(min(c.anio) AS INTEGER) AS primer_anio,
    CAST(max(c.anio) AS INTEGER) AS ultimo_anio,
    sum(c.mejora) AS mejora,
    sum(c.mejora) / count(c.mejora) AS mejora_anual,
    min(n.n_panel) AS n_panel
FROM cambios c
JOIN n_panel n ON n.indicador_id = c.indicador_id
JOIN g ON make_date(c.anio, 7, 1) >= g.desde AND make_date(c.anio, 7, 1) < g.hasta
WHERE c.mejora IS NOT NULL
GROUP BY c.indicador_id, indice, g.presidente, g.familia, g.desde, g.hasta
ORDER BY c.indicador_id, orden
```

```sql mandatos_vdem
SELECT * FROM ${mandatos} WHERE indicador_id = 'vdem_corrupcion_politica' ORDER BY orden
```

```sql mandatos_wgi
SELECT * FROM ${mandatos} WHERE indicador_id = 'wgi_control_corrupcion' ORDER BY orden
```

```sql wjp_factores
SELECT nombre_corto AS factor, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id LIKE 'wjp_%'
ORDER BY orden_indicador, anio
```

```sql opciones
SELECT DISTINCT indicador_id, nombre, orden_indicador
FROM mother.transparencia_internacional
ORDER BY orden_indicador
```

```sql exp_info
SELECT DISTINCT nombre, unidad, sentido, fuente, url_fuente
FROM mother.transparencia_internacional
WHERE indicador_id = '${inputs.ind.value}'
```

```sql exp_serie
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = '${inputs.ind.value}' AND es_referencia AND anio >= 1996
ORDER BY orden_pais, anio
```

```sql exp_ranking
SELECT t.pais, t.valor,
    CASE WHEN t.cod_pais = 'ES' THEN 'España' WHEN t.es_ue THEN 'Resto de la UE' ELSE 'Resto de la OCDE' END AS grupo
FROM mother.transparencia_internacional t
WHERE t.indicador_id = '${inputs.ind.value}' AND (t.es_ue OR t.es_ocde)
  AND t.anio = (
    SELECT max(anio) FROM mother.transparencia_internacional
    WHERE indicador_id = '${inputs.ind.value}' AND cod_pais = 'ES'
  )
ORDER BY t.valor DESC
```

# 🌍 Transparency: Spain compared with other countries

How does the integrity of Spain's institutions look from the outside? Several international organisations publish **cross-country comparable indices** every year on corruption, the rule of law and open government. This page brings together the main ones, places Spain among the **27 EU countries** and the **38 OECD countries**, and compares it with its neighbours and with the countries that usually top these rankings (Denmark, Finland, New Zealand and Estonia).

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">How to read this page</p>
<p class="mb-1">None of these indices counts cases of corruption: <b>they measure perceptions and assessments</b> by experts, businesses and surveyed citizens. They are useful for comparing countries and seeing long-term trends, but they react with a delay, have margins of error of several points and can move because of media scandals as much as because of real changes.</p>
<p class="mb-0">Differences of one or two points between years or between neighbouring countries in the ranking <b>are not usually significant</b>. What matters is the trend over several years and the distance from the average.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Corruption Perceptions (CPI)"
        value={esp_cpi[0]?.valor}
        formattedValue="{formatNumber(esp_cpi[0]?.valor, 0)} / 100"
        period="{esp_cpi[0]?.anio} · ranked {esp_cpi[0]?.puesto_ue} of {esp_cpi[0]?.n_ue} in the EU, {esp_cpi[0]?.puesto_mundial} in the world"
        change={esp_cpi[0]?.cambio}
        changeUnit=" pts"
        changePeriod="vs {esp_cpi[0]?.anio_anterior}"
        direction="positive-up"
        source="Transparency International"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'cpi').map(d => d.valor)}
    />
    <KpiCard
        title="Control of corruption (World Bank)"
        value={esp_wgi[0]?.valor}
        formattedValue="{formatNumber(esp_wgi[0]?.valor, 1)} / 100"
        period="{esp_wgi[0]?.anio} · ranked {esp_wgi[0]?.puesto_ue} of {esp_wgi[0]?.n_ue} in the EU (EU average {formatNumber(esp_wgi[0]?.valor_ue, 1)})"
        change={esp_wgi[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wgi[0]?.anio_anterior}"
        direction="positive-up"
        source="World Bank (WGI)"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wgi_control_corrupcion').map(d => d.valor)}
    />
    <KpiCard
        title="Open government (WJP)"
        value={esp_wjp[0]?.valor}
        formattedValue="{formatNumber(esp_wjp[0]?.valor, 0)} / 100"
        period="{esp_wjp[0]?.anio} · ranked {esp_wjp[0]?.puesto_ue} of {esp_wjp[0]?.n_ue} in the EU"
        change={esp_wjp[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wjp[0]?.anio_anterior}"
        direction="positive-up"
        source="World Justice Project"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wjp_gobierno_abierto').map(d => d.valor)}
    />
    <KpiCard
        title="Political corruption (V-Dem)"
        value={esp_vdem[0]?.valor}
        formattedValue="{formatNumber(esp_vdem[0]?.valor, 1)} / 100"
        period="{esp_vdem[0]?.anio} · lower is better · ranked {esp_vdem[0]?.puesto_ue} of {esp_vdem[0]?.n_ue} in the EU"
        change={esp_vdem[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_vdem[0]?.anio_anterior}"
        direction="positive-down"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'vdem_corrupcion_politica' && d.anio >= 1977).map(d => d.valor)}
    />
</Grid>

In the latest year with data, Spain ranks **between {rango[0]?.mejor} and {rango[0]?.peor} of the 27 EU countries** depending on the index, far behind the Nordic countries, which top almost all these rankings. In the Corruption Perceptions Index it has gone from {formatNumber(cpi_inicio[0]?.valor, 0)} points in {cpi_inicio[0]?.anio} (ranked {cpi_inicio[0]?.puesto_ue} in the EU) to {formatNumber(esp_cpi[0]?.valor, 0)} in {esp_cpi[0]?.anio} (ranked {esp_cpi[0]?.puesto_ue}).

## Spain and the benchmark countries

Latest available figure for each country in the main indices. In all of them **higher is better** except V-Dem (political corruption), where higher is worse. EU and OECD averages only exist for the World Bank and V-Dem indices (see the methodology).

<DataTable data={tabla_paises} rows=all>
    <Column id=pais title="Country" />
    <Column id=cpi title="CPI (0-100)" fmt='0' />
    <Column id=wgi_cc title="Control of corruption (0-100)" fmt='0.0' />
    <Column id=wgi_va title="Voice and accountability (0-100)" fmt='0.0' />
    <Column id=wgi_ge title="Government effectiveness (0-100)" fmt='0.0' />
    <Column id=wjp_ga title="WJP open government (0-100)" fmt='0.0' />
    <Column id=vdem_cp title="V-Dem political corruption (0-100, lower is better)\" fmt='0.0' />
</DataTable>

## Perceived corruption

Transparency International's **Corruption Perceptions Index** (CPI) is the most widely cited. It averages up to 13 surveys and assessments by experts and businesses on public sector corruption; 100 is «very clean» and 0 «highly corrupt». Its method is only comparable from 2012 onwards.

<LineChart
    data={referencia.filter(d => d.indicador_id === 'cpi')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yMin=20
    yAxisTitle="points (0-100)"
    title="Corruption Perceptions Index"
    seriesColors={{'España': '#b91c1c'}}
/>

<BarChart
    data={ranking_ue.filter(d => d.indicador_id === 'cpi')}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    yFmt='0'
    title="CPI: EU countries in {esp_cpi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

## Governance according to the World Bank

The World Bank's **Worldwide Governance Indicators** combine more than 30 sources (household and business surveys, NGOs, public bodies and risk rating agencies) into six dimensions of governance. Four are shown here, on their 0 to 100 scale. The EU and OECD averages are **simple averages** of their current member countries.

<Grid cols=2>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_control_corrupcion')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Control of corruption"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_voz_rendicion_cuentas')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Voice and accountability"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_eficacia_gobierno')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Government effectiveness"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_estado_derecho')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Rule of law"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
</Grid>

**Voice and accountability** measures freedom of expression, of the press and of association and the quality of elections; **government effectiveness**, the quality of public services and of the civil service and their independence from political pressure; **rule of law**, confidence in the laws, the courts, the police and contract enforcement. Each score comes with a 90% confidence interval of several points: year-on-year changes usually fall within it.

### Spain's rank in the EU

<LineChart
    data={puesto_ue_serie}
    x=anio
    y=puesto_ue
    series=nombre_corto
    xFmt='0'
    yFmt='0'
    yAxisTitle="rank out of 27 (1 = best)"
    title="Spain's position among EU-27 countries"
/>

The position is calculated among the countries that make up today's EU-27 with data that year (1 = best). On the axis, a higher number means a worse position.

## Long series and changes of government

The **V-Dem** project (University of Gothenburg) uses expert assessments to reconstruct a political corruption index going back long before democracy, so it covers the whole constitutional period. The background bands show who was in government: <span style="color:#16a34a">UCD</span>, <span style="color:#dc2626">PSOE</span> and <span style="color:#2563eb">PP</span>. The EU average only appears once there are data for at least 90% of the countries that make it up today (several did not exist as independent states before 1991).

<LineChart
    data={larga_vdem}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (higher = more corruption)"
    title="Political corruption index (V-Dem), 1977-{esp_vdem[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
>
    <ReferenceArea data={gob_ucd} xMin=anio_desde xMax=anio_hasta label=familia color="#16a34a" opacity=0.08 />
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.08 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.08 />
</LineChart>

<LineChart
    data={larga_wgi}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100 (higher = better)"
    title="Control of corruption (World Bank), 1996-{esp_wgi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

### By government, compared with the EU average

So as not to attribute to a government what is a European trend, we measure **how much the gap between Spain and the EU average changed** during each term. The average is that of the EU countries with a complete series, so that its composition does not change over the years ({mandatos_vdem[0]?.n_panel} countries in V-Dem since 1976 and {mandatos_wgi[0]?.n_panel} in the World Bank index since 1996). Each year is assigned to whoever was in government on 1 July. A positive value means Spain **improved relative to the EU**; a negative one, that it worsened. Expressed in points of the 0-100 scale.

<BarChart
    data={mandatos_vdem}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="V-Dem, political corruption: improvement relative to the EU (points)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<BarChart
    data={mandatos_wgi}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="World Bank, control of corruption: improvement relative to the EU (points)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<DataTable data={mandatos} rows=all>
    <Column id=indice title="Index" />
    <Column id=mandato title="Term" />
    <Column id=familia title="Party" />
    <Column id=primer_anio title="From" fmt='0' />
    <Column id=ultimo_anio title="To" fmt='0' />
    <Column id=anios title="Years with data" fmt='0' />
    <Column id=mejora title="Improvement relative to the EU" fmt='0.0' contentType=delta />
    <Column id=mejora_anual title="Per year" fmt='0.00' contentType=delta />
</DataTable>

These bars should be read with caution. Perception indices **react years late**: major corruption cases are usually tried and made public long after the events, often during the following term. Nor do they separate what depends on the central government from what depends on regions, councils, parties or courts. And short terms add up to few years, so a single atypical figure carries a lot of weight.

## Rule of law and open government

The World Justice Project's **Rule of Law Index** is based on a survey of the general population (around 1,000 people per country) and on questionnaires to legal experts. Of its eight factors, these four are the most closely related to transparency: the overall index, **constraints on government powers** (checks by Parliament, the courts and audit bodies), **absence of corruption** and **open government** (published laws and data, right of access to information, civic participation and complaint mechanisms).

<LineChart
    data={wjp_factores}
    x=anio
    y=valor
    series=factor
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Spain in the Rule of Law Index (WJP)"
/>

<LineChart
    data={referencia.filter(d => d.indicador_id === 'wjp_gobierno_abierto')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Open government (WJP, factor 3)"
    seriesColors={{'España': '#b91c1c'}}
/>

The 2012-2013 and 2017-2018 editions of the WJP index were biennial and appear in the second year.

## Explore any index

Choose an index to see how it has changed in the benchmark countries and the ranking of EU and OECD countries in the latest year with data for Spain.

<Dropdown data={opciones} name=ind value=indicador_id label=nombre order=orden_indicador title="Index" defaultValue="cpi" />

<LineChart
    data={exp_serie}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yAxisTitle={exp_info[0]?.unidad}
    title={exp_info[0]?.nombre}
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

<BarChart
    data={exp_ranking}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    title="{exp_info[0]?.nombre}: EU and OECD countries"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#64748b', 'Resto de la OCDE': '#cbd5e1'}}
/>

Unit: {exp_info[0]?.unidad}. {exp_info[0]?.sentido === 'negativo' ? 'In this index, a higher value is worse.' : 'In this index, a higher value is better.'} Source: <a href={exp_info[0]?.url_fuente}>{exp_info[0]?.fuente}</a>.

## Methodology and sources

- **Corruption Perceptions Index (CPI)**, [Transparency International](https://www.transparency.org/en/cpi). Average of between 3 and 13 sources (country risk assessments, executive surveys and expert assessments) rescaled from 0 to 100. It measures **perceived public sector** corruption, not private sector corruption, money laundering or illegal party financing. Comparable since 2012. We take the time-series sheet of the annual results spreadsheet. CC BY-ND 4.0 licence: the official scores and world ranks are reproduced **without transformation**, which is why no EU or OECD average is calculated (Spain's position in the EU is simply the order of the published scores).
- **Worldwide Governance Indicators (WGI)**, [World Bank](https://www.worldbank.org/en/publication/worldwide-governance-indicators), World Bank data API (source 3). A statistical model combining more than 30 perception sources into six dimensions; we use the 0 to 100 score from the 2024 methodological revision, with its 90% confidence interval. Biennial until 2002. CC BY 4.0 licence.
- **V-Dem** (Varieties of Democracy, University of Gothenburg), via [Our World in Data](https://ourworldindata.org/grapher/political-corruption-index). Indices of political corruption (executive, legislative, judicial and public sector) and public sector corruption, from 0 to 100 (100 = maximum corruption; the original 0-1 scale multiplied by 100), built with a measurement model on the assessments of thousands of experts per country. CC BY-SA 4.0 (V-Dem) and CC BY 4.0 (OWID) licences.
- **Rule of Law Index**, [World Justice Project](https://worldjusticeproject.org/rule-of-law-index/). Survey of the general population and questionnaires to experts; scale from 0 to 100 (the original 0-1 scale multiplied by 100). Growing country coverage since 2012-2013. CC BY-NC-ND 4.0 licence: scores reproduced as published, without averages of our own.
- **EU and OECD averages**: simple averages (not weighted by population) of the countries that are members **today**, calculated only for WGI and V-Dem and only in years with data for at least 90% of them. **Rank in the EU/OECD**: order among current members with data that year (1 = best).
- **Governments**: prime ministers and party, from the SpainFacts governments seed. In the analysis by term, each year is attributed to whoever was in government on 1 July, and the annual change is the variation in the gap between Spain and the EU average relative to the previous year with data.
- **Common limitations**: all are **perception indices**, built from surveys and subjective assessments; several share sources (which is why they are so similar); they have margins of error of several points; and they reflect events with a delay. They are no substitute for data on convictions or investigations (see [crime](/en/sociedad/criminalidad/) and [council accounts reporting](/en/transparencia/cuentas-municipales/)).
- **Sources ruled out**: the European Commission's Open Data Maturity report and the public procurement indicators of the Single Market Scoreboard (single bidder, awards without a call for tenders) do not currently offer a reusable download of data by country and year (only PDF reports and interactive dashboards); the Global Right to Information Rating assesses the access to information law, which changes very rarely, and does not form an annual series.
