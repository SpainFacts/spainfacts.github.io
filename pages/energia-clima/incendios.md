---
title: Incendios forestales
description: Superficie quemada en España cada año, incendios dentro de la Red Natura 2000, mapa de áreas quemadas y focos activos detectados por satélite.
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🔥 Incendios forestales en España

En lo que va de **{kpis[0]?.anio}** los satélites de Copernicus han cartografiado **{formatNumber(kpis[0]?.n_incendios, 0)} incendios** que han quemado **{formatNumber(kpis[0]?.ha_quemadas, 0)} hectáreas**, {kpis[0]?.ha_misma_fecha > kpis[0]?.ha_media_10 ? 'por encima' : 'por debajo'} de la media de la última década a estas alturas del año ({formatNumber(kpis[0]?.ha_media_10, 0)} ha). El **{formatNumber(kpis[0]?.pct_natura2000, 1)} %** de lo quemado está dentro de espacios protegidos de la **Red Natura 2000**. Último incendio registrado: **{new Date(kpis[0]?.ultima_fecha).toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**.

<Grid cols=3>
    <KpiCard
        title="Superficie quemada en {kpis[0]?.anio}"
        value={kpis[0]?.ha_quemadas}
        formattedValue={formatNumber(kpis[0]?.ha_quemadas, 0)}
        unit=" ha"
        change={kpis[0]?.ha_media_10 ? Math.round(100 * (kpis[0]?.ha_misma_fecha / kpis[0]?.ha_media_10 - 1)) : null}
        changeUnit="%"
        changePeriod="vs. media 10 años a la misma fecha"
        direction="positive-down"
        source="EFFIS – Copernicus"
        sparklineData={serie_ha}
    />
    <KpiCard
        title="Incendios cartografiados"
        value={kpis[0]?.n_incendios}
        formattedValue={formatNumber(kpis[0]?.n_incendios, 0)}
        period="{formatNumber(kpis[0]?.n_grandes_incendios, 0)} de más de 500 ha · media 10 años: {formatNumber(kpis[0]?.n_media_10, 0)}"
        direction="positive-down"
        sparklineData={serie_n}
    />
    <KpiCard
        title="Quemado en Red Natura 2000"
        value={kpis[0]?.pct_natura2000}
        formattedValue={formatNumber(kpis[0]?.pct_natura2000, 1)}
        unit="%"
        period="{formatNumber(kpis[0]?.ha_natura2000, 0)} ha · media 10 años: {formatNumber(kpis[0]?.pct_natura2000_10, 1)} %"
        direction="positive-down"
        sparklineData={serie_natura}
    />
</Grid>

<p class="text-xs text-gray-500">EFFIS cartografía con imágenes de satélite los incendios de cierto tamaño (en general, de unas 30 ha en adelante), así que el número de incendios es muy inferior al de la estadística oficial del MITECO, que cuenta todos los conatos. La superficie, en cambio, recoge la gran mayoría de lo quemado.</p>

---

## Dónde ha ardido este año

Cada círculo es un incendio de {kpis[0]?.anio}, situado en el centro de su perímetro y con tamaño proporcional a la superficie quemada. El color indica qué parte del área quemada está dentro de la Red Natura 2000.

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

<MapaEspana
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
        {id: 'fecha_txt', title: 'Inicio'},
        {id: 'area_ha', title: 'Hectáreas', fmt: 'num0'},
        {id: 'natura2000', title: 'En Natura 2000', fmt: 'pct0'},
        {id: 'cubierta_principal', title: 'Cubierta principal'}
    ]}
/>

## Focos activos en los últimos 7 días

