---
title: Espanya a Europa
description: "Com es compara Espanya amb la resta d'Europa en més de 70 indicadors d'Eurostat: economia, ocupació, comptes públics, desigualtat, educació, població, salut, habitatge, energia i clima. Mapa, classificació i evolució de cadascun."
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
        if (Math.abs(f.valor_espana - f.valor_ue) < 1e-9) return '= igual';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_ue) ? '▲ millor' : '▼ pitjor';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicador', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Apartat' },
        { id: 'valor_espana', titulo: 'Espanya', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'UE-27', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_ue', titulo: 'Posició a la UE', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `núm. ${v} de ${f.n_ue}`) },
        { id: 'frente_ue', titulo: 'Davant la UE', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Any', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'País', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Deu anys abans', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🇪🇺 Espanya a Europa

Està Espanya per sobre o per sota de la mitjana europea? Aquí es compara amb la resta d'Europa en
**{resumen.length} indicadors d'Eurostat**, l'oficina estadística de la UE, que mesura igual tots
els països: les mateixes enquestes d'ocupació i de condicions de vida, els mateixos comptes nacionals i
públics. Les xifres van per habitant, en percentatge o en paritat de poder adquisitiu (descomptant
que la vida no costa el mateix a tots els països), mai en totals que només reflecteixin la mida
de cada país. Per a la resta del món, mira [Espanya al món](/ca/varios/espana-en-el-mundo).

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
    { valor: 'mejor', n: balance[0]?.mejor, texto: 'indicadors en què Espanya està millor que la mitjana de la UE', tono: 'verde' },
    { valor: 'peor', n: balance[0]?.peor, texto: 'indicadors en què Espanya està pitjor que la mitjana de la UE', tono: 'rojo' },
    { valor: 'tercio_alto', n: balance[0]?.tercio_alto, texto: 'al terç capdavanter de la UE-27' },
    { valor: 'tercio_bajo', n: balance[0]?.tercio_bajo, texto: 'al terç de la cua de la UE-27' }
]} />

Millor o pitjor només es jutja en els {balance[0]?.con_sentido ?? '…'} indicadors en què més és clarament
millor (ocupació, renda, esperança de vida...) o clarament pitjor (atur, pobresa, emissions...). En els
altres (inflació, fecunditat, despesa pública, edat mitjana...) la posició ordena de més a menys, sense
jutjar.

## Tots els indicadors

Cerca un indicador o filtra per apartat i fes clic a la seva fila per veure el mapa d'Europa, la classificació
dels països i l'evolució d'Espanya davant la UE.

```sql apartados
SELECT apartado, min(orden) AS o FROM ${resumen} GROUP BY apartado ORDER BY o
```

<ButtonGroup data={apartados} name=apartado value=apartado title="Apartat">
    <ButtonGroupItem valueLabel="Tots" value="Todos" default />
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

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Cerca un indicador (atur, pobresa, renda, deute…)" etiqueta="Indicadors d'Espanya a Europa" alto={360} />

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
{textosIndicador(elegido[0], lang).unidad} · Font: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{textosIndicador(elegido[0], lang).fuente}<span class="sr-only"> (s'obre en una pestanya nova)</span></a> · Sèrie d'Espanya des de {elegido[0].anio_inicio}
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Espanya, {elegido[0].anio_ref}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">fa deu anys: {num(elegido[0].valor_espana_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Mitjana de la UE-27</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">fa deu anys: {num(elegido[0].valor_ue_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Posició d'Espanya</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">núm. {elegido[0].puesto_ue ?? '–'} <span class="text-sm font-normal">de {elegido[0].n_ue} a la UE</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">núm. {elegido[0].puesto} de {elegido[0].n_paises} països europeus · {elegido[0].sentido === 'neutro' ? 'de més a menys' : 'de millor a pitjor'}</p>
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

**Classificació {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(de més a menys)' : '(de millor a pitjor)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Cerca un país" etiqueta="Classificació de països europeus" alto={480} />

</div>
</Grid>

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">S'està actualitzant el mapa…</p>
{/if}

### Evolució

Espanya davant la mitjana de la UE-27 i els països que triïs.

```sql paises_disponibles
SELECT DISTINCT cod_pais, pais FROM mother.internacional_europa
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado AND cod_pais <> 'ES'
ORDER BY pais
```

<Dropdown data={paises_disponibles} name=paises value=cod_pais label=pais title="Compara amb" multiple=true defaultValue={['FR', 'DE', 'IT', 'PT']} />

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

- **Països**: els que publica Eurostat a cada taula: els 27 de la UE, gairebé sempre Noruega, Suïssa i Islàndia, i sovint el Regne Unit (fins al 2019 o el 2020) i els candidats a entrar-hi (Turquia, Sèrbia, Macedònia del Nord, Montenegro, Albània...). La mitjana de la UE-27 és la d'Eurostat (ponderada per població o per PIB segons l'indicador), no la mitjana simple dels països.
- **Any de referència**: l'últim amb dada d'Espanya i de la majoria dels països. Alguns països publiquen abans, així que hi pot haver anys més recents amb menys països: tria'ls al desplegable del mapa.
- **Posició**: 1 és el millor (el valor més alt si més és millor, el més baix si més és pitjor). En els indicadors sense lectura clara, 1 és el valor més alt.
- **Paritat de poder adquisitiu (PPA)**: Eurostat converteix euros i altres monedes a una unitat comuna que descompta les diferències de preus entre països, per comparar el que de debò es pot comprar.
- Els colors del mapa reparteixen els països en cinc grups amb el mateix nombre de països cadascun. Verd és millor i vermell pitjor; en els indicadors sense lectura clara, blau més fosc és més alt.

<LastRefreshed prefix="Dades actualitzades" />
