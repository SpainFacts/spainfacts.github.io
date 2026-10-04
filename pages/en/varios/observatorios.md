---
title: Public observatories
description: "Census of Spain's public observatories: how many there are, which administration creates them, when they were set up, how many are still active, how many there are per inhabitant in each region and which party was in government when they were created."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: a544f976aca5
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql resumen
SELECT
    count(*) AS total,
    count(*) FILTER (WHERE estado = 'Activo') AS activos,
    count(*) FILTER (WHERE estado = 'Inactivo') AS inactivos,
    count(*) FILTER (WHERE estado = 'Sin información') AS sin_info,
    100.0 * count(*) FILTER (WHERE estado = 'Activo') / count(*) AS pct_activos,
    count(*) FILTER (WHERE nivel = 'Estatal') AS estatales,
    count(anio_creacion) AS con_anio,
    count(*) FILTER (WHERE anio_creacion >= 2015) AS desde_2015,
    100.0 * count(*) FILTER (WHERE anio_creacion >= 2015) / count(anio_creacion) AS pct_desde_2015,
    count(*) FILTER (WHERE tipo = 'Mixto (público-privado)') AS mixtos,
    max(anio_creacion) AS ultimo_anio,
    count(*) FILTER (WHERE nivel IN ('Autonómico', 'Provincial o insular', 'Local') AND cod_ccaa IS NULL) AS sin_comunidad,
    100.0 * count(*) FILTER (WHERE estado = 'Sin información') / count(*) AS pct_sin_info
FROM mother.observatorios_detalle
```

```sql por_anio
SELECT
    CAST(anio_creacion AS INTEGER) AS anio,
    count(*) AS creados,
    sum(count(*)) OVER (ORDER BY anio_creacion) AS acumulados
FROM mother.observatorios_detalle
WHERE anio_creacion IS NOT NULL
GROUP BY anio_creacion
ORDER BY anio_creacion
```

```sql por_nivel
SELECT
    nivel,
    estado,
    count(*) AS observatorios,
    CASE nivel WHEN 'Estatal' THEN 1 WHEN 'Autonómico' THEN 2 WHEN 'Provincial o insular' THEN 3 WHEN 'Local' THEN 4 ELSE 5 END AS orden
FROM mother.observatorios_detalle
GROUP BY ALL
ORDER BY orden, estado
```

```sql por_nivel_resumen
SELECT
    nivel,
    count(*) AS total,
    100.0 * count(*) FILTER (WHERE estado = 'Activo') / count(*) AS pct_activos
FROM mother.observatorios_detalle
GROUP BY nivel
ORDER BY total DESC
```

```sql por_ccaa
WITH pob AS (
    SELECT cod, poblacion
    FROM mother.poblacion_territorios
    WHERE nivel = 'ccaa' AND sexo = 'Total' AND anio = (SELECT max(anio) FROM mother.poblacion_territorios)
)
SELECT
    t.cod,
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    count(o.nombre) AS observatorios,
    count(o.nombre) FILTER (WHERE o.estado = 'Activo') AS activos,
    1e6 * count(o.nombre) / p.poblacion AS por_millon
FROM mother.territorios t
JOIN pob p ON p.cod = t.cod
LEFT JOIN mother.observatorios_detalle o ON o.cod_ccaa = t.cod
WHERE t.nivel = 'ccaa'
GROUP BY t.cod, t.nombre, t.ruta, p.poblacion
ORDER BY por_millon DESC
```

```sql listado
SELECT
    nombre,
    nivel,
    coalesce(ccaa, '') AS comunidad,
    coalesce(municipio, '') AS municipio,
    anio_creacion,
    coalesce(partido, '') AS partido,
    estado,
    tipo
FROM mother.observatorios_detalle
ORDER BY nombre
```

```sql partidos
-- Observatorios con partido atribuido, por familia política y nivel
SELECT
    partido,
    any_value(color_partido) AS color,
    nivel,
    count(*) AS observatorios
