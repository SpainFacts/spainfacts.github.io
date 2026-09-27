---
title: Territorios
description: "España por comunidades autónomas y provincias: población, cuentas públicas y deuda de cada administración."
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT * FROM mother.territorios WHERE nivel = 'pais'
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

# 🗺️ España, territorio a territorio

España es un Estado descentralizado: las **comunidades autónomas** gestionan la sanidad, la educación y buena parte de los servicios sociales, y los **ayuntamientos** y **diputaciones** se ocupan de los servicios de proximidad. Elige una comunidad en el mapa para ver su población, sus cuentas y su deuda, y baja desde ahí a cada provincia.

<Grid cols=3>
    <KpiCard
        title="Población de España"
        value={espana[0]?.poblacion_ultima}
        formattedValue={formatCompact(espana[0]?.poblacion_ultima, 2)}
        unit="hab."
        period="1 de enero de {espana[0]?.anio_poblacion} · Padrón (INE)"
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

<AreaMap
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
    SELECT cod_ccaa, deuda_eur, deuda_pct_pib
    FROM mother.ccaa_deuda
    WHERE fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
)
SELECT
    c.nombre AS comunidad,
    c.ruta,
    c.poblacion,
    r.gastos_no_financieros / p.poblacion AS gasto_hab,
    d.deuda_eur / c.poblacion AS deuda_hab,
    d.deuda_pct_pib / 100 AS deuda_pct_pib
FROM ${ccaa} c
LEFT JOIN mother.ccaa_cuentas_resumen r
  ON r.cod_ccaa = c.cod AND r.anio = (SELECT anio FROM anio_cuentas)
LEFT JOIN mother.poblacion_territorios p
  ON p.nivel = 'ccaa' AND p.cod = c.cod AND p.anio = r.anio AND p.sexo = 'Total'
LEFT JOIN deuda d ON d.cod_ccaa = c.cod
ORDER BY c.poblacion DESC
```

## Comparativa entre comunidades

<DataTable data={comparativa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=poblacion title="Población" fmt=num0 />
    <Column id=gasto_hab title="Gasto no financiero (€/hab.)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=deuda_hab title="Deuda (€/hab.)" fmt=num0 />
    <Column id=deuda_pct_pib title="Deuda (% PIB)" fmt=pct1 contentType=bar barColor="#bfdbfe" />
</DataTable>

<p class="text-xs text-gray-500">Gasto: última liquidación de Hacienda (capítulos 1 a 7). Deuda: último trimestre del Banco de España. Ceuta y Melilla no tienen deuda autonómica propia en el Protocolo de Déficit Excesivo.</p>

## Comunidades autónomas

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 not-prose">
{#each ccaa as c}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
        <a href={c.ruta} class="text-base font-bold text-gray-900 dark:text-white hover:underline no-underline">{c.nombre}</a>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1 mb-2">{formatNumber(c.poblacion, 0)} habitantes · {#if c.crecimiento_10_anios > 0}+{/if}{formatNumber(c.crecimiento_10_anios, 1)} % en 10 años</p>
        <p class="text-xs mb-0">
        {#each provincias.filter(p => p.cod_ccaa === c.cod) as p, i}
            <a href={p.ruta} class="text-blue-600 dark:text-blue-400 hover:underline">{p.nombre}</a>{#if i < provincias.filter(x => x.cod_ccaa === c.cod).length - 1} · {/if}
        {/each}
        </p>
    </div>
{/each}
</div>

---

## Fuentes oficiales

- **[INE – Cifras oficiales de población de los municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**: población a 1 de enero, agregada por provincia y comunidad.
- **[INE – Relación de municipios y códigos](https://www.ine.es/daco/daco42/codmun/codmun00i.htm)**: correspondencia municipio → provincia → comunidad.
- **[Instituto Geográfico Nacional (vía es-atlas)](https://github.com/martgnz/es-atlas)**: límites de comunidades, provincias y municipios (CC BY 4.0).

<LastRefreshed prefix="Datos actualizados" />
