---
title: Ciudades de España y de Europa
description: "Las ciudades españolas frente a unas 900 ciudades europeas con los datos de Urban Audit de Eurostat: paro, población, inmigración, natalidad, vivienda, coches, tráfico, estudios y la encuesta europea de calidad de vida. Mapa, clasificación, evolución y ficha de cada ciudad."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaMundo from '../../../../../../src/lib/components/MapaMundo.svelte';
    import TablaSeleccion from '../../../../../../src/lib/components/TablaSeleccion.svelte';
    import { IDIOMAS, idiomaDeRuta, enlace } from '../../../../../../src/lib/i18n.js';

    $: lang = idiomaDeRuta($page.url.pathname);
    $: locale = IDIOMAS[lang]?.locale ?? 'es-ES';
    const num = (v, d = 1, loc = 'es-ES') =>
        v == null ? '–' : Number(v).toLocaleString(loc, { minimumFractionDigits: d, maximumFractionDigits: d });
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicador' },
        { id: 'apartado', titulo: 'Apartado' },
        { id: 'mediana_espana', titulo: 'Mediana España', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mejor_espana', titulo: 'Mejor ciudad española', fmt: (v, f) => (f.sentido === 'neutro' ? '' : v ?? '') },
        { id: 'n_ciudades', titulo: 'Ciudades', alinear: 'right', fmt: (v, f) => `${f.n_espana} / ${v}` },
        { id: 'anio_ref', titulo: 'Año', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'puesto', titulo: '#', alinear: 'right' },
        { id: 'ciudad', titulo: 'Ciudad', fmt: (v, f) => (f.es_espana ? `▶ ${v}` : v) },
        { id: 'pais', titulo: 'País' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'anio', titulo: 'Año', alinear: 'right' }
    ];
    $: columnasFicha = [
        { id: 'nombre', titulo: 'Indicador' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_espana', titulo: 'Mediana España', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_espana', titulo: 'Puesto en España', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}.º de ${f.n_espana}`) },
        { id: 'puesto', titulo: 'Puesto en Europa', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}.º de ${f.n_ciudades}`) },
        { id: 'anio', titulo: 'Año', alinear: 'right' }
    ];
</script>

# 🏙️ Ciudades de España y de Europa

¿Cómo está tu ciudad frente a otras de España y de Europa? Urban Audit, el programa de estadísticas
urbanas de Eurostat, reúne datos con las mismas definiciones de **{ciudades_n[0]?.n ?? '…'} ciudades
europeas**, {ciudades_n[0]?.n_espana ?? '…'} de ellas españolas: casi todos los municipios de más de
50.000 habitantes. Aquí están sus datos de población, empleo, vivienda, movilidad y educación, y la
encuesta europea de calidad de vida en las ciudades, en la que se pregunta a sus vecinos si están
satisfechos de vivir en ella, si se sienten seguros o si es fácil encontrar trabajo o una vivienda.
Para los países, mira [España en Europa](/varios/espana-en-europa).

```sql ciudades_n
SELECT count(*) AS n, count(*) FILTER (WHERE es_espana) AS n_espana FROM mother.ciudades
```

```sql resumen
SELECT * FROM mother.ciudades_resumen ORDER BY orden
```

## Todos los indicadores

Pulsa un indicador para ver el mapa de las ciudades europeas, la clasificación y la evolución.

<TablaSeleccion data={resumen} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Buscar un indicador (paro, vivienda, seguridad…)" etiqueta="Indicadores de ciudades" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

{#if elegido.length}

## {elegido[0].nombre}

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · último dato de cada ciudad entre {elegido[0].anio_min} y {elegido[0].anio_ref} · Fuente: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (se abre en una pestaña nueva)</span></a>
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Ciudad española mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_espana} ciudades españolas</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Ciudad europea mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_europa, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_ciudades} ciudades europeas</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor más alto de Europa' : 'Mejor ciudad europea'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_ciudad} ({elegido[0].mejor_ciudad_pais})</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor más alto de España' : 'Mejor ciudad española'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_espana_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_espana}</p>
    </div>
</div>

### Mapa y clasificación

<ButtonGroup name=ambito title="Ciudades">
    <ButtonGroupItem valueLabel="Toda Europa" value="europa" default />
    <ButtonGroupItem valueLabel="Solo España" value="espana" />
</ButtonGroup>

```sql datos
SELECT *
FROM mother.ciudades_ultimo
WHERE indicador_id = '${inputs.indicador}'
  AND ('${inputs.ambito}' = 'europa' OR es_espana)
ORDER BY puesto
```

