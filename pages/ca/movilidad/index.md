---
title: Mobilitat
description: "Mobilitat a Espanya: cotxes que es venen i circulen per tipus de motor, transició al cotxe elèctric, punts de recàrrega i viatgers de metro, autobús, tren i avió."
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

# 🚦 Mobilitat

Com ens movem a Espanya: els cotxes que es compren i els que circulen, l'avenç del cotxe elèctric, on es pot recarregar i quants viatgers fan servir el transport públic.

<Grid cols=4>
    <KpiCard
        title="Turismes nous endollables"
        value={cuota_ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(cuota_ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="elèctrics + híbrids endollables · {cuota_ultimo[0]?.mes_texto}"
        change={cuota_ultimo[0]?.cuota_anio_antes != null ? ((cuota_ultimo[0].cuota_enchufables - cuota_ultimo[0].cuota_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un any abans"
        direction="positive-up"
        source="DGT"
        href="/ca/movilidad/coche-electrico"
        sparklineData={cuota.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Turismes en circulació"
        value={parque[0]?.turismos}
        formattedValue="{formatNumber(1000 * parque[0]?.turismos / parque[0]?.poblacion, 0)} per 1.000 hab."
        period="{formatCompact(parque[0]?.turismos, 1)} turismes · {formatNumber(parque[0]?.turismos_enchufables / parque[0]?.turismos / 0.01, 1)} % endollables · {parque[0]?.mes_texto}"
        source="DGT"
        href="/ca/movilidad/parque"
    />
    <KpiCard
        title="Punts de recàrrega públics"
        value={recarga[0]?.puntos}
        formattedValue="{formatNumber(100000 * recarga[0]?.puntos / recarga[0]?.poblacion, 0)} per 100.000 hab."
        period="{formatNumber(recarga[0]?.puntos, 0)} punts, {formatNumber(recarga[0]?.rapidos, 0)} ràpids (≥50 kW)"
        source="NAP DGT / MITECO"
        href="/ca/movilidad/recarga"
    />
    <KpiCard
        title="Viatgers de transport públic"
        value={transporte[0]?.viajeros}
        formattedValue="{formatNumber(transporte[0]?.viajeros / transporte[0]?.poblacion, 1)} viatges per hab."
        period="al mes · {formatCompact(transporte[0]?.viajeros, 1)} viatgers · {transporte[0]?.mes_texto}"
        source="INE"
        href="/ca/movilidad/transporte-publico"
        sparklineData={transporte_serie}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose my-6">
    <a href="/ca/movilidad/coche-electrico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚡</span> Cotxe elèctric</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Turismes nous per tipus de motor cada mes des del 2015, quota d'elèctrics per província i emissions de CO2.</p>
    </a>
    <a href="/ca/movilidad/marcas-y-modelos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚗</span> Marques i models més venuts</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Rànquing mensual de cotxes, motos, furgonetes, camions i autobusos per marca, model i grup, filtrable per motor i per canal (particulars o flotes).</p>
    </a>
    <a href="/ca/movilidad/parque" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🅿️ Parc de vehicles</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Els vehicles que circulen avui: motor, etiqueta ambiental, antiguitat i models més comuns, per província i municipi.</p>
    </a>
    <a href="/ca/movilidad/camiones-y-autobuses" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚚</span> Camions i autobusos</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Matriculacions per tipus de motor, avenç de l'autobús elèctric, grups més venuts i antiguitat dels que circulen.</p>
    </a>
    <a href="/ca/movilidad/flotas-e-impuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏝️</span> Els paradisos fiscals de les flotes</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Pobles d'unes desenes de veïns amb milers de cotxes d'empresa: on es matriculen les flotes per pagar menys impost de circulació.</p>
    </a>
    <a href="/ca/movilidad/recarga" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔌</span> Punts de recàrrega</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Mapa dels punts públics per potència i operador, i cotxes endollables per punt a cada província.</p>
    </a>
    <a href="/ca/movilidad/transporte-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚇</span> Transport públic</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Viatgers de metro, autobús, Rodalies, AVE i avió cada mes, i el metro de les set ciutats que en tenen.</p>
    </a>
</div>

<LastRefreshed prefix="Dades actualitzades" />
