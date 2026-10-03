---
title: Baso-suteak
description: Espainian urtero erretako azalera, Natura 2000 Sarearen barruko suteak, erretako eremuen mapa eta sateliteek detektatutako foku aktiboak.
i18n_origen: 31d2856b157a
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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

# 🔥 Baso-suteak Espainian

**{kpis[0]?.anio}**. urtean orain arte, Copernicusen sateliteek **{formatNumber(kpis[0]?.n_incendios, 0)} sute** kartografiatu dituzte, eta **{formatNumber(kpis[0]?.ha_quemadas, 0)} hektarea** erre dituzte, azken hamarkadako batez bestekotik {kpis[0]?.ha_misma_fecha > kpis[0]?.ha_media_10 ? 'gora' : 'behera'} urteko garai honetan ({formatNumber(kpis[0]?.ha_media_10, 0)} ha). Erretakoaren **{formatNumber(kpis[0]?.pct_natura2000, 1)} %** **Natura 2000 Sareko** gune babestuen barruan dago. Erregistratutako azken sutea: **{new Date(kpis[0]?.ultima_fecha).toLocaleDateString('eu-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**.

<Grid cols=3>
    <KpiCard
        title="Erretako azalera, {kpis[0]?.anio}. urtean"
        value={kpis[0]?.ha_quemadas}
        formattedValue={formatNumber(kpis[0]?.ha_quemadas, 0)}
        unit=" ha"
        change={kpis[0]?.ha_media_10 ? Math.round(100 * (kpis[0]?.ha_misma_fecha / kpis[0]?.ha_media_10 - 1)) : null}
        changeUnit="%"
        changePeriod="10 urteko batez bestekoarekin alderatuta, data berean"
        direction="positive-down"
        source="EFFIS – Copernicus"
        sparklineData={serie_ha}
    />
    <KpiCard
        title="Kartografiatutako suteak"
        value={kpis[0]?.n_incendios}
        formattedValue={formatNumber(kpis[0]?.n_incendios, 0)}
        period="{formatNumber(kpis[0]?.n_grandes_incendios, 0)} 500 ha baino handiagoak · 10 urteko batez bestekoa: {formatNumber(kpis[0]?.n_media_10, 0)}"
        direction="positive-down"
        sparklineData={serie_n}
    />
    <KpiCard
        title="Natura 2000 Sarean erretakoa"
        value={kpis[0]?.pct_natura2000}
        formattedValue={formatNumber(kpis[0]?.pct_natura2000, 1)}
        unit="%"
        period="{formatNumber(kpis[0]?.ha_natura2000, 0)} ha · 10 urteko batez bestekoa: {formatNumber(kpis[0]?.pct_natura2000_10, 1)} %"
        direction="positive-down"
        sparklineData={serie_natura}
    />
</Grid>

<p class="text-xs text-gray-500">EFFISek satelite-irudiekin kartografiatzen ditu tamaina jakin bateko suteak (oro har, 30 ha ingurutik gorakoak); beraz, sute kopurua MITECOren estatistika ofizialekoa baino askoz txikiagoa da, hark sute-hasiera guztiak zenbatzen baititu. Azalerak, aldiz, erretakoaren gehiengo handia jasotzen du.</p>

---

## Non erre den aurten

Zirkulu bakoitza {kpis[0]?.anio}. urteko sute bat da, bere perimetroaren erdigunean kokatua eta erretako azaleraren proportzioko tamainarekin. Koloreak adierazten du erretako eremuaren zer zati dagoen Natura 2000 Sarearen barruan.

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
        {id: 'fecha_txt', title: 'Hasiera'},
        {id: 'area_ha', title: 'Hektareak', fmt: 'num0'},
        {id: 'natura2000', title: 'Natura 2000 barruan', fmt: 'pct0'},
        {id: 'cubierta_principal', title: 'Estaldura nagusia'}
    ]}
/>

## Azken 7 egunetako foku aktiboak

NASAren VIIRS eta MODIS sateliteek (FIRMS sistema) Espainiako lurraldean detektatutako puntu beroak. Sute handi batek hamarnaka foku sortzen ditu; koloreak suaren **erradiazio-potentzia** islatzen du (FRP, megawattetan).

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

