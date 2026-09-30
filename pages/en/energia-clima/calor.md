---
title: Heat and temperatures
description: Daily map of heat in Spain by province, compared with the usual maximum temperature for each day in 1991-2020, and each province's records. AEMET data.
i18n_origen: 963e5a5d3d55
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const signo = (v) => (v > 0 ? '+' : '') + formatNumber(v, 1);
    const fechaLarga = (f) => f ? new Date(f).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }) : '-';
</script>

```sql espana
SELECT * FROM mother.calor_espana_diario ORDER BY fecha DESC LIMIT 1
```

```sql serie_espana
SELECT fecha, anomalia_tmax_media AS valor, n_provincias_por_encima
FROM mother.calor_espana_diario
WHERE fecha >= (SELECT max(fecha) - INTERVAL 60 DAY FROM mother.calor_espana_diario)
ORDER BY fecha
```

```sql mas_anomala
SELECT provincia, tmax, anomalia_tmax, tmax_media_historica
FROM mother.calor_ultimo_dia
WHERE anomalia_tmax IS NOT NULL
ORDER BY anomalia_tmax DESC
LIMIT 1
```

```sql lugar_mas_caluroso
SELECT m.fecha, m.estacion, m.provincia, m.tmax
FROM mother.calor_maxima_diaria AS m
WHERE m.fecha = (SELECT max(fecha) FROM mother.calor_ultimo_dia)
```

```sql serie_mayor_anomalia
SELECT fecha, max(anomalia_tmax) AS valor
FROM mother.calor_provincia_diario
WHERE fecha >= (SELECT max(fecha) - INTERVAL 60 DAY FROM mother.calor_provincia_diario)
GROUP BY fecha
ORDER BY fecha
```

```sql serie_maxima
SELECT fecha, max(tmax) AS valor
FROM mother.calor_maxima_diaria
WHERE fecha >= (SELECT max(fecha) - INTERVAL 60 DAY FROM mother.calor_maxima_diaria)
GROUP BY fecha
ORDER BY fecha
```

```sql records_ultimo_dia
SELECT count(*) AS n FROM mother.calor_ultimo_dia WHERE es_record_dia
```

# 🌡️ Heat and temperatures in Spain

On **{fechaLarga(espana[0]?.fecha)}** the maximum temperature at each province's reference weather station was, on average, **{signo(espana[0]?.anomalia_tmax_media)} °C** compared with what is usual for that day in 1991-2020. **{espana[0]?.n_provincias_por_encima} of {espana[0]?.n_provincias} provinces** were above normal and {espana[0]?.n_provincias_p90} exceeded the unusual heat threshold (the warmest 10 % of days for the time of year). In {records_ultimo_dia[0]?.n} provinces it was the highest maximum for that date since 1991.

<Grid cols=4>
    <KpiCard
        title="National anomaly"
        value={espana[0]?.anomalia_tmax_media}
        formattedValue={signo(espana[0]?.anomalia_tmax_media)}
        unit=" °C"
        period="Maximum compared with the 1991-2020 average"
        source="AEMET"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Provinces above normal"
        value={espana[0]?.n_provincias_por_encima}
        formattedValue="{espana[0]?.n_provincias_por_encima}"
        unit=" of {espana[0]?.n_provincias}"
        period="More than 1 °C above their average"
        sparklineData={serie_espana.map(d => ({valor: d.n_provincias_por_encima}))}
    />
    <KpiCard
        title="Largest anomaly"
        value={mas_anomala[0]?.anomalia_tmax}
        formattedValue={mas_anomala[0]?.provincia}
        period="{formatNumber(mas_anomala[0]?.tmax, 1)} °C, {signo(mas_anomala[0]?.anomalia_tmax)} °C above normal"
        sparklineData={serie_mayor_anomalia}
    />
    <KpiCard
        title="Hottest place"
        value={lugar_mas_caluroso[0]?.tmax}
        formattedValue={formatNumber(lugar_mas_caluroso[0]?.tmax, 1)}
        unit=" °C"
        period="{lugar_mas_caluroso[0]?.estacion ?? '-'} ({lugar_mas_caluroso[0]?.provincia ?? '-'})"
        sparklineData={serie_maxima}
    />
</Grid>

---

## The heat map, day by day

Each province is coloured according to how many degrees its maximum temperature departed from the **historical average for that same day** (1991-2020): red, hotter than usual; blue, cooler. Choose a date from the last three months.

```sql fechas
SELECT DISTINCT
    strftime(fecha, '%Y-%m-%d') AS fecha_txt,
    strftime(fecha, '%d/%m/%Y') AS fecha_label,
    fecha
FROM mother.calor_espana_diario
WHERE fecha >= (SELECT max(fecha) - INTERVAL 90 DAY FROM mother.calor_espana_diario)
ORDER BY fecha DESC
```

<Dropdown data={fechas} name=fecha value=fecha_txt label=fecha_label title="Date" />

