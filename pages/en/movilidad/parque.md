---
title: Vehicle fleet
description: "The vehicles on the road in Spain: cars by engine type, DGT environmental label and age, most common models, and comparison by province and municipality."
i18n_origen: 5bbacb52d8c4
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql resumen
SELECT
    strftime(max(mes), '%m/%Y') AS mes_texto,
    sum(vehiculos) AS vehiculos,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo') AS turismos,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND energia IN ('bev', 'phev')) AS enchufables,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND energia = 'bev') AS bev,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND distintivo = 'SIN') AS sin_distintivo,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND antiguedad = '20+') AS mas_de_20,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion
FROM mother.movilidad_parque_provincia
```

# 🅿️ The vehicle fleet

The vehicles registered as active with the Directorate-General for Traffic (DGT), that is, those that can be driven on Spanish roads today: what engine they have, what environmental label they carry and how old they are.

```sql parque_mensual
SELECT mes, turismos_1000, pct_enchufables, pct_bev, pct_sin_distintivo
FROM mother.movilidad_parque_resumen
ORDER BY mes
```

<Grid cols=3>
    <KpiCard
        title="Cars on the road"
        value={resumen[0]?.turismos}
        formattedValue="{formatNumber(1000 * resumen[0]?.turismos / resumen[0]?.poblacion, 0)} per 1,000 people"
        period="{formatCompact(resumen[0]?.turismos, 1)} cars and {formatCompact(resumen[0]?.vehiculos, 1)} vehicles of all types · {resumen[0]?.mes_texto}"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.turismos_1000)}
    />
    <KpiCard
        title="Plug-in cars"
        value={parque_mensual.slice(-1)[0]?.pct_enchufables}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_enchufables, 1)}%"
        period="of all cars · {formatNumber(resumen[0]?.enchufables, 0)} plug-ins, {formatNumber(resumen[0]?.bev, 0)} battery electric"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_enchufables)}
    />
    <KpiCard
        title="Cars without an environmental label"
        value={parque_mensual.slice(-1)[0]?.pct_sin_distintivo}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_sin_distintivo, 1)}%"
        period="of all cars · {formatCompact(resumen[0]?.sin_distintivo, 1)} cars · petrol from before 2000 and diesel from before 2006"
        direction="positive-down"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_sin_distintivo)}
    />
</Grid>

<p class="text-xs text-gray-500">The sparklines start in March 2025: the DGT only keeps the fleet files for the last few months, and the series grows with each monthly release.</p>

<ButtonGroup name=grupo title="Vehicle">
    <ButtonGroupItem valueLabel="Cars" value="turismo" default />
    <ButtonGroupItem valueLabel="Motorbikes" value="motocicleta" />
    <ButtonGroupItem valueLabel="Vans" value="furgoneta" />
    <ButtonGroupItem valueLabel="Lorries" value="camion" />
    <ButtonGroupItem valueLabel="Buses" value="autobus" />
</ButtonGroup>

```sql por_energia
SELECT e.energia_etiqueta AS motor, e.energia_orden, sum(p.vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia p
JOIN ${energias} e ON e.energia = p.energia
WHERE p.grupo = '${inputs.grupo}'
GROUP BY ALL
ORDER BY e.energia_orden
```

```sql por_distintivo
SELECT
    CASE distintivo WHEN 'CERO' THEN '0 emisiones (azul)' WHEN 'ECO' THEN 'ECO' WHEN 'C' THEN 'C (verde)' WHEN 'B' THEN 'B (amarilla)' ELSE 'Sin etiqueta' END AS etiqueta,
    CASE distintivo WHEN 'CERO' THEN 1 WHEN 'ECO' THEN 2 WHEN 'C' THEN 3 WHEN 'B' THEN 4 ELSE 5 END AS orden,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo = '${inputs.grupo}'
GROUP BY ALL
ORDER BY orden
```

```sql por_antiguedad
SELECT antiguedad || ' años' AS antiguedad, sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo = '${inputs.grupo}' AND antiguedad <> 'desconocida'
GROUP BY antiguedad
ORDER BY CASE antiguedad WHEN '0-4' THEN 1 WHEN '5-9' THEN 2 WHEN '10-14' THEN 3 WHEN '15-19' THEN 4 ELSE 5 END
```

<Grid cols=3>
    <BarChart data={por_energia} x=motor y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#0f766e" title="By engine type" />
    <BarChart data={por_distintivo} x=etiqueta y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#14b8a6" title="By environmental label" />
    <BarChart data={por_antiguedad} x=antiguedad y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#78716c" title="By age" />
</Grid>

<p class="text-xs text-gray-500">Age is counted from the date of registration in Spain (for imported used vehicles, from when they were registered here). The environmental label is the one the DGT assigns to each vehicle according to its engine and Euro emissions standard.</p>

## Most common models

<Dropdown name=energia title="Engine" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="All engines" />
</Dropdown>

```sql modelos
SELECT
    row_number() OVER (ORDER BY sum(vehiculos) DESC, marca, modelo) AS puesto,
    marca,
    modelo,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_modelos
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
  AND es_modelo_real
GROUP BY marca, modelo
ORDER BY vehiculos DESC
```

```sql marcas_parque
SELECT
    row_number() OVER (ORDER BY sum(vehiculos) DESC, marca) AS puesto,
    marca,
    sum(vehiculos) AS vehiculos,
    sum(vehiculos) / sum(sum(vehiculos)) OVER () AS cuota
FROM mother.movilidad_parque_modelos
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
GROUP BY marca
ORDER BY vehiculos DESC
```

<Grid cols=2>
<DataTable data={modelos} rows=20 search=true title="Models">
    <Column id=puesto title="#" />
    <Column id=marca title="Make" />
    <Column id=modelo title="Model" />
    <Column id=vehiculos title="On the road" fmt=num0 contentType=bar barColor="#99f6e4" />
</DataTable>
<DataTable data={marcas_parque} rows=20 search=true title="Makes">
    <Column id=puesto title="#" />
    <Column id=marca title="Make" />
    <Column id=vehiculos title="On the road" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Share" fmt=pct1 />
</DataTable>
</Grid>

<p class="text-xs text-gray-500">For many older vehicles the DGT does not hold the model (only the make): they count in the makes ranking but not in the models ranking. Models with fewer than 100 units are not shown.</p>

## By province

```sql provincias
SELECT
    cod_prov,
    provincia,
    sum(vehiculos) AS turismos,
    sum(vehiculos_por_1000_hab) AS turismos_por_1000_hab,
    sum(vehiculos) FILTER (WHERE energia IN ('bev', 'phev')) / sum(vehiculos) AS cuota_enchufables,
    sum(vehiculos) FILTER (WHERE distintivo = 'SIN') / sum(vehiculos) AS cuota_sin_etiqueta,
    sum(vehiculos) FILTER (WHERE antiguedad = '20+') / sum(vehiculos) AS cuota_mas_20
FROM mother.movilidad_parque_provincia
WHERE grupo = 'turismo'
GROUP BY ALL
ORDER BY turismos_por_1000_hab DESC
```

<ButtonGroup name=indicador_prov title="Indicator">
    <ButtonGroupItem valueLabel="% without environmental label" value="cuota_sin_etiqueta" default />
    <ButtonGroupItem valueLabel="% over 20 years old" value="cuota_mas_20" />
    <ButtonGroupItem valueLabel="% plug-in" value="cuota_enchufables" />
</ButtonGroup>

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value={inputs.indicador_prov}
    valueFmt="pct1"
    colorPalette={inputs.indicador_prov === 'cuota_enchufables' ? ['#f0fdfa', '#5eead4', '#0f766e'] : ['#fef3c7', '#f59e0b', '#92400e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'turismos', title: 'Cars', fmt: 'num0'},
        {id: 'turismos_por_1000_hab', title: 'Per 1,000 people', fmt: 'num0'},
        {id: 'cuota_sin_etiqueta', title: 'No label', fmt: 'pct1'},
        {id: 'cuota_mas_20', title: 'Over 20 years old', fmt: 'pct1'},
        {id: 'cuota_enchufables', title: 'Plug-in', fmt: 'pct1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=turismos title="Cars" fmt=num0 />
    <Column id=turismos_por_1000_hab title="Per 1,000 people" fmt=num0 />
    <Column id=cuota_sin_etiqueta title="No label" fmt=pct1 />
    <Column id=cuota_mas_20 title="Over 20 years old" fmt=pct1 />
    <Column id=cuota_enchufables title="Plug-in" fmt=pct1 />
</DataTable>

## Municipalities with more than 10,000 inhabitants

```sql municipios
SELECT
    cod_mun,
    municipio,
    poblacion,
    turismos,
    turismos_por_1000_hab,
    enchufables_pct,
    sin_distintivo_pct,
    mas_de_15_anios_pct
FROM mother.movilidad_parque_municipio
WHERE poblacion >= 10000
ORDER BY turismos DESC
```

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=turismos title="Cars" fmt=num0 />
    <Column id=turismos_por_1000_hab title="Per 1,000 people" fmt=num0 />
    <Column id=enchufables_pct title="Plug-in" fmt='0.0"%"' />
    <Column id=sin_distintivo_pct title="No label" fmt='0.0"%"' />
    <Column id=mas_de_15_anios_pct title="Over 15 years old" fmt='0.0"%"' />
</DataTable>

<p class="text-xs text-gray-500">The DGT does not publish the municipality of vehicles registered in municipalities with fewer than 10,000 inhabitants. Municipalities where leasing or rental companies are headquartered (Madrid, Alcobendas...) accumulate vehicles that circulate all over the country, which pushes up their cars per person.</p>

---

## Sources and notes

- **[DGT – Vehicle fleet microdata](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**: one record per active vehicle at the end of each month (~39 million). SpainFacts keeps an aggregated snapshot of every month since August 2026.
- Engine type based on the propulsion and electric category in the technical data sheet; label based on the environmental badge assigned by the DGT.

<LastRefreshed prefix="Data updated" />
