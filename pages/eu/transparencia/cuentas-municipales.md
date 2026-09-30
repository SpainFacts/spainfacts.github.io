---
title: Gardentasuna
description: "Informazioa argitaratzeko edo bidaltzeko legezko betebeharrak betetzen ez dituzten administrazioak: zein diren, non dauden eta nork gobernatzen zuen epea amaitzean."
i18n_origen: f1f81e75efbb
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    // Urteei euskal atzizkia eransten die (2021eko, 2023ko, 2025eko...)
    const urte = (n, s) => (n == null || n === '' || Number.isNaN(n) ? '' : n + ([1, 5, 10, 15].includes(Number(n) % 20) ? 'e' : '') + s);
    // Datuetatik gaztelaniaz datozen datak euskaratzen ditu («mayo de 2024» → «2024ko maiatza»; «3º trimestre de 2024» → «2024ko 3. hiruhilekoa»)
    const HILAK = {enero: 'urtarrila', febrero: 'otsaila', marzo: 'martxoa', abril: 'apirila', mayo: 'maiatza', junio: 'ekaina', julio: 'uztaila', agosto: 'abuztua', septiembre: 'iraila', octubre: 'urria', noviembre: 'azaroa', diciembre: 'abendua'};
    const dataEu = (t) => {
        const s = String(t ?? '');
        let m = s.match(/^(\p{L}+) de (\d{4})$/u);
        if (m && HILAK[m[1].toLowerCase()]) return urte(m[2], 'ko') + ' ' + HILAK[m[1].toLowerCase()];
        m = s.match(/^(\d)º trimestre de (\d{4})$/);
        if (m) return urte(m[2], 'ko') + ' ' + m[1] + '. hiruhilekoa';
        return s;
    };
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

# 🔍 Gardentasuna: nork ez dituen kontuak ematen

Administrazio publikoak **legez behartuta** daude urtero informazio ekonomiko jakin bat bidaltzera. Orri honek, datu ofizialekin, jasotzen du zein administraziok ez duten hori egiten, non dauden eta **nork gobernatzen zuen epea amaitzean**.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Nola irakurri orri hau</p>
<p class="mb-1">Datu guztiak erregistro ofizialak eta egiaztagarriak dira. Administrazio bat hemen agertzeak esan nahi du <b>informazioa ez dagoela iturri ofizialean</b> argitalpen-datan: berandu bidali ahal izan du edo izapidetzen egon daiteke, eta komeni da iturria kontsultatzea kasu jakin bati buruzko ondoriorik atera aurretik.</p>
<p class="mb-0">Ez-betetzea <b>legezko epearen egunean jardunean zegoen gobernuari</b> egozten zaio, ez egungoari. Eta udalerri txikiek, baliabide gutxiagorekin, askoz gehiagotan ez dutenez betetzen, alderdien arteko alderaketak <b>biztanleria-tamainaren arabera doitzen dira</b>.</p>
</div>

## Udal-aurrekontuaren likidazioa

Udal bakoitzak Ogasun Ministerioari bidali behar dio bere aurrekontuaren likidazioa (benetan diru-sartu eta gastatu zuena) **hurrengo urteko martxoaren 31 baino lehen** (HAP/2105/2012 Aginduaren 15.3 art., Aurrekontu Egonkortasunari buruzko 2/2012 Lege Organikoa garatzen duena). Informazio hori gabe ezin da jakin diru publikoa zertan gastatzen den. (Araba eta Nafarroa adierazle honetatik kanpo geratzen dira beren foru-araubideagatik; ikus metodologia.)

<Grid cols=3>
    <KpiCard
        title="{urte(ultimo[0]?.anio, 'ko')} likidaziorik gabeko udalak"
        value={resumen[0]?.incumplen}
        formattedValue={formatNumber(resumen[0]?.incumplen, 0)}
        period="{formatNumber(resumen[0]?.incumplen / resumen[0]?.total / 0.01, 1)} % {formatNumber(resumen[0]?.total, 0)} udalen gainean"
        source="Ogasun Ministerioa (CONPREL)"
        sparklineData={liq_serie.map(d => d.incumplen)}
    />
    <KpiCard
        title="Kaltetutako bizilagunak"
        value={resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(resumen[0]?.afectados_por_1000, 1)}
        unit="1.000 biz. bakoitzeko"
        period="{formatNumber(resumen[0]?.poblacion_afectada, 0)} bizilagun guztira; 20.000 biztanletik gorako udalak: {formatNumber(resumen[0]?.grandes, 0)}"
        sparklineData={liq_serie.map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="Hiru urte edo gehiago jarraian"
        value={resumen_rachas[0]?.tres_o_mas}
        formattedValue={formatNumber(resumen_rachas[0]?.tres_o_mas, 0)}
        period="gutxienez hiru ekitalditan bidali ez duten udalak"
    />
</Grid>

### {urte(ultimo[0]?.anio, 'an')} bidali ez zutenak

```sql lista
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    coalesce(r.anios_seguidos, 0) AS anios_seguidos,
    t.alcalde_en_plazo,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/eu/territorios/municipios?m=' || t.cod_mun AS enlace
FROM (SELECT * FROM mother.transparencia_liquidaciones WHERE aplica_indicador) t
LEFT JOIN ${rachas} r USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.anio = (SELECT anio FROM ${ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=anios_seguidos title="Bidali gabeko urteak jarraian" contentType=colorscale colorMax=10 />
    <Column id=lista_en_plazo title="Alkatearen zerrenda epemugan" />
    <Column id=familia_en_plazo title="Familia politikoa" />
</DataTable>

<p class="text-xs text-gray-500">Biztanle gehienetik gutxienera ordenatuta. «Epemugan» = {urte(ultimo[0]?.anio + 1, 'ko')} martxoaren 31, {urte(ultimo[0]?.anio, 'ko')} likidazioa bidaltzeko azken eguna.</p>

### Lurraldearen arabera

```sql por_ccaa
SELECT
    c.nombre AS comunidad,
    '/eu' || c.ruta AS ruta,
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Mugak © Instituto Geográfico Nacional"
    title="{urte(ultimo[0]?.anio, 'ko')} likidazioa bidali ez zuten udalak, probintziaka"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: 'Ez zuten bidali', fmt: 'pct1'},
        {id: 'incumplen', title: 'Udalak', fmt: 'num0'},
        {id: 'municipios', title: 'Guztira', fmt: 'num0'}
    ]}
