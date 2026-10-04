---
title: The media
description: "The media in Spain in data: how much public money public broadcasters and private media receive in institutional advertising and subsidies, per inhabitant, by region and by party."
i18n_origen: fac8a0e02911
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# <span aria-hidden="true">📰</span> The media

The financial relationship between public administrations and the media: how much public broadcasters cost, how much is spent on institutional advertising and with which groups, and which private media receive subsidies. Always per inhabitant and adjusted for inflation.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
    {#if tv.length && pub.length && sub.length}
    <KpiCard
        title="Public broadcasters"
        value={tv.slice(-1)[0]?.total_eur_hab_real}
        formattedValue={formatNumber(tv.slice(-1)[0]?.total_eur_hab_real, 1) + ' €'}
        unit="per inhabitant"
        period={`${tv.slice(-1)[0]?.anio} · ${formatCompact(tv.slice(-1)[0]?.total_meur_nominal * 1e6, 2)} € (RTVE and regional broadcasters)`}
        source="CNMC and RTVE"
        direction="positive-down"
        href="/en/medios/dinero-publico"
        sparklineData={tv.map(d => d.total_eur_hab_real)}
    />
    <KpiCard
        title="Central government advertising"
        value={pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real}
        formattedValue={formatNumber(pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real, 2) + ' €'}
        unit="per inhabitant"
        period={`${pub.slice(-1)[0]?.anio} · institutional and by state-owned companies`}
        source="Institutional Advertising Commission"
        direction="positive-down"
        href="/en/medios/dinero-publico"
        sparklineData={pub.map(d => d.institucional_eur_hab_real + d.comercial_eur_hab_real)}
    />
    <KpiCard
        title="Subsidies to private media"
        value={sub.slice(-1)[0]?.eur_hab_real}
        formattedValue={formatNumber(sub.slice(-1)[0]?.eur_hab_real, 2) + ' €'}
        unit="per inhabitant"
        period={`${sub.slice(-1)[0]?.anio} · ${formatCompact(sub.slice(-1)[0]?.eur_nominal, 2)} €`}
        source="BDNS"
        direction="positive-down"
        href="/en/medios/dinero-publico"
        sparklineData={sub.map(d => d.eur_hab_real)}
    />
    {/if}
</div>

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/en/medios/dinero-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Public money in the media</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">RTVE and the regional broadcasters by region and cost per audience share point, central government institutional and commercial advertising by government and by media group, and subsidies to private media with their recipients.</p>
    </a>
    <a href="/en/medios/buscador" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔎</span> Who gets what</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Search for a media outlet and see how much public money it has received, from which administrations and why: advertising, contracts and subsidies, payment by payment.</p>
    </a>
    <a href="/en/medios/confianza" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🤝</span> Trust and news consumption</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">How much Spaniards trust the news and each outlet, how they get informed, how many pay for news and how many avoid it, compared with the rest of the EU.</p>
    </a>
    <a href="/en/medios/libertad-pluralismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗽</span> Press freedom and pluralism</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Spain's position in the Reporters Without Borders index, the risks to pluralism and the Council of Europe's alerts about journalists.</p>
    </a>
    <a href="/en/medios/sector" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📉</span> The media business</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">How much is read, watched and listened to, how much is invested in advertising and in which medium, how many people work in the media and how much weight public money carries.</p>
    </a>
</div>
