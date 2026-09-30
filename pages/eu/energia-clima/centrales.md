---
title: Zentral elektrikoak
description: "Espainiako zentral elektrikoen mapa: martxan, eraikitzen, izapidetzen eta erretiratuak, teknologiaren, potentziaren eta jabearen arabera."
i18n_origen: abe822fcd116
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql tecnologias
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM mother.centrales_resumen
GROUP BY tecnologia
ORDER BY orden
```

```sql kpis
SELECT
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') / 1000 AS gw_operacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación' AND renovable) * 100
        / sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') AS pct_renovable,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En construcción') / 1000 AS gw_construccion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En tramitación') / 1000 AS gw_tramitacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'Anunciada') / 1000 AS gw_anunciada,
    (SELECT count(*) FROM mother.centrales WHERE estado_grupo = 'En operación') AS n_operacion
FROM mother.centrales_resumen
```

```sql carbon
SELECT sum(mw_baja) / 1000 AS gw_carbon_retirado
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018
```

```sql operacion_serie
SELECT anio, valor
FROM (
    SELECT anio, sum(sum(mw_alta - mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
    FROM mother.centrales_por_anio
    WHERE anio <= year(current_date)
    GROUP BY anio
)
WHERE anio >= 2000
ORDER BY anio
```

```sql carbon_serie
SELECT anio, sum(sum(mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018 AND anio <= year(current_date)
GROUP BY anio
ORDER BY anio
```

# ⚡ Espainiako zentral elektrikoak

Espainiak **{formatNumber(kpis[0]?.gw_operacion, 1)} GW** potentzia ditu martxan 1 MW baino gehiagoko **{formatNumber(kpis[0]?.n_operacion, 0)} zentraletan**, eta beste **{formatNumber(kpis[0]?.gw_construccion, 1)} GW** eraikitzen. Horien atzean izapidetzen dauden **{formatNumber(kpis[0]?.gw_tramitacion, 0)} GW** proiektu daude zain, dagoeneko martxan dagoen potentzia osoa baino gehiago, nahiz eta horien zati bat baino ez den eraikiko. Mapa honek zentral bakoitza jasotzen du (martxan, obretan, izapidetzen, iragarrita edo dagoeneko itxita), Global Energy Monitorren mundu-inbentarioaren arabera.

<Grid cols=4>
    <KpiCard
        title="Martxan"
        value={kpis[0]?.gw_operacion}
        formattedValue={formatNumber(kpis[0]?.gw_operacion, 1)}
        unit=" GW"
        period="{formatNumber(kpis[0]?.pct_renovable, 0)} % berriztagarria"
        source="Global Energy Monitor"
        sparklineData={operacion_serie}
    />
    <KpiCard
        title="Eraikitzen"
        value={kpis[0]?.gw_construccion}
        formattedValue={formatNumber(kpis[0]?.gw_construccion, 1)}
        unit=" GW"
        period="Hasitako obrak"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Izapidetzen"
        value={kpis[0]?.gw_tramitacion}
        formattedValue={formatNumber(kpis[0]?.gw_tramitacion, 0)}
        unit=" GW"
        period="Baimenak bidean dituztela"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="2018az geroztik itxitako ikatza"
        value={carbon[0]?.gw_carbon_retirado}
        formattedValue={formatNumber(carbon[0]?.gw_carbon_retirado, 1)}
        unit=" GW"
        period="Erretiratutako ikatz-potentzia"
        source="Global Energy Monitor"
        sparklineData={carbon_serie}
    />
</Grid>

---

## Mapa

Zirkulu bakoitza zentral bat da: haren azalera potentziaren proportzionala da, eta koloreak teknologia adierazten du. Aukeratu egoera, teknologiak eta autonomia-erkidegoa; pasatu sagua zirkulu baten gainetik haren datuak ikusteko.

```sql opciones_ccaa
SELECT DISTINCT cod_ccaa, ccaa
FROM mother.centrales
WHERE ccaa IS NOT NULL
ORDER BY ccaa
```

<ButtonGroup name=estado title="Egoera">
    <ButtonGroupItem valueLabel="Martxan" value="En operación" default />
    <ButtonGroupItem valueLabel="Eraikitzen" value="En construcción" />
    <ButtonGroupItem valueLabel="Izapidetzen" value="En tramitación" />
    <ButtonGroupItem valueLabel="Iragarrita" value="Anunciada" />
    <ButtonGroupItem valueLabel="Geldituta" value="Paralizada" />
    <ButtonGroupItem valueLabel="Erretiratuta" value="Retirada" />
    <ButtonGroupItem valueLabel="Bertan behera utzita" value="Cancelada" />
    <ButtonGroupItem valueLabel="Guztiak" value="Todas" />
</ButtonGroup>

<Dropdown data={tecnologias} name=tec value=tecnologia order=orden title="Teknologia" multiple=true selectAllByDefault=true />

<Dropdown data={opciones_ccaa} name=ccaa value=cod_ccaa label=ccaa title="Autonomia-erkidegoa" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="Espainia osoa" />
</Dropdown>

```sql filtradas
SELECT
    nombre,
    tecnologia,
    color,
    orden_tecnologia,
    estado_grupo,
    estados,
    potencia_mw,
    n_unidades,
    CASE
        WHEN estado_grupo = 'Retirada' AND anio_retiro IS NOT NULL THEN 'Cerrada en ' || CAST(CAST(anio_retiro AS INTEGER) AS VARCHAR)
        WHEN anio_inicio_min IS NULL THEN 'Sin fecha'
        WHEN anio_inicio_min = anio_inicio_max THEN CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR) || '–' || CAST(CAST(anio_inicio_max AS INTEGER) AS VARCHAR)
    END AS fechas,
    anio_inicio_min,
    coalesce(propietario, 'Sin datos') AS propietario,
    coalesce(municipio || ' (' || provincia || ')', provincia) AS ubicacion,
    provincia,
    ccaa,
    precision_ubicacion,
    lat,
    lon,
    url_gem
FROM mother.centrales
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
```

```sql mapa
-- La paleta categórica de BubbleMap se asigna por orden de aparición: primero
-- va la mayor central de cada tecnología (en el orden de la paleta) y luego el
-- resto de mayor a menor, para que las pequeñas queden encima.
SELECT *
FROM (
    SELECT *, row_number() OVER (PARTITION BY tecnologia ORDER BY potencia_mw DESC NULLS LAST, nombre) = 1 AS primera
    FROM ${filtradas}
    WHERE potencia_mw > 0
)
ORDER BY primera DESC, CASE WHEN primera THEN orden_tecnologia END, potencia_mw DESC
```

```sql colores_mapa
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM ${filtradas}
WHERE potencia_mw > 0
GROUP BY tecnologia
ORDER BY orden
```

```sql totales_filtro
SELECT count(*) AS n_centrales, sum(potencia_mw) / 1000 AS gw
FROM ${filtradas}
```

<p class="text-sm text-gray-600 dark:text-gray-400">Aukeratutako iragazkiekin: {formatNumber(totales_filtro[0]?.n_centrales, 0)} zentral, {formatNumber(totales_filtro[0]?.gw, 1)} GW guztira.</p>

<BubbleMap
    data={mapa}
    lat=lat
    long=lon
    size=potencia_mw
    maxSize={26}
    value=tecnologia
    legendType=categorical
    colorPalette={[...new Map(Array.from(mapa ?? []).map(d => [d.tecnologia, d.color])).values()]}
    opacity={0.75}
    pointName=nombre
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Zentralak: Global Energy Monitor (CC BY 4.0)"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tecnologia', title: 'Teknologia'},
        {id: 'potencia_mw', title: 'Potentzia (MW)', fmt: 'num0'},
        {id: 'estados', title: 'Egoera'},
        {id: 'fechas', title: 'Abian jartzea'},
        {id: 'propietario', title: 'Jabea'},
        {id: 'ubicacion', title: 'Kokapena'}
    ]}
/>

<p class="text-xs text-gray-500">2.900 unitate inguruko koordenatuak (batez ere izapidetzen dauden eguzki- eta eoliko-parkeak) gutxi gorabeherakoak dira: udalerrian kokatu ohi dira, ez lursail zehatzean. Kanariak hego-mendebaldean agertzen dira: handitu mapa edo aukeratu erkidegoa iragazkian.</p>

---

## Martxan dagoena eta datorrena

Izapidetzen eta iragarrita dagoen potentziak instalatutakoa biderkatzen du, baina ez da aurreikuspen bat: proiektu horietako zati handi bat ez da inoiz eraikiko (inbentarioak berak geldituta edo bertan behera utzita gisa markatzen ditu urteak berririk gabe daramatzatenak). **Eraikitzen** dagoen potentzia da hurrengo bizpahiru urteetan zerbitzuan sartuko denaren seinalerik onena.

```sql por_estado
SELECT
    estado_grupo,
    min(orden_estado) AS orden_estado,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw
FROM mother.centrales_ccaa
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
GROUP BY estado_grupo, tecnologia
ORDER BY orden_estado, min(orden_tecnologia)
```

<BarChart
    data={por_estado}
    x=estado_grupo
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Potentzia egoeraren eta teknologiaren arabera (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={420}
/>

```sql por_ccaa
SELECT
    ccaa,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw,
    sum(sum(potencia_mw)) OVER (PARTITION BY ccaa) AS total_ccaa
FROM mother.centrales_ccaa
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
GROUP BY ccaa, tecnologia
ORDER BY total_ccaa DESC, min(orden_tecnologia)
```

<BarChart
    data={por_ccaa}
    x=ccaa
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Potentzia autonomia-erkidegoka — {inputs.estado} (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={520}
/>

---

## Nola aldatu den sorkuntza-parkea

Urtero zerbitzuan sartu eta itxi den potentzia, unitate bakoitza abian jarri zen dataren arabera. Ikus daitezke laurogeiko hamarkadako nuklearraren eta ikatzaren olatua, 2000ko hamarkadako ziklo konbinatuak eta eolikoa, 2010eko hamarkadako geldialdia eta 2019tik aurrerako olatu fotovoltaiko handia; eta bigarren grafikoan, ia ikatz guztiaren itxiera 2020 inguruan.

**Kontuz 2017arekin**: 790 parke fotovoltaiko txiki inguru (3,9 GW, 3 MWko mediana) 2017 abian jartze-urtetzat dutela agertzen dira inbentarioan. Ia ziur lehenetsitako data bat da (GEMek teknologia fotovoltaikoa «suposatzen» dien parkeak dira guztiak), eta gehienak 2007-2008ko lehen eguzki-boomekoak izango dira. Gailur horrek ez du islatzen 2017an eraiki zena.

```sql altas_bajas
SELECT
    anio,
    tecnologia,
    min(orden_tecnologia) AS orden,
    sum(mw_alta) / 1000 AS gw_alta,
    sum(mw_baja) / 1000 AS gw_baja
FROM mother.centrales_por_anio
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
  AND anio BETWEEN 1950 AND year(current_date)
GROUP BY anio, tecnologia
ORDER BY anio, orden
```

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_alta
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Urtero abian jarritako potentzia (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_baja
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Urtero itxitako potentzia (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

```sql acumulada
WITH anios AS (
    SELECT range AS anio FROM range(1950, year(current_date) + 1)
),
tecs AS (
    SELECT DISTINCT tecnologia FROM ${altas_bajas}
),
neta AS (
    SELECT anio, tecnologia, sum(gw_alta - gw_baja) AS gw FROM ${altas_bajas} GROUP BY ALL
)
SELECT
    a.anio,
    t.tecnologia,
    sum(coalesce(n.gw, 0)) OVER (PARTITION BY t.tecnologia ORDER BY a.anio) AS gw
FROM anios a
CROSS JOIN tecs t
LEFT JOIN neta n ON n.anio = a.anio AND n.tecnologia = t.tecnologia
ORDER BY a.anio
```

<AreaChart
    data={acumulada}
    x=anio
    y=gw
    series=tecnologia
    xFmt="0"
    yFmt=num0
    yAxisTitle="GW"
    title="Zerbitzuan dagoen potentzia metatua, alta- eta itxiera-daten arabera (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<p class="text-xs text-gray-500">Martxan dauden 8 GW inguruk (batez ere eguzki- eta eoliko-parke txikiak) ez dute abian jartze-urterik inbentarioan, eta ez dira grafiko hauetan agertzen; beraz, metatua egungo potentzia baino zertxobait beherago geratzen da. Baliteke potentzia-berritzeak eta inbentarioa sortu aurretik itxitako zentralak ez agertzea.</p>

---

## Zentral guztiak

```sql tabla
SELECT
    nombre,
    tecnologia,
    potencia_mw,
    n_unidades,
    estados,
    fechas,
    provincia,
    propietario,
    url_gem
FROM ${filtradas}
ORDER BY potencia_mw DESC NULLS LAST
```

<DataTable data={tabla} search=true rows=20>
    <Column id=nombre title="Zentrala" />
    <Column id=tecnologia title="Teknologia" />
    <Column id=potencia_mw title="MW" fmt=num0 />
    <Column id=n_unidades title="Unitateak" />
    <Column id=estados title="Egoera" />
    <Column id=fechas title="Abian jartzea" />
    <Column id=provincia title="Probintzia" />
    <Column id=propietario title="Jabea" />
    <Column id=url_gem title="Fitxa" contentType=link linkLabel="GEM ↗" openInNewTab=true />
</DataTable>

<DownloadCsvButton data={tabla} filename="spainfacts_centrales_electricas.csv" label="Deskargatu zentralak (CSV)" />

---

## Metodologia eta oharrak

- **Iturria**: Global Energy Monitorren (GEM) [Global Integrated Power Tracker](https://globalenergymonitor.org/projects/global-integrated-power-tracker/), 2026ko iraileko edizioa, CC BY 4.0 lizentziarekin. Espainia osorako zentral bakoitzaren kokapena, potentzia, egoera, jabea eta datak biltzen dituen inbentario ireki bakarra da, obretan, izapidetzen edo dagoeneko itxita daudenak barne.
- **Unitateak eta zentralak**: GEMek unitateak edo faseak erregistratzen ditu (zentral termiko bateko talde bakoitza, parke bateko fase bakoitza). Hemen zentralaren eta egoeraren arabera biltzen dira: zentral batek talde itxiak eta martxan dauden beste batzuk baditu, bi aldiz agertzen da, egoera bakoitzean behin. Puntu bakoitzaren teknologia potentziarik handiena duena da.
- **Egoerak**: *martxan*; *eraikitzen* (hasitako obrak); *izapidetzen* (eraiki aurrekoa: baimenak edo finantzaketa bidean); *iragarrita*; *geldituta* (geldiarazitako proiektuak, GEMek bi urtez berririk gabe geldituta ematen dituenak eta erreserban edo hibernatuta dauden zentralak); *bertan behera utzita* (lau urtez berririk gabeko proiektuak barne) eta *erretiratuta*.
- **Proiektuen zorroa puztuta dago**: izapidetzen 92 GW eguzki-energia eta 47 GW eoliko inguru agertzen dira, sistemak xurga dezakeena eta PNIECek aurreikusten duena baino askoz gehiago. Proiektu askok sarerako sarbide berberaren alde lehiatzen dute, eta iraungi egingo dira. Horregatik erakusten dira bereizita eraikitzen dagoen potentzia eta izapidetzen edo iragarrita dagoena.
- **Falta dena**: autokontsumoa eta teilatuetako fotovoltaikoa (8-9 GW inguru), instalazio txikiak (GEMek eguzki-energia ~1 MW-tik jasotzen du, eolikoa ~6 MW-tik, eta kanpoan uzten ditu minihidraulikoa eta industria-kogenerazioaren zati handi bat) eta bateriak, inbentarioak jasotzen ez dituenak; ponpaketa bai, hidraulikoaren barruan.
- **REErekiko alderaketa**: teknologiaka martxan dagoen potentzia Red Eléctricaren ofizialaren antzekoa da: fotovoltaikoa ~34 GW (REE ~32 GW autokontsumorik gabe), eolikoa ~31 GW (~32 GW), hidraulikoa ponpaketarekin ~16 GW (~17 GW), ziklo konbinatuak ~27 GW (~26 GW), nuklearra 7,4 GW gordin (7,1 GW garbi). Kogenerazioa ofiziala baino askoz beherago geratzen da (~1,4 GW ~5-6 GW-en aldean), GEMek handiak baino ez dituelako jasotzen. Ponpaketak ponpaketa duten zentral hidraulikoak biltzen ditu, hutsa zein mistoa.
- **Teknologiak**: *kogenerazioa* 150 MW baino gutxiagoko gas naturaleko unitateak dira, industriarako beroa ere ekoizten dutenak; *gas-turbinak eta motorrak* eta *lurrun-turbinak* batez ere Kanarietako, Balear Uharteetako, Ceutako eta Melillako fuel- eta gasolio-taldeak dira. Hiri-hondakinak ez-berriztagarritzat hartzen dira, eta ponpaketa, biltegiratze gisa, ez da berriztagarrien ehunekoan ere kontatzen.
- **Kokapena**: probintzia eta erkidegoa unitate bakoitzaren koordenatuen arabera esleitzen dira (itsasoko parke eolikoak, kostaldeko probintziarik hurbilenari).

Aipua: *Global Integrated Power Tracker, Global Energy Monitor, 2026ko iraila (CC BY 4.0)*.

<LastRefreshed prefix="Datuak eguneratuta" />
