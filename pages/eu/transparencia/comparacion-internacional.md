---
title: Espainia beste herrialdeen aldean
description: "Ustelkeriari, osotasunari eta gobernu irekiari buruzko indize internazionalak: non dagoen Espainia EBren, ELGAren eta erreferentziazko herrialdeen aldean, eta nola aldatu den Gobernu bakoitzarekin."
i18n_origen: 43c868242525
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // Urteei euskal atzizkiak eransten dizkie (2021ean, 2023an, 2000n...)
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
</script>

```sql esp
-- Último dato de España en cada índice, con el anterior, el primero de la serie y la media UE
WITH e AS (
    SELECT *,
        lag(valor) OVER (PARTITION BY indicador_id ORDER BY anio) AS valor_anterior,
        lag(anio) OVER (PARTITION BY indicador_id ORDER BY anio) AS anio_anterior,
        row_number() OVER (PARTITION BY indicador_id ORDER BY anio DESC) AS rn
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ES'
)
SELECT e.indicador_id, e.nombre_corto, e.unidad, e.sentido, e.fuente, e.orden_indicador,
    CAST(e.anio AS INTEGER) AS anio, e.valor, e.valor_anterior, CAST(e.anio_anterior AS INTEGER) AS anio_anterior,
    e.valor - e.valor_anterior AS cambio,
    CAST(e.puesto_mundial AS INTEGER) AS puesto_mundial,
    CAST(e.puesto_ue AS INTEGER) AS puesto_ue, CAST(e.n_ue AS INTEGER) AS n_ue,
    CAST(e.puesto_ocde AS INTEGER) AS puesto_ocde, CAST(e.n_ocde AS INTEGER) AS n_ocde,
    ue.valor AS valor_ue
FROM e
LEFT JOIN mother.transparencia_internacional ue
    ON ue.indicador_id = e.indicador_id AND ue.anio = e.anio AND ue.cod_pais = 'EU27_2020'
WHERE e.rn = 1
ORDER BY e.orden_indicador
```

```sql esp_cpi
SELECT * FROM ${esp} WHERE indicador_id = 'cpi'
```

```sql esp_wgi
SELECT * FROM ${esp} WHERE indicador_id = 'wgi_control_corrupcion'
```

```sql esp_wjp
SELECT * FROM ${esp} WHERE indicador_id = 'wjp_gobierno_abierto'
```

```sql esp_vdem
SELECT * FROM ${esp} WHERE indicador_id = 'vdem_corrupcion_politica'
```

```sql rango
SELECT CAST(min(puesto_ue) AS INTEGER) AS mejor, CAST(max(puesto_ue) AS INTEGER) AS peor FROM ${esp}
```

```sql cpi_inicio
SELECT CAST(anio AS INTEGER) AS anio, valor, CAST(puesto_ue AS INTEGER) AS puesto_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id = 'cpi'
ORDER BY anio
LIMIT 1
```

```sql serie_esp
SELECT indicador_id, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES'
ORDER BY indicador_id, anio
```

```sql referencia
-- Países de referencia y medias UE/OCDE, todas las series
SELECT indicador_id, pais, cod_pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE es_referencia AND anio >= 1996
ORDER BY indicador_id, orden_pais, anio
```

```sql ranking_ue
-- Países de la UE en el último año con dato de España, España destacada
SELECT t.indicador_id, t.pais, t.valor, CAST(t.anio AS INTEGER) AS anio,
    CASE WHEN t.cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.transparencia_internacional t
JOIN (
    SELECT indicador_id, max(anio) AS anio
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ES'
    GROUP BY indicador_id
) u ON u.indicador_id = t.indicador_id AND u.anio = t.anio
WHERE t.es_ue
ORDER BY t.indicador_id, t.valor DESC
```

```sql puesto_ue_serie
SELECT indicador_id, nombre_corto, CAST(anio AS INTEGER) AS anio, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id IN ('cpi', 'wgi_control_corrupcion', 'wjp_estado_derecho') AND anio >= 1996
ORDER BY indicador_id, anio
```

