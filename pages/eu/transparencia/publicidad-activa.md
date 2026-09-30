---
title: Publizitate aktiboa
description: "Argitaratzen al dute administrazioek beren gardentasun-atarietan legeak eskatzen diena? Erakundez erakundeko ebaluazio ofizialak (Gardentasun eta Gobernu Oneko Kontseilua eta Kanarietako Gardentasun Komisionatua), haien bilakaera, alderdien araberako alderaketa eta oraindik neurtu ezin dena."
i18n_origen: 8c5314133b0c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
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
    CASE WHEN cod_prov = '35' THEN 'Las Palmas' ELSE 'Santa Cruz de Tenerife' END AS provincia,
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

# 📋 Publizitate aktiboa: argitaratzen al dute administrazioek legeak eskatzen diena?

2014tik, [gardentasunari buruzko 19/2013 Legeak](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) administrazio guztiak behartzen ditu **beren kabuz argitaratzera**, inork eskatu gabe, informazio-zerrenda bat beren gardentasun-atarian: nork agintzen duen eta zenbat kobratzen duen, zer arau prestatzen dituen, zer kontratu eta diru-laguntza ematen dituen, haren aurrekontuak eta kontuak, haren ondarea. Horri **publizitate aktiboa** deritzo. Orri honek **ebaluazio ofizialak** biltzen ditu, erakundez erakunde betetze-maila zein den adierazten dutenak.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Erantzun laburra</p>
<p class="mb-1">Ez dago Espainiako administrazio guztientzako ebaluazio <b>bakar eta homogeneorik</b>. Kontrol-organo bakoitzak (Gardentasun eta Gobernu Oneko Kontseiluak eta autonomia-erkidegoetako kontseiluek edo komisionatuek) <b>bere eremua</b> ebaluatzen du, bere metodo eta egutegiarekin, eta ia guztiek PDF edo Word txostenetan argitaratzen dituzte emaitzak, ez datu gisa.</p>
<p class="mb-0">Datu ofizial berrerabilgarriekin gaur egun ikus daitezkeenak: <b>Estatuko Administrazio Orokorraren Gardentasun Ataria</b> (2021-2025), Gardentasun Kontseiluak ebaluatutako <b>zortzi autonomia-erkidego eta -hiri</b> eta <b>hamaika udal</b> (2020-2021), eta <b>Kanarietako sektore publiko osoa</b>, haren 88 udalak barne, 2016tik. Ebaluatzaile desberdinen puntuazioak <b>ez dira elkarren artean alderagarriak</b>.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="EAOren ataria"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="betetako derrigorrezko informazioa ({age[age.length - 1]?.anio}, ICIO)"
        source="Gardentasun eta Gobernu Oneko Kontseilua"
        sparklineData={age.map(d => d.icio)}
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
        sparklineData={itc_aytos_serie.map(d => d.media / 10)}
    />
    <KpiCard
        title="Nota baxua duten Kanarietako udalak"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="guztira {formatNumber(itc_resumen[0]?.total, 0)}: 5etik behera edo ebaluazioa egin gabe ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => d.suspenso)}
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
| [Gardentasun eta Gobernu Oneko Kontseilua](https://consejodetransparencia.es/evaluacion) (CTBG) | EAO eta estatuko sektore publikoa, konstituzio-organoak, alderdiak, sindikatuak, diruz lagundutako erakundeak; eta hitzarmena duten autonomia-erkidego eta -hiriak (Asturias, Kantabria, Gaztela-Mantxa, Extremadura, Errioxa, Ceuta eta Melilla; Madril 2020-2021ean) eta haien udal batzuk | Derrigorrezko Informazioa Betetzeko Indizea (ICIO, 0-100 %, MESTA metodologia) erakunde bakoitzeko Word txosten batean; datu-taularik gabe | Bai: EAOren ataria, 8 erkidego eta 11 udal |
| [Kanarietako Gardentasun Komisionatua](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Kanarietako sektore publiko osoa (Gobernua, kabildoak, udalak, unibertsitateak eta haien erakundeak) eta diruz lagundutako erakunde pribatuak | Kanarietako Gardentasun Indizea (ITCanarias, 0-10) Excel taula batean, erakunde guztiekin 2016tik (CC BY 4.0) | Bai: sektore publikoa |
| [Murtziako Eskualdeko Gardentasun Kontseilua](https://comisionadotransparencia.carm.es/) | Eskualdeko administrazioa, udalak eta haien sektore publikoa (egiaztatutako autoebaluazioa, MESTAn oinarritua) | PDF txosten exekutiboa, erakunde motaren araberako emaitza bateratuekin; udal bakoitzaren notak grafikoetan baino ez dira agertzen | Ez: ez dago erakundez erakundeko datu berrerabilgarririk |
| [Kataluniako Síndic de Greuges](https://www.sindic.cat/) | Kataluniako administrazioak (19/2014 Legea) | Urteko txostena eta banakako txostenak PDFan; publizitate aktiboaren garapen-indizea (IDPAC) proba-fasean 2024tik | Ez: erakunde bakoitzeko PDF txostenak, taularik gabe |
| Andaluzia, Aragoi, Gaztela eta Leon, Valentziako Erkidegoa, Galizia, Nafarroa, Euskadi eta beste batzuetako kontseiluak eta komisionatuak | Beren erkidegoa eta haren toki-erakundeak | Urteko memoriak, kontrol- eta ikuskapen-planak eta ebazpenak, PDFan; ez dugu aurkitu erakunde bakoitzeko argitaratutako betetze-indizerik | Ez |

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

<AreaMap
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

## Alderdika

Alderaketa **Kanarietako udalekin** baino ez da posible: 88 dira, guztiak ebaluatzen dira, metodo berarekin, 2016tik. Udal eta ebaluazio bakoitzerako nota **aurreikusgarria** kalkulatzen da: tamaina bereko Kanarietako udalen batez bestekoa (5.000 biztanletik behera, 5.000tik 20.000ra eta 20.000tik gora) ebaluazio berean. Ondoren, alderdi bakoitzak gobernatutakoen batez besteko nota haien nota aurreikusgarriarekin alderatzen da.

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

## Zer falta den

- **Ez dago Espainia osorako ebaluazio homogeneorik.** Kontrol-organo bakoitzak bere eremua ebaluatzen du bere metodoarekin: Kanarietako udal baten nota (ITCanarias) eta Kantabriako batena (CTBGren ICIO) ezin dira alderatu.
- **Autonomia-erkidegoetako organo gehienek ez dute erakunde bakoitzeko notarik argitaratzen datu irekietan.** Murtziak, Kataluniak, Andaluziak, Gaztela eta Leonek eta beste batzuek memoriak eta txostenak argitaratzen dituzte PDFan, batzuetan notak grafikoetan soilik. Horietakoren batek erakunde bakoitzeko emaitzak formatu berrerabilgarrian argitaratzen baditu, hona ekarriko dira.
- **Espainiako 8.100 udal baino gehiago ez dira sistematikoki ebaluatzen**, Kanarietan izan ezik. CTBGk 11 ebaluatu zituen 2020-2021ean.
- **Estatuko sektore publikoak** (erakundeak, enpresak eta fundazioak) badu erakunde bakoitzeko nota CTBGren txostenetan, baina banakako dokumentuetan. 2025ean CTBGk horietako 225 erakunde ebaluatu zituen, eta batez besteko ICIOa 38,9 % baino ez zen izan ([CTBGren oharra](https://consejodetransparencia.es/comunicacion/noticias/hemeroteca/2025/20251114)). Hori da hurrengo zabalkuntza bideragarria.
- Ebaluazioek neurtzen dute **informazioa argitaratuta dagoen eta nola**, ez ea egiazkoa edo edukiz osoa den.

---

## Metodologia eta iturriak

- **[Gardentasun eta Gobernu Oneko Kontseilua – Ebaluazioa](https://consejodetransparencia.es/evaluacion)**: [MESTA metodologiaren](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf) Derrigorrezko Informazioa Betetzeko Indizea (ICIO), **behin betiko txosten** bakoitzaren testutik irakurria (.docx): EAOren Gardentasun Ataria (2021-2025), hitzarmena duten autonomia-erkidego eta -hiriak (2020ko ebaluazioa eta 2021eko berrikuspena) eta haien ebaluatutako udalak. CTBGk zuzenean berrikusten du atari bakoitza, eta betebehar bakoitzerako puntuatzen du edukia argitaratzen den eta haren kalitate-atributuak (forma, eguneratzea, irisgarritasuna, berrerabilpena). Datuen jatorria: Gardentasun eta Gobernu Oneko Kontseilua (37/2007 Legearen araberako berrerabilpena).
- **[Kanarietako Gardentasun Komisionatua – Puntuazioak](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: Kanarietako Gardentasun Indizeko sektore publikoaren puntuazioen taula nagusia (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), 2016ko ebaluaziotik. Derrigorrezko informazioaren betetzea, web-euskarriaren kalitatea eta borondatezko gardentasuna konbinatzen ditu ([metodologia](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). Erakundeak galdetegi bat betetzen du, eta Komisionatuak egiaztatzen du. 100etik erakusten da (nota bider 10) ICIOaren ondoan marrazteko soilik; **bi eskalak ez dira baliokideak**.
- **Udalerriak**: Komisionatuaren izenak INEren kodearekin lotzen dira izenaren bidez (sei, forma desberdina dutenak, eskuz). Ebaluatutako urteko INEren erroldako biztanleria.
- **Alderdiei egoztea**: udaletan, ebaluatutako aldiaren amaieran kargudun zegoen alkatea, [Lurralde Politikako Ministerioaren alkateen erregistroaren](https://concejales.redsara.es/consulta/) arabera («2022/23» ebaluaziorako, 2023ko ekainaren 1a, maiatzeko hauteskundeetatik sortutako korporazioen aurretik); erkidegoetan eta Estatuan, ebaluatutako urteko abenduaren 31n (ITCanarias) edo ebaluazio-urteko ekainaren 30ean (CTBG) kargudun zegoen presidentea. Alderdiak familia politikotan biltzen dira.
- **Lege-betebeharrak**: [gardentasunari, informazio publikoa eskuratzeari eta gobernu onari buruzko 19/2013 Legearen](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) 5.etik 9.era bitarteko artikuluak; Kanarietan, [gardentasunari eta informazio publikoa eskuratzeari buruzko 12/2014 Legea](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Datuak eguneratuta" />
