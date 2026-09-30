---
title: Population trends
description: "Spain's population since 1971 and its annual growth per 1,000 inhabitants, split into births minus deaths and migration, by region and province (INE)."
i18n_origen: 40e6678c9212
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion, poblacion / 1e6 AS millones
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, crecimiento, crecimiento_1000, vegetativo_1000, resto_1000,
    crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais' AND crecimiento_1000 IS NOT NULL
ORDER BY anio
```

```sql resumen
SELECT
    (SELECT anio FROM ${poblacion} ORDER BY anio DESC LIMIT 1) AS anio_pob,
    (SELECT poblacion FROM ${poblacion} ORDER BY anio DESC LIMIT 1) AS pob,
    (SELECT anio FROM ${poblacion} ORDER BY anio LIMIT 1) AS anio_ini,
    (SELECT poblacion FROM ${poblacion} ORDER BY anio LIMIT 1) AS pob_ini,
    (SELECT poblacion FROM ${poblacion} WHERE anio = (SELECT max(anio) - 10 FROM ${poblacion})) AS pob_10
```

# 📈 Population trends

How the number of people living in Spain has changed since 1971, and how much of the growth is due to births and deaths and how much to migration.

<Grid cols=4>
    <KpiCard
        title="Population"
        value={resumen[0]?.pob}
        formattedValue="{formatNumber(resumen[0]?.pob / 1e6, 2)} million"
        period="as at 1 January {resumen[0]?.anio_pob} · {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} million in {resumen[0]?.anio_ini}"
        change={100 * (resumen[0]?.pob / resumen[0]?.pob_10 - 1)}
        changeUnit="%"
        changePeriod="in 10 years"
        source="INE"
        sparklineData={poblacion.map(d => ({anio: d.anio, valor: d.millones}))}
    />
    <KpiCard
        title="Annual growth"
        value={anual.slice(-1)[0]?.crecimiento_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.crecimiento_1000, 1)} per 1,000 inhab."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento, 0)} more people in {anual.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.crecimiento_1000}))}
    />
    <KpiCard
        title="Births minus deaths"
        value={anual.slice(-1)[0]?.vegetativo_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.vegetativo_1000, 1)} per 1,000 inhab."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento_vegetativo, 0)} people in {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/en/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.vegetativo_1000}))}
    />
    <KpiCard
        title="Migration and adjustments"
        value={anual.slice(-1)[0]?.resto_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} per 1,000 inhab."
        period="{formatNumber(anual.slice(-1)[0]?.resto, 0)} people in {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/en/sociedad/inmigracion"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.resto_1000}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('crecimiento_poblacion')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_poblacion')} />


## Population since 1971

<LineChart
    data={poblacion}
    x=anio
    y=millones
    yFmt=num1
    xFmt="####"
    lineColor="#1d4ed8"
    yAxisTitle="millions of inhabitants"
    title="Resident population of Spain on 1 January (millions)"
/>

<p class="text-xs text-gray-500">INE Continuous Population Statistics, which reconstructs the series back to 1971 using consistent criteria. Between {resumen[0]?.anio_ini} and {resumen[0]?.anio_pob} the population rose from {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} to {formatNumber(resumen[0]?.pob / 1e6, 1)} million.</p>

## Births, deaths and migration

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual}
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual}
ORDER BY anio
```

```sql anios_baja
SELECT count(*) AS n, string_agg(CAST(anio AS VARCHAR), ', ' ORDER BY anio) AS lista,
    count(*) FILTER (WHERE resto_1000 < 0) AS con_migracion_negativa
FROM ${anual}
WHERE crecimiento_1000 < 0
```

```sql decadas
SELECT
    CASE WHEN anio < 1985 THEN '1975-1984' WHEN anio < 1995 THEN '1985-1994' WHEN anio < 2005 THEN '1995-2004'
         WHEN anio < 2015 THEN '2005-2014' ELSE '2015-' || max(anio) OVER () END AS periodo,
    vegetativo_1000, resto_1000, crecimiento_1000
FROM ${anual}
```

```sql decadas_media
SELECT periodo, avg(vegetativo_1000) AS vegetativo, avg(resto_1000) AS migracion, avg(crecimiento_1000) AS total
FROM ${decadas}
GROUP BY 1
ORDER BY 1
```

