---
title: Coche eléctrico
description: "Transición al coche eléctrico en España: matriculaciones de turismos por tipo de motor cada mes desde 2015, cuota de eléctricos e híbridos enchufables por provincia y emisiones de CO2."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql mensual
SELECT
    mes,
    energia,
    energia_etiqueta AS motor,
    energia_orden,
    sum(matriculaciones) AS turismos
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY mes, energia_orden
```

```sql cuota_mensual
SELECT
    mes,
    sum(turismos) FILTER (WHERE energia = 'bev') / sum(turismos) AS cuota_bev,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev')) / sum(turismos) AS cuota_enchufables,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev', 'hev')) / sum(turismos) AS cuota_electrificados,
    sum(turismos) AS total
FROM ${mensual}
GROUP BY mes
ORDER BY mes
```

```sql ultimo
SELECT
    c.*,
    strftime(c.mes, '%m/%Y') AS mes_texto,
    a.cuota_enchufables AS cuota_enchufables_anio_antes,
    a.cuota_bev AS cuota_bev_anio_antes
FROM ${cuota_mensual} c
LEFT JOIN ${cuota_mensual} a ON a.mes = c.mes - INTERVAL 12 MONTH
ORDER BY c.mes DESC
LIMIT 1
```

```sql anual
SELECT
    CAST(year(mes) AS INTEGER) AS anio,
    motor,
    energia_orden,
    sum(turismos) AS turismos
FROM ${mensual}
GROUP BY ALL
ORDER BY anio, energia_orden
```

```sql co2
SELECT
    mes,
    sum(co2_medio * matriculaciones) / sum(matriculaciones) AS co2_medio
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N' AND co2_medio IS NOT NULL
GROUP BY mes
ORDER BY mes
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${mensual} ORDER BY energia_orden
```

# ⚡ La transición al coche eléctrico

¿Cuántos de los coches que se venden en España ya son eléctricos? La respuesta sale de los microdatos de la Dirección General de Tráfico, que registran cada turismo matriculado con su tipo de motor.

<Grid cols=3>
    <KpiCard
        title="Eléctricos puros"
        value={ultimo[0]?.cuota_bev * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_bev * 100, 1)}
        unit="%"
        period="de los turismos nuevos · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_bev_anio_antes != null ? ((ultimo[0].cuota_bev - ultimo[0].cuota_bev_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un año antes"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Enchufables (eléctricos + híbridos enchufables)"
        value={ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="de los turismos nuevos · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_enchufables_anio_antes != null ? ((ultimo[0].cuota_enchufables - ultimo[0].cuota_enchufables_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un año antes"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Electrificados (incluidos híbridos)"
        value={ultimo[0]?.cuota_electrificados * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_electrificados * 100, 1)}
        unit="%"
        period="de los turismos nuevos · {ultimo[0]?.mes_texto}"
        source="DGT"
    />
</Grid>

## Cuota de mercado de los turismos nuevos cada mes

<LineChart
    data={cuota_mensual}
    x=mes
    y={['cuota_bev', 'cuota_enchufables', 'cuota_electrificados']}
    yFmt=pct0
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#14b8a6', '#a3e635']}
    legend=true
    seriesLabels={{cuota_bev: 'Eléctricos puros', cuota_enchufables: 'Eléctricos + enchufables', cuota_electrificados: 'Todos los electrificados (con híbridos)'}}
/>

## Turismos nuevos por tipo de motor

<BarChart
    data={mensual}
    x=mes
    y=turismos
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="mmm yyyy"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

<p class="text-xs text-gray-500">El diésel pasó de ser más de la mitad de las ventas en 2015 a una fracción residual; su hueco lo ocuparon primero la gasolina y después los híbridos. Híbridos no enchufables (HEV) incluye los <em>mild hybrid</em> (etiqueta ECO); los de autonomía extendida (REEV) se cuentan con los enchufables.</p>

<BarChart
    data={anual}
    x=anio
    y=turismos
    series=motor
    type=stacked
    yFmt=num0
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Turismos nuevos matriculados por año"
/>

<p class="text-xs text-gray-500">El último año está incompleto (hasta el último mes publicado).</p>

## Emisiones de CO2 de los coches nuevos

<LineChart
    data={co2}
    x=mes
    y=co2_medio
    yFmt=num0
    xFmt="mmm yyyy"
    yAxisTitle="g CO2/km"
    colorPalette={['#78716c']}
/>

<p class="text-xs text-gray-500">Media de las emisiones homologadas de los turismos nuevos (g/km, eléctricos incluidos con 0). La subida hasta 2021 tiene dos causas: el paso del diésel (que emite menos CO2 por kilómetro) a la gasolina y el cambio de ciclo de homologación de NEDC a WLTP, más exigente, que eleva las cifras oficiales sin que los coches contaminen más. Desde entonces bajan con la llegada de híbridos y eléctricos.</p>

```sql provincias
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_provincia)
SELECT
    p.cod_prov,
    p.provincia,
    sum(p.matriculaciones) AS turismos,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'bev') / sum(p.matriculaciones) AS cuota_bev,
    sum(p.matriculaciones) FILTER (WHERE p.energia IN ('bev', 'phev')) / sum(p.matriculaciones) AS cuota_enchufables,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'diesel') / sum(p.matriculaciones) AS cuota_diesel
FROM mother.movilidad_matriculaciones_provincia p, ult
WHERE p.nuevo_usado = 'N'
  AND p.mes > ult.mes - INTERVAL 12 MONTH
GROUP BY ALL
ORDER BY cuota_enchufables DESC
```

## ¿Dónde se compran más coches enchufables?

Cuota de eléctricos e híbridos enchufables en los turismos nuevos de los últimos 12 meses, según la provincia del domicilio del titular.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_enchufables"
    valueFmt="pct1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_enchufables', title: 'Enchufables', fmt: 'pct1'},
        {id: 'cuota_bev', title: 'Eléctricos puros', fmt: 'pct1'},
        {id: 'turismos', title: 'Turismos nuevos', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=turismos title="Turismos nuevos (12 meses)" fmt=num0 />
    <Column id=cuota_bev title="Eléctricos puros" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_enchufables title="Enchufables" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_diesel title="Diésel" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Ojo con Madrid y otras provincias con sedes de empresas de renting y alquiler: allí se matriculan flotas que luego circulan por todo el país, lo que infla su volumen y su cuota.</p>

---

## Fuentes y notas

- **[DGT – Microdatos de matriculaciones de vehículos (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual desde enero de 2015. Se cuentan solo las matriculaciones ordinarias de turismos (incluidos todoterrenos) **nuevos**; los usados importados, que también se matriculan por primera vez en España, se excluyen.
- El tipo de motor combina la categoría de vehículo eléctrico (BEV, PHEV, REEV, HEV) y la propulsión de la ficha técnica. Gas incluye GLP y gas natural.
- Las cifras pueden diferir ligeramente de las de las asociaciones del sector (ANFAC, que usa sus propios criterios de fecha y clasificación).

<LastRefreshed prefix="Datos actualizados" />
