---
title: Territoris
description: "Espanya per comunitats autònomes i províncies: població, comptes públics i deute de cada administració."
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
    '/ca' || t.ruta AS ruta,
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
SELECT cod, cod_ccaa, nombre, '/ca' || ruta AS ruta, poblacion_ultima AS poblacion
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

# 🗺️ Espanya, territori a territori

Espanya és un Estat descentralitzat: les **comunitats autònomes** gestionen la sanitat, l'educació i bona part dels serveis socials, i els **ajuntaments** i les **diputacions** s'ocupen dels serveis de proximitat. Tria una comunitat al mapa per veure'n la població, els comptes i el deute, i baixa des d'allà a cada província.

<Grid cols=3>
    <KpiCard
        title="Població d'Espanya"
        value={espana[0]?.poblacion_ultima}
        formattedValue={formatCompact(espana[0]?.poblacion_ultima, 2)}
        unit="hab."
        period="1 de gener de {espana[0]?.anio_poblacion} · Padró (INE)"
        sparklineData={espana_serie}
    />
    <KpiCard
        title="Comunitats i ciutats autònomes"
        value={ccaa.length}
        formattedValue="{ccaa.length}"
        period="17 comunitats + Ceuta i Melilla"
    />
    <KpiCard
        title="Províncies"
        value={provincias.length}
        formattedValue="{provincias.length}"
        period="amb més de 8.100 municipis"
    />
</Grid>

<div class="not-prose my-4">
    <a href="/ca/territorios/municipios" class="inline-flex items-center gap-2 rounded-lg bg-blue-600 hover:bg-blue-700 px-4 py-2 text-sm font-semibold text-white no-underline">🔎 Cerca el teu municipi: població, comptes de l'ajuntament i qui governa</a>
</div>

## Mapa de comunitats autònomes

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límits © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Població', fmt: 'num0'},
        {id: 'crecimiento_10_anios', title: 'Creixement en 10 anys (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Fes clic en una comunitat per obrir-ne la fitxa.</p>

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

## Comparativa entre comunitats

<DataTable data={comparativa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=poblacion title="Població" fmt=num0 />
    <Column id=gasto_hab title="Despesa no financera (€/hab., euros de {base[0]?.anio_base})" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=deuda_hab title="Deute (€/hab., euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=deuda_pct_pib title="Deute (% PIB)" fmt=pct1 contentType=bar barColor="#bfdbfe" />
</DataTable>

<p class="text-xs text-gray-500">Imports per habitant i descomptada la inflació (euros de {base[0]?.anio_base}, amb l'IPC mitjà anual). Despesa: última liquidació d'Hisenda ({anio_gasto[0]?.anio}, capítols 1 a 7). Deute: últim trimestre del Banc d'Espanya. Ceuta i Melilla no tenen deute autonòmic propi en el Protocol de Dèficit Excessiu.</p>

## Comunitats autònomes

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 not-prose">
{#each ccaa as c}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
        <a href={c.ruta} class="text-base font-bold text-gray-900 dark:text-white hover:underline no-underline">{c.nombre}</a>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1 mb-2">{formatNumber(c.poblacion, 0)} habitants · {#if c.crecimiento_10_anios > 0}+{/if}{formatNumber(c.crecimiento_10_anios, 1)} % en 10 anys</p>
        <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs">
        {#each provincias.filter(p => p.cod_ccaa === c.cod) as p}
            <a href={p.ruta} class="text-blue-600 dark:text-blue-400 hover:underline whitespace-nowrap">{p.nombre}</a>
        {/each}
        </div>
    </div>
{/each}
</div>

---

## Fonts oficials

- **[INE – Xifres oficials de població dels municipis (Padró)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**: població a 1 de gener, agregada per província i comunitat.
- **[INE – Relació de municipis i codis](https://www.ine.es/daco/daco42/codmun/codmun00i.htm)**: correspondència municipi → província → comunitat.
- **[Instituto Geográfico Nacional (via es-atlas)](https://github.com/martgnz/es-atlas)**: límits de comunitats, províncies i municipis (CC BY 4.0).

<LastRefreshed prefix="Dades actualitzades" />
