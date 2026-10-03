---
title: Reservas de agua y embalses
description: Estado semanal de los embalses españoles por cuenca, comparado con el año anterior y con la media de los últimos diez años.
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import MapaEmbalses from '../../../../../../src/lib/components/MapaEmbalses.svelte';
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

# 💧 Reservas de agua en España

Los embalses españoles almacenan hoy **{formatNumber(espana[0]?.volumen_hm3, 0)} hm³**, el **{formatNumber(espana[0]?.pct_llenado, 1)} %** de su capacidad total ({formatNumber(espana[0]?.capacidad_hm3, 0)} hm³). Datos del Boletín Hidrológico del MITECO a **{new Date(espana[0]?.fecha).toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' })}**, que se publica cada martes.

<Grid cols=3>
    <KpiCard
        title="Reserva hídrica"
        value={espana[0]?.pct_llenado}
        formattedValue={formatNumber(espana[0]?.pct_llenado, 1)}
        unit="%"
        period="{formatNumber(espana[0]?.volumen_hm3, 0)} hm³"
        source="MITECO – Boletín Hidrológico"
        sparklineData={serie_espana}
    />
    <KpiCard
        title="Frente a hace un año"
        value={espana[0]?.dif_vs_anio_anterior}
        formattedValue="{espana[0]?.dif_vs_anio_anterior > 0 ? '+' : ''}{formatNumber(espana[0]?.dif_vs_anio_anterior, 1)}"
        unit=" pp"
        period="Hace un año: {formatNumber(espana[0]?.pct_hace_un_anio, 1)} %"
        direction="positive-up"
        sparklineData={serie_comparada.map(d => ({valor: d.dif_anio}))}
    />
    <KpiCard
        title="Frente a la media de 10 años"
        value={espana[0]?.dif_vs_media_10_anios}
        formattedValue="{espana[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(espana[0]?.dif_vs_media_10_anios, 1)}"
        unit=" pp"
        period="Media misma semana: {formatNumber(espana[0]?.pct_media_10_anios, 1)} %"
        direction="positive-up"
        sparklineData={serie_comparada.map(d => ({valor: d.dif_media}))}
    />
</Grid>

---

## El agua embalsada en cada demarcación

```sql demarcaciones
SELECT
    clave,
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
    areaCol="clave"
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
        {id: 'llenado', title: 'Llenado', fmt: 'pct1'},
        {id: 'volumen_hm3', title: 'Agua embalsada (hm³)', fmt: 'num0'},
        {id: 'dif_vs_media_10_anios', title: 'Vs. media 10 años (pp)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Las islas, Ceuta y Melilla no forman parte del Boletín Hidrológico. El ámbito «Cuencas Internas del País Vasco» se suma a la demarcación del Cantábrico Oriental.</p>

## Embalse por embalse

Cada cuadrado es un embalse: su tamaño es proporcional a la capacidad y el relleno, al agua que tiene ahora. El color indica si está por encima (verde azulado) o por debajo (marrón) de lo habitual para esta semana del año, es decir, la media de la misma semana en los diez años anteriores.

```sql mapa_embalses
SELECT embalse, cuenca, lat, lon, capacidad_hm3, volumen_hm3, pct_llenado,
       pct_habitual, dif_vs_habitual, uso_electrico
FROM mother.embalses_actual
```

<MapaEmbalses data={mapa_embalses} />

<p class="text-xs text-gray-500">Ubicación de los embalses: © colaboradores de OpenStreetMap (ODbL) y Wikidata, casados por nombre con el Boletín Hidrológico. Límites provinciales © Instituto Geográfico Nacional.</p>

## Cuencas por encima y por debajo de lo habitual

La columna **vs. media 10 años** compara el llenado actual con el de la misma semana en los diez años anteriores: es la mejor forma de saber si una cuenca está en situación normal para la época del año.

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
    <Column id=cuenca title="Cuenca" />
    <Column id=llenado title="Llenado" fmt=pct1 contentType=bar barColor="#7dd3fc" />
    <Column id=volumen_hm3 title="hm³" fmt=num0 />
    <Column id=hace_un_anio title="Hace un año" fmt=pct1 />
    <Column id=dif_vs_anio_anterior title="Dif. (pp)" fmt=num1 contentType=delta />
    <Column id=media_10_anios title="Media 10 años" fmt=pct1 />
    <Column id=dif_vs_media_10_anios title="Dif. (pp)" fmt=num1 contentType=delta />
    <Column id=situacion title="Situación" />
    <Column id=n_embalses title="Embalses" />
</DataTable>

---

## Evolución a lo largo del año

Cada línea es un año natural (de los seis últimos): así se ve si la reserva actual va por delante o por detrás de años anteriores en la misma época.

```sql opciones_cuenca
SELECT DISTINCT nombre, CASE WHEN nivel = 'pais' THEN 0 ELSE 1 END AS orden
FROM mother.embalses_semanal
ORDER BY orden, nombre
```

<Dropdown data={opciones_cuenca} name=cuenca value=nombre title="Ámbito" defaultValue="España" />

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
    xAxisTitle="Semana del año"
    title="Llenado semanal — {inputs.cuenca.value}"
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
    title="Serie histórica desde 2000 — {inputs.cuenca.value}"
    fillColor="#7dd3fc"
    lineColor="#0369a1"
/>

---

## Todos los embalses

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
    <Column id=embalse title="Embalse" />
    <Column id=cuenca title="Cuenca" />
    <Column id=uso title="Uso" />
    <Column id=capacidad_hm3 title="Capacidad (hm³)" fmt=num0 />
    <Column id=volumen_hm3 title="Actual (hm³)" fmt=num0 />
    <Column id=llenado title="Llenado" fmt=pct0 contentType=bar barColor="#7dd3fc" />
    <Column id=dif_vs_anio_anterior title="Vs. hace un año (pp)" fmt=num1 contentType=delta />
</DataTable>

---

## Fuentes oficiales

- **[MITECO – Boletín Hidrológico semanal](https://www.miteco.gob.es/es/agua/temas/evaluacion-de-los-recursos-hidricos/boletin-hidrologico.html)**: base de datos histórica de embalses (1988-hoy), actualizada cada martes.
- **[Agencia Europea de Medio Ambiente – WISE WFD](https://water.discomap.eea.europa.eu/)**: límites de las demarcaciones hidrográficas (PHC 2022-2027).

Los embalses «hidroeléctricos» son los que el MITECO marca como de uso eléctrico; el resto abastecen consumo, regadío o industria.

<LastRefreshed prefix="Datos actualizados" />
