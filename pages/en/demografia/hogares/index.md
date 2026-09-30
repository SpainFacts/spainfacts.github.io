---
title: Households
description: "Average household size and percentage of one-person households in Spain, by region and province, since 2021 (INE, Continuous Population Statistics)."
i18n_origen: 36e2d1ec8163
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT CAST(h.anio AS INTEGER) AS anio, h.hogares, h.tamano_medio, h.unipersonales, h.pct_unipersonales,
    h.pct_2, h.pct_3, h.pct_4_o_mas
FROM mother.demografia_hogares h
WHERE h.nivel = 'pais'
ORDER BY anio
```

# 🏠 Households

How many people live in each household on average and how many households consist of a single person. The data come from the INE Continuous Population Statistics, which has published them since 2021.

<Grid cols=4>
    <KpiCard
        title="People per household"
        value={espana.slice(-1)[0]?.tamano_medio}
        formattedValue={formatNumber(espana.slice(-1)[0]?.tamano_medio, 2)}
        period="average size, 1 January {espana.slice(-1)[0]?.anio} · {formatNumber(espana[0]?.tamano_medio, 2)} in {espana[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.tamano_medio}))}
    />
    <KpiCard
        title="One-person households"
        value={espana.slice(-1)[0]?.pct_unipersonales}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_unipersonales, 1)}%"
        period="of households · {formatCompact(espana.slice(-1)[0]?.unipersonales, 2)} households"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_unipersonales}))}
    />
    <KpiCard
        title="Two-person households"
        value={espana.slice(-1)[0]?.pct_2}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_2, 1)}%"
        period="of households, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_2}))}
    />
    <KpiCard
        title="Households of 4 or more"
        value={espana.slice(-1)[0]?.pct_4_o_mas}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_4_o_mas, 1)}%"
        period="of households · {formatCompact(espana.slice(-1)[0]?.hogares, 3)} households in total"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_4_o_mas}))}
    />
</Grid>

<p class="text-xs text-gray-500">Households of people living in family dwellings (excludes care homes, barracks, convents and other collective establishments).</p>

## Households by number of members

```sql tamanos
SELECT anio, '1 persona' AS tamano, pct_unipersonales / 100 AS cuota FROM ${espana}
UNION ALL SELECT anio, '2 personas', pct_2 / 100 FROM ${espana}
UNION ALL SELECT anio, '3 personas', pct_3 / 100 FROM ${espana}
UNION ALL SELECT anio, '4 o más', pct_4_o_mas / 100 FROM ${espana}
ORDER BY anio
```

<BarChart
    data={tamanos}
    x=anio
    y=cuota
    series=tamano
    type=stacked
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#f59e0b', '#fcd34d', '#fef3c7']}
    title="Households by number of members (% of total, as at 1 January)"
/>

## By autonomous community

```sql ccaa
SELECT h.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales,
    h.pct_4_o_mas / 100 AS cuatro_o_mas, h.hogares
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod
WHERE h.nivel = 'ccaa' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.tamano_medio DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=tamano_medio title="People per household" fmt=num2 contentType=bar barColor="#fde68a" />
    <Column id=unipersonales title="1-person households" fmt=pct1 />
    <Column id=cuatro_o_mas title="Households of 4 or more" fmt=pct1 />
    <Column id=hogares title="Households" fmt=num0 />
</DataTable>

## By province

```sql provincias
SELECT h.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = h.cod
WHERE h.nivel = 'provincia' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.pct_unipersonales DESC
```

One-person households range from {formatNumber(provincias[0]?.unipersonales / 0.01, 1)}% in {provincias[0]?.provincia} to {formatNumber(provincias.slice(-1)[0]?.unipersonales / 0.01, 1)}% in {provincias.slice(-1)[0]?.provincia}.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="unipersonales"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fffbeb', '#f59e0b', '#78350f']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="One-person households (% of households)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'unipersonales', title: '1-person households', fmt: 'pct1'},
        {id: 'tamano_medio', title: 'People per household', fmt: 'num2'}
    ]}
/>

---

## Sources and notes

- **[INE – Continuous Population Statistics: households](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)**: households by number of members by region ([60131](https://www.ine.es/jaxiT3/Tabla.htm?t=60131)) and province ([60133](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)), and average household size ([60132](https://www.ine.es/jaxiT3/Tabla.htm?t=60132) and [60134](https://www.ine.es/jaxiT3/Tabla.htm?t=60134)). Provisional data as at 1 January; the INE has published them quarterly since 2021. The former Continuous Household Survey (2013-2020) is not included because its methodology is different.

<LastRefreshed prefix="Data updated" />
