---
title: Electric cars
description: "The shift to electric cars in Spain: new car registrations by engine type every month since 2015, share of battery electric and plug-in hybrids by province, and CO2 emissions."
i18n_origen: a3ce9f887980
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql mensual
SELECT
    mes,
    energia,
    energia_etiqueta AS motor,
    energia_orden,
    sum(matriculaciones) AS turismos
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY mes, energia_orden
```

```sql cuota_mensual
SELECT
    mes,
    sum(turismos) FILTER (WHERE energia = 'bev') / sum(turismos) AS cuota_bev,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev')) / sum(turismos) AS cuota_enchufables,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev', 'hev')) / sum(turismos) AS cuota_electrificados,
    sum(turismos) AS total
FROM ${mensual}
GROUP BY mes
ORDER BY mes
```

```sql ultimo
SELECT
    c.*,
    strftime(c.mes, '%m/%Y') AS mes_texto,
    a.cuota_enchufables AS cuota_enchufables_anio_antes,
    a.cuota_bev AS cuota_bev_anio_antes
FROM ${cuota_mensual} c
LEFT JOIN ${cuota_mensual} a ON a.mes = c.mes - INTERVAL 12 MONTH
ORDER BY c.mes DESC
LIMIT 1
```

```sql anual
-- Turismos nuevos por 1.000 habitantes (padrón del año; el último para los más recientes)
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.motor,
    m.energia_orden,
    sum(m.turismos) AS turismos,
    1000.0 * sum(m.turismos) / any_value(p.poblacion) AS por_1000
FROM ${mensual} m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
GROUP BY ALL
ORDER BY anio, m.energia_orden
```

```sql co2
SELECT
    mes,
    sum(co2_medio * matriculaciones) / sum(matriculaciones) AS co2_medio
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N' AND co2_medio IS NOT NULL
GROUP BY mes
ORDER BY mes
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${mensual} ORDER BY energia_orden
```

# ⚡ The shift to electric cars

How many of the cars sold in Spain are already electric? The answer comes from the microdata of the Directorate-General for Traffic (DGT), which records every car registered along with its engine type.

<Grid cols=3>
    <KpiCard
        title="Battery electric"
        value={ultimo[0]?.cuota_bev * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_bev * 100, 1)}
        unit="%"
        period="of new cars · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_bev_anio_antes != null ? ((ultimo[0].cuota_bev - ultimo[0].cuota_bev_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. a year earlier"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({...d, valor: d.cuota_bev * 100}))}
    />
    <KpiCard
        title="Plug-in (battery electric + plug-in hybrids)"
        value={ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="of new cars · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_enchufables_anio_antes != null ? ((ultimo[0].cuota_enchufables - ultimo[0].cuota_enchufables_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. a year earlier"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({...d, valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Electrified (including hybrids)"
        value={ultimo[0]?.cuota_electrificados * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_electrificados * 100, 1)}
        unit="%"
        period="of new cars · {ultimo[0]?.mes_texto}"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({...d, valor: d.cuota_electrificados * 100}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'coche_electrico_cuota'
```

<Comparativa data={comparativa_internacional} decimales={0} />

## Monthly market share of new cars

<LineChart
    data={cuota_mensual}
    x=mes
    y={['cuota_bev', 'cuota_enchufables', 'cuota_electrificados']}
    yFmt=pct0
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#14b8a6', '#a3e635']}
    legend=true
    seriesLabels={{cuota_bev: 'Battery electric', cuota_enchufables: 'Battery electric + plug-in hybrids', cuota_electrificados: 'All electrified (incl. hybrids)'}}
/>

## New cars by engine type

<BarChart
    data={mensual}
    x=mes
    y=turismos
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="mmm yyyy"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

<p class="text-xs text-gray-500">Diesel went from more than half of all sales in 2015 to a residual share; its place was taken first by petrol and then by hybrids. Non-plug-in hybrids (HEV) include <em>mild hybrids</em> (ECO label); extended-range electric vehicles (REEV) are counted with plug-ins.</p>

