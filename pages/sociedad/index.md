---
title: Sociedad
description: "Criminalidad, salud, inmigración, renta y pobreza, educación y elecciones en España con datos oficiales, por habitante y comparados con la UE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
</script>

```sql crimen
SELECT anio, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
ORDER BY anio DESC
LIMIT 1
```

```sql crimen_serie
-- Tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018), en orden cronológico
WITH b AS (
    SELECT anio, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
),
l AS (
    SELECT anio, max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND tipologia = 'TOTAL INFRACCIONES PENALES'
    GROUP BY 1
)
SELECT anio, tasa_1000 AS valor FROM b
UNION ALL
SELECT anio, tasa_1000 AS valor FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY anio
```

```sql vida
SELECT CAST(anio AS INTEGER) AS anio, anios AS valor
FROM mother.salud_esperanza_vida
WHERE (nivel = 'pais' OR cod = '00') AND sexo = 'Ambos sexos'
ORDER BY anio
```

```sql nacionalizaciones
SELECT CAST(anio AS INTEGER) AS anio, nacionalizaciones, por_1000_extranjeros AS valor
FROM mother.inmigracion_nacionalizaciones
WHERE cod = '00' AND nacionalidad_previa = 'Total'
ORDER BY anio
```

```sql renta
SELECT CAST(anio AS INTEGER) AS anio, CAST(anio_renta AS INTEGER) AS anio_renta, renta_persona_real AS valor
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND renta_persona_real IS NOT NULL
ORDER BY anio
```

```sql abandono
SELECT CAST(anio AS INTEGER) AS anio, valor
FROM mother.educacion_indicadores
WHERE nivel = 'pais' AND indicador = 'abandono'
ORDER BY anio
```

```sql participacion
SELECT fecha, CAST(anio AS INTEGER) AS anio, participacion AS valor
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '02'
ORDER BY fecha
```

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Sociedad</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Sociedad</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Cómo vivimos en España: la seguridad, la salud, la población que llega de fuera, la renta, la educación y el voto, con las cifras oficiales y el contexto necesario para leerlas bien.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por habitante</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Comparativa UE</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">INE · Interior · Sanidad · Eurostat</span>
    </div>
</div>

<Grid cols=3>
    <KpiCard
        title="Infracciones penales conocidas"
        value={crimen[0]?.infracciones}
        formattedValue="{formatNumber(crimen[0]?.tasa_1000, 1)} por 1.000 hab."
        period="{formatCompact(crimen[0]?.infracciones, 2)} en total · {crimen[0]?.anio}"
        source="Ministerio del Interior"
        href="/sociedad/criminalidad"
        sparklineData={crimen_serie}
    />
    <KpiCard
        title="Esperanza de vida al nacer"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} años"
        period="en {vida.slice(-1)[0]?.anio}, una de las más altas del mundo"
        change={vida.length > 1 ? vida.slice(-1)[0]?.valor - vida.slice(-2)[0]?.valor : null}
        changeUnit="años"
        changePeriod="vs año anterior"
        direction="positive-up"
        source="INE"
        href="/sociedad/salud"
        sparklineData={vida}
    />
    <KpiCard
        title="Adquisiciones de nacionalidad"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 1)} por 1.000 extranjeros"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} residentes obtuvieron la nacionalidad en {nacionalizaciones.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="INE"
        href="/sociedad/inmigracion"
        sparklineData={nacionalizaciones}
    />
    <KpiCard
        title="Renta media por persona"
        value={renta.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renta.slice(-1)[0]?.valor, 0)} € al año"
        period="renta de {renta.slice(-1)[0]?.anio_renta}, descontada la inflación"
        change={renta.length > 1 ? 100 * (renta.slice(-1)[0]?.valor / renta.slice(-2)[0]?.valor - 1) : null}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="INE / ECV"
        href="/sociedad/desigualdad"
        sparklineData={renta}
    />
    <KpiCard
        title="Abandono escolar temprano"
        value={abandono.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(abandono.slice(-1)[0]?.valor, 1)} %"
        period="de los jóvenes de 18 a 24 años en {abandono.slice(-1)[0]?.anio} · en {abandono[0]?.anio} era el {formatNumber(abandono[0]?.valor, 1)} %"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/sociedad/educacion"
        sparklineData={abandono}
    />
    <KpiCard
        title="Participación en las generales"
        value={participacion.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(participacion.slice(-1)[0]?.valor, 1)} %"
        period="del censo votó en {participacion.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Ministerio del Interior"
        href="/sociedad/elecciones"
        sparklineData={participacion}
    />
</Grid>

## Explora en detalle

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/sociedad/criminalidad" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Criminalidad</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Delitos conocidos por tipo, comunidad, provincia y municipio desde 2010, cibercriminalidad y condenados por nacionalidad con su contexto.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/sociedad/salud" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Salud</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Esperanza de vida, causas de muerte y exceso de mortalidad, y el sistema sanitario: listas de espera, médicos, camas y gasto.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/sociedad/inmigracion" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Inmigración</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Población extranjera por comunidad y origen, saldo migratorio, llegadas irregulares, asilo y nacionalizaciones.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/sociedad/desigualdad" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Renta, pobreza y desigualdad</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Renta de los hogares descontada la inflación, riesgo de pobreza, AROPE, Gini y S80/S20 por comunidad, edad y municipio, y comparación con la UE.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/sociedad/educacion" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Educación</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Abandono escolar temprano, nivel de estudios de los adultos, jóvenes que ni estudian ni trabajan, gasto por habitante y por alumno, FP y PISA, frente a la UE y por comunidad.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/sociedad/publico-privado" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M12 6v4"/><path d="M10 8h4"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Público y privado</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Cuánto de la sanidad y la educación públicas se presta a través de empresas y centros privados: conciertos, hospitales de concesión, seguros, concertada, FP y universidades privadas.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/sociedad/elecciones" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 12 2 2 4-4"/><path d="M5 7c0-1.1.9-2 2-2h10a2 2 0 0 1 2 2v12H5V7Z"/><path d="M22 19H2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Elecciones</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Generales desde 1977, europeas y municipales: participación, voto por partido y bloque, fragmentación, votos por escaño y ganador en cada provincia y municipio.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>

<div class="sf-sources-footer">
<LastRefreshed prefix="Datos actualizados" />
</div>
