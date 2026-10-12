---
title: España en el mundo
description: "Cómo se compara España con los demás países del mundo en más de 50 indicadores del Banco Mundial, el FMI, la ONU y otras fuentes: riqueza, empleo, población, salud, educación, desigualdad, seguridad, energía y clima. Mapa del mundo, clasificación y evolución de cada uno."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaMundo from '../../../../../../src/lib/components/MapaMundo.svelte';
    import TablaSeleccion from '../../../../../../src/lib/components/TablaSeleccion.svelte';
    import { IDIOMAS, idiomaDeRuta } from '../../../../../../src/lib/i18n.js';
    import { textosIndicador } from '../../../../../../src/lib/i18n_internacional.js';

    $: lang = idiomaDeRuta($page.url.pathname);
    $: locale = IDIOMAS[lang]?.locale ?? 'es-ES';
    const num = (v, d = 1, loc = 'es-ES') =>
        v == null ? '–' : Number(v).toLocaleString(loc, { minimumFractionDigits: d, maximumFractionDigits: d });
    // Frente a la media mundial según si más es mejor o peor
    const frente = (f) => {
        if (f?.valor_mundo == null || f?.valor_espana == null || f.sentido === 'neutro') return '';
        if (Math.abs(f.valor_espana - f.valor_mundo) < 1e-9) return '= igual';
        return (f.sentido === 'positivo') === (f.valor_espana > f.valor_mundo) ? '▲ mejor' : '▼ peor';
    };
    $: columnasIndicadores = [
        { id: 'nombre', titulo: 'Indicador', fmt: (v, f) => textosIndicador(f, lang).nombre },
        { id: 'apartado', titulo: 'Apartado' },
        { id: 'valor_espana', titulo: 'España', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_mundo', titulo: 'Mundo', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'valor_ue', titulo: 'UE', alinear: 'right', fmt: (v, f) => num(v, f.decimales, locale) },
        { id: 'puesto', titulo: 'Puesto mundial', alinear: 'right', fmt: (v, f) => (v == null ? '–' : `${v}.º de ${f.n_paises}`) },
        { id: 'frente_mundo', titulo: 'Frente al mundo', fmt: (v, f) => frente(f) },
        { id: 'anio_ref', titulo: 'Año', alinear: 'right' }
    ];
    $: columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right', fmt: (v) => v ?? '' },
        { id: 'pais', titulo: 'País', fmt: (v, f) => (f.cod_pais === 'ES' ? `▶ ${v}` : v) },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) },
        { id: 'valor_hace_10', titulo: 'Diez años antes', alinear: 'right', fmt: (v) => num(v, elegido[0]?.decimales, locale) }
    ];
</script>

# 🌍 España en el mundo

