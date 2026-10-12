---
title: Cities of Spain and Europe
description: "Spanish cities compared with some 900 European cities using Eurostat's Urban Audit data: unemployment, population, immigration, births, housing, cars, traffic, education and the European quality of life survey. Map, ranking, trend and a profile of each city."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 09474b187e48
---

<script>
    import MapaMundo from '../../../../../../../src/lib/components/MapaMundo.svelte';
    import TablaSeleccion from '../../../../../../../src/lib/components/TablaSeleccion.svelte';
    import { IDIOMAS, idiomaDeRuta, enlace } from '../../../../../../../src/lib/i18n.js';

    $: lang = idiomaDeRuta($page.url.pathname);
    $: locale = IDIOMAS[lang]?.locale ?? 'es-ES';
    const num = (v, d = 1, loc = 'es-ES') =>
        v == null ? '–' : Number(v).toLocaleString(loc, { minimumFractionDigits: d, maximumFractionDigits: d });
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicator' },
        { id: 'apartado', titulo: 'Section' },
        { id: 'mediana_espana', titulo: 'Spain median', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Europe median', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mejor_espana', titulo: 'Best Spanish city', fmt: (v, f) => (f.sentido === 'neutro' ? '' : v ?? '') },
        { id: 'n_ciudades', titulo: 'Cities', alinear: 'right', fmt: (v, f) => `${f.n_espana} / ${v}` },
        { id: 'anio_ref', titulo: 'Year', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'puesto', titulo: '#', alinear: 'right' },
        { id: 'ciudad', titulo: 'City', fmt: (v, f) => (f.es_espana ? `▶ ${v}` : v) },
        { id: 'pais', titulo: 'Country' },
        { id: 'valor', titulo: 'Value', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'anio', titulo: 'Year', alinear: 'right' }
    ];
    $: columnasFicha = [
        { id: 'nombre', titulo: 'Indicator' },
        { id: 'valor', titulo: 'Value', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_espana', titulo: 'Spain median', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Europe median', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_espana', titulo: 'Rank in Spain', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `#${v} of ${f.n_espana}`) },
        { id: 'puesto', titulo: 'Rank in Europe', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `#${v} of ${f.n_ciudades}`) },
        { id: 'anio', titulo: 'Year', alinear: 'right' }
    ];
</script>

# 🏙️ Cities of Spain and Europe

How does your city compare with others in Spain and Europe? Urban Audit, Eurostat's urban statistics
programme, gathers data with the same definitions for **{ciudades_n[0]?.n ?? '…'} European
cities**, {ciudades_n[0]?.n_espana ?? '…'} of them Spanish: almost every municipality with more than
50,000 inhabitants. Here you will find their data on population, jobs, housing, mobility and education,
plus the European survey on quality of life in cities, which asks residents whether they are happy
living there, whether they feel safe and whether it is easy to find a job or a home.
For countries, see [Spain in Europe](/en/varios/espana-en-europa).

```sql ciudades_n
SELECT count(*) AS n, count(*) FILTER (WHERE es_espana) AS n_espana FROM mother.ciudades
```

```sql resumen
SELECT * FROM mother.ciudades_resumen ORDER BY orden
```

## All indicators

Click an indicator to see the map of European cities, the ranking and the trend.

<TablaSeleccion data={resumen} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Search for an indicator (unemployment, housing, safety…)" etiqueta="City indicators" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

{#if elegido.length}

## {elegido[0].nombre}

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · latest figure for each city between {elegido[0].anio_min} and {elegido[0].anio_ref} · Source: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (opens in a new tab)</span></a>
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Median Spanish city</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_espana} Spanish cities</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Median European city</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_europa, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_ciudades} European cities</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Highest value in Europe' : 'Best European city'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_ciudad} ({elegido[0].mejor_ciudad_pais})</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Highest value in Spain' : 'Best Spanish city'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_espana_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_espana}</p>
    </div>
</div>

### Map and ranking

<ButtonGroup name=ambito title="Cities">
    <ButtonGroupItem valueLabel="All of Europe" value="europa" default />
    <ButtonGroupItem valueLabel="Spain only" value="espana" />
</ButtonGroup>

```sql datos
SELECT *
FROM mother.ciudades_ultimo
WHERE indicador_id = '${inputs.indicador}'
  AND ('${inputs.ambito}' = 'europa' OR es_espana)
ORDER BY puesto
```