/>

<DataTable data={por_ccaa} rows=all link=ruta showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=incumplen title="Ez zuten bidali" fmt=num0 />
    <Column id=municipios title="Udalak" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Gobernuan dagoen alderdiaren arabera

{ultimo[0]?.anio - 11} eta {ultimo[0]?.anio} artean bidali gabeko likidazioak, alkateak epemugan zuen familia politikoaren arabera. **Ratio doituak** alderdi bakoitza alderatzen du **tamaina bereko, erkidego bereko eta urte bereko** udalerrietan espero litekeenarekin: 1 = esperotakoa; 2 = bikoitza; 0,5 = erdia. Konfiantza-tarteak 1 barne hartzen badu, aldea zoriaren ondorio izan daiteke.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>Datuek diotena:</b> udalerriaren tamaina eta autonomia-erkidegoa kontuan hartuta, alderdi gehienak 1etik oso gertu geratzen dira. Udal batek bere kontuak ez bidaltzea gehien azaltzen duena txikia izatea eta non dagoen da, nork gobernatzen duen baino gehiago.
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
    title="Ez-betetze doitua, tamainaren eta erkidegoaren arabera (1 = esperotakoa)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={por_familia} rows=all>
    <Column id=familia title="Alkatearen familia politikoa epemugan" />
    <Column id=ayuntamientos_anio title="Udalak × urtea" fmt=num0 />
    <Column id=incumplimientos title="Bidali gabeko likidazioak" fmt=num0 />
    <Column id=tasa title="Tasa gordina" fmt=pct1 />
    <Column id=ratio_tamano title="Tamainaren arabera soilik doitua" fmt=num2 />
    <Column id=ratio_ajustado title="Tamainaren eta erkidegoaren arabera doitua" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num2 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num2 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

<p class="text-xs text-gray-500">Gutxienez 300 udal-urte dituzten familiak soilik. «Sin detalle en la fuente» taldean erregistro ofizialean koalizio-etiketa generiko batekin agertzen den zerrenda duten alkatetzak biltzen dira; «Independientes y locales» taldean, hautesle-elkarteak. Familiek oso udalerri desberdinak gobernatzen dituzte (tamaina, erkidegoa, baliabideak): ratioak tamaina doitzen du, baina ez beste desberdintasunik.</p>

### Bilakaera

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
    title="Likidazioa bidali ez zuten udalak, tamainaren arabera"
/>

## Kontu Orokorra eta barne-kontrola (Kontuen Epaitegia)

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

**Kontu Orokorrak** udalaren kontu guztiak biltzen ditu (aurrekontua, balantzea, emaitzak, diruzaintza). Osoko Bilkurak onartu ondoren, **Kontuen Epaitegira** (edo erkidegoko kanpo-kontrolerako organora) bidali behar da **hurrengo urteko urriaren 15a baino lehen** ([Toki Ogasunak arautzen dituen Legearen testu bategina](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214), 212.5 eta 223.2 art.). Gainera, udal bakoitzak **apirilaren 30a baino lehen** bidali behar du **barne-kontrolari** buruzko informazioa (kontu-hartzailearen eragozpenen aurka hartutako erabakiak eta diru-sarreren anomalia nagusiak; lege bereko 218.3 art.) eta, **otsaila amaitu baino lehen**, **kontratuen urteko zerrenda** edo, kontraturik izan ez bada, ziurtagiri negatiboa (Sektore Publikoko Kontratuen Legearen 335. art.). Plataformak ez ditu barne hartzen Euskadi eta Nafarroa, beren kanpo-kontrolerako organoak baitituzte.

