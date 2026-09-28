---
title: Transparencia
description: "Administraciones que no cumplen sus obligaciones legales de publicar o remitir información: quiénes son, dónde están y quién gobernaba cuando vencía el plazo."
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../src/lib/utils.js';
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

# 🔍 Transparencia: quién no rinde cuentas

Las administraciones públicas están **obligadas por ley** a remitir cada año cierta información económica. Esta página recoge, con datos oficiales, qué administraciones no lo hacen, dónde están y **quién gobernaba cuando vencía el plazo**.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Cómo leer esta página</p>
<p class="mb-1">Todos los datos son registros oficiales y verificables. Que una administración aparezca aquí significa que <b>la información no consta en la fuente oficial</b> en la fecha de publicación: puede haberla remitido tarde o estar en trámite, y conviene consultar la fuente antes de sacar conclusiones sobre un caso concreto.</p>
<p class="mb-0">El incumplimiento se atribuye al gobierno <b>en funciones el día del plazo legal</b>, no al actual. Y como los municipios pequeños, con menos medios, incumplen mucho más, las comparaciones entre partidos se <b>ajustan por tamaño de población</b>.</p>
</div>

## Liquidación del presupuesto municipal

Cada ayuntamiento debe remitir al Ministerio de Hacienda la liquidación de su presupuesto (lo que realmente ingresó y gastó) **antes del 31 de marzo del año siguiente** (art. 15.3 de la Orden HAP/2105/2012, que desarrolla la Ley Orgánica 2/2012 de Estabilidad Presupuestaria). Sin esa información no se puede saber en qué gasta el dinero público. (Álava y Navarra quedan fuera de este indicador por su régimen foral; ver la metodología.)

<Grid cols=3>
    <KpiCard
        title="Ayuntamientos sin liquidación {ultimo[0]?.anio}"
        value={resumen[0]?.incumplen}
        formattedValue={formatNumber(resumen[0]?.incumplen, 0)}
        period="{formatNumber(100 * resumen[0]?.incumplen / resumen[0]?.total, 1)} % de {formatNumber(resumen[0]?.total, 0)} ayuntamientos"
        source="Ministerio de Hacienda (CONPREL)"
        sparklineData={liq_serie.map(d => d.incumplen)}
    />
    <KpiCard
        title="Vecinos afectados"
        value={resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(resumen[0]?.afectados_por_1000, 1)}
        unit="por cada 1.000 hab."
        period="{formatNumber(resumen[0]?.poblacion_afectada, 0)} vecinos en total; {formatNumber(resumen[0]?.grandes, 0)} de esos ayuntamientos tienen más de 20.000 habitantes"
        sparklineData={liq_serie.map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Tres años o más seguidos"
        value={resumen_rachas[0]?.tres_o_mas}
        formattedValue={formatNumber(resumen_rachas[0]?.tres_o_mas, 0)}
        period="ayuntamientos que llevan al menos tres ejercicios sin remitirla"
    />
</Grid>

### Los que no la remitieron en {ultimo[0]?.anio}

```sql lista
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    coalesce(r.anios_seguidos, 0) AS anios_seguidos,
    t.alcalde_en_plazo,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/territorios/municipios?m=' || t.cod_mun AS enlace
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
LEFT JOIN ${rachas} r USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.anio = (SELECT anio FROM ${ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=anios_seguidos title="Años seguidos sin remitir" contentType=colorscale colorMax=10 />
    <Column id=lista_en_plazo title="Lista del alcalde en el plazo" />
    <Column id=familia_en_plazo title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de más a menos habitantes. «En el plazo» = el 31 de marzo de {ultimo[0]?.anio + 1}, fecha límite para remitir la liquidación de {ultimo[0]?.anio}.</p>

### Por territorio

```sql por_ccaa
SELECT
    c.nombre AS comunidad,
    c.ruta,
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    title="Ayuntamientos que no remitieron la liquidación de {ultimo[0]?.anio}, por provincia"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: 'No la remitieron', fmt: 'pct1'},
        {id: 'incumplen', title: 'Ayuntamientos', fmt: 'num0'},
        {id: 'municipios', title: 'De un total de', fmt: 'num0'}
    ]}
/>

