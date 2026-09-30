---
title: Births and fertility
description: "Births and deaths per 1,000 inhabitants, children per woman, mothers' mean age and births to foreign mothers in Spain, by region and province since 1975 (INE)."
i18n_origen: a59927850e3c
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, crecimiento_vegetativo,
    tasa_natalidad, tasa_mortalidad, vegetativo_1000, fecundidad, fecundidad_espanolas,
    fecundidad_extranjeras, edad_maternidad, edad_primer_hijo, pct_madre_extranjera
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql ultimo
SELECT a.*, p.anio AS anio_pico, p.nacimientos AS nacimientos_pico, p.tasa_natalidad AS tasa_pico,
    f.anio AS anio_icf_max, f.fecundidad AS icf_max
FROM ${anual} a
CROSS JOIN (SELECT anio, nacimientos, tasa_natalidad FROM ${anual} WHERE anio >= 2000 ORDER BY nacimientos DESC LIMIT 1) p
CROSS JOIN (SELECT anio, fecundidad FROM ${anual} WHERE anio >= 1990 ORDER BY fecundidad DESC LIMIT 1) f
ORDER BY a.anio DESC
LIMIT 1
```

```sql primero
SELECT * FROM ${anual} ORDER BY anio LIMIT 1
```

```sql vegetativo_negativo
SELECT min(anio) AS desde, count(*) AS anios
FROM ${anual}
WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👶 Births and fertility

How many children are born in Spain relative to its population, how many children each woman has on average, at what age, and how many are born to foreign mothers, together with the deaths that determine the natural growth of the population.

<Grid cols=4>
    <KpiCard
        title="Birth rate"
        value={ultimo[0]?.tasa_natalidad}
        formattedValue="{formatNumber(ultimo[0]?.tasa_natalidad, 2)} per 1,000 inhab."
        period="{formatNumber(ultimo[0]?.nacimientos, 0)} births in {ultimo[0]?.anio} · {formatNumber(primero[0]?.tasa_natalidad, 1)} in {primero[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Children per woman"
        value={ultimo[0]?.fecundidad}
        formattedValue={formatNumber(ultimo[0]?.fecundidad, 2)}
        period="{ultimo[0]?.anio} · {formatNumber(ultimo[0]?.fecundidad_espanolas, 2)} for Spanish women and {formatNumber(ultimo[0]?.fecundidad_extranjeras, 2)} for foreign women"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Mothers' mean age"
        value={ultimo[0]?.edad_maternidad}
        formattedValue="{formatNumber(ultimo[0]?.edad_maternidad, 1)} years"
        period="{formatNumber(ultimo[0]?.edad_primer_hijo, 1)} at first child, {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.edad_maternidad}))}
    />
    <KpiCard
        title="Births to foreign mothers"
        value={ultimo[0]?.pct_madre_extranjera}
        formattedValue="{formatNumber(ultimo[0]?.pct_madre_extranjera, 1)}%"
        period="of births in {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.filter(d => d.pct_madre_extranjera !== null).map(d => ({anio: d.anio, valor: d.pct_madre_extranjera}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('fecundidad')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'fecundidad')} />


<p class="text-xs text-gray-500">Rates are calculated on the average population for the year. The total fertility rate is the average number of children a woman would have over her lifetime if that year's age-specific fertility rates remained constant; around 2.1 is needed for a population to sustain itself without migration.</p>

## Births and deaths

Since {primero[0]?.anio} the birth rate has fallen from {formatNumber(primero[0]?.tasa_natalidad, 1)} to {formatNumber(ultimo[0]?.tasa_natalidad, 1)} births per 1,000 inhabitants. More people have died than been born every year since {vegetativo_negativo[0]?.desde}.

```sql tasas
SELECT anio, 'Nacimientos' AS fenomeno, tasa_natalidad AS por_1000 FROM ${anual}
UNION ALL
SELECT anio, 'Defunciones', tasa_mortalidad FROM ${anual}
ORDER BY anio
```

