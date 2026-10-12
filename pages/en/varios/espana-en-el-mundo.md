---
title: Spain in the world
description: "How Spain compares with the other countries of the world on more than 50 indicators from the World Bank, the IMF, the UN and other sources: wealth, employment, population, health, education, inequality, safety, energy and climate. A world map, a ranking and the trend for each one."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: d2d5a42614f5
---

<script>
    import MapaMundo from '../../../../../../../src/lib/components/MapaMundo.svelte';
    import TablaSeleccion from '../../../../../../../src/lib/components/TablaSeleccion.svelte';
    import { IDIOMAS, idiomaDeRuta } from '../../../../../../../src/lib/i18n.js';
    import { textosIndicador } from '../../../../../../../src/lib/i18n_internacional.js';

    $: lang = idiomaDeRuta($page.url.pathname);
    $: locale = IDIOMAS[lang]?.locale ?? 'es-ES';
    const num = (v, d = 1, loc = 'es-ES') =>
        v == null ? '–' : Number(v).toLocaleString(loc, { minimumFractionDigits: d, maximumFractionDigits: d });
    // Frente a la media mundial según si más es mejor o peor
    const frente = (f) => {
        if (f?.valor_mundo == null || f?.valor_espana == null || f.sentido === 'neutro') return '';
        if (Math.abs(f.valor_espana - f.valor_mundo) < 1e-9) return '= same';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_mundo) ? '▲ better' : '▼ worse';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicator', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Section' },
        { id: 'valor_espana', titulo: 'Spain', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_mundo', titulo: 'World', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'EU', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto', titulo: 'World rank', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `#${v} of ${f.n_paises}`) },
        { id: 'frente_mundo', titulo: 'Vs the world', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Year', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'Country', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Value', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Ten years earlier', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🌍 Spain in the world

Where does Spain stand among the world's 200 or so countries? Here it is compared on
**{resumen.length} indicators** from the World Bank, the IMF, the UN, the WHO, Ember and the World Happiness
Report, which gather data for almost every country using common definitions. Figures are per
inhabitant, in percentages or in purchasing power parity (which allows for the fact that living costs
differ between countries), never in totals that only reflect the size of each country. For a closer
comparison with Spain's European neighbours, using Eurostat's harmonised statistics, see
[Spain in Europe](/en/varios/espana-en-europa).

```sql resumen
SELECT
    *,
    CASE
        WHEN valor_mundo IS NULL OR sentido = 'neutro' THEN NULL
        WHEN (sentido = 'positivo') = (valor_espana > valor_mundo) THEN 'mejor'
        ELSE 'peor'
    END AS frente_mundo,
    CASE
        WHEN valor_ue IS NULL OR sentido = 'neutro' THEN NULL
        WHEN (sentido = 'positivo') = (valor_espana > valor_ue) THEN 'mejor'
        ELSE 'peor'
    END AS frente_ue
FROM mother.internacional_resumen
WHERE ambito = 'mundo'
ORDER BY orden
```

```sql balance
SELECT
    count(*) FILTER (WHERE frente_ue = 'mejor') AS mejor,
    count(*) FILTER (WHERE frente_ue = 'peor') AS peor,
    count(*) FILTER (WHERE sentido <> 'neutro' AND puesto <= n_paises / 4.0) AS cuarto_alto,
    count(*) FILTER (WHERE sentido <> 'neutro' AND puesto > n_paises / 2.0) AS mitad_baja,
    count(*) FILTER (WHERE sentido <> 'neutro') AS con_sentido
FROM ${resumen}
```

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-6 not-prose">
    <div class="rounded-xl border border-green-200 dark:border-green-900 bg-green-50/60 dark:bg-green-950/30 p-4">
        <p class="text-3xl font-bold text-green-700 dark:text-green-400">{balance[0]?.mejor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">indicators where Spain does better than the European Union average</p>
    </div>
    <div class="rounded-xl border border-red-200 dark:border-red-900 bg-red-50/60 dark:bg-red-950/30 p-4">
        <p class="text-3xl font-bold text-red-700 dark:text-red-400">{balance[0]?.peor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">indicators where Spain does worse than the European Union average</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.cuarto_alto ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">among the best 25 % of countries in the world</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.mitad_baja ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">in the bottom half of the world</p>
    </div>
</div>

Against the world, Spain is nearly always above average, so the comparison that tells you most is the
one with the European Union. Better or worse is only judged for the {balance[0]?.con_sentido ?? '…'} indicators
where more is clearly better (wealth, life expectancy, employment...) or clearly worse (unemployment,
mortality, emissions...). For the rest (inflation, fertility, urban population...) the rank simply runs
from highest to lowest, without judgement.

## All indicators

Search for an indicator or filter by section, then click its row to see the world map, the country
ranking and Spain's trend compared with the world, the EU and the countries you choose.

```sql apartados
SELECT apartado, min(orden) AS o FROM ${resumen} GROUP BY apartado ORDER BY o
```

<ButtonGroup data={apartados} name=apartado value=apartado title="Section">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
</ButtonGroup>

```sql indicadores
SELECT * FROM ${resumen}
WHERE '${inputs.apartado}' = 'Todos' OR apartado = '${inputs.apartado}'
ORDER BY orden
```

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Search for an indicator (wealth, unemployment, life, emissions…)" etiqueta="Indicators of Spain in the world" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

```sql anios
SELECT DISTINCT indicador_id, anio FROM mother.internacional_mundo
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado
ORDER BY anio DESC
```

{#if elegido.length}

## {textosIndicador(elegido[0], lang).nombre}

<p class="text-sm text-gray-600 dark:text-gray-400">
{textosIndicador(elegido[0], lang).unidad} · Source: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{textosIndicador(elegido[0], lang).fuente}<span class="sr-only"> (opens in a new tab)</span></a> · Spanish series since {elegido[0].anio_inicio}
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Spain, {elegido[0].anio_ref}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">ten years ago: {num(elegido[0].valor_espana_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">World</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_mundo, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">European Union: {num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Spain's rank</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">#{elegido[0].puesto ?? '–'} <span class="text-sm font-normal">of {elegido[0].n_paises} countries</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">#{elegido[0].puesto_ue ?? '–'} of {elegido[0].n_ue} in the EU · {elegido[0].sentido === 'neutro' ? 'highest to lowest' : 'best to worst'}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Highest value' : 'Best country'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_pais}</p>
    </div>
</div>

### Map and ranking

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Year" defaultValue="ref">
    <DropdownOption value="ref" valueLabel="Reference year" />
</Dropdown>

```sql datos
WITH disponibles AS (
    SELECT * FROM mother.internacional_mundo WHERE indicador_id = '${inputs.indicador}'
),
anio_elegido AS (
    -- el año del desplegable si existe para este indicador; si no, el de referencia
    SELECT coalesce(
        max(d.anio) FILTER (WHERE d.anio = try_cast('${inputs.anio.value}' AS INTEGER)),
        any_value(r.anio_ref)
    ) AS anio
    FROM disponibles d
    JOIN ${resumen} r USING (indicador_id)
)
SELECT
    d.indicador_id,
    d.cod_pais,
    d.pais,
    d.region,
    d.es_ue,
    d.es_agregado,
    d.anio,
    d.valor,
    h.valor AS valor_hace_10,
    CASE WHEN NOT d.es_agregado THEN CAST(rank() OVER (
        PARTITION BY d.es_agregado
        ORDER BY CASE WHEN r.sentido = 'negativo' THEN d.valor ELSE -d.valor END
    ) AS INTEGER) END AS posicion
FROM disponibles d
JOIN anio_elegido a USING (anio)
JOIN ${resumen} r ON r.indicador_id = d.indicador_id
LEFT JOIN disponibles h ON h.cod_pais = d.cod_pais AND h.anio = d.anio - 10
ORDER BY d.es_agregado, posicion
```

{#if datos.length && datos[0]?.indicador_id === elegido[0].indicador_id}

<MapaMundo data={datos} vista="mundo" decimales={elegido[0].decimales} unidad={textosIndicador(elegido[0], lang).unidad} sentido={elegido[0].sentido} title="{textosIndicador(elegido[0], lang).nombre}, {datos[0].anio}" height={520} />

**Ranking {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(highest to lowest)' : '(best to worst)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Search for a country" etiqueta="Ranking of the world's countries" alto={360} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Updating the map…</p>
{/if}

### Trend

Spain compared with the world, the European Union and the countries you choose.

```sql paises_disponibles
SELECT DISTINCT cod_pais, pais FROM mother.internacional_mundo
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado AND cod_pais <> 'ES'
ORDER BY pais
```

<Dropdown data={paises_disponibles} name=paises value=cod_pais label=pais title="Compare with" multiple=true defaultValue={['FR', 'DE', 'IT', 'US', 'JP', 'MA']} />

```sql evolucion
SELECT anio, CASE cod_pais WHEN 'EU27_2020' THEN 'Unión Europea' WHEN 'WLD' THEN 'Mundo' ELSE pais END AS pais, valor
FROM mother.internacional_mundo
WHERE indicador_id = '${inputs.indicador}'
  AND (cod_pais IN ('ES', 'EU27_2020', 'WLD') OR cod_pais IN ${inputs.paises.value})
ORDER BY anio
```

<LineChart
    data={evolucion}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yAxisTitle={textosIndicador(elegido[0], lang).unidad}
    startingAtZero={false}
    seriesColors={{'España': '#b91c1c', 'Unión Europea': '#6b7280', 'Mundo': '#a3a3a3'}}
    title={textosIndicador(elegido[0], lang).nombre}
/>

{/if}

## Notes

- **Countries**: all those published by each source, which are not always the same (the World Bank covers some 215 countries and territories; life satisfaction, about 140; OECD social housing, only a few rich countries). The World and European Union aggregates are each source's own, weighted by population or by GDP depending on the indicator, not the simple average of the countries.
- **Reference year**: the latest year with data for Spain and for most countries. International sources publish with a lag of one or two years, and some countries report earlier than others: the most recent years, with fewer countries, can be picked in the map's drop-down.
- **Rank**: 1 is the best (the highest value if more is better, the lowest if more is worse). For indicators with no clear reading, 1 is the highest value. Among very small countries (Monaco, Liechtenstein, Caribbean islands) the extremes are sometimes not very representative.
- **Purchasing power parity (PPP)**: converts each currency into international dollars that remove price differences between countries, to compare what money can really buy. GDP per inhabitant is also in constant 2021 dollars, adjusted for inflation.
- **Borders**: those of GISCO, Eurostat's mapping service, following the EU's position (Western Sahara shown separately from Morocco).
- The map colours split the countries into five groups with the same number of countries in each. Green is better and red is worse; for indicators with no clear reading, darker blue is higher.

<LastRefreshed prefix="Data updated" />
