---
title: España no mundo
description: "Como se compara España cos demais países do mundo en máis de 50 indicadores do Banco Mundial, o FMI, a ONU e outras fontes: riqueza, emprego, poboación, saúde, educación, desigualdade, seguridade, enerxía e clima. Mapa do mundo, clasificación e evolución de cada un."
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
    // Fronte á media mundial segundo se máis é mellor ou peor
    const frente = (f) => {
        if (f?.valor_mundo == null || f?.valor_espana == null || f.sentido === 'neutro') return '';
        if (Math.abs(f.valor_espana - f.valor_mundo) < 1e-9) return '= igual';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_mundo) ? '▲ mellor' : '▼ peor';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicador', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Apartado' },
        { id: 'valor_espana', titulo: 'España', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_mundo', titulo: 'Mundo', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'UE', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto', titulo: 'Posto mundial', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}.º de ${f.n_paises}`) },
        { id: 'frente_mundo', titulo: 'Fronte ao mundo', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Ano', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'País', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Dez anos antes', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🌍 España no mundo

Onde queda España entre os preto de 200 países do mundo? Aquí compárase en
**{resumen.length} indicadores** do Banco Mundial, o FMI, a ONU, a OMS, Ember e o World Happiness
Report, que reúnen datos de case todos os países con definicións comúns. As cifras van por
habitante, en porcentaxe ou en paridade de poder adquisitivo (descontando que a vida non custa o mesmo
en todos os países), nunca en totais que só reflictan o tamaño de cada país. Para comparar con
máis detalle cos veciños europeos, coas estatísticas harmonizadas de Eurostat, mira
[España en Europa](/gl/varios/espana-en-europa).

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
        <p class="text-sm text-gray-600 dark:text-gray-400">indicadores nos que España está mellor que a media da Unión Europea</p>
    </div>
    <div class="rounded-xl border border-red-200 dark:border-red-900 bg-red-50/60 dark:bg-red-950/30 p-4">
        <p class="text-3xl font-bold text-red-700 dark:text-red-400">{balance[0]?.peor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">indicadores nos que España está peor que a media da Unión Europea</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.cuarto_alto ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">no 25 % dos mellores países do mundo</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.mitad_baja ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">na metade peor do mundo</p>
    </div>
</div>

Fronte ao mundo, España sae case sempre por riba da media, así que a comparación que máis di
é a da Unión Europea. Mellor ou peor só se xulga nos {balance[0]?.con_sentido ?? '…'} indicadores nos
que máis é claramente mellor (riqueza, esperanza de vida, emprego...) ou claramente peor (paro,
mortalidade, emisións...). Nos demais (inflación, fecundidade, poboación urbana...) o posto ordena
de maior a menor, sen xulgar.

## Todos os indicadores

Busca un indicador ou filtra por apartado e preme a súa fila para ver o mapa do mundo, a clasificación
dos países e a evolución de España fronte ao mundo, a UE e os países que escollas.

```sql apartados
SELECT apartado, min(orden) AS o FROM ${resumen} GROUP BY apartado ORDER BY o
```

<ButtonGroup data={apartados} name=apartado value=apartado title="Apartado">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
</ButtonGroup>

```sql indicadores
SELECT * FROM ${resumen}
WHERE '${inputs.apartado}' = 'Todos' OR apartado = '${inputs.apartado}'
ORDER BY orden
```

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Buscar un indicador (riqueza, paro, vida, emisións…)" etiqueta="Indicadores de España no mundo" alto={360} />

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
{textosIndicador(elegido[0], lang).unidad} · Fonte: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{textosIndicador(elegido[0], lang).fuente}<span class="sr-only"> (ábrese nunha pestana nova)</span></a> · Serie de España desde {elegido[0].anio_inicio}
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">España, {elegido[0].anio_ref}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">hai dez anos: {num(elegido[0].valor_espana_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Mundo</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_mundo, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">Unión Europea: {num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Posto de España</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{elegido[0].puesto ?? '–'}.º <span class="text-sm font-normal">de {elegido[0].n_paises} países</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].puesto_ue ?? '–'}.º de {elegido[0].n_ue} na UE · {elegido[0].sentido === 'neutro' ? 'de maior a menor' : 'de mellor a peor'}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor máis alto' : 'Mellor país'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_pais}</p>
    </div>
</div>

### Mapa e clasificación

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Ano" defaultValue="ref">
    <DropdownOption value="ref" valueLabel="Ano de referencia" />
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

**Clasificación {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(de maior a menor)' : '(de mellor a peor)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Buscar país" etiqueta="Clasificación de países do mundo" alto={360} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Actualizando o mapa…</p>
{/if}

### Evolución

España fronte ao mundo, a Unión Europea e os países que escollas.

```sql paises_disponibles
SELECT DISTINCT cod_pais, pais FROM mother.internacional_mundo
WHERE indicador_id = '${inputs.indicador}' AND NOT es_agregado AND cod_pais <> 'ES'
ORDER BY pais
```

<Dropdown data={paises_disponibles} name=paises value=cod_pais label=pais title="Comparar con" multiple=true defaultValue={['FR', 'DE', 'IT', 'US', 'JP', 'MA']} />

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

## Notas

- **Países**: todos os que publica cada fonte, que non sempre son os mesmos (o Banco Mundial cobre uns 215 países e territorios; a satisfacción coa vida, uns 140; a vivenda social da OCDE, só uns poucos países ricos). Os agregados Mundo e Unión Europea son os de cada fonte, ponderados por poboación ou por PIB segundo o indicador, non a media simple dos países.
- **Ano de referencia**: o último con dato de España e da maioría dos países. As fontes internacionais publican cun ou dous anos de atraso, e algúns países antes que outros: os anos máis recentes, con menos países, pódense escoller no despregable do mapa.
- **Posto**: 1 é o mellor (o valor máis alto se máis é mellor, o máis baixo se máis é peor). Nos indicadores sen lectura clara, 1 é o valor máis alto. Entre países moi pequenos (Mónaco, Liechtenstein, illas do Caribe) os extremos son ás veces pouco representativos.
- **Paridade de poder adquisitivo (PPA)**: converte cada moeda a dólares internacionais que descontan as diferenzas de prezos entre países, para comparar o que de verdade se pode mercar. O PIB por habitante vai ademais en dólares constantes de 2021, descontada a inflación.
- **Fronteiras**: as de GISCO, o servizo cartográfico de Eurostat, coa posición da UE (o Sáhara Occidental, á parte de Marrocos).
- As cores do mapa reparten os países en cinco grupos co mesmo número de países cada un. Verde é mellor e vermello peor; nos indicadores sen lectura clara, azul máis escuro é máis alto.

<LastRefreshed prefix="Datos actualizados" />
