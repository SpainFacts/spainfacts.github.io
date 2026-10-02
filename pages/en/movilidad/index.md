---
title: Mobility
description: "Mobility in Spain: cars sold and on the road by engine type, the shift to electric cars, charging points, and passengers on metro, bus, rail and air."
i18n_origen: 672121895650
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql cuota
SELECT
    mes,
    strftime(mes, '%m/%Y') AS mes_texto,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS cuota_enchufables,
    sum(matriculaciones) AS turismos
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY mes
ORDER BY mes
```

```sql cuota_ultimo
SELECT c.*, a.cuota_enchufables AS cuota_anio_antes
FROM ${cuota} c
LEFT JOIN ${cuota} a ON a.mes = c.mes - INTERVAL 12 MONTH
ORDER BY c.mes DESC
LIMIT 1
```

```sql parque
SELECT
    strftime(mes, '%m/%Y') AS mes_texto,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo') AS turismos,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND energia IN ('bev', 'phev')) AS turismos_enchufables,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND distintivo = 'SIN') AS turismos_sin_distintivo,
    any_value((SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1)) AS poblacion
FROM mother.movilidad_parque_provincia
GROUP BY mes
```

```sql recarga
SELECT sum(puntos) AS puntos, sum(puntos_rapidos) AS rapidos, (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion FROM mother.movilidad_recarga_provincia
```

```sql transporte
SELECT
    strftime(mes, '%m/%Y') AS mes_texto,
    viajeros,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion
FROM mother.movilidad_transporte_modos
WHERE clave = 'total'
ORDER BY mes DESC
LIMIT 1
```

```sql transporte_serie
-- Viajeros por cada 1.000 habitantes, últimos 36 meses
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios
    WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT t.mes, 1000 * t.viajeros / p.poblacion AS valor
FROM mother.movilidad_transporte_modos AS t
JOIN pob AS p ON p.anio = least(CAST(year(t.mes) AS INTEGER), (SELECT max(anio) FROM pob))
WHERE t.clave = 'total'
  AND t.mes >= (SELECT max(mes) FROM mother.movilidad_transporte_modos) - INTERVAL 35 MONTH
ORDER BY t.mes
```

# 🚦 Mobility

How people get around in Spain: the cars being bought and the ones on the road, the progress of electric cars, where you can charge, and how many passengers use public transport.

<Grid cols=4>
    <KpiCard
        title="New plug-in cars"
        value={cuota_ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(cuota_ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="battery electric + plug-in hybrids · {cuota_ultimo[0]?.mes_texto}"
        change={cuota_ultimo[0]?.cuota_anio_antes != null ? ((cuota_ultimo[0].cuota_enchufables - cuota_ultimo[0].cuota_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. a year earlier"
        direction="positive-up"
        source="DGT"
        href="/en/movilidad/coche-electrico"
        sparklineData={cuota.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Cars on the road"
        value={parque[0]?.turismos}
        formattedValue="{formatNumber(1000 * parque[0]?.turismos / parque[0]?.poblacion, 0)} per 1,000 people"
        period="{formatCompact(parque[0]?.turismos, 1)} cars · {formatNumber(parque[0]?.turismos_enchufables / parque[0]?.turismos / 0.01, 1)}% plug-in · {parque[0]?.mes_texto}"
        source="DGT"
        href="/en/movilidad/parque"
    />
    <KpiCard
        title="Public charging points"
        value={recarga[0]?.puntos}
        formattedValue="{formatNumber(100000 * recarga[0]?.puntos / recarga[0]?.poblacion, 0)} per 100,000 people"
        period="{formatNumber(recarga[0]?.puntos, 0)} points, {formatNumber(recarga[0]?.rapidos, 0)} fast (≥50 kW)"
        source="NAP DGT / MITECO"
        href="/en/movilidad/recarga"
    />
    <KpiCard
        title="Public transport passengers"
        value={transporte[0]?.viajeros}
        formattedValue="{formatNumber(transporte[0]?.viajeros / transporte[0]?.poblacion, 1)} trips per person"
        period="per month · {formatCompact(transporte[0]?.viajeros, 1)} passengers · {transporte[0]?.mes_texto}"
        source="INE"
        href="/en/movilidad/transporte-publico"
        sparklineData={transporte_serie}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose my-6">
    <a href="/en/movilidad/coche-electrico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚡</span> Electric cars</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">New cars by engine type every month since 2015, electric share by province and CO2 emissions.</p>
    </a>
    <a href="/en/movilidad/marcas-y-modelos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚗</span> Best-selling makes and models</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Monthly ranking of cars, motorbikes, vans, trucks and buses by make, model and group, filterable by engine and by channel (private buyers or fleets).</p>
    </a>
    <a href="/en/movilidad/parque" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🅿️ Vehicle fleet</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">The vehicles on the road today: engine, environmental label, age and most common models, by province and municipality.</p>
    </a>
    <a href="/en/movilidad/camiones-y-autobuses" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚚</span> Trucks and buses</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Registrations by engine type, the rise of the electric bus, best-selling groups and the age of those on the road.</p>
    </a>
    <a href="/en/movilidad/flotas-e-impuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏝️</span> The fleet tax havens</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Villages of a few dozen residents with thousands of company cars: where fleets are registered to pay less vehicle tax.</p>
    </a>
    <a href="/en/movilidad/recarga" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔌</span> Charging points</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Map of public charging points by power and operator, and plug-in cars per point in each province.</p>
    </a>
    <a href="/en/movilidad/transporte-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚇</span> Public transport</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Metro, bus, Cercanías commuter rail, AVE high-speed rail and air passengers every month, and the metro in the seven cities that have one.</p>
    </a>
</div>

<LastRefreshed prefix="Data updated" />
