---
title: Osasuna
description: "Bizi-itxaropena Espainian erkidego eta probintziaka, zerk eragiten dituen heriotzak, suizidioak, trafiko-istripuak, gehiegizko hilkortasuna eta osasun-sistema: itxaron-zerrendak, medikuak, erizainak, oheak eta biztanleko gastua EBrekin alderatuta."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 29850a7d6705
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
    // Datak (datuetan gaztelaniaz datoz): '30 de junio de 2024' -> '2024ko ekainaren 30a' / '...30ean'
    const HILAK = { enero: 'urtarrilaren', febrero: 'otsailaren', marzo: 'martxoaren', abril: 'apirilaren', mayo: 'maiatzaren', junio: 'ekainaren', julio: 'uztailaren', agosto: 'abuztuaren', septiembre: 'irailaren', octubre: 'urriaren', noviembre: 'azaroaren', diciembre: 'abenduaren' };
    const dataEu = (s, inesiboa = false) => {
        const m = String(s ?? String()).match(/(\d+) de ([a-z]+) de (\d{4})/);
        if (!m) return s ?? String();
        const e = Number(m[1]);
        const atz = inesiboa ? (urteN(e) ? 'n' : urteK(e) ? 'ean' : 'an') : (urteN(e) ? String() : 'a');
        return `${urteko(m[3])} ${HILAK[m[2]] ?? m[2]} ${e}${atz}`;
    };
</script>

```sql ev_espana
SELECT anio, sexo, anios
FROM mother.salud_esperanza_vida
WHERE nivel = 'pais'
ORDER BY anio
```

```sql ev_ultimo
SELECT
    max(anio) AS anio,
    max(anios) FILTER (WHERE sexo = 'Ambos sexos') AS total,
    max(anios) FILTER (WHERE sexo = 'Mujeres') AS mujeres,
    max(anios) FILTER (WHERE sexo = 'Hombres') AS hombres
FROM ${ev_espana}
WHERE anio = (SELECT max(anio) FROM ${ev_espana})
```

```sql ev_serie
SELECT anio, anios AS valor FROM ${ev_espana} WHERE sexo = 'Ambos sexos' AND anio >= 2000 ORDER BY anio
```

```sql causas_clave
SELECT anio, codigo_causa, defunciones, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND codigo_causa IN ('001-102', '098', '090', '099')
ORDER BY anio
```

```sql causas_ultimo
SELECT
    max(anio) AS anio,
    max(defunciones) FILTER (WHERE codigo_causa = '001-102') AS total,
    max(defunciones) FILTER (WHERE codigo_causa = '098') AS suicidios,
    max(tasa_100k) FILTER (WHERE codigo_causa = '098') AS suicidios_tasa,
    max(defunciones) FILTER (WHERE codigo_causa = '090') AS trafico,
    max(tasa_100k) FILTER (WHERE codigo_causa = '090') AS trafico_tasa,
    max(tasa_100k) FILTER (WHERE codigo_causa = '001-102') / 100 AS mortalidad_1000
FROM ${causas_clave}
WHERE anio = (SELECT max(anio) FROM ${causas_clave})
```

```sql exceso_anual
SELECT anio, sum(defunciones) AS defunciones, sum(defunciones) / sum(media_2015_2019) - 1 AS exceso, count(*) AS semanas
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND anio >= 2015
GROUP BY anio
ORDER BY anio
```

# 🩺 Osasuna

Zenbat bizi garen, zerk eragiten dizkigun heriotzak eta nola aldatu diren gauzak, INEren estatistika demografikoekin. Beherago, <a href="#osasun-sistema">osasun-sistema</a>: itxaron-zerrendak, medikuak, erizainak, oheak eta gastua.

<Grid cols=4>
    <KpiCard
        title="Bizi-itxaropena jaiotzean"
        value={ev_ultimo[0]?.total}
        formattedValue="{formatNumber(ev_ultimo[0]?.total, 1)} urte"
        period="emakumeak {formatNumber(ev_ultimo[0]?.mujeres, 1)} · gizonak {formatNumber(ev_ultimo[0]?.hombres, 1)} · {ev_ultimo[0]?.anio}"
        source="INE / Eurostat"
        sparklineData={ev_serie}
    />
    <KpiCard
        title="Hilkortasun-tasa"
        value={causas_ultimo[0]?.mortalidad_1000}
        formattedValue="{formatNumber(causas_ultimo[0]?.mortalidad_1000, 1)} 1.000 biz."
        period="{formatNumber(causas_ultimo[0]?.total, 0)} heriotza {urtean(causas_ultimo[0]?.anio)} · tasa gordina"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '001-102' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k / 100}))}
    />
    <KpiCard
        title="Suizidioak"
        value={causas_ultimo[0]?.suicidios_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.suicidios_tasa, 1)} 100.000 biz."
        period="{formatNumber(causas_ultimo[0]?.suicidios, 0)} {urtean(causas_ultimo[0]?.anio)} · kanpoko heriotza-kausa nagusia"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '098' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k}))}
    />
    <KpiCard
        title="Trafiko-istripuetan hildakoak"
        value={causas_ultimo[0]?.trafico_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.trafico_tasa, 1)} 100.000 biz."
        period="{formatNumber(causas_ultimo[0]?.trafico, 0)} egoiliar hil ziren {urtean(causas_ultimo[0]?.anio)}"
        source="INE"
        direction="positive-down"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '090' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('esperanza_vida', 'mortalidad_infantil', 'gasto_sanitario_pc_ppa', 'medicos', 'camas', 'suicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'esperanza_vida')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'mortalidad_infantil')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gasto_sanitario_pc_ppa')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'medicos')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'camas')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'suicidios')} />