{#if tcu_cobertura[0]?.provincias < 40}

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-3 text-sm text-gray-700 dark:text-gray-300">
<b>Prestatzen.</b> Datuak pixkanaka deskargatzen ari dira Kontuen Epaitegiaren plataformatik, gainkargarik ez eragiteko, eta atal hau Espainia osoa hartzen duenean argitaratuko da (Euskadi eta Nafarroa izan ezik). Probintzia batzuekin bakarrik, zifrak ez lirateke adierazgarriak izango.
</div>

{:else}

{#if tcu_cobertura[0]?.parcial}
<div class="not-prose rounded-lg border border-amber-200 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-800 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
<b>Datu partzialak:</b> Kontuen Epaitegiaren plataformatiko deskarga pixkanaka egiten da, gainkargarik ez eragiteko. Oraingoz, atal honek <b>{tcu_cobertura[0]?.provincias} probintziatako datuak</b> jasotzen ditu ({formatNumber(tcu_cobertura[0]?.ayuntamientos, 0)} udal); zifrak ez dira oraindik Espainia osoaren adierazgarri.
</div>
{/if}

<Grid cols=3>
    <KpiCard
        title="{urte(tcu_ultimo[0]?.cg, 'ko')} Kontu Orokorrik gabe"
        value={tcu_resumen[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen[0]?.no_rendida / tcu_resumen[0]?.total / 0.01, 1)} % {formatNumber(tcu_resumen[0]?.total, 0)} udalen gainean; ez dago emandakotzat jasota {tcu_cobertura[0]?.extraccion} datan"
        source="Kontuen Epaitegia (rendiciondecuentas.es)"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'cuenta_general').map(d => d.no_rendida)}
    />
    <KpiCard
        title="Epe barruan bidalia"
        value={tcu_resumen[0]?.en_plazo}
        formattedValue="{formatNumber(tcu_resumen[0]?.en_plazo / tcu_resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(tcu_resumen[0]?.en_plazo, 0)} udal 15/10/{tcu_ultimo[0]?.cg + 1} baino lehen; beranduago bidali zutenak: {formatNumber(tcu_resumen[0]?.fuera_plazo, 0)}"
    />
    <KpiCard
        title="{urte(tcu_ultimo[0]?.ci, 'ko')} barne-kontrolik gabe"
        value={tcu_resumen_ci[0]?.no_rendida}
        formattedValue={formatNumber(tcu_resumen_ci[0]?.no_rendida, 0)}
        period="{formatNumber(tcu_resumen_ci[0]?.no_rendida / tcu_resumen_ci[0]?.total / 0.01, 1)} % {formatNumber(tcu_resumen_ci[0]?.total, 0)} udalen gainean (epea: 30/04/{tcu_ultimo[0]?.ci + 1})"
        sparklineData={tcu_serie.filter(d => d.obligacion === 'control_interno').map(d => d.no_rendida)}
    />
</Grid>

### {urte(tcu_ultimo[0]?.cg, 'ko')} Kontu Orokorra eman ez dutenak

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
    '/eu/territorios/municipios?m=' || t.cod_mun AS enlace
FROM cg t
JOIN historial h USING (cod_mun)
LEFT JOIN ci USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.ejercicio = (SELECT cg FROM ${tcu_ultimo}) AND t.incumple
ORDER BY t.poblacion DESC
```

<DataTable data={tcu_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=ejercicios_sin_rendir title="Kontu Orokorrik gabeko ekitaldiak" />
    <Column id=control_interno title="Barne-kontrola {tcu_ultimo[0]?.ci}" />
    <Column id=lista_en_plazo title="Alkatearen zerrenda epemugan" />
    <Column id=familia_en_plazo title="Familia politikoa" />
</DataTable>

<p class="text-xs text-gray-500">Biztanle gehienetik gutxienera ordenatuta. «No consta» = plataformak ez du emandakotzat erakusten erauzketa-datan ({tcu_cobertura[0]?.extraccion}); geroago bidali ahal izan da edo izapidetzen egon daiteke. «Epemugan» = {urte(tcu_ultimo[0]?.cg + 1, 'ko')} urriaren 15a. Ekitaldien zutabeak epea igarota duten urte eskuragarri guztiak hartzen ditu.</p>

### Autonomia-erkidegoaren arabera

```sql tcu_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/eu' || c.ruta AS ruta,
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
    <Column id=comunidad title="Erkidegoa" />
    <Column id=ayuntamientos title="Udalak" fmt=num0 />
    <Column id=pct_cg title="{urte(tcu_ultimo[0]?.cg, 'ko')} Kontu Orokorrik gabe" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_cg_en_plazo title="Kontu Orokorra epe barruan" fmt=pct1 />
    <Column id=pct_ci title="{urte(tcu_ultimo[0]?.ci, 'ko')} barne-kontrolik gabe" fmt=pct1 />
    <Column id=pct_ct title="{urte(tcu_ultimo[0]?.ct, 'ko')} kontratu-zerrendarik gabe" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Kontratuen zerrenda: «gabe» esan nahi du ez dagoela jasota ez zerrenda, ez kontraturik egin ez delako ziurtagiri negatiboa.</p>

### Gobernuan dagoen alderdiaren arabera