¿Dónde queda España entre los cerca de 200 países del mundo? Aquí se compara en
**{resumen.length} indicadores** del Banco Mundial, el FMI, la ONU, la OMS, Ember y el World Happiness
Report, que reúnen datos de casi todos los países con definiciones comunes. Las cifras van por
habitante, en porcentaje o en paridad de poder adquisitivo (descontando que la vida no cuesta lo mismo
en todos los países), nunca en totales que solo reflejen el tamaño de cada país. Para comparar con
más detalle con los vecinos europeos, con las estadísticas armonizadas de Eurostat, mira
[España en Europa](/varios/espana-en-europa).

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
        <p class="text-sm text-gray-600 dark:text-gray-400">indicadores en los que España está mejor que la media de la Unión Europea</p>
    </div>
    <div class="rounded-xl border border-red-200 dark:border-red-900 bg-red-50/60 dark:bg-red-950/30 p-4">
        <p class="text-3xl font-bold text-red-700 dark:text-red-400">{balance[0]?.peor ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">indicadores en los que España está peor que la media de la Unión Europea</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.cuarto_alto ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">en el 25 % de los mejores países del mundo</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-3xl font-bold text-gray-900 dark:text-white">{balance[0]?.mitad_baja ?? '–'}</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">en la mitad peor del mundo</p>
    </div>
</div>

Frente al mundo, España sale casi siempre por encima de la media, así que la comparación que más dice
es la de la Unión Europea. Mejor o peor solo se juzga en los {balance[0]?.con_sentido ?? '…'} indicadores en
los que más es claramente mejor (riqueza, esperanza de vida, empleo...) o claramente peor (paro,
mortalidad, emisiones...). En los demás (inflación, fecundidad, población urbana...) el puesto ordena
de mayor a menor, sin juzgar.

## Todos los indicadores

Busca un indicador o filtra por apartado y pulsa su fila para ver el mapa del mundo, la clasificación
de los países y la evolución de España frente al mundo, la UE y los países que elijas.

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

<TablaSeleccion data={indicadores} name=indicador value=indicador_id columnas={columnasIndicadores} placeholder="Buscar un indicador (riqueza, paro, vida, emisiones…)" etiqueta="Indicadores de España en el mundo" alto={360} />

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
{textosIndicador(elegido[0], lang).unidad} · Fuente: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{textosIndicador(elegido[0], lang).fuente}<span class="sr-only"> (se abre en una pestaña nueva)</span></a> · Serie de España desde {elegido[0].anio_inicio}
</p>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-4 not-prose">
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">España, {elegido[0].anio_ref}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_espana, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">hace diez años: {num(elegido[0].valor_espana_hace_10, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Mundo</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].valor_mundo, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">Unión Europea: {num(elegido[0].valor_ue, elegido[0].decimales, locale)}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">Puesto de España</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{elegido[0].puesto ?? '–'}.º <span class="text-sm font-normal">de {elegido[0].n_paises} países</span></p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].puesto_ue ?? '–'}.º de {elegido[0].n_ue} en la UE · {elegido[0].sentido === 'neutro' ? 'de mayor a menor' : 'de mejor a peor'}</p>
    </div>
    <div class="rounded-xl border border-gray-200 dark:border-gray-700 p-4">
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].sentido === 'neutro' ? 'Valor más alto' : 'Mejor país'}</p>
        <p class="text-2xl font-bold text-gray-900 dark:text-white">{num(elegido[0].mejor_valor, elegido[0].decimales, locale)}</p>
        <p class="text-xs text-gray-500 dark:text-gray-400">{elegido[0].mejor_pais}</p>
    </div>
</div>

### Mapa y clasificación

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Año" defaultValue="ref">
    <DropdownOption value="ref" valueLabel="Año de referencia" />
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

**Clasificación {datos[0].anio}** {elegido[0].sentido === 'neutro' ? '(de mayor a menor)' : '(de mejor a peor)'}

<TablaSeleccion data={datos} name=pais_marcado value=cod_pais columnas={columnasRanking} placeholder="Buscar país" etiqueta="Clasificación de países del mundo" alto={360} />

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Actualizando el mapa…</p>
{/if}

### Evolución

España frente al mundo, la Unión Europea y los países que elijas.

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

- **Países**: todos los que publica cada fuente, que no siempre son los mismos (el Banco Mundial cubre unos 215 países y territorios; la satisfacción con la vida, unos 140; la vivienda social de la OCDE, solo unos pocos países ricos). Los agregados Mundo y Unión Europea son los de cada fuente, ponderados por población o por PIB según el indicador, no la media simple de los países.
- **Año de referencia**: el último con dato de España y de la mayoría de los países. Las fuentes internacionales publican con uno o dos años de retraso, y algunos países antes que otros: los años más recientes, con menos países, se pueden elegir en el desplegable del mapa.
- **Puesto**: 1 es el mejor (el valor más alto si más es mejor, el más bajo si más es peor). En los indicadores sin lectura clara, 1 es el valor más alto. Entre países muy pequeños (Mónaco, Liechtenstein, islas del Caribe) los extremos son a veces poco representativos.
- **Paridad de poder adquisitivo (PPA)**: convierte cada moneda a dólares internacionales que descuentan las diferencias de precios entre países, para comparar lo que de verdad se puede comprar. El PIB por habitante va además en dólares constantes de 2021, descontada la inflación.
- **Fronteras**: las de GISCO, el servicio cartográfico de Eurostat, con la posición de la UE (el Sáhara Occidental, aparte de Marruecos).
- Los colores del mapa reparten los países en cinco grupos con el mismo número de países cada uno. Verde es mejor y rojo peor; en los indicadores sin lectura clara, azul más oscuro es más alto.

<LastRefreshed prefix="Datos actualizados" />
