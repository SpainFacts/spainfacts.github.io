---
title: Ekonomiaren elektrifikazioa
description: "Espainiako industriak, garraioak, etxeek eta zerbitzuek kontsumitzen duten energiaren zenbat den elektrizitatea, nola berotzen diren etxeak probintziaka eta zenbat bero-ponpa dauden."
i18n_origen: a287d12777fb
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
SELECT anio, cod_sector, sector, cuota_electricidad, total, electricidad
FROM mother.electrificacion_sectores
WHERE cod_sector IN ('FC_E', 'FC_IND_E', 'FC_TRA_E', 'FC_OTH_HH_E', 'FC_OTH_CP_E')
ORDER BY anio
```

```sql ultimo
SELECT
    max(anio) AS anio,
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_E') AS total,
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_IND_E') AS industria,
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_TRA_E') AS transporte,
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_OTH_HH_E') AS hogares,
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_OTH_CP_E') AS servicios
FROM ${principales}
WHERE anio = (SELECT max(anio) FROM ${principales})
```

```sql hace_10
SELECT
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_E') AS total,
    max(cuota_electricidad) FILTER (WHERE cod_sector = 'FC_OTH_HH_E') AS hogares
FROM ${principales}
WHERE anio = (SELECT max(anio) - 10 FROM ${principales})
```

# ⚡ Ekonomiaren elektrifikazioa

Deskarbonizatzea ez da soilik elektrizitatea berriztagarriekin ekoiztea: gaur egun gasa, gasolioa edo gasolina erretzen diren lekuetan **elektrizitatea erabili** behar da, auto elektrikoetan, bero-ponpetan edo industria-prozesuetan. Zenbat aurreratu dugu?

<Grid cols=4>
    <KpiCard
        title="Elektrizitatea azken kontsumoan"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total / 0.01, 1)} %"
        period="erabiltzen den energia guztiarena · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (100 * (ultimo[0].total - hace_10[0].total)).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="10 urtean"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Etxeak"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares / 0.01, 1)} %"
        period="beren energiarena elektrizitatea da"
        change={hace_10[0]?.hogares != null ? (100 * (ultimo[0].hogares - hace_10[0].hogares)).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="10 urtean"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Industria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria / 0.01, 1)} %"
        period="beren energiarena elektrizitatea da"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Garraioa"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte / 0.01, 1)} %"
        period="ia dena trena da; auto elektrikoa ia ez da nabaritzen oraindik"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
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
    y=cuota_electricidad
    series=sector
    yFmt=pct0
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#7c3aed', '#94a3b8']}
/>

<p class="text-xs text-gray-500">Elektrizitatearen pisua sektore bakoitzaren energiaren azken kontsumoan (erabilera energetikoa, lehengairik gabe). Ekonomia osoan, elektrifikazioa ia geldirik dago laurden baten inguruan duela hamarkada bat geroztik: etxeek aurrera egiten dute, baina garraioak, beste edozein sektorek baino energia gehiago kontsumitzen duenak, petrolio-deribatuekin soilik dabil ia. "Merkataritza eta zerbitzu publikoak" atalak bulegoak, dendak, ospitaleak, ikastetxeak eta administrazioetako eraikinak barne hartzen ditu: Eurostatek ez ditu bereizten.</p>

```sql mix_sectores
SELECT
    sector,
    unnest(['Electricidad', 'Gas natural', 'Petróleo', 'Renovables y calor ambiente', 'Calor y carbón']) AS fuente,
    unnest([electricidad, gas_natural, petroleo, renovables, coalesce(calor, 0) + coalesce(carbon, 0)]) / total AS cuota
