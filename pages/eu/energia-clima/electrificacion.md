---
title: Ekonomiaren elektrifikazioa
description: "Espainiako industriak, garraioak, etxeek eta zerbitzuek kontsumitzen duten energiaren zenbat den elektrizitatea, nola berotzen diren etxeak probintziaka eta zenbat bero-ponpa dauden."
i18n_origen: da7631302ea5
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql principales
SELECT anio, cod_sector, sector, cuota_electricidad_pct, total, electricidad
FROM mother.electrificacion_sectores
WHERE cod_sector IN ('FC_E', 'FC_IND_E', 'FC_TRA_E', 'FC_OTH_HH_E', 'FC_OTH_CP_E')
ORDER BY anio
```

```sql ultimo
SELECT
    max(anio) AS anio,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_E') AS total,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_IND_E') AS industria,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_TRA_E') AS transporte,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_OTH_HH_E') AS hogares,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_OTH_CP_E') AS servicios
FROM ${principales}
WHERE anio = (SELECT max(anio) FROM ${principales})
```

```sql hace_10
SELECT
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_E') AS total,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_OTH_HH_E') AS hogares
FROM ${principales}
WHERE anio = (SELECT max(anio) - 10 FROM ${principales})
```

# ⚡ Ekonomiaren elektrifikazioa

Deskarbonizatzea ez da soilik elektrizitatea berriztagarriekin ekoiztea: gaur egun gasa, gasolioa edo gasolina erretzen diren lekuetan **elektrizitatea erabili** behar da, auto elektrikoetan, bero-ponpetan edo industria-prozesuetan. Zenbat aurreratu dugu?

<Grid cols=4>
    <KpiCard
        title="Elektrizitatea azken kontsumoan"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total, 1)} %"
        period="erabiltzen den energia guztiarena · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (ultimo[0].total - hace_10[0].total).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="10 urtean"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Etxeak"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares, 1)} %"
        period="beren energiarena elektrizitatea da"
        change={hace_10[0]?.hogares != null ? (ultimo[0].hogares - hace_10[0].hogares).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="10 urtean"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Industria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria, 1)} %"
        period="beren energiarena elektrizitatea da"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Garraioa"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte, 1)} %"
        period="ia dena trena da; auto elektrikoa ia ez da nabaritzen oraindik"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
        href="/eu/movilidad/coche-electrico"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electrificacion'
```

<Comparativa data={comparativa_internacional} />

## Erabiltzen den energiaren zenbat da elektrizitatea?

<LineChart
    data={principales}
    x=anio
    y=cuota_electricidad_pct
    series=sector
    yFmt='0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#7c3aed', '#94a3b8']}
/>

<p class="text-xs text-gray-500">Elektrizitatearen pisua sektore bakoitzaren energiaren azken kontsumoan (erabilera energetikoa, lehengairik gabe). Ekonomia osoan, elektrifikazioa ia geldirik dago laurden baten inguruan duela hamarkada bat geroztik: etxeek aurrera egiten dute, baina garraioak, beste edozein sektorek baino energia gehiago kontsumitzen duenak, petrolio-deribatuekin soilik dabil ia. "Merkataritza eta zerbitzu publikoak" atalak bulegoak, dendak, ospitaleak, ikastetxeak eta administrazioetako eraikinak barne hartzen ditu: Eurostatek ez ditu bereizten.</p>

```sql mix_sectores
SELECT
    e.sector,
    f.fuente,
    CASE f.orden
        WHEN 1 THEN e.cuota_electricidad_pct
        WHEN 2 THEN e.cuota_gas_pct
        WHEN 3 THEN e.cuota_petroleo_pct
        WHEN 4 THEN e.cuota_renovables_pct
        ELSE e.cuota_calor_carbon_pct
    END AS cuota
FROM mother.electrificacion_sectores e
CROSS JOIN (VALUES (1, 'Electricidad'), (2, 'Gas natural'), (3, 'Petróleo'), (4, 'Renovables y calor ambiente'), (5, 'Calor y carbón')) AS f(orden, fuente)
WHERE e.anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
  AND e.cod_sector IN ('FC_IND_E', 'FC_TRA_E', 'FC_OTH_HH_E', 'FC_OTH_CP_E', 'FC_OTH_AF_E')
ORDER BY e.sector, f.orden
```