<Grid cols=2>
    <LineChart
        data={tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="per 1,000 inhabitants"
        title="Births and deaths per 1,000 inhabitants"
    />
    <BarChart
        data={anual}
        x=anio
        y=vegetativo_1000
        yFmt=num1
        xFmt="####"
        fillColor="#be185d"
        yAxisTitle="per 1,000 inhabitants"
        title="Natural change (births minus deaths) per 1,000 inhab."
    />
</Grid>

<p class="text-xs text-gray-500">The spike in deaths in 2020 corresponds to the COVID-19 pandemic. In absolute terms, in {ultimo[0]?.anio} there were {formatNumber(ultimo[0]?.nacimientos, 0)} births and {formatNumber(ultimo[0]?.defunciones, 0)} deaths among residents of Spain; the highest number of births this century was in {ultimo[0]?.anio_pico}, with {formatNumber(ultimo[0]?.nacimientos_pico, 0)}.</p>

## Children per woman

```sql fecundidad_nac
SELECT anio, 'Total' AS madre, fecundidad AS hijos FROM ${anual}
UNION ALL
SELECT anio, 'Madres españolas', fecundidad_espanolas FROM ${anual} WHERE fecundidad_espanolas IS NOT NULL
UNION ALL
SELECT anio, 'Madres extranjeras', fecundidad_extranjeras FROM ${anual} WHERE fecundidad_extranjeras IS NOT NULL
ORDER BY anio
```

```sql edad_madres
SELECT anio, 'Todos los hijos' AS hijo, edad_maternidad AS edad FROM ${anual}
UNION ALL
SELECT anio, 'Primer hijo', edad_primer_hijo FROM ${anual}
ORDER BY anio
```

<Grid cols=2>
    <LineChart
        data={fecundidad_nac}
        x=anio
        y=hijos
        series=madre
        yFmt=num2
        xFmt="####"
        colorPalette={['#1e293b', '#db2777', '#0f766e']}
        yAxisTitle="children per woman"
        title="Total fertility rate by mother's nationality"
    >
        <ReferenceLine y=2.1 label="Replacement (2.1)" color="#94a3b8" />
    </LineChart>
    <LineChart
        data={edad_madres}
        x=anio
        y=edad
        series=hijo
        yFmt=num1
        xFmt="####"
        colorPalette={['#7c3aed', '#c4b5fd']}
        yAxisTitle="years"
        yMin=24
        title="Mean age at motherhood"
    />
</Grid>

<p class="text-xs text-gray-500">Fertility by nationality starts in 2002. In {ultimo[0]?.anio} each woman had an average of {formatNumber(ultimo[0]?.fecundidad, 2)} children, compared with {formatNumber(primero[0]?.fecundidad, 2)} in {primero[0]?.anio}; the highest value since 1990 was {formatNumber(ultimo[0]?.icf_max, 2)} in {ultimo[0]?.anio_icf_max}. The mean age at first child has risen from {formatNumber(primero[0]?.edad_primer_hijo, 1)} to {formatNumber(ultimo[0]?.edad_primer_hijo, 1)} years.</p>

```sql madre_extranjera
SELECT anio, pct_madre_extranjera / 100 AS cuota FROM ${anual} WHERE pct_madre_extranjera IS NOT NULL
```

<LineChart
    data={madre_extranjera}
    x=anio
    y=cuota
    yFmt=pct0
    xFmt="####"
    lineColor="#0f766e"
    title="Births to foreign mothers, as % of total"
/>

<p class="text-xs text-gray-500">Based on the mother's nationality at the time of birth; a mother born abroad who already holds Spanish nationality counts as Spanish.</p>

## By autonomous community

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad,
    a.edad_maternidad, a.pct_madre_extranjera / 100 AS madre_extranjera, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.fecundidad DESC
```

<Grid cols=2>
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="fecundidad"
        valueFmt="num2"
        link="ruta"
        colorPalette={['#fdf2f8', '#f472b6', '#9d174d']}
        height={400}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
        title="Children per woman, {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'fecundidad', title: 'Children per woman', fmt: 'num2'},
            {id: 'tasa_natalidad', title: 'Births per 1,000 inhab.', fmt: 'num1'},
            {id: 'edad_maternidad', title: "Mother's mean age", fmt: 'num1'}
        ]}
    />
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="vegetativo_1000"
        valueFmt="num1"
        link="ruta"
        colorPalette={['#b91c1c', '#f8fafc', '#15803d']}
        height={400}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
        title="Births minus deaths per 1,000 inhab., {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'vegetativo_1000', title: 'Natural change per 1,000 inhab.', fmt: 'num1'},
            {id: 'tasa_natalidad', title: 'Births per 1,000 inhab.', fmt: 'num1'},
            {id: 'tasa_mortalidad', title: 'Deaths per 1,000 inhab.', fmt: 'num1'}
        ]}
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=fecundidad title="Children per woman" fmt=num2 contentType=bar barColor="#fbcfe8" />
    <Column id=tasa_natalidad title="Births per 1,000 inhab." fmt=num1 />
    <Column id=tasa_mortalidad title="Deaths per 1,000 inhab." fmt=num1 />
    <Column id=vegetativo_1000 title="Natural change per 1,000 inhab." fmt=num1 contentType=delta />
    <Column id=edad_maternidad title="Mother's mean age" fmt=num1 />
    <Column id=madre_extranjera title="Foreign mother" fmt=pct1 />
    <Column id=nacimientos title="Births" fmt=num0 />
</DataTable>

## By province

```sql provincias
SELECT a.cod AS cod_prov, t.nombre AS provincia, '/en' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad, a.edad_maternidad, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = a.cod
WHERE a.nivel = 'provincia' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.tasa_natalidad DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE vegetativo_1000 < 0) AS negativas, count(*) AS total,
    arg_max(provincia, tasa_natalidad) AS max_prov, max(tasa_natalidad) AS max_tasa,
    arg_min(provincia, tasa_natalidad) AS min_prov, min(tasa_natalidad) AS min_tasa
