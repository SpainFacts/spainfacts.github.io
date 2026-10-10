---
title: Enplegu publikoa
description: "Zenbat enplegatu publiko dauden Espainian, zein administrazio eta sektoretan lan egiten duten (osasuna, hezkuntza, udalak, segurtasun-indarrak...), nola aldatu den haien kopurua, zenbat kobratzen duten sektore pribatuarekin alderatuta eta zenbat balio duten."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: eb201e9adb20
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql ultima
SELECT
    max(fecha) AS fecha,
    strftime(max(fecha), '%d/%m/%Y') AS fecha_texto
FROM mother.empleo_efectivos
```

```sql resumen
SELECT
    sum(efectivos) AS total,
    sum(efectivos) FILTER (WHERE administracion = 'Estado') AS estado,
    sum(efectivos) FILTER (WHERE administracion = 'Comunidades autónomas') AS ccaa,
    sum(efectivos) FILTER (WHERE administracion = 'Entidades locales') AS local,
    sum(efectivos) FILTER (WHERE sexo = 'Mujeres') AS mujeres,
    sum(efectivos) FILTER (WHERE tipo_personal IN ('Funcionario interino', 'Laboral temporal')) AS temporales
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
```

```sql por_1000
SELECT por_1000_hab FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = (SELECT fecha FROM ${ultima})
```

```sql coste_ultimo
SELECT anio, anio_base, millones_eur, pct_pib, eur_hab_real
FROM mother.empleo_coste
WHERE cod_sector = 'S13'
ORDER BY anio DESC
LIMIT 1
```

```sql salario_ultimo
SELECT
    anio,
    max(salario_mensual) FILTER (WHERE sector = 'Público') AS publico,
    max(salario_mensual) FILTER (WHERE sector = 'Privado') AS privado
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo' AND decil_nombre = 'Total'
GROUP BY anio
ORDER BY anio DESC
LIMIT 1
```

```sql serie_cuota_ccaa
SELECT
    fecha,
    100 * sum(efectivos) FILTER (WHERE administracion = 'Comunidades autónomas') / sum(efectivos) AS cuota_ccaa
