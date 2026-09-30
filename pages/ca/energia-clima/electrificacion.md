---
title: Electrificació de l'economia
description: "Quina part de l'energia que consumeixen la indústria, el transport, les llars i els serveis a Espanya és electricitat, com s'escalfen les cases per província i quantes bombes de calor hi ha."
i18n_origen: 49a1fe838e5e
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
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

# ⚡ L'electrificació de l'economia

Descarbonitzar no és només produir l'electricitat amb renovables: també cal **fer servir electricitat** allà on avui es cremen gas, gasoil o gasolina, en cotxes elèctrics, bombes de calor o processos industrials. Quant hem avançat?

<Grid cols=4>
    <KpiCard
        title="Electricitat en el consum final"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total / 0.01, 1)} %"
        period="de tota l'energia que es fa servir · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (100 * (ultimo[0].total - hace_10[0].total)).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anys"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Llars"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares / 0.01, 1)} %"
        period="de la seva energia és electricitat"
        change={hace_10[0]?.hogares != null ? (100 * (ultimo[0].hogares - hace_10[0].hogares)).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anys"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Indústria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria / 0.01, 1)} %"
        period="de la seva energia és electricitat"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Transport"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte / 0.01, 1)} %"
        period="gairebé tot és tren; el cotxe elèctric encara amb prou feines es nota"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
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
    y=cuota_electricidad
    series=sector
    yFmt=pct0
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#7c3aed', '#94a3b8']}
/>

<p class="text-xs text-gray-500">Pes de l'electricitat en el consum final d'energia de cada sector (ús energètic, sense matèries primeres). En el conjunt de l'economia l'electrificació està pràcticament estancada al voltant d'una quarta part des de fa una dècada: les llars avancen, però el transport, que gasta més energia que cap altre sector, continua funcionant gairebé només amb derivats del petroli. "Comerç i serveis públics" inclou oficines, comerços, hospitals, escoles i edificis de les administracions: Eurostat no els separa.</p>

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
    title="Amb quina energia funciona cada sector ({ultimo[0]?.anio})"
/>

## La indústria, branca a branca

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
    title="Pes de l'electricitat en l'energia de cada branca industrial"
/>

<p class="text-xs text-gray-500">Les branques que necessiten calor a molt alta temperatura (ciment, ceràmica, vidre, química) són les més difícils d'electrificar i continuen depenent del gas; la siderúrgia ja és en bona part elèctrica perquè a Espanya la major part de l'acer es fabrica en forns d'arc elèctric a partir de ferralla.</p>

## Com s'escalfen les cases

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
SELECT cod_prov, provincia, viviendas, cuota_electricidad, cuota_gas, cuota_petroleo
FROM mother.electrificacion_calefaccion_provincia
WHERE cod_prov <> '00'
ORDER BY cuota_electricidad DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE cod_prov = '00'
```

### Habitatges que s'escalfen amb electricitat, per província

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_electricidad"
    valueFmt="pct0"
    colorPalette={['#fff7ed', '#93c5fd', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad', title: 'Electricitat', fmt: 'pct0'},
        {id: 'cuota_gas', title: 'Gas natural', fmt: 'pct0'},
        {id: 'cuota_petroleo', title: 'Gasoil i derivats', fmt: 'pct0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=viviendas title="Habitatges amb calefacció" fmt=num0 />
    <Column id=cuota_electricidad title="Electricitat" fmt=pct0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas title="Gas natural" fmt=pct0 />
    <Column id=cuota_petroleo title="Gasoil i derivats" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}A Espanya, {formatNumber(100 * espana_viv[0].cuota_electricidad, 0)} de cada 100 habitatges amb calefacció la tenen elèctrica. {/if}Al sud i a les Canàries, amb hiverns suaus, predominen els radiadors elèctrics i l'aire condicionat; a l'interior nord, amb hiverns freds i llargs, el gas natural i el gasoil. Enquesta de Característiques Essencials de la Població i els Habitatges 2021 de l'INE (mostral): compta habitatges, no energia, i no distingeix un radiador d'una bomba de calor.</p>

---

## Fonts i notes

- **[Eurostat – Balanços energètics complets (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consum final d'energia per sector, branca industrial i combustible, 1990-últim any. La comparació amb altres països fa servir la mateixa taula i la mateixa definició (electricitat entre consum final d'energia, ús energètic) i només cobreix països europeus; Noruega i Suècia hi apareixen com a referència (vora discontínua) perquè són les economies més electrificades d'Europa.
- **[Eurostat – Consum d'energia de les llars per ús (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacció, aigua calenta, cuina, refrigeració i il·luminació per combustible, des del 2010 (a Espanya l'elabora l'IDAE).
- **[Eurostat – Bombes de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potència tèrmica per tecnologia.
- **[INE – ECEPOV 2021, taula 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: habitatges principals amb calefacció per tipus de combustible i província.
- No hi ha estadística oficial oberta del sistema de calefacció dels edificis públics: els registres de certificats energètics de les comunitats no en recullen el combustible.

<LastRefreshed prefix="Dades actualitzades" />