{#if datos.length && datos[0]?.indicador_id === elegido[0].indicador_id}

<MapaMundo puntos data={datos} vista={inputs.ambito === "espana" ? "espana" : "europa"} id="cod_ciudad" decimales={elegido[0].decimales} unidad={elegido[0].unidad} sentido={elegido[0].sentido} destacar={inputs.ciudad_marcada} title="{elegido[0].nombre}, último dato de cada ciudad" height={600} />

**Clasificación** {elegido[0].sentido === 'neutro' ? '(de mayor a menor)' : '(de mejor a peor)'}: pulsa una ciudad para marcarla en el mapa.

<TablaSeleccion data={datos} name=ciudad_marcada value=cod_ciudad columnas={columnasRanking} placeholder="Buscar ciudad o país" etiqueta="Clasificación de ciudades" alto={380} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Actualizando el mapa…</p>
{/if}

### Evolución

```sql ciudades_disponibles
SELECT DISTINCT cod_ciudad, ciudad || ' (' || pais || ')' AS etiqueta
FROM mother.ciudades_series
WHERE indicador_id = '${inputs.indicador}'
ORDER BY etiqueta
```

<Dropdown data={ciudades_disponibles} name=ciudades_evolucion value=cod_ciudad label=etiqueta title="Ciudades" multiple=true defaultValue={['ES001C', 'ES002C', 'ES003C', 'ES004C', 'FR001C', 'DE001C', 'IT001C', 'PT001C']} />

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

## Ficha de una ciudad española

Todos los indicadores de una ciudad, con su puesto entre las españolas y entre las europeas.

```sql ciudades_espana
SELECT cod_ciudad, ciudad FROM mother.ciudades WHERE es_espana ORDER BY ciudad
```

<Dropdown data={ciudades_espana} name=ciudad_ficha value=cod_ciudad label=ciudad title="Ciudad" defaultValue="ES001C" />

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
{ficha_ciudad[0].ciudad}: {num(ficha_ciudad[0].poblacion, 0, locale)} habitantes en {ficha_ciudad[0].anio_poblacion} según Urban Audit{#if ficha_ciudad[0].cod_mun}&nbsp;· <a href={enlace(`/territorios/municipios?m=${ficha_ciudad[0].cod_mun}`, lang)}>ver su ficha de municipio</a>{/if}
</p>
{/if}

<TablaSeleccion data={ficha} name=indicador_ficha value=indicador_id columnas={columnasFicha} placeholder="Buscar un indicador" etiqueta="Ficha de la ciudad" alto={520} />

## Notas

- **Qué es una ciudad**: Eurostat y los institutos de estadística definen las ciudades de Urban Audit con criterios comunes de densidad. Casi siempre coinciden con el municipio, pero en algunas grandes ciudades son la «gran ciudad», con municipios vecinos: Madrid, Barcelona o Valencia tienen más población aquí que en el padrón de su municipio, y París son más de diez millones de habitantes.
- **Último dato de cada ciudad**: no todas las ciudades publican todos los años, así que se compara el último dato de cada una en los cinco años anteriores al más reciente; el año de cada ciudad sale en la clasificación y en el mapa al pasar el ratón.
- **Encuesta de calidad de vida**: la hace la Comisión Europea a unas 800 personas por ciudad cada tres o cuatro años (la última, en 2023) en unas 80 ciudades, solo cuatro españolas: Madrid, Barcelona, Málaga y Oviedo. Las cifras suman las respuestas «muy» y «bastante» de acuerdo o satisfechos.
- **Datos imposibles**: Urban Audit trae algunos valores que no pueden ser (más del 100 % de la población nacida fuera, miles de coches por cada 1.000 habitantes); se han quitado. Aun así, en algunas ciudades pequeñas un solo caso mueve mucho las tasas (muertes de tráfico, mortalidad infantil), y en algunas italianas los coches de empresas de alquiler disparan los turismos por habitante.
- **Precio de la vivienda**: euros corrientes del año de cada ciudad, sin descontar la inflación ni las diferencias de precios entre países.
- **Puesto**: 1 es la mejor ciudad (el valor más alto si más es mejor, el más bajo si más es peor); en los indicadores sin lectura clara, 1 es el valor más alto. Los colores del mapa reparten las ciudades en cinco grupos del mismo tamaño; el tamaño del círculo es la población.

<LastRefreshed prefix="Datos actualizados" />
