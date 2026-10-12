---
title: Cidades de España e de Europa
description: "As cidades españolas fronte a unhas 900 cidades europeas cos datos de Urban Audit de Eurostat: paro, poboación, inmigración, natalidade, vivenda, coches, tráfico, estudos e a enquisa europea de calidade de vida. Mapa, clasificación, evolución e ficha de cada cidade."
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
        { id: 'apartado', titulo: 'Apartado' },
        { id: 'mediana_espana', titulo: 'Mediana España', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mejor_espana', titulo: 'Mellor cidade española', fmt: (v, f) => (f.sentido === 'neutro' ? '' : v ?? '') },
        { id: 'n_ciudades', titulo: 'Cidades', alinear: 'right', fmt: (v, f) => `${f.n_espana} / ${v}` },
        { id: 'anio_ref', titulo: 'Ano', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'puesto', titulo: '#', alinear: 'right' },
        { id: 'ciudad', titulo: 'Cidade', fmt: (v, f) => (f.es_espana ? `▶ ${v}` : v) },
        { id: 'pais', titulo: 'País' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'anio', titulo: 'Ano', alinear: 'right' }
    ];
    $: columnasFicha = [
        { id: 'nombre', titulo: 'Indicador' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_espana', titulo: 'Mediana España', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_espana', titulo: 'Posto en España', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}.º de ${f.n_espana}`) },
        { id: 'puesto', titulo: 'Posto en Europa', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}.º de ${f.n_ciudades}`) },
        { id: 'anio', titulo: 'Ano', alinear: 'right' }
    ];
</script>

# 🏙️ Cidades de España e de Europa

Como está a túa cidade fronte a outras de España e de Europa? Urban Audit, o programa de estatísticas
urbanas de Eurostat, reúne datos coas mesmas definicións de **{ciudades_n[0]?.n ?? '…'} cidades
europeas**, {ciudades_n[0]?.n_espana ?? '…'} delas españolas: case todos os concellos de máis de
50.000 habitantes. Aquí están os seus datos de poboación, emprego, vivenda, mobilidade e educación, e a
enquisa europea de calidade de vida nas cidades, na que se lles pregunta aos veciños se están
satisfeitos de vivir nela, se se senten seguros ou se é doado atopar traballo ou unha vivenda.
Para os países, mira [España en Europa](/gl/varios/espana-en-europa).

```sql ciudades_n
SELECT count(*) AS n, count(*) FILTER (WHERE es_espana) AS n_espana FROM mother.ciudades
```

```sql resumen
SELECT * FROM mother.ciudades_resumen ORDER BY orden
```

## Todos os indicadores

Preme nun indicador para ver o mapa das cidades europeas, a clasificación e a evolución.

<TablaSeleccion data={resumen} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Buscar un indicador (paro, vivenda, seguridade…)" etiqueta="Indicadores de cidades" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

{#if elegido.length}

## {elegido[0].nombre}

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · último dato de cada cidade entre {elegido[0].anio_min} e {elegido[0].anio_ref} · Fonte: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (ábrese nunha lapela nova)</span></a>
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Cidade española mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_espana} cidades españolas</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Cidade europea mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_europa, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].n_ciudades} cidades europeas</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor máis alto de Europa' : 'Mellor cidade europea'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_ciudad} ({elegido[0].mejor_ciudad_pais})</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor máis alto de España' : 'Mellor cidade española'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_espana_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_espana}</p>
    </div>
</div>

### Mapa e clasificación

<ButtonGroup name=ambito title="Cidades">
    <ButtonGroupItem valueLabel="Toda Europa" value="europa" default />
    <ButtonGroupItem valueLabel="Só España" value="espana" />
</ButtonGroup>

```sql datos
SELECT *
FROM mother.ciudades_ultimo
WHERE indicador_id = '${inputs.indicador}'
  AND ('${inputs.ambito}' = 'europa' OR es_espana)
ORDER BY puesto
```

