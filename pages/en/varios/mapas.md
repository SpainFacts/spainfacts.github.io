---
title: Map explorer
description: "All SpainFacts data with a geographical breakdown, by autonomous community or by province. Pick an indicator in the table and it is drawn on the map."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: ffea07200ad9
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import TablaSeleccion from '../../../../../../../src/lib/components/TablaSeleccion.svelte';

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
</script>

# 🧭 Map explorer

Here is every dataset on the site that has a geographical breakdown. Search for or filter an indicator,
click its row and it is drawn on the map, by autonomous community or by province. Monetary amounts are per
inhabitant and in real euros, as on the rest of SpainFacts.

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
FROM mother.mapas_indicadores
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
</ButtonGroup>

```sql catalogo
SELECT *
FROM ${catalogo_todo}
WHERE ('${inputs.tema}' = 'Todos' OR tema = '${inputs.tema}')
  AND ('${inputs.nivel}' = 'Todos' OR nivel = '${inputs.nivel}')
ORDER BY tema, nombre, nivel
```

<TablaSeleccion data={catalogo} name=indicador value=indicador_id columnas={columnasTabla} placeholder="Search for an indicator (unemployment, income, housing…)" etiqueta="Indicators with a map" alto={300} />

```sql elegido
SELECT * FROM ${catalogo_todo} WHERE indicador_id = '${inputs.indicador}'
```

```sql anios
SELECT DISTINCT anio FROM mother.mapas_indicadores
WHERE indicador_id = '${inputs.indicador}'
ORDER BY anio DESC
```

{#if elegido.length}

## {elegido[0].nombre}

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

<p class="text-sm text-gray-600 dark:text-gray-400">
{elegido[0].unidad} · {datos[0]?.anio} · {elegido[0].nivel === 'Provincia' ? 'by province' : 'by autonomous community'} · Source: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (opens in a new tab)</span></a> · <a href={elegido[0].pagina}>View in {elegido[0].tema}</a>{#if elegido[0].nota}&nbsp;· {elegido[0].nota}{/if}
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

{/if}

<LastRefreshed prefix="Data updated" />
