---
title: Territorios
description: "España por comunidades autónomas y provincias: población, cuentas públicas y deuda de cada administración."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT * FROM mother.territorios WHERE nivel = 'pais'
```

```sql espana_serie
SELECT anio, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'pais' AND sexo = 'Total'
ORDER BY anio
```

```sql ccaa
SELECT
    t.cod,
    t.nombre,
    t.slug,
    t.ruta,
    t.poblacion_ultima AS poblacion,
    t.anio_poblacion,
    p10.poblacion AS poblacion_hace_10,
    100.0 * (t.poblacion_ultima - p10.poblacion) / p10.poblacion AS crecimiento_10_anios
FROM mother.territorios t
LEFT JOIN mother.poblacion_territorios p10
  ON p10.nivel = 'ccaa' AND p10.cod = t.cod AND p10.sexo = 'Total' AND p10.anio = t.anio_poblacion - 10
WHERE t.nivel = 'ccaa'
ORDER BY t.poblacion_ultima DESC
```

```sql provincias
SELECT cod, cod_ccaa, nombre, ruta, poblacion_ultima AS poblacion
FROM mother.territorios
WHERE nivel = 'provincia'
ORDER BY nombre
```

```sql base
SELECT max(anio_base) AS anio_base FROM mother.deflactor
```

```sql anio_gasto
SELECT max(anio) AS anio FROM mother.ccaa_cuentas_resumen WHERE cod_ccaa <= '17'
```

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Territorios</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/><line x1="9" y1="3" x2="9" y2="18"/><line x1="15" y1="6" x2="15" y2="21"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">España, territorio a territorio</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                España es un Estado descentralizado: las <strong>comunidades autónomas</strong> gestionan la sanidad, la educación y buena parte de los servicios sociales, y los <strong>ayuntamientos</strong> y <strong>diputaciones</strong> se ocupan de los servicios de proximidad. Elige una comunidad en el mapa para ver su población, sus cuentas y su deuda, y baja desde ahí a cada provincia.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">19 CCAA y Ciudades Autónomas</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">52 Provincias · +8.100 Municipios</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">INE · Hacienda · Banco de España</span>
    </div>
</div>

<Grid cols=3>
    <KpiCard
        title="Población de España"
        value={espana[0]?.poblacion_ultima}
        formattedValue={formatCompact(espana[0]?.poblacion_ultima, 2)}
        unit="hab."
        period="1 de enero de {espana[0]?.anio_poblacion} · Padrón (INE)"
        sparklineData={espana_serie}
    />
    <KpiCard
        title="Comunidades y ciudades autónomas"
        value={ccaa.length}
        formattedValue="{ccaa.length}"
        period="17 comunidades + Ceuta y Melilla"
    />
    <KpiCard
        title="Provincias"
        value={provincias.length}
        formattedValue="{provincias.length}"
        period="con más de 8.100 municipios"
    />
</Grid>

## Mapa de comunidades autónomas

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="poblacion"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#dbeafe', '#60a5fa', '#1d4ed8']}
    height={480}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Población', fmt: 'num0'},
        {id: 'crecimiento_10_anios', title: 'Crecimiento en 10 años (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Pulsa en una comunidad para abrir su ficha.</p>

```sql comparativa
WITH anio_cuentas AS (SELECT max(anio) AS anio FROM mother.ccaa_cuentas_resumen WHERE cod_ccaa <= '17'),
deuda AS (
    SELECT cod_ccaa, anio, deuda_eur_hab_real, deuda_pct_pib
    FROM mother.ccaa_deuda
    WHERE fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
)
-- Euros por habitante y constantes (euros del último año completo)
SELECT
    c.nombre AS comunidad,
    c.ruta,
    c.poblacion,
    r.gastos_nf_eur_hab_real AS gasto_hab,
    d.deuda_eur_hab_real AS deuda_hab,
    d.deuda_pct_pib / 100 AS deuda_pct_pib
FROM ${ccaa} c
LEFT JOIN mother.ccaa_cuentas_resumen r
  ON r.cod_ccaa = c.cod AND r.anio = (SELECT anio FROM anio_cuentas)
LEFT JOIN deuda d ON d.cod_ccaa = c.cod
ORDER BY c.poblacion DESC
```

## Comparativa entre comunidades

<DataTable data={comparativa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=poblacion title="Población" fmt=num0 />
    <Column id=gasto_hab title="Gasto no financiero (€/hab., euros de {base[0]?.anio_base})" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=deuda_hab title="Deuda (€/hab., euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=deuda_pct_pib title="Deuda (% PIB)" fmt=pct1 contentType=bar barColor="#bfdbfe" />
</DataTable>

<p class="text-xs text-gray-500">Importes por habitante y descontada la inflación (euros de {base[0]?.anio_base}, con el IPC medio anual). Gasto: última liquidación de Hacienda ({anio_gasto[0]?.anio}, capítulos 1 a 7). Deuda: último trimestre del Banco de España. Ceuta y Melilla no tienen deuda autonómica propia en el Protocolo de Déficit Excesivo.</p>

## Explora en detalle

<div class="not-prose grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
    <a href="/territorios/municipios" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Buscador de municipios</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Busca tu municipio para consultar su población, las cuentas del ayuntamiento (ingresos, gastos y deuda por habitante) y quién gobierna.</p>
        <span class="sf-card-cta">Buscar municipio →</span>
    </a>
    <a href="/territorios/suelos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Suelos agrarios</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Composición del suelo en cada territorio: suelos arcillosos, francos o arenosos, nivel de pH y materia orgánica.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>

## Comunidades autónomas

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 not-prose">
{#each ccaa as c}
    <div class="rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4">
        <a href={c.ruta} class="text-base font-bold text-slate-900 dark:text-white hover:underline no-underline">{c.nombre}</a>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-2 tabular-nums">{formatNumber(c.poblacion, 0)} habitantes · {#if c.crecimiento_10_anios > 0}+{/if}{formatNumber(c.crecimiento_10_anios, 1)} % en 10 años</p>
        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
        {#each provincias.filter(p => p.cod_ccaa === c.cod) as p}
            <a href={p.ruta} class="font-medium hover:underline whitespace-nowrap" style="color: var(--sf-accent)">{p.nombre}</a>
        {/each}
        </div>
    </div>
{/each}
</div>

<div class="sf-sources-footer">

## Fuentes oficiales

- **[INE – Cifras oficiales de población de los municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**: población a 1 de enero, agregada por provincia y comunidad.
- **[INE – Relación de municipios y códigos](https://www.ine.es/daco/daco42/codmun/codmun00i.htm)**: correspondencia municipio → provincia → comunidad.
- **[Instituto Geográfico Nacional (vía es-atlas)](https://github.com/martgnz/es-atlas)**: límites de comunidades, provincias y municipios (CC BY 4.0).

<LastRefreshed prefix="Datos actualizados" />

</div>