Eman gabeko Kontu Orokorrak ekitaldi eskuragarri guztietan, alkateak hurrengo urteko urriaren 15ean zuen familia politikoaren arabera. **Ratio doituak** alderdi bakoitza alderatzen du **tamaina bereko, erkidego bereko eta ekitaldi bereko** udalerrietan espero litekeenarekin (1 = esperotakoa). Konfiantza-tarteak 1 barne hartzen badu, aldea zoriaren ondorio izan daiteke.

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
    title="Eman gabeko Kontu Orokorra, tamainaren eta erkidegoaren arabera doitua (1 = esperotakoa)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={tcu_por_familia} rows=all>
    <Column id=familia title="Alkatearen familia politikoa epemugan" />
    <Column id=ayuntamientos_anio title="Udalak × ekitaldia" fmt=num0 />
    <Column id=incumplimientos title="Eman gabeko kontuak" fmt=num0 />
    <Column id=tasa title="Tasa gordina" fmt=pct1 />
    <Column id=ratio_tamano title="Tamainaren arabera soilik doitua" fmt=num2 />
    <Column id=ratio_ajustado title="Tamainaren eta erkidegoaren arabera doitua" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num2 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num2 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

<p class="text-xs text-gray-500">Gutxienez 300 udal-ekitaldi dituzten familiak soilik. Ratioak tamaina eta erkidegoa doitzen ditu, baina ez familia bakoitzak gobernatzen dituen udalerrien arteko beste desberdintasunik.</p>

{:else}

<p class="text-sm text-gray-500">Oraindik ez dago datu nahikorik (gutxienez 300 udal-ekitaldi familia politiko bakoitzeko) alderdiak berme osoz alderatzeko.</p>

{/if}

{/if}

---

## Estatuaren funtsen atxikipena, informazioa ez bidaltzeagatik

Udal batek Ogasunari **bere aurrekontuaren likidazioa** bidaltzen ez dionean, Ministerioak **Estatuaren zergetako partaidetzaren hileko entregak atxikitzen dizkio** (Estatutik jasotzen duen transferentzia nagusia) bidali arte (Ekonomia Iraunkorrari buruzko 2/2011 Legearen 36. art.). 2022tik, gauza bera gertatzen da **urteko aurrekontua** uztailaren 1a baino lehen edo **hurrengo urteko aurrekontuaren oinarrizko ildoak** irailaren 15a baino lehen bidaltzen ez baditu (22/2021 Legearen 87. xedapen gehigarria). Ogasunak hilero argitaratzen du atxikitako udalen zerrenda; hemen, 2016ko urritik aurrerako guztiak biltzen dira. (Ez dago Euskadiko ez Nafarroako udalik: beren foru-araubideagatik ez dute partaidetza hori bide arruntetik jasotzen.)

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
        title="Atxikitako udalak: {dataEu(pie_ultimo[0]?.mes)}"
        value={pie_resumen[0]?.retenidos_mes}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_mes, 0)}
        period="horietatik {formatNumber(pie_resumen[0]?.retenidos_liquidacion, 0)} likidazioa ez bidaltzeagatik"
        source="Ogasun Ministerioa (OVEELL)"
        sparklineData={pie_serie_12m.map(d => d.retenidos_mes)}
    />
    <KpiCard
        title="Azken 12 hilabeteetan atxikitakoa"
        value={pie_resumen[0]?.eur_12m_real}
        formattedValue={formatNumber(pie_resumen[0]?.eur_12m_real / 1e6, 1)}
        unit="M€ ({urte(base_deflactor[0]?.anio_base, 'ko')} eurotan)"
        period="ez-betetzeak iraun bitartean transferitu gabeko Estatuaren zergetako partaidetza ({formatNumber(pie_resumen[0]?.eur_12m / 1e6, 1)} M€ korronte)"
        source="Hileko konturako entregak"
        sparklineData={pie_serie_12m.filter(d => d.eur_12m_real != null).map(d => d.eur_12m_real)}
    />
    <KpiCard
        title="Azken urtean atxikitako udalak"
        value={pie_resumen[0]?.retenidos_12m}
        formattedValue={formatNumber(pie_resumen[0]?.retenidos_12m, 0)}
        period="gutxienez hilabete batez azken 12etan"
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
    title="Partaidetza atxikita izan duten udalak hilero, arrazoiaren arabera"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<BarChart
    data={pie_serie}
    x=periodo
    y=importe_real
    series=motivo
    type=stacked
    yFmt=eur1m
    title="Hilero atxikitako euroak ({urte(base_deflactor[0]?.anio_base, 'ko')} eurotan, inflazioa kenduta)"
    colorPalette={['#9a3412', '#f59e0b', '#fcd34d']}
/>

