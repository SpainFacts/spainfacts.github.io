---
title: Espainiako eta Europako hiriak
description: "Espainiako hiriak Europako 900 hiri inguruekin alderatuta, Eurostaten Urban Audit programaren datuekin: langabezia, biztanleria, immigrazioa, jaiotza-tasa, etxebizitza, autoak, trafikoa, ikasketak eta bizi-kalitateari buruzko Europako inkesta. Mapa, sailkapena, bilakaera eta hiri bakoitzaren fitxa."
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
        { id: 'nombre', titulo: 'Adierazlea' },
        { id: 'apartado', titulo: 'Atala' },
        { id: 'mediana_espana', titulo: 'Mediana Espainian', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europan', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mejor_espana', titulo: 'Espainiako hiririk onena', fmt: (v, f) => (f.sentido === 'neutro' ? '' : v ?? '') },
        { id: 'n_ciudades', titulo: 'Hiriak', alinear: 'right', fmt: (v, f) => `${f.n_espana} / ${v}` },
        { id: 'anio_ref', titulo: 'Urtea', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'puesto', titulo: '#', alinear: 'right' },
        { id: 'ciudad', titulo: 'Hiria', fmt: (v, f) => (f.es_espana ? `▶ ${v}` : v) },
        { id: 'pais', titulo: 'Herrialdea' },
        { id: 'valor', titulo: 'Balioa', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'anio', titulo: 'Urtea', alinear: 'right' }
    ];
    $: columnasFicha = [
        { id: 'nombre', titulo: 'Adierazlea' },
        { id: 'valor', titulo: 'Balioa', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_espana', titulo: 'Mediana Espainian', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'mediana_europa', titulo: 'Mediana Europan', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_espana', titulo: 'Postua Espainian', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}. (${f.n_espana}tik)`) },
        { id: 'puesto', titulo: 'Postua Europan', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}. (${f.n_ciudades}tik)`) },
        { id: 'anio', titulo: 'Urtea', alinear: 'right' }
    ];
</script>

# 🏙️ Espainiako eta Europako hiriak

Nola dago zure hiria Espainiako eta Europako beste hiriekin alderatuta? Urban Audit Eurostaten hiri-estatistiken
programa da, eta definizio berberak dituzten datuak biltzen ditu **Europako {ciudades_n[0]?.n ?? '…'} hiritan**;
horietatik {ciudades_n[0]?.n_espana ?? '…'} Espainiakoak dira: 50.000 biztanletik gorako udalerri ia guztiak.
Hemen daude haien biztanleria, enplegu, etxebizitza, mugikortasun eta hezkuntza datuak, eta hirietako
bizi-kalitateari buruzko Europako inkesta. Inkesta horretan bizilagunei galdetzen zaie ea pozik bizi diren
beren hirian, seguru sentitzen diren edo erraza den lana edo etxebizitza aurkitzea.
Herrialdeetarako, ikusi [Espainia Europan](/eu/varios/espana-en-europa).

```sql ciudades_n
SELECT count(*) AS n, count(*) FILTER (WHERE es_espana) AS n_espana FROM mother.ciudades
```

```sql resumen
SELECT * FROM mother.ciudades_resumen ORDER BY orden
```

## Adierazle guztiak

Sakatu adierazle bat Europako hirien mapa, sailkapena eta bilakaera ikusteko.

<TablaSeleccion data={resumen} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Bilatu adierazle bat (langabezia, etxebizitza, segurtasuna…)" etiqueta="Hirien adierazleak" alto={360} />

```sql elegido
SELECT * FROM ${resumen} WHERE indicador_id = '${inputs.indicador}'
```

{#if elegido.length}

## {elegido[0].nombre}

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · hiri bakoitzaren azken datua, {elegido[0].anio_min} eta {elegido[0].anio_ref} artean · Iturria: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (fitxa berri batean irekitzen da)</span></a>
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Espainiako hiri mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">Espainiako {elegido[0].n_espana} hiri</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Europako hiri mediana</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mediana_europa, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">Europako {elegido[0].n_ciudades} hiri</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Europako balio altuena' : 'Europako hiririk onena'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_ciudad} ({elegido[0].mejor_ciudad_pais})</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Espainiako balio altuena' : 'Espainiako hiririk onena'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_espana_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_espana}</p>
    </div>
</div>

### Mapa eta sailkapena

<ButtonGroup name=ambito title="Hiriak">
    <ButtonGroupItem valueLabel="Europa osoa" value="europa" default />
    <ButtonGroupItem valueLabel="Espainia bakarrik" value="espana" />
</ButtonGroup>

```sql datos
SELECT *
FROM mother.ciudades_ultimo
WHERE indicador_id = '${inputs.indicador}'
  AND ('${inputs.ambito}' = 'europa' OR es_espana)
ORDER BY puesto
```