{#if datos.length && datos[0]?.indicador_id === elegido[0].indicador_id}

<MapaMundo puntos data={datos} vista={inputs.ambito === "espana" ? "espana" : "europa"} id="cod_ciudad" decimales={elegido[0].decimales} unidad={elegido[0].unidad} sentido={elegido[0].sentido} destacar={inputs.ciudad_marcada} title="{elegido[0].nombre}, latest figure for each city" height={600} />

**Ranking** {elegido[0].sentido === 'neutro' ? '(highest to lowest)' : '(best to worst)'}: click a city to highlight it on the map.

<TablaSeleccion data={datos} name=ciudad_marcada value=cod_ciudad columnas={columnasRanking} placeholder="Search for a city or country" etiqueta="City ranking" alto={380} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Updating the map…</p>
{/if}

### Trend

```sql ciudades_disponibles
SELECT DISTINCT cod_ciudad, ciudad || ' (' || pais || ')' AS etiqueta
FROM mother.ciudades_series
WHERE indicador_id = '${inputs.indicador}'
ORDER BY etiqueta
```

<Dropdown data={ciudades_disponibles} name=ciudades_evolucion value=cod_ciudad label=etiqueta title="Cities" multiple=true defaultValue={['ES001C', 'ES002C', 'ES003C', 'ES004C', 'FR001C', 'DE001C', 'IT001C', 'PT001C']} />

```sql evolucion
SELECT anio, ciudad, valor
FROM mother.ciudades_series
WHERE indicador_id = '${inputs.indicador}'
  AND cod_ciudad IN ${inputs.ciudades_evolucion.value}
ORDER BY anio
```

<LineChart
    data={evolucion}
    x=anio
    y=valor
    series=ciudad
    xFmt='0'
    yAxisTitle={elegido[0].unidad}
    title={elegido[0].nombre}
/>

{/if}

## Profile of a Spanish city

All the indicators for one city, with its rank among Spanish and among European cities.

```sql ciudades_espana
SELECT cod_ciudad, ciudad FROM mother.ciudades WHERE es_espana ORDER BY ciudad
```

<Dropdown data={ciudades_espana} name=ciudad_ficha value=cod_ciudad label=ciudad title="City" defaultValue="ES001C" />

```sql ficha
SELECT u.*, r.nombre, r.unidad, r.apartado, r.sentido, r.decimales, r.orden, r.mediana_espana, r.mediana_europa
FROM mother.ciudades_ultimo u
JOIN ${resumen} r USING (indicador_id)
WHERE u.cod_ciudad = '${inputs.ciudad_ficha.value}'
ORDER BY r.orden
```

```sql ficha_ciudad
SELECT * FROM mother.ciudades WHERE cod_ciudad = '${inputs.ciudad_ficha.value}'
```

{#if ficha_ciudad.length}
<p class="text-sm text-gray-600 dark:text-gray-400">
{ficha_ciudad[0].ciudad}: {num(ficha_ciudad[0].poblacion, 0, locale)} inhabitants in {ficha_ciudad[0].anio_poblacion} according to Urban Audit{#if ficha_ciudad[0].cod_mun}&nbsp;· <a href={enlace(`/territorios/municipios?m=${ficha_ciudad[0].cod_mun}`, lang)}>see its municipality profile</a>{/if}
</p>
{/if}

<TablaSeleccion data={ficha} name=indicador_ficha value=indicador_id columnas={columnasFicha} placeholder="Search for an indicator" etiqueta="City profile" alto={520} />

## Notes

- **What counts as a city**: Eurostat and the national statistics offices define Urban Audit cities with common density criteria. They almost always match the municipality, but some large cities are a «greater city» that takes in neighbouring municipalities: Madrid, Barcelona and Valencia have more people here than in their municipal register, and Paris has more than ten million inhabitants.
- **Latest figure for each city**: not every city reports every year, so the comparison uses each city's latest figure from the five years up to the most recent one; each city's year appears in the ranking and on the map when you hover over it.
- **Quality of life survey**: the European Commission carries it out every three or four years (most recently in 2023), with some 800 people per city in about 80 cities, only four of them Spanish: Madrid, Barcelona, Málaga and Oviedo. The figures add up the «strongly» and «somewhat» agree or satisfied answers.
- **Impossible figures**: Urban Audit includes some values that cannot be right (more than 100 % of the population born abroad, thousands of cars per 1,000 inhabitants); these have been removed. Even so, in some small cities a single case moves the rates a lot (road deaths, infant mortality), and in some Italian cities rental company cars push up the number of cars per inhabitant.
- **Housing prices**: current euros for each city's year, not adjusted for inflation or for price differences between countries.
- **Rank**: 1 is the best city (the highest value if more is better, the lowest if more is worse); for indicators with no clear reading, 1 is the highest value. The map colours split the cities into five groups of the same size; the size of the circle shows the population.

<LastRefreshed prefix="Data updated" />
