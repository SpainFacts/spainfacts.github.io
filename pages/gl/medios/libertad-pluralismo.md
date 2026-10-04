---
title: Liberdade de prensa e pluralismo
description: "Onde está España nos índices internacionais de liberdade de prensa e pluralismo dos medios (Reporteiros Sen Fronteiras, Media Pluralism Monitor, V-Dem e a plataforma do Consello de Europa) e como evolucionou fronte á UE e aos países de referencia."
i18n_origen: 70c909289afe
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

# <span aria-hidden="true">🗞️</span> Liberdade de prensa e pluralismo

Poden os xornalistas traballar en España sen presións e hai variedade de medios independentes? Varias organizacións internacionais avalíano cada ano con **índices comparables entre países**. Esta páxina reúne os catro principais e sitúa España entre os **27 países da UE**: a Clasificación Mundial da Liberdade de Prensa de Reporteiros Sen Fronteiras, o Media Pluralism Monitor do Instituto Universitario Europeo, os indicadores de medios de V-Dem e as alertas da plataforma do Consello de Europa para a protección do xornalismo.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Como ler esta páxina</p>
<p class="mb-1">Son <b>valoracións desas organizacións</b>, feitas con cuestionarios a xornalistas, académicos e expertos, non medicións directas. Cada unha mira cousas distintas: RSF, as condicións para exercer o xornalismo; o Media Pluralism Monitor, os riscos para o pluralismo (leis, concentración da propiedade, independencia, acceso); V-Dem, a censura, o acoso e o nesgo; o Consello de Europa, casos concretos de ameazas que rexistran organizacións de xornalistas.</p>
<p class="mb-0">Os métodos cambian cos anos e as diferenzas de poucos puntos ou postos <b>non adoitan ser significativas</b>. O que importa é a tendencia e a distancia coa UE.</p>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if k_rsf.length && k_mpm.length && k_vdem.length && k_coe.length}
    <KpiCard
        title="Clasificación de RSF"
        value={k_rsf[0].valor}
        formattedValue={'Posto ' + formatNumber(k_rsf[0].valor, 0)}
        period={`${k_rsf[0].anio} · de ${k_rsf[0].n_total} países; ${k_rsf[0].puesto_ue}.º de ${k_rsf[0].n_ue} na UE`}
        change={-(k_rsf[0].cambio)}
        changeUnit=" postos"
        changePeriod={`vs ${k_rsf[0].anio_anterior}`}
        direction="positive-up"
        source="Reporteiros Sen Fronteiras"
        sparklineData={serie_esp.filter(d => d.indice_id === 'rsf_puesto').map(d => -d.valor)}
    />
    <KpiCard
        title="Risco para o pluralismo"
        value={k_mpm[0].valor}
        formattedValue={formatNumber(k_mpm[0].valor, 0) + ' %'}
        period={`MPM${k_mpm[0].anio} · ${k_mpm[0].puesto_ue ? k_mpm[0].puesto_ue + '.º de ' + k_mpm[0].n_ue + ' na UE (1 = menor risco)' : 'máis alto = peor'}`}
        change={k_mpm[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs MPM${k_mpm[0].anio_anterior}`}
        direction="positive-down"
        source="Media Pluralism Monitor (EUI)"
        sparklineData={serie_esp.filter(d => d.indice_id === 'mpm_total').map(d => d.valor)}
    />
    <KpiCard
        title="Liberdade de expresión (V-Dem)"
        value={k_vdem[0].valor}
        formattedValue={formatNumber(k_vdem[0].valor, 1) + ' / 100'}
        period={`${k_vdem[0].anio} · ${k_vdem[0].puesto_ue}.º de ${k_vdem[0].n_ue} na UE (media UE ${formatNumber(k_vdem[0].valor_ue, 1)})`}
        change={k_vdem[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs ${k_vdem[0].anio_anterior}`}
        direction="positive-up"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indice_id === 'vdem_libertad_expresion' && d.anio >= 1990).map(d => d.valor)}
    />
    <KpiCard
        title="Alertas do Consello de Europa"
        value={k_coe[0].valor}
        formattedValue={formatNumber(k_coe[0].valor, 2)}
        unit="por 10 millóns de hab."
        period={`${k_coe[0].anio} · ${k_coe[0].n_total} alertas; media UE ${formatNumber(k_coe[0].valor_ue, 2)}`}
        change={k_coe[0].cambio}
        changeUnit=""
        changePeriod={`vs ${k_coe[0].anio_anterior}`}
        direction="positive-down"
        source="Consello de Europa"
        sparklineData={serie_esp.filter(d => d.indice_id === 'coe_alertas').map(d => d.valor)}
    />
    {/if}
