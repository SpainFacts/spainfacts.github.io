---
title: Ur-erreserbak eta urtegiak
description: Espainiako urtegien asteko egoera arroka, aurreko urtearekin eta azken hamar urteetako batez bestekoarekin alderatuta.
i18n_origen: 868173fde4bb
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    import MapaEmbalses from '../../../../../../../src/lib/components/MapaEmbalses.svelte';
</script>

```sql espana
SELECT * FROM mother.embalses_estado_actual WHERE nivel = 'pais'
```

```sql serie_espana
SELECT fecha, pct_llenado AS valor
FROM mother.embalses_semanal
WHERE nivel = 'pais' AND fecha >= (SELECT max(fecha) - INTERVAL 2 YEAR FROM mother.embalses_semanal)
ORDER BY fecha
```

```sql serie_comparada
SELECT
    u.fecha,
    round(u.pct_llenado - max(s.pct_llenado) FILTER (WHERE s.anio = u.anio - 1), 1) AS dif_anio,
    round(u.pct_llenado - avg(s.pct_llenado) FILTER (WHERE s.anio BETWEEN u.anio - 10 AND u.anio - 1), 1) AS dif_media
FROM mother.embalses_semanal AS u
JOIN mother.embalses_semanal AS s
  ON s.nivel = 'pais' AND s.semana = u.semana AND s.anio < u.anio
WHERE u.nivel = 'pais'
  AND u.fecha >= (SELECT max(fecha) - INTERVAL 1 YEAR FROM mother.embalses_semanal)
GROUP BY u.fecha, u.anio, u.pct_llenado
ORDER BY u.fecha
```

# 💧 Ur-erreserbak Espainian

