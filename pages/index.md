---
title: SpainFacts · El Estado de España en Datos Oficiales
---

<script>
    import { formatNumber, formatCompact } from '../../../../src/lib/utils.js';
    import KpiCard from '../../../../src/lib/components/KpiCard.svelte';
</script>

```sql kpi_poblacion
SELECT 
    Total AS valor,
    CAST(Year AS VARCHAR) AS periodo_txt,
    Year
FROM mother.totalAno
ORDER BY Year DESC
LIMIT 2
```

```sql kpi_paro
SELECT 
    valor,
    strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt,
    periodo
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo DESC
LIMIT 2
```

```sql kpi_ipc
SELECT 
    valor,
    strftime(periodo, '%Y-%m') AS periodo_txt,
    periodo
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo DESC
LIMIT 2
```

```sql kpi_deuda
SELECT 
    valor,
    strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt,
    periodo
FROM mother.metricas
WHERE metrica_id = 'deuda_publica_pib'
ORDER BY periodo DESC
LIMIT 2
```

```sql sparkline_poblacion
SELECT Total AS valor
FROM mother.totalAno
WHERE Year >= 2000
ORDER BY Year ASC
```

```sql sparkline_paro
SELECT valor
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo ASC
```

```sql sparkline_ipc
SELECT valor
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo ASC
```

```sql sparkline_deuda
SELECT valor
FROM mother.metricas
WHERE metrica_id = 'deuda_publica_pib'
ORDER BY periodo ASC
```

<!-- Hero Principal USAFacts Style -->
<div class="rounded-2xl bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 text-white p-8 md:p-12 mb-8 shadow-xl border border-slate-800">
    <div class="max-w-3xl">
        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-blue-500/20 text-blue-300 border border-blue-400/30 mb-4">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Plataforma Cívica de Datos Abiertos
        </span>
        <h1 class="text-3xl md:text-5xl font-extrabold tracking-tight text-white mb-4 leading-tight">
            El retrato de España, <br class="hidden sm:inline"/>medido en <span class="text-blue-400">datos oficiales</span>.
        </h1>
        <p class="text-base md:text-lg text-slate-300 mb-6 leading-relaxed">
            SpainFacts es una iniciativa independiente y no partidista que recopila, estandariza y visualiza los datos del gobierno y las instituciones públicas para que cualquier ciudadano conozca la realidad de nuestro país sin filtros.
        </p>
        <div class="flex flex-wrap gap-3">
            <a href="/indicadores" class="inline-flex items-center px-4 py-2.5 rounded-lg text-sm font-semibold bg-blue-600 hover:bg-blue-500 text-white shadow transition-all">
                Explorar todos los indicadores →
            </a>
            <a href="/demografia" class="inline-flex items-center px-4 py-2.5 rounded-lg text-sm font-semibold bg-white/10 hover:bg-white/20 text-white border border-white/20 transition-all">
                Informe Demográfico
            </a>
        </div>
    </div>
</div>

## España de un vistazo

Principales métricas clave del país actualizadas automáticamente desde las series de los organismos oficiales.

