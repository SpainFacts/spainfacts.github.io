---
title: Gardentasuna
description: "Nola ematen dituzten kontuak Espainiako administrazioek: udalen informazio-betebeharrak, gardentasun-atariak, lege-dekretuak, indultuak, luzatutako aurrekontuak eta Espainiak osotasun-indize internazionaletan duen lekua, Gobernuka eta alderdika."
i18n_origen: f730ced4988b
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
        title="Lege-dekretuak"
        value={actos_ult[0].rdl}
        formattedValue={formatNumber(actos_ult[0].rdl, 0)}
        unit="urtean"
        period={`${actos_ult[0].anio} · lege-mailako arauen ${formatNumber(actos_ult[0].pct_rdl, 0)} %`}
        source="BOE"
        direction="positive-down"
        href="/eu/transparencia/decretos-ley"
        sparklineData={actos.map(d => ({...d, y: d.rdl}))}
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
        sparklineData={actos.map(d => ({...d, y: d.indultos}))}
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
        sparklineData={cpi.map(d => ({...d, y: d.valor}))}
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
        sparklineData={liquidaciones.map(d => ({...d, y: d.valor}))}
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
    <a href="/eu/transparencia/publicidad-activa" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🪟</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Gardentasun-atariak</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Zein administraziok argitaratzen duten legeak eskatzen diena, ebaluazio ofizialen arabera (Gardentasun eta Gobernu Oneko Kontseilua eta Kanarietako Gardentasun Komisionatua), eta zer dagoen ebaluatzeke.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ikusi nork betetzen duen →</span>
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

## Eraikitzen

Kontu-ematearen pieza hauek datu publikoak badituzte, baina oraindik ez daude eginda, haien iturriak
ez direlako erraz berrerabiltzeko moduko formatuetan argitaratzen. Orri bakoitzak azaltzen du zer
erakutsiko duen eta zer falta den.

<Grid cols=2>
    <a href="/eu/transparencia/contratacion" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 Eraikitzen</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Kontratazio publikoa</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Kontratu txikiak, publizitaterik gabeko prozedurak eta lizitatzaile bakarreko kontratuak, administrazioka eta alderdika.</p>
    </a>
    <a href="/eu/transparencia/subvenciones" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 Eraikitzen</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Diru-laguntzak</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Norgehiagoka lehiarik gabe zenbat ematen den (zuzeneko emakida eta izendunak) eta nork ematen duen.</p>
    </a>
    <a href="/eu/transparencia/consejo-transparencia" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 Eraikitzen</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Informazioa eskuratzeko erreklamazioak</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Ukatutako informazioagatiko zenbat erreklamazio ebazten dituen Gardentasun Kontseiluak eta zer ministeriori eragiten dieten.</p>
    </a>
</Grid>

Espainiako datu irekien iturriak [Datu irekiak Espainian](/eu/varios/datos-abiertos) orrian bilduta daude.
