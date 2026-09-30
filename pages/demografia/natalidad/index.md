---
title: Natalidad y fecundidad
description: "Nacimientos y defunciones por 1.000 habitantes, hijos por mujer, edad media de las madres y nacimientos de madre extranjera en España, por comunidad y provincia desde 1975 (INE)."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 👶 Natalidad y fecundidad

Cuántos niños nacen en España en relación con su población, cuántos hijos tiene de media cada mujer, a qué edad y cuántos nacen de madre extranjera, junto con las defunciones que marcan el crecimiento natural de la población.

<Grid cols=4>
    <KpiCard
        title="Tasa de natalidad"
        value={ultimo[0]?.tasa_natalidad}
        formattedValue="{formatNumber(ultimo[0]?.tasa_natalidad, 2)} por 1.000 hab."
        period="{formatNumber(ultimo[0]?.nacimientos, 0)} nacimientos en {ultimo[0]?.anio} · {formatNumber(primero[0]?.tasa_natalidad, 1)} en {primero[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Hijos por mujer"
        value={ultimo[0]?.fecundidad}
        formattedValue={formatNumber(ultimo[0]?.fecundidad, 2)}
        period="{ultimo[0]?.anio} · {formatNumber(ultimo[0]?.fecundidad_espanolas, 2)} las españolas y {formatNumber(ultimo[0]?.fecundidad_extranjeras, 2)} las extranjeras"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Edad media de las madres"
        value={ultimo[0]?.edad_maternidad}
        formattedValue="{formatNumber(ultimo[0]?.edad_maternidad, 1)} años"
        period="{formatNumber(ultimo[0]?.edad_primer_hijo, 1)} al tener el primer hijo, {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.edad_maternidad}))}
    />
    <KpiCard
        title="Nacimientos de madre extranjera"
        value={ultimo[0]?.pct_madre_extranjera}
        formattedValue="{formatNumber(ultimo[0]?.pct_madre_extranjera, 1)} %"
        period="de los nacidos en {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.filter(d => d.pct_madre_extranjera !== null).map(d => ({anio: d.anio, valor: d.pct_madre_extranjera}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('fecundidad')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'fecundidad')} />


<p class="text-xs text-gray-500">Las tasas se calculan sobre la población media del año. El indicador coyuntural de fecundidad es el número medio de hijos que tendría una mujer a lo largo de su vida si se mantuvieran las tasas de fecundidad por edad de ese año; para que una población se mantenga sin migración hacen falta unos 2,1.</p>

## Nacimientos y defunciones

Desde {primero[0]?.anio} la tasa de natalidad ha pasado de {formatNumber(primero[0]?.tasa_natalidad, 1)} a {formatNumber(ultimo[0]?.tasa_natalidad, 1)} nacimientos por 1.000 habitantes. Mueren más personas de las que nacen todos los años desde {vegetativo_negativo[0]?.desde}.

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
        yAxisTitle="por 1.000 habitantes"
        title="Nacimientos y defunciones por 1.000 habitantes"
    />
    <BarChart
        data={anual}
        x=anio
        y=vegetativo_1000
        yFmt=num1
        xFmt="####"
        fillColor="#be185d"
        yAxisTitle="por 1.000 habitantes"
        title="Crecimiento vegetativo (nacimientos menos defunciones) por 1.000 hab."
    />
</Grid>

<p class="text-xs text-gray-500">El pico de defunciones de 2020 corresponde a la pandemia de COVID-19. En números absolutos, en {ultimo[0]?.anio} hubo {formatNumber(ultimo[0]?.nacimientos, 0)} nacimientos y {formatNumber(ultimo[0]?.defunciones, 0)} defunciones de residentes en España; el máximo de nacimientos de este siglo fue en {ultimo[0]?.anio_pico}, con {formatNumber(ultimo[0]?.nacimientos_pico, 0)}.</p>

## Hijos por mujer

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
        yAxisTitle="hijos por mujer"
        title="Indicador coyuntural de fecundidad según la nacionalidad de la madre"
    >
        <ReferenceLine y=2.1 label="Reemplazo (2,1)" color="#94a3b8" />
    </LineChart>
    <LineChart
        data={edad_madres}
        x=anio
        y=edad
        series=hijo
        yFmt=num1
        xFmt="####"
        colorPalette={['#7c3aed', '#c4b5fd']}
        yAxisTitle="años"
        yMin=24
        title="Edad media a la maternidad"
    />
</Grid>