FROM mother.empleo_efectivos
GROUP BY fecha
ORDER BY fecha
```

```sql serie_por_1000
SELECT fecha, por_1000_hab
FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion = 'Total' AND por_1000_hab IS NOT NULL
ORDER BY fecha
```

```sql coste_serie_real
-- Para las mini-gráficas: euros por habitante a precios constantes (ya calculados en la tabla)
SELECT anio, eur_hab_real
FROM mother.empleo_coste
WHERE cod_sector = 'S13' AND eur_hab_real IS NOT NULL
ORDER BY anio
```

```sql salario_serie_real
SELECT anio, max(salario_mensual_real) AS publico_real
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo' AND decil_nombre = 'Total' AND sector = 'Público' AND salario_mensual_real IS NOT NULL
GROUP BY anio
ORDER BY anio
```

# 🏛️ Enplegu publikoa

Nork lan egiten duen Espainiako administrazio publikoentzat: zenbat diren, zein administraziotan eta zein zerbitzutan, non, zenbat kobratzen duten eta zenbat balio duten.

<Grid cols=4>
    <KpiCard
        title="Enplegatu publikoak"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(por_1000[0]?.por_1000_hab, 1)} 1.000 biz."
        period="{formatCompact(resumen[0]?.total, 2)} guztira · {ultima[0]?.fecha_texto}"
        source="Langileen Erregistro Zentrala"
        sparklineData={serie_por_1000.map(d => ({...d, y: d.por_1000_hab}))}
    />
    <KpiCard
        title="Autonomia-erkidegoetan"
        value={resumen[0]?.ccaa}
        formattedValue="{formatNumber(resumen[0]?.ccaa / resumen[0]?.total / 0.01, 0)} %"
        period="{formatCompact(resumen[0]?.ccaa, 2)}: batez ere osasuna eta hezkuntza"
        source="Langileen Erregistro Zentrala"
        sparklineData={serie_cuota_ccaa.map(d => ({...d, y: d.cuota_ccaa}))}
    />
    <KpiCard
        title="Urtean balio dutena, biztanleko"
        value={coste_ultimo[0]?.eur_hab_real}
        formattedValue="{formatNumber(coste_ultimo[0]?.eur_hab_real, 0)} €"
        period="{formatNumber(coste_ultimo[0]?.millones_eur / 1000, 1)} mila M€ guztira · BPGaren {formatNumber(coste_ultimo[0]?.pct_pib, 1)} % · {coste_ultimo[0]?.anio} ({urteko(coste_ultimo[0]?.anio_base)} euroak)"
        source="Eurostat"
        sparklineData={coste_serie_real.map(d => ({...d, y: d.eur_hab_real}))}
    />
    <KpiCard
        title="Batez besteko soldata (lanaldi osoa)"
        value={salario_ultimo[0]?.publico}
        formattedValue="{formatNumber(salario_ultimo[0]?.publico, 0)} €/hil."
        period="sektore pribatuko {formatNumber(salario_ultimo[0]?.privado, 0)} €-ren aldean · {salario_ultimo[0]?.anio}"
        source="INE (EPA)"
        sparklineData={salario_serie_real.map(d => ({...d, y: d.publico_real}))}
    />
</Grid>

## Non egiten dute lan?

```sql sectores
SELECT administracion, sector, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY efectivos DESC
```

<BarChart
    data={sectores}
    x=sector
    y=efectivos
    series=administracion
    swapXY=true
    yFmt=num0
    sort=false
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Enplegatu publikoak sektorearen eta administrazioaren arabera"
/>

<p class="text-xs text-gray-500">Enplegu publikoaren ia erdia osasunean eta unibertsitatez kanpoko irakaskuntzan dago, eta horiek autonomia-erkidegoek kudeatzen dituzte laurogeiko hamarkadatik 2002ra bitarteko eskualdatzeez geroztik. Estatuak batez ere Indar Armatuak, Polizia Nazionala, Guardia Civil, Zerga Agentzia, espetxeak eta ministerioetako zerbitzuak mantentzen ditu.</p>

```sql tipos
SELECT tipo_personal, sum(efectivos) AS efectivos,
    CASE tipo_personal WHEN 'Funcionario de carrera' THEN 1 WHEN 'Funcionario interino' THEN 2 WHEN 'Laboral fijo' THEN 3 WHEN 'Laboral temporal' THEN 4 WHEN 'Laboral (sin detalle)' THEN 5 ELSE 6 END AS orden
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY orden
```

```sql sexo_sector
SELECT sector, sum(efectivos) FILTER (WHERE sexo = 'Mujeres') / sum(efectivos) AS cuota_mujeres, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY sector
HAVING sum(efectivos) > 10000
ORDER BY cuota_mujeres DESC
```

<Grid cols=2>
    <BarChart data={tipos} x=tipo_personal y=efectivos sort=false yFmt=num0 fillColor="#0f766e" title="Harreman motaren arabera" />
    <BarChart data={sexo_sector} x=sector y=cuota_mujeres swapXY=true sort=false yFmt=pct0 fillColor="#a78bfa" title="Emakumeen ehunekoa sektorearen arabera" />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(100 * resumen[0]?.temporales / resumen[0]?.total, 0)} % bitartekoak edo aldi baterako lan-kontratudunak dira. Karrerako funtzionarioa: oposizioaren ondoren jabetzan duen plaza. Bitartekoa: plaza huts bat edo ordezkapen bat betetzen du. Lan-kontratuduna: lan-kontratua (finkoa edo aldi baterakoa). Osasunean, osasun-zerbitzuetako langile estatutarioak funtzionariotzat zenbatzen dira.</p>

```sql organismos
SELECT
    row_number() OVER (ORDER BY efectivos DESC) AS puesto,
    organismo,
    administracion,
    nullif(ministerio, '') AS ministerio,
    efectivos,
    mujeres / efectivos AS cuota_mujeres
FROM mother.empleo_organismos
ORDER BY efectivos DESC
```

<Details title="Langile gehien dituzten Estatuko erakundeak">

<DataTable data={organismos} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=organismo title="Erakundea" />
    <Column id=ministerio title="Atxikitze-ministerioa" />
    <Column id=efectivos title="Langileak" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_mujeres title="Emakumeak" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Azken edizioan 100 langile edo gehiago dituzten Estatuko ministerioak, agentziak eta erakundeak. Autonomia-erkidegoetan eta toki-erakundeetan, erregistroak ez du banakatzen sailka edo erakundeka.</p>

</Details>

## Zenbat daude biztanleko lurralde bakoitzean?

```sql ccaa
SELECT
    t.cod AS cod_ccaa,
    c.nombre AS comunidad,
    '/eu' || c.ruta AS ruta,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS efectivos,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total') AS por_1000_hab,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Estado') AS estado_1000,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Comunidades autónomas') AS ccaa_1000,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Entidades locales') AS local_1000