</div>

## Clasificación Mundial da Liberdade de Prensa

**Reporteiros Sen Fronteiras** (RSF) clasifica cada ano uns 180 países segundo as condicións para exercer o xornalismo, a partir dun cuestionario a xornalistas, académicos e defensores de dereitos humanos e da súa propia conta de agresións a xornalistas. España ocupa o **posto {k_rsf[0]?.valor} de {k_rsf[0]?.n_total}** na edición de {k_rsf[0]?.anio} e o {k_rsf[0]?.puesto_ue}.º dos {k_rsf[0]?.n_ue} países da UE. O seu mellor posto foi o {rsf_extremos[0]?.mejor_puesto} (edición {rsf_extremos[0]?.mejor_edicion}) e o peor, o {rsf_extremos[0]?.peor_puesto} ({rsf_extremos[0]?.peor_edicion}).

<LineChart
    data={rsf_ref}
    x=edicion
    y=puesto_mundial
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="posto mundial (1 = o mellor)"
    title="Posto na Clasificación Mundial da Liberdade de Prensa (RSF)"
    seriesColors={{'España': '#b91c1c'}}
>
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.06 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.06 />
</LineChart>

No eixe, un número máis alto é unha posición peor. As bandas de fondo marcan o partido do Goberno central (<span style="color:#dc2626">PSOE</span> ou <span style="color:#2563eb">PP</span>) só como referencia temporal: a clasificación valora todo o país, non só o Goberno. Cada edición publícase na primavera e valora sobre todo o ano anterior. O número de países clasificados pasou de {rsf_extremos[0]?.primer_n} en {rsf_extremos[0]?.primera_edicion} a {k_rsf[0]?.n_total}, así que os postos dos primeiros anos non son de todo comparables.

<BarChart
    data={rsf_ue_ult}
    x=pais
    y=puntuacion
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Puntuación de RSF dos países da UE, {k_rsf[0]?.anio} (0-100, máis é mellor)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

### Os cinco indicadores de RSF

Desde 2022 RSF desagrega a puntuación en cinco indicadores: **contexto político** (presións do poder político e apoio á independencia dos medios), **económico** (sustentabilidade dos medios, concentración, reparto de axudas e publicidade pública), **marco legal** (leis e a súa aplicación), **contexto social** (respecto social aos xornalistas, presións de grupos) e **seguridade** (agresións, ameazas, detencións). En {rsf_ind_ult[0]?.edicion}, o mellor posto de España é en {rsf_ind_ult[0]?.indicador} ({rsf_ind_ult[0]?.puesto_mundial}.º do mundo) e o peor en {rsf_ind_ult.slice(-1)[0]?.indicador} ({rsf_ind_ult.slice(-1)[0]?.puesto_mundial}.º).

<LineChart
    data={rsf_ind}
    x=edicion
    y=puntuacion
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="puntos 0-100 (máis é mellor)"
    title="España nos indicadores de RSF"
/>

<DataTable data={rsf_ind_tabla} rows=all>
    <Column id=pais title="País" />
    <Column id=puesto title="Posto mundial" fmt='0' />
    <Column id=global title="Global" fmt='0.0' />
    <Column id=politico title="Político" fmt='0.0' />
    <Column id=economico title="Económico" fmt='0.0' />
    <Column id=legislativo title="Marco legal" fmt='0.0' />
    <Column id=social title="Social" fmt='0.0' />
    <Column id=seguridad title="Seguridade" fmt='0.0' />
</DataTable>

### Edición a edición

Posto de España en cada edición e partido que gobernaba o 1 de xullo do ano que valora esa edición. É unha descrición do calendario, non unha atribución: a valoración recolle tamén a actuación de comunidades, tribunais, empresas de medios e outros actores.

<DataTable data={rsf_gobiernos} rows=all>
    <Column id=edicion title="Edición" fmt='0' />
    <Column id=puesto_mundial title="Posto mundial" fmt='0' />
    <Column id=puesto_ue title="Posto na UE" fmt='0' />
    <Column id=presidente title="Presidente a 1 de xullo do ano anterior" />
    <Column id=familia title="Partido" />