<BarChart
    data={mix_sectores}
    x=sector
    y=cuota
    series=fuente
    swapXY=true
    type=stacked100
    yFmt=pct0
    colorPalette={['#1d4ed8', '#f59e0b', '#78716c', '#0f766e', '#cbd5e1']}
    title="Zer energiarekin dabilen sektore bakoitza ({ultimo[0]?.anio})"
/>

## Industria, adarrez adar

```sql ramas
SELECT sector, cuota_electricidad_pct, total, electricidad
FROM mother.electrificacion_sectores
WHERE tipo_sector = 'rama_industria' AND anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
ORDER BY cuota_electricidad_pct DESC
```

<BarChart
    data={ramas}
    x=sector
    y=cuota_electricidad_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor="#1d4ed8"
    title="Elektrizitatearen pisua industria-adar bakoitzaren energian"
/>

<p class="text-xs text-gray-500">Tenperatura oso altuko beroa behar duten adarrak (zementua, zeramika, beira, kimika) dira elektrifikatzen zailenak, eta gasaren mende jarraitzen dute; siderurgia neurri handi batean elektrikoa da jada, Espainian altzairu gehiena arku elektrikoko labeetan fabrikatzen delako txatarratik abiatuta.</p>

## Garraioa: energia elektriko gutxi, bidaiari asko

```sql transporte_energia
WITH t AS (
    SELECT
        max(anio) AS anio,
        max(total) FILTER (WHERE cod_sector = 'FC_TRA_E') AS total,
        max(electricidad) FILTER (WHERE cod_sector = 'FC_TRA_E') AS electricidad,
        max(total) FILTER (WHERE cod_sector = 'FC_TRA_ROAD_E') AS carretera,
        max(electricidad) FILTER (WHERE cod_sector = 'FC_TRA_ROAD_E') AS carretera_elec,
        max(total) FILTER (WHERE cod_sector = 'FC_TRA_RAIL_E') AS ferrocarril,
        max(electricidad) FILTER (WHERE cod_sector = 'FC_TRA_RAIL_E') AS ferrocarril_elec
    FROM mother.electrificacion_sectores
    WHERE anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
      AND cod_sector IN ('FC_TRA_E', 'FC_TRA_ROAD_E', 'FC_TRA_RAIL_E')
)
SELECT anio, 1 AS orden, 'Carretera' AS modo, 'Electricidad' AS energia, carretera_elec / total AS cuota FROM t
UNION ALL SELECT anio, 1, 'Carretera', 'Gasóleo, gasolina y otras', (carretera - carretera_elec) / total FROM t
UNION ALL SELECT anio, 2, 'Avión, barco y otros', 'Electricidad', (electricidad - carretera_elec - ferrocarril_elec) / total FROM t
UNION ALL SELECT anio, 2, 'Avión, barco y otros', 'Gasóleo, gasolina y otras', ((total - carretera - ferrocarril) - (electricidad - carretera_elec - ferrocarril_elec)) / total FROM t
UNION ALL SELECT anio, 3, 'Ferrocarril (tren, metro y tranvía)', 'Electricidad', ferrocarril_elec / total FROM t
UNION ALL SELECT anio, 3, 'Ferrocarril (tren, metro y tranvía)', 'Gasóleo, gasolina y otras', (ferrocarril - ferrocarril_elec) / total FROM t
ORDER BY orden, energia
```

```sql transporte_resumen
SELECT
    max(anio) AS anio,
    100 * sum(cuota) FILTER (WHERE orden = 3) AS ferrocarril_pct,
    100 * sum(cuota) FILTER (WHERE orden = 1) AS carretera_pct,
    100 * sum(cuota) FILTER (WHERE energia = 'Electricidad') AS electricidad_pct,
    100 * sum(cuota) FILTER (WHERE orden = 3 AND energia = 'Electricidad') / sum(cuota) FILTER (WHERE orden = 3) AS ferrocarril_elec_pct
FROM ${transporte_energia}
```

