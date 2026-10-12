---
title: Spain in Europe
description: "How Spain compares with the rest of Europe on more than 70 Eurostat indicators: economy, employment, public finances, inequality, education, population, health, housing, energy and climate. A map, a ranking and the trend for each one."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 6f85cfe0154f
---

<script>
    import MapaMundo from '../../../../../../../src/lib/components/MapaMundo.svelte';
    import TablaSeleccion from '../../../../../../../src/lib/components/TablaSeleccion.svelte';
    import TarjetasFiltro from '../../../../../../../src/lib/components/TarjetasFiltro.svelte';
    import { IDIOMAS, idiomaDeRuta } from '../../../../../../../src/lib/i18n.js';
    import { textosIndicador } from '../../../../../../../src/lib/i18n_internacional.js';

    $: lang = idiomaDeRuta($page.url.pathname);
    $: locale = IDIOMAS[lang]?.locale ?? 'es-ES';
    const num = (v, d = 1, loc = 'es-ES') =>
        v == null ? '–' : Number(v).toLocaleString(loc, { minimumFractionDigits: d, maximumFractionDigits: d });
    // Frente a la UE según si más es mejor o peor
    const frente = (f) => {
        if (f?.valor_ue == null || f?.valor_espana == null || f.sentido === 'neutro') return '';
        if (Math.abs(f.valor_espana - f.valor_ue) < 1e-9) return '= same';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_ue) ? '▲ better' : '▼ worse';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicator', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Section' },
        { id: 'valor_espana', titulo: 'Spain', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'EU-27', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_ue', titulo: 'EU rank', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `#${v} of ${f.n_ue}`) },
        { id: 'frente_ue', titulo: 'Vs the EU', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Year', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'Country', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Value', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Ten years earlier', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🇪🇺 Spain in Europe

Is Spain above or below the European average? Here it is compared with the rest of Europe on
**{resumen.length} Eurostat indicators**. Eurostat is the EU's statistical office, and it measures every
country in the same way: the same labour force and living conditions surveys, the same national and
public accounts. Figures are per inhabitant, in percentages or in purchasing power parity (which allows
for the fact that living costs differ between countries), never in totals that only reflect the size
of each country. For the rest of the world, see [Spain in the world](/en/varios/espana-en-el-mundo).

```sql resumen
SELECT
    *,
    CASE
        WHEN valor_ue IS NULL OR sentido = 'neutro' THEN NULL
        WHEN (sentido = 'positivo') = (valor_espana > valor_ue) THEN 'mejor'
        ELSE 'peor'
    END AS frente_ue
FROM mother.internacional_resumen
WHERE ambito = 'europa'
ORDER BY orden
```

```sql balance
SELECT
    count(*) FILTER (WHERE frente_ue = 'mejor') AS mejor,
    count(*) FILTER (WHERE frente_ue = 'peor') AS peor,
    count(*) FILTER (WHERE sentido <> 'neutro' AND puesto_ue <= n_ue / 3.0) AS tercio_alto,
    count(*) FILTER (WHERE sentido <> 'neutro' AND puesto_ue > 2 * n_ue / 3.0) AS tercio_bajo,
    count(*) FILTER (WHERE sentido <> 'neutro') AS con_sentido
FROM ${resumen}
```

<TarjetasFiltro name=filtro tarjetas={[
    { valor: 'mejor', n: balance[0]?.mejor, texto: 'indicators where Spain does better than the EU average', tono: 'verde' },
    { valor: 'peor', n: balance[0]?.peor, texto: 'indicators where Spain does worse than the EU average', tono: 'rojo' },
    { valor: 'tercio_alto', n: balance[0]?.tercio_alto, texto: 'in the top third of the EU-27' },
    { valor: 'tercio_bajo', n: balance[0]?.tercio_bajo, texto: 'in the bottom third of the EU-27' }
]} />

Better or worse is only judged for the {balance[0]?.con_sentido ?? '…'} indicators where more is clearly
better (employment, income, life expectancy...) or clearly worse (unemployment, poverty, emissions...).
For the rest (inflation, fertility, public spending, median age...) the rank simply runs from highest to
lowest, without judgement.

## All indicators

Search for an indicator or filter by section, then click its row to see the map of Europe, the country
ranking and Spain's trend compared with the EU.

```sql apartados
SELECT apartado, min(orden) AS o FROM ${resumen} GROUP BY apartado ORDER BY o
```

<ButtonGroup data={apartados} name=apartado value=apartado title="Section">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
</ButtonGroup>

```sql indicadores
SELECT * FROM ${resumen}
WHERE ('${inputs.apartado}' = 'Todos' OR apartado = '${inputs.apartado}')
  AND coalesce(CASE '${inputs.filtro}'
      WHEN 'mejor' THEN frente_ue = 'mejor'
      WHEN 'peor' THEN frente_ue = 'peor'
      WHEN 'tercio_alto' THEN sentido <> 'neutro' AND puesto_ue <= n_ue / 3.0
      WHEN 'tercio_bajo' THEN sentido <> 'neutro' AND puesto_ue > 2 * n_ue / 3.0
      ELSE true
  END, false)
ORDER BY orden
```

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Search for an indicator (unemployment, poverty, income, debt…)" etiqueta="Indicators of Spain in Europe" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

```sql anios
SELECT DISTINCT indicador_id, anio FROM mother.internacional_europa
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
        <p class="text-xs text-gray-500 dark:text-gray-400">EU-27 average</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">ten years ago: {num(elegido[0].valor_ue_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Spain's rank</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">#{elegido[0].puesto_ue ?? '–'} <span class="text-sm font-normal">of {elegido[0].n_ue} in the EU</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">#{elegido[0].puesto} of {elegido[0].n_paises} European countries · {elegido[0].sentido === 'neutro' ? 'highest to lowest' : 'best to worst'}</p>
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
    SELECT * FROM mother.internacional_europa WHERE indicador_id = '${inputs.indicador}'
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

<Grid cols=3>
<div class="col-span-2">
<MapaMundo data={datos} vista="europa" decimales={elegido[0].decimales} unidad={textosIndicador(elegido[0], lang).unidad} sentido={elegido[0].sentido} title="{textosIndicador(elegido[0], lang).nombre}, {datos[0].anio}" height={560} />
</div>
<div>

**Ranking {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(highest to lowest)' : '(best to worst)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Search for a country" etiqueta="Ranking of European countries" alto={480} />

</div>
</Grid>

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Updating the map…</p>
{/if}

### Trend

Spain compared with the EU-27 average and with the countries you choose.

```sql paises_disponibles
SELECT DISTINCT cod_pais, pais FROM mother.internacional_europa
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado AND cod_pais <> 'ES'
ORDER BY pais
```

<Dropdown data={paises_disponibles} name=paises value=cod_pais label=pais title="Compare with" multiple=true defaultValue={['FR', 'DE', 'IT', 'PT']} />

```sql evolucion
SELECT anio, CASE WHEN cod_pais = 'EU27_2020' THEN 'UE-27' ELSE pais END AS pais, valor
FROM mother.internacional_europa
WHERE indicador_id = '${inputs.indicador}'
  AND (cod_pais IN ('ES', 'EU27_2020') OR cod_pais IN ${inputs.paises.value})
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
    seriesColors={{'España': '#b91c1c', 'UE-27': '#6b7280'}}
    title={textosIndicador(elegido[0], lang).nombre}
/>

{/if}

## Notes

- **Countries**: those Eurostat publishes in each table: the 27 EU members, nearly always Norway, Switzerland and Iceland, and often the United Kingdom (up to 2019 or 2020) and the candidate countries (Turkey, Serbia, North Macedonia, Montenegro, Albania...). The EU-27 average is Eurostat's own (weighted by population or by GDP, depending on the indicator), not the simple average of the countries.
- **Reference year**: the latest year with data for Spain and for most countries. Some countries publish earlier, so there may be more recent years with fewer countries: you can pick them in the map's drop-down.
- **Rank**: 1 is the best (the highest value if more is better, the lowest if more is worse). For indicators with no clear reading, 1 is the highest value.
- **Purchasing power parity (PPP)**: Eurostat converts euros and other currencies into a common unit that removes price differences between countries, to compare what money can really buy.
- The map colours split the countries into five groups with the same number of countries in each. Green is better and red is worse; for indicators with no clear reading, darker blue is higher.

<LastRefreshed prefix="Data updated" />
