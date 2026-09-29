---
title: Observatorios públicos
description: "Censo de los observatorios públicos de España: cuántos hay, qué administración los crea, cuándo nacieron, cuántos siguen activos y cuántos hay por habitante en cada comunidad."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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
    t.ruta,
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
    coalesce(comunidad, '') AS comunidad,
    anio_creacion,
    estado,
    tipo
FROM mother.observatorios_detalle
ORDER BY nombre
```

# 🔍 Observatorios públicos

Las administraciones crean observatorios para seguir un tema (la violencia de género, la vivienda, el cambio climático, el comercio...) y publicar informes sobre él. Esta página resume el censo que mantiene [observatoriospublicos.es](https://observatoriospublicos.es/): cuántos hay, quién los crea, cuándo nacieron y si siguen activos.

<Grid cols=4>
    <KpiCard
        title="Observatorios censados"
        value={resumen[0]?.total}
        formattedValue={formatNumber(resumen[0]?.total, 0)}
        period="{formatNumber(resumen[0]?.estatales, 0)} de la Administración General del Estado"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.acumulados)}
    />
    <KpiCard
        title="Activos"
        value={resumen[0]?.pct_activos}
        formattedValue="{formatNumber(resumen[0]?.pct_activos, 0)} %"
        period="{formatNumber(resumen[0]?.activos, 0)} confirmados · {formatNumber(resumen[0]?.inactivos, 0)} cerrados · {formatNumber(resumen[0]?.sin_info, 0)} sin información"
        source="observatoriospublicos.es"
    />
    <KpiCard
        title="Creados desde 2015"
        value={resumen[0]?.pct_desde_2015}
        formattedValue="{formatNumber(resumen[0]?.pct_desde_2015, 0)} %"
        period="{formatNumber(resumen[0]?.desde_2015, 0)} de los {formatNumber(resumen[0]?.con_anio, 0)} con año de creación conocido"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.creados)}
    />
    <KpiCard
        title="Con participación privada"
        value={resumen[0]?.mixtos}
        formattedValue="{formatNumber(resumen[0]?.mixtos / resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(resumen[0]?.mixtos, 0)} observatorios mixtos (público-privados)"
        source="observatoriospublicos.es"
    />
</Grid>

## Cuándo se crearon

Observatorios creados cada año y total acumulado. Solo {formatNumber(resumen[0]?.con_anio, 0)} de los {formatNumber(resumen[0]?.total, 0)} tienen fecha de creación en el censo, así que las barras se quedan cortas. Entre los que tienen fecha, el {formatNumber(resumen[0]?.pct_desde_2015, 0)} % nació en 2015 o después (los más recientes también suelen tener la fecha mejor documentada).

<BarChart
    data={por_anio}
    x=anio
    y=creados
    y2=acumulados
    y2SeriesType=line
    xFmt='0'
    yAxisTitle="Creados en el año"
    y2AxisTitle="Acumulados"
    title="Observatorios públicos creados por año (con fecha conocida)"
/>

## Quién los crea y cuántos siguen activos

Por nivel de la administración. El censo solo marca como cerrados {formatNumber(resumen[0]?.inactivos, 0)} observatorios; del total, el {formatNumber(resumen[0]?.pct_sin_info, 0)} % no tiene información sobre si sigue funcionando.

<BarChart
    data={por_nivel}
    x=nivel
    y=observatorios
    series=estado
    swapXY=true
    sort=false
    colorPalette={['#16a34a', '#dc2626', '#94a3b8']}
    title="Observatorios por nivel de la administración y estado"
/>

## Por comunidad autónoma

Observatorios autonómicos, provinciales y locales cuyo ámbito identifica la comunidad, por millón de habitantes (otros {formatNumber(resumen[0]?.sin_comunidad, 0)} observatorios regionales o locales del censo no indican su comunidad y no cuentan aquí).

<AreaMap
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: observatoriospublicos.es"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_millon', title: 'Por millón de hab.', fmt: '0.0'},
        {id: 'observatorios', title: 'Observatorios', fmt: '0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunidad"/>
    <Column id=por_millon title="Por millón de hab." fmt='0.0'/>
    <Column id=observatorios title="Observatorios" fmt='0'/>
    <Column id=activos title="Activos confirmados" fmt='0'/>
</DataTable>

## Todos los observatorios

<DataTable data={listado} rows=15 search=true>
    <Column id=nombre title="Observatorio" wrap=true/>
    <Column id=nivel title="Nivel"/>
    <Column id=comunidad title="Comunidad"/>
    <Column id=anio_creacion title="Creado" fmt='0'/>
    <Column id=estado title="Estado"/>
    <Column id=tipo title="Tipo"/>
</DataTable>

---

**Fuente:** [observatoriospublicos.es](https://observatoriospublicos.es/), censo ciudadano de observatorios de las administraciones públicas españolas. El nivel y la comunidad se deducen del ámbito que indica el censo; el estado "Sin información" significa que el censo no dice si el observatorio sigue activo.
