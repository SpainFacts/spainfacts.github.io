---
title: Map explorer
description: "All SpainFacts data with a geographical breakdown, by autonomous community, province, municipality or neighbourhood (census section). Pick an indicator in the table and it is drawn on the map."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: fd7ff4cd1a09
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import TablaSeleccion from '../../../../../../../src/lib/components/TablaSeleccion.svelte';
    import MapaExplorador from '../../../../../../../src/lib/components/MapaExplorador.svelte';

    const numero = (v) =>
        v == null ? String() : Number(v).toLocaleString('en-GB', { maximumFractionDigits: Math.abs(v) >= 100 ? 0 : 1 });
    const columnasTabla = [
        { id: 'nombre', titulo: 'Indicator' },
        { id: 'tema', titulo: 'Section' },
        { id: 'nivel', titulo: 'Map' },
        { id: 'ultimo_anio', titulo: 'Latest year', alinear: 'right' }
    ];
    const columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right' },
        { id: 'territorio', titulo: 'Territory' },
        { id: 'valor', titulo: 'Value', alinear: 'right', fmt: numero }
    ];
    // Colores: verde = mejor, rojo = peor; los neutros en azul
    const paletas = {
        positivo: ['#b91c1c', '#fef3c7', '#15803d'],
        negativo: ['#15803d', '#fef3c7', '#b91c1c'],
        neutro: ['#dbeafe', '#60a5fa', '#1e3a8a']
    };
    // Municipios y barrios: enteros para habitantes y euros, un decimal para el resto
    const formato = (unidad) => (/^(€|habitantes)/.test(unidad ?? '') ? '#,##0' : '#,##0.0');
    const NIVEL_TEXTO = { Provincia: 'by province', Comunidad: 'by autonomous community', Municipio: 'by municipality', 'Sección censal': 'by census section (neighbourhood)' };
</script>

# 🧭 Map explorer

Here is every dataset on the site that has a geographical breakdown. Search for or filter an indicator,
click its row and it is drawn on the map: by autonomous community, province, municipality or
neighbourhood (census section). Monetary amounts are per inhabitant and in real euros, as on the rest of
SpainFacts. The page link keeps the indicator, the year and the map view, so you can share it as it is.

```sql catalogo_todo
SELECT
    indicador_id,
    any_value(nombre) AS nombre,
    any_value(tema) AS tema,
    any_value(nivel) AS nivel,
    any_value(unidad) AS unidad,
    any_value(sentido) AS sentido,
    any_value(fuente) AS fuente,
    any_value(url_fuente) AS url_fuente,
    '/en' || any_value(pagina) AS pagina,
    any_value(nota) AS nota,
    min(anio) AS primer_anio,
    max(anio) AS ultimo_anio
FROM (
    SELECT indicador_id, nombre, tema, nivel, unidad, sentido, fuente, url_fuente, pagina, nota, anio FROM mother.mapas_indicadores
    UNION ALL
    SELECT indicador_id, nombre, tema, nivel, unidad, sentido, fuente, url_fuente, pagina, nota, anio FROM mother.mapas_municipios
    UNION ALL
    SELECT indicador_id, nombre, tema, nivel, unidad, sentido, fuente, url_fuente, pagina, nota, anio FROM mother.mapas_secciones
)
GROUP BY indicador_id
```

```sql temas
SELECT tema, count(*) AS n FROM ${catalogo_todo} GROUP BY tema ORDER BY n DESC
```

<ButtonGroup data={temas} name=tema value=tema title="Section">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
</ButtonGroup>

<ButtonGroup name=nivel title="Map">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
    <ButtonGroupItem valueLabel="Regions" value="Comunidad" />
    <ButtonGroupItem valueLabel="Provinces" value="Provincia" />
    <ButtonGroupItem valueLabel="Municipalities" value="Municipio" />
    <ButtonGroupItem valueLabel="Neighbourhoods" value="Sección censal" />
</ButtonGroup>

```sql catalogo
SELECT *
FROM ${catalogo_todo}
WHERE ('${inputs.tema}' = 'Todos' OR tema = '${inputs.tema}')
  AND ('${inputs.nivel}' = 'Todos' OR nivel = '${inputs.nivel}')
ORDER BY tema, nombre, nivel
```

<TablaSeleccion data={catalogo} name=indicador value=indicador_id columnas={columnasTabla} placeholder="Search for an indicator (unemployment, income, housing…)" etiqueta="Indicators with a map" alto={300} parametro="i" />

```sql elegido
SELECT * FROM ${catalogo_todo} WHERE indicador_id = '${inputs.indicador}'
```

```sql anios
SELECT DISTINCT indicador_id, anio FROM mother.mapas_indicadores
WHERE indicador_id = '${inputs.indicador}'
ORDER BY anio DESC
```

```sql datos_municipios
SELECT indicador_id, cod, territorio, anio, valor
FROM mother.mapas_municipios
WHERE indicador_id = '${inputs.indicador}'
```

```sql datos_secciones
SELECT indicador_id, cod, territorio, anio, valor, geo_anio
FROM mother.mapas_secciones
WHERE indicador_id = '${inputs.indicador}'
```

```sql datos_secciones_municipio
-- al alejarse del mapa de barrios: el mismo dato por municipio (si existe) y del mismo año
SELECT cod, territorio, anio, valor
FROM mother.mapas_municipios
WHERE indicador_id = (SELECT any_value(indicador_municipio) FROM mother.mapas_secciones WHERE indicador_id = '${inputs.indicador}')
  AND anio = (SELECT max(anio) FROM mother.mapas_secciones WHERE indicador_id = '${inputs.indicador}')
```