<BarChart
    data={anual}
    x=anio
    y=por_1000
    series=motor
    type=stacked
    yFmt=num1
    yAxisTitle="per 1,000 people"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="New cars registered per year, per 1,000 people"
/>

<p class="text-xs text-gray-500">The latest year is incomplete (up to the last month published).</p>

## Who buys new cars?

```sql canales_anual
SELECT
    CAST(year(mes) AS INTEGER) AS anio,
    canal_etiqueta AS canal,
    canal_orden,
    sum(matriculaciones) AS turismos,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS cuota_enchufables
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY anio, canal_orden
```

```sql canales_orden
SELECT DISTINCT canal, canal_orden FROM ${canales_anual} ORDER BY canal_orden
```

```sql canales_ultimo
SELECT
    any_value(anio) AS anio,
    100 * sum(turismos) FILTER (WHERE canal_orden = 1) / sum(turismos) AS pct_particulares,
    100 * max(cuota_enchufables) FILTER (WHERE canal_orden = 1) AS pct_enchufables_particulares,
    100 * sum(turismos * cuota_enchufables) FILTER (WHERE canal_orden > 1) / sum(turismos) FILTER (WHERE canal_orden > 1) AS pct_enchufables_flotas
FROM ${canales_anual}
-- Último año completo (con diciembre publicado)
WHERE anio = (SELECT CAST(year(max(mes)) AS INTEGER) - CASE WHEN month(max(mes)) = 12 THEN 0 ELSE 1 END FROM mother.movilidad_matriculaciones_mensual)
```

Fewer than half of new cars are bought by private individuals. The rest go to fleets: companies (which include self-registrations by dealers and brands, the "zero-kilometre" cars), renting, car rental, and taxis and ride-hailing (VTC). In {canales_ultimo[0]?.anio}, private buyers took {formatNumber(canales_ultimo[0]?.pct_particulares, 1)}% of registrations; plug-ins were {formatNumber(canales_ultimo[0]?.pct_enchufables_particulares, 1)}% of their purchases, compared with {formatNumber(canales_ultimo[0]?.pct_enchufables_flotas, 1)}% in fleets.

<BarChart
    data={canales_anual}
    x=anio
    y=turismos
    series=canal
    type=stacked100
    yFmt=pct0
    xFmt="####"
    seriesOrder={canales_orden.map(d => d.canal)}
    colorPalette={['#0d9488', '#2563eb', '#7c3aed', '#f59e0b', '#9ca3af']}
    title="New cars by sales channel"
/>

<LineChart
    data={canales_anual}
    x=anio
    y=cuota_enchufables
    series=canal
    yFmt=pct0
    xFmt="####"
    markers=true
    seriesOrder={canales_orden.map(d => d.canal)}
    colorPalette={['#0d9488', '#2563eb', '#7c3aed', '#f59e0b', '#9ca3af']}
    title="Plug-in share (battery electric + plug-in hybrids) in each channel"
/>

<p class="text-xs text-gray-500">Private buyers: registered to a natural person (including the self-employed) without renting. Companies: legal entities, without renting or rental. Renting: long-term lease contracts, for companies or individuals. Rental: rental service without driver (rent a car). Taxi, VTC and others: public service (taxi, hire with driver, driving schools...). The latest year is incomplete.</p>

## CO2 emissions of new cars

<LineChart
    data={co2}
    x=mes
    y=co2_medio
    yFmt=num0
    xFmt="mmm yyyy"
    yAxisTitle="g CO2/km"
    colorPalette={['#78716c']}
/>

<p class="text-xs text-gray-500">Average type-approved emissions of new cars (g/km, with electric cars counted as 0). The rise up to 2021 has two causes: the switch from diesel (which emits less CO2 per kilometre) to petrol, and the change of type-approval cycle from NEDC to the stricter WLTP, which raises the official figures without the cars actually polluting more. Since then they have fallen as hybrids and electric cars have arrived.</p>