{#if datos.length && datos[0]?.indicador_id === elegido[0].indicador_id}

<MapaMundo puntos data={datos} vista={inputs.ambito === "espana" ? "espana" : "europa"} id="cod_ciudad" decimales={elegido[0].decimales} unidad={elegido[0].unidad} sentido={elegido[0].sentido} destacar={inputs.ciudad_marcada} title="{elegido[0].nombre}, último dato de cada cidade" height={600} />

**Clasificación** {elegido[0].sentido === 'neutro' ? '(de maior a menor)' : '(de mellor a peor)'}: preme nunha cidade para marcala no mapa.

<TablaSeleccion data={datos} name=ciudad_marcada value=cod_ciudad columnas={columnasRanking} placeholder="Buscar cidade ou país" etiqueta="Clasificación de cidades" alto={380} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Actualizando o mapa…</p>
{/if}

### Evolución

```sql ciudades_disponibles
SELECT DISTINCT cod_ciudad, ciudad || ' (' || pais || ')' AS etiqueta
FROM mother.ciudades_series
WHERE indicador_id = '${inputs.indicador}'
ORDER BY etiqueta
```

<Dropdown data={ciudades_disponibles} name=ciudades_evolucion value=cod_ciudad label=etiqueta title="Cidades" multiple=true defaultValue={['ES001C', 'ES002C', 'ES003C', 'ES004C', 'FR001C', 'DE001C', 'IT001C', 'PT001C']} />

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

## Ficha dunha cidade española

Todos os indicadores dunha cidade, co seu posto entre as españolas e entre as europeas.

```sql ciudades_espana
SELECT cod_ciudad, ciudad FROM mother.ciudades WHERE es_espana ORDER BY ciudad
```

<Dropdown data={ciudades_espana} name=ciudad_ficha value=cod_ciudad label=ciudad title="Cidade" defaultValue="ES001C" />

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
{ficha_ciudad[0].ciudad}: {num(ficha_ciudad[0].poblacion, 0, locale)} habitantes en {ficha_ciudad[0].anio_poblacion} segundo Urban Audit{#if ficha_ciudad[0].cod_mun}&nbsp;· <a href={enlace(`/territorios/municipios?m=${ficha_ciudad[0].cod_mun}`, lang)}>ver a súa ficha de concello</a>{/if}
</p>
{/if}

<TablaSeleccion data={ficha} name=indicador_ficha value=indicador_id columnas={columnasFicha} placeholder="Buscar un indicador" etiqueta="Ficha da cidade" alto={520} />

## Notas

- **Que é unha cidade**: Eurostat e os institutos de estatística definen as cidades de Urban Audit con criterios comúns de densidade. Case sempre coinciden co concello, pero nalgunhas grandes cidades son a «gran cidade», con concellos veciños: Madrid, Barcelona ou Valencia teñen aquí máis poboación que no padrón do seu concello, e París pasa dos dez millóns de habitantes.
- **Último dato de cada cidade**: non todas as cidades publican todos os anos, así que se compara o último dato de cada unha nos cinco anos anteriores ao máis recente; o ano de cada cidade aparece na clasificación e no mapa ao pasar o rato.
- **Enquisa de calidade de vida**: faina a Comisión Europea a unhas 800 persoas por cidade cada tres ou catro anos (a última, en 2023) en unhas 80 cidades, só catro españolas: Madrid, Barcelona, Málaga e Oviedo. As cifras suman as respostas «moi» e «bastante» de acordo ou satisfeitos.
- **Datos imposibles**: Urban Audit trae algúns valores que non poden ser (máis do 100 % da poboación nacida fóra, miles de coches por cada 1.000 habitantes); quitáronse. Aínda así, nalgunhas cidades pequenas un só caso move moito as taxas (mortes de tráfico, mortalidade infantil), e nalgunhas italianas os coches das empresas de aluguer disparan os turismos por habitante.
- **Prezo da vivenda**: euros correntes do ano de cada cidade, sen descontar a inflación nin as diferenzas de prezos entre países.
- **Posto**: 1 é a mellor cidade (o valor máis alto se máis é mellor, o máis baixo se máis é peor); nos indicadores sen lectura clara, 1 é o valor máis alto. As cores do mapa reparten as cidades en cinco grupos do mesmo tamaño; o tamaño do círculo é a poboación.

<LastRefreshed prefix="Datos actualizados" />