{#if elegido.length}

## {elegido[0].nombre}

{#if elegido[0].nivel === 'Municipio' || elegido[0].nivel === 'Sección censal'}

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · {elegido[0].primer_anio === elegido[0].ultimo_anio ? elegido[0].ultimo_anio : elegido[0].primer_anio + '-' + elegido[0].ultimo_anio} · {NIVEL_TEXTO[elegido[0].nivel]} · Source: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (opens in a new tab)</span></a> · <a href={elegido[0].pagina}>View in {elegido[0].tema}</a>{#if elegido[0].nota}&nbsp;· {elegido[0].nota}{/if}
</p>

{#if elegido[0].nivel === 'Municipio' && datos_municipios[0]?.indicador_id === elegido[0].indicador_id}
{#key elegido[0].nivel}
<MapaExplorador
    data={datos_municipios}
    nivel="municipio"
    valueFmt={formato(elegido[0].unidad)}
    unidad={elegido[0].unidad}
    sentido={elegido[0].sentido}
    colorPalette={paletas[elegido[0].sentido] ?? paletas.neutro}
/>
{/key}
{:else if elegido[0].nivel === 'Sección censal' && datos_secciones[0]?.indicador_id === elegido[0].indicador_id}
{#key elegido[0].nivel}
<MapaExplorador
    data={datos_secciones}
    nivel="seccion"
    datosMunicipio={datos_secciones_municipio}
    valueFmt={formato(elegido[0].unidad)}
    unidad={elegido[0].unidad}
    sentido={elegido[0].sentido}
    colorPalette={paletas[elegido[0].sentido] ?? paletas.neutro}
/>
{/key}
{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Updating the map…</p>
{/if}

<p class="text-xs text-gray-500 dark:text-gray-400">Hover over a territory to see its value and rank. With «Current view», the colour scale adapts to the part of the map you are looking at. The address search uses Nominatim, from OpenStreetMap: whatever you type is sent to its server.</p>

{:else}

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Year" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Latest available" />
</Dropdown>

```sql datos
WITH disponibles AS (
    SELECT * FROM mother.mapas_indicadores WHERE indicador_id = '${inputs.indicador}'
),
anio_elegido AS (
    -- el año del desplegable si existe para este indicador; si no ('Último disponible'), el último
    SELECT coalesce(
        max(anio) FILTER (WHERE anio = try_cast('${inputs.anio.value}' AS INTEGER)),
        max(anio)
    ) AS anio
    FROM disponibles
)
SELECT
    d.indicador_id,
    d.cod,
    d.territorio,
    d.anio,
    d.valor,
    d.unidad,
    CAST(row_number() OVER (
        ORDER BY CASE WHEN d.sentido = 'negativo' THEN d.valor ELSE -d.valor END
    ) AS INTEGER) AS posicion
FROM disponibles d
JOIN anio_elegido a USING (anio)
ORDER BY posicion
```

{#if anios[0]?.indicador_id === elegido[0].indicador_id && datos.length && datos[0]?.indicador_id === elegido[0].indicador_id && datos[0]?.anio === (inputs.anio.value && anios.some(a => String(a.anio) === String(inputs.anio.value)) ? Number(inputs.anio.value) : anios[0]?.anio)}
<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · {datos[0]?.anio} · {NIVEL_TEXTO[elegido[0].nivel]} · Source: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (opens in a new tab)</span></a> · <a href={elegido[0].pagina}>View in {elegido[0].tema}</a>{#if elegido[0].nota}&nbsp;· {elegido[0].nota}{/if}
</p>

<Grid cols=3>
<div class="col-span-2">
<!-- Un mapa por nivel: AreaMap no admite cambiar de geojson sin recrearse -->
{#if elegido[0].nivel === 'Provincia'}
<MapaEspana
    data={datos}
    areaCol=cod
    geoJsonUrl="/geo/provincias.geojson"
    geoId=cod_prov
    value=valor
    valueFmt='#,##0.0'
    tooltip={[
        { id: 'territorio', showColumnName: false, valueClass: 'font-bold' },
        { id: 'valor', title: elegido[0].unidad, fmt: '#,##0.0' },
        { id: 'posicion', title: 'Rank' }
    ]}
    colorPalette={paletas[elegido[0].sentido] ?? paletas.neutro}
    height=520
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
/>
{:else}
<MapaEspana
    data={datos}
    areaCol=cod
    geoJsonUrl="/geo/ccaa.geojson"
    geoId=cod_ccaa
    value=valor
    valueFmt='#,##0.0'
    tooltip={[
        { id: 'territorio', showColumnName: false, valueClass: 'font-bold' },
        { id: 'valor', title: elegido[0].unidad, fmt: '#,##0.0' },
        { id: 'posicion', title: 'Rank' }
    ]}
    colorPalette={paletas[elegido[0].sentido] ?? paletas.neutro}
    height=520
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
/>
{/if}
</div>
<div>

**Ranking** {elegido[0].sentido === 'neutro' ? '(highest to lowest)' : '(best to worst)'}

<TablaSeleccion data={datos} name=territorio_marcado value=cod columnas={columnasRanking} placeholder="Search for a territory" etiqueta="Territory ranking" alto={440} />

</div>
</Grid>

{:else}
<p role="status" class="my-6 text-sm text-gray-600 dark:text-gray-400">Updating the map…</p>
{/if}

{/if}

{/if}

<LastRefreshed prefix="Data updated" />
