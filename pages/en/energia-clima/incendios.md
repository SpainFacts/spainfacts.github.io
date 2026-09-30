---
title: Wildfires
description: Area burnt in Spain each year, fires within the Natura 2000 network, a map of burnt areas and active fires detected by satellite.
i18n_origen: e647cb90ccc3
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql kpis
SELECT
    a.anio,
    a.ultima_fecha,
    a.ha_quemadas,
    a.n_incendios,
    a.n_grandes_incendios,
    a.ha_mayor_incendio,
    a.pct_natura2000,
    a.ha_natura2000,
    a.ha_misma_fecha,
    (SELECT avg(h.ha_misma_fecha) FROM mother.incendios_anual h WHERE h.anio BETWEEN a.anio - 10 AND a.anio - 1) AS ha_media_10,
    (SELECT avg(h.n_incendios_misma_fecha) FROM mother.incendios_anual h WHERE h.anio BETWEEN a.anio - 10 AND a.anio - 1) AS n_media_10,
    (SELECT sum(h.ha_natura2000) * 100.0 / sum(h.ha_quemadas) FROM mother.incendios_anual h WHERE h.anio BETWEEN a.anio - 10 AND a.anio - 1) AS pct_natura2000_10
FROM mother.incendios_anual a
WHERE a.es_anio_actual
```

```sql serie_ha
SELECT anio, ha_quemadas AS valor FROM mother.incendios_anual ORDER BY anio
```

```sql serie_n
SELECT anio, n_incendios AS valor FROM mother.incendios_anual ORDER BY anio
```

```sql serie_natura
SELECT anio, pct_natura2000 AS valor FROM mother.incendios_anual ORDER BY anio
```

# 🔥 Wildfires in Spain

So far in **{kpis[0]?.anio}**, Copernicus satellites have mapped **{formatNumber(kpis[0]?.n_incendios, 0)} fires** that have burnt **{formatNumber(kpis[0]?.ha_quemadas, 0)} hectares**, {kpis[0]?.ha_misma_fecha > kpis[0]?.ha_media_10 ? 'above' : 'below'} the average for the past decade at this point in the year ({formatNumber(kpis[0]?.ha_media_10, 0)} ha). **{formatNumber(kpis[0]?.pct_natura2000, 1)} %** of the burnt area lies within protected sites of the **Natura 2000 network**. Latest fire recorded: **{new Date(kpis[0]?.ultima_fecha).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}**.

<Grid cols=3>
    <KpiCard
        title="Area burnt in {kpis[0]?.anio}"
        value={kpis[0]?.ha_quemadas}
        formattedValue={formatNumber(kpis[0]?.ha_quemadas, 0)}
        unit=" ha"
        change={kpis[0]?.ha_media_10 ? Math.round(100 * (kpis[0]?.ha_misma_fecha / kpis[0]?.ha_media_10 - 1)) : null}
        changeUnit="%"
        changePeriod="vs 10-year average to the same date"
        direction="positive-down"
        source="EFFIS – Copernicus"
        sparklineData={serie_ha}
    />
    <KpiCard
        title="Fires mapped"
        value={kpis[0]?.n_incendios}
        formattedValue={formatNumber(kpis[0]?.n_incendios, 0)}
        period="{formatNumber(kpis[0]?.n_grandes_incendios, 0)} larger than 500 ha · 10-year average: {formatNumber(kpis[0]?.n_media_10, 0)}"
        direction="positive-down"
        sparklineData={serie_n}
    />
    <KpiCard
        title="Burnt within Natura 2000"
        value={kpis[0]?.pct_natura2000}
        formattedValue={formatNumber(kpis[0]?.pct_natura2000, 1)}
        unit="%"
        period="{formatNumber(kpis[0]?.ha_natura2000, 0)} ha · 10-year average: {formatNumber(kpis[0]?.pct_natura2000_10, 1)} %"
        direction="positive-down"
        sparklineData={serie_natura}
    />
</Grid>

<p class="text-xs text-gray-500">EFFIS uses satellite imagery to map fires above a certain size (generally around 30 ha or more), so the number of fires is far lower than in MITECO's official statistics, which count every incipient fire. The burnt area, however, captures the vast majority of what has burnt.</p>

---

## Where fires have burnt this year

Each circle is a {kpis[0]?.anio} fire, placed at the centre of its perimeter and sized in proportion to the area burnt. The colour shows how much of the burnt area lies within the Natura 2000 network.

```sql areas_anio
SELECT
    municipio,
    provincia,
    strftime(fecha, '%d/%m/%Y') AS fecha_txt,
    area_ha,
    pct_natura2000 / 100 AS natura2000,
    cubierta_principal,
    latitud,
    longitud
