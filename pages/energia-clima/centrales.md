---
title: Centrales eléctricas
description: "Mapa de las centrales eléctricas de España: en operación, en construcción, en tramitación y retiradas, por tecnología, potencia y propietario."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql tecnologias
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM mother.centrales_resumen
GROUP BY tecnologia
ORDER BY orden
```

```sql kpis
SELECT
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') / 1000 AS gw_operacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación' AND renovable) * 100
        / sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') AS pct_renovable,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En construcción') / 1000 AS gw_construccion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En tramitación') / 1000 AS gw_tramitacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'Anunciada') / 1000 AS gw_anunciada,
    (SELECT count(*) FROM mother.centrales WHERE estado_grupo = 'En operación') AS n_operacion
FROM mother.centrales_resumen
```

```sql carbon
SELECT sum(mw_baja) / 1000 AS gw_carbon_retirado
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018
```

```sql operacion_serie
SELECT anio, valor
FROM (
    SELECT anio, sum(sum(mw_alta - mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
    FROM mother.centrales_por_anio
    WHERE anio <= year(current_date)
    GROUP BY anio
)
WHERE anio >= 2000
ORDER BY anio
```

```sql carbon_serie
SELECT anio, sum(sum(mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018 AND anio <= year(current_date)
GROUP BY anio
ORDER BY anio
```

# ⚡ Centrales eléctricas de España

España tiene **{formatNumber(kpis[0]?.gw_operacion, 1)} GW** de potencia en **{formatNumber(kpis[0]?.n_operacion, 0)} centrales** de más de 1 MW en funcionamiento, y otros **{formatNumber(kpis[0]?.gw_construccion, 1)} GW** en construcción. Detrás esperan **{formatNumber(kpis[0]?.gw_tramitacion, 0)} GW** de proyectos en tramitación, más que toda la potencia que ya funciona, aunque solo una parte llegará a construirse. Este mapa recoge cada central (en operación, en obras, en tramitación, anunciada o ya cerrada) según el inventario mundial de Global Energy Monitor.

<Grid cols=4>
    <KpiCard
        title="En operación"
        value={kpis[0]?.gw_operacion}
        formattedValue={formatNumber(kpis[0]?.gw_operacion, 1)}
        unit=" GW"
        period="{formatNumber(kpis[0]?.pct_renovable, 0)} % renovable"
        source="Global Energy Monitor"
        sparklineData={operacion_serie}
    />
    <KpiCard
        title="En construcción"
        value={kpis[0]?.gw_construccion}
        formattedValue={formatNumber(kpis[0]?.gw_construccion, 1)}
        unit=" GW"
        period="Obras iniciadas"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="En tramitación"
        value={kpis[0]?.gw_tramitacion}
        formattedValue={formatNumber(kpis[0]?.gw_tramitacion, 0)}
        unit=" GW"
        period="Con permisos en curso"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Carbón cerrado desde 2018"
        value={carbon[0]?.gw_carbon_retirado}
        formattedValue={formatNumber(carbon[0]?.gw_carbon_retirado, 1)}
        unit=" GW"
        period="Potencia de carbón retirada"
        source="Global Energy Monitor"
        sparklineData={carbon_serie}
    />
</Grid>

---

## El mapa

Cada círculo es una central: su área es proporcional a la potencia y el color indica la tecnología. Elige el estado, las tecnologías y la comunidad autónoma; pasa el ratón por un círculo para ver sus datos.

```sql opciones_ccaa
SELECT DISTINCT cod_ccaa, ccaa
FROM mother.centrales
WHERE ccaa IS NOT NULL
ORDER BY ccaa
```

<ButtonGroup name=estado title="Estado">
    <ButtonGroupItem valueLabel="En operación" value="En operación" default />
    <ButtonGroupItem valueLabel="En construcción" value="En construcción" />
    <ButtonGroupItem valueLabel="En tramitación" value="En tramitación" />
    <ButtonGroupItem valueLabel="Anunciada" value="Anunciada" />
    <ButtonGroupItem valueLabel="Paralizada" value="Paralizada" />
    <ButtonGroupItem valueLabel="Retirada" value="Retirada" />
    <ButtonGroupItem valueLabel="Cancelada" value="Cancelada" />
    <ButtonGroupItem valueLabel="Todas" value="Todas" />
</ButtonGroup>

<Dropdown data={tecnologias} name=tec value=tecnologia order=orden title="Tecnología" multiple=true selectAllByDefault=true />

<Dropdown data={opciones_ccaa} name=ccaa value=cod_ccaa label=ccaa title="Comunidad autónoma" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="Toda España" />
</Dropdown>

```sql filtradas
SELECT
    nombre,
    tecnologia,
    color,
    orden_tecnologia,
    estado_grupo,
    estados,
    potencia_mw,
    n_unidades,
    CASE
        WHEN estado_grupo = 'Retirada' AND anio_retiro IS NOT NULL THEN 'Cerrada en ' || CAST(CAST(anio_retiro AS INTEGER) AS VARCHAR)
        WHEN anio_inicio_min IS NULL THEN 'Sin fecha'
        WHEN anio_inicio_min = anio_inicio_max THEN CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR) || '–' || CAST(CAST(anio_inicio_max AS INTEGER) AS VARCHAR)
    END AS fechas,
    anio_inicio_min,
    coalesce(propietario, 'Sin datos') AS propietario,
    coalesce(municipio || ' (' || provincia || ')', provincia) AS ubicacion,
    provincia,
    ccaa,
    precision_ubicacion,
    lat,
    lon,
    url_gem
FROM mother.centrales
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
```

```sql mapa
-- La paleta categórica de BubbleMap se asigna por orden de aparición: primero
-- va la mayor central de cada tecnología (en el orden de la paleta) y luego el
-- resto de mayor a menor, para que las pequeñas queden encima.
SELECT *
FROM (
    SELECT *, row_number() OVER (PARTITION BY tecnologia ORDER BY potencia_mw DESC NULLS LAST, nombre) = 1 AS primera
    FROM ${filtradas}
    WHERE potencia_mw > 0
)
ORDER BY primera DESC, CASE WHEN primera THEN orden_tecnologia END, potencia_mw DESC
```

```sql colores_mapa
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM ${filtradas}
WHERE potencia_mw > 0
GROUP BY tecnologia
ORDER BY orden
```

```sql totales_filtro
SELECT count(*) AS n_centrales, sum(potencia_mw) / 1000 AS gw
FROM ${filtradas}
```

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(totales_filtro[0]?.n_centrales, 0)} centrales con {formatNumber(totales_filtro[0]?.gw, 1)} GW con los filtros elegidos.</p>

<BubbleMap
    data={mapa}
    lat=lat
    long=lon
    size=potencia_mw
    maxSize={26}
    value=tecnologia
    legendType=categorical
    colorPalette={colores_mapa.map(d => d.color)}
    opacity={0.75}
    pointName=nombre
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Centrales: Global Energy Monitor (CC BY 4.0)"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tecnologia', title: 'Tecnología'},
        {id: 'potencia_mw', title: 'Potencia (MW)', fmt: 'num0'},
        {id: 'estados', title: 'Estado'},
        {id: 'fechas', title: 'Puesta en marcha'},
        {id: 'propietario', title: 'Propietario'},
        {id: 'ubicacion', title: 'Ubicación'}
    ]}
/>

<p class="text-xs text-gray-500">Las coordenadas de unas 2.900 unidades (sobre todo parques solares y eólicos en tramitación) son aproximadas: suelen situarse en el municipio, no en la parcela exacta. Canarias aparece al suroeste: amplía el mapa o elige la comunidad en el filtro.</p>

---

## Lo que funciona y lo que viene

La potencia en tramitación y anunciada multiplica la instalada, pero no es una previsión: una gran parte de esos proyectos no se construirá nunca (el propio inventario marca como paralizados o cancelados los que llevan años sin noticias). La potencia **en construcción** es la mejor pista de lo que entrará en servicio en los próximos dos o tres años.

```sql por_estado
SELECT
    estado_grupo,
    min(orden_estado) AS orden_estado,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw
FROM mother.centrales_ccaa
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
GROUP BY estado_grupo, tecnologia
ORDER BY orden_estado, min(orden_tecnologia)
```

<BarChart
    data={por_estado}
    x=estado_grupo
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Potencia por estado y tecnología (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={420}
/>

```sql por_ccaa
SELECT
    ccaa,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw,
    sum(sum(potencia_mw)) OVER (PARTITION BY ccaa) AS total_ccaa
FROM mother.centrales_ccaa
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
GROUP BY ccaa, tecnologia
ORDER BY total_ccaa DESC, min(orden_tecnologia)
```

<BarChart
    data={por_ccaa}
    x=ccaa
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Potencia por comunidad autónoma — {inputs.estado} (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={520}
/>

---

## Cómo ha cambiado el parque de generación

Potencia que entró en servicio y que se cerró cada año según la fecha de puesta en marcha de cada unidad. Se ven la oleada nuclear y del carbón de los años ochenta, los ciclos combinados y la eólica de los 2000, el parón de la década de 2010 y la gran oleada fotovoltaica desde 2019; y en el segundo gráfico, el cierre de casi todo el carbón en torno a 2020.

**Ojo con 2017**: unos 790 parques fotovoltaicos pequeños (3,9 GW, mediana de 3 MW) figuran en el inventario con 2017 como año de puesta en marcha. Es casi con seguridad una fecha asignada por defecto (todos son parques cuya tecnología GEM «asume» fotovoltaica) y la mayoría deben de ser del primer boom solar de 2007-2008. Ese pico no refleja lo que se construyó en 2017.

```sql altas_bajas
SELECT
    anio,
    tecnologia,
    min(orden_tecnologia) AS orden,
    sum(mw_alta) / 1000 AS gw_alta,
    sum(mw_baja) / 1000 AS gw_baja
FROM mother.centrales_por_anio
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
  AND anio BETWEEN 1950 AND year(current_date)
GROUP BY anio, tecnologia
ORDER BY anio, orden
```

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_alta
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Potencia puesta en marcha cada año (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_baja
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Potencia cerrada cada año (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

```sql acumulada
WITH anios AS (
    SELECT range AS anio FROM range(1950, year(current_date) + 1)
),
tecs AS (
    SELECT DISTINCT tecnologia FROM ${altas_bajas}
),
neta AS (
    SELECT anio, tecnologia, sum(gw_alta - gw_baja) AS gw FROM ${altas_bajas} GROUP BY ALL
)
SELECT
    a.anio,
    t.tecnologia,
    sum(coalesce(n.gw, 0)) OVER (PARTITION BY t.tecnologia ORDER BY a.anio) AS gw
FROM anios a
CROSS JOIN tecs t
LEFT JOIN neta n ON n.anio = a.anio AND n.tecnologia = t.tecnologia
ORDER BY a.anio
```

<AreaChart
    data={acumulada}
    x=anio
    y=gw
    series=tecnologia
    xFmt="0"
    yFmt=num0
    yAxisTitle="GW"
    title="Potencia en servicio acumulada según las fechas de alta y cierre (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<p class="text-xs text-gray-500">Unos 8 GW en operación (sobre todo parques solares y eólicos pequeños) no tienen año de puesta en marcha en el inventario y no aparecen en estos gráficos, por lo que el acumulado se queda algo por debajo de la potencia actual. Las repotenciaciones y las centrales que cerraron antes de que existiera el inventario pueden no figurar.</p>

---

## Todas las centrales

```sql tabla
SELECT
    nombre,
    tecnologia,
    potencia_mw,
    n_unidades,
    estados,
    fechas,
    provincia,
    propietario,
    url_gem
FROM ${filtradas}
ORDER BY potencia_mw DESC NULLS LAST
```

<DataTable data={tabla} search=true rows=20>
    <Column id=nombre title="Central" />
    <Column id=tecnologia title="Tecnología" />
    <Column id=potencia_mw title="MW" fmt=num0 />
    <Column id=n_unidades title="Unidades" />
    <Column id=estados title="Estado" />
    <Column id=fechas title="Puesta en marcha" />
    <Column id=provincia title="Provincia" />
    <Column id=propietario title="Propietario" />
    <Column id=url_gem title="Ficha" contentType=link linkLabel="GEM ↗" openInNewTab=true />
</DataTable>

<DownloadCsvButton data={tabla} filename="spainfacts_centrales_electricas.csv" label="Descargar centrales (CSV)" />

---

## Metodología y advertencias

- **Fuente**: [Global Integrated Power Tracker](https://globalenergymonitor.org/projects/global-integrated-power-tracker/) de Global Energy Monitor (GEM), edición de septiembre de 2026, con licencia CC BY 4.0. Es el único inventario abierto que reúne, para toda España, la ubicación, la potencia, el estado, el propietario y las fechas de cada central, incluidas las que están en obras, en tramitación o ya cerradas.
- **Unidades y centrales**: GEM registra unidades o fases (cada grupo de una térmica, cada fase de un parque). Aquí se agrupan por central y estado: si una central tiene grupos cerrados y otros en funcionamiento, aparece dos veces, una en cada estado. La tecnología de cada punto es la de mayor potencia.
- **Estados**: *en operación*; *en construcción* (obras iniciadas); *en tramitación* (pre-construcción: con permisos o financiación en curso); *anunciada*; *paralizada* (proyectos detenidos, los que GEM da por paralizados tras dos años sin noticias y las centrales en reserva o hibernadas); *cancelada* (incluidos los proyectos sin noticias en cuatro años) y *retirada*.
- **La cartera de proyectos está inflada**: en tramitación figuran unos 92 GW solares y 47 GW eólicos, mucho más de lo que el sistema puede absorber y de lo que prevé el PNIEC. Muchos proyectos compiten por el mismo acceso a la red y acabarán caducando. Por eso se muestran por separado la potencia en construcción y la potencia en tramitación o anunciada.
- **Lo que no está**: el autoconsumo y la fotovoltaica sobre tejado (unos 8-9 GW), las instalaciones pequeñas (GEM recoge solar desde ~1 MW, eólica desde ~6 MW y deja fuera la minihidráulica y buena parte de la cogeneración industrial) y las baterías, que el inventario no incluye; el bombeo sí está, dentro de la hidráulica.
- **Comparación con REE**: la potencia en operación por tecnología se parece a la oficial de Red Eléctrica: fotovoltaica ~34 GW (REE ~32 GW sin autoconsumo), eólica ~31 GW (~32 GW), hidráulica con bombeo ~16 GW (~17 GW), ciclos combinados ~27 GW (~26 GW), nuclear 7,4 GW brutos (7,1 GW netos). La cogeneración queda muy por debajo de la oficial (~1,4 GW frente a ~5-6 GW) porque GEM solo recoge las grandes. Bombeo reúne las centrales hidráulicas con bombeo, puro o mixto.
- **Tecnologías**: *cogeneración* son las unidades de gas natural de menos de 150 MW que producen también calor para industria; *turbinas de gas y motores* y *turbinas de vapor* son sobre todo los grupos de fuel y gasóleo de Canarias, Baleares, Ceuta y Melilla. Los residuos urbanos se cuentan como no renovables y el bombeo, como almacenamiento, tampoco suma en el porcentaje renovable.
- **Ubicación**: la provincia y la comunidad se asignan por las coordenadas de cada unidad (los parques eólicos marinos, a la provincia costera más cercana).

Cita: *Global Integrated Power Tracker, Global Energy Monitor, septiembre de 2026 (CC BY 4.0)*.

<LastRefreshed prefix="Datos actualizados" />
