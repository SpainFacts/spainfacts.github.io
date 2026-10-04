---
title: Ekonomiaren elektrifikazioa
description: "Espainiako industriak, garraioak, etxeek eta zerbitzuek kontsumitzen duten energiaren zenbat den elektrizitatea, nola berotzen diren etxeak probintziaka eta zenbat bero-ponpa dauden."
i18n_origen: aaa2f7109662
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
    yFmt='0"%"'
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
    yFmt='0"%"'
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
SELECT cod AS cod_prov, nombre AS provincia, viviendas, cuota_electricidad_pct, cuota_gas_pct, cuota_petroleo_pct
FROM mother.electrificacion_calefaccion_provincia
WHERE nivel = 'provincia'
ORDER BY cuota_electricidad_pct DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE nivel = 'pais'
```

### Elektrizitatearekin berotzen diren etxebizitzak, probintziaka

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_electricidad_pct"
    valueFmt='0"%"'
    colorPalette={['#fff7ed', '#93c5fd', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Elektrizitatea', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas naturala', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasolioa eta deribatuak', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=viviendas title="Berokuntza duten etxebizitzak" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Elektrizitatea" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas naturala" fmt='0"%"' />
    <Column id=cuota_petroleo_pct title="Gasolioa eta deribatuak" fmt='0"%"' />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}Espainian, berokuntza duten 100 etxebizitzatik {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)}k elektrikoa dute. {/if}Hegoaldean eta Kanarietan, negu epelekin, erradiadore elektrikoak eta aire girotua nagusitzen dira; iparraldeko barnealdean, negu hotz eta luzeekin, gas naturala eta gasolioa. INEren Biztanleriaren eta Etxebizitzen Funtsezko Ezaugarrien Inkesta 2021 (laginketa bidezkoa): etxebizitzak zenbatzen ditu, ez energia, eta ez du bereizten erradiadore bat eta bero-ponpa bat.</p>

---

## Iturriak eta oharrak

- **[Eurostat – Energia-balantze osoak (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: energiaren azken kontsumoa sektoreka, industria-adarka eta erregaika, 1990etik azken urtera arte. Beste herrialdeekiko alderaketak taula eta definizio berak erabiltzen ditu (elektrizitatea energiaren azken kontsumoaren gainean, erabilera energetikoa) eta Europako herrialdeak baino ez ditu hartzen; Norvegia eta Suedia erreferentzia gisa agertzen dira (ertz etena), Europako ekonomia elektrifikatuenak direlako.
- **[Eurostat – Etxeetako energia-kontsumoa erabileraren arabera (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: berokuntza, ur beroa, sukaldaritza, hozkuntza eta argiztapena erregaika, 2010etik (Espainian IDAEk egiten du).
- **[Eurostat – Bero-ponpak (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potentzia termikoa teknologiaka.
- **[INE – ECEPOV 2021, 56784 taula](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: berokuntza duten etxebizitza nagusiak, erregai motaren eta probintziaren arabera.
- Ez dago eraikin publikoetako berokuntza-sistemari buruzko estatistika ofizial irekirik: erkidegoetako ziurtagiri energetikoen erregistroek ez dute erregaia jasotzen.

<LastRefreshed prefix="Datuak eguneratuta" />
