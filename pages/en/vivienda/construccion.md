---
title: New builds
description: "Open-market homes started and completed each year in Spain per 1,000 inhabitants since 1996, by region and province, with data from the Ministry of Housing."
i18n_origen: 6b1ad71c87ca
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, iniciadas, terminadas, iniciadas_1000, terminadas_1000
FROM mother.vivienda_obra_nueva
WHERE nivel = 'pais' AND iniciadas_1000 IS NOT NULL
ORDER BY anio
```

```sql espana_largo
SELECT anio, 'Iniciadas' AS fase, iniciadas_1000 AS por_1000 FROM ${espana}
UNION ALL
SELECT anio, 'Terminadas' AS fase, terminadas_1000 AS por_1000 FROM ${espana}
ORDER BY anio, fase
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(terminadas_1000, anio) AS term_ult,
    arg_max(iniciadas_1000, anio) AS ini_ult,
    arg_max(terminadas, anio) AS term_total,
    arg_max(iniciadas, anio) AS ini_total,
    max(terminadas_1000) AS term_max,
    arg_max(anio, terminadas_1000) AS anio_term_max,
    max(iniciadas_1000) AS ini_max,
    arg_max(anio, iniciadas_1000) AS anio_ini_max,
    min(terminadas_1000) AS term_min,
    arg_min(anio, terminadas_1000) AS anio_term_min,
    arg_max(terminadas_1000, anio) / max(terminadas_1000) AS fraccion_max,
    avg(terminadas_1000) FILTER (WHERE anio BETWEEN 1996 AND 2000) AS media_9600
FROM ${espana}
```

```sql mercado
SELECT o.anio, o.terminadas_1000, m.compraventas_nueva_1000
FROM mother.vivienda_obra_nueva o
JOIN mother.vivienda_mercado_anual m ON m.nivel = 'pais' AND m.anio = o.anio AND m.meses = 12
WHERE o.nivel = 'pais'
ORDER BY o.anio
```

```sql mercado_largo
SELECT anio, 'Viviendas libres terminadas' AS serie, terminadas_1000 AS por_1000 FROM ${mercado}
UNION ALL
SELECT anio, 'Compraventas de vivienda nueva' AS serie, compraventas_nueva_1000 AS por_1000 FROM ${mercado}
ORDER BY anio, serie
```

```sql ccaa
SELECT o.cod, o.nombre AS comunidad, '/en' || t.ruta AS ruta, o.anio, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas,
       (SELECT avg(x.terminadas_1000) FROM mother.vivienda_obra_nueva x WHERE x.nivel = 'ccaa' AND x.cod = o.cod AND x.anio BETWEEN o.anio - 4 AND o.anio) AS terminadas_1000_5a
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = o.cod
WHERE o.nivel = 'ccaa' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

```sql provincias
SELECT o.cod AS cod_prov, o.nombre AS provincia, '/en' || t.ruta AS ruta, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = o.cod
WHERE o.nivel = 'provincia' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

# 🏗️ New builds

How many homes are built in Spain. These are **open-market homes** (excluding social or subsidised housing) on which work begins (**started**) and ends (**completed**) each year, estimated by the Ministry of Housing from the certificates issued by the associations of building surveyors, always **per 1,000 inhabitants**.

<Grid cols=4>
    <KpiCard
        title="Homes completed"
        value={hitos[0]?.term_ult}
        formattedValue="{formatNumber(hitos[0]?.term_ult, 2)} per 1,000 inhab."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.term_total, 0)} open-market homes"
        source="Ministry of Housing"
        sparklineData={espana.map(d => d.terminadas_1000)}
    />
    <KpiCard
        title="Homes started"
        value={hitos[0]?.ini_ult}
        formattedValue="{formatNumber(hitos[0]?.ini_ult, 2)} per 1,000 inhab."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.ini_total, 0)} open-market homes"
        source="Ministry of Housing"
        sparklineData={espana.map(d => d.iniciadas_1000)}
    />
    <KpiCard
        title="Versus the peak"
        value={hitos[0]?.fraccion_max}
        formattedValue="{formatNumber(hitos[0]?.fraccion_max / 0.01, 0)} %"
        period="of homes completed per inhabitant in {hitos[0]?.anio_term_max} ({formatNumber(hitos[0]?.term_max, 1)} per 1,000 inhab.)"
        source="Ministry of Housing"
        sparklineData={espana.map(d => d.terminadas_1000)}
    />
    <KpiCard
        title="Versus the late 1990s"
        value={hitos[0]?.media_9600}
        formattedValue="{formatNumber(hitos[0]?.media_9600, 1)} per 1,000 inhab."
        period="homes completed per year on average in 1996-2000"
        source="Ministry of Housing"
        sparklineData={espana.filter(d => d.anio <= 2000).map(d => d.terminadas_1000)}
    />
</Grid>

## Trend

The peak in homes completed per inhabitant was in {hitos[0]?.anio_term_max} ({formatNumber(hitos[0]?.term_max, 1)} per 1,000 inhabitants) and the low in {hitos[0]?.anio_term_min} ({formatNumber(hitos[0]?.term_min, 2)}). In {hitos[0]?.anio_ult}, {formatNumber(hitos[0]?.term_ult, 2)} per 1,000 inhabitants were completed and {formatNumber(hitos[0]?.ini_ult, 2)} were started.

<LineChart
    data={espana_largo}
    x=anio
    y=por_1000
    series=fase
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1,000 inhabitants"
    title="Open-market homes started and completed per 1,000 inhabitants"
/>

Completed homes can be compared with the sales of new homes recorded by the INE (which also include subsidised housing):

<LineChart
    data={mercado_largo}
    x=anio
    y=por_1000
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1,000 inhabitants"
    title="Homes completed and sales of new homes per 1,000 inhabitants"
/>

## By region

Open-market homes completed per 1,000 inhabitants in {ccaa[0]?.anio}.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="terminadas_1000"
    valueFmt="num2"
    link="ruta"
    colorPalette={['#ecfccb', '#84cc16', '#365314']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'terminadas_1000', title: 'Completed per 1,000 inhab.', fmt: 'num2'},
        {id: 'iniciadas_1000', title: 'Started per 1,000 inhab.', fmt: 'num2'},
        {id: 'terminadas', title: 'Completed', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=terminadas_1000 title="Completed per 1,000 inhab." fmt='0.00' />
    <Column id=terminadas_1000_5a title="5-year average" fmt='0.00' />
    <Column id=iniciadas_1000 title="Started per 1,000 inhab." fmt='0.00' />
    <Column id=terminadas title="Completed" fmt='#,##0' />
</DataTable>

## By province

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Province" />
    <Column id=terminadas_1000 title="Completed per 1,000 inhab." fmt='0.00' />
    <Column id=iniciadas_1000 title="Started per 1,000 inhab." fmt='0.00' />
    <Column id=terminadas title="Completed" fmt='#,##0' />
    <Column id=iniciadas title="Started" fmt='#,##0' />
</DataTable>

---

**Sources:** [Ministry of Housing and Urban Agenda, statistical bulletin: open-market homes started and completed](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000) (tables 3.1 and 3.2, annual since 1991, based on the certificates of the associations of building surveyors; the per-inhabitant series starts in 1996, the first year of INE population data) and [INE, Property Rights Transfer Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=6150).
