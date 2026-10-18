---
i18n_origen: da7631302ea5
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

# ⚡ A electrificación da economía

Descarbonizar non é só producir a electricidade con renovables: tamén hai que **usar electricidade** onde hoxe se queiman gas, gasóleo ou gasolina, en coches eléctricos, bombas de calor ou procesos industriais. Canto avanzamos?

<Grid cols=4>
    <KpiCard
        title="Electricidade no consumo final"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total, 1)} %"
        period="de toda a enerxía que se usa · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (ultimo[0].total - hace_10[0].total).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anos"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Fogares"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares, 1)} %"
        period="da súa enerxía é electricidade"
        change={hace_10[0]?.hogares != null ? (ultimo[0].hogares - hace_10[0].hogares).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 anos"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Industria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria, 1)} %"
        period="da súa enerxía é electricidade"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Transporte"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte, 1)} %"
        period="case todo é tren; o coche eléctrico apenas se nota aínda"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
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
    y=cuota_electricidad_pct
    series=sector
    yFmt='0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#7c3aed', '#94a3b8']}
/>

<p class="text-xs text-gray-500">Peso da electricidade no consumo final de enerxía de cada sector (uso enerxético, sen materias primas). No conxunto da economía a electrificación está practicamente estancada arredor dunha cuarta parte desde hai unha década: os fogares avanzan, pero o transporte, que gasta máis enerxía ca ningún outro sector, segue funcionando case só con derivados do petróleo. "Comercio e servizos públicos" inclúe oficinas, comercios, hospitais, colexios e edificios das administracións: Eurostat non os separa.</p>

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
    title="Con que enerxía funciona cada sector ({ultimo[0]?.anio})"
/>

## A industria, rama a rama

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
    title="Peso da electricidade na enerxía de cada rama industrial"
/>

<p class="text-xs text-gray-500">As ramas que necesitan calor a moi alta temperatura (cemento, cerámica, vidro, química) son as máis difíciles de electrificar e seguen dependendo do gas; a siderurxia xa é en boa parte eléctrica porque en España a maior parte do aceiro fabrícase en fornos de arco eléctrico a partir de chatarra.</p>

## O transporte: pouca enerxía eléctrica, moitos viaxeiros

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

O transporte é o sector menos electrificado: {#if transporte_resumen.length > 0}só un {formatNumber(transporte_resumen[0].electricidad_pct, 1)} % da enerxía que gasta é electricidade{/if}. Pode parecer pouco para un país con metro en sete cidades, Cercanías e unha das maiores redes de alta velocidade do mundo, pero a cifra mide **enerxía, non viaxes**, e o tren eléctrico é tan eficiente que gasta moi pouca para o traballo que fai.

<Grid cols=4>
    <KpiCard
        title="Enerxía do transporte que gasta o ferrocarril"
        value={transporte_resumen[0]?.ferrocarril_pct}
        formattedValue="{formatNumber(transporte_resumen[0]?.ferrocarril_pct, 1)} %"
        period="tren, metro e tranvía · {transporte_resumen[0]?.anio}"
        source="Eurostat"
    />
    <KpiCard
        title="Viaxeiros-km que van en tren"
        value={reparto_ultimo[0]?.viajeros_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.viajeros_es, 1)} %"
        period="fronte ao coche e ao autobús, sen contar o metro · UE: {formatNumber(reparto_ultimo[0]?.viajeros_ue, 1)} % · {reparto_ultimo[0]?.anio_viajeros}"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_viajeros_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Mercadorías que van en tren"
        value={reparto_ultimo[0]?.mercancias_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.mercancias_es, 1)} %"
        period="das toneladas-km por terra · UE: {formatNumber(reparto_ultimo[0]?.mercancias_ue, 1)} % · {reparto_ultimo[0]?.anio_mercancias}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_mercancias_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Viaxes en metro por habitante"
        value={viajes_resumen[viajes_resumen.length - 1]?.metro_hab}
        formattedValue="{formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro_hab, 0)}"
        period="ao ano · {formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro / 1e6, 0)} millóns de viaxes en {viajes_resumen[viajes_resumen.length - 1]?.anio}"
        source="INE"
        sparklineData={viajes_resumen.map(d => ({...d, y: d.metro_hab}))}
        href="/gl/movilidad/ferrocarril"
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
    title="En que se vai a enerxía do transporte ({transporte_energia[0]?.anio})"