```sql mapa
SELECT
    cod_prov,
    provincia,
    estacion,
    tmax,
    tmax_media_historica,
    anomalia_tmax,
    categoria,
    CASE WHEN es_record_dia THEN 'Sí' ELSE 'No' END AS record_dia
FROM mother.calor_provincia_diario
WHERE strftime(fecha, '%Y-%m-%d') = '${inputs.fecha.value}'
```

<AreaMap
    data={mapa}
    geoJsonUrl="/spain-provinces.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="anomalia_tmax"
    valueFmt="num1"
    colorPalette={['#1d4ed8', '#93c5fd', '#f8fafc', '#fca5a5', '#b91c1c']}
    min={-10}
    max={10}
    height={520}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tmax', title: 'Maximum (°C)', fmt: 'num1'},
        {id: 'tmax_media_historica', title: '1991-2020 average (°C)', fmt: 'num1'},
        {id: 'anomalia_tmax', title: 'Difference (°C)', fmt: 'num1'},
        {id: 'categoria', title: 'Status'},
        {id: 'record_dia', title: 'Record for the day'},
        {id: 'estacion', title: 'Station'}
    ]}
/>

<p class="text-xs text-gray-500">Scale from −10 °C (blue) to +10 °C (red). A province in grey has no data for that day at its reference station.</p>

<DataTable data={mapa} rows=all sort="anomalia_tmax desc">
    <Column id=provincia title="Province" />
    <Column id=tmax title="Maximum (°C)" fmt=num1 />
    <Column id=tmax_media_historica title="1991-2020 average" fmt=num1 />
    <Column id=anomalia_tmax title="Difference (°C)" fmt=num1 contentType=colorscale colorScale={['#1d4ed8', '#f8fafc', '#b91c1c']} colorMin={-10} colorMid={0} colorMax={10} />
    <Column id=categoria title="Status" />
    <Column id=record_dia title="Record for the day" />
</DataTable>

---

## This year compared with the usual

The red line is this year's daily maximum temperature in the selected province (series "Máxima de este año"); the grey one, the 1991-2020 average for each day ("Media 1991-2020"), and the dashed lines mark the usual range, between the coolest 10 % of days ("Umbral fresco (p10)") and the warmest 10 % ("Umbral cálido (p90)").

```sql opciones_provincia
SELECT DISTINCT cod_prov, provincia FROM mother.calor_ultimo_dia ORDER BY provincia
```

<Dropdown data={opciones_provincia} name=provincia value=cod_prov label=provincia title="Province" defaultValue="28" />

```sql anio_actual
SELECT
    max(anio) AS anio,
    (SELECT provincia FROM mother.calor_ultimo_dia WHERE cod_prov = '${inputs.provincia.value}') AS provincia
FROM mother.calor_provincia_diario
```

```sql serie_provincia
WITH anio AS (SELECT max(anio) AS anio FROM mother.calor_provincia_diario),
base AS (
    SELECT
        make_date(CAST((SELECT anio FROM anio) AS INTEGER), 1, 1) + CAST(n.dia_anio - 1 AS INTEGER) * INTERVAL 1 DAY AS fecha,
        n.tmax_media,
        n.tmax_p10,
        n.tmax_p90,
        d.tmax
    FROM mother.calor_normal_diaria AS n
    LEFT JOIN mother.calor_provincia_diario AS d
      ON d.cod_prov = n.cod_prov AND d.dia_anio = n.dia_anio AND d.anio = (SELECT anio FROM anio)
    WHERE n.cod_prov = '${inputs.provincia.value}'
)
SELECT fecha, 'Máxima de este año' AS serie, tmax AS valor FROM base WHERE tmax IS NOT NULL
UNION ALL SELECT fecha, 'Media 1991-2020', tmax_media FROM base
UNION ALL SELECT fecha, 'Umbral cálido (p90)', tmax_p90 FROM base
UNION ALL SELECT fecha, 'Umbral fresco (p10)', tmax_p10 FROM base
ORDER BY fecha
```

<LineChart
    data={serie_provincia}
    x=fecha
    y=valor
    series=serie
    yFmt=num0
    yAxisTitle="°C"
    title="Daily maximum temperature in {anio_actual[0]?.anio} — {anio_actual[0]?.provincia}"
    seriesColors={{
        'Máxima de este año': '#dc2626',
        'Media 1991-2020': '#475569',
        'Umbral cálido (p90)': '#fca5a5',
        'Umbral fresco (p10)': '#93c5fd'
    }}
/>

---

## Hotter every year?

Provincial average of the difference between the daily maximum and its normal. The latest year is incomplete.

```sql anual
SELECT
    anio::VARCHAR AS anio,
    anomalia_tmax,
    anomalia_tmax_verano,
    dias_p90,
    records_dia,
    anio_completo
FROM mother.calor_anual
ORDER BY anio
```

