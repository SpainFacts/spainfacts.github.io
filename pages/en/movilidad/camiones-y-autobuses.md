---
title: Trucks and buses
description: "Trucks and buses in Spain: registrations by engine type since 2015, the rise of the electric bus, best-selling makes and groups, and the age of those on the road."
i18n_origen: 4190a8292d58
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql anual
-- Camiones y autobuses nuevos por año y motor, por 100.000 habitantes
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.grupo,
    m.energia,
    m.energia_etiqueta AS motor,
    m.energia_orden,
    sum(m.matriculaciones) AS unidades,
    100000.0 * sum(m.matriculaciones) / any_value(p.poblacion) AS por_100000
FROM mother.movilidad_matriculaciones_mensual m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
WHERE m.grupo IN ('camion', 'autobus') AND m.nuevo_usado = 'N'
GROUP BY ALL
ORDER BY anio, m.energia_orden
```

```sql cero_emisiones
-- Cuota de cero emisiones (eléctricos puros e hidrógeno) en los últimos 12 meses y un año antes
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_mensual),
base AS (
    SELECT
        m.grupo,
        m.mes > u.mes - INTERVAL 12 MONTH AS actual,
        sum(m.matriculaciones) AS total,
        sum(m.matriculaciones) FILTER (WHERE m.energia IN ('bev', 'hidrogeno')) AS cero,
        sum(m.matriculaciones) FILTER (WHERE m.energia = 'diesel') AS diesel
    FROM mother.movilidad_matriculaciones_mensual m, ult u
    WHERE m.grupo IN ('camion', 'autobus') AND m.nuevo_usado = 'N'
      AND m.mes > u.mes - INTERVAL 24 MONTH
    GROUP BY ALL
)
SELECT
    a.grupo,
    a.total,
    a.cero / a.total AS cuota_cero,
    a.diesel / a.total AS cuota_diesel,
    b.cero / b.total AS cuota_cero_antes,
    (SELECT strftime(mes, '%m/%Y') FROM ult) AS mes_texto
FROM base a
JOIN base b ON b.grupo = a.grupo AND NOT b.actual
WHERE a.actual
```

```sql anual_cuota
SELECT anio, grupo,
    sum(unidades) FILTER (WHERE energia IN ('bev', 'hidrogeno')) / sum(unidades) AS cuota_cero,
    CASE grupo WHEN 'camion' THEN 'Camiones' ELSE 'Autobuses' END AS vehiculo
FROM ${anual}
GROUP BY ALL
ORDER BY anio
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${anual} ORDER BY energia_orden
```

# 🚚 Trucks and buses

Trucks and buses are few compared with cars, but they cover far more kilometres and burn mostly diesel: heavy transport is a large part of road transport emissions. This page shows how many are sold, with what engine, and how old the ones on the road are.

<Grid cols=2>
    <KpiCard
        title="Zero-emission new buses"
        value={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="electric and hydrogen · 12 months to {cero_emisiones[0]?.mes_texto}"
        change={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. the previous 12 months"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Zero-emission new trucks"
        value={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="electric and hydrogen · {formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_diesel * 100, 0)}% diesel · 12 months"
        change={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. the previous 12 months"
        direction="positive-up"
        source="DGT"
    />
</Grid>

## Zero-emission share of new vehicles

<LineChart
    data={anual_cuota}
    x=anio
    y=cuota_cero
    series=vehiculo
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#0f766e', '#f59e0b']}
    title="Battery electric and hydrogen, % of vehicles registered each year"
/>

<p class="text-xs text-gray-500">City buses are electrifying first because they run short routes and return to the depot every night, where they charge; European subsidies and cities' low-emission zones also help. Long-haul trucks are still almost all diesel: batteries are heavy and the charging network for heavy vehicles is only just starting. The latest year is incomplete.</p>

## New buses by engine type

<BarChart
    data={anual.filter(d => d.grupo === 'autobus')}
    x=anio
    y=unidades
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

## New trucks by engine type

<BarChart
    data={anual.filter(d => d.grupo === 'camion')}
    x=anio
    y=por_100000
    series=motor
    type=stacked
    yFmt=num0
    yAxisTitle="per 100,000 inhabitants"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="New trucks registered per year, per 100,000 inhabitants"
/>

<p class="text-xs text-gray-500">Truck sales follow the economic cycle: they fall in crises (2020) and recover with activity. Includes trucks of all weights and tractor units; vans are counted separately.</p>

## Best-selling makes and groups

```sql marcas
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_marcas_mensual)
SELECT
    m.grupo,
    CASE m.grupo WHEN 'camion' THEN 'Camiones' ELSE 'Autobuses' END AS vehiculo,
    m.grupo_empresarial,
    m.marca,
    sum(m.matriculaciones) AS unidades
