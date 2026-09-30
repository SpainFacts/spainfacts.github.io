---
title: Power plants
description: "Map of Spain's power plants: operating, under construction, in the permitting pipeline and retired, by technology, capacity and owner."
i18n_origen: abe822fcd116
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql tecnologias
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM mother.centrales_resumen
GROUP BY tecnologia
ORDER BY orden
```

```sql kpis
SELECT
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') / 1000 AS gw_operacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación' AND renovable) * 100
        / sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') AS pct_renovable,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En construcción') / 1000 AS gw_construccion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En tramitación') / 1000 AS gw_tramitacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'Anunciada') / 1000 AS gw_anunciada,
    (SELECT count(*) FROM mother.centrales WHERE estado_grupo = 'En operación') AS n_operacion
FROM mother.centrales_resumen
```

```sql carbon
SELECT sum(mw_baja) / 1000 AS gw_carbon_retirado
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018
```

```sql operacion_serie
SELECT anio, valor
FROM (
    SELECT anio, sum(sum(mw_alta - mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
    FROM mother.centrales_por_anio
    WHERE anio <= year(current_date)
    GROUP BY anio
)
WHERE anio >= 2000
ORDER BY anio
```

```sql carbon_serie
SELECT anio, sum(sum(mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018 AND anio <= year(current_date)
GROUP BY anio
ORDER BY anio
```

# ⚡ Spain's power plants

Spain has **{formatNumber(kpis[0]?.gw_operacion, 1)} GW** of capacity in **{formatNumber(kpis[0]?.n_operacion, 0)} operating power plants** of more than 1 MW, and another **{formatNumber(kpis[0]?.gw_construccion, 1)} GW** under construction. Behind them are **{formatNumber(kpis[0]?.gw_tramitacion, 0)} GW** of projects going through the permitting process, more than all the capacity already running, although only part of it will ever be built. This map shows every power plant (operating, under construction, in permitting, announced or already closed) according to Global Energy Monitor's worldwide inventory.

<Grid cols=4>
    <KpiCard
        title="Operating"
        value={kpis[0]?.gw_operacion}
        formattedValue={formatNumber(kpis[0]?.gw_operacion, 1)}
        unit=" GW"
        period="{formatNumber(kpis[0]?.pct_renovable, 0)} % renewable"
        source="Global Energy Monitor"
        sparklineData={operacion_serie}
    />
    <KpiCard
        title="Under construction"
        value={kpis[0]?.gw_construccion}
        formattedValue={formatNumber(kpis[0]?.gw_construccion, 1)}
        unit=" GW"
        period="Works started"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="In permitting"
        value={kpis[0]?.gw_tramitacion}
        formattedValue={formatNumber(kpis[0]?.gw_tramitacion, 0)}
        unit=" GW"
        period="Permits in progress"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Coal closed since 2018"
        value={carbon[0]?.gw_carbon_retirado}
        formattedValue={formatNumber(carbon[0]?.gw_carbon_retirado, 1)}
        unit=" GW"
        period="Coal capacity retired"
        source="Global Energy Monitor"
        sparklineData={carbon_serie}
    />
</Grid>

---

## The map

Each circle is a power plant: its area is proportional to capacity and its colour shows the technology. Choose the status, the technologies and the region; hover over a circle to see its details.

```sql opciones_ccaa
SELECT DISTINCT cod_ccaa, ccaa
FROM mother.centrales
WHERE ccaa IS NOT NULL
ORDER BY ccaa
```

<ButtonGroup name=estado title="Status">
    <ButtonGroupItem valueLabel="Operating" value="En operación" default />
    <ButtonGroupItem valueLabel="Under construction" value="En construcción" />
    <ButtonGroupItem valueLabel="In permitting" value="En tramitación" />
    <ButtonGroupItem valueLabel="Announced" value="Anunciada" />
    <ButtonGroupItem valueLabel="Shelved" value="Paralizada" />
    <ButtonGroupItem valueLabel="Retired" value="Retirada" />
    <ButtonGroupItem valueLabel="Cancelled" value="Cancelada" />
    <ButtonGroupItem valueLabel="All" value="Todas" />
</ButtonGroup>

<Dropdown data={tecnologias} name=tec value=tecnologia order=orden title="Technology" multiple=true selectAllByDefault=true />

<Dropdown data={opciones_ccaa} name=ccaa value=cod_ccaa label=ccaa title="Region" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="All of Spain" />
</Dropdown>

```sql filtradas
SELECT
    nombre,
    tecnologia,
    color,
    orden_tecnologia,
    estado_grupo,
    estados,
    potencia_mw,
    n_unidades,
    CASE
        WHEN estado_grupo = 'Retirada' AND anio_retiro IS NOT NULL THEN 'Cerrada en ' || CAST(CAST(anio_retiro AS INTEGER) AS VARCHAR)
        WHEN anio_inicio_min IS NULL THEN 'Sin fecha'
        WHEN anio_inicio_min = anio_inicio_max THEN CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR) || '–' || CAST(CAST(anio_inicio_max AS INTEGER) AS VARCHAR)
    END AS fechas,
    anio_inicio_min,
    coalesce(propietario, 'Sin datos') AS propietario,
    coalesce(municipio || ' (' || provincia || ')', provincia) AS ubicacion,
    provincia,
    ccaa,
    precision_ubicacion,
    lat,
    lon,
    url_gem
FROM mother.centrales
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
```

```sql mapa
-- La paleta categórica de BubbleMap se asigna por orden de aparición: primero
-- va la mayor central de cada tecnología (en el orden de la paleta) y luego el
-- resto de mayor a menor, para que las pequeñas queden encima.
SELECT *
FROM (
    SELECT *, row_number() OVER (PARTITION BY tecnologia ORDER BY potencia_mw DESC NULLS LAST, nombre) = 1 AS primera
    FROM ${filtradas}
    WHERE potencia_mw > 0
)
ORDER BY primera DESC, CASE WHEN primera THEN orden_tecnologia END, potencia_mw DESC
```

```sql colores_mapa
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM ${filtradas}
WHERE potencia_mw > 0
GROUP BY tecnologia
ORDER BY orden
```

```sql totales_filtro
SELECT count(*) AS n_centrales, sum(potencia_mw) / 1000 AS gw
FROM ${filtradas}
```

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(totales_filtro[0]?.n_centrales, 0)} power plants with {formatNumber(totales_filtro[0]?.gw, 1)} GW for the selected filters.</p>

<BubbleMap
    data={mapa}
    lat=lat
    long=lon
    size=potencia_mw
    maxSize={26}
    value=tecnologia
    legendType=categorical
    colorPalette={[...new Map(Array.from(mapa ?? []).map(d => [d.tecnologia, d.color])).values()]}
    opacity={0.75}
    pointName=nombre
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Power plants: Global Energy Monitor (CC BY 4.0)"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tecnologia', title: 'Technology'},
        {id: 'potencia_mw', title: 'Capacity (MW)', fmt: 'num0'},
        {id: 'estados', title: 'Status'},
        {id: 'fechas', title: 'Commissioned'},
        {id: 'propietario', title: 'Owner'},
        {id: 'ubicacion', title: 'Location'}
    ]}
/>

<p class="text-xs text-gray-500">The coordinates of about 2,900 units (mostly solar and wind farms in the permitting process) are approximate: they are usually placed in the municipality, not on the exact plot. The Canary Islands appear to the south-west: zoom in on the map or choose the region in the filter.</p>

---

## What is running and what is coming

The capacity in permitting and announced is several times the installed capacity, but it is not a forecast: a large share of those projects will never be built (the inventory itself flags as shelved or cancelled those that have had no news for years). Capacity **under construction** is the best clue to what will come into service in the next two or three years.

```sql por_estado
SELECT
    estado_grupo,
    min(orden_estado) AS orden_estado,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw
FROM mother.centrales_ccaa
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
GROUP BY estado_grupo, tecnologia
ORDER BY orden_estado, min(orden_tecnologia)
```

<BarChart
    data={por_estado}
    x=estado_grupo
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Capacity by status and technology (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={420}
/>

```sql por_ccaa
SELECT
    ccaa,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw,
    sum(sum(potencia_mw)) OVER (PARTITION BY ccaa) AS total_ccaa
FROM mother.centrales_ccaa
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
GROUP BY ccaa, tecnologia
ORDER BY total_ccaa DESC, min(orden_tecnologia)
```

<BarChart
    data={por_ccaa}
    x=ccaa
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Capacity by region — {inputs.estado} (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={520}
/>

---

## How the generation fleet has changed

Capacity that came into service and that was closed each year, according to each unit's commissioning date. You can see the nuclear and coal wave of the 1980s, the combined cycle and wind plants of the 2000s, the standstill of the 2010s and the great solar photovoltaic wave since 2019; and, in the second chart, the closure of almost all coal around 2020.

**Beware of 2017**: some 790 small photovoltaic farms (3.9 GW, median of 3 MW) are listed in the inventory with 2017 as their commissioning year. This is almost certainly a default date (all of them are farms for which GEM "assumes" photovoltaic technology), and most of them probably date from the first solar boom of 2007-2008. That peak does not reflect what was built in 2017.

```sql altas_bajas
SELECT
    anio,
    tecnologia,
    min(orden_tecnologia) AS orden,
    sum(mw_alta) / 1000 AS gw_alta,
    sum(mw_baja) / 1000 AS gw_baja
FROM mother.centrales_por_anio
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
  AND anio BETWEEN 1950 AND year(current_date)
GROUP BY anio, tecnologia
ORDER BY anio, orden
```

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_alta
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Capacity commissioned each year (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_baja
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Capacity closed each year (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

```sql acumulada
WITH anios AS (
    SELECT range AS anio FROM range(1950, year(current_date) + 1)
),
tecs AS (
    SELECT DISTINCT tecnologia FROM ${altas_bajas}
),
neta AS (
    SELECT anio, tecnologia, sum(gw_alta - gw_baja) AS gw FROM ${altas_bajas} GROUP BY ALL
)
SELECT
    a.anio,
    t.tecnologia,
    sum(coalesce(n.gw, 0)) OVER (PARTITION BY t.tecnologia ORDER BY a.anio) AS gw
FROM anios a
CROSS JOIN tecs t
LEFT JOIN neta n ON n.anio = a.anio AND n.tecnologia = t.tecnologia
ORDER BY a.anio
```

<AreaChart
    data={acumulada}
    x=anio
    y=gw
    series=tecnologia
    xFmt="0"
    yFmt=num0
    yAxisTitle="GW"
    title="Cumulative capacity in service based on commissioning and closure dates (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<p class="text-xs text-gray-500">Some 8 GW in operation (mostly small solar and wind farms) have no commissioning year in the inventory and do not appear in these charts, so the cumulative total falls somewhat short of current capacity. Repowering projects and plants that closed before the inventory existed may be missing.</p>

---

## All power plants

```sql tabla
SELECT
    nombre,
    tecnologia,
    potencia_mw,
    n_unidades,
    estados,
    fechas,
    provincia,
    propietario,
    url_gem
FROM ${filtradas}
ORDER BY potencia_mw DESC NULLS LAST
```

<DataTable data={tabla} search=true rows=20>
    <Column id=nombre title="Power plant" />
    <Column id=tecnologia title="Technology" />
    <Column id=potencia_mw title="MW" fmt=num0 />
    <Column id=n_unidades title="Units" />
    <Column id=estados title="Status" />
    <Column id=fechas title="Commissioned" />
    <Column id=provincia title="Province" />
    <Column id=propietario title="Owner" />
    <Column id=url_gem title="Details" contentType=link linkLabel="GEM ↗" openInNewTab=true />
</DataTable>

<DownloadCsvButton data={tabla} filename="spainfacts_centrales_electricas.csv" label="Download power plants (CSV)" />

---

## Methodology and caveats

- **Source**: Global Energy Monitor's (GEM) [Global Integrated Power Tracker](https://globalenergymonitor.org/projects/global-integrated-power-tracker/), September 2026 edition, licensed under CC BY 4.0. It is the only open inventory that brings together, for the whole of Spain, the location, capacity, status, owner and dates of every power plant, including those under construction, in permitting or already closed.
- **Units and plants**: GEM records units or phases (each unit of a thermal plant, each phase of a farm). Here they are grouped by plant and status: if a plant has some units closed and others running, it appears twice, once under each status. The technology of each point is the one with the largest capacity.
- **Statuses**: *operating*; *under construction* (works started); *in permitting* (pre-construction: with permits or financing in progress); *announced*; *shelved* (halted projects, those GEM considers shelved after two years without news, and plants in reserve or mothballed); *cancelled* (including projects with no news for four years) and *retired*. In the data and charts they appear with their Spanish labels: En operación, En construcción, En tramitación, Anunciada, Paralizada, Cancelada and Retirada.
- **The project pipeline is inflated**: some 92 GW of solar and 47 GW of wind are in permitting, far more than the system can absorb and than the PNIEC (Spain's National Integrated Energy and Climate Plan) envisages. Many projects are competing for the same grid access and will end up lapsing. That is why capacity under construction is shown separately from capacity in permitting or announced.
- **What is not included**: self-consumption and rooftop photovoltaics (about 8-9 GW), small installations (GEM covers solar from ~1 MW and wind from ~6 MW and leaves out mini-hydro and much of industrial cogeneration) and batteries, which the inventory does not include; pumped storage is included, within hydro.
- **Comparison with REE**: operating capacity by technology is similar to the official Red Eléctrica figures: photovoltaic ~34 GW (REE ~32 GW excluding self-consumption), wind ~31 GW (~32 GW), hydro including pumped storage ~16 GW (~17 GW), combined cycle ~27 GW (~26 GW), nuclear 7.4 GW gross (7.1 GW net). Cogeneration falls well short of the official figure (~1.4 GW versus ~5-6 GW) because GEM only covers the large plants. Pumped storage brings together hydro plants with pumping, pure or mixed.
- **Technologies**: *cogeneration* are natural gas units of less than 150 MW that also produce heat for industry; *gas turbines and engines* and *steam turbines* are mostly the fuel oil and diesel units in the Canary Islands, the Balearic Islands, Ceuta and Melilla. Municipal waste is counted as non-renewable, and pumped storage, as storage, does not count towards the renewable percentage either.
- **Location**: the province and region are assigned from each unit's coordinates (offshore wind farms, to the nearest coastal province).

Citation: *Global Integrated Power Tracker, Global Energy Monitor, September 2026 (CC BY 4.0)*.

<LastRefreshed prefix="Data updated" />