<p class="text-xs text-gray-500">Laguntza behar baduzu edo behar dezakeen norbait ezagutzen baduzu, deitu <b>024</b> zenbakira, jokabide suizidaren arretarako telefonora (doakoa, isilpekoa, 24 orduz).</p>

## Zenbat bizi garen

<LineChart
    data={ev_espana}
    x=anio
    y=anios
    series=sexo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#1d4ed8', '#be185d']}
    yAxisTitle="urteak"
    title="Bizi-itxaropena jaiotzean Espainian"
/>

<p class="text-xs text-gray-500">2020ko jaitsiera COVID-19aren pandemia da (bizi-itxaropenaren urtebete baino gehiago galdu zen); 2019ko maila ez zen berreskuratu 2023ra arte. Espainia munduko bizi-itxaropen handiena duten herrialdeen artean dago.</p>

```sql ev_provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, e.anios
FROM mother.salud_esperanza_vida e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.sexo = 'Ambos sexos'
  AND e.anio = (SELECT max(anio) FROM mother.salud_esperanza_vida WHERE nivel = 'provincia')
ORDER BY e.anios DESC
```

<AreaMap
    data={ev_provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="anios"
    valueFmt="num1"
    colorPalette={['#fef3c7', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'anios', title: 'Bizi-itxaropena (urteak)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Bizi-itxaropena jaiotzean bizileku-probintziaren arabera, {urtean(ev_ultimo[0]?.anio)}. Altuenak Madrilen eta iparraldeko barnealdean daude; baxuenak, hegoaldean, Kanarietan, Ceutan eta Melillan.</p>

## Zerk eragiten dizkigun heriotzak

```sql capitulos
SELECT causa, defunciones, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND es_capitulo AND codigo_causa <> '001-102'
  AND anio = (SELECT max(anio) FROM mother.salud_causas_muerte)
ORDER BY defunciones DESC
LIMIT 10
```

<BarChart
    data={capitulos}
    x=causa
    y=tasa_100k
    swapXY=true
    sort=false
    yFmt=num0
    yAxisTitle="100.000 biztanleko"
    fillColor="#0f766e"
    title="Heriotzak kausa-talde handien arabera, 100.000 biztanleko ({causas_ultimo[0]?.anio})"
/>

```sql evolucion_capitulos
SELECT anio, causa, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND codigo_causa IN ('009-041', '053-061', '062-067', '046-049', '090-102')
  AND anio >= 2000
ORDER BY anio
```

<LineChart
    data={evolucion_capitulos}
    x=anio
    y=tasa_100k
    series=causa
    yFmt=num0
    xFmt="####"
    legend=true
    yAxisTitle="100.000 biztanleko"
    title="Heriotza-kausa nagusiak 2000tik (tasa gordina)"
/>

<p class="text-xs text-gray-500">2024an, lehen aldiz, tumoreek bihotzeko eta odol-hodietako gaixotasunak gainditu zituzten lehen heriotza-kausa gisa. Buruko nahasmenduak batez ere dementziengatik hazten ari dira (alzheimerra eta beste batzuk), zahartzeari lotuta. Tasa gordinak: gero eta zaharragoa den biztanleriarekin, igo egiten dira adin bakoitzean hiltzeko probabilitatea jaitsi arren.</p>

## Suizidioak, trafikoa eta hilketak

```sql externas
SELECT anio,
    CASE codigo_causa WHEN '098' THEN 'Suicidios' WHEN '090' THEN 'Accidentes de tráfico' WHEN '099' THEN 'Homicidios' END AS causa,
    defunciones,
    tasa_100k
FROM ${causas_clave}
WHERE codigo_causa IN ('098', '090', '099') AND anio >= 1996
ORDER BY anio
```

<LineChart
    data={externas}
    x=anio
    y=tasa_100k
    series=causa
    yFmt=num1
    yAxisTitle="100.000 biztanleko"
    xFmt="####"
    legend=true
    colorPalette={['#f59e0b', '#7c3aed', '#b91c1c']}
    title="Suizidioz, trafiko-istripuz eta hilketaz izandako heriotzak, 100.000 biztanleko"
/>

<p class="text-xs text-gray-500">2008az geroztik, Espainian pertsona gehiago hiltzen dira suizidioz trafiko-istripuetan baino; azken horiek herenera baino gutxiagora jaitsi dira 2000tik. Zifrak hildakoaren bizilekuaren arabera eta heriotza-ziurtagiriko kausaren arabera daude (DGTren errepideko hildakoak, 30 egunera zenbatuak, zertxobait desberdinak dira).</p>

```sql suicidio_ccaa
SELECT c.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Total') AS tasa,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Hombres') AS tasa_hombres,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Mujeres') AS tasa_mujeres,
    max(c.defunciones) FILTER (WHERE c.sexo = 'Total') AS defunciones
FROM mother.salud_causas_muerte c
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod
WHERE c.nivel = 'ccaa' AND c.codigo_causa = '098' AND c.anio = (SELECT max(anio) FROM mother.salud_causas_muerte)
GROUP BY ALL
ORDER BY tasa DESC
```

<DataTable data={suicidio_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=defunciones title="Suizidioak" fmt=num0 />
    <Column id=tasa title="100.000 biz." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=tasa_hombres title="Gizonak" fmt=num1 />
    <Column id=tasa_mujeres title="Emakumeak" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Lau suizidiotik hiru gizonenak dira. Tasa altuenak ipar-mendebaldean daude (Asturias, Galizia), biztanleria zahartuagoarekin.</p>

## Gehiegizko hilkortasuna

<BarChart
    data={exceso_anual}
    x=anio
    y=exceso
    yFmt=pct0
    xFmt="####"
    fillColor="#b91c1c"
    title="Urte bakoitzeko heriotzak 2015-2019ko batez bestekoaren aldean"
/>

```sql semanal
SELECT semana, defunciones, media_2015_2019
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND semana >= (SELECT max(semana) FROM mother.salud_mortalidad_semanal) - INTERVAL 3 YEAR
ORDER BY semana
```

<LineChart
    data={semanal}
    x=semana
    y={['defunciones', 'media_2015_2019']}
    yFmt=num0
    seriesLabels={{defunciones: 'Heriotzak', media_2015_2019: 'Aste bereko batez bestekoa 2015-2019an'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Heriotzak astez aste (azken hiru urteak)"
/>

<p class="text-xs text-gray-500">2015-2019rekiko konparazioa sinplea da eta ez du zuzentzen biztanleria urtero zaharragoa eta ugariagoa dela; beraz, 2023tik "gehiegizko" horren zati bat zahartzea besterik ez da. Gailurrak neguko gripe-boladekin eta bero-boladekin bat datoz (ikus <a href="/eu/energia-clima/calor">Beroa</a>). Azken asteak osatu gabe egon daitezke.</p>

```sql san_le
SELECT fecha, CAST(anio AS INTEGER) AS anio, corte, tipo, pacientes, tasa_1000, pct_espera_larga, dias_medio
FROM mother.sanidad_listas_espera
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql san_le_ultimo
WITH q AS (SELECT * FROM mother.sanidad_listas_espera WHERE nivel = 'pais' AND tipo = 'quirurgica'),
c AS (SELECT * FROM mother.sanidad_listas_espera WHERE nivel = 'pais' AND tipo = 'consultas'),
uq AS (SELECT * FROM q WHERE fecha = (SELECT max(fecha) FROM q)),
aq AS (SELECT * FROM q WHERE fecha = (SELECT max(fecha) - INTERVAL 1 YEAR FROM q)),
pq AS (SELECT * FROM q WHERE fecha = (SELECT min(fecha) FROM q)),
uc AS (SELECT * FROM c WHERE fecha = (SELECT max(fecha) FROM c)),
ac AS (SELECT * FROM c WHERE fecha = (SELECT max(fecha) - INTERVAL 1 YEAR FROM c))
SELECT
    CASE WHEN uq.corte = 'junio' THEN '30 de junio de ' ELSE '31 de diciembre de ' END || CAST(uq.anio AS INTEGER) AS fecha_txt,
    CASE WHEN uq.corte = 'junio' THEN 'junio de ' ELSE 'diciembre de ' END || CAST(uq.anio - 1 AS INTEGER) AS fecha_ant_txt,
    uq.pacientes, uq.tasa_1000, uq.pct_espera_larga, uq.dias_medio,
    round(uq.tasa_1000 - aq.tasa_1000, 2) AS tasa_var,
    round(uq.dias_medio - aq.dias_medio, 0) AS dias_var,
    CAST(pq.anio AS INTEGER) AS anio_ini, pq.tasa_1000 AS tasa_ini, pq.dias_medio AS dias_ini, pq.pct_espera_larga AS pct_ini,
    uc.tasa_1000 AS c_tasa, uc.dias_medio AS c_dias, uc.pct_espera_larga AS c_pct,
    round(uc.dias_medio - ac.dias_medio, 0) AS c_dias_var
FROM uq, aq, pq, uc, ac
```

```sql san_le_dias
SELECT fecha,
    CASE tipo WHEN 'quirurgica' THEN 'Operación programada' ELSE 'Primera consulta con el especialista' END AS lista,
    dias_medio
FROM mother.sanidad_listas_espera
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql san_le_ccaa
SELECT t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    max(l.tasa_1000) FILTER (WHERE l.tipo = 'quirurgica') AS q_tasa,
    max(l.dias_medio) FILTER (WHERE l.tipo = 'quirurgica') AS q_dias,
    max(l.pct_espera_larga) FILTER (WHERE l.tipo = 'quirurgica') / 100 AS q_pct,
    max(l.tasa_1000) FILTER (WHERE l.tipo = 'consultas') AS c_tasa,
    max(l.dias_medio) FILTER (WHERE l.tipo = 'consultas') AS c_dias,
    max(l.pct_espera_larga) FILTER (WHERE l.tipo = 'consultas') / 100 AS c_pct
FROM mother.sanidad_listas_espera l
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = l.cod
WHERE l.nivel = 'ccaa' AND l.fecha = (SELECT max(fecha) FROM mother.sanidad_listas_espera)
GROUP BY ALL
ORDER BY q_dias DESC
```

```sql san_le_extremos
SELECT
    arg_max(comunidad, q_dias) AS max_com, max(q_dias) AS max_dias,
    arg_min(comunidad, q_dias) AS min_com, min(q_dias) AS min_dias
FROM ${san_le_ccaa}
```

```sql san_le_esp
SELECT especialidad, tasa_1000, pct_espera_larga / 100 AS pct, dias_medio
FROM mother.sanidad_listas_especialidad
WHERE tipo = 'quirurgica' AND fecha = (SELECT max(fecha) FROM mother.sanidad_listas_especialidad)
ORDER BY dias_medio DESC
```

```sql san_le_esp_cons
SELECT especialidad, tasa_1000, pct_espera_larga / 100 AS pct, dias_medio
FROM mother.sanidad_listas_especialidad
WHERE tipo = 'consultas' AND fecha = (SELECT max(fecha) FROM mother.sanidad_listas_especialidad)
ORDER BY dias_medio DESC
```

```sql san_rec
SELECT anio, geo, recurso,
    CASE recurso WHEN 'medicos' THEN 'Médicos' WHEN 'enfermeras' THEN 'Enfermeras' ELSE 'Camas' END
        || CASE WHEN geo = 'ES' THEN ' · España' ELSE ' · media UE-27' END AS serie,
    por_1000
FROM mother.sanidad_recursos
WHERE geo IN ('ES', 'UE') AND anio >= 2000
ORDER BY anio
```

```sql san_rec_ultimo
WITH es AS (SELECT recurso, max(anio) AS anio FROM mother.sanidad_recursos WHERE geo = 'ES' GROUP BY recurso)
SELECT e.recurso, CAST(e.anio AS INTEGER) AS anio, r.por_1000 AS es, r.numero AS numero_es, u.por_1000 AS ue, u.n_paises
FROM es e
JOIN mother.sanidad_recursos r ON r.geo = 'ES' AND r.recurso = e.recurso AND r.anio = e.anio
LEFT JOIN mother.sanidad_recursos u ON u.geo = 'UE' AND u.recurso = e.recurso AND u.anio = e.anio
```

```sql san_rec_paises
WITH ultimo AS (
    SELECT geo, recurso, max(anio) AS anio
    FROM mother.sanidad_recursos
    WHERE geo <> 'UE' AND anio <= (SELECT max(anio) FROM mother.sanidad_recursos WHERE geo = 'ES')
    GROUP BY ALL
)
SELECT r.pais,
    max(r.por_1000) FILTER (WHERE r.recurso = 'medicos') AS medicos,
    max(r.por_1000) FILTER (WHERE r.recurso = 'enfermeras') AS enfermeras,
    max(r.por_1000) FILTER (WHERE r.recurso = 'camas') AS camas,
    CAST(max(r.anio) AS INTEGER) AS anio
FROM mother.sanidad_recursos r
JOIN ultimo u ON u.geo = r.geo AND u.recurso = r.recurso AND u.anio = r.anio
GROUP BY ALL
ORDER BY medicos DESC NULLS LAST
```

```sql san_rec_rango
SELECT
    count(*) FILTER (WHERE enfermeras IS NOT NULL) AS n_enf,
    count(*) FILTER (WHERE enfermeras > (SELECT enfermeras FROM ${san_rec_paises} WHERE pais = 'España')) + 1 AS puesto_enf,
    count(*) FILTER (WHERE camas IS NOT NULL) AS n_camas,
    count(*) FILTER (WHERE camas > (SELECT camas FROM ${san_rec_paises} WHERE pais = 'España')) + 1 AS puesto_camas
FROM ${san_rec_paises}
```

```sql san_rec_ccaa
SELECT t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    max(r.por_1000) FILTER (WHERE r.recurso = 'medicos') AS medicos,
    max(r.por_1000) FILTER (WHERE r.recurso = 'camas') AS camas,
    CAST(max(r.anio) AS INTEGER) AS anio
FROM mother.sanidad_recursos_ccaa r
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = r.cod
WHERE r.nivel = 'ccaa' AND r.anio = (SELECT max(anio) FROM mother.sanidad_recursos_ccaa WHERE nivel = 'ccaa')
GROUP BY ALL
ORDER BY medicos DESC
```

```sql san_gasto_es
SELECT anio, financiacion, pct_pib, eur_hab_real, CAST(anio_base AS INTEGER) AS anio_base
FROM mother.sanidad_gasto
WHERE geo = 'ES'
ORDER BY anio
```

```sql san_gasto_ultimo
WITH es AS (SELECT * FROM mother.sanidad_gasto WHERE geo = 'ES'),
ue AS (SELECT * FROM mother.sanidad_gasto WHERE geo = 'UE'),
u AS (SELECT max(anio) AS anio FROM es WHERE financiacion = 'Total'),
uu AS (SELECT max(anio) AS anio FROM ue WHERE financiacion = 'Total')
SELECT
    CAST((SELECT anio FROM u) AS INTEGER) AS anio,
    CAST((SELECT anio FROM uu) AS INTEGER) AS anio_ue,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM u)) AS pub_real,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM u)) AS pub_pib,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM u)) AS tot_pib,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Pago directo de los hogares' AND es.anio = (SELECT anio FROM u)) AS hog_real,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Seguros voluntarios' AND es.anio = (SELECT anio FROM u)) AS seg_real,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM u)) AS tot_real,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM uu)) AS pub_pib_es_uu,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM uu)) AS tot_pib_es_uu,
    (SELECT pct_pib FROM ue WHERE financiacion = 'Público' AND anio = (SELECT anio FROM uu)) AS pub_pib_ue,
    (SELECT pct_pib FROM ue WHERE financiacion = 'Total' AND anio = (SELECT anio FROM uu)) AS tot_pib_ue,
    100 * max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM u))
        / max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM u)) AS pub_peso,
    CAST(max(es.anio_base) AS INTEGER) AS anio_base
FROM es
```

```sql san_gasto_pib
SELECT anio,
    CASE WHEN financiacion = 'Público' THEN 'Público' ELSE 'Privado' END || ' · ' || pais AS serie,
    sum(pct_pib) AS pct_pib
FROM mother.sanidad_gasto
WHERE geo IN ('ES', 'UE') AND financiacion IN ('Público', 'Seguros voluntarios', 'Pago directo de los hogares')
GROUP BY ALL
ORDER BY anio, serie
```

```sql san_gasto_paises
SELECT pais, pps_hab,
    CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'UE' THEN 'Media UE-27' ELSE 'Resto de países' END AS grupo
FROM mother.sanidad_gasto
WHERE financiacion = 'Total' AND pps_hab IS NOT NULL
  AND anio = (SELECT max(anio) FROM mother.sanidad_gasto WHERE geo = 'UE' AND financiacion = 'Total' AND pps_hab IS NOT NULL)
ORDER BY pps_hab DESC
```

```sql san_gasto_ccaa
SELECT t.nombre AS comunidad, '/eu' || t.ruta AS ruta, g.eur_hab_real, g.pct_pib / 100 AS pct_pib,
    g.eur_hab_real / b.eur_hab_real - 1 AS var_2019,
    CAST(g.anio AS INTEGER) AS anio, g.provisional
FROM mother.sanidad_gasto_ccaa g
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = g.cod
JOIN mother.sanidad_gasto_ccaa b ON b.cod = g.cod AND b.anio = 2019
WHERE g.nivel = 'ccaa' AND g.anio = (SELECT max(anio) FROM mother.sanidad_gasto_ccaa)
ORDER BY g.eur_hab_real DESC
```

```sql san_gasto_ccaa_total
SELECT CAST(g.anio AS INTEGER) AS anio, g.eur_hab_real, g.provisional,
    (SELECT max(eur_hab_real) FROM ${san_gasto_ccaa}) AS max_real,
    (SELECT min(eur_hab_real) FROM ${san_gasto_ccaa}) AS min_real,
    (SELECT arg_max(comunidad, eur_hab_real) FROM ${san_gasto_ccaa}) AS max_com,
    (SELECT arg_min(comunidad, eur_hab_real) FROM ${san_gasto_ccaa}) AS min_com
FROM mother.sanidad_gasto_ccaa g
WHERE g.nivel = 'total_ccaa' AND g.anio = (SELECT max(anio) FROM mother.sanidad_gasto_ccaa)
```

## Osasun-sistema

Zenbat itxaron behar den osasun publikoan ebakuntza egiteko edo espezialista ikusteko, zenbat mediku, erizain eta ohe dauden biztanleko eta zenbat gastatzen den osasunean, Europar Batasuneko gainerako herrialdeekin alderatuta.

<Grid cols=4>
    <KpiCard
        title="Kirurgiako itxaron-zerrenda"
        value={san_le_ultimo[0]?.tasa_1000}
        formattedValue="{formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} 1.000 biz."
        period="{formatNumber(san_le_ultimo[0]?.pacientes, 0)} paziente, {dataEu(san_le_ultimo[0]?.fecha_txt)}"
        change={san_le_ultimo[0]?.tasa_var}
        changeUnit=""
        changePeriod="urtebete lehenagorekiko"
        direction="positive-down"
        source="Osasun Ministerioa (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Ebakuntzarako batez besteko itxaronaldia"
        value={san_le_ultimo[0]?.dias_medio}
        formattedValue="{formatNumber(san_le_ultimo[0]?.dias_medio, 0)} egun"
        period="{formatNumber(san_le_ultimo[0]?.pct_espera_larga, 1)} % 6 hilabete baino gehiago daramatza"
        change={san_le_ultimo[0]?.dias_var}
        changeUnit="egun"
        changePeriod="urtebetean"
        direction="positive-down"
        source="Osasun Ministerioa (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Espezialistarako batez besteko itxaronaldia"
        value={san_le_ultimo[0]?.c_dias}
        formattedValue="{formatNumber(san_le_ultimo[0]?.c_dias, 0)} egun"
        period="lehen kontsulta · {formatNumber(san_le_ultimo[0]?.c_pct, 1)} % 60 egun baino gehiago itxaroten"
        change={san_le_ultimo[0]?.c_dias_var}
        changeUnit="egun"
        changePeriod="urtebetean"
        direction="positive-down"
        source="Osasun Ministerioa (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'consultas').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Osasun-gastu publikoa"
        value={san_gasto_ultimo[0]?.pub_real}
        formattedValue="{formatNumber(san_gasto_ultimo[0]?.pub_real, 0)} € biz."
        period="BPGaren {formatNumber(san_gasto_ultimo[0]?.pub_pib, 1)} % {urtean(san_gasto_ultimo[0]?.anio)} · {urteko(san_gasto_ultimo[0]?.anio_base)} euroak"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Público').map(d => ({valor: d.eur_hab_real}))}
    />
    <KpiCard
        title="Medikuak"
        value={san_rec_ultimo.find(d => d.recurso === 'medicos')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} 1.000 biz."
        period="EBko batez bestekoa: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.geo === 'ES' && d.recurso === 'medicos').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Erizainak"
        value={san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} 1.000 biz."
        period="EBko batez bestekoa: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.geo === 'ES' && d.recurso === 'enfermeras').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Ospitaleko oheak"
        value={san_rec_ultimo.find(d => d.recurso === 'camas')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} 1.000 biz."
        period="EBko batez bestekoa: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'camas')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.geo === 'ES' && d.recurso === 'camas').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Etxeen ordainketa zuzena"
        value={san_gasto_ultimo[0]?.hog_real}
        formattedValue="{formatNumber(san_gasto_ultimo[0]?.hog_real, 0)} € biz."
        period="beren poltsikotik {urtean(san_gasto_ultimo[0]?.anio)} (farmazia, dentista, kontsulta pribatuak...) · gehi {formatNumber(san_gasto_ultimo[0]?.seg_real, 0)} € aseguruetan"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Pago directo de los hogares').map(d => ({valor: d.eur_hab_real}))}
    />
</Grid>

### Itxaron-zerrendak

Osasun publikoan, {dataEu(san_le_ultimo[0]?.fecha_txt, true)}, {formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} pertsona zeuden 1.000 biztanleko programatutako ebakuntza baten zain; {urteko(san_le_ultimo[0]?.anio_ini)} abenduan, berriz, {formatNumber(san_le_ultimo[0]?.tasa_ini, 1)}. Batez besteko itxaronaldia {formatNumber(san_le_ultimo[0]?.dias_medio, 0)} egunekoa zen ebakuntza egiteko eta {formatNumber(san_le_ultimo[0]?.c_dias, 0)} egunekoa espezialistarekin lehen kontsulta izateko.

<BarChart
    data={san_le.filter(d => d.tipo === 'quirurgica')}
    x=fecha
    y=tasa_1000
    yFmt=num1
    fillColor="#0f766e"
    yAxisTitle="1.000 biztanleko"
    title="Kirurgiako itxaron-zerrendako pazienteak 1.000 biztanleko (ekainaren 30a eta abenduaren 31)"
/>

<LineChart
    data={san_le_dias}
    x=fecha
    y=dias_medio
    series=lista
    yFmt=num0
    legend=true
    colorPalette={['#0f766e', '#7c3aed']}
    yAxisTitle="egunak"
    title="Batez besteko itxaronaldia Osasun Sistema Nazionalean"
/>

<p class="text-xs text-gray-500">Egiturazko itxaronaldia: premiazkoa ez den ebakuntza baten edo arreta espezializatuko lehen kontsulta baten zain dauden pazienteak, itxaronaldia sistemaren antolaketari eta baliabideei egozten zaienean (ez du lehen mailako arreta barne hartzen). Batez besteko denbora da ebaketa-egunean zerrendan jarraitzen dutenek daramatena itxaroten; tasa osasun-txartela duen biztanleriaren gainean kalkulatzen da. Datuak erkidego bakoitzak ematen ditu eta Osasun Ministerioak batzen ditu; irizpide-aldaketak izan dira: 2016ko ekainera arte erkidego baten datuak estimatu egiten ziren, 2018an Andaluziak zenbaketa-sistema aldatu zuen (serie-haustura, ministerioaren arabera), eta 60 egunetik gorako kontsulten %-ak azken edizioetan oraindik hitzordurik ez duten pazienteak ere barne hartzen ditu. 2020ko gailurra COVID-19aren pandemiarekin bat dator.</p>

<DataTable data={san_le_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=q_tasa title="Ebakuntza: 1.000 biz." fmt=num1 />
    <Column id=q_dias title="Ebakuntza: egunak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=q_pct title="Ebakuntza: 6 hilabete baino gehiago" fmt=pct1 />
    <Column id=c_tasa title="Espezialista: 1.000 biz." fmt=num1 />
    <Column id=c_dias title="Espezialista: egunak" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=c_pct title="Espezialista: 60 egun baino gehiago" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Egoera: {dataEu(san_le_ultimo[0]?.fecha_txt)}. Ebakuntzarako batez besteko itxaronaldia {formatNumber(san_le_extremos[0]?.min_dias, 0)} egunetik ({san_le_extremos[0]?.min_com}) {formatNumber(san_le_extremos[0]?.max_dias, 0)} egunera ({san_le_extremos[0]?.max_com}) bitartekoa da. Erkidegoek ez dituzte pazienteak berdin zenbatzen (ministerioak ohartarazten du bakoitza bere datuen erantzule dela); beraz, haien arteko aldeak kontuz irakurri behar dira.</p>

<BarChart
    data={san_le_esp}
    x=especialidad
    y=dias_medio
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    yAxisTitle="egunak"
    title="Ebakuntzarako batez besteko itxaronaldia espezialitatearen arabera ({dataEu(san_le_ultimo[0]?.fecha_txt)})"
/>

<DataTable data={san_le_esp_cons} rows=all>
    <Column id=especialidad title="Kanpo-kontsultak: espezialitatea" />
    <Column id=tasa_1000 title="Pazienteak 1.000 biz." fmt=num2 />
    <Column id=dias_medio title="Itxaron-egunak" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=pct title="60 egun baino gehiago" fmt=pct1 />
</DataTable>

### Medikuak, erizainak eta oheak

<LineChart
    data={san_rec.filter(d => d.recurso !== 'camas')}
    x=anio
    y=por_1000
    series=serie
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#b45309', '#fcd34d', '#1d4ed8', '#93c5fd']}
    yAxisTitle="1.000 biztanleko"
    title="Jardunean dauden medikuak eta erizainak, 1.000 biztanleko: Espainia eta EBko batez bestekoa"
/>

<LineChart
    data={san_rec.filter(d => d.recurso === 'camas')}
    x=anio
    y=por_1000
    series=serie
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#94a3b8']}
    yAxisTitle="1.000 biztanleko"
    title="Ospitaleko oheak 1.000 biztanleko: Espainia eta EBko batez bestekoa"
/>

<p class="text-xs text-gray-500">{urtean(san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio)}, Espainiak {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} mediku zituen jardunean 1.000 biztanleko ({#if san_rec_ultimo.find(d => d.recurso === 'medicos')?.es > san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue}EBko batez bestekoaren gainetik{:else}EBko batez bestekoaren azpitik{/if}: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)}), {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} erizain (EBko batez bestekoa: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)}; datua duten {san_rec_rango[0]?.n_enf} herrialdeetatik {san_rec_rango[0]?.puesto_enf}. postua) eta {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} ospitale-ohe (EBko batez bestekoa: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)}; {san_rec_rango[0]?.n_camas} herrialdetatik {san_rec_rango[0]?.puesto_camas}. postua). EBko batez bestekoa biztanleriaren arabera haztatuta dago, eta gutxienez 24 herrialdek informazioa ematen duten urteetan baino ez da kalkulatzen; herrialde batek jardunean dauden langileak ematen ez dituenean, profesionalki aktiboak erabiltzen dira; beraz, konparazioak gutxi gorabeherakoak dira.</p>

<DataTable data={san_rec_paises} rows=all>
    <Column id=pais title="Herrialdea" />
    <Column id=medicos title="Medikuak 1.000 biz." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=enfermeras title="Erizainak 1.000 biz." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=camas title="Oheak 1.000 biz." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=anio title="Urtea" fmt="####" />
</DataTable>

<DataTable data={san_rec_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=medicos title="Medikuak 1.000 biz." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=camas title="Ospitale-oheak 1.000 biz." fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

<p class="text-xs text-gray-500">Medikuak eta oheak (publikoak eta pribatuak) erkidegoka, {urtean(san_rec_ccaa[0]?.anio)}, Eurostaten arabera. Erkidego bakoitzean kokatutako baliabideak zenbatzen dira, beste erkidego batzuetako pazienteak ere artatzen dituztenak.</p>

### Zenbat gastatzen den osasunean

Espainiako osasun-gastu osoa {formatNumber(san_gasto_ultimo[0]?.tot_real, 0)} euro izan zen biztanleko {urtean(san_gasto_ultimo[0]?.anio)} ({urteko(san_gasto_ultimo[0]?.anio_base)} euroak), BPGaren {formatNumber(san_gasto_ultimo[0]?.tot_pib, 1)} %. Administrazioek {formatNumber(san_gasto_ultimo[0]?.pub_peso, 0)} % ordaindu zuten; gainerakoa etxeen poltsikotik edo aseguru pribatuetatik atera zen. {urtean(san_gasto_ultimo[0]?.anio_ue)}, Europako datua duen azken urtean, gastu publikoa BPGaren {formatNumber(san_gasto_ultimo[0]?.pub_pib_es_uu, 1)} % izan zen Espainian eta {formatNumber(san_gasto_ultimo[0]?.pub_pib_ue, 1)} % EBko batez bestekoan.

<BarChart
    data={san_gasto_es.filter(d => d.financiacion !== 'Total')}
    x=anio
    y=eur_hab_real
    series=financiacion
    type=stacked
    xFmt="####"
    yFmt='#,##0" €"'
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    yAxisTitle="euro biztanleko"
    title="Osasun-gastua biztanleko, nork ordaintzen duen ({urteko(san_gasto_ultimo[0]?.anio_base)} euroak, inflazioa kenduta)"
/>

<LineChart
    data={san_gasto_pib}
    x=anio
    y=pct_pib
    series=serie
    yFmt='0.0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#b45309', '#fcd34d', '#0f766e', '#99f6e4']}
    yAxisTitle="BPGaren %"
    title="Osasun-gastu publikoa eta pribatua BPGaren ehunekotan: Espainia eta EB-27"
/>

<BarChart
    data={san_gasto_paises}
    x=pais
    y=pps_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#94a3b8', '#b91c1c', '#1d4ed8']}
    yAxisTitle="PPS biztanleko"
    title="Osasun-gastu osoa biztanleko EBn ({san_gasto_ultimo[0]?.anio_ue}, erosteko ahalmenaren parekotasunean)"
/>

<p class="text-xs text-gray-500">Uneko osasun-gastua, Eurostaten osasun-kontuen arabera (SHA 2011). Publikoak administrazioak eta derrigorrezko gizarte-aseguruak barne hartzen ditu (funtzionarioen mutualitateak ere bai); pribatuak, borondatezko aseguruak eta etxeen ordainketa zuzena. Herrialdeen arteko konparazioak erosteko ahalmenaren parekotasuna (PPS) erabiltzen du, prezio-aldeak kentzen dituena.</p>

<DataTable data={san_gasto_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=eur_hab_real title="Osasun-gastu publikoa biztanleko (€)" fmt='#,##0' contentType=bar barColor="#99f6e4" />
    <Column id=pct_pib title="Eskualdeko BPGaren %" fmt=pct1 />
    <Column id=var_2019 title="Aldaketa erreala 2019tik" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Autonomia-erkidego bakoitzeko osasun-gastua biztanleko, {urtean(san_gasto_ccaa_total[0]?.anio)}{#if san_gasto_ccaa_total[0]?.provisional} (behin-behineko zifrak){/if}, {urteko(san_gasto_ultimo[0]?.anio_base)} eurotan: {formatNumber(san_gasto_ccaa_total[0]?.min_real, 0)} €-tik ({san_gasto_ccaa_total[0]?.min_com}) {formatNumber(san_gasto_ccaa_total[0]?.max_real, 0)} €-ra ({san_gasto_ccaa_total[0]?.max_com}); {formatNumber(san_gasto_ccaa_total[0]?.eur_hab_real, 0)} € erkidego guztietan batera. Autonomia-erkidegoetako osasun-zerbitzuen gastua da (Osasun Ministerioaren Osasun Gastu Publikoaren Estatistika), osasun-gastu publikoaren 90 % baino gehiago; ez ditu barne hartzen funtzionarioen mutualitateak ezta udalak ere. Ceuta eta Melilla ez dira agertzen, haien osasuna Estatuak kudeatzen duelako (INGESA).</p>

---

## Iturriak eta oharrak

- **[INE – Oinarrizko adierazle demografikoak](https://www.ine.es/jaxiT3/Tabla.htm?t=1448)**: bizi-itxaropena jaiotzean erkidegoka (1448 taula) eta probintziaka (1485); **[Eurostat – demo_mlexpec](https://ec.europa.eu/eurostat/databrowser/view/demo_mlexpec/default/table)** Espainia osorako.
- **[INE – Heriotzak heriotza-kausaren arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=9936)** (9936 taula, kausen zerrenda laburtua bizileku-probintziaren arabera, 1980tik; argitaratutako azken urtea behin betikoa da urtebeteko atzerapenarekin).
- **[INE – Asteko Heriotzen Estimazioa (EDeS)](https://www.ine.es/jaxiT3/Tabla.htm?t=35177)** (35177 taula): heriotzak asteka eta erkidegoka.
- **[Osasun Ministerioa – OSNko itxaron-zerrendak (SISLE-SNS)](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm)**: kirurgiako eta kanpo-kontsultetako itxaron-zerrendei buruzko sei hilean behingo txostenak (ekainaren 30a eta abenduaren 31), erkidego eta espezialitatearen arabera, 2013ko abendutik ([historikoa](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEsperaInfAnt.htm)). Ministerioak PDFn baino ez ditu argitaratzen; zifrak haien tauletatik irakurtzen dira.
- **[Osasun Ministerioa – Osasun Gastu Publikoaren Estatistika](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)**: osasun-gastu publikoa autonomia-erkidegoka (euro biztanleko eta BPGaren %, I.1 eta I.2 eranskinak).
- **[Eurostat – hlth_rs_prs2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_prs2/default/table)** (medikuak eta erizainak), **[hlth_rs_bds1](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bds1/default/table)** (ospitale-oheak), **[hlth_rs_physreg](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_physreg/default/table)** eta **[hlth_rs_bdsrg2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bdsrg2/default/table)** (erkidegoka) eta **[hlth_sha11_hf](https://ec.europa.eu/eurostat/databrowser/view/hlth_sha11_hf/default/table)** (osasun-gastua finantzaketa-iturriaren arabera). Espainiako biztanleko euroei inflazioa kentzen zaie INEren KPIarekin.
- Administrazioen gastu osoaren barruko osasun-gastua hemen dago: [Gastu publikoak](/eu/cuentas-publicas/gastos).

<LastRefreshed prefix="Datuak eguneratuta" />
