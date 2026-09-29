---
title: Obra nueva
description: "Viviendas libres que se empiezan y se terminan cada año en España por 1.000 habitantes desde 1996, por comunidad y provincia, con datos del Ministerio de Vivienda."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
SELECT o.cod, o.nombre AS comunidad, t.ruta, o.anio, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas,
       (SELECT avg(x.terminadas_1000) FROM mother.vivienda_obra_nueva x WHERE x.nivel = 'ccaa' AND x.cod = o.cod AND x.anio BETWEEN o.anio - 4 AND o.anio) AS terminadas_1000_5a
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = o.cod
WHERE o.nivel = 'ccaa' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

```sql provincias
SELECT o.cod AS cod_prov, o.nombre AS provincia, t.ruta, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = o.cod
WHERE o.nivel = 'provincia' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

# 🏗️ Obra nueva

Cuántas viviendas se construyen en España. Son **viviendas libres** (sin la protegida) que se empiezan (**iniciadas**) y se acaban (**terminadas**) cada año, estimadas por el Ministerio de Vivienda a partir de los certificados de los colegios de aparejadores, siempre **por cada 1.000 habitantes**.

<Grid cols=4>
    <KpiCard
        title="Viviendas terminadas"
        value={hitos[0]?.term_ult}
        formattedValue="{formatNumber(hitos[0]?.term_ult, 2)} por 1.000 hab."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.term_total, 0)} viviendas libres"
        source="Ministerio de Vivienda"
        sparklineData={espana.map(d => d.terminadas_1000)}
    />
    <KpiCard
        title="Viviendas iniciadas"
        value={hitos[0]?.ini_ult}
        formattedValue="{formatNumber(hitos[0]?.ini_ult, 2)} por 1.000 hab."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.ini_total, 0)} viviendas libres"
        source="Ministerio de Vivienda"
        sparklineData={espana.map(d => d.iniciadas_1000)}
    />
    <KpiCard
        title="Frente al máximo"
        value={hitos[0]?.fraccion_max}
        formattedValue="{formatNumber(hitos[0]?.fraccion_max / 0.01, 0)} %"
        period="de las viviendas terminadas por habitante en {hitos[0]?.anio_term_max} ({formatNumber(hitos[0]?.term_max, 1)} por 1.000 hab.)"
        source="Ministerio de Vivienda"
        sparklineData={espana.map(d => d.terminadas_1000)}
    />
    <KpiCard
        title="Frente a finales de los 90"
        value={hitos[0]?.media_9600}
        formattedValue="{formatNumber(hitos[0]?.media_9600, 1)} por 1.000 hab."
        period="viviendas terminadas al año de media en 1996-2000"
        source="Ministerio de Vivienda"
        sparklineData={espana.filter(d => d.anio <= 2000).map(d => d.terminadas_1000)}
    />
</Grid>

## Evolución

El máximo de viviendas terminadas por habitante fue en {hitos[0]?.anio_term_max} ({formatNumber(hitos[0]?.term_max, 1)} por 1.000 habitantes) y el mínimo en {hitos[0]?.anio_term_min} ({formatNumber(hitos[0]?.term_min, 2)}). En {hitos[0]?.anio_ult} se terminaron {formatNumber(hitos[0]?.term_ult, 2)} por 1.000 habitantes y se empezaron {formatNumber(hitos[0]?.ini_ult, 2)}.

<LineChart
    data={espana_largo}
    x=anio
    y=por_1000
    series=fase
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Viviendas libres iniciadas y terminadas por 1.000 habitantes"
/>

Las viviendas terminadas se pueden comparar con las compraventas de vivienda nueva que registra el INE (que incluyen también la protegida):

<LineChart
    data={mercado_largo}
    x=anio
    y=por_1000
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Viviendas terminadas y compraventas de vivienda nueva por 1.000 habitantes"
/>

## Por comunidad

Viviendas libres terminadas por 1.000 habitantes en {ccaa[0]?.anio}.

<AreaMap
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'terminadas_1000', title: 'Terminadas por 1.000 hab.', fmt: 'num2'},
        {id: 'iniciadas_1000', title: 'Iniciadas por 1.000 hab.', fmt: 'num2'},
        {id: 'terminadas', title: 'Terminadas', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=terminadas_1000 title="Terminadas por 1.000 hab." fmt='0.00' />
    <Column id=terminadas_1000_5a title="Media 5 años" fmt='0.00' />
    <Column id=iniciadas_1000 title="Iniciadas por 1.000 hab." fmt='0.00' />
    <Column id=terminadas title="Terminadas" fmt='#,##0' />
</DataTable>

## Por provincia

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=terminadas_1000 title="Terminadas por 1.000 hab." fmt='0.00' />
    <Column id=iniciadas_1000 title="Iniciadas por 1.000 hab." fmt='0.00' />
    <Column id=terminadas title="Terminadas" fmt='#,##0' />
    <Column id=iniciadas title="Iniciadas" fmt='#,##0' />
</DataTable>

---

**Fuentes:** [Ministerio de Vivienda y Agenda Urbana, boletín estadístico: viviendas libres iniciadas y terminadas](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000) (tablas 3.1 y 3.2, anuales desde 1991, a partir de los certificados de los colegios de aparejadores; la serie por habitante empieza en 1996, primer año de la población del INE) e [INE, Estadística de Transmisiones de Derechos de la Propiedad](https://www.ine.es/jaxiT3/Tabla.htm?t=6150).