FROM mother.movilidad_marcas_mensual m, ult u
WHERE m.grupo IN ('camion', 'autobus')
  AND m.mes > u.mes - INTERVAL 12 MONTH
GROUP BY ALL
```

```sql grupos
WITH g AS (
    SELECT
        vehiculo,
        grupo_empresarial AS grupo,
        string_agg(marca, ', ' ORDER BY unidades DESC) AS marcas,
        sum(unidades) AS unidades
    FROM ${marcas}
    GROUP BY vehiculo, grupo_empresarial
)
SELECT *
FROM (
    SELECT *,
        unidades / sum(unidades) OVER (PARTITION BY vehiculo) AS cuota,
        row_number() OVER (PARTITION BY vehiculo ORDER BY unidades DESC) AS puesto
    FROM g
)
WHERE puesto <= 10
ORDER BY vehiculo DESC, unidades DESC
```

The ten groups with the most registrations over the last 12 months. For vehicles finished by a bodybuilder (most buses and many trucks) the chassis make is counted: a bus with an Irizar or Castrosua body on a Scania chassis counts as a Scania.

<DataTable data={grupos} rows=20 groupBy=vehiculo groupsOpen=true>
    <Column id=grupo title="Group" />
    <Column id=marcas title="Makes" wrap=true />
    <Column id=unidades title="Units" fmt=num0 />
    <Column id=cuota title="Share" fmt=pct1 contentType=bar barColor="#ddd6fe" />
</DataTable>

<p class="text-xs text-gray-500">Group by majority owner: Scania and MAN belong to the Volkswagen group (Traton); Volvo and Renault Trucks to AB Volvo (separate from Volvo Cars, which is owned by Geely); Mercedes-Benz, Setra and Fuso to Daimler Truck. The full ranking, by month and engine type, is in <a href="/en/movilidad/marcas-y-modelos">Best-selling makes and models</a>.</p>

## Age of those on the road

```sql antiguedad
SELECT
    CASE grupo WHEN 'camion' THEN 'Camiones' WHEN 'autobus' THEN 'Autobuses' ELSE 'Turismos' END AS vehiculo,
    antiguedad,
    CASE antiguedad WHEN '0-4' THEN 1 WHEN '5-9' THEN 2 WHEN '10-14' THEN 3 WHEN '15-19' THEN 4 WHEN '20+' THEN 5 ELSE 6 END AS orden,
    CASE antiguedad WHEN '0-4' THEN 'Menos de 5 años' WHEN '5-9' THEN '5 a 9 años' WHEN '10-14' THEN '10 a 14 años'
        WHEN '15-19' THEN '15 a 19 años' WHEN '20+' THEN '20 años o más' ELSE 'Sin dato' END AS tramo,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo IN ('camion', 'autobus', 'turismo')
  AND mes = (SELECT max(mes) FROM mother.movilidad_parque_provincia)
GROUP BY ALL
ORDER BY orden
```

```sql tramos
SELECT DISTINCT tramo, orden FROM ${antiguedad} ORDER BY orden
```

<BarChart
    data={antiguedad}
    x=vehiculo
    y=vehiculos
    series=tramo
    type=stacked100
    swapXY=true
    yFmt=pct0
    seriesOrder={tramos.map(d => d.tramo)}
    colorPalette={['#0f766e', '#5eead4', '#fde68a', '#f59e0b', '#b91c1c', '#d1d5db']}
    title="Vehicles on the road by age (passenger cars for reference)"
/>

<p class="text-xs text-gray-500">DGT register of active vehicles, latest month published. More detail, by province and municipality, in <a href="/en/movilidad/parque">Vehicle fleet</a>.</p>

---

## Sources and notes

- **[DGT – Vehicle registration microdata (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, monthly since January 2015. Only ordinary registrations of new vehicles.
- **[DGT – Vehicle fleet](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**, latest month published.
- Trucks: the DGT's truck and tractor-unit types, of any weight. Buses: buses and coaches, including articulated and double-decker ones. Zero emissions: battery electric (BEV) and hydrogen fuel cell.

<LastRefreshed prefix="Data updated" />
