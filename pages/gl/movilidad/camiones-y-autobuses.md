---
i18n_origen: 4190a8292d58
title: Camións e autobuses
description: "Camións e autobuses en España: matriculacións por tipo de motor desde 2015, avance do autobús eléctrico, marcas e grupos máis vendidos e antigüidade dos que circulan."
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

# 🚚 Camións e autobuses

Os camións e autobuses son poucos fronte aos coches, pero percorren moitos máis quilómetros e queiman sobre todo gasóleo: o transporte pesado é unha parte importante das emisións do transporte por estrada. Aquí vese cantos se venden, con que motor e cantos anos teñen os que circulan.

<Grid cols=2>
    <KpiCard
        title="Autobuses novos de cero emisións"
        value={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="eléctricos e hidróxeno · 12 meses ata {cero_emisiones[0]?.mes_texto}"
        change={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. os 12 meses anteriores"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Camións novos de cero emisións"
        value={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="eléctricos e hidróxeno · {formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_diesel * 100, 0)} % diésel · 12 meses"
        change={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. os 12 meses anteriores"
        direction="positive-up"
        source="DGT"
    />
</Grid>

## Cota de cero emisións nos vehículos novos

<LineChart
    data={anual_cuota}
    x=anio
    y=cuota_cero
    series=vehiculo
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#0f766e', '#f59e0b']}
    title="Eléctricos puros e hidróxeno, % dos matriculados cada ano"
/>

<p class="text-xs text-gray-500">Os autobuses urbanos electrifícanse antes porque fan percorridos curtos e volven cada noite á cocheira, onde se cargan; as axudas europeas e as zonas de baixas emisións das cidades tamén empuxan. O camión de longo percorrido segue case todo en diésel: as baterías pesan e a rede de recarga para pesados apenas comeza. O último ano está incompleto.</p>

## Autobuses novos por tipo de motor

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

## Camións novos por tipo de motor

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
    title="Camións novos matriculados por ano, por 100.000 habitantes"
/>

<p class="text-xs text-gray-500">As vendas de camións seguen o ciclo económico: caen nas crises (2020) e recupéranse coa actividade. Inclúe camións de todos os pesos e cabezas tractoras; as furgonetas cóntanse á parte.</p>

## Marcas e grupos máis vendidos

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

Os dez grupos con máis matriculacións dos últimos 12 meses. Nos vehículos que remata un carroceiro (a maioría dos autobuses e moitos camións) cóntase a marca do chasis: un autobús con carrozaría de Irizar ou Castrosua sobre un chasis Scania conta como Scania.

<DataTable data={grupos} rows=20 groupBy=vehiculo groupsOpen=true>
    <Column id=grupo title="Grupo" />
    <Column id=marcas title="Marcas" wrap=true />
    <Column id=unidades title="Unidades" fmt=num0 />
    <Column id=cuota title="Cota" fmt=pct1 contentType=bar barColor="#ddd6fe" />
</DataTable>

<p class="text-xs text-gray-500">Grupo segundo o dono maioritario: Scania e MAN son do grupo Volkswagen (Traton); Volvo e Renault Trucks, de AB Volvo (distinta de Volvo Cars, que é de Geely); Mercedes-Benz, Setra e Fuso, de Daimler Truck. O ranking completo, por mes e por tipo de motor, está en <a href="/gl/movilidad/marcas-y-modelos">Marcas e modelos</a>.</p>

## Antigüidade dos que circulan

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
    title="Vehículos en circulación por antigüidade (os turismos, como referencia)"
/>

<p class="text-xs text-gray-500">Parque de vehículos en alta da DGT, último mes publicado. Máis detalle, por provincia e concello, en <a href="/gl/movilidad/parque">Parque de vehículos</a>.</p>

---

## Fontes e notas

- **[DGT – Microdatos de matriculacións de vehículos (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual desde xaneiro de 2015. Só matriculacións ordinarias de vehículos novos.
- **[DGT – Parque de vehículos](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**, último mes publicado.
- Camións: os tipos de camión e cabeza tractora da DGT, de calquera peso. Autobuses: autobuses e autocares, incluídos os articulados e os de dous pisos. Cero emisións: eléctricos puros (BEV) e de pila de hidróxeno.

<LastRefreshed prefix="Datos actualizados" />
