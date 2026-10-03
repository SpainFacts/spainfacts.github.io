---
title: Electrification of the economy
description: "How much of the energy used by industry, transport, households and services in Spain is electricity, how homes are heated in each province and how many heat pumps there are."
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

# ⚡ The electrification of the economy

Decarbonising is not just about generating electricity from renewables: we also need to **use electricity** where gas, diesel or petrol are burned today, in electric cars, heat pumps or industrial processes. How far have we come?

<Grid cols=4>
    <KpiCard
        title="Electricity in final consumption"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total / 0.01, 1)} %"
        period="of all the energy used · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (100 * (ultimo[0].total - hace_10[0].total)).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="over 10 years"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Households"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares / 0.01, 1)} %"
        period="of their energy is electricity"
        change={hace_10[0]?.hogares != null ? (100 * (ultimo[0].hogares - hace_10[0].hogares)).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="over 10 years"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Industry"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria / 0.01, 1)} %"
        period="of its energy is electricity"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
    />
    <KpiCard
        title="Transport"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte / 0.01, 1)} %"
        period="almost all of it rail; electric cars barely register yet"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: 100 * d.cuota_electricidad}))}
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
    y=cuota_electricidad
    series=sector
    yFmt=pct0
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#7c3aed', '#94a3b8']}
/>

<p class="text-xs text-gray-500">Share of electricity in each sector's final energy consumption (energy use, excluding feedstocks). Across the economy as a whole, electrification has been practically stuck at around a quarter for a decade: households are making progress, but transport, which uses more energy than any other sector, still runs almost entirely on oil products. "Comercio y servicios públicos" (commercial and public services) includes offices, shops, hospitals, schools and government buildings: Eurostat does not separate them.</p>

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
    title="What energy each sector runs on ({ultimo[0]?.anio})"
/>

## Industry, branch by branch

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
    title="Share of electricity in the energy used by each industrial branch"
/>

<p class="text-xs text-gray-500">The branches that need very high-temperature heat (cement, ceramics, glass, chemicals) are the hardest to electrify and still depend on gas; the steel industry is already largely electric because in Spain most steel is made in electric arc furnaces from scrap.</p>

## How homes are heated

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
SELECT cod_prov, provincia, viviendas, cuota_electricidad, cuota_gas, cuota_petroleo
FROM mother.electrificacion_calefaccion_provincia
WHERE cod_prov <> '00'
ORDER BY cuota_electricidad DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE cod_prov = '00'
```

### Homes heated with electricity, by province

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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad', title: 'Electricity', fmt: 'pct0'},
        {id: 'cuota_gas', title: 'Natural gas', fmt: 'pct0'},
        {id: 'cuota_petroleo', title: 'Heating oil and oil products', fmt: 'pct0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=viviendas title="Homes with heating" fmt=num0 />
    <Column id=cuota_electricidad title="Electricity" fmt=pct0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas title="Natural gas" fmt=pct0 />
    <Column id=cuota_petroleo title="Heating oil and oil products" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}In Spain, {formatNumber(100 * espana_viv[0].cuota_electricidad, 0)} out of every 100 homes with heating have electric heating. {/if}In the south and in the Canary Islands, with mild winters, electric radiators and air conditioning predominate; in the northern interior, with long, cold winters, natural gas and heating oil. INE's 2021 Survey of Essential Characteristics of the Population and Housing (sample-based): it counts homes, not energy, and does not distinguish between a radiator and a heat pump.</p>

---

## Sources and notes

- **[Eurostat – Complete energy balances (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: final energy consumption by sector, industrial branch and fuel, 1990-latest year. The comparison with other countries uses the same table and the same definition (electricity as a share of final energy consumption, energy use) and only covers European countries; Norway and Sweden appear as a reference (dashed border) as they are the most electrified economies in Europe.
- **[Eurostat – Energy consumption in households by use (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: space heating, water heating, cooking, cooling and lighting by fuel, since 2010 (compiled in Spain by IDAE).
- **[Eurostat – Heat pumps (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: thermal capacity by technology.
- **[INE – ECEPOV 2021, table 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: main residences with heating by type of fuel and province.
- There are no open official statistics on the heating systems of public buildings: the regional energy performance certificate registers do not record the fuel.

<LastRefreshed prefix="Data updated" />
