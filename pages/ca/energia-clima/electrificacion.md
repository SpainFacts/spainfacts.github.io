---
title: Electrificació de l'economia
description: "Quina part de l'energia que consumeixen la indústria, el transport, les llars i els serveis a Espanya és electricitat, com s'escalfen les cases per província i quantes bombes de calor hi ha."
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
    yFmt='0"%"'
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
    yFmt='0"%"'
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
SELECT cod AS cod_prov, nombre AS provincia, viviendas, cuota_electricidad_pct, cuota_gas_pct, cuota_petroleo_pct
FROM mother.electrificacion_calefaccion_provincia
WHERE nivel = 'provincia'
ORDER BY cuota_electricidad_pct DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE nivel = 'pais'
```

### Habitatges que s'escalfen amb electricitat, per província

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Electricitat', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas natural', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasoil i derivats', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=viviendas title="Habitatges amb calefacció" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Electricitat" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas natural" fmt='0"%"' />
    <Column id=cuota_petroleo_pct title="Gasoil i derivats" fmt='0"%"' />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}A Espanya, {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)} de cada 100 habitatges amb calefacció la tenen elèctrica. {/if}Al sud i a les Canàries, amb hiverns suaus, predominen els radiadors elèctrics i l'aire condicionat; a l'interior nord, amb hiverns freds i llargs, el gas natural i el gasoil. Enquesta de Característiques Essencials de la Població i els Habitatges 2021 de l'INE (mostral): compta habitatges, no energia, i no distingeix un radiador d'una bomba de calor.</p>

---

## Fonts i notes

- **[Eurostat – Balanços energètics complets (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consum final d'energia per sector, branca industrial i combustible, 1990-últim any. La comparació amb altres països fa servir la mateixa taula i la mateixa definició (electricitat entre consum final d'energia, ús energètic) i només cobreix països europeus; Noruega i Suècia hi apareixen com a referència (vora discontínua) perquè són les economies més electrificades d'Europa.
- **[Eurostat – Consum d'energia de les llars per ús (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacció, aigua calenta, cuina, refrigeració i il·luminació per combustible, des del 2010 (a Espanya l'elabora l'IDAE).
- **[Eurostat – Bombes de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potència tèrmica per tecnologia.
- **[INE – ECEPOV 2021, taula 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: habitatges principals amb calefacció per tipus de combustible i província.
- No hi ha estadística oficial oberta del sistema de calefacció dels edificis públics: els registres de certificats energètics de les comunitats no en recullen el combustible.

<LastRefreshed prefix="Dades actualitzades" />