FROM mother.observatorios_detalle
WHERE partido IS NOT NULL
GROUP BY partido, nivel
ORDER BY sum(count(*)) OVER (PARTITION BY partido) DESC, nivel
```

```sql partidos_colores
SELECT partido, any_value(color_partido) AS color, count(*) AS n
FROM mother.observatorios_detalle
WHERE partido IS NOT NULL
GROUP BY partido
ORDER BY n DESC
```

```sql cobertura
SELECT
    count(*) FILTER (WHERE partido IS NOT NULL) AS atribuidos,
    count(*) FILTER (WHERE anio_creacion IS NOT NULL) AS con_anio,
    count(*) AS total,
    count(*) FILTER (WHERE partido IS NOT NULL AND cambio_en_el_anio) AS dudosos,
    count(*) FILTER (WHERE metodo_partido = 'Diputación o cabildo (sin datos)') AS provinciales,
    min(anio_creacion) FILTER (WHERE partido IS NOT NULL) AS desde
FROM mother.observatorios_detalle
```

```sql esperados
-- Observados frente a esperados: la creación de observatorios crece con los años (y
-- el censo documenta mejor los recientes), así que quien gobierna ahora saldría
-- favorecido. La tendencia de cada año se toma de los observatorios con fecha de los
-- OTROS niveles (para los estatales, autonómicos y locales), y los observatorios de
-- cada nivel se reparten según esa tendencia y la parte de cada año que gobernó cada
-- partido. z: diferencia observada frente al azar (binomial, aproximación normal).
WITH obs AS (
    SELECT * FROM mother.observatorios_detalle WHERE anio_creacion IS NOT NULL
),
anios AS (SELECT CAST(unnest(range(1990, year(current_date) + 1)) AS INTEGER) AS anio),
tendencia AS (
    SELECT n.nivel, a.anio, count(o.nombre) AS n_ref
    FROM (VALUES ('Estatal'), ('Autonómico')) n(nivel)
    CROSS JOIN anios a
    LEFT JOIN obs o ON CAST(o.anio_creacion AS INTEGER) = a.anio AND o.nivel <> n.nivel
    GROUP BY ALL
),
pesos AS (
    SELECT nivel, anio, n_ref / sum(n_ref) OVER (PARTITION BY nivel) AS w FROM tendencia
),
gob AS (
    SELECT
        CASE g.nivel WHEN 'estatal' THEN 'Estatal' ELSE 'Autonómico' END AS nivel,
        g.familia AS partido,
        a.anio,
        greatest(0, date_diff('day', greatest(CAST(g.desde AS DATE), make_date(a.anio, 1, 1)),
            least(coalesce(CAST(g.hasta AS DATE), current_date), make_date(a.anio + 1, 1, 1)))) / 365.25
          / CASE g.nivel WHEN 'estatal' THEN 1 ELSE 19 END AS fraccion
    FROM mother.gobiernos_presidentes g
    CROSS JOIN anios a
),
esperado AS (
    SELECT g.nivel, g.partido, sum(p.w * g.fraccion) AS cuota
    FROM gob g JOIN pesos p USING (nivel, anio)
    GROUP BY ALL
),
observado AS (
    SELECT nivel, partido, count(*) AS observados
    FROM obs WHERE nivel IN ('Estatal', 'Autonómico') AND partido IS NOT NULL
    GROUP BY ALL
),
totales AS (SELECT nivel, sum(observados) AS total FROM observado GROUP BY nivel)
SELECT
    e.nivel,
    e.partido,
    coalesce(o.observados, 0) AS observados,
    t.total * e.cuota AS esperados,
    coalesce(o.observados, 0) / (t.total * e.cuota) AS ratio,
    (coalesce(o.observados, 0) - t.total * e.cuota) / sqrt(t.total * e.cuota * (1 - e.cuota)) AS z
FROM esperado e
JOIN totales t USING (nivel)
LEFT JOIN observado o USING (nivel, partido)
WHERE t.total * e.cuota >= 1
ORDER BY e.nivel DESC, esperados DESC
```

```sql esperados_resumen
SELECT
    max(ratio) FILTER (WHERE nivel = 'Estatal' AND partido = 'PSOE') AS psoe_est,
    max(ratio) FILTER (WHERE nivel = 'Estatal' AND partido = 'PP') AS pp_est,
    max(ratio) FILTER (WHERE nivel = 'Autonómico' AND partido = 'PSOE') AS psoe_aut,
    max(ratio) FILTER (WHERE nivel = 'Autonómico' AND partido = 'PP') AS pp_aut,
    max(abs(z)) FILTER (WHERE nivel = 'Estatal' AND partido IN ('PSOE', 'PP')) AS z_est,
    max(abs(z)) FILTER (WHERE nivel = 'Autonómico' AND partido IN ('PSOE', 'PP')) AS z_aut
