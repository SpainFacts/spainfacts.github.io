---
title: Beroa eta tenperaturak
description: Espainiako beroaren eguneko mapa probintziaka, egun bakoitzeko ohiko tenperatura maximoarekin (1991-2020) alderatuta, eta probintzia bakoitzeko errekorrak. AEMETen datuak.
i18n_origen: b2c2b4a53fb2
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const signo = (v) => (v > 0 ? '+' : '') + formatNumber(v, 1);
    const fechaLarga = (f) => f ? new Date(f).toLocaleDateString('eu-ES', { day: 'numeric', month: 'long', year: 'numeric' }) : '-';
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

# 🌡️ Beroa eta tenperaturak Espainian

Azken datuaren egunean (**{fechaLarga(espana[0]?.fecha)}**), probintzia bakoitzeko erreferentzia-estazioetako tenperatura maximoa, batez beste, **{signo(espana[0]?.anomalia_tmax_media)} °C**-koa izan zen 1991-2020 aldian egun horretarako ohikoa zenaren aldean. **{espana[0]?.n_provincias}tik {espana[0]?.n_provincias_por_encima} probintzia** egon ziren normaltasunetik gora, eta {espana[0]?.n_provincias_p90} probintziak gainditu zuten ezohiko beroaren atalasea (garai horretako egunik beroenen 10 %). {records_ultimo_dia[0]?.n} probintziatan, 1991tik data horretarako maximorik altuena izan zen.

<Grid cols=4>
    <KpiCard
        title="Anomalia nazionala"
        value={espana[0]?.anomalia_tmax_media}
        formattedValue={signo(espana[0]?.anomalia_tmax_media)}
        unit=" °C"
        period="Maximoa 1991-2020ko batez bestekoaren aldean"
        source="AEMET"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Normaltasunetik gorako probintziak"
        value={espana[0]?.n_provincias_por_encima}
        formattedValue="{espana[0]?.n_provincias_por_encima}"
        unit=" / {espana[0]?.n_provincias}"
        period="Beren batez bestekoa baino 1 °C baino gehiago"
        sparklineData={serie_espana.map(d => ({...d, valor: d.n_provincias_por_encima}))}
    />
    <KpiCard
        title="Anomaliarik handiena"
        value={mas_anomala[0]?.anomalia_tmax}
        formattedValue={mas_anomala[0]?.provincia}
        period="{formatNumber(mas_anomala[0]?.tmax, 1)} °C, {signo(mas_anomala[0]?.anomalia_tmax)} °C normaltasunaren gainetik"
        sparklineData={serie_mayor_anomalia}
    />
    <KpiCard
        title="Lekurik beroena"
        value={lugar_mas_caluroso[0]?.tmax}
        formattedValue={formatNumber(lugar_mas_caluroso[0]?.tmax, 1)}
        unit=" °C"
        period="{lugar_mas_caluroso[0]?.estacion ?? '-'} ({lugar_mas_caluroso[0]?.provincia ?? '-'})"
        sparklineData={serie_maxima}
    />
</Grid>

---

## Beroaren mapa, egunez egun

Probintzia bakoitza koloreztatzen da bere tenperatura maximoa **egun horretako batez besteko historikotik** (1991-2020) zenbat gradu aldendu zen kontuan hartuta: gorria, ohikoa baino bero gehiago; urdina, freskoagoa. Aukeratu azken hiru hilabeteetako data bat.

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
        {id: 'tmax', title: 'Maximoa (°C)', fmt: 'num1'},
        {id: 'tmax_media_historica', title: '1991-2020ko batez bestekoa (°C)', fmt: 'num1'},
        {id: 'anomalia_tmax', title: 'Aldea (°C)', fmt: 'num1'},
        {id: 'categoria', title: 'Egoera'},
        {id: 'record_dia', title: 'Eguneko errekorra'},
        {id: 'estacion', title: 'Estazioa'}
    ]}
/>

<p class="text-xs text-gray-500">Eskala −10 °C-tik (urdina) +10 °C-ra (gorria). Grisez dagoen probintzia batek ez du daturik egun horretan bere erreferentzia-estazioan.</p>

<DataTable data={mapa} rows=all sort="anomalia_tmax desc">
    <Column id=provincia title="Probintzia" />
    <Column id=tmax title="Maximoa (°C)" fmt=num1 />
    <Column id=tmax_media_historica title="1991-2020ko batez bestekoa" fmt=num1 />
    <Column id=anomalia_tmax title="Aldea (°C)" fmt=num1 contentType=colorscale colorScale={['#1d4ed8', '#f8fafc', '#b91c1c']} colorMin={-10} colorMid={0} colorMax={10} />
    <Column id=categoria title="Egoera" />
    <Column id=record_dia title="Eguneko errekorra" />
</DataTable>

---

## Aurtengoa ohikoaren aldean

Lerro gorria aukeratutako probintzian aurten izandako eguneko tenperatura maximoa da; grisa, egun bakoitzerako 1991-2020ko batez bestekoa, eta lerro etenek ohiko tartea markatzen dute (egunik freskoenen 10 %-aren eta beroenen 10 %-aren artean).

