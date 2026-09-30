---
title: Gardentasuna
description: "Nola ematen dituzten kontuak Espainiako administrazioek: udalen informazio-betebeharrak, lege-dekretuak, indultuak, luzatutako aurrekontuak eta Espainiak osotasun-indize internazionaletan duen lekua, Gobernuka eta alderdika."
i18n_origen: 9ea4661f7e55
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    // Urteei euskal atzizkiak eransten dizkie (2021eko, 2023ko...)
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
</script>

# <span aria-hidden="true">🔍</span> Gardentasuna eta kontu-ematea

Demokrazia bat kontuak emateko moduaren arabera ere neur daiteke: administrazioek argitaratu behar dutena
argitaratzen duten, Gobernuak bide arruntaren bidez ala dekretuz legegintzen duen, grazia-eskubidea nola
erabiltzen duen eta osotasun-indize internazionalek Espainia nola ikusten duten. Azpiatal bakoitzak
gobernatzen zuen alderdiari egozten dizkio datuak, eta bakoitzak boterean emandako denborarekin alderatzen ditu.

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
WHERE indicador_id = 'cpi' AND cod_pais = 'ESP'
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
        title="Lege-dekretuak"
        value={actos_ult[0].rdl}
        formattedValue={formatNumber(actos_ult[0].rdl, 0)}
        unit="urtean"
        period={`${actos_ult[0].anio} · lege-mailako arauen ${formatNumber(actos_ult[0].pct_rdl, 0)} %`}
        source="BOE"
        direction="positive-down"
        href="/eu/transparencia/decretos-ley"
        sparklineData={actos.map(d => d.rdl)}
    />
    <KpiCard
        title="Indultuak"
        value={actos_ult[0].indultos}
        formattedValue={formatNumber(actos_ult[0].indultos, 0)}
        unit="dekretu"
        period={`${actos_ult[0].anio}`}
        source="BOE"
        direction="neutral"
        href="/eu/transparencia/indultos"
        sparklineData={actos.map(d => d.indultos)}
    />
    {/if}
    {#if cpi_ult.length}
    <KpiCard
        title="Ustelkeriaren pertzepzioa"
        value={cpi_ult[0].valor}
        formattedValue={formatNumber(cpi_ult[0].valor, 0)}
        unit="100etik"
        period={`${cpi_ult[0].anio} · EBko postua: ${cpi_ult[0].puesto_ue}/${cpi_ult[0].n_ue}`}
        source="Transparency International"
        direction="positive-up"
        href="/eu/transparencia/comparacion-internacional"
        sparklineData={cpi.map(d => d.valor)}
    />
    {/if}
    {#if liquidaciones_ult.length}
    <KpiCard
        title="Likidaziorik gabeko udalak"
        value={liquidaciones_ult[0].valor}
        formattedValue={formatNumber(liquidaciones_ult[0].valor, 0)}
        unit="ez zuten bidali"
        period={`${urteko(liquidaciones_ult[0].anio)} aurrekontua`}
        source="Ogasuna"
        direction="positive-down"
        href="/eu/transparencia/cuentas-municipales"
        sparklineData={liquidaciones.map(d => d.valor)}
    />
    {/if}
</div>

## Azpiatalak

<Grid cols=2>
    <a href="/eu/transparencia/cuentas-municipales" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🏛️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Udalen kontu-ematea</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Zein udalek ez dioten Ogasunari bidaltzen aurrekontuaren likidazioa, Kontu Orokorra edo batez besteko ordainketa-epea, non dauden eta nork gobernatzen zuen epea amaitzean.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ikusi udalak →</span>
    </a>
    <a href="/eu/transparencia/decretos-ley" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📜</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Lege-dekretuak</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Zenbat errege lege-dekretu onartzen dituen Gobernu bakoitzak 1977tik, lege-mailako arauen zer zati egiten den dekretuz eta Kongresuak zenbat indargabetzen dituen.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ikusi lege-dekretuak →</span>
    </a>
    <a href="/eu/transparencia/indultos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">⚖️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Indultuak</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">BOEren arabera Gobernu bakoitzak zenbat indultu ematen dituen, denborarekin nola aldatu diren eta presidente eta alderdi bakoitza nola alderatzen den.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ikusi indultuak →</span>
    </a>
    <a href="/eu/transparencia/presupuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📅</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Luzatutako aurrekontuak</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Zein urtetan hasi zen Estatua Aurrekontu Orokorrak onartu gabe, zenbat egun iraun zuen luzapenak eta zer Gobernuri zegokion aurkeztea.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ikusi aurrekontuak →</span>
    </a>
    <a href="/eu/transparencia/comparacion-internacional" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🌍</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Espainia beste herrialdeen aldean</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Ustelkeriaren pertzepzioaren, gobernantzaren, zuzenbide-estatuaren eta gobernu irekiaren indizeak: non dagoen Espainia EBren eta ELGAren aldean eta nola aldatu den Gobernu bakoitzarekin.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ikusi alderaketa →</span>
    </a>
</Grid>

## Zer gehiago neur liteke

Kontu-ematearen beste pieza batzuek ere badituzte datu publikoak, baina oraindik ez daude hemen, haien
iturriak ez direlako formatu berrerabilgarrietan argitaratzen edo lan handiagoa eskatzen dutelako:
Gardentasun eta Gobernu Oneko Kontseiluaren ebazpenak (HTML eta PDF zerrendetan soilik), kontratazio
publikoa (Sektore Publikoko Kontratazio Plataformaren milaka XML fitxategi) eta zuzeneko emakida-bidezko
diru-laguntzak (Diru-laguntzen Datu-base Nazionala). Espainiako datu irekien iturriak
[Datu irekiak Espainian](/eu/varios/datos-abiertos) orrian bilduta daude.
