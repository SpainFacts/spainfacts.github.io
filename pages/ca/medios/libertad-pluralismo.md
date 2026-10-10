---
title: Llibertat de premsa i pluralisme
description: "On és Espanya en els índexs internacionals de llibertat de premsa i pluralisme dels mitjans (Reporters Sense Fronteres, Media Pluralism Monitor, V-Dem i la plataforma del Consell d'Europa) i com ha evolucionat respecte a la UE i els països de referència."
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

# <span aria-hidden="true">🗞️</span> Llibertat de premsa i pluralisme

Poden els periodistes treballar a Espanya sense pressions i hi ha varietat de mitjans independents? Diverses organitzacions internacionals ho avaluen cada any amb **índexs comparables entre països**. Aquesta pàgina reuneix els quatre principals i situa Espanya entre els **27 països de la UE**: la Classificació Mundial de la Llibertat de Premsa de Reporters Sense Fronteres, el Media Pluralism Monitor de l'Institut Universitari Europeu, els indicadors de mitjans de V-Dem i les alertes de la plataforma del Consell d'Europa per a la protecció del periodisme.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Com llegir aquesta pàgina</p>
<p class="mb-1">Són <b>valoracions d'aquestes organitzacions</b>, fetes amb qüestionaris a periodistes, acadèmics i experts, no mesuraments directes. Cadascuna mira coses diferents: RSF, les condicions per exercir el periodisme; el Media Pluralism Monitor, els riscos per al pluralisme (lleis, concentració de la propietat, independència, accés); V-Dem, la censura, l'assetjament i el biaix; el Consell d'Europa, casos concrets d'amenaces que registren organitzacions de periodistes.</p>
<p class="mb-0">Els mètodes canvien amb els anys i les diferències de pocs punts o posicions <b>no solen ser significatives</b>. El que importa és la tendència i la distància amb la UE.</p>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if k_rsf.length && k_mpm.length && k_vdem.length && k_coe.length}
    <KpiCard
        title="Classificació de RSF"
        value={k_rsf[0].valor}
        formattedValue={'Posició ' + formatNumber(k_rsf[0].valor, 0)}
        period={`${k_rsf[0].anio} · de ${k_rsf[0].n_total} països; posició ${k_rsf[0].puesto_ue} de ${k_rsf[0].n_ue} a la UE`}
        change={-(k_rsf[0].cambio)}
        changeUnit=" posicions"
        changePeriod={`vs ${k_rsf[0].anio_anterior}`}
        direction="positive-up"
        source="Reporters Sense Fronteres"
        sparklineData={serie_esp.filter(d => d.indice_id === 'rsf_puesto').map(d => ({...d, y: -d.valor}))}
    />
    <KpiCard
        title="Risc per al pluralisme"
        value={k_mpm[0].valor}
        formattedValue={formatNumber(k_mpm[0].valor, 0) + ' %'}
        period={`MPM${k_mpm[0].anio} · ${k_mpm[0].puesto_ue ? 'posició ' + k_mpm[0].puesto_ue + ' de ' + k_mpm[0].n_ue + ' a la UE (1 = menys risc)' : 'més alt = pitjor'}`}
        change={k_mpm[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs MPM${k_mpm[0].anio_anterior}`}
        direction="positive-down"
        source="Media Pluralism Monitor (EUI)"
        sparklineData={serie_esp.filter(d => d.indice_id === 'mpm_total').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Llibertat d'expressió (V-Dem)"
        value={k_vdem[0].valor}
        formattedValue={formatNumber(k_vdem[0].valor, 1) + ' / 100'}
        period={`${k_vdem[0].anio} · posició ${k_vdem[0].puesto_ue} de ${k_vdem[0].n_ue} a la UE (mitjana UE ${formatNumber(k_vdem[0].valor_ue, 1)})`}
        change={k_vdem[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs ${k_vdem[0].anio_anterior}`}
        direction="positive-up"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indice_id === 'vdem_libertad_expresion' && d.anio >= 1990).map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Alertes del Consell d'Europa"
        value={k_coe[0].valor}
        formattedValue={formatNumber(k_coe[0].valor, 2)}
        unit="per 10 milions d'hab."
        period={`${k_coe[0].anio} · ${k_coe[0].n_total} alertes; mitjana UE ${formatNumber(k_coe[0].valor_ue, 2)}`}
        change={k_coe[0].cambio}
        changeUnit=""
        changePeriod={`vs ${k_coe[0].anio_anterior}`}
        direction="positive-down"
        source="Consell d'Europa"
        sparklineData={serie_esp.filter(d => d.indice_id === 'coe_alertas').map(d => ({...d, y: d.valor}))}
    />
    {/if}