```sql reparto_modal
SELECT indicador_id, cod_pais, pais, anio, valor
FROM mother.internacional_europa
WHERE indicador_id IN ('tren_viajeros_pct', 'tren_mercancias_pct', 'electrificacion_transporte')
  AND cod_pais IN ('ES', 'EU27_2020')
ORDER BY anio
```

```sql reparto_ultimo
SELECT
    max(anio) FILTER (WHERE indicador_id = 'tren_viajeros_pct' AND cod_pais = 'ES') AS anio_viajeros,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_viajeros_pct' AND cod_pais = 'ES') AS viajeros_es,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_viajeros_pct' AND cod_pais = 'EU27_2020') AS viajeros_ue,
    max(anio) FILTER (WHERE indicador_id = 'tren_mercancias_pct' AND cod_pais = 'ES') AS anio_mercancias,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_mercancias_pct' AND cod_pais = 'ES') AS mercancias_es,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_mercancias_pct' AND cod_pais = 'EU27_2020') AS mercancias_ue
FROM ${reparto_modal}
```

```sql viajes_publico
WITH completos AS (
    SELECT anio FROM mother.movilidad_transporte_modos
    WHERE clave = 'total'
    GROUP BY anio HAVING count(DISTINCT mes) = 12
),
anual AS (
    SELECT
        m.anio,
        CASE
            WHEN m.clave = 'metro' THEN 'Metro'
            WHEN m.clave IN ('cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional') THEN 'Tren (Cercanías, media y larga distancia)'
            WHEN m.clave = 'autobus_urbano' THEN 'Autobús urbano'
            WHEN m.clave LIKE 'autobus_%' THEN 'Autobús interurbano'
            WHEN m.clave LIKE 'aereo_%' OR m.clave = 'maritimo' THEN 'Avión y barco (interior)'
            ELSE 'Autobús escolar, de empresa y discrecional'
        END AS modo,
        m.clave IN ('metro', 'cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional') AS sobre_railes,
        sum(m.viajeros) AS viajes,
        avg(m.poblacion) AS poblacion
    FROM mother.movilidad_transporte_modos m
    JOIN completos c ON c.anio = m.anio
    WHERE m.es_hoja
    GROUP BY ALL
)
SELECT anio, modo, sobre_railes, viajes, viajes / poblacion AS viajes_hab
FROM anual
ORDER BY anio, viajes DESC
```

```sql viajes_ultimo
SELECT
    anio,
    modo,
    CASE WHEN sobre_railes THEN 'Sobre raíles' ELSE 'Por carretera, aire o mar' END AS tipo,
    viajes,
    viajes_hab,
    viajes / sum(viajes) OVER () AS cuota
FROM ${viajes_publico}
WHERE anio = (SELECT max(anio) FROM ${viajes_publico})
ORDER BY viajes DESC
```

```sql viajes_resumen
SELECT
    anio,
    sum(viajes) FILTER (WHERE modo = 'Metro') AS metro,
    sum(viajes_hab) FILTER (WHERE modo = 'Metro') AS metro_hab,
    sum(viajes) FILTER (WHERE modo LIKE 'Tren%') AS tren,
    100 * sum(viajes) FILTER (WHERE sobre_railes) / sum(viajes) AS railes_pct
FROM ${viajes_publico}
GROUP BY anio
ORDER BY anio
```

