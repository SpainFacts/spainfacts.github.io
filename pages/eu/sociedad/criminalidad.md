---
title: Kriminalitatea
description: "Espainian ezagututako delituak motaren, erkidegoaren, probintziaren eta udalerriaren arabera 2010etik, zibergaizkileriaren bilakaera eta kondenatuak nazionalitatearen arabera, haien testuinguruarekin."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 675d5e735dd8
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
<li><b>Atzerritarren tasa gainestimatuta dago.</b> Atzerriko nazionalitateko kondenatuen artean turistak, igarotzen ari diren pertsonak eta erroldan agertzen ez diren egoera irregularreko pertsonak daude; beraz, zenbakitzailean daude, baina ez izendatzailean.</li>
<li><b>Adinak eta sexuak asko eragiten dute.</b> Edozein herrialdetan, kondenatu gehienak gizon gazteak dira, eta atzerritar biztanleriak gizon gazte gehiago ditu espainiarrak baino. Horregatik, hemen gizonak gizonekin eta emakumeak emakumeekin alderatzen dira (gizonetan, milako {formatNumber(condenados_ultimo[0]?.h_ext, 1)} atzerritarrak eta {formatNumber(condenados_ultimo[0]?.h_esp, 1)} espainiarrak; emakumeetan, {formatNumber(condenados_ultimo[0]?.m_ext, 1)} eta {formatNumber(condenados_ultimo[0]?.m_esp, 1)}). Ezin da adinaren arabera doitu: INEk ez ditu gurutzatzen kondenatuen adina eta nazionalitatea.</li>
<li><b>Beste faktore batzuk</b>, estatistika honek jasotzen ez dituenak eta azterlanetan aldearen zati bat azaltzen dutenak: errenta-maila, enplegua, ikasketa-maila edo bizilekuko auzoa.</li>
<li>Kondenatutako pertsonak dira, ez atxilotuak edo ikertuak: epaiketa bat egin da jada. Kondena ematen duen epaitegiaren erkidegoan zenbatzen da.</li>
</ul>
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

---

## Iturriak eta oharrak

- **[Barne Ministerioa – Kriminalitatearen Atari Estatistikoa](https://estadisticasdecriminalidad.ses.mir.es/)**: 2010etik erkidego eta probintziaka ezagututako arau-hauste penalen urteko seriea, eta hiruhileko Kriminalitate Balantzea, 20.000 biztanletik gorako udalerriekin (urte osoa 2019tik). 2019an Balantzearen sailkapena aldatu zen; beraz, ez da aurreko urteekin alderatzen.
- **[INE – Kondenatuen Estatistika: helduak](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (25704 eta 49050 taulak), Zigortuen Erregistro Zentraletik abiatuta, eta **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (56942 taula), urtarrilaren 1eko biztanleria nazionalitatearen, sexuaren eta adinaren arabera lortzeko. 18 urteko edo gehiagoko biztanleria, bost urteko adin-taldeetatik abiatuta hurbildua.

<LastRefreshed prefix="Datuak eguneratuta" />
