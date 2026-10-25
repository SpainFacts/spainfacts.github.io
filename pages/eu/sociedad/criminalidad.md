---
title: Kriminalitatea
description: "Espainian ezagututako delituak motaren, erkidegoaren, probintziaren eta udalerriaren arabera 2010etik, zibergaizkileriaren bilakaera eta kondenatuak nazionalitatearen arabera, haien testuinguruarekin."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 7a9a98e7cc4a
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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
</script>

```sql espana
SELECT anio, categoria, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais'
ORDER BY anio
```

```sql resumen
WITH u AS (SELECT max(anio) AS anio FROM ${espana})
SELECT
    u.anio,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS total,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS tasa,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = 2019) AS total_2019,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) AS homicidios,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) * 100 AS homicidios_100k,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Cibercriminalidad' AND e.anio = u.anio) AS ciber
FROM ${espana} e, u
GROUP BY u.anio
```

```sql serie_kpi
-- Historia para los sparklines, en tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018)
WITH b AS (
    SELECT anio, categoria, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria IN ('Total infracciones penales', 'Homicidios y asesinatos consumados')
),
l AS (
    SELECT
        anio,
        CASE WHEN tipologia = 'TOTAL INFRACCIONES PENALES' THEN 'Total infracciones penales' ELSE 'Homicidios y asesinatos consumados' END AS categoria,
        max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND (tipologia = 'TOTAL INFRACCIONES PENALES' OR codigo_tipologia = '1.1.1')
    GROUP BY 1, 2
)
SELECT anio, categoria, tasa_1000 FROM b
UNION ALL
SELECT anio, categoria, tasa_1000 FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY categoria, anio
```

```sql semestre
SELECT periodo, anio, infracciones, infracciones_anio_anterior, variacion_pct / 100 AS variacion
FROM mother.crimen_ultimo_periodo
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
```

# 🚨 Kriminalitatea

Polizia Nazionalak, Guardia Civilek, Mossos d'Esquadrak, Ertzaintzak, Nafarroako Foruzaingoak eta udaltzaingoek ezagutzen dituzten delituak, Barne Ministerioaren arabera.

