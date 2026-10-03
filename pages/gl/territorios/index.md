---
title: Territorios
description: "España por comunidades autónomas e provincias: poboación, contas públicas e débeda de cada administración."
i18n_origen: abbe3b0c0256
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
    '/gl' || t.ruta AS ruta,
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
SELECT cod, cod_ccaa, nombre, '/gl' || ruta AS ruta, poblacion_ultima AS poblacion
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

# 🗺️ España, territorio a territorio

España é un Estado descentralizado: as **comunidades autónomas** xestionan a sanidade, a educación e boa parte dos servizos sociais, e os **concellos** e as **deputacións** ocúpanse dos servizos de proximidade. Escolle unha comunidade no mapa para ver a súa poboación, as súas contas e a súa débeda, e baixa desde aí a cada provincia.

<Grid cols=3>
    <KpiCard
        title="Poboación de España"
        value={espana[0]?.poblacion_ultima}
        formattedValue={formatCompact(espana[0]?.poblacion_ultima, 2)}
        unit="hab."
        period="1 de xaneiro de {espana[0]?.anio_poblacion} · Padrón (INE)"
        sparklineData={espana_serie}
    />
    <KpiCard
        title="Comunidades e cidades autónomas"
        value={ccaa.length}
        formattedValue="{ccaa.length}"
        period="17 comunidades + Ceuta e Melilla"
    />
    <KpiCard
        title="Provincias"
        value={provincias.length}
        formattedValue="{provincias.length}"
        period="con máis de 8.100 municipios"
    />
</Grid>

<div class="not-prose my-4">
    <a href="/gl/territorios/municipios" class="inline-flex items-center gap-2 rounded-lg bg-blue-600 hover:bg-blue-700 px-4 py-2 text-sm font-semibold text-white no-underline">🔎 Busca o teu municipio: poboación, contas do concello e quen goberna</a>
</div>

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
        {id: 'poblacion', title: 'Poboación', fmt: 'num0'},
        {id: 'crecimiento_10_anios', title: 'Crecemento en 10 anos (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Preme nunha comunidade para abrir a súa ficha.</p>

```sql comparativa
WITH anio_cuentas AS (SELECT max(anio) AS anio FROM mother.ccaa_cuentas_resumen WHERE cod_ccaa <= '17'),
deuda AS (
    SELECT cod_ccaa, anio, deuda_eur, deuda_pct_pib
    FROM mother.ccaa_deuda
    WHERE fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
)
-- Euros por habitante y constantes (euros del último año completo, mother.deflactor)
SELECT
    c.nombre AS comunidad,
    c.ruta,
    c.poblacion,
    r.gastos_no_financieros / p.poblacion * fg.factor AS gasto_hab,
    d.deuda_eur / c.poblacion * coalesce(fd.factor, 1) AS deuda_hab,
    d.deuda_pct_pib / 100 AS deuda_pct_pib
FROM ${ccaa} c
LEFT JOIN mother.ccaa_cuentas_resumen r
  ON r.cod_ccaa = c.cod AND r.anio = (SELECT anio FROM anio_cuentas)
LEFT JOIN mother.poblacion_territorios p
  ON p.nivel = 'ccaa' AND p.cod = c.cod AND p.anio = r.anio AND p.sexo = 'Total'
LEFT JOIN deuda d ON d.cod_ccaa = c.cod
LEFT JOIN mother.deflactor fg ON fg.anio = CAST(r.anio AS INTEGER)
LEFT JOIN mother.deflactor fd ON fd.anio = CAST(d.anio AS INTEGER)
ORDER BY c.poblacion DESC
```

## Comparativa entre comunidades

<DataTable data={comparativa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=poblacion title="Poboación" fmt=num0 />
    <Column id=gasto_hab title="Gasto non financeiro (€/hab., euros de {base[0]?.anio_base})" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=deuda_hab title="Débeda (€/hab., euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=deuda_pct_pib title="Débeda (% PIB)" fmt=pct1 contentType=bar barColor="#bfdbfe" />
</DataTable>

<p class="text-xs text-gray-500">Importes por habitante e descontada a inflación (euros de {base[0]?.anio_base}, co IPC medio anual). Gasto: última liquidación de Facenda ({anio_gasto[0]?.anio}, capítulos 1 a 7). Débeda: último trimestre do Banco de España. Ceuta e Melilla non teñen débeda autonómica propia no Protocolo de Déficit Excesivo.</p>

## Comunidades autónomas

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 not-prose">
{#each ccaa as c}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
        <a href={c.ruta} class="text-base font-bold text-gray-900 dark:text-white hover:underline no-underline">{c.nombre}</a>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1 mb-2">{formatNumber(c.poblacion, 0)} habitantes · {#if c.crecimiento_10_anios > 0}+{/if}{formatNumber(c.crecimiento_10_anios, 1)} % en 10 anos</p>
        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
        {#each provincias.filter(p => p.cod_ccaa === c.cod) as p}
            <a href={p.ruta} class="text-blue-600 dark:text-blue-400 hover:underline whitespace-nowrap">{p.nombre}</a>
        {/each}
        </div>
    </div>
{/each}
</div>

---

## Fontes oficiais

- **[INE – Cifras oficiais de poboación dos municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**: poboación a 1 de xaneiro, agregada por provincia e comunidade.
- **[INE – Relación de municipios e códigos](https://www.ine.es/daco/daco42/codmun/codmun00i.htm)**: correspondencia municipio → provincia → comunidade.
- **[Instituto Geográfico Nacional (vía es-atlas)](https://github.com/martgnz/es-atlas)**: límites de comunidades, provincias e municipios (CC BY 4.0).

<LastRefreshed prefix="Datos actualizados" />
