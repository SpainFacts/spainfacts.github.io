---
title: Ciutats d'Espanya i d'Europa
description: "Les ciutats espanyoles davant unes 900 ciutats europees amb les dades d'Urban Audit d'Eurostat: atur, població, immigració, natalitat, habitatge, cotxes, trànsit, estudis i l'enquesta europea de qualitat de vida. Mapa, classificació, evolució i fitxa de cada ciutat."
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
        { id: 'nombre', titulo: 'Indicador' },
        { id: 'apartado', titulo: 'Apartat' },
        { id: 'mediana_espana', titulo: 'Mediana Espanya', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mejor_espana', titulo: 'Millor ciutat espanyola', fmt: (v, f) => (f.sentido === 'neutro' ? '' : v ?? '') },
        { id: 'n_ciudades', titulo: 'Ciutats', alinear: 'right', fmt: (v, f) => `${f.n_espana} / ${v}` },
        { id: 'anio_ref', titulo: 'Any', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'puesto', titulo: '#', alinear: 'right' },
        { id: 'ciudad', titulo: 'Ciutat', fmt: (v, f) => (f.es_espana ? `▶ ${v}` : v) },
        { id: 'pais', titulo: 'País' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'anio', titulo: 'Any', alinear: 'right' }
    ];
    $: columnasFicha = [
        { id: 'nombre', titulo: 'Indicador' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_espana', titulo: 'Mediana Espanya', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_espana', titulo: 'Posició a Espanya', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `núm. ${v} de ${f.n_espana}`) },
        { id: 'puesto', titulo: 'Posició a Europa', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `núm. ${v} de ${f.n_ciudades}`) },
        { id: 'anio', titulo: 'Any', alinear: 'right' }
    ];
</script>

# 🏙️ Ciutats d'Espanya i d'Europa

Com està la teva ciutat davant d'altres d'Espanya i d'Europa? Urban Audit, el programa d'estadístiques
urbanes d'Eurostat, reuneix dades amb les mateixes definicions de **{ciudades_n[0]?.n ?? '…'} ciutats
europees**, {ciudades_n[0]?.n_espana ?? '…'} d'elles espanyoles: gairebé tots els municipis de més de
50.000 habitants. Aquí hi ha les seves dades de població, ocupació, habitatge, mobilitat i educació, i
l'enquesta europea de qualitat de vida a les ciutats, que pregunta als veïns si estan satisfets de viure-hi,
si s'hi senten segurs o si és fàcil trobar feina o un habitatge.
Per als països, mira [Espanya a Europa](/ca/varios/espana-en-europa).

```sql ciudades_n
SELECT count(*) AS n, count(*) FILTER (WHERE es_espana) AS n_espana FROM mother.ciudades
```

```sql resumen
SELECT * FROM mother.ciudades_resumen ORDER BY orden
```

## Tots els indicadors

Prem un indicador per veure el mapa de les ciutats europees, la classificació i l'evolució.

<TablaSeleccion data={resumen} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Cerca un indicador (atur, habitatge, seguretat…)" etiqueta="Indicadors de ciutats" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

{#if elegido.length}

## {elegido[0].nombre}

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · última dada de cada ciutat entre {elegido[0].anio_min} i {elegido[0].anio_ref} · Font: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (s'obre en una pestanya nova)</span></a>
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Ciutat espanyola mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_espana} ciutats espanyoles</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Ciutat europea mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_europa, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_ciudades} ciutats europees</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? "Valor més alt d'Europa" : 'Millor ciutat europea'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_ciudad} ({elegido[0].mejor_ciudad_pais})</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? "Valor més alt d'Espanya" : 'Millor ciutat espanyola'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_espana_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_espana}</p>
    </div>
</div>

### Mapa i classificació

<ButtonGroup name=ambito title="Ciutats">
    <ButtonGroupItem valueLabel="Tot Europa" value="europa" default />
    <ButtonGroupItem valueLabel="Només Espanya" value="espana" />
</ButtonGroup>

```sql datos
SELECT *
FROM mother.ciudades_ultimo
WHERE indicador_id = '${inputs.indicador}'
  AND ('${inputs.ambito}' = 'europa' OR es_espana)
ORDER BY puesto
```