<p class="text-xs text-gray-500">Hileko zerrenda bakoitza argazki bat da: hilabete horretan nork jarraitzen duen atxikita. Likidazioaren zerrenda ekaina aldera berritzen da (bi urte lehenagoko likidazioarekin) eta udalek bidali ahala husten da; aurrekontuarena azaroan eta abenduan agertzen da, eta oinarrizko ildoena abendutik abuztura. Ez dago zenbatekorik Ogasunak konturako entregen Excela argitaratu ez zuen hilabeteetan (2019ko martxoa eta urria, 2020ko azarotik 2021eko urtarrilera eta 2022ko otsaila). Webgunearen gainerakoan bezala, zenbatekoak inflazioa kenduta adierazten dira, {urte(base_deflactor[0]?.anio_base, 'ko')} eurotan (INEren urteko batez besteko KPIa; aurtengo urtean, argitaratutako hilabeteen batez bestekoarekin).</p>

### Atxikitakoak: {dataEu(pie_ultimo[0]?.mes)}

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
    '/eu/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pie t
LEFT JOIN ${pie_importe_real} ir ON ir.cod_mun = t.cod_mun AND ir.seccion = t.seccion AND ir.anio = CAST(t.anio AS INTEGER)
LEFT JOIN ${pie_rachas} r ON r.cod_mun = t.cod_mun
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.sigue_retenido
GROUP BY t.cod_mun, t.municipio, p.nombre, t.poblacion, r.meses_seguidos, r.desde
ORDER BY t.poblacion DESC
```

<DataTable data={pie_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=motivo title="Informazio falta (ekitaldia)" />
    <Column id=meses_seguidos title="Atxikita jarraian daramatzan hilabeteak" contentType=colorscale colorMax=24 />
    <Column id=importe_real title="Kanpaina honetan atxikita ({urte(base_deflactor[0]?.anio_base, 'ko')} €)" fmt=eur0 />
    <Column id=lista title="Alkatearen zerrenda atxikipena hastean" />
    <Column id=familia title="Familia politikoa" />
</DataTable>

<p class="text-xs text-gray-500">Biztanle gehienetik gutxienera ordenatuta. «Kanpaina honetan atxikita»: informazio horregatik atxikipena hasi zenetik transferitu gabeko euroak (beste batekin bat egiten badu, hileko zenbatekoa bien artean banatzen da), hilez hil inflazioa kenduta. Batzuk atxikita daude Ogasunak ez duelako jaso udalaren mendeko erakunde edo sozietate baten informazioa, ez udalarena bera.</p>

### Autonomia-erkidegoaren arabera

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
    '/eu' || c.ruta AS ruta,
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
    <Column id=comunidad title="Erkidegoa" />
    <Column id=retenidos title="Atxikitakoak: {dataEu(pie_ultimo[0]?.mes)}" fmt=num0 />
    <Column id=municipios title="Udalak" fmt=num0 />
    <Column id=pct title="%" fmt=pct1 contentType=bar barColor="#fdba74" />
</DataTable>

### Gobernuan dagoen alderdiaren arabera

Atxikipen-kanpaina bakoitza (informazio mota eta ekitaldi bakoitzeko bat) behaketa bat da udal bakoitzeko: atxikita edo ez. Familia politikoa alkatearena da **atxikipena hastean** (edo, atxiki ez bazuten, kanpaina hori hastean). Likidazioan bezala, **ratio doituak** familia bakoitza alderatzen du tamaina bereko, erkidego bereko eta kanpaina bereko udalerrietan espero litekeenarekin.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>Datuek diotena:</b> tamaina eta erkidegoa doitu ondoren, udal gehienak gobernatzen dituzten bi alderdiak ia 1ean geratzen dira, eta familia bat ere ez dago argi eta garbi esperotakoaren gainetik. Batzuk azpitik geratzen dira, batez ere erkidego bakarrean ezarrita dauden alderdiak; udal gutxirekin, tarteak zabalak dira. Askoz gehiago eragiten du tamainak: 1.000 biztanletik beherako udalerrietan atxikipena bost aldiz inguru ohikoagoa da 100.000tik gorakoetan baino.
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
    title="Atxikipen doituak, tamainaren eta erkidegoaren arabera (1 = esperotakoa)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pie_por_familia} rows=all>
    <Column id=familia title="Alkatearen familia politikoa" />
    <Column id=observaciones title="Udalak × kanpaina" fmt=num0 />
    <Column id=retenciones title="Atxikipenak" fmt=num0 />
    <Column id=tasa title="Tasa gordina" fmt=pct1 />
    <Column id=ratio_tamano title="Tamainaren arabera soilik doitua" fmt=num2 />
    <Column id=ratio_ajustado title="Tamainaren eta erkidegoaren arabera doitua" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num2 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num2 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

<p class="text-xs text-gray-500">2017tik aurrerako kanpaina osoak (2015etik 2024ra arteko likidazioak, 2022tik 2025era arteko aurrekontuak eta 2023tik 2026ra arteko oinarrizko ildoak). Gutxienez 300 udal × kanpaina dituzten familiak soilik. Likidazioaren atxikipena hura bidaltzeko epea amaitu eta bi urte inguru geroago hasten da; beraz, atxikipena hastean dagoen alkatea ez da zertan izan hura bidali behar zuena (batez ere 2019ko eta 2023ko maiatzeko udal-hauteskundeen ondoren).</p>

---

## Hornitzaileei ordaintzeko batez besteko epea

Udal guztiek **hornitzaileei ordaintzeko batez besteko epea (PMP) kalkulatu eta hiruhilero Ogasunari jakinarazi** behar diote (batez beste zenbat egun behar dituzten fakturak ordaintzeko), hurrengo hilabetearen azken eguna baino lehen (635/2014 Errege Dekretua eta HAP/2105/2012 Aginduaren 16.8 art.). Ogasunak jakinarazten dutenen datuak argitaratzen ditu; agertzen ez dena ez da jakinarazi. Ordaintzeko legezko gehienezko epea **30 egun** da (2/2012 Lege Organikoaren 13.6 art.). Nafarroa eta, urteen arabera, Euskadiko foru-lurraldeak jakinarazpen-adierazletik kanpo geratzen dira: haien finantza-tutoretza forala da eta haien udal gehienak ez dira argitalpenean agertzen.

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
        title="PMPa jakinarazi gabe ({pmp_ultimo[0]?.periodo})"
        value={pmp_resumen[0]?.no_comunican}
        formattedValue={formatNumber(pmp_resumen[0]?.no_comunican, 0)}
        period="{formatNumber(pmp_resumen[0]?.no_comunican / pmp_resumen[0]?.total / 0.01, 1)} % {formatNumber(pmp_resumen[0]?.total, 0)} udalen gainean"
        source="Ogasun Ministerioa (PMP_NET)"
        sparklineData={pmp_serie.map(d => d.no_comunican)}
    />
    <KpiCard
        title="Kaltetutako bizilagunak"
        value={pmp_resumen[0]?.afectados_por_1000}
        formattedValue={formatNumber(pmp_resumen[0]?.afectados_por_1000, 1)}
        unit="1.000 biz. bakoitzeko"
        period="{formatNumber(pmp_resumen[0]?.poblacion_afectada, 0)} bizilagun guztira; 5.000 biztanletik gorako udalak: {formatNumber(pmp_resumen[0]?.mas_5000, 0)}"
        sparklineData={pmp_serie.filter(d => d.afectados_por_1000 != null).map(d => d.afectados_por_1000)}
    />
    <KpiCard
        title="30 egun baino gehiagoan ordaintzen dute"
        value={pmp_resumen[0]?.supera_30}
        formattedValue={formatNumber(pmp_resumen[0]?.supera_30, 0)}
        period="{formatNumber(pmp_resumen[0]?.supera_30 / pmp_resumen[0]?.comunican / 0.01, 1)} % jakinarazten dutenen artean ({formatNumber(pmp_resumen[0]?.poblacion_supera_30, 0)} biz.)"
        sparklineData={pmp_serie.map(d => d.supera_30)}
    />
</Grid>

### {dataEu(pmp_ultimo[0]?.etiqueta)}: jakinarazi ez zutenak

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
    '/eu/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
JOIN historial h USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.aplica_indicador AND NOT t.reporta
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_lista} search=true rows=20 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=trimestres_sin title="Jakinarazi gabeko hiruhilekoak (azken 12etatik)" contentType=colorscale colorMax=12 />
    <Column id=lista_en_plazo title="Alkatearen zerrenda epemugan" />
    <Column id=familia_en_plazo title="Familia politikoa" />
</DataTable>

<p class="text-xs text-gray-500">Biztanle gehienetik gutxienera ordenatuta. «Epemugan» = hiruhilekoaren hurrengo hilabetearen azken eguna. Berandu jakinarazi zuen udal bat ez da agertuko, agian, hiruhileko horretako argitalpenean.</p>

### Autonomia-erkidegoaren arabera

```sql pmp_por_ccaa
SELECT
    c.nombre AS comunidad,
    '/eu' || c.ruta AS ruta,
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
    <Column id=comunidad title="Erkidegoa" />
    <Column id=no_comunican title="Ez zuten jakinarazi" fmt=num0 />
    <Column id=municipios title="Udalak" fmt=num0 />
    <Column id=pct title="Jakinarazi gabeen %" fmt=pct1 contentType=bar barColor="#fdba74" />
    <Column id=pct_supera_30 title="Jakinarazten dutenetatik 30 egun baino gehiagoan ordaintzen dutenen %" fmt=pct1 />
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
    title="PMPa jakinarazi gabeko udalak eta 30 egunetik gorako PMPa dutenak, hiruhilekoka"