<p class="text-xs text-gray-500">La fecundidad por nacionalidad empieza en 2002. En {ultimo[0]?.anio} cada mujer tenía de media {formatNumber(ultimo[0]?.fecundidad, 2)} hijos, frente a {formatNumber(primero[0]?.fecundidad, 2)} en {primero[0]?.anio}; el valor más alto desde 1990 fue {formatNumber(ultimo[0]?.icf_max, 2)} en {ultimo[0]?.anio_icf_max}. La edad media al primer hijo ha pasado de {formatNumber(primero[0]?.edad_primer_hijo, 1)} a {formatNumber(ultimo[0]?.edad_primer_hijo, 1)} años.</p>

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
    title="Nacimientos de madre extranjera, en % del total"
/>

<p class="text-xs text-gray-500">Según la nacionalidad de la madre en el momento del parto; una madre nacida fuera que ya tiene la nacionalidad española cuenta como española.</p>

## Por comunidad autónoma

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, t.ruta,
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
        attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        title="Hijos por mujer, {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'fecundidad', title: 'Hijos por mujer', fmt: 'num2'},
            {id: 'tasa_natalidad', title: 'Nacimientos por 1.000 hab.', fmt: 'num1'},
            {id: 'edad_maternidad', title: 'Edad media de la madre', fmt: 'num1'}
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
        attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        title="Nacimientos menos defunciones por 1.000 hab., {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'vegetativo_1000', title: 'Crecimiento vegetativo por 1.000 hab.', fmt: 'num1'},
            {id: 'tasa_natalidad', title: 'Nacimientos por 1.000 hab.', fmt: 'num1'},
            {id: 'tasa_mortalidad', title: 'Defunciones por 1.000 hab.', fmt: 'num1'}
        ]}
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=fecundidad title="Hijos por mujer" fmt=num2 contentType=bar barColor="#fbcfe8" />
    <Column id=tasa_natalidad title="Nacimientos por 1.000 hab." fmt=num1 />
    <Column id=tasa_mortalidad title="Defunciones por 1.000 hab." fmt=num1 />
    <Column id=vegetativo_1000 title="Vegetativo por 1.000 hab." fmt=num1 contentType=delta />
    <Column id=edad_maternidad title="Edad media madre" fmt=num1 />
    <Column id=madre_extranjera title="Madre extranjera" fmt=pct1 />
    <Column id=nacimientos title="Nacimientos" fmt=num0 />
</DataTable>

## Por provincia

```sql provincias
SELECT a.cod AS cod_prov, t.nombre AS provincia, t.ruta,
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

En {ultimo[0]?.anio}, {provincias_resumen[0]?.negativas} de las {provincias_resumen[0]?.total} provincias tuvieron más defunciones que nacimientos. La natalidad va de {formatNumber(provincias_resumen[0]?.max_tasa, 1)} nacimientos por 1.000 habitantes en {provincias_resumen[0]?.max_prov} a {formatNumber(provincias_resumen[0]?.min_tasa, 1)} en {provincias_resumen[0]?.min_prov}.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Nacimientos por 1.000 habitantes en cada provincia, {ultimo[0]?.anio}"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_natalidad', title: 'Nacimientos por 1.000 hab.', fmt: 'num1'},
        {id: 'tasa_mortalidad', title: 'Defunciones por 1.000 hab.', fmt: 'num1'},
        {id: 'fecundidad', title: 'Hijos por mujer', fmt: 'num2'},
        {id: 'nacimientos', title: 'Nacimientos', fmt: 'num0'}
    ]}
/>

---

## Fuentes y notas

- **[INE – Indicadores Demográficos Básicos](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: tasa bruta de natalidad (tablas [1470](https://www.ine.es/jaxiT3/Tabla.htm?t=1470) y [1432](https://www.ine.es/jaxiT3/Tabla.htm?t=1432)) y de mortalidad ([1482](https://www.ine.es/jaxiT3/Tabla.htm?t=1482) y [1445](https://www.ine.es/jaxiT3/Tabla.htm?t=1445)), indicador coyuntural de fecundidad ([1478](https://www.ine.es/jaxiT3/Tabla.htm?t=1478) y [1441](https://www.ine.es/jaxiT3/Tabla.htm?t=1441)), edad media a la maternidad ([1581](https://www.ine.es/jaxiT3/Tabla.htm?t=1581) y [1580](https://www.ine.es/jaxiT3/Tabla.htm?t=1580)) y nacidos según la nacionalidad de la madre ([2777](https://www.ine.es/jaxiT3/Tabla.htm?t=2777)).
- **[INE – Movimiento Natural de la Población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: nacimientos por residencia de la madre ([6524](https://www.ine.es/jaxiT3/Tabla.htm?t=6524)) y defunciones por residencia ([6561](https://www.ine.es/jaxiT3/Tabla.htm?t=6561)). Datos definitivos; el último año publicado es {ultimo[0]?.anio}.
- Crecimiento vegetativo por 1.000 hab. = tasa de natalidad menos tasa de mortalidad.

<LastRefreshed prefix="Datos actualizados" />
