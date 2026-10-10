---
title: Mugikortasuna
description: "Mugikortasuna Espainian: motor motaren arabera saltzen eta zirkulatzen duten autoak, auto elektrikorako trantsizioa, karga-puntuak eta metro, autobus, tren eta hegazkineko bidaiariak."
i18n_origen: 55dddfc9d8f7
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

# 🚦 Mugikortasuna

Nola mugitzen garen Espainian: erosten diren autoak eta zirkulatzen dutenak, auto elektrikoaren aurrerapena, non karga daitekeen eta zenbat bidaiarik erabiltzen duten garraio publikoa.

<Grid cols=4>
    <KpiCard
        title="Turismo berri entxufagarriak"
        value={cuota_ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(cuota_ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="elektrikoak + hibrido entxufagarriak · {cuota_ultimo[0]?.mes_texto}"
        change={cuota_ultimo[0]?.cuota_anio_antes != null ? ((cuota_ultimo[0].cuota_enchufables - cuota_ultimo[0].cuota_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-up"
        source="DGT"
        href="/eu/movilidad/coche-electrico"
        sparklineData={cuota.map(d => ({...d, valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Zirkulazioan dauden turismoak"
        value={parque[0]?.turismos}
        formattedValue="{formatNumber(1000 * parque[0]?.turismos / parque[0]?.poblacion, 0)} 1.000 biztanleko"
        period="{formatCompact(parque[0]?.turismos, 1)} turismo · {formatNumber(parque[0]?.turismos_enchufables / parque[0]?.turismos / 0.01, 1)} % entxufagarriak · {parque[0]?.mes_texto}"
        source="DGT"
        href="/eu/movilidad/parque"
    />
    <KpiCard
        title="Karga-puntu publikoak"
        value={recarga[0]?.puntos}
        formattedValue="{formatNumber(100000 * recarga[0]?.puntos / recarga[0]?.poblacion, 0)} 100.000 biztanleko"
        period="{formatNumber(recarga[0]?.puntos, 0)} puntu, {formatNumber(recarga[0]?.rapidos, 0)} azkar (≥50 kW)"
        source="NAP DGT / MITECO"
        href="/eu/movilidad/recarga"
    />
    <KpiCard
        title="Garraio publikoko bidaiariak"
        value={transporte[0]?.viajeros}
        formattedValue="{formatNumber(transporte[0]?.viajeros / transporte[0]?.poblacion, 1)} bidaia biztanleko"
        period="hilean · {formatCompact(transporte[0]?.viajeros, 1)} bidaiari · {transporte[0]?.mes_texto}"
        source="INE"
        href="/eu/movilidad/transporte-publico"
        sparklineData={transporte_serie}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose my-6">
    <a href="/eu/movilidad/coche-electrico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚡</span> Auto elektrikoa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Turismo berriak motor motaren arabera hilero 2015etik, elektrikoen kuota probintziaka eta CO2 isuriak.</p>
    </a>
    <a href="/eu/movilidad/marcas-y-modelos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚗</span> Marka eta modelo salduenak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Auto, moto, furgoneta, kamioi eta autobusen hileko sailkapena markaren, modeloaren eta taldearen arabera, motorraren eta kanalaren arabera iragazgarria (partikularrak edo flotak).</p>
    </a>
    <a href="/eu/movilidad/parque" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🅿️ Ibilgailu-parkea</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Gaur egun zirkulatzen duten ibilgailuak: motorra, ingurumen-etiketa, antzinatasuna eta modelo ohikoenak, probintziaka eta udalerrika.</p>
    </a>
    <a href="/eu/movilidad/camiones-y-autobuses" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚚</span> Kamioiak eta autobusak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Matrikulazioak motor motaren arabera, autobus elektrikoaren aurrerapena, talde salduenak eta zirkulatzen dutenen antzinatasuna.</p>
    </a>
    <a href="/eu/movilidad/flotas-e-impuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏝️</span> Flotentzako paradisu fiskalak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Hamarka bizilagun eta milaka enpresa-auto dituzten herriak: non matrikulatzen diren flotak zirkulazio-zerga gutxiago ordaintzeko.</p>
    </a>
    <a href="/eu/movilidad/recarga" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔌</span> Karga-puntuak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Puntu publikoen mapa potentziaren eta operadorearen arabera, eta auto entxufagarriak puntu bakoitzeko probintzia bakoitzean.</p>
    </a>
    <a href="/eu/movilidad/transporte-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚇</span> Garraio publikoa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Metro, autobus, Cercanías (aldiriko trenak), AVE eta hegazkineko bidaiariak hilero, eta metroa duten zazpi hirietako metroa.</p>
    </a>
</div>

<LastRefreshed prefix="Datuak eguneratuta" />