```sql tabla_paises
-- Último dato de cada país de referencia en los índices principales
WITH u AS (
    SELECT t.* FROM mother.transparencia_internacional t
    JOIN (
        SELECT indicador_id, cod_pais, max(anio) AS anio
        FROM mother.transparencia_internacional
        GROUP BY indicador_id, cod_pais
    ) m ON m.indicador_id = t.indicador_id AND m.cod_pais = t.cod_pais AND m.anio = t.anio
    WHERE t.es_referencia
)
SELECT
    pais,
    min(orden_pais) AS orden,
    max(CASE WHEN indicador_id = 'cpi' THEN valor END) AS cpi,
    max(CASE WHEN indicador_id = 'wgi_control_corrupcion' THEN valor END) AS wgi_cc,
    max(CASE WHEN indicador_id = 'wgi_voz_rendicion_cuentas' THEN valor END) AS wgi_va,
    max(CASE WHEN indicador_id = 'wgi_eficacia_gobierno' THEN valor END) AS wgi_ge,
    max(CASE WHEN indicador_id = 'wjp_gobierno_abierto' THEN valor END) AS wjp_ga,
    max(CASE WHEN indicador_id = 'vdem_corrupcion_politica' THEN valor END) AS vdem_cp
FROM u
GROUP BY pais
ORDER BY orden, pais
```

```sql gobiernos
SELECT
    CAST(year(CAST(desde AS DATE)) AS INTEGER) AS anio_desde,
    CAST(coalesce(year(CAST(hasta AS DATE)), year(current_date)) AS INTEGER) AS anio_hasta,
    presidente, familia
FROM mother.gobiernos_presidentes
WHERE nivel = 'estatal'
ORDER BY anio_desde
```

```sql gob_psoe
SELECT * FROM ${gobiernos} WHERE familia = 'PSOE'
```

```sql gob_pp
SELECT * FROM ${gobiernos} WHERE familia = 'PP'
```

```sql gob_ucd
SELECT * FROM ${gobiernos} WHERE familia = 'UCD'
```

```sql larga_vdem
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'vdem_corrupcion_politica' AND cod_pais IN ('ES', 'EU27_2020', 'OECD') AND anio >= 1977
ORDER BY cod_pais, anio
```

```sql larga_wgi
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'wgi_control_corrupcion' AND cod_pais IN ('ES', 'EU27_2020', 'OECD')
ORDER BY cod_pais, anio
```