FROM mother.empleo_territorio t
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY por_1000_hab DESC
```

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="por_1000_hab"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Langileen Erregistro Zentrala"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_1000_hab', title: '1.000 biztanleko', fmt: 'num0'},
        {id: 'efectivos', title: 'Enplegatu publikoak', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=efectivos title="Enplegatu publikoak" fmt=num0 />
    <Column id=por_1000_hab title="1.000 biz." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=estado_1000 title="…Estatukoak" fmt=num1 />
    <Column id=ccaa_1000 title="…erkidegokoak" fmt=num1 />
    <Column id=local_1000 title="…tokikoak" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Lanpostua dagoen erkidegoaren arabera. Ceuta eta Melilla nabarmentzen dira han destinatutako militar eta poliziengatik, eta Madril ministerioetako zerbitzu zentralengatik. Erkidego batek itunen, partzuergoen edo enpresa publikoen bidez ematen dituenean zerbitzuak (Katalunian osasunaren zati handi bat, adibidez), langile horiek ez dira erregistroan agertzen eta tasa baxuagoa ateratzen da. Sakatu erkidego batean haren probintziak ikusteko.</p>

## Nola aldatu da?

```sql serie_registro
-- Empleados por 1.000 habitantes (padrón del año; el último disponible para los más recientes)
SELECT fecha, administracion, efectivos, por_1000_hab AS por_1000
FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion <> 'Total'
ORDER BY fecha
```

<BarChart
    data={serie_registro}
    x=fecha
    y=por_1000
    series=administracion
    type=stacked
    yFmt=num1
    xFmt="mmm yyyy"
    yAxisTitle="1.000 biztanleko"
    colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
    title="Enplegatu publikoak 1.000 biztanleko (Langileen Erregistro Zentrala, urtarrilaren 1a eta uztailaren 1a)"
/>

<p class="text-xs text-gray-500">Kontuz 2022ko uztailaren eta 2023ko urtarrilaren arteko jauziarekin (~+240.000): Ministerioak 2026ko abuztuan berrikusi zituen 2023tik aurrerako edizio guztiak iturri eta hiztegi berriekin (batez ere autonomia-erkidegoetan); beraz, igoeraren zati bat metodologikoa da, ez kontratazioak. 2019ko uztaila baino lehen, datuak ez dira formatu irekian argitaratzen.</p>

```sql serie_epa
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT e.trimestre, e.administracion, e.asalariados,
    1000.0 * e.asalariados / p.poblacion AS por_1000
FROM mother.empleo_epa_administracion e
JOIN pob p ON p.anio = greatest(least(CAST(year(e.trimestre) AS INTEGER), (SELECT max(anio) FROM pob)), (SELECT min(anio) FROM pob))
WHERE e.administracion NOT IN ('Total', 'Otras / no sabe')
ORDER BY e.trimestre
```

<BarChart
    data={serie_epa}
    x=trimestre
    y=por_1000
    series=administracion
    type=stacked
    yFmt=num1
    xFmt="yyyy"
    yAxisTitle="1.000 biztanleko"
    title="Sektore publikoko soldatapekoak 1.000 biztanleko, EParen arabera (2002tik)"
/>

<p class="text-xs text-gray-500">Biztanleria Aktiboaren Inkestak serie luzeagoa ematen du (hiruhilekoa 2002tik) eta enpresa eta erakunde publikoak ere zenbatzen ditu, baina inkesta bat da: horregatik ematen ditu erregistroak baino enplegatu publiko gehiago (3,6 milioi inguru), eta haren hiruhileko datuak errore-marjina du. Ikus daitezke 2011-2014ko murrizketa (urteko batez beste 3,28 milioitik 2,93 milioira, zorraren krisiarekin) eta ondorengo hazkundea, azkarragoa 2018tik.</p>

```sql cuota_ccaa
SELECT e.fecha, e.nombre AS comunidad, e.cuota_publico_pct
FROM mother.empleo_epa_ccaa e
WHERE e.nivel = 'ccaa' AND e.fecha = (SELECT max(fecha) FROM mother.empleo_epa_ccaa)
ORDER BY e.cuota_publico_pct DESC
```

<BarChart
    data={cuota_ccaa}
    x=comunidad
    y=cuota_publico_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor="#1d4ed8"
    title="Enplegu publikoaren pisua soldatapeko guztien gainean (EPA, azken hiruhilekoa)"
/>

## Zenbat kobratzen dute?

```sql deciles
SELECT
    decil,
    decil_nombre AS decil_txt,
    sector,
    salario_mensual
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo'
  AND anio = (SELECT max(anio) FROM mother.empleo_salarios_deciles)
  AND decil IS NOT NULL
  AND sector IN ('Público', 'Privado')