Garraioa da gutxien elektrifikatutako sektorea: {#if transporte_resumen.length > 0}erabiltzen duen energiaren % {formatNumber(transporte_resumen[0].electricidad_pct, 1)} baino ez da elektrizitatea{/if}. Gutxi irudi dezake zazpi hiritan metroa, aldiriko trenak eta munduko abiadura handiko sare handienetako bat dituen herrialde batentzat, baina zifrak **energia neurtzen du, ez bidaiak**, eta tren elektrikoa hain da eraginkorra, ezen egiten duen lanerako oso energia gutxi behar baitu.

<Grid cols=4>
    <KpiCard
        title="Trenbideak erabiltzen duen garraio-energia"
        value={transporte_resumen[0]?.ferrocarril_pct}
        formattedValue="{formatNumber(transporte_resumen[0]?.ferrocarril_pct, 1)} %"
        period="trena, metroa eta tranbia · {transporte_resumen[0]?.anio}"
        source="Eurostat"
    />
    <KpiCard
        title="Trenez egindako bidaiari-km-ak"
        value={reparto_ultimo[0]?.viajeros_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.viajeros_es, 1)} %"
        period="autoaren eta autobusaren aldean, metroa kontatu gabe · EB: {formatNumber(reparto_ultimo[0]?.viajeros_ue, 1)} % · {reparto_ultimo[0]?.anio_viajeros}"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_viajeros_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Trenez doazen salgaiak"
        value={reparto_ultimo[0]?.mercancias_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.mercancias_es, 1)} %"
        period="lurreko tona-km-en artean · EB: {formatNumber(reparto_ultimo[0]?.mercancias_ue, 1)} % · {reparto_ultimo[0]?.anio_mercancias}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_mercancias_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Metroko bidaiak biztanleko"
        value={viajes_resumen[viajes_resumen.length - 1]?.metro_hab}
        formattedValue="{formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro_hab, 0)}"
        period="urtean · {formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro / 1e6, 0)} milioi bidaia {viajes_resumen[viajes_resumen.length - 1]?.anio}"
        source="INE"
        sparklineData={viajes_resumen.map(d => ({...d, y: d.metro_hab}))}
        href="/eu/movilidad/ferrocarril"
    />
</Grid>

<BarChart
    data={transporte_energia}
    x=modo
    y=cuota
    series=energia
    swapXY=true
    type=stacked
    sort=false
    yFmt=pct0
    colorPalette={['#1d4ed8', '#78716c']}
    title="Nora doan garraioaren energia ({transporte_energia[0]?.anio})"
/>

<p class="text-xs text-gray-500">Garraioaren azken energia-kontsumoa Espainian barrena (Eurostat). «Trenbidea»n bidaiari- eta salgai-trenak, metroa eta tranbia sartzen dira. «Hegazkina, itsasontzia eta beste batzuk» barneko hegaldiak eta itsasontziak eta olio- eta gas-hodiak dira; nazioarteko hegaldiak eta itsasontziak ez daude zifra honetan. Hodien ponpak elektrikoak dira: horregatik dago barra horretan zati urdin txiki bat.</p>

### Zergatik du hain pisu txikia: tren elektrikoaren eraginkortasuna

