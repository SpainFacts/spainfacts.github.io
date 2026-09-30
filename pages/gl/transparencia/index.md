---
title: Transparencia
description: "Administracións que non cumpren as súas obrigas legais de publicar ou remitir información: quen son, onde están e quen gobernaba cando vencía o prazo."
i18n_origen: f1f81e75efbb
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    const MESES_GL = {enero: 'xaneiro', febrero: 'febreiro', marzo: 'marzo', abril: 'abril', mayo: 'maio', junio: 'xuño', julio: 'xullo', agosto: 'agosto', septiembre: 'setembro', octubre: 'outubro', noviembre: 'novembro', diciembre: 'decembro'};
    const mesGl = (s) => (s ?? '').replace(/^[a-z]+/, (m) => MESES_GL[m] ?? m);
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

# 🔍 Transparencia: quen non rende contas

As administracións públicas están **obrigadas por lei** a remitir cada ano certa información económica. Esta páxina recolle, con datos oficiais, que administracións non o fan, onde están e **quen gobernaba cando vencía o prazo**.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Como ler esta páxina</p>
<p class="mb-1">Todos os datos son rexistros oficiais e verificables. Que unha administración apareza aquí significa que <b>a información non consta na fonte oficial</b> na data de publicación: pode habela remitido tarde ou estar en trámite, e convén consultar a fonte antes de tirar conclusións sobre un caso concreto.</p>
<p class="mb-0">O incumprimento atribúeselle ao goberno <b>en funcións o día do prazo legal</b>, non ao actual. E como os municipios pequenos, con menos medios, incumpren moito máis, as comparacións entre partidos <b>axústanse por tamaño de poboación</b>.</p>
</div>

## Liquidación do orzamento municipal

Cada concello debe remitir ao Ministerio de Facenda a liquidación do seu orzamento (o que realmente ingresou e gastou) **antes do 31 de marzo do ano seguinte** (art. 15.3 da Orde HAP/2105/2012, que desenvolve a Lei orgánica 2/2012 de estabilidade orzamentaria). Sen esa información non se pode saber en que se gasta o diñeiro público. (Álava e Navarra quedan fóra deste indicador polo seu réxime foral; ver a metodoloxía.)

<Grid cols=3>
    <KpiCard
        title="Concellos sen liquidación {ultimo[0]?.anio}"
        value={resumen[0]?.incumplen}
        formattedValue={formatNumber(resumen[0]?.incumplen, 0)}
        period="{formatNumber(resumen[0]?.incumplen / resumen[0]?.total / 0.01, 1)} % de {formatNumber(resumen[0]?.total, 0)} concellos"
        source="Ministerio de Facenda (CONPREL)"
        sparklineData={liq_serie.map(d => d.incumplen)}
    />
    <KpiCard
        title="Veciños afectados"
        value={resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(resumen[0]?.afectados_por_1000, 1)}
        unit="por cada 1.000 hab."
        period="{formatNumber(resumen[0]?.poblacion_afectada, 0)} veciños en total; {formatNumber(resumen[0]?.grandes, 0)} deses concellos teñen máis de 20.000 habitantes"
        sparklineData={liq_serie.map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Tres anos ou máis seguidos"
        value={resumen_rachas[0]?.tres_o_mas}
        formattedValue={formatNumber(resumen_rachas[0]?.tres_o_mas, 0)}
        period="concellos que levan polo menos tres exercicios sen remitila"
    />
</Grid>

### Os que non a remitiron en {ultimo[0]?.anio}

```sql lista
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    coalesce(r.anios_seguidos, 0) AS anios_seguidos,
    t.alcalde_en_plazo,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/gl/territorios/municipios?m=' || t.cod_mun AS enlace
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
    <Column id=anios_seguidos title="Anos seguidos sen remitir" contentType=colorscale colorMax=10 />
    <Column id=lista_en_plazo title="Lista do alcalde no prazo" />
    <Column id=familia_en_plazo title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de máis a menos habitantes. «No prazo» = o 31 de marzo de {ultimo[0]?.anio + 1}, data límite para remitir a liquidación de {ultimo[0]?.anio}.</p>

### Por territorio

```sql por_ccaa
SELECT
    c.nombre AS comunidad,
    '/gl' || c.ruta AS ruta,
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
    title="Concellos que non remitiron a liquidación de {ultimo[0]?.anio}, por provincia"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: 'Non a remitiron', fmt: 'pct1'},
        {id: 'incumplen', title: 'Concellos', fmt: 'num0'},
        {id: 'municipios', title: 'Dun total de', fmt: 'num0'}
    ]}
