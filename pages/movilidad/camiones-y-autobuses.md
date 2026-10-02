---
title: Camiones y autobuses
description: "Camiones y autobuses en España: matriculaciones por tipo de motor desde 2015, avance del autobús eléctrico, marcas y grupos más vendidos y antigüedad de los que circulan."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 🚚 Camiones y autobuses

Los camiones y autobuses son pocos frente a los coches, pero recorren muchos más kilómetros y queman sobre todo gasóleo: el transporte pesado es una parte importante de las emisiones del transporte por carretera. Aquí se ve cuántos se venden, con qué motor y cuántos años tienen los que circulan.

<Grid cols=2>
    <KpiCard
        title="Autobuses nuevos de cero emisiones"
        value={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="eléctricos e hidrógeno · 12 meses hasta {cero_emisiones[0]?.mes_texto}"
        change={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. los 12 meses anteriores"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Camiones nuevos de cero emisiones"
        value={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="eléctricos e hidrógeno · {formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_diesel * 100, 0)} % diésel · 12 meses"
        change={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. los 12 meses anteriores"
        direction="positive-up"
        source="DGT"
    />
</Grid>

## Cuota de cero emisiones en los vehículos nuevos

<LineChart
    data={anual_cuota}
    x=anio
    y=cuota_cero
    series=vehiculo
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#0f766e', '#f59e0b']}
    title="Eléctricos puros e hidrógeno, % de los matriculados cada año"
/>

<p class="text-xs text-gray-500">Los autobuses urbanos se electrifican antes porque hacen recorridos cortos y vuelven cada noche a la cochera, donde se cargan; las ayudas europeas y las zonas de bajas emisiones de las ciudades también empujan. El camión de largo recorrido sigue casi todo en diésel: las baterías pesan y la red de recarga para pesados apenas empieza. El último año está incompleto.</p>

## Autobuses nuevos por tipo de motor

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

## Camiones nuevos por tipo de motor

<BarChart
    data={anual.filter(d => d.grupo === 'camion')}
    x=anio
    y=por_100000
    series=motor
    type=stacked
    yFmt=num0
    yAxisTitle="por 100.000 habitantes"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Camiones nuevos matriculados por año, por 100.000 habitantes"
/>

<p class="text-xs text-gray-500">Las ventas de camiones siguen el ciclo económico: caen en las crisis (2020) y se recuperan con la actividad. Incluye camiones de todos los pesos y cabezas tractoras; las furgonetas se cuentan aparte.</p>

## Marcas y grupos más vendidos

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

Los diez grupos con más matriculaciones de los últimos 12 meses. En los vehículos que termina un carrocero (la mayoría de los autobuses y muchos camiones) se cuenta la marca del chasis: un autobús con carrocería de Irizar o Castrosua sobre un chasis Scania cuenta como Scania.

<DataTable data={grupos} rows=20 groupBy=vehiculo groupsOpen=true>
    <Column id=grupo title="Grupo" />
    <Column id=marcas title="Marcas" wrap=true />
    <Column id=unidades title="Unidades" fmt=num0 />
    <Column id=cuota title="Cuota" fmt=pct1 contentType=bar barColor="#ddd6fe" />
</DataTable>

<p class="text-xs text-gray-500">Grupo según el dueño mayoritario: Scania y MAN son del grupo Volkswagen (Traton); Volvo y Renault Trucks, de AB Volvo (distinta de Volvo Cars, que es de Geely); Mercedes-Benz, Setra y Fuso, de Daimler Truck. El ranking completo, por mes y por tipo de motor, está en <a href="/movilidad/marcas-y-modelos">Marcas y modelos</a>.</p>

## Antigüedad de los que circulan

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
    title="Vehículos en circulación por antigüedad (los turismos, como referencia)"
/>

<p class="text-xs text-gray-500">Parque de vehículos en alta de la DGT, último mes publicado. Más detalle, por provincia y municipio, en <a href="/movilidad/parque">Parque de vehículos</a>.</p>

---

## Fuentes y notas

- **[DGT – Microdatos de matriculaciones de vehículos (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual desde enero de 2015. Solo matriculaciones ordinarias de vehículos nuevos.
- **[DGT – Parque de vehículos](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**, último mes publicado.
- Camiones: los tipos de camión y cabeza tractora de la DGT, de cualquier peso. Autobuses: autobuses y autocares, incluidos los articulados y los de dos pisos. Cero emisiones: eléctricos puros (BEV) y de pila de hidrógeno.

<LastRefreshed prefix="Datos actualizados" />