Espainiako urtegiek gaur **{formatNumber(espana[0]?.volumen_hm3, 0)} hm³** biltzen dituzte, beren ahalmen osoaren **{formatNumber(espana[0]?.pct_llenado, 1)} %** ({formatNumber(espana[0]?.capacidad_hm3, 0)} hm³). MITECOren Buletin Hidrologikoaren datuak (data: **{new Date(espana[0]?.fecha).toLocaleDateString('eu-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**); asteartero argitaratzen da.

<Grid cols=3>
    <KpiCard
        title="Ur-erreserba"
        value={espana[0]?.pct_llenado}
        formattedValue={formatNumber(espana[0]?.pct_llenado, 1)}
        unit="%"
        period="{formatNumber(espana[0]?.volumen_hm3, 0)} hm³"
        source="MITECO – Buletin Hidrologikoa"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Duela urtebeterekin alderatuta"
        value={espana[0]?.dif_vs_anio_anterior}
        formattedValue="{espana[0]?.dif_vs_anio_anterior > 0 ? '+' : ''}{formatNumber(espana[0]?.dif_vs_anio_anterior, 1)}"
        unit=" p.p."
        period="Duela urtebete: {formatNumber(espana[0]?.pct_hace_un_anio, 1)} %"
        direction="positive-up"
        sparklineData={serie_comparada.map(d => ({...d, valor: d.dif_anio}))}
    />
    <KpiCard
        title="10 urteko batez bestekoarekin alderatuta"
        value={espana[0]?.dif_vs_media_10_anios}
        formattedValue="{espana[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(espana[0]?.dif_vs_media_10_anios, 1)}"
        unit=" p.p."
        period="Aste bereko batez bestekoa: {formatNumber(espana[0]?.pct_media_10_anios, 1)} %"
        direction="positive-up"
        sparklineData={serie_comparada.map(d => ({...d, valor: d.dif_media}))}
    />
</Grid>

---

## Demarkazio bakoitzean urtegietan bildutako ura

```sql demarcaciones
SELECT
    cod,
    nombre,
    pct_llenado / 100 AS llenado,
    volumen_hm3,
    capacidad_hm3,
    dif_vs_media_10_anios
FROM mother.embalses_estado_actual
WHERE nivel = 'demarcacion'
```

<MapaEspana
    data={demarcaciones}
    geoJsonUrl="/demarcaciones-hidrograficas.geojson"
    geoId="cod_demarcacion"
    areaCol="cod"
    value="llenado"
    valueFmt="pct0"
    colorPalette={['#fde68a', '#7dd3fc', '#0369a1']}
    min={0.3}
    max={0.8}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'llenado', title: 'Betetze-maila', fmt: 'pct1'},
        {id: 'volumen_hm3', title: 'Urtegietako ura (hm³)', fmt: 'num0'},
        {id: 'dif_vs_media_10_anios', title: '10 urteko batez bestekoarekiko (p.p.)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Uharteak, Ceuta eta Melilla ez daude Buletin Hidrologikoan. «Euskal Autonomia Erkidegoko Barne Arroak» eremua Ekialdeko Kantauriko demarkazioari gehitzen zaio.</p>

## Urtegiz urtegi

Karratu bakoitza urtegi bat da: haren tamaina ahalmenaren proportzionala da, eta betegarria, orain duen urarena. Koloreak adierazten du urteko aste honetarako ohikoa baino gorago (berde urdinxka) edo beherago (marroia) dagoen, hau da, aurreko hamar urteetako aste bereko batez bestekoaren aldean.

```sql mapa_embalses
SELECT embalse, cuenca, lat, lon, capacidad_hm3, volumen_hm3, pct_llenado,
       pct_habitual, dif_vs_habitual, uso_electrico
FROM mother.embalses_actual
```

<MapaEmbalses data={mapa_embalses} />

<p class="text-xs text-gray-500">Urtegien kokapena: © OpenStreetMap-en laguntzaileak (ODbL) eta Wikidata, izenaren bidez Buletin Hidrologikoarekin lotuak. Probintzien mugak © Instituto Geográfico Nacional.</p>

## Ohikotik gora eta behera dauden arroak

**10 urteko batez bestekoarekiko** zutabeak egungo betetze-maila aurreko hamar urteetako aste berekoarekin alderatzen du: hori da arro bat urteko garai horretarako egoera normalean dagoen jakiteko modurik onena.

```sql cuencas
SELECT
    nombre AS cuenca,
    pct_llenado / 100 AS llenado,
    volumen_hm3,
    capacidad_hm3,
    pct_hace_un_anio / 100 AS hace_un_anio,
    dif_vs_anio_anterior,
    pct_media_10_anios / 100 AS media_10_anios,
    dif_vs_media_10_anios,
    -- Criterio editorial: ±5 pp respecto a la media de 10 años es "normal";
    -- además, por debajo del 40 % se avisa aunque la cuenca esté en su media.
    CASE
        WHEN dif_vs_media_10_anios <= -15 THEN 'Muy por debajo'
        WHEN dif_vs_media_10_anios < -5 THEN 'Por debajo'
        WHEN pct_llenado < 40 THEN 'Reservas bajas'
        WHEN dif_vs_media_10_anios > 5 THEN 'Por encima'
        ELSE 'Normal'
    END AS situacion,
    n_embalses
FROM mother.embalses_estado_actual
WHERE nivel = 'cuenca'
ORDER BY pct_llenado DESC
```

<DataTable data={cuencas} rows=all>
    <Column id=cuenca title="Arroa" />
    <Column id=llenado title="Betetze-maila" fmt=pct1 contentType=bar barColor="#7dd3fc" />
    <Column id=volumen_hm3 title="hm³" fmt=num0 />
    <Column id=hace_un_anio title="Duela urtebete" fmt=pct1 />
    <Column id=dif_vs_anio_anterior title="Aldea (p.p.)" fmt=num1 contentType=delta />
    <Column id=media_10_anios title="10 urteko batez bestekoa" fmt=pct1 />
    <Column id=dif_vs_media_10_anios title="Aldea (p.p.)" fmt=num1 contentType=delta />
    <Column id=situacion title="Egoera" />
    <Column id=n_embalses title="Urtegiak" />
</DataTable>

---

## Bilakaera urtean zehar

Lerro bakoitza urte natural bat da (azken seietakoa): horrela ikusten da egungo erreserba aurreko urteen aurretik edo atzetik doan garai berean.

```sql opciones_cuenca
SELECT DISTINCT nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.embalses_semanal
ORDER BY orden, nombre
```

<Dropdown data={opciones_cuenca} name=cuenca value=nombre title="Eremua" defaultValue="España" />

```sql evolucion
SELECT
    semana,
    anio::VARCHAR AS año,
    pct_llenado / 100 AS llenado
FROM mother.embalses_semanal
WHERE nombre = '${inputs.cuenca.value}'
  AND anio >= (SELECT max(anio) - 5 FROM mother.embalses_semanal)
ORDER BY anio, semana
```

<LineChart
    data={evolucion}
    x=semana
    y=llenado
    series=año
    yFmt=pct0
    xAxisTitle="Urteko astea"
    title="Asteko betetze-maila — {inputs.cuenca.value}"
    colorPalette={['#cbd5e1', '#94a3b8', '#64748b', '#475569', '#7dd3fc', '#0369a1']}
/>

```sql historico
SELECT fecha, pct_llenado / 100 AS llenado
FROM mother.embalses_semanal
WHERE nombre = '${inputs.cuenca.value}'
ORDER BY fecha
```

<AreaChart
    data={historico}
    x=fecha
    y=llenado
    yFmt=pct0
    title="Serie historikoa 2000tik — {inputs.cuenca.value}"
    fillColor="#7dd3fc"
    lineColor="#0369a1"
/>

---

## Urtegi guztiak

```sql embalses
SELECT
    embalse,
    cuenca,
    CASE WHEN uso_electrico THEN 'Hidroeléctrico' ELSE 'Consuntivo' END AS uso,
    capacidad_hm3,
    volumen_hm3,
    pct_llenado / 100 AS llenado,
    (pct_llenado - pct_hace_un_anio) AS dif_vs_anio_anterior
FROM mother.embalses_actual
ORDER BY capacidad_hm3 DESC
```

<DataTable data={embalses} search=true rows=15>
    <Column id=embalse title="Urtegia" />
    <Column id=cuenca title="Arroa" />
    <Column id=uso title="Erabilera" />
    <Column id=capacidad_hm3 title="Ahalmena (hm³)" fmt=num0 />
    <Column id=volumen_hm3 title="Egungoa (hm³)" fmt=num0 />
    <Column id=llenado title="Betetze-maila" fmt=pct0 contentType=bar barColor="#7dd3fc" />
    <Column id=dif_vs_anio_anterior title="Duela urtebeterekiko (p.p.)" fmt=num1 contentType=delta />
</DataTable>

---

## Iturri ofizialak

- **[MITECO – Asteko Buletin Hidrologikoa](https://www.miteco.gob.es/es/agua/temas/evaluacion-de-los-recursos-hidricos/boletin-hidrologico.html)**: urtegien datu-base historikoa (1988-gaur), asteartero eguneratua.
- **[Ingurumenaren Europako Agentzia – WISE WFD](https://water.discomap.eea.europa.eu/)**: demarkazio hidrografikoen mugak (PHC 2022-2027).

Urtegi «hidroelektrikoak» MITECOk erabilera elektrikokotzat markatzen dituenak dira; gainerakoek kontsumoa, ureztatzea edo industria hornitzen dituzte.

<LastRefreshed prefix="Datuak eguneratuta" />
