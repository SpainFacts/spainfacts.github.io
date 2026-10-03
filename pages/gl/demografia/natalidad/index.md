---
title: Natalidade e fecundidade
description: "Nacementos e defuncións por 1.000 habitantes, fillos por muller, idade media das nais e nacementos de nai estranxeira en España, por comunidade e provincia desde 1975 (INE)."
i18n_origen: 07771f420182
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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

# 👶 Natalidade e fecundidade

Cantos nenos nacen en España en relación coa súa poboación, cantos fillos ten de media cada muller, a que idade e cantos nacen de nai estranxeira, xunto coas defuncións que marcan o crecemento natural da poboación.

<Grid cols=4>
    <KpiCard
        title="Taxa de natalidade"
        value={ultimo[0]?.tasa_natalidad}
        formattedValue="{formatNumber(ultimo[0]?.tasa_natalidad, 2)} por 1.000 hab."
        period="{formatNumber(ultimo[0]?.nacimientos, 0)} nacementos en {ultimo[0]?.anio} · {formatNumber(primero[0]?.tasa_natalidad, 1)} en {primero[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Fillos por muller"
        value={ultimo[0]?.fecundidad}
        formattedValue={formatNumber(ultimo[0]?.fecundidad, 2)}
        period="{ultimo[0]?.anio} · {formatNumber(ultimo[0]?.fecundidad_espanolas, 2)} as españolas e {formatNumber(ultimo[0]?.fecundidad_extranjeras, 2)} as estranxeiras"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Idade media das nais"
        value={ultimo[0]?.edad_maternidad}
        formattedValue="{formatNumber(ultimo[0]?.edad_maternidad, 1)} anos"
        period="{formatNumber(ultimo[0]?.edad_primer_hijo, 1)} ao ter o primeiro fillo, {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.edad_maternidad}))}
    />
    <KpiCard
        title="Nacementos de nai estranxeira"
        value={ultimo[0]?.pct_madre_extranjera}
        formattedValue="{formatNumber(ultimo[0]?.pct_madre_extranjera, 1)} %"
        period="dos nados en {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.filter(d => d.pct_madre_extranjera !== null).map(d => ({anio: d.anio, valor: d.pct_madre_extranjera}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('fecundidad')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'fecundidad')} />


<p class="text-xs text-gray-500">As taxas calcúlanse sobre a poboación media do ano. O indicador conxuntural de fecundidade é o número medio de fillos que tería unha muller ao longo da súa vida se se mantivesen as taxas de fecundidade por idade dese ano; para que unha poboación se manteña sen migración fan falta uns 2,1.</p>

## Nacementos e defuncións

Desde {primero[0]?.anio} a taxa de natalidade pasou de {formatNumber(primero[0]?.tasa_natalidad, 1)} a {formatNumber(ultimo[0]?.tasa_natalidad, 1)} nacementos por 1.000 habitantes. Morren máis persoas das que nacen todos os anos desde {vegetativo_negativo[0]?.desde}.

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
        title="Nacementos e defuncións por 1.000 habitantes"
    />
    <BarChart
        data={anual}
        x=anio
        y=vegetativo_1000
        yFmt=num1
        xFmt="####"
        fillColor="#be185d"
        yAxisTitle="por 1.000 habitantes"
        title="Crecemento vexetativo (nacementos menos defuncións) por 1.000 hab."
    />
</Grid>

<p class="text-xs text-gray-500">O pico de defuncións de 2020 corresponde á pandemia de COVID-19. En números absolutos, en {ultimo[0]?.anio} houbo {formatNumber(ultimo[0]?.nacimientos, 0)} nacementos e {formatNumber(ultimo[0]?.defunciones, 0)} defuncións de residentes en España; o máximo de nacementos deste século foi en {ultimo[0]?.anio_pico}, con {formatNumber(ultimo[0]?.nacimientos_pico, 0)}.</p>

## Fillos por muller

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
        yAxisTitle="fillos por muller"
        title="Indicador conxuntural de fecundidade segundo a nacionalidade da nai"
    >
        <ReferenceLine y=2.1 label="Remprazo (2,1)" color="#94a3b8" />
    </LineChart>
    <LineChart
        data={edad_madres}
        x=anio
        y=edad
        series=hijo
        yFmt=num1
        xFmt="####"
        colorPalette={['#7c3aed', '#c4b5fd']}
        yAxisTitle="anos"
        yMin=24
        title="Idade media á maternidade"
    />
</Grid>

<p class="text-xs text-gray-500">A fecundidade por nacionalidade comeza en 2002. En {ultimo[0]?.anio} cada muller tiña de media {formatNumber(ultimo[0]?.fecundidad, 2)} fillos, fronte a {formatNumber(primero[0]?.fecundidad, 2)} en {primero[0]?.anio}; o valor máis alto desde 1990 foi {formatNumber(ultimo[0]?.icf_max, 2)} en {ultimo[0]?.anio_icf_max}. A idade media ao primeiro fillo pasou de {formatNumber(primero[0]?.edad_primer_hijo, 1)} a {formatNumber(ultimo[0]?.edad_primer_hijo, 1)} anos.</p>

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
    title="Nacementos de nai estranxeira, en % do total"
