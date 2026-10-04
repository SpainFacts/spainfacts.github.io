---
title: Reserves d'aigua i embassaments
description: Estat setmanal dels embassaments espanyols per conca, comparat amb l'any anterior i amb la mitjana dels últims deu anys.
i18n_origen: 428062b2d659
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

# 💧 Reserves d'aigua a Espanya

Els embassaments espanyols emmagatzemen avui **{formatNumber(espana[0]?.volumen_hm3, 0)} hm³**, el **{formatNumber(espana[0]?.pct_llenado, 1)} %** de la seva capacitat total ({formatNumber(espana[0]?.capacidad_hm3, 0)} hm³). Dades del Butlletí Hidrològic del MITECO a **{new Date(espana[0]?.fecha).toLocaleDateString('ca-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**, que es publica cada dimarts.

<Grid cols=3>
    <KpiCard
        title="Reserva hídrica"
        value={espana[0]?.pct_llenado}
        formattedValue={formatNumber(espana[0]?.pct_llenado, 1)}
        unit="%"
        period="{formatNumber(espana[0]?.volumen_hm3, 0)} hm³"
        source="MITECO – Butlletí Hidrològic"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Respecte a fa un any"
        value={espana[0]?.dif_vs_anio_anterior}
        formattedValue="{espana[0]?.dif_vs_anio_anterior > 0 ? '+' : ''}{formatNumber(espana[0]?.dif_vs_anio_anterior, 1)}"
        unit=" pp"
        period="Fa un any: {formatNumber(espana[0]?.pct_hace_un_anio, 1)} %"
        direction="positive-up"
        sparklineData={serie_comparada.map(d => ({valor: d.dif_anio}))}
    />
    <KpiCard
        title="Respecte a la mitjana de 10 anys"
        value={espana[0]?.dif_vs_media_10_anios}
        formattedValue="{espana[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(espana[0]?.dif_vs_media_10_anios, 1)}"
        unit=" pp"
        period="Mitjana de la mateixa setmana: {formatNumber(espana[0]?.pct_media_10_anios, 1)} %"
        direction="positive-up"
        sparklineData={serie_comparada.map(d => ({valor: d.dif_media}))}
    />
</Grid>

---

## L'aigua embassada a cada demarcació

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
        {id: 'llenado', title: 'Ompliment', fmt: 'pct1'},
        {id: 'volumen_hm3', title: 'Aigua embassada (hm³)', fmt: 'num0'},
        {id: 'dif_vs_media_10_anios', title: 'Vs. mitjana de 10 anys (pp)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Les illes, Ceuta i Melilla no formen part del Butlletí Hidrològic. L'àmbit «Conques Internes del País Basc» se suma a la demarcació del Cantàbric Oriental.</p>

## Embassament per embassament

Cada quadrat és un embassament: la seva mida és proporcional a la capacitat i l'emplenament, a l'aigua que té ara. El color indica si està per sobre (verd blavós) o per sota (marró) del que és habitual per a aquesta setmana de l'any, és a dir, la mitjana de la mateixa setmana en els deu anys anteriors.

```sql mapa_embalses
SELECT embalse, cuenca, lat, lon, capacidad_hm3, volumen_hm3, pct_llenado,
       pct_habitual, dif_vs_habitual, uso_electrico
FROM mother.embalses_actual
```

<MapaEmbalses data={mapa_embalses} />

<p class="text-xs text-gray-500">Ubicació dels embassaments: © col·laboradors d'OpenStreetMap (ODbL) i Wikidata, aparellats per nom amb el Butlletí Hidrològic. Límits provincials © Instituto Geográfico Nacional.</p>

## Conques per sobre i per sota del que és habitual

La columna **vs. mitjana de 10 anys** compara l'ompliment actual amb el de la mateixa setmana en els deu anys anteriors: és la millor manera de saber si una conca està en una situació normal per a l'època de l'any.

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
    <Column id=cuenca title="Conca" />
    <Column id=llenado title="Ompliment" fmt=pct1 contentType=bar barColor="#7dd3fc" />
    <Column id=volumen_hm3 title="hm³" fmt=num0 />
    <Column id=hace_un_anio title="Fa un any" fmt=pct1 />
    <Column id=dif_vs_anio_anterior title="Dif. (pp)" fmt=num1 contentType=delta />
    <Column id=media_10_anios title="Mitjana de 10 anys" fmt=pct1 />
    <Column id=dif_vs_media_10_anios title="Dif. (pp)" fmt=num1 contentType=delta />
    <Column id=situacion title="Situació" />
    <Column id=n_embalses title="Embassaments" />
</DataTable>

---

## Evolució al llarg de l'any

Cada línia és un any natural (dels sis últims): així es veu si la reserva actual va per davant o per darrere d'anys anteriors en la mateixa època.

```sql opciones_cuenca
SELECT DISTINCT nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.embalses_semanal
ORDER BY orden, nombre
```

<Dropdown data={opciones_cuenca} name=cuenca value=nombre title="Àmbit" defaultValue="España" />

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
    xAxisTitle="Setmana de l'any"
    title="Ompliment setmanal — {inputs.cuenca.value}"
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
    title="Sèrie històrica des del 2000 — {inputs.cuenca.value}"
    fillColor="#7dd3fc"
    lineColor="#0369a1"
/>

---

## Tots els embassaments

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
    <Column id=embalse title="Embassament" />
    <Column id=cuenca title="Conca" />
    <Column id=uso title="Ús" />
    <Column id=capacidad_hm3 title="Capacitat (hm³)" fmt=num0 />
    <Column id=volumen_hm3 title="Actual (hm³)" fmt=num0 />
    <Column id=llenado title="Ompliment" fmt=pct0 contentType=bar barColor="#7dd3fc" />
    <Column id=dif_vs_anio_anterior title="Vs. fa un any (pp)" fmt=num1 contentType=delta />
</DataTable>

---

## Fonts oficials

- **[MITECO – Butlletí Hidrològic setmanal](https://www.miteco.gob.es/es/agua/temas/evaluacion-de-los-recursos-hidricos/boletin-hidrologico.html)**: base de dades històrica d'embassaments (1988-avui), actualitzada cada dimarts.
- **[Agència Europea de Medi Ambient – WISE WFD](https://water.discomap.eea.europa.eu/)**: límits de les demarcacions hidrogràfiques (PHC 2022-2027).

Els embassaments «hidroelèctrics» són els que el MITECO marca com d'ús elèctric; la resta abasteixen consum, regadiu o indústria.

<LastRefreshed prefix="Dades actualitzades" />
