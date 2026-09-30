---
title: Incendis forestals
description: Superfície cremada a Espanya cada any, incendis dins de la Xarxa Natura 2000, mapa d'àrees cremades i focus actius detectats per satèl·lit.
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

# 🔥 Incendis forestals a Espanya

En el que portem de **{kpis[0]?.anio}** els satèl·lits de Copernicus han cartografiat **{formatNumber(kpis[0]?.n_incendios, 0)} incendis** que han cremat **{formatNumber(kpis[0]?.ha_quemadas, 0)} hectàrees**, {kpis[0]?.ha_misma_fecha > kpis[0]?.ha_media_10 ? 'per sobre' : 'per sota'} de la mitjana de l'última dècada en aquest moment de l'any ({formatNumber(kpis[0]?.ha_media_10, 0)} ha). El **{formatNumber(kpis[0]?.pct_natura2000, 1)} %** del que s'ha cremat és dins d'espais protegits de la **Xarxa Natura 2000**. Últim incendi registrat: **{new Date(kpis[0]?.ultima_fecha).toLocaleDateString('ca-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**.

<Grid cols=3>
    <KpiCard
        title="Superfície cremada el {kpis[0]?.anio}"
        value={kpis[0]?.ha_quemadas}
        formattedValue={formatNumber(kpis[0]?.ha_quemadas, 0)}
        unit=" ha"
        change={kpis[0]?.ha_media_10 ? Math.round(100 * (kpis[0]?.ha_misma_fecha / kpis[0]?.ha_media_10 - 1)) : null}
        changeUnit="%"
        changePeriod="vs. mitjana de 10 anys a la mateixa data"
        direction="positive-down"
        source="EFFIS – Copernicus"
        sparklineData={serie_ha}
    />
    <KpiCard
        title="Incendis cartografiats"
        value={kpis[0]?.n_incendios}
        formattedValue={formatNumber(kpis[0]?.n_incendios, 0)}
        period="{formatNumber(kpis[0]?.n_grandes_incendios, 0)} de més de 500 ha · mitjana de 10 anys: {formatNumber(kpis[0]?.n_media_10, 0)}"
        direction="positive-down"
        sparklineData={serie_n}
    />
    <KpiCard
        title="Cremat a la Xarxa Natura 2000"
        value={kpis[0]?.pct_natura2000}
        formattedValue={formatNumber(kpis[0]?.pct_natura2000, 1)}
        unit="%"
        period="{formatNumber(kpis[0]?.ha_natura2000, 0)} ha · mitjana de 10 anys: {formatNumber(kpis[0]?.pct_natura2000_10, 1)} %"
        direction="positive-down"
        sparklineData={serie_natura}
    />
</Grid>

<p class="text-xs text-gray-500">L'EFFIS cartografia amb imatges de satèl·lit els incendis d'una certa mida (en general, d'unes 30 ha en amunt), de manera que el nombre d'incendis és molt inferior al de l'estadística oficial del MITECO, que compta tots els conats. La superfície, en canvi, recull la gran majoria del que s'ha cremat.</p>

---

## On ha cremat aquest any

Cada cercle és un incendi del {kpis[0]?.anio}, situat al centre del seu perímetre i amb una mida proporcional a la superfície cremada. El color indica quina part de l'àrea cremada és dins de la Xarxa Natura 2000.

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
        {id: 'fecha_txt', title: 'Inici'},
        {id: 'area_ha', title: 'Hectàrees', fmt: 'num0'},
        {id: 'natura2000', title: 'A Natura 2000', fmt: 'pct0'},
        {id: 'cubierta_principal', title: 'Coberta principal'}
    ]}
/>

## Focus actius en els últims 7 dies

Punts calents detectats pels satèl·lits VIIRS i MODIS de la NASA (sistema FIRMS) en territori espanyol. Un incendi gran genera desenes de focus; el color reflecteix la **potència radiativa** del foc (FRP, en megawatts).

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

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(focos_resumen[0]?.n_focos, 0)} focus amb confiança mitjana o alta entre el {new Date(focos_resumen[0]?.desde).toLocaleDateString('ca-ES', { day: 'numeric', month: 'long' })} i el {new Date(focos_resumen[0]?.hasta).toLocaleDateString('ca-ES', { day: 'numeric', month: 'long', year: 'numeric' })}.</p>

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
        {id: 'detectado', title: 'Detectat'},
        {id: 'frp_mw', title: 'Potència (MW)', fmt: 'num1'},
        {id: 'confianza', title: 'Confiança'},
        {id: 'instrumento', title: 'Sensor'}
    ]}
