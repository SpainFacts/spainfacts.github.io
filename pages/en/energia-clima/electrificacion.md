---
title: Electrification of the economy
description: "How much of the energy used by industry, transport, households and services in Spain is electricity, how homes are heated in each province and how many heat pumps there are."
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

# ⚡ The electrification of the economy

Decarbonising is not just about generating electricity from renewables: we also need to **use electricity** where gas, diesel or petrol are burned today, in electric cars, heat pumps or industrial processes. How far have we come?

<Grid cols=4>
    <KpiCard
        title="Electricity in final consumption"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total, 1)} %"
        period="of all the energy used · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (ultimo[0].total - hace_10[0].total).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="over 10 years"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Households"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares, 1)} %"
        period="of their energy is electricity"
        change={hace_10[0]?.hogares != null ? (ultimo[0].hogares - hace_10[0].hogares).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="over 10 years"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Industry"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria, 1)} %"
        period="of its energy is electricity"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Transport"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte, 1)} %"
        period="almost all of it rail; electric cars barely register yet"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
        href="/en/movilidad/coche-electrico"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electrificacion'
```

<Comparativa data={comparativa_internacional} />

## How much of the energy used is electricity?

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

<p class="text-xs text-gray-500">Share of electricity in each sector's final energy consumption (energy use, excluding feedstocks). Across the economy as a whole, electrification has been practically stuck at around a quarter for a decade: households are making progress, but transport, which uses more energy than any other sector, still runs almost entirely on oil products. "Comercio y servicios públicos" (commercial and public services) includes offices, shops, hospitals, schools and government buildings: Eurostat does not separate them.</p>

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
    title="What energy each sector runs on ({ultimo[0]?.anio})"
/>

## Industry, branch by branch

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
    title="Share of electricity in the energy used by each industrial branch"
/>

<p class="text-xs text-gray-500">The branches that need very high-temperature heat (cement, ceramics, glass, chemicals) are the hardest to electrify and still depend on gas; the steel industry is already largely electric because in Spain most steel is made in electric arc furnaces from scrap.</p>

## Transport: little electricity, many passengers

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

Transport is the least electrified sector: {#if transporte_resumen.length > 0}only {formatNumber(transporte_resumen[0].electricidad_pct, 1)}% of the energy it uses is electricity{/if}. That may seem low for a country with metros in seven cities, commuter rail and one of the largest high-speed networks in the world, but the figure measures **energy, not trips**, and electric trains are so efficient that they use very little for the work they do.

<Grid cols=4>
    <KpiCard
        title="Transport energy used by rail"
        value={transporte_resumen[0]?.ferrocarril_pct}
        formattedValue="{formatNumber(transporte_resumen[0]?.ferrocarril_pct, 1)} %"
        period="train, metro and tram · {transporte_resumen[0]?.anio}"
        source="Eurostat"
    />
    <KpiCard
        title="Passenger-km by train"
        value={reparto_ultimo[0]?.viajeros_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.viajeros_es, 1)} %"
        period="vs. car and bus, excluding metro · EU: {formatNumber(reparto_ultimo[0]?.viajeros_ue, 1)} % · {reparto_ultimo[0]?.anio_viajeros}"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_viajeros_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Freight by train"
        value={reparto_ultimo[0]?.mercancias_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.mercancias_es, 1)} %"
        period="of inland tonne-km · EU: {formatNumber(reparto_ultimo[0]?.mercancias_ue, 1)} % · {reparto_ultimo[0]?.anio_mercancias}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_mercancias_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Metro trips per inhabitant"
        value={viajes_resumen[viajes_resumen.length - 1]?.metro_hab}
        formattedValue="{formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro_hab, 0)}"
        period="per year · {formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro / 1e6, 0)} million trips in {viajes_resumen[viajes_resumen.length - 1]?.anio}"
        source="INE"
        sparklineData={viajes_resumen.map(d => ({...d, y: d.metro_hab}))}
        href="/en/movilidad/ferrocarril"
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
    title="Where transport energy goes ({transporte_energia[0]?.anio})"
/>

<p class="text-xs text-gray-500">Final energy consumption of transport within Spain (Eurostat). "Rail" includes passenger and freight trains, metro and tram. "Air, water and other" covers domestic flights and shipping and oil and gas pipelines; international flights and shipping are not included in this figure. Pipeline pumps are electric: hence the small blue part of that bar.</p>

### Why it weighs so little: the efficiency of electric trains

The figures make it clear. {#if transporte_resumen.length > 0 && reparto_ultimo.length > 0}Rail carries **{formatNumber(reparto_ultimo[0].viajeros_es, 1)}% of inland passenger-km** and **{formatNumber(reparto_ultimo[0].mercancias_es, 1)}% of tonne-km** with only **{formatNumber(transporte_resumen[0].ferrocarril_pct, 1)}% of transport energy**, even though that energy also includes metro and tram, which are not in the passenger-km. {formatNumber(transporte_resumen[0].ferrocarril_elec_pct, 0)}% of rail energy is already electricity.{/if} There are two reasons. The first is the motor: an electric one turns almost all the energy it receives into motion, while a petrol or diesel engine loses most of it as heat. The second is the steel wheel on the rail, which has far less friction than a tyre on asphalt, and a train carries hundreds of people at once. That is why moving passengers and freight from road to rail cuts energy use far more than it raises electricity use.

The flip side also holds: the electrification of transport has stalled because {#if transporte_resumen.length > 0}{formatNumber(transporte_resumen[0].carretera_pct, 0)}%{:else}almost all{/if} of its energy is used on the roads, where electric cars are still a very small share of the fleet and lorries have barely started. In freight, Spain is far behind Europe: almost everything goes by lorry.

```sql transporte_paises
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = '${inputs.transporte_indicador}'
```

<ButtonGroup name=transporte_indicador title="Compare with Europe">
    <ButtonGroupItem valueLabel="Passengers by train" value="tren_viajeros_pct" default />
    <ButtonGroupItem valueLabel="Freight by train" value="tren_mercancias_pct" />
    <ButtonGroupItem valueLabel="Electricity in transport" value="electrificacion_transporte" />
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
    title="Spain vs. the EU"
/>

<p class="text-xs text-gray-500">Passengers: split of passenger-km between car, bus and train. Freight: split of tonne-km between road, rail and inland waterways (Spain has no inland waterway freight). Eurostat does not include metro or tram in the passenger split because there are no harmonised data on the distances their passengers travel, nor does it include air.</p>

### Metro does count in trips

Eurostat's passenger-km leave out the metro, but INE counts how many trips are made on each mode of public transport. {#if viajes_resumen.length > 0}In {viajes_resumen[viajes_resumen.length - 1].anio} the metro carried {formatNumber(viajes_resumen[viajes_resumen.length - 1].metro / 1e6, 0)} million trips, {#if viajes_resumen[viajes_resumen.length - 1].metro > viajes_resumen[viajes_resumen.length - 1].tren}more than all trains combined ({formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} million){:else}compared with {formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} million by train{/if}, and {formatNumber(viajes_resumen[viajes_resumen.length - 1].railes_pct, 0)} out of every 100 public transport trips were on rails.{/if}

<BarChart
    data={viajes_ultimo}
    x=modo
    y=viajes_hab
    series=tipo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#1d4ed8', '#94a3b8']}
    title="Public transport trips per inhabitant per year ({viajes_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">INE Passenger Transport Statistics: trips (not kilometres) by metro, bus, train, air and sea within Spain, divided by population. A metro trip is much shorter than a high-speed one, so these figures cannot be added to the passenger-km above. Trams do not have their own line in this statistic. "On rails" is not always electric: some regional lines still run on diesel.</p>

## How homes are heated

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
    title="Energy used for home heating, by fuel"
/>

<p class="text-xs text-gray-500">In energy terms, home heating is split almost equally between biomass (firewood and pellets, especially in rural areas), natural gas, and heating oil or butane; electricity and the heat captured from the air by heat pumps together account for around 15 %. A heat pump makes use of free energy from the air: for every kWh of electricity it delivers 3 or 4 kWh of heat, and Eurostat counts that part as "ambient heat".</p>

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
    yAxisTitle="Thermal GW"
    title="Installed heat pumps (thermal capacity)"
/>

<p class="text-xs text-gray-500">The vast majority are reversible air-to-air units, in other words split air-conditioning units that also provide heating; Eurostat counts them as heat pumps even though many are used mainly in summer. Air-to-water heat pumps (the kind that replace a boiler and heat radiators, underfloor heating and hot water) are still a small share.</p>

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

### Homes by heating fuel, by province

<ButtonGroup name=calefaccion_tec title="Fuel">
    <ButtonGroupItem valueLabel="Electricity" value="cuota_electricidad_pct" default />
    <ButtonGroupItem valueLabel="Natural gas" value="cuota_gas_pct" />
    <ButtonGroupItem valueLabel="Heating oil and oil products" value="cuota_petroleo_pct" />
    <ButtonGroupItem valueLabel="Biomass and other" value="cuota_otros_pct" />
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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Electricity', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Natural gas', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Heating oil and oil products', fmt: '0"%"'},
        {id: 'cuota_otros_pct', title: 'Biomass and other', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=viviendas title="Homes with heating" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Electricity" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Natural gas" fmt='0"%"' contentType=bar barColor="#fde68a" />
    <Column id=cuota_petroleo_pct title="Heating oil and oil products" fmt='0"%"' contentType=bar barColor="#d6d3d1" />
    <Column id=cuota_otros_pct title="Biomass and other" fmt='0"%"' contentType=bar barColor="#d9f99d" />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}In Spain, out of every 100 homes with heating {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)} have electric heating, {formatNumber(espana_viv[0].cuota_gas_pct, 0)} natural gas, {formatNumber(espana_viv[0].cuota_petroleo_pct, 0)} heating oil or oil products and {formatNumber(espana_viv[0].cuota_otros_pct, 0)} biomass or other fuels. {/if}In the south and in the Canary Islands, with mild winters, electric radiators and air conditioning predominate; in the northern interior, with long, cold winters, natural gas and heating oil; and in the coldest rural areas (Ourense, Lugo, Soria, Cuenca) and in Jaén, where a lot of olive pits are burned, biomass. INE's 2021 Survey of Essential Characteristics of the Population and Housing (sample-based): it counts homes, not energy, and only offers four answers. "Biomass and other" is INE's "Other" answer, which in practice is mostly firewood, pellets and olive pits, but also includes coal and solar. Heat pumps cannot be separated by province: the survey counts them under "Electricity" together with radiators and air conditioning, and the heat pump figure above (Eurostat) only exists for Spain as a whole.</p>

---

## Sources and notes

- **[Eurostat – Complete energy balances (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: final energy consumption by sector, industrial branch and fuel, 1990-latest year. The comparison with other countries uses the same table and the same definition (electricity as a share of final energy consumption, energy use) and only covers European countries; Norway and Sweden appear as a reference (dashed border) as they are the most electrified economies in Europe.
- **[Eurostat – Modal split of passenger transport (tran_hv_psmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_psmod/default/table)** and **[of freight transport (tran_hv_frmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_frmod/default/table)**: % of passenger-km by car, bus and train and of tonne-km by road, rail and inland waterways. They do not include metro, tram or air.
- **[INE – Passenger Transport Statistics, table 20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239)**: monthly trips by metro, city and intercity bus, train, air and sea. It counts trips, not kilometres.
- **[Eurostat – Energy consumption in households by use (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: space heating, water heating, cooking, cooling and lighting by fuel, since 2010 (compiled in Spain by IDAE).
- **[Eurostat – Heat pumps (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: thermal capacity by technology.
- **[INE – ECEPOV 2021, table 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: main residences with heating by type of fuel and province.
- There are no open official statistics on the heating systems of public buildings: the regional energy performance certificate registers do not record the fuel.

<LastRefreshed prefix="Data updated" />