/>

<p class="text-xs text-gray-500">Segundo a nacionalidade da nai no momento do parto; unha nai nada fóra que xa ten a nacionalidade española conta como española.</p>

## Por comunidade autónoma

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad,
    a.edad_maternidad, a.pct_madre_extranjera / 100 AS madre_extranjera, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.fecundidad DESC
```

<Grid cols=2>
    <MapaEspana
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
        attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        title="Fillos por muller, {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'fecundidad', title: 'Fillos por muller', fmt: 'num2'},
            {id: 'tasa_natalidad', title: 'Nacementos por 1.000 hab.', fmt: 'num1'},
            {id: 'edad_maternidad', title: 'Idade media da nai', fmt: 'num1'}
        ]}
    />
    <MapaEspana
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
        attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        title="Nacementos menos defuncións por 1.000 hab., {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'vegetativo_1000', title: 'Crecemento vexetativo por 1.000 hab.', fmt: 'num1'},
            {id: 'tasa_natalidad', title: 'Nacementos por 1.000 hab.', fmt: 'num1'},
            {id: 'tasa_mortalidad', title: 'Defuncións por 1.000 hab.', fmt: 'num1'}
        ]}
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=fecundidad title="Fillos por muller" fmt=num2 contentType=bar barColor="#fbcfe8" />
    <Column id=tasa_natalidad title="Nacementos por 1.000 hab." fmt=num1 />
    <Column id=tasa_mortalidad title="Defuncións por 1.000 hab." fmt=num1 />
    <Column id=vegetativo_1000 title="Vexetativo por 1.000 hab." fmt=num1 contentType=delta />
    <Column id=edad_maternidad title="Idade media nai" fmt=num1 />
    <Column id=madre_extranjera title="Nai estranxeira" fmt=pct1 />
    <Column id=nacimientos title="Nacementos" fmt=num0 />
</DataTable>

## Por provincia

```sql provincias
SELECT a.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta,
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

En {ultimo[0]?.anio}, {provincias_resumen[0]?.negativas} das {provincias_resumen[0]?.total} provincias tiveron máis defuncións ca nacementos. A natalidade vai de {formatNumber(provincias_resumen[0]?.max_tasa, 1)} nacementos por 1.000 habitantes en {provincias_resumen[0]?.max_prov} a {formatNumber(provincias_resumen[0]?.min_tasa, 1)} en {provincias_resumen[0]?.min_prov}.

<MapaEspana
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Nacementos por 1.000 habitantes en cada provincia, {ultimo[0]?.anio}"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_natalidad', title: 'Nacementos por 1.000 hab.', fmt: 'num1'},
        {id: 'tasa_mortalidad', title: 'Defuncións por 1.000 hab.', fmt: 'num1'},
        {id: 'fecundidad', title: 'Fillos por muller', fmt: 'num2'},
        {id: 'nacimientos', title: 'Nacementos', fmt: 'num0'}
    ]}
/>

---

## Fontes e notas

- **[INE – Indicadores Demográficos Básicos](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: taxa bruta de natalidade (táboas [1470](https://www.ine.es/jaxiT3/Tabla.htm?t=1470) e [1432](https://www.ine.es/jaxiT3/Tabla.htm?t=1432)) e de mortalidade ([1482](https://www.ine.es/jaxiT3/Tabla.htm?t=1482) e [1445](https://www.ine.es/jaxiT3/Tabla.htm?t=1445)), indicador conxuntural de fecundidade ([1478](https://www.ine.es/jaxiT3/Tabla.htm?t=1478) e [1441](https://www.ine.es/jaxiT3/Tabla.htm?t=1441)), idade media á maternidade ([1581](https://www.ine.es/jaxiT3/Tabla.htm?t=1581) e [1580](https://www.ine.es/jaxiT3/Tabla.htm?t=1580)) e nados segundo a nacionalidade da nai ([2777](https://www.ine.es/jaxiT3/Tabla.htm?t=2777)).
- **[INE – Movemento Natural da Poboación](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: nacementos por residencia da nai ([6524](https://www.ine.es/jaxiT3/Tabla.htm?t=6524)) e defuncións por residencia ([6561](https://www.ine.es/jaxiT3/Tabla.htm?t=6561)). Datos definitivos; o último ano publicado é {ultimo[0]?.anio}.
- Crecemento vexetativo por 1.000 hab. = taxa de natalidade menos taxa de mortalidade.

<LastRefreshed prefix="Datos actualizados" />