FROM ${provincias}
```

In {ultimo[0]?.anio}, {provincias_resumen[0]?.negativas} of the {provincias_resumen[0]?.total} provinces recorded more deaths than births. The birth rate ranges from {formatNumber(provincias_resumen[0]?.max_tasa, 1)} births per 1,000 inhabitants in {provincias_resumen[0]?.max_prov} to {formatNumber(provincias_resumen[0]?.min_tasa, 1)} in {provincias_resumen[0]?.min_prov}.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="tasa_natalidad"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#fdf2f8', '#f472b6', '#9d174d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    title="Births per 1,000 inhabitants in each province, {ultimo[0]?.anio}"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_natalidad', title: 'Births per 1,000 inhab.', fmt: 'num1'},
        {id: 'tasa_mortalidad', title: 'Deaths per 1,000 inhab.', fmt: 'num1'},
        {id: 'fecundidad', title: 'Children per woman', fmt: 'num2'},
        {id: 'nacimientos', title: 'Births', fmt: 'num0'}
    ]}
/>

---

## Sources and notes

- **[INE – Basic Demographic Indicators](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: crude birth rate (tables [1470](https://www.ine.es/jaxiT3/Tabla.htm?t=1470) and [1432](https://www.ine.es/jaxiT3/Tabla.htm?t=1432)) and crude death rate ([1482](https://www.ine.es/jaxiT3/Tabla.htm?t=1482) and [1445](https://www.ine.es/jaxiT3/Tabla.htm?t=1445)), total fertility rate ([1478](https://www.ine.es/jaxiT3/Tabla.htm?t=1478) and [1441](https://www.ine.es/jaxiT3/Tabla.htm?t=1441)), mean age at motherhood ([1581](https://www.ine.es/jaxiT3/Tabla.htm?t=1581) and [1580](https://www.ine.es/jaxiT3/Tabla.htm?t=1580)) and births by mother's nationality ([2777](https://www.ine.es/jaxiT3/Tabla.htm?t=2777)).
- **[INE – Vital Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: births by mother's residence ([6524](https://www.ine.es/jaxiT3/Tabla.htm?t=6524)) and deaths by residence ([6561](https://www.ine.es/jaxiT3/Tabla.htm?t=6561)). Final data; the latest year published is {ultimo[0]?.anio}.
- Natural change per 1,000 inhab. = birth rate minus death rate.

<LastRefreshed prefix="Data updated" />