<Grid cols=4>
    <KpiCard
        title="Población Total"
        value={kpi_poblacion[0].valor}
        formattedValue="{formatCompact(kpi_poblacion[0].valor, 2)}"
        unit="hab."
        period="{kpi_poblacion[0].periodo_txt}"
        change={kpi_poblacion.length > 1 ? (((kpi_poblacion[0].valor - kpi_poblacion[1].valor) / kpi_poblacion[1].valor) * 100).toFixed(2) : null}
        changeUnit="%"
        changePeriod="interanual"
        direction="positive-up"
        source="INE"
        href="/demografia"
        sparklineData={sparkline_poblacion}
    />

    <KpiCard
        title="Tasa de Paro"
        value={kpi_paro[0].valor}
        formattedValue="{formatNumber(kpi_paro[0].valor, 1)}%"
        period="{kpi_paro[0].periodo_txt}"
        change={kpi_paro.length > 1 ? (kpi_paro[0].valor - kpi_paro[1].valor).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs trimestre ant."
        direction="positive-down"
        source="INE / EPA"
        href="/economia/paro"
        sparklineData={sparkline_paro}
    />

    <KpiCard
        title="Inflación (IPC)"
        value={kpi_ipc[0].valor}
        formattedValue="{formatNumber(kpi_ipc[0].valor, 1)}%"
        period="{kpi_ipc[0].periodo_txt}"
        change={kpi_ipc.length > 1 ? (kpi_ipc[0].valor - kpi_ipc[1].valor).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs mes ant."
        direction="positive-down"
        source="INE"
        href="/economia/ipc"
        sparklineData={sparkline_ipc}
    />

    <KpiCard
        title="Deuda Pública / PIB"
        value={kpi_deuda[0].valor}
        formattedValue="{formatNumber(kpi_deuda[0].valor, 1)}%"
        period="{kpi_deuda[0].periodo_txt}"
        change={kpi_deuda.length > 1 ? (kpi_deuda[0].valor - kpi_deuda[1].valor).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs trimestre ant."
        direction="positive-down"
        source="Eurostat / BdE"
        href="/cuentas-publicas"
        sparklineData={sparkline_deuda}
    />
</Grid>

---

## Áreas Temáticas Principales

Explora los grandes pilares que componen la sociedad, la economía y la gestión pública en España:

<Grid cols=3>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xl mb-4">
            👥
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Demografía y Sociedad</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Evolución del censo de población, pirámide demográfica, distribución por provincias y ratios por sexo desde 1971.
        </p>
    </div>
    <a href="/demografia" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver informe demográfico →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold text-xl mb-4">
            💼
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Economía y Empleo</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Tasa de desempleo de la Encuesta de Población Activa (EPA) y variación de precios con el IPC general e histórico.
        </p>
    </div>
    <a href="/economia" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver datos económicos →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4">
            🏛️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Cuentas Públicas</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Evolución de la deuda pública consolidada de las Administraciones Públicas y porcentaje sobre el PIB según el PDE.
        </p>
    </div>
    <a href="/cuentas-publicas" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver cuentas públicas →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4">
            🌱
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Energía & Clima</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Mix de generación eléctrica, cuota renovable, emisiones de GEI por sector y potencia instalada eólica y solar fotovoltaica.
        </p>
    </div>
    <a href="/energia-clima" class="text-sm font-semibold text-green-600 dark:text-green-400 hover:underline inline-flex items-center">
        Ver energía y clima →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center font-bold text-xl mb-4">
            🔍
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Observatorios Públicos</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Censo y estado de actividad de los observatorios e instituciones públicas creados en España a lo largo del tiempo.
        </p>
    </div>
    <a href="/observatorios" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver observatorios →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-rose-100 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center font-bold text-xl mb-4">
            🗺️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Mapas y Territorio</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Visualización cartográfica coroplética por comunidades autónomas y provincias para análisis territorial comparativo.
        </p>
    </div>
    <a href="/maps" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver mapas territoriales →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xl mb-4">
            📊
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Catálogo de Indicadores</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Directorio completo con todas las métricas disponibles, ficha técnica individual, periodicidad y enlace a la fuente original.
        </p>
    </div>
    <a href="/indicadores" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver todos los indicadores →
    </a>
</div>

</Grid>

---

## Principios de Transparencia y Neutralidad

Inspirados en el modelo de **[USAFacts](https://usafacts.org/)**, SpainFacts se rige por tres compromisos fundamentales:

1. **Fuentes Primarias Oficiales:** Todos los datos provienen directamente de organismos estadísticos y de gobierno (INE, Banco de España, Eurostat, Ministerios).
2. **Neutralidad Total:** No emitimos juicios de valor ni recomendaciones políticas. Proveemos el contexto histórico y la metodología para que el ciudadano forme su propio criterio.
3. **Código y Datos Abiertos:** Los pipelines de ingesta y transformación son públicos, auditables y reproducibles.

<div class="my-4">
    <a href="/fuentes" class="inline-flex items-center px-4 py-2 rounded-lg text-sm font-semibold bg-gray-100 hover:bg-gray-200 text-gray-800 dark:bg-gray-800 dark:hover:bg-gray-700 dark:text-gray-200 border border-gray-300 dark:border-gray-700 transition-colors">
        🔍 Consultar el directorio completo de trazabilidad y auditoría de fuentes →
    </a>
</div>

<LastRefreshed prefix="Última sincronización de datos con fuentes oficiales" />