</DataTable>

## Risco para o pluralismo dos medios

O **Media Pluralism Monitor** (MPM) do Centre for Media Pluralism and Media Freedom (Instituto Universitario Europeo, Florencia) avalía cun equipo de investigadores de cada país unhas 200 preguntas agrupadas en catro áreas. O resultado é un **risco de 0 a 100 %: máis alto é peor**. Na edición MPM{mpm_esp_ult[0]?.edicion}, o risco global de España é do {formatNumber(mpm_esp_ult[0]?.riesgo_pct, 0)} % (banda {mpm_esp_ult[0]?.banda}).

<BarChart
    data={mpm_esp_ult.filter(d => d.orden_area > 0)}
    x=area
    y=riesgo_pct
    swapXY=true
    yFmt='0"%"'
    yMax=100
    title="España: risco por área, MPM{mpm_esp_ult[0]?.edicion}"
    colorPalette={['#b45309']}
/>

- **Protección fundamental**: liberdade de expresión, dereito á información, condicións e seguridade dos xornalistas e independencia do regulador.
- **Pluralidade do mercado**: transparencia da propiedade, concentración, viabilidade económica dos medios e influencia comercial no que publican.
- **Independencia política**: control político dos medios, independencia dos medios públicos, reparto da publicidade institucional e das axudas, autonomía editorial.
- **Inclusión social**: acceso de minorías, comunidades locais, mulleres e persoas con discapacidade, e alfabetización mediática.

### España fronte á media da UE

A media da UE é a media simple dos 27 países que hoxe a forman, nas edicións nas que o MPM os avaliou a todos. Na edición MPM{mpm_esp_ue_ult[0]?.edicion}, España tiña máis risco que a media en {mpm_esp_ue_ult.filter(d => d.orden_area > 0 && d.diferencia > 0).length} das catro áreas.

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
    yAxisTitle="risco %"
    title="Protección fundamental"
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
    yAxisTitle="risco %"
    title="Pluralidade do mercado"
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
    yAxisTitle="risco %"
    title="Independencia política"
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
    yAxisTitle="risco %"
    title="Inclusión social"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
</Grid>

O cuestionario cambia en cada edición, así que os saltos de poucos puntos entre edicións non sempre reflicten cambios reais. Non houbo edicións en 2018 nin 2019 (a MPM2020 cobre 2018 e 2019).

<BarChart
    data={mpm_ue_ult}
    x=pais
    y=riesgo_pct
    series=grupo
    swapXY=true
    yFmt='0"%"'
    title="Risco global para o pluralismo na UE, MPM{mpm_ue_ult[0]?.edicion} (máis é peor)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

<DataTable data={mpm_esp} rows=all>
    <Column id=area title="Área" />
    <Column id=etiqueta_edicion title="Edición" />
    <Column id=riesgo_pct title="Risco (%)" fmt='0' />
    <Column id=banda title="Banda" />
    <Column id=puesto_ue title="Posto na UE (1 = menor risco)" fmt='0' />
</DataTable>

## Censura, acoso e nesgo segundo V-Dem

O proxecto **V-Dem** (Universidade de Gotemburgo) pídelles cada ano a varios expertos por país que valoren, entre outras cousas, se o Goberno intenta censurar a prensa, se se acosa a xornalistas, se os medios se autocensuran e se teñen nesgo contra a oposición. Cun modelo estatístico convérteo en puntuacións comparables entre países e anos, e resúmeo nun índice de liberdade de expresión de 0 a 100.

<LineChart
    data={vdem_ref}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (máis é mellor)"
    title="Índice de liberdade de expresión e fontes alternativas de información (V-Dem)"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569'}}
/>

<LineChart
    data={vdem_esp.filter(d => d.orden_indicador > 1 && d.pais === 'España')}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="escala de V-Dem (máis alto = máis liberdade)"
    title="España: indicadores de medios de V-Dem desde 1976"
/>

Estes catro indicadores están na escala do modelo de V-Dem (máis ou menos de -4 a +4): **canto máis alto, máis liberdade** (menos censura, menos acoso, menos autocensura, menos nesgo). En {vdem_ult[0]?.anio}:

