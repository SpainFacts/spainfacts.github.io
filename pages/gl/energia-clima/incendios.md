---
i18n_origen: e647cb90ccc3
title: Incendios forestais
description: Superficie queimada en España cada ano, incendios dentro da Rede Natura 2000, mapa de áreas queimadas e focos activos detectados por satélite.
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

# 🔥 Incendios forestais en España

No que vai de **{kpis[0]?.anio}** os satélites de Copernicus cartografaron **{formatNumber(kpis[0]?.n_incendios, 0)} incendios** que queimaron **{formatNumber(kpis[0]?.ha_quemadas, 0)} hectáreas**, {kpis[0]?.ha_misma_fecha > kpis[0]?.ha_media_10 ? 'por riba' : 'por debaixo'} da media da última década a estas alturas do ano ({formatNumber(kpis[0]?.ha_media_10, 0)} ha). O **{formatNumber(kpis[0]?.pct_natura2000, 1)} %** do queimado está dentro de espazos protexidos da **Rede Natura 2000**. Último incendio rexistrado: **{new Date(kpis[0]?.ultima_fecha).toLocaleDateString('gl-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**.

<Grid cols=3>
    <KpiCard
        title="Superficie queimada en {kpis[0]?.anio}"
        value={kpis[0]?.ha_quemadas}
        formattedValue={formatNumber(kpis[0]?.ha_quemadas, 0)}
        unit=" ha"
        change={kpis[0]?.ha_media_10 ? Math.round(100 * (kpis[0]?.ha_misma_fecha / kpis[0]?.ha_media_10 - 1)) : null}
        changeUnit="%"
        changePeriod="vs. media 10 anos na mesma data"
        direction="positive-down"
        source="EFFIS – Copernicus"
        sparklineData={serie_ha}
    />
    <KpiCard
        title="Incendios cartografados"
        value={kpis[0]?.n_incendios}
        formattedValue={formatNumber(kpis[0]?.n_incendios, 0)}
        period="{formatNumber(kpis[0]?.n_grandes_incendios, 0)} de máis de 500 ha · media 10 anos: {formatNumber(kpis[0]?.n_media_10, 0)}"
        direction="positive-down"
        sparklineData={serie_n}
    />
    <KpiCard
        title="Queimado en Rede Natura 2000"
        value={kpis[0]?.pct_natura2000}
        formattedValue={formatNumber(kpis[0]?.pct_natura2000, 1)}
        unit="%"
        period="{formatNumber(kpis[0]?.ha_natura2000, 0)} ha · media 10 anos: {formatNumber(kpis[0]?.pct_natura2000_10, 1)} %"
        direction="positive-down"
        sparklineData={serie_natura}
    />
</Grid>

<p class="text-xs text-gray-500">EFFIS cartografa con imaxes de satélite os incendios de certo tamaño (en xeral, dunhas 30 ha en diante), así que o número de incendios é moi inferior ao da estatística oficial do MITECO, que conta todos os conatos. A superficie, en cambio, recolle a gran maioría do queimado.</p>

---

## Onde ardeu este ano

Cada círculo é un incendio de {kpis[0]?.anio}, situado no centro do seu perímetro e con tamaño proporcional á superficie queimada. A cor indica que parte da área queimada está dentro da Rede Natura 2000.

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
    attribution="Teselas © Esri — Esri, HERE, Garmin, © colaboradores de OpenStreetMap"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'provincia', showColumnName: false},
        {id: 'fecha_txt', title: 'Inicio'},
        {id: 'area_ha', title: 'Hectáreas', fmt: 'num0'},
        {id: 'natura2000', title: 'En Natura 2000', fmt: 'pct0'},
        {id: 'cubierta_principal', title: 'Cuberta principal'}
    ]}
/>

## Focos activos nos últimos 7 días

