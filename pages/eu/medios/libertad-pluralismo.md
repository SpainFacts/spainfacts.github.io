---
title: Prentsa-askatasuna eta aniztasuna
description: "Non dagoen Espainia prentsa-askatasunaren eta komunikabideen aniztasunaren nazioarteko indizeetan (Mugarik Gabeko Kazetariak, Media Pluralism Monitor, V-Dem eta Europako Kontseiluaren plataforma) eta nola aldatu den EBren eta erreferentziazko herrialdeen aldean."
i18n_origen: 70c909289afe
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql esp
-- Último dato de España en cada índice, con el anterior
WITH e AS (
    SELECT *,
        lag(valor) OVER (PARTITION BY indice_id ORDER BY anio) AS valor_anterior,
        lag(anio) OVER (PARTITION BY indice_id ORDER BY anio) AS anio_anterior,
        row_number() OVER (PARTITION BY indice_id ORDER BY anio DESC) AS rn
    FROM mother.medios_libertad_espana
)
SELECT indice_id, nombre, unidad, sentido, CAST(anio AS INTEGER) AS anio, valor,
    valor_anterior, CAST(anio_anterior AS INTEGER) AS anio_anterior, valor - valor_anterior AS cambio,
    CAST(n_total AS INTEGER) AS n_total, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue, valor_ue
FROM e
WHERE rn = 1
```

```sql k_rsf
SELECT * FROM ${esp} WHERE indice_id = 'rsf_puesto'
```

```sql k_mpm
SELECT * FROM ${esp} WHERE indice_id = 'mpm_total'
```

```sql k_vdem
SELECT * FROM ${esp} WHERE indice_id = 'vdem_libertad_expresion'
```

```sql k_coe
SELECT * FROM ${esp} WHERE indice_id = 'coe_alertas'
```

```sql serie_esp
SELECT indice_id, CAST(anio AS INTEGER) AS anio, valor, valor_ue, CAST(puesto_ue AS INTEGER) AS puesto_ue
FROM mother.medios_libertad_espana
ORDER BY indice_id, anio
```

```sql rsf_esp
SELECT CAST(edicion AS INTEGER) AS edicion, etiqueta_edicion, escala, puntuacion,
    CAST(puesto_mundial AS INTEGER) AS puesto_mundial, CAST(n_paises AS INTEGER) AS n_paises,
    CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.medios_libertad_rsf
