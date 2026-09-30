---
title: Transparència
description: "Com reten comptes les administracions espanyoles: obligacions d'informació dels ajuntaments, decrets llei, indults, pressupostos prorrogats i la posició d'Espanya en els índexs internacionals d'integritat, per Govern i per partit."
i18n_origen: 9ea4661f7e55
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

# <span aria-hidden="true">🔍</span> Transparència i retiment de comptes

Una democràcia també es pot mesurar per com ret comptes: si les administracions publiquen el que
han de publicar, si el Govern legisla per la via ordinària o per decret, com fa servir el dret de gràcia i com
veuen Espanya els índexs internacionals d'integritat. Cada subsecció atribueix les dades al partit
que governava i les compara amb el temps que cadascun ha estat al poder.

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
        title="Decrets llei"
        value={actos_ult[0].rdl}
        formattedValue={formatNumber(actos_ult[0].rdl, 0)}
        unit="en l'any"
        period={`${actos_ult[0].anio} · ${formatNumber(actos_ult[0].pct_rdl, 0)} % de les normes amb rang de llei`}
        source="BOE"
        direction="positive-down"
        href="/ca/transparencia/decretos-ley"
        sparklineData={actos.map(d => d.rdl)}
    />
    <KpiCard
        title="Indults"
        value={actos_ult[0].indultos}
        formattedValue={formatNumber(actos_ult[0].indultos, 0)}
        unit="decrets"
        period={`${actos_ult[0].anio}`}
        source="BOE"
        direction="neutral"
        href="/ca/transparencia/indultos"
        sparklineData={actos.map(d => d.indultos)}
    />
    {/if}
    {#if cpi_ult.length}
    <KpiCard
        title="Percepció de la corrupció"
        value={cpi_ult[0].valor}
        formattedValue={formatNumber(cpi_ult[0].valor, 0)}
        unit="sobre 100"
        period={`${cpi_ult[0].anio} · lloc ${cpi_ult[0].puesto_ue} de ${cpi_ult[0].n_ue} a la UE`}
        source="Transparency International"
        direction="positive-up"
        href="/ca/transparencia/comparacion-internacional"
        sparklineData={cpi.map(d => d.valor)}
    />
    {/if}
    {#if liquidaciones_ult.length}
    <KpiCard
        title="Ajuntaments sense liquidació"
        value={liquidaciones_ult[0].valor}
        formattedValue={formatNumber(liquidaciones_ult[0].valor, 0)}
        unit="no la van trametre"
        period={`Pressupost de ${liquidaciones_ult[0].anio}`}
        source="Hisenda"
        direction="positive-down"
        href="/ca/transparencia/cuentas-municipales"
        sparklineData={liquidaciones.map(d => d.valor)}
    />
    {/if}
</div>

## Subseccions

<Grid cols=2>
    <a href="/ca/transparencia/cuentas-municipales" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🏛️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Retiment de comptes dels ajuntaments</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Quins ajuntaments no trameten a Hisenda la liquidació del pressupost, el Compte General o el període mitjà de pagament, on són i qui governava quan vencia el termini.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Mostra els ajuntaments →</span>
    </a>
    <a href="/ca/transparencia/decretos-ley" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📜</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Decrets llei</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Quants reials decrets llei aprova cada Govern des de 1977, quina part de les normes amb rang de llei es fan per decret i quants en deroga el Congrés.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Mostra els decrets llei →</span>
    </a>
    <a href="/ca/transparencia/indultos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">⚖️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Indults</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Quants indults concedeix cada Govern segons el BOE, com han canviat amb el temps i com es compara cada president i cada partit.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Mostra els indults →</span>
    </a>
    <a href="/ca/transparencia/presupuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📅</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Pressupostos prorrogats</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Quins anys l'Estat va començar sense Pressupostos Generals aprovats, quants dies va durar la pròrroga i a quin Govern li tocava presentar-los.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Mostra els pressupostos →</span>
    </a>
    <a href="/ca/transparencia/comparacion-internacional" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🌍</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Espanya davant d'altres països</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Índexs de percepció de la corrupció, governança, estat de dret i govern obert: on és Espanya respecte a la UE i l'OCDE i com ha canviat amb cada Govern.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Mostra la comparació →</span>
    </a>
</Grid>

## Què més es podria mesurar

Hi ha altres peces del retiment de comptes amb dades públiques que encara no són aquí perquè les seves
fonts no es publiquen en formats reutilitzables o exigeixen una feina més gran: les resolucions del Consell
de Transparència i Bon Govern (només en llistats HTML i PDF), la contractació pública (milers de fitxers
XML de la Plataforma de Contractació del Sector Públic) i les subvencions de concessió directa (Base de
Dades Nacional de Subvencions). Les fonts de dades obertes d'Espanya són recollides a
[Dades obertes a Espanya](/ca/varios/datos-abiertos).