Puntos quentes detectados polos satélites VIIRS e MODIS da NASA (sistema FIRMS) en territorio español. Un incendio grande xera decenas de focos; a cor reflicte a **potencia radiativa** do lume (FRP, en megavatios).

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

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(focos_resumen[0]?.n_focos, 0)} focos con confianza media ou alta entre o {new Date(focos_resumen[0]?.desde).toLocaleDateString('gl-ES', { day: 'numeric', month: 'long' })} e o {new Date(focos_resumen[0]?.hasta).toLocaleDateString('gl-ES', { day: 'numeric', month: 'long', year: 'numeric' })}.</p>

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
    attribution="Teselas © Esri — Esri, HERE, Garmin, © colaboradores de OpenStreetMap"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'detectado', title: 'Detectado'},
        {id: 'frp_mw', title: 'Potencia (MW)', fmt: 'num1'},
        {id: 'confianza', title: 'Confianza'},
        {id: 'instrumento', title: 'Sensor'}
    ]}
/>

<p class="text-xs text-gray-500">Un foco é un píxel de satélite (375 m en VIIRS, 1 km en MODIS) máis quente do normal: ademais de incendios forestais inclúe queimas agrícolas e fontes industriais fixas como aceirías, refinarías ou fachos de gas. Omítense os focos de confianza baixa.</p>

---

## A superficie queimada provincia a provincia

```sql anios
SELECT DISTINCT anio FROM mother.incendios_provincia_anio ORDER BY anio DESC
```

<Dropdown data={anios} name=anio_prov value=anio title="Ano" />

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
    attribution="Teselas © Esri — Esri, HERE, Garmin, © colaboradores de OpenStreetMap"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ha_quemadas', title: 'Hectáreas queimadas', fmt: 'num0'},
        {id: 'n_incendios', title: 'Incendios', fmt: 'num0'},
        {id: 'ha_natura2000', title: 'Ha en Natura 2000', fmt: 'num0'},
        {id: 'ha_mayor_incendio', title: 'Maior incendio (ha)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">As provincias sen cor non tiveron ningún incendio cartografado por EFFIS ese ano.</p>

---

## Un cuarto de século de incendios

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
    title="Superficie queimada por ano (ha)"
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
    title="Parte da superficie queimada dentro da Rede Natura 2000"
    lineColor="#b91c1c"
    markers=true
/>

## Que tipo de terreo arde

EFFIS cruza cada perímetro co mapa de cubertas do solo CORINE: así se sabe se o queimado era bosque, mato, pastos ou cultivos.

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
    title="Superficie queimada por tipo de cuberta"
    colorPalette={['#166534', '#a3a635', '#fcd34d', '#d97706', '#9ca3af']}
/>

---

## Os maiores incendios da última década

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
    <Column id=municipio title="Concello" />
    <Column id=provincia title="Provincia" />
    <Column id=area_ha title="Hectáreas" fmt=num0 contentType=bar barColor="#fdba74" />
    <Column id=ha_natura2000 title="Ha en Natura 2000" fmt=num0 />
    <Column id=natura2000 title="% Natura 2000" fmt=pct0 />
    <Column id=cubierta_principal title="Cuberta principal" />
</DataTable>

---

## Fontes oficiais

- **[EFFIS – European Forest Fire Information System](https://forest-fire.emergency.copernicus.eu/)** (Copernicus, Comisión Europea): perímetros de áreas queimadas cartografados con satélite desde 2000, coa súa superficie, cubertas do solo afectadas (CORINE Land Cover) e porcentaxe dentro da Rede Natura 2000. As cifras da tempada en curso son provisionais e EFFIS revísaas.
- **[NASA FIRMS – Fire Information for Resource Management System](https://firms.modaps.eosdis.nasa.gov/)**: focos de calor case en tempo real dos sensores VIIRS (Suomi NPP, NOAA-20 e NOAA-21) e MODIS.
- **[Rede Natura 2000](https://www.miteco.gob.es/es/biodiversidad/temas/espacios-protegidos/red-natura-2000.html)** (MITECO): rede europea de espazos protexidos (ZEC e ZEPA).

A estatística oficial de incendios forestais do MITECO inclúe tamén os conatos (menos de 1 ha) e publícase con máis atraso; por iso os seus totais poden diferir dos de EFFIS.

<LastRefreshed prefix="Datos actualizados" />