</div>

## Classificació Mundial de la Llibertat de Premsa

**Reporters Sense Fronteres** (RSF) classifica cada any uns 180 països segons les condicions per exercir el periodisme, a partir d'un qüestionari a periodistes, acadèmics i defensors dels drets humans i del seu propi recompte d'agressions a periodistes. Espanya ocupa la **posició {k_rsf[0]?.valor} de {k_rsf[0]?.n_total}** en l'edició del {k_rsf[0]?.anio} i la posició {k_rsf[0]?.puesto_ue} entre els {k_rsf[0]?.n_ue} països de la UE. La seva millor posició va ser la {rsf_extremos[0]?.mejor_puesto} (edició {rsf_extremos[0]?.mejor_edicion}) i la pitjor, la {rsf_extremos[0]?.peor_puesto} ({rsf_extremos[0]?.peor_edicion}).

<LineChart
    data={rsf_ref}
    x=edicion
    y=puesto_mundial
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="posició mundial (1 = la millor)"
    title="Posició en la Classificació Mundial de la Llibertat de Premsa (RSF)"
    seriesColors={{'España': '#b91c1c'}}
>
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.06 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.06 />
</LineChart>

A l'eix, un número més alt és una posició pitjor. Les bandes de fons marquen el partit del Govern central (<span style="color:#dc2626">PSOE</span> o <span style="color:#2563eb">PP</span>) només com a referència temporal: la classificació valora tot el país, no només el Govern. Cada edició es publica a la primavera i valora sobretot l'any anterior. El nombre de països classificats ha passat de {rsf_extremos[0]?.primer_n} el {rsf_extremos[0]?.primera_edicion} a {k_rsf[0]?.n_total}, de manera que les posicions dels primers anys no són del tot comparables.

<BarChart
    data={rsf_ue_ult}
    x=pais
    y=puntuacion
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Puntuació de RSF dels països de la UE, {k_rsf[0]?.anio} (0-100, més és millor)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

### Els cinc indicadors de RSF