/>

### Gobernuan dagoen alderdiaren arabera

Azken hiru urteetan PMPa jakinarazi gabeko hiruhilekoak, alkateak epemugan zuen familia politikoaren arabera, **tamaina bereko, erkidego bereko eta hiruhileko bereko** udalerrietan espero litekeenarekin alderatuta. Udal txiki askok hiruhilekoz hiruhileko jakinarazteari uzten diote; beraz, behaketak ez dira independenteak eta benetako tartea erakutsitakoa baino zertxobait zabalagoa da.

<div class="not-prose rounded-lg border border-blue-200 bg-blue-50 dark:bg-blue-950/40 dark:border-blue-800 p-3 my-3 text-sm text-blue-900 dark:text-blue-200">
<b>Datuek diotena:</b> alkatetza gehien dituzten bi alderdiak 1 inguruan geratzen dira doikuntzaren ondoren. Desbideratze handienak, gainetik zein azpitik, erkidego bakarrean ezarrita dauden alderdienak dira; han, erkidegoaren eta tamainaren araberako doikuntzak okerrago jasotzen ditu udalerrien arteko desberdintasunak. Tamainak askoz gehiago eragiten du: 1.000 biztanletik beherako udalen ia hamarretik hiruk ez dute jakinarazten, eta 50.000tik gorakoetan ia batek ere ez.
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
    title="Jakinarazi gabeko PMPa, tamainaren eta erkidegoaren arabera doitua (1 = esperotakoa)"
    fillColor="#9a3412"
    sort=false