/>

<DataTable data={por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=incumplen title="Non a remitiron" fmt=num0 />
    <Column id=municipios title="Concellos" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Por partido no goberno

Liquidacións non remitidas entre {ultimo[0]?.anio - 11} e {ultimo[0]?.anio} segundo a familia política do alcalde no prazo. O **ratio axustado** compara cada partido co que cabería esperar de municipios **do mesmo tamaño, na mesma comunidade e no mesmo ano**: 1 = o esperable; 2 = o dobre; 0,5 = a metade. Se o intervalo de confianza inclúe o 1, a diferenza pode deberse ao azar.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>O que din os datos:</b> unha vez descontados o tamaño do municipio e a comunidade autónoma, a maioría dos partidos queda moi preto de 1. O que máis explica que un concello non remita as súas contas é que sexa pequeno e onde estea, máis que quen o goberne.
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
    title="Incumprimento axustado por tamaño e comunidade (1 = o esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={por_familia} rows=all>
    <Column id=familia title="Familia política do alcalde no prazo" />
    <Column id=ayuntamientos_anio title="Concellos × ano" fmt=num0 />
    <Column id=incumplimientos title="Liquidacións non remitidas" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Axustado só por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Axustado por tamaño e comunidade" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Só familias con polo menos 300 concellos-ano. «Sin detalle en la fuente» agrupa alcaldías cuxa lista figura no rexistro oficial cunha etiqueta xenérica de coalición; «Independientes y locales», agrupacións de electores. As familias gobernan municipios moi distintos (tamaño, comunidade, recursos): o ratio axusta o tamaño, pero non outras diferenzas.</p>

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
    title="Concellos que non remitiron a liquidación, por tamaño"
/>

## Conta Xeral e control interno (Tribunal de Contas)

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

A **Conta Xeral** recolle todas as contas do concello (orzamento, balance, resultados, tesouraría). Unha vez aprobada polo Pleno, debe enviarse ao **Tribunal de Contas** (ou ao órgano de control externo da comunidade) **antes do 15 de outubro do ano seguinte** (arts. 212.5 e 223.2 do [texto refundido da Lei de facendas locais](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)). Ademais, cada concello debe remitir **antes do 30 de abril** a información de **control interno** (acordos adoptados contra os reparos do interventor e principais anomalías de ingresos; art. 218.3 da mesma lei) e, **antes de que remate febreiro**, a **relación anual de contratos** ou, se non os houbo, unha certificación negativa (art. 335 da Lei de contratos do sector público). A plataforma non inclúe o País Vasco nin Navarra, que teñen os seus propios órganos de control externo.

{#if tcu_cobertura[0]?.provincias < 40}

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-3 text-sm text-gray-700 dark:text-gray-300">
<b>En preparación.</b> Os datos estanse descargando aos poucos da plataforma do Tribunal de Contas para non sobrecargala, e esta sección publicarase cando cubra toda España (sen País Vasco nin Navarra). Con só algunhas provincias as cifras non serían representativas.
</div>

{:else}

{#if tcu_cobertura[0]?.parcial}
<div class="not-prose rounded-lg border border-amber-200 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-800 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
<b>Datos parciais:</b> a descarga desde a plataforma do Tribunal de Contas faise aos poucos para non sobrecargala. Polo de agora esta sección recolle <b>datos de {tcu_cobertura[0]?.provincias} provincias</b> ({formatNumber(tcu_cobertura[0]?.ayuntamientos, 0)} concellos); as cifras aínda non son representativas de España.
</div>
{/if}

<Grid cols=3>
    <KpiCard
        title="Sen Conta Xeral {tcu_ultimo[0]?.cg}"
        value={tcu_resumen[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen[0]?.no_rendida / tcu_resumen[0]?.total / 0.01, 1)} % de {formatNumber(tcu_resumen[0]?.total, 0)} concellos; non consta rendida a {tcu_cobertura[0]?.extraccion}"
        source="Tribunal de Contas (rendiciondecuentas.es)"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'cuenta_general').map(d => d.no_rendida)}
    />
    <KpiCard
        title="Enviada dentro do prazo"
        value={tcu_resumen[0]?.en_plazo}
        formattedValue="{formatNumber(tcu_resumen[0]?.en_plazo / tcu_resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(tcu_resumen[0]?.en_plazo, 0)} concellos antes do 15/10/{tcu_ultimo[0]?.cg + 1}; {formatNumber(tcu_resumen[0]?.fuera_plazo, 0)} enviárona máis tarde"
    />
    <KpiCard
        title="Sen control interno {tcu_ultimo[0]?.ci}"
        value={tcu_resumen_ci[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen_ci[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen_ci[0]?.no_rendida / tcu_resumen_ci[0]?.total / 0.01, 1)} % de {formatNumber(tcu_resumen_ci[0]?.total, 0)} concellos (prazo: 30/04/{tcu_ultimo[0]?.ci + 1})"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'control_interno').map(d => d.no_rendida)}
    />
</Grid>

### Os que non renderon a Conta Xeral de {tcu_ultimo[0]?.cg}

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
    '/gl/territorios/municipios?m=' || t.cod_mun AS enlace
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
    <Column id=ejercicios_sin_rendir title="Exercicios sen Conta Xeral" />
    <Column id=control_interno title="Control interno {tcu_ultimo[0]?.ci}" />
    <Column id=lista_en_plazo title="Lista do alcalde no prazo" />
    <Column id=familia_en_plazo title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de máis a menos habitantes. «No consta» = a plataforma non a mostra como rendida á data de extracción ({tcu_cobertura[0]?.extraccion}); pode haberse enviado despois ou estar en trámite. «No prazo» = o 15 de outubro de {tcu_ultimo[0]?.cg + 1}. A columna de exercicios inclúe todos os anos dispoñibles co prazo vencido.</p>

### Por comunidade autónoma

```sql tcu_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/gl' || c.ruta AS ruta,
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
    <Column id=comunidad title="Comunidade" />
    <Column id=ayuntamientos title="Concellos" fmt=num0 />
    <Column id=pct_cg title="Sen Conta Xeral {tcu_ultimo[0]?.cg}" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_cg_en_plazo title="Conta Xeral no prazo" fmt=pct1 />
    <Column id=pct_ci title="Sen control interno {tcu_ultimo[0]?.ci}" fmt=pct1 />
    <Column id=pct_ct title="Sen relación de contratos {tcu_ultimo[0]?.ct}" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Relación de contratos: «sen» significa que non consta nin a relación nin a certificación negativa de non ter celebrado contratos.</p>

### Por partido no goberno

Contas Xerais non rendidas en todos os exercicios dispoñibles, segundo a familia política do alcalde o 15 de outubro do ano seguinte. O **ratio axustado** compara cada partido co esperable en municipios **do mesmo tamaño, a mesma comunidade e o mesmo exercicio** (1 = o esperable). Se o intervalo de confianza inclúe o 1, a diferenza pode deberse ao azar.

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
    title="Conta Xeral non rendida, axustada por tamaño e comunidade (1 = o esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={tcu_por_familia} rows=all>
    <Column id=familia title="Familia política do alcalde no prazo" />
    <Column id=ayuntamientos_anio title="Concellos × exercicio" fmt=num0 />
    <Column id=incumplimientos title="Contas non rendidas" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Axustado só por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Axustado por tamaño e comunidade" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Só familias con polo menos 300 concellos-exercicio. O ratio axusta o tamaño e a comunidade, pero non outras diferenzas entre os municipios que goberna cada familia.</p>

{:else}

<p class="text-sm text-gray-500">Aínda non hai datos suficientes (polo menos 300 concellos-exercicio por familia política) para comparar partidos con garantías.</p>

{/if}

{/if}

---

## Retención de fondos do Estado por non remitir información

Cando un concello non lle envía a Facenda a **liquidación do seu orzamento**, o Ministerio **retenlle as entregas mensuais da participación nos tributos do Estado** (a principal transferencia que recibe do Estado) ata que a remite (art. 36 da Lei 2/2011, de economía sostible). Desde 2022 o mesmo ocorre se non envía o **orzamento do ano** antes do 1 de xullo ou as **liñas fundamentais do orzamento do ano seguinte** antes do 15 de setembro (disposición adicional 87.ª da Lei 22/2021). Facenda publica cada mes a lista de concellos retidos; aquí reúnense todas desde outubro de 2016. (Non hai concellos vascos nin navarros: polo seu réxime foral non reciben esta participación pola vía común.)

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
        title="Concellos retidos en {mesGl(pie_ultimo[0]?.mes)}"
        value={pie_resumen[0]?.retenidos_mes}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_mes, 0)}
        period="{formatNumber(pie_resumen[0]?.retenidos_liquidacion, 0)} deles por non remitir a liquidación"
        source="Ministerio de Facenda (OVEELL)"
        sparklineData={pie_serie_12m.map(d => d.retenidos_mes)}
    />
    <KpiCard
        title="Retido nos últimos 12 meses"
        value={pie_resumen[0]?.eur_12m_real}
        formattedValue={formatNumber(pie_resumen[0]?.eur_12m_real / 1e6, 1)}
        unit="M€ de {base_deflactor[0]?.anio_base}"
        period="participación en tributos do Estado non transferida mentres duraba o incumprimento ({formatNumber(pie_resumen[0]?.eur_12m / 1e6, 1)} M€ correntes)"
        source="Entregas a conta mensuais"
        sparklineData={pie_serie_12m.filter(d => d.eur_12m_real != null).map(d => d.eur_12m_real)}
    />
    <KpiCard
        title="Concellos retidos no último ano"
        value={pie_resumen[0]?.retenidos_12m}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_12m, 0)}
        period="polo menos un mes nos últimos 12"
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
    title="Concellos coa participación retida cada mes, por motivo"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<BarChart
    data={pie_serie}
    x=periodo
    y=importe_real
    series=motivo
    type=stacked
    yFmt=eur1m
    title="Euros retidos cada mes (euros de {base_deflactor[0]?.anio_base}, descontada a inflación)"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<p class="text-xs text-gray-500">Cada lista mensual é unha foto: quen segue retido ese mes. A lista da liquidación renóvase cara a xuño (coa liquidación de dous anos antes) e vaise baleirando a medida que os concellos a envían; a do orzamento aparece en novembro e decembro, e a das liñas fundamentais de decembro a agosto. Non hai importes para os meses en que Facenda non publicou o Excel de entregas a conta (marzo e outubro de 2019, novembro de 2020 a xaneiro de 2021 e febreiro de 2022). Como no resto da web, os importes exprésanse descontada a inflación, en euros de {base_deflactor[0]?.anio_base} (IPC medio anual do INE; o ano en curso, coa media dos meses publicados).</p>

### Retidos en {mesGl(pie_ultimo[0]?.mes)}

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
    '/gl/territorios/municipios?m=' || t.cod_mun AS enlace
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
    <Column id=motivo title="Información pendente (exercicio)" />
    <Column id=meses_seguidos title="Meses seguidos retido" contentType=colorscale colorMax=24 />
    <Column id=importe_real title="Retido nesta campaña (€ de {base_deflactor[0]?.anio_base})" fmt=eur0 />
    <Column id=lista title="Lista do alcalde ao comezar a retención" />
    <Column id=familia title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de máis a menos habitantes. «Retido nesta campaña»: euros non transferidos desde que comezou a retención por esa información (se coincide con outra, o importe mensual repártese entre ambas), descontada a inflación mes a mes. Algúns están retidos por non ter recibido Facenda a información dunha entidade ou sociedade que depende do concello, non a do propio concello.</p>

### Por comunidade autónoma

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
    '/gl' || c.ruta AS ruta,
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
    <Column id=comunidad title="Comunidade" />
    <Column id=retenidos title="Retidos en {mesGl(pie_ultimo[0]?.mes)}" fmt=num0 />
    <Column id=municipios title="Concellos" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Por partido no goberno

Cada campaña de retención (unha por tipo de información e exercicio) conta como unha observación por concello: retido ou non. A familia política é a do alcalde **ao comezar a retención** (ou, se non foi retido, ao comezar esa campaña). Como na liquidación, o **ratio axustado** compara cada familia co esperable en municipios do mesmo tamaño, a mesma comunidade e a mesma campaña.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>O que din os datos:</b> unha vez axustados o tamaño e a comunidade, os dous partidos que gobernan a maioría dos concellos quedan practicamente en 1 e ningunha familia queda claramente por riba do esperable. Algunhas quedan por debaixo, sobre todo partidos con implantación nunha soa comunidade; con poucos concellos, os intervalos son amplos. Pesa moito máis o tamaño: nos municipios de menos de 1.000 habitantes a retención é unhas cinco veces máis frecuente ca nos de máis de 100.000.
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
    title="Retencións axustadas por tamaño e comunidade (1 = o esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pie_por_familia} rows=all>
    <Column id=familia title="Familia política do alcalde" />
    <Column id=observaciones title="Concellos × campaña" fmt=num0 />
    <Column id=retenciones title="Retencións" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Axustado só por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Axustado por tamaño e comunidade" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Campañas completas desde 2017 (liquidacións de 2015 a 2024, orzamentos de 2022 a 2025 e liñas fundamentais de 2023 a 2026). Só familias con polo menos 300 concellos × campaña. A retención da liquidación comeza uns dous anos despois do prazo para remitila, así que o alcalde ao comezar a retención pode non ser o que debía enviala (sobre todo tras as eleccións municipais de maio de 2019 e 2023).</p>

---

## Período medio de pagamento a provedores

Todos os concellos deben calcular e **comunicarlle a Facenda cada trimestre o seu período medio de pagamento a provedores** (PMP: cantos días tardan, de media, en pagar as súas facturas), antes do último día do mes seguinte (Real decreto 635/2014 e art. 16.8 da Orde HAP/2105/2012). Facenda publica os datos de quen o comunica; quen non aparece non o comunicou. O máximo legal para pagar é de **30 días** (art. 13.6 da Lei orgánica 2/2012). Navarra e, segundo os anos, os territorios forais vascos quedan fóra do indicador de comunicación: a súa tutela financeira é foral e a maioría dos seus concellos non aparece na publicación.

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
        title="Sen comunicar o PMP ({pmp_ultimo[0]?.periodo})"
        value={pmp_resumen[0]?.no_comunican}
        formattedValue={formatNumber(pmp_resumen[0]?.no_comunican, 0)}
        period="{formatNumber(pmp_resumen[0]?.no_comunican / pmp_resumen[0]?.total / 0.01, 1)} % de {formatNumber(pmp_resumen[0]?.total, 0)} concellos"
        source="Ministerio de Facenda (PMP_NET)"
        sparklineData={pmp_serie.map(d => d.no_comunican)}
    />
    <KpiCard
        title="Veciños afectados"
        value={pmp_resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(pmp_resumen[0]?.afectados_por_1000, 1)}
        unit="por cada 1.000 hab."
        period="{formatNumber(pmp_resumen[0]?.poblacion_afectada, 0)} veciños en total; {formatNumber(pmp_resumen[0]?.mas_5000, 0)} deses concellos teñen máis de 5.000 habitantes"
        sparklineData={pmp_serie.filter(d => d.afectados_por_1000 != null).map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Pagan en máis de 30 días"
        value={pmp_resumen[0]?.supera_30}
        formattedValue={formatNumber(pmp_resumen[0]?.supera_30, 0)}
        period="{formatNumber(pmp_resumen[0]?.supera_30 / pmp_resumen[0]?.comunican / 0.01, 1)} % dos que o comunican ({formatNumber(pmp_resumen[0]?.poblacion_supera_30, 0)} hab.)"
        sparklineData={pmp_serie.map(d => d.supera_30)}
    />
</Grid>

### Os que non o comunicaron no {pmp_ultimo[0]?.etiqueta}

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
    '/gl/territorios/municipios?m=' || t.cod_mun AS enlace
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
    <Column id=trimestres_sin title="Trimestres sen comunicar (dos últimos 12)" contentType=colorscale colorMax=12 />
    <Column id=lista_en_plazo title="Lista do alcalde no prazo" />
    <Column id=familia_en_plazo title="Familia política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenados de máis a menos habitantes. «No prazo» = o último día do mes seguinte ao trimestre. Un concello que o comunicou tarde pode non figurar na publicación dese trimestre.</p>

### Por comunidade autónoma

```sql pmp_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/gl' || c.ruta AS ruta,
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
    <Column id=comunidad title="Comunidade" />
    <Column id=no_comunican title="Non o comunicaron" fmt=num0 />
    <Column id=municipios title="Concellos" fmt=num0 />
    <Column id=pct title="% sen comunicar" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_supera_30 title="% dos que comunican que paga en máis de 30 días" fmt=pct1 />
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
    title="Concellos sen comunicar o PMP e con PMP por riba de 30 días, por trimestre"
/>

### Por partido no goberno

Trimestres sen comunicar o PMP nos últimos tres anos segundo a familia política do alcalde no prazo, comparados co esperable en municipios **do mesmo tamaño, a mesma comunidade e o mesmo trimestre**. Moitos concellos pequenos deixan de comunicalo trimestre tras trimestre, así que as observacións non son independentes e o intervalo real é algo máis ancho ca o mostrado.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>O que din os datos:</b> os dous partidos con máis alcaldías quedan arredor de 1 tras o axuste. As desviacións máis grandes, por riba e por debaixo, son de partidos con implantación nunha soa comunidade, onde o axuste por comunidade e tamaño recolle peor as diferenzas entre municipios. O tamaño pesa moito máis: case tres de cada dez concellos de menos de 1.000 habitantes non o comunican, fronte a practicamente ningún por riba de 50.000.
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
    title="PMP sen comunicar, axustado por tamaño e comunidade (1 = o esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pmp_por_familia} rows=all>
    <Column id=familia title="Familia política do alcalde no prazo" />
    <Column id=observaciones title="Concellos × trimestre" fmt=num0 />
    <Column id=incumplimientos title="Trimestres sen comunicar" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Axustado só por tamaño" fmt=num2 />
    <Column id=ratio_ajustado title="Axustado por tamaño e comunidade" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

### Pagar en máis de 30 días

Entre os concellos que si comunican o seu PMP, estes son os que no {pmp_ultimo[0]?.etiqueta} declararon un período medio de pagamento **por riba do máximo legal de 30 días**. É un dato que calcula e asina o propio concello.

```sql pmp_mayor30
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    t.pmp_dias,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/gl/territorios/municipios?m=' || t.cod_mun AS enlace
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
    <Column id=lista_en_plazo title="Lista do alcalde no prazo" />
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
    <Column id=familia title="Familia política do alcalde no prazo" />
    <Column id=observaciones title="Concellos × trimestre que comunican" fmt=num0 />
    <Column id=por_encima title="Trimestres con PMP > 30 días" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_ajustado title="Axustado por tamaño e comunidade" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Últimos 12 trimestres publicados. Só familias con polo menos 300 concellos × trimestre. Quen non comunica o seu PMP non entra neste cálculo, así que non se sabe se paga no prazo.</p>

---

## Metodoloxía e fontes

- **[Ministerio de Facenda – CONPREL](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: o estado de información «N» (sen datos) de cada entidade na publicación definitiva de liquidacións. Desde 2013; antes Facenda imputaba datos de moitos municipios pequenos. Non se usan os avances provisionais, porque quen remite tarde aínda non aparece neles.
- **[Ministerio de Política Territorial – Alcaldes e concelleiros](https://concejales.redsara.es/consulta/)**: alcalde en funcións na data límite e lista coa que foi elixido, agrupada en familias políticas.
- **Obriga legal**: art. 15.3 da [Orde HAP/2105/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-12147), en desenvolvemento do art. 6 da [Lei orgánica 2/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-5730).
- **Territorios forais**: en Álava e Navarra a liquidación municipal non se canaliza a CONPREL pola vía común (tutela financeira da Deputación Foral e do Goberno de Navarra), e en Biscaia e Guipúscoa tampouco en 2013-2014. Eses casos **non se contan como incumprimentos**: aparecerían case ao 100 % por un efecto do réxime foral, non de cada concello.
- **[Tribunal de Contas – Plataforma de Rendición de Contas das Entidades Locais](https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/)** (Tribunal de Contas e órganos de control externo autonómicos): estado de cada concello nas consultas de Conta Xeral, control interno e contratos, e a data de envío de cada Conta Xeral rendida. A plataforma non ofrece descarga masiva: as súas páxinas consúltanse con pausas e gárdanse só os estados e datas, coa data de extracción. Cada entidade emparéllase co seu código INE a partir dos seus códigos de Facenda (MEH) e do Directorio Común (DIR3), e por nome e provincia se faltan.
- **Prazos**: Conta Xeral, 15 de outubro do ano seguinte (arts. 212.5 e 223.2 do [TRLRFL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)); control interno, 30 de abril (art. 218.3 do TRLRFL e [Instrución do Tribunal de Contas de 2019](https://www.boe.es/buscar/doc.php?id=BOE-A-2020-680)); relación de contratos, fin de febreiro (art. 335 da [LCSP](https://www.boe.es/buscar/act.php?id=BOE-A-2017-12902) e [Instrución de 2018](https://www.boe.es/buscar/doc.php?id=BOE-A-2018-9585)). Só contan os exercicios co prazo vencido.
- «Dentro do prazo» mídese coa data de envío que mostra a plataforma; se unha conta consta rendida pero non se coñece a súa data, non se clasifica como no prazo nin fóra do prazo.
- **[Ministerio de Facenda – Oficina Virtual de Entidades Locais](https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx)**: relación mensual (en PDF) de concellos aos que se lles retén a participación nos tributos do Estado, desde outubro de 2016, e Excel mensual de entregas a conta co importe retido a cada un. Ata outubro de 2022 as listas só traen o nome: emparéllanse co código INE por nome e provincia (todas casan; tres cunha errata no nome, por aproximación). Nesas listas antigas o exercicio da liquidación non se indica e dedúcese da campaña (a de xuño do ano A corresponde á liquidación de A-2, como nas listas posteriores). Os importes dos PDF e dos Excel coinciden en concellos case mes a mes.
- **Retención de fondos**: art. 36 da [Lei 2/2011, de economía sostible](https://www.boe.es/buscar/act.php?id=BOE-A-2011-4117) (liquidación, en relación co art. 193.5 do [TRLRFL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)) e disposición adicional 87.ª da [Lei 22/2021 de orzamentos para 2022](https://www.boe.es/buscar/act.php?id=BOE-A-2021-21653) (orzamento e liñas fundamentais). Cada lista mensual é unha foto de quen segue retido, non de quen incumpriu ese mes. Os territorios forais non figuran porque non reciben a participación pola vía común.
- **[Ministerio de Facenda – PMP_NET](https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/)**: período medio de pagamento de cada entidade local por trimestre, desde o terceiro de 2014. «Non comunica» = o concello existe ese ano (padrón do INE) pero non figura na publicación do trimestre. Obriga: [Real decreto 635/2014](https://www.boe.es/buscar/act.php?id=BOE-A-2014-8121) (modificado polo [RD 1040/2017](https://www.boe.es/buscar/doc.php?id=BOE-A-2017-15492)) e art. 16.8 da Orde HAP/2105/2012; máximo de 30 días, art. 13.6 da LO 2/2012. O limiar de 30 días só se aplica desde o segundo trimestre de 2018, cando o RD 1040/2017 cambiou o cálculo (antes descontaba os 30 días de conformidade e podía ser negativo). En Navarra (todos os anos), Álava (ata 2022) e Biscaia e Guipúscoa (ata o segundo trimestre de 2016) a maioría de concellos non figura na publicación pola canle foral: eses casos non contan como incumprimentos.
- Só se consideran os concellos; deputacións, mancomunidades e entidades menores teñen as súas propias obrigas e non se inclúen aquí.

<LastRefreshed prefix="Datos actualizados" />
