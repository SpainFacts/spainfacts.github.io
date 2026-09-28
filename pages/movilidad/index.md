---
title: Movilidad
description: "Movilidad en España: coches que se venden y circulan por tipo de motor, transición al coche eléctrico, puntos de recarga y viajeros de metro, autobús, tren y avión."
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
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
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND distintivo = 'SIN') AS turismos_sin_distintivo
FROM mother.movilidad_parque_provincia
GROUP BY mes
```

```sql recarga
SELECT sum(puntos) AS puntos, sum(puntos_rapidos) AS rapidos FROM mother.movilidad_recarga_provincia
```

```sql transporte
SELECT
    strftime(mes, '%m/%Y') AS mes_texto,
    viajeros
FROM mother.movilidad_transporte_modos
WHERE clave = 'total'
ORDER BY mes DESC
LIMIT 1
```

# 🚦 Movilidad

Cómo nos movemos en España: los coches que se compran y los que circulan, el avance del coche eléctrico, dónde se puede recargar y cuántos viajeros usan el transporte público.

<Grid cols=4>
    <KpiCard
        title="Turismos nuevos enchufables"
        value={cuota_ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(cuota_ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="eléctricos + híbridos enchufables · {cuota_ultimo[0]?.mes_texto}"
        change={cuota_ultimo[0]?.cuota_anio_antes != null ? ((cuota_ultimo[0].cuota_enchufables - cuota_ultimo[0].cuota_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un año antes"
        direction="positive-up"
        source="DGT"
        href="/movilidad/coche-electrico"
        sparklineData={cuota.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Turismos en circulación"
        value={parque[0]?.turismos}
        formattedValue={formatCompact(parque[0]?.turismos, 1)}
        period="{formatNumber(100 * parque[0]?.turismos_enchufables / parque[0]?.turismos, 1)} % enchufables · {parque[0]?.mes_texto}"
        source="DGT"
        href="/movilidad/parque"
    />
    <KpiCard
        title="Puntos de recarga públicos"
        value={recarga[0]?.puntos}
        formattedValue={formatNumber(recarga[0]?.puntos, 0)}
        period="{formatNumber(recarga[0]?.rapidos, 0)} rápidos (≥50 kW)"
        source="NAP DGT / MITECO"
        href="/movilidad/recarga"
    />
    <KpiCard
        title="Viajeros de transporte público"
        value={transporte[0]?.viajeros}
        formattedValue={formatCompact(transporte[0]?.viajeros, 1)}
        period={transporte[0]?.mes_texto}
        source="INE"
        href="/movilidad/transporte-publico"
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose my-6">
    <a href="/movilidad/coche-electrico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">⚡ Coche eléctrico</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Turismos nuevos por tipo de motor cada mes desde 2015, cuota de eléctricos por provincia y emisiones de CO2.</p>
    </a>
    <a href="/movilidad/marcas-y-modelos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🚗 Marcas y modelos más vendidos</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Ranking mensual de coches, motos y furgonetas, filtrable por eléctricos, híbridos, gasolina o diésel.</p>
    </a>
    <a href="/movilidad/parque" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🅿️ Parque de vehículos</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Los vehículos que circulan hoy: motor, etiqueta ambiental, antigüedad y modelos más comunes, por provincia y municipio.</p>
    </a>
    <a href="/movilidad/recarga" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🔌 Puntos de recarga</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Mapa de los puntos públicos por potencia y operador, y coches enchufables por punto en cada provincia.</p>
    </a>
    <a href="/movilidad/transporte-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🚇 Transporte público</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Viajeros de metro, autobús, Cercanías, AVE y avión cada mes, y el metro de las siete ciudades que lo tienen.</p>
    </a>
</div>

<LastRefreshed prefix="Datos actualizados" />
