---
title: Publizitate aktiboa
description: "Argitaratzen eta garaiz bidaltzen al dute administrazioek legeak eskatzen diena? Erakundez erakundeko ebaluazio ofizialak (Gardentasun Kontseilua, Kanariak, Katalunia eta Murtzia) eta 8.100 udal baino gehiagoren, diputazioen eta erkidegoen neurketa propioa, ez-betetzeak adierazita eta alderdien araberako alderaketarekin."
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
    '/eu/territorios/municipios?m=' || cod_mun AS enlace
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

# 📋 Publizitate aktiboa: argitaratzen al dute administrazioek legeak eskatzen diena?

{#if mp_destacados.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Bidali beharrekoa egunean ageri ez duten administrazioak</p>
    <p class="mt-2 text-red-900 dark:text-red-100">Erkidegoak, diputazioak eta 20.000 biztanle edo gehiagoko udalak, duela hiru hilabete baino gehiago epea amaitu zitzaien betebeharren bat dutenak, eta horri buruz erregistro ofizialean <b>ezer ez da ageri</b>. Guztira, tamaina guztietako {formatNumber(mp_resumen[0]?.con_incumplimientos, 0)} administrazio daude egoera horretan.</p>
    {#each mp_destacados.slice(0, 12) as d}
    <div class="mt-4">
        <p class="text-xl font-extrabold leading-tight text-red-700 dark:text-red-300">{#if d.cod_mun}<a class="underline" href="/eu/territorios/municipios?m={d.cod_mun}">{d.nombre_entidad}</a>{:else}{d.nombre_entidad}{/if} <span class="whitespace-nowrap text-base font-semibold">({d.tipo_entidad}{d.provincia ? ', ' + d.provincia : ''}{d.poblacion ? ', ' + formatNumber(d.poblacion, 0) + ' bizt.' : ''})</span></p>
        <p class="mt-1 text-red-900 dark:text-red-100">Ez da ageri: {d.incumplimientos}.</p>
    </div>
    {/each}
    {#if mp_destacados.length > 12}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">Eta tamaina horretako beste {mp_destacados.length - 12}. Guztiak <a class="font-semibold underline" href="#neurketa-propioa-administrazio-guztiak">neurketa propioaren taulan</a> daude.</p>
    {/if}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">«Ez da ageri» esan nahi du ez dagoela iturri ofizialean azken deskargaren datan, ez dela frogatu egin ez denik. Kasu bakoitzak bere fitxara eramaten du, iturriarekin.</p>
</div>
{/if}

2014tik, [gardentasunari buruzko 19/2013 Legeak](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) administrazio guztiak behartzen ditu **beren kabuz argitaratzera**, inork eskatu gabe, informazio-zerrenda bat beren gardentasun-atarian: nork agintzen duen eta zenbat kobratzen duen, zer arau prestatzen dituen, zer kontratu eta diru-laguntza ematen dituen, haren aurrekontuak eta kontuak, haren ondarea. Horri **publizitate aktiboa** deritzo. Gainera, beren kontuak, aurrekontuak, kontratuak eta diru-laguntzak erregistro ofizialetara **bidali** behar dituzte, legeak finkatutako epeetan. Orri honek dauden **ebaluazio ofizialak** eta administrazio guztien **neurketa propio** bat biltzen ditu.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Erantzun laburra</p>
<p class="mb-1">Ez dago administrazio guztientzako ebaluazio ofizial <b>bakar eta homogeneorik</b>. Kontrol-organo bakoitzak <b>bere eremua</b> ebaluatzen du, bere metodoarekin. Lauk baino ez dituzte argitaratzen erakunde bakoitzeko notak: Gardentasun eta Gobernu Oneko Kontseiluak (Estatua eta haren sektore publikoa), Kanarietako Komisionatuak, Kataluniako Síndic de Greugesek eta Murtziako Kontseiluak. Horrela, <b>Kanarietako, Kataluniako eta Murtziako udalak</b> daude estalita, eta ia beste inor ez.</p>
<p class="mb-0">Gainerakoetara iristeko, SpainFactsek <b>bere kabuz neurtzen ditu</b> 8.100 udal baino gehiago, diputazioak eta erkidegoak. Erregistro ofizialetan egiaztatzen du betebehar bakoitza ageri den eta epean iritsi zen. Gaur, {formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} udalek ({formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %) dute duela hiru hilabete baino gehiago epea amaitu zitzaien betebeharren bat, eta horri buruz ezer ez da ageri. Ebaluatzaile desberdinen notak <b>ez dira elkarren artean alderagarriak</b>, ezta neurketa propioarekin ere.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="EAOren ataria"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="betetako derrigorrezko informazioa ({age[age.length - 1]?.anio}, ICIO)"
        source="Gardentasun eta Gobernu Oneko Kontseilua"
        sparklineData={age.map(d => ({...d, y: d.icio}))}
    />
    <KpiCard
        title="CTBGk ebaluatutako erkidegoak"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="hitzarmena duten 8en batez besteko ICIOa, 2021eko berrikuspena"
        source="Gardentasun eta Gobernu Oneko Kontseilua"
    />
    <KpiCard
        title="Kanarietako udalak"
        value={itc_resumen[0]?.media}
        formattedValue="10etik {formatNumber(itc_resumen[0]?.media / 10, 2)}"
        period="batez besteko nota Kanarietako Gardentasun Indizean ({itc_ultimo[0]?.etiqueta})"
        source="Kanarietako Gardentasun Komisionatua"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.media / 10}))}
    />
    <KpiCard
        title="Nota baxua duten Kanarietako udalak"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="guztira {formatNumber(itc_resumen[0]?.total, 0)}: 5etik behera edo ebaluazioa egin gabe ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => ({...d, y: d.suspenso}))}
    />
</Grid>

## Zer eskatzen duen legeak

19/2013 Legeak (5.etik 8.era bitarteko artikuluak) hiru multzotan biltzen ditu betebeharrak, eta autonomia-erkidegoetako gardentasun-legeek beste batzuk gehitzen dituzte beren administrazioentzat eta udalentzat:

- **Erakunde-, antolaketa- eta plangintza-informazioa**: eginkizunak, araudia, organigrama, arduradunak eta haien ibilbidea, planak eta programak eta haien betetze-maila.
- **Garrantzi juridikoko informazioa**: jarraibideak eta instrukzioak, lege-aurreproiektuak eta erregelamendu-proiektuak, arau-espedienteetako memoriak eta txostenak.
- **Informazio ekonomikoa, aurrekontuzkoa eta estatistikoa**: kontratuak (txikiak barne), hitzarmenak, gomendioak, diru-laguntzak eta laguntzak, aurrekontuak eta haien betearazpena, kontuak eta auditoria-txostenak, goi-karguen ordainsariak, bateragarritasunak, ondasun patrimonialak eta zerbitzuen kalitateari buruzko estatistikak.

Informazioak **argia, egituratua, eguneratua eta berrerabilgarria** izan behar du (5. art.). Betebehar horiek behin eta berriz ez betetzea arau-hauste astuna da estatuko legearen arabera (9.3 art.), baina praktikan zehapenak salbuespenezkoak dira: kontrol-organoek **gomendatu eta ebaluatu** egiten dute, ez dute isunik jartzen.

## Nork ebaluatzen duen eta zer argitaratzen duen

| Kontrol-organoa | Nor ebaluatzen duen | Zer argitaratzen duen erakunde bakoitzeko | Hemen erabiltzen al da? |
|---|---|---|---|
| [Gardentasun eta Gobernu Oneko Kontseilua](https://consejodetransparencia.es/evaluacion) (CTBG) | EAO eta estatuko sektore publikoa, konstituzio-organoak, alderdiak, sindikatuak, diruz lagundutako erakundeak; eta hitzarmena duten autonomia-erkidego eta -hiriak (Asturias, Kantabria, Gaztela-Mantxa, Extremadura, Errioxa, Ceuta eta Melilla; Madril 2020-2021ean) eta haien udal batzuk | Derrigorrezko Informazioa Betetzeko Indizea (ICIO, 0-100 %, MESTA metodologia) erakunde bakoitzeko Word txosten batean; datu-taularik gabe | Bai: EAOren ataria, 8 erkidego, 11 udal eta, 2022tik, txosten bateratuetako taula (estatuko sektore publikoa, erakunde pribatuak, korporazioak) |
| [Kanarietako Gardentasun Komisionatua](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Kanarietako sektore publiko osoa (Gobernua, kabildoak, udalak, unibertsitateak eta haien erakundeak) eta diruz lagundutako erakunde pribatuak | Kanarietako Gardentasun Indizea (ITCanarias, 0-10) Excel taula batean, erakunde guztiekin 2016tik (CC BY 4.0) | Bai: sektore publikoa |
| [Murtziako Eskualdeko Gardentasun Kontseilua](https://comisionadotransparencia.carm.es/informes-de-evaluacion) | Eskualdeko administrazioa, haren 45 udalak eta haren sektore publikoa, alderdiak, sindikatuak, federazioak… | Publizitate aktiboa betetzeko indizea (ICPA, 0-10) 2020tik 2023ra, 2023ko txostenaren eranskineko taula batean (PDF). Borondatezko autoebaluazioa da, Kontseiluak egiaztatzen duena | Bai: eranskineko taula |
| [Kataluniako Síndic de Greuges](https://www.sindic.cat/ca/page.asp?id=904) | Kataluniako 947 udalak, diputazioak, eskualde-kontseiluak, Generalitateko sailak, unibertsitateak eta kontrol-organoak | Publizitate aktiboaren garapen-indizea (IDPAC, 0-100), Síndicek berak berrikusia, datu irekietan (CSV, CC0) 2026ko ediziotik | Bai |
| Andaluzia, Aragoi, Gaztela eta Leon, Valentziako Erkidegoa, Galizia, Madril, Nafarroa, Euskadi eta beste batzuetako kontseiluak eta komisionatuak | Beren erkidegoa eta haren toki-erakundeak | Urteko memoriak, kontrol-planak eta ebazpenak, PDFan. Ez dugu aurkitu erakunde bakoitzeko argitaratutako indizerik. Madril bere udal guztiak ebaluatzen hasi da (emaitzak 2026ko memorian aurreikusita) | Ez |

Gizarte zibilaren rankingak ere badaude (Dyntra, Bartzelonako Unibertsitate Autonomoaren Infoparticipa Mapa, Transparency International Espainiaren antzinako indizeak). **Ez dira hemen erabiltzen**: ez dira iturri ofizialak, eta ez dugu egiaztatu haien lizentziak datuak berrerabiltzea ahalbidetzen duenik.

## Estatuko Administrazio Orokorra

CTBGk urtero ebaluatzen du EAOren [Gardentasun Ataria](https://transparencia.gob.es/). ICIOak betebehar bakoitzerako neurtzen du informazioa argitaratzen den eta zer kalitaterekin (forma, eguneratze-data, irisgarritasuna, berrerabilpena).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="EAOren Gardentasun Ataria: betetze-indizea (%)"
    markers=true
    sort=false
/>

Bost ebaluazioak Pedro Sánchezen Gobernuei dagozkie; beraz, **ez dute alderdiak alderatzeko aukerarik ematen** gobernu zentralean. Gainera, CTBGk urtero ebaluatzen ditu, bereiz, estatuko sektore publikoko ehunka erakunde, enpresa eta fundazio; haien notak banakako txostenetan daude, eta oraindik ez dira hona ekarri.

## CTBGk ebaluatutako autonomia-erkidegoak eta udalak

Beren kontrol-organoa sortu ez zuten erkidegoek hitzarmen bat sinatu zuten CTBGk haien gardentasuna zain dezan. 2020an CTBGk haien atariak ebaluatu zituen, eta 2021ean haren gomendioak aplikatu zituzten berrikusi zuen.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Derrigorrezko informazioa betetzeko indizea (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Autonomia-erkidegoa edo -hiria" />
    <Column id=familia title="Presidentearen alderdia" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Hobekuntza (puntuak)" fmt=num1 contentType=delta />
</DataTable>

Guztiek hobera egin zuten gomendioen ondoren. Zortzi erkidego baino ez daudenez, lau alderdi desberdinek gobernatuak, **ez du zentzurik alderdiak alderatzeak**: edozein desberdintasun erkidego bakar baten ondorio izan daiteke.

CTBGk ebaluatutako udalak gutxi dira eta ez dira lagin adierazgarria (Kontseiluak aukeratu zituen). Hala ere, erakusten dute udal handi bat betetzetik zein urrun egon daitekeen: 2021eko berrikuspenean, ebaluatutako {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} udalen artean, {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} 50 %-tik behera zeuden oraindik.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Udala" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=familia title="Alkatearen alderdia (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Kanariak: sektore publiko osoa, erakundez erakunde

Kanariak da bere administrazio guztien nota **urtero eta datu irekietan** argitaratzen duen erkidego bakarra. Gardentasun Komisionatuak Kanarietako legearen betebeharrei buruzko galdetegi bat bidaltzen du (estatukoa baino zorrotzagoa), erantzunak atarietan egiaztatzen ditu eta Kanarietako Gardentasun Indizea kalkulatzen du (0tik 10era). Ebaluazioa betetzen ez duen erakundea **ez-betetzaile** gisa agertzen da.

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
    title="Kanarietako Gardentasun Indizea, batez besteko nota (100etik)"
/>

<p class="text-xs text-gray-500">Azken bi ebaluazioak ez dira urte naturalak: «2022/23» ebaluazioak 2022a eta 2023ko lehen seihilekoa hartzen ditu; «2023/24» ebaluazioak, 2023ko bigarren seihilekoa eta 2024a. Nota 100etik erakusten da, grafikoaren eskalarekin alderatzeko (10etik 7,5 = 75).</p>

Hobekuntza argia da: udalen batez besteko nota lehen ebaluazioan {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} izan zen, eta azkenekoan, berriz, {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)}. Igoeraren zati batek erakusten du erakundeek galdetegiari erantzuten ikasten dutela, eta asko jada gehienekoan daude; beraz, nota altuek gutxi bereizten dituzte elkarren artean.

### Udalak, {itc_ultimo[0]?.etiqueta}

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Mugak © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Nota (100etik)', fmt: 'num1'},
        {id: 'familia', title: 'Alkatearen alderdia'},
        {id: 'situacion', title: 'Egoera'}
    ]}
/>

<p class="text-xs text-gray-500">Kolore-eskala 50ean hasten da: horren azpitik, denak gorriz ikusten dira. Grisez dagoen udalerriak ez zuen ebaluazioa egin.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=puntuacion_original title="Nota (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Egoera" />
    <Column id=familia title="Alkatearen alderdia" />
</DataTable>

### Kanarietako Gobernua eta kabildoak

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Erakundea" />
    <Column id=tipo_administracion title="Mota" />
    <Column id=en_2017 title="2017ko nota (100etik)" fmt=num1 />
    <Column id=ultima title="Azken nota (100etik)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="Presidentearen alderdia" />
</DataTable>

<p class="text-xs text-gray-500">Kabildoak ez zaizkio alderdi bati egozten: SpainFacts-en ez dago oraindik haien presidenteen erregistro ofizialik.</p>

### Enpresa, erakunde eta fundazio publikoak

Gehien betetzen ez dena ez da administrazioetan, haien **menpeko erakundeetan** baizik: enpresa publikoak, fundazioak, partzuergoak eta zuzenbide publikoko korporazioak, horiek ere behartuta baitaude.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Erakunde mota" />
    <Column id=entidades title="Erakundeak" fmt=num0 />
    <Column id=media title="Batez besteko nota (100etik)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="Ebaluazioa egin ez zutenak" fmt=num0 />
</DataTable>

<details>
<summary>Azken bi edizioetan ebaluazioa egin ez zuten erakundeak</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Ebaluazioa" />
    <Column id=entidad title="Erakundea" />
    <Column id=tipo_entidad title="Mota" />
    <Column id=entidad_principal title="Nongoa den" />
</DataTable>

</details>

```sql sindic_aytos
SELECT cod_mun, municipio, provincia, poblacion, puntuacion, familia, gobernante,
    '/eu/territorios/municipios?m=' || cod_mun AS enlace
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

## Katalunia: 947 udalak, Síndicek berrikusiak

Síndic de Greugesek **berak** berrikusten du Kataluniako udal bakoitzaren ataria, eta emaitza datu irekietan argitaratzen du: erkidego bateko udal guztien kanpoko ebaluazio bakarra da. Publizitate aktiboaren garapen-indizeak (IDPAC, 0-100) derrigorrezko edukia (70 %) eta web-guneko kalitatea (30 %) konbinatzen ditu. 2026ko edizioa urtarriletik maiatzera egin zen.

<DataTable data={sindic_tramos} rows=all>
    <Column id=tramo title="Biztanleak" />
    <Column id=ayuntamientos title="Udalak" fmt=num0 />
    <Column id=media title="Batez besteko IDPAC" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=menos_50 title="50etik behera" fmt=num0 />
</DataTable>

<DataTable data={sindic_aytos} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
    <Column id=familia title="Alkatearen alderdia" />
</DataTable>

<details>
<summary>Generalitatea, diputazioak, eskualde-kontseiluak eta beste batzuk</summary>

<DataTable data={sindic_otros} search=true rows=15>
    <Column id=entidad title="Erakundea" />
    <Column id=tipo_entidad title="Mota" />
    <Column id=puntuacion title="IDPAC (0-100)" fmt=num1 contentType=colorscale colorMin=40 colorMax=100 />
</DataTable>

</details>

## Murtziako Eskualdea

Murtziako Eskualdeko Gardentasun Kontseiluak ebaluatzeko prest dagoen erakunde bakoitzaren publizitate aktiboa betetzeko indizea (ICPA) argitaratzen du. Erakundeak plataforma batean betetzen du ebaluazioa, eta Kontseiluak egiaztatzen du. **Borondatezkoa da**: parte hartu ez zuen udal bat «ez zuen parte hartu» gisa agertzen da, inoiz ez zero batekin.

<BarChart
    data={murcia_serie}
    x=anio
    y={['evaluados', 'no_participaron']}
    type=stacked
    title="Ebaluatutako eta parte hartu ez zuten Murtziako udalak"
    sort=false
/>

<DataTable data={murcia_aytos} search=true rows=15>
    <Column id=municipio title="Udalerria" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=n2020 title="2020" fmt=num1 />
    <Column id=n2021 title="2021" fmt=num1 />
    <Column id=n2022 title="2022" fmt=num1 />
    <Column id=n2023 title="2023 (100etik)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
    <Column id=no_participo title="Parte hartu gabeko urteak" fmt=num0 />
    <Column id=familia title="Alkatearen alderdia (2023)" />
</DataTable>

<p class="text-xs text-gray-500">Jatorrizko nota 0-10 da, 100etik erakutsia. Gelaxka hutsa: ez zuen parte hartu edo ez zuten deitu.</p>

## Estatuko sektore publikoa

Urtero, Gardentasun Kontseiluak estatuko erakundeak, enpresak eta fundazioak ebaluatzen ditu, baita diru-laguntzak jasotzen dituzten erakunde pribatuak eta elkargo profesionalak bezalako korporazioak ere. Haren txosten bateratuek taula bat dakarte, bakoitzaren betetze-indizearekin (ICIO).

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
    title="Ebaluatutako erakundeen batez besteko ICIOa (%)"
/>

<p class="text-xs text-gray-500">Urtero erakunde desberdinak ebaluatzen dira (sektore publikoko 225 2025ean, 2022ko 74en aldean); beraz, batez bestekoak ez ditu beti erakunde berberak jarraitzen.</p>

<DataTable data={spe_ultimo} search=true rows=15>
    <Column id=entidad title="Erakundea" />
    <Column id=grupo title="Taldea" />
    <Column id=anio title="Azken ebaluazioa" />
    <Column id=icio title="ICIO (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Alderdika Kanarietan

Ebaluazio ofizialekin, alderaketa **Kanarietako udalekin** baino ez da posible: 88 dira, guztiak ebaluatzen dira, metodo berarekin, 2016tik. Udal eta ebaluazio bakoitzerako nota **aurreikusgarria** kalkulatzen da: tamaina bereko Kanarietako udalen batez bestekoa (5.000 biztanletik behera, 5.000tik 20.000ra eta 20.000tik gora) ebaluazio berean. Ondoren, alderdi bakoitzak gobernatutakoen batez besteko nota haien nota aurreikusgarriarekin alderatzen da.

```sql itc_familia_grafico
SELECT familia, diferencia FROM ${itc_familia}
```

<BarChart
    data={itc_familia_grafico}
    x=familia
    y=diferencia
    swapXY=true
    yFmt=num1
    title="Behatutako nota ken nota aurreikusgarria (puntuak, 100etik)"
    fillColor="#0f766e"
    sort=false
/>

<DataTable data={itc_familia} rows=all>
    <Column id=familia title="Alkatearen alderdia" />
    <Column id=evaluaciones title="Ebaluazioak" fmt=num0 />
    <Column id=municipios title="Udalerri desberdinak" fmt=num0 />
    <Column id=observada title="Batez besteko nota" fmt=num1 />
    <Column id=esperada title="Aurreikusgarria" fmt=num1 />
    <Column id=diferencia title="Aldea" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num1 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num1 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

<p class="text-xs text-gray-500">Gutxienez 20 ebaluazio dituzten alderdiak baino ez; ebaluazioa egin ez zuten udalek ez dute notarik, eta ez dira kalkuluan sartzen. Konfiantza-tartea udalerri desberdinen kopuruarekin kalkulatzen da, ez ebaluazioenarekin, udal beraren urte jarraituetako notak ez baitira independenteak. «Sin detalle en la fuente» taldeak erregistro ofizialak modu generikoan etiketatzen dituen zerrendetan hautatutako alkatetzak biltzen ditu; «Independientes y locales» taldeak, hautesle-elkarteak. Alderdien arteko alde batek ez du frogatzen alderdiaren ondorio denik: plantillak, baliabide teknikoek, uharteak eta gobernatzen duen pertsonak ere eragiten dute.</p>

Autonomia-erkidegoetarako eta gobernu zentralerako **ez dago lagin nahikorik**: ebaluazio bakarra erkidego eta urte bakoitzeko, eta Estatuaren kasuan Gobernu bakarra ebaluatutako aldi osoan.

## Neurketa propioa: administrazio guztiak

Administrazio gehienak ia inork ez dituenez ebaluatzen, **guk neurtzen dugu**, metodo berarekin guztientzat. Ez dugu web-ataria begiz puntuatzen. **Data duten erregistro ofizialetan** egiaztatzen dugu legezko betebehar bakoitza ageri den eta bere epearen barruan iritsi zen. Erregistroak hauek dira: Diru-laguntzen Datu-base Nazionala, Kontratazio Plataforma, Kontuen Auzitegia eta Ogasuna. Betebehar bakoitzak 1 puntu jasotzen du garaiz ageri bada, 0,5 berandu ageri bada eta 0 epea amaituta ageri ez bada. Administrazio bakoitzaren indizea (0-100) neurtutako azken aldiaren batez bestekoa da. Adierazle bakoitzaren irizpideak, lege-oinarria eta kodea [Iturriak › SpainFactsen neurketa propioko datuak](/eu/fuentes#spainfactsen-neurketa-propioko-datuak) atalean daude.

<Grid cols=4>
    <KpiCard
        title="Neurtutako administrazioak"
        value={mp_resumen[0]?.entidades}
        formattedValue={formatNumber(mp_resumen[0]?.entidades, 0)}
        period="{formatNumber(mp_resumen[0]?.ayuntamientos, 0)} udal eta {formatNumber(mp_resumen[0]?.entidades - mp_resumen[0]?.ayuntamientos, 0)} diputazio, kabildo eta erkidego"
        source="SpainFacts (neurketa propioa)"
    />
    <KpiCard
        title="Epea amaituta zerbait ageri ez zaien udalak"
        value={mp_resumen[0]?.pct_aytos_incumplimientos}
        formattedValue="{formatNumber(mp_resumen[0]?.pct_aytos_incumplimientos, 1)} %"
        period="{formatNumber(mp_resumen[0]?.aytos_con_incumplimientos, 0)} udal, epea amaitu eta 3 hilabete baino gehiagora"
        source="SpainFacts (neurketa propioa)"
    />
    <KpiCard
        title="20.000 biztanle edo gehiagokoak"
        value={mp_resumen[0]?.grandes_con_incumplimientos}
        formattedValue={formatNumber(mp_resumen[0]?.grandes_con_incumplimientos, 0)}
        period="epea amaituta betebeharren bat ageri ez zaien udal handiak"
        source="SpainFacts (neurketa propioa)"
    />
    <KpiCard
        title="Udalen indize mediana"
        value={mp_resumen[0]?.mediana_aytos}
        formattedValue="100etik {formatNumber(mp_resumen[0]?.mediana_aytos, 1)}"
        period="betebehar bakoitzaren azken aldiaren batez bestekoa"
        source="SpainFacts (neurketa propioa)"
    />
</Grid>

### Betebeharrez betebehar

<DataTable data={mp_obligaciones} rows=all groupBy=tipo_entidad>
    <Column id=tipo_entidad title="Administrazioa" />
    <Column id=obligacion title="Betebeharra" />
    <Column id=ultimo_periodo title="Azken aldia" />
    <Column id=entidades title="Neurtuak" fmt=num0 />
    <Column id=cumplimiento title="Betetzea (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=con_retraso title="Atzerapenarekin" fmt=num0 />
    <Column id=no_consta title="Ez da ageri" fmt=num0 />
    <Column id=mediana_retraso title="Egunak (mediana)" fmt=num0 />
    <Column id=en_indice title="Indizean" />
</DataTable>

<p class="text-xs text-gray-500">«Egunak (mediana)»: behin bakarrik egin beharreko betebeharretan, berandu iritsi zirenen atzerapena; kontratuetan eta diru-laguntzetan, administrazio tipikoak argitaratzeko edo erregistratzeko behar duena. Administrazio bakoitzaren epea amaituta duen azken aldia zenbatzen da. Iturriak neurtzen ez dituen administrazioak (adibidez, foru-bidetik bidaltzen dutenak) ez dira zenbatzen. Betebehar bat indizean eta ez-betetzeen zerrendan sartzen da bere motako administrazioen 80 % gutxienez neurtzen duenean; ordura arte, Kontuen Auzitegiaren probintziaz probintziako arakatzea bezala, hemen eta fitxa bakoitzean baino ez da ikusten.</p>

### Tamainaren eta probintziaren arabera

Udal txikiek huts egiten dute gehien: askok ez dute idazkaririk ere lanaldi osoan. Horregatik, udal bakoitza bere tamainakoekin alderatzen da beti.

<DataTable data={mp_tramos} rows=all>
    <Column id=tramo_poblacion title="Biztanleak" />
    <Column id=ayuntamientos title="Udalak" fmt=num0 />
    <Column id=indice_medio title="Batez besteko indizea" fmt=num1 contentType=colorscale colorMin=70 colorMax=100 />
    <Column id=pct_incumplimientos title="Epea amaituta zerbait ageri ez zaienak (%)" fmt=num1 />
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
        {id: 'pct_incumplimientos', title: 'Epea amaituta zerbait ageri ez zaien udalak (%)', fmt: 'num1'},
        {id: 'indice_medio', title: 'Batez besteko indizea', fmt: 'num1'},
        {id: 'ayuntamientos', title: 'Udalak', fmt: 'num0'}
    ]}
/>

### Udal guztiak

Indize txikienetik handienera ordenatuta. Bilatu zurea edo ireki haren fitxa betebehar bakoitza ikusteko, bere epea, data eta orduan nork gobernatzen zuen.

<DataTable data={mp_ranking} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=indice title="Indizea (0-100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=media_tramo_espana title="Bere tamainakoen batez bestekoa" fmt=num1 />
    <Column id=n_incumplimientos_destacados title="Epea amaituta, ageri ez" fmt=num0 />
    <Column id=incumplimientos title="Zer ez den ageri" />
    <Column id=familia_actual title="Alkatearen alderdia gaur" />
</DataTable>

### Alderdika

Udal, betebehar eta aldi bakoitzerako **aurreikusgarria** kalkulatzen da: tamaina eta erkidego bereko udalen batez bestekoa aldi horretan. Ondoren, alderdi bakoitzak **epearen egunean** gobernatutakoen nota aurreikusgarriarekin alderatzen da. Azken bost urteak erabiltzen dira.

<DataTable data={mp_familia} rows=all>
    <Column id=familia title="Alkatearen alderdia epearen egunean" />
    <Column id=municipios title="Udalerriak" fmt=num0 />
    <Column id=observada title="Batez besteko nota" fmt=num1 />
    <Column id=esperada title="Aurreikusgarria" fmt=num1 />
    <Column id=diferencia title="Aldea" fmt=num2 contentType=delta />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num2 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num2 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

<p class="text-xs text-gray-500">Gutxienez 30 udalerri dituzten alderdiak baino ez. Udalerri bat behin zenbatzen da alderdi bakoitzeko, nahiz eta zenbait betebehar eman, eta tartea udalerrien kopuruarekin kalkulatzen da. Alderdien arteko alde batek ez du frogatzen alderdiaren ondorio denik: plantillak, idazkari-kontu-hartzaileak, diputazioaren baliabideek eta gobernatzen duen pertsonak ere eragiten dute.</p>

## Zer falta den

- **Ez dago Espainia osorako ebaluazio ofizial homogeneorik.** Kontrol-organo bakoitzak bere eremua ebaluatzen du bere metodoarekin: Kanarietako udal baten nota (ITCanarias), Kataluniako batena (IDPAC) eta Murtziako batena (ICPA) ezin dira elkarren artean alderatu.
- **Neurketa propioak erregistro ofizialetara bidaltzen dena neurtzen du, ez gardentasun-ataria bera.** Kontu orokorra edo kontratuak ageri izateak ez du bermatzen atariak organigrama edo ordainsariak argitaratzen dituenik. Horretarako, atariak berrikusten dituen robot bat prestatzen ari gara, eskuz berrikusitako lagin batekin haren errorea neurtzeko. Haren emaitzak errore hori neurtuta dagoenean argitaratuko dira.
- **Kontratazioa Katalunian, Euskadin eta Nafarroan.** Haien administrazioek beren plataforman argitaratzen dute, ez Estatukoan; estalita ez dagoenean, ez dira adierazle horretan zenbatzen.
- **Andaluziak, Gaztela eta Leonek, Aragoik, Valentziako Erkidegoak, Galiziak, Nafarroak edo Euskadik** ez dute erakunde bakoitzeko notarik argitaratzen. Madril bere udal guztiak ebaluatzen hasi da. Datuak daudenean bertan sartuko dira.
- Ez ebaluazioek ez neurketa propioak ez dute esaten **informazioa egiazkoa edo osoa den**: argitaratuta edo bidalita dagoen eta noiz, besterik ez.

---

## Metodologia eta iturriak

- **[Gardentasun eta Gobernu Oneko Kontseilua – Ebaluazioa](https://consejodetransparencia.es/evaluacion)**: [MESTA metodologiaren](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf) Derrigorrezko Informazioa Betetzeko Indizea (ICIO), **behin betiko txosten** bakoitzaren testutik irakurria (.docx): EAOren Gardentasun Ataria (2021-2025), hitzarmena duten autonomia-erkidego eta -hiriak (2020ko ebaluazioa eta 2021eko berrikuspena) eta haien ebaluatutako udalak. CTBGk zuzenean berrikusten du atari bakoitza, eta betebehar bakoitzerako puntuatzen du edukia argitaratzen den eta haren kalitate-atributuak (forma, eguneratzea, irisgarritasuna, berrerabilpena). Datuen jatorria: Gardentasun eta Gobernu Oneko Kontseilua (37/2007 Legearen araberako berrerabilpena).
- **[Kanarietako Gardentasun Komisionatua – Puntuazioak](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: Kanarietako Gardentasun Indizeko sektore publikoaren puntuazioen taula nagusia (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), 2016ko ebaluaziotik. Derrigorrezko informazioaren betetzea, web-euskarriaren kalitatea eta borondatezko gardentasuna konbinatzen ditu ([metodologia](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). Erakundeak galdetegi bat betetzen du, eta Komisionatuak egiaztatzen du. 100etik erakusten da (nota bider 10) ICIOaren ondoan marrazteko soilik; **bi eskalak ez dira baliokideak**.
- **[Kataluniako Síndic de Greuges – IDPAC](https://www.sindic.cat/ca/page.asp?id=904)**: [CSVa datu irekietan](https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3) (CC0), 2026ko edizioa. Síndicek atari bakoitza berrikusten du; IDPACek (0-100) derrigorrezko edukia (70 %) eta web-gunea (30 %) haztatzen ditu ([gida metodologikoa](https://www.sindic.cat/site/files/informe_transparencia/guia_metodologica_municipis_no_rurals_2026.pdf)). Udalerriak INErekin lotzen dira izenaren eta probintziaren bidez.
- **[Murtziako Eskualdeko Gardentasun Kontseilua – Ebaluazio-txostenak](https://comisionadotransparencia.carm.es/informes-de-evaluacion)**: 2023ko txostenaren I. eranskina (PDF), ICPA 0-10 2020tik 2023ra = 70 % ICIO (MESTA) + 30 % web-euskarria. Kontseiluak egiaztatutako borondatezko autoebaluazioa; «ez zuen parte hartu» ez da zero gisa zenbatzen. 100etik erakusten da.
- **[CTBG – Ebaluazio-txosten bateratuak](https://consejodetransparencia.es/evaluacion)** (2022-2026): eranskineko taula, estatuko sektore publiko instituzionaleko erakunde bakoitzaren, diruz lagundutako erakunde pribatuen, zuzenbide publikoko korporazioen eta konstituzio-organoen ICIOarekin. Txosten bateratuak hamarrenera biribiltzen du.
- **Neurketa propioa (SpainFacts)**: legezko epea duten bidalketa-betebeharrak, erregistro ofizialetan egiaztatuak; adierazle bakoitzaren irizpideak, lege-oinarria eta kodea [Iturriak › SpainFactsen neurketa propioko datuak](/eu/fuentes#spainfactsen-neurketa-propioko-datuak) atalean. Epearen egunean kargudun zegoen gobernuari egozten zaio.
- **Udalerriak**: Komisionatuaren izenak INEren kodearekin lotzen dira izenaren bidez (sei, forma desberdina dutenak, eskuz). Ebaluatutako urteko INEren erroldako biztanleria.
- **Alderdiei egoztea**: udaletan, ebaluatutako aldiaren amaieran kargudun zegoen alkatea, [Lurralde Politikako Ministerioaren alkateen erregistroaren](https://concejales.redsara.es/consulta/) arabera («2022/23» ebaluaziorako, 2023ko ekainaren 1a, maiatzeko hauteskundeetatik sortutako korporazioen aurretik); erkidegoetan eta Estatuan, ebaluatutako urteko abenduaren 31n (ITCanarias) edo ebaluazio-urteko ekainaren 30ean (CTBG) kargudun zegoen presidentea. Alderdiak familia politikotan biltzen dira.
- **Lege-betebeharrak**: [gardentasunari, informazio publikoa eskuratzeari eta gobernu onari buruzko 19/2013 Legearen](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) 5.etik 9.era bitarteko artikuluak; Kanarietan, [gardentasunari eta informazio publikoa eskuratzeari buruzko 12/2014 Legea](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Datuak eguneratuta" />
