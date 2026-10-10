---
title: Medios de comunicación
description: "Medios de comunicación en España en datos: canto diñeiro público reciben as radiotelevisións públicas e os medios privados en publicidade institucional e subvencións, por habitante, por comunidade e por partido."
i18n_origen: 04e7dfd80d80
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

# <span aria-hidden="true">📰</span> Medios de comunicación

Que relación económica teñen as administracións cos medios de comunicación: canto custan as radiotelevisións públicas, canto se gasta en publicidade institucional e en que grupos, e que medios privados reciben subvencións. Sempre por habitante e descontada a inflación.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
    {#if tv.length && pub.length && sub.length}
    <KpiCard
        title="Radiotelevisións públicas"
        value={tv.slice(-1)[0]?.total_eur_hab_real}
        formattedValue={formatNumber(tv.slice(-1)[0]?.total_eur_hab_real, 1) + ' €'}
        unit="por habitante"
        period={`${tv.slice(-1)[0]?.anio} · ${formatCompact(tv.slice(-1)[0]?.total_meur_nominal * 1e6, 2)} € (RTVE e autonómicas)`}
        source="CNMC e RTVE"
        direction="positive-down"
        href="/gl/medios/dinero-publico"
        sparklineData={tv.map(d => ({...d, y: d.total_eur_hab_real}))}
    />
    <KpiCard
        title="Publicidade do Estado"
        value={pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real}
        formattedValue={formatNumber(pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${pub.slice(-1)[0]?.anio} · institucional e de empresas públicas`}
        source="Comisión de Publicidade Institucional"
        direction="positive-down"
        href="/gl/medios/dinero-publico"
        sparklineData={pub.map(d => ({...d, y: d.institucional_eur_hab_real + d.comercial_eur_hab_real}))}
    />
    <KpiCard
        title="Subvencións a medios privados"
        value={sub.slice(-1)[0]?.eur_hab_real}
        formattedValue={formatNumber(sub.slice(-1)[0]?.eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${sub.slice(-1)[0]?.anio} · ${formatCompact(sub.slice(-1)[0]?.eur_nominal, 2)} €`}
        source="BDNS"
        direction="positive-down"
        href="/gl/medios/dinero-publico"
        sparklineData={sub.map(d => ({...d, y: d.eur_hab_real}))}
    />
    {/if}
</div>

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/gl/medios/dinero-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Diñeiro público nos medios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">RTVE e as televisións autonómicas por comunidade e custo por punto de audiencia, publicidade institucional e comercial do Estado por Goberno e por grupo mediático, e subvencións a medios privados cos seus beneficiarios.</p>
    </a>
    <a href="/gl/medios/buscador" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔎</span> Quen recibe que</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Busca un medio e mira canto diñeiro público recibiu, de que administracións e por que: publicidade, contratos e subvencións, pagamento a pagamento.</p>
    </a>
    <a href="/gl/medios/confianza" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🤝</span> Confianza e consumo de noticias</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Canto confían os españois nas noticias e en cada medio, como se informan, cantos pagan por noticias e cantos as evitan, fronte ao resto da UE.</p>
    </a>
    <a href="/gl/medios/libertad-pluralismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗽</span> Liberdade de prensa e pluralismo</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">A posición de España na clasificación de Reporteiros Sen Fronteiras, os riscos para o pluralismo e as alertas sobre xornalistas do Consello de Europa.</p>
    </a>
    <a href="/gl/medios/sector" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📉</span> O negocio dos medios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Canto se le, se ve e se escoita, canto se inviste en publicidade e en que soporte, canta xente traballa nos medios e canto pesa o diñeiro público.</p>
    </a>
</div>
