---
title: Publicidad activa
description: "¿Publican y remiten a tiempo las administraciones lo que les obliga la ley? Evaluaciones oficiales por entidad (Consejo de Transparencia, Canarias, Cataluña y Murcia) y una medición propia de los más de 8.100 ayuntamientos, las diputaciones y las comunidades, con los incumplimientos señalados y la comparación por partido."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql age
SELECT CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio, puntuacion AS icio, gobernante, familia, url_fuente
FROM mother.transparencia_publicidad_activa
WHERE tipo_administracion = 'Administración General del Estado'
ORDER BY anio
```

```sql ctbg_ccaa
SELECT entidad, familia,
    max(CASE WHEN anio = 2020 THEN puntuacion END) AS icio_2020,
    max(CASE WHEN anio = 2021 THEN puntuacion END) AS icio_2021,
    max(CASE WHEN anio = 2021 THEN puntuacion END) - max(CASE WHEN anio = 2020 THEN puntuacion END) AS mejora
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Comunidad autónoma'
GROUP BY entidad, familia
ORDER BY icio_2021 DESC
```

```sql ctbg_ccaa_largo
SELECT entidad, CAST(CAST(anio AS INTEGER) AS VARCHAR) AS evaluacion, puntuacion AS icio
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Comunidad autónoma'
ORDER BY entidad, anio
```

```sql ctbg_ayto
SELECT entidad,
    max(familia) FILTER (WHERE anio = 2021) AS familia,
    max(poblacion) AS poblacion,
    max(CASE WHEN anio = 2020 THEN puntuacion END) AS icio_2020,
    max(CASE WHEN anio = 2021 THEN puntuacion END) AS icio_2021,
    max(url_fuente) FILTER (WHERE anio = 2021) AS informe
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Ayuntamiento'
GROUP BY entidad
ORDER BY icio_2021 DESC
```

```sql ctbg_resumen
SELECT
    avg(puntuacion) FILTER (WHERE tipo_administracion = 'Comunidad autónoma' AND anio = 2021) AS media_ccaa,
    avg(puntuacion) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021) AS media_ayto,
    count(*) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021) AS n_ayto,
    count(*) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021 AND puntuacion < 50) AS ayto_menos_50
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
```

```sql itc
-- ITCanarias con etiqueta corta de periodo (los dos últimos no son años naturales)
SELECT *,
    CASE WHEN periodo LIKE '2022%' THEN '2022/23'
         WHEN periodo LIKE '%2023%2024%' THEN '2023/24'
         ELSE periodo END AS etiqueta
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Comisionado de Transparencia de Canarias'
```

```sql itc_ultimo
SELECT max(orden_periodo) AS orden, max(etiqueta) FILTER (WHERE orden_periodo = (SELECT max(orden_periodo) FROM ${itc})) AS etiqueta
FROM ${itc}
```

```sql itc_evolucion
SELECT CAST(orden_periodo AS INTEGER) AS orden, etiqueta, tipo_administracion,
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE estado = 'evaluada') AS evaluadas,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras
FROM ${itc}
WHERE tipo_administracion IN ('Ayuntamiento', 'Cabildo insular', 'Comunidad autónoma', 'Entes dependientes y otros')
GROUP BY ALL
ORDER BY orden, tipo_administracion
```

```sql itc_aytos_serie
SELECT CAST(orden_periodo AS INTEGER) AS orden, etiqueta,
    avg(puntuacion) AS media,
    median(puntuacion) AS mediana,
    quantile_cont(puntuacion, 0.25) AS p25,
    quantile_cont(puntuacion, 0.75) AS p75,
    count(*) FILTER (WHERE puntuacion >= 90) AS notable_alto,
    count(*) FILTER (WHERE puntuacion < 50 OR estado = 'incumplidora') AS suspenso,
    count(*) AS total
FROM ${itc}
WHERE tipo_administracion = 'Ayuntamiento'
GROUP BY ALL
ORDER BY orden
```

```sql itc_aytos_ultimo
SELECT
    cod_mun, entidad, regexp_replace(entidad, '^Ayuntamiento de ', '') AS municipio,
    provincia,
    poblacion, estado, puntuacion, puntuacion_original, familia, gobernante,
    CASE WHEN estado = 'incumplidora' THEN 'No rindió la evaluación' ELSE 'Evaluado' END AS situacion
FROM ${itc}
WHERE tipo_administracion = 'Ayuntamiento' AND orden_periodo = (SELECT orden FROM ${itc_ultimo})
ORDER BY puntuacion DESC NULLS LAST
```

```sql itc_resumen
SELECT
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE puntuacion >= 90) AS altos,
    count(*) FILTER (WHERE puntuacion < 50 OR estado = 'incumplidora') AS bajos,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras,
    count(*) AS total
FROM ${itc_aytos_ultimo}
```

```sql itc_institucionales
SELECT entidad, tipo_administracion,
    max(puntuacion) FILTER (WHERE orden_periodo = (SELECT orden FROM ${itc_ultimo})) AS ultima,
    max(puntuacion) FILTER (WHERE orden_periodo = 2) AS en_2017,
    max(familia) FILTER (WHERE orden_periodo = (SELECT orden FROM ${itc_ultimo})) AS familia
