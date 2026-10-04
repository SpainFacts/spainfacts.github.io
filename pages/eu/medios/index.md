---
title: Komunikabideak
description: "Espainiako komunikabideak datuetan: zenbat diru publiko jasotzen duten irrati-telebista publikoek eta komunikabide pribatuek erakunde-publizitatean eta diru-laguntzetan, biztanleko, erkidegoka eta alderdika."
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
# <span aria-hidden="true">📰</span> Komunikabideak

Zer harreman ekonomiko duten administrazioek komunikabideekin: zenbat kostatzen diren irrati-telebista publikoak, zenbat gastatzen den erakunde-publizitatean eta zein taldetan, eta zein komunikabide pribatuk jasotzen dituzten diru-laguntzak. Beti biztanleko eta inflazioa kenduta.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
    {#if tv.length && pub.length && sub.length}
    <KpiCard
        title="Irrati-telebista publikoak"
        value={tv.slice(-1)[0]?.total_eur_hab_real}
        formattedValue={formatNumber(tv.slice(-1)[0]?.total_eur_hab_real, 1) + ' €'}
        unit="biztanleko"
        period={`${tv.slice(-1)[0]?.anio} · ${formatCompact(tv.slice(-1)[0]?.total_meur_nominal * 1e6, 2)} € (RTVE eta autonomikoak)`}
        source="CNMC eta RTVE"
        direction="positive-down"
        href="/eu/medios/dinero-publico"
        sparklineData={tv.map(d => d.total_eur_hab_real)}
    />
    <KpiCard
        title="Estatuaren publizitatea"
        value={pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real}
        formattedValue={formatNumber(pub.slice(-1)[0]?.institucional_eur_hab_real + pub.slice(-1)[0]?.comercial_eur_hab_real, 2) + ' €'}
        unit="biztanleko"
        period={`${pub.slice(-1)[0]?.anio} · erakundeena eta enpresa publikoena`}
        source="Erakunde Publizitatearen Batzordea"
        direction="positive-down"
        href="/eu/medios/dinero-publico"
        sparklineData={pub.map(d => d.institucional_eur_hab_real + d.comercial_eur_hab_real)}
    />
    <KpiCard
        title="Diru-laguntzak komunikabide pribatuei"
        value={sub.slice(-1)[0]?.eur_hab_real}
        formattedValue={formatNumber(sub.slice(-1)[0]?.eur_hab_real, 2) + ' €'}
        unit="biztanleko"
        period={`${sub.slice(-1)[0]?.anio} · ${formatCompact(sub.slice(-1)[0]?.eur_nominal, 2)} €`}
        source="BDNS"
        direction="positive-down"
        href="/eu/medios/dinero-publico"
        sparklineData={sub.map(d => d.eur_hab_real)}
    />
    {/if}
</div>

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/eu/medios/dinero-publico" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Diru publikoa komunikabideetan</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">RTVE eta telebista autonomikoak erkidegoka eta audientzia-puntuko kostua, Estatuaren erakunde- eta merkataritza-publizitatea Gobernuka eta komunikazio-taldeka, eta komunikabide pribatuentzako diru-laguntzak, onuradunekin.</p>
    </a>
    <a href="/eu/medios/buscador" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔎</span> Nork zer jasotzen duen</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Bilatu komunikabide bat eta ikusi zenbat diru publiko jaso duen, zein administraziotatik eta zergatik: publizitatea, kontratuak eta diru-laguntzak, ordainketaz ordainketa.</p>
    </a>
    <a href="/eu/medios/confianza" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🤝</span> Konfiantza eta albisteen kontsumoa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Zenbaterainoko konfiantza duten espainiarrek albisteetan eta komunikabide bakoitzean, nola informatzen diren, zenbatek ordaintzen duten albisteengatik eta zenbatek saihesten dituzten, EBko gainerako herrialdeekin alderatuta.</p>
    </a>
    <a href="/eu/medios/libertad-pluralismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗽</span> Prentsa-askatasuna eta aniztasuna</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Espainiaren postua Mugarik Gabeko Kazetarien sailkapenean, aniztasunerako arriskuak eta Europako Kontseiluak kazetariei buruz emandako alertak.</p>
    </a>
    <a href="/eu/medios/sector" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📉</span> Komunikabideen negozioa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Zenbat irakurtzen, ikusten eta entzuten den, zenbat inbertitzen den publizitatean eta zein euskarritan, zenbat jendek egiten duen lan komunikabideetan eta zenbateko pisua duen diru publikoak.</p>
    </a>
</div>
