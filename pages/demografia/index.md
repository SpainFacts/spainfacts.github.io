---
title: Demografía
description: "Población de España con datos oficiales del INE: crecimiento, natalidad y fecundidad, envejecimiento, reparto territorial, hombres y mujeres y hogares, por comunidad y provincia."
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
</script>

```sql edades
SELECT CAST(anio AS INTEGER) AS anio, poblacion, pct_65, pct_80, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, tasa_natalidad, tasa_mortalidad,
    vegetativo_1000, fecundidad, crecimiento_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql poblacion_serie
SELECT anio, poblacion / 1e6 AS valor FROM ${edades}
```

```sql crecimiento_ultimo
SELECT anio, crecimiento_1000, vegetativo_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000,
    100.0 * resto / crecimiento AS pct_resto
FROM ${anual}
WHERE crecimiento IS NOT NULL
ORDER BY anio DESC
LIMIT 1
```

```sql primer_negativo
SELECT min(anio) AS anio FROM ${anual} WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👪 Demografía

Cuántos somos, cuántos nacen y mueren, cuánto crece la población y por qué, cómo envejece y cómo se reparte por el territorio. Todas las cifras son oficiales del INE y se dan por habitante o en porcentaje para poder comparar años y territorios.

<Grid cols=4>
    <KpiCard
        title="Población"
        value={edades.slice(-1)[0]?.poblacion}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.poblacion / 1e6, 2)} millones"
        period="a 1 de enero de {edades.slice(-1)[0]?.anio}"
        change={100 * (edades.slice(-1)[0]?.poblacion / edades.slice(-2)[0]?.poblacion - 1)}
        changeUnit="%"
        changePeriod="en un año"
        direction="neutral"
        source="INE"
        href="/demografia/evolucion-poblacion"
        sparklineData={poblacion_serie}
    />
    <KpiCard
        title="Natalidad"
        value={anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.tasa_natalidad, 2)} por 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.nacimientos, 0)} nacimientos en {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Hijos por mujer"
        value={anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(anual.slice(-1)[0]?.fecundidad, 2)}
        period="indicador coyuntural de fecundidad, {anual.slice(-1)[0]?.anio} (el reemplazo generacional es 2,1)"
        source="INE"
        href="/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Mayores de 65 años"
        value={edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.pct_65, 1)} %"
        period="de la población · edad media {formatNumber(edades.slice(-1)[0]?.edad_media, 1)} años"
        source="INE"
        href="/demografia/estructura-edades"
        sparklineData={edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
</Grid>

## De dónde viene el crecimiento de la población

La población cambia por dos vías: la diferencia entre nacimientos y defunciones (crecimiento vegetativo) y la diferencia entre quienes llegan a vivir a España y quienes se van (saldo migratorio).

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
ORDER BY anio
```

<BarChart
    data={componentes}
    x=anio
    y=por_1000
    series=componente
    type=stacked
    yFmt=num1
    xFmt="####"
    colorPalette={['#be185d', '#0f766e']}
    yAxisTitle="por 1.000 habitantes"
    title="Crecimiento anual de la población por 1.000 habitantes y sus componentes"
/>

<p class="text-xs text-gray-500">Crecimiento = población a 1 de enero del año siguiente menos la del año, según la Estadística Continua de Población. "Migración y ajustes" es la parte del crecimiento que no explican nacimientos y defunciones. Coincide casi exactamente con el saldo migratorio con el extranjero que mide la Estadística de Migraciones desde 2021: en {crecimiento_ultimo[0]?.anio}, {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} frente a {formatNumber(crecimiento_ultimo[0]?.saldo_exterior_1000, 1)} por 1.000 habitantes (ver <a href="/sociedad/inmigracion">Inmigración</a>).</p>

{#if crecimiento_ultimo[0]?.vegetativo_1000 < 0}

En {crecimiento_ultimo[0]?.anio} la población creció {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} personas por cada 1.000 habitantes ({formatNumber(crecimiento_ultimo[0]?.crecimiento, 0)} en total). Murieron más personas de las que nacieron ({formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} por 1.000), algo que ocurre todos los años desde {primer_negativo[0]?.anio}, así que todo el crecimiento procede de la migración.

{:else}

En {crecimiento_ultimo[0]?.anio} la población creció {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} personas por cada 1.000 habitantes: {formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} por nacimientos menos defunciones y {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} por migración y ajustes.

{/if}

## Explora

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/demografia/evolucion-poblacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">📈 Evolución de la población</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Población desde 1971, crecimiento anual por 1.000 habitantes y cuánto aportan nacimientos, defunciones y migración en cada comunidad.</p>
    </a>
    <a href="/demografia/natalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-pink-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">👶 Natalidad y fecundidad</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Nacimientos y defunciones por 1.000 habitantes, hijos por mujer, edad de las madres y nacimientos de madre extranjera, por comunidad y provincia.</p>
    </a>
    <a href="/demografia/estructura-edades" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-rose-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🔺 Edades y envejecimiento</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Pirámides de población de España, cada comunidad y cada provincia; mayores de 65 y de 80 años, dependencia y edad media.</p>
    </a>
    <a href="/demografia/distribucion-territorial" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-emerald-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🗺️ Reparto territorial</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Qué provincias ganan y pierden población, el peso de cada comunidad y el porcentaje de nacidos en el extranjero en cada provincia.</p>
    </a>
    <a href="/demografia/poblacion-sexo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-purple-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">⚖️ Hombres y mujeres</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Hombres por cada 100 mujeres según la edad, a lo largo del tiempo y en cada provincia.</p>
    </a>
    <a href="/demografia/hogares" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🏠 Hogares</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Tamaño medio del hogar y hogares de una sola persona, por comunidad y provincia.</p>
    </a>
</div>

---

## Fuentes y notas

- **[INE – Estadística Continua de Población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177095)**: población a 1 de enero por provincia, edad y sexo (tabla 56945), por lugar de nacimiento (56948) y nacionalidad (56947), y hogares (60131 a 60134).
- **[INE – Movimiento Natural de la Población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: nacimientos (tabla 6524) y defunciones (6561) por provincia de residencia.
- **[INE – Indicadores Demográficos Básicos](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: tasas de natalidad y mortalidad, fecundidad, edad media a la maternidad y nacidos de madre extranjera.
- **[INE – Estadística de Migraciones y Cambios de Residencia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)**: saldo migratorio con el extranjero desde 2021 (ver [Inmigración](/sociedad/inmigracion)).

<LastRefreshed prefix="Datos actualizados" />