FROM mother.electrificacion_sectores
WHERE anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
  AND cod_sector IN ('FC_IND_E', 'FC_TRA_E', 'FC_OTH_HH_E', 'FC_OTH_CP_E', 'FC_OTH_AF_E')
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
SELECT sector, cuota_electricidad, total, electricidad
FROM mother.electrificacion_sectores
WHERE es_rama_industrial AND anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
ORDER BY cuota_electricidad DESC
```

<BarChart
    data={ramas}
    x=sector
    y=cuota_electricidad
    swapXY=true
    sort=false
    yFmt=pct0
    fillColor="#1d4ed8"
    title="Elektrizitatearen pisua industria-adar bakoitzaren energian"
/>

<p class="text-xs text-gray-500">Tenperatura oso altuko beroa behar duten adarrak (zementua, zeramika, beira, kimika) dira elektrifikatzen zailenak, eta gasaren mende jarraitzen dute; siderurgia neurri handi batean elektrikoa da jada, Espainian altzairu gehiena arku elektrikoko labeetan fabrikatzen delako txatarratik abiatuta.</p>

## Nola berotzen diren etxeak

```sql calefaccion
SELECT anio, combustible, cuota, tj
FROM mother.electrificacion_hogares
WHERE cod_uso = 'FC_OTH_HH_E_SH'
ORDER BY anio
```

```sql agua
SELECT combustible, cuota FROM mother.electrificacion_hogares
WHERE cod_uso = 'FC_OTH_HH_E_WH' AND anio = (SELECT max(anio) FROM mother.electrificacion_hogares)
ORDER BY cuota DESC
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
SELECT cod_prov, provincia, viviendas, cuota_electricidad, cuota_gas, cuota_petroleo
FROM mother.electrificacion_calefaccion_provincia
WHERE cod_prov <> '00'
ORDER BY cuota_electricidad DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE cod_prov = '00'
```

### Elektrizitatearekin berotzen diren etxebizitzak, probintziaka

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_electricidad"
    valueFmt="pct0"
    colorPalette={['#fff7ed', '#93c5fd', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad', title: 'Elektrizitatea', fmt: 'pct0'},
        {id: 'cuota_gas', title: 'Gas naturala', fmt: 'pct0'},
        {id: 'cuota_petroleo', title: 'Gasolioa eta deribatuak', fmt: 'pct0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=viviendas title="Berokuntza duten etxebizitzak" fmt=num0 />
    <Column id=cuota_electricidad title="Elektrizitatea" fmt=pct0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas title="Gas naturala" fmt=pct0 />
    <Column id=cuota_petroleo title="Gasolioa eta deribatuak" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}Espainian, berokuntza duten 100 etxebizitzatik {formatNumber(100 * espana_viv[0].cuota_electricidad, 0)}k elektrikoa dute. {/if}Hegoaldean eta Kanarietan, negu epelekin, erradiadore elektrikoak eta aire girotua nagusitzen dira; iparraldeko barnealdean, negu hotz eta luzeekin, gas naturala eta gasolioa. INEren Biztanleriaren eta Etxebizitzen Funtsezko Ezaugarrien Inkesta 2021 (laginketa bidezkoa): etxebizitzak zenbatzen ditu, ez energia, eta ez du bereizten erradiadore bat eta bero-ponpa bat.</p>

---

## Iturriak eta oharrak

- **[Eurostat – Energia-balantze osoak (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: energiaren azken kontsumoa sektoreka, industria-adarka eta erregaika, 1990etik azken urtera arte. Beste herrialdeekiko alderaketak taula eta definizio berak erabiltzen ditu (elektrizitatea energiaren azken kontsumoaren gainean, erabilera energetikoa) eta Europako herrialdeak baino ez ditu hartzen; Norvegia eta Suedia erreferentzia gisa agertzen dira (ertz etena), Europako ekonomia elektrifikatuenak direlako.
- **[Eurostat – Etxeetako energia-kontsumoa erabileraren arabera (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: berokuntza, ur beroa, sukaldaritza, hozkuntza eta argiztapena erregaika, 2010etik (Espainian IDAEk egiten du).
- **[Eurostat – Bero-ponpak (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potentzia termikoa teknologiaka.
- **[INE – ECEPOV 2021, 56784 taula](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: berokuntza duten etxebizitza nagusiak, erregai motaren eta probintziaren arabera.
- Ez dago eraikin publikoetako berokuntza-sistemari buruzko estatistika ofizial irekirik: erkidegoetako ziurtagiri energetikoen erregistroek ez dute erregaia jasotzen.

<LastRefreshed prefix="Datuak eguneratuta" />
