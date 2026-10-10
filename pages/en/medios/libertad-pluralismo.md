---
title: Press freedom and pluralism
description: "Where Spain stands in the international indices of press freedom and media pluralism (Reporters Without Borders, Media Pluralism Monitor, V-Dem and the Council of Europe platform) and how it has evolved compared with the EU and benchmark countries."
i18n_origen: d04ffb7eb03d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql esp
-- Último dato de España en cada índice, con el anterior
WITH e AS (
    SELECT *,
        lag(valor) OVER (PARTITION BY indice_id ORDER BY anio) AS valor_anterior,
        lag(anio) OVER (PARTITION BY indice_id ORDER BY anio) AS anio_anterior,
        row_number() OVER (PARTITION BY indice_id ORDER BY anio DESC) AS rn
    FROM mother.medios_libertad_espana
)
SELECT indice_id, nombre, unidad, sentido, CAST(anio AS INTEGER) AS anio, valor,
    valor_anterior, CAST(anio_anterior AS INTEGER) AS anio_anterior, valor - valor_anterior AS cambio,
    CAST(n_total AS INTEGER) AS n_total, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue, valor_ue
FROM e
WHERE rn = 1
```

```sql k_rsf
SELECT * FROM ${esp} WHERE indice_id = 'rsf_puesto'
```

```sql k_mpm
SELECT * FROM ${esp} WHERE indice_id = 'mpm_total'
```

```sql k_vdem
SELECT * FROM ${esp} WHERE indice_id = 'vdem_libertad_expresion'
```

```sql k_coe
SELECT * FROM ${esp} WHERE indice_id = 'coe_alertas'
```

```sql serie_esp
SELECT indice_id, CAST(anio AS INTEGER) AS anio, valor, valor_ue, CAST(puesto_ue AS INTEGER) AS puesto_ue
FROM mother.medios_libertad_espana
ORDER BY indice_id, anio
```

```sql rsf_esp
SELECT CAST(edicion AS INTEGER) AS edicion, etiqueta_edicion, escala, puntuacion,
    CAST(puesto_mundial AS INTEGER) AS puesto_mundial, CAST(n_paises AS INTEGER) AS n_paises,
    CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.medios_libertad_rsf