Puntos calientes detectados por los satélites VIIRS y MODIS de la NASA (sistema FIRMS) en territorio español. Un incendio grande genera decenas de focos; el color refleja la **potencia radiativa** del fuego (FRP, en megavatios).

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

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(focos_resumen[0]?.n_focos, 0)} focos con confianza media o alta entre el {new Date(focos_resumen[0]?.desde).toLocaleDateString('es-ES', { day: 'numeric', month: 'long' })} y el {new Date(focos_resumen[0]?.hasta).toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' })}.</p>

<MapaEspana
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
        {id: 'detectado', title: 'Detectado'},
        {id: 'frp_mw', title: 'Potencia (MW)', fmt: 'num1'},
        {id: 'confianza', title: 'Confianza'},
        {id: 'instrumento', title: 'Sensor'}
    ]}
/>

<p class="text-xs text-gray-500">Un foco es un píxel de satélite (375 m en VIIRS, 1 km en MODIS) más caliente de lo normal: además de incendios forestales incluye quemas agrícolas y fuentes industriales fijas como acerías, refinerías o antorchas de gas. Se omiten los focos de confianza baja.</p>

---

## La superficie quemada provincia a provincia

```sql anios
SELECT DISTINCT anio FROM mother.incendios_provincia_anio ORDER BY anio DESC
```

<Dropdown data={anios} name=anio_prov value=anio title="Año" />

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

<MapaEspana
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
        {id: 'ha_quemadas', title: 'Hectáreas quemadas', fmt: 'num0'},
        {id: 'n_incendios', title: 'Incendios', fmt: 'num0'},
        {id: 'ha_natura2000', title: 'Ha en Natura 2000', fmt: 'num0'},
        {id: 'ha_mayor_incendio', title: 'Mayor incendio (ha)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Las provincias sin color no tuvieron ningún incendio cartografiado por EFFIS ese año.</p>

---

## Un cuarto de siglo de incendios

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
    yAxisTitle="Hectáreas"
    title="Superficie quemada por año (ha)"
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
    title="Parte de la superficie quemada dentro de la Red Natura 2000"
    lineColor="#b91c1c"
    markers=true
/>

## Qué tipo de terreno arde

EFFIS cruza cada perímetro con el mapa de cubiertas del suelo CORINE: así se sabe si lo quemado era bosque, matorral, pastos o cultivos.

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
    title="Superficie quemada por tipo de cubierta"
    colorPalette={['#166534', '#a3a635', '#fcd34d', '#d97706', '#9ca3af']}
/>

---

## Los mayores incendios de la última década

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
    <Column id=fecha title="Inicio" fmt="dd/mm/yyyy" />
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=area_ha title="Hectáreas" fmt=num0 contentType=bar barColor="#fdba74" />
    <Column id=ha_natura2000 title="Ha en Natura 2000" fmt=num0 />
    <Column id=natura2000 title="% Natura 2000" fmt=pct0 />
    <Column id=cubierta_principal title="Cubierta principal" />
</DataTable>

---

## Fuentes oficiales

- **[EFFIS – European Forest Fire Information System](https://forest-fire.emergency.copernicus.eu/)** (Copernicus, Comisión Europea): perímetros de áreas quemadas cartografiados con satélite desde 2000, con su superficie, cubiertas del suelo afectadas (CORINE Land Cover) y porcentaje dentro de la Red Natura 2000. Las cifras de la temporada en curso son provisionales y EFFIS las revisa.
- **[NASA FIRMS – Fire Information for Resource Management System](https://firms.modaps.eosdis.nasa.gov/)**: focos de calor casi en tiempo real de los sensores VIIRS (Suomi NPP, NOAA-20 y NOAA-21) y MODIS.
- **[Red Natura 2000](https://www.miteco.gob.es/es/biodiversidad/temas/espacios-protegidos/red-natura-2000.html)** (MITECO): red europea de espacios protegidos (ZEC y ZEPA).

La estadística oficial de incendios forestales del MITECO incluye también los conatos (menos de 1 ha) y se publica con más retraso; por eso sus totales pueden diferir de los de EFFIS.

<LastRefreshed prefix="Datos actualizados" />