/>

<DataTable data={pmp_por_familia} rows=all>
    <Column id=familia title="Alkatearen familia politikoa epemugan" />
    <Column id=observaciones title="Udalak × hiruhilekoa" fmt=num0 />
    <Column id=incumplimientos title="Jakinarazi gabeko hiruhilekoak" fmt=num0 />
    <Column id=tasa title="Tasa gordina" fmt=pct1 />
    <Column id=ratio_tamano title="Tamainaren arabera soilik doitua" fmt=num2 />
    <Column id=ratio_ajustado title="Tamainaren eta erkidegoaren arabera doitua" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num2 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num2 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

### 30 egun baino gehiagoan ordaintzea

PMPa jakinarazten duten udalen artean, hauek dira {dataEu(pmp_ultimo[0]?.etiqueta)} aldian ordaintzeko batez besteko epe bat **30 eguneko legezko gehienezkoaren gainetik** adierazi zutenak. Udalak berak kalkulatu eta sinatzen duen datua da.

```sql pmp_mayor30
SELECT
    t.municipio,
    p.nombre AS provincia,
    t.poblacion,
    t.pmp_dias,
    t.lista_en_plazo,
    t.familia_en_plazo,
    '/eu/territorios/municipios?m=' || t.cod_mun AS enlace
FROM mother.transparencia_pmp t
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = t.cod_prov
WHERE t.fecha_trimestre = (SELECT fecha FROM ${pmp_ultimo}) AND t.supera_30
ORDER BY t.poblacion DESC
```

<DataTable data={pmp_mayor30} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=pmp_dias title="PMP (egunak)" fmt=num1 contentType=colorscale colorMin=30 colorMax=180 />
    <Column id=lista_en_plazo title="Alkatearen zerrenda epemugan" />
    <Column id=familia_en_plazo title="Familia politikoa" />
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
    <Column id=familia title="Alkatearen familia politikoa epemugan" />
    <Column id=observaciones title="Jakinarazten duten udalak × hiruhilekoa" fmt=num0 />
    <Column id=por_encima title="30 egunetik gorako PMPa duten hiruhilekoak" fmt=num0 />
    <Column id=tasa title="Tasa gordina" fmt=pct1 />
    <Column id=ratio_ajustado title="Tamainaren eta erkidegoaren arabera doitua" fmt=num2 contentType=colorscale colorMid=1 />
    <Column id=ic_bajo title="KT 95 % (min.)" fmt=num2 />
    <Column id=ic_alto title="KT 95 % (max.)" fmt=num2 />
    <Column id=lectura title="Irakurketa" />
</DataTable>

<p class="text-xs text-gray-500">Argitaratutako azken 12 hiruhilekoak. Gutxienez 300 udal × hiruhileko dituzten familiak soilik. PMPa jakinarazten ez duena ez da kalkulu honetan sartzen; beraz, ez da jakiten epe barruan ordaintzen duen.</p>

---

## Metodologia eta iturriak

