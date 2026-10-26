---
title: Publicitat activa
description: "Publiquen i trameten a temps les administracions el que els obliga la llei? Avaluacions oficials per entitat (Consell de Transparència, Canàries, Catalunya i Múrcia) i una mesura pròpia dels més de 8.100 ajuntaments, les diputacions i les comunitats, amb els incompliments assenyalats i la comparació per partit."
i18n_origen: e3ab0f3b8a10
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
    '/ca/territorios/municipios?m=' || cod_mun AS enlace
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

# 📋 Publicitat activa: publiquen les administracions el que els obliga la llei?

{#if mp_destacados.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Administracions que no consten al dia en el que han de trametre</p>
    <p class="mt-2 text-red-900 dark:text-red-100">Comunitats, diputacions i ajuntaments de 20.000 habitants o més amb alguna obligació el termini de la qual va vèncer fa més de tres mesos i de la qual <b>no consta res</b> al registre oficial. En total, {formatNumber(mp_resumen[0]?.con_incumplimientos, 0)} administracions de totes les mides es troben en aquesta situació.</p>
    {#each mp_destacados.slice(0, 12) as d}
    <div class="mt-4">
        <p class="text-xl font-extrabold leading-tight text-red-700 dark:text-red-300">{#if d.cod_mun}<a class="underline" href="/ca/territorios/municipios?m={d.cod_mun}">{d.nombre_entidad}</a>{:else}{d.nombre_entidad}{/if} <span class="whitespace-nowrap text-base font-semibold">({d.tipo_entidad}{d.provincia ? ', ' + d.provincia : ''}{d.poblacion ? ', ' + formatNumber(d.poblacion, 0) + ' hab.' : ''})</span></p>
        <p class="mt-1 text-red-900 dark:text-red-100">No consta: {d.incumplimientos}.</p>
    </div>
    {/each}
    {#if mp_destacados.length > 12}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">I {mp_destacados.length - 12} més d'aquesta mida. Són totes a la <a class="font-semibold underline" href="#mesura-pròpia-totes-les-administracions">taula de la mesura pròpia</a>.</p>
    {/if}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">«No consta» vol dir que no figura a la font oficial en la data de l'última descàrrega, no que s'hagi provat que no es va fer. Cada cas enllaça a la seva fitxa amb la font.</p>
</div>
{/if}

Des del 2014, la [Llei 19/2013 de transparència](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) obliga totes les administracions a **publicar pel seu compte**, sense que ningú ho demani, una llista d'informacions al seu portal de transparència: qui mana i quant cobra, quines normes prepara, quins contractes i subvencions concedeix, els seus pressupostos i comptes, el seu patrimoni. És el que s'anomena **publicitat activa**. A més, han de **trametre** els seus comptes, pressupostos, contractes i subvencions a registres oficials en terminis fixats per llei. Aquesta pàgina reuneix les **avaluacions oficials** que hi ha i una **mesura pròpia** de totes les administracions.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">La resposta curta</p>
<p class="mb-1">No hi ha una avaluació oficial <b>única i homogènia</b> per a totes les administracions. Cada òrgan de control avalua el <b>seu àmbit</b>, amb el seu propi mètode. Només en publiquen notes per entitat quatre: el Consell de Transparència i Bon Govern (l'Estat i el seu sector públic), el Comissionat de Canàries, el Síndic de Greuges de Catalunya i el Consell de Múrcia. Així queden coberts els <b>ajuntaments de Canàries, Catalunya i Múrcia</b> i gairebé ningú més.</p>
<p class="mb-0">Per arribar a la resta, SpainFacts <b>mesura pel seu compte</b> els més de 8.100 ajuntaments, les diputacions i les comunitats. Comprova als registres oficials si cada obligació consta i si va arribar dins del termini. Avui {formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} ajuntaments ({formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %) tenen alguna obligació vençuda fa més de tres mesos de la qual no consta res. Les notes d'avaluadors diferents <b>no són comparables entre si</b>, ni amb la mesura pròpia.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Portal de l'AGE"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="de la informació obligatòria complerta el {age[age.length - 1]?.anio} (ICIO)"
        source="Consell de Transparència i Bon Govern"
        sparklineData={age.map(d => ({...d, y: d.icio}))}
    />
    <KpiCard
        title="Comunitats avaluades pel CTBG"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="ICIO mitjà de les 8 amb conveni, revisió del 2021"
        source="Consell de Transparència i Bon Govern"
    />
    <KpiCard
        title="Ajuntaments canaris"
        value={itc_resumen[0]?.media}
        formattedValue="{formatNumber(itc_resumen[0]?.media / 10, 2)} de 10"
        period="nota mitjana a l'Índex de Transparència de Canàries ({itc_ultimo[0]?.etiqueta})"
        source="Comissionat de Transparència de Canàries"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.media / 10}))}
    />
    <KpiCard
        title="Ajuntaments canaris amb nota baixa"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="de {formatNumber(itc_resumen[0]?.total, 0)}: per sota de 5 o sense retre l'avaluació ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.suspenso}))}
    />
</Grid>

## Què obliga la llei

La Llei 19/2013 (arts. 5 a 8) agrupa les obligacions en tres blocs, i les lleis autonòmiques de transparència n'hi afegeixen d'altres per a les seves administracions i ajuntaments:

- **Informació institucional, organitzativa i de planificació**: funcions, normativa, organigrama, responsables i la seva trajectòria, plans i programes amb el seu grau de compliment.
- **Informació de rellevància jurídica**: directrius i instruccions, avantprojectes de llei i projectes de reglament, memòries i informes dels expedients normatius.
- **Informació econòmica, pressupostària i estadística**: contractes (inclosos els menors), convenis, encàrrecs, subvencions i ajuts, pressupostos i la seva execució, comptes i informes d'auditoria, retribucions d'alts càrrecs, compatibilitats, béns patrimonials i estadístiques de qualitat dels serveis.

La informació ha de ser **clara, estructurada, actualitzada i reutilitzable** (art. 5). Incomplir aquestes obligacions de manera reiterada és una infracció greu segons la llei estatal (art. 9.3), però a la pràctica les sancions són excepcionals: els òrgans de control **recomanen i avaluen**, no multen.

## Qui avalua i què publica

| Òrgan de control | A qui avalua | Què publica per entitat | S'utilitza aquí? |
|---|---|---|---|
| [Consell de Transparència i Bon Govern](https://consejodetransparencia.es/evaluacion) (CTBG) | AGE i sector públic estatal, òrgans constitucionals, partits, sindicats, entitats subvencionades; i les comunitats i ciutats autònomes amb conveni (Astúries, Cantàbria, Castella - la Manxa, Extremadura, La Rioja, Ceuta i Melilla; Madrid el 2020-2021) i alguns dels seus ajuntaments | Índex de Compliment de la Informació Obligatòria (ICIO, 0-100 %, metodologia MESTA) en un informe Word per entitat; sense taula de dades | Sí: Portal de l'AGE, 8 comunitats, 11 ajuntaments i, des del 2022, la taula dels informes agregats (sector públic estatal, entitats privades, corporacions) |
| [Comissionat de Transparència de Canàries](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Tot el sector públic canari (Govern, cabildos, ajuntaments, universitats i els seus ens) i entitats privades subvencionades | Índex de Transparència de Canàries (ITCanarias, 0-10) en una taula Excel amb totes les entitats des del 2016 (CC BY 4.0) | Sí: sector públic |
| [Consell de la Transparència de la Regió de Múrcia](https://comisionadotransparencia.carm.es/informes-de-evaluacion) | Administració regional, els seus 45 ajuntaments i el seu sector públic, partits, sindicats, federacions… | Índex de compliment de la publicitat activa (ICPA, 0-10) del 2020 al 2023, en una taula de l'annex de l'informe del 2023 (PDF). És una autoavaluació voluntària que el Consell verifica | Sí: taula de l'annex |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/ca/page.asp?id=904) | Els 947 ajuntaments catalans, diputacions, consells comarcals, departaments de la Generalitat, universitats i òrgans de control | Índex de desenvolupament de la publicitat activa (IDPAC, 0-100), revisat pel mateix Síndic, en dades obertes (CSV, CC0) des de l'edició del 2026 | Sí |
| Consells i comissionats d'Andalusia, Aragó, Castella i Lleó, Comunitat Valenciana, Galícia, Madrid, Navarra, País Basc i altres | La seva comunitat i les seves entitats locals | Memòries anuals, plans de control i resolucions, en PDF. No hem trobat cap índex publicat per entitat. Madrid ha començat a avaluar tots els seus ajuntaments (resultats previstos a la seva memòria del 2026) | No |

També hi ha rànquings de la societat civil (Dyntra, el Mapa Infoparticipa de la Universitat Autònoma de Barcelona, els antics índexs de Transparència Internacional Espanya). **No s'utilitzen aquí**: no són fonts oficials i no hem comprovat que la seva llicència permeti reutilitzar les dades.

## Administració General de l'Estat

El CTBG avalua cada any el [Portal de la Transparència](https://transparencia.gob.es/) de l'AGE. L'ICIO mesura, per a cada obligació, si la informació es publica i amb quina qualitat (forma, data d'actualització, accessibilitat, reutilització).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="Portal de la Transparència de l'AGE: índex de compliment (%)"
    markers=true
    sort=false
/>

Les cinc avaluacions corresponen a Governs de Pedro Sánchez, de manera que **no permeten comparar partits** al Govern central. A més, el CTBG avalua cada any, per separat, centenars d'organismes, empreses i fundacions del sector públic estatal; les seves notes són en informes individuals i encara no s'han incorporat.

## Comunitats autònomes i ajuntaments avaluats pel CTBG

Les comunitats que no van crear el seu propi òrgan de control van signar un conveni perquè el CTBG vigilés la seva transparència. El 2020 el CTBG en va avaluar els portals i el 2021 va revisar si havien aplicat les seves recomanacions.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Índex de compliment de la informació obligatòria (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Comunitat o ciutat autònoma" />
    <Column id=familia title="Partit del president" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Millora (punts)" fmt=num1 contentType=delta />
</DataTable>

Totes van millorar després de les recomanacions. Amb només vuit comunitats, governades per quatre partits diferents, **no té sentit comparar partits**: qualsevol diferència pot deure's a una sola comunitat.

Els ajuntaments avaluats pel CTBG són pocs i no formen una mostra representativa (els va triar el Consell). Tot i així, mostren com de lluny pot quedar un ajuntament gran de complir: {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} de {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} continuaven per sota del 50 % a la revisió del 2021.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Ajuntament" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=familia title="Partit de l'alcalde (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Canàries: tot el sector públic, entitat per entitat

Canàries és l'única comunitat que publica **cada any i en dades obertes** la nota de totes les seves administracions. El Comissionat de Transparència envia un qüestionari sobre les obligacions de la llei canària (més exigent que l'estatal), comprova les respostes als portals i calcula l'Índex de Transparència de Canàries (0 a 10). Una entitat que no emplena l'avaluació figura com a **incomplidora**.

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
    title="Índex de Transparència de Canàries, nota mitjana (sobre 100)"
/>

<p class="text-xs text-gray-500">Les dues últimes avaluacions no són anys naturals: «2022/23» cobreix el 2022 i el primer semestre del 2023; «2023/24», el segon semestre del 2023 i el 2024. La nota es mostra sobre 100 per comparar-la amb l'escala del gràfic (7,5 de 10 = 75).</p>

La millora és clara: la nota mitjana dels ajuntaments va passar de {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} a la primera avaluació a {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)} a l'última. Part de la pujada reflecteix que les entitats aprenen a respondre el qüestionari, i moltes ja són al màxim, de manera que les notes altes distingeixen poc entre elles.

### Ajuntaments, {itc_ultimo[0]?.etiqueta}

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límits © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Nota (sobre 100)', fmt: 'num1'},
        {id: 'familia', title: "Partit de l'alcalde"},
        {id: 'situacion', title: 'Situació'}
    ]}
/>

<p class="text-xs text-gray-500">L'escala de color comença a 50: per sota, tots es veuen en vermell. Un municipi en gris no va retre l'avaluació.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=puntuacion_original title="Nota (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Situació" />
    <Column id=familia title="Partit de l'alcalde" />
</DataTable>

### Govern de Canàries i cabildos

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Entitat" />
    <Column id=tipo_administracion title="Tipus" />
    <Column id=en_2017 title="Nota 2017 (sobre 100)" fmt=num1 />
    <Column id=ultima title="Última nota (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="Partit del president" />
</DataTable>

<p class="text-xs text-gray-500">Els cabildos no s'atribueixen a cap partit: encara no hi ha un registre oficial dels seus presidents a SpainFacts.</p>

### Empreses, organismes i fundacions públiques

On més s'incompleix no és a les administracions, sinó als seus **ens dependents**: empreses públiques, fundacions, consorcis i corporacions de dret públic, que també hi estan obligats.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Tipus d'entitat" />
    <Column id=entidades title="Entitats" fmt=num0 />
    <Column id=media title="Nota mitjana (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="No van retre l'avaluació" fmt=num0 />
</DataTable>

<details>
<summary>Entitats que no van retre l'avaluació en les dues últimes edicions</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Avaluació" />
    <Column id=entidad title="Entitat" />
    <Column id=tipo_entidad title="Tipus" />
    <Column id=entidad_principal title="Depèn de" />
</DataTable>

</details>

```sql sindic_aytos
SELECT cod_mun, municipio, provincia, poblacion, puntuacion, familia, gobernante,
    '/ca/territorios/municipios?m=' || cod_mun AS enlace
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

## Catalunya: els 947 ajuntaments, revisats pel Síndic

El Síndic de Greuges revisa **ell mateix** el portal de cada ajuntament català i publica el resultat en dades obertes: és l'única avaluació externa de tots els ajuntaments d'una comunitat. L'índex de desenvolupament de la publicitat activa (IDPAC, 0-100) combina el contingut obligatori (70 %) i la qualitat de l'espai web (30 %). L'edició del 2026 es va fer entre gener i maig.

<DataTable data={sindic_tramos} rows=all>
    <Column id=tramo title="Habitants" />
    <Column id=ayuntamientos title="Ajuntaments" fmt=num0 />
    <Column id=media title="IDPAC mitjà" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=menos_50 title="Per sota de 50" fmt=num0 />
</DataTable>

<DataTable data={sindic_aytos} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=familia title="Partit de l'alcalde" />
</DataTable>

<details>
<summary>Generalitat, diputacions, consells comarcals i altres</summary>

<DataTable data={sindic_otros} search=true rows=15>
    <Column id=entidad title="Entitat" />
    <Column id=tipo_entidad title="Tipus" />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
</DataTable>

</details>

## Regió de Múrcia

El Consell de la Transparència de la Regió de Múrcia publica l'índex de compliment de la publicitat activa (ICPA) de cada entitat que es presta a ser avaluada. L'entitat emplena l'avaluació en una plataforma i el Consell la verifica. **És voluntari**: un ajuntament que no hi va participar figura com a «no hi va participar», mai amb un zero.

<BarChart
    data={murcia_serie}
    x=anio
    y={['evaluados', 'no_participaron']}
    type=stacked
    title="Ajuntaments murcians avaluats i que no hi van participar"
    sort=false
/>

<DataTable data={murcia_aytos} search=true rows=15>
    <Column id=municipio title="Municipi" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=n2020 title="2020" fmt=num1 />
    <Column id=n2021 title="2021" fmt=num1 />
    <Column id=n2022 title="2022" fmt=num1 />
    <Column id=n2023 title="2023 (sobre 100)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
    <Column id=no_participo title="Anys sense participar" fmt=num0 />
    <Column id=familia title="Partit de l'alcalde (2023)" />
</DataTable>

<p class="text-xs text-gray-500">Nota original 0-10, mostrada sobre 100. Cel·la buida: no hi va participar o no havia estat convocat.</p>

## Sector públic estatal

Cada any el Consell de Transparència avalua organismes, empreses i fundacions estatals, entitats privades que reben subvencions i corporacions com els col·legis professionals. Els seus informes agregats inclouen una taula amb l'índex de compliment (ICIO) de cadascuna.

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
    title="ICIO mitjà de les entitats avaluades (%)"
/>

<p class="text-xs text-gray-500">Cada any s'avaluen entitats diferents (225 del sector públic el 2025, davant de 74 el 2022), de manera que la mitjana no segueix sempre les mateixes.</p>

<DataTable data={spe_ultimo} search=true rows=15>
    <Column id=entidad title="Entitat" />
    <Column id=grupo title="Grup" />
    <Column id=anio title="Última avaluació" />
    <Column id=icio title="ICIO (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Per partit a Canàries

Amb les avaluacions oficials, la comparació només és possible amb els **ajuntaments canaris**: són 88, s'avaluen tots, amb el mateix mètode, des del 2016. Per a cada ajuntament i avaluació es calcula la nota **esperable**: la mitjana dels ajuntaments canaris de la mateixa mida (menys de 5.000, de 5.000 a 20.000 i més de 20.000 habitants) en aquella mateixa avaluació. Després es compara la nota mitjana dels governats per cada partit amb la seva esperable.

```sql itc_familia_grafico
SELECT familia, diferencia FROM ${itc_familia}
```

<BarChart
    data={itc_familia_grafico}
    x=familia
    y=diferencia
    swapXY=true
    yFmt=num1
    title="Nota observada menys esperable (punts sobre 100)"
    fillColor="#0f766e"
    sort=false
/>

<DataTable data={itc_familia} rows=all>
    <Column id=familia title="Partit de l'alcalde" />
    <Column id=evaluaciones title="Avaluacions" fmt=num0 />
    <Column id=municipios title="Municipis diferents" fmt=num0 />
    <Column id=observada title="Nota mitjana" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferència" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num1 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num1 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Només partits amb almenys 20 avaluacions; els ajuntaments que no van retre l'avaluació no tenen nota i no entren en el càlcul. L'interval de confiança es calcula amb el nombre de municipis diferents, no d'avaluacions, perquè les notes d'un mateix ajuntament en anys seguits no són independents. «Sin detalle en la fuente» (sense detall a la font) agrupa alcaldies escollides en llistes que el registre oficial etiqueta de manera genèrica; «Independientes y locales» (independents i locals), agrupacions d'electors. Una diferència entre partits no prova que es degui al partit: hi influeixen la plantilla, els mitjans tècnics, l'illa i la persona que governa.</p>

Per a les comunitats autònomes i el Govern central **no hi ha prou mostra**: una sola avaluació per comunitat i any, i en el cas de l'Estat un únic Govern en tot el període avaluat.

## Mesura pròpia: totes les administracions

Com que gairebé ningú no avalua la majoria d'administracions, **ho mesurem nosaltres** amb el mateix mètode per a totes. No puntuem el portal web a ull. Comprovem als **registres oficials que porten data** si cada obligació legal consta i si va arribar dins del termini. Els registres són la Base de Dades Nacional de Subvencions, la Plataforma de Contractació, el Tribunal de Comptes i Hisenda. Cada obligació puntua 1 si consta a temps, 0,5 si consta tard i 0 si no consta amb el termini vençut. L'índex de cada administració (0-100) és la mitjana del seu últim període mesurat. Els criteris, la base legal i el codi de cada indicador són a [Fonts › Dades d'elaboració pròpia](/ca/fuentes#dades-delaboració-pròpia).

<Grid cols=4>
    <KpiCard
        title="Administracions mesurades"
        value={mp_resumen[0]?.entidades}
        formattedValue={formatNumber(mp_resumen[0]?.entidades, 0)}
        period="{formatNumber(mp_resumen[0]?.ayuntamientos, 0)} ajuntaments i {formatNumber(mp_resumen[0]?.entidades - mp_resumen[0]?.ayuntamientos, 0)} diputacions, cabildos i comunitats"
        source="SpainFacts (elaboració pròpia)"
    />
    <KpiCard
        title="Ajuntaments amb alguna cosa vençuda que no consta"
        value={mp_resumen[0]?.pct_aytos_incumplimientos}
        formattedValue="{formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %"
        period="{formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} ajuntaments, més de 3 mesos després del termini"
        source="SpainFacts (elaboració pròpia)"
    />
    <KpiCard
        title="De 20.000 habitants o més"
        value={mp_resumen[0]?.grandes_con_incumplimientos}
        formattedValue={formatNumber(mp_resumen[0]?.grandes_con_incumplimientos, 0)}
        period="ajuntaments grans amb alguna obligació vençuda que no consta"
        source="SpainFacts (elaboració pròpia)"
    />
    <KpiCard
        title="Índex medià dels ajuntaments"
        value={mp_resumen[0]?.mediana_aytos}
        formattedValue="{formatNumber(mp_resumen[0]?.mediana_aytos, 1)} de 100"
        period="mitjana de l'últim període de cada obligació"
        source="SpainFacts (elaboració pròpia)"
    />
</Grid>

### Obligació per obligació

<DataTable data={mp_obligaciones} rows=all groupBy=tipo_entidad>
    <Column id=tipo_entidad title="Administració" />
    <Column id=obligacion title="Obligació" />
    <Column id=ultimo_periodo title="Últim període" />
    <Column id=entidades title="Mesurades" fmt=num0 />
    <Column id=cumplimiento title="Compliment (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=con_retraso title="Amb retard" fmt=num0 />
    <Column id=no_consta title="No consta" fmt=num0 />
    <Column id=mediana_retraso title="Dies (mediana)" fmt=num0 />
    <Column id=en_indice title="A l'índex" />
</DataTable>

<p class="text-xs text-gray-500">«Dies (mediana)»: en les obligacions úniques, el retard de les que van arribar tard; en contractes i subvencions, el que triga a publicar-se o registrar-se l'administració típica. Es compta l'últim període de cada administració amb el termini vençut. Les administracions que la font no mesura (per exemple, les que trameten per la via foral) no es compten. Una obligació entra a l'índex i a la llista d'incompliments quan mesura almenys el 80 % de les administracions del seu tipus; fins aleshores, com el rastreig del Tribunal de Comptes que va província a província, només es veu aquí i a cada fitxa.</p>

### Per mida i província

Els ajuntaments petits són els que fallen més: molts no tenen ni secretari a temps complet. Per això cada ajuntament es compara sempre amb els de la seva mida.

<DataTable data={mp_tramos} rows=all>
    <Column id=tramo_poblacion title="Habitants" />
    <Column id=ayuntamientos title="Ajuntaments" fmt=num0 />
    <Column id=indice_medio title="Índex mitjà" fmt=num1 contentType=colorscale colorMin=70 colorMax=100 />
    <Column id=pct_incumplimientos title="Amb alguna cosa vençuda que no consta (%)" fmt=num1 />
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
        {id: 'pct_incumplimientos', title: 'Ajuntaments amb alguna cosa vençuda que no consta (%)', fmt: 'num1'},
        {id: 'indice_medio', title: 'Índex mitjà', fmt: 'num1'},
        {id: 'ayuntamientos', title: 'Ajuntaments', fmt: 'num0'}
    ]}
/>

### Tots els ajuntaments

Ordenats de menor a major índex. Cerca el teu o obre'n la fitxa per veure cada obligació, amb el seu termini, la data i qui governava aleshores.

<DataTable data={mp_ranking} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=indice title="Índex (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=media_tramo_espana title="Mitjana de la seva mida" fmt=num1 />
    <Column id=n_incumplimientos_destacados title="Vençudes sense constar" fmt=num0 />
    <Column id=incumplimientos title="Què no consta" />
    <Column id=familia_actual title="Partit de l'alcalde avui" />
</DataTable>

### Per partit

Per a cada ajuntament, obligació i període es calcula el que és **esperable**: la mitjana dels ajuntaments de la mateixa mida i comunitat en aquell període. Després es compara la nota dels governats per cada partit **el dia del termini** amb el que és esperable. S'utilitzen els últims cinc anys.

<DataTable data={mp_familia} rows=all>
    <Column id=familia title="Partit de l'alcalde el dia del termini" />
    <Column id=municipios title="Municipis" fmt=num0 />
    <Column id=observada title="Nota mitjana" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferència" fmt=num2 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num2 />
    <Column id=ic_alto title="IC 95 % (màx.)" fmt=num2 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Només partits amb almenys 30 municipis. Un municipi compta una vegada per partit encara que aporti diverses obligacions, i l'interval es calcula amb el nombre de municipis. Que hi hagi diferència entre partits no prova que la causi el partit: hi influeixen la plantilla, el secretari-interventor, els mitjans de la diputació i la persona que governa.</p>

## Què hi falta

- **No hi ha una avaluació oficial homogènia per a tota Espanya.** Cada òrgan de control avalua el seu àmbit amb el seu mètode: la nota d'un ajuntament canari (ITCanarias), la d'un de català (IDPAC) i la d'un de murcià (ICPA) no es poden comparar entre si.
- **La mesura pròpia mesura el que es tramet a registres oficials, no el portal de transparència en si.** Que hi consti el compte general o els contractes no garanteix que el portal publiqui l'organigrama o les retribucions. Per a això preparem un robot que revisa els portals, amb una mostra revisada a mà per mesurar-ne l'error. Els seus resultats es publicaran quan aquest error estigui mesurat.
- **Contractació a Catalunya, el País Basc i Navarra.** Les seves administracions publiquen a la seva pròpia plataforma, no a la de l'Estat; quan no està coberta, no compten en aquest indicador.
- **Andalusia, Castella i Lleó, Aragó, la Comunitat Valenciana, Galícia, Navarra o el País Basc** no publiquen notes per entitat. Madrid ha començat a avaluar tots els seus ajuntaments. S'hi incorporaran tan bon punt hi hagi dades.
- Ni les avaluacions ni la mesura pròpia diuen **si la informació és veraç ni completa**: només si està publicada o tramesa, i quan.

---

## Metodologia i fonts

- **[Consell de Transparència i Bon Govern – Avaluació](https://consejodetransparencia.es/evaluacion)**: Índex de Compliment de la Informació Obligatòria (ICIO) de la [metodologia MESTA](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), llegit del text de cada **informe definitiu** (.docx): Portal de la Transparència de l'AGE (2021-2025), comunitats i ciutats autònomes amb conveni (avaluació del 2020 i revisió del 2021) i els seus ajuntaments avaluats. El CTBG revisa directament cada portal i puntua, per a cada obligació, si se'n publica el contingut i els seus atributs de qualitat (forma, actualització, accessibilitat, reutilització). Origen de les dades: Consell de Transparència i Bon Govern (reutilització segons la Llei 37/2007).
- **[Comissionat de Transparència de Canàries – Puntuacions](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: taula mestra de puntuacions del sector públic de l'Índex de Transparència de Canàries (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), des de l'avaluació del 2016. Combina el compliment de la informació obligatòria, la qualitat del suport web i la transparència voluntària ([metodologia](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). L'entitat emplena un qüestionari i el Comissionat el verifica. Es mostra sobre 100 (nota per 10) només per dibuixar-la al costat de l'ICIO; **les dues escales no són equivalents**.
- **[Síndic de Greuges de Catalunya – IDPAC](https://www.sindic.cat/ca/page.asp?id=904)**: [CSV en dades obertes](https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3) (CC0), edició 2026. El Síndic revisa cada portal; l'IDPAC (0-100) pondera el contingut obligatori (70 %) i l'espai web (30 %) ([guia metodològica](https://www.sindic.cat/site/files/informe_transparencia/guia_metodologica_municipis_no_rurals_2026.pdf)). Els municipis s'aparellen amb l'INE pel nom i la província.
- **[Consell de la Transparència de la Regió de Múrcia – Informes d'avaluació](https://comisionadotransparencia.carm.es/informes-de-evaluacion)**: Annex I de l'informe del 2023 (PDF), ICPA 0-10 del 2020 al 2023 = 70 % ICIO (MESTA) + 30 % suport web. Autoavaluació voluntària verificada pel Consell; «no hi va participar» no es compta com a zero. Es mostra sobre 100.
- **[CTBG – Informes agregats d'avaluació](https://consejodetransparencia.es/evaluacion)** (2022-2026): taula de l'annex amb l'ICIO de cada entitat del sector públic institucional estatal, entitats privades subvencionades, corporacions de dret públic i òrgans constitucionals. L'agregat arrodoneix a una dècima.
- **Mesura pròpia (SpainFacts)**: obligacions de tramesa amb termini legal comprovades en registres oficials; criteris, base legal i codi de cada indicador a [Fonts › Dades d'elaboració pròpia](/ca/fuentes#dades-delaboració-pròpia). S'atribueix al govern en funcions el dia del termini.
- **Municipis**: els noms del Comissionat s'aparellen amb el codi INE pel nom (sis amb una forma diferent, a mà). Població del padró de l'INE de l'any avaluat.
- **Atribució a partits**: ajuntaments, alcalde en funcions al final del període avaluat segons el [registre d'alcaldes del Ministeri de Política Territorial](https://concejales.redsara.es/consulta/) (per a l'avaluació «2022/23», l'1 de juny de 2023, abans de les corporacions sorgides de les eleccions de maig); comunitats i Estat, president en funcions el 31 de desembre de l'any avaluat (ITCanarias) o el 30 de juny de l'any de l'avaluació (CTBG). Els partits s'agrupen en famílies polítiques.
- **Obligacions legals**: arts. 5 a 9 de la [Llei 19/2013, de transparència, accés a la informació pública i bon govern](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); a Canàries, la [Llei 12/2014, de transparència i d'accés a la informació pública](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Dades actualitzades" />
