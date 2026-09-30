---
i18n_origen: abe822fcd116
title: Centrais eléctricas
description: "Mapa das centrais eléctricas de España: en operación, en construción, en tramitación e retiradas, por tecnoloxía, potencia e propietario."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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

# ⚡ Centrais eléctricas de España

España ten **{formatNumber(kpis[0]?.gw_operacion, 1)} GW** de potencia en **{formatNumber(kpis[0]?.n_operacion, 0)} centrais** de máis de 1 MW en funcionamento, e outros **{formatNumber(kpis[0]?.gw_construccion, 1)} GW** en construción. Detrás agardan **{formatNumber(kpis[0]?.gw_tramitacion, 0)} GW** de proxectos en tramitación, máis que toda a potencia que xa funciona, aínda que só unha parte chegará a construírse. Este mapa recolle cada central (en operación, en obras, en tramitación, anunciada ou xa pechada) segundo o inventario mundial de Global Energy Monitor.

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
        title="En construción"
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
        title="Carbón pechado desde 2018"
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

Cada círculo é unha central: a súa área é proporcional á potencia e a cor indica a tecnoloxía. Escolle o estado, as tecnoloxías e a comunidade autónoma; pasa o rato por un círculo para ver os seus datos.

```sql opciones_ccaa
SELECT DISTINCT cod_ccaa, ccaa
FROM mother.centrales
WHERE ccaa IS NOT NULL
ORDER BY ccaa
```

<ButtonGroup name=estado title="Estado">
    <ButtonGroupItem valueLabel="En operación" value="En operación" default />
    <ButtonGroupItem valueLabel="En construción" value="En construcción" />
    <ButtonGroupItem valueLabel="En tramitación" value="En tramitación" />
    <ButtonGroupItem valueLabel="Anunciada" value="Anunciada" />
    <ButtonGroupItem valueLabel="Paralizada" value="Paralizada" />
    <ButtonGroupItem valueLabel="Retirada" value="Retirada" />
    <ButtonGroupItem valueLabel="Cancelada" value="Cancelada" />
    <ButtonGroupItem valueLabel="Todas" value="Todas" />
</ButtonGroup>

<Dropdown data={tecnologias} name=tec value=tecnologia order=orden title="Tecnoloxía" multiple=true selectAllByDefault=true />

<Dropdown data={opciones_ccaa} name=ccaa value=cod_ccaa label=ccaa title="Comunidade autónoma" defaultValue="Todas">
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

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(totales_filtro[0]?.n_centrales, 0)} centrais con {formatNumber(totales_filtro[0]?.gw, 1)} GW cos filtros escollidos.</p>

<BubbleMap
    data={mapa}
    lat=lat
    long=lon
    size=potencia_mw
    maxSize={26}
    value=tecnologia
    legendType=categorical
    colorPalette={[...new Map(Array.from(mapa ?? []).map(d => [d.tecnologia, d.color])).values()]}
    opacity={0.75}
    pointName=nombre
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri — Esri, HERE, Garmin, © colaboradores de OpenStreetMap · Centrais: Global Energy Monitor (CC BY 4.0)"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tecnologia', title: 'Tecnoloxía'},
        {id: 'potencia_mw', title: 'Potencia (MW)', fmt: 'num0'},
        {id: 'estados', title: 'Estado'},
        {id: 'fechas', title: 'Posta en marcha'},
        {id: 'propietario', title: 'Propietario'},
        {id: 'ubicacion', title: 'Localización'}
    ]}
/>

<p class="text-xs text-gray-500">As coordenadas dunhas 2.900 unidades (sobre todo parques solares e eólicos en tramitación) son aproximadas: adoitan situarse no concello, non na parcela exacta. Canarias aparece ao suroeste: amplía o mapa ou escolle a comunidade no filtro.</p>

---

## O que funciona e o que vén

A potencia en tramitación e anunciada multiplica a instalada, pero non é unha previsión: unha gran parte deses proxectos non se construirá nunca (o propio inventario marca como paralizados ou cancelados os que levan anos sen novas). A potencia **en construción** é a mellor pista do que entrará en servizo nos próximos dous ou tres anos.

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
    title="Potencia por estado e tecnoloxía (GW)"
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
    title="Potencia por comunidade autónoma — {inputs.estado} (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={520}
/>

---

## Como cambiou o parque de xeración

Potencia que entrou en servizo e que se pechou cada ano segundo a data de posta en marcha de cada unidade. Vense a vaga nuclear e do carbón dos anos oitenta, os ciclos combinados e a eólica dos 2000, a parada da década de 2010 e a gran vaga fotovoltaica desde 2019; e na segunda gráfica, o peche de case todo o carbón arredor de 2020.

