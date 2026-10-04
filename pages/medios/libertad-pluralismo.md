---
title: Libertad de prensa y pluralismo
description: "Dónde está España en los índices internacionales de libertad de prensa y pluralismo de los medios (Reporters sans frontières, Media Pluralism Monitor, V-Dem y la plataforma del Consejo de Europa) y cómo ha evolucionado frente a la UE y los países de referencia."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# <span aria-hidden="true">🗞️</span> Libertad de prensa y pluralismo

¿Pueden los periodistas trabajar en España sin presiones y hay variedad de medios independientes? Varias organizaciones internacionales lo evalúan cada año con **índices comparables entre países**. Esta página reúne los cuatro principales y sitúa a España entre los **27 países de la UE**: la Clasificación Mundial de la Libertad de Prensa de Reporters sans frontières, el Media Pluralism Monitor del Instituto Universitario Europeo, los indicadores de medios de V-Dem y las alertas de la plataforma del Consejo de Europa para la protección del periodismo.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Cómo leer esta página</p>
<p class="mb-1">Son <b>valoraciones de esas organizaciones</b>, hechas con cuestionarios a periodistas, académicos y expertos, no mediciones directas. Cada una mira cosas distintas: RSF, las condiciones para ejercer el periodismo; el Media Pluralism Monitor, los riesgos para el pluralismo (leyes, concentración de la propiedad, independencia, acceso); V-Dem, la censura, el acoso y el sesgo; el Consejo de Europa, casos concretos de amenazas que registran organizaciones de periodistas.</p>
<p class="mb-0">Los métodos cambian con los años y las diferencias de pocos puntos o puestos <b>no suelen ser significativas</b>. Lo que importa es la tendencia y la distancia con la UE.</p>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if k_rsf.length && k_mpm.length && k_vdem.length && k_coe.length}
    <KpiCard
        title="Clasificación de RSF"
        value={k_rsf[0].valor}
        formattedValue={'Puesto ' + formatNumber(k_rsf[0].valor, 0)}
        period={`${k_rsf[0].anio} · de ${k_rsf[0].n_total} países; ${k_rsf[0].puesto_ue}.º de ${k_rsf[0].n_ue} en la UE`}
        change={-(k_rsf[0].cambio)}
        changeUnit=" puestos"
        changePeriod={`vs ${k_rsf[0].anio_anterior}`}
        direction="positive-up"
        source="Reporters sans frontières"
        sparklineData={serie_esp.filter(d => d.indice_id === 'rsf_puesto').map(d => -d.valor)}
    />
    <KpiCard
        title="Riesgo para el pluralismo"
        value={k_mpm[0].valor}
        formattedValue={formatNumber(k_mpm[0].valor, 0) + ' %'}
        period={`MPM${k_mpm[0].anio} · ${k_mpm[0].puesto_ue ? k_mpm[0].puesto_ue + '.º de ' + k_mpm[0].n_ue + ' en la UE (1 = menor riesgo)' : 'más alto = peor'}`}
        change={k_mpm[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs MPM${k_mpm[0].anio_anterior}`}
        direction="positive-down"
        source="Media Pluralism Monitor (EUI)"
        sparklineData={serie_esp.filter(d => d.indice_id === 'mpm_total').map(d => d.valor)}
    />
    <KpiCard
        title="Libertad de expresión (V-Dem)"
        value={k_vdem[0].valor}
        formattedValue={formatNumber(k_vdem[0].valor, 1) + ' / 100'}
        period={`${k_vdem[0].anio} · ${k_vdem[0].puesto_ue}.º de ${k_vdem[0].n_ue} en la UE (media UE ${formatNumber(k_vdem[0].valor_ue, 1)})`}
        change={k_vdem[0].cambio}
        changeUnit=" pts"
        changePeriod={`vs ${k_vdem[0].anio_anterior}`}
        direction="positive-up"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indice_id === 'vdem_libertad_expresion' && d.anio >= 1990).map(d => d.valor)}
    />
    <KpiCard
        title="Alertas del Consejo de Europa"
        value={k_coe[0].valor}
        formattedValue={formatNumber(k_coe[0].valor, 2)}
        unit="por 10 millones de hab."
        period={`${k_coe[0].anio} · ${k_coe[0].n_total} alertas; media UE ${formatNumber(k_coe[0].valor_ue, 2)}`}
        change={k_coe[0].cambio}
        changeUnit=""
        changePeriod={`vs ${k_coe[0].anio_anterior}`}
        direction="positive-down"
        source="Consejo de Europa"
        sparklineData={serie_esp.filter(d => d.indice_id === 'coe_alertas').map(d => d.valor)}
    />
    {/if}
</div>

## Clasificación Mundial de la Libertad de Prensa

**Reporters sans frontières** (RSF) clasifica cada año unos 180 países según las condiciones para ejercer el periodismo, a partir de un cuestionario a periodistas, académicos y defensores de derechos humanos y de su propio recuento de agresiones a periodistas. España ocupa el **puesto {k_rsf[0]?.valor} de {k_rsf[0]?.n_total}** en la edición de {k_rsf[0]?.anio} y el {k_rsf[0]?.puesto_ue}.º de los {k_rsf[0]?.n_ue} países de la UE. Su mejor puesto fue el {rsf_extremos[0]?.mejor_puesto} (edición {rsf_extremos[0]?.mejor_edicion}) y el peor, el {rsf_extremos[0]?.peor_puesto} ({rsf_extremos[0]?.peor_edicion}).

<LineChart
    data={rsf_ref}
    x=edicion
    y=puesto_mundial
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="puesto mundial (1 = el mejor)"
    title="Puesto en la Clasificación Mundial de la Libertad de Prensa (RSF)"
    seriesColors={{'España': '#b91c1c'}}
>
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.06 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.06 />
</LineChart>

En el eje, un número más alto es una posición peor. Las bandas de fondo marcan el partido del Gobierno central (<span style="color:#dc2626">PSOE</span> o <span style="color:#2563eb">PP</span>) solo como referencia temporal: la clasificación valora a todo el país, no solo al Gobierno. Cada edición se publica en primavera y valora sobre todo el año anterior. El número de países clasificados ha pasado de {rsf_extremos[0]?.primer_n} en {rsf_extremos[0]?.primera_edicion} a {k_rsf[0]?.n_total}, así que los puestos de los primeros años no son del todo comparables.

<BarChart
    data={rsf_ue_ult}
    x=pais
    y=puntuacion
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Puntuación de RSF de los países de la UE, {k_rsf[0]?.anio} (0-100, más es mejor)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

### Los cinco indicadores de RSF

Desde 2022 RSF desglosa la puntuación en cinco indicadores: **contexto político** (presiones del poder político y apoyo a la independencia de los medios), **económico** (sostenibilidad de los medios, concentración, reparto de ayudas y publicidad pública), **marco legal** (leyes y su aplicación), **contexto social** (respeto social a los periodistas, presiones de grupos) y **seguridad** (agresiones, amenazas, detenciones). En {rsf_ind_ult[0]?.edicion}, el mejor puesto de España es en {rsf_ind_ult[0]?.indicador} ({rsf_ind_ult[0]?.puesto_mundial}.º del mundo) y el peor en {rsf_ind_ult.slice(-1)[0]?.indicador} ({rsf_ind_ult.slice(-1)[0]?.puesto_mundial}.º).

<LineChart
    data={rsf_ind}
    x=edicion
    y=puntuacion
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="puntos 0-100 (más es mejor)"
    title="España en los indicadores de RSF"
/>

<DataTable data={rsf_ind_tabla} rows=all>
    <Column id=pais title="País" />
    <Column id=puesto title="Puesto mundial" fmt='0' />
    <Column id=global title="Global" fmt='0.0' />
    <Column id=politico title="Político" fmt='0.0' />
    <Column id=economico title="Económico" fmt='0.0' />
    <Column id=legislativo title="Marco legal" fmt='0.0' />
    <Column id=social title="Social" fmt='0.0' />
    <Column id=seguridad title="Seguridad" fmt='0.0' />
</DataTable>

### Edición a edición

Puesto de España en cada edición y partido que gobernaba el 1 de julio del año que valora esa edición. Es una descripción del calendario, no una atribución: la valoración recoge también la actuación de comunidades, tribunales, empresas de medios y otros actores.

<DataTable data={rsf_gobiernos} rows=all>
    <Column id=edicion title="Edición" fmt='0' />
    <Column id=puesto_mundial title="Puesto mundial" fmt='0' />
    <Column id=puesto_ue title="Puesto en la UE" fmt='0' />
    <Column id=presidente title="Presidente a 1 de julio del año anterior" />
    <Column id=familia title="Partido" />
</DataTable>

## Riesgo para el pluralismo de los medios

El **Media Pluralism Monitor** (MPM) del Centre for Media Pluralism and Media Freedom (Instituto Universitario Europeo, Florencia) evalúa con un equipo de investigadores de cada país unas 200 preguntas agrupadas en cuatro áreas. El resultado es un **riesgo de 0 a 100 %: más alto es peor**. En la edición MPM{mpm_esp_ult[0]?.edicion}, el riesgo global de España es del {formatNumber(mpm_esp_ult[0]?.riesgo_pct, 0)} % (banda {mpm_esp_ult[0]?.banda}).

<BarChart
    data={mpm_esp_ult.filter(d => d.orden_area > 0)}
    x=area
    y=riesgo_pct
    swapXY=true
    yFmt='0"%"'
    yMax=100
    title="España: riesgo por área, MPM{mpm_esp_ult[0]?.edicion}"
    colorPalette={['#b45309']}
/>

- **Protección fundamental**: libertad de expresión, derecho a la información, condiciones y seguridad de los periodistas e independencia del regulador.
- **Pluralidad del mercado**: transparencia de la propiedad, concentración, viabilidad económica de los medios e influencia comercial en lo que publican.
- **Independencia política**: control político de los medios, independencia de los medios públicos, reparto de la publicidad institucional y de las ayudas, autonomía editorial.
- **Inclusión social**: acceso de minorías, comunidades locales, mujeres y personas con discapacidad, y alfabetización mediática.

### España frente a la media de la UE

La media de la UE es la media simple de los 27 países que hoy la forman, en las ediciones en las que el MPM los evaluó a todos. En la edición MPM{mpm_esp_ue_ult[0]?.edicion}, España tenía más riesgo que la media en {mpm_esp_ue_ult.filter(d => d.orden_area > 0 && d.diferencia > 0).length} de las cuatro áreas.

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
    yAxisTitle="riesgo %"
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
    yAxisTitle="riesgo %"
    title="Pluralidad del mercado"
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
    yAxisTitle="riesgo %"
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
    yAxisTitle="riesgo %"
    title="Inclusión social"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
</Grid>

El cuestionario cambia en cada edición, así que los saltos de pocos puntos entre ediciones no siempre reflejan cambios reales. No hubo ediciones en 2018 ni 2019 (la MPM2020 cubre 2018 y 2019).

<BarChart
    data={mpm_ue_ult}
    x=pais
    y=riesgo_pct
    series=grupo
    swapXY=true
    yFmt='0"%"'
    title="Riesgo global para el pluralismo en la UE, MPM{mpm_ue_ult[0]?.edicion} (más es peor)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

<DataTable data={mpm_esp} rows=all>
    <Column id=area title="Área" />
    <Column id=etiqueta_edicion title="Edición" />
    <Column id=riesgo_pct title="Riesgo (%)" fmt='0' />
    <Column id=banda title="Banda" />
    <Column id=puesto_ue title="Puesto en la UE (1 = menor riesgo)" fmt='0' />
</DataTable>

## Censura, acoso y sesgo según V-Dem

El proyecto **V-Dem** (Universidad de Gotemburgo) pide cada año a varios expertos por país que valoren, entre otras cosas, si el Gobierno intenta censurar a la prensa, si se acosa a periodistas, si los medios se autocensuran y si tienen sesgo contra la oposición. Con un modelo estadístico lo convierte en puntuaciones comparables entre países y años, y lo resume en un índice de libertad de expresión de 0 a 100.

<LineChart
    data={vdem_ref}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (más es mejor)"
    title="Índice de libertad de expresión y fuentes alternativas de información (V-Dem)"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569'}}
/>

<LineChart
    data={vdem_esp.filter(d => d.orden_indicador > 1 && d.pais === 'España')}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="escala de V-Dem (más alto = más libertad)"
    title="España: indicadores de medios de V-Dem desde 1976"
/>

Estos cuatro indicadores están en la escala del modelo de V-Dem (más o menos de -4 a +4): **cuanto más alto, más libertad** (menos censura, menos acoso, menos autocensura, menos sesgo). En {vdem_ult[0]?.anio}:

<DataTable data={vdem_ult} rows=all>
    <Column id=indicador title="Indicador" />
    <Column id=espana title="España" fmt='0.00' />
    <Column id=ue title="Media de la UE" fmt='0.00' />
    <Column id=puesto_ue title="Puesto de España en la UE" fmt='0' />
</DataTable>

## Alertas del Consejo de Europa

La **Plataforma del Consejo de Europa para la protección del periodismo y la seguridad de los periodistas** publica alertas sobre amenazas graves a la libertad de prensa (agresiones, detenciones, acoso, demandas abusivas, presiones políticas) que registran sus organizaciones socias, como la Federación Europea de Periodistas o RSF. Los Estados pueden responder a cada alerta. Entre {coe_resumen[0]?.desde} y {coe_resumen[0]?.hasta} se publicaron {coe_resumen[0]?.total_esp} alertas sobre España, {coe_resumen[0]?.sin_respuesta_esp} de ellas sin respuesta del Estado. Para comparar países de tamaño distinto se cuentan por cada 10 millones de habitantes.

<LineChart
    data={coe_esp}
    x=anio
    y=alertas_por_10m_hab
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="alertas por 10 millones de habitantes"
    title="Alertas publicadas por año, por 10 millones de habitantes"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (27)': '#94a3b8'}}
/>

<BarChart
    data={coe_ue_ult}
    x=pais
    y=alertas_10m_anuales
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Alertas al año por 10 millones de habitantes, media {coe_periodo[0]?.desde}-{coe_periodo[0]?.hasta}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

Un recuento bajo no significa necesariamente menos problemas: depende de qué casos deciden registrar las organizaciones socias y de cuánta presencia tienen en cada país.

## Metodología y fuentes

- **Clasificación Mundial de la Libertad de Prensa**, [Reporters sans frontières](https://rsf.org/es/clasificacion), ficheros CSV de cada edición (2002-2010 y desde 2012; la de 2012 cubre 2011-2012). Se reproducen tal cual el puesto y la puntuación oficiales, citando a RSF, sin medias ni cálculos propios (las condiciones de uso de rsf.org reservan todos los derechos). Las puntuaciones de tres etapas **no son comparables**: 2002-2012 (escala sin tope, 0 = mejor), 2013-2021 (0-100) y desde 2022 (nueva metodología con cinco indicadores). El puesto en la UE es solo el orden de los puestos oficiales entre los 27 países que hoy la forman.
- **Media Pluralism Monitor**, [Centre for Media Pluralism and Media Freedom](https://cmpf.eui.eu/) (Instituto Universitario Europeo), licencia CC BY 4.0. Ediciones MPM2016, MPM2017 y MPM2020 en adelante (no hubo MPM2018 ni MPM2019); la edición N valora el año N-1. Ediciones pasadas transcritas de los informes país en PDF del [repositorio Cadmus](https://cadmus.eui.eu/) y la última de las [fichas por país](https://cmpf.eui.eu/mpm-2025-results/) del CMPF. En la MPM2025 solo se dispone del dato de España. Riesgo global: el publicado por el CMPF o, en las ediciones que no lo publicaban, la media simple de las cuatro áreas (como lo calcula el CMPF desde 2022). Hasta la MPM2024 había tres bandas de riesgo (bajo, medio, alto) y desde la MPM2025, seis.
- **V-Dem** (Varieties of Democracy, Universidad de Gotemburgo), vía [Our World in Data](https://ourworldindata.org/grapher/key-media-freedoms): censura gubernamental (v2mecenefm), acoso a periodistas (v2meharjrn), autocensura (v2meslfcen) y sesgo de los medios (v2mebias), estimación central del modelo de medida; e [índice de libertad de expresión](https://ourworldindata.org/grapher/freedom-of-expression-index) (0-1, multiplicado por 100). Licencias CC BY-SA 4.0 (V-Dem) y CC BY 4.0 (OWID). Media de la UE: media simple de los países miembros actuales, solo en los años con dato de al menos el 90 %.
- **Alertas**, [Plataforma del Consejo de Europa para la protección del periodismo y la seguridad de los periodistas](https://fom.coe.int/), recuento por país y año desde 2015 (año de la alerta según el portal), con la población media anual de Eurostat. El estado de cada alerta (respondida, resuelta) es el de la fecha de descarga.
- Ninguno de estos índices mide audiencias ni calidad de los medios. Para el dinero público que reciben los medios, ver [Dinero público en los medios](/medios/dinero-publico/).