FROM mother.incendios_areas_quemadas
WHERE anio = (SELECT max(anio) FROM mother.incendios_areas_quemadas)
ORDER BY area_ha DESC
```

<BubbleMap
    data={areas_anio}
    lat=latitud
    long=longitud
    size=area_ha
    maxSize={40}
    value=natura2000
    valueFmt=pct0
    colorPalette={['#fdba74', '#dc2626', '#7f1d1d']}
    pointName=municipio
    height={520}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'provincia', showColumnName: false},
        {id: 'fecha_txt', title: 'Start'},
        {id: 'area_ha', title: 'Hectares', fmt: 'num0'},
        {id: 'natura2000', title: 'Within Natura 2000', fmt: 'pct0'},
        {id: 'cubierta_principal', title: 'Main land cover'}
    ]}
/>

## Active fires in the last 7 days

Hotspots detected on Spanish territory by NASA's VIIRS and MODIS satellites (FIRMS system). A large fire produces dozens of hotspots; the colour reflects the fire's **radiative power** (FRP, in megawatts).

```sql focos
SELECT
    latitud,
    longitud,
    provincia,
    strftime(fecha_hora_utc, '%d/%m %H:%M') || ' UTC' AS detectado,
    instrumento,
    confianza,
    frp_mw,
    least(frp_mw, 100) AS intensidad
FROM mother.incendios_focos_activos
WHERE confianza <> 'baja'
ORDER BY frp_mw
```

```sql focos_resumen
SELECT
    count(*) AS n_focos,
    min(fecha) AS desde,
    max(fecha) AS hasta
FROM mother.incendios_focos_activos
WHERE confianza <> 'baja'
```

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(focos_resumen[0]?.n_focos, 0)} hotspots with medium or high confidence between {new Date(focos_resumen[0]?.desde).toLocaleDateString('en-GB', { day: 'numeric', month: 'long' })} and {new Date(focos_resumen[0]?.hasta).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}.</p>

<PointMap
    data={focos}
    lat=latitud
    long=longitud
    value=intensidad
    valueFmt=num0
    colorPalette={['#fde047', '#f97316', '#b91c1c']}
    pointName=provincia
    height={480}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'detectado', title: 'Detected'},
        {id: 'frp_mw', title: 'Power (MW)', fmt: 'num1'},
        {id: 'confianza', title: 'Confidence'},
        {id: 'instrumento', title: 'Sensor'}
    ]}
/>

<p class="text-xs text-gray-500">A hotspot is a satellite pixel (375 m for VIIRS, 1 km for MODIS) that is hotter than normal: besides wildfires, it includes agricultural burning and fixed industrial sources such as steelworks, refineries or gas flares. Low-confidence hotspots are omitted.</p>

---

## Area burnt, province by province

```sql anios
SELECT DISTINCT anio FROM mother.incendios_provincia_anio ORDER BY anio DESC
```

<Dropdown data={anios} name=anio_prov value=anio title="Year" />

```sql provincias
SELECT
    cod_prov,
    provincia,
    ha_quemadas,
    n_incendios,
    ha_natura2000,
    ha_mayor_incendio