/>

<p class="text-xs text-gray-500">Consumo final de enerxía do transporte dentro de España (Eurostat). «Ferrocarril» inclúe trens de viaxeiros e de mercadorías, metro e tranvía. «Avión, barco e outros» son os voos e barcos nacionais e os oleodutos e gasodutos; os voos e barcos internacionais non están nesta cifra. As bombas dos oleodutos e gasodutos son eléctricas: de aí a pequena parte azul desa barra.</p>

### Por que pesa tan pouco: a eficiencia do tren eléctrico

As cifras déixano claro. {#if transporte_resumen.length > 0 && reparto_ultimo.length > 0}O ferrocarril fai o **{formatNumber(reparto_ultimo[0].viajeros_es, 1)} % dos viaxeiros-km** por terra e o **{formatNumber(reparto_ultimo[0].mercancias_es, 1)} % das toneladas-km** con só o **{formatNumber(transporte_resumen[0].ferrocarril_pct, 1)} % da enerxía** do transporte, e iso que esa enerxía inclúe tamén o metro e o tranvía, que non están nos viaxeiros-km. Do ferrocarril, un {formatNumber(transporte_resumen[0].ferrocarril_elec_pct, 0)} % da enerxía xa é electricidade.{/if} Hai dous motivos. O primeiro é o motor: un eléctrico converte en movemento case toda a enerxía que recibe, mentres que un de gasolina ou gasóleo perde a maior parte en calor. O segundo é a roda de aceiro sobre o carril, que roza moito menos ca un pneumático sobre o asfalto, e un tren leva a centos de persoas á vez. Por iso pasar viaxeiros e mercadorías da estrada ao tren reduce o consumo de enerxía moito máis do que sobe o consumo de electricidade.

O contrario tamén se cumpre: a electrificación do transporte está estancada porque {#if transporte_resumen.length > 0}o {formatNumber(transporte_resumen[0].carretera_pct, 0)} %{:else}case toda{/if} da súa enerxía se gasta na estrada, e alí o coche eléctrico aínda é unha parte moi pequena do parque e os camións case non comezaron. En mercadorías, España está moi por debaixo de Europa: case todo vai en camión.

```sql transporte_paises
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = '${inputs.transporte_indicador}'
```

<ButtonGroup name=transporte_indicador title="Comparar con Europa">
    <ButtonGroupItem valueLabel="Viaxeiros en tren" value="tren_viajeros_pct" default />
    <ButtonGroupItem valueLabel="Mercadorías en tren" value="tren_mercancias_pct" />
    <ButtonGroupItem valueLabel="Electricidade no transporte" value="electrificacion_transporte" />
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
    title="España fronte á UE"
/>

<p class="text-xs text-gray-500">Viaxeiros: reparto dos viaxeiros-km entre coche, autobús e tren. Mercadorías: reparto das toneladas-km entre estrada, tren e vías navegables (en España non hai transporte fluvial de mercadorías). Eurostat non inclúe o metro nin o tranvía no reparto de viaxeiros porque non hai datos harmonizados dos quilómetros que percorren os seus viaxeiros, nin tampouco os avións.</p>

### O metro si conta nas viaxes

Os viaxeiros-km de Eurostat deixan fóra o metro, pero o INE conta cantas viaxes se fan en cada medio de transporte público. {#if viajes_resumen.length > 0}En {viajes_resumen[viajes_resumen.length - 1].anio} o metro fixo {formatNumber(viajes_resumen[viajes_resumen.length - 1].metro / 1e6, 0)} millóns de viaxes, {#if viajes_resumen[viajes_resumen.length - 1].metro > viajes_resumen[viajes_resumen.length - 1].tren}máis que todos os trens xuntos ({formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} millóns){:else}fronte a {formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} millóns en tren{/if}, e {formatNumber(viajes_resumen[viajes_resumen.length - 1].railes_pct, 0)} de cada 100 viaxes en transporte público foron sobre carrís.{/if}

<BarChart
    data={viajes_ultimo}
    x=modo
    y=viajes_hab
    series=tipo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#1d4ed8', '#94a3b8']}
    title="Viaxes en transporte público por habitante e ano ({viajes_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estatística de Transporte de Viaxeiros do INE: viaxes (non quilómetros) en metro, autobús, tren, avión e barco dentro de España, divididas pola poboación. Unha viaxe en metro é moito máis curta ca unha en AVE, así que estas cifras non se poden sumar aos viaxeiros-km de arriba. O tranvía non ten unha partida propia nesta estatística. «Sobre carrís» non sempre é eléctrico: algunhas liñas de media distancia seguen sendo de gasóleo.</p>

## Como se quentan as casas

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

### Con que se quentan as vivendas, por provincia

<ButtonGroup name=calefaccion_tec title="Combustible">
    <ButtonGroupItem valueLabel="Electricidade" value="cuota_electricidad_pct" default />
    <ButtonGroupItem valueLabel="Gas natural" value="cuota_gas_pct" />
    <ButtonGroupItem valueLabel="Gasóleo e derivados" value="cuota_petroleo_pct" />
    <ButtonGroupItem valueLabel="Biomasa e outros" value="cuota_otros_pct" />
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Electricidade', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas natural', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasóleo e derivados', fmt: '0"%"'},
        {id: 'cuota_otros_pct', title: 'Biomasa e outros', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=viviendas title="Vivendas con calefacción" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Electricidade" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas natural" fmt='0"%"' contentType=bar barColor="#fde68a" />
    <Column id=cuota_petroleo_pct title="Gasóleo e derivados" fmt='0"%"' contentType=bar barColor="#d6d3d1" />
    <Column id=cuota_otros_pct title="Biomasa e outros" fmt='0"%"' contentType=bar barColor="#d9f99d" />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}En España, de cada 100 vivendas con calefacción {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)} téñena eléctrica, {formatNumber(espana_viv[0].cuota_gas_pct, 0)} de gas natural, {formatNumber(espana_viv[0].cuota_petroleo_pct, 0)} de gasóleo ou derivados e {formatNumber(espana_viv[0].cuota_otros_pct, 0)} de biomasa ou outros. {/if}No sur e en Canarias, con invernos suaves, predominan os radiadores eléctricos e o aire acondicionado; no interior norte, con invernos fríos e longos, o gas natural e o gasóleo; e na España rural máis fría (Ourense, Lugo, Soria, Cuenca) e en Xaén, onde se queima moito óso de oliva, a biomasa. Enquisa de Características Esenciais da Poboación e as Vivendas 2021 do INE (mostral): conta vivendas, non enerxía, e só ofrece catro respostas. «Biomasa e outros» é a resposta «Outros» do INE, que na práctica é sobre todo leña, pellets e óso de oliva, pero tamén inclúe carbón e solar. A bomba de calor non se pode separar por provincia: a enquisa cóntaa dentro de «Electricidade» xunto cos radiadores e o aire acondicionado, e a cifra de bombas de calor de máis arriba (Eurostat) só existe para o conxunto de España.</p>

---

## Fontes e notas

- **[Eurostat – Balances enerxéticos completos (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consumo final de enerxía por sector, rama industrial e combustible, 1990-último ano. A comparación con outros países usa a mesma táboa e a mesma definición (electricidade entre consumo final de enerxía, uso enerxético) e só abrangue países europeos; Noruega e Suecia aparecen como referencia (bordo descontinuo) por seren as economías máis electrificadas de Europa.
- **[Eurostat – Reparto modal do transporte de viaxeiros (tran_hv_psmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_psmod/default/table)** e **[de mercadorías (tran_hv_frmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_frmod/default/table)**: % dos viaxeiros-km en coche, autobús e tren e das toneladas-km por estrada, tren e vías navegables. Non inclúen metro, tranvía nin avión.
- **[INE – Estatística de Transporte de Viaxeiros, táboa 20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239)**: viaxes mensuais en metro, autobús urbano e interurbano, tren, avión e barco. Conta viaxes, non quilómetros.
- **[Eurostat – Consumo de enerxía dos fogares por uso (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacción, auga quente, cociña, refrixeración e iluminación por combustible, desde 2010 (en España elabórao o IDAE).
- **[Eurostat – Bombas de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potencia térmica por tecnoloxía.
- **[INE – ECEPOV 2021, táboa 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: vivendas principais con calefacción por tipo de combustible e provincia.
- Non hai estatística oficial aberta do sistema de calefacción dos edificios públicos: os rexistros de certificados enerxéticos das comunidades non recollen o combustible.

<LastRefreshed prefix="Datos actualizados" />
