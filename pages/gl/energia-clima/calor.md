---
i18n_origen: 963e5a5d3d55
title: Calor e temperaturas
description: Mapa diario da calor en España por provincia, comparado coa temperatura máxima habitual de cada día en 1991-2020, e os récords de cada provincia. Datos de AEMET.
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const signo = (v) => (v > 0 ? '+' : '') + formatNumber(v, 1);
    const fechaLarga = (f) => f ? new Date(f).toLocaleDateString('gl-ES', { day: 'numeric', month: 'long', year: 'numeric' }) : '-';
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

# 🌡️ Calor e temperaturas en España

O **{fechaLarga(espana[0]?.fecha)}** a temperatura máxima nas estacións de referencia de cada provincia foi, de media, **{signo(espana[0]?.anomalia_tmax_media)} °C** respecto ao habitual para ese día en 1991-2020. **{espana[0]?.n_provincias_por_encima} de {espana[0]?.n_provincias} provincias** estiveron por riba do normal e {espana[0]?.n_provincias_p90} superaron o limiar de calor inusual (o 10 % de días máis cálidos da época). En {records_ultimo_dia[0]?.n} provincias foi a máxima máis alta para esa data desde 1991.

<Grid cols=4>
    <KpiCard
        title="Anomalía nacional"
        value={espana[0]?.anomalia_tmax_media}
        formattedValue={signo(espana[0]?.anomalia_tmax_media)}
        unit=" °C"
        period="Máxima fronte á media 1991-2020"
        source="AEMET"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Provincias por riba do normal"
        value={espana[0]?.n_provincias_por_encima}
        formattedValue="{espana[0]?.n_provincias_por_encima}"
        unit=" de {espana[0]?.n_provincias}"
        period="Máis de 1 °C sobre a súa media"
        sparklineData={serie_espana.map(d => ({valor: d.n_provincias_por_encima}))}
    />
    <KpiCard
        title="Maior anomalía"
        value={mas_anomala[0]?.anomalia_tmax}
        formattedValue={mas_anomala[0]?.provincia}
        period="{formatNumber(mas_anomala[0]?.tmax, 1)} °C, {signo(mas_anomala[0]?.anomalia_tmax)} °C sobre o normal"
        sparklineData={serie_mayor_anomalia}
    />
    <KpiCard
        title="Lugar máis caloroso"
        value={lugar_mas_caluroso[0]?.tmax}
        formattedValue={formatNumber(lugar_mas_caluroso[0]?.tmax, 1)}
        unit=" °C"
        period="{lugar_mas_caluroso[0]?.estacion ?? '-'} ({lugar_mas_caluroso[0]?.provincia ?? '-'})"
        sparklineData={serie_maxima}
    />
</Grid>

---

## O mapa da calor, día a día

Cada provincia colórese segundo cantos graos se separou a súa temperatura máxima da **media histórica dese mesmo día** (1991-2020): vermello, máis calor do habitual; azul, máis fresco. Escolle unha data dos últimos tres meses.

```sql fechas
SELECT DISTINCT
    strftime(fecha, '%Y-%m-%d') AS fecha_txt,
    strftime(fecha, '%d/%m/%Y') AS fecha_label,
    fecha
FROM mother.calor_espana_diario
WHERE fecha >= (SELECT max(fecha) - INTERVAL 90 DAY FROM mother.calor_espana_diario)
ORDER BY fecha DESC
```

<Dropdown data={fechas} name=fecha value=fecha_txt label=fecha_label title="Data" />

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
    attribution="Teselas © Esri — Esri, HERE, Garmin, © colaboradores de OpenStreetMap"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tmax', title: 'Máxima (°C)', fmt: 'num1'},
        {id: 'tmax_media_historica', title: 'Media 1991-2020 (°C)', fmt: 'num1'},
        {id: 'anomalia_tmax', title: 'Diferenza (°C)', fmt: 'num1'},
        {id: 'categoria', title: 'Situación'},
        {id: 'record_dia', title: 'Récord do día'},
        {id: 'estacion', title: 'Estación'}
    ]}
/>

<p class="text-xs text-gray-500">Escala de −10 °C (azul) a +10 °C (vermello). Unha provincia en gris non ten dato ese día na súa estación de referencia.</p>

<DataTable data={mapa} rows=all sort="anomalia_tmax desc">
    <Column id=provincia title="Provincia" />
    <Column id=tmax title="Máxima (°C)" fmt=num1 />
    <Column id=tmax_media_historica title="Media 1991-2020" fmt=num1 />
    <Column id=anomalia_tmax title="Diferenza (°C)" fmt=num1 contentType=colorscale colorScale={['#1d4ed8', '#f8fafc', '#b91c1c']} colorMin={-10} colorMid={0} colorMax={10} />
    <Column id=categoria title="Situación" />
    <Column id=record_dia title="Récord do día" />
