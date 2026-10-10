---
title: Mitjans de comunicació
description: "Els mitjans de comunicació a Espanya en dades: quants diners públics reben les ràdios i televisions públiques i els mitjans privats en publicitat institucional i subvencions, per habitant, per comunitat i per partit."
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

# <span aria-hidden="true">📰</span> Mitjans de comunicació

Quina relació econòmica tenen les administracions amb els mitjans de comunicació: quant costen les ràdios i televisions públiques, quant es gasta en publicitat institucional i en quins grups, i quins mitjans privats reben subvencions. Sempre per habitant i descomptada la inflació.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
    {#if tv.length && pub.length && sub.length}
    <KpiCard
        title="Ràdios i televisions públiques"
        value={tv.slice(-1)[0]?.total_eur_hab_real}
        formattedValue={formatNumber(tv.slice(-1)[0]?.total_eur_hab_real, 1) + ' €'}
        unit="per habitant"
        period={`${tv.slice(-1)[0]?.anio} · ${formatCompact(tv.slice(-1)[0]?.total_meur_nominal * 1e6, 2)} € (RTVE i autonòmiques)`}
        source="CNMC i RTVE"
        direction="positive-down"
        href="/ca/medios/dinero-publico"
        sparklineData={tv.map(d => ({...d, y: d.total_eur_hab_real}))}
    />
    <KpiCard
        title="Publicitat de l'Estat"
        value={pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real}
        formattedValue={formatNumber(pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real, 2) + ' €'}
        unit="per habitant"
        period={`${pub.slice(-1)[0]?.anio} · institucional i d'empreses públiques`}
        source="Comissió de Publicitat Institucional"
        direction="positive-down"
        href="/ca/medios/dinero-publico"
        sparklineData={pub.map(d => ({...d, y: d.institucional_eur_hab_real + d.comercial_eur_hab_real}))}
    />
    <KpiCard
        title="Subvencions a mitjans privats"
        value={sub.slice(-1)[0]?.eur_hab_real}
        formattedValue={formatNumber(sub.slice(-1)[0]?.eur_hab_real, 2) + ' €'}
        unit="per habitant"
        period={`${sub.slice(-1)[0]?.anio} · ${formatCompact(sub.slice(-1)[0]?.eur_nominal, 2)} €`}
        source="BDNS"
        direction="positive-down"
        href="/ca/medios/dinero-publico"
        sparklineData={sub.map(d => ({...d, y: d.eur_hab_real}))}
    />
    {/if}
</div>

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/ca/medios/dinero-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Diners públics als mitjans</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">RTVE i les televisions autonòmiques per comunitat i cost per punt d'audiència, publicitat institucional i comercial de l'Estat per Govern i per grup mediàtic, i subvencions a mitjans privats amb els seus beneficiaris.</p>
    </a>
    <a href="/ca/medios/buscador" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔎</span> Qui rep què</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cerca un mitjà i mira quants diners públics ha rebut, de quines administracions i per què: publicitat, contractes i subvencions, pagament a pagament.</p>
    </a>
    <a href="/ca/medios/confianza" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🤝</span> Confiança i consum de notícies</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Quant confien els espanyols en les notícies i en cada mitjà, com s'informen, quants paguen per notícies i quants les eviten, en comparació amb la resta de la UE.</p>
    </a>
    <a href="/ca/medios/libertad-pluralismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗽</span> Llibertat de premsa i pluralisme</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">La posició d'Espanya en la classificació de Reporters Sense Fronteres, els riscos per al pluralisme i les alertes sobre periodistes del Consell d'Europa.</p>
    </a>
    <a href="/ca/medios/sector" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📉</span> El negoci dels mitjans</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Quant es llegeix, es veu i s'escolta, quant s'inverteix en publicitat i en quin suport, quanta gent treballa als mitjans i quant pesen els diners públics.</p>
    </a>
</div>
