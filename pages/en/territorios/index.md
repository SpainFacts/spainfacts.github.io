---
title: Regions
description: "Spain by autonomous community and province: population, public accounts and debt of each administration."
i18n_origen: 6facd905aab0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
    '/en' || t.ruta AS ruta,
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
SELECT cod, cod_ccaa, nombre, '/en' || ruta AS ruta, poblacion_ultima AS poblacion
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

# 🗺️ Spain, region by region

Spain is a decentralised state: the **autonomous communities** run healthcare, education and much of social services, while **town councils** and **provincial councils** (diputaciones) handle local services. Choose a community on the map to see its population, accounts and debt, and drill down from there to each province.

<Grid cols=3>
    <KpiCard
        title="Population of Spain"
        value={espana[0]?.poblacion_ultima}
        formattedValue={formatCompact(espana[0]?.poblacion_ultima, 2)}
        unit="people"
        period="1 January {espana[0]?.anio_poblacion} · Municipal Register (INE)"
        sparklineData={espana_serie}
    />
    <KpiCard
        title="Autonomous communities and cities"
        value={ccaa.length}
        formattedValue="{ccaa.length}"
        period="17 communities + Ceuta and Melilla"
    />
    <KpiCard
        title="Provinces"
        value={provincias.length}
        formattedValue="{provincias.length}"
        period="with more than 8,100 municipalities"
    />
</Grid>

<div class="not-prose my-4">
    <a href="/en/territorios/municipios" class="inline-flex items-center gap-2 rounded-lg bg-blue-600 hover:bg-blue-700 px-4 py-2 text-sm font-semibold text-white no-underline">🔎 Find your municipality: population, council accounts and who governs</a>
</div>

## Map of autonomous communities

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Boundaries © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Population', fmt: 'num0'},
        {id: 'crecimiento_10_anios', title: 'Growth over 10 years (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Click on a community to open its profile.</p>

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

## Comparison between communities

<DataTable data={comparativa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Community" />
    <Column id=poblacion title="Population" fmt=num0 />
    <Column id=gasto_hab title="Non-financial spending (€ per person, {base[0]?.anio_base} euros)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=deuda_hab title="Debt (€ per person, {base[0]?.anio_base} euros)" fmt=num0 />
    <Column id=deuda_pct_pib title="Debt (% of GDP)" fmt=pct1 contentType=bar barColor="#bfdbfe" />
</DataTable>

<p class="text-xs text-gray-500">Amounts per person and adjusted for inflation ({base[0]?.anio_base} euros, using the annual average CPI). Spending: latest outturn published by the Ministry of Finance ({anio_gasto[0]?.anio}, chapters 1 to 7). Debt: latest quarter from the Banco de España. Ceuta and Melilla have no regional debt of their own under the Excessive Deficit Procedure.</p>

## Autonomous communities

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 not-prose">
{#each ccaa as c}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
        <a href={c.ruta} class="text-base font-bold text-gray-900 dark:text-white hover:underline no-underline">{c.nombre}</a>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1 mb-2">{formatNumber(c.poblacion, 0)} inhabitants · {#if c.crecimiento_10_anios > 0}+{/if}{formatNumber(c.crecimiento_10_anios, 1)}% over 10 years</p>
        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
        {#each provincias.filter(p => p.cod_ccaa === c.cod) as p}
            <a href={p.ruta} class="text-blue-600 dark:text-blue-400 hover:underline whitespace-nowrap">{p.nombre}</a>
        {/each}
        </div>
    </div>
{/each}
</div>

---

## Official sources

- **[INE – Official population figures for municipalities (Municipal Register)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**: population on 1 January, aggregated by province and community.
- **[INE – List of municipalities and codes](https://www.ine.es/daco/daco42/codmun/codmun00i.htm)**: municipality → province → community mapping.
- **[Instituto Geográfico Nacional (via es-atlas)](https://github.com/martgnz/es-atlas)**: boundaries of communities, provinces and municipalities (CC BY 4.0).

<LastRefreshed prefix="Data updated" />