```sql opciones_provincia
SELECT DISTINCT cod_prov, provincia FROM mother.calor_ultimo_dia ORDER BY provincia
```

<Dropdown data={opciones_provincia} name=provincia value=cod_prov label=provincia title="Probintzia" defaultValue="28" />

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
    title="Eguneko tenperatura maximoa, {anio_actual[0]?.anio}. urtean — {anio_actual[0]?.provincia}"
    seriesColors={{
        'Máxima de este año': '#dc2626',
        'Media 1991-2020': '#475569',
        'Umbral cálido (p90)': '#fca5a5',
        'Umbral fresco (p10)': '#93c5fd'
    }}
/>

---

## Urtero bero gehiago?

Eguneko maximoaren eta haren balio normalaren arteko aldearen probintzien batez bestekoa. Azken urtea osatu gabe dago.

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
    title="Tenperatura maximoaren urteko anomalia (probintzien batez bestekoa)"
    fillColor="#ea580c"
/>

<BarChart
    data={anual}
    x=anio
    y=dias_p90
    yFmt=num0
    title="Ezohiko beroko egunak urtean (90. pertzentiletik gora), probintziako batez bestekoa"
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
    title="Eguneko anomalia nazionala azken 12 hilabeteetan"
    fillColor="#fdba74"
    lineColor="#ea580c"
/>

---

## Errekorrak

Probintzia bakoitzean 1991tik bere erreferentzia-estazioan erregistratutako tenperatura maximorik altuena, eta aurtengo altuena.

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
    <Column id=provincia title="Probintzia" />
    <Column id=record title="Errekorra (°C)" fmt=num1 contentType=colorscale colorScale={['#fef3c7', '#b91c1c']} />
    <Column id=fecha_record title="Errekorraren data" fmt="dd/mm/yyyy" />
    <Column id=max_anio title="Aurtengo maximoa (°C)" fmt=num1 />
    <Column id=fecha_max_anio title="Data" fmt="dd/mm/yyyy" />
    <Column id=records_dia_anio title="Eguneko errekorrak aurten" />
    <Column id=estacion title="Estazioa" />
</DataTable>

```sql top_dias
SELECT provincia, fecha, tmax, anomalia_tmax, estacion
FROM mother.calor_records
ORDER BY tmax DESC, fecha DESC
LIMIT 20
```

<DataTable data={top_dias} rows=20 title="Erreferentzia-estazioetako 20 egunik beroenak (1991-gaur)">
    <Column id=provincia title="Probintzia" />
    <Column id=fecha title="Data" fmt="dd/mm/yyyy" />
    <Column id=tmax title="Maximoa (°C)" fmt=num1 />
    <Column id=anomalia_tmax title="Normaltasunaren gainetik (°C)" fmt=num1 />
    <Column id=estacion title="Estazioa" />
</DataTable>

---

## Metodologia eta iturriak

- **Estazio bat probintziako.** Probintzia bakoitzerako AEMETen erreferentzia-estazio bat erabiltzen da, normalean hiriburukoa edo haren aireportukoa, 1991tik serie jarraitua duelako aukeratua. Probintzia bateko estazio guztien batez bestekoa eginez gero, gailurrak eta haranak nahasiko lirateke, eta estazioen altak eta bajak aldatuko lukete; estazio bakar bat denboran zehar konparagarria da. AEMETek estazioaren adierazgarria aldatu duenean (Santander, Guadalajara, Gasteiz…), seriea aurrekoarekin lotzen da.
- **Zer den «normala».** Probintzia eta urteko egun bakoitzerako, 1991-2020ko tenperatura maximoaren batez bestekoa kalkulatzen da (MMEren indarreko erreferentziazko aldi klimatikoa), 30 urteetako egun hori eta aurreko eta ondorengo zazpiak erabiliz (450 behaketa inguru), eta horrek kurba leuntzen du. **Ezohiko beroaren atalasea** leiho horren beraren 90. pertzentila da.
- **Errekorrak.** Erreferentzia-estazioaren seriearen maximoak dira 1991tik, ez nahitaez estazioaren errekor historiko ofizialak. «Eguneko errekorra» egutegiko egun horretan 1991tik erregistratutako maximorik altuena da (2001etik aurrera soilik, gutxienez aurreko hamar urterekin alderatzeko).
- **Lekurik beroena**: AEMETen estazio guztien artean (800 inguru) eguneko maximorik altuena duen estazioa.
- **Atzerapena.** AEMETek baliozkotutako eguneko datu klimatologikoak egun batzuetako atzerapenarekin argitaratzen ditu, eta azken egunak berrikus ditzake; eguneratze bakoitzean berriro deskargatzen dira. Grisez dauden probintziek ez dute daturik egun horretan.

**Iturria:** [AEMET OpenData](https://opendata.aemet.es/) — Estatuko Meteorologia Agentziaren estazioetako eguneko balio klimatologikoak. Probintzien mugak: IGN.

<LastRefreshed prefix="Datuak eguneratuta" />