FROM ${itc}
WHERE tipo_administracion IN ('Cabildo insular', 'Comunidad autónoma')
GROUP BY ALL
ORDER BY ultima DESC
```

```sql itc_entes
SELECT tipo_entidad,
    count(*) AS entidades,
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras
FROM ${itc}
WHERE tipo_administracion = 'Entes dependientes y otros' AND orden_periodo = (SELECT orden FROM ${itc_ultimo})
GROUP BY tipo_entidad
HAVING count(*) >= 3
ORDER BY media
```

```sql itc_familia
-- Observado frente a esperado: el esperado de cada ayuntamiento y evaluación es la media
-- de los ayuntamientos canarios de su mismo tramo de población en esa misma evaluación.
-- El intervalo usa el número de municipios distintos (no de evaluaciones), porque el
-- mismo ayuntamiento aparece varios años y sus notas no son independientes.
WITH base AS (
    SELECT *,
        CASE WHEN poblacion < 5000 THEN 'a' WHEN poblacion < 20000 THEN 'b' ELSE 'c' END AS tramo
    FROM ${itc}
    WHERE tipo_administracion = 'Ayuntamiento' AND estado = 'evaluada'
),
esperado AS (
    SELECT *, avg(puntuacion) OVER (PARTITION BY orden_periodo, tramo) AS esperada
    FROM base
)
SELECT
    coalesce(familia, 'Sin atribuir') AS familia,
    count(*) AS evaluaciones,
    count(DISTINCT cod_mun) AS municipios,
    avg(puntuacion) AS observada,
    avg(esperada) AS esperada,
    avg(puntuacion - esperada) AS diferencia,
    avg(puntuacion - esperada) - 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) AS ic_bajo,
    avg(puntuacion - esperada) + 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) AS ic_alto,
    CASE
        WHEN count(DISTINCT cod_mun) < 10 THEN 'Muestra pequeña: no concluyente'
        WHEN avg(puntuacion - esperada) + 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) < 0 THEN 'Por debajo de lo esperable'
        WHEN avg(puntuacion - esperada) - 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) > 0 THEN 'Por encima de lo esperable'
        ELSE 'Dentro de lo esperable'
    END AS lectura
