---
title: Análisis y reportajes en datos
description: "Investigaciones y reportajes de datos sobre España con fuentes oficiales: vivienda y salarios, diputados caseros, paraísos fiscales de flotas, decretos-ley, sanidad y educación público-privada y transición energética."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../src/lib/utils.js';
</script>

```sql caseros_kpi
SELECT
    max(pct) FILTER (WHERE definicion_id = 'alquila') AS pct_alquila,
    max(n_cumplen) FILTER (WHERE definicion_id = 'alquila') AS n_alquila,
    max(pct) FILTER (WHERE definicion_id = 'dos_viviendas') AS pct_dos_viviendas
FROM mother.diputados_inmuebles_resumen
```

```sql esfuerzo_kpi
SELECT anio, anios_salario, pct_alquiler
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql renovables_kpi
SELECT anio, cuota_renovable_pct AS valor
FROM mother.energia_resumen_anual_mix
ORDER BY anio
```

```sql decretos_kpi
SELECT anio, rdl, leyes, pct_rdl
FROM mother.gobierno_actos_anual
WHERE NOT anio_en_curso
ORDER BY anio
```

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Análisis</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Análisis y reportajes en datos</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Mientras que las secciones principales de SpainFacts mantienen siempre visibles las series estructurales del país, este espacio reúne <strong>investigaciones a fondo y cruces de datos</strong> sobre cuestiones concretas del debate público. Todas las piezas siguen la misma regla: fuentes oficiales documentadas, datos ajustados por población e inflación y contexto sin opinión partidista.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Cruces de fuentes públicas</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por habitante y euros reales</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Trazabilidad completa</span>
    </div>
</div>

<Grid cols=4>
    <KpiCard
        title="Diputados que declaran alquileres"
        value={caseros_kpi[0]?.pct_alquila}
        formattedValue="{formatNumber(caseros_kpi[0]?.pct_alquila, 1)} %"
        period="{formatNumber(caseros_kpi[0]?.n_alquila, 0)} diputados · {formatNumber(caseros_kpi[0]?.pct_dos_viviendas, 1)} % tiene 2+ viviendas"
        source="Congreso / AEAT"
        href="/varios/diputados-caseros"
    />
    <KpiCard
        title="Esfuerzo para comprar vivienda"
        value={esfuerzo_kpi.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo_kpi.slice(-1)[0]?.anios_salario, 1)} años"
        period="de salario bruto íntegro para 90 m² ({esfuerzo_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/analisis/brecha-vivienda-salarios"
        sparklineData={esfuerzo_kpi.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Electricidad de origen renovable"
        value={renovables_kpi.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renovables_kpi.slice(-1)[0]?.valor, 1)} %"
        period="del mix anual en {renovables_kpi.slice(-1)[0]?.anio} (frente al {formatNumber(renovables_kpi[0]?.valor, 1)} % en {renovables_kpi[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/analisis/revolucion-renovable"
        sparklineData={renovables_kpi}
    />
    <KpiCard
        title="Leyes aprobadas por decreto-ley"
        value={decretos_kpi.slice(-1)[0]?.pct_rdl}
        formattedValue="{formatNumber(decretos_kpi.slice(-1)[0]?.pct_rdl, 0)} %"
        period="{formatNumber(decretos_kpi.slice(-1)[0]?.rdl, 0)} reales decretos-ley en {decretos_kpi.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="BOE"
        href="/transparencia/decretos-ley"
        sparklineData={decretos_kpi.map(d => ({...d, y: d.pct_rdl}))}
    />
</Grid>

## En foco · Nuevos análisis