</DataTable>

---

## Este ano fronte ao habitual

A liña vermella é a temperatura máxima diaria deste ano na provincia escollida; a gris, a media de 1991-2020 para cada día, e as descontinuas marcan a franxa habitual (entre o 10 % de días máis frescos e o 10 % máis cálidos).

```sql opciones_provincia
SELECT DISTINCT cod_prov, provincia FROM mother.calor_ultimo_dia ORDER BY provincia
```

<Dropdown data={opciones_provincia} name=provincia value=cod_prov label=provincia title="Provincia" defaultValue="28" />

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
    title="Temperatura máxima diaria en {anio_actual[0]?.anio} — {anio_actual[0]?.provincia}"
    seriesColors={{
        'Máxima de este año': '#dc2626',
        'Media 1991-2020': '#475569',
        'Umbral cálido (p90)': '#fca5a5',
        'Umbral fresco (p10)': '#93c5fd'
    }}
/>

---

## Cada ano máis calor?

Media das provincias da diferenza entre a máxima diaria e o seu normal. O último ano está incompleto.

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
    title="Anomalía anual da temperatura máxima (media de provincias)"
    fillColor="#ea580c"
/>

<BarChart
    data={anual}
    x=anio
    y=dias_p90
    yFmt=num0
    title="Días de calor inusual ao ano (por riba do percentil 90), media por provincia"
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
    title="Anomalía diaria nacional nos últimos 12 meses"
    fillColor="#fdba74"
    lineColor="#ea580c"
/>

---

## Récords

Temperatura máxima máis alta rexistrada en cada provincia desde 1991 na súa estación de referencia, e a máis alta deste ano.

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
    <Column id=provincia title="Provincia" />
    <Column id=record title="Récord (°C)" fmt=num1 contentType=colorscale colorScale={['#fef3c7', '#b91c1c']} />
    <Column id=fecha_record title="Data do récord" fmt="dd/mm/yyyy" />
    <Column id=max_anio title="Máxima este ano (°C)" fmt=num1 />
    <Column id=fecha_max_anio title="Data" fmt="dd/mm/yyyy" />
    <Column id=records_dia_anio title="Récords do día este ano" />
    <Column id=estacion title="Estación" />
</DataTable>

```sql top_dias
SELECT provincia, fecha, tmax, anomalia_tmax, estacion
FROM mother.calor_records
ORDER BY tmax DESC, fecha DESC
LIMIT 20
```

<DataTable data={top_dias} rows=20 title="Os 20 días máis calorosos nas estacións de referencia (1991-hoxe)">
    <Column id=provincia title="Provincia" />
    <Column id=fecha title="Data" fmt="dd/mm/yyyy" />
    <Column id=tmax title="Máxima (°C)" fmt=num1 />
    <Column id=anomalia_tmax title="Sobre o normal (°C)" fmt=num1 />
    <Column id=estacion title="Estación" />
</DataTable>

---

## Metodoloxía e fontes

- **Unha estación por provincia.** Para cada provincia úsase unha estación de referencia de AEMET, normalmente a da capital ou o seu aeroporto, escollida por ter unha serie continua desde 1991. Promediar todas as estacións dunha provincia mesturaría cumios e vales e cambiaría coas altas e baixas de estacións; unha soa estación é comparable ao longo do tempo. Cando AEMET cambiou o indicativo da estación (Santander, Guadalajara, Vitoria…), a serie empálmase coa anterior.
- **Que é «o normal».** Para cada provincia e día do ano calcúlase a media da temperatura máxima de 1991-2020 (o período de referencia climática vixente da OMM), usando ese día e os sete anteriores e posteriores dos 30 anos (unhas 450 observacións), o que suaviza a curva. O **limiar de calor inusual** é o percentil 90 desa mesma xanela.
- **Récords.** Son os máximos da serie da estación de referencia desde 1991, non necesariamente os récords históricos oficiais da estación. Un «récord do día» é a máxima máis alta rexistrada nese día do calendario desde 1991 (só a partir de 2001, con polo menos dez anos previos de comparación).
- **Lugar máis caloroso**: a estación coa máxima máis alta do día entre todas as de AEMET (unhas 800).
- **Atraso.** AEMET publica os datos climatolóxicos diarios validados cuns días de atraso e pode revisar os últimos días, que se volven descargar en cada actualización. As provincias en gris non teñen dato ese día.

**Fonte:** [AEMET OpenData](https://opendata.aemet.es/) — valores climatolóxicos diarios das estacións da Agencia Estatal de Meteorología. Límites provinciais: IGN.

<LastRefreshed prefix="Datos actualizados" />