FROM esperado
GROUP BY ALL
HAVING count(*) >= 20
ORDER BY diferencia DESC
```

```sql itc_incumplidoras
SELECT etiqueta AS evaluacion, entidad, tipo_entidad, entidad_principal
FROM ${itc}
WHERE estado = 'incumplidora' AND orden_periodo >= (SELECT orden FROM ${itc_ultimo}) - 1
ORDER BY orden_periodo DESC, tipo_entidad, entidad
```

```sql mp_entidades
SELECT * FROM mother.transparencia_cumplimiento_entidad
```

```sql mp_resumen
SELECT
    count(*) FILTER (WHERE indice IS NOT NULL) AS entidades,
    count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND indice IS NOT NULL) AS ayuntamientos,
    count(*) FILTER (WHERE n_incumplimientos_destacados > 0) AS con_incumplimientos,
    count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND n_incumplimientos_destacados > 0) AS aytos_con_incumplimientos,
    100.0 * count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND n_incumplimientos_destacados > 0)
        / nullif(count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento'), 0) AS pct_aytos_incumplimientos,
    median(indice) FILTER (WHERE tipo_entidad = 'Ayuntamiento') AS mediana_aytos,
    count(*) FILTER (WHERE tipo_entidad = 'Ayuntamiento' AND poblacion >= 20000 AND n_incumplimientos_destacados > 0) AS grandes_con_incumplimientos
FROM ${mp_entidades}
```

```sql mp_destacados
-- Lo que se señala arriba: comunidades, diputaciones y ayuntamientos de 20.000 habitantes o más
SELECT tipo_entidad, nombre_entidad, provincia, ccaa, poblacion, incumplimientos, n_incumplimientos_destacados,
    gobernante_actual, familia_actual, cod_mun
FROM ${mp_entidades}
WHERE n_incumplimientos_destacados > 0
  AND (tipo_entidad <> 'Ayuntamiento' OR poblacion >= 20000)
ORDER BY CASE tipo_entidad WHEN 'Comunidad autónoma' THEN 1 WHEN 'Diputación provincial' THEN 2 WHEN 'Cabildo o consell insular' THEN 3 ELSE 4 END,
    n_incumplimientos_destacados DESC, poblacion DESC
```

```sql mp_obligaciones
SELECT
    c.obligacion_nombre AS obligacion,
    c.tipo_entidad,
    max(c.periodo) AS ultimo_periodo,
    count(*) AS entidades,
    100.0 * avg(c.puntuacion) AS cumplimiento,
    count(*) FILTER (WHERE c.estado IN ('en_plazo', 'consta')) AS en_plazo,
    count(*) FILTER (WHERE c.estado = 'fuera_plazo' OR (c.estado = 'con_registros' AND c.n_fuera_plazo > 0)) AS con_retraso,
    count(*) FILTER (WHERE c.estado = 'no_consta') AS no_consta,
    coalesce(median(c.dias_retraso) FILTER (WHERE c.estado = 'fuera_plazo'), median(c.mediana_dias)) AS mediana_retraso,
    100.0 * count(*) / any_value(t.n) AS cobertura,
    CASE WHEN any_value(c.bloque) = 'pago' THEN 'No: mide si paga a tiempo, no si publica'
         WHEN count(*) >= 0.8 * any_value(t.n) THEN 'Sí'
         ELSE 'Todavía no (' || CAST(round(100.0 * count(*) / any_value(t.n)) AS INTEGER) || ' % medidas)' END AS en_indice
FROM mother.transparencia_cumplimiento c
JOIN (SELECT tipo_entidad, count(DISTINCT cod_entidad) AS n FROM mother.transparencia_cumplimiento GROUP BY 1) t USING (tipo_entidad)
WHERE c.es_ultimo
GROUP BY ALL
ORDER BY c.tipo_entidad, en_indice DESC, cumplimiento
```

```sql mp_tramos
SELECT tramo_poblacion, min(tramo_orden) AS orden,
    count(*) FILTER (WHERE indice IS NOT NULL) AS ayuntamientos,
    avg(indice) AS indice_medio,
    100.0 * count(*) FILTER (WHERE n_incumplimientos_destacados > 0) / count(*) AS pct_incumplimientos
FROM (
    SELECT *, CASE tramo_poblacion WHEN '<1.000' THEN 1 WHEN '1.000-5.000' THEN 2 WHEN '5.000-20.000' THEN 3
        WHEN '20.000-100.000' THEN 4 ELSE 5 END AS tramo_orden
    FROM ${mp_entidades} WHERE tipo_entidad = 'Ayuntamiento'
)
GROUP BY ALL
ORDER BY orden
```

```sql mp_provincias
SELECT cod_prov, any_value(provincia) AS provincia,
    count(*) AS ayuntamientos,
    100.0 * count(*) FILTER (WHERE n_incumplimientos_destacados > 0) / count(*) AS pct_incumplimientos,
    avg(indice) AS indice_medio
FROM ${mp_entidades}
WHERE tipo_entidad = 'Ayuntamiento' AND cod_prov IS NOT NULL
GROUP BY cod_prov
```

```sql mp_ranking
SELECT nombre_entidad AS municipio, provincia, poblacion, indice, obligaciones_medidas, n_incumplimientos_destacados,
    incumplimientos, familia_actual, media_tramo_espana,
    '/territorios/municipios?m=' || cod_mun AS enlace
FROM ${mp_entidades}
WHERE tipo_entidad = 'Ayuntamiento' AND indice IS NOT NULL
ORDER BY indice, poblacion DESC
```

```sql mp_familia
-- Observado frente a esperado: lo esperado de cada obligación es la media de los
-- ayuntamientos de su mismo tramo de población y comunidad en ese mismo periodo.
-- IC con el número de municipios distintos (un mismo ayuntamiento aporta varias obligaciones).
WITH base AS (
    SELECT *, avg(puntuacion) OVER (PARTITION BY obligacion, periodo, tramo_poblacion, cod_ccaa) AS esperada
    FROM mother.transparencia_cumplimiento
    WHERE tipo_entidad = 'Ayuntamiento' AND puntuacion IS NOT NULL AND anio >= year(current_date) - 4
),
por_mun AS (
    SELECT coalesce(familia_en_plazo, 'Sin atribuir') AS familia, cod_mun,
        avg(puntuacion - esperada) AS dif, avg(puntuacion) AS obs, avg(esperada) AS esp, count(*) AS n
    FROM base GROUP BY ALL
)
SELECT familia,
    count(*) AS municipios,
    sum(n) AS mediciones,
    100 * avg(obs) AS observada,
    100 * avg(esp) AS esperada,
    100 * avg(dif) AS diferencia,
    100 * (avg(dif) - 1.96 * stddev_samp(dif) / sqrt(count(*))) AS ic_bajo,
    100 * (avg(dif) + 1.96 * stddev_samp(dif) / sqrt(count(*))) AS ic_alto,
    CASE
        WHEN count(*) < 30 THEN 'Muestra pequeña: no concluyente'
        WHEN avg(dif) + 1.96 * stddev_samp(dif) / sqrt(count(*)) < 0 THEN 'Por debajo de lo esperable'
        WHEN avg(dif) - 1.96 * stddev_samp(dif) / sqrt(count(*)) > 0 THEN 'Por encima de lo esperable'
        ELSE 'Dentro de lo esperable'
    END AS lectura
FROM por_mun
GROUP BY familia
HAVING count(*) >= 30
ORDER BY diferencia DESC
```

# 📋 Publicidad activa: ¿publican las administraciones lo que les obliga la ley?

{#if mp_destacados.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Administraciones que no constan al día en lo que deben remitir</p>
    <p class="mt-2 text-red-900 dark:text-red-100">Comunidades, diputaciones y ayuntamientos de 20.000 habitantes o más con alguna obligación cuyo plazo venció hace más de tres meses y de la que <b>no consta nada</b> en el registro oficial. En total, {formatNumber(mp_resumen[0]?.con_incumplimientos, 0)} administraciones de todos los tamaños están en esa situación.</p>
    {#each mp_destacados.slice(0, 12) as d}
    <div class="mt-4">
        <p class="text-xl font-extrabold leading-tight text-red-700 dark:text-red-300">{#if d.cod_mun}<a class="underline" href="/territorios/municipios?m={d.cod_mun}">{d.nombre_entidad}</a>{:else}{d.nombre_entidad}{/if} <span class="whitespace-nowrap text-base font-semibold">({d.tipo_entidad}{d.provincia ? ', ' + d.provincia : ''}{d.poblacion ? ', ' + formatNumber(d.poblacion, 0) + ' hab.' : ''})</span></p>
        <p class="mt-1 text-red-900 dark:text-red-100">No consta: {d.incumplimientos}.</p>
    </div>
    {/each}
    {#if mp_destacados.length > 12}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">Y {mp_destacados.length - 12} más de ese tamaño. Están todas en la <a class="font-semibold underline" href="#medición-propia-todas-las-administraciones">tabla de la medición propia</a>.</p>
    {/if}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">«No consta» significa que no figura en la fuente oficial a la fecha de la última descarga, no que se haya probado que no se hizo. Cada caso enlaza a su ficha con la fuente.</p>
</div>
{/if}

Desde 2014, la [Ley 19/2013 de transparencia](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) obliga a todas las administraciones a **publicar por su cuenta**, sin que nadie lo pida, una lista de informaciones en su portal de transparencia: quién manda y cuánto cobra, qué normas prepara, qué contratos y subvenciones concede, sus presupuestos y cuentas, su patrimonio. Es lo que se llama **publicidad activa**. Además, deben **remitir** sus cuentas, presupuestos, contratos y subvenciones a registros oficiales en plazos fijados por ley. Esta página reúne las **evaluaciones oficiales** que hay y una **medición propia** de todas las administraciones.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">La respuesta corta</p>
<p class="mb-1">No existe una evaluación oficial <b>única y homogénea</b> para todas las administraciones. Cada órgano de control evalúa a <b>su ámbito</b>, con su propio método. Solo publican notas por entidad cuatro: el Consejo de Transparencia y Buen Gobierno (el Estado y su sector público), el Comisionado de Canarias, el Síndic de Greuges de Catalunya y el Consejo de Murcia. Así quedan cubiertos los <b>ayuntamientos de Canarias, Cataluña y Murcia</b> y casi nadie más.</p>
<p class="mb-0">Para llegar al resto, SpainFacts <b>mide por su cuenta</b> a los más de 8.100 ayuntamientos, las diputaciones y las comunidades. Comprueba en los registros oficiales si cada obligación consta y si llegó en plazo. Hoy {formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} ayuntamientos ({formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %) tienen alguna obligación vencida hace más de tres meses de la que no consta nada. Las notas de evaluadores distintos <b>no son comparables entre sí</b>, ni con la medición propia.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Portal de la AGE"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="de la información obligatoria cumplida en {age[age.length - 1]?.anio} (ICIO)"
        source="Consejo de Transparencia y Buen Gobierno"
        sparklineData={age.map(d => ({...d, y: d.icio}))}
    />
    <KpiCard
        title="Comunidades evaluadas por el CTBG"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="ICIO medio de las 8 con convenio, revisión de 2021"
        source="Consejo de Transparencia y Buen Gobierno"
    />
    <KpiCard
        title="Ayuntamientos canarios"
        value={itc_resumen[0]?.media}
        formattedValue="{formatNumber(itc_resumen[0]?.media / 10, 2)} de 10"
        period="nota media en el Índice de Transparencia de Canarias ({itc_ultimo[0]?.etiqueta})"
        source="Comisionado de Transparencia de Canarias"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.media / 10}))}
    />
    <KpiCard
        title="Ayuntamientos canarios con nota baja"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="de {formatNumber(itc_resumen[0]?.total, 0)}: por debajo de 5 o sin rendir la evaluación ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.suspenso}))}
    />
</Grid>

## Qué obliga la ley

La Ley 19/2013 (arts. 5 a 8) agrupa las obligaciones en tres bloques, y las leyes autonómicas de transparencia añaden otras para sus administraciones y ayuntamientos:

- **Información institucional, organizativa y de planificación**: funciones, normativa, organigrama, responsables y su trayectoria, planes y programas con su grado de cumplimiento.
- **Información de relevancia jurídica**: directrices e instrucciones, anteproyectos de ley y proyectos de reglamento, memorias e informes de los expedientes normativos.
- **Información económica, presupuestaria y estadística**: contratos (incluidos los menores), convenios, encomiendas, subvenciones y ayudas, presupuestos y su ejecución, cuentas e informes de auditoría, retribuciones de altos cargos, compatibilidades, bienes patrimoniales y estadísticas de calidad de los servicios.

La información debe ser **clara, estructurada, actualizada y reutilizable** (art. 5). Incumplir estas obligaciones de forma reiterada es infracción grave según la ley estatal (art. 9.3), pero en la práctica las sanciones son excepcionales: los órganos de control **recomiendan y evalúan**, no multan.

## Quién evalúa y qué publica

| Órgano de control | A quién evalúa | Qué publica por entidad | ¿Se usa aquí? |
|---|---|---|---|
| [Consejo de Transparencia y Buen Gobierno](https://consejodetransparencia.es/evaluacion) (CTBG) | AGE y sector público estatal, órganos constitucionales, partidos, sindicatos, entidades subvencionadas; y las comunidades y ciudades autónomas con convenio (Asturias, Cantabria, Castilla-La Mancha, Extremadura, La Rioja, Ceuta y Melilla; Madrid en 2020-2021) y algunos de sus ayuntamientos | Índice de Cumplimiento de la Información Obligatoria (ICIO, 0-100 %, metodología MESTA) en un informe Word por entidad; sin tabla de datos | Sí: Portal de la AGE, 8 comunidades, 11 ayuntamientos y, desde 2022, la tabla de los informes agregados (sector público estatal, entidades privadas, corporaciones) |
| [Comisionado de Transparencia de Canarias](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Todo el sector público canario (Gobierno, cabildos, ayuntamientos, universidades y sus entes) y entidades privadas subvencionadas | Índice de Transparencia de Canarias (ITCanarias, 0-10) en una tabla Excel con todas las entidades desde 2016 (CC BY 4.0) | Sí: sector público |
| [Consejo de la Transparencia de la Región de Murcia](https://comisionadotransparencia.carm.es/informes-de-evaluacion) | Administración regional, sus 45 ayuntamientos y su sector público, partidos, sindicatos, federaciones… | Índice de cumplimiento de la publicidad activa (ICPA, 0-10) de 2020 a 2023, en una tabla del anexo del informe de 2023 (PDF). Es una autoevaluación voluntaria que el Consejo verifica | Sí: tabla del anexo |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/ca/page.asp?id=904) | Los 947 ayuntamientos catalanes, diputaciones, consejos comarcales, departamentos de la Generalitat, universidades y órganos de control | Índice de desarrollo de la publicidad activa (IDPAC, 0-100), revisado por el propio Síndic, en datos abiertos (CSV, CC0) desde la edición de 2026 | Sí |
| Consejos y comisionados de Andalucía, Aragón, Castilla y León, Comunitat Valenciana, Galicia, Madrid, Navarra, País Vasco y otros | Su comunidad y sus entidades locales | Memorias anuales, planes de control y resoluciones, en PDF. No hemos encontrado un índice publicado por entidad. Madrid ha empezado a evaluar a todos sus ayuntamientos (resultados previstos en su memoria de 2026) | No |

También hay rankings de la sociedad civil (Dyntra, el Mapa Infoparticipa de la Universitat Autònoma de Barcelona, los antiguos índices de Transparencia Internacional España). **No se usan aquí**: no son fuentes oficiales y no hemos comprobado que su licencia permita reutilizar los datos.

## Administración General del Estado

El CTBG evalúa cada año el [Portal de la Transparencia](https://transparencia.gob.es/) de la AGE. El ICIO mide, para cada obligación, si la información se publica y con qué calidad (forma, fecha de actualización, accesibilidad, reutilización).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="Portal de la Transparencia de la AGE: índice de cumplimiento (%)"
    markers=true
    sort=false
/>

Las cinco evaluaciones corresponden a Gobiernos de Pedro Sánchez, así que **no permiten comparar partidos** en el Gobierno central. El CTBG evalúa además cada año, por separado, a cientos de organismos, empresas y fundaciones del sector público estatal; sus notas están en informes individuales y no se han incorporado todavía.

## Comunidades autónomas y ayuntamientos evaluados por el CTBG

Las comunidades que no crearon su propio órgano de control firmaron un convenio para que el CTBG vigile su transparencia. En 2020 el CTBG evaluó sus portales y en 2021 revisó si habían aplicado sus recomendaciones.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Índice de cumplimiento de la información obligatoria (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Comunidad o ciudad autónoma" />
    <Column id=familia title="Partido del presidente" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Mejora (puntos)" fmt=num1 contentType=delta />
</DataTable>

Todas mejoraron tras las recomendaciones. Con solo ocho comunidades, gobernadas por cuatro partidos distintos, **no tiene sentido comparar partidos**: cualquier diferencia puede deberse a una sola comunidad.

Los ayuntamientos evaluados por el CTBG son pocos y no forman una muestra representativa (los eligió el Consejo). Aun así, muestran lo lejos que puede quedar un ayuntamiento grande de cumplir: {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} de {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} seguían por debajo del 50 % en la revisión de 2021.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Ayuntamiento" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=familia title="Partido del alcalde (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Canarias: todo el sector público, entidad por entidad

Canarias es la única comunidad que publica **cada año y en datos abiertos** la nota de todas sus administraciones. El Comisionado de Transparencia envía un cuestionario sobre las obligaciones de la ley canaria (más exigente que la estatal), comprueba las respuestas en los portales y calcula el Índice de Transparencia de Canarias (0 a 10). Una entidad que no rellena la evaluación figura como **incumplidora**.

<LineChart
    data={itc_evolucion}
    x=etiqueta
    y=media
    series=tipo_administracion
    yFmt=num1
    yMin=0
    yMax=100
    sort=false
    markers=true
    title="Índice de Transparencia de Canarias, nota media (sobre 100)"
/>

<p class="text-xs text-gray-500">Las dos últimas evaluaciones no son años naturales: «2022/23» cubre 2022 y el primer semestre de 2023; «2023/24», el segundo semestre de 2023 y 2024. La nota se muestra sobre 100 para compararla con la escala de la gráfica (7,5 de 10 = 75).</p>

La mejora es clara: la nota media de los ayuntamientos pasó de {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} en la primera evaluación a {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)} en la última. Parte de la subida refleja que las entidades aprenden a responder el cuestionario, y muchas ya están en el máximo, así que las notas altas distinguen poco entre ellas.

### Ayuntamientos, {itc_ultimo[0]?.etiqueta}

<MapaEspana
    data={itc_aytos_ultimo}
    geoJsonUrl="/geo/municipios/05.geojson"
    geoId="cod_mun"
    areaCol="cod_mun"
    value="puntuacion"
    valueFmt="num1"
    min={50}
    max={100}
    colorPalette={['#b91c1c', '#fde68a', '#15803d']}
    height={420}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Nota (sobre 100)', fmt: 'num1'},
        {id: 'familia', title: 'Partido del alcalde'},
        {id: 'situacion', title: 'Situación'}
    ]}
/>

<p class="text-xs text-gray-500">La escala de color empieza en 50: por debajo, todos se ven en rojo. Un municipio en gris no rindió la evaluación.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=puntuacion_original title="Nota (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Situación" />
    <Column id=familia title="Partido del alcalde" />
</DataTable>

### Gobierno de Canarias y cabildos

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Entidad" />
    <Column id=tipo_administracion title="Tipo" />
    <Column id=en_2017 title="Nota 2017 (sobre 100)" fmt=num1 />
    <Column id=ultima title="Última nota (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="Partido del presidente" />
</DataTable>

<p class="text-xs text-gray-500">Los cabildos no se atribuyen a un partido: no hay todavía un registro oficial de sus presidentes en SpainFacts.</p>

### Empresas, organismos y fundaciones públicas

Donde más se incumple no es en las administraciones, sino en sus **entes dependientes**: empresas públicas, fundaciones, consorcios y corporaciones de derecho público, que también están obligados.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Tipo de entidad" />
    <Column id=entidades title="Entidades" fmt=num0 />
    <Column id=media title="Nota media (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="No rindieron la evaluación" fmt=num0 />
</DataTable>

<details>
<summary>Entidades que no rindieron la evaluación en las dos últimas ediciones</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Evaluación" />
    <Column id=entidad title="Entidad" />
    <Column id=tipo_entidad title="Tipo" />
    <Column id=entidad_principal title="Depende de" />
</DataTable>

</details>

```sql sindic_aytos
SELECT cod_mun, municipio, provincia, poblacion, puntuacion, familia, gobernante,
    '/territorios/municipios?m=' || cod_mun AS enlace
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Síndic de Greuges de Catalunya' AND tipo_administracion = 'Ayuntamiento'
ORDER BY puntuacion DESC
```

```sql sindic_tramos
SELECT CASE WHEN poblacion < 1000 THEN '<1.000' WHEN poblacion < 5000 THEN '1.000-5.000'
            WHEN poblacion < 20000 THEN '5.000-20.000' WHEN poblacion < 100000 THEN '20.000-100.000' ELSE '>100.000' END AS tramo,
    min(poblacion) AS orden, count(*) AS ayuntamientos, avg(puntuacion) AS media,
    count(*) FILTER (WHERE puntuacion < 50) AS menos_50
FROM ${sindic_aytos}
GROUP BY 1 ORDER BY orden
```

```sql sindic_otros
SELECT entidad, tipo_administracion, tipo_entidad, puntuacion
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Síndic de Greuges de Catalunya' AND tipo_administracion <> 'Ayuntamiento'
ORDER BY tipo_administracion, puntuacion
```

```sql murcia_aytos
SELECT cod_mun, municipio, poblacion,
    max(puntuacion) FILTER (WHERE anio = 2020) AS n2020,
    max(puntuacion) FILTER (WHERE anio = 2021) AS n2021,
    max(puntuacion) FILTER (WHERE anio = 2022) AS n2022,
    max(puntuacion) FILTER (WHERE anio = 2023) AS n2023,
    count(*) FILTER (WHERE estado = 'no_participo') AS no_participo,
    max(familia) FILTER (WHERE anio = 2023) AS familia
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de la Transparencia de la Región de Murcia' AND tipo_administracion = 'Ayuntamiento'
GROUP BY ALL
ORDER BY n2023 DESC NULLS LAST
```

```sql murcia_serie
SELECT CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    count(*) FILTER (WHERE estado = 'evaluada') AS evaluados,
    count(*) FILTER (WHERE estado = 'no_participo') AS no_participaron,
    avg(puntuacion) AS media
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de la Transparencia de la Región de Murcia' AND tipo_administracion = 'Ayuntamiento'
GROUP BY ALL ORDER BY anio
```

```sql spe_serie
SELECT CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio, tipo_entidad AS grupo, avg(puntuacion) AS media, count(*) AS entidades
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
  AND tipo_administracion IN ('Sector público estatal', 'Entidades privadas')
  AND periodo NOT LIKE '%evaluación)'
GROUP BY ALL ORDER BY anio, grupo
```

```sql spe_ultimo
SELECT entidad, tipo_entidad AS grupo, CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio, puntuacion AS icio
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
  AND tipo_administracion IN ('Sector público estatal', 'Entidades privadas', 'Corporaciones de derecho público')
QUALIFY row_number() OVER (PARTITION BY entidad ORDER BY anio DESC, periodo DESC) = 1
ORDER BY icio
```

## Cataluña: los 947 ayuntamientos, revisados por el Síndic

El Síndic de Greuges revisa **él mismo** el portal de cada ayuntamiento catalán y publica el resultado en datos abiertos: es la única evaluación externa de todos los ayuntamientos de una comunidad. El índice de desarrollo de la publicidad activa (IDPAC, 0-100) combina el contenido obligatorio (70 %) y la calidad del espacio web (30 %). La edición de 2026 se hizo entre enero y mayo.

<DataTable data={sindic_tramos} rows=all>
    <Column id=tramo title="Habitantes" />
    <Column id=ayuntamientos title="Ayuntamientos" fmt=num0 />
    <Column id=media title="IDPAC medio" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=menos_50 title="Por debajo de 50" fmt=num0 />
</DataTable>

<DataTable data={sindic_aytos} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=familia title="Partido del alcalde" />
</DataTable>

<details>
<summary>Generalitat, diputaciones, consejos comarcales y otros</summary>

<DataTable data={sindic_otros} search=true rows=15>
    <Column id=entidad title="Entidad" />
    <Column id=tipo_entidad title="Tipo" />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
</DataTable>

</details>

## Región de Murcia

El Consejo de la Transparencia de la Región de Murcia publica el índice de cumplimiento de la publicidad activa (ICPA) de cada entidad que se presta a evaluarse. La entidad rellena la evaluación en una plataforma y el Consejo la verifica. **Es voluntario**: un ayuntamiento que no participó figura como «no participó», nunca con un cero.

<BarChart
    data={murcia_serie}
    x=anio
    y={['evaluados', 'no_participaron']}
    type=stacked
    title="Ayuntamientos murcianos evaluados y que no participaron"
    sort=false
/>

<DataTable data={murcia_aytos} search=true rows=15>
    <Column id=municipio title="Municipio" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=n2020 title="2020" fmt=num1 />
    <Column id=n2021 title="2021" fmt=num1 />
    <Column id=n2022 title="2022" fmt=num1 />
    <Column id=n2023 title="2023 (sobre 100)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
    <Column id=no_participo title="Años sin participar" fmt=num0 />
    <Column id=familia title="Partido del alcalde (2023)" />
</DataTable>

<p class="text-xs text-gray-500">Nota original 0-10, mostrada sobre 100. Celda vacía: no participó o no había sido convocado.</p>

## Sector público estatal

Cada año el Consejo de Transparencia evalúa a organismos, empresas y fundaciones estatales, a entidades privadas que reciben subvenciones y a corporaciones como los colegios profesionales. Sus informes agregados traen una tabla con el índice de cumplimiento (ICIO) de cada una.

<LineChart
    data={spe_serie}
    x=anio
    y=media
    series=grupo
    yFmt=num1
    yMin=0
    yMax=100
    markers=true
    sort=false
    title="ICIO medio de las entidades evaluadas (%)"
/>

<p class="text-xs text-gray-500">Cada año se evalúa a entidades distintas (225 del sector público en 2025, frente a 74 en 2022), así que la media no sigue siempre a las mismas.</p>

<DataTable data={spe_ultimo} search=true rows=15>
    <Column id=entidad title="Entidad" />
    <Column id=grupo title="Grupo" />
    <Column id=anio title="Última evaluación" />
    <Column id=icio title="ICIO (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Por partido en Canarias

Con las evaluaciones oficiales, la comparación solo es posible con los **ayuntamientos canarios**: son 88, se evalúan todos, con el mismo método, desde 2016. Para cada ayuntamiento y evaluación se calcula la nota **esperable**: la media de los ayuntamientos canarios de su mismo tamaño (menos de 5.000, de 5.000 a 20.000 y más de 20.000 habitantes) en esa misma evaluación. Después se compara la nota media de los gobernados por cada partido con su esperable.

```sql itc_familia_grafico
SELECT familia, diferencia FROM ${itc_familia}
```

<BarChart
    data={itc_familia_grafico}
    x=familia
    y=diferencia
    swapXY=true
    yFmt=num1
    title="Nota observada menos esperable (puntos sobre 100)"
    fillColor="#0f766e"
    sort=false
/>

<DataTable data={itc_familia} rows=all>
    <Column id=familia title="Partido del alcalde" />
    <Column id=evaluaciones title="Evaluaciones" fmt=num0 />
    <Column id=municipios title="Municipios distintos" fmt=num0 />
    <Column id=observada title="Nota media" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferencia" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num1 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num1 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Solo partidos con al menos 20 evaluaciones; los ayuntamientos que no rindieron la evaluación no tienen nota y no entran en el cálculo. El intervalo de confianza se calcula con el número de municipios distintos, no de evaluaciones, porque las notas de un mismo ayuntamiento en años seguidos no son independientes. «Sin detalle en la fuente» agrupa alcaldías elegidas en listas que el registro oficial etiqueta de forma genérica; «Independientes y locales», agrupaciones de electores. Una diferencia entre partidos no prueba que se deba al partido: influyen la plantilla, los medios técnicos, la isla y la persona que gobierna.</p>

Para las comunidades autónomas y el Gobierno central **no hay muestra suficiente**: una sola evaluación por comunidad y año, y en el caso del Estado un único Gobierno en todo el periodo evaluado.

## Medición propia: todas las administraciones

Como casi nadie evalúa a la mayoría de administraciones, **lo medimos nosotros** con el mismo método para todas. No puntuamos el portal web a ojo. Comprobamos en los **registros oficiales que traen fecha** si cada obligación legal consta y si llegó dentro de su plazo. Los registros son la Base de Datos Nacional de Subvenciones, la Plataforma de Contratación, el Tribunal de Cuentas y Hacienda. Cada obligación puntúa 1 si consta a tiempo, 0,5 si consta tarde y 0 si no consta con el plazo vencido. El índice de cada administración (0-100) es la media de su último periodo medido. Los criterios, la base legal y el código de cada indicador están en [Fuentes › Datos de elaboración propia](/fuentes#datos-de-elaboración-propia).

<Grid cols=4>
    <KpiCard
        title="Administraciones medidas"
        value={mp_resumen[0]?.entidades}
        formattedValue={formatNumber(mp_resumen[0]?.entidades, 0)}
        period="{formatNumber(mp_resumen[0]?.ayuntamientos, 0)} ayuntamientos y {formatNumber(mp_resumen[0]?.entidades - mp_resumen[0]?.ayuntamientos, 0)} diputaciones, cabildos y comunidades"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="Ayuntamientos con algo vencido que no consta"
        value={mp_resumen[0]?.pct_aytos_incumplimientos}
        formattedValue="{formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %"
        period="{formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} ayuntamientos, más de 3 meses después del plazo"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="De 20.000 habitantes o más"
        value={mp_resumen[0]?.grandes_con_incumplimientos}
        formattedValue={formatNumber(mp_resumen[0]?.grandes_con_incumplimientos, 0)}
        period="ayuntamientos grandes con alguna obligación vencida que no consta"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="Índice mediano de los ayuntamientos"
        value={mp_resumen[0]?.mediana_aytos}
        formattedValue="{formatNumber(mp_resumen[0]?.mediana_aytos, 1)} de 100"
        period="media del último periodo de cada obligación"
        source="SpainFacts (elaboración propia)"
    />
</Grid>

### Obligación por obligación

<DataTable data={mp_obligaciones} rows=all groupBy=tipo_entidad>
    <Column id=tipo_entidad title="Administración" />
    <Column id=obligacion title="Obligación" />
    <Column id=ultimo_periodo title="Último periodo" />
    <Column id=entidades title="Medidas" fmt=num0 />
    <Column id=cumplimiento title="Cumplimiento (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=con_retraso title="Con retraso" fmt=num0 />
    <Column id=no_consta title="No consta" fmt=num0 />
    <Column id=mediana_retraso title="Días (mediana)" fmt=num0 />
    <Column id=en_indice title="En el índice" />
</DataTable>

<p class="text-xs text-gray-500">«Días (mediana)»: en las obligaciones únicas, el retraso de las que llegaron tarde; en contratos y subvenciones, lo que tarda en publicarse o registrarse la administración típica. Se cuenta el último periodo de cada administración con el plazo vencido. Las administraciones que la fuente no mide (por ejemplo, las que remiten por el cauce foral) no se cuentan. Una obligación entra en el índice y en la lista de incumplimientos cuando mide al menos al 80 % de las administraciones de su tipo; hasta entonces, como el rastreo del Tribunal de Cuentas que va provincia a provincia, solo se ve aquí y en cada ficha.</p>

### Por tamaño y provincia

Los ayuntamientos pequeños son los que más fallan: muchos no tienen ni secretario a tiempo completo. Por eso cada ayuntamiento se compara siempre con los de su tamaño.

<DataTable data={mp_tramos} rows=all>
    <Column id=tramo_poblacion title="Habitantes" />
    <Column id=ayuntamientos title="Ayuntamientos" fmt=num0 />
    <Column id=indice_medio title="Índice medio" fmt=num1 contentType=colorscale colorMin=70 colorMax=100 />
    <Column id=pct_incumplimientos title="Con algo vencido que no consta (%)" fmt=num1 />
</DataTable>

<MapaEspana
    data={mp_provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="pct_incumplimientos"
    valueFmt="num1"
    colorPalette={['#f0fdf4', '#fde68a', '#b91c1c']}
    height={420}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_incumplimientos', title: 'Ayuntamientos con algo vencido que no consta (%)', fmt: 'num1'},
        {id: 'indice_medio', title: 'Índice medio', fmt: 'num1'},
        {id: 'ayuntamientos', title: 'Ayuntamientos', fmt: 'num0'}
    ]}
/>

### Todos los ayuntamientos

Ordenados de menor a mayor índice. Busca el tuyo o abre su ficha para ver cada obligación, con su plazo, la fecha y quién gobernaba entonces.

<DataTable data={mp_ranking} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=indice title="Índice (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=media_tramo_espana title="Media de su tamaño" fmt=num1 />
    <Column id=n_incumplimientos_destacados title="Vencidas sin constar" fmt=num0 />
    <Column id=incumplimientos title="Qué no consta" />
    <Column id=familia_actual title="Partido del alcalde hoy" />
</DataTable>

### Por partido

Para cada ayuntamiento, obligación y periodo se calcula lo **esperable**: la media de los ayuntamientos de su mismo tamaño y comunidad en ese periodo. Después se compara la nota de los gobernados por cada partido **el día del plazo** con lo esperable. Se usan los últimos cinco años.

<DataTable data={mp_familia} rows=all>
    <Column id=familia title="Partido del alcalde el día del plazo" />
    <Column id=municipios title="Municipios" fmt=num0 />
    <Column id=observada title="Nota media" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferencia" fmt=num2 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Solo partidos con al menos 30 municipios. Un municipio cuenta una vez por partido aunque aporte varias obligaciones, y el intervalo se calcula con el número de municipios. Que haya diferencia entre partidos no prueba que la cause el partido: influyen la plantilla, el secretario-interventor, los medios de la diputación y la persona que gobierna.</p>

## Qué falta

- **No hay una evaluación oficial homogénea para toda España.** Cada órgano de control evalúa a su ámbito con su método: la nota de un ayuntamiento canario (ITCanarias), la de uno catalán (IDPAC) y la de uno murciano (ICPA) no se pueden comparar entre sí.
- **La medición propia mide lo que se remite a registros oficiales, no el portal de transparencia en sí.** Que conste la cuenta general o los contratos no garantiza que el portal publique el organigrama o las retribuciones. Para eso preparamos un robot que revisa los portales, con una muestra revisada a mano para medir su error. Sus resultados se publicarán cuando ese error esté medido.
- **Contratación en Cataluña, País Vasco y Navarra.** Sus administraciones publican en su propia plataforma, no en la del Estado; cuando no está cubierta, no cuentan en ese indicador.
- **Andalucía, Castilla y León, Aragón, Comunitat Valenciana, Galicia, Navarra o el País Vasco** no publican notas por entidad. Madrid ha empezado a evaluar a todos sus ayuntamientos. Se incorporarán en cuanto haya datos.
- Ni las evaluaciones ni la medición propia dicen **si la información es veraz ni completa**: solo si está publicada o remitida, y cuándo.

---

## Metodología y fuentes

- **[Consejo de Transparencia y Buen Gobierno – Evaluación](https://consejodetransparencia.es/evaluacion)**: Índice de Cumplimiento de la Información Obligatoria (ICIO) de la [metodología MESTA](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), leído del texto de cada **informe definitivo** (.docx): Portal de la Transparencia de la AGE (2021-2025), comunidades y ciudades autónomas con convenio (evaluación de 2020 y revisión de 2021) y sus ayuntamientos evaluados. El CTBG revisa directamente cada portal y puntúa, para cada obligación, si se publica el contenido y sus atributos de calidad (forma, actualización, accesibilidad, reutilización). Origen de los datos: Consejo de Transparencia y Buen Gobierno (reutilización según la Ley 37/2007).
- **[Comisionado de Transparencia de Canarias – Puntuaciones](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: tabla maestra de puntuaciones del sector público del Índice de Transparencia de Canarias (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), desde la evaluación de 2016. Combina el cumplimiento de la información obligatoria, la calidad del soporte web y la transparencia voluntaria ([metodología](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). La entidad rellena un cuestionario y el Comisionado lo verifica. Se muestra sobre 100 (nota por 10) solo para dibujarla junto al ICIO; **las dos escalas no son equivalentes**.
- **[Síndic de Greuges de Catalunya – IDPAC](https://www.sindic.cat/ca/page.asp?id=904)**: [CSV en datos abiertos](https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3) (CC0), edición 2026. El Síndic revisa cada portal; el IDPAC (0-100) pondera el contenido obligatorio (70 %) y el espacio web (30 %) ([guía metodológica](https://www.sindic.cat/site/files/informe_transparencia/guia_metodologica_municipis_no_rurals_2026.pdf)). Los municipios se casan con el INE por nombre y provincia.
- **[Consejo de la Transparencia de la Región de Murcia – Informes de evaluación](https://comisionadotransparencia.carm.es/informes-de-evaluacion)**: Anexo I del informe de 2023 (PDF), ICPA 0-10 de 2020 a 2023 = 70 % ICIO (MESTA) + 30 % soporte web. Autoevaluación voluntaria verificada por el Consejo; «no participó» no se cuenta como cero. Se muestra sobre 100.
- **[CTBG – Informes agregados de evaluación](https://consejodetransparencia.es/evaluacion)** (2022-2026): tabla del anexo con el ICIO de cada entidad del sector público institucional estatal, entidades privadas subvencionadas, corporaciones de derecho público y órganos constitucionales. El agregado redondea a una décima.
- **Medición propia (SpainFacts)**: obligaciones de remisión con plazo legal comprobadas en registros oficiales; criterios, base legal y código de cada indicador en [Fuentes › Datos de elaboración propia](/fuentes#datos-de-elaboración-propia). Se atribuye al gobierno en funciones el día del plazo.
- **Municipios**: los nombres del Comisionado se casan con el código INE por nombre (seis con una forma distinta, a mano). Población del padrón del INE del año evaluado.
- **Atribución a partidos**: ayuntamientos, alcalde en funciones al final del periodo evaluado según el [registro de alcaldes del Ministerio de Política Territorial](https://concejales.redsara.es/consulta/) (para la evaluación «2022/23», el 1 de junio de 2023, antes de las corporaciones salidas de las elecciones de mayo); comunidades y Estado, presidente en funciones el 31 de diciembre del año evaluado (ITCanarias) o el 30 de junio del año de la evaluación (CTBG). Los partidos se agrupan en familias políticas.
- **Obligaciones legales**: arts. 5 a 9 de la [Ley 19/2013, de transparencia, acceso a la información pública y buen gobierno](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); en Canarias, la [Ley 12/2014, de transparencia y de acceso a la información pública](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Datos actualizados" />