{#if datos.length && datos[0]?.indicador_id === elegido[0].indicador_id}

<MapaMundo puntos data={datos} vista={inputs.ambito === "espana" ? "espana" : "europa"} id="cod_ciudad" decimales={elegido[0].decimales} unidad={elegido[0].unidad} sentido={elegido[0].sentido} destacar={inputs.ciudad_marcada} title="{elegido[0].nombre}, última dada de cada ciutat" height={600} />

**Classificació** {elegido[0].sentido === 'neutro' ? '(de més a menys)' : '(de millor a pitjor)'}: prem una ciutat per marcar-la al mapa.

<TablaSeleccion data={datos} name=ciudad_marcada value=cod_ciudad columnas={columnasRanking} placeholder="Cerca una ciutat o un país" etiqueta="Classificació de ciutats" alto={380} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">S'està actualitzant el mapa…</p>
{/if}

### Evolució

```sql ciudades_disponibles
SELECT DISTINCT cod_ciudad, ciudad || ' (' || pais || ')' AS etiqueta
FROM mother.ciudades_series
WHERE indicador_id = '${inputs.indicador}'
ORDER BY etiqueta
```

<Dropdown data={ciudades_disponibles} name=ciudades_evolucion value=cod_ciudad label=etiqueta title="Ciutats" multiple=true defaultValue={['ES001C', 'ES002C', 'ES003C', 'ES004C', 'FR001C', 'DE001C', 'IT001C', 'PT001C']} />

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

## Fitxa d'una ciutat espanyola

Tots els indicadors d'una ciutat, amb la seva posició entre les espanyoles i entre les europees.

```sql ciudades_espana
SELECT cod_ciudad, ciudad FROM mother.ciudades WHERE es_espana ORDER BY ciudad
```

<Dropdown data={ciudades_espana} name=ciudad_ficha value=cod_ciudad label=ciudad title="Ciutat" defaultValue="ES001C" />

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
{ficha_ciudad[0].ciudad}: {num(ficha_ciudad[0].poblacion, 0, locale)} habitants el {ficha_ciudad[0].anio_poblacion} segons Urban Audit{#if ficha_ciudad[0].cod_mun}&nbsp;· <a href={enlace(`/territorios/municipios?m=${ficha_ciudad[0].cod_mun}`, lang)}>mostra la fitxa del municipi</a>{/if}
</p>
{/if}

<TablaSeleccion data={ficha} name=indicador_ficha value=indicador_id columnas={columnasFicha} placeholder="Cerca un indicador" etiqueta="Fitxa de la ciutat" alto={520} />

## Notes

- **Què és una ciutat**: Eurostat i els instituts d'estadística defineixen les ciutats d'Urban Audit amb criteris comuns de densitat. Gairebé sempre coincideixen amb el municipi, però en algunes grans ciutats són la «gran ciutat», amb municipis veïns: Madrid, Barcelona o València hi tenen més població que al padró del municipi, i París hi passa dels deu milions d'habitants.
- **Última dada de cada ciutat**: no totes les ciutats publiquen cada any, així que es compara l'última dada de cadascuna en els cinc anys anteriors al més recent; l'any de cada ciutat surt a la classificació i al mapa en passar-hi el ratolí.
- **Enquesta de qualitat de vida**: la fa la Comissió Europea a unes 800 persones per ciutat cada tres o quatre anys (l'última, el 2023) en unes 80 ciutats, només quatre d'espanyoles: Madrid, Barcelona, Màlaga i Oviedo. Les xifres sumen les respostes «molt» i «força» d'acord o satisfets.
- **Dades impossibles**: Urban Audit porta alguns valors que no poden ser (més del 100 % de la població nascuda fora, milers de cotxes per cada 1.000 habitants); s'han tret. Tot i així, en algunes ciutats petites un sol cas mou molt les taxes (morts de trànsit, mortalitat infantil), i en algunes d'italianes els cotxes de les empreses de lloguer disparen els turismes per habitant.
- **Preu de l'habitatge**: euros corrents de l'any de cada ciutat, sense descomptar la inflació ni les diferències de preus entre països.
- **Posició**: 1 és la millor ciutat (el valor més alt si més és millor, el més baix si més és pitjor); en els indicadors sense lectura clara, 1 és el valor més alt. Els colors del mapa reparteixen les ciutats en cinc grups de la mateixa mida; la mida del cercle és la població.

<LastRefreshed prefix="Dades actualitzades" />
