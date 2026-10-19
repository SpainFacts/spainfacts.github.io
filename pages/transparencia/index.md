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

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Transparencia</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Transparencia y rendición de cuentas</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Una democracia se puede medir también por cómo rinden cuentas las instituciones: si las administraciones publican lo que deben, si el Gobierno legisla por la vía ordinaria o por decreto, cómo usa el derecho de gracia y cómo ven a España los índices internacionales de integridad. Cada subsección atribuye los datos al partido que gobernaba y los compara con el tiempo que cada uno ha estado en el poder.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por Gobierno y partido</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Series desde 1977</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">BOE · Hacienda · CTBG · OIReScon</span>
    </div>
</div>

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
        sparklineData={actos.map(d => ({...d, y: d.rdl}))}
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
        sparklineData={actos.map(d => ({...d, y: d.indultos}))}
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
        sparklineData={cpi.map(d => ({...d, y: d.valor}))}
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
        sparklineData={liquidaciones.map(d => ({...d, y: d.valor}))}
    />
    {/if}
</div>

## Subsecciones

<Grid cols=2>
    <a href="/transparencia/cuentas-municipales" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="22" x2="21" y2="22"/><line x1="6" y1="18" x2="6" y2="11"/><line x1="10" y1="18" x2="10" y2="11"/><line x1="14" y1="18" x2="14" y2="11"/><line x1="18" y1="18" x2="18" y2="11"/><polygon points="12 2 20 7 4 7"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Rendición de cuentas de los ayuntamientos</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Qué ayuntamientos no remiten a Hacienda la liquidación del presupuesto, la Cuenta General o el periodo medio de pago, dónde están y quién gobernaba cuando vencía el plazo.</p>
        <span class="sf-card-cta">Ver los ayuntamientos →</span>
    </a>
    <a href="/transparencia/publicidad-activa" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="12" y1="3" x2="12" y2="21"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Portales de transparencia</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Qué administraciones publican lo que les obliga la ley según las evaluaciones oficiales (Consejo de Transparencia y Comisionado de Canarias), y qué falta por evaluar.</p>
        <span class="sf-card-cta">Ver quién cumple →</span>
    </a>
    <a href="/transparencia/decretos-ley" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Decretos-ley</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Cuántos reales decretos-ley aprueba cada Gobierno desde 1977, qué parte de las normas con rango de ley se hacen por decreto y cuántos deroga el Congreso.</p>
        <span class="sf-card-cta">Ver los decretos-ley →</span>
    </a>
    <a href="/transparencia/indultos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Indultos</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Cuántos indultos concede cada Gobierno según el BOE, cómo han cambiado con el tiempo y cómo se compara cada presidente y cada partido.</p>
        <span class="sf-card-cta">Ver los indultos →</span>
    </a>
    <a href="/transparencia/presupuestos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Presupuestos prorrogados</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Qué años empezó el Estado sin Presupuestos Generales aprobados, cuántos días duró la prórroga y a qué Gobierno le tocaba presentarlos.</p>
        <span class="sf-card-cta">Ver los presupuestos →</span>
    </a>
    <a href="/transparencia/comparacion-internacional" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">España frente a otros países</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Índices de percepción de la corrupción, gobernanza, Estado de derecho y gobierno abierto: dónde está España respecto a la UE y la OCDE y cómo ha cambiado con cada Gobierno.</p>
        <span class="sf-card-cta">Ver la comparación →</span>
    </a>
    <a href="/transparencia/contratacion" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Contratación pública</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Volumen adjudicado, licitaciones con un único ofertante, procedimientos negociados sin publicidad, peso de las pymes y reparto por administración (OIReScon).</p>
        <span class="sf-card-cta">Ver la contratación →</span>
    </a>
    <a href="/transparencia/subvenciones" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Subvenciones públicas</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Cuánto se concede en concurrencia competitiva frente a concesión directa o nominativa y qué administraciones concentran los fondos (BDNS / IGAE).</p>
        <span class="sf-card-cta">Ver las subvenciones →</span>
    </a>
    <a href="/transparencia/consejo-transparencia" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
        </div>
        <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Reclamaciones de acceso a la información</h3>
        <p class="mb-0 text-sm text-slate-600 dark:text-slate-400">Cuántas reclamaciones por información denegada resuelve el Consejo de Transparencia, en cuántas da la razón al ciudadano y qué ministerios acumulan más.</p>
        <span class="sf-card-cta">Ver las reclamaciones →</span>
    </a>
</Grid>

<div class="sf-sources-footer">
Las fuentes de datos abiertos de España están recogidas en [Datos abiertos en España](/varios/datos-abiertos).
</div>