**Atención a 2017**: uns 790 parques fotovoltaicos pequenos (3,9 GW, mediana de 3 MW) figuran no inventario con 2017 como ano de posta en marcha. É case con seguridade unha data asignada por defecto (todos son parques cuxa tecnoloxía GEM «asume» fotovoltaica) e a maioría deben de ser do primeiro boom solar de 2007-2008. Ese pico non reflicte o que se construíu en 2017.

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
    title="Potencia posta en marcha cada ano (GW)"
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
    title="Potencia pechada cada ano (GW)"
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
    title="Potencia en servizo acumulada segundo as datas de alta e peche (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<p class="text-xs text-gray-500">Uns 8 GW en operación (sobre todo parques solares e eólicos pequenos) non teñen ano de posta en marcha no inventario e non aparecen nestas gráficas, polo que o acumulado queda algo por debaixo da potencia actual. As repotenciacións e as centrais que pecharon antes de que existise o inventario poden non figurar.</p>

---

## Todas as centrais

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
    <Column id=tecnologia title="Tecnoloxía" />
    <Column id=potencia_mw title="MW" fmt=num0 />
    <Column id=n_unidades title="Unidades" />
    <Column id=estados title="Estado" />
    <Column id=fechas title="Posta en marcha" />
    <Column id=provincia title="Provincia" />
    <Column id=propietario title="Propietario" />
    <Column id=url_gem title="Ficha" contentType=link linkLabel="GEM ↗" openInNewTab=true />
</DataTable>

<DownloadCsvButton data={tabla} filename="spainfacts_centrales_electricas.csv" label="Descargar centrais (CSV)" />

---

## Metodoloxía e advertencias

- **Fonte**: [Global Integrated Power Tracker](https://globalenergymonitor.org/projects/global-integrated-power-tracker/) de Global Energy Monitor (GEM), edición de setembro de 2026, con licenza CC BY 4.0. É o único inventario aberto que reúne, para toda España, a localización, a potencia, o estado, o propietario e as datas de cada central, incluídas as que están en obras, en tramitación ou xa pechadas.
- **Unidades e centrais**: GEM rexistra unidades ou fases (cada grupo dunha térmica, cada fase dun parque). Aquí agrúpanse por central e estado: se unha central ten grupos pechados e outros en funcionamento, aparece dúas veces, unha en cada estado. A tecnoloxía de cada punto é a de maior potencia.
- **Estados**: *en operación*; *en construción* (obras iniciadas); *en tramitación* (preconstrución: con permisos ou financiamento en curso); *anunciada*; *paralizada* (proxectos detidos, os que GEM dá por paralizados despois de dous anos sen novas e as centrais en reserva ou hibernadas); *cancelada* (incluídos os proxectos sen novas en catro anos) e *retirada*.
- **A carteira de proxectos está inchada**: en tramitación figuran uns 92 GW solares e 47 GW eólicos, moito máis do que o sistema pode absorber e do que prevé o PNIEC. Moitos proxectos compiten polo mesmo acceso á rede e acabarán caducando. Por iso se mostran por separado a potencia en construción e a potencia en tramitación ou anunciada.
- **O que non está**: o autoconsumo e a fotovoltaica sobre tellado (uns 8-9 GW), as instalacións pequenas (GEM recolle solar desde ~1 MW, eólica desde ~6 MW e deixa fóra a minihidráulica e boa parte da coxeración industrial) e as baterías, que o inventario non inclúe; o bombeo si está, dentro da hidráulica.
- **Comparación con REE**: a potencia en operación por tecnoloxía seméllase á oficial de Red Eléctrica: fotovoltaica ~34 GW (REE ~32 GW sen autoconsumo), eólica ~31 GW (~32 GW), hidráulica con bombeo ~16 GW (~17 GW), ciclos combinados ~27 GW (~26 GW), nuclear 7,4 GW brutos (7,1 GW netos). A coxeración queda moi por debaixo da oficial (~1,4 GW fronte a ~5-6 GW) porque GEM só recolle as grandes. Bombeo reúne as centrais hidráulicas con bombeo, puro ou mixto.
- **Tecnoloxías**: *coxeración* son as unidades de gas natural de menos de 150 MW que producen tamén calor para a industria; *turbinas de gas e motores* e *turbinas de vapor* son sobre todo os grupos de fuel e gasóleo de Canarias, Baleares, Ceuta e Melilla. Os residuos urbanos cóntanse como non renovables e o bombeo, como almacenamento, tampouco suma na porcentaxe renovable.
- **Localización**: a provincia e a comunidade asígnanse polas coordenadas de cada unidade (os parques eólicos mariños, á provincia costeira máis próxima).

Cita: *Global Integrated Power Tracker, Global Energy Monitor, setembro de 2026 (CC BY 4.0)*.

<LastRefreshed prefix="Datos actualizados" />