```sql provincias
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_provincia)
SELECT
    p.cod_prov,
    p.provincia,
    sum(p.matriculaciones) AS turismos,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'bev') / sum(p.matriculaciones) AS cuota_bev,
    sum(p.matriculaciones) FILTER (WHERE p.energia IN ('bev', 'phev')) / sum(p.matriculaciones) AS cuota_enchufables,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'diesel') / sum(p.matriculaciones) AS cuota_diesel
FROM mother.movilidad_matriculaciones_provincia p, ult
WHERE p.nuevo_usado = 'N'
  AND p.mes > ult.mes - INTERVAL 12 MONTH
  AND ('${inputs.canal_prov}' = 'todos' OR p.canal = 'particular')
GROUP BY ALL
ORDER BY cuota_enchufables DESC
```

## Where are the most plug-in cars bought?

Share of battery electric and plug-in hybrids among new cars over the last 12 months, by the province of the owner's registered address. By default only private buyers' cars are counted: fleets are registered where they have their headquarters and distort the map (see the note below).

<ButtonGroup name=canal_prov title="Buyers">
    <ButtonGroupItem valueLabel="Private buyers only" value="particular" default />
    <ButtonGroupItem valueLabel="All, including fleets" value="todos" />
</ButtonGroup>

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_enchufables"
    valueFmt="pct1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_enchufables', title: 'Plug-in', fmt: 'pct1'},
        {id: 'cuota_bev', title: 'Battery electric', fmt: 'pct1'},
        {id: 'turismos', title: 'New cars', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=turismos title="New cars (12 months)" fmt=num0 />
    <Column id=cuota_bev title="Battery electric" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_enchufables title="Plug-in" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_diesel title="Diesel" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500"><b>Where fleets are registered.</b> A car is registered in the municipality of its owner's domicile, and renting and rental companies choose where to domicile their fleets. Vehicle tax (IVTM) is municipal: each town council can raise the minimum rate up to double, so many fleets are registered at a branch opened in a municipality with the lowest tax. That is why villages such as La Hiruela, Venturada or Patones (Madrid) or Aguilar de Segarra (Barcelona) register many more cars each year than they have inhabitants, and according to the AEA association ten municipalities account for around 35% of company-vehicle registrations. Those cars are then driven all over the country; with "All, including fleets", Madrid and Barcelona appear far above what their residents buy. Source: <a href="https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/">AEA, study on the IVTM (2026)</a>. The municipalities, one by one, in <a href="/en/movilidad/flotas-e-impuestos">The fleet tax havens</a>.</p>

---

## Sources and notes

- **[DGT – Vehicle registration microdata (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, monthly since January 2015. Only ordinary registrations of **new** passenger cars (including off-roaders) are counted; imported used cars, which are also registered in Spain for the first time, are excluded.
- Engine type combines the electric vehicle category (BEV, PHEV, REEV, HEV) with the propulsion recorded in the vehicle's technical data sheet. Gas includes LPG and natural gas.
- The figures may differ slightly from those of the industry associations (ANFAC, which uses its own date and classification criteria). ANFAC also separates private buyers, companies and rental firms; here the channel comes from the owner (natural or legal person), the renting flag and the type of service of each vehicle in the DGT file.
- For the latest month, until the DGT publishes the monthly file (around the 15th of the following month), figures are calculated from its daily files.
- The international comparison (full year, battery electric plus plug-in hybrids) comes from the **[IEA – Global EV Data Explorer](https://www.iea.org/data-and-statistics/data-tools/global-ev-data-explorer)** (CC BY 4.0), which rounds recent shares to whole numbers; that is why it may not match the DGT figure exactly. Norway and Denmark appear as a reference (dashed border): they are the countries where electric cars are most widespread.

<LastRefreshed prefix="Data updated" />
