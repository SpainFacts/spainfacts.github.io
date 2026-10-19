---
title: Demografía
description: "Población de España con datos oficiales del INE: crecimiento, natalidad y fecundidad, envejecimiento, reparto territorial, hombres y mujeres y hogares, por comunidad y provincia."
og:
  image: https://spainfacts.org/og-spainfacts.png
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

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Demografía</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Demografía</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Cuántos somos, cuántos nacen y mueren, cuánto crece la población y por qué, cómo envejece y cómo se reparte por el territorio. Todas las cifras son oficiales del INE y se dan por habitante o en porcentaje para poder comparar años y territorios.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por 1.000 habitantes</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">CCAA y provincias</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">INE (ECP · MNP)</span>
    </div>
</div>

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
    <a href="/demografia/evolucion-poblacion" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Evolución de la población</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Población desde 1971, crecimiento anual por 1.000 habitantes y cuánto aportan nacimientos, defunciones y migración en cada comunidad.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/demografia/natalidad" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 12h.01"/><path d="M15 12h.01"/><path d="M10 16c.5.3 1.2.5 2 .5s1.5-.2 2-.5"/><path d="M19 6.3a9 9 0 0 1 1.8 3.9 2 2 0 0 1 0 3.6 9 9 0 0 1-17.6 0 2 2 0 0 1 0-3.6A9 9 0 0 1 12 3c2 0 3.5 1.1 3.5 2.5s-.9 2.5-2 2.5c-.8 0-1.5-.4-1.5-1"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Natalidad y fecundidad</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Nacimientos y defunciones por 1.000 habitantes, hijos por mujer, edad de las madres y nacimientos de madre extranjera, por comunidad y provincia.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/demografia/estructura-edades" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 22 22 22 12 2"/><line x1="7" y1="12" x2="17" y2="12"/><line x1="4.5" y1="17" x2="19.5" y2="17"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Edades y envejecimiento</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Pirámides de población de España, cada comunidad y cada provincia; mayores de 65 y de 80 años, dependencia y edad media.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/demografia/distribucion-territorial" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/><line x1="9" y1="3" x2="9" y2="18"/><line x1="15" y1="6" x2="15" y2="21"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Reparto territorial</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Qué provincias ganan y pierden población, el peso de cada comunidad y el porcentaje de nacidos en el extranjero en cada provincia.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/demografia/poblacion-sexo" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Hombres y mujeres</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Hombres por cada 100 mujeres según la edad, a lo largo del tiempo y en cada provincia.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/demografia/hogares" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Hogares</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Tamaño medio del hogar y hogares de una sola persona, por comunidad y provincia.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>

<div class="sf-sources-footer">

## Fuentes y notas

- **[INE – Estadística Continua de Población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177095)**: población a 1 de enero por provincia, edad y sexo (tabla 56945), por lugar de nacimiento (56948) y nacionalidad (56947), y hogares (60131 a 60134).
- **[INE – Movimiento Natural de la Población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: nacimientos (tabla 6524) y defunciones (6561) por provincia de residencia.
- **[INE – Indicadores Demográficos Básicos](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: tasas de natalidad y mortalidad, fecundidad, edad media a la maternidad y nacidos de madre extranjera.
- **[INE – Estadística de Migraciones y Cambios de Residencia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)**: saldo migratorio con el extranjero desde 2021 (ver [Inmigración](/sociedad/inmigracion)).

<LastRefreshed prefix="Datos actualizados" />

</div>
