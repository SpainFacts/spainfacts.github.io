---
title: Demografia
description: "Població d'Espanya amb dades oficials de l'INE: creixement, natalitat i fecunditat, envelliment, repartiment territorial, homes i dones i llars, per comunitat i província."
i18n_origen: 306ecbcd10ab
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql edades
SELECT CAST(anio AS INTEGER) AS anio, poblacion, pct_65, pct_80, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, tasa_natalidad, tasa_mortalidad,
    vegetativo_1000, fecundidad, crecimiento_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql poblacion_serie
SELECT anio, poblacion / 1e6 AS valor FROM ${edades}
```

```sql crecimiento_ultimo
SELECT anio, crecimiento_1000, vegetativo_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000,
    100.0 * resto / crecimiento AS pct_resto
FROM ${anual}
WHERE crecimiento IS NOT NULL
ORDER BY anio DESC
LIMIT 1
```

```sql primer_negativo
SELECT min(anio) AS anio FROM ${anual} WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👪 Demografia

Quants som, quants neixen i moren, quant creix la població i per què, com envelleix i com es reparteix pel territori. Totes les xifres són oficials de l'INE i es donen per habitant o en percentatge per poder comparar anys i territoris.

<Grid cols=4>
    <KpiCard
        title="Població"
        value={edades.slice(-1)[0]?.poblacion}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.poblacion / 1e6, 2)} milions"
        period="a 1 de gener de {edades.slice(-1)[0]?.anio}"
        change={100 * (edades.slice(-1)[0]?.poblacion / edades.slice(-2)[0]?.poblacion - 1)}
        changeUnit="%"
        changePeriod="en un any"
        direction="neutral"
        source="INE"
        href="/ca/demografia/evolucion-poblacion"
        sparklineData={poblacion_serie}
    />
    <KpiCard
        title="Natalitat"
        value={anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.tasa_natalidad, 2)} per 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.nacimientos, 0)} naixements el {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/ca/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Fills per dona"
        value={anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(anual.slice(-1)[0]?.fecundidad, 2)}
        period="indicador conjuntural de fecunditat, {anual.slice(-1)[0]?.anio} (el reemplaçament generacional és 2,1)"
        source="INE"
        href="/ca/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Més grans de 65 anys"
        value={edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.pct_65, 1)} %"
        period="de la població · edat mitjana {formatNumber(edades.slice(-1)[0]?.edad_media, 1)} anys"
        source="INE"
        href="/ca/demografia/estructura-edades"
        sparklineData={edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
</Grid>

## D'on ve el creixement de la població

La població canvia per dues vies: la diferència entre naixements i defuncions (creixement vegetatiu) i la diferència entre els qui vénen a viure a Espanya i els qui se'n van (saldo migratori).

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
ORDER BY anio
```

<BarChart
    data={componentes}
    x=anio
    y=por_1000
    series=componente
    type=stacked
    yFmt=num1
    xFmt="####"
    colorPalette={['#be185d', '#0f766e']}
    yAxisTitle="per 1.000 habitants"
    title="Creixement anual de la població per 1.000 habitants i els seus components"
/>

<p class="text-xs text-gray-500">Creixement = població a 1 de gener de l'any següent menys la de l'any, segons l'Estadística Contínua de Població. "Migració i ajustos" és la part del creixement que no expliquen els naixements i les defuncions. Coincideix gairebé exactament amb el saldo migratori amb l'estranger que mesura l'Estadística de Migracions des del 2021: el {crecimiento_ultimo[0]?.anio}, {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} davant de {formatNumber(crecimiento_ultimo[0]?.saldo_exterior_1000, 1)} per 1.000 habitants (vegeu <a href="/ca/sociedad/inmigracion">Immigració</a>).</p>

{#if crecimiento_ultimo[0]?.vegetativo_1000 < 0}

El {crecimiento_ultimo[0]?.anio} la població va créixer {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} persones per cada 1.000 habitants ({formatNumber(crecimiento_ultimo[0]?.crecimiento, 0)} en total). Van morir més persones de les que van néixer ({formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} per 1.000), cosa que passa cada any des del {primer_negativo[0]?.anio}, de manera que tot el creixement prové de la migració.

{:else}

El {crecimiento_ultimo[0]?.anio} la població va créixer {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} persones per cada 1.000 habitants: {formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} per naixements menys defuncions i {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} per migració i ajustos.

{/if}

## Explora

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/ca/demografia/evolucion-poblacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📈</span> Evolució de la població</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Població des de 1971, creixement anual per 1.000 habitants i quant hi aporten els naixements, les defuncions i la migració a cada comunitat.</p>
    </a>
    <a href="/ca/demografia/natalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-pink-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">👶</span> Natalitat i fecunditat</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Naixements i defuncions per 1.000 habitants, fills per dona, edat de les mares i naixements de mare estrangera, per comunitat i província.</p>
    </a>
    <a href="/ca/demografia/estructura-edades" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-rose-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔺</span> Edats i envelliment</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Piràmides de població d'Espanya, de cada comunitat i de cada província; més grans de 65 i de 80 anys, dependència i edat mitjana.</p>
    </a>
    <a href="/ca/demografia/distribucion-territorial" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-emerald-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗺️</span> Repartiment territorial</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Quines províncies guanyen i perden població, el pes de cada comunitat i el percentatge de nascuts a l'estranger a cada província.</p>
    </a>
    <a href="/ca/demografia/poblacion-sexo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-purple-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Homes i dones</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Homes per cada 100 dones segons l'edat, al llarg del temps i a cada província.</p>
    </a>
    <a href="/ca/demografia/hogares" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏠</span> Llars</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Mida mitjana de la llar i llars d'una sola persona, per comunitat i província.</p>
    </a>
</div>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177095)**: població a 1 de gener per província, edat i sexe (taula 56945), per lloc de naixement (56948) i nacionalitat (56947), i llars (60131 a 60134).
- **[INE – Moviment Natural de la Població](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: naixements (taula 6524) i defuncions (6561) per província de residència.
- **[INE – Indicadors Demogràfics Bàsics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: taxes de natalitat i mortalitat, fecunditat, edat mitjana a la maternitat i nascuts de mare estrangera.
- **[INE – Estadística de Migracions i Canvis de Residència](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)**: saldo migratori amb l'estranger des del 2021 (vegeu [Immigració](/ca/sociedad/inmigracion)).

<LastRefreshed prefix="Dades actualitzades" />