<p class="text-sm text-gray-600 dark:text-gray-400">Konfiantza ertaineko edo altuko {formatNumber(focos_resumen[0]?.n_focos, 0)} foku, tartea: {new Date(focos_resumen[0]?.desde).toLocaleDateString('eu-ES', { day: 'numeric', month: 'long' })} – {new Date(focos_resumen[0]?.hasta).toLocaleDateString('eu-ES', { day: 'numeric', month: 'long', year: 'numeric' })}.</p>

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
        {id: 'detectado', title: 'Detektatua'},
        {id: 'frp_mw', title: 'Potentzia (MW)', fmt: 'num1'},
        {id: 'confianza', title: 'Konfiantza'},
        {id: 'instrumento', title: 'Sentsorea'}
    ]}
/>

<p class="text-xs text-gray-500">Fokua normala baino beroagoa den satelite-pixel bat da (375 m VIIRSen, 1 km MODISen): baso-suteez gain, nekazaritza-erreketak eta iturri industrial finkoak ere barne hartzen ditu, hala nola altzairutegiak, findegiak edo gas-zuziak. Konfiantza baxuko fokuak baztertzen dira.</p>

---

## Erretako azalera probintziaz probintzia

```sql anios
SELECT DISTINCT anio FROM mother.incendios_provincia_anio ORDER BY anio DESC
```

<Dropdown data={anios} name=anio_prov value=anio title="Urtea" />

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
        {id: 'ha_quemadas', title: 'Hektarea erreak', fmt: 'num0'},
        {id: 'n_incendios', title: 'Suteak', fmt: 'num0'},
        {id: 'ha_natura2000', title: 'Ha Natura 2000n', fmt: 'num0'},
        {id: 'ha_mayor_incendio', title: 'Sute handiena (ha)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Kolorerik gabeko probintziek ez zuten EFFISek kartografiatutako suterik izan urte horretan.</p>

---

## Mende-laurden bat suteak

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
    yAxisTitle="Hektareak"
    title="Erretako azalera urteka (ha)"
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
    title="Natura 2000 Sarearen barruan erretako azaleraren zatia"
    lineColor="#b91c1c"
    markers=true
/>

## Zer lur mota erretzen den

EFFISek perimetro bakoitza CORINE lurzoru-estalduren maparekin gurutzatzen du: horrela jakiten da erretakoa basoa, sastrakadia, larreak edo laboreak ziren.

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
    title="Erretako azalera estaldura motaren arabera"
    colorPalette={['#166534', '#a3a635', '#fcd34d', '#d97706', '#9ca3af']}
/>

---

## Azken hamarkadako sute handienak

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
    <Column id=fecha title="Hasiera" fmt="dd/mm/yyyy" />
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=area_ha title="Hektareak" fmt=num0 contentType=bar barColor="#fdba74" />
    <Column id=ha_natura2000 title="Ha Natura 2000n" fmt=num0 />
    <Column id=natura2000 title="Natura 2000 %" fmt=pct0 />
    <Column id=cubierta_principal title="Estaldura nagusia" />
</DataTable>

---

## Iturri ofizialak

- **[EFFIS – European Forest Fire Information System](https://forest-fire.emergency.copernicus.eu/)** (Copernicus, Europako Batzordea): 2000tik satelitez kartografiatutako erretako eremuen perimetroak, beren azalerarekin, kaltetutako lurzoru-estaldurekin (CORINE Land Cover) eta Natura 2000 Sarearen barruko ehunekoarekin. Uneko denboraldiko zifrak behin-behinekoak dira, eta EFFISek berrikusi egiten ditu.
- **[NASA FIRMS – Fire Information for Resource Management System](https://firms.modaps.eosdis.nasa.gov/)**: ia denbora errealeko bero-fokuak, VIIRS (Suomi NPP, NOAA-20 eta NOAA-21) eta MODIS sentsoreenak.
- **[Natura 2000 Sarea](https://www.miteco.gob.es/es/biodiversidad/temas/espacios-protegidos/red-natura-2000.html)** (MITECO): gune babestuen Europako sarea (KBE eta HBBE).

MITECOren baso-suteen estatistika ofizialak sute-hasierak ere barne hartzen ditu (1 ha baino gutxiago), eta atzerapen handiagoarekin argitaratzen da; horregatik, haren guztizkoak EFFISenetatik desberdinak izan daitezke.

<LastRefreshed prefix="Datuak eguneratuta" />