{#if datos.length && datos[0]?.indicador_id === elegido[0].indicador_id}

<MapaMundo puntos data={datos} vista={inputs.ambito === "espana" ? "espana" : "europa"} id="cod_ciudad" decimales={elegido[0].decimales} unidad={elegido[0].unidad} sentido={elegido[0].sentido} destacar={inputs.ciudad_marcada} title="{elegido[0].nombre}, hiri bakoitzaren azken datua" height={600} />

**Sailkapena** {elegido[0].sentido === 'neutro' ? '(handienetik txikienera)' : '(onenetik txarrenera)'}: sakatu hiri bat mapan markatzeko.

<TablaSeleccion data={datos} name=ciudad_marcada value=cod_ciudad columnas={columnasRanking} placeholder="Bilatu hiria edo herrialdea" etiqueta="Hirien sailkapena" alto={380} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Mapa eguneratzen…</p>
{/if}

### Bilakaera

```sql ciudades_disponibles
SELECT DISTINCT cod_ciudad, ciudad || ' (' || pais || ')' AS etiqueta
FROM mother.ciudades_series
WHERE indicador_id = '${inputs.indicador}'
ORDER BY etiqueta
```

<Dropdown data={ciudades_disponibles} name=ciudades_evolucion value=cod_ciudad label=etiqueta title="Hiriak" multiple=true defaultValue={['ES001C', 'ES002C', 'ES003C', 'ES004C', 'FR001C', 'DE001C', 'IT001C', 'PT001C']} />

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

## Espainiako hiri baten fitxa

Hiri baten adierazle guztiak, Espainiako hirien eta Europakoen artean duen postuarekin.

```sql ciudades_espana
SELECT cod_ciudad, ciudad FROM mother.ciudades WHERE es_espana ORDER BY ciudad
```

<Dropdown data={ciudades_espana} name=ciudad_ficha value=cod_ciudad label=ciudad title="Hiria" defaultValue="ES001C" />

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
{ficha_ciudad[0].ciudad}: {num(ficha_ciudad[0].poblacion, 0, locale)} biztanle {ficha_ciudad[0].anio_poblacion}. urtean, Urban Auditen arabera{#if ficha_ciudad[0].cod_mun}&nbsp;· <a href={enlace(`/territorios/municipios?m=${ficha_ciudad[0].cod_mun}`, lang)}>ikusi bere udalerri-fitxa</a>{/if}
</p>
{/if}

<TablaSeleccion data={ficha} name=indicador_ficha value=indicador_id columnas={columnasFicha} placeholder="Bilatu adierazle bat" etiqueta="Hiriaren fitxa" alto={520} />

## Oharrak

- **Zer den hiri bat**: Eurostatek eta estatistika-institutuek dentsitate-irizpide komunekin zehazten dituzte Urban Auditeko hiriak. Ia beti udalerriarekin bat datoz, baina hiri handi batzuetan «hiri handia» dira, inguruko udalerriekin batera: Madrilek, Bartzelonak edo Valentziak biztanle gehiago dituzte hemen beren udalerriko erroldan baino, eta Parisek hamar milioi biztanle baino gehiago ditu.
- **Hiri bakoitzaren azken datua**: hiri guztiek ez dute urtero argitaratzen; beraz, hiri bakoitzaren azken datua alderatzen da, berrienaren aurreko bost urteetan. Hiri bakoitzaren urtea sailkapenean ageri da, eta mapan saguarekin gainetik pasatzean.
- **Bizi-kalitateari buruzko inkesta**: Europako Batzordeak egiten du, hiri bakoitzeko 800 bat pertsonari, hiru edo lau urtean behin (azkena, 2023an), 80 bat hiritan. Horietatik lau bakarrik dira Espainiakoak: Madril, Bartzelona, Malaga eta Oviedo. Zifrek «oso» eta «nahiko» ados edo pozik dauden erantzunak batzen dituzte.
- **Datu ezinezkoak**: Urban Auditek ezin izan daitezkeen balio batzuk ditu (biztanleriaren % 100 baino gehiago kanpoan jaioa, milaka auto 1.000 biztanleko); kendu egin dira. Hala ere, hiri txiki batzuetan kasu bakar batek asko mugitzen ditu tasak (trafikoko heriotzak, haurren heriotza-tasa), eta Italiako hiri batzuetan alokairu-enpresen autoek gora bultzatzen dute biztanleko turismo kopurua.
- **Etxebizitzaren prezioa**: hiri bakoitzaren urteko euro korronteak, inflazioa eta herrialdeen arteko prezio-aldeak kendu gabe.
- **Postua**: 1 hiririk onena da (balio altuena, gehiago hobea bada; baxuena, gehiago okerragoa bada); irakurketa argirik ez duten adierazleetan, 1 balio altuena da. Maparen koloreek tamaina bereko bost taldetan banatzen dituzte hiriak; zirkuluaren tamaina biztanleria da.

<LastRefreshed prefix="Datuak eguneratuta" />
