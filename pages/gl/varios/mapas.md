---
title: Explorador de mapas
description: "Todos os datos de SpainFacts que teñen repartición xeográfica, por comunidade autónoma ou por provincia. Escolle un indicador na táboa e debúxase no mapa."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 47d78cea0317
---

<script>
    import TablaSeleccion from '../../../../../../../src/lib/components/TablaSeleccion.svelte';

    const numero = (v) =>
        v == null ? String() : Number(v).toLocaleString('gl-ES', { maximumFractionDigits: Math.abs(v) >= 100 ? 0 : 1 });
    const columnasTabla = [
        { id: 'nombre', titulo: 'Indicador' },
        { id: 'tema', titulo: 'Apartado' },
        { id: 'nivel', titulo: 'Mapa' },
        { id: 'ultimo_anio', titulo: 'Último ano', alinear: 'right' }
    ];
    const columnasRanking = [
        { id: 'posicion', titulo: '#', alinear: 'right' },
        { id: 'territorio', titulo: 'Territorio' },
        { id: 'valor', titulo: 'Valor', alinear: 'right', fmt: numero }
    ];
    // Colores: verde = mejor, rojo = peor; los neutros en azul
    const paletas = {
        positivo: ['#b91c1c', '#fef3c7', '#15803d'],
        negativo: ['#15803d', '#fef3c7', '#b91c1c'],
        neutro: ['#dbeafe', '#60a5fa', '#1e3a8a']
    };
</script>

# 🧭 Explorador de mapas

Aquí están todos os datos da web que teñen repartición xeográfica. Busca ou filtra un indicador,
preme a súa fila e debúxase no mapa, por comunidade autónoma ou por provincia. Os importes van por
habitante e en euros reais, como no resto de SpainFacts.

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
    '/gl' || any_value(pagina) AS pagina,
    any_value(nota) AS nota,
    min(anio) AS primer_anio,
    max(anio) AS ultimo_anio
FROM mother.mapas_indicadores
GROUP BY indicador_id
```

```sql temas
SELECT tema, count(*) AS n FROM ${catalogo_todo} GROUP BY tema ORDER BY n DESC
```

<ButtonGroup data={temas} name=tema value=tema title="Apartado">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
</ButtonGroup>

<ButtonGroup name=nivel title="Mapa">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
    <ButtonGroupItem valueLabel="Comunidades" value="Comunidad" />
    <ButtonGroupItem valueLabel="Provincias" value="Provincia" />
</ButtonGroup>

```sql catalogo
SELECT *
FROM ${catalogo_todo}
WHERE ('${inputs.tema}' = 'Todos' OR tema = '${inputs.tema}')
  AND ('${inputs.nivel}' = 'Todos' OR nivel = '${inputs.nivel}')
ORDER BY tema, nombre, nivel
```

<TablaSeleccion data={catalogo} name=indicador value=indicador_id columnas={columnasTabla} placeholder="Buscar un indicador (paro, renda, vivenda…)" etiqueta="Indicadores con mapa" alto={300} />

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

<Dropdown data={anios} name=anio value=anio order="anio desc" title="Ano" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Último disponible" />
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
{elegido[0].unidad} · {datos[0]?.anio} · {elegido[0].nivel === 'Provincia' ? 'por provincia' : 'por comunidade autónoma'} · Fonte: <a href={elegido[0].url_fuente} target="_blank" rel="noopener noreferrer">{elegido[0].fuente}<span class="sr-only"> (ábrese nunha nova lapela)</span></a> · <a href={elegido[0].pagina}>Ver en {elegido[0].tema}</a>{#if elegido[0].nota}&nbsp;· {elegido[0].nota}{/if}
</p>

<Grid cols=3>
<div class="col-span-2">
<!-- Un mapa por nivel: AreaMap no admite cambiar de geojson sin recrearse -->
{#if elegido[0].nivel === 'Provincia'}
<AreaMap
    data={datos}
    areaCol=cod
    geoJsonUrl="/geo/provincias.geojson"
    geoId=cod_prov
    value=valor
    valueFmt='#,##0.0'
    tooltip={[
        { id: 'territorio', showColumnName: false, valueClass: 'font-bold' },
        { id: 'valor', title: elegido[0].unidad, fmt: '#,##0.0' },
        { id: 'posicion', title: 'Posto' }
    ]}
    colorPalette={paletas[elegido[0].sentido] ?? paletas.neutro}
    height=520
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
/>
{:else}
<AreaMap
    data={datos}
    areaCol=cod
    geoJsonUrl="/geo/ccaa.geojson"
    geoId=cod_ccaa
    value=valor
    valueFmt='#,##0.0'
    tooltip={[
        { id: 'territorio', showColumnName: false, valueClass: 'font-bold' },
        { id: 'valor', title: elegido[0].unidad, fmt: '#,##0.0' },
        { id: 'posicion', title: 'Posto' }
    ]}
    colorPalette={paletas[elegido[0].sentido] ?? paletas.neutro}
    height=520
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
/>
{/if}
</div>
<div>

**Clasificación** {elegido[0].sentido === 'neutro' ? '(de maior a menor)' : '(de mellor a peor)'}

<TablaSeleccion data={datos} name=territorio_marcado value=cod columnas={columnasRanking} placeholder="Buscar territorio" etiqueta="Clasificación de territorios" alto={440} />

</div>
</Grid>

{/if}

<LastRefreshed prefix="Datos actualizados" />