/>

<p class="text-xs text-gray-500">Un focus és un píxel de satèl·lit (375 m en VIIRS, 1 km en MODIS) més calent del normal: a més d'incendis forestals inclou cremes agrícoles i fonts industrials fixes com acereries, refineries o torxes de gas. S'ometen els focus de confiança baixa.</p>

---

## La superfície cremada província a província

```sql anios
SELECT DISTINCT anio FROM mother.incendios_provincia_anio ORDER BY anio DESC
```

<Dropdown data={anios} name=anio_prov value=anio title="Any" />

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
        {id: 'ha_quemadas', title: 'Hectàrees cremades', fmt: 'num0'},
        {id: 'n_incendios', title: 'Incendis', fmt: 'num0'},
        {id: 'ha_natura2000', title: 'Ha a Natura 2000', fmt: 'num0'},
        {id: 'ha_mayor_incendio', title: 'Incendi més gran (ha)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Les províncies sense color no van tenir cap incendi cartografiat per l'EFFIS aquell any.</p>

---

## Un quart de segle d'incendis

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
    yAxisTitle="Hectàrees"
    title="Superfície cremada per any (ha)"
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
    title="Part de la superfície cremada dins de la Xarxa Natura 2000"
    lineColor="#b91c1c"
    markers=true
/>

## Quin tipus de terreny crema

L'EFFIS encreua cada perímetre amb el mapa de cobertes del sòl CORINE: així se sap si el que s'ha cremat era bosc, matollar, pastures o conreus.

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
    title="Superfície cremada per tipus de coberta"
    colorPalette={['#166534', '#a3a635', '#fcd34d', '#d97706', '#9ca3af']}
/>

---

## Els incendis més grans de l'última dècada

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
    <Column id=fecha title="Inici" fmt="dd/mm/yyyy" />
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=area_ha title="Hectàrees" fmt=num0 contentType=bar barColor="#fdba74" />
    <Column id=ha_natura2000 title="Ha a Natura 2000" fmt=num0 />
    <Column id=natura2000 title="% Natura 2000" fmt=pct0 />
    <Column id=cubierta_principal title="Coberta principal" />
</DataTable>

---

## Fonts oficials

- **[EFFIS – European Forest Fire Information System](https://forest-fire.emergency.copernicus.eu/)** (Copernicus, Comissió Europea): perímetres d'àrees cremades cartografiats amb satèl·lit des del 2000, amb la seva superfície, les cobertes del sòl afectades (CORINE Land Cover) i el percentatge dins de la Xarxa Natura 2000. Les xifres de la temporada en curs són provisionals i l'EFFIS les revisa.
- **[NASA FIRMS – Fire Information for Resource Management System](https://firms.modaps.eosdis.nasa.gov/)**: focus de calor gairebé en temps real dels sensors VIIRS (Suomi NPP, NOAA-20 i NOAA-21) i MODIS.
- **[Xarxa Natura 2000](https://www.miteco.gob.es/es/biodiversidad/temas/espacios-protegidos/red-natura-2000.html)** (MITECO): xarxa europea d'espais protegits (ZEC i ZEPA).

L'estadística oficial d'incendis forestals del MITECO inclou també els conats (menys d'1 ha) i es publica amb més retard; per això els seus totals poden diferir dels de l'EFFIS.

<LastRefreshed prefix="Dades actualitzades" />
