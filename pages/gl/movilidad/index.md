---
i18n_origen: 59d7fcbfaeaa
title: Mobilidade
description: "Mobilidade en España: coches que se venden e circulan por tipo de motor, transición ao coche eléctrico, puntos de recarga e viaxeiros de metro, autobús, tren e avión."
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
SELECT t.mes, t.viajeros_por_1000_hab AS valor
FROM mother.movilidad_transporte_modos AS t
WHERE t.clave = 'total'
  AND t.mes >= (SELECT max(mes) FROM mother.movilidad_transporte_modos) - INTERVAL 35 MONTH
ORDER BY t.mes
```

# 🚦 Mobilidade

Como nos movemos en España: os coches que se compran e os que circulan, o avance do coche eléctrico, onde se pode recargar e cantos viaxeiros usan o transporte público.

<Grid cols=4>
    <KpiCard
        title="Turismos novos enchufables"
        value={cuota_ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(cuota_ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="eléctricos + híbridos enchufables · {cuota_ultimo[0]?.mes_texto}"
        change={cuota_ultimo[0]?.cuota_anio_antes != null ? ((cuota_ultimo[0].cuota_enchufables - cuota_ultimo[0].cuota_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un ano antes"
        direction="positive-up"
        source="DGT"
        href="/gl/movilidad/coche-electrico"
        sparklineData={cuota.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Turismos en circulación"
        value={parque[0]?.turismos}
        formattedValue="{formatNumber(1000 * parque[0]?.turismos / parque[0]?.poblacion, 0)} por 1.000 hab."
        period="{formatCompact(parque[0]?.turismos, 1)} turismos · {formatNumber(parque[0]?.turismos_enchufables / parque[0]?.turismos / 0.01, 1)} % enchufables · {parque[0]?.mes_texto}"
        source="DGT"
        href="/gl/movilidad/parque"
    />
    <KpiCard
        title="Puntos de recarga públicos"
        value={recarga[0]?.puntos}
        formattedValue="{formatNumber(100000 * recarga[0]?.puntos / recarga[0]?.poblacion, 0)} por 100.000 hab."
        period="{formatNumber(recarga[0]?.puntos, 0)} puntos, {formatNumber(recarga[0]?.rapidos, 0)} rápidos (≥50 kW)"
        source="NAP DGT / MITECO"
        href="/gl/movilidad/recarga"
    />
    <KpiCard
        title="Viaxeiros de transporte público"
        value={transporte[0]?.viajeros}
        formattedValue="{formatNumber(transporte[0]?.viajeros / transporte[0]?.poblacion, 1)} viaxes por hab."
        period="ao mes · {formatCompact(transporte[0]?.viajeros, 1)} viaxeiros · {transporte[0]?.mes_texto}"
        source="INE"
        href="/gl/movilidad/transporte-publico"
        sparklineData={transporte_serie}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose my-6">
    <a href="/gl/movilidad/coche-electrico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚡</span> Coche eléctrico</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Turismos novos por tipo de motor cada mes desde 2015, cota de eléctricos por provincia e emisións de CO2.</p>
    </a>
    <a href="/gl/movilidad/marcas-y-modelos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚗</span> Marcas e modelos máis vendidos</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Clasificación mensual de coches, motos, furgonetas, camións e autobuses por marca, modelo e grupo, filtrable por motor e por canle (particulares ou frotas).</p>
    </a>
    <a href="/gl/movilidad/parque" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🅿️ Parque de vehículos</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Os vehículos que circulan hoxe: motor, etiqueta ambiental, antigüidade e modelos máis comúns, por provincia e concello.</p>
    </a>
    <a href="/gl/movilidad/camiones-y-autobuses" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚚</span> Camións e autobuses</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Matriculacións por tipo de motor, avance do autobús eléctrico, grupos máis vendidos e antigüidade dos que circulan.</p>
    </a>
    <a href="/gl/movilidad/flotas-e-impuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏝️</span> Os paraísos fiscais das frotas</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Aldeas de unhas decenas de veciños con miles de coches de empresa: onde se matriculan as frotas para pagar menos imposto de circulación.</p>
    </a>
    <a href="/gl/movilidad/recarga" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔌</span> Puntos de recarga</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Mapa dos puntos públicos por potencia e operador, e coches enchufables por punto en cada provincia.</p>
    </a>
    <a href="/gl/movilidad/transporte-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚇</span> Transporte público</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Viaxeiros de metro, autobús, Cercanías, AVE e avión cada mes, e o metro das sete cidades que o teñen.</p>
    </a>
</div>

<LastRefreshed prefix="Datos actualizados" />