<BarChart
    data={componentes}
    x=anio
    y=por_1000
    series=componente
    type=stacked
    yFmt=num1
    xFmt="####"
    colorPalette={['#be185d', '#0f766e']}
    yAxisTitle="per 1,000 inhabitants"
    title="Annual growth per 1,000 inhabitants and its components"
/>

<DataTable data={decadas_media} rows=all>
    <Column id=periodo title="Period" />
    <Column id=total title="Average annual growth per 1,000 inhab." fmt=num1 />
    <Column id=vegetativo title="…from births minus deaths" fmt=num1 contentType=delta />
    <Column id=migracion title="…from migration and adjustments" fmt=num1 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">"Migración y ajustes" (migration and adjustments) = total growth minus natural change. Since 2021 it can be compared with the net migration with other countries measured directly by the Migration Statistics: in {anual.slice(-1)[0]?.anio}, {formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} versus {formatNumber(anual.slice(-1)[0]?.saldo_exterior_1000, 1)} per 1,000 inhabitants. {#if anios_baja[0]?.n > 0}Since 1975 the population has fallen in only {anios_baja[0]?.n} years ({anios_baja[0]?.lista}){#if anios_baja[0]?.con_migracion_negativa === anios_baja[0]?.n}, and in all of them the migration component was negative{/if}.{/if}</p>

## By autonomous community

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    a.crecimiento_1000, a.vegetativo_1000, a.resto_1000, a.saldo_exterior_1000,
    e.poblacion, 100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
JOIN mother.demografia_envejecimiento e ON e.nivel = 'ccaa' AND e.cod = a.cod AND e.anio = a.anio + 1
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = a.cod AND e10.anio = a.anio - 9
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE crecimiento_1000 IS NOT NULL)
ORDER BY a.crecimiento_1000 DESC
```

In {anual.slice(-1)[0]?.anio} the regions that grew most relative to their population were {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.crecimiento_1000, 1)} per 1,000 inhab.) and {ccaa[1]?.comunidad} ({formatNumber(ccaa[1]?.crecimiento_1000, 1)}); the one that grew least was {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.crecimiento_1000, 1)}).

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=crecimiento_1000 title="Growth per 1,000 inhab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=vegetativo_1000 title="…births minus deaths" fmt=num1 contentType=delta />
    <Column id=resto_1000 title="…migration and adjustments" fmt=num1 />
    <Column id=saldo_exterior_1000 title="Net migration with other countries" fmt=num1 />
    <Column id=crec_10 title="Growth over 10 years (%)" fmt=num1 />
    <Column id=poblacion title="Population" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">For a region, "migration and adjustments" also includes changes of residence to and from other regions, which is why it does not match net migration with other countries. Population as at 1 January {anual.slice(-1)[0]?.anio + 1}.</p>

## By province

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta, e.poblacion,
    100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10,
    100.0 * (e.poblacion / e00.poblacion - 1) AS crec_2000
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'provincia' AND e10.cod = e.cod AND e10.anio = e.anio - 10
JOIN mother.demografia_envejecimiento e00 ON e00.nivel = 'provincia' AND e00.cod = e.cod AND e00.anio = 2000
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY crec_10 DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE crec_10 < 0) AS pierden_10, count(*) FILTER (WHERE crec_2000 < 0) AS pierden_2000
FROM ${provincias}
```

{provincias_resumen[0]?.pierden_10} provinces have fewer inhabitants today than ten years ago, and {provincias_resumen[0]?.pierden_2000} fewer than in 2000.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="crec_10"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#b91c1c', '#f8fafc', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="Population change over the last 10 years (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_10', title: 'Change over 10 years (%)', fmt: 'num1'},
        {id: 'crec_2000', title: 'Change since 2000 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Population', fmt: 'num0'}
    ]}
/>

---

## Sources and notes

- **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (table 56945): population on 1 January by province since 1971. This is the official consistent series; it may differ slightly from the municipal register figures used in the [regional profiles](/en/territorios).
- **[INE – Vital Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)** (tables 6524 and 6561): births and deaths by province of residence.
- **[INE – Migration and Change of Residence Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (tables 69758 and 69762): net migration with other countries since 2021.
- Growth per 1,000 inhab. = (population on 1 January of the following year − population on 1 January) / average population for the year × 1,000.

<LastRefreshed prefix="Data updated" />
