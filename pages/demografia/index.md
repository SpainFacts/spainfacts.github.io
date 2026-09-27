---
title: Demografía y Población · SpainFacts
description: Evolución, distribución y estructura de la población española según datos oficiales del INE.
---

<script>
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql total_poblacion
SELECT Total AS valor, Year AS periodo_txt, Year
FROM mother.totalAno
ORDER BY Year DESC
LIMIT 2
```

```sql sparkline_poblacion
SELECT Total AS valor
FROM mother.totalAno
WHERE Year >= 2000
ORDER BY Year ASC
```

# Demografía y Población de España

Los cambios en la población de España reflejan tendencias demográficas, económicas y sociales que han moldeado el país a lo largo del tiempo: desde el baby boom y la transición demográfica hasta el envejecimiento y los flujos migratorios recientes.

## Explora Demografía

<Grid cols=2>
    <a href="/demografia/evolucion-poblacion" class="block rounded-xl border border-blue-200 dark:border-blue-800 bg-blue-50/60 dark:bg-blue-950/30 p-5 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-2xl">📈</span>
        <h3 class="mt-3 text-base font-bold text-gray-900 dark:text-white">Evolución de la población</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cambios anuales de población y comparación entre periodos.</p>
        <span class="mt-3 inline-block text-sm font-semibold text-blue-600 dark:text-blue-400">Ver subtema →</span>
    </a>
    <a href="/demografia/poblacion-sexo" class="block rounded-xl border border-purple-200 dark:border-purple-800 bg-purple-50/60 dark:bg-purple-950/30 p-5 hover:border-purple-400 dark:hover:border-purple-600 transition-colors no-underline">
        <span class="text-2xl">👥</span>
        <h3 class="mt-3 text-base font-bold text-gray-900 dark:text-white">Población por sexo</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Distribución y evolución comparada de mujeres y hombres.</p>
        <span class="mt-3 inline-block text-sm font-semibold text-purple-600 dark:text-purple-400">Ver subtema →</span>
    </a>
    <a href="/demografia/distribucion-territorial" class="block rounded-xl border border-emerald-200 dark:border-emerald-800 bg-emerald-50/60 dark:bg-emerald-950/30 p-5 hover:border-emerald-400 dark:hover:border-emerald-600 transition-colors no-underline">
        <span class="text-2xl">🗺️</span>
        <h3 class="mt-3 text-base font-bold text-gray-900 dark:text-white">Distribución territorial</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Población por provincia y sus cambios en el tiempo.</p>
        <span class="mt-3 inline-block text-sm font-semibold text-emerald-600 dark:text-emerald-400">Ver subtema →</span>
    </a>
    <a href="/demografia/estructura-edades" class="block rounded-xl border border-rose-200 dark:border-rose-800 bg-rose-50/60 dark:bg-rose-950/30 p-5 hover:border-rose-400 dark:hover:border-rose-600 transition-colors no-underline">
        <span class="text-2xl">🔺</span>
        <h3 class="mt-3 text-base font-bold text-gray-900 dark:text-white">Estructura por edades</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Pirámide poblacional por edad y sexo.</p>
        <span class="mt-3 inline-block text-sm font-semibold text-rose-600 dark:text-rose-400">Ver subtema →</span>
    </a>
</Grid>

---

## España en cifras demográficas

<Grid cols=1>
    <KpiCard
        title="Población Total"
        value={total_poblacion[0].valor}
        formattedValue="{formatCompact(total_poblacion[0].valor, 2)}"
        unit="hab."
        period="{total_poblacion[0].periodo_txt}"
        change={total_poblacion.length > 1 ? (((total_poblacion[0].valor - total_poblacion[1].valor) / total_poblacion[1].valor) * 100).toFixed(2) : null}
        changeUnit="%"
        changePeriod="interanual"
        direction="positive-up"
        source="INE"
        sparklineData={sparkline_poblacion}
    />
</Grid>

---

## Principios de Transparencia

Todos los datos provienen directamente del **Instituto Nacional de Estadística (INE)** y se actualizan automáticamente desde las series estadísticas oficiales.

<LastRefreshed prefix="Última sincronización de datos con fuentes oficiales" />
