---
title: Calor i temperatures
description: Mapa diari de la calor a Espanya per província, comparat amb la temperatura màxima habitual de cada dia el 1991-2020, i els rècords de cada província. Dades d'AEMET.
i18n_origen: 2e6c1757c41f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const signo = (v) => (v > 0 ? '+' : '') + formatNumber(v, 1);
    const fechaLarga = (f) => f ? new Date(f).toLocaleDateString('ca-ES', { day: 'numeric', month: 'long', year: 'numeric' }) : '-';
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

# 🌡️ Calor i temperatures a Espanya

El **{fechaLarga(espana[0]?.fecha)}** la temperatura màxima a les estacions de referència de cada província va ser, de mitjana, **{signo(espana[0]?.anomalia_tmax_media)} °C** respecte al que és habitual per a aquell dia el 1991-2020. **{espana[0]?.n_provincias_por_encima} de {espana[0]?.n_provincias} províncies** van estar per sobre del normal i {espana[0]?.n_provincias_p90} van superar el llindar de calor inusual (el 10 % de dies més càlids de l'època). En {records_ultimo_dia[0]?.n} províncies va ser la màxima més alta per a aquella data des del 1991.

<Grid cols=4>
    <KpiCard
        title="Anomalia nacional"
        value={espana[0]?.anomalia_tmax_media}
        formattedValue={signo(espana[0]?.anomalia_tmax_media)}
        unit=" °C"
        period="Màxima respecte a la mitjana 1991-2020"
        source="AEMET"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Províncies per sobre del normal"
        value={espana[0]?.n_provincias_por_encima}
        formattedValue="{espana[0]?.n_provincias_por_encima}"
        unit=" de {espana[0]?.n_provincias}"
        period="Més d'1 °C sobre la seva mitjana"
        sparklineData={serie_espana.map(d => ({valor: d.n_provincias_por_encima}))}
    />
    <KpiCard
        title="Anomalia més gran"
        value={mas_anomala[0]?.anomalia_tmax}
        formattedValue={mas_anomala[0]?.provincia}
        period="{formatNumber(mas_anomala[0]?.tmax, 1)} °C, {signo(mas_anomala[0]?.anomalia_tmax)} °C sobre el normal"
        sparklineData={serie_mayor_anomalia}
    />
    <KpiCard
        title="Lloc més calorós"
        value={lugar_mas_caluroso[0]?.tmax}
        formattedValue={formatNumber(lugar_mas_caluroso[0]?.tmax, 1)}
        unit=" °C"
        period="{lugar_mas_caluroso[0]?.estacion ?? '-'} ({lugar_mas_caluroso[0]?.provincia ?? '-'})"
        sparklineData={serie_maxima}
    />
</Grid>

---

## El mapa de la calor, dia a dia

Cada província es pinta segons quants graus es va separar la seva temperatura màxima de la **mitjana històrica d'aquell mateix dia** (1991-2020): vermell, més calor del que és habitual; blau, més fresc. Tria una data dels últims tres mesos.

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

<MapaEspana
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
        {id: 'tmax', title: 'Màxima (°C)', fmt: 'num1'},
        {id: 'tmax_media_historica', title: 'Mitjana 1991-2020 (°C)', fmt: 'num1'},
        {id: 'anomalia_tmax', title: 'Diferència (°C)', fmt: 'num1'},
        {id: 'categoria', title: 'Situació'},
        {id: 'record_dia', title: 'Rècord del dia'},
        {id: 'estacion', title: 'Estació'}
    ]}
/>

<p class="text-xs text-gray-500">Escala de −10 °C (blau) a +10 °C (vermell). Una província en gris no té dada aquell dia a la seva estació de referència.</p>

<DataTable data={mapa} rows=all sort="anomalia_tmax desc">
    <Column id=provincia title="Província" />
    <Column id=tmax title="Màxima (°C)" fmt=num1 />
    <Column id=tmax_media_historica title="Mitjana 1991-2020" fmt=num1 />
    <Column id=anomalia_tmax title="Diferència (°C)" fmt=num1 contentType=colorscale colorScale={['#1d4ed8', '#f8fafc', '#b91c1c']} colorMin={-10} colorMid={0} colorMax={10} />
    <Column id=categoria title="Situació" />
    <Column id=record_dia title="Rècord del dia" />
</DataTable>

---

## Aquest any respecte al que és habitual

La línia vermella és la temperatura màxima diària d'aquest any a la província triada; la grisa, la mitjana del 1991-2020 per a cada dia, i les discontínues marquen la franja habitual (entre el 10 % de dies més frescos i el 10 % més càlids).