<DataTable data={por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=incumplen title="No la remitieron" fmt=num0 />
    <Column id=municipios title="Ayuntamientos" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Por partido en el gobierno

Liquidaciones no remitidas entre {ultimo[0]?.anio - 11} y {ultimo[0]?.anio} según la familia política del alcalde en el plazo. El **ratio ajustado** compara cada partido con lo que cabría esperar de municipios **del mismo tamaño, en la misma comunidad y el mismo año**: 1 = lo esperable; 2 = el doble; 0,5 = la mitad. Si el intervalo de confianza incluye el 1, la diferencia puede deberse al azar.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>Lo que dicen los datos:</b> una vez descontados el tamaño del municipio y la comunidad autónoma, la mayoría de los partidos queda muy cerca de 1. Lo que más explica que un ayuntamiento no remita sus cuentas es que sea pequeño y dónde esté, más que quién lo gobierne.
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
    title="Incumplimiento ajustado por tamaño y comunidad (1 = lo esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={por_familia} rows=all>
    <Column id=familia title="Familia política del alcalde en el plazo" />
    <Column id=ayuntamientos_anio title="Ayuntamientos × año" fmt=num0 />
    <Column id=incumplimientos title="Liquidaciones no remitidas" fmt=num0 />
    <Column id=tasa title="Tasa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustado solo por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustado por tamaño y comunidad" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Solo familias con al menos 300 ayuntamientos-año. «Sin detalle en la fuente» agrupa alcaldías cuya lista figura en el registro oficial con una etiqueta genérica de coalición; «Independientes y locales», agrupaciones de electores. Las familias gobiernan municipios muy distintos (tamaño, comunidad, recursos): el ratio ajusta el tamaño, pero no otras diferencias.</p>

### Evolución

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
    title="Ayuntamientos que no remitieron la liquidación, por tamaño"
/>

## Cuenta General y control interno (Tribunal de Cuentas)

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

La **Cuenta General** recoge todas las cuentas del ayuntamiento (presupuesto, balance, resultados, tesorería). Una vez aprobada por el Pleno, debe enviarse al **Tribunal de Cuentas** (o al órgano de control externo de la comunidad) **antes del 15 de octubre del año siguiente** (arts. 212.5 y 223.2 del [texto refundido de la Ley de Haciendas Locales](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)). Además, cada ayuntamiento debe remitir **antes del 30 de abril** la información de **control interno** (acuerdos adoptados contra los reparos del interventor y principales anomalías de ingresos; art. 218.3 de la misma ley) y, **antes de que acabe febrero**, la **relación anual de contratos** o, si no hubo, una certificación negativa (art. 335 de la Ley de Contratos del Sector Público). La plataforma no incluye País Vasco ni Navarra, que tienen sus propios órganos de control externo.

{#if tcu_cobertura[0]?.provincias < 40}

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-3 text-sm text-gray-700 dark:text-gray-300">
<b>En preparación.</b> Los datos se están descargando poco a poco de la plataforma del Tribunal de Cuentas para no sobrecargarla, y esta sección se publicará cuando cubra toda España (sin País Vasco ni Navarra). Con solo algunas provincias las cifras no serían representativas.
</div>

{:else}

{#if tcu_cobertura[0]?.parcial}
<div class="not-prose rounded-lg border border-amber-200 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-800 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
<b>Datos parciales:</b> la descarga desde la plataforma del Tribunal de Cuentas se hace poco a poco para no sobrecargarla. Por ahora esta sección recoge <b>datos de {tcu_cobertura[0]?.provincias} provincias</b> ({formatNumber(tcu_cobertura[0]?.ayuntamientos, 0)} ayuntamientos); las cifras no son todavía representativas de España.
</div>
{/if}

<Grid cols=3>
    <KpiCard
        title="Sin Cuenta General {tcu_ultimo[0]?.cg}"
        value={tcu_resumen[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen[0]?.no_rendida, 0)}
        period="{formatNumber(100 * tcu_resumen[0]?.no_rendida / tcu_resumen[0]?.total, 1)} % de {formatNumber(tcu_resumen[0]?.total, 0)} ayuntamientos; no consta rendida a {tcu_cobertura[0]?.extraccion}"
        source="Tribunal de Cuentas (rendiciondecuentas.es)"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'cuenta_general').map(d => d.no_rendida)}
    />
    <KpiCard
        title="Enviada dentro de plazo"
        value={tcu_resumen[0]?.en_plazo}
        formattedValue="{formatNumber(100 * tcu_resumen[0]?.en_plazo / tcu_resumen[0]?.total, 1)} %"
        period="{formatNumber(tcu_resumen[0]?.en_plazo, 0)} ayuntamientos antes del 15/10/{tcu_ultimo[0]?.cg + 1}; {formatNumber(tcu_resumen[0]?.fuera_plazo, 0)} la enviaron más tarde"
    />
    <KpiCard
        title="Sin control interno {tcu_ultimo[0]?.ci}"
        value={tcu_resumen_ci[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen_ci[0]?.no_rendida, 0)}
        period="{formatNumber(100 * tcu_resumen_ci[0]?.no_rendida / tcu_resumen_ci[0]?.total, 1)} % de {formatNumber(tcu_resumen_ci[0]?.total, 0)} ayuntamientos (plazo: 30/04/{tcu_ultimo[0]?.ci + 1})"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'control_interno').map(d => d.no_rendida)}
    />
