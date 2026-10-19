---
title: Medios de comunicación
description: "Medios de comunicación en España en datos: cuánto dinero público reciben las radiotelevisiones públicas y los medios privados en publicidad institucional y subvenciones, por habitante, por comunidad y por partido."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
</script>

```sql tv
SELECT CAST(anio AS INTEGER) AS anio, total_eur_hab_real, total_meur_nominal
FROM mother.medios_tv_espana_anual
WHERE total_eur_hab_real IS NOT NULL
ORDER BY anio
```

```sql pub
SELECT CAST(anio AS INTEGER) AS anio, institucional_eur_hab_real, comercial_eur_hab_real, institucional_eur_nominal, comercial_eur_nominal
FROM mother.medios_publicidad_age_anual
WHERE institucional_eur_nominal IS NOT NULL
ORDER BY anio
```

```sql sub
SELECT CAST(s.anio AS INTEGER) AS anio, sum(s.importe_eur_real) / max(p.poblacion) AS eur_hab_real, sum(s.importe_eur_nominal) AS eur_nominal
FROM mother.medios_subvenciones_anual s
JOIN mother.poblacion_territorios p ON p.nivel = 'pais' AND p.cod = '00' AND p.sexo = 'Total' AND p.anio = s.anio
WHERE NOT s.parcial
GROUP BY s.anio
ORDER BY s.anio
```

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Medios</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-2 2Zm0 0a2 2 0 0 1-2-2v-9c0-1.1.9-2 2-2h2"/><path d="M18 14h-8"/><path d="M15 18h-5"/><path d="M10 6h8v4h-8V6Z"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Medios de comunicación</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Qué relación económica tienen las administraciones con los medios de comunicación: cuánto cuestan las radiotelevisiones públicas, cuánto se gasta en publicidad institucional y en qué grupos, y qué medios privados reciben subvenciones. Siempre por habitante y descontada la inflación.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por habitante</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Euros constantes</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">CNMC · RTVE · BDNS · RSF</span>
    </div>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
    {#if tv.length && pub.length && sub.length}
    <KpiCard
        title="Radiotelevisiones públicas"
        value={tv.slice(-1)[0]?.total_eur_hab_real}
        formattedValue={formatNumber(tv.slice(-1)[0]?.total_eur_hab_real, 1) + ' €'}
        unit="por habitante"
        period={`${tv.slice(-1)[0]?.anio} · ${formatCompact(tv.slice(-1)[0]?.total_meur_nominal * 1e6, 2)} € (RTVE y autonómicas)`}
        source="CNMC y RTVE"
        direction="positive-down"
        href="/medios/dinero-publico"
        sparklineData={tv.map(d => ({...d, y: d.total_eur_hab_real}))}
    />
    <KpiCard
        title="Publicidad del Estado"
        value={pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real}
        formattedValue={formatNumber(pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${pub.slice(-1)[0]?.anio} · institucional y de empresas públicas`}
        source="Comisión de Publicidad Institucional"
        direction="positive-down"
        href="/medios/dinero-publico"
        sparklineData={pub.map(d => ({...d, y: d.institucional_eur_hab_real + d.comercial_eur_hab_real}))}
    />
    <KpiCard
        title="Subvenciones a medios privados"
        value={sub.slice(-1)[0]?.eur_hab_real}
        formattedValue={formatNumber(sub.slice(-1)[0]?.eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${sub.slice(-1)[0]?.anio} · ${formatCompact(sub.slice(-1)[0]?.eur_nominal, 2)} €`}
        source="BDNS"
        direction="positive-down"
        href="/medios/dinero-publico"
        sparklineData={sub.map(d => ({...d, y: d.eur_hab_real}))}
    />
    {/if}
</div>

## Explora en detalle

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/medios/dinero-publico" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Dinero público en los medios</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">RTVE y las televisiones autonómicas por comunidad y coste por punto de audiencia, publicidad institucional y comercial del Estado por Gobierno y por grupo mediático, y subvenciones a medios privados con sus beneficiarios.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/medios/buscador" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Quién recibe qué</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Busca un medio y mira cuánto dinero público ha recibido, de qué administraciones y por qué: publicidad, contratos y subvenciones, pago a pago.</p>
        <span class="sf-card-cta">Abrir buscador →</span>
    </a>
    <a href="/medios/confianza" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><polyline points="16 11 18 13 22 9"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Confianza y consumo de noticias</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Cuánto confían los españoles en las noticias y en cada medio, cómo se informan, cuántos pagan por noticias y cuántos las evitan, frente al resto de la UE.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/medios/libertad-pluralismo" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Libertad de prensa y pluralismo</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">La posición de España en la clasificación de Reporteros Sin Fronteras, los riesgos para el pluralismo y las alertas sobre periodistas del Consejo de Europa.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/medios/sector" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">El negocio de los medios</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Cuánto se lee, se ve y se escucha, cuánto se invierte en publicidad y en qué soporte, cuánta gente trabaja en los medios y cuánto pesa el dinero público.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>
