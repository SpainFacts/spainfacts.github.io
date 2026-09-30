---
title: Lurraldeak
description: "Espainia autonomia-erkidegoka eta probintziaka: biztanleria, kontu publikoak eta administrazio bakoitzaren zorra."
i18n_origen: dd7a1e214c07
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    // Urteei euskal atzizkia eransten die (2021eko, 2023ko, 2025eko...)
    const urte = (n, s) => (n == null || n === '' ? '' : n + ([1, 5, 10, 15].includes(Number(n) % 20) ? 'e' : '') + s);
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
    '/eu' || t.ruta AS ruta,
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
SELECT cod, cod_ccaa, nombre, '/eu' || ruta AS ruta, poblacion_ultima AS poblacion
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

# 🗺️ Espainia, lurraldez lurralde

Espainia Estatu deszentralizatua da: **autonomia-erkidegoek** osasuna, hezkuntza eta gizarte-zerbitzuen zati handi bat kudeatzen dituzte, eta **udalek** eta **diputazioek** hurbileko zerbitzuez arduratzen dira. Aukeratu erkidego bat mapan haren biztanleria, kontuak eta zorra ikusteko, eta jaitsi hortik probintzia bakoitzera.

<Grid cols=3>
    <KpiCard
        title="Espainiako biztanleria"
        value={espana[0]?.poblacion_ultima}
        formattedValue={formatCompact(espana[0]?.poblacion_ultima, 2)}
        unit="biz."
        period="{urte(espana[0]?.anio_poblacion, 'ko')} urtarrilaren 1a · Udal Erroldak (INE)"
        sparklineData={espana_serie}
    />
    <KpiCard
        title="Autonomia-erkidegoak eta -hiriak"
        value={ccaa.length}
        formattedValue="{ccaa.length}"
        period="17 erkidego + Ceuta eta Melilla"
    />
    <KpiCard
        title="Probintziak"
        value={provincias.length}
        formattedValue="{provincias.length}"
        period="8.100 udalerri baino gehiagorekin"
    />
</Grid>

<div class="not-prose my-4">
    <a href="/eu/territorios/municipios" class="inline-flex items-center gap-2 rounded-lg bg-blue-600 hover:bg-blue-700 px-4 py-2 text-sm font-semibold text-white no-underline">🔎 Bilatu zure udalerria: biztanleria, udalaren kontuak eta nork gobernatzen duen</a>
</div>

## Autonomia-erkidegoen mapa

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Mugak © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Biztanleria', fmt: 'num0'},
        {id: 'crecimiento_10_anios', title: 'Hazkundea 10 urtean (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Sakatu erkidego batean haren fitxa irekitzeko.</p>

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

## Erkidegoen arteko alderaketa

<DataTable data={comparativa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=poblacion title="Biztanleria" fmt=num0 />
    <Column id=gasto_hab title="Gastu ez-finantzarioa (€/biz., {urte(base[0]?.anio_base, 'ko')} eurotan)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=deuda_hab title="Zorra (€/biz., {urte(base[0]?.anio_base, 'ko')} eurotan)" fmt=num0 />
    <Column id=deuda_pct_pib title="Zorra (BPGaren %)" fmt=pct1 contentType=bar barColor="#bfdbfe" />
</DataTable>

<p class="text-xs text-gray-500">Zenbatekoak biztanleko eta inflazioa kenduta ({urte(base[0]?.anio_base, 'ko')} eurotan, urteko batez besteko KPIarekin). Gastua: Ogasunaren azken likidazioa ({anio_gasto[0]?.anio}, 1etik 7rako kapituluak). Zorra: Espainiako Bankuaren azken hiruhilekoa. Ceutak eta Melillak ez dute autonomia-zor propiorik Gehiegizko Defizitaren Prozeduran.</p>

## Autonomia-erkidegoak

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 not-prose">
{#each ccaa as c}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
        <a href={c.ruta} class="text-base font-bold text-gray-900 dark:text-white hover:underline no-underline">{c.nombre}</a>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1 mb-2">{formatNumber(c.poblacion, 0)} biztanle · {#if c.crecimiento_10_anios > 0}+{/if}{formatNumber(c.crecimiento_10_anios, 1)} % 10 urtean</p>
        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
        {#each provincias.filter(p => p.cod_ccaa === c.cod) as p}
            <a href={p.ruta} class="text-blue-600 dark:text-blue-400 hover:underline whitespace-nowrap">{p.nombre}</a>
        {/each}
        </div>
    </div>
{/each}
</div>

---

## Iturri ofizialak

- **[INE – Udalerrien biztanleria-zifra ofizialak (Udal Erroldak)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**: urtarrilaren 1eko biztanleria, probintziaka eta erkidegoka batuta.
- **[INE – Udalerrien eta kodeen zerrenda](https://www.ine.es/daco/daco42/codmun/codmun00i.htm)**: udalerria → probintzia → erkidegoa korrespondentzia.
- **[Instituto Geográfico Nacional (es-atlas bidez)](https://github.com/martgnz/es-atlas)**: erkidegoen, probintzien eta udalerrien mugak (CC BY 4.0).

<LastRefreshed prefix="Datuak eguneratuta" />
