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
    />
    <KpiCard
        title="Vecinos afectados"
        value={resumen[0]?.poblacion_afectada}
        formattedValue={formatNumber(resumen[0]?.poblacion_afectada, 0)}
        unit="hab."
        period="{formatNumber(resumen[0]?.grandes, 0)} de esos ayuntamientos tienen más de 20.000 habitantes"
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

---

## Metodología y fuentes

- **[Ministerio de Hacienda – CONPREL](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: el estado de información «N» (sin datos) de cada entidad en la publicación definitiva de liquidaciones. Desde 2013; antes Hacienda imputaba datos de muchos municipios pequeños. No se usan los avances provisionales, porque quien remite tarde aún no aparece en ellos.
- **[Ministerio de Política Territorial – Alcaldes y concejales](https://concejales.redsara.es/consulta/)**: alcalde en funciones en la fecha límite y lista con la que fue elegido, agrupada en familias políticas.
- **Obligación legal**: art. 15.3 de la [Orden HAP/2105/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-12147), en desarrollo del art. 6 de la [Ley Orgánica 2/2012](https://www.boe.es/buscar/act.php?id=BOE-A-2012-5730).
- **Territorios forales**: en Álava y Navarra la liquidación municipal no se canaliza a CONPREL por la vía común (tutela financiera de la Diputación Foral y del Gobierno de Navarra), y en Bizkaia y Gipuzkoa tampoco en 2013-2014. Esos casos **no se cuentan como incumplimientos**: aparecerían casi al 100 % por un efecto del régimen foral, no de cada ayuntamiento.
- Solo se consideran los ayuntamientos; diputaciones, mancomunidades y entidades menores tienen sus propias obligaciones y no se incluyen aquí.

<LastRefreshed prefix="Datos actualizados" />
