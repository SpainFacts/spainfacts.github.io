---
i18n_origen: e3ab0f3b8a10
title: Publicidade activa
description: "Publican e remiten a tempo as administracións o que lles obriga a lei? Avaliacións oficiais por entidade (Consello de Transparencia, Canarias, Cataluña e Murcia) e unha medición propia dos máis de 8.100 concellos, as deputacións e as comunidades, cos incumprimentos sinalados e a comparación por partido."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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
    '/gl/territorios/municipios?m=' || cod_mun AS enlace
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

# 📋 Publicidade activa: publican as administracións o que lles obriga a lei?

{#if mp_destacados.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Administracións que non constan ao día no que deben remitir</p>
    <p class="mt-2 text-red-900 dark:text-red-100">Comunidades, deputacións e concellos de 20.000 habitantes ou máis con algunha obriga cuxo prazo venceu hai máis de tres meses e da que <b>non consta nada</b> no rexistro oficial. En total, {formatNumber(mp_resumen[0]?.con_incumplimientos, 0)} administracións de todos os tamaños están nesa situación.</p>
    {#each mp_destacados.slice(0, 12) as d}
    <div class="mt-4">
        <p class="text-xl font-extrabold leading-tight text-red-700 dark:text-red-300">{#if d.cod_mun}<a class="underline" href="/gl/territorios/municipios?m={d.cod_mun}">{d.nombre_entidad}</a>{:else}{d.nombre_entidad}{/if} <span class="whitespace-nowrap text-base font-semibold">({d.tipo_entidad}{d.provincia ? ', ' + d.provincia : ''}{d.poblacion ? ', ' + formatNumber(d.poblacion, 0) + ' hab.' : ''})</span></p>
        <p class="mt-1 text-red-900 dark:text-red-100">Non consta: {d.incumplimientos}.</p>
    </div>
    {/each}
    {#if mp_destacados.length > 12}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">E {mp_destacados.length - 12} máis dese tamaño. Están todas na <a class="font-semibold underline" href="#medición-propia-todas-as-administracións">táboa da medición propia</a>.</p>
    {/if}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">«Non consta» significa que non figura na fonte oficial á data da última descarga, non que se probase que non se fixo. Cada caso enlaza á súa ficha coa fonte.</p>
</div>
{/if}

Desde 2014, a [Lei 19/2013 de transparencia](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) obriga todas as administracións a **publicar pola súa conta**, sen que ninguén o pida, unha lista de informacións no seu portal de transparencia: quen manda e canto cobra, que normas prepara, que contratos e subvencións concede, os seus orzamentos e contas, o seu patrimonio. É o que se chama **publicidade activa**. Ademais, deben **remitir** as súas contas, orzamentos, contratos e subvencións a rexistros oficiais en prazos fixados por lei. Esta páxina reúne as **avaliacións oficiais** que hai e unha **medición propia** de todas as administracións.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">A resposta curta</p>
<p class="mb-1">Non existe unha avaliación oficial <b>única e homoxénea</b> para todas as administracións. Cada órgano de control avalía o <b>seu ámbito</b>, co seu propio método. Só publican notas por entidade catro: o Consello de Transparencia e Bo Goberno (o Estado e o seu sector público), o Comisionado de Canarias, o Síndic de Greuges de Catalunya e o Consello de Murcia. Así quedan cubertos os <b>concellos de Canarias, Cataluña e Murcia</b> e case ninguén máis.</p>
<p class="mb-0">Para chegar ao resto, SpainFacts <b>mide pola súa conta</b> os máis de 8.100 concellos, as deputacións e as comunidades. Comproba nos rexistros oficiais se cada obriga consta e se chegou en prazo. Hoxe {formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} concellos ({formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %) teñen algunha obriga vencida hai máis de tres meses da que non consta nada. As notas de avaliadores distintos <b>non son comparables entre si</b>, nin coa medición propia.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Portal da AXE"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="da información obrigatoria cumprida en {age[age.length - 1]?.anio} (ICIO)"
        source="Consello de Transparencia e Bo Goberno"
        sparklineData={age.map(d => ({...d, y: d.icio}))}
    />
    <KpiCard
        title="Comunidades avaliadas polo CTBG"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="ICIO medio das 8 con convenio, revisión de 2021"
        source="Consello de Transparencia e Bo Goberno"
    />
    <KpiCard
        title="Concellos canarios"
        value={itc_resumen[0]?.media}
        formattedValue="{formatNumber(itc_resumen[0]?.media / 10, 2)} de 10"
        period="nota media no Índice de Transparencia de Canarias ({itc_ultimo[0]?.etiqueta})"
        source="Comisionado de Transparencia de Canarias"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.media / 10}))}
    />
    <KpiCard
        title="Concellos canarios con nota baixa"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="de {formatNumber(itc_resumen[0]?.total, 0)}: por debaixo de 5 ou sen render a avaliación ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.suspenso}))}
    />
</Grid>

## Que obriga a lei

A Lei 19/2013 (arts. 5 a 8) agrupa as obrigas en tres bloques, e as leis autonómicas de transparencia engaden outras para as súas administracións e concellos:

- **Información institucional, organizativa e de planificación**: funcións, normativa, organigrama, responsables e a súa traxectoria, plans e programas co seu grao de cumprimento.
- **Información de relevancia xurídica**: directrices e instrucións, anteproxectos de lei e proxectos de regulamento, memorias e informes dos expedientes normativos.
- **Información económica, orzamentaria e estatística**: contratos (incluídos os menores), convenios, encomendas, subvencións e axudas, orzamentos e a súa execución, contas e informes de auditoría, retribucións de altos cargos, compatibilidades, bens patrimoniais e estatísticas de calidade dos servizos.

A información debe ser **clara, estruturada, actualizada e reutilizable** (art. 5). Incumprir estas obrigas de forma reiterada é infracción grave segundo a lei estatal (art. 9.3), pero na práctica as sancións son excepcionais: os órganos de control **recomendan e avalían**, non multan.

## Quen avalía e que publica

| Órgano de control | A quen avalía | Que publica por entidade | Úsase aquí? |
|---|---|---|---|
| [Consello de Transparencia e Bo Goberno](https://consejodetransparencia.es/evaluacion) (CTBG) | AXE e sector público estatal, órganos constitucionais, partidos, sindicatos, entidades subvencionadas; e as comunidades e cidades autónomas con convenio (Asturias, Cantabria, Castela-A Mancha, Estremadura, A Rioxa, Ceuta e Melilla; Madrid en 2020-2021) e algúns dos seus concellos | Índice de Cumprimento da Información Obrigatoria (ICIO, 0-100 %, metodoloxía MESTA) nun informe Word por entidade; sen táboa de datos | Si: Portal da AXE, 8 comunidades, 11 concellos e, desde 2022, a táboa dos informes agregados (sector público estatal, entidades privadas, corporacións) |
| [Comisionado de Transparencia de Canarias](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Todo o sector público canario (Goberno, cabidos, concellos, universidades e os seus entes) e entidades privadas subvencionadas | Índice de Transparencia de Canarias (ITCanarias, 0-10) nunha táboa Excel con todas as entidades desde 2016 (CC BY 4.0) | Si: sector público |
| [Consello da Transparencia da Rexión de Murcia](https://comisionadotransparencia.carm.es/informes-de-evaluacion) | Administración rexional, os seus 45 concellos e o seu sector público, partidos, sindicatos, federacións… | Índice de cumprimento da publicidade activa (ICPA, 0-10) de 2020 a 2023, nunha táboa do anexo do informe de 2023 (PDF). É unha autoavaliación voluntaria que o Consello verifica | Si: táboa do anexo |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/ca/page.asp?id=904) | Os 947 concellos cataláns, deputacións, consellos comarcais, departamentos da Generalitat, universidades e órganos de control | Índice de desenvolvemento da publicidade activa (IDPAC, 0-100), revisado polo propio Síndic, en datos abertos (CSV, CC0) desde a edición de 2026 | Si |
| Consellos e comisionados de Andalucía, Aragón, Castela e León, Comunidade Valenciana, Galicia, Madrid, Navarra, País Vasco e outros | A súa comunidade e as súas entidades locais | Memorias anuais, plans de control e resolucións, en PDF. Non atopamos un índice publicado por entidade. Madrid empezou a avaliar todos os seus concellos (resultados previstos na súa memoria de 2026) | Non |

Tamén hai rankings da sociedade civil (Dyntra, o Mapa Infoparticipa da Universitat Autònoma de Barcelona, os antigos índices de Transparencia Internacional España). **Non se usan aquí**: non son fontes oficiais e non comprobamos que a súa licenza permita reutilizar os datos.

## Administración Xeral do Estado

O CTBG avalía cada ano o [Portal da Transparencia](https://transparencia.gob.es/) da AXE. O ICIO mide, para cada obriga, se a información se publica e con que calidade (forma, data de actualización, accesibilidade, reutilización).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="Portal da Transparencia da AXE: índice de cumprimento (%)"
    markers=true
    sort=false
/>

As cinco avaliacións corresponden a Gobernos de Pedro Sánchez, así que **non permiten comparar partidos** no Goberno central. O CTBG avalía ademais cada ano, por separado, centos de organismos, empresas e fundacións do sector público estatal; as súas notas están en informes individuais e aínda non se incorporaron.

## Comunidades autónomas e concellos avaliados polo CTBG

As comunidades que non crearon o seu propio órgano de control asinaron un convenio para que o CTBG vixíe a súa transparencia. En 2020 o CTBG avaliou os seus portais e en 2021 revisou se aplicaran as súas recomendacións.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Índice de cumprimento da información obrigatoria (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Comunidade ou cidade autónoma" />
    <Column id=familia title="Partido do presidente" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Mellora (puntos)" fmt=num1 contentType=delta />
</DataTable>

Todas melloraron tras as recomendacións. Con só oito comunidades, gobernadas por catro partidos distintos, **non ten sentido comparar partidos**: calquera diferenza pode deberse a unha soa comunidade.

Os concellos avaliados polo CTBG son poucos e non forman unha mostra representativa (escolleunos o Consello). Aínda así, mostran o lonxe que pode quedar un concello grande de cumprir: {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} de {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} seguían por debaixo do 50 % na revisión de 2021.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Concello" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=familia title="Partido do alcalde (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Canarias: todo o sector público, entidade por entidade

Canarias é a única comunidade que publica **cada ano e en datos abertos** a nota de todas as súas administracións. O Comisionado de Transparencia envía un cuestionario sobre as obrigas da lei canaria (máis esixente ca a estatal), comproba as respostas nos portais e calcula o Índice de Transparencia de Canarias (0 a 10). Unha entidade que non enche a avaliación figura como **incumpridora**.

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

<p class="text-xs text-gray-500">As dúas últimas avaliacións non son anos naturais: «2022/23» abrangue 2022 e o primeiro semestre de 2023; «2023/24», o segundo semestre de 2023 e 2024. A nota móstrase sobre 100 para comparala coa escala da gráfica (7,5 de 10 = 75).</p>

A mellora é clara: a nota media dos concellos pasou de {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} na primeira avaliación a {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)} na última. Parte da subida reflicte que as entidades aprenden a responder o cuestionario, e moitas xa están no máximo, así que as notas altas distinguen pouco entre elas.

### Concellos, {itc_ultimo[0]?.etiqueta}

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
    attribution="Teselas © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Nota (sobre 100)', fmt: 'num1'},
        {id: 'familia', title: 'Partido do alcalde'},
        {id: 'situacion', title: 'Situación'}
    ]}
/>

<p class="text-xs text-gray-500">A escala de cor comeza en 50: por debaixo, todos se ven en vermello. Un municipio en gris non rendeu a avaliación.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=puntuacion_original title="Nota (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Situación" />
    <Column id=familia title="Partido do alcalde" />
</DataTable>

### Goberno de Canarias e cabidos

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Entidade" />
    <Column id=tipo_administracion title="Tipo" />
    <Column id=en_2017 title="Nota 2017 (sobre 100)" fmt=num1 />
    <Column id=ultima title="Última nota (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="Partido do presidente" />
</DataTable>

<p class="text-xs text-gray-500">Os cabidos non se atribúen a un partido: aínda non hai un rexistro oficial dos seus presidentes en SpainFacts.</p>

### Empresas, organismos e fundacións públicas

Onde máis se incumpre non é nas administracións, senón nos seus **entes dependentes**: empresas públicas, fundacións, consorcios e corporacións de dereito público, que tamén están obrigados.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Tipo de entidade" />
    <Column id=entidades title="Entidades" fmt=num0 />
    <Column id=media title="Nota media (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="Non renderon a avaliación" fmt=num0 />
</DataTable>

<details>
<summary>Entidades que non renderon a avaliación nas dúas últimas edicións</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Avaliación" />
    <Column id=entidad title="Entidade" />
    <Column id=tipo_entidad title="Tipo" />
    <Column id=entidad_principal title="Depende de" />
</DataTable>

</details>

```sql sindic_aytos
SELECT cod_mun, municipio, provincia, poblacion, puntuacion, familia, gobernante,
    '/gl/territorios/municipios?m=' || cod_mun AS enlace
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

## Cataluña: os 947 concellos, revisados polo Síndic

O Síndic de Greuges revisa **el mesmo** o portal de cada concello catalán e publica o resultado en datos abertos: é a única avaliación externa de todos os concellos dunha comunidade. O índice de desenvolvemento da publicidade activa (IDPAC, 0-100) combina o contido obrigatorio (70 %) e a calidade do espazo web (30 %). A edición de 2026 fíxose entre xaneiro e maio.

<DataTable data={sindic_tramos} rows=all>
    <Column id=tramo title="Habitantes" />
    <Column id=ayuntamientos title="Concellos" fmt=num0 />
    <Column id=media title="IDPAC medio" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=menos_50 title="Por debaixo de 50" fmt=num0 />
</DataTable>

<DataTable data={sindic_aytos} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=familia title="Partido do alcalde" />
</DataTable>

<details>
<summary>Generalitat, deputacións, consellos comarcais e outros</summary>

<DataTable data={sindic_otros} search=true rows=15>
    <Column id=entidad title="Entidade" />
    <Column id=tipo_entidad title="Tipo" />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
</DataTable>

</details>

## Rexión de Murcia

O Consello da Transparencia da Rexión de Murcia publica o índice de cumprimento da publicidade activa (ICPA) de cada entidade que se presta a avaliarse. A entidade enche a avaliación nunha plataforma e o Consello verifícaa. **É voluntario**: un concello que non participou figura como «non participou», nunca cun cero.

<BarChart
    data={murcia_serie}
    x=anio
    y={['evaluados', 'no_participaron']}
    type=stacked
    title="Concellos murcianos avaliados e que non participaron"
    sort=false
/>

<DataTable data={murcia_aytos} search=true rows=15>
    <Column id=municipio title="Municipio" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=n2020 title="2020" fmt=num1 />
    <Column id=n2021 title="2021" fmt=num1 />
    <Column id=n2022 title="2022" fmt=num1 />
    <Column id=n2023 title="2023 (sobre 100)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
    <Column id=no_participo title="Anos sen participar" fmt=num0 />
    <Column id=familia title="Partido do alcalde (2023)" />
</DataTable>

<p class="text-xs text-gray-500">Nota orixinal 0-10, mostrada sobre 100. Cela baleira: non participou ou non fora convocado.</p>

## Sector público estatal

Cada ano o Consello de Transparencia avalía organismos, empresas e fundacións estatais, entidades privadas que reciben subvencións e corporacións como os colexios profesionais. Os seus informes agregados traen unha táboa co índice de cumprimento (ICIO) de cada unha.

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
    title="ICIO medio das entidades avaliadas (%)"
/>

<p class="text-xs text-gray-500">Cada ano avalíanse entidades distintas (225 do sector público en 2025, fronte a 74 en 2022), así que a media non segue sempre as mesmas.</p>

<DataTable data={spe_ultimo} search=true rows=15>
    <Column id=entidad title="Entidade" />
    <Column id=grupo title="Grupo" />
    <Column id=anio title="Última avaliación" />
    <Column id=icio title="ICIO (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Por partido en Canarias

Coas avaliacións oficiais, a comparación só é posible cos **concellos canarios**: son 88, avalíanse todos, co mesmo método, desde 2016. Para cada concello e avaliación calcúlase a nota **esperable**: a media dos concellos canarios do seu mesmo tamaño (menos de 5.000, de 5.000 a 20.000 e máis de 20.000 habitantes) nesa mesma avaliación. Despois compárase a nota media dos gobernados por cada partido coa súa esperable.

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
    <Column id=familia title="Partido do alcalde" />
    <Column id=evaluaciones title="Avaliacións" fmt=num0 />
    <Column id=municipios title="Municipios distintos" fmt=num0 />
    <Column id=observada title="Nota media" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferenza" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num1 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num1 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Só partidos con polo menos 20 avaliacións; os concellos que non renderon a avaliación non teñen nota e non entran no cálculo. O intervalo de confianza calcúlase co número de municipios distintos, non de avaliacións, porque as notas dun mesmo concello en anos seguidos non son independentes. «Sen detalle na fonte» agrupa alcaldías elixidas en listas que o rexistro oficial etiqueta de forma xenérica; «Independentes e locais», agrupacións de electores. Unha diferenza entre partidos non proba que se deba ao partido: inflúen o persoal, os medios técnicos, a illa e a persoa que goberna.</p>

Para as comunidades autónomas e o Goberno central **non hai mostra suficiente**: unha soa avaliación por comunidade e ano, e no caso do Estado un único Goberno en todo o período avaliado.

## Medición propia: todas as administracións

Como case ninguén avalía a maioría das administracións, **medímolo nós** co mesmo método para todas. Non puntuamos o portal web a ollo. Comprobamos nos **rexistros oficiais que levan data** se cada obriga legal consta e se chegou dentro do seu prazo. Os rexistros son a Base de Datos Nacional de Subvencións, a Plataforma de Contratación, o Tribunal de Contas e Facenda. Cada obriga puntúa 1 se consta a tempo, 0,5 se consta tarde e 0 se non consta co prazo vencido. O índice de cada administración (0-100) é a media do seu último período medido. Os criterios, a base legal e o código de cada indicador están en [Fontes › Datos de elaboración propia](/gl/fuentes#datos-de-elaboración-propia).

<Grid cols=4>
    <KpiCard
        title="Administracións medidas"
        value={mp_resumen[0]?.entidades}
        formattedValue={formatNumber(mp_resumen[0]?.entidades, 0)}
        period="{formatNumber(mp_resumen[0]?.ayuntamientos, 0)} concellos e {formatNumber(mp_resumen[0]?.entidades - mp_resumen[0]?.ayuntamientos, 0)} deputacións, cabidos e comunidades"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="Concellos con algo vencido que non consta"
        value={mp_resumen[0]?.pct_aytos_incumplimientos}
        formattedValue="{formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %"
        period="{formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} concellos, máis de 3 meses despois do prazo"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="De 20.000 habitantes ou máis"
        value={mp_resumen[0]?.grandes_con_incumplimientos}
        formattedValue={formatNumber(mp_resumen[0]?.grandes_con_incumplimientos, 0)}
        period="concellos grandes con algunha obriga vencida que non consta"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="Índice mediano dos concellos"
        value={mp_resumen[0]?.mediana_aytos}
        formattedValue="{formatNumber(mp_resumen[0]?.mediana_aytos, 1)} de 100"
        period="media do último período de cada obriga"
        source="SpainFacts (elaboración propia)"
    />
</Grid>

### Obriga por obriga

<DataTable data={mp_obligaciones} rows=all groupBy=tipo_entidad>
    <Column id=tipo_entidad title="Administración" />
    <Column id=obligacion title="Obriga" />
    <Column id=ultimo_periodo title="Último período" />
    <Column id=entidades title="Medidas" fmt=num0 />
    <Column id=cumplimiento title="Cumprimento (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=con_retraso title="Con atraso" fmt=num0 />
    <Column id=no_consta title="Non consta" fmt=num0 />
    <Column id=mediana_retraso title="Días (mediana)" fmt=num0 />
    <Column id=en_indice title="No índice" />
</DataTable>

<p class="text-xs text-gray-500">«Días (mediana)»: nas obrigas únicas, o atraso das que chegaron tarde; en contratos e subvencións, o que tarda en publicarse ou rexistrarse a administración típica. Cóntase o último período de cada administración co prazo vencido. As administracións que a fonte non mide (por exemplo, as que remiten pola canle foral) non se contan. Unha obriga entra no índice e na lista de incumprimentos cando mide polo menos o 80 % das administracións do seu tipo; ata entón, como o rastrexo do Tribunal de Contas que vai provincia a provincia, só se ve aquí e en cada ficha.</p>

### Por tamaño e provincia

Os concellos pequenos son os que máis fallan: moitos non teñen nin secretario a tempo completo. Por iso cada concello compárase sempre cos do seu tamaño.

<DataTable data={mp_tramos} rows=all>
    <Column id=tramo_poblacion title="Habitantes" />
    <Column id=ayuntamientos title="Concellos" fmt=num0 />
    <Column id=indice_medio title="Índice medio" fmt=num1 contentType=colorscale colorMin=70 colorMax=100 />
    <Column id=pct_incumplimientos title="Con algo vencido que non consta (%)" fmt=num1 />
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
        {id: 'pct_incumplimientos', title: 'Concellos con algo vencido que non consta (%)', fmt: 'num1'},
        {id: 'indice_medio', title: 'Índice medio', fmt: 'num1'},
        {id: 'ayuntamientos', title: 'Concellos', fmt: 'num0'}
    ]}
/>

### Todos os concellos

Ordenados de menor a maior índice. Busca o teu ou abre a súa ficha para ver cada obriga, co seu prazo, a data e quen gobernaba entón.

<DataTable data={mp_ranking} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=indice title="Índice (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=media_tramo_espana title="Media do seu tamaño" fmt=num1 />
    <Column id=n_incumplimientos_destacados title="Vencidas sen constar" fmt=num0 />
    <Column id=incumplimientos title="Que non consta" />
    <Column id=familia_actual title="Partido do alcalde hoxe" />
</DataTable>

### Por partido

Para cada concello, obriga e período calcúlase o **esperable**: a media dos concellos do seu mesmo tamaño e comunidade nese período. Despois compárase a nota dos gobernados por cada partido **o día do prazo** co esperable. Úsanse os últimos cinco anos.

<DataTable data={mp_familia} rows=all>
    <Column id=familia title="Partido do alcalde o día do prazo" />
    <Column id=municipios title="Municipios" fmt=num0 />
    <Column id=observada title="Nota media" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferenza" fmt=num2 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Só partidos con polo menos 30 municipios. Un municipio conta unha vez por partido aínda que achegue varias obrigas, e o intervalo calcúlase co número de municipios. Que haxa diferenza entre partidos non proba que a cause o partido: inflúen o persoal, o secretario-interventor, os medios da deputación e a persoa que goberna.</p>

## Que falta

- **Non hai unha avaliación oficial homoxénea para toda España.** Cada órgano de control avalía o seu ámbito co seu método: a nota dun concello canario (ITCanarias), a dun catalán (IDPAC) e a dun murciano (ICPA) non se poden comparar entre si.
- **A medición propia mide o que se remite a rexistros oficiais, non o portal de transparencia en si.** Que conste a conta xeral ou os contratos non garante que o portal publique o organigrama ou as retribucións. Para iso preparamos un robot que revisa os portais, cunha mostra revisada a man para medir o seu erro. Os seus resultados publicaranse cando ese erro estea medido.
- **Contratación en Cataluña, País Vasco e Navarra.** As súas administracións publican na súa propia plataforma, non na do Estado; cando non está cuberta, non contan nese indicador.
- **Andalucía, Castela e León, Aragón, Comunidade Valenciana, Galicia, Navarra ou o País Vasco** non publican notas por entidade. Madrid empezou a avaliar todos os seus concellos. Incorporaranse en canto haxa datos.
- Nin as avaliacións nin a medición propia din **se a información é veraz nin completa**: só se está publicada ou remitida, e cando.

---

## Metodoloxía e fontes

- **[Consello de Transparencia e Bo Goberno – Avaliación](https://consejodetransparencia.es/evaluacion)**: Índice de Cumprimento da Información Obrigatoria (ICIO) da [metodoloxía MESTA](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), lido do texto de cada **informe definitivo** (.docx): Portal da Transparencia da AXE (2021-2025), comunidades e cidades autónomas con convenio (avaliación de 2020 e revisión de 2021) e os seus concellos avaliados. O CTBG revisa directamente cada portal e puntúa, para cada obriga, se se publica o contido e os seus atributos de calidade (forma, actualización, accesibilidade, reutilización). Orixe dos datos: Consello de Transparencia e Bo Goberno (reutilización segundo a Lei 37/2007).
- **[Comisionado de Transparencia de Canarias – Puntuacións](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: táboa mestra de puntuacións do sector público do Índice de Transparencia de Canarias (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), desde a avaliación de 2016. Combina o cumprimento da información obrigatoria, a calidade do soporte web e a transparencia voluntaria ([metodoloxía](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). A entidade enche un cuestionario e o Comisionado verifícao. Móstrase sobre 100 (nota por 10) só para debuxala xunto ao ICIO; **as dúas escalas non son equivalentes**.
- **[Síndic de Greuges de Catalunya – IDPAC](https://www.sindic.cat/ca/page.asp?id=904)**: [CSV en datos abertos](https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3) (CC0), edición 2026. O Síndic revisa cada portal; o IDPAC (0-100) pondera o contido obrigatorio (70 %) e o espazo web (30 %) ([guía metodolóxica](https://www.sindic.cat/site/files/informe_transparencia/guia_metodologica_municipis_no_rurals_2026.pdf)). Os municipios cásanse co INE por nome e provincia.
- **[Consello da Transparencia da Rexión de Murcia – Informes de avaliación](https://comisionadotransparencia.carm.es/informes-de-evaluacion)**: Anexo I do informe de 2023 (PDF), ICPA 0-10 de 2020 a 2023 = 70 % ICIO (MESTA) + 30 % soporte web. Autoavaliación voluntaria verificada polo Consello; «non participou» non se conta como cero. Móstrase sobre 100.
- **[CTBG – Informes agregados de avaliación](https://consejodetransparencia.es/evaluacion)** (2022-2026): táboa do anexo co ICIO de cada entidade do sector público institucional estatal, entidades privadas subvencionadas, corporacións de dereito público e órganos constitucionais. O agregado redondea a unha décima.
- **Medición propia (SpainFacts)**: obrigas de remisión con prazo legal comprobadas en rexistros oficiais; criterios, base legal e código de cada indicador en [Fontes › Datos de elaboración propia](/gl/fuentes#datos-de-elaboración-propia). Atribúese ao goberno en funcións o día do prazo.
- **Municipios**: os nomes do Comisionado cásanse co código INE por nome (seis cunha forma distinta, a man). Poboación do padrón do INE do ano avaliado.
- **Atribución a partidos**: concellos, alcalde en funcións ao final do período avaliado segundo o [rexistro de alcaldes do Ministerio de Política Territorial](https://concejales.redsara.es/consulta/) (para a avaliación «2022/23», o 1 de xuño de 2023, antes das corporacións saídas das eleccións de maio); comunidades e Estado, presidente en funcións o 31 de decembro do ano avaliado (ITCanarias) ou o 30 de xuño do ano da avaliación (CTBG). Os partidos agrúpanse en familias políticas.
- **Obrigas legais**: arts. 5 a 9 da [Lei 19/2013, de transparencia, acceso á información pública e bo goberno](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); en Canarias, a [Lei 12/2014, de transparencia e de acceso á información pública](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Datos actualizados" />