- **[Ogasun Ministerioa – CONPREL](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: erakunde bakoitzaren «N» informazio-egoera (daturik gabe) likidazioen behin betiko argitalpenean. 2013tik; lehenago, Ogasunak udalerri txiki askoren datuak egozten zituen. Ez dira behin-behineko aurrerapenak erabiltzen, berandu bidaltzen duena oraindik ez delako haietan agertzen.
- **[Lurralde Politikako Ministerioa – Alkateak eta zinegotziak](https://concejales.redsara.es/consulta/)**: epemugan jardunean zegoen alkatea eta hautatua izan zeneko zerrenda, familia politikotan bilduta.
- **Legezko betebeharra**: [HAP/2105/2012 Aginduaren](https://www.boe.es/buscar/act.php?id=BOE-A-2012-12147) 15.3 art., [2/2012 Lege Organikoaren](https://www.boe.es/buscar/act.php?id=BOE-A-2012-5730) 6. art. garatuz.
- **Foru-lurraldeak**: Araban eta Nafarroan, udal-likidazioa ez da CONPRELera bide arruntetik bideratzen (Foru Aldundiaren eta Nafarroako Gobernuaren finantza-tutoretza), ezta Bizkaian eta Gipuzkoan ere 2013-2014an. Kasu horiek **ez dira ez-betetzetzat zenbatzen**: ia % 100ean agertuko lirateke, foru-araubidearen ondorioz, ez udal bakoitzaren jokabideagatik.
- **[Kontuen Epaitegia – Toki Erakundeen Kontuak Emateko Plataforma](https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/)** (Kontuen Epaitegia eta autonomia-erkidegoetako kanpo-kontrolerako organoak): udal bakoitzaren egoera Kontu Orokorraren, barne-kontrolaren eta kontratuen kontsultetan, eta emandako Kontu Orokor bakoitzaren bidalketa-data. Plataformak ez du deskarga masiborik eskaintzen: haren orriak etenaldiekin kontsultatzen dira eta egoerak eta datak baino ez dira gordetzen, erauzketa-datarekin. Erakunde bakoitza bere INE kodearekin lotzen da Ogasuneko kodeetatik (MEH) eta Direktorio Komunetik (DIR3) abiatuta, eta, horiek falta badira, izenaren eta probintziaren arabera.
- **Epeak**: Kontu Orokorra, hurrengo urteko urriaren 15a ([TRLRHL](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214), 212.5 eta 223.2 art.); barne-kontrola, apirilaren 30a (TRLRHLaren 218.3 art. eta [Kontuen Epaitegiaren 2019ko Jarraibidea](https://www.boe.es/buscar/doc.php?id=BOE-A-2020-680)); kontratuen zerrenda, otsailaren amaiera ([LCSP](https://www.boe.es/buscar/act.php?id=BOE-A-2017-12902), 335. art., eta [2018ko Jarraibidea](https://www.boe.es/buscar/doc.php?id=BOE-A-2018-9585)). Epea igarota duten ekitaldiak soilik zenbatzen dira.
- «Epe barruan» plataformak erakusten duen bidalketa-datarekin neurtzen da; kontu bat emandakotzat jasota badago baina haren data ezezaguna bada, ez da epe barrukotzat ez epez kanpokotzat sailkatzen.
- **[Ogasun Ministerioa – Toki Erakundeen Bulego Birtuala](https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx)**: Estatuaren zergetako partaidetza atxikita duten udalen hileko zerrenda (PDFan), 2016ko urritik, eta konturako entregen hileko Excela, bakoitzari atxikitako zenbatekoarekin. 2022ko urrira arte, zerrendek izena baino ez dakarte: INE kodearekin izenaren eta probintziaren arabera lotzen dira (guztiak lotzen dira; hiru, izenean akats bat dutenak, hurbilketaz). Zerrenda zahar horietan likidazioaren ekitaldia ez da adierazten, eta kanpainatik ondorioztatzen da (A urteko ekainekoa A-2ren likidazioari dagokio, ondorengo zerrendetan bezala). PDFetako eta Excel-etako zenbatekoak ia hilez hil bat datoz udaletan.
- **Funtsen atxikipena**: [Ekonomia Iraunkorrari buruzko 2/2011 Legearen](https://www.boe.es/buscar/act.php?id=BOE-A-2011-4117) 36. art. (likidazioa, [TRLRHLaren](https://www.boe.es/buscar/act.php?id=BOE-A-2004-4214) 193.5 art.arekin lotuta) eta [2022rako Aurrekontuei buruzko 22/2021 Legearen](https://www.boe.es/buscar/act.php?id=BOE-A-2021-21653) 87. xedapen gehigarria (aurrekontua eta oinarrizko ildoak). Hileko zerrenda bakoitza nork atxikita jarraitzen duenaren argazkia da, ez hilabete horretan nork ez zuen bete. Foru-lurraldeak ez dira agertzen, partaidetza ez dutelako bide arruntetik jasotzen.
- **[Ogasun Ministerioa – PMP_NET](https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/)**: toki-erakunde bakoitzaren ordaintzeko batez besteko epea hiruhilekoka, 2014ko hirugarrenetik. «Ez du jakinarazten» = udala urte horretan badago (INEren errolda) baina ez da hiruhilekoaren argitalpenean agertzen. Betebeharra: [635/2014 Errege Dekretua](https://www.boe.es/buscar/act.php?id=BOE-A-2014-8121) ([1040/2017 ED](https://www.boe.es/buscar/doc.php?id=BOE-A-2017-15492)-k aldatua) eta HAP/2105/2012 Aginduaren 16.8 art.; gehienez 30 egun, 2/2012 LOren 13.6 art. 30 eguneko muga 2018ko bigarren hiruhilekotik aurrera baino ez da aplikatzen, 1040/2017 EDk kalkulua aldatu zuenean (lehen, adostasuneko 30 egunak kentzen zituen eta negatiboa izan zitekeen). Nafarroan (urte guztietan), Araban (2022ra arte) eta Bizkaian eta Gipuzkoan (2016ko bigarren hiruhilekora arte) udal gehienak ez dira argitalpenean agertzen, foru-bidea dela eta: kasu horiek ez dira ez-betetzetzat zenbatzen.
- Udalak soilik hartzen dira kontuan; diputazioek, mankomunitateek eta toki-erakunde txikiek beren betebeharrak dituzte, eta ez dira hemen sartzen.

<LastRefreshed prefix="Datuak eguneratuta" />