<div class="not-prose grid grid-cols-1 lg:grid-cols-2 gap-6 my-6">
    <a href="/analisis/brecha-vivienda-salarios" data-tema="vivienda" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider" style="color: var(--sf-topic-color)">
                <span>Vivienda y salarios</span>
                <span>·</span>
                <span>Especial en datos</span>
            </div>
            <h3 class="font-editorial mt-3 text-xl font-bold text-slate-900 dark:text-white leading-snug">
                La brecha de la vivienda: cuántos años de sueldo cuesta comprar o alquilar un piso
            </h3>
            <p class="mt-2 text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                Comparamos la evolución real de los salarios con el precio tasado del metro cuadrado y el alquiler mediano del IRPF: por qué en Baleares, Madrid o Canarias el esfuerzo multiplica al del interior peninsular.
            </p>
        </div>
        <span class="sf-card-cta">
            Leer el análisis completo →
        </span>
    </a>

    <a href="/analisis/revolucion-renovable" data-tema="energia-clima" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider" style="color: var(--sf-topic-color)">
                <span>Energía y clima</span>
                <span>·</span>
                <span>Especial en datos</span>
            </div>
            <h3 class="font-editorial mt-3 text-xl font-bold text-slate-900 dark:text-white leading-snug">
                La gran transformación eléctrica: cómo el sol y el viento desplazaron al carbón
            </h3>
            <p class="mt-2 text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
                En quince años España cerró casi todo su carbón y multiplicó la generación solar y eólica, desplomando las emisiones eléctricas. Sin embargo, el transporte concentra ya casi un tercio de todo el CO₂ del país.
            </p>
        </div>
        <span class="sf-card-cta">
            Leer el análisis completo →
        </span>
    </a>
</div>

## Investigaciones sobre instituciones, impuestos y servicios públicos

<div class="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 my-6">
    <a href="/varios/diputados-caseros" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Congreso e IRPF</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">¿Cuántos diputados son caseros?</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Declaraciones de bienes y rentas de los 350 diputados cruzadas por partido y comparadas con los tramos de renta de la Agencia Tributaria.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/movilidad/flotas-e-impuestos" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Fiscalidad municipal · DGT</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Los paraísos fiscales de las flotas</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Por qué municipios de menos de 500 habitantes matriculan decenas de miles de coches de alquiler y empresa gracias a rebajas del IVTM.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/sociedad/publico-privado" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M12 6v4"/><path d="M10 8h4"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Sanidad y educación</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Público y privado en los servicios públicos</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Conciertos sanitarios, seguros privados, enseñanza concertada, FP y auge de las universidades privadas por comunidad autónoma.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/transparencia/decretos-ley" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Poder ejecutivo · BOE</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Gobernar por decreto desde 1977</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Cuántos reales decretos-ley aprueba cada presidente del Gobierno por año de mandato y qué peso tienen sobre el total de leyes.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/medios/dinero-publico" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2"/><path d="M18 14h-8"/><path d="M15 18h-5"/><path d="M10 6h8v4h-8V6Z"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Medios y dinero público</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Publicidad institucional y medios</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Cuánto gastan el Estado y las comunidades autónomas en campañas de publicidad institucional y cómo se reparte entre medios.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/varios/observatorios" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Administración pública</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Censo de observatorios públicos</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Cuántos observatorios existen en España, qué administración los creó y cuántos mantienen actividad real.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/transparencia/contratacion" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Contratación · OIReScon</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Licitaciones, único licitador y contratos menores</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Más del 9 % del PIB pasa por la contratación pública: qué parte se adjudica sin publicidad o con una sola oferta.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/transparencia/subvenciones" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Subvenciones · BDNS</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">Subvenciones: concurrencia frente a concesión directa</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                Cómo se reparten las ayudas públicas entre Estado, comunidades y ayuntamientos y qué porcentaje se concede de forma directa.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>

    <a href="/vivienda/vivienda-publica" class="sf-subtopic-card no-underline">
        <div>
            <div class="flex items-center justify-between gap-2">
                <div class="sf-icon-box">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/></svg>
                </div>
                <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300">Comparativa europea</span>
            </div>
            <h3 class="mt-3 text-base font-bold text-slate-900 dark:text-white">¿Por qué España tiene tan poca vivienda pública en alquiler?</h3>
            <p class="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
                España pasó de construir cientos de miles de VPO en propiedad a tener uno de los parques de alquiler social más pequeños de Europa.
            </p>
        </div>
        <span class="sf-card-cta">Ver investigación →</span>
    </a>
</div>

<div class="sf-sources-footer">

## ¿Buscas las series permanentes por tema?

Los grandes bloques de seguimiento continuo están siempre disponibles en la barra superior: [Territorios](/territorios), [Demografía](/demografia), [Economía](/economia), [Vivienda](/vivienda), [Cuentas públicas](/cuentas-publicas), [Energía y clima](/energia-clima), [Movilidad](/movilidad), [Sociedad](/sociedad), [Medios](/medios) y [Transparencia](/transparencia), o puedes hacer cualquier consulta abierta en [Pregunta a los datos](/chat).

</div>
