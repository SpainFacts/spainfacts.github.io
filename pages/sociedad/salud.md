---
title: Salud
description: "Esperanza de vida en España por comunidad y provincia, de qué se muere la gente, suicidios, accidentes de tráfico y exceso de mortalidad semana a semana."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql ev_espana
SELECT anio, sexo, anios
FROM mother.salud_esperanza_vida
WHERE nivel = 'pais'
ORDER BY anio
```

```sql ev_ultimo
SELECT
    max(anio) AS anio,
    max(anios) FILTER (WHERE sexo = 'Ambos sexos') AS total,
    max(anios) FILTER (WHERE sexo = 'Mujeres') AS mujeres,
    max(anios) FILTER (WHERE sexo = 'Hombres') AS hombres
FROM ${ev_espana}
WHERE anio = (SELECT max(anio) FROM ${ev_espana})
```

```sql ev_serie
SELECT anio, anios AS valor FROM ${ev_espana} WHERE sexo = 'Ambos sexos' AND anio >= 2000 ORDER BY anio
```

```sql causas_clave
SELECT anio, codigo_causa, defunciones, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND codigo_causa IN ('001-102', '098', '090', '099')
ORDER BY anio
```

```sql causas_ultimo
SELECT
    max(anio) AS anio,
    max(defunciones) FILTER (WHERE codigo_causa = '001-102') AS total,
    max(defunciones) FILTER (WHERE codigo_causa = '098') AS suicidios,
    max(tasa_100k) FILTER (WHERE codigo_causa = '098') AS suicidios_tasa,
    max(defunciones) FILTER (WHERE codigo_causa = '090') AS trafico
FROM ${causas_clave}
WHERE anio = (SELECT max(anio) FROM ${causas_clave})
```

```sql exceso_anual
SELECT anio, sum(defunciones) AS defunciones, sum(defunciones) / sum(media_2015_2019) - 1 AS exceso, count(*) AS semanas
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND anio >= 2015
GROUP BY anio
ORDER BY anio
```

# 🩺 Salud

Cuánto vivimos, de qué morimos y cómo han cambiado las cosas, con las estadísticas vitales del INE.

<Grid cols=4>
    <KpiCard
        title="Esperanza de vida al nacer"
        value={ev_ultimo[0]?.total}
        formattedValue="{formatNumber(ev_ultimo[0]?.total, 1)} años"
        period="mujeres {formatNumber(ev_ultimo[0]?.mujeres, 1)} · hombres {formatNumber(ev_ultimo[0]?.hombres, 1)} · {ev_ultimo[0]?.anio}"
        source="INE / Eurostat"
        sparklineData={ev_serie}
    />
    <KpiCard
        title="Defunciones"
        value={causas_ultimo[0]?.total}
        formattedValue={formatNumber(causas_ultimo[0]?.total, 0)}
        period="en {causas_ultimo[0]?.anio}"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '001-102' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.defunciones}))}
    />
    <KpiCard
        title="Suicidios"
        value={causas_ultimo[0]?.suicidios}
        formattedValue={formatNumber(causas_ultimo[0]?.suicidios, 0)}
        period="{formatNumber(causas_ultimo[0]?.suicidios_tasa, 1)} por 100.000 habitantes · primera causa externa de muerte"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '098' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.defunciones}))}
    />
    <KpiCard
        title="Muertos en accidentes de tráfico"
        value={causas_ultimo[0]?.trafico}
        formattedValue={formatNumber(causas_ultimo[0]?.trafico, 0)}
        period="residentes en España fallecidos en {causas_ultimo[0]?.anio}"
        source="INE"
        direction="positive-down"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '090' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.defunciones}))}
    />
</Grid>

<p class="text-xs text-gray-500">Si necesitas ayuda o conoces a alguien que pueda necesitarla, llama al <b>024</b>, la línea de atención a la conducta suicida (gratuita, confidencial, 24 horas).</p>

## Cuánto vivimos

<LineChart
    data={ev_espana}
    x=anio
    y=anios
    series=sexo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#1d4ed8', '#be185d']}
    yAxisTitle="años"
    title="Esperanza de vida al nacer en España"
/>

<p class="text-xs text-gray-500">La caída de 2020 es la pandemia de COVID-19 (más de un año de esperanza de vida perdido); no se recuperó el nivel de 2019 hasta 2023. España está entre los países con mayor esperanza de vida del mundo.</p>

```sql ev_provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, e.anios
FROM mother.salud_esperanza_vida e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.sexo = 'Ambos sexos'
  AND e.anio = (SELECT max(anio) FROM mother.salud_esperanza_vida WHERE nivel = 'provincia')
ORDER BY e.anios DESC
```

<AreaMap
    data={ev_provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="anios"
    valueFmt="num1"
    colorPalette={['#fef3c7', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'anios', title: 'Esperanza de vida (años)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Esperanza de vida al nacer por provincia de residencia en {ev_ultimo[0]?.anio}. Las más altas están en Madrid y el interior norte; las más bajas, en el sur, Canarias, Ceuta y Melilla.</p>

## De qué morimos

```sql capitulos
SELECT causa, defunciones
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND es_capitulo AND codigo_causa <> '001-102'
  AND anio = (SELECT max(anio) FROM mother.salud_causas_muerte)