Zifrek argi uzten dute. {#if transporte_resumen.length > 0 && reparto_ultimo.length > 0}Trenbideak lurreko **bidaiari-km-en % {formatNumber(reparto_ultimo[0].viajeros_es, 1)}** eta **tona-km-en % {formatNumber(reparto_ultimo[0].mercancias_es, 1)}** egiten ditu garraioaren **energiaren % {formatNumber(transporte_resumen[0].ferrocarril_pct, 1)}** baino ez erabilita, eta energia horretan metroa eta tranbia ere sartzen dira, bidaiari-km-etan ez daudenak. Trenbidearen energiaren % {formatNumber(transporte_resumen[0].ferrocarril_elec_pct, 0)} elektrizitatea da jada.{/if} Bi arrazoi daude. Lehena motorra da: elektriko batek jasotzen duen energia ia osoa mugimendu bihurtzen du, eta gasolinazko edo gasoliozko batek gehiena beroan galtzen du. Bigarrena, altzairuzko gurpila errailaren gainean, pneumatiko batek asfaltoan baino askoz marruskadura txikiagoa duena, eta tren batek ehunka pertsona eramaten ditu aldi berean. Horregatik, bidaiariak eta salgaiak errepidetik trenera eramateak energia-kontsumoa askoz gehiago murrizten du elektrizitate-kontsumoa igotzen duena baino.

Alderantzizkoa ere betetzen da: garraioaren elektrifikazioa geldirik dago, bere energiaren {#if transporte_resumen.length > 0}% {formatNumber(transporte_resumen[0].carretera_pct, 0)}{:else}ia guztia{/if} errepidean gastatzen delako, eta han auto elektrikoa parkearen zati oso txikia da oraindik eta kamioiak ia ez dira hasi. Salgaietan, Espainia Europatik oso behera dago: ia dena kamioiz doa.

```sql transporte_paises
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = '${inputs.transporte_indicador}'
```

<ButtonGroup name=transporte_indicador title="Europarekin alderatu">
    <ButtonGroupItem valueLabel="Bidaiariak trenez" value="tren_viajeros_pct" default />
    <ButtonGroupItem valueLabel="Salgaiak trenez" value="tren_mercancias_pct" />
    <ButtonGroupItem valueLabel="Elektrizitatea garraioan" value="electrificacion_transporte" />
</ButtonGroup>

<Comparativa data={transporte_paises} />

<LineChart
    data={reparto_modal.filter(d => d.indicador_id === inputs.transporte_indicador)}
    x=anio
    y=valor
    series=pais
    yFmt='0.0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#c2410c', '#94a3b8']}
    title="Espainia EBren aldean"
/>

<p class="text-xs text-gray-500">Bidaiariak: bidaiari-km-en banaketa autoaren, autobusaren eta trenaren artean. Salgaiak: tona-km-en banaketa errepidearen, trenaren eta ibai-bideen artean (Espainian ez dago salgaien ibai-garraiorik). Eurostatek ez ditu metroa eta tranbia bidaiarien banaketan sartzen, ez baitago haien bidaiariek egiten dituzten kilometroen datu harmonizaturik, ezta hegazkinak ere.</p>

### Metroa bidaietan bai kontatzen da

