---
title: Retiment de comptes dels ajuntaments
description: "Administracions que no compleixen les seves obligacions legals de publicar o trametre informació: quines són, on són i qui governava quan vencia el termini."
i18n_origen: 3425c0f0ac57
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // Dates en català (les etiquetes de mes que es construeixen a les consultes SQL són en castellà)
    const mesDe = (d) => d ? new Date(d).toLocaleDateString('ca-ES', {day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC'}).replace(/^\d+\s+/, '') : '';
    const trimCa = (d) => { if (!d) return ''; const x = new Date(d); return ['1r', '2n', '3r', '4t'][Math.floor(x.getUTCMonth() / 3)] + ' trimestre del ' + x.getUTCFullYear(); };
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

# 🔍 Transparència: qui no ret comptes

Les administracions públiques estan **obligades per llei** a trametre cada any determinada informació econòmica. Aquesta pàgina recull, amb dades oficials, quines administracions no ho fan, on són i **qui governava quan vencia el termini**.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Com llegir aquesta pàgina</p>
<p class="mb-1">Totes les dades són registres oficials i verificables. Que una administració aparegui aquí vol dir que <b>la informació no consta a la font oficial</b> en la data de publicació: pot haver-la tramesa tard o estar en tràmit, i convé consultar la font abans de treure conclusions sobre un cas concret.</p>
<p class="mb-0">L'incompliment s'atribueix al govern <b>en funcions el dia del termini legal</b>, no a l'actual. I com que els municipis petits, amb menys mitjans, incompleixen molt més, les comparacions entre partits s'<b>ajusten per mida de població</b>.</p>
</div>

## Liquidació del pressupost municipal

Cada ajuntament ha de trametre al Ministeri d'Hisenda la liquidació del seu pressupost (el que realment va ingressar i gastar) **abans del 31 de març de l'any següent** (art. 15.3 de l'Ordre HAP/2105/2012, que desplega la Llei orgànica 2/2012 d'estabilitat pressupostària). Sense aquesta informació no es pot saber en què es gasten els diners públics. (Àlaba i Navarra queden fora d'aquest indicador pel seu règim foral; vegeu la metodologia.)

<Grid cols=3>
    <KpiCard
        title="Ajuntaments sense liquidació {ultimo[0]?.anio}"
        value={resumen[0]?.incumplen}
        formattedValue={formatNumber(resumen[0]?.incumplen, 0)}
        period="{formatNumber(resumen[0]?.incumplen / resumen[0]?.total / 0.01, 1)} % de {formatNumber(resumen[0]?.total, 0)} ajuntaments"
        source="Ministeri d'Hisenda (CONPREL)"
        sparklineData={liq_serie.map(d => d.incumplen)}
    />
    <KpiCard
        title="Veïns afectats"
        value={resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(resumen[0]?.afectados_por_1000, 1)}
        unit="per cada 1.000 hab."
        period="{formatNumber(resumen[0]?.poblacion_afectada, 0)} veïns en total; {formatNumber(resumen[0]?.grandes, 0)} d'aquests ajuntaments tenen més de 20.000 habitants"
        sparklineData={liq_serie.map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Tres anys o més seguits"
        value={resumen_rachas[0]?.tres_o_mas}
        formattedValue={formatNumber(resumen_rachas[0]?.tres_o_mas, 0)}
        period="ajuntaments que porten almenys tres exercicis sense trametre-la"
    />
</Grid>

### Els que no la van trametre el {ultimo[0]?.anio}

```sql lista
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    coalesce(r.anios_seguidos, 0) AS anios_seguidos,
    t.alcalde_en_plazo,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/ca/territorios/municipios?m=' || t.cod_mun AS enlace
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
LEFT JOIN ${rachas} r USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.anio = (SELECT anio FROM ${ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=anios_seguidos title="Anys seguits sense trametre" contentType=colorscale colorMax=10 />
    <Column id=lista_en_plazo title="Llista de l'alcalde en el termini" />
    <Column id=familia_en_plazo title="Família política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenats de més a menys habitants. «En el termini» = el 31 de març de {ultimo[0]?.anio + 1}, data límit per trametre la liquidació del {ultimo[0]?.anio}.</p>

### Per territori

```sql por_ccaa
SELECT
    c.nombre AS comunidad,
    '/ca' || c.ruta AS ruta,
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límits © Instituto Geográfico Nacional"
    title="Ajuntaments que no van trametre la liquidació del {ultimo[0]?.anio}, per província"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: 'No la van trametre', fmt: 'pct1'},
        {id: 'incumplen', title: 'Ajuntaments', fmt: 'num0'},
        {id: 'municipios', title: "D'un total de", fmt: 'num0'}
    ]}
/>

<DataTable data={por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=incumplen title="No la van trametre" fmt=num0 />
    <Column id=municipios title="Ajuntaments" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Per partit al govern

Liquidacions no trameses entre el {ultimo[0]?.anio - 11} i el {ultimo[0]?.anio} segons la família política de l'alcalde en el termini. La **ràtio ajustada** compara cada partit amb el que caldria esperar de municipis **de la mateixa mida, a la mateixa comunitat i el mateix any**: 1 = el que és esperable; 2 = el doble; 0,5 = la meitat. Si l'interval de confiança inclou l'1, la diferència pot ser deguda a l'atzar.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>El que diuen les dades:</b> un cop descomptades la mida del municipi i la comunitat autònoma, la majoria dels partits queda molt a prop d'1. El que més explica que un ajuntament no trameti els seus comptes és que sigui petit i on sigui, més que no pas qui el governi.
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
    title="Incompliment ajustat per mida i comunitat (1 = el que és esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={por_familia} rows=all>
    <Column id=familia title="Família política de l'alcalde en el termini" />
    <Column id=ayuntamientos_anio title="Ajuntaments × any" fmt=num0 />
    <Column id=incumplimientos title="Liquidacions no trameses" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustada només per mida" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustada per mida i comunitat" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Només famílies amb almenys 300 ajuntaments-any. «Sin detalle en la fuente» (sense detall a la font) agrupa alcaldies la llista de les quals figura al registre oficial amb una etiqueta genèrica de coalició; «Independientes y locales» (independents i locals), agrupacions d'electors. Les famílies governen municipis molt diferents (mida, comunitat, recursos): la ràtio ajusta la mida, però no altres diferències.</p>

### Evolució

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
    title="Ajuntaments que no van trametre la liquidació, per mida"
/>

## Compte General i control intern (Tribunal de Comptes)

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

El **Compte General** recull tots els comptes de l'ajuntament (pressupost, balanç, resultats, tresoreria). Un cop aprovat pel Ple, s'ha d'enviar al **Tribunal de Comptes** (o a l'òrgan de control extern de la comunitat) **abans del 15 d'octubre de l'any següent** (arts. 212.5 i 223.2 del [text refós de la Llei d'hisendes locals](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)). A més, cada ajuntament ha de trametre **abans del 30 d'abril** la informació de **control intern** (acords adoptats contra les objeccions de l'interventor i principals anomalies d'ingressos; art. 218.3 de la mateixa llei) i, **abans que acabi el febrer**, la **relació anual de contractes** o, si no n'hi ha hagut, una certificació negativa (art. 335 de la Llei de contractes del sector públic). La plataforma no inclou el País Basc ni Navarra, que tenen els seus propis òrgans de control extern.

{#if tcu_cobertura[0]?.provincias < 40}

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-3 text-sm text-gray-700 dark:text-gray-300">
<b>En preparació.</b> Les dades s'estan descarregant a poc a poc de la plataforma del Tribunal de Comptes per no sobrecarregar-la, i aquesta secció es publicarà quan cobreixi tot Espanya (sense el País Basc ni Navarra). Amb només algunes províncies les xifres no serien representatives.
</div>

{:else}

{#if tcu_cobertura[0]?.parcial}
<div class="not-prose rounded-lg border border-amber-200 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-800 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
<b>Dades parcials:</b> la descàrrega des de la plataforma del Tribunal de Comptes es fa a poc a poc per no sobrecarregar-la. De moment aquesta secció recull <b>dades de {tcu_cobertura[0]?.provincias} províncies</b> ({formatNumber(tcu_cobertura[0]?.ayuntamientos, 0)} ajuntaments); les xifres encara no són representatives d'Espanya.
</div>
{/if}

<Grid cols=3>
    <KpiCard
        title="Sense Compte General {tcu_ultimo[0]?.cg}"
        value={tcu_resumen[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen[0]?.no_rendida / tcu_resumen[0]?.total / 0.01, 1)} % de {formatNumber(tcu_resumen[0]?.total, 0)} ajuntaments; no consta com a retut a {tcu_cobertura[0]?.extraccion}"
        source="Tribunal de Comptes (rendiciondecuentas.es)"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'cuenta_general').map(d => d.no_rendida)}
    />
    <KpiCard
        title="Enviat dins del termini"
        value={tcu_resumen[0]?.en_plazo}
        formattedValue="{formatNumber(tcu_resumen[0]?.en_plazo / tcu_resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(tcu_resumen[0]?.en_plazo, 0)} ajuntaments abans del 15/10/{tcu_ultimo[0]?.cg + 1}; {formatNumber(tcu_resumen[0]?.fuera_plazo, 0)} el van enviar més tard"
    />
    <KpiCard
        title="Sense control intern {tcu_ultimo[0]?.ci}"
        value={tcu_resumen_ci[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen_ci[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen_ci[0]?.no_rendida / tcu_resumen_ci[0]?.total / 0.01, 1)} % de {formatNumber(tcu_resumen_ci[0]?.total, 0)} ajuntaments (termini: 30/04/{tcu_ultimo[0]?.ci + 1})"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'control_interno').map(d => d.no_rendida)}
    />
</Grid>

### Els que no han retut el Compte General del {tcu_ultimo[0]?.cg}

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
    '/ca/territorios/municipios?m=' || t.cod_mun AS enlace
FROM cg t
JOIN historial h USING (cod_mun)
LEFT JOIN ci USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.ejercicio = (SELECT cg FROM ${tcu_ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={tcu_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=ejercicios_sin_rendir title="Exercicis sense Compte General" />
    <Column id=control_interno title="Control intern {tcu_ultimo[0]?.ci}" />
    <Column id=lista_en_plazo title="Llista de l'alcalde en el termini" />
    <Column id=familia_en_plazo title="Família política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenats de més a menys habitants. «No consta» = la plataforma no el mostra com a retut en la data d'extracció ({tcu_cobertura[0]?.extraccion}); pot haver-se enviat després o estar en tràmit. «En el termini» = el 15 d'octubre de {tcu_ultimo[0]?.cg + 1}. La columna d'exercicis inclou tots els anys disponibles amb el termini vençut.</p>

### Per comunitat autònoma

```sql tcu_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/ca' || c.ruta AS ruta,
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
    <Column id=comunidad title="Comunitat" />
    <Column id=ayuntamientos title="Ajuntaments" fmt=num0 />
    <Column id=pct_cg title="Sense Compte General {tcu_ultimo[0]?.cg}" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_cg_en_plazo title="Compte General en termini" fmt=pct1 />
    <Column id=pct_ci title="Sense control intern {tcu_ultimo[0]?.ci}" fmt=pct1 />
    <Column id=pct_ct title="Sense relació de contractes {tcu_ultimo[0]?.ct}" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Relació de contractes: «sense» vol dir que no consta ni la relació ni la certificació negativa de no haver celebrat contractes.</p>

### Per partit al govern

Comptes Generals no retuts en tots els exercicis disponibles, segons la família política de l'alcalde el 15 d'octubre de l'any següent. La **ràtio ajustada** compara cada partit amb el que és esperable en municipis **de la mateixa mida, la mateixa comunitat i el mateix exercici** (1 = el que és esperable). Si l'interval de confiança inclou l'1, la diferència pot ser deguda a l'atzar.

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
    title="Compte General no retut, ajustat per mida i comunitat (1 = el que és esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={tcu_por_familia} rows=all>
    <Column id=familia title="Família política de l'alcalde en el termini" />
    <Column id=ayuntamientos_anio title="Ajuntaments × exercici" fmt=num0 />
    <Column id=incumplimientos title="Comptes no retuts" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustada només per mida" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustada per mida i comunitat" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Només famílies amb almenys 300 ajuntaments-exercici. La ràtio ajusta la mida i la comunitat, però no altres diferències entre els municipis que governa cada família.</p>

{:else}

<p class="text-sm text-gray-500">Encara no hi ha prou dades (almenys 300 ajuntaments-exercici per família política) per comparar partits amb garanties.</p>

{/if}

{/if}

---

## Retenció de fons de l'Estat per no trametre informació

Quan un ajuntament no envia a Hisenda la **liquidació del seu pressupost**, el Ministeri li **reté els lliuraments mensuals de la participació en els tributs de l'Estat** (la principal transferència que rep de l'Estat) fins que la tramet (art. 36 de la Llei 2/2011, d'economia sostenible). Des del 2022 passa el mateix si no envia el **pressupost de l'any** abans de l'1 de juliol o les **línies fonamentals del pressupost de l'any següent** abans del 15 de setembre (disposició addicional 87a de la Llei 22/2021). Hisenda publica cada mes la llista d'ajuntaments retinguts; aquí es reuneixen totes des d'octubre del 2016. (No hi ha ajuntaments bascos ni navarresos: pel seu règim foral no reben aquesta participació per la via comuna.)

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
        title="Ajuntaments retinguts el mes {mesDe(pie_ultimo[0]?.periodo)}"
        value={pie_resumen[0]?.retenidos_mes}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_mes, 0)}
        period="{formatNumber(pie_resumen[0]?.retenidos_liquidacion, 0)} d'ells per no trametre la liquidació"
        source="Ministeri d'Hisenda (OVEELL)"
        sparklineData={pie_serie_12m.map(d => d.retenidos_mes)}
    />
    <KpiCard
        title="Retingut els últims 12 mesos"
        value={pie_resumen[0]?.eur_12m_real}
        formattedValue={formatNumber(pie_resumen[0]?.eur_12m_real / 1e6, 1)}
        unit="M€ de {base_deflactor[0]?.anio_base}"
        period="participació en tributs de l'Estat no transferida mentre durava l'incompliment ({formatNumber(pie_resumen[0]?.eur_12m / 1e6, 1)} M€ corrents)"
        source="Lliuraments a compte mensuals"
        sparklineData={pie_serie_12m.filter(d => d.eur_12m_real != null).map(d => d.eur_12m_real)}
    />
    <KpiCard
        title="Ajuntaments retinguts l'últim any"
        value={pie_resumen[0]?.retenidos_12m}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_12m, 0)}
        period="almenys un mes en els últims 12"
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
    title="Ajuntaments amb la participació retinguda cada mes, per motiu"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<BarChart
    data={pie_serie}
    x=periodo
    y=importe_real
    series=motivo
    type=stacked
    yFmt=eur1m
    title="Euros retinguts cada mes (euros de {base_deflactor[0]?.anio_base}, descomptada la inflació)"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<p class="text-xs text-gray-500">Cada llista mensual és una foto: qui continua retingut aquell mes. La llista de la liquidació es renova cap al juny (amb la liquidació de dos anys abans) i es va buidant a mesura que els ajuntaments l'envien; la del pressupost apareix al novembre i al desembre, i la de les línies fonamentals, de desembre a agost. No hi ha imports per als mesos en què Hisenda no va publicar l'Excel de lliuraments a compte (març i octubre del 2019, de novembre del 2020 a gener del 2021 i febrer del 2022). Com a la resta del web, els imports s'expressen descomptada la inflació, en euros de {base_deflactor[0]?.anio_base} (IPC mitjà anual de l'INE; l'any en curs, amb la mitjana dels mesos publicats).</p>

### Retinguts el mes {mesDe(pie_ultimo[0]?.periodo)}

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
    '/ca/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pie t
LEFT JOIN ${pie_importe_real} ir ON ir.cod_mun = t.cod_mun AND ir.seccion = t.seccion AND ir.anio = CAST(t.anio AS INTEGER)
LEFT JOIN ${pie_rachas} r ON r.cod_mun = t.cod_mun
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.sigue_retenido
GROUP BY t.cod_mun, t.municipio, p.nombre, t.poblacion, r.meses_seguidos, r.desde
ORDER BY t.poblacion DESC
```

<DataTable data={pie_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=motivo title="Informació pendent (exercici)" />
    <Column id=meses_seguidos title="Mesos seguits retingut" contentType=colorscale colorMax=24 />
    <Column id=importe_real title="Retingut en aquesta campanya (€ de {base_deflactor[0]?.anio_base})" fmt=eur0 />
    <Column id=lista title="Llista de l'alcalde en començar la retenció" />
    <Column id=familia title="Família política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenats de més a menys habitants. «Retingut en aquesta campanya»: euros no transferits des que va començar la retenció per aquella informació (si coincideix amb una altra, l'import mensual es reparteix entre totes dues), descomptada la inflació mes a mes. Alguns estan retinguts perquè Hisenda no ha rebut la informació d'una entitat o societat que depèn de l'ajuntament, no la del mateix ajuntament.</p>

### Per comunitat autònoma

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
    '/ca' || c.ruta AS ruta,
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
    <Column id=comunidad title="Comunitat" />
    <Column id=retenidos title="Retinguts el mes {mesDe(pie_ultimo[0]?.periodo)}" fmt=num0 />
    <Column id=municipios title="Ajuntaments" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Per partit al govern

Cada campanya de retenció (una per tipus d'informació i exercici) compta com una observació per ajuntament: retingut o no. La família política és la de l'alcalde **en començar la retenció** (o, si no va ser retingut, en començar aquella campanya). Com en la liquidació, la **ràtio ajustada** compara cada família amb el que és esperable en municipis de la mateixa mida, la mateixa comunitat i la mateixa campanya.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>El que diuen les dades:</b> un cop ajustades la mida i la comunitat, els dos partits que governen la majoria dels ajuntaments queden pràcticament en 1 i cap família queda clarament per sobre del que és esperable. Algunes queden per sota, sobretot partits amb implantació en una sola comunitat; amb pocs ajuntaments, els intervals són amplis. Pesa molt més la mida: als municipis de menys de 1.000 habitants la retenció és unes cinc vegades més freqüent que als de més de 100.000.
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
    title="Retencions ajustades per mida i comunitat (1 = el que és esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pie_por_familia} rows=all>
    <Column id=familia title="Família política de l'alcalde" />
    <Column id=observaciones title="Ajuntaments × campanya" fmt=num0 />
    <Column id=retenciones title="Retencions" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustada només per mida" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustada per mida i comunitat" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Campanyes completes des del 2017 (liquidacions del 2015 al 2024, pressupostos del 2022 al 2025 i línies fonamentals del 2023 al 2026). Només famílies amb almenys 300 ajuntaments × campanya. La retenció de la liquidació comença uns dos anys després del termini per trametre-la, de manera que l'alcalde en començar la retenció pot no ser el que l'havia d'enviar (sobretot després de les eleccions municipals de maig del 2019 i del 2023).</p>

---

## Període mitjà de pagament a proveïdors

Tots els ajuntaments han de calcular i **comunicar a Hisenda cada trimestre el seu període mitjà de pagament a proveïdors** (PMP: quants dies triguen, de mitjana, a pagar les seves factures), abans de l'últim dia del mes següent (Reial decret 635/2014 i art. 16.8 de l'Ordre HAP/2105/2012). Hisenda publica les dades dels qui el comuniquen; qui no hi apareix no l'ha comunicat. El màxim legal per pagar és de **30 dies** (art. 13.6 de la Llei orgànica 2/2012). Navarra i, segons els anys, els territoris forals bascos queden fora de l'indicador de comunicació: la seva tutela financera és foral i la majoria dels seus ajuntaments no apareix a la publicació.

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
        title="Sense comunicar el PMP ({trimCa(pmp_ultimo[0]?.fecha)})"
        value={pmp_resumen[0]?.no_comunican}
        formattedValue={formatNumber(pmp_resumen[0]?.no_comunican, 0)}
        period="{formatNumber(pmp_resumen[0]?.no_comunican / pmp_resumen[0]?.total / 0.01, 1)} % de {formatNumber(pmp_resumen[0]?.total, 0)} ajuntaments"
        source="Ministeri d'Hisenda (PMP_NET)"
        sparklineData={pmp_serie.map(d => d.no_comunican)}
    />
    <KpiCard
        title="Veïns afectats"
        value={pmp_resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(pmp_resumen[0]?.afectados_por_1000, 1)}
        unit="per cada 1.000 hab."
        period="{formatNumber(pmp_resumen[0]?.poblacion_afectada, 0)} veïns en total; {formatNumber(pmp_resumen[0]?.mas_5000, 0)} d'aquests ajuntaments tenen més de 5.000 habitants"
        sparklineData={pmp_serie.filter(d => d.afectados_por_1000 != null).map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Paguen en més de 30 dies"
        value={pmp_resumen[0]?.supera_30}
        formattedValue={formatNumber(pmp_resumen[0]?.supera_30, 0)}
        period="{formatNumber(pmp_resumen[0]?.supera_30 / pmp_resumen[0]?.comunican / 0.01, 1)} % dels qui el comuniquen ({formatNumber(pmp_resumen[0]?.poblacion_supera_30, 0)} hab.)"
        sparklineData={pmp_serie.map(d => d.supera_30)}
    />
</Grid>

### Els que no el van comunicar el {trimCa(pmp_ultimo[0]?.fecha)}

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
    '/ca/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
JOIN historial h USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.aplica_indicador AND NOT t.reporta
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=trimestres_sin title="Trimestres sense comunicar (dels últims 12)" contentType=colorscale colorMax=12 />
    <Column id=lista_en_plazo title="Llista de l'alcalde en el termini" />
    <Column id=familia_en_plazo title="Família política" />
</DataTable>

<p class="text-xs text-gray-500">Ordenats de més a menys habitants. «En el termini» = l'últim dia del mes següent al trimestre. Un ajuntament que el va comunicar tard pot no figurar a la publicació d'aquell trimestre.</p>

### Per comunitat autònoma

```sql pmp_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/ca' || c.ruta AS ruta,
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
    <Column id=comunidad title="Comunitat" />
    <Column id=no_comunican title="No el van comunicar" fmt=num0 />
    <Column id=municipios title="Ajuntaments" fmt=num0 />
    <Column id=pct title="% sense comunicar" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_supera_30 title="% dels qui el comuniquen que paga en més de 30 dies" fmt=pct1 />
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
    title="Ajuntaments sense comunicar el PMP i amb PMP per sobre de 30 dies, per trimestre"
/>

### Per partit al govern

Trimestres sense comunicar el PMP en els últims tres anys segons la família política de l'alcalde en el termini, comparats amb el que és esperable en municipis **de la mateixa mida, la mateixa comunitat i el mateix trimestre**. Molts ajuntaments petits deixen de comunicar-lo trimestre rere trimestre, de manera que les observacions no són independents i l'interval real és una mica més ample que el que es mostra.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>El que diuen les dades:</b> els dos partits amb més alcaldies queden al voltant d'1 després de l'ajust. Les desviacions més grans, per sobre i per sota, són de partits amb implantació en una sola comunitat, on l'ajust per comunitat i mida recull pitjor les diferències entre municipis. La mida pesa molt més: gairebé tres de cada deu ajuntaments de menys de 1.000 habitants no el comuniquen, davant de pràcticament cap per sobre de 50.000.
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
    title="PMP sense comunicar, ajustat per mida i comunitat (1 = el que és esperable)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pmp_por_familia} rows=all>
    <Column id=familia title="Família política de l'alcalde en el termini" />
    <Column id=observaciones title="Ajuntaments × trimestre" fmt=num0 />
    <Column id=incumplimientos title="Trimestres sense comunicar" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_tamano title="Ajustada només per mida" fmt=num2 />
    <Column id=ratio_ajustado title="Ajustada per mida i comunitat" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

### Pagar en més de 30 dies

Entre els ajuntaments que sí que comuniquen el seu PMP, aquests són els que el {trimCa(pmp_ultimo[0]?.fecha)} van declarar un període mitjà de pagament **per sobre del màxim legal de 30 dies**. És una dada que calcula i signa el mateix ajuntament.

```sql pmp_mayor30
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    t.pmp_dias,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/ca/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.supera_30
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_mayor30} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=pmp_dias title="PMP (dies)" fmt=num1 contentType=colorscale colorMin=30 colorMax=180 />
    <Column id=lista_en_plazo title="Llista de l'alcalde en el termini" />
    <Column id=familia_en_plazo title="Família política" />
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
    <Column id=familia title="Família política de l'alcalde en el termini" />
    <Column id=observaciones title="Ajuntaments × trimestre que el comuniquen" fmt=num0 />
    <Column id=por_encima title="Trimestres amb PMP > 30 dies" fmt=num0 />
    <Column id=tasa title="Taxa bruta" fmt=pct1 />
    <Column id=ratio_ajustado title="Ajustada per mida i comunitat" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Últims 12 trimestres publicats. Només famílies amb almenys 300 ajuntaments × trimestre. Qui no comunica el seu PMP no entra en aquest càlcul, de manera que no se sap si paga dins del termini.</p>

---

## Metodologia i fonts

- **[Ministeri d'Hisenda – CONPREL](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: l'estat d'informació «N» (sense dades) de cada entitat en la publicació definitiva de liquidacions. Des del 2013; abans Hisenda imputava dades de molts municipis petits. No s'utilitzen els avançaments provisionals, perquè qui tramet tard encara no hi apareix.
- **[Ministeri de Política Territorial – Alcaldes i regidors](https://concejales.redsara.es/consulta/)**: alcalde en funcions en la data límit i llista amb què va ser elegit, agrupada en famílies polítiques.
- **Obligació legal**: art. 15.3 de l'[Ordre HAP/2105/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-12147), en desplegament de l'art. 6 de la [Llei orgànica 2/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-5730).
- **Territoris forals**: a Àlaba i Navarra la liquidació municipal no es canalitza a CONPREL per la via comuna (tutela financera de la Diputació Foral i del Govern de Navarra), i a Biscaia i Guipúscoa tampoc el 2013-2014. Aquests casos **no es compten com a incompliments**: apareixerien gairebé al 100 % per un efecte del règim foral, no de cada ajuntament.
- **[Tribunal de Comptes – Plataforma de Rendició de Comptes de les Entitats Locals](https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/)** (Tribunal de Comptes i òrgans de control extern autonòmics): estat de cada ajuntament en les consultes de Compte General, control intern i contractes, i la data d'enviament de cada Compte General retut. La plataforma no ofereix descàrrega massiva: les seves pàgines es consulten amb pauses i només se'n desen els estats i les dates, amb la data d'extracció. Cada entitat s'associa amb el seu codi INE a partir dels seus codis d'Hisenda (MEH) i del Directori Comú (DIR3), i per nom i província si en falten.
- **Terminis**: Compte General, 15 d'octubre de l'any següent (arts. 212.5 i 223.2 del [TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)); control intern, 30 d'abril (art. 218.3 del TRLRHL i [Instrucció del Tribunal de Comptes del 2019](https://www.boe.es/buscar/doc.php?id=BOE-A-2020-680)); relació de contractes, final de febrer (art. 335 de la [LCSP](https://www.boe.es/buscar/act.php?id=BOE-A-2017-12902) i [Instrucció del 2018](https://www.boe.es/buscar/doc.php?id=BOE-A-2018-9585)). Només compten els exercicis amb el termini vençut.
- «Dins del termini» es mesura amb la data d'enviament que mostra la plataforma; si un compte consta com a retut però no se'n coneix la data, no es classifica ni dins ni fora del termini.
- **[Ministeri d'Hisenda – Oficina Virtual d'Entitats Locals](https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx)**: relació mensual (en PDF) d'ajuntaments als quals es reté la participació en els tributs de l'Estat, des d'octubre del 2016, i Excel mensual de lliuraments a compte amb l'import retingut a cadascun. Fins a l'octubre del 2022 les llistes només porten el nom: s'associen amb el codi INE per nom i província (totes casen; tres amb una errata en el nom, per aproximació). En aquestes llistes antigues l'exercici de la liquidació no s'indica i es dedueix de la campanya (la de juny de l'any A correspon a la liquidació d'A-2, com en les llistes posteriors). Els imports dels PDF i dels Excel coincideixen en ajuntaments gairebé mes a mes.
- **Retenció de fons**: art. 36 de la [Llei 2/2011, d'economia sostenible](https://www.boe.es/buscar/act.php?id=BOE-A-2011-4117) (liquidació, en relació amb l'art. 193.5 del [TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214)) i disposició addicional 87a de la [Llei 22/2021 de pressupostos per al 2022](https://www.boe.es/buscar/act.php?id=BOE-A-2021-21653) (pressupost i línies fonamentals). Cada llista mensual és una foto de qui continua retingut, no de qui va incomplir aquell mes. Els territoris forals no hi figuren perquè no reben la participació per la via comuna.
- **[Ministeri d'Hisenda – PMP_NET](https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/)**: període mitjà de pagament de cada entitat local per trimestre, des del tercer del 2014. «No comunica» = l'ajuntament existeix aquell any (padró de l'INE) però no figura a la publicació del trimestre. Obligació: [Reial decret 635/2014](https://www.boe.es/buscar/act.php?id=BOE-A-2014-8121) (modificat pel [RD 1040/2017](https://www.boe.es/buscar/doc.php?id=BOE-A-2017-15492)) i art. 16.8 de l'Ordre HAP/2105/2012; màxim de 30 dies, art. 13.6 de la LO 2/2012. El llindar de 30 dies només s'aplica des del segon trimestre del 2018, quan el RD 1040/2017 va canviar el càlcul (abans descomptava els 30 dies de conformitat i podia ser negatiu). A Navarra (tots els anys), Àlaba (fins al 2022) i Biscaia i Guipúscoa (fins al segon trimestre del 2016) la majoria d'ajuntaments no figura a la publicació per la via foral: aquests casos no compten com a incompliments.
- Només es consideren els ajuntaments; diputacions, mancomunitats i entitats menors tenen les seves pròpies obligacions i no s'hi inclouen.

<LastRefreshed prefix="Dades actualitzades" />
