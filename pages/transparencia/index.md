---
title: Transparencia
description: "Cómo rinden cuentas las administraciones españolas: obligaciones de información de los ayuntamientos, portales de transparencia, decretos-ley, indultos, presupuestos prorrogados y la posición de España en los índices internacionales de integridad, por Gobierno y por partido."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../src/lib/utils.js';
</script>

# <span aria-hidden="true">🔍</span> Transparencia y rendición de cuentas

Una democracia se puede medir también por cómo rinde cuentas: si las administraciones publican lo que
deben, si el Gobierno legisla por la vía ordinaria o por decreto, cómo usa el derecho de gracia y cómo
ven a España los índices internacionales de integridad. Cada subsección atribuye los datos al partido
que gobernaba y los compara con el tiempo que cada uno ha estado en el poder.

```sql actos
SELECT anio, rdl, leyes, pct_rdl, indultos, presidente, familia
FROM mother.gobierno_actos_anual
WHERE NOT anio_en_curso
ORDER BY anio
```

```sql actos_ult
SELECT * FROM ${actos} ORDER BY anio DESC LIMIT 1
```

```sql cpi
SELECT anio, valor, puesto_ue, n_ue
FROM mother.transparencia_internacional
WHERE indicador_id = 'cpi' AND cod_pais = 'ES'
ORDER BY anio
```

```sql cpi_ult
SELECT * FROM ${cpi} ORDER BY anio DESC LIMIT 1
```

```sql liquidaciones
SELECT CAST(year(periodo) AS INTEGER) AS anio, valor
FROM mother.metricas
WHERE metrica_id = 'transparencia_liquidaciones_sin_remitir'
ORDER BY periodo
```

```sql liquidaciones_ult
SELECT * FROM ${liquidaciones} ORDER BY anio DESC LIMIT 1
```

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if actos_ult.length}
    <KpiCard
        title="Decretos-ley"
        value={actos_ult[0].rdl}
        formattedValue={formatNumber(actos_ult[0].rdl, 0)}
        unit="en el año"
        period={`${actos_ult[0].anio} · ${formatNumber(actos_ult[0].pct_rdl, 0)} % de las normas con rango de ley`}
        source="BOE"
        direction="positive-down"
        href="/transparencia/decretos-ley"
        sparklineData={actos.map(d => d.rdl)}
    />
    <KpiCard
        title="Indultos"
        value={actos_ult[0].indultos}
        formattedValue={formatNumber(actos_ult[0].indultos, 0)}
        unit="decretos"
        period={`${actos_ult[0].anio}`}
        source="BOE"
        direction="neutral"
        href="/transparencia/indultos"
        sparklineData={actos.map(d => d.indultos)}
    />
    {/if}
    {#if cpi_ult.length}
    <KpiCard
        title="Percepción de la corrupción"
        value={cpi_ult[0].valor}
        formattedValue={formatNumber(cpi_ult[0].valor, 0)}
        unit="sobre 100"
        period={`${cpi_ult[0].anio} · puesto ${cpi_ult[0].puesto_ue} de ${cpi_ult[0].n_ue} en la UE`}
        source="Transparency International"
        direction="positive-up"
        href="/transparencia/comparacion-internacional"
        sparklineData={cpi.map(d => d.valor)}
    />
    {/if}
    {#if liquidaciones_ult.length}
    <KpiCard
        title="Ayuntamientos sin liquidación"
        value={liquidaciones_ult[0].valor}
        formattedValue={formatNumber(liquidaciones_ult[0].valor, 0)}
        unit="no la remitieron"
        period={`Presupuesto de ${liquidaciones_ult[0].anio}`}
        source="Hacienda"
        direction="positive-down"
        href="/transparencia/cuentas-municipales"
        sparklineData={liquidaciones.map(d => d.valor)}
    />
    {/if}
</div>

## Subsecciones

<Grid cols=2>
    <a href="/transparencia/cuentas-municipales" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🏛️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Rendición de cuentas de los ayuntamientos</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Qué ayuntamientos no remiten a Hacienda la liquidación del presupuesto, la Cuenta General o el periodo medio de pago, dónde están y quién gobernaba cuando vencía el plazo.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver los ayuntamientos →</span>
    </a>
    <a href="/transparencia/publicidad-activa" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🪟</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Portales de transparencia</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Qué administraciones publican lo que les obliga la ley según las evaluaciones oficiales (Consejo de Transparencia y Comisionado de Canarias), y qué falta por evaluar.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver quién cumple →</span>
    </a>
    <a href="/transparencia/decretos-ley" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📜</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Decretos-ley</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cuántos reales decretos-ley aprueba cada Gobierno desde 1977, qué parte de las normas con rango de ley se hacen por decreto y cuántos deroga el Congreso.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver los decretos-ley →</span>
    </a>
    <a href="/transparencia/indultos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">⚖️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Indultos</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cuántos indultos concede cada Gobierno según el BOE, cómo han cambiado con el tiempo y cómo se compara cada presidente y cada partido.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver los indultos →</span>
    </a>
    <a href="/transparencia/presupuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📅</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Presupuestos prorrogados</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Qué años empezó el Estado sin Presupuestos Generales aprobados, cuántos días duró la prórroga y a qué Gobierno le tocaba presentarlos.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver los presupuestos →</span>
    </a>
    <a href="/transparencia/comparacion-internacional" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🌍</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">España frente a otros países</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Índices de percepción de la corrupción, gobernanza, Estado de derecho y gobierno abierto: dónde está España respecto a la UE y la OCDE y cómo ha cambiado con cada Gobierno.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver la comparación →</span>
    </a>
</Grid>

## En construcción

Estas piezas de la rendición de cuentas tienen datos públicos, pero todavía no están hechas porque sus
fuentes no se publican en formatos fáciles de reutilizar. Cada página explica qué mostrará y qué falta.

<Grid cols=2>
    <a href="/transparencia/contratacion" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 En construcción</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Contratación pública</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Contratos menores, procedimientos sin publicidad y contratos con un solo licitador, por administración y partido.</p>
    </a>
    <a href="/transparencia/subvenciones" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 En construcción</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Subvenciones</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cuánto se concede sin concurrencia competitiva (concesión directa y nominativas) y quién lo concede.</p>
    </a>
    <a href="/transparencia/consejo-transparencia" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 En construcción</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Reclamaciones de acceso a la información</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cuántas reclamaciones por información denegada resuelve el Consejo de Transparencia y a qué ministerios afectan.</p>
    </a>
</Grid>

Las fuentes de datos abiertos de España están recogidas en [Datos abiertos en España](/varios/datos-abiertos).
