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

# <span aria-hidden="true">📰</span> Medios de comunicación

Qué relación económica tienen las administraciones con los medios de comunicación: cuánto cuestan las radiotelevisiones públicas, cuánto se gasta en publicidad institucional y en qué grupos, y qué medios privados reciben subvenciones. Siempre por habitante y descontada la inflación.

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
        sparklineData={tv.map(d => d.total_eur_hab_real)}
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
        sparklineData={pub.map(d => d.institucional_eur_hab_real + d.comercial_eur_hab_real)}
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
        sparklineData={sub.map(d => d.eur_hab_real)}
    />
    {/if}
</div>

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/medios/dinero-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Dinero público en los medios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">RTVE y las televisiones autonómicas por comunidad y coste por punto de audiencia, publicidad institucional y comercial del Estado por Gobierno y por grupo mediático, y subvenciones a medios privados con sus beneficiarios.</p>
    </a>
    <a href="/medios/buscador" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔎</span> Quién recibe qué</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Busca un medio y mira cuánto dinero público ha recibido, de qué administraciones y por qué: publicidad, contratos y subvenciones, pago a pago.</p>
    </a>
    <a href="/medios/confianza" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🤝</span> Confianza y consumo de noticias</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cuánto confían los españoles en las noticias y en cada medio, cómo se informan, cuántos pagan por noticias y cuántos las evitan, frente al resto de la UE.</p>
    </a>
    <a href="/medios/libertad-pluralismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗽</span> Libertad de prensa y pluralismo</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">La posición de España en la clasificación de Reporteros Sin Fronteras, los riesgos para el pluralismo y las alertas sobre periodistas del Consejo de Europa.</p>
    </a>
    <a href="/medios/sector" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📉</span> El negocio de los medios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cuánto se lee, se ve y se escucha, cuánto se invierte en publicidad y en qué soporte, cuánta gente trabaja en los medios y cuánto pesa el dinero público.</p>
    </a>
</div>
