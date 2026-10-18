---
title: Electrificació de l'economia
description: "Quina part de l'energia que consumeixen la indústria, el transport, les llars i els serveis a Espanya és electricitat, com s'escalfen les cases per província i quantes bombes de calor hi ha."
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

# ⚡ L'electrificació de l'economia

Descarbonitzar no és només produir l'electricitat amb renovables: també cal **fer servir electricitat** allà on avui es cremen gas, gasoil o gasolina, en cotxes elèctrics, bombes de calor o processos industrials. Quant hem avançat?

<Grid cols=4>
    <KpiCard
        title="Electricitat en el consum final"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total, 1)} %"
        period="de tota l'energia que es fa servir · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (ultimo[0].total - hace_10[0].total).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anys"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Llars"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares, 1)} %"
        period="de la seva energia és electricitat"
        change={hace_10[0]?.hogares != null ? (ultimo[0].hogares - hace_10[0].hogares).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anys"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Indústria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria, 1)} %"
        period="de la seva energia és electricitat"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Transport"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte, 1)} %"
        period="gairebé tot és tren; el cotxe elèctric encara amb prou feines es nota"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
        href="/ca/movilidad/coche-electrico"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electrificacion'
```

<Comparativa data={comparativa_internacional} />

## Quina part de l'energia que es fa servir és electricitat?

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

<p class="text-xs text-gray-500">Pes de l'electricitat en el consum final d'energia de cada sector (ús energètic, sense matèries primeres). En el conjunt de l'economia l'electrificació està pràcticament estancada al voltant d'una quarta part des de fa una dècada: les llars avancen, però el transport, que gasta més energia que cap altre sector, continua funcionant gairebé només amb derivats del petroli. "Comerç i serveis públics" inclou oficines, comerços, hospitals, escoles i edificis de les administracions: Eurostat no els separa.</p>

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
    title="Amb quina energia funciona cada sector ({ultimo[0]?.anio})"
/>

## La indústria, branca a branca

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
    title="Pes de l'electricitat en l'energia de cada branca industrial"
/>

<p class="text-xs text-gray-500">Les branques que necessiten calor a molt alta temperatura (ciment, ceràmica, vidre, química) són les més difícils d'electrificar i continuen depenent del gas; la siderúrgia ja és en bona part elèctrica perquè a Espanya la major part de l'acer es fabrica en forns d'arc elèctric a partir de ferralla.</p>

## El transport: poca energia elèctrica, molts viatgers

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

El transport és el sector menys electrificat: {#if transporte_resumen.length > 0}només un {formatNumber(transporte_resumen[0].electricidad_pct, 1)} % de l'energia que gasta és electricitat{/if}. Pot semblar poc per a un país amb metro a set ciutats, Rodalies i una de les xarxes d'alta velocitat més grans del món, però la xifra mesura **energia, no viatges**, i el tren elèctric és tan eficient que en gasta molt poca per a la feina que fa.

<Grid cols=4>
    <KpiCard
        title="Energia del transport que gasta el ferrocarril"
        value={transporte_resumen[0]?.ferrocarril_pct}
        formattedValue="{formatNumber(transporte_resumen[0]?.ferrocarril_pct, 1)} %"
        period="tren, metro i tramvia · {transporte_resumen[0]?.anio}"
        source="Eurostat"
    />
    <KpiCard
        title="Viatgers-km que van en tren"
        value={reparto_ultimo[0]?.viajeros_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.viajeros_es, 1)} %"
        period="davant del cotxe i l'autobús, sense comptar el metro · UE: {formatNumber(reparto_ultimo[0]?.viajeros_ue, 1)} % · {reparto_ultimo[0]?.anio_viajeros}"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_viajeros_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Mercaderies que van en tren"
        value={reparto_ultimo[0]?.mercancias_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.mercancias_es, 1)} %"
        period="de les tones-km per terra · UE: {formatNumber(reparto_ultimo[0]?.mercancias_ue, 1)} % · {reparto_ultimo[0]?.anio_mercancias}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_mercancias_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Viatges en metro per habitant"
        value={viajes_resumen[viajes_resumen.length - 1]?.metro_hab}
        formattedValue="{formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro_hab, 0)}"
        period="l'any · {formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro / 1e6, 0)} milions de viatges el {viajes_resumen[viajes_resumen.length - 1]?.anio}"
        source="INE"
        sparklineData={viajes_resumen.map(d => ({...d, y: d.metro_hab}))}
        href="/ca/movilidad/ferrocarril"
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
    title="On va l'energia del transport ({transporte_energia[0]?.anio})"
/>

<p class="text-xs text-gray-500">Consum final d'energia del transport dins d'Espanya (Eurostat). «Ferrocarril» inclou trens de viatgers i de mercaderies, metro i tramvia. «Avió, vaixell i altres» són els vols i vaixells nacionals i els oleoductes i gasoductes; els vols i vaixells internacionals no són en aquesta xifra. Les bombes dels oleoductes i gasoductes són elèctriques: d'aquí la petita part blava d'aquesta barra.</p>

### Per què pesa tan poc: l'eficiència del tren elèctric

Les xifres ho deixen clar. {#if transporte_resumen.length > 0 && reparto_ultimo.length > 0}El ferrocarril fa el **{formatNumber(reparto_ultimo[0].viajeros_es, 1)} % dels viatgers-km** per terra i el **{formatNumber(reparto_ultimo[0].mercancias_es, 1)} % de les tones-km** amb només el **{formatNumber(transporte_resumen[0].ferrocarril_pct, 1)} % de l'energia** del transport, tot i que aquesta energia inclou també el metro i el tramvia, que no són als viatgers-km. Del ferrocarril, un {formatNumber(transporte_resumen[0].ferrocarril_elec_pct, 0)} % de l'energia ja és electricitat.{/if} Hi ha dos motius. El primer és el motor: un d'elèctric converteix en moviment gairebé tota l'energia que rep, mentre que un de gasolina o gasoil en perd la major part en calor. El segon és la roda d'acer sobre el carril, que frega molt menys que un pneumàtic sobre l'asfalt, i un tren porta centenars de persones alhora. Per això passar viatgers i mercaderies de la carretera al tren redueix el consum d'energia molt més del que augmenta el consum d'electricitat.

El contrari també es compleix: l'electrificació del transport està estancada perquè {#if transporte_resumen.length > 0}el {formatNumber(transporte_resumen[0].carretera_pct, 0)} %{:else}gairebé tota{/if} de la seva energia es gasta a la carretera, i allà el cotxe elèctric encara és una part molt petita del parc i els camions gairebé no han començat. En mercaderies, Espanya és molt per sota d'Europa: gairebé tot va en camió.

```sql transporte_paises
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = '${inputs.transporte_indicador}'
```

<ButtonGroup name=transporte_indicador title="Comparar amb Europa">
    <ButtonGroupItem valueLabel="Viatgers en tren" value="tren_viajeros_pct" default />
    <ButtonGroupItem valueLabel="Mercaderies en tren" value="tren_mercancias_pct" />
    <ButtonGroupItem valueLabel="Electricitat en el transport" value="electrificacion_transporte" />
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
    title="Espanya davant de la UE"
/>

<p class="text-xs text-gray-500">Viatgers: repartiment dels viatgers-km entre cotxe, autobús i tren. Mercaderies: repartiment de les tones-km entre carretera, tren i vies navegables (a Espanya no hi ha transport fluvial de mercaderies). Eurostat no inclou el metro ni el tramvia en el repartiment de viatgers perquè no hi ha dades harmonitzades dels quilòmetres que recorren els seus viatgers, ni tampoc els avions.</p>

### El metro sí que compta en els viatges

Els viatgers-km d'Eurostat deixen fora el metro, però l'INE compta quants viatges es fan en cada mitjà de transport públic. {#if viajes_resumen.length > 0}El {viajes_resumen[viajes_resumen.length - 1].anio} el metro va fer {formatNumber(viajes_resumen[viajes_resumen.length - 1].metro / 1e6, 0)} milions de viatges, {#if viajes_resumen[viajes_resumen.length - 1].metro > viajes_resumen[viajes_resumen.length - 1].tren}més que tots els trens junts ({formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} milions){:else}davant de {formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} milions en tren{/if}, i {formatNumber(viajes_resumen[viajes_resumen.length - 1].railes_pct, 0)} de cada 100 viatges en transport públic van ser sobre rails.{/if}

<BarChart
    data={viajes_ultimo}
    x=modo
    y=viajes_hab
    series=tipo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#1d4ed8', '#94a3b8']}
    title="Viatges en transport públic per habitant i any ({viajes_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estadística de Transport de Viatgers de l'INE: viatges (no quilòmetres) en metro, autobús, tren, avió i vaixell dins d'Espanya, dividits per la població. Un viatge en metro és molt més curt que un en AVE, així que aquestes xifres no es poden sumar als viatgers-km de més amunt. El tramvia no té una partida pròpia en aquesta estadística. «Sobre rails» no sempre és elèctric: algunes línies de mitjana distància encara són de gasoil.</p>

## Com s'escalfen les cases

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
    title="Energia per a calefacció a les llars, per combustible"
/>

<p class="text-xs text-gray-500">En energia, la calefacció de les llars es reparteix gairebé a parts iguals entre biomassa (llenya i pèl·lets, sobretot en zones rurals), gas natural i gasoil o butà; l'electricitat i la calor que capten de l'aire les bombes de calor sumen al voltant d'un 15 %. Una bomba de calor aprofita energia gratuïta de l'aire: per cada kWh d'electricitat en lliura 3 o 4 de calor, i Eurostat compta aquesta part com a "calor ambient".</p>

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
    yAxisTitle="GW tèrmics"
    title="Bombes de calor instal·lades (potència tèrmica)"
/>

<p class="text-xs text-gray-500">La gran majoria són equips aire-aire reversibles, és a dir, aparells d'aire condicionat tipus split que també fan calor; Eurostat els compta com a bombes de calor encara que molts es facin servir sobretot a l'estiu. L'aerotèrmia aire-aigua (la que substitueix una caldera i escalfa radiadors, terra radiant i aigua calenta) és encara una part petita.</p>

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

### Amb què s'escalfen els habitatges, per província

<ButtonGroup name=calefaccion_tec title="Combustible">
    <ButtonGroupItem valueLabel="Electricitat" value="cuota_electricidad_pct" default />
    <ButtonGroupItem valueLabel="Gas natural" value="cuota_gas_pct" />
    <ButtonGroupItem valueLabel="Gasoil i derivats" value="cuota_petroleo_pct" />
    <ButtonGroupItem valueLabel="Biomassa i altres" value="cuota_otros_pct" />
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Electricitat', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas natural', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasoil i derivats', fmt: '0"%"'},
        {id: 'cuota_otros_pct', title: 'Biomassa i altres', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=viviendas title="Habitatges amb calefacció" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Electricitat" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas natural" fmt='0"%"' contentType=bar barColor="#fde68a" />
    <Column id=cuota_petroleo_pct title="Gasoil i derivats" fmt='0"%"' contentType=bar barColor="#d6d3d1" />
    <Column id=cuota_otros_pct title="Biomassa i altres" fmt='0"%"' contentType=bar barColor="#d9f99d" />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}A Espanya, de cada 100 habitatges amb calefacció {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)} la tenen elèctrica, {formatNumber(espana_viv[0].cuota_gas_pct, 0)} de gas natural, {formatNumber(espana_viv[0].cuota_petroleo_pct, 0)} de gasoil o derivats i {formatNumber(espana_viv[0].cuota_otros_pct, 0)} de biomassa o altres. {/if}Al sud i a les Canàries, amb hiverns suaus, predominen els radiadors elèctrics i l'aire condicionat; a l'interior nord, amb hiverns freds i llargs, el gas natural i el gasoil; i a l'Espanya rural més freda (Ourense, Lugo, Sòria, Conca) i a Jaén, on es crema molt pinyol d'oliva, la biomassa. Enquesta de Característiques Essencials de la Població i els Habitatges 2021 de l'INE (mostral): compta habitatges, no energia, i només ofereix quatre respostes. «Biomassa i altres» és la resposta «Altres» de l'INE, que a la pràctica és sobretot llenya, pèl·lets i pinyol d'oliva, però també inclou carbó i solar. La bomba de calor no es pot separar per província: l'enquesta la compta dins d'«Electricitat» amb els radiadors i l'aire condicionat, i la xifra de bombes de calor de més amunt (Eurostat) només existeix per al conjunt d'Espanya.</p>

---

## Fonts i notes

- **[Eurostat – Balanços energètics complets (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consum final d'energia per sector, branca industrial i combustible, 1990-últim any. La comparació amb altres països fa servir la mateixa taula i la mateixa definició (electricitat entre consum final d'energia, ús energètic) i només cobreix països europeus; Noruega i Suècia hi apareixen com a referència (vora discontínua) perquè són les economies més electrificades d'Europa.
- **[Eurostat – Repartiment modal del transport de viatgers (tran_hv_psmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_psmod/default/table)** i **[de mercaderies (tran_hv_frmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_frmod/default/table)**: % dels viatgers-km en cotxe, autobús i tren i de les tones-km per carretera, tren i vies navegables. No inclouen metro, tramvia ni avió.
- **[INE – Estadística de Transport de Viatgers, taula 20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239)**: viatges mensuals en metro, autobús urbà i interurbà, tren, avió i vaixell. Compta viatges, no quilòmetres.
- **[Eurostat – Consum d'energia de les llars per ús (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacció, aigua calenta, cuina, refrigeració i il·luminació per combustible, des del 2010 (a Espanya l'elabora l'IDAE).
- **[Eurostat – Bombes de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potència tèrmica per tecnologia.
- **[INE – ECEPOV 2021, taula 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: habitatges principals amb calefacció per tipus de combustible i província.
- No hi ha estadística oficial oberta del sistema de calefacció dels edificis públics: els registres de certificats energètics de les comunitats no en recullen el combustible.

<LastRefreshed prefix="Dades actualitzades" />