<Grid cols=4>
    <KpiCard
        title="Arau-hauste penal ezagunak"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(resumen[0]?.tasa, 1)} 1.000 biz."
        period="{formatCompact(resumen[0]?.total, 2)} guztira · {resumen[0]?.anio}"
        change={resumen[0]?.total_2019 ? (100 * (resumen[0].total / resumen[0].total_2019 - 1)).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="2019arekiko"
        direction="positive-down"
        source="Barne Ministerioa"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => ({...d, y: d.tasa_1000}))}
    />
    <KpiCard
        title="Hilketak eta erailketak"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} 100.000 biz."
        period="{formatNumber(resumen[0]?.homicidios, 0)} burutuak, {urtean(resumen[0]?.anio)}"
        source="Barne Ministerioa"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => ({...d, y: d.tasa_1000 * 100}))}
    />
    <KpiCard
        title="Zibergaizkileria"
        value={resumen[0]?.ciber}
        formattedValue="{formatNumber(resumen[0]?.ciber / resumen[0]?.total / 0.01, 0)} %"
        period="{formatNumber(resumen[0]?.ciber / 1000, 0)} mila arau-hauste internet bidez, batez ere iruzurrak"
        source="Barne Ministerioa"
        sparklineData={espana.filter(d => d.categoria === 'Cibercriminalidad').map(d => 100 * d.infracciones / (espana.find(t => t.anio === d.anio && t.categoria === 'Total infracciones penales')?.infracciones ?? NaN)).filter(v => Number.isFinite(v))}
    />
    <KpiCard
        title="Aurten ({semestre[0]?.periodo})"
        value={semestre[0]?.infracciones}
        formattedValue={formatCompact(semestre[0]?.infracciones, 2)}
        change={semestre[0]?.variacion != null ? (100 * semestre[0].variacion).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="{urteko(semestre[0]?.anio - 1)} aldi berarekiko"
        direction="positive-down"
        source="Kriminalitate Balantzea"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('homicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'homicidios')} />


<p class="text-xs text-gray-500">Zifra guztiak biztanleko ematen dira, bilakaerak biztanleriaren hazkundea soilik isla ez dezan (Espainiak 2 milioi biztanle inguru irabazi zituen 2019 eta 2025 artean); guztizkoa bigarren mailako datu gisa agertzen da. Gertaera <b>ezagunak</b> dira (salatuak edo poliziak aurkituak), ez egindako delitu guztiak: igoera bat gehiago salatzen delako gerta daiteke (sexu-delituekin edo interneteko iruzurrekin gertatu den bezala). Biztanleko tasak ez ditu kontuan hartzen turistak eta bisitariak, delituak jasan eta egiten dituztenak ere: horregatik ateratzen da altua gune turistikoenetan.</p>

## Zer delitu eta nola aldatzen diren

```sql categorias
SELECT categoria, infracciones, tasa_1000 * 100 AS tasa_100k
FROM ${espana}
WHERE anio = (SELECT max(anio) FROM ${espana})
  AND categoria NOT IN ('Total infracciones penales', 'Criminalidad convencional', 'Cibercriminalidad', 'Resto de infracciones',
                        'Robos con fuerza en domicilios', 'Delitos contra la libertad sexual')
ORDER BY infracciones DESC
```

<BarChart
    data={categorias}
    x=categoria
    y=tasa_100k
    swapXY=true
    sort=false
    yFmt=num0
    yAxisTitle="100.000 biztanleko"
    fillColor="#b91c1c"
    title="{urteko(resumen[0]?.anio)} delitu ezagun nagusiak, 100.000 biztanleko"
/>

```sql convencional_ciber
SELECT anio, categoria, infracciones, tasa_1000
FROM ${espana}
WHERE categoria IN ('Criminalidad convencional', 'Cibercriminalidad')
ORDER BY anio
```

<BarChart
    data={convencional_ciber}
    x=anio
    y=tasa_1000
    series=categoria
    type=stacked
    yFmt=num1
    yAxisTitle="1.000 biztanleko"
    xFmt="####"
    colorPalette={['#b91c1c', '#7c3aed']}
    title="Ohiko kriminalitatea eta internet bidezkoa, 1.000 biztanleko"
/>

<p class="text-xs text-gray-500">2020 konfinamenduaren urtea da. 2019tik, Ministerioak bereiz zenbatzen du zibergaizkileria (internet bidez egindako iruzurrak eta beste delitu batzuk), gainerakoak baino askoz gehiago hazi dena.</p>

```sql serie_larga
SELECT anio, tipologia, infracciones, tasa_1000 * 100 AS tasa_100k
FROM mother.crimen_serie_larga
WHERE nivel = 'pais' AND codigo_tipologia IN ('1.1.1', '3.2', '5.1', '5.2.2', '5.3', '5.5.1', '6.1')
ORDER BY anio
```

<LineChart
    data={serie_larga}
    x=anio
    y=tasa_100k
    series=tipologia
    yFmt=num1
    yAxisTitle="100.000 biztanleko"
    xFmt="####"
    yLog=true
    legend=true
    title="Zenbait delitu 2010etik, 100.000 biztanleko (eskala logaritmikoa)"
/>

<p class="text-xs text-gray-500">Eskala logaritmikoa, kopuruz oso desberdinak diren delituak elkarrekin ikusteko: malda berak hazkunde-erritmo bera adierazten du. Iruzur informatikoak asko ugaritu dira 2016tik, etxebizitzetako lapurretak jaitsi egin dira eta sartze bidezko sexu-eraso ezagunak gehitu egin dira, neurri batean gehiago salatzen direlako.</p>

## Europan eta munduan Espainia

```sql mundo_ultimo
WITH u AS (
    SELECT delito_id, cod_pais, max(anio) AS anio
    FROM mother.crimen_mundo_delitos
    WHERE anio >= (SELECT max(anio) FROM mother.crimen_mundo_delitos) - 6
    GROUP BY ALL
)
SELECT m.*
FROM mother.crimen_mundo_delitos m
JOIN u USING (delito_id, cod_pais, anio)
```

```sql mundo_espana
WITH r AS (
    SELECT *, rank() OVER (PARTITION BY delito_id ORDER BY por_100k_hab) AS puesto_mundo,
           count(*) OVER (PARTITION BY delito_id) AS paises_mundo
    FROM ${mundo_ultimo}
),
e AS (
    SELECT delito_id, cod_pais, rank() OVER (PARTITION BY delito_id ORDER BY por_100k_hab) AS puesto_ue,
           count(*) OVER (PARTITION BY delito_id) AS paises_ue
    FROM ${mundo_ultimo}
    WHERE es_ue
),
m AS (
    SELECT delito_id,
           median(por_100k_hab) FILTER (WHERE es_ue) AS mediana_ue,
           median(por_100k_hab) FILTER (WHERE es_ocde) AS mediana_ocde
    FROM ${mundo_ultimo}
    GROUP BY delito_id
)
SELECT r.delito, r.orden, r.anio, r.por_100k_hab AS espana, m.mediana_ue, m.mediana_ocde,
       r.por_100k_hab / m.mediana_ue AS veces_ue,
       e.puesto_ue, e.paises_ue, r.puesto_mundo, r.paises_mundo,
       e.puesto_ue || ' de ' || e.paises_ue AS puesto_ue_texto,
       r.puesto_mundo || ' de ' || r.paises_mundo AS puesto_mundo_texto
FROM r
JOIN e USING (delito_id, cod_pais)
JOIN m USING (delito_id)
WHERE r.cod_pais = 'ES'
ORDER BY r.orden
```

```sql mundo_resumen
SELECT
    max(espana) FILTER (WHERE orden = 1) AS homicidios,
    max(anio) FILTER (WHERE orden = 1) AS homicidios_anio,
    max(mediana_ue) FILTER (WHERE orden = 1) AS homicidios_ue,
    max(puesto_mundo) FILTER (WHERE orden = 1) AS homicidios_puesto,
    max(paises_mundo) FILTER (WHERE orden = 1) AS homicidios_paises,
    max(puesto_ue) FILTER (WHERE orden = 1) AS homicidios_puesto_ue,
    max(espana) FILTER (WHERE orden = 16) AS presos,
    max(mediana_ue) FILTER (WHERE orden = 16) AS presos_ue,
    count(*) FILTER (WHERE veces_ue < 1 AND orden NOT IN (1, 16)) AS por_debajo,
    count(*) FILTER (WHERE veces_ue >= 1 AND orden NOT IN (1, 16)) AS por_encima
FROM ${mundo_espana}
```

```sql delitos_lista
SELECT DISTINCT delito, orden FROM ${mundo_ultimo} ORDER BY orden
```

```sql mundo_ranking
SELECT pais, por_100k_hab, anio,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM ${mundo_ultimo}
WHERE delito = '${inputs.delito_mundo.value}' AND (es_europa OR es_ocde)
ORDER BY por_100k_hab DESC
```

```sql mundo_serie
SELECT pais, anio, por_100k_hab
FROM mother.crimen_mundo_delitos
WHERE delito = '${inputs.delito_mundo.value}'
  AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'GB', 'US', 'SE')
  AND anio >= 2005
ORDER BY anio
```

Homizidioak herrialdeen artean alderatzeko zifrarik onena dira, eta horietan Espainia munduko kasu gutxien dituzten herrialdeen artean dago: 100.000 biztanleko {formatNumber(mundo_resumen[0]?.homicidios, 1)}, {urtean(mundo_resumen[0]?.homicidios_anio)} (EBko mediana: {formatNumber(mundo_resumen[0]?.homicidios_ue, 1)}). {mundo_resumen[0]?.homicidios_paises} herrialdetatik {mundo_resumen[0]?.homicidios_puesto}. postuan dago, eta EBn {mundo_resumen[0]?.homicidios_puesto_ue}. postuan, txikienetik hasita. Poliziak erregistratzen dituen gainerako delituetan, Espainia EBko medianaren azpitik dago {mundo_resumen[0]?.por_debajo} delitutan eta gainetik {mundo_resumen[0]?.por_encima} delitutan. 100.000 biztanleko {formatNumber(mundo_resumen[0]?.presos, 0)} preso ditu (EBko mediana: {formatNumber(mundo_resumen[0]?.presos_ue, 0)}).

<DataTable data={mundo_espana} rows=all>
    <Column id=delito title="Delitua" />
    <Column id=anio title="Urtea" fmt="####" />
    <Column id=espana title="Espainia" fmt=num1 />
    <Column id=mediana_ue title="EBko mediana" fmt=num1 />
    <Column id=mediana_ocde title="OECDko mediana" fmt=num1 />
    <Column id=veces_ue title="Espainia / EBko mediana" fmt='0.0"×"' />
    <Column id=puesto_ue_texto title="Postua EBn" />
    <Column id=puesto_mundo_texto title="Postua munduan" />
</DataTable>

<p class="text-xs text-gray-500">100.000 biztanleko, herrialde bakoitzaren azken urtea, azken zazpien artean. 1. postua = gutxien duen herrialdea. Herrialde bakoitzak Nazio Batuei (UNODC) jakinarazten dizkion poliziak erregistratutako delituak (Europan Eurostatek erabiltzen duen bilketa bera da); homizidioak, Munduko Bankuarenak, UNODCren datuekin; presoak, UNODCrenak.</p>

<Dropdown data={delitos_lista} name=delito_mundo value=delito title="Delitua" defaultValue="Homicidios intencionados" />

<BarChart
    data={mundo_ranking}
    x=pais
    y=por_100k_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="100.000 biztanleko"
    title="{inputs.delito_mundo.value}: Europako eta OECDko herrialdeak (herrialde bakoitzaren azken urtea)"
/>

<LineChart
    data={mundo_serie}
    x=anio
    y=por_100k_hab
    series=pais
    yFmt=num1
    xFmt="####"
    legend=true
    yMin=0
    yAxisTitle="100.000 biztanleko"
    title="{inputs.delito_mundo.value}: bilakaera Espainian eta beste herrialde batzuetan"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Zergatik alderatu behar den kontuz</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Homizidioak dira zifrarik fidagarriena</b>: ia beti erregistratzen dira, eta definizioa antzekoa da toki guztietan.</li>
<li><b>Gainerakoak erregistratutako delituak dira, ez egindakoak.</b> Zenbat salatzen den eta herrialde bakoitzak nola zenbatzen duen eragiten die. Jendeak poliziarengan konfiantza gehiago duen tokian edo aseguruak salaketa eskatzen duen tokian, salaketa gehiago egiten dira (horregatik erregistratzen dituzte herrialde nordikoek lapurreta txiki asko).</li>
<li><b>Definizioak aldatu egiten dira.</b> Espainian, indarrez edo beldurtuz egindako lapurretak eskuratzeko tirakadak barne hartzen ditu; beste herrialde batzuetan, lapurreta txiki gisa zenbatu daitezke. Suediak Europako bortxaketaren definiziorik zabalenetakoa du. Espainiak interneteko iruzur-salaketa bakoitza iruzur gisa erregistratzen du, eta horiek asko hazi dira 2019tik.</li>
<li><b>Ustelkeria edo dirua zuritzeko kasu erregistratu gutxi ez dira ustelkeria gutxi</b>: batez ere zenbat ikertzen den neurtzen dute.</li>
<li>Ez dago herrialdeen artean alderagarria den delitu-guztizkorik: herrialde bakoitzak falta eta delitu arin desberdinak sartzen ditu. Horregatik delitu bakoitza bere aldetik alderatzen da.</li>
</ul>
</div>

## Lurraldearen arabera

```sql ccaa
SELECT b.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = b.cod
WHERE b.nivel = 'ccaa' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
ORDER BY b.tasa_1000 DESC
```

```sql provincias
SELECT b.cod, t.nombre AS provincia, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = b.cod
WHERE b.nivel = 'provincia' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
```

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod"
    value="tasa_1000"
    valueFmt="num1"
    colorPalette={['#fef2f2', '#f87171', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Barne Ministerioa"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_1000', title: 'Arau-hausteak 1.000 biz.', fmt: 'num1'},
        {id: 'infracciones', title: 'Arau-hausteak', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=infracciones title="Arau-hauste ezagunak" fmt=num0 />
    <Column id=tasa_1000 title="1.000 biz." fmt=num1 contentType=bar barColor="#fecaca" />
</DataTable>

```sql municipios
WITH u AS (SELECT max(anio) AS anio FROM mother.crimen_balance WHERE nivel = 'municipio')
SELECT
    b.cod AS cod_mun,
    b.nombre AS municipio,
    p.nombre AS provincia,
    b.poblacion,
    max(b.infracciones) FILTER (WHERE b.categoria = 'Total infracciones penales') AS infracciones,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Total infracciones penales') AS tasa_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Hurtos') AS hurtos_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con violencia o intimidación') AS robos_violencia_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con fuerza en domicilios') AS robos_domicilios_1000,
    '/eu/territorios/municipios?m=' || b.cod AS enlace
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = left(b.cod, 2)
WHERE b.nivel = 'municipio'
GROUP BY ALL
ORDER BY tasa_1000 DESC
```

### 20.000 biztanletik gorako udalerriak ({resumen[0]?.anio})

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=tasa_1000 title="Arau-hausteak 1.000 biz." fmt=num1 contentType=bar barColor="#fecaca" />
    <Column id=hurtos_1000 title="Ebasketak" fmt=num1 />
    <Column id=robos_violencia_1000 title="Lapurreta bortitzak" fmt=num1 />
    <Column id=robos_domicilios_1000 title="Etxebizitzetako lapurretak" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Zerrendaren buruan aireportua, portua edo turismo handia duten udalerriak daude (El Prat de Llobregat, Adeje, Sant Josep de sa Talaia, Calvià...): han bisitarien eta bidaiarien aurkako delitu asko salatzen dira, baina tasa erroldatutako bizilagunen artean baino ez da zatitzen. Tasak, erroldatutako 1.000 biztanleko.</p>

## Kondenatuak nazionalitatearen arabera

```sql condenados
SELECT anio, sexo, nacionalidad, condenados, poblacion_18, tasa_1000
FROM mother.crimen_condenados
WHERE nivel = 'pais' AND nacionalidad IN ('Española', 'Extranjera')
ORDER BY anio
```

```sql condenados_ultimo
SELECT
    max(anio) AS anio,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS extranjeros,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS espanoles,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS pob_extranjera,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS pob_espanola,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Extranjera') AS h_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Española') AS h_esp,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Extranjera') AS m_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Española') AS m_esp,
    100.0 * max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(condenados) FILTER (WHERE sexo = 'Total') AS pct_condenados_extranjeros,
    100.0 * max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(poblacion_18) FILTER (WHERE sexo = 'Total') AS pct_poblacion_extranjera
FROM ${condenados}
WHERE anio = (SELECT max(anio) FROM ${condenados})
```

INEren Kondenatuen Estatistikaren arabera, {urtean(condenados_ultimo[0]?.anio)} Espainiako nazionalitateko {formatNumber(condenados_ultimo[0]?.espanoles, 0)} heldu eta atzerriko nazionalitateko {formatNumber(condenados_ultimo[0]?.extranjeros, 0)} kondenatu zituzten epai irmoz (guztizkoaren {formatNumber(condenados_ultimo[0]?.pct_condenados_extranjeros, 0)} %), atzerritarrak egoiliar helduen {formatNumber(condenados_ultimo[0]?.pct_poblacion_extranjera, 0)} % diren bitartean.

```sql tasas_sexo
SELECT anio, sexo || ', ' || lower(nacionalidad) AS grupo, tasa_1000
FROM ${condenados}
WHERE sexo IN ('Hombres', 'Mujeres')
ORDER BY anio
```

<LineChart
    data={tasas_sexo}
    x=anio
    y=tasa_1000
    series=grupo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="kondenatuak 18+ urteko 1.000 egoiliarreko"
    title="Kondenatuak, sexu eta nazionalitate bereko 1.000 egoiliar heldu bakoitzeko"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Nola irakurri konparazio hau</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Atzerritarren tasa gainestimatuta dago.</b> Atzerriko nazionalitateko kondenatuen artean turistak eta igarotzen ari diren pertsonak daude, Espainian bizi ez direnak: zenbakitzailean daude, baina ez izendatzailean, hark egoiliarrak baino ez baititu zenbatzen. Egoera irregularreko atzerritarrak, aldiz, izendatzailean egon ohi dira, errolda ez baitu egoitza-baimenik eskatzen.</li>
<li><b>Adinak eta sexuak asko eragiten dute.</b> Edozein herrialdetan, kondenatu gehienak gizon gazteak dira, eta atzerritar biztanleriak gizon gazte gehiago ditu espainiarrak baino. Horregatik, hemen gizonak gizonekin eta emakumeak emakumeekin alderatzen dira (gizonetan, milako {formatNumber(condenados_ultimo[0]?.h_ext, 1)} atzerritarrak eta {formatNumber(condenados_ultimo[0]?.h_esp, 1)} espainiarrak; emakumeetan, {formatNumber(condenados_ultimo[0]?.m_ext, 1)} eta {formatNumber(condenados_ultimo[0]?.m_esp, 1)}). Jarraian, adinaren eta Espainian bizi ez diren atzerritarren arabera ere doitzen da.</li>
<li><b>Beste faktore batzuk</b>, estatistika honek jasotzen ez dituenak eta azterlanetan aldearen zati bat azaltzen dutenak: errenta-maila, enplegua, ikasketa-maila edo bizilekuko auzoa.</li>
<li>Kondenatutako pertsonak dira, ez atxilotuak edo ikertuak: epaiketa bat egin da jada. Kondena ematen duen epaitegiaren erkidegoan zenbatzen da.</li>
</ul>
</div>

### Adinaren, sexuaren eta Espainian bizi ez diren atzerritarren arabera doituz

```sql ajuste
SELECT anio, orden, ajuste, espanoles_por_1000_hab, extranjeros_por_1000_hab, veces,
       condenados_extranjeros, poblacion_extranjera_18, no_residentes_presentes
FROM mother.crimen_condenados_ajuste
WHERE procedencia = 'Total'
ORDER BY anio, orden
```

```sql ajuste_ultimo
SELECT
    max(anio) AS anio,
    max(veces) FILTER (WHERE orden = 1) AS v1,
    max(veces) FILTER (WHERE orden = 2) AS v2,
    max(veces) FILTER (WHERE orden = 3) AS v3,
    max(espanoles_por_1000_hab) FILTER (WHERE orden = 1) AS esp1,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 1) AS ext1,
    max(espanoles_por_1000_hab) FILTER (WHERE orden = 2) AS esp2,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 2) AS ext2,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 3) AS ext3,
    max(poblacion_extranjera_18) AS pob_ext,
    max(no_residentes_presentes) AS visitantes
FROM ${ajuste}
WHERE anio = (SELECT max(anio) FROM ${ajuste})
```

```sql ajuste_barras
SELECT ajuste, veces
FROM ${ajuste}
WHERE anio = (SELECT max(anio) FROM ${ajuste})
ORDER BY orden
```

```sql edad_estructura
SELECT
    100.0 * sum(poblacion) FILTER (WHERE nacionalidad = 'Extranjera' AND edad_desde <= 26) / sum(poblacion) FILTER (WHERE nacionalidad = 'Extranjera') AS ext_jovenes,
    100.0 * sum(poblacion) FILTER (WHERE nacionalidad = 'Española' AND edad_desde <= 26) / sum(poblacion) FILTER (WHERE nacionalidad = 'Española') AS esp_jovenes
FROM mother.crimen_condenados_edad
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenados_edad) AND procedencia IN ('España', 'Total')
```

```sql tasas_edad
SELECT replace(replace(replace(tramo_edad, 'De ', ''), ' años', ''), ' a ', '-') AS edad, edad_desde, sexo || ', ' || lower(nacionalidad) AS grupo, condenados_por_1000_hab
FROM mother.crimen_condenados_edad
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenados_edad) AND procedencia IN ('España', 'Total')
ORDER BY edad_desde, grupo
```

INEk kondenatuak sexuaren, adinaren eta nazionalitatearen arabera batera argitaratzen ditu, beraz talde bakoitza bere pareekin alderatu daiteke. Egin daitezkeen doikuntza guztiekin, {urtean(ajuste_ultimo[0]?.anio)} atzerritar helduen kondenatu-tasa espainiarrenaren {formatNumber(ajuste_ultimo[0]?.v1, 1)} halakoa izatetik {formatNumber(ajuste_ultimo[0]?.v3, 1)} halakoa izatera igarotzen da.

<BarChart
    data={ajuste_barras}
    x=ajuste
    y=veces
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    labels=true
    fillColor="#b91c1c"
    yAxisTitle="espainiarren tasaren halako"
    title="Atzerritarren kondenatu-tasa zenbat halako handiagoa den, doikuntzaren arabera ({ajuste_ultimo[0]?.anio})"
/>

<BarChart
    data={tasas_edad}
    x=edad
    y=condenados_por_1000_hab
    series=grupo
    type=grouped
    sort=false
    yFmt=num1
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="kondenatuak 1.000 egoiliarreko"
    title="Kondenatuak, sexu, adin eta nazionalitate bereko 1.000 egoiliar bakoitzeko ({ajuste_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">Adin guztietan atzerritarren tasa altuagoa da, baina aldea handiagoa da gazteen artean eta adinarekin murrizten da. Atzerritar helduen % {formatNumber(edad_estructura[0]?.ext_jovenes, 0)} 18 eta 30 urte artekoa da, espainiar helduen % {formatNumber(edad_estructura[0]?.esp_jovenes, 0)}ren aldean.</p>

<LineChart
    data={ajuste}
    x=anio
    y=veces
    series=ajuste
    yFmt='0.0"×"'
    xFmt="####"
    legend=true
    yMin=0
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="espainiarren tasaren halako"
    title="Atzerritarren kondenatu-tasa espainiarrenarekin alderatuta, doikuntza bakoitzarekin"
/>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Zer doitu den eta nola</p>
<ol class="list-decimal ml-5 space-y-1">
<li><b>Doitu gabe</b> ({formatNumber(ajuste_ultimo[0]?.v1, 1)} halako): urte erdian 18 urteko edo gehiagoko egoiliarren artean kondenatuak ({formatNumber(ajuste_ultimo[0]?.ext1, 1)} atzerritar milako, {formatNumber(ajuste_ultimo[0]?.esp1, 1)} espainiar milako). Goiko zifra da, baina urtarrilaren 1eko biztanleria erabili beharrean urte erdikoa hartuta, kondenatuak urte osoan zehar zenbatzen direlako eta atzerritar biztanleria azkar hazten delako.</li>
<li><b>Adina eta sexua</b> ({formatNumber(ajuste_ultimo[0]?.v2, 1)} halako): sexu- eta adin-talde bakoitzaren tasa kalkulatzen da (18 eta 20 urte arteko gizonak, 21 eta 25 urte arteko emakumeak...) eta berriz osatzen da espainiarrek eta atzerritarrek piramide bera balute bezala: {urtean(ajuste_ultimo[0]?.anio)} Espainiako biztanleria heldu osoarena. Horrela, milako {formatNumber(ajuste_ultimo[0]?.ext2, 1)} geratzen dira atzerritarrentzat eta {formatNumber(ajuste_ultimo[0]?.esp2, 1)} espainiarrentzat. Doikuntza honek atzerritarrak gazteagoak izateak eta gizon gehiago egoteak eragindako aldearen zatia baino ez du kentzen.</li>
<li><b>Egoiliar ez diren atzerritarrak</b> ({formatNumber(ajuste_ultimo[0]?.v3, 1)} halako): izendatzaileari gehitzen zaizkio egun arrunt batean Espainian dauden atzerriko bisitariak, kondenatuak izan daitezkeenak baina erroldatuta ez daudenak. Frontur-ekin, egoiliar ez diren bisitari guztiek urtean Espainian egindako gauak batzen dira eta 365 egunez zatitzen dira: egun arrunt batean Espainian dauden {formatNumber(ajuste_ultimo[0]?.visitantes / 1e6, 1)} milioi heldu inguru ateratzen dira, erroldatutako {formatNumber(ajuste_ultimo[0]?.pob_ext / 1e6, 1)} milioi atzerritar helduen aldean. Horrela, milako {formatNumber(ajuste_ultimo[0]?.ext3, 1)} geratzen dira. 2016tik aurrera dago datua.</li>
</ol>
<p class="font-semibold mt-3 mb-1">Hirugarren doikuntzaren hipotesiak</p>
<ul class="list-disc ml-5 space-y-1">
<li>Frontur-ek ematen du zenbat bisitarik egiten duten gau 1, 2 eta 3 artean, 4 eta 7 artean, 8 eta 15 artean edo 15 baino gehiago. Tarte bakoitzaren erdiko puntua hartzen da, «15 baino gehiago» tarterako 25 gau eta gaua igarotzen ez dutenentzat egun erdi.</li>
<li>Frontur-ek ez du bisitarien adina argitaratzen: % 85 helduak direla eta sexuaren eta adinaren arabera Espainiako biztanleria helduaren moduan banatzen direla suposatzen da.</li>
<li>Bisitari baten egun bakoitza egoiliar baten egun baten balio berekoa da. Astebeteko turista batek ziur aski egoiliar batek baino aukera gutxiago ditu delitu egiteko (eta hemen epaitua izateko); beraz, doikuntza hau luzeegi gera daiteke.</li>
<li>Frontur-ek egoitza-herrialdearen arabera zenbatzen du, ez nazionalitatearen arabera: kanpoan bizi diren eta bisitan datozen espainiarrak barne daude. Horregatik ere luzeegi gera daiteke.</li>
<li>Aurkako norabidean, Espainian erroldatu gabe bizi diren atzerritarrak ez daude inongo izendatzailean. Ez dago zifra ofizialik. 2025eko urtarrilaren 1ean egoera irregularrean zeuden 840.000 atzerritar inguruko zenbatespena (<a class="underline" href="https://www.funcas.es/wp-content/uploads/2026/01/Nota-Coyuntura-Social_Enero-2026.pdf">Funcas</a>) erroldatutako biztanleriarekin egiten da hain zuzen; beraz, pertsona horiek zenbatuta daude jada.</li>
</ul>
<p class="mt-3">Datu hauekin, atzerritarren kondenatu-tasa espainiarrenaren {formatNumber(ajuste_ultimo[0]?.v3, 1)} eta {formatNumber(ajuste_ultimo[0]?.v2, 1)} halako artean dago, bisitariak zenbat zenbatzen diren arabera. Estatistika hauek doitzen uzten ez dutena: errenta, enplegua, ikasketa-maila edo bizilekuko auzoa, azterlanetan aldearen beste zati bat azaltzen dutenak, eta atxiloketan, ikerketan edo epaiketan egon daitezkeen tratu-aldeak.</p>
</div>

```sql delitos_nacionalidad
SELECT delito, total, extranjera / total AS cuota_extranjera
FROM mother.crimen_condenas_delito
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenas_delito)
  AND delito IN ('Homicidio y sus formas', 'Lesiones', 'Contra la libertad', 'Contra la libertad e indemnidad sexuales', 'Hurtos', 'Robos',
                 'Contra la seguridad vial', 'Contra la salud pública', 'Defraudaciones', 'Contra la Administración de Justicia', 'Quebrantamiento de condena',
                 'Contra las relaciones familiares', 'Falsedades')
ORDER BY total DESC
```

<DataTable data={delitos_nacionalidad} rows=all>
    <Column id=delito title="Delitua" />
    <Column id=total title="Kondenatutako delituak" fmt=num0 />
    <Column id=cuota_extranjera title="Kondenatua atzerritarra" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">{urtean(condenados_ultimo[0]?.anio)} kondena eragin zuten delituak (kondenatu bat hainbat delitugatik kondena daiteke) eta kondenatuak atzerriko nazionalitatea zuen kasuen ehunekoa. Espainiar nazionalitatea hartu dutenak espainiartzat zenbatzen dira.</p>

### Jatorriaren arabera

```sql procedencia_condenas
SELECT a.procedencia, a.ajuste, a.orden, a.veces, a.anio
FROM mother.crimen_condenados_ajuste a
JOIN (SELECT procedencia, veces AS v2 FROM mother.crimen_condenados_ajuste
      WHERE orden = 2 AND anio = (SELECT max(anio) FROM mother.crimen_condenados_ajuste)) r USING (procedencia)
WHERE a.procedencia <> 'Total' AND a.anio = (SELECT max(anio) FROM mother.crimen_condenados_ajuste)
ORDER BY r.v2 DESC, a.orden
```

```sql procedencia_resumen
SELECT
    max(anio) AS anio,
    max(veces) FILTER (WHERE procedencia = 'África' AND orden = 1) AS africa1,
    max(veces) FILTER (WHERE procedencia = 'África' AND orden = 3) AS africa3,
    max(veces) FILTER (WHERE procedencia = 'América' AND orden = 1) AS america1,
    max(veces) FILTER (WHERE procedencia = 'América' AND orden = 3) AS america3,
    max(veces) FILTER (WHERE procedencia = 'Unión Europea' AND orden = 1) AS ue1,
    max(veces) FILTER (WHERE procedencia = 'Unión Europea' AND orden = 3) AS ue3,
    max(veces) FILTER (WHERE procedencia = 'Resto de Europa' AND orden = 1) AS europa1,
    max(veces) FILTER (WHERE procedencia = 'Resto de Europa' AND orden = 3) AS europa3,
    max(veces) FILTER (WHERE procedencia = 'Asia y Oceanía' AND orden = 3) AS asia3
FROM ${procedencia_condenas}
```

Immigrazio guztia ez da berdina. Hiru doikuntza berekin, {urtean(procedencia_resumen[0]?.anio)} egoiliar afrikarren kondenatu-tasa espainiarrenaren {formatNumber(procedencia_resumen[0]?.africa1, 1)} halakotik {formatNumber(procedencia_resumen[0]?.africa3, 1)} halakora igarotzen da; amerikarrena, {formatNumber(procedencia_resumen[0]?.america1, 1)} halakotik {formatNumber(procedencia_resumen[0]?.america3, 1)} halakora; EBko beste herrialde batzuetako herritarrena, {formatNumber(procedencia_resumen[0]?.ue1, 1)} halakotik {formatNumber(procedencia_resumen[0]?.ue3, 1)} halakora, eta Europako gainerakoena (Erresuma Batua barne), {formatNumber(procedencia_resumen[0]?.europa1, 1)} halakotik {formatNumber(procedencia_resumen[0]?.europa3, 1)} halakora. Asiarrak espainiarrak baino beherago geratzen dira ({formatNumber(procedencia_resumen[0]?.asia3, 1)} halako).

<BarChart
    data={procedencia_condenas}
    x=procedencia
    y=veces
    series=ajuste
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="espainiarren tasaren halako"
    title="Atzerriko kondenatuak jatorriaren arabera: espainiarren tasaren halako ({procedencia_resumen[0]?.anio})"
/>

<p class="text-xs text-gray-500">INEren Kondenatuen Estatistikak kontinenteka baino ez ditu multzokatzen: «América» multzoak Hispanoamerika, AEB eta Kanada batzen ditu (egoiliar gutxi), eta «África» multzoak Afrikako iparraldea eta kontinenteko gainerakoa. Bisitariak jatorriaren arabera banatzen dira, Frontur-eko turisten egoitza-herrialdearen arabera. Europar Batasuna eta Europako gainerakoa, 2020tik aurrera.</p>

#### Herrialdeka: atxiloketak eta ikertuak

```sql detenidos_regiones
SELECT procedencia, veces, veces_edad_sexo, veces_visitantes, detenidos_por_1000_hab, espanoles_por_1000_hab, anio,
       row_number() OVER (ORDER BY veces_edad_sexo DESC) AS puesto
FROM mother.crimen_detenidos_procedencia
WHERE tipo IN ('total', 'region') AND anio = (SELECT max(anio) FROM mother.crimen_detenidos_procedencia)
```

```sql detenidos_regiones_largo
SELECT procedencia, puesto, 'Sin ajustar' AS ajuste, 1 AS orden, veces AS valor FROM ${detenidos_regiones}
UNION ALL
SELECT procedencia, puesto, 'Edad y sexo', 2, veces_edad_sexo FROM ${detenidos_regiones}
UNION ALL
SELECT procedencia, puesto, 'Edad, sexo y visitantes', 3, veces_visitantes FROM ${detenidos_regiones} WHERE veces_visitantes IS NOT NULL
ORDER BY puesto, orden
```

```sql detenidos_resumen
SELECT
    max(anio) AS anio,
    max(espanoles_por_1000_hab) AS espanoles,
    max(detenidos_por_1000_hab) FILTER (WHERE procedencia = 'Todos los extranjeros') AS extranjeros,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Todos los extranjeros') AS total2,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Norte de África') AS norte_africa,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'África subsahariana') AS subsahariana,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Hispanoamérica') AS hispanoamerica,
    max(veces_visitantes) FILTER (WHERE procedencia = 'Europa') AS europa3,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Asia') AS asia
FROM ${detenidos_regiones}
```

```sql detenidos_paises
SELECT procedencia AS pais, detenidos, poblacion_15, detenidos_por_1000_hab, veces, veces_edad_sexo, veces_visitantes
FROM mother.crimen_detenidos_procedencia
WHERE tipo = 'pais' AND anio = (SELECT max(anio) FROM mother.crimen_detenidos_procedencia)
  AND poblacion_15 >= 15000
ORDER BY veces_edad_sexo DESC
```

Afrikako iparraldea kontinenteko gainerakotik bereizteko, edo Hispanoamerika bereizteko, Barne Ministerioaren atxiloketak eta ikertuak erabili behar dira; horiek herrialdea ematen dute (baina atxiloketak zenbatzen dituzte, ez kondenak). {urtean(detenidos_resumen[0]?.anio)} {formatNumber(detenidos_resumen[0]?.extranjeros, 0)} atxiloketa edo ikerketa izan ziren 15 urteko edo gehiagoko 1.000 atzerritarreko, eta {formatNumber(detenidos_resumen[0]?.espanoles, 0)} 1.000 espainiarreko. Adinaren eta sexuaren arabera zuzenduta, atzerritarren tasa espainiarrenaren {formatNumber(detenidos_resumen[0]?.total2, 1)} halako da: afrikar iparraldekoena {formatNumber(detenidos_resumen[0]?.norte_africa, 1)} halako, Saharaz hegoaldeko afrikarrena {formatNumber(detenidos_resumen[0]?.subsahariana, 1)}, hispanoamerikarrena {formatNumber(detenidos_resumen[0]?.hispanoamerica, 1)} eta asiarrena {formatNumber(detenidos_resumen[0]?.asia, 1)}. Europarrena, turistak zenbatuta, {formatNumber(detenidos_resumen[0]?.europa3, 1)} halako da.

<BarChart
    data={detenidos_regiones_largo}
    x=procedencia
    y=valor
    series=ajuste
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="espainiarren tasaren halako"
    title="Atxiloketak eta ikertuak jatorrizko eskualdearen arabera: espainiarren tasaren halako ({detenidos_resumen[0]?.anio})"
/>

<DataTable data={detenidos_paises} rows=15 search=true>
    <Column id=pais title="Nazionalitatea" />
    <Column id=detenidos title="Atxiloketak eta ikertuak" fmt=num0 />
    <Column id=poblacion_15 title="15+ urteko egoiliarrak" fmt=num0 />
    <Column id=detenidos_por_1000_hab title="1.000 egoiliarreko" fmt=num1 />
    <Column id=veces title="Espainiarren tasaren halako" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Adinaren eta sexuaren arabera zuzenduta" fmt='0.0"×"' />
    <Column id=veces_visitantes title="Eta turistekin" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Nola irakurri herrialdeko atxiloketak</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Atxiloketak eta ikerketak dira, ez kondenak, ezta pertsonak ere.</b> Pertsona berak urtean hainbat aldiz zenbatu daiteke, eta guztiek ez dute kondenarekin amaitzen. Atzerritarrak kondenetan baino gehiago agertzen dira atxiloketetan.</li>
<li><b>Hemen bizi ez dena ere barne dago.</b> Turistak, igarotzen ari diren pertsonak eta oraindik erroldatu gabe dauden atzerritar iritsi berriak atxiloketetan zenbatzen dira, baina ez biztanleerian. Duela gutxi sartze irregular asko izan dituzten nazionalitateetan, aljeriarrarena bezala, edo Ceuta eta Melillatik egunero jende asko igarotzen den nazionalitateetan, marokoarrarena bezala, tasa are gainestimatuagoa dago. «Eta turistekin» zutabea Frontur-ek bereizten dituen herrialdeetarako baino ez dago.</li>
<li><b>Adinaren eta sexuaren araberako zuzenketa:</b> Barne Ministerioak atxilotuen adina ematen ez duenez, nazionalitate bakoitzaren piramideari Espainiako kondenatuen adin- eta sexu-kurba aplikatzen zaio, eta ikusitakoa espero zenarekin alderatzen da.</li>
<li>Hispanoamerika Amerika da Brasil kenduta. Atxiloketetan AEB eta Kanada barne daude, Barne Ministerioak ez dituelako bereizten, baina biztanleriatik kentzen dira: 100.000 egoiliar inguru dira, 4 milioi hispanoamerikarren aldean. 15 urteko edo gehiagoko 15.000 egoiliar gutxienez dituzten herrialdeak baino ez dira erakusten.</li>
<li>2020an Mossos d'Esquadra sartu ziren estatistikan eta 2025ean Ertzaintzaren ikertuak: zifrak bat-batean igotzen dira urte horietan nazionalitate guztietan.</li>
</ul>
</div>

### Espainia Europan

```sql europa
SELECT pais, cod_pais, anio, veces, veces_edad_sexo, factor_edad_sexo, extranjeros_poblacion_pct, extranjeros_condenados_pct, veces_presos,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.crimen_europa_nacionalidad e
WHERE anio = (SELECT max(anio) FROM mother.crimen_europa_nacionalidad x WHERE x.cod_pais = e.cod_pais)
  AND anio >= 2018 AND extranjeros_poblacion_pct >= 5 AND cod_pais <> 'LV'
ORDER BY veces_edad_sexo DESC
```

```sql europa_espana
SELECT
    max(anio) FILTER (WHERE cod_pais = 'ES') AS anio,
    max(veces) FILTER (WHERE cod_pais = 'ES') AS veces,
    max(veces_edad_sexo) FILTER (WHERE cod_pais = 'ES') AS ajustado,
    count(*) AS paises,
    count(*) FILTER (WHERE veces_edad_sexo > (SELECT veces_edad_sexo FROM ${europa} WHERE cod_pais = 'ES')) AS por_encima,
    median(veces_edad_sexo) AS mediana
FROM ${europa}
```

```sql europa_serie
SELECT pais, anio, veces_edad_sexo
FROM mother.crimen_europa_nacionalidad
WHERE cod_pais IN ('ES', 'DE', 'FR', 'IT', 'PT', 'AT', 'CH', 'DK') AND anio >= 2010
ORDER BY anio
```

Eurostat-ek hogei bat Europako herrialdek argitaratzen dituzten kondenatuak nazionalitatearen arabera biltzen ditu. {urtean(europa_espana[0]?.anio)} Espainiako atzerritarren kondenatu-tasa espainiarrenaren {formatNumber(europa_espana[0]?.veces, 1)} halako zen, eta {formatNumber(europa_espana[0]?.ajustado, 1)} halako adinaren eta sexuaren arabera zuzenduta. Atzerritar biztanleriaren % 5 gutxienez duten {formatNumber(europa_espana[0]?.paises, 0)} herrialdeetatik, {formatNumber(europa_espana[0]?.por_encima, 0)} herrialdetan Espainian baino aldea handiagoa dago (mediana {formatNumber(europa_espana[0]?.mediana, 1)} halako da).

<BarChart
    data={europa}
    x=pais
    y=veces_edad_sexo
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="naziokoen tasaren halako, adinaren eta sexuaren arabera zuzenduta"
    title="Atzerriko kondenatuak naziokoekin alderatuta Europan, adinaren eta sexuaren arabera zuzenduta (herrialde bakoitzeko azken urtea)"
/>

<LineChart
    data={europa_serie}
    x=anio
    y=veces_edad_sexo
    series=pais
    yFmt='0.0"×"'
    xFmt="####"
    legend=true
    yMin=0
    yAxisTitle="halako, adinaren eta sexuaren arabera zuzenduta"
    title="Bilakaera zenbait herrialdetan: atzerriko kondenatuak naziokoekin alderatuta, adinaren eta sexuaren arabera zuzenduta"
/>

<DataTable data={europa} rows=all>
    <Column id=pais title="Herrialdea" />
    <Column id=anio title="Urtea" fmt="####" />
    <Column id=extranjeros_poblacion_pct title="Atzerritarrak biztanleerian (15+)" fmt='0.0"%"' />
    <Column id=extranjeros_condenados_pct title="Atzerritarrak kondenatuen artean" fmt='0.0"%"' />
    <Column id=veces title="Halako, doitu gabe" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Adinaren eta sexuaren arabera zuzenduta" fmt='0.0"×"' />
    <Column id=veces_presos title="Presoak: halako" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Nola egin den Europako konparazioa</p>
<ul class="list-disc ml-5 space-y-1">
<li>Eurostat-en nazionalitatearen araberako kondenatuak (crim_just_ctz), nazionalitate bereko 15 urteko edo gehiagoko biztanleriaz zatituta (migr_pop1ctz). «Zenbat halako» herrialde bakoitzaren barruan alderatzen da, herrialde bakoitzak kondenak bere erara zenbatzen dituelako (Alemanian, adibidez, atzerritarrak soilik egin ditzakeen atzerritartasun-delituak barne daude; Espainian egoera irregularrean egotea ez da delitua).</li>
<li>Eurostat-ek ez du kondenatuen adina ematen. Adinaren eta sexuaren arabera zuzentzeko, herrialde bakoitzeko naziokoen eta atzerritarren piramideari Espainiako kondenatuen adin- eta sexu-kurba aplikatzen zaio. Horrela kalkulatzen da talde bakoitzean zenbat kondenatu espero litekeen adinagatik eta sexuagatik soilik. Espainian, metodo honek {formatNumber(europa_espana[0]?.ajustado, 1)} halako ematen du, INEren datu osoekin egindako zuzeneko doikuntzaren ia berdina.</li>
<li>Ez da turisten arabera doitzen herrialde batean ere. Espainiak, Austriak, Greziak edo Portugalek bisitari asko jasotzen dituzte biztanleko; beraz, haien zifra beste batzuenena baino pixka bat puztuagoa dago.</li>
<li>Atzerritarren % 5 gutxienez duten eta 2018tik datuak dituzten herrialdeak baino ez. Letonia kanpoan geratzen da: han «atzerritar» gehienak betidanik bizi diren egoiliarrak dira, Letoniako nazionalitaterik gabe. «Presoak: halako» zutabeak presoak (prebentiboak barne) modu berean alderatzen ditu, adinagatik zuzendu gabe.</li>
<li>Suedia edo Herrialde Baxuak bezalako herrialdeek ez dute datu hau Eurostat-en argitaratzen. Gainera, han etorkin askok laster hartzen dute nazionalitatea eta atzerritar gisa zenbatzeari uzten diote, Espainian nazionalitatea hartu dutenak espainiartzat zenbatzen diren bezala.</li>
</ul>
</div>

---

## Iturriak eta oharrak

- **[Barne Ministerioa – Kriminalitatearen Atari Estatistikoa](https://estadisticasdecriminalidad.ses.mir.es/)**: 2010etik erkidego eta probintziaka ezagututako arau-hauste penalen urteko seriea, eta hiruhileko Kriminalitate Balantzea, 20.000 biztanletik gorako udalerriekin (urte osoa 2019tik). 2019an Balantzearen sailkapena aldatu zen; beraz, ez da aurreko urteekin alderatzen.
- **[INE – Kondenatuen Estatistika: helduak](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (25704 eta 49050 taulak), Zigortuen Erregistro Zentraletik abiatuta, **[INE – Kondenatuak sexuaren, adinaren eta nazionalitatearen arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=25645)** (25645 taula), adinaren araberako doikuntzarako, eta **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (56942 taula), urtarrilaren 1eko biztanleria nazionalitatearen, sexuaren eta adinaren arabera lortzeko. 18 urteko edo gehiagoko biztanleria eta adin-tarte bakoitzekoa, bost urteko adin-taldeetatik abiatuta hurbildua.
- **[INE – Frontur](https://www.ine.es/jaxiT3/Tabla.htm?t=23987)** (23987 eta 23984 taulak): egoiliar ez diren bisitariak egonaldiaren iraupenaren arabera eta turistak egoitza-herrialdearen arabera, egun arrunt batean Espainian zenbat dauden eta nondik datozen zenbatesteko.
- **[Barne Ministerioa – Atxiloketak eta ikertuak](https://estadisticasdecriminalidad.ses.mir.es/)** (03007 eta 03001 taulak): atxilotu eta ikertu atzerritarrak nazionalitatearen arabera eta guztizkoa, eta **[INE – Biztanleria nazionalitate-herrialdearen arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=56936)** (56936 taula) izendatzailerako.
- **[Nazio Batuak – UNODC](https://dataunodc.un.org/)**: poliziak erregistratutako delituak motaren arabera eta presoak UN-CTS inkestari erantzuten dioten herrialde guztietan, eta intentzioz egindako homizidioak **[Munduko Bankuarenak](https://data.worldbank.org/indicator/VC.IHR.PSRC.P5)**, UNODCren datuekin.
- **[Eurostat](https://ec.europa.eu/eurostat/databrowser/view/crim_just_ctz)**: Europako herrialde bakoitzeko kondenatuak (crim_just_ctz) eta presoak (crim_pris_ctz) nazionalitatearen arabera, eta biztanleria nazionalitatearen, sexuaren eta adinaren arabera (migr_pop1ctz).

<LastRefreshed prefix="Datuak eguneratuta" />