```sql mandatos
-- Cambio de la distancia de España a la media de la UE atribuido a cada Gobierno.
-- Media de la UE: media simple de los países de la UE con serie completa desde
-- 1976 (o desde el inicio del índice), para que la composición no cambie con los
-- años. Cada año se asigna a quien gobernaba el 1 de julio; el cambio de un año es
-- la variación de la brecha respecto al año anterior con dato. Signo positivo =
-- España mejora respecto a la UE (en V-Dem, donde más es peor, se invierte).
WITH g AS (
    SELECT presidente, familia, CAST(desde AS DATE) AS desde,
        coalesce(CAST(hasta AS DATE), current_date + INTERVAL 1 DAY) AS hasta
    FROM mother.gobiernos_presidentes
    WHERE nivel = 'estatal'
),
base AS (
    SELECT indicador_id, sentido, cod_pais, es_ue, CAST(anio AS INTEGER) AS anio, valor
    FROM mother.transparencia_internacional
    WHERE indicador_id IN ('vdem_corrupcion_politica', 'wgi_control_corrupcion')
      AND anio >= 1976 AND NOT es_agregado
),
anios_esp AS (
    SELECT indicador_id, count(*) AS n FROM base WHERE cod_pais = 'ES' GROUP BY indicador_id
),
panel AS (
    SELECT b.indicador_id, b.cod_pais
    FROM base b JOIN anios_esp a ON a.indicador_id = b.indicador_id
    WHERE b.es_ue AND b.cod_pais <> 'ES'
    GROUP BY b.indicador_id, b.cod_pais, a.n
    HAVING count(*) = a.n
),
n_panel AS (
    SELECT indicador_id, CAST(count(*) AS INTEGER) AS n_panel FROM panel GROUP BY indicador_id
),
media AS (
    SELECT b.indicador_id, b.anio, avg(b.valor) AS valor
    FROM base b JOIN panel p ON p.indicador_id = b.indicador_id AND p.cod_pais = b.cod_pais
    GROUP BY b.indicador_id, b.anio
),
brecha AS (
    SELECT e.indicador_id, e.sentido, e.anio, e.valor - m.valor AS brecha
    FROM base e JOIN media m ON m.indicador_id = e.indicador_id AND m.anio = e.anio
    WHERE e.cod_pais = 'ES'
),
cambios AS (
    SELECT *,
        (brecha - lag(brecha) OVER (PARTITION BY indicador_id ORDER BY anio))
            * CASE WHEN sentido = 'negativo' THEN -1 ELSE 1 END AS mejora
    FROM brecha
)
SELECT
    c.indicador_id,
    CASE WHEN c.indicador_id = 'vdem_corrupcion_politica' THEN 'Corrupción política (V-Dem, puntos)' ELSE 'Control de la corrupción (Banco Mundial, puntos)' END AS indice,
    CASE g.presidente
        WHEN 'Adolfo Suárez / Leopoldo Calvo-Sotelo' THEN 'Suárez y Calvo-Sotelo'
        WHEN 'Felipe González' THEN 'González'
        WHEN 'José María Aznar' THEN 'Aznar'
        WHEN 'José Luis Rodríguez Zapatero' THEN 'Zapatero'
        WHEN 'Mariano Rajoy' THEN 'Rajoy'
        WHEN 'Pedro Sánchez' THEN 'Sánchez'
        ELSE g.presidente END || ' (' || CAST(year(g.desde) AS VARCHAR) || '-' ||
        CASE WHEN g.hasta > current_date THEN 'hoy' ELSE CAST(year(g.hasta) AS VARCHAR) END || ')' AS mandato,
    g.familia,
    year(g.desde) AS orden,
    CAST(count(c.mejora) AS INTEGER) AS anios,
    CAST(min(c.anio) AS INTEGER) AS primer_anio,
    CAST(max(c.anio) AS INTEGER) AS ultimo_anio,
    sum(c.mejora) AS mejora,
    sum(c.mejora) / count(c.mejora) AS mejora_anual,
    min(n.n_panel) AS n_panel
FROM cambios c
JOIN n_panel n ON n.indicador_id = c.indicador_id
JOIN g ON make_date(c.anio, 7, 1) >= g.desde AND make_date(c.anio, 7, 1) < g.hasta
WHERE c.mejora IS NOT NULL
GROUP BY c.indicador_id, indice, g.presidente, g.familia, g.desde, g.hasta
ORDER BY c.indicador_id, orden
```

```sql mandatos_vdem
SELECT * FROM ${mandatos} WHERE indicador_id = 'vdem_corrupcion_politica' ORDER BY orden
```

```sql mandatos_wgi
SELECT * FROM ${mandatos} WHERE indicador_id = 'wgi_control_corrupcion' ORDER BY orden
```

```sql wjp_factores
SELECT nombre_corto AS factor, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id LIKE 'wjp_%'
ORDER BY orden_indicador, anio
```

```sql opciones
SELECT DISTINCT indicador_id, nombre, orden_indicador
FROM mother.transparencia_internacional
ORDER BY orden_indicador
```

```sql exp_info
SELECT DISTINCT nombre, unidad, sentido, fuente, url_fuente
FROM mother.transparencia_internacional
WHERE indicador_id = '${inputs.ind.value}'
```

```sql exp_serie
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = '${inputs.ind.value}' AND es_referencia AND anio >= 1996
ORDER BY orden_pais, anio
```