Eurostaten bidaiari-km-ek metroa kanpoan uzten dute, baina INEk zenbatzen du garraio publikoko bide bakoitzean zenbat bidaia egiten diren. {#if viajes_resumen.length > 0}{viajes_resumen[viajes_resumen.length - 1].anio}an metroak {formatNumber(viajes_resumen[viajes_resumen.length - 1].metro / 1e6, 0)} milioi bidaia egin zituen, {#if viajes_resumen[viajes_resumen.length - 1].metro > viajes_resumen[viajes_resumen.length - 1].tren}tren guztiek batera baino gehiago ({formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} milioi){:else}trenaren {formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} milioien aldean{/if}, eta garraio publikoko 100 bidaiatik {formatNumber(viajes_resumen[viajes_resumen.length - 1].railes_pct, 0)} erraletan egin ziren.{/if}

<BarChart
    data={viajes_ultimo}
    x=modo
    y=viajes_hab
    series=tipo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#1d4ed8', '#94a3b8']}
    title="Garraio publikoko bidaiak biztanleko eta urteko ({viajes_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">INEren Bidaiarien Garraioaren Estatistika: bidaiak (ez kilometroak) metroan, autobusean, trenean, hegazkinean eta itsasontzian Espainian barrena, biztanleriarekin zatituta. Metroko bidaia bat AVEko bat baino askoz laburragoa da; beraz, zifra hauek ezin zaizkie goiko bidaiari-km-ei batu. Tranbiak ez du bere partida propiorik estatistika honetan. «Erraletan» ez da beti elektrikoa: distantzia ertaineko linea batzuk gasoliozkoak dira oraindik.</p>

## Nola berotzen diren etxeak

```sql calefaccion
SELECT anio, combustible, cuota_pct AS cuota, tj
FROM mother.electrificacion_hogares
WHERE cod_uso = 'FC_OTH_HH_E_SH'
ORDER BY anio
```

```sql agua
SELECT combustible, cuota_pct FROM mother.electrificacion_hogares
WHERE cod_uso = 'FC_OTH_HH_E_WH' AND anio = (SELECT max(anio) FROM mother.electrificacion_hogares)
ORDER BY cuota_pct DESC
```

<BarChart
    data={calefaccion}
    x=anio
    y=cuota
    series=combustible
    type=stacked100
    yFmt=pct0
    xFmt="####"
    colorPalette={['#1d4ed8', '#f59e0b', '#78716c', '#65a30d', '#fde047', '#0f766e', '#f472b6', '#cbd5e1']}
    title="Etxeetako berokuntzarako energia, erregaiaren arabera"
/>

<p class="text-xs text-gray-500">Energiari dagokionez, etxeetako berokuntza ia zati berdinetan banatzen da biomasaren (egurra eta pelletak, batez ere landa-eremuetan), gas naturalaren eta gasolioaren edo butanoaren artean; elektrizitateak eta bero-ponpek airetik hartzen duten beroak 15 % inguru egiten dute. Bero-ponpa batek airearen doako energia aprobetxatzen du: elektrizitatearen kWh bakoitzeko 3 edo 4 bero ematen ditu, eta Eurostatek zati hori "giro-bero" gisa zenbatzen du.</p>

```sql bombas
SELECT anio, tecnologia, mw / 1000 AS gw
FROM mother.electrificacion_bombas_calor
ORDER BY anio
```

<BarChart
    data={bombas}
    x=anio
    y=gw
    series=tecnologia
    type=stacked
    yFmt=num1
    xFmt="####"
    yAxisTitle="GW termiko"
    title="Instalatutako bero-ponpak (potentzia termikoa)"
/>

<p class="text-xs text-gray-500">Gehienak aire-aire ekipo itzulgarriak dira, hau da, beroa ere ematen duten split motako aire girotuko aparatuak; Eurostatek bero-ponpatzat hartzen ditu, nahiz eta asko batez ere udan erabiltzen diren. Aire-ur aerotermia (galdara bat ordezkatzen duena eta erradiadoreak, lurzoru erradiatzailea eta ur beroa berotzen dituena) zati txiki bat da oraindik.</p>

```sql provincias
SELECT
    cod AS cod_prov, nombre AS provincia, viviendas,
    cuota_electricidad_pct, cuota_gas_pct, cuota_petroleo_pct,
    100.0 * otros / nullif(viviendas, 0) AS cuota_otros_pct
FROM mother.electrificacion_calefaccion_provincia
WHERE nivel = 'provincia'
ORDER BY ${inputs.calefaccion_tec} DESC
```

```sql espana_viv
SELECT *, 100.0 * otros / nullif(viviendas, 0) AS cuota_otros_pct
FROM mother.electrificacion_calefaccion_provincia WHERE nivel = 'pais'
```

### Zerekin berotzen diren etxebizitzak, probintziaka

<ButtonGroup name=calefaccion_tec title="Erregaia">
    <ButtonGroupItem valueLabel="Elektrizitatea" value="cuota_electricidad_pct" default />
    <ButtonGroupItem valueLabel="Gas naturala" value="cuota_gas_pct" />
    <ButtonGroupItem valueLabel="Gasolioa eta deribatuak" value="cuota_petroleo_pct" />
    <ButtonGroupItem valueLabel="Biomasa eta beste batzuk" value="cuota_otros_pct" />
</ButtonGroup>

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value={inputs.calefaccion_tec}
    valueFmt='0"%"'
    colorPalette={({
        cuota_gas_pct: ['#fffbeb', '#fcd34d', '#d97706'],
        cuota_petroleo_pct: ['#fafaf9', '#a8a29e', '#57534e'],
        cuota_otros_pct: ['#f7fee7', '#a3e635', '#4d7c0f']
    })[inputs.calefaccion_tec] ?? ['#fff7ed', '#93c5fd', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Elektrizitatea', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas naturala', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasolioa eta deribatuak', fmt: '0"%"'},
        {id: 'cuota_otros_pct', title: 'Biomasa eta beste batzuk', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=viviendas title="Berokuntza duten etxebizitzak" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Elektrizitatea" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas naturala" fmt='0"%"' contentType=bar barColor="#fde68a" />
    <Column id=cuota_petroleo_pct title="Gasolioa eta deribatuak" fmt='0"%"' contentType=bar barColor="#d6d3d1" />
    <Column id=cuota_otros_pct title="Biomasa eta beste batzuk" fmt='0"%"' contentType=bar barColor="#d9f99d" />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}Espainian, berokuntza duten 100 etxebizitzatik {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)}k elektrikoa dute, {formatNumber(espana_viv[0].cuota_gas_pct, 0)}k gas naturala, {formatNumber(espana_viv[0].cuota_petroleo_pct, 0)}k gasolioa edo deribatuak eta {formatNumber(espana_viv[0].cuota_otros_pct, 0)}k biomasa edo beste batzuk. {/if}Hegoaldean eta Kanarietan, negu epelekin, erradiadore elektrikoak eta aire girotua nagusitzen dira; iparraldeko barnealdean, negu hotz eta luzeekin, gas naturala eta gasolioa; eta landa-eremu hotzenetan (Ourense, Lugo, Soria, Cuenca) eta Jaénen, olibe-hezur asko erretzen baita, biomasa. INEren Biztanleriaren eta Etxebizitzen Funtsezko Ezaugarrien Inkesta 2021 (laginketa bidezkoa): etxebizitzak zenbatzen ditu, ez energia, eta lau erantzun baino ez ditu eskaintzen. «Biomasa eta beste batzuk» INEren «Beste batzuk» erantzuna da: praktikan batez ere egurra, pelletak eta olibe-hezurra, baina ikatza eta eguzki-energia ere sartzen dira. Bero-ponpa ezin da probintziaka bereizi: inkestak «Elektrizitatea»ren barruan zenbatzen du, erradiadoreekin eta aire girotuarekin batera, eta goiko bero-ponpen zifra (Eurostat) Espainia osorako baino ez dago.</p>

---

## Iturriak eta oharrak

- **[Eurostat – Energia-balantze osoak (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: energiaren azken kontsumoa sektoreka, industria-adarka eta erregaika, 1990etik azken urtera arte. Beste herrialdeekiko alderaketak taula eta definizio berak erabiltzen ditu (elektrizitatea energiaren azken kontsumoaren gainean, erabilera energetikoa) eta Europako herrialdeak baino ez ditu hartzen; Norvegia eta Suedia erreferentzia gisa agertzen dira (ertz etena), Europako ekonomia elektrifikatuenak direlako.
- **[Eurostat – Bidaiarien garraioaren banaketa modala (tran_hv_psmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_psmod/default/table)** eta **[salgaiena (tran_hv_frmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_frmod/default/table)**: autoz, autobusez eta trenez egindako bidaiari-km-en % eta errepidez, trenez eta ibai-bideetatik egindako tona-km-en %. Ez dituzte metroa, tranbia eta hegazkina sartzen.
- **[INE – Bidaiarien Garraioaren Estatistika, 20239 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=20239)**: hileko bidaiak metroan, hiri- eta hiriarteko autobusean, trenean, hegazkinean eta itsasontzian. Bidaiak zenbatzen ditu, ez kilometroak.
- **[Eurostat – Etxeetako energia-kontsumoa erabileraren arabera (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: berokuntza, ur beroa, sukaldaritza, hozkuntza eta argiztapena erregaika, 2010etik (Espainian IDAEk egiten du).
- **[Eurostat – Bero-ponpak (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potentzia termikoa teknologiaka.
- **[INE – ECEPOV 2021, 56784 taula](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: berokuntza duten etxebizitza nagusiak, erregai motaren eta probintziaren arabera.
- Ez dago eraikin publikoetako berokuntza-sistemari buruzko estatistika ofizial irekirik: erkidegoetako ziurtagiri energetikoen erregistroek ez dute erregaia jasotzen.

<LastRefreshed prefix="Datuak eguneratuta" />