<DataTable data={vdem_ult} rows=all>
    <Column id=indicador title="Indicador" />
    <Column id=espana title="España" fmt='0.00' />
    <Column id=ue title="Media da UE" fmt='0.00' />
    <Column id=puesto_ue title="Posto de España na UE" fmt='0' />
</DataTable>

## Alertas do Consello de Europa

A **Plataforma do Consello de Europa para a protección do xornalismo e a seguridade dos xornalistas** publica alertas sobre ameazas graves á liberdade de prensa (agresións, detencións, acoso, demandas abusivas, presións políticas) que rexistran as súas organizacións socias, como a Federación Europea de Xornalistas ou RSF. Os Estados poden responder a cada alerta. Entre {coe_resumen[0]?.desde} e {coe_resumen[0]?.hasta} publicáronse {coe_resumen[0]?.total_esp} alertas sobre España, {coe_resumen[0]?.sin_respuesta_esp} delas sen resposta do Estado. Para comparar países de tamaño distinto cóntanse por cada 10 millóns de habitantes.

<LineChart
    data={coe_esp}
    x=anio
    y=alertas_por_10m_hab
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="alertas por 10 millóns de habitantes"
    title="Alertas publicadas por ano, por 10 millóns de habitantes"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (27)': '#94a3b8'}}
/>

<BarChart
    data={coe_ue_ult}
    x=pais
    y=alertas_10m_anuales
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Alertas ao ano por 10 millóns de habitantes, media {coe_periodo[0]?.desde}-{coe_periodo[0]?.hasta}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

Unha conta baixa non significa necesariamente menos problemas: depende de que casos deciden rexistrar as organizacións socias e de canta presenza teñen en cada país.

## Metodoloxía e fontes

- **Clasificación Mundial da Liberdade de Prensa**, [Reporteiros Sen Fronteiras](https://rsf.org/es/clasificacion), ficheiros CSV de cada edición (2002-2010 e desde 2012; a de 2012 cobre 2011-2012). Reprodúcense tal cal o posto e a puntuación oficiais, citando RSF, sen medias nin cálculos propios (as condicións de uso de rsf.org reservan todos os dereitos). As puntuacións de tres etapas **non son comparables**: 2002-2012 (escala sen teito, 0 = mellor), 2013-2021 (0-100) e desde 2022 (nova metodoloxía con cinco indicadores). O posto na UE é só a orde dos postos oficiais entre os 27 países que hoxe a forman.
- **Media Pluralism Monitor**, [Centre for Media Pluralism and Media Freedom](https://cmpf.eui.eu/) (Instituto Universitario Europeo), licenza CC BY 4.0. Edicións MPM2016, MPM2017 e MPM2020 en diante (non houbo MPM2018 nin MPM2019); a edición N valora o ano N-1. Edicións pasadas transcritas dos informes país en PDF do [repositorio Cadmus](https://cadmus.eui.eu/) e a última das [fichas por país](https://cmpf.eui.eu/mpm-2025-results/) do CMPF. Na MPM2025 só se dispón do dato de España. Risco global: o publicado polo CMPF ou, nas edicións que non o publicaban, a media simple das catro áreas (como o calcula o CMPF desde 2022). Ata a MPM2024 había tres bandas de risco (baixo, medio, alto) e desde a MPM2025, seis.
- **V-Dem** (Varieties of Democracy, Universidade de Gotemburgo), vía [Our World in Data](https://ourworldindata.org/grapher/key-media-freedoms): censura gobernamental (v2mecenefm), acoso a xornalistas (v2meharjrn), autocensura (v2meslfcen) e nesgo dos medios (v2mebias), estimación central do modelo de medida; e [índice de liberdade de expresión](https://ourworldindata.org/grapher/freedom-of-expression-index) (0-1, multiplicado por 100). Licenzas CC BY-SA 4.0 (V-Dem) e CC BY 4.0 (OWID). Media da UE: media simple dos países membros actuais, só nos anos con dato de polo menos o 90 %.
- **Alertas**, [Plataforma do Consello de Europa para a protección do xornalismo e a seguridade dos xornalistas](https://fom.coe.int/), conta por país e ano desde 2015 (ano da alerta segundo o portal), coa poboación media anual de Eurostat. O estado de cada alerta (respondida, resolta) é o da data de descarga.
- Ningún destes índices mide audiencias nin calidade dos medios. Para o diñeiro público que reciben os medios, ver [Diñeiro público nos medios](/gl/medios/dinero-publico/).