<BarChart
    data={anual}
    x=anio
    y=anomalia_tmax
    yFmt=num1
    yAxisTitle="°C"
    title="Annual maximum temperature anomaly (provincial average)"
    fillColor="#ea580c"
/>

<BarChart
    data={anual}
    x=anio
    y=dias_p90
    yFmt=num0
    title="Days of unusual heat per year (above the 90th percentile), average per province"
    fillColor="#b91c1c"
/>

```sql espana_365
SELECT fecha, anomalia_tmax_media
FROM mother.calor_espana_diario
WHERE fecha >= (SELECT max(fecha) - INTERVAL 365 DAY FROM mother.calor_espana_diario)
ORDER BY fecha
```

<AreaChart
    data={espana_365}
    x=fecha
    y=anomalia_tmax_media
    yFmt=num1
    yAxisTitle="°C"
    title="National daily anomaly over the last 12 months"
    fillColor="#fdba74"
    lineColor="#ea580c"
/>

---

## Records

Highest maximum temperature recorded in each province since 1991 at its reference station, and the highest so far this year.

```sql records_provincia
WITH record AS (
    SELECT cod_prov, provincia, estacion, tmax AS record, fecha AS fecha_record
    FROM mother.calor_records WHERE posicion = 1
),
este_anio AS (
    SELECT cod_prov, tmax AS max_anio, fecha AS fecha_max_anio,
           row_number() OVER (PARTITION BY cod_prov ORDER BY tmax DESC, fecha DESC) AS rn
    FROM mother.calor_provincia_diario
    WHERE anio = (SELECT max(anio) FROM mother.calor_provincia_diario) AND tmax IS NOT NULL
),
dias_record AS (
    SELECT cod_prov, count(*) FILTER (WHERE es_record_dia) AS records_dia_anio
    FROM mother.calor_provincia_diario
    WHERE anio = (SELECT max(anio) FROM mother.calor_provincia_diario)
    GROUP BY cod_prov
)
SELECT r.provincia, r.record, r.fecha_record, e.max_anio, e.fecha_max_anio,
       coalesce(d.records_dia_anio, 0) AS records_dia_anio, r.estacion
FROM record AS r
LEFT JOIN este_anio AS e ON e.cod_prov = r.cod_prov AND e.rn = 1
LEFT JOIN dias_record AS d ON d.cod_prov = r.cod_prov
ORDER BY r.record DESC
```

<DataTable data={records_provincia} rows=15 search=true>
    <Column id=provincia title="Province" />
    <Column id=record title="Record (°C)" fmt=num1 contentType=colorscale colorScale={['#fef3c7', '#b91c1c']} />
    <Column id=fecha_record title="Date of record" fmt="dd/mm/yyyy" />
    <Column id=max_anio title="Maximum this year (°C)" fmt=num1 />
    <Column id=fecha_max_anio title="Date" fmt="dd/mm/yyyy" />
    <Column id=records_dia_anio title="Daily records this year" />
    <Column id=estacion title="Station" />
</DataTable>

```sql top_dias
SELECT provincia, fecha, tmax, anomalia_tmax, estacion
FROM mother.calor_records
ORDER BY tmax DESC, fecha DESC
LIMIT 20
```

<DataTable data={top_dias} rows=20 title="The 20 hottest days at the reference stations (1991-present)">
    <Column id=provincia title="Province" />
    <Column id=fecha title="Date" fmt="dd/mm/yyyy" />
    <Column id=tmax title="Maximum (°C)" fmt=num1 />
    <Column id=anomalia_tmax title="Above normal (°C)" fmt=num1 />
    <Column id=estacion title="Station" />
</DataTable>

---

## Methodology and sources

- **One station per province.** For each province a single AEMET reference station is used, usually the one in the provincial capital or at its airport, chosen because it has a continuous series since 1991. Averaging all the stations in a province would mix peaks and valleys and would change as stations open and close; a single station is comparable over time. Where AEMET has changed the station identifier (Santander, Guadalajara, Vitoria…), the series is spliced with the previous one.
- **What "normal" means.** For each province and day of the year, the average maximum temperature for 1991-2020 is calculated (the current WMO climate reference period), using that day and the seven days before and after it across the 30 years (about 450 observations), which smooths the curve. The **unusual heat threshold** is the 90th percentile of that same window.
- **Records.** These are the maximums in the reference station's series since 1991, not necessarily the station's official all-time records. A "record for the day" is the highest maximum recorded on that calendar day since 1991 (only from 2001 onwards, with at least ten previous years for comparison).
- **Hottest place**: the station with the highest maximum of the day among all AEMET stations (about 800).
- **Delay.** AEMET publishes validated daily climate data a few days late and may revise the most recent days, which are downloaded again at every update. Provinces in grey have no data for that day.

**Source:** [AEMET OpenData](https://opendata.aemet.es/) — daily climatological values from the stations of the State Meteorological Agency (Agencia Estatal de Meteorología). Provincial boundaries: IGN.

<LastRefreshed prefix="Data updated" />
