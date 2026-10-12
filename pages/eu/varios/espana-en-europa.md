---
title: Espainia Europan
description: "Nola konparatzen den Espainia gainerako Europarekin Eurostaten 70 adierazle baino gehiagotan: ekonomia, enplegua, kontu publikoak, desberdintasuna, hezkuntza, biztanleria, osasuna, etxebizitza, energia eta klima. Bakoitzaren mapa, sailkapena eta bilakaera."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 8ba895d2d4a0
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
    // Frente a la UE según si más es mejor o peor
    const frente = (f) => {
        if (f?.valor_ue == null || f?.valor_espana == null || f.sentido === 'neutro') return '';
        if (Math.abs(f.valor_espana - f.valor_ue) < 1e-9) return '= berdin';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_ue) ? '▲ hobea' : '▼ okerragoa';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Adierazlea', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Atala' },
        { id: 'valor_espana', titulo: 'Espainia', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'EB-27', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto_ue', titulo: 'Postua EBn', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}. (${f.n_ue}tik)`) },
        { id: 'frente_ue', titulo: 'EBrekin alderatuta', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Urtea', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'Herrialdea', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Balioa', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Hamar urte lehenago', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🇪🇺 Espainia Europan

Europako batez bestekoaren gainetik ala azpitik dago Espainia? Hemen gainerako Europarekin konparatzen da
**Eurostaten {resumen.length} adierazletan**. Eurostat EBko estatistika bulegoa da, eta herrialde guztiak
modu berean neurtzen ditu: enpleguari eta bizi-baldintzei buruzko inkesta berberak, kontu nazional eta
publiko berberak. Zifrak biztanleko, ehunekotan edo erosteko ahalmenaren parekotasunean daude (bizitzak
herrialde guztietan berdin balio ez duela kontuan hartuta), eta inoiz ez herrialde bakoitzaren tamaina
baino islatzen ez duten guztizkoetan. Munduko gainerako herrialdeekin konparatzeko, ikusi
[Espainia munduan](/eu/varios/espana-en-el-mundo).

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
    count(*) FILTER (WHERE puesto_ue IS NOT NULL AND puesto_ue <= n_ue / 3.0) AS tercio_alto,
    count(*) FILTER (WHERE puesto_ue IS NOT NULL AND puesto_ue > 2 * n_ue / 3.0) AS tercio_bajo,
    count(*) FILTER (WHERE sentido <> 'neutro') AS con_sentido
FROM ${resumen}
```

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-6 not-prose">
    <div class="rounded-xl border border-green-200 dark:border-green-900 bg-green-50/60 dark:bg-green-950/30 p-4">
        <p class="text-3xl font-bold text-green-700 dark:text-green-400">{balance[0]?.mejor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">adierazle, Espainia EBko batez bestekoa baino hobeto dagoenak</p>
    </div>
    <div class="rounded-xl border border-red-200 dark:border-red-900 bg-red-50/60 dark:bg-red-950/30 p-4">
        <p class="text-3xl font-bold text-red-700 dark:text-red-400">{balance[0]?.peor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">adierazle, Espainia EBko batez bestekoa baino okerrago dagoenak</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.tercio_alto ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">EB-27ko goiko herenean</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.tercio_bajo ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">EB-27ko beheko herenean</p>
    </div>
</div>

Hobea ala okerragoa den {balance[0]?.con_sentido ?? '…'} adierazletan baino ez da epaitzen: gehiago argi eta
garbi hobea denetan (enplegua, errenta, bizi-itxaropena...) edo argi eta garbi okerragoa denetan (langabezia,
pobrezia, isuriak...). Gainerakoetan (inflazioa, ugalkortasuna, gastu publikoa, batez besteko adina...)
postuak handienetik txikienera ordenatzen ditu, epaitu gabe.

## Adierazle guztiak

Bilatu adierazle bat edo iragazi atalka, eta sakatu haren errenkada Europako mapa, herrialdeen sailkapena
eta Espainiaren bilakaera EBrekin alderatuta ikusteko.

```sql apartados
SELECT apartado, min(orden) AS o FROM ${resumen} GROUP BY apartado ORDER BY o
```

<ButtonGroup data={apartados} name=apartado value=apartado title="Atala">
    <ButtonGroupItem valueLabel="Guztiak" value="Todos" default />
</ButtonGroup>

```sql indicadores
SELECT * FROM ${resumen}
WHERE '${inputs.apartado}' = 'Todos' OR apartado = '${inputs.apartado}'
ORDER BY orden
```

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Bilatu adierazle bat (langabezia, pobrezia, errenta, zorra…)" etiqueta="Espainia Europan: adierazleak" alto={360} />

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
{textosIndicador(elegido[0], lang).unidad} · Iturria: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{textosIndicador(elegido[0], lang).fuente}<span class="sr-only"> (fitxa berri batean irekitzen da)</span></a> · Espainiaren seriea: {elegido[0].anio_inicio}. urtetik aurrera
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Espainia, {elegido[0].anio_ref}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">duela hamar urte: {num(elegido[0].valor_espana_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">EB-27ko batez bestekoa</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">duela hamar urte: {num(elegido[0].valor_ue_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Espainiaren postua</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{elegido[0].puesto_ue ?? '–'}. <span class="text-sm font-normal">({elegido[0].n_ue}tik, EBn)</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].puesto}. ({elegido[0].n_paises}tik, Europako herrialdeen artean) · {elegido[0].sentido === 'neutro' ? 'handienetik txikienera' : 'onenetik txarrenera'}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Balio altuena' : 'Herrialde onena'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_pais}</p>
    </div>
</div>

### Mapa eta sailkapena

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Urtea" defaultValue="ref">
    <DropdownOption value="ref" valueLabel="Erreferentzia-urtea" />
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

**Sailkapena, {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(handienetik txikienera)' : '(onenetik txarrenera)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Bilatu herrialde bat" etiqueta="Europako herrialdeen sailkapena" alto={480} />

</div>
</Grid>

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Mapa eguneratzen…</p>
{/if}

### Bilakaera

Espainia, EB-27ko batez bestekoarekin eta zuk aukeratutako herrialdeekin alderatuta.

```sql paises_disponibles
SELECT DISTINCT cod_pais, pais FROM mother.internacional_europa
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado AND cod_pais <> 'ES'
ORDER BY pais
```

<Dropdown data={paises_disponibles} name=paises value=cod_pais label=pais title="Honekin alderatu" multiple=true defaultValue={['FR', 'DE', 'IT', 'PT']} />

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

## Oharrak

- **Herrialdeak**: Eurostatek taula bakoitzean argitaratzen dituenak: EBko 27ak, ia beti Norvegia, Suitza eta Islandia, eta askotan Erresuma Batua (2019 edo 2020 arte) eta sartzeko hautagaiak (Turkia, Serbia, Ipar Mazedonia, Montenegro, Albania...). EB-27ko batez bestekoa Eurostatena da (biztanleriaren edo BPGaren arabera haztatua, adierazlearen arabera), ez herrialdeen batez besteko soila.
- **Erreferentzia-urtea**: Espainiaren eta herrialde gehienen datua duen azkena. Herrialde batzuek lehenago argitaratzen dute, beraz urte berriagoak egon daitezke herrialde gutxiagorekin: aukeratu mapako zabalgarrian.
- **Postua**: 1 da onena (balio altuena gehiago hobea bada, baxuena gehiago okerragoa bada). Irakurketa argirik ez duten adierazleetan, 1 da balio altuena.
- **Erosteko ahalmenaren parekotasuna (EAP)**: Eurostatek euroak eta beste moneta batzuk unitate komun batera bihurtzen ditu, herrialdeen arteko prezio-aldeak kenduta, benetan zer eros daitekeen konparatzeko.
- Mapako koloreek herrialdeak bost taldetan banatzen dituzte, talde bakoitzean herrialde kopuru bera dagoela. Berdea hobea da eta gorria okerragoa; irakurketa argirik ez duten adierazleetan, zenbat eta urdin ilunagoa, orduan eta altuagoa.

<LastRefreshed prefix="Datuak eguneratuta" />