FROM mother.incendios_provincia_anio
WHERE anio = ${inputs.anio_prov.value}
```

<AreaMap
    data={provincias}
    geoJsonUrl="/spain-provinces.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="ha_quemadas"
    valueFmt="num0"
    colorPalette={['#fed7aa', '#f97316', '#7f1d1d']}
    height={480}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ha_quemadas', title: 'Hectares burnt', fmt: 'num0'},
        {id: 'n_incendios', title: 'Fires', fmt: 'num0'},
        {id: 'ha_natura2000', title: 'Ha within Natura 2000', fmt: 'num0'},
        {id: 'ha_mayor_incendio', title: 'Largest fire (ha)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Provinces without colour had no fires mapped by EFFIS that year.</p>

---

## A quarter of a century of fires

```sql anual
SELECT
    anio::VARCHAR AS año,
    ha_quemadas - ha_natura2000 AS "Fuera de Natura 2000",
    ha_natura2000 AS "Dentro de Natura 2000"
FROM mother.incendios_anual
ORDER BY anio
```

<BarChart
    data={anual}
    x=año
    y={['Dentro de Natura 2000', 'Fuera de Natura 2000']}
    yFmt=num0
    yAxisTitle="Hectares"
    title="Area burnt per year (ha)"
    colorPalette={['#b91c1c', '#fdba74']}
/>

```sql natura_anual
SELECT anio::VARCHAR AS año, pct_natura2000 / 100 AS natura2000, n_incendios
FROM mother.incendios_anual
ORDER BY anio
```

<LineChart
    data={natura_anual}
    x=año
    y=natura2000
    yFmt=pct0
    title="Share of burnt area within the Natura 2000 network"
    lineColor="#b91c1c"
    markers=true
/>

## What kind of land burns

EFFIS overlays each perimeter on the CORINE land cover map, which shows whether the burnt land was forest, scrub, grassland or cropland.

```sql cubiertas
SELECT anio::VARCHAR AS año, 'Arbolado' AS cubierta, ha_arbolado AS ha FROM mother.incendios_anual
UNION ALL SELECT anio::VARCHAR, 'Matorral', ha_matorral FROM mother.incendios_anual
UNION ALL SELECT anio::VARCHAR, 'Pastos y otra vegetación natural', ha_otra_natural FROM mother.incendios_anual
UNION ALL SELECT anio::VARCHAR, 'Agrícola', ha_agricola FROM mother.incendios_anual
UNION ALL SELECT anio::VARCHAR, 'Otras', ha_otras FROM mother.incendios_anual
ORDER BY año
```

<BarChart
    data={cubiertas}
    x=año
    y=ha
    series=cubierta
    type=stacked100
    title="Area burnt by land cover type"
    colorPalette={['#166534', '#a3a635', '#fcd34d', '#d97706', '#9ca3af']}
/>

---

## The largest fires of the past decade

```sql grandes
SELECT
    fecha,
    municipio,
    provincia,
    area_ha,
    ha_natura2000,
    pct_natura2000 / 100 AS natura2000,
    cubierta_principal
FROM mother.incendios_areas_quemadas
ORDER BY area_ha DESC
```

<DataTable data={grandes} search=true rows=15>
    <Column id=fecha title="Start" fmt="dd/mm/yyyy" />
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=area_ha title="Hectares" fmt=num0 contentType=bar barColor="#fdba74" />
    <Column id=ha_natura2000 title="Ha within Natura 2000" fmt=num0 />
    <Column id=natura2000 title="% Natura 2000" fmt=pct0 />
    <Column id=cubierta_principal title="Main land cover" />
</DataTable>

---

## Official sources

- **[EFFIS – European Forest Fire Information System](https://forest-fire.emergency.copernicus.eu/)** (Copernicus, European Commission): burnt area perimeters mapped by satellite since 2000, with their area, the land cover affected (CORINE Land Cover) and the share within the Natura 2000 network. Figures for the current season are provisional and are revised by EFFIS.
- **[NASA FIRMS – Fire Information for Resource Management System](https://firms.modaps.eosdis.nasa.gov/)**: near-real-time hotspots from the VIIRS (Suomi NPP, NOAA-20 and NOAA-21) and MODIS sensors.
- **[Natura 2000 network](https://www.miteco.gob.es/es/biodiversidad/temas/espacios-protegidos/red-natura-2000.html)** (MITECO): the European network of protected sites (SACs and SPAs).

MITECO's official wildfire statistics also include incipient fires (under 1 ha) and are published with a longer delay, which is why their totals may differ from EFFIS's.

<LastRefreshed prefix="Data updated" />