ORDER BY defunciones DESC
LIMIT 10
```

<BarChart
    data={capitulos}
    x=causa
    y=defunciones
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Defunciones por grandes grupos de causas ({causas_ultimo[0]?.anio})"
/>

```sql evolucion_capitulos
SELECT anio, causa, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND codigo_causa IN ('009-041', '053-061', '062-067', '046-049', '090-102')
  AND anio >= 2000
ORDER BY anio
```

<LineChart
    data={evolucion_capitulos}
    x=anio
    y=tasa_100k
    series=causa
    yFmt=num0
    xFmt="####"
    legend=true
    yAxisTitle="por 100.000 habitantes"
    title="Principales causas de muerte desde 2000 (tasa bruta)"
/>

<p class="text-xs text-gray-500">En 2024, por primera vez, los tumores superaron a las enfermedades del corazón y los vasos sanguíneos como primera causa de muerte. Los trastornos mentales crecen sobre todo por las demencias (alzhéimer y otras), ligadas al envejecimiento. Tasas brutas: con una población cada vez más mayor, suben aunque la probabilidad de morir a cada edad baje.</p>

## Suicidios, tráfico y homicidios

```sql externas
SELECT anio,
    CASE codigo_causa WHEN '098' THEN 'Suicidios' WHEN '090' THEN 'Accidentes de tráfico' WHEN '099' THEN 'Homicidios' END AS causa,
    defunciones
FROM ${causas_clave}
WHERE codigo_causa IN ('098', '090', '099') AND anio >= 1990
ORDER BY anio
```

<LineChart
    data={externas}
    x=anio
    y=defunciones
    series=causa
    yFmt=num0
    xFmt="####"
    legend=true
    colorPalette={['#f59e0b', '#7c3aed', '#b91c1c']}
    title="Muertes por suicidio, accidentes de tráfico y homicidio"
/>

<p class="text-xs text-gray-500">Desde 2008 mueren en España más personas por suicidio que en accidentes de tráfico, que han caído a menos de un tercio desde 2000. Cifras por residencia del fallecido y según la causa del certificado de defunción (los muertos en carretera de la DGT, contados a 30 días, son algo distintos).</p>

```sql suicidio_ccaa
SELECT c.cod, t.nombre AS comunidad, t.ruta,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Total') AS tasa,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Hombres') AS tasa_hombres,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Mujeres') AS tasa_mujeres,
    max(c.defunciones) FILTER (WHERE c.sexo = 'Total') AS defunciones
FROM mother.salud_causas_muerte c
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod
WHERE c.nivel = 'ccaa' AND c.codigo_causa = '098' AND c.anio = (SELECT max(anio) FROM mother.salud_causas_muerte)
GROUP BY ALL
ORDER BY tasa DESC
```

<DataTable data={suicidio_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=defunciones title="Suicidios" fmt=num0 />
    <Column id=tasa title="Por 100.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=tasa_hombres title="Hombres" fmt=num1 />
    <Column id=tasa_mujeres title="Mujeres" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Tres de cada cuatro suicidios son de hombres. Las tasas más altas se dan en el noroeste (Asturias, Galicia), con población más envejecida.</p>

## Exceso de mortalidad

<BarChart
    data={exceso_anual}
    x=anio
    y=exceso
    yFmt=pct0
    xFmt="####"
    fillColor="#b91c1c"
    title="Muertes de cada año frente a la media de 2015-2019"
/>

```sql semanal
SELECT semana, defunciones, media_2015_2019
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND semana >= (SELECT max(semana) FROM mother.salud_mortalidad_semanal) - INTERVAL 3 YEAR
ORDER BY semana
```

<LineChart
    data={semanal}
    x=semana
    y={['defunciones', 'media_2015_2019']}
    yFmt=num0
    seriesLabels={{defunciones: 'Defunciones', media_2015_2019: 'Media de la misma semana en 2015-2019'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Defunciones semana a semana (últimos tres años)"
/>

<p class="text-xs text-gray-500">La comparación con 2015-2019 es sencilla y no corrige que la población es cada año mayor y más numerosa, así que desde 2023 parte del "exceso" es simplemente envejecimiento. Los picos coinciden con las olas de gripe en invierno y con las olas de calor (ver <a href="/energia-clima/calor">Calor</a>). Las últimas semanas pueden estar incompletas.</p>

---

## Fuentes y notas

- **[INE – Indicadores demográficos básicos](https://www.ine.es/jaxiT3/Tabla.htm?t=1448)**: esperanza de vida al nacer por comunidad (tabla 1448) y provincia (1485); **[Eurostat – demo_mlexpec](https://ec.europa.eu/eurostat/databrowser/view/demo_mlexpec/default/table)** para el total de España.
- **[INE – Defunciones según la causa de muerte](https://www.ine.es/jaxiT3/Tabla.htm?t=9936)** (tabla 9936, lista reducida de causas por provincia de residencia, desde 1980; el último año publicado es definitivo con un año de retraso).
- **[INE – Estimación de Defunciones Semanales (EDeS)](https://www.ine.es/jaxiT3/Tabla.htm?t=35177)** (tabla 35177): defunciones por semana y comunidad.
- El gasto sanitario público está en [Gastos públicos](/cuentas-publicas/gastos).

<LastRefreshed prefix="Datos actualizados" />