</Grid>

### Los que no han rendido la Cuenta General de {tcu_ultimo[0]?.cg}

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
    '/territorios/municipios?m=' || t.cod_mun AS enlace
FROM cg t
JOIN historial h USING (cod_mun)
LEFT JOIN ci USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.ejercicio = (SELECT cg FROM ${tcu_ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={tcu_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=ejercicios_sin_rendir title="Ejercicios sin Cuenta General" />
    <Column id=control_interno title="Control interno {tcu_ultimo[0]?.ci}" />
    <Column id=lista_en_plazo title="Lista del alcalde en el plazo" />
    <Column id=familia_en_plazo title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de más a menos habitantes. «No consta» = la plataforma no la muestra como rendida a fecha de extracción ({tcu_cobertura[0]?.extraccion}); puede haberse enviado después o estar en trámite. «En el plazo» = el 15 de octubre de {tcu_ultimo[0]?.cg + 1}. La columna de ejercicios incluye todos los años disponibles con el plazo vencido.</p>

### Por comunidad autónoma

```sql tcu_por_ccaa
SELECT
    c.nombre AS comunidad,
    c.ruta,
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
    <Column id=comunidad title="Comunidad" />
    <Column id=ayuntamientos title="Ayuntamientos" fmt=num0 />
    <Column id=pct_cg title="Sin Cuenta General {tcu_ultimo[0]?.cg}" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_cg_en_plazo title="Cuenta General en plazo" fmt=pct1 />
    <Column id=pct_ci title="Sin control interno {tcu_ultimo[0]?.ci}" fmt=pct1 />
    <Column id=pct_ct title="Sin relación de contratos {tcu_ultimo[0]?.ct}" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Relación de contratos: «sin» significa que no consta ni la relación ni la certificación negativa de no haber celebrado contratos.</p>

### Por partido en el gobierno

Cuentas Generales no rendidas en todos los ejercicios disponibles, según la familia política del alcalde el 15 de octubre del año siguiente. El **ratio ajustado** compara cada partido con lo esperable en municipios **del mismo tamaño, la misma comunidad y el mismo ejercicio** (1 = lo esperable). Si el intervalo de confianza incluye el 1, la diferencia puede deberse al azar.

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
    title="Cuenta General no rendida, ajustada por tamaño y comunidad (1 = lo esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={tcu_por_familia} rows=all>
    <Column id=familia title="Familia política del alcalde en el plazo" />
    <Column id=ayuntamientos_anio title="Ayuntamientos × ejercicio" fmt=num0 />
    <Column id=incumplimientos title="Cuentas no rendidas" fmt=num0 />
    <Column id=tasa title="Tasa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustado solo por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustado por tamaño y comunidad" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Solo familias con al menos 300 ayuntamientos-ejercicio. El ratio ajusta el tamaño y la comunidad, pero no otras diferencias entre los municipios que gobierna cada familia.</p>

{:else}

<p class="text-sm text-gray-500">Todavía no hay datos suficientes (al menos 300 ayuntamientos-ejercicio por familia política) para comparar partidos con garantías.</p>

{/if}

{/if}

---

## Retención de fondos del Estado por no remitir información

Cuando un ayuntamiento no envía a Hacienda la **liquidación de su presupuesto**, el Ministerio le **retiene las entregas mensuales de la participación en los tributos del Estado** (la principal transferencia que recibe del Estado) hasta que la remite (art. 36 de la Ley 2/2011, de Economía Sostenible). Desde 2022 lo mismo ocurre si no envía el **presupuesto del año** antes del 1 de julio o las **líneas fundamentales del presupuesto del año siguiente** antes del 15 de septiembre (disposición adicional 87ª de la Ley 22/2021). Hacienda publica cada mes la lista de ayuntamientos retenidos; aquí se reúnen todas desde octubre de 2016. (No hay ayuntamientos vascos ni navarros: por su régimen foral no reciben esta participación por la vía común.)

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
        title="Ayuntamientos retenidos en {pie_ultimo[0]?.mes}"
        value={pie_resumen[0]?.retenidos_mes}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_mes, 0)}
        period="{formatNumber(pie_resumen[0]?.retenidos_liquidacion, 0)} de ellos por no remitir la liquidación"
        source="Ministerio de Hacienda (OVEELL)"
        sparklineData={pie_serie_12m.map(d => d.retenidos_mes)}
    />
    <KpiCard
        title="Retenido en los últimos 12 meses"
        value={pie_resumen[0]?.eur_12m_real}
        formattedValue={formatNumber(pie_resumen[0]?.eur_12m_real / 1e6, 1)}
        unit="M€ de {base_deflactor[0]?.anio_base}"
        period="participación en tributos del Estado no transferida mientras duraba el incumplimiento ({formatNumber(pie_resumen[0]?.eur_12m / 1e6, 1)} M€ corrientes)"
        source="Entregas a cuenta mensuales"
        sparklineData={pie_serie_12m.filter(d => d.eur_12m_real != null).map(d => d.eur_12m_real)}
    />
    <KpiCard
        title="Ayuntamientos retenidos en el último año"
        value={pie_resumen[0]?.retenidos_12m}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_12m, 0)}
        period="al menos un mes en los últimos 12"
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
    title="Ayuntamientos con la participación retenida cada mes, por motivo"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<BarChart
    data={pie_serie}
    x=periodo
    y=importe_real
    series=motivo
    type=stacked
    yFmt=eur1m
    title="Euros retenidos cada mes (euros de {base_deflactor[0]?.anio_base}, descontada la inflación)"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<p class="text-xs text-gray-500">Cada lista mensual es una foto: quién sigue retenido ese mes. La lista de la liquidación se renueva hacia junio (con la liquidación de dos años antes) y se va vaciando a medida que los ayuntamientos la envían; la del presupuesto aparece en noviembre y diciembre, y la de las líneas fundamentales de diciembre a agosto. No hay importes para los meses en que Hacienda no publicó el Excel de entregas a cuenta (marzo y octubre de 2019, noviembre de 2020 a enero de 2021 y febrero de 2022). Como en el resto de la web, los importes se expresan descontada la inflación, en euros de {base_deflactor[0]?.anio_base} (IPC medio anual del INE; el año en curso, con la media de los meses publicados).</p>

### Retenidos en {pie_ultimo[0]?.mes}

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
    '/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pie t
LEFT JOIN ${pie_importe_real} ir ON ir.cod_mun = t.cod_mun AND ir.seccion = t.seccion AND ir.anio = CAST(t.anio AS INTEGER)
LEFT JOIN ${pie_rachas} r ON r.cod_mun = t.cod_mun
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.sigue_retenido
GROUP BY t.cod_mun, t.municipio, p.nombre, t.poblacion, r.meses_seguidos, r.desde
ORDER BY t.poblacion DESC
```

<DataTable data={pie_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=motivo title="Información pendiente (ejercicio)" />
    <Column id=meses_seguidos title="Meses seguidos retenido" contentType=colorscale colorMax=24 />
    <Column id=importe_real title="Retenido en esta campaña (€ de {base_deflactor[0]?.anio_base})" fmt=eur0 />
    <Column id=lista title="Lista del alcalde al empezar la retención" />
    <Column id=familia title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de más a menos habitantes. «Retenido en esta campaña»: euros no transferidos desde que empezó la retención por esa información (si coincide con otra, el importe mensual se reparte entre ambas), descontada la inflación mes a mes. Algunos están retenidos por no haber recibido Hacienda la información de una entidad o sociedad que depende del ayuntamiento, no la del propio ayuntamiento.</p>

### Por comunidad autónoma

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
    c.ruta,
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
    <Column id=comunidad title="Comunidad" />
    <Column id=retenidos title="Retenidos en {pie_ultimo[0]?.mes}" fmt=num0 />
    <Column id=municipios title="Ayuntamientos" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Por partido en el gobierno

Cada campaña de retención (una por tipo de información y ejercicio) cuenta como una observación por ayuntamiento: retenido o no. La familia política es la del alcalde **al empezar la retención** (o, si no fue retenido, al empezar esa campaña). Como en la liquidación, el **ratio ajustado** compara cada familia con lo esperable en municipios del mismo tamaño, la misma comunidad y la misma campaña.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>Lo que dicen los datos:</b> una vez ajustados el tamaño y la comunidad, los dos partidos que gobiernan la mayoría de los ayuntamientos quedan prácticamente en 1 y ninguna familia queda claramente por encima de lo esperable. Algunas quedan por debajo, sobre todo partidos con implantación en una sola comunidad; con pocos ayuntamientos, los intervalos son amplios. Pesa mucho más el tamaño: en los municipios de menos de 1.000 habitantes la retención es unas cinco veces más frecuente que en los de más de 100.000.
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
    title="Retenciones ajustadas por tamaño y comunidad (1 = lo esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pie_por_familia} rows=all>
    <Column id=familia title="Familia política del alcalde" />
    <Column id=observaciones title="Ayuntamientos × campaña" fmt=num0 />
    <Column id=retenciones title="Retenciones" fmt=num0 />
    <Column id=tasa title="Tasa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustado solo por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustado por tamaño y comunidad" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Campañas completas desde 2017 (liquidaciones de 2015 a 2024, presupuestos de 2022 a 2025 y líneas fundamentales de 2023 a 2026). Solo familias con al menos 300 ayuntamientos × campaña. La retención de la liquidación empieza unos dos años después del plazo para remitirla, así que el alcalde al empezar la retención puede no ser el que debía enviarla (sobre todo tras las elecciones municipales de mayo de 2019 y 2023).</p>

---

## Periodo medio de pago a proveedores

Todos los ayuntamientos deben calcular y **comunicar a Hacienda cada trimestre su periodo medio de pago a proveedores** (PMP: cuántos días tardan, de media, en pagar sus facturas), antes del último día del mes siguiente (Real Decreto 635/2014 y art. 16.8 de la Orden HAP/2105/2012). Hacienda publica los datos de quienes lo comunican; quien no aparece no lo ha comunicado. El máximo legal para pagar es de **30 días** (art. 13.6 de la Ley Orgánica 2/2012). Navarra y, según los años, los territorios forales vascos quedan fuera del indicador de comunicación: su tutela financiera es foral y la mayoría de sus ayuntamientos no aparece en la publicación.

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
        title="Sin comunicar el PMP ({pmp_ultimo[0]?.periodo})"
        value={pmp_resumen[0]?.no_comunican}
        formattedValue={formatNumber(pmp_resumen[0]?.no_comunican, 0)}
        period="{formatNumber(100 * pmp_resumen[0]?.no_comunican / pmp_resumen[0]?.total, 1)} % de {formatNumber(pmp_resumen[0]?.total, 0)} ayuntamientos"
        source="Ministerio de Hacienda (PMP_NET)"
        sparklineData={pmp_serie.map(d => d.no_comunican)}
    />
    <KpiCard
        title="Vecinos afectados"
        value={pmp_resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(pmp_resumen[0]?.afectados_por_1000, 1)}
        unit="por cada 1.000 hab."
        period="{formatNumber(pmp_resumen[0]?.poblacion_afectada, 0)} vecinos en total; {formatNumber(pmp_resumen[0]?.mas_5000, 0)} de esos ayuntamientos tienen más de 5.000 habitantes"
        sparklineData={pmp_serie.filter(d => d.afectados_por_1000 != null).map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Pagan en más de 30 días"
        value={pmp_resumen[0]?.supera_30}
        formattedValue={formatNumber(pmp_resumen[0]?.supera_30, 0)}
        period="{formatNumber(100 * pmp_resumen[0]?.supera_30 / pmp_resumen[0]?.comunican, 1)} % de los que lo comunican ({formatNumber(pmp_resumen[0]?.poblacion_supera_30, 0)} hab.)"
        sparklineData={pmp_serie.map(d => d.supera_30)}
    />
</Grid>

### Los que no lo comunicaron en el {pmp_ultimo[0]?.etiqueta}

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
    '/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
JOIN historial h USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.aplica_indicador AND NOT t.reporta
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=trimestres_sin title="Trimestres sin comunicar (de los últimos 12)" contentType=colorscale colorMax=12 />
    <Column id=lista_en_plazo title="Lista del alcalde en el plazo" />
    <Column id=familia_en_plazo title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de más a menos habitantes. «En el plazo» = el último día del mes siguiente al trimestre. Un ayuntamiento que lo comunicó tarde puede no figurar en la publicación de ese trimestre.</p>

### Por comunidad autónoma

```sql pmp_por_ccaa
SELECT
    c.nombre AS comunidad,
    c.ruta,
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
    <Column id=comunidad title="Comunidad" />
    <Column id=no_comunican title="No lo comunicaron" fmt=num0 />
    <Column id=municipios title="Ayuntamientos" fmt=num0 />
    <Column id=pct title="% sin comunicar" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_supera_30 title="% de los que comunican que paga en más de 30 días" fmt=pct1 />
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
    title="Ayuntamientos sin comunicar el PMP y con PMP por encima de 30 días, por trimestre"
/>

### Por partido en el gobierno

Trimestres sin comunicar el PMP en los últimos tres años según la familia política del alcalde en el plazo, comparados con lo esperable en municipios **del mismo tamaño, la misma comunidad y el mismo trimestre**. Muchos ayuntamientos pequeños dejan de comunicarlo trimestre tras trimestre, así que las observaciones no son independientes y el intervalo real es algo más ancho que el mostrado.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>Lo que dicen los datos:</b> los dos partidos con más alcaldías quedan en torno a 1 tras el ajuste. Las desviaciones más grandes, por encima y por debajo, son de partidos con implantación en una sola comunidad, donde el ajuste por comunidad y tamaño recoge peor las diferencias entre municipios. El tamaño pesa mucho más: casi tres de cada diez ayuntamientos de menos de 1.000 habitantes no lo comunican, frente a prácticamente ninguno por encima de 50.000.
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
    title="PMP sin comunicar, ajustado por tamaño y comunidad (1 = lo esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pmp_por_familia} rows=all>
    <Column id=familia title="Familia política del alcalde en el plazo" />
    <Column id=observaciones title="Ayuntamientos × trimestre" fmt=num0 />
    <Column id=incumplimientos title="Trimestres sin comunicar" fmt=num0 />
    <Column id=tasa title="Tasa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustado solo por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustado por tamaño y comunidad" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

### Pagar en más de 30 días

Entre los ayuntamientos que sí comunican su PMP, estos son los que en el {pmp_ultimo[0]?.etiqueta} declararon un periodo medio de pago **por encima del máximo legal de 30 días**. Es un dato que calcula y firma el propio ayuntamiento.

```sql pmp_mayor30
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    t.pmp_dias,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.supera_30
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_mayor30} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=pmp_dias title="PMP (días)" fmt=num1 contentType=colorscale colorMin=30 colorMax=180 />
    <Column id=lista_en_plazo title="Lista del alcalde en el plazo" />
    <Column id=familia_en_plazo title="Familia política" />
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
    <Column id=familia title="Familia política del alcalde en el plazo" />
    <Column id=observaciones title="Ayuntamientos × trimestre que comunican" fmt=num0 />
    <Column id=por_encima title="Trimestres con PMP > 30 días" fmt=num0 />
    <Column id=tasa title="Tasa bruta" fmt=pct1 />
    <Column id=ratio_ajustado title="Ajustado por tamaño y comunidad" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Últimos 12 trimestres publicados. Solo familias con al menos 300 ayuntamientos × trimestre. Quien no comunica su PMP no entra en este cálculo, así que no se sabe si paga en plazo.</p>

---

## Metodología y fuentes

- **[Ministerio de Hacienda – CONPREL](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: el estado de información «N» (sin datos) de cada entidad en la publicación definitiva de liquidaciones. Desde 2013; antes Hacienda imputaba datos de muchos municipios pequeños. No se usan los avances provisionales, porque quien remite tarde aún no aparece en ellos.
- **[Ministerio de Política Territorial – Alcaldes y concejales](https://concejales.redsara.es/consulta/)**: alcalde en funciones en la fecha límite y lista con la que fue elegido, agrupada en familias políticas.
- **Obligación legal**: art. 15.3 de la [Orden HAP/2105/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-12147), en desarrollo del art. 6 de la [Ley Orgánica 2/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-5730).
- **Territorios forales**: en Álava y Navarra la liquidación municipal no se canaliza a CONPREL por la vía común (tutela financiera de la Diputación Foral y del Gobierno de Navarra), y en Bizkaia y Gipuzkoa tampoco en 2013-2014. Esos casos **no se cuentan como incumplimientos**: aparecerían casi al 100 % por un efecto del régimen foral, no de cada ayuntamiento.
- **[Tribunal de Cuentas – Plataforma de Rendición de Cuentas de las Entidades Locales](https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/)** (Tribunal de Cuentas y órganos de control externo autonómicos): estado de cada ayuntamiento en las consultas de Cuenta General, control interno y contratos, y la fecha de envío de cada Cuenta General rendida. La plataforma no ofrece descarga masiva: sus páginas se consultan con pausas y se guardan solo los estados y fechas, con la fecha de extracción. Cada entidad se casa con su código INE a partir de sus códigos de Hacienda (MEH) y del Directorio Común (DIR3), y por nombre y provincia si faltan.
- **Plazos**: Cuenta General, 15 de octubre del año siguiente (arts. 212.5 y 223.2 del [TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)); control interno, 30 de abril (art. 218.3 del TRLRHL e [Instrucción del Tribunal de Cuentas de 2019](https://www.boe.es/buscar/doc.php?id=BOE-A-2020-680)); relación de contratos, fin de febrero (art. 335 de la [LCSP](https://www.boe.es/buscar/act.php?id=BOE-A-2017-12902) e [Instrucción de 2018](https://www.boe.es/buscar/doc.php?id=BOE-A-2018-9585)). Solo cuentan los ejercicios con el plazo vencido.
- «Dentro de plazo» se mide con la fecha de envío que muestra la plataforma; si una cuenta consta rendida pero no se conoce su fecha, no se clasifica como en plazo ni fuera de plazo.
- **[Ministerio de Hacienda – Oficina Virtual de Entidades Locales](https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx)**: relación mensual (en PDF) de ayuntamientos a los que se retiene la participación en los tributos del Estado, desde octubre de 2016, y Excel mensual de entregas a cuenta con el importe retenido a cada uno. Hasta octubre de 2022 las listas solo traen el nombre: se casan con el código INE por nombre y provincia (todas casan; tres con una errata en el nombre, por aproximación). En esas listas antiguas el ejercicio de la liquidación no se indica y se deduce de la campaña (la de junio del año A corresponde a la liquidación de A-2, como en las listas posteriores). Los importes de los PDF y los Excel coinciden en ayuntamientos casi mes a mes.
- **Retención de fondos**: art. 36 de la [Ley 2/2011, de Economía Sostenible](https://www.boe.es/buscar/act.php?id=BOE-A-2011-4117) (liquidación, en relación con el art. 193.5 del [TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)) y disposición adicional 87ª de la [Ley 22/2021 de Presupuestos para 2022](https://www.boe.es/buscar/act.php?id=BOE-A-2021-21653) (presupuesto y líneas fundamentales). Cada lista mensual es una foto de quién sigue retenido, no de quién incumplió ese mes. Los territorios forales no figuran porque no reciben la participación por la vía común.
- **[Ministerio de Hacienda – PMP_NET](https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/)**: periodo medio de pago de cada entidad local por trimestre, desde el tercero de 2014. «No comunica» = el ayuntamiento existe ese año (padrón del INE) pero no figura en la publicación del trimestre. Obligación: [Real Decreto 635/2014](https://www.boe.es/buscar/act.php?id=BOE-A-2014-8121) (modificado por el [RD 1040/2017](https://www.boe.es/buscar/doc.php?id=BOE-A-2017-15492)) y art. 16.8 de la Orden HAP/2105/2012; máximo de 30 días, art. 13.6 de la LO 2/2012. El umbral de 30 días solo se aplica desde el segundo trimestre de 2018, cuando el RD 1040/2017 cambió el cálculo (antes descontaba los 30 días de conformidad y podía ser negativo). En Navarra (todos los años), Álava (hasta 2022) y Bizkaia y Gipuzkoa (hasta el segundo trimestre de 2016) la mayoría de ayuntamientos no figura en la publicación por el cauce foral: esos casos no cuentan como incumplimientos.
- Solo se consideran los ayuntamientos; diputaciones, mancomunidades y entidades menores tienen sus propias obligaciones y no se incluyen aquí.

<LastRefreshed prefix="Datos actualizados" />
