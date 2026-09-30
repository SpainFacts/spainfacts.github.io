---
title: Demografía
description: "Poboación de España con datos oficiais do INE: crecemento, natalidade e fecundidade, avellentamento, repartición territorial, homes e mulleres e fogares, por comunidade e provincia."
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

# 👪 Demografía

Cantos somos, cantos nacen e morren, canto medra a poboación e por que, como avellenta e como se reparte polo territorio. Todas as cifras son oficiais do INE e danse por habitante ou en porcentaxe para poder comparar anos e territorios.

<Grid cols=4>
    <KpiCard
        title="Poboación"
        value={edades.slice(-1)[0]?.poblacion}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.poblacion / 1e6, 2)} millóns"
        period="a 1 de xaneiro de {edades.slice(-1)[0]?.anio}"
        change={100 * (edades.slice(-1)[0]?.poblacion / edades.slice(-2)[0]?.poblacion - 1)}
        changeUnit="%"
        changePeriod="nun ano"
        direction="neutral"
        source="INE"
        href="/gl/demografia/evolucion-poblacion"
        sparklineData={poblacion_serie}
    />
    <KpiCard
        title="Natalidade"
        value={anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.tasa_natalidad, 2)} por 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.nacimientos, 0)} nacementos en {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/gl/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Fillos por muller"
        value={anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(anual.slice(-1)[0]?.fecundidad, 2)}
        period="indicador conxuntural de fecundidade, {anual.slice(-1)[0]?.anio} (o remprazo xeracional é 2,1)"
        source="INE"
        href="/gl/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Maiores de 65 anos"
        value={edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.pct_65, 1)} %"
        period="da poboación · idade media {formatNumber(edades.slice(-1)[0]?.edad_media, 1)} anos"
        source="INE"
        href="/gl/demografia/estructura-edades"
        sparklineData={edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
</Grid>

## De onde vén o crecemento da poboación

A poboación cambia por dúas vías: a diferenza entre nacementos e defuncións (crecemento vexetativo) e a diferenza entre quen chega a vivir a España e quen se vai (saldo migratorio).

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
    yAxisTitle="por 1.000 habitantes"
    title="Crecemento anual da poboación por 1.000 habitantes e os seus compoñentes"
/>

<p class="text-xs text-gray-500">Crecemento = poboación a 1 de xaneiro do ano seguinte menos a do ano, segundo a Estatística Continua de Poboación. "Migración e axustes" é a parte do crecemento que non explican nacementos e defuncións. Coincide case exactamente co saldo migratorio co estranxeiro que mide a Estatística de Migracións desde 2021: en {crecimiento_ultimo[0]?.anio}, {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} fronte a {formatNumber(crecimiento_ultimo[0]?.saldo_exterior_1000, 1)} por 1.000 habitantes (ver <a href="/gl/sociedad/inmigracion">Inmigración</a>).</p>

{#if crecimiento_ultimo[0]?.vegetativo_1000 < 0}

En {crecimiento_ultimo[0]?.anio} a poboación medrou {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} persoas por cada 1.000 habitantes ({formatNumber(crecimiento_ultimo[0]?.crecimiento, 0)} en total). Morreron máis persoas das que naceron ({formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} por 1.000), algo que ocorre todos os anos desde {primer_negativo[0]?.anio}, así que todo o crecemento procede da migración.

{:else}

En {crecimiento_ultimo[0]?.anio} a poboación medrou {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} persoas por cada 1.000 habitantes: {formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} por nacementos menos defuncións e {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} por migración e axustes.

{/if}

## Explora

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/gl/demografia/evolucion-poblacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📈</span> Evolución da poboación</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Poboación desde 1971, crecemento anual por 1.000 habitantes e canto achegan nacementos, defuncións e migración en cada comunidade.</p>
    </a>
    <a href="/gl/demografia/natalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-pink-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">👶</span> Natalidade e fecundidade</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Nacementos e defuncións por 1.000 habitantes, fillos por muller, idade das nais e nacementos de nai estranxeira, por comunidade e provincia.</p>
    </a>
    <a href="/gl/demografia/estructura-edades" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-rose-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔺</span> Idades e avellentamento</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Pirámides de poboación de España, cada comunidade e cada provincia; maiores de 65 e de 80 anos, dependencia e idade media.</p>
    </a>
    <a href="/gl/demografia/distribucion-territorial" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-emerald-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗺️</span> Repartición territorial</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Que provincias gañan e perden poboación, o peso de cada comunidade e a porcentaxe de nados no estranxeiro en cada provincia.</p>
    </a>
    <a href="/gl/demografia/poblacion-sexo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-purple-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Homes e mulleres</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Homes por cada 100 mulleres segundo a idade, ao longo do tempo e en cada provincia.</p>
    </a>
    <a href="/gl/demografia/hogares" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏠</span> Fogares</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Tamaño medio do fogar e fogares dunha soa persoa, por comunidade e provincia.</p>
    </a>
</div>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177095)**: poboación a 1 de xaneiro por provincia, idade e sexo (táboa 56945), por lugar de nacemento (56948) e nacionalidade (56947), e fogares (60131 a 60134).
- **[INE – Movemento Natural da Poboación](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: nacementos (táboa 6524) e defuncións (6561) por provincia de residencia.
- **[INE – Indicadores Demográficos Básicos](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: taxas de natalidade e mortalidade, fecundidade, idade media á maternidade e nados de nai estranxeira.
- **[INE – Estatística de Migracións e Cambios de Residencia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)**: saldo migratorio co estranxeiro desde 2021 (ver [Inmigración](/gl/sociedad/inmigracion)).

<LastRefreshed prefix="Datos actualizados" />