ORDER BY decil
```

```sql brecha
-- En euros constantes del último año completo (descontada la inflación con el IPC)
SELECT
    s.anio,
    max(s.salario_mensual_real) FILTER (WHERE s.sector = 'Público') AS publico,
    max(s.salario_mensual_real) FILTER (WHERE s.sector = 'Privado') AS privado,
    any_value(s.anio_euros) AS anio_base
FROM mother.empleo_salarios_deciles s
WHERE s.jornada = 'Jornada a tiempo completo' AND s.decil_nombre = 'Total'
GROUP BY s.anio
ORDER BY s.anio
```

<LineChart
    data={brecha}
    x=anio
    y={['publico', 'privado']}
    yFmt=num0
    xFmt="####"
    colorPalette={['#1d4ed8', '#f59e0b']}
    seriesLabels={{publico: 'Sektore publikoa', privado: 'Sektore pribatua'}}
    legend=true
    yAxisTitle="€ gordin hilean (euro konstanteak)"
    title="Hileko batez besteko soldata gordina, lanaldi osoa, {urteko(brecha[0]?.anio_base)} eurotan, inflazioa kenduta"
/>

<BarChart
    data={deciles}
    x=decil_txt
    y=salario_mensual
    series=sector
    type=grouped
    yFmt=num0
    sort=false
    colorPalette={['#f59e0b', '#1d4ed8']}
    title="Dezil bakoitzeko batez besteko soldata (gutxien kobratzen duen 10 %-tik gehien kobratzen duen 10 %-ra)"
/>

<p class="text-xs text-gray-500">Dezil bakoitzaren barruan (soldataren arabera ordenatutako soldatapekoen 10 %-eko tarte bakoitza), sektore publikoak eta pribatuak ia berdin kobratzen dute, eta dezil altuenean pribatuak gehiago kobratzen du. Batez besteko aldea osaeratik dator: tarte altuetan proportzioz enplegatu publiko askoz gehiago daude (medikuak, irakasleak, goi-mailako tituludunak, antzinatasun handiagoa), eta sektore pribatuko soldata baxueneko enpleguetan ia bat ere ez (ostalaritza, merkataritza, nekazaritza). Lanaldi osoko enplegu nagusiaren hileko soldata gordina, zergen eta langilearen kotizazioen aurretik.</p>

```sql salarios_ccaa
SELECT nombre AS comunidad, salario_publico, salario_privado, brecha_publico_pct AS diferencia
FROM mother.empleo_salarios_ccaa
WHERE nivel = 'ccaa'
ORDER BY salario_publico DESC
```

<DataTable data={salarios_ccaa} rows=all>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=salario_publico title="Publikoa (€/urte)" fmt=num0 />
    <Column id=salario_privado title="Pribatua (€/urte)" fmt=num0 />
    <Column id=diferencia title="Aldea" fmt='0"%"' />
</DataTable>

<p class="text-xs text-gray-500">2022ko urteko batez besteko soldata gordina, INEren Soldata Egituraren Lau Urteko Inkestaren arabera, lantokiaren erkidegoaren arabera eta enpresa edo erakundea nork kontrolatzen duen kontuan hartuta. Erregimen Orokorrean kotizatzen dutenak baino ez ditu hartzen: kanpoan uzten ditu mutualitateetako funtzionarioak (MUFACE, ISFAS, MUGEJU).</p>

## Zenbat balio dute?

```sql coste
-- Euros por habitante y constantes (descontada la inflación con el IPC; ya calculados en la tabla)
SELECT c.anio, c.subsector, c.millones_eur / 1000 AS miles_millones, c.pct_pib,
    c.eur_hab_real, c.anio_base
