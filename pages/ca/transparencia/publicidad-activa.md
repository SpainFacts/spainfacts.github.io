---
title: Publicitat activa
description: "Publiquen les administracions als seus portals de transparència el que els obliga la llei? Avaluacions oficials per entitat (Consell de Transparència i Bon Govern i Comissionat de Transparència de Canàries), la seva evolució, la comparació per partit i el que encara no es pot mesurar."
i18n_origen: 6724b8e266cf
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql age
SELECT CAST(anio AS VARCHAR) AS anio, puntuacion AS icio, gobernante, familia, url_fuente
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
SELECT entidad, CAST(anio AS VARCHAR) AS evaluacion, puntuacion AS icio
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

# 📋 Publicitat activa: publiquen les administracions el que els obliga la llei?

Des del 2014, la [Llei 19/2013 de transparència](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) obliga totes les administracions a **publicar pel seu compte**, sense que ningú ho demani, una llista d'informacions al seu portal de transparència: qui mana i quant cobra, quines normes prepara, quins contractes i subvencions concedeix, els seus pressupostos i comptes, el seu patrimoni. És el que s'anomena **publicitat activa**. Aquesta pàgina reuneix les **avaluacions oficials** que diuen, entitat per entitat, en quina mesura es compleix.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">La resposta curta</p>
<p class="mb-1">No hi ha una avaluació <b>única i homogènia</b> per a totes les administracions d'Espanya. Cada òrgan de control (el Consell de Transparència i Bon Govern i els consells o comissionats autonòmics) avalua el <b>seu àmbit</b>, amb el seu propi mètode i calendari, i gairebé tots publiquen els resultats en informes en PDF o Word, no en dades.</p>
<p class="mb-0">Amb dades oficials reutilitzables avui es pot veure: el <b>Portal de Transparència de l'Administració General de l'Estat</b> (2021-2025), <b>vuit comunitats i ciutats autònomes</b> i <b>onze ajuntaments</b> avaluats pel Consell de Transparència (2020-2021), i <b>tot el sector públic de Canàries</b>, inclosos els seus 88 ajuntaments, des del 2016. Les puntuacions d'avaluadors diferents <b>no són comparables entre si</b>.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Portal de l'AGE"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="de la informació obligatòria complerta el {age[age.length - 1]?.anio} (ICIO)"
        source="Consell de Transparència i Bon Govern"
        sparklineData={age.map(d => d.icio)}
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
        sparklineData={itc_aytos_serie.map(d => d.media / 10)}
    />
    <KpiCard
        title="Ajuntaments canaris amb nota baixa"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="de {formatNumber(itc_resumen[0]?.total, 0)}: per sota de 5 o sense retre l'avaluació ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => d.suspenso)}
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
| [Consell de Transparència i Bon Govern](https://consejodetransparencia.es/evaluacion) (CTBG) | AGE i sector públic estatal, òrgans constitucionals, partits, sindicats, entitats subvencionades; i les comunitats i ciutats autònomes amb conveni (Astúries, Cantàbria, Castella - la Manxa, Extremadura, La Rioja, Ceuta i Melilla; Madrid el 2020-2021) i alguns dels seus ajuntaments | Índex de Compliment de la Informació Obligatòria (ICIO, 0-100 %, metodologia MESTA) en un informe Word per entitat; sense taula de dades | Sí: Portal de l'AGE, 8 comunitats i 11 ajuntaments |
| [Comissionat de Transparència de Canàries](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Tot el sector públic canari (Govern, cabildos, ajuntaments, universitats i els seus ens) i entitats privades subvencionades | Índex de Transparència de Canàries (ITCanarias, 0-10) en una taula Excel amb totes les entitats des del 2016 (CC BY 4.0) | Sí: sector públic |
| [Consell de la Transparència de la Regió de Múrcia](https://comisionadotransparencia.carm.es/) | Administració regional, ajuntaments i el seu sector públic (autoavaluació verificada, basada en MESTA) | Informe executiu en PDF amb resultats agregats per tipus d'entitat; les notes per ajuntament només apareixen en gràfics | No: no hi ha dades per entitat reutilitzables |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/) | Administracions catalanes (Llei 19/2014) | Informe anual i informes individuals en PDF; índex de desenvolupament de la publicitat activa (IDPAC) en fase pilot des del 2024 | No: informes en PDF per entitat, sense taula |
| Consells i comissionats d'Andalusia, Aragó, Castella i Lleó, Comunitat Valenciana, Galícia, Navarra, País Basc i altres | La seva comunitat i les seves entitats locals | Memòries anuals, plans de control i inspecció i resolucions, en PDF; no hem trobat cap índex de compliment publicat per entitat | No |

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

## Per partit

La comparació només és possible amb els **ajuntaments canaris**: són 88, s'avaluen tots, amb el mateix mètode, des del 2016. Per a cada ajuntament i avaluació es calcula la nota **esperable**: la mitjana dels ajuntaments canaris de la mateixa mida (menys de 5.000, de 5.000 a 20.000 i més de 20.000 habitants) en aquella mateixa avaluació. Després es compara la nota mitjana dels governats per cada partit amb la seva esperable.

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

## Què hi falta

- **No hi ha una avaluació homogènia per a tota Espanya.** Cada òrgan de control avalua el seu àmbit amb el seu mètode: la nota d'un ajuntament canari (ITCanarias) i la d'un de càntabre (ICIO del CTBG) no es poden comparar.
- **La majoria dels òrgans autonòmics no publica notes per entitat en dades obertes.** Múrcia, Catalunya, Andalusia, Castella i Lleó i altres publiquen memòries i informes en PDF, de vegades amb les notes només en gràfics. Si algun publica els seus resultats per entitat en un format reutilitzable, s'hi incorporarà.
- **Els més de 8.100 ajuntaments d'Espanya no s'avaluen de manera sistemàtica**, llevat de Canàries. El CTBG en va avaluar 11 el 2020-2021.
- **El sector públic estatal** (organismes, empreses i fundacions) sí que té nota per entitat als informes del CTBG, però en documents individuals. El 2025 el CTBG va avaluar 225 d'aquestes entitats, amb un ICIO mitjà de només el 38,9 % ([nota del CTBG](https://consejodetransparencia.es/comunicacion/noticias/hemeroteca/2025/20251114)). És la pròxima ampliació viable.
- Les avaluacions mesuren **si la informació està publicada i com**, no si és veraç ni completa en el seu contingut.

---

## Metodologia i fonts

- **[Consell de Transparència i Bon Govern – Avaluació](https://consejodetransparencia.es/evaluacion)**: Índex de Compliment de la Informació Obligatòria (ICIO) de la [metodologia MESTA](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), llegit del text de cada **informe definitiu** (.docx): Portal de la Transparència de l'AGE (2021-2025), comunitats i ciutats autònomes amb conveni (avaluació del 2020 i revisió del 2021) i els seus ajuntaments avaluats. El CTBG revisa directament cada portal i puntua, per a cada obligació, si se'n publica el contingut i els seus atributs de qualitat (forma, actualització, accessibilitat, reutilització). Origen de les dades: Consell de Transparència i Bon Govern (reutilització segons la Llei 37/2007).
- **[Comissionat de Transparència de Canàries – Puntuacions](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: taula mestra de puntuacions del sector públic de l'Índex de Transparència de Canàries (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), des de l'avaluació del 2016. Combina el compliment de la informació obligatòria, la qualitat del suport web i la transparència voluntària ([metodologia](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). L'entitat emplena un qüestionari i el Comissionat el verifica. Es mostra sobre 100 (nota per 10) només per dibuixar-la al costat de l'ICIO; **les dues escales no són equivalents**.
- **Municipis**: els noms del Comissionat s'aparellen amb el codi INE pel nom (sis amb una forma diferent, a mà). Població del padró de l'INE de l'any avaluat.
- **Atribució a partits**: ajuntaments, alcalde en funcions al final del període avaluat segons el [registre d'alcaldes del Ministeri de Política Territorial](https://concejales.redsara.es/consulta/) (per a l'avaluació «2022/23», l'1 de juny de 2023, abans de les corporacions sorgides de les eleccions de maig); comunitats i Estat, president en funcions el 31 de desembre de l'any avaluat (ITCanarias) o el 30 de juny de l'any de l'avaluació (CTBG). Els partits s'agrupen en famílies polítiques.
- **Obligacions legals**: arts. 5 a 9 de la [Llei 19/2013, de transparència, accés a la informació pública i bon govern](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); a Canàries, la [Llei 12/2014, de transparència i d'accés a la informació pública](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Dades actualitzades" />
