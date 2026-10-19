---
title: Economía
description: "PIB por habitante, crecimiento, comercio exterior, sectores, empleo, salarios, paro e inflación en España, descontada la inflación y en proporción a la población."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql pib_hab
SELECT anio, real_eur AS valor, 100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql pib_trim
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, interanual, anio_base
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql exportaciones
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, pct_pib
FROM mother.economia_pib_trimestral
WHERE componente = 'P6'
ORDER BY trimestre
```

```sql salario
SELECT anio, salario_real, crecimiento_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql empleo
SELECT anio, ocupados_1000_hab, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql serie_paro
SELECT periodo, valor AS paro, strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo
```

```sql serie_ipc
SELECT periodo, valor AS ipc, strftime(periodo, '%Y-%m') AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo
```

```sql sectores_crec
SELECT
    s.sector,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crecimiento,
    s.anio
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
  AND s.rama <> 'TOTAL' AND NOT s.es_subrama
ORDER BY crecimiento DESC
```

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Economía</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Economía</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Cómo evoluciona la economía española. Siguiendo el criterio de toda la web, lo que depende del tamaño del país se muestra <strong>por habitante</strong> y lo que se mide en euros, <strong>descontada la inflación</strong> (en euros de {pib_trim[0]?.anio_base}).
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por habitante</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Euros constantes ({pib_trim[0]?.anio_base})</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Eurostat · INE</span>
    </div>
</div>

<Grid cols=3>
    <KpiCard
        title="PIB por habitante"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="en {pib_hab.slice(-1)[0]?.anio}, en euros de {pib_trim[0]?.anio_base}"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab.map(d => ({...d, y: d.valor}))}
        href="/economia/pib"
    />
    <KpiCard
        title="Crecimiento del PIB"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="interanual real, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => ({...d, y: d.interanual}))}
        href="/economia/pib"
    />
    <KpiCard
        title="Exportaciones"
        value={exportaciones.slice(-1)[0]?.pct_pib}
        formattedValue="{formatNumber(exportaciones.slice(-1)[0]?.pct_pib, 1)} % del PIB"
        period="bienes y servicios, {exportaciones.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={exportaciones.slice(-40).map(d => ({...d, y: d.pct_pib}))}
        href="/economia/comercio-exterior"
    />
    <KpiCard
        title="Salario medio"
        value={salario.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(salario.slice(-1)[0]?.salario_real, 0)} €/mes"
        period="bruto en {salario.slice(-1)[0]?.anio}, descontada la inflación"
        change={salario.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={salario.map(d => ({...d, y: d.salario_real}))}
        href="/economia/salarios"
    />
    <KpiCard
        title="Tasa de paro"
        value={serie_paro.slice(-1)[0]?.paro}
        formattedValue="{formatNumber(serie_paro.slice(-1)[0]?.paro, 1)} %"
        period={serie_paro.slice(-1)[0]?.periodo_txt}
        change={serie_paro.length > 1 ? (serie_paro.slice(-1)[0]?.paro - serie_paro.slice(-2)[0]?.paro).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs trimestre anterior"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={serie_paro.slice(-40).map(d => ({...d, y: d.paro}))}
        href="/economia/paro"
    />
    <KpiCard
        title="Inflación"
        value={serie_ipc.slice(-1)[0]?.ipc}
        formattedValue="{formatNumber(serie_ipc.slice(-1)[0]?.ipc, 1)} %"
        period="IPC interanual, {serie_ipc.slice(-1)[0]?.periodo_txt}"
        change={serie_ipc.length > 1 ? (serie_ipc.slice(-1)[0]?.ipc - serie_ipc.slice(-2)[0]?.ipc).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={serie_ipc.slice(-36).map(d => ({...d, y: d.ipc}))}
        href="/economia/ipc"
    />
</Grid>

## PIB por habitante

Lo que produce la economía por cada habitante, en euros constantes. [Crecimiento trimestral, demanda y comparación con Europa →](/economia/pib)

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante (reales)"
    startingAtZero={false}
    title="PIB por habitante en euros de {pib_trim[0]?.anio_base}"
/>

## Sectores

Crecimiento real del valor añadido de cada gran sector desde 2019. [Empleo, peso y productividad por sector →](/economia/sectores)

<BarChart
    data={sectores_crec}
    x=sector
    y=crecimiento
    swapXY=true
    yFmt='0.0"%"'
    title="Crecimiento real del valor añadido entre 2019 y {sectores_crec[0]?.anio} (%)"
/>

## Empleo

Ocupados por cada 1.000 habitantes: sube cuando se crea empleo más deprisa de lo que crece la población. [Tasa de paro →](/economia/paro)

<LineChart
    data={empleo}
    x=anio
    y=ocupados_1000_hab
    xFmt='0'
    yAxisTitle="Ocupados por 1.000 hab."
    startingAtZero={false}
    title="Ocupados por 1.000 habitantes"
/>

## Salarios

Salario medio mensual bruto descontada la inflación. [Crecimiento, sectores y deciles →](/economia/salarios)

<LineChart
    data={salario}
    x=anio
    y=salario_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reales)"
    startingAtZero={false}
    title="Salario medio mensual en euros de {pib_trim[0]?.anio_base}"
/>

## Paro e inflación

<Grid cols=2>
<LineChart
    data={serie_paro}
    x=periodo
    y=paro
    yAxisTitle="% de la población activa"
    title="Tasa de paro (EPA)"
    startingAtZero={false}
/>
<LineChart
    data={serie_ipc}
    x=periodo
    y=ipc
    yAxisTitle="% interanual"
    title="Inflación (IPC, variación anual)"
    startingAtZero={false}
/>
</Grid>

## Explora en detalle

<Grid cols=3>
    <a href="/economia/comercio-exterior" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Comercio exterior</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">Exportaciones, importaciones y saldo exterior sobre el PIB</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/paro" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Paro</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">Serie histórica de la Encuesta de Población Activa (EPA)</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/ipc" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Inflación</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">Índice de precios de consumo y precio de la energía</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/turismo" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Turismo</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">Turistas por habitante, su gasto real y en % del PIB, hoteles y viviendas turísticas</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/empresas" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Empresas, emprendimiento e I+D</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">Empresas por habitante y tamaño, sociedades creadas y disueltas, concursos, autónomos y gasto en I+D frente a Europa</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/sector-primario" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Agricultura, ganadería y pesca</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">La huerta de Europa: aceite, cítricos, frutas y hortalizas, porcino, vino y pesca, y el puesto de España en la UE</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/industria" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 20a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8l-7 5V8l-7 5V4a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Industria</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">Coches, azulejos, alimentación, tren y aerogeneradores: dónde destaca España y cuánta industria tiene frente a la UE</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/economia/construccion" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="8" rx="1"/><path d="M17 14v7"/><path d="M7 14v7"/><path d="M17 3v3"/><path d="M7 3v3"/><path d="M10 14 2.3 6.3"/><path d="m14 6 7.7 7.7"/><path d="m8 6 8 8"/></svg>
        </div>
        <div class="font-bold text-slate-900 dark:text-white mt-3">Construcción</div>
        <div class="text-sm text-slate-600 dark:text-slate-400 mt-1">La burbuja de 2007, el desplome y la recuperación: empleo, obra pública licitada, viviendas visadas y cemento frente a la UE</div>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</Grid>

<div class="sf-sources-footer">

**Fuentes:** Eurostat (contabilidad nacional: [namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table), [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table)) e INE ([EPA](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918), [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [Encuesta Trimestral de Coste Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6038)).

</div>