FROM mother.empleo_coste c
WHERE c.cod_sector <> 'S13' AND c.eur_hab_real IS NOT NULL
ORDER BY c.anio
```

```sql coste_total
SELECT anio, pct_pib FROM mother.empleo_coste WHERE cod_sector = 'S13' ORDER BY anio
```

<BarChart
    data={coste}
    x=anio
    y=eur_hab_real
    series=subsector
    type=stacked
    yFmt=num0
    xFmt="####"
    yAxisTitle="€ biztanleko (konstanteak)"
    title="Langile publikoen kostua biztanleko eta administrazioaren arabera, {urteko(coste[0]?.anio_base)} eurotan"
/>

<LineChart
    data={coste_total}
    x=anio
    y=pct_pib
    yFmt=num1
    xFmt="####"
    colorPalette={['#1d4ed8']}
    yAxisTitle="BPGaren %"
    title="Langile publikoen kostua BPGaren gainean"
/>

<p class="text-xs text-gray-500">Biztanleko eta euro konstanteetan, bilakaerak biztanleriaren eta prezioen igoera soilik isla ez dezan. Administrazio publikoetako soldatapekoen ordainsaria (kontabilitate nazionala, Eurostat): soldatak gehi administrazioak enplegatzaile gisa ordaintzen dituen gizarte-kotizazioak. Administrazioen arteko transferentziak ez dira bi aldiz zenbatzen: bakoitzak bere langileei ordaintzen die.</p>

```sql coste_ccaa
SELECT
    c.nombre AS comunidad,
    '/eu' || c.ruta AS ruta,
    g.anio,
    g.anio_base,
    g.gasto_personal_ccaa / 1e6 AS gasto_ccaa_millones,
    g.gasto_personal_ccaa_eur_hab_real,
    g.gasto_personal_ayuntamientos_eur_hab_real
FROM mother.empleo_gasto_personal_territorio g
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = g.cod
WHERE g.nivel = 'ccaa'
  AND g.anio = (SELECT max(anio) FROM mother.empleo_gasto_personal_territorio WHERE nivel = 'ccaa' AND gasto_personal_ccaa IS NOT NULL AND gasto_personal_ayuntamientos IS NOT NULL)
ORDER BY g.gasto_personal_ccaa_eur_hab_real DESC
```

### Erkidego bakoitzaren eta haren udalen langile-gastua ({coste_ccaa[0]?.anio}, {urteko(coste_ccaa[0]?.anio_base)} euroak)

<DataTable data={coste_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=gasto_ccaa_millones title="Erkidegoa (M€)" fmt=num0 />
    <Column id=gasto_personal_ccaa_eur_hab_real title="Erkidegoa (€/biz.)" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=gasto_personal_ayuntamientos_eur_hab_real title="Udalak (€/biz.)" fmt=num0 contentType=bar barColor="#fde68a" />
</DataTable>

<p class="text-xs text-gray-500">Likidazioen 1. kapitulua («langile-gastuak»): erkidegoarena, Ogasunetik; udalena, beren likidazioa Ogasunera bidali zutenen batura (CONPREL), udalerri horietako biztanleko. Euskadik eta Nafarroak beren zergak kobratzen dituzte (foru-araubidea) eta eskumen gehiago hartzen dituzte, eta horrek haien gastua handitzen du; Araban eta Nafarroan udalak ez dira CONPRELen agertzen. Udal bakoitzaren langile-gastua haren fitxan dago: <a href="/eu/territorios/municipios">udalerriak</a>.</p>

---

## Iturriak eta oharrak

- **[Administrazio Publikoen Zerbitzuko Langileen Buletin Estatistikoa (Langileen Erregistro Zentrala)](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**, Eraldaketa Digitalerako eta Funtzio Publikoko Ministerioa: urtarrilaren 1eko eta uztailaren 1eko langileak 2019tik. Ez ditu barne hartzen enpresa publikoak ezta fundazioak ere, eta ez da udal bakoitzaren xehetasunera iristen (erakunde motaren eta probintziaren arabera soilik). Toki-erakundeetako langileak Gizarte Segurantzako afiliaziotik datoz.
- **[INE – Biztanleria Aktiboaren Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=65193)**: soldatapeko publikoak administrazioaren arabera (65193 taula) eta erkidegoka (65327); soldatak dezilka (66250).
- **[INE – Soldata Egituraren Inkesta 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: urteko soldata erkidegoka eta kontrol publiko edo pribatuaren arabera.
- **[Eurostat – gov_10a_main](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main/default/table)**: administrazio publikoetako soldatapekoen ordainsaria (D1), azpisektoreka.
- **Ogasun Ministerioa**: autonomia-erkidegoen eta toki-erakundeen likidazioak (CONPREL), 1. kapitulua.
- Hiru zenbaketek gauza desberdinak neurtzen dituzte: erregistroak administrazio batean lanpostua duten pertsonak zenbatzen ditu; EPAk sektore publikoan lan egiten dutela dioten soldatapekoak estimatzen ditu (enpresa publikoak barne); kontabilitate nazionalak kostua neurtzen du.

<LastRefreshed prefix="Datuak eguneratuta" />
