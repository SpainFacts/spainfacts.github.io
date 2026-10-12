---
title: Espanya al món
description: "Com es compara Espanya amb els altres països del món en més de 50 indicadors del Banc Mundial, l'FMI, l'ONU i altres fonts: riquesa, ocupació, població, salut, educació, desigualtat, seguretat, energia i clima. Mapa del món, classificació i evolució de cadascun."
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
        if (Math.abs(f.valor_espana - f.valor_mundo) < 1e-9) return '= igual';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_mundo) ? '▲ millor' : '▼ pitjor';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicador', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Apartat' },
        { id: 'valor_espana', titulo: 'Espanya', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_mundo', titulo: 'Món', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'UE', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto', titulo: 'Posició mundial', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `núm. ${v} de ${f.n_paises}`) },
        { id: 'frente_mundo', titulo: 'Davant el món', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Any', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'País', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Deu anys abans', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🌍 Espanya al món

On queda Espanya entre els prop de 200 països del món? Aquí es compara en
**{resumen.length} indicadors** del Banc Mundial, l'FMI, l'ONU, l'OMS, Ember i el World Happiness
Report, que reuneixen dades de gairebé tots els països amb definicions comunes. Les xifres van per
habitant, en percentatge o en paritat de poder adquisitiu (descomptant que la vida no costa el mateix
a tots els països), mai en totals que només reflecteixin la mida de cada país. Per comparar amb
més detall amb els veïns europeus, amb les estadístiques harmonitzades d'Eurostat, mira
[Espanya a Europa](/ca/varios/espana-en-europa).

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
        <p class="text-sm text-gray-600 dark:text-gray-400">indicadors en què Espanya està millor que la mitjana de la Unió Europea</p>
    </div>
    <div class="rounded-xl border border-red-200 dark:border-red-900 bg-red-50/60 dark:bg-red-950/30 p-4">
        <p class="text-3xl font-bold text-red-700 dark:text-red-400">{balance[0]?.peor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">indicadors en què Espanya està pitjor que la mitjana de la Unió Europea</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.cuarto_alto ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">entre el 25 % de millors països del món</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.mitad_baja ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">a la meitat pitjor del món</p>
    </div>
</div>

Davant el món, Espanya surt gairebé sempre per sobre de la mitjana, així que la comparació que més diu
és la de la Unió Europea. Millor o pitjor només es jutja en els {balance[0]?.con_sentido ?? '…'} indicadors en
què més és clarament millor (riquesa, esperança de vida, ocupació...) o clarament pitjor (atur,
mortalitat, emissions...). En els altres (inflació, fecunditat, població urbana...) la posició ordena
de més a menys, sense jutjar.

## Tots els indicadors

Cerca un indicador o filtra per apartat i fes clic a la seva fila per veure el mapa del món, la classificació
dels països i l'evolució d'Espanya davant el món, la UE i els països que triïs.

```sql apartados
SELECT apartado, min(orden) AS o FROM ${resumen} GROUP BY apartado ORDER BY o
```

<ButtonGroup data={apartados} name=apartado value=apartado title="Apartat">
    <ButtonGroupItem valueLabel="Tots" value="Todos" default />
</ButtonGroup>

```sql indicadores
SELECT * FROM ${resumen}
WHERE '${inputs.apartado}' = 'Todos' OR apartado = '${inputs.apartado}'
ORDER BY orden
```

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Cerca un indicador (riquesa, atur, vida, emissions…)" etiqueta="Indicadors d'Espanya al món" alto={360} />

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
{textosIndicador(elegido[0], lang).unidad} · Font: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{textosIndicador(elegido[0], lang).fuente}<span class="sr-only"> (s'obre en una pestanya nova)</span></a> · Sèrie d'Espanya des de {elegido[0].anio_inicio}
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Espanya, {elegido[0].anio_ref}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">fa deu anys: {num(elegido[0].valor_espana_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Món</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_mundo, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">Unió Europea: {num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Posició d'Espanya</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">núm. {elegido[0].puesto ?? '–'} <span class="text-sm font-normal">de {elegido[0].n_paises} països</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">núm. {elegido[0].puesto_ue ?? '–'} de {elegido[0].n_ue} a la UE · {elegido[0].sentido === 'neutro' ? 'de més a menys' : 'de millor a pitjor'}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor més alt' : 'Millor país'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_pais}</p>
    </div>
</div>

### Mapa i classificació

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Any" defaultValue="ref">
    <DropdownOption value="ref" valueLabel="Any de referència" />
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

**Classificació {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(de més a menys)' : '(de millor a pitjor)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Cerca un país" etiqueta="Classificació de països del món" alto={360} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">S'està actualitzant el mapa…</p>
{/if}

### Evolució

Espanya davant el món, la Unió Europea i els països que triïs.

```sql paises_disponibles
SELECT DISTINCT cod_pais, pais FROM mother.internacional_mundo
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado AND cod_pais <> 'ES'
ORDER BY pais
```

<Dropdown data={paises_disponibles} name=paises value=cod_pais label=pais title="Compara amb" multiple=true defaultValue={['FR', 'DE', 'IT', 'US', 'JP', 'MA']} />

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

- **Països**: tots els que publica cada font, que no sempre són els mateixos (el Banc Mundial cobreix uns 215 països i territoris; la satisfacció amb la vida, uns 140; l'habitatge social de l'OCDE, només uns quants països rics). Els agregats Món i Unió Europea són els de cada font, ponderats per població o per PIB segons l'indicador, no la mitjana simple dels països.
- **Any de referència**: l'últim amb dada d'Espanya i de la majoria dels països. Les fonts internacionals publiquen amb un o dos anys de retard, i alguns països abans que d'altres: els anys més recents, amb menys països, es poden triar al desplegable del mapa.
- **Posició**: 1 és el millor (el valor més alt si més és millor, el més baix si més és pitjor). En els indicadors sense lectura clara, 1 és el valor més alt. Entre països molt petits (Mònaco, Liechtenstein, illes del Carib) els extrems de vegades són poc representatius.
- **Paritat de poder adquisitiu (PPA)**: converteix cada moneda a dòlars internacionals que descompten les diferències de preus entre països, per comparar el que de debò es pot comprar. El PIB per habitant va, a més, en dòlars constants del 2021, descomptada la inflació.
- **Fronteres**: les de GISCO, el servei cartogràfic d'Eurostat, amb la posició de la UE (el Sàhara Occidental, a part del Marroc).
- Els colors del mapa reparteixen els països en cinc grups amb el mateix nombre de països cadascun. Verd és millor i vermell pitjor; en els indicadors sense lectura clara, blau més fosc és més alt.

<LastRefreshed prefix="Dades actualitzades" />