FROM ${esperados}
```

```sql estatal_anio
SELECT CAST(anio_creacion AS INTEGER) AS anio, partido, count(*) AS observatorios
FROM mother.observatorios_detalle
WHERE nivel = 'Estatal' AND partido IS NOT NULL
GROUP BY ALL
ORDER BY anio
```

# 🔍 Public observatories

Public administrations set up observatories to monitor a subject (gender-based violence, housing, climate change, retail...) and publish reports on it. This page summarises the census maintained by [observatoriospublicos.es](https://observatoriospublicos.es/): how many there are, who creates them, when they were set up and whether they are still active.

<Grid cols=4>
    <KpiCard
        title="Observatories in the census"
        value={resumen[0]?.total}
        formattedValue={formatNumber(resumen[0]?.total, 0)}
        period="{formatNumber(resumen[0]?.estatales, 0)} belong to the General State Administration"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.acumulados)}
    />
    <KpiCard
        title="Active"
        value={resumen[0]?.pct_activos}
        formattedValue="{formatNumber(resumen[0]?.pct_activos, 0)}%"
        period="{formatNumber(resumen[0]?.activos, 0)} confirmed · {formatNumber(resumen[0]?.inactivos, 0)} closed · {formatNumber(resumen[0]?.sin_info, 0)} no information"
        source="observatoriospublicos.es"
    />
    <KpiCard
        title="Created since 2015"
        value={resumen[0]?.pct_desde_2015}
        formattedValue="{formatNumber(resumen[0]?.pct_desde_2015, 0)}%"
        period="{formatNumber(resumen[0]?.desde_2015, 0)} of the {formatNumber(resumen[0]?.con_anio, 0)} with a known year of creation"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.creados)}
    />
    <KpiCard
        title="With private participation"
        value={resumen[0]?.mixtos}
        formattedValue="{formatNumber(resumen[0]?.mixtos / resumen[0]?.total / 0.01, 1)}%"
        period="{formatNumber(resumen[0]?.mixtos, 0)} mixed (public-private) observatories"
        source="observatoriospublicos.es"
    />
</Grid>

## When they were created

Observatories created each year and cumulative total. Only {formatNumber(resumen[0]?.con_anio, 0)} of the {formatNumber(resumen[0]?.total, 0)} have a creation date in the census, so the bars fall short. Among those with a date, {formatNumber(resumen[0]?.pct_desde_2015, 0)}% were set up in 2015 or later (the most recent ones also tend to have better-documented dates).

<BarChart
    data={por_anio}
    x=anio
    y=creados
    y2=acumulados
    y2SeriesType=line
    xFmt='0'
    yAxisTitle="Created in the year"
    y2AxisTitle="Cumulative"
    title="Public observatories created per year (known date)"
/>

## Who creates them and how many are still active

By level of administration. The census only marks {formatNumber(resumen[0]?.inactivos, 0)} observatories as closed; of the total, {formatNumber(resumen[0]?.pct_sin_info, 0)}% have no information on whether they are still operating.

<BarChart
    data={por_nivel}
    x=nivel
    y=observatorios
    series=estado
    swapXY=true
    sort=false
    colorPalette={['#16a34a', '#dc2626', '#94a3b8']}
    title="Observatories by level of administration and status"
/>

## By autonomous community

Regional, provincial and local observatories in each autonomous community, per million inhabitants. The region is taken from the scope stated in the census or, if it is not stated, from the observatory's name: the municipality (matched against INE's list), the island or province, or the demonym ("Andaluz", "Galego"...). {formatNumber(resumen[0]?.sin_comunidad, 0)} remain unassigned because their name gives no clue ("Observatorio Social", "Observatorio del Agua"...).

<MapaEspana
    data={por_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="por_millon"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#f5f3ff', '#a78bfa', '#5b21b6']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: observatoriospublicos.es"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_millon', title: 'Per million inhab.', fmt: '0.0'},
        {id: 'observatorios', title: 'Observatories', fmt: '0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Region"/>
    <Column id=por_millon title="Per million inhab." fmt='0.0'/>
    <Column id=observatorios title="Observatories" fmt='0'/>
    <Column id=activos title="Confirmed active" fmt='0'/>
</DataTable>

## Who was in government when they were created

Each observatory with a year of creation is attributed to the party that governed the creating administration in the middle of that year: the Spanish Government for state observatories, the regional presidency for regional ones and the mayoralty for municipal ones. This attributes {formatNumber(cobertura[0]?.atribuidos, 0)} of the {formatNumber(cobertura[0]?.total, 0)} observatories in the census: the rest have no creation date, belong to a provincial council or island council ({formatNumber(cobertura[0]?.provinciales, 0)}, with no data on who chaired them) or cannot be located. In {formatNumber(cobertura[0]?.dudosos, 0)} cases the government changed that same year and the attribution is less certain.

<BarChart
    data={partidos}
    x=partido
    y=observatorios
    series=nivel
    swapXY=true
    sort=false
    colorPalette={['#0f766e', '#6366f1', '#f59e0b', '#94a3b8']}
    title="Observatories created by the party in government (known year of creation)"
/>

A simple count favours whoever has governed longest, and also whoever governs now: more and more observatories are being created (and the census documents recent ones better). To adjust for this, the table compares the **observed** observatories with those **expected** if each party had followed the trend of the rest of the census in the years it governed (for state observatories, the trend of regional and local ones, which do not depend on the Spanish Government). A ratio of 1 is what would be expected; 2, double; 0.5, half.

<DataTable data={esperados} rows=20>
    <Column id=nivel title="Level"/>
    <Column id=partido title="President's party"/>
    <Column id=observados title="Observed" fmt='0'/>
    <Column id=esperados title="Expected from the trend" fmt='0.0'/>
    <Column id=ratio title="Observed / expected" fmt='0.00'/>
</DataTable>

Once the trend is discounted, in the Spanish Government the PSOE creates {formatNumber(esperados_resumen[0]?.psoe_est, 2)} times the expected number and the PP {formatNumber(esperados_resumen[0]?.pp_est, 2)} times: {#if esperados_resumen[0]?.z_est >= 1.96}a larger difference than chance would explain, albeit with few cases{:else}with so few cases, the difference is no larger than chance could explain{/if}. In the regions, the PSOE stands at {formatNumber(esperados_resumen[0]?.psoe_aut, 2)} and the PP at {formatNumber(esperados_resumen[0]?.pp_aut, 2)}: {#if esperados_resumen[0]?.z_aut >= 1.96}a larger difference than chance would explain{:else}a difference that chance can explain{/if}.

<BarChart
    data={estatal_anio}
    x=anio
    y=observatorios
    series=partido
    xFmt='0'
    seriesColors={Object.fromEntries(partidos_colores.map(d => [d.partido, d.color]))}
    title="State observatories created each year, by the party of the Spanish Government"
/>

## All observatories

<DataTable data={listado} rows=15 search=true>
    <Column id=nombre title="Observatory" wrap=true/>
    <Column id=nivel title="Level"/>
    <Column id=comunidad title="Region"/>
    <Column id=municipio title="Municipality"/>
    <Column id=anio_creacion title="Created" fmt='0'/>
    <Column id=partido title="In government"/>
    <Column id=estado title="Status"/>
    <Column id=tipo title="Type"/>
</DataTable>

---

**Source:** [observatoriospublicos.es](https://observatoriospublicos.es/), a citizen-run census of observatories of Spanish public administrations. The level and region are inferred from the scope stated in the census and, where it is not stated, from the observatory's name (INE municipalities, islands, provinces and demonyms). The status "Sin información" means the census does not say whether the observatory is still active. Party: presidencies of the Spanish Government and of the autonomous communities checked against Wikidata and official sources, and mayors from the Local Information System of the Ministry of Territorial Policy ([who governs each municipality](/en/territorios/municipios)).