WHERE cod_pais = 'ES' AND indicador = 'global'
ORDER BY edicion
```

```sql rsf_extremos
SELECT
    (SELECT CAST(edicion AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial, edicion DESC LIMIT 1) AS mejor_edicion,
    (SELECT CAST(puesto_mundial AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial LIMIT 1) AS mejor_puesto,
    (SELECT CAST(edicion AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial DESC, edicion DESC LIMIT 1) AS peor_edicion,
    (SELECT CAST(puesto_mundial AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial DESC LIMIT 1) AS peor_puesto,
    (SELECT CAST(edicion AS INTEGER) FROM ${rsf_esp} ORDER BY edicion LIMIT 1) AS primera_edicion,
    (SELECT CAST(puesto_mundial AS INTEGER) FROM ${rsf_esp} ORDER BY edicion LIMIT 1) AS primer_puesto,
    (SELECT CAST(n_paises AS INTEGER) FROM ${rsf_esp} ORDER BY edicion LIMIT 1) AS primer_n
```

```sql rsf_ref
-- Puesto mundial de los países de referencia en cada edición
SELECT pais, CAST(edicion AS INTEGER) AS edicion, CAST(puesto_mundial AS INTEGER) AS puesto_mundial
FROM mother.medios_libertad_rsf
WHERE indicador = 'global' AND es_referencia AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'NL')
ORDER BY orden_pais, edicion
```

```sql rsf_ue_ult
-- Puntuación de los países de la UE en la última edición
SELECT pais, puntuacion, CAST(puesto_mundial AS INTEGER) AS puesto_mundial, CAST(puesto_ue AS INTEGER) AS puesto_ue,
    CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.medios_libertad_rsf
WHERE indicador = 'global' AND es_ue AND edicion = (SELECT max(edicion) FROM mother.medios_libertad_rsf)
ORDER BY puntuacion DESC
```

```sql rsf_ind
-- Indicadores de RSF de España desde 2022
SELECT nombre_indicador AS indicador, CAST(edicion AS INTEGER) AS edicion, puntuacion,
    CAST(puesto_mundial AS INTEGER) AS puesto_mundial, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.medios_libertad_rsf
WHERE cod_pais = 'ES' AND indicador <> 'global' AND escala = '2022'
ORDER BY orden_indicador, edicion
```

```sql rsf_ind_ult
SELECT * FROM ${rsf_ind} WHERE edicion = (SELECT max(edicion) FROM ${rsf_ind}) ORDER BY puesto_mundial
```

```sql rsf_ind_tabla
-- Última edición: indicadores de los países de referencia
SELECT pais, min(orden_pais) AS orden,
    max(CASE WHEN indicador = 'global' THEN puntuacion END) AS global,
    max(CASE WHEN indicador = 'global' THEN puesto_mundial END) AS puesto,
    max(CASE WHEN indicador = 'politico' THEN puntuacion END) AS politico,
    max(CASE WHEN indicador = 'economico' THEN puntuacion END) AS economico,
    max(CASE WHEN indicador = 'legislativo' THEN puntuacion END) AS legislativo,
    max(CASE WHEN indicador = 'social' THEN puntuacion END) AS social,
    max(CASE WHEN indicador = 'seguridad' THEN puntuacion END) AS seguridad
FROM mother.medios_libertad_rsf
WHERE es_referencia AND edicion = (SELECT max(edicion) FROM mother.medios_libertad_rsf)
GROUP BY pais
ORDER BY orden, pais
```

```sql gobiernos
SELECT
    CAST(year(CAST(desde AS DATE)) AS INTEGER) AS anio_desde,
    CAST(coalesce(year(CAST(hasta AS DATE)), year(current_date)) AS INTEGER) AS anio_hasta,
    presidente, familia
FROM mother.gobiernos_presidentes
WHERE nivel = 'estatal' AND coalesce(year(CAST(hasta AS DATE)), 9999) >= 2002
ORDER BY anio_desde
```

```sql gob_psoe
SELECT * FROM ${gobiernos} WHERE familia = 'PSOE'
```

```sql gob_pp
SELECT * FROM ${gobiernos} WHERE familia = 'PP'
```

```sql rsf_gobiernos
-- Puesto de España en cada edición y quién gobernaba el 1 de julio del año anterior,
-- el periodo que valora cada edición (descriptivo, sin atribuir causalidad)
SELECT CAST(r.edicion AS INTEGER) AS edicion, CAST(r.puesto_mundial AS INTEGER) AS puesto_mundial,
    CAST(r.puesto_ue AS INTEGER) AS puesto_ue, g.presidente, g.familia
FROM mother.medios_libertad_rsf r
LEFT JOIN mother.gobiernos_presidentes g
    ON g.nivel = 'estatal'
    AND make_date(CAST(r.edicion AS INTEGER) - 1, 7, 1) >= CAST(g.desde AS DATE)
    AND make_date(CAST(r.edicion AS INTEGER) - 1, 7, 1) < coalesce(CAST(g.hasta AS DATE), current_date + INTERVAL 1 DAY)
WHERE r.cod_pais = 'ES' AND r.indicador = 'global'
ORDER BY r.edicion
```

```sql mpm_esp
SELECT nombre_area AS area, orden_area, CAST(edicion AS INTEGER) AS edicion, etiqueta_edicion, riesgo_pct, banda,
    CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.medios_libertad_mpm
WHERE cod_pais = 'ES'
ORDER BY orden_area, edicion
```

```sql mpm_esp_ult
SELECT * FROM ${mpm_esp} WHERE edicion = (SELECT max(edicion) FROM ${mpm_esp}) ORDER BY orden_area
```

```sql mpm_esp_ue
-- España y media de la UE por área en las ediciones con los 27 países
SELECT e.nombre_area AS area, e.orden_area, CAST(e.edicion AS INTEGER) AS edicion, e.riesgo_pct AS espana, u.riesgo_pct AS ue,
    e.riesgo_pct - u.riesgo_pct AS diferencia
FROM mother.medios_libertad_mpm e
JOIN mother.medios_libertad_mpm u ON u.cod_pais = 'EU27_2020' AND u.area = e.area AND u.edicion = e.edicion
WHERE e.cod_pais = 'ES'
ORDER BY e.orden_area, e.edicion
```

```sql mpm_esp_ue_ult
SELECT * FROM ${mpm_esp_ue} WHERE edicion = (SELECT max(edicion) FROM ${mpm_esp_ue}) ORDER BY orden_area
```

```sql mpm_largo
SELECT area, edicion, 'España' AS serie, espana AS riesgo_pct FROM ${mpm_esp_ue}
UNION ALL
SELECT area, edicion, 'Media de la UE' AS serie, ue AS riesgo_pct FROM ${mpm_esp_ue}
ORDER BY area, edicion, serie
```

```sql mpm_ue_ult
-- Riesgo global de los países de la UE en la última edición
SELECT pais, riesgo_pct, banda, CAST(puesto_ue AS INTEGER) AS puesto_ue,
    CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo,
    CAST(edicion AS INTEGER) AS edicion
FROM mother.medios_libertad_mpm
WHERE area = 'total' AND es_ue AND edicion = (SELECT max(edicion) FROM mother.medios_libertad_mpm WHERE area = 'total' AND n_ue = 27)
ORDER BY riesgo_pct
```

```sql vdem_esp
SELECT nombre_corto AS indicador, orden_indicador, pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.medios_libertad_vdem
WHERE cod_pais IN ('ES', 'EU27_2020') AND anio >= 1976
ORDER BY orden_indicador, orden_pais, anio
```

```sql vdem_ref
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.medios_libertad_vdem
WHERE indicador_id = 'vdem_libertad_expresion' AND es_referencia AND cod_pais IN ('ES', 'EU27_2020', 'FR', 'DE', 'IT', 'PT', 'HU') AND anio >= 2000
ORDER BY orden_pais, anio
```

```sql vdem_ult
-- Último año: España, media UE y puesto en cada indicador
SELECT e.nombre_corto AS indicador, e.orden_indicador, CAST(e.anio AS INTEGER) AS anio, e.valor AS espana, u.valor AS ue,
    CAST(e.puesto_ue AS INTEGER) AS puesto_ue, CAST(e.n_ue AS INTEGER) AS n_ue, e.unidad
FROM mother.medios_libertad_vdem e
JOIN mother.medios_libertad_vdem u ON u.indicador_id = e.indicador_id AND u.anio = e.anio AND u.cod_pais = 'EU27_2020'
WHERE e.cod_pais = 'ES' AND e.anio = (SELECT max(anio) FROM mother.medios_libertad_vdem WHERE cod_pais = 'ES')
ORDER BY e.orden_indicador
```

```sql coe_esp
SELECT pais, CAST(anio AS INTEGER) AS anio, alertas_por_10m_hab, CAST(alertas AS INTEGER) AS alertas,
    CAST(sin_respuesta AS INTEGER) AS sin_respuesta, CAST(resueltas AS INTEGER) AS resueltas
FROM mother.medios_libertad_coe_alertas
WHERE cod_pais IN ('ES', 'EU27_2020') AND NOT parcial
ORDER BY cod_pais DESC, anio
```

```sql coe_resumen
SELECT
    CAST(sum(alertas) FILTER (WHERE pais = 'España') AS INTEGER) AS total_esp,
    CAST(min(anio) AS INTEGER) AS desde,
    CAST(max(anio) AS INTEGER) AS hasta,
    CAST(sum(sin_respuesta) FILTER (WHERE pais = 'España') AS INTEGER) AS sin_respuesta_esp
FROM ${coe_esp}
```

```sql coe_ue_ult
-- Alertas por 10 millones de habitantes en los países de la UE, suma de los últimos 5 años completos
WITH u AS (
    SELECT max(anio) AS hasta FROM mother.medios_libertad_coe_alertas WHERE NOT parcial
)
SELECT c.pais,
    sum(c.alertas) / avg(c.poblacion) * 1e7 / 5 AS alertas_10m_anuales,
    CAST(sum(c.alertas) AS INTEGER) AS alertas,
    CASE WHEN c.cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.medios_libertad_coe_alertas c, u
WHERE c.es_ue AND c.anio > u.hasta - 5 AND c.anio <= u.hasta
GROUP BY c.pais, c.cod_pais
ORDER BY alertas_10m_anuales DESC
```

```sql coe_periodo
SELECT CAST(max(anio) - 4 AS INTEGER) AS desde, CAST(max(anio) AS INTEGER) AS hasta
FROM mother.medios_libertad_coe_alertas WHERE NOT parcial
```

# <span aria-hidden="true">🗞️</span> Press freedom and pluralism

Can journalists work in Spain without pressure, and is there a variety of independent media? Several international organisations assess this every year with **indices that are comparable across countries**. This page brings together the four main ones and places Spain among the **27 EU countries**: the World Press Freedom Index by Reporters Without Borders, the Media Pluralism Monitor of the European University Institute, the V-Dem media indicators and the alerts of the Council of Europe Platform for the protection of journalism.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">How to read this page</p>
<p class="mb-1">These are <b>assessments by those organisations</b>, based on questionnaires to journalists, academics and experts, not direct measurements. Each looks at different things: RSF, the conditions for practising journalism; the Media Pluralism Monitor, the risks to pluralism (laws, concentration of ownership, independence, access); V-Dem, censorship, harassment and bias; the Council of Europe, specific cases of threats recorded by journalists' organisations.</p>
<p class="mb-0">Methods change over the years and differences of a few points or places <b>are not usually significant</b>. What matters is the trend and the gap with the EU.</p>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if k_rsf.length && k_mpm.length && k_vdem.length && k_coe.length}
    <KpiCard
        title="RSF Index"
        value={k_rsf[0].valor}
        formattedValue={'Rank ' + formatNumber(k_rsf[0].valor, 0)}
        period={`${k_rsf[0].anio} · of ${k_rsf[0].n_total} countries; ${k_rsf[0].puesto_ue} of ${k_rsf[0].n_ue} in the EU`}
        change={-(k_rsf[0].cambio)}
        changeUnit=" places"
        changePeriod={`vs ${k_rsf[0].anio_anterior}`}
        direction="positive-up"
        source="Reporters Without Borders"
        sparklineData={serie_esp.filter(d => d.indice_id === 'rsf_puesto').map(d => ({...d, y: -d.valor}))}
    />
    <KpiCard
        title="Risk to pluralism"
        value={k_mpm[0].valor}
        formattedValue={formatNumber(k_mpm[0].valor, 0) + ' %'}
        period={`MPM${k_mpm[0].anio} · ${k_mpm[0].puesto_ue ? k_mpm[0].puesto_ue + ' of ' + k_mpm[0].n_ue + ' in the EU (1 = lowest risk)' : 'higher = worse'}`}
        change={k_mpm[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs MPM${k_mpm[0].anio_anterior}`}
        direction="positive-down"
        source="Media Pluralism Monitor (EUI)"
        sparklineData={serie_esp.filter(d => d.indice_id === 'mpm_total').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Freedom of expression (V-Dem)"
        value={k_vdem[0].valor}
        formattedValue={formatNumber(k_vdem[0].valor, 1) + ' / 100'}
        period={`${k_vdem[0].anio} · ${k_vdem[0].puesto_ue} of ${k_vdem[0].n_ue} in the EU (EU average ${formatNumber(k_vdem[0].valor_ue, 1)})`}
        change={k_vdem[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs ${k_vdem[0].anio_anterior}`}
        direction="positive-up"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indice_id === 'vdem_libertad_expresion' && d.anio >= 1990).map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Council of Europe alerts"
        value={k_coe[0].valor}
        formattedValue={formatNumber(k_coe[0].valor, 2)}
        unit="per 10 million inhabitants"
        period={`${k_coe[0].anio} · ${k_coe[0].n_total} alerts; EU average ${formatNumber(k_coe[0].valor_ue, 2)}`}
        change={k_coe[0].cambio}
        changeUnit=""
        changePeriod={`vs ${k_coe[0].anio_anterior}`}
        direction="positive-down"
        source="Council of Europe"
        sparklineData={serie_esp.filter(d => d.indice_id === 'coe_alertas').map(d => ({...d, y: d.valor}))}
    />
    {/if}
</div>

## World Press Freedom Index

**Reporters Without Borders** (RSF) ranks some 180 countries every year according to the conditions for practising journalism, based on a questionnaire to journalists, academics and human rights defenders and on its own tally of attacks on journalists. Spain is **ranked {k_rsf[0]?.valor} of {k_rsf[0]?.n_total}** in the {k_rsf[0]?.anio} edition and {k_rsf[0]?.puesto_ue} of the {k_rsf[0]?.n_ue} EU countries. Its best ranking was {rsf_extremos[0]?.mejor_puesto} ({rsf_extremos[0]?.mejor_edicion} edition) and its worst, {rsf_extremos[0]?.peor_puesto} ({rsf_extremos[0]?.peor_edicion}).

<LineChart
    data={rsf_ref}
    x=edicion
    y=puesto_mundial
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="world rank (1 = best)"
    title="Rank in the World Press Freedom Index (RSF)"
    seriesColors={{'España': '#b91c1c'}}
>
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.06 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.06 />
</LineChart>

On the axis, a higher number is a worse position. The background bands mark the party of the central government (<span style="color:#dc2626">PSOE</span> or <span style="color:#2563eb">PP</span>) purely as a time reference: the index assesses the whole country, not just the government. Each edition is published in spring and mainly assesses the previous year. The number of countries ranked has gone from {rsf_extremos[0]?.primer_n} in {rsf_extremos[0]?.primera_edicion} to {k_rsf[0]?.n_total}, so the rankings of the early years are not fully comparable.

<BarChart
    data={rsf_ue_ult}
    x=pais
    y=puntuacion
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="RSF score of EU countries, {k_rsf[0]?.anio} (0-100, higher is better)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

### The five RSF indicators

Since 2022 RSF has broken the score down into five indicators: **political context** (pressure from political power and support for media independence), **economic** (media sustainability, concentration, allocation of public aid and advertising), **legal framework** (laws and their application), **social context** (social respect for journalists, pressure from groups) and **security** (attacks, threats, arrests). In {rsf_ind_ult[0]?.edicion}, Spain's best ranking is in {rsf_ind_ult[0]?.indicador} ({rsf_ind_ult[0]?.puesto_mundial} in the world) and its worst in {rsf_ind_ult.slice(-1)[0]?.indicador} ({rsf_ind_ult.slice(-1)[0]?.puesto_mundial}).

<LineChart
    data={rsf_ind}
    x=edicion
    y=puntuacion
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="points 0-100 (higher is better)"
    title="Spain in the RSF indicators"
/>

<DataTable data={rsf_ind_tabla} rows=all>
    <Column id=pais title="Country" />
    <Column id=puesto title="World rank" fmt='0' />
    <Column id=global title="Overall" fmt='0.0' />
    <Column id=politico title="Political" fmt='0.0' />
    <Column id=economico title="Economic" fmt='0.0' />
    <Column id=legislativo title="Legal framework" fmt='0.0' />
    <Column id=social title="Social" fmt='0.0' />
    <Column id=seguridad title="Security" fmt='0.0' />
</DataTable>

### Edition by edition

Spain's rank in each edition and the party in government on 1 July of the year that edition assesses. This describes the calendar, it does not attribute responsibility: the assessment also reflects the conduct of regional governments, courts, media companies and other actors.

<DataTable data={rsf_gobiernos} rows=all>
    <Column id=edicion title="Edition" fmt='0' />
    <Column id=puesto_mundial title="World rank" fmt='0' />
    <Column id=puesto_ue title="EU rank" fmt='0' />
    <Column id=presidente title="Prime Minister on 1 July of the previous year" />
    <Column id=familia title="Party" />
</DataTable>

## Risk to media pluralism

The **Media Pluralism Monitor** (MPM) of the Centre for Media Pluralism and Media Freedom (European University Institute, Florence) uses a team of researchers in each country to assess some 200 questions grouped into four areas. The result is a **risk from 0 to 100 %: higher is worse**. In the MPM{mpm_esp_ult[0]?.edicion} edition, Spain's overall risk is {formatNumber(mpm_esp_ult[0]?.riesgo_pct, 0)} % (band: {mpm_esp_ult[0]?.banda}).

<BarChart
    data={mpm_esp_ult.filter(d => d.orden_area > 0)}
    x=area
    y=riesgo_pct
    swapXY=true
    yFmt='0"%"'
    yMax=100
    title="Spain: risk by area, MPM{mpm_esp_ult[0]?.edicion}"
    colorPalette={['#b45309']}
/>

- **Fundamental protection**: freedom of expression, right to information, working conditions and safety of journalists, and independence of the regulator.
- **Market plurality**: transparency of ownership, concentration, economic viability of the media and commercial influence on what they publish.
- **Political independence**: political control of the media, independence of public service media, allocation of institutional advertising and aid, editorial autonomy.
- **Social inclusiveness**: access for minorities, local communities, women and people with disabilities, and media literacy.

### Spain compared with the EU average

The EU average is the simple average of the 27 countries that currently make up the EU, in the editions in which the MPM assessed all of them. In the MPM{mpm_esp_ue_ult[0]?.edicion} edition, Spain had higher risk than the average in {mpm_esp_ue_ult.filter(d => d.orden_area > 0 && d.diferencia > 0).length} of the four areas.

<Grid cols=2>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Protección fundamental')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="risk %"
    title="Fundamental protection"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Pluralidad del mercado')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="risk %"
    title="Market plurality"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Independencia política')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="risk %"
    title="Political independence"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Inclusión social')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="risk %"
    title="Social inclusiveness"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
</Grid>

The questionnaire changes with each edition, so jumps of a few points between editions do not always reflect real changes. There were no editions in 2018 or 2019 (MPM2020 covers 2018 and 2019).

<BarChart
    data={mpm_ue_ult}
    x=pais
    y=riesgo_pct
    series=grupo
    swapXY=true
    yFmt='0"%"'
    title="Overall risk to pluralism in the EU, MPM{mpm_ue_ult[0]?.edicion} (higher is worse)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

<DataTable data={mpm_esp} rows=all>
    <Column id=area title="Area" />
    <Column id=etiqueta_edicion title="Edition" />
    <Column id=riesgo_pct title="Risk (%)" fmt='0' />
    <Column id=banda title="Band" />
    <Column id=puesto_ue title="EU rank (1 = lowest risk)" fmt='0' />
</DataTable>

## Censorship, harassment and bias according to V-Dem

The **V-Dem** project (University of Gothenburg) asks several experts per country every year to assess, among other things, whether the government attempts to censor the press, whether journalists are harassed, whether the media self-censor and whether they are biased against the opposition. A statistical model turns this into scores comparable across countries and years, summarised in a freedom of expression index from 0 to 100.

<LineChart
    data={vdem_ref}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (higher is better)"
    title="Freedom of expression and alternative sources of information index (V-Dem)"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569'}}
/>

<LineChart
    data={vdem_esp.filter(d => d.orden_indicador > 1 && d.pais === 'España')}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="V-Dem scale (higher = more freedom)"
    title="Spain: V-Dem media indicators since 1976"
/>

These four indicators are on the V-Dem model scale (roughly from -4 to +4): **the higher, the more freedom** (less censorship, less harassment, less self-censorship, less bias). In {vdem_ult[0]?.anio}:

<DataTable data={vdem_ult} rows=all>
    <Column id=indicador title="Indicator" />
    <Column id=espana title="Spain" fmt='0.00' />
    <Column id=ue title="EU average" fmt='0.00' />
    <Column id=puesto_ue title="Spain's EU rank" fmt='0' />
</DataTable>

## Council of Europe alerts

The **Council of Europe Platform to promote the protection of journalism and safety of journalists** publishes alerts about serious threats to press freedom (attacks, arrests, harassment, abusive lawsuits, political pressure) recorded by its partner organisations, such as the European Federation of Journalists or RSF. States can respond to each alert. Between {coe_resumen[0]?.desde} and {coe_resumen[0]?.hasta}, {coe_resumen[0]?.total_esp} alerts were published about Spain, {coe_resumen[0]?.sin_respuesta_esp} of them without a reply from the State. To compare countries of different sizes, they are counted per 10 million inhabitants.

<LineChart
    data={coe_esp}
    x=anio
    y=alertas_por_10m_hab
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="alerts per 10 million inhabitants"
    title="Alerts published per year, per 10 million inhabitants"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (27)': '#94a3b8'}}
/>

<BarChart
    data={coe_ue_ult}
    x=pais
    y=alertas_10m_anuales
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Alerts per year per 10 million inhabitants, average {coe_periodo[0]?.desde}-{coe_periodo[0]?.hasta}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

A low count does not necessarily mean fewer problems: it depends on which cases the partner organisations decide to record and how much presence they have in each country.

## Methodology and sources

- **World Press Freedom Index**, [Reporters Without Borders](https://rsf.org/en/index), CSV files for each edition (2002-2010 and from 2012; the 2012 edition covers 2011-2012). The official rank and score are reproduced as they are, citing RSF, without averages or calculations of our own (the terms of use of rsf.org reserve all rights). The scores of three periods **are not comparable**: 2002-2012 (open-ended scale, 0 = best), 2013-2021 (0-100) and from 2022 (new methodology with five indicators). The EU rank is simply the order of the official ranks among the 27 countries that currently make up the EU.
- **Media Pluralism Monitor**, [Centre for Media Pluralism and Media Freedom](https://cmpf.eui.eu/) (European University Institute), CC BY 4.0 licence. Editions MPM2016, MPM2017 and MPM2020 onwards (there was no MPM2018 or MPM2019); edition N assesses year N-1. Past editions transcribed from the PDF country reports in the [Cadmus repository](https://cadmus.eui.eu/) and the latest one from the CMPF's [country sheets](https://cmpf.eui.eu/mpm-2025-results/). For MPM2025 only Spain's data are available. Overall risk: the figure published by the CMPF or, in editions that did not publish it, the simple average of the four areas (as the CMPF has calculated it since 2022). Up to MPM2024 there were three risk bands (low, medium, high) and from MPM2025, six.
- **V-Dem** (Varieties of Democracy, University of Gothenburg), via [Our World in Data](https://ourworldindata.org/grapher/key-media-freedoms): government censorship (v2mecenefm), harassment of journalists (v2meharjrn), self-censorship (v2meslfcen) and media bias (v2mebias), central estimate of the measurement model; and [freedom of expression index](https://ourworldindata.org/grapher/freedom-of-expression-index) (0-1, multiplied by 100). Licences CC BY-SA 4.0 (V-Dem) and CC BY 4.0 (OWID). EU average: simple average of the current member states, only in years with data for at least 90 % of them.
- **Alerts**, [Council of Europe Platform to promote the protection of journalism and safety of journalists](https://fom.coe.int/), count by country and year since 2015 (year of the alert according to the portal), with Eurostat's average annual population. The status of each alert (replied, resolved) is as of the download date.
- None of these indices measures audiences or media quality. For the public money the media receive, see [Public money in the media](/en/medios/dinero-publico/).
