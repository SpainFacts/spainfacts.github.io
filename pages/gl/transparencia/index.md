---
i18n_origen: fd0f9eb9de30
title: Transparencia
description: "Como render contas as administracións españolas: obrigas de información dos concellos, portais de transparencia, decretos lei, indultos, orzamentos prorrogados e a posición de España nos índices internacionais de integridade, por Goberno e por partido."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

# <span aria-hidden="true">🔍</span> Transparencia e rendición de contas

Unha democracia pódese medir tamén por como render contas: se as administracións publican o que
deben, se o Goberno lexisla pola vía ordinaria ou por decreto, como usa o dereito de graza e como
ven a España os índices internacionais de integridade. Cada subsección atribúelle os datos ao partido
que gobernaba e compáraos co tempo que cada un estivo no poder.

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
        title="Decretos lei"
        value={actos_ult[0].rdl}
        formattedValue={formatNumber(actos_ult[0].rdl, 0)}
        unit="no ano"
        period={`${actos_ult[0].anio} · ${formatNumber(actos_ult[0].pct_rdl, 0)} % das normas con rango de lei`}
        source="BOE"
        direction="positive-down"
        href="/gl/transparencia/decretos-ley"
        sparklineData={actos.map(d => d.rdl)}
    />
    <KpiCard
        title="Indultos"
        value={actos_ult[0].indultos}
        formattedValue={formatNumber(actos_ult[0].indultos, 0)}
        unit="decretos"
        period={`${actos_ult[0].anio}`}
        source="BOE"
        direction="neutral"
        href="/gl/transparencia/indultos"
        sparklineData={actos.map(d => d.indultos)}
    />
    {/if}
    {#if cpi_ult.length}
    <KpiCard
        title="Percepción da corrupción"
        value={cpi_ult[0].valor}
        formattedValue={formatNumber(cpi_ult[0].valor, 0)}
        unit="sobre 100"
        period={`${cpi_ult[0].anio} · posto ${cpi_ult[0].puesto_ue} de ${cpi_ult[0].n_ue} na UE`}
        source="Transparency International"
        direction="positive-up"
        href="/gl/transparencia/comparacion-internacional"
        sparklineData={cpi.map(d => d.valor)}
    />
    {/if}
    {#if liquidaciones_ult.length}
    <KpiCard
        title="Concellos sen liquidación"
        value={liquidaciones_ult[0].valor}
        formattedValue={formatNumber(liquidaciones_ult[0].valor, 0)}
        unit="non a remitiron"
        period={`Orzamento de ${liquidaciones_ult[0].anio}`}
        source="Facenda"
        direction="positive-down"
        href="/gl/transparencia/cuentas-municipales"
        sparklineData={liquidaciones.map(d => d.valor)}
    />
    {/if}
</div>

## Subseccións

<Grid cols=2>
    <a href="/gl/transparencia/cuentas-municipales" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🏛️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Rendición de contas dos concellos</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Que concellos non lle remiten a Facenda a liquidación do orzamento, a Conta Xeral ou o período medio de pagamento, onde están e quen gobernaba cando vencía o prazo.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver os concellos →</span>
    </a>
    <a href="/gl/transparencia/publicidad-activa" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🪟</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Portais de transparencia</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Que administracións publican o que lles obriga a lei segundo as avaliacións oficiais (Consello de Transparencia e Comisionado de Canarias), e que falta por avaliar.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver quen cumpre →</span>
    </a>
    <a href="/gl/transparencia/decretos-ley" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📜</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Decretos lei</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cantos reais decretos lei aproba cada Goberno desde 1977, que parte das normas con rango de lei se fan por decreto e cantos derroga o Congreso.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver os decretos lei →</span>
    </a>
    <a href="/gl/transparencia/indultos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">⚖️</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Indultos</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cantos indultos concede cada Goberno segundo o BOE, como cambiaron co tempo e como se compara cada presidente e cada partido.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver os indultos →</span>
    </a>
    <a href="/gl/transparencia/presupuestos" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">📅</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Orzamentos prorrogados</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Que anos comezou o Estado sen Orzamentos Xerais aprobados, cantos días durou a prórroga e a que Goberno lle tocaba presentalos.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver os orzamentos →</span>
    </a>
    <a href="/gl/transparencia/comparacion-internacional" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 hover:border-blue-400 dark:hover:border-blue-600 transition-colors no-underline">
        <span class="text-3xl" aria-hidden="true">🌍</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">España fronte a outros países</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Índices de percepción da corrupción, gobernanza, Estado de dereito e goberno aberto: onde está España respecto da UE e da OCDE e como cambiou con cada Goberno.</p>
        <span class="mt-4 inline-block text-sm font-semibold text-blue-700 dark:text-blue-400">Ver a comparación →</span>
    </a>
</Grid>

## En construción

Estas pezas da rendición de contas teñen datos públicos, pero aínda non están feitas porque as súas
fontes non se publican en formatos doados de reutilizar. Cada páxina explica que mostrará e que falta.

<Grid cols=2>
    <a href="/gl/transparencia/contratacion" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 En construción</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Contratación pública</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Contratos menores, procedementos sen publicidade e contratos cun só licitador, por administración e partido.</p>
    </a>
    <a href="/gl/transparencia/subvenciones" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 En construción</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Subvencións</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Canto se concede sen concorrencia competitiva (concesión directa e nominativas) e quen o concede.</p>
    </a>
    <a href="/gl/transparencia/consejo-transparencia" class="block rounded-xl border border-dashed border-amber-500 dark:border-amber-600 bg-amber-50/50 dark:bg-amber-950/20 p-6 hover:border-amber-600 transition-colors no-underline">
        <span class="inline-block rounded-full bg-amber-100 dark:bg-amber-900/60 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:text-amber-200">🚧 En construción</span>
        <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">Reclamacións de acceso á información</h3>
        <p class="mb-0 text-sm text-gray-600 dark:text-gray-400">Cantas reclamacións por información denegada resolve o Consello de Transparencia e a que ministerios afectan.</p>
    </a>
</Grid>

As fontes de datos abertos de España están recollidas en [Datos abertos en España](/gl/varios/datos-abiertos).
