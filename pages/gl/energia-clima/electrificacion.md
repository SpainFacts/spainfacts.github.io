---
i18n_origen: a287d12777fb
title: Electrificación da economía
description: "Canta da enerxía que consomen a industria, o transporte, os fogares e os servizos en España é electricidade, como se quentan as casas por provincia e cantas bombas de calor hai."
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

# ⚡ A electrificación da economía

Descarbonizar non é só producir a electricidade con renovables: tamén hai que **usar electricidade** onde hoxe se queiman gas, gasóleo ou gasolina, en coches eléctricos, bombas de calor ou procesos industriais. Canto avanzamos?

<Grid cols=4>
    <KpiCard
        title="Electricidade no consumo final"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total / 0.01, 1)} %"
        period="de toda a enerxía que se usa · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (100 * (ultimo[0].total - hace_10[0].total)).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anos"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Fogares"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares / 0.01, 1)} %"
        period="da súa enerxía é electricidade"
        change={hace_10[0]?.hogares != null ? (100 * (ultimo[0].hogares - hace_10[0].hogares)).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anos"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Industria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria / 0.01, 1)} %"
        period="da súa enerxía é electricidade"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Transporte"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte / 0.01, 1)} %"
        period="case todo é tren; o coche eléctrico apenas se nota aínda"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
        href="/gl/movilidad/coche-electrico"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electrificacion'
```

<Comparativa data={comparativa_internacional} />

## Canta da enerxía que se usa é electricidade?

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

<p class="text-xs text-gray-500">Peso da electricidade no consumo final de enerxía de cada sector (uso enerxético, sen materias primas). No conxunto da economía a electrificación está practicamente estancada arredor dunha cuarta parte desde hai unha década: os fogares avanzan, pero o transporte, que gasta máis enerxía ca ningún outro sector, segue funcionando case só con derivados do petróleo. "Comercio e servizos públicos" inclúe oficinas, comercios, hospitais, colexios e edificios das administracións: Eurostat non os separa.</p>

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
    title="Con que enerxía funciona cada sector ({ultimo[0]?.anio})"
/>

## A industria, rama a rama

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
    title="Peso da electricidade na enerxía de cada rama industrial"
/>

<p class="text-xs text-gray-500">As ramas que necesitan calor a moi alta temperatura (cemento, cerámica, vidro, química) son as máis difíciles de electrificar e seguen dependendo do gas; a siderurxia xa é en boa parte eléctrica porque en España a maior parte do aceiro fabrícase en fornos de arco eléctrico a partir de chatarra.</p>

## Como se quentan as casas

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
    title="Enerxía para calefacción nos fogares, por combustible"
/>

<p class="text-xs text-gray-500">En enerxía, a calefacción dos fogares repártese case a partes iguais entre biomasa (leña e pellets, sobre todo en zonas rurais), gas natural e gasóleo ou butano; a electricidade e a calor que captan as bombas de calor do aire suman arredor dun 15 %. Unha bomba de calor aproveita enerxía gratuíta do aire: por cada kWh de electricidade entrega 3 ou 4 de calor, e Eurostat conta esa parte como "calor ambiente".</p>

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
    yAxisTitle="GW térmicos"
    title="Bombas de calor instaladas (potencia térmica)"
/>

<p class="text-xs text-gray-500">A gran maioría son equipos aire-aire reversibles, é dicir, aparellos de aire acondicionado tipo split que tamén dan calor; Eurostat cóntaos como bombas de calor aínda que moitos se usen sobre todo no verán. A aerotermia aire-auga (a que substitúe unha caldeira e quenta radiadores, chan radiante e auga quente) é aínda unha parte pequena.</p>

```sql provincias
SELECT cod_prov, provincia, viviendas, cuota_electricidad, cuota_gas, cuota_petroleo
FROM mother.electrificacion_calefaccion_provincia
WHERE cod_prov <> '00'
ORDER BY cuota_electricidad DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE cod_prov = '00'
```

### Vivendas que se quentan con electricidade, por provincia

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad', title: 'Electricidade', fmt: 'pct0'},
        {id: 'cuota_gas', title: 'Gas natural', fmt: 'pct0'},
        {id: 'cuota_petroleo', title: 'Gasóleo e derivados', fmt: 'pct0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=viviendas title="Vivendas con calefacción" fmt=num0 />
    <Column id=cuota_electricidad title="Electricidade" fmt=pct0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas title="Gas natural" fmt=pct0 />
    <Column id=cuota_petroleo title="Gasóleo e derivados" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}En España, {formatNumber(100 * espana_viv[0].cuota_electricidad, 0)} de cada 100 vivendas con calefacción téñena eléctrica. {/if}No sur e en Canarias, con invernos suaves, predominan os radiadores eléctricos e o aire acondicionado; no interior norte, con invernos fríos e longos, o gas natural e o gasóleo. Enquisa de Características Esenciais da Poboación e as Vivendas 2021 do INE (mostral): conta vivendas, non enerxía, e non distingue un radiador dunha bomba de calor.</p>

---

## Fontes e notas

- **[Eurostat – Balances enerxéticos completos (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consumo final de enerxía por sector, rama industrial e combustible, 1990-último ano. A comparación con outros países usa a mesma táboa e a mesma definición (electricidade entre consumo final de enerxía, uso enerxético) e só abrangue países europeos; Noruega e Suecia aparecen como referencia (bordo descontinuo) por seren as economías máis electrificadas de Europa.
- **[Eurostat – Consumo de enerxía dos fogares por uso (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacción, auga quente, cociña, refrixeración e iluminación por combustible, desde 2010 (en España elabórao o IDAE).
- **[Eurostat – Bombas de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potencia térmica por tecnoloxía.
- **[INE – ECEPOV 2021, táboa 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: vivendas principais con calefacción por tipo de combustible e provincia.
- Non hai estatística oficial aberta do sistema de calefacción dos edificios públicos: os rexistros de certificados enerxéticos das comunidades non recollen o combustible.

<LastRefreshed prefix="Datos actualizados" />