```sql exp_ranking
SELECT t.pais, t.valor,
    CASE WHEN t.cod_pais = 'ES' THEN 'España' WHEN t.es_ue THEN 'Resto de la UE' ELSE 'Resto de la OCDE' END AS grupo
FROM mother.transparencia_internacional t
WHERE t.indicador_id = '${inputs.ind.value}' AND (t.es_ue OR t.es_ocde)
  AND t.anio = (
    SELECT max(anio) FROM mother.transparencia_internacional
    WHERE indicador_id = '${inputs.ind.value}' AND cod_pais = 'ES'
  )
ORDER BY t.valor DESC
```

# 🌍 Gardentasuna: Espainia beste herrialdeen aldean

Nola ikusten da kanpotik Espainiako erakundeen osotasuna? Hainbat erakunde internazionalek **herrialdeen artean alderagarriak diren indizeak** argitaratzen dituzte urtero ustelkeriari, zuzenbide-estatuari eta gobernu irekiari buruz. Orri honek nagusiak biltzen ditu, Espainia **EBko 27 herrialdeen** eta **ELGAko 38en** artean kokatzen du, eta bere auzokideekin eta sailkapen horien buruan egon ohi diren herrialdeekin (Danimarka, Finlandia, Zeelanda Berria eta Estonia) alderatzen du.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Nola irakurri orri hau</p>
<p class="mb-1">Indize hauetako batek ere ez ditu ustelkeria-kasuak zenbatzen: inkestatutako adituen, enpresen eta herritarren <b>pertzepzioak eta balorazioak neurtzen dituzte</b>. Erabilgarriak dira herrialdeak alderatzeko eta joera luzeak ikusteko, baina berandu erreakzionatzen dute, hainbat puntuko errore-marjinak dituzte, eta komunikabideetako eskandaluengatik mugi daitezke aldaketa errealengatik adina.</p>
<p class="mb-0">Urteen artean edo sailkapeneko herrialde auzokideen artean puntu bat edo biko aldeak <b>ez dira esanguratsuak izan ohi</b>. Garrantzitsuena urte batzuetako joera eta batez bestekoarekiko aldea da.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Ustelkeriaren pertzepzioa (CPI)"
        value={esp_cpi[0]?.valor}
        formattedValue="{formatNumber(esp_cpi[0]?.valor, 0)} / 100"
        period="{esp_cpi[0]?.anio} · EBko postua: {esp_cpi[0]?.puesto_ue}/{esp_cpi[0]?.n_ue} · munduan: {esp_cpi[0]?.puesto_mundial}."
        change={esp_cpi[0]?.cambio}
        changeUnit=" puntu"
        changePeriod="aurreko datuarekin alderatuta ({esp_cpi[0]?.anio_anterior})"
        direction="positive-up"
        source="Transparency International"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'cpi').map(d => d.valor)}
    />
    <KpiCard
        title="Ustelkeriaren kontrola (Munduko Bankua)"
        value={esp_wgi[0]?.valor}
        formattedValue="{formatNumber(esp_wgi[0]?.valor, 1)} / 100"
        period="{esp_wgi[0]?.anio} · EBko postua: {esp_wgi[0]?.puesto_ue}/{esp_wgi[0]?.n_ue} (EBko batez bestekoa: {formatNumber(esp_wgi[0]?.valor_ue, 1)})"
        change={esp_wgi[0]?.cambio?.toFixed(1)}
        changeUnit=" puntu"
        changePeriod="aurreko datuarekin alderatuta ({esp_wgi[0]?.anio_anterior})"
        direction="positive-up"
        source="Munduko Bankua (WGI)"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wgi_control_corrupcion').map(d => d.valor)}
    />
    <KpiCard
        title="Gobernu irekia (WJP)"
        value={esp_wjp[0]?.valor}
        formattedValue="{formatNumber(esp_wjp[0]?.valor, 0)} / 100"
        period="{esp_wjp[0]?.anio} · EBko postua: {esp_wjp[0]?.puesto_ue}/{esp_wjp[0]?.n_ue}"
        change={esp_wjp[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="aurreko datuarekin alderatuta ({esp_wjp[0]?.anio_anterior})"
        direction="positive-up"
        source="World Justice Project"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wjp_gobierno_abierto').map(d => d.valor)}
    />
    <KpiCard
        title="Ustelkeria politikoa (V-Dem)"
        value={esp_vdem[0]?.valor}
        formattedValue="{formatNumber(esp_vdem[0]?.valor, 1)} / 100"
        period="{esp_vdem[0]?.anio} · txikiagoa hobea da · EBko postua: {esp_vdem[0]?.puesto_ue}/{esp_vdem[0]?.n_ue}"
        change={esp_vdem[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="aurreko datuarekin alderatuta ({esp_vdem[0]?.anio_anterior})"
        direction="positive-down"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'vdem_corrupcion_politica' && d.anio >= 1977).map(d => d.valor)}
    />
</Grid>

Datuak dituen azken urtean, Espainia **EBko 27 herrialdeen artean {rango[0]?.mejor}. eta {rango[0]?.peor}. postuen artean** dago, indizearen arabera, sailkapen ia guztien buruan dauden herrialde nordikoetatik urrun. Ustelkeriaren Pertzepzio Indizean, {formatNumber(cpi_inicio[0]?.valor, 0)} puntu zituen {urtean(cpi_inicio[0]?.anio)} (EBko {cpi_inicio[0]?.puesto_ue}. postua), eta {formatNumber(esp_cpi[0]?.valor, 0)} {urtean(esp_cpi[0]?.anio)} ({esp_cpi[0]?.puesto_ue}. postua).

## Espainia eta erreferentziazko herrialdeak

Herrialde bakoitzaren azken datu erabilgarria indize nagusietan. Guztietan, **handiagoa hobea da**, V-Demen indizean (ustelkeria politikoa) izan ezik, non handiagoa okerragoa den. EBren eta ELGAren batez bestekoak Munduko Bankuaren eta V-Demen indizeetarako baino ez daude (ikus metodologia).

<DataTable data={tabla_paises} rows=all>
    <Column id=pais title="Herrialdea" />
    <Column id=cpi title="CPI (0-100)" fmt='0' />
    <Column id=wgi_cc title="Ustelkeriaren kontrola (0-100)" fmt='0.0' />
    <Column id=wgi_va title="Ahotsa eta kontu-ematea (0-100)" fmt='0.0' />
    <Column id=wgi_ge title="Gobernuaren eraginkortasuna (0-100)" fmt='0.0' />
    <Column id=wjp_ga title="Gobernu irekia WJP (0-100)" fmt='0.0' />
    <Column id=vdem_cp title="Ustelkeria politikoa V-Dem (0-100, txikiagoa hobea)\" fmt='0.0' />
</DataTable>

## Ustelkeriaren pertzepzioa

Transparency Internationalen **Ustelkeriaren Pertzepzio Indizea** (CPI) da gehien aipatzen dena. Sektore publikoko ustelkeriari buruzko 13 inkesta eta aditu eta enpresen balorazio arteko batez bestekoa egiten du; 100 «oso garbia» da eta 0 «oso ustela». Haren metodoa 2012tik aurrera baino ez da alderagarria.

<LineChart
    data={referencia.filter(d => d.indicador_id === 'cpi')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yMin=20
    yAxisTitle="puntuak (0-100)"
    title="Ustelkeriaren Pertzepzio Indizea"
    seriesColors={{'España': '#b91c1c'}}
/>

<BarChart
    data={ranking_ue.filter(d => d.indicador_id === 'cpi')}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    yFmt='0'
    title="CPI: EBko herrialdeak, {esp_cpi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

## Gobernantza, Munduko Bankuaren arabera

Munduko Bankuaren **Worldwide Governance Indicators** adierazleek 30 iturri baino gehiago (etxeei eta enpresei egindako inkestak, GKEak, erakunde publikoak eta arrisku-agentziak) konbinatzen dituzte gobernantzaren sei dimentsiotan. Hemen lau erakusten dira, 0tik 100era bitarteko eskalan. EBren eta ELGAren batez bestekoak egungo herrialde kideen **batez besteko sinpleak** dira.

<Grid cols=2>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_control_corrupcion')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Ustelkeriaren kontrola"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_voz_rendicion_cuentas')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Ahotsa eta kontu-ematea"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_eficacia_gobierno')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Gobernuaren eraginkortasuna"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_estado_derecho')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Zuzenbide-estatua"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
</Grid>

**Ahotsa eta kontu-emateak** adierazpen-, prentsa- eta elkartze-askatasuna eta hauteskundeen kalitatea neurtzen ditu; **gobernuaren eraginkortasunak**, zerbitzu publikoen eta administrazioaren kalitatea eta presio politikoekiko independentzia; **zuzenbide-estatuak**, legeekiko, auzitegiekiko eta poliziarekiko konfiantza eta kontratuen betetzea. Puntuazio bakoitzak hainbat puntuko % 90eko konfiantza-tartea du: urte batetik bestera izaten diren aldaketak tarte horren barruan geratu ohi dira.

### Espainiaren postua EBn

<LineChart
    data={puesto_ue_serie}
    x=anio
    y=puesto_ue
    series=nombre_corto
    xFmt='0'
    yFmt='0'
    yAxisTitle="postua 27en artean (1 = onena)"
    title="Espainiaren postua EB-27ko herrialdeen artean"
/>

Postua gaur egun EB-27 osatzen duten eta urte horretan datua duten herrialdeen artean kalkulatzen da (1 = onena). Ardatzean, zenbaki handiago batek postu okerragoa esan nahi du.

## Serie luzea eta Gobernu-aldaketak

**V-Dem** proiektuak (Göteborgeko Unibertsitatea) adituen balorazioekin berreraikitzen du ustelkeria politikoaren indize bat demokrazia baino askoz lehenagotik, eta, beraz, etapa konstituzional osoa ikusteko aukera ematen du. Atzealdeko bandek nork gobernatzen zuen adierazten dute: <span style="color:#16a34a">UCD</span>, <span style="color:#dc2626">PSOE</span> eta <span style="color:#2563eb">PP</span>. EBko batez bestekoa gaur egun EB osatzen duten herrialdeen % 90ek gutxienez datua dutenetik baino ez da agertzen (horietako batzuk ez ziren estatu independente gisa existitzen 1991 baino lehen).

<LineChart
    data={larga_vdem}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (handiagoa = ustelkeria gehiago)"
    title="Ustelkeria politikoaren indizea (V-Dem), 1977-{esp_vdem[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
>
    <ReferenceArea data={gob_ucd} xMin=anio_desde xMax=anio_hasta label=familia color="#16a34a" opacity=0.08 />
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.08 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.08 />
</LineChart>

<LineChart
    data={larga_wgi}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100 (handiagoa = hobea)"
    title="Ustelkeriaren kontrola (Munduko Bankua), 1996-{esp_wgi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

### Gobernuka, EBko batez bestekoaren aldean

Europako joera bat Gobernu bati ez egozteko, **Espainiaren eta EBko batez bestekoaren arteko aldea agintaldi bakoitzean zenbat aldatu zen** neurtzen da. Batez bestekoa serie osoa duten EBko herrialdeena da, urteekin haren osaera alda ez dadin ({mandatos_vdem[0]?.n_panel} herrialde V-Demen 1976tik, eta {mandatos_wgi[0]?.n_panel} Munduko Bankuan 1996tik). Urte bakoitza uztailaren 1ean gobernatzen zuenari esleitzen zaio. Balio positiboak esan nahi du Espainia **EBren aldean hobetu zela**; negatiboak, okerrera egin zuela. 0-100 eskalako puntuetan adierazten da.

<BarChart
    data={mandatos_vdem}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="V-Dem, ustelkeria politikoa: hobekuntza EBren aldean (puntuak)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<BarChart
    data={mandatos_wgi}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="Munduko Bankua, ustelkeriaren kontrola: hobekuntza EBren aldean (puntuak)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<DataTable data={mandatos} rows=all>
    <Column id=indice title="Indizea" />
    <Column id=mandato title="Agintaldia" />
    <Column id=familia title="Alderdia" />
    <Column id=primer_anio title="Noiztik" fmt='0' />
    <Column id=ultimo_anio title="Noiz arte" fmt='0' />
    <Column id=anios title="Datua duten urteak" fmt='0' />
    <Column id=mejora title="Hobekuntza EBren aldean" fmt='0.0' contentType=delta />
    <Column id=mejora_anual title="Urteko" fmt='0.00' contentType=delta />
</DataTable>

Barra hauek kontuz irakurri behar dira. Pertzepzio-indizeek **urte batzuetako atzerapenarekin erreakzionatzen dute**: ustelkeria-kasu handiak gertaeren ondoren askoz geroago epaitu eta argitaratu ohi dira, eta askotan hurrengo agintaldian. Ez dute bereizten, gainera, zer dagoen gobernu zentralaren esku eta zer erkidegoen, udalen, alderdien edo auzitegien esku. Eta agintaldi laburrek urte gutxi batzen dituzte; beraz, datu atipiko bakar batek pisu handia du.

## Zuzenbide-estatua eta gobernu irekia

World Justice Projecten **Rule of Law Index** delakoa biztanleria orokorrari egindako inkesta batean (herrialde bakoitzeko 1.000 lagun inguru) eta aditu juridikoei egindako galdetegietan oinarritzen da. Bere zortzi faktoreetatik, lau hauek dira gardentasunarekin lotuenak: indize orokorra, **gobernuaren boterearen mugak** (Parlamentuaren, auzitegien eta auditoria-organoen kontrolak), **ustelkeriarik eza** eta **gobernu irekia** (argitaratutako legeak eta datuak, informazioa eskuratzeko eskubidea, herritarren parte-hartzea eta kexa-bideak).

<LineChart
    data={wjp_factores}
    x=anio
    y=valor
    series=factor
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Espainia Rule of Law Index-ean (WJP)"
/>

<LineChart
    data={referencia.filter(d => d.indicador_id === 'wjp_gobierno_abierto')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Gobernu irekia (WJP, 3. faktorea)"
    seriesColors={{'España': '#b91c1c'}}
/>

WJPren 2012-2013 eta 2017-2018 edizioak bi urtekoak izan ziren, eta bigarren urtean agertzen dira.

## Arakatu edozein indize

Aukeratu indize bat erreferentziazko herrialdeetan izan duen bilakaera eta EBko eta ELGAko herrialdeen sailkapena ikusteko, Espainiak datua duen azken urtean.

<Dropdown data={opciones} name=ind value=indicador_id label=nombre order=orden_indicador title="Indizea" defaultValue="cpi" />

<LineChart
    data={exp_serie}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yAxisTitle={exp_info[0]?.unidad}
    title={exp_info[0]?.nombre}
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

<BarChart
    data={exp_ranking}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    title="{exp_info[0]?.nombre}: EBko eta ELGAko herrialdeak"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#64748b', 'Resto de la OCDE': '#cbd5e1'}}
/>

Unitatea: {exp_info[0]?.unidad}. {exp_info[0]?.sentido === 'negativo' ? 'Indize honetan, balio handiagoa okerragoa da.' : 'Indize honetan, balio handiagoa hobea da.'} Iturria: <a href={exp_info[0]?.url_fuente}>{exp_info[0]?.fuente}</a>.

## Metodologia eta iturriak

- **Ustelkeriaren Pertzepzio Indizea (CPI)**, [Transparency International](https://www.transparency.org/en/cpi). 3 eta 13 iturri arteko batez bestekoa (herrialde-arriskuaren ebaluazioak, zuzendariei egindako inkestak eta adituen balorazioak), 0tik 100era berreskalatuta. **Sektore publikoan hautematen den** ustelkeria neurtzen du, ez pribatua, ez diru-zuritzea, ez alderdien legez kanpoko finantzaketa. 2012tik alderagarria. Emaitzen urteko Excelaren serieen orria hartzen da. CC BY-ND 4.0 lizentzia: puntuazio eta munduko postu ofizialak **eraldatu gabe** erreproduzitzen dira, eta horregatik ez da EBko ez ELGAko batez bestekorik kalkulatzen (Espainiak EBn duen postua argitaratutako puntuazioen ordena besterik ez da).
- **Worldwide Governance Indicators (WGI)**, [Munduko Bankua](https://www.worldbank.org/en/publication/worldwide-governance-indicators), Munduko Bankuaren datuen APIa (3. iturria). 30 pertzepzio-iturri baino gehiago sei dimentsiotan konbinatzen dituen eredu estatistikoa; 2024ko berrikuspen metodologikoaren 0-100 puntuazioa erabiltzen da, % 90eko konfiantza-tartearekin. Bi urtean behin 2002ra arte. CC BY 4.0 lizentzia.
- **V-Dem** (Varieties of Democracy, Göteborgeko Unibertsitatea), [Our World in Data](https://ourworldindata.org/grapher/political-corruption-index) bidez. Ustelkeria politikoaren indizeak (exekutiboa, legegilea, judiziala eta sektore publikoa) eta sektore publikoko ustelkeriarenak, 0tik 100era (100 = ustelkeria handiena; jatorrizko 0-1 eskala, 100 ez biderkatua), herrialde bakoitzeko milaka adituren balorazioen gaineko neurketa-eredu batekin eraikiak. CC BY-SA 4.0 (V-Dem) eta CC BY 4.0 (OWID) lizentziak.
- **Rule of Law Index**, [World Justice Project](https://worldjusticeproject.org/rule-of-law-index/). Biztanleria orokorrari egindako inkesta eta adituei egindako galdetegiak; 0-100 eskala (jatorrizko 0-1 eskala, 100 ez biderkatua). Herrialdeen estaldura gero eta handiagoa 2012-2013tik. CC BY-NC-ND 4.0 lizentzia: puntuazioak dauden bezala erreproduzituak, batez besteko propiorik gabe.
- **EBren eta ELGAren batez bestekoak**: **gaur egun** kide diren herrialdeen batez besteko sinpleak (ez biztanleriaren arabera haztatuak), WGIrako eta V-Demerako soilik kalkulatuak, eta haien % 90ek gutxienez datua duten urteetan soilik. **EBko/ELGAko postua**: urte horretan datua duten egungo kideen arteko ordena (1 = onena).
- **Gobernuak**: Gobernuko presidenteak eta alderdia, SpainFactsen gobernuen seed-etik. Agintaldikako analisian, urte bakoitza uztailaren 1ean gobernatzen zuenari egozten zaio, eta urteko aldaketa Espainiaren eta EBko batez bestekoaren arteko aldeak datua duen aurreko urtearekiko izan duen aldakuntza da.
- **Muga komunak**: guztiak **pertzepzio-indizeak** dira, inkestetatik eta balorazio subjektiboetatik osatuak; batzuek iturriak partekatzen dituzte (horregatik dira hain antzekoak); hainbat puntuko errore-marjinak dituzte; eta gertaerak atzerapenarekin islatzen dituzte. Ez dituzte ordezkatzen kondenen edo ikerketen datuak (ikus [kriminalitatea](/eu/sociedad/criminalidad/) eta [udalen kontu-ematea](/eu/transparencia/cuentas-municipales/)).
- **Baztertutako iturriak**: Europako Batzordearen Open Data Maturity delakoak eta Single Market Scoreboard-eko kontratazio publikoko adierazleek (lizitatzaile bakarra, deialdirik gabeko esleipenak) ez dute gaur egun herrialdeka eta urteka datu-deskarga berrerabilgarririk eskaintzen (PDF txostenak eta panel interaktiboak soilik); Global Right to Information Rating-ek informazioa eskuratzeko legea ebaluatzen du, oso gutxitan aldatzen dena, eta ez du urteko seriea osatzen.