```sql opciones_provincia
SELECT DISTINCT cod_prov, provincia FROM mother.calor_ultimo_dia ORDER BY provincia
```

<Dropdown data={opciones_provincia} name=provincia value=cod_prov label=provincia title="Província" defaultValue="28" />

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
    title="Temperatura màxima diària el {anio_actual[0]?.anio} — {anio_actual[0]?.provincia}"
    seriesColors={{
        'Máxima de este año': '#dc2626',
        'Media 1991-2020': '#475569',
        'Umbral cálido (p90)': '#fca5a5',
        'Umbral fresco (p10)': '#93c5fd'
    }}
/>

---

## Cada any més calor?

Mitjana de les províncies de la diferència entre la màxima diària i la seva normal. L'últim any està incomplet.

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
    title="Anomalia anual de la temperatura màxima (mitjana de províncies)"
    fillColor="#ea580c"
/>

<BarChart
    data={anual}
    x=anio
    y=dias_p90
    yFmt=num0
    title="Dies de calor inusual a l'any (per sobre del percentil 90), mitjana per província"
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
    title="Anomalia diària nacional en els últims 12 mesos"
    fillColor="#fdba74"
    lineColor="#ea580c"
/>

---

## Rècords

Temperatura màxima més alta registrada a cada província des del 1991 a la seva estació de referència, i la més alta d'aquest any.

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
    <Column id=provincia title="Província" />
    <Column id=record title="Rècord (°C)" fmt=num1 contentType=colorscale colorScale={['#fef3c7', '#b91c1c']} />
    <Column id=fecha_record title="Data del rècord" fmt="dd/mm/yyyy" />
    <Column id=max_anio title="Màxima aquest any (°C)" fmt=num1 />
    <Column id=fecha_max_anio title="Data" fmt="dd/mm/yyyy" />
    <Column id=records_dia_anio title="Rècords del dia aquest any" />
    <Column id=estacion title="Estació" />
</DataTable>

```sql top_dias
SELECT provincia, fecha, tmax, anomalia_tmax, estacion
FROM mother.calor_records
ORDER BY tmax DESC, fecha DESC
LIMIT 20
```

<DataTable data={top_dias} rows=20 title="Els 20 dies més calorosos a les estacions de referència (1991-avui)">
    <Column id=provincia title="Província" />
    <Column id=fecha title="Data" fmt="dd/mm/yyyy" />
    <Column id=tmax title="Màxima (°C)" fmt=num1 />
    <Column id=anomalia_tmax title="Sobre el normal (°C)" fmt=num1 />
    <Column id=estacion title="Estació" />
</DataTable>

---

## Metodologia i fonts

- **Una estació per província.** Per a cada província es fa servir una estació de referència d'AEMET, normalment la de la capital o el seu aeroport, triada perquè té una sèrie contínua des del 1991. Fer la mitjana de totes les estacions d'una província barrejaria cims i valls i canviaria amb les altes i baixes d'estacions; una sola estació és comparable al llarg del temps. Quan AEMET ha canviat l'indicatiu de l'estació (Santander, Guadalajara, Vitòria…), la sèrie s'empalma amb l'anterior.
- **Què és «el normal».** Per a cada província i dia de l'any es calcula la mitjana de la temperatura màxima del 1991-2020 (el període de referència climàtica vigent de l'OMM), fent servir aquell dia i els set anteriors i posteriors dels 30 anys (unes 450 observacions), cosa que suavitza la corba. El **llindar de calor inusual** és el percentil 90 d'aquesta mateixa finestra.
- **Rècords.** Són els màxims de la sèrie de l'estació de referència des del 1991, no necessàriament els rècords històrics oficials de l'estació. Un «rècord del dia» és la màxima més alta registrada en aquell dia del calendari des del 1991 (només a partir del 2001, amb almenys deu anys previs de comparació).
- **Lloc més calorós**: l'estació amb la màxima més alta del dia entre totes les d'AEMET (unes 800).
- **Retard.** AEMET publica les dades climatològiques diàries validades amb uns quants dies de retard i pot revisar els últims dies, que es tornen a descarregar a cada actualització. Les províncies en gris no tenen dada aquell dia.

**Font:** [AEMET OpenData](https://opendata.aemet.es/) — valors climatològics diaris de les estacions de l'Agència Estatal de Meteorologia. Límits provincials: IGN.

<LastRefreshed prefix="Dades actualitzades" />