WHERE cod_pais = 'ES' AND indicador = 'global'
ORDER BY edicion
```

```sql rsf_extremos
SELECT
    (SELECT CAST(edicion AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial, edicion DESC LIMIT 1) AS mejor_edicion,
    (SELECT CAST(puesto_mundial AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial LIMIT 1) AS mejor_puesto,
    (SELECT CAST(edicion AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial DESC, edicion DESC LIMIT 1) AS peor_edicion,
    (SELECT CAST(puesto_mundial AS INTEGER) FROM ${rsf_esp} ORDER BY puesto_mundial DESC LIMIT 1) AS peor_puesto,
    (SELECT CAST(edicion AS INTEGER) FROM ${rsf_esp} ORDER BY edicion LIMIT 1) AS primera_edicion,
    (SELECT CAST(puesto_mundial AS INTEGER) FROM ${rsf_esp} ORDER BY edicion LIMIT 1) AS primer_puesto,
    (SELECT CAST(n_paises AS INTEGER) FROM ${rsf_esp} ORDER BY edicion LIMIT 1) AS primer_n
```

```sql rsf_ref
-- Puesto mundial de los países de referencia en cada edición
SELECT pais, CAST(edicion AS INTEGER) AS edicion, CAST(puesto_mundial AS INTEGER) AS puesto_mundial
FROM mother.medios_libertad_rsf
WHERE indicador = 'global' AND es_referencia AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'NL')
ORDER BY orden_pais, edicion
```

```sql rsf_ue_ult
-- Puntuación de los países de la UE en la última edición
SELECT pais, puntuacion, CAST(puesto_mundial AS INTEGER) AS puesto_mundial, CAST(puesto_ue AS INTEGER) AS puesto_ue,
    CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.medios_libertad_rsf
WHERE indicador = 'global' AND es_ue AND edicion = (SELECT max(edicion) FROM mother.medios_libertad_rsf)
ORDER BY puntuacion DESC
```

```sql rsf_ind
-- Indicadores de RSF de España desde 2022
SELECT nombre_indicador AS indicador, CAST(edicion AS INTEGER) AS edicion, puntuacion,
    CAST(puesto_mundial AS INTEGER) AS puesto_mundial, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.medios_libertad_rsf
WHERE cod_pais = 'ES' AND indicador <> 'global' AND escala = '2022'
ORDER BY orden_indicador, edicion
```

```sql rsf_ind_ult
SELECT * FROM ${rsf_ind} WHERE edicion = (SELECT max(edicion) FROM ${rsf_ind}) ORDER BY puesto_mundial
```

```sql rsf_ind_tabla
-- Última edición: indicadores de los países de referencia
SELECT pais, min(orden_pais) AS orden,
    max(CASE WHEN indicador = 'global' THEN puntuacion END) AS global,
    max(CASE WHEN indicador = 'global' THEN puesto_mundial END) AS puesto,
    max(CASE WHEN indicador = 'politico' THEN puntuacion END) AS politico,
    max(CASE WHEN indicador = 'economico' THEN puntuacion END) AS economico,
    max(CASE WHEN indicador = 'legislativo' THEN puntuacion END) AS legislativo,
    max(CASE WHEN indicador = 'social' THEN puntuacion END) AS social,
    max(CASE WHEN indicador = 'seguridad' THEN puntuacion END) AS seguridad
FROM mother.medios_libertad_rsf
WHERE es_referencia AND edicion = (SELECT max(edicion) FROM mother.medios_libertad_rsf)
GROUP BY pais
ORDER BY orden, pais
```

```sql gobiernos
SELECT
    CAST(year(CAST(desde AS DATE)) AS INTEGER) AS anio_desde,
    CAST(coalesce(year(CAST(hasta AS DATE)), year(current_date)) AS INTEGER) AS anio_hasta,
    presidente, familia
FROM mother.gobiernos_presidentes
WHERE nivel = 'estatal' AND coalesce(year(CAST(hasta AS DATE)), 9999) >= 2002
ORDER BY anio_desde
```

```sql gob_psoe
SELECT * FROM ${gobiernos} WHERE familia = 'PSOE'
```

```sql gob_pp
SELECT * FROM ${gobiernos} WHERE familia = 'PP'
```

```sql rsf_gobiernos
-- Puesto de España en cada edición y quién gobernaba el 1 de julio del año anterior,
-- el periodo que valora cada edición (descriptivo, sin atribuir causalidad)
SELECT CAST(r.edicion AS INTEGER) AS edicion, CAST(r.puesto_mundial AS INTEGER) AS puesto_mundial,
    CAST(r.puesto_ue AS INTEGER) AS puesto_ue, g.presidente, g.familia
FROM mother.medios_libertad_rsf r
LEFT JOIN mother.gobiernos_presidentes g
    ON g.nivel = 'estatal'
    AND make_date(CAST(r.edicion AS INTEGER) - 1, 7, 1) >= CAST(g.desde AS DATE)
    AND make_date(CAST(r.edicion AS INTEGER) - 1, 7, 1) < coalesce(CAST(g.hasta AS DATE), current_date + INTERVAL 1 DAY)
WHERE r.cod_pais = 'ES' AND r.indicador = 'global'
ORDER BY r.edicion
```

```sql mpm_esp
SELECT nombre_area AS area, orden_area, CAST(edicion AS INTEGER) AS edicion, etiqueta_edicion, riesgo_pct, banda,
    CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.medios_libertad_mpm
WHERE cod_pais = 'ES'
ORDER BY orden_area, edicion
```

```sql mpm_esp_ult
SELECT * FROM ${mpm_esp} WHERE edicion = (SELECT max(edicion) FROM ${mpm_esp}) ORDER BY orden_area
```

```sql mpm_esp_ue
-- España y media de la UE por área en las ediciones con los 27 países
SELECT e.nombre_area AS area, e.orden_area, CAST(e.edicion AS INTEGER) AS edicion, e.riesgo_pct AS espana, u.riesgo_pct AS ue,
    e.riesgo_pct - u.riesgo_pct AS diferencia
FROM mother.medios_libertad_mpm e
JOIN mother.medios_libertad_mpm u ON u.cod_pais = 'EU27_2020' AND u.area = e.area AND u.edicion = e.edicion
WHERE e.cod_pais = 'ES'
ORDER BY e.orden_area, e.edicion
```

```sql mpm_esp_ue_ult
SELECT * FROM ${mpm_esp_ue} WHERE edicion = (SELECT max(edicion) FROM ${mpm_esp_ue}) ORDER BY orden_area
```

```sql mpm_largo
SELECT area, edicion, 'España' AS serie, espana AS riesgo_pct FROM ${mpm_esp_ue}
UNION ALL
SELECT area, edicion, 'Media de la UE' AS serie, ue AS riesgo_pct FROM ${mpm_esp_ue}
ORDER BY area, edicion, serie
```

```sql mpm_ue_ult
-- Riesgo global de los países de la UE en la última edición
SELECT pais, riesgo_pct, banda, CAST(puesto_ue AS INTEGER) AS puesto_ue,
    CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo,
    CAST(edicion AS INTEGER) AS edicion
FROM mother.medios_libertad_mpm
WHERE area = 'total' AND es_ue AND edicion = (SELECT max(edicion) FROM mother.medios_libertad_mpm WHERE area = 'total' AND n_ue = 27)
ORDER BY riesgo_pct
```

```sql vdem_esp
SELECT nombre_corto AS indicador, orden_indicador, pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.medios_libertad_vdem
WHERE cod_pais IN ('ES', 'EU27_2020') AND anio >= 1976
ORDER BY orden_indicador, orden_pais, anio
```

```sql vdem_ref
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.medios_libertad_vdem
WHERE indicador_id = 'vdem_libertad_expresion' AND es_referencia AND cod_pais IN ('ES', 'EU27_2020', 'FR', 'DE', 'IT', 'PT', 'HU') AND anio >= 2000
ORDER BY orden_pais, anio
```

```sql vdem_ult
-- Último año: España, media UE y puesto en cada indicador
SELECT e.nombre_corto AS indicador, e.orden_indicador, CAST(e.anio AS INTEGER) AS anio, e.valor AS espana, u.valor AS ue,
    CAST(e.puesto_ue AS INTEGER) AS puesto_ue, CAST(e.n_ue AS INTEGER) AS n_ue, e.unidad
FROM mother.medios_libertad_vdem e
JOIN mother.medios_libertad_vdem u ON u.indicador_id = e.indicador_id AND u.anio = e.anio AND u.cod_pais = 'EU27_2020'
WHERE e.cod_pais = 'ES' AND e.anio = (SELECT max(anio) FROM mother.medios_libertad_vdem WHERE cod_pais = 'ES')
ORDER BY e.orden_indicador
```

```sql coe_esp
SELECT pais, CAST(anio AS INTEGER) AS anio, alertas_por_10m_hab, CAST(alertas AS INTEGER) AS alertas,
    CAST(sin_respuesta AS INTEGER) AS sin_respuesta, CAST(resueltas AS INTEGER) AS resueltas
FROM mother.medios_libertad_coe_alertas
WHERE cod_pais IN ('ES', 'EU27_2020') AND NOT parcial
ORDER BY cod_pais DESC, anio
```

```sql coe_resumen
SELECT
    CAST(sum(alertas) FILTER (WHERE pais = 'España') AS INTEGER) AS total_esp,
    CAST(min(anio) AS INTEGER) AS desde,
    CAST(max(anio) AS INTEGER) AS hasta,
    CAST(sum(sin_respuesta) FILTER (WHERE pais = 'España') AS INTEGER) AS sin_respuesta_esp
FROM ${coe_esp}
```

```sql coe_ue_ult
-- Alertas por 10 millones de habitantes en los países de la UE, suma de los últimos 5 años completos
WITH u AS (
    SELECT max(anio) AS hasta FROM mother.medios_libertad_coe_alertas WHERE NOT parcial
)
SELECT c.pais,
    sum(c.alertas) / avg(c.poblacion) * 1e7 / 5 AS alertas_10m_anuales,
    CAST(sum(c.alertas) AS INTEGER) AS alertas,
    CASE WHEN c.cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.medios_libertad_coe_alertas c, u
WHERE c.es_ue AND c.anio > u.hasta - 5 AND c.anio <= u.hasta
GROUP BY c.pais, c.cod_pais
ORDER BY alertas_10m_anuales DESC
```

```sql coe_periodo
SELECT CAST(max(anio) - 4 AS INTEGER) AS desde, CAST(max(anio) AS INTEGER) AS hasta
FROM mother.medios_libertad_coe_alertas WHERE NOT parcial
```

# <span aria-hidden="true">🗞️</span> Prentsa-askatasuna eta aniztasuna

Kazetariek presiorik gabe lan egin dezakete Espainian, eta badago komunikabide independenteen aniztasunik? Nazioarteko hainbat erakundek urtero ebaluatzen dute hori, **herrialdeen artean konparagarriak diren indizeekin**. Orri honek lau nagusiak biltzen ditu eta Espainia **EBko 27 herrialdeen** artean kokatzen du: Mugarik Gabeko Kazetarien Prentsa Askatasunaren Munduko Sailkapena, Europako Unibertsitate Institutuaren Media Pluralism Monitor, V-Dem-en komunikabideen adierazleak eta Europako Kontseiluak kazetaritza babesteko duen plataformaren alertak.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Nola irakurri orri hau</p>
<p class="mb-1">Erakunde horien <b>balorazioak</b> dira, kazetariei, akademikoei eta adituei egindako galdetegiekin eginak, ez neurketa zuzenak. Bakoitzak gauza desberdinak aztertzen ditu: RSFk, kazetaritzan aritzeko baldintzak; Media Pluralism Monitor-ek, aniztasunerako arriskuak (legeak, jabetzaren kontzentrazioa, independentzia, sarbidea); V-Dem-ek, zentsura, jazarpena eta alborapena; Europako Kontseiluak, kazetarien erakundeek erregistratzen dituzten mehatxu-kasu zehatzak.</p>
<p class="mb-0">Metodoak urteekin aldatzen dira, eta puntu edo postu gutxiko aldeak <b>ez dira izaten esanguratsuak</b>. Garrantzitsuena joera eta EBrekiko aldea dira.</p>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if k_rsf.length && k_mpm.length && k_vdem.length && k_coe.length}
    <KpiCard
        title="RSFren sailkapena"
        value={k_rsf[0].valor}
        formattedValue={formatNumber(k_rsf[0].valor, 0) + '. postua'}
        period={`${k_rsf[0].anio} · ${k_rsf[0].n_total} herrialdeen artean; EBn ${k_rsf[0].puesto_ue}.a, ${k_rsf[0].n_ue} herrialdeen artean`}
        change={-(k_rsf[0].cambio)}
        changeUnit=" postu"
        changePeriod={`${urteko(k_rsf[0].anio_anterior)}arekiko`}
        direction="positive-up"
        source="Reporters sans frontières"
        sparklineData={serie_esp.filter(d => d.indice_id === 'rsf_puesto').map(d => -d.valor)}
    />
    <KpiCard
        title="Aniztasunerako arriskua"
        value={k_mpm[0].valor}
        formattedValue={formatNumber(k_mpm[0].valor, 0) + ' %'}
        period={`MPM${k_mpm[0].anio} · ${k_mpm[0].puesto_ue ? k_mpm[0].puesto_ue + '.a EBko ' + k_mpm[0].n_ue + ' herrialdeen artean (1 = arrisku txikiena)' : 'altuagoa = okerragoa'}`}
        change={k_mpm[0].cambio}
        changeUnit=" pt"
        changePeriod={`MPM${k_mpm[0].anio_anterior} edizioarekiko`}
        direction="positive-down"
        source="Media Pluralism Monitor (EUI)"
        sparklineData={serie_esp.filter(d => d.indice_id === 'mpm_total').map(d => d.valor)}
    />
    <KpiCard
        title="Adierazpen-askatasuna (V-Dem)"
        value={k_vdem[0].valor}
        formattedValue={formatNumber(k_vdem[0].valor, 1) + ' / 100'}
        period={`${k_vdem[0].anio} · ${k_vdem[0].puesto_ue}.a EBko ${k_vdem[0].n_ue} herrialdeen artean (EBko batez bestekoa ${formatNumber(k_vdem[0].valor_ue, 1)})`}
        change={k_vdem[0].cambio}
        changeUnit=" pt"
        changePeriod={`${urteko(k_vdem[0].anio_anterior)}arekiko`}
        direction="positive-up"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indice_id === 'vdem_libertad_expresion' && d.anio >= 1990).map(d => d.valor)}
    />
    <KpiCard
        title="Europako Kontseiluaren alertak"
        value={k_coe[0].valor}
        formattedValue={formatNumber(k_coe[0].valor, 2)}
        unit="10 milioi biztanleko"
        period={`${k_coe[0].anio} · ${k_coe[0].n_total} alerta; EBko batez bestekoa ${formatNumber(k_coe[0].valor_ue, 2)}`}
        change={k_coe[0].cambio}
        changeUnit=""
        changePeriod={`${urteko(k_coe[0].anio_anterior)}arekiko`}
        direction="positive-down"
        source="Europako Kontseilua"
        sparklineData={serie_esp.filter(d => d.indice_id === 'coe_alertas').map(d => d.valor)}
    />
    {/if}
</div>

## Prentsa Askatasunaren Munduko Sailkapena

**Mugarik Gabeko Kazetariak** (RSF) erakundeak urtero 180 bat herrialde sailkatzen ditu kazetaritzan aritzeko baldintzen arabera, kazetariei, akademikoei eta giza eskubideen defendatzaileei egindako galdetegi batetik eta kazetarien aurkako erasoen bere zenbaketatik abiatuta. Espainia **{k_rsf[0]?.n_total} herrialdeetatik {k_rsf[0]?.valor}. postuan** dago {urteko(k_rsf[0]?.anio)} edizioan, eta EBko {k_rsf[0]?.n_ue} herrialdeen artean {k_rsf[0]?.puesto_ue}.a da. Bere posturik onena {rsf_extremos[0]?.mejor_puesto}.a izan zen ({urteko(rsf_extremos[0]?.mejor_edicion)} edizioa), eta txarrena, {rsf_extremos[0]?.peor_puesto}.a ({rsf_extremos[0]?.peor_edicion}).

<LineChart
    data={rsf_ref}
    x=edicion
    y=puesto_mundial
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="munduko postua (1 = onena)"
    title="Postua Prentsa Askatasunaren Munduko Sailkapenean (RSF)"
    seriesColors={{'España': '#b91c1c'}}
>
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.06 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.06 />
</LineChart>

Ardatzean, zenbaki altuagoa posizio okerragoa da. Atzeko bandek gobernu zentraleko alderdia adierazten dute (<span style="color:#dc2626">PSOE</span> edo <span style="color:#2563eb">PP</span>), denbora-erreferentzia gisa soilik: sailkapenak herrialde osoa baloratzen du, ez Gobernua bakarrik. Edizio bakoitza udaberrian argitaratzen da eta, batez ere, aurreko urtea baloratzen du. Sailkatutako herrialdeen kopurua {urteko(rsf_extremos[0]?.primera_edicion)} {rsf_extremos[0]?.primer_n} izatetik {k_rsf[0]?.n_total} izatera igaro da; beraz, lehen urteetako postuak ez dira guztiz konparagarriak.

<BarChart
    data={rsf_ue_ult}
    x=pais
    y=puntuacion
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="EBko herrialdeen RSF puntuazioa, {k_rsf[0]?.anio} (0-100, gehiago hobea da)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

### RSFren bost adierazleak

2022tik RSFk puntuazioa bost adierazletan banatzen du: **testuinguru politikoa** (botere politikoaren presioak eta komunikabideen independentziarako laguntza), **ekonomikoa** (komunikabideen iraunkortasuna, kontzentrazioa, laguntzen eta publizitate publikoaren banaketa), **lege-esparrua** (legeak eta haien aplikazioa), **testuinguru soziala** (kazetariekiko errespetu soziala, taldeen presioak) eta **segurtasuna** (erasoak, mehatxuak, atxiloketak). {urteko(rsf_ind_ult[0]?.edicion)} edizioan, Espainiaren posturik onena {rsf_ind_ult[0]?.indicador} adierazlean da (munduko {rsf_ind_ult[0]?.puesto_mundial}.a), eta txarrena {rsf_ind_ult.slice(-1)[0]?.indicador} adierazlean ({rsf_ind_ult.slice(-1)[0]?.puesto_mundial}.a).

<LineChart
    data={rsf_ind}
    x=edicion
    y=puntuacion
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 puntu (gehiago hobea da)"
    title="Espainia RSFren adierazleetan"
/>

<DataTable data={rsf_ind_tabla} rows=all>
    <Column id=pais title="Herrialdea" />
    <Column id=puesto title="Munduko postua" fmt='0' />
    <Column id=global title="Orokorra" fmt='0.0' />
    <Column id=politico title="Politikoa" fmt='0.0' />
    <Column id=economico title="Ekonomikoa" fmt='0.0' />
    <Column id=legislativo title="Lege-esparrua" fmt='0.0' />
    <Column id=social title="Soziala" fmt='0.0' />
    <Column id=seguridad title="Segurtasuna" fmt='0.0' />
</DataTable>

### Edizioz edizio

Espainiaren postua edizio bakoitzean, eta edizio horrek baloratzen duen urteko uztailaren 1ean gobernatzen zuen alderdia. Egutegiaren deskribapen bat da, ez egozpen bat: balorazioak erkidegoen, auzitegien, komunikabide-enpresen eta beste eragile batzuen jarduna ere jasotzen du.

<DataTable data={rsf_gobiernos} rows=all>
    <Column id=edicion title="Edizioa" fmt='0' />
    <Column id=puesto_mundial title="Munduko postua" fmt='0' />
    <Column id=puesto_ue title="Postua EBn" fmt='0' />
    <Column id=presidente title="Presidentea aurreko urteko uztailaren 1ean" />
    <Column id=familia title="Alderdia" />
</DataTable>

## Komunikabideen aniztasunerako arriskua

Centre for Media Pluralism and Media Freedom-en (Europako Unibertsitate Institutua, Florentzia) **Media Pluralism Monitor**-ek (MPM) herrialde bakoitzeko ikertzaile-talde batekin ebaluatzen ditu lau arlotan bildutako 200 bat galdera. Emaitza **0tik 100 %-rainoko arrisku bat da: altuagoa okerragoa da**. MPM{mpm_esp_ult[0]?.edicion} edizioan, Espainiaren arrisku orokorra {formatNumber(mpm_esp_ult[0]?.riesgo_pct, 0)} % da ({mpm_esp_ult[0]?.banda} banda).

<BarChart
    data={mpm_esp_ult.filter(d => d.orden_area > 0)}
    x=area
    y=riesgo_pct
    swapXY=true
    yFmt='0"%"'
    yMax=100
    title="Espainia: arriskua arloka, MPM{mpm_esp_ult[0]?.edicion}"
    colorPalette={['#b45309']}
/>

- **Oinarrizko babesa**: adierazpen-askatasuna, informazio-eskubidea, kazetarien baldintzak eta segurtasuna, eta erregulatzailearen independentzia.
- **Merkatuaren aniztasuna**: jabetzaren gardentasuna, kontzentrazioa, komunikabideen bideragarritasun ekonomikoa eta argitaratzen dutenaren gaineko eragin komertziala.
- **Independentzia politikoa**: komunikabideen kontrol politikoa, komunikabide publikoen independentzia, erakunde-publizitatearen eta laguntzen banaketa, autonomia editoriala.
- **Gizarteratzea**: gutxiengoen, tokiko komunitateen, emakumeen eta desgaitasuna duten pertsonen sarbidea, eta alfabetatze mediatikoa.

### Espainia EBko batez bestekoaren aldean

EBko batez bestekoa gaur egun EB osatzen duten 27 herrialdeen batez besteko soila da, MPMk guztiak ebaluatu zituen edizioetan. MPM{mpm_esp_ue_ult[0]?.edicion} edizioan, Espainiak batez bestekoak baino arrisku handiagoa zuen lau arloetatik {mpm_esp_ue_ult.filter(d => d.orden_area > 0 && d.diferencia > 0).length}etan.

<Grid cols=2>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Protección fundamental')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="arriskua %"
    title="Oinarrizko babesa"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Pluralidad del mercado')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="arriskua %"
    title="Merkatuaren aniztasuna"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Independencia política')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="arriskua %"
    title="Independentzia politikoa"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
<LineChart
    data={mpm_largo.filter(d => d.area === 'Inclusión social')}
    x=edicion
    y=riesgo_pct
    series=serie
    xFmt='0'
    yFmt='0'
    yMin=0
    yMax=100
    yAxisTitle="arriskua %"
    title="Gizarteratzea"
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#94a3b8'}}
/>
</Grid>

Galdetegia edizio bakoitzean aldatzen da; beraz, edizioen arteko puntu gutxiko jauziek ez dute beti aldaketa errealik islatzen. Ez zen ediziorik izan 2018an ez 2019an (MPM2020k 2018 eta 2019 hartzen ditu).

<BarChart
    data={mpm_ue_ult}
    x=pais
    y=riesgo_pct
    series=grupo
    swapXY=true
    yFmt='0"%"'
    title="Aniztasunerako arrisku orokorra EBn, MPM{mpm_ue_ult[0]?.edicion} (gehiago okerragoa da)"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

<DataTable data={mpm_esp} rows=all>
    <Column id=area title="Arloa" />
    <Column id=etiqueta_edicion title="Edizioa" />
    <Column id=riesgo_pct title="Arriskua (%)" fmt='0' />
    <Column id=banda title="Banda" />
    <Column id=puesto_ue title="Postua EBn (1 = arrisku txikiena)" fmt='0' />
</DataTable>

## Zentsura, jazarpena eta alborapena V-Dem-en arabera

**V-Dem** proiektuak (Göteborgeko Unibertsitatea) herrialde bakoitzeko hainbat adituri eskatzen die urtero baloratzeko, besteak beste, Gobernua prentsa zentsuratzen saiatzen den, kazetariak jazartzen diren, komunikabideek beren burua zentsuratzen duten eta oposizioaren aurkako alborapenik duten. Eredu estatistiko batekin herrialdeen eta urteen artean konparagarriak diren puntuazio bihurtzen du hori, eta 0tik 100erako adierazpen-askatasunaren indize batean laburtzen du.

<LineChart
    data={vdem_ref}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (gehiago hobea da)"
    title="Adierazpen-askatasunaren eta informazio-iturri alternatiboen indizea (V-Dem)"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569'}}
/>

<LineChart
    data={vdem_esp.filter(d => d.orden_indicador > 1 && d.pais === 'España')}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="V-Dem-en eskala (altuagoa = askatasun gehiago)"
    title="Espainia: V-Dem-en komunikabideen adierazleak 1976tik"
/>

Lau adierazle hauek V-Dem-en ereduaren eskalan daude (gutxi gorabehera -4tik +4ra): **zenbat eta altuagoa, orduan eta askatasun gehiago** (zentsura gutxiago, jazarpen gutxiago, autozentsura gutxiago, alborapen gutxiago). {urtean(vdem_ult[0]?.anio)}:

<DataTable data={vdem_ult} rows=all>
    <Column id=indicador title="Adierazlea" />
    <Column id=espana title="Espainia" fmt='0.00' />
    <Column id=ue title="EBko batez bestekoa" fmt='0.00' />
    <Column id=puesto_ue title="Espainiaren postua EBn" fmt='0' />
</DataTable>

## Europako Kontseiluaren alertak

**Europako Kontseiluak kazetaritza eta kazetarien segurtasuna babesteko duen plataformak** prentsa-askatasunaren aurkako mehatxu larriei buruzko alertak argitaratzen ditu (erasoak, atxiloketak, jazarpena, salaketa abusiboak, presio politikoak), bere erakunde bazkideek erregistratuak, hala nola Kazetarien Europako Federazioak edo RSFk. Estatuek alerta bakoitzari erantzun diezaiokete. {urtetik(coe_resumen[0]?.desde)} {urtera(coe_resumen[0]?.hasta)} Espainiari buruzko {coe_resumen[0]?.total_esp} alerta argitaratu ziren, eta horietatik {coe_resumen[0]?.sin_respuesta_esp} Estatuaren erantzunik gabe. Tamaina desberdineko herrialdeak alderatzeko, 10 milioi biztanleko zenbatzen dira.

<LineChart
    data={coe_esp}
    x=anio
    y=alertas_por_10m_hab
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="alertak 10 milioi biztanleko"
    title="Urtean argitaratutako alertak, 10 milioi biztanleko"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (27)': '#94a3b8'}}
/>

<BarChart
    data={coe_ue_ult}
    x=pais
    y=alertas_10m_anuales
    series=grupo
    swapXY=true
    yFmt='0.0'
    title="Urteko alertak 10 milioi biztanleko, {coe_periodo[0]?.desde}-{coe_periodo[0]?.hasta} batez bestekoa"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

Zenbaketa txiki batek ez du nahitaez arazo gutxiago adierazten: erakunde bazkideek zein kasu erregistratzea erabakitzen duten eta herrialde bakoitzean zenbateko presentzia duten araberakoa da.

## Metodologia eta iturriak

- **Prentsa Askatasunaren Munduko Sailkapena**, [Reporters sans frontières](https://rsf.org/es/clasificacion) (Mugarik Gabeko Kazetariak), edizio bakoitzaren CSV fitxategiak (2002-2010 eta 2012tik aurrera; 2012koak 2011-2012 hartzen ditu). Postu eta puntuazio ofizialak bere horretan erreproduzitzen dira, RSF aipatuz, batez besteko edo kalkulu propiorik gabe (rsf.org-en erabilera-baldintzek eskubide guztiak gordetzen dituzte). Hiru etapetako puntuazioak **ez dira konparagarriak**: 2002-2012 (mugarik gabeko eskala, 0 = onena), 2013-2021 (0-100) eta 2022tik aurrera (metodologia berria, bost adierazlerekin). EBko postua gaur egun EB osatzen duten 27 herrialdeen artean postu ofizialen ordena besterik ez da.
- **Media Pluralism Monitor**, [Centre for Media Pluralism and Media Freedom](https://cmpf.eui.eu/) (Europako Unibertsitate Institutua), CC BY 4.0 lizentzia. MPM2016, MPM2017 eta MPM2020tik aurrerako edizioak (ez zen MPM2018 ez MPM2019 izan); N edizioak N-1 urtea baloratzen du. Iraganeko edizioak [Cadmus biltegiko](https://cadmus.eui.eu/) herrialde-txostenetatik (PDF) transkribatuak, eta azkena CMPFren [herrialdekako fitxetatik](https://cmpf.eui.eu/mpm-2025-results/). MPM2025ean Espainiaren datua soilik dago eskuragarri. Arrisku orokorra: CMPFk argitaratutakoa edo, argitaratzen ez zuten edizioetan, lau arloen batez besteko soila (CMPFk 2022tik kalkulatzen duen bezala). MPM2024ra arte hiru arrisku-banda zeuden (baxua, ertaina, altua) eta MPM2025etik, sei.
- **V-Dem** (Varieties of Democracy, Göteborgeko Unibertsitatea), [Our World in Data](https://ourworldindata.org/grapher/key-media-freedoms) bidez: gobernuaren zentsura (v2mecenefm), kazetarien jazarpena (v2meharjrn), autozentsura (v2meslfcen) eta komunikabideen alborapena (v2mebias), neurketa-ereduaren estimazio zentrala; eta [adierazpen-askatasunaren indizea](https://ourworldindata.org/grapher/freedom-of-expression-index) (0-1, 100ez biderkatua). CC BY-SA 4.0 (V-Dem) eta CC BY 4.0 (OWID) lizentziak. EBko batez bestekoa: gaur egungo estatu kideen batez besteko soila, datua herrialdeen gutxienez 90 %-k duen urteetan soilik.
- **Alertak**, [Europako Kontseiluak kazetaritza eta kazetarien segurtasuna babesteko duen plataforma](https://fom.coe.int/), herrialde eta urteko zenbaketa 2015etik (alertaren urtea, atariaren arabera), Eurostaten urteko batez besteko biztanleriarekin. Alerta bakoitzaren egoera (erantzuna, ebatzia) deskargatze-egunekoa da.
- Indize hauetako batek ere ez ditu komunikabideen audientziak edo kalitatea neurtzen. Komunikabideek jasotzen duten diru publikorako, ikus [Diru publikoa komunikabideetan](/eu/medios/dinero-publico/).
