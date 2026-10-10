---
title: Coche eléctrico
description: "Transición al coche eléctrico en España: matriculaciones de turismos por tipo de motor cada mes desde 2015, cuota de eléctricos e híbridos enchufables por provincia y emisiones de CO2."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
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
-- Turismos nuevos por 1.000 habitantes (padrón del año; el último para los más recientes)
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.motor,
    m.energia_orden,
    sum(m.turismos) AS turismos,
    1000.0 * sum(m.turismos) / any_value(p.poblacion) AS por_1000
FROM ${mensual} m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
GROUP BY ALL
ORDER BY anio, m.energia_orden
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
        sparklineData={cuota_mensual.map(d => ({...d, valor: d.cuota_bev * 100}))}
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
        sparklineData={cuota_mensual.map(d => ({...d, valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Electrificados (incluidos híbridos)"
        value={ultimo[0]?.cuota_electrificados * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_electrificados * 100, 1)}
        unit="%"
        period="de los turismos nuevos · {ultimo[0]?.mes_texto}"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({...d, valor: d.cuota_electrificados * 100}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'coche_electrico_cuota'
```

<Comparativa data={comparativa_internacional} decimales={0} />

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
    y=por_1000
    series=motor
    type=stacked
    yFmt=num1
    yAxisTitle="por 1.000 habitantes"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Turismos nuevos matriculados por año, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">El último año está incompleto (hasta el último mes publicado).</p>

## ¿Quién compra los coches nuevos?

```sql canales_anual
SELECT
    CAST(year(mes) AS INTEGER) AS anio,
    canal_etiqueta AS canal,
    canal_orden,
    sum(matriculaciones) AS turismos,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS cuota_enchufables
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY anio, canal_orden
```

```sql canales_orden
SELECT DISTINCT canal, canal_orden FROM ${canales_anual} ORDER BY canal_orden
```

```sql canales_ultimo
SELECT
    any_value(anio) AS anio,
    100 * sum(turismos) FILTER (WHERE canal_orden = 1) / sum(turismos) AS pct_particulares,
    100 * max(cuota_enchufables) FILTER (WHERE canal_orden = 1) AS pct_enchufables_particulares,
    100 * sum(turismos * cuota_enchufables) FILTER (WHERE canal_orden > 1) / sum(turismos) FILTER (WHERE canal_orden > 1) AS pct_enchufables_flotas
FROM ${canales_anual}
-- Último año completo (con diciembre publicado)
WHERE anio = (SELECT CAST(year(max(mes)) AS INTEGER) - CASE WHEN month(max(mes)) = 12 THEN 0 ELSE 1 END FROM mother.movilidad_matriculaciones_mensual)
```

Menos de la mitad de los turismos nuevos los compran particulares. El resto va a flotas: empresas (que incluyen las automatriculaciones de concesionarios y marcas, los «kilómetro cero»), renting, alquiler de coches y taxis y VTC. En {canales_ultimo[0]?.anio}, los particulares se quedaron el {formatNumber(canales_ultimo[0]?.pct_particulares, 1)} % de las matriculaciones; los enchufables fueron el {formatNumber(canales_ultimo[0]?.pct_enchufables_particulares, 1)} % de sus compras, frente al {formatNumber(canales_ultimo[0]?.pct_enchufables_flotas, 1)} % en las flotas.

<BarChart
    data={canales_anual}
    x=anio
    y=turismos
    series=canal
    type=stacked100
    yFmt=pct0
    xFmt="####"
    seriesOrder={canales_orden.map(d => d.canal)}
    colorPalette={['#0d9488', '#2563eb', '#7c3aed', '#f59e0b', '#9ca3af']}
    title="Turismos nuevos por canal de venta"
/>

<LineChart
    data={canales_anual}
    x=anio
    y=cuota_enchufables
    series=canal
    yFmt=pct0
    xFmt="####"
    markers=true
    seriesOrder={canales_orden.map(d => d.canal)}
    colorPalette={['#0d9488', '#2563eb', '#7c3aed', '#f59e0b', '#9ca3af']}
    title="Cuota de enchufables (eléctricos + híbridos enchufables) en cada canal"
/>

<p class="text-xs text-gray-500">Particulares: matriculados a nombre de una persona física (incluye autónomos) sin renting. Empresas: personas jurídicas, sin renting ni alquiler. Renting: contratos de arrendamiento a largo plazo, de empresas o de particulares. Alquiler: servicio de alquiler sin conductor (rent a car). Taxi, VTC y otros: servicio público (taxi, alquiler con conductor, autoescuela...). El último año está incompleto.</p>

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
  AND ('${inputs.canal_prov}' = 'todos' OR p.canal = 'particular')
GROUP BY ALL
ORDER BY cuota_enchufables DESC
```

## ¿Dónde se compran más coches enchufables?

Cuota de eléctricos e híbridos enchufables en los turismos nuevos de los últimos 12 meses, según la provincia del domicilio del titular. Por defecto solo cuentan los de particulares: las flotas se matriculan donde tienen la sede y deforman el mapa (ver la nota de abajo).

<ButtonGroup name=canal_prov title="Compradores">
    <ButtonGroupItem valueLabel="Solo particulares" value="particular" default />
    <ButtonGroupItem valueLabel="Todos, con flotas" value="todos" />
</ButtonGroup>

<MapaEspana
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

<p class="text-xs text-gray-500"><b>Dónde matriculan las flotas.</b> Un coche se matricula en el municipio del domicilio de su titular, y las empresas de renting y alquiler eligen dónde domiciliar sus flotas. El impuesto de circulación (IVTM) es municipal: cada ayuntamiento puede subir la tarifa mínima hasta el doble, así que muchas flotas se registran en una delegación abierta en un municipio con el impuesto más bajo. Por eso pueblos como La Hiruela, Venturada o Patones (Madrid) o Aguilar de Segarra (Barcelona) matriculan cada año muchos más coches que habitantes tienen, y según la asociación AEA diez municipios concentran en torno al 35 % de las matriculaciones de vehículos de empresa. Esos coches circulan después por todo el país; con «Todos, con flotas», Madrid y Barcelona aparecen muy por encima de lo que compran sus vecinos. Fuente: <a href="https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/">AEA, estudio sobre el IVTM (2026)</a>. Los municipios, uno a uno, en <a href="/movilidad/flotas-e-impuestos">Los paraísos fiscales de las flotas</a>.</p>

---

## Fuentes y notas

- **[DGT – Microdatos de matriculaciones de vehículos (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual desde enero de 2015. Se cuentan solo las matriculaciones ordinarias de turismos (incluidos todoterrenos) **nuevos**; los usados importados, que también se matriculan por primera vez en España, se excluyen.
- El tipo de motor combina la categoría de vehículo eléctrico (BEV, PHEV, REEV, HEV) y la propulsión de la ficha técnica. Gas incluye GLP y gas natural.
- Las cifras pueden diferir ligeramente de las de las asociaciones del sector (ANFAC, que usa sus propios criterios de fecha y clasificación). ANFAC separa también particulares, empresas y alquiladores; aquí el canal sale del titular (persona física o jurídica), del indicador de renting y del tipo de servicio de cada vehículo en el fichero de la DGT.
- El último mes, hasta que la DGT publica el fichero mensual (hacia el día 15 del mes siguiente), se calcula con sus ficheros diarios.
- La comparación internacional (año completo, eléctricos puros más híbridos enchufables) es de la **[AIE – Global EV Data Explorer](https://www.iea.org/data-and-statistics/data-tools/global-ev-data-explorer)** (CC BY 4.0), que redondea a números enteros las cuotas recientes; por eso puede no coincidir exactamente con la de la DGT. Noruega y Dinamarca aparecen como referencia (borde discontinuo): son los países donde el coche eléctrico está más extendido.

<LastRefreshed prefix="Datos actualizados" />