Des del 2022 RSF desglossa la puntuació en cinc indicadors: **context polític** (pressions del poder polític i suport a la independència dels mitjans), **econòmic** (sostenibilitat dels mitjans, concentració, repartiment d'ajuts i publicitat pública), **marc legal** (lleis i la seva aplicació), **context social** (respecte social als periodistes, pressions de grups) i **seguretat** (agressions, amenaces, detencions). El {rsf_ind_ult[0]?.edicion}, la millor posició d'Espanya és en {rsf_ind_ult[0]?.indicador} (posició {rsf_ind_ult[0]?.puesto_mundial} del món) i la pitjor en {rsf_ind_ult.slice(-1)[0]?.indicador} (posició {rsf_ind_ult.slice(-1)[0]?.puesto_mundial}).

<LineChart
    data={rsf_ind}
    x=edicion
    y=puntuacion
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="punts 0-100 (més és millor)"
    title="Espanya en els indicadors de RSF"
/>

<DataTable data={rsf_ind_tabla} rows=all>
    <Column id=pais title="País" />
    <Column id=puesto title="Posició mundial" fmt='0' />
    <Column id=global title="Global" fmt='0.0' />
    <Column id=politico title="Polític" fmt='0.0' />
    <Column id=economico title="Econòmic" fmt='0.0' />
    <Column id=legislativo title="Marc legal" fmt='0.0' />
    <Column id=social title="Social" fmt='0.0' />
    <Column id=seguridad title="Seguretat" fmt='0.0' />
</DataTable>

### Edició a edició

Posició d'Espanya en cada edició i partit que governava l'1 de juliol de l'any que valora aquella edició. És una descripció del calendari, no una atribució: la valoració recull també l'actuació de comunitats, tribunals, empreses de mitjans i altres actors.

<DataTable data={rsf_gobiernos} rows=all>
    <Column id=edicion title="Edició" fmt='0' />
    <Column id=puesto_mundial title="Posició mundial" fmt='0' />
    <Column id=puesto_ue title="Posició a la UE" fmt='0' />
    <Column id=presidente title="President a 1 de juliol de l'any anterior" />
    <Column id=familia title="Partit" />
</DataTable>

## Risc per al pluralisme dels mitjans

El **Media Pluralism Monitor** (MPM) del Centre for Media Pluralism and Media Freedom (Institut Universitari Europeu, Florència) avalua amb un equip d'investigadors de cada país unes 200 preguntes agrupades en quatre àrees. El resultat és un **risc de 0 a 100 %: més alt és pitjor**. En l'edició MPM{mpm_esp_ult[0]?.edicion}, el risc global d'Espanya és del {formatNumber(mpm_esp_ult[0]?.riesgo_pct, 0)} % (banda {mpm_esp_ult[0]?.banda}).

<BarChart
    data={mpm_esp_ult.filter(d => d.orden_area > 0)}
    x=area
    y=riesgo_pct
    swapXY=true
    yFmt='0"%"'
    yMax=100
    title="Espanya: risc per àrea, MPM{mpm_esp_ult[0]?.edicion}"
    colorPalette={['#b45309']}
/>

- **Protecció fonamental**: llibertat d'expressió, dret a la informació, condicions i seguretat dels periodistes i independència del regulador.
- **Pluralitat del mercat**: transparència de la propietat, concentració, viabilitat econòmica dels mitjans i influència comercial en allò que publiquen.
- **Independència política**: control polític dels mitjans, independència dels mitjans públics, repartiment de la publicitat institucional i dels ajuts, autonomia editorial.
- **Inclusió social**: accés de minories, comunitats locals, dones i persones amb discapacitat, i alfabetització mediàtica.

### Espanya respecte a la mitjana de la UE

La mitjana de la UE és la mitjana simple dels 27 països que avui la formen, en les edicions en què el MPM els va avaluar tots. En l'edició MPM{mpm_esp_ue_ult[0]?.edicion}, Espanya tenia més risc que la mitjana en {mpm_esp_ue_ult.filter(d => d.orden_area > 0 && d.diferencia > 0).length} de les quatre àrees.

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
    yAxisTitle="risc %"
    title="Protecció fonamental"
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
    yAxisTitle="risc %"
    title="Pluralitat del mercat"
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
    yAxisTitle="risc %"
    title="Independència política"
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
    yAxisTitle="risc %"
    title="Inclusió social"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
</Grid>

El qüestionari canvia a cada edició, de manera que els salts de pocs punts entre edicions no sempre reflecteixen canvis reals. No hi va haver edicions el 2018 ni el 2019 (la MPM2020 cobreix el 2018 i el 2019).

<BarChart
    data={mpm_ue_ult}
    x=pais
    y=riesgo_pct
    series=grupo
    swapXY=true
    yFmt='0"%"'
    title="Risc global per al pluralisme a la UE, MPM{mpm_ue_ult[0]?.edicion} (més és pitjor)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

<DataTable data={mpm_esp} rows=all>
    <Column id=area title="Àrea" />
    <Column id=etiqueta_edicion title="Edició" />
    <Column id=riesgo_pct title="Risc (%)" fmt='0' />
    <Column id=banda title="Banda" />
    <Column id=puesto_ue title="Posició a la UE (1 = menys risc)" fmt='0' />
</DataTable>

## Censura, assetjament i biaix segons V-Dem

El projecte **V-Dem** (Universitat de Göteborg) demana cada any a diversos experts per país que valorin, entre altres coses, si el Govern intenta censurar la premsa, si s'assetja periodistes, si els mitjans s'autocensuren i si tenen biaix contra l'oposició. Amb un model estadístic ho converteix en puntuacions comparables entre països i anys, i ho resumeix en un índex de llibertat d'expressió de 0 a 100.

<LineChart
    data={vdem_ref}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (més és millor)"
    title="Índex de llibertat d'expressió i fonts alternatives d'informació (V-Dem)"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569'}}
/>

<LineChart
    data={vdem_esp.filter(d => d.orden_indicador > 1 && d.pais === 'España')}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="escala de V-Dem (més alt = més llibertat)"
    title="Espanya: indicadors de mitjans de V-Dem des del 1976"
/>

Aquests quatre indicadors són en l'escala del model de V-Dem (aproximadament de -4 a +4): **com més alt, més llibertat** (menys censura, menys assetjament, menys autocensura, menys biaix). El {vdem_ult[0]?.anio}:

<DataTable data={vdem_ult} rows=all>
    <Column id=indicador title="Indicador" />
    <Column id=espana title="Espanya" fmt='0.00' />
    <Column id=ue title="Mitjana de la UE" fmt='0.00' />
    <Column id=puesto_ue title="Posició d'Espanya a la UE" fmt='0' />
</DataTable>

## Alertes del Consell d'Europa

La **Plataforma del Consell d'Europa per a la protecció del periodisme i la seguretat dels periodistes** publica alertes sobre amenaces greus a la llibertat de premsa (agressions, detencions, assetjament, demandes abusives, pressions polítiques) que registren les seves organitzacions sòcies, com la Federació Europea de Periodistes o RSF. Els estats poden respondre a cada alerta. Entre el {coe_resumen[0]?.desde} i el {coe_resumen[0]?.hasta} es van publicar {coe_resumen[0]?.total_esp} alertes sobre Espanya, {coe_resumen[0]?.sin_respuesta_esp} de les quals sense resposta de l'Estat. Per comparar països de mida diferent es compten per cada 10 milions d'habitants.

<LineChart
    data={coe_esp}
    x=anio
    y=alertas_por_10m_hab
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="alertes per 10 milions d'habitants"
    title="Alertes publicades per any, per 10 milions d'habitants"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (27)': '#94a3b8'}}
/>

<BarChart
    data={coe_ue_ult}
    x=pais
    y=alertas_10m_anuales
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Alertes l'any per 10 milions d'habitants, mitjana {coe_periodo[0]?.desde}-{coe_periodo[0]?.hasta}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

Un recompte baix no vol dir necessàriament menys problemes: depèn de quins casos decideixen registrar les organitzacions sòcies i de quanta presència tenen a cada país.

## Metodologia i fonts

- **Classificació Mundial de la Llibertat de Premsa**, [Reporters Sense Fronteres](https://rsf.org/es/clasificacion), fitxers CSV de cada edició (2002-2010 i des del 2012; la del 2012 cobreix el 2011-2012). Es reprodueixen tal qual la posició i la puntuació oficials, citant RSF, sense mitjanes ni càlculs propis (les condicions d'ús de rsf.org reserven tots els drets). Les puntuacions de tres etapes **no són comparables**: 2002-2012 (escala sense límit, 0 = millor), 2013-2021 (0-100) i des del 2022 (nova metodologia amb cinc indicadors). La posició a la UE és només l'ordre de les posicions oficials entre els 27 països que avui la formen.
- **Media Pluralism Monitor**, [Centre for Media Pluralism and Media Freedom](https://cmpf.eui.eu/) (Institut Universitari Europeu), llicència CC BY 4.0. Edicions MPM2016, MPM2017 i MPM2020 en endavant (no hi va haver MPM2018 ni MPM2019); l'edició N valora l'any N-1. Edicions passades transcrites dels informes de país en PDF del [repositori Cadmus](https://cadmus.eui.eu/) i l'última de les [fitxes per país](https://cmpf.eui.eu/mpm-2025-results/) del CMPF. A la MPM2025 només es disposa de la dada d'Espanya. Risc global: el publicat pel CMPF o, en les edicions que no el publicaven, la mitjana simple de les quatre àrees (com el calcula el CMPF des del 2022). Fins a la MPM2024 hi havia tres bandes de risc (baix, mitjà, alt) i des de la MPM2025, sis.
- **V-Dem** (Varieties of Democracy, Universitat de Göteborg), via [Our World in Data](https://ourworldindata.org/grapher/key-media-freedoms): censura governamental (v2mecenefm), assetjament a periodistes (v2meharjrn), autocensura (v2meslfcen) i biaix dels mitjans (v2mebias), estimació central del model de mesura; i [índex de llibertat d'expressió](https://ourworldindata.org/grapher/freedom-of-expression-index) (0-1, multiplicat per 100). Llicències CC BY-SA 4.0 (V-Dem) i CC BY 4.0 (OWID). Mitjana de la UE: mitjana simple dels països membres actuals, només en els anys amb dada d'almenys el 90 %.
- **Alertes**, [Plataforma del Consell d'Europa per a la protecció del periodisme i la seguretat dels periodistes](https://fom.coe.int/), recompte per país i any des del 2015 (any de l'alerta segons el portal), amb la població mitjana anual d'Eurostat. L'estat de cada alerta (resposta, resolta) és el de la data de descàrrega.
- Cap d'aquests índexs no mesura audiències ni qualitat dels mitjans. Per als diners públics que reben els mitjans, vegeu [Diners públics als mitjans](/ca/medios/dinero-publico/).
