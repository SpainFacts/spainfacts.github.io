---
description: "Ficha de la comunidad autónoma: población, economía, cuentas públicas, deuda, empleo público, seguridad y más, con datos oficiales y comparados con España."
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'"
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { page as currentPage } from '$app/stores';
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import IndiceTerritorio from '../../../../../../src/lib/components/IndiceTerritorio.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql terr
SELECT * FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'
```

```sql espana
SELECT poblacion_ultima FROM mother.territorios WHERE nivel = 'pais'
```

```sql base
-- Año de los euros constantes (último año completo de IPC)
SELECT max(anio_base) AS anio_base FROM mother.deflactor
```

```sql serie_poblacion
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND sexo = 'Total'
ORDER BY anio
```

```sql peso_serie
SELECT c.anio, 100.0 * c.poblacion / e.poblacion AS valor
FROM mother.poblacion_territorios c
JOIN mother.poblacion_territorios e
  ON e.nivel = 'pais' AND e.sexo = 'Total' AND e.anio = c.anio
WHERE c.nivel = 'ccaa' AND c.cod = '${terr[0]?.cod}' AND c.sexo = 'Total'
ORDER BY c.anio
```

```sql poblacion_sexo
SELECT sexo, poblacion
FROM mother.poblacion_territorios
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND sexo <> 'Total'
  AND anio = (SELECT max(anio) FROM mother.poblacion_territorios)
```

```sql provincias
SELECT
    t.cod, t.nombre, t.ruta, t.poblacion_ultima AS poblacion,
    count(m.cod_mun) AS municipios
FROM mother.territorios t
LEFT JOIN mother.poblacion_municipios m
  ON m.cod_prov = t.cod AND m.anio = t.anio_poblacion
WHERE t.nivel = 'provincia' AND t.cod_ccaa = '${terr[0]?.cod}'
GROUP BY ALL
ORDER BY poblacion DESC
```

```sql municipios
WITH ultimo AS (SELECT max(anio) AS anio FROM mother.poblacion_municipios),
actual AS (
    SELECT cod_mun, municipio, cod_prov, poblacion
    FROM mother.poblacion_municipios
    WHERE cod_ccaa = '${terr[0]?.cod}' AND anio = (SELECT anio FROM ultimo)
),
antes AS (
    SELECT cod_mun, poblacion AS poblacion_antes
    FROM mother.poblacion_municipios
    WHERE cod_ccaa = '${terr[0]?.cod}' AND anio = (SELECT anio - 9 FROM ultimo)
)
SELECT
    a.cod_mun, a.municipio, p.nombre AS provincia, a.poblacion,
    100.0 * (a.poblacion - b.poblacion_antes) / nullif(b.poblacion_antes, 0) AS crecimiento,
    '/territorios/municipios?m=' || a.cod_mun AS enlace
FROM actual a
LEFT JOIN antes b USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = a.cod_prov
ORDER BY a.poblacion DESC
```

```sql resumen_municipios
SELECT
    count(*) AS n,
    count(*) FILTER (WHERE poblacion < 1000) AS menos_1000,
    count(*) FILTER (WHERE crecimiento < 0) AS pierden,
    quantile_cont(poblacion, 0.9) AS p90
FROM ${municipios}
```

{#if terr[0]?.slug === $currentPage.params.ccaa}
# {terr[0]?.nombre}

<IndiceTerritorio />

<p class="text-sm text-gray-500"><a href="/territorios">Territorios</a> › {terr[0]?.nombre}</p>

<Grid cols=3>
    <KpiCard
        title="Población"
        value={terr[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima, 0)}
        unit="hab."
        period="1 de enero de {terr[0]?.anio_poblacion}"
        source="INE – Padrón"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Peso en España"
        value={100 * terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima / 0.01, 1)}
        unit="%"
        period="de la población española"
        sparklineData={peso_serie}
    />
    <KpiCard
        title="Municipios"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} con menos de 1.000 hab. · {formatNumber(resumen_municipios[0]?.pierden, 0)} pierden población en 10 años"
    />
</Grid>

## Población

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Población a 1 de enero (Padrón)"
    lineColor="#1d4ed8"
/>

```sql demo_anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, tasa_natalidad, tasa_mortalidad,
    vegetativo_1000, fecundidad, edad_maternidad, pct_madre_extranjera, crecimiento_1000, resto_1000
FROM mother.demografia_anual
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND tasa_natalidad IS NOT NULL
ORDER BY anio
```

```sql demo_edades
SELECT CAST(anio AS INTEGER) AS anio, pct_65, pct_80, dependencia, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
ORDER BY anio
```

```sql demo_espana
SELECT a.tasa_natalidad, a.fecundidad, e.pct_65, e.edad_media
FROM mother.demografia_anual a
JOIN mother.demografia_envejecimiento e ON e.nivel = 'pais' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
WHERE a.nivel = 'pais' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
```

```sql demo_piramide
SELECT grupo, edad_desde, sexo, CASE WHEN sexo = 'Hombres' THEN -pct ELSE pct END AS pct
FROM mother.demografia_piramide
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
  AND anio = (SELECT max(anio) FROM mother.demografia_piramide)
ORDER BY edad_desde, sexo
```

```sql demo_tasas
SELECT anio, 'Nacimientos' AS fenomeno, tasa_natalidad AS por_1000 FROM ${demo_anual}
UNION ALL
SELECT anio, 'Defunciones', tasa_mortalidad FROM ${demo_anual}
ORDER BY anio
```

## Natalidad y envejecimiento

<Grid cols=4>
    <KpiCard
        title="Natalidad"
        value={demo_anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(demo_anual.slice(-1)[0]?.tasa_natalidad, 1)} por 1.000 hab."
        period="{formatNumber(demo_anual.slice(-1)[0]?.nacimientos, 0)} nacimientos en {demo_anual.slice(-1)[0]?.anio} · España: {formatNumber(demo_espana[0]?.tasa_natalidad, 1)}"
        source="INE"
        href="/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Hijos por mujer"
        value={demo_anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(demo_anual.slice(-1)[0]?.fecundidad, 2)}
        period="{demo_anual.slice(-1)[0]?.anio} · España: {formatNumber(demo_espana[0]?.fecundidad, 2)}"
        source="INE"
        href="/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Mayores de 65 años"
        value={demo_edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.pct_65, 1)} %"
        period="de la población en {demo_edades.slice(-1)[0]?.anio} · España: {formatNumber(demo_espana[0]?.pct_65, 1)} %"
        source="INE"
        href="/demografia/estructura-edades"
        sparklineData={demo_edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Edad media"
        value={demo_edades.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.edad_media, 1)} años"
        period="{demo_edades.slice(-1)[0]?.anio} · España: {formatNumber(demo_espana[0]?.edad_media, 1)} años"
        source="INE"
        href="/demografia/estructura-edades"
        sparklineData={demo_edades.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

<Grid cols=2>
    <BarChart
        data={demo_piramide}
        x=grupo
        y=pct
        series=sexo
        swapXY=true
        type=stacked
        sort=false
        yFmt='0.0"%";0.0"%"'
        colorPalette={['#0f766e', '#7c3aed']}
        title="Pirámide de población, {demo_edades.slice(-1)[0]?.anio} (% del total)"
    />
    <LineChart
        data={demo_tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="por 1.000 habitantes"
        title="Nacimientos y defunciones por 1.000 habitantes"
    />
</Grid>

<p class="text-xs text-gray-500">En {demo_anual.slice(-1)[0]?.anio} la población de {terr[0]?.nombre} cambió {formatNumber(demo_anual.slice(-1)[0]?.crecimiento_1000, 1)} por 1.000 habitantes: {formatNumber(demo_anual.slice(-1)[0]?.vegetativo_1000, 1)} por nacimientos menos defunciones y {formatNumber(demo_anual.slice(-1)[0]?.resto_1000, 1)} por migración (con el extranjero y con otras comunidades) y ajustes. {formatNumber(demo_edades.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % de sus habitantes nació en el extranjero. Fuente: INE (Movimiento Natural de la Población, Indicadores Demográficos Básicos y Estadística Continua de Población).</p>

{#if provincias.length > 1}

## Provincias

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 not-prose">
{#each provincias as p}
    <a href={p.ruta} class="block rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-3 hover:border-blue-400 no-underline">
        <span class="font-semibold text-gray-900 dark:text-white">{p.nombre}</span>
        <span class="block text-xs text-gray-500">{formatNumber(p.poblacion, 0)} hab. · {p.municipios} municipios</span>
    </a>
{/each}
</div>

{:else}

<p>{terr[0]?.nombre} es una comunidad uniprovincial. <a href={provincias[0]?.ruta}>Ver la ficha provincial de {provincias[0]?.nombre}</a>.</p>

{/if}

## Municipios

<MapaEspana
    data={municipios}
    geoJsonUrl="/geo/municipios/{terr[0]?.cod}.geojson"
    geoId="cod_mun"
    areaCol="cod_mun"
    value="poblacion"
    valueFmt="num0"
    max={resumen_municipios[0]?.p90}
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Población', fmt: 'num0'},
        {id: 'crecimiento', title: 'Crecimiento 10 años (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">La escala de color satura en el 10 % de municipios más poblados para que se distingan los pequeños.</p>

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Población" fmt=num0 />
    <Column id=crecimiento title="Crecimiento 10 años (%)" fmt=num1 contentType=delta />
</DataTable>

```sql cuentas
SELECT
    r.anio,
    make_date(CAST(r.anio AS INTEGER), 1, 1) AS fecha,
    r.ingresos_no_financieros,
    r.gastos_no_financieros,
    r.saldo_no_financiero,
    -- Euros por habitante constantes (euros del último año completo)
    r.gastos_nf_eur_hab_real AS gasto_hab_real,
    r.ingresos_nf_eur_hab_real AS ingreso_hab_real,
    r.saldo_nf_eur_hab_real AS saldo_hab_real
FROM mother.ccaa_cuentas_resumen r
WHERE r.cod_ccaa = '${terr[0]?.cod}'
ORDER BY r.anio
```

```sql cuentas_ultimo
SELECT * FROM ${cuentas} ORDER BY anio DESC LIMIT 1
```

```sql cuentas_evolucion
SELECT fecha, 'Ingresos' AS concepto, ingreso_hab_real AS importe FROM ${cuentas}
UNION ALL
SELECT fecha, 'Gastos', gasto_hab_real FROM ${cuentas}
ORDER BY fecha
```

```sql gasto_ranking
WITH ultimo AS (SELECT max(anio) AS anio FROM mother.ccaa_cuentas_resumen WHERE cod_ccaa <= '17')
SELECT
    r.ccaa AS comunidad,
    r.gastos_nf_eur_hab_real AS gasto_hab,
    CASE WHEN r.cod_ccaa = '${terr[0]?.cod}' THEN 'Esta comunidad' ELSE 'Resto' END AS grupo
FROM mother.ccaa_cuentas_resumen r
WHERE r.anio = (SELECT anio FROM ultimo) AND r.cod_ccaa <= '17'
ORDER BY gasto_hab DESC
```

```sql politicas
-- Gasto por política (depurado de transferencias a ayuntamientos y fondos
-- PAC) por habitante, frente a la media de las 17 comunidades. Los importes
-- por habitante van en euros constantes del último año completo.
WITH anio AS (SELECT max(anio) AS anio FROM mother.ccaa_gasto_politicas WHERE cod_ccaa = '${terr[0]?.cod}'),
por_ccaa AS (
    SELECT g.cod_ccaa, g.cod_politica, g.politica_nombre,
        sum(g.obligaciones) AS obligaciones,
        sum(g.obligaciones_eur_hab_real) AS hab_real,
        any_value(g.poblacion) AS poblacion
    FROM mother.ccaa_gasto_politicas g
    WHERE g.anio = (SELECT anio FROM anio) AND g.cod_ccaa <= '17'
    GROUP BY ALL
),
media AS (
    SELECT cod_politica, sum(hab_real * poblacion) / sum(poblacion) AS media_hab_real
    FROM por_ccaa GROUP BY cod_politica
)
SELECT
    c.politica_nombre AS politica,
    c.obligaciones,
    c.hab_real AS por_habitante,
    m.media_hab_real AS media_ccaa,
    100.0 * (c.hab_real - m.media_hab_real) / nullif(m.media_hab_real, 0) AS dif_pct,
    c.obligaciones / sum(c.obligaciones) OVER () AS peso
FROM por_ccaa c
JOIN media m USING (cod_politica)
WHERE c.cod_ccaa = '${terr[0]?.cod}' AND c.obligaciones > 0
ORDER BY c.obligaciones DESC
```

```sql politicas_grafico
SELECT politica, 'Esta comunidad' AS serie, por_habitante AS euros FROM ${politicas} WHERE peso >= 0.02
UNION ALL
SELECT politica, 'Media de las CCAA', media_ccaa FROM ${politicas} WHERE peso >= 0.02
```

```sql capitulos
SELECT
    CASE c.tipo WHEN 'ingreso' THEN 'Ingresos' ELSE 'Gastos' END AS tipo,
    c.capitulo,
    c.capitulo_nombre,
    c.anio,
    c.ejecutado_eur_hab_real AS ejecutado_hab,
    c.presupuesto_definitivo,
    c.ejecutado,
    c.ejecutado / nullif(c.presupuesto_definitivo, 0) AS grado_ejecucion
FROM mother.ccaa_cuentas_capitulos c
WHERE c.cod_ccaa = '${terr[0]?.cod}'
  AND c.anio = (SELECT max(anio) FROM mother.ccaa_cuentas_capitulos WHERE cod_ccaa = '${terr[0]?.cod}')
ORDER BY c.tipo DESC, c.capitulo
```

{#if cuentas.length > 0 && cuentas_ultimo[0]?.anio >= 2020}

## Ingresos y gastos de la comunidad

Cuentas ejecutadas (liquidación) de la administración autonómica consolidada. Se usa el gasto **no financiero** (capítulos 1 a 7), que deja fuera la compra de activos y la devolución de deuda, para comparar lo que cada comunidad gasta de verdad en servicios. Todos los importes van **por habitante** y **descontada la inflación**, en euros de {base[0]?.anio_base}: así la evolución no crece solo porque haya más población o suban los precios.

<Grid cols=3>
    <KpiCard
        title="Gasto no financiero por habitante"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="Liquidación {cuentas_ultimo[0]?.anio}, en euros de {base[0]?.anio_base} · total: {formatCompact(cuentas_ultimo[0]?.gastos_no_financieros, 0)} € corrientes"
        source="Ministerio de Hacienda"
        sparklineData={cuentas.filter(d => d.gasto_hab_real != null).map(d => ({anio: d.anio, valor: d.gasto_hab_real}))}
    />
    <KpiCard
        title="Ingreso no financiero por habitante"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="En euros de {base[0]?.anio_base} · total: {formatCompact(cuentas_ultimo[0]?.ingresos_no_financieros, 0)} € corrientes"
        sparklineData={cuentas.filter(d => d.ingreso_hab_real != null).map(d => ({anio: d.anio, valor: d.ingreso_hab_real}))}
    />
    <KpiCard
        title="Saldo no financiero por habitante"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Ingresos − gastos no financieros, en euros de {base[0]?.anio_base} · total: {formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 0)} € corrientes"
        direction="positive-up"
        sparklineData={cuentas.filter(d => d.saldo_hab_real != null).map(d => ({anio: d.anio, valor: d.saldo_hab_real}))}
    />
</Grid>

<BarChart
    data={gasto_ranking}
    x=comunidad
    y=gasto_hab
    series=grupo
    swapXY=true
    yFmt=num0
    title="Gasto no financiero por habitante en {cuentas_ultimo[0]?.anio} (euros de {base[0]?.anio_base})"
    colorPalette={['#0f766e', '#cbd5e1']}
    sort=false
/>

### ¿En qué gasta?

<BarChart
    data={politicas_grafico}
    x=politica
    y=euros
    series=serie
    type=grouped
    swapXY=true
    yFmt=num0
    title="Euros por habitante en cada política (euros de {base[0]?.anio_base}; las que pesan al menos un 2 %)"
    colorPalette={['#0f766e', '#94a3b8']}
/>

<DataTable data={politicas} rows=all>
    <Column id=politica title="Política de gasto" />
    <Column id=por_habitante title="€/habitante (euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=media_ccaa title="Media CCAA (€/hab.)" fmt=num0 />
    <Column id=dif_pct title="Diferencia (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Peso" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=obligaciones title="Gasto total (€ corrientes)" fmt=num0 />
</DataTable>

### Evolución

<LineChart
    data={cuentas_evolucion}
    x=fecha
    y=importe
    series=concepto
    yFmt=num0
    yAxisTitle="€ por habitante"
    title="Ingresos y gastos no financieros por habitante (euros de {base[0]?.anio_base}, descontada la inflación)"
    colorPalette={['#0f766e', '#b45309']}
/>

<Details title="Detalle por capítulos del último año">

<DataTable data={capitulos} rows=all groupBy=tipo>
    <Column id=capitulo title="Cap." />
    <Column id=capitulo_nombre title="Capítulo" />
    <Column id=ejecutado_hab title="Ejecutado por habitante (euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=presupuesto_definitivo title="Presupuesto definitivo (€)" fmt=num0 />
    <Column id=ejecutado title="Ejecutado (€)" fmt=num0 />
    <Column id=grado_ejecucion title="Ejecución" fmt=pct0 />
</DataTable>

</Details>

{:else}

<p class="text-sm text-gray-500">Hacienda solo publica la liquidación de {terr[0]?.nombre} hasta 2012, por lo que no se muestra la comparación con el resto de comunidades.</p>

{/if}

```sql deuda
SELECT fecha, anio, trimestre, deuda_eur, deuda_pct_pib
FROM mother.ccaa_deuda
WHERE cod_ccaa = '${terr[0]?.cod}'
ORDER BY fecha
```

```sql deuda_ultima
-- Deuda por habitante en euros constantes (deuda_eur_hab_real)
SELECT
    d.fecha, d.anio, d.trimestre, d.deuda_eur, d.deuda_pct_pib,
    d.deuda_eur_hab_real AS deuda_hab_real,
    a.deuda_pct_pib AS pct_pib_hace_un_anio
FROM mother.ccaa_deuda d
LEFT JOIN mother.ccaa_deuda a
  ON a.cod_ccaa = d.cod_ccaa AND a.fecha = d.fecha - INTERVAL 1 YEAR
WHERE d.cod_ccaa = '${terr[0]?.cod}'
ORDER BY d.fecha DESC
LIMIT 1
```

```sql deuda_ranking
SELECT
    t.nombre AS comunidad,
    d.deuda_pct_pib / 100 AS deuda_pct_pib,
    CASE WHEN d.cod_ccaa = '${terr[0]?.cod}' THEN 'Esta comunidad' ELSE 'Resto' END AS grupo
FROM mother.ccaa_deuda d
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = d.cod_ccaa
WHERE d.fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
ORDER BY d.deuda_pct_pib DESC
```

```sql deuda_hab_serie
-- Deuda al cierre de cada año (último trimestre publicado) por habitante, en euros constantes
-- (sin deflactor antes de 1996: la serie real empieza ese año)
SELECT anio, deuda_eur_hab_real AS valor
FROM mother.ccaa_deuda
WHERE cod_ccaa = '${terr[0]?.cod}' AND deuda_eur_hab_real IS NOT NULL
QUALIFY row_number() OVER (PARTITION BY anio ORDER BY fecha DESC) = 1
ORDER BY anio
```

```sql saldo
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, anio, saldo_eur, saldo_pct_pib / 100 AS saldo_pct_pib, saldo_pct_pib AS saldo_pct
FROM mother.ccaa_saldo
WHERE cod_ccaa = '${terr[0]?.cod}'
ORDER BY anio
```

{#if deuda.length > 0}

## Deuda y déficit

<Grid cols=3>
    <KpiCard
        title="Deuda pública por habitante"
        value={deuda_ultima[0]?.deuda_hab_real}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_hab_real, 0)}
        unit="€"
        period="{deuda_ultima[0]?.trimestre}.º trim. {deuda_ultima[0]?.anio}, en euros de {base[0]?.anio_base} · total: {formatCompact(deuda_ultima[0]?.deuda_eur, 0)} € corrientes"
        source="Banco de España (PDE)"
        sparklineData={deuda_hab_serie}
    />
    <KpiCard
        title="Deuda sobre el PIB regional"
        value={deuda_ultima[0]?.deuda_pct_pib}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_pct_pib, 1)}
        unit="%"
        change={deuda_ultima[0]?.pct_pib_hace_un_anio != null ? (deuda_ultima[0].deuda_pct_pib - deuda_ultima[0].pct_pib_hace_un_anio).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. hace un año"
        direction="positive-down"
        sparklineData={deuda.filter(d => d.deuda_pct_pib != null).slice(-40).map(d => ({fecha: d.fecha, valor: d.deuda_pct_pib}))}
    />
    {#if saldo.length > 0}
    <KpiCard
        title="Déficit (−) o superávit (+)"
        value={saldo[saldo.length - 1]?.saldo_pct}
        formattedValue={formatNumber(saldo[saldo.length - 1]?.saldo_pct, 1)}
        unit="% PIB"
        period="en {saldo[saldo.length - 1]?.anio}"
        direction="positive-up"
        sparklineData={saldo.map(d => ({anio: d.anio, valor: d.saldo_pct}))}
    />
    {/if}
</Grid>

<p class="text-xs text-gray-500">La deuda por habitante usa la población del Padrón de cada año (la última disponible para los años sin Padrón) y está descontada la inflación: euros de {base[0]?.anio_base} (la serie de la miniatura empieza en 1996, primer año con deflactor).</p>

<BarChart
    data={deuda_ranking}
    x=comunidad
    y=deuda_pct_pib
    series=grupo
    swapXY=true
    yFmt=pct0
    title="Deuda sobre el PIB regional, todas las comunidades"
    colorPalette={['#1d4ed8', '#cbd5e1']}
    sort=false
/>

<LineChart
    data={deuda}
    x=fecha
    y=deuda_pct_pib
    yFmt=num0
    yAxisTitle="% del PIB regional"
    title="Evolución de la deuda (% del PIB regional)"
    lineColor="#1d4ed8"
/>

{#if saldo.length > 0}

<BarChart
    data={saldo}
    x=anio
    y=saldo_pct_pib
    yFmt=pct1
    title="Superávit (+) o déficit (−) anual, % del PIB regional"
    fillColor="#64748b"
/>

<p class="text-xs text-gray-500">El saldo anual es la suma de los doce meses publicados por el Banco de España (solo años completos); el porcentaje se calcula con el PIB regional implícito en sus series de deuda.</p>

{/if}

{:else}

<p class="text-sm text-gray-500">El Banco de España no publica deuda propia de {terr[0]?.nombre}: en el Protocolo de Déficit Excesivo Ceuta y Melilla se contabilizan como administración local.</p>

{/if}

```sql empleo
WITH ult AS (SELECT max(fecha) AS fecha FROM mother.empleo_territorio)
SELECT
    strftime(t.fecha, '%d/%m/%Y') AS fecha_texto,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS efectivos,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total') AS por_1000,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Estado') AS estado,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Comunidades autónomas') AS ccaa,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Entidades locales') AS local,
    100.0 * max(t.efectivos) FILTER (WHERE t.administracion = 'Comunidades autónomas') / max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS pct_ccaa,
    100.0 * max(t.efectivos) FILTER (WHERE t.administracion = 'Estado') / max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS pct_estado,
    100.0 * max(t.efectivos) FILTER (WHERE t.administracion = 'Entidades locales') / max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS pct_local,
    (SELECT por_1000_hab FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = t.fecha) AS por_1000_espana,
    (SELECT count(*) + 1 FROM mother.empleo_territorio o
      WHERE o.nivel = 'ccaa' AND o.administracion = 'Total' AND o.fecha = t.fecha
        AND o.por_1000_hab > max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total')) AS puesto
FROM mother.empleo_territorio t, ult
WHERE t.nivel = 'ccaa' AND t.cod = '${terr[0]?.cod}' AND t.fecha = ult.fecha
GROUP BY t.fecha
```

```sql empleo_sectores
-- Por 1.000 habitantes, con la última población del Padrón
SELECT
    sector, administracion,
    1000.0 * sum(efectivos) / (SELECT poblacion_ultima FROM mother.territorios WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}') AS por_1000,
    sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE cod_ccaa = '${terr[0]?.cod}' AND fecha = (SELECT max(fecha) FROM mother.empleo_efectivos)
GROUP BY ALL
ORDER BY efectivos DESC
```

```sql empleo_serie
SELECT fecha, administracion, por_1000_hab, efectivos
FROM mother.empleo_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND administracion <> 'Total'
ORDER BY fecha
```

```sql empleo_total_serie
SELECT fecha, efectivos, por_1000_hab
FROM mother.empleo_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND administracion = 'Total'
ORDER BY fecha
```

```sql empleo_gasto_serie
-- Gasto de personal de la comunidad por habitante, en euros constantes
SELECT g.anio, g.gasto_personal_ccaa_eur_hab_real AS valor
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ccaa_eur_hab_real IS NOT NULL
ORDER BY g.anio
```

```sql empleo_gasto
-- Importes por habitante en euros constantes del último año completo
SELECT
    g.anio,
    g.gasto_personal_ccaa,
    g.gasto_personal_ccaa_eur_hab_real AS gasto_personal_ccaa_hab,
    g.gasto_personal_ayuntamientos_eur_hab_real AS gasto_personal_ayuntamientos_hab,
    (SELECT avg(gasto_personal_ccaa_eur_hab_real) FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'ccaa' AND x.anio = g.anio AND x.cod <= '17') AS media_ccaa_hab,
    (SELECT gasto_personal_ayuntamientos_eur_hab_real FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'pais' AND x.anio = g.anio) AS aytos_espana_hab
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ccaa IS NOT NULL
ORDER BY g.anio DESC
LIMIT 1
```

```sql empleo_salario
SELECT salario_publico, salario_privado FROM mother.empleo_salarios_ccaa WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
```

```sql crimen_ccaa
SELECT
    b.anio,
    b.tasa_1000 AS tasa,
    b.infracciones,
    e.tasa_1000 AS tasa_espana
FROM mother.crimen_balance b
JOIN mother.crimen_balance e ON e.nivel = 'pais' AND e.anio = b.anio AND e.categoria = b.categoria
WHERE b.nivel = 'ccaa' AND b.cod = '${terr[0]?.cod}' AND b.categoria = 'Total infracciones penales'
ORDER BY b.anio
```

{#if crimen_ccaa.length > 0}

## Seguridad

<LineChart
    data={crimen_ccaa}
    x=anio
    y={['tasa', 'tasa_espana']}
    yFmt=num1
    xFmt="####"
    seriesLabels={{tasa: terr[0]?.nombre, tasa_espana: 'España'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    yAxisTitle="por 1.000 habitantes"
    title="Infracciones penales conocidas por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">{formatNumber(crimen_ccaa.slice(-1)[0]?.infracciones, 0)} infracciones conocidas en {crimen_ccaa.slice(-1)[0]?.anio} (Ministerio del Interior; incluye policías autonómicas). 2020 es el año del confinamiento. Detalle por tipo de delito y municipio en <a href="/sociedad/criminalidad">Criminalidad</a>.</p>

{/if}

{#if empleo.length > 0}

## Empleo público

<Grid cols=3>
    <KpiCard
        title="Empleados públicos por 1.000 habitantes"
        value={empleo[0]?.por_1000}
        formattedValue={formatNumber(empleo[0]?.por_1000, 1)}
        period="España: {formatNumber(empleo[0]?.por_1000_espana, 1)} · puesto {empleo[0]?.puesto} de 19 · {formatNumber(empleo[0]?.efectivos, 0)} empleados a {empleo[0]?.fecha_texto}"
        source="Registro Central de Personal"
        sparklineData={empleo_total_serie.filter(d => d.por_1000_hab != null).map(d => ({fecha: d.fecha, valor: d.por_1000_hab}))}
    />
    <KpiCard
        title="Trabajan para la comunidad"
        value={empleo[0]?.pct_ccaa}
        formattedValue={formatNumber(empleo[0]?.pct_ccaa, 0)}
        unit="%"
        period="del empleo público · Estado: {formatNumber(empleo[0]?.pct_estado, 0)} % · entidades locales: {formatNumber(empleo[0]?.pct_local, 0)} %"
        source="Registro Central de Personal"
    />
    {#if empleo_gasto.length > 0}
    <KpiCard
        title="Gasto de personal de la comunidad"
        value={empleo_gasto[0]?.gasto_personal_ccaa_hab}
        formattedValue="{formatNumber(empleo_gasto[0]?.gasto_personal_ccaa_hab, 0)} €/hab."
        period="{empleo_gasto[0]?.anio}, en euros de {base[0]?.anio_base} · media de las comunidades: {formatNumber(empleo_gasto[0]?.media_ccaa_hab, 0)} € · total: {formatNumber(empleo_gasto[0]?.gasto_personal_ccaa / 1e9, 1)} mil M€ corrientes"
        source="Hacienda (capítulo 1)"
        sparklineData={empleo_gasto_serie}
    />
    {/if}
</Grid>

<Grid cols=2>
    <BarChart
        data={empleo_sectores}
        x=sector
        y=por_1000
        series=administracion
        swapXY=true
        sort=false
        yFmt=num1
        colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
        title="Por sector y administración (por 1.000 habitantes)"
    />
    <BarChart
        data={empleo_serie}
        x=fecha
        y=por_1000_hab
        series=administracion
        type=stacked
        yFmt=num1
        xFmt="mmm yyyy"
        colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
        title="Evolución por 1.000 habitantes (1 de enero y 1 de julio)"
    />
</Grid>

<p class="text-xs text-gray-500">Personal con puesto en {terr[0]?.nombre} de las tres administraciones: el Estado (Guardia Civil, Policía Nacional, militares, Agencia Tributaria...), la comunidad (sanidad, educación, universidades...) y las entidades locales. {#if empleo_gasto.length > 0 && empleo_gasto[0]?.gasto_personal_ayuntamientos_hab}Los ayuntamientos de la comunidad gastaron en personal {formatNumber(empleo_gasto[0].gasto_personal_ayuntamientos_hab, 0)} € por habitante en {empleo_gasto[0].anio} (media de España: {formatNumber(empleo_gasto[0].aytos_espana_hab, 0)} €; euros de {base[0]?.anio_base}).{/if} {#if empleo_salario.length > 0 && empleo_salario[0]?.salario_publico}Salario medio bruto en 2022: {formatNumber(empleo_salario[0].salario_publico, 0)} € al año en el sector público y {formatNumber(empleo_salario[0].salario_privado, 0)} € en el privado (INE).{/if} El salto de 2023 es en parte una revisión del registro. Más en <a href="/cuentas-publicas/empleo-publico">Empleo público</a>.</p>

{/if}

---

```sql paro_terr
SELECT
    CAST(year(t.trimestre) AS INTEGER) || '-T' || CAST(quarter(t.trimestre) AS INTEGER) AS periodo,
    t.trimestre, t.tasa_paro, t.media_4t_tasa_paro, t.tasa_paro_menor25, t.media_4t_tasa_paro_menor25,
    t.pct_hogares_todos_parados, t.tasa_paro_dif_anual,
    e.tasa_paro AS tasa_paro_espana, e.tasa_paro_menor25 AS tasa_paro_menor25_espana
FROM mother.mercado_paro_territorios t
LEFT JOIN mother.mercado_paro_territorios e ON e.nivel = 'pais' AND e.trimestre = t.trimestre
WHERE t.nivel = 'ccaa' AND t.cod = '${terr[0]?.cod}'
ORDER BY t.trimestre
```

```sql ipc_terr
SELECT i.mes, strftime(i.mes, '%m/%Y') AS mes_txt, i.var_anual, i.subida_desde_2019
FROM mother.mercado_ipc_ccaa i
WHERE i.cod_ccaa = '${terr[0]?.cod}'
ORDER BY i.mes
```

```sql paro_reg_terr
SELECT mes, strftime(mes, '%m/%Y') AS mes_txt, paro_registrado, por_100_16_64, variacion_anual_pct
FROM mother.mercado_paro_registrado
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
ORDER BY mes
```

{#if paro_terr.length > 0}

## Paro y precios

<Grid cols=4>
    <KpiCard
        title="Tasa de paro"
        value={paro_terr.slice(-1)[0]?.tasa_paro}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro, 1)} %"
        period="EPA {paro_terr.slice(-1)[0]?.periodo} · media del último año {formatNumber(paro_terr.slice(-1)[0]?.media_4t_tasa_paro, 1)} % · España {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_espana, 1)} %"
        direction="positive-down"
        source="INE / EPA"
        href="/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => ({...d, y: d.tasa_paro}))}
    />
    <KpiCard
        title="Paro de menores de 25 años"
        value={paro_terr.slice(-1)[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25, 1)} %"
        period="{paro_terr.slice(-1)[0]?.periodo} · España {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25_espana, 1)} %"
        direction="positive-down"
        source="INE / EPA"
        href="/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => ({...d, y: d.tasa_paro_menor25}))}
    />
    <KpiCard
        title="Paro registrado"
        value={paro_reg_terr.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(paro_reg_terr.slice(-1)[0]?.por_100_16_64, 1)} por 100 hab."
        period="de 16 a 64 años, {paro_reg_terr.slice(-1)[0]?.mes_txt} · {formatNumber(paro_reg_terr.slice(-1)[0]?.paro_registrado, 0)} personas ({formatNumber(paro_reg_terr.slice(-1)[0]?.variacion_anual_pct, 1)} % en un año)"
        direction="positive-down"
        source="SEPE"
        href="/economia/paro"
        sparklineData={paro_reg_terr.slice(-36).map(d => ({...d, y: d.por_100_16_64}))}
    />
    <KpiCard
        title="Inflación"
        value={ipc_terr.slice(-1)[0]?.var_anual}
        formattedValue="{formatNumber(ipc_terr.slice(-1)[0]?.var_anual, 1)} %"
        period="IPC interanual, {ipc_terr.slice(-1)[0]?.mes_txt} · precios +{formatNumber(ipc_terr.slice(-1)[0]?.subida_desde_2019, 1)} % desde finales de 2019"
        direction="positive-down"
        source="INE / IPC"
        href="/economia/ipc"
        sparklineData={ipc_terr.slice(-36).map(d => ({...d, y: d.var_anual}))}
    />
</Grid>

<LineChart
    data={paro_terr}
    x=trimestre
    y={['tasa_paro', 'tasa_paro_espana']}
    seriesLabels={{tasa_paro: terr[0]?.nombre, tasa_paro_espana: 'España'}}
    colorPalette={['#2563eb', '#94a3b8']}
    yFmt='0.0"%"'
    yAxisTitle="% de la población activa"
    title="Tasa de paro (EPA)"
/>

{/if}

```sql renta_ccaa
SELECT
    CAST(e.anio AS INTEGER) AS anio,
    CAST(e.anio_renta AS INTEGER) AS anio_renta,
    e.renta_persona_real, e.renta_uc_real, e.tasa_pobreza, e.arope, e.carencia_severa, e.fin_mes_dificultad, e.gini,
    n.renta_persona_real AS renta_persona_espana, n.tasa_pobreza AS pobreza_espana, n.arope AS arope_espana, n.gini AS gini_espana
FROM mother.renta_ecv_ccaa e
LEFT JOIN mother.renta_ecv_ccaa n ON n.cod = '00' AND n.anio = e.anio
WHERE e.cod = '${terr[0]?.cod}' AND e.anio >= 2008
ORDER BY e.anio
```

```sql renta_ccaa_puesto
SELECT puesto_pobreza, puesto_renta, n FROM (
    SELECT cod,
        rank() OVER (ORDER BY tasa_pobreza DESC) AS puesto_pobreza,
        rank() OVER (ORDER BY renta_persona_real DESC) AS puesto_renta,
        count(*) OVER () AS n
    FROM mother.renta_ecv_ccaa
    WHERE nivel = 'ccaa' AND anio = (SELECT max(anio) FROM mother.renta_ecv_ccaa WHERE tasa_pobreza IS NOT NULL)
) WHERE cod = '${terr[0]?.cod}'
```

```sql renta_ccaa_municipios
SELECT m.municipio, m.poblacion, m.renta_persona_real, m.renta_hogar_real, CAST(m.anio AS INTEGER) AS anio,
    '/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
WHERE m.cod_ccaa = '${terr[0]?.cod}' AND m.anio = (SELECT max(anio) FROM mother.renta_municipios)
  AND m.poblacion > 20000 AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

{#if renta_ccaa.length > 0}

## Renta y pobreza

<Grid cols=3>
    <KpiCard
        title="Renta media por persona"
        value={renta_ccaa.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="al año, renta de {renta_ccaa.slice(-1)[0]?.anio_renta} descontada la inflación · España {formatNumber(renta_ccaa.slice(-1)[0]?.renta_persona_espana, 0)} € · puesto {renta_ccaa_puesto[0]?.puesto_renta} de {renta_ccaa_puesto[0]?.n}"
        direction="positive-up"
        source="INE / ECV"
        href="/sociedad/desigualdad"
        sparklineData={renta_ccaa.map(d => ({...d, y: d.renta_persona_real}))}
    />
    <KpiCard
        title="Riesgo de pobreza"
        value={renta_ccaa.slice(-1)[0]?.tasa_pobreza}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.tasa_pobreza, 1)} %"
        period="de la población, encuesta {renta_ccaa.slice(-1)[0]?.anio} · España {formatNumber(renta_ccaa.slice(-1)[0]?.pobreza_espana, 1)} % · puesto {renta_ccaa_puesto[0]?.puesto_pobreza} de {renta_ccaa_puesto[0]?.n} (1 = más pobreza)"
        direction="positive-down"
        source="INE / ECV"
        href="/sociedad/desigualdad"
        sparklineData={renta_ccaa.map(d => ({...d, y: d.tasa_pobreza}))}
    />
    <KpiCard
        title="Pobreza o exclusión (AROPE)"
        value={renta_ccaa.slice(-1)[0]?.arope}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.arope, 1)} %"
        period="encuesta {renta_ccaa.slice(-1)[0]?.anio} · España {formatNumber(renta_ccaa.slice(-1)[0]?.arope_espana, 1)} %"
        direction="positive-down"
        source="INE / ECV"
        href="/sociedad/desigualdad"
        sparklineData={renta_ccaa.filter(d => d.arope != null).map(d => ({...d, y: d.arope}))}
    />
</Grid>

<LineChart
    data={renta_ccaa}
    x=anio
    y={['tasa_pobreza', 'pobreza_espana']}
    seriesLabels={{tasa_pobreza: terr[0]?.nombre, pobreza_espana: 'España'}}
    colorPalette={['#b45309', '#94a3b8']}
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de la población"
    title="Tasa de riesgo de pobreza (año de la encuesta)"
/>

{#if renta_ccaa_municipios.length > 0}

Renta neta media por persona en los municipios de más de 20.000 habitantes (Atlas de Distribución de Renta, {renta_ccaa_municipios[0]?.anio}, euros de 2025).

<DataTable data={renta_ccaa_municipios} link=enlace rows=10 search=true>
    <Column id=municipio title="Municipio"/>
    <Column id=renta_persona_real title="Renta por persona (€)" fmt='#,##0'/>
    <Column id=renta_hogar_real title="Renta por hogar (€)" fmt='#,##0'/>
    <Column id=poblacion title="Habitantes" fmt='#,##0'/>
</DataTable>

{/if}

<p class="text-xs text-gray-500">Encuesta de Condiciones de Vida del INE: la renta es la del año anterior a la encuesta. Más en <a href="/sociedad/desigualdad">Renta, pobreza y desigualdad</a>.</p>

{/if}

```sql viv
SELECT r.*, e.euros_m2_real AS euros_m2_real_espana, e.alquiler_mes_mediana_real AS alquiler_espana,
       e.compraventas_12m_1000 AS compraventas_espana, e.anios_salario AS anios_salario_espana,
       strftime(r.mercado_fecha, '%m/%Y') AS mercado_mes
FROM mother.vivienda_resumen_territorios r
JOIN mother.vivienda_resumen_territorios e ON e.nivel = 'pais'
WHERE r.nivel = 'ccaa' AND r.cod = '${terr[0]?.cod}'
```

```sql viv_precio
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${terr[0]?.cod}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql viv_precio_ccaa
SELECT euros_m2_real FROM mother.vivienda_precio_tasado
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND euros_m2_real IS NOT NULL
ORDER BY fecha
```

```sql viv_alquiler
SELECT anio, alquiler_mes_mediana_real FROM mother.vivienda_alquiler
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND tipologia = 'Colectiva'
ORDER BY anio
```

```sql viv_mercado
SELECT fecha, compraventas_12m_1000 FROM mother.vivienda_mercado_mensual
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND compraventas_12m_1000 IS NOT NULL
ORDER BY fecha
```

```sql viv_esfuerzo
SELECT anio, anios_salario FROM mother.vivienda_esfuerzo
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql viv_provincias
SELECT nombre AS provincia, ruta, euros_m2_real, precio_interanual_real, alquiler_mes_mediana_real, compraventas_12m_1000, terminadas_1000
FROM mother.vivienda_resumen_territorios
WHERE nivel = 'provincia' AND cod_ccaa = '${terr[0]?.cod}'
ORDER BY euros_m2_real DESC
```

{#if viv.length > 0 && viv[0]?.euros_m2_real != null}

## Vivienda

<Grid cols=4>
    <KpiCard
        title="Precio de la vivienda"
        value={viv[0]?.euros_m2_real}
        formattedValue="{formatNumber(viv[0]?.euros_m2_real, 0)} €/m²"
        period="valor tasado, {viv[0]?.precio_periodo} · España: {formatNumber(viv[0]?.euros_m2_real_espana, 0)} €/m²"
        change={viv[0]?.precio_interanual_real?.toFixed(1)}
        changePeriod="real vs un año antes"
        source="Ministerio de Vivienda"
        href="/vivienda/precios"
        sparklineData={viv_precio_ccaa.map(d => ({...d, y: d.euros_m2_real}))}
    />
    <KpiCard
        title="Alquiler mediano de un piso"
        value={viv[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(viv[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="{viv[0]?.alquiler_anio} · España: {formatNumber(viv[0]?.alquiler_espana, 0)} €/mes"
        source="Ministerio de Vivienda (SERPAVI)"
        href="/vivienda/alquiler"
        sparklineData={viv_alquiler.map(d => ({...d, y: d.alquiler_mes_mediana_real}))}
    />
    <KpiCard
        title="Compraventas por 1.000 hab."
        value={viv[0]?.compraventas_12m_1000}
        formattedValue={formatNumber(viv[0]?.compraventas_12m_1000, 1)}
        period="12 meses hasta {viv[0]?.mercado_mes} · España: {formatNumber(viv[0]?.compraventas_espana, 1)}"
        source="INE / ETDP"
        href="/vivienda/compraventas"
        sparklineData={viv_mercado.map(d => ({...d, y: d.compraventas_12m_1000}))}
    />
    <KpiCard
        title="Años de salario para 90 m²"
        value={viv[0]?.anios_salario}
        formattedValue="{formatNumber(viv[0]?.anios_salario, 1)} años"
        period="{viv[0]?.esfuerzo_anio} · España: {formatNumber(viv[0]?.anios_salario_espana, 1)}"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        href="/vivienda/esfuerzo"
        sparklineData={viv_esfuerzo.map(d => ({...d, y: d.anios_salario}))}
    />
</Grid>

<LineChart
    data={viv_precio}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (euros de {viv[0]?.anio_base})"
    startingAtZero={false}
    title="Valor tasado de la vivienda descontada la inflación"
/>

{#if viv_provincias.length > 1}
<DataTable data={viv_provincias} link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=alquiler_mes_mediana_real title="Alquiler €/mes" fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Compraventas por 1.000 hab." fmt='0.0' />
    <Column id=terminadas_1000 title="Viviendas terminadas por 1.000 hab." fmt='0.00' />
</DataTable>
{/if}

<p class="text-xs text-gray-500">Precios y alquileres en euros de {viv[0]?.anio_base}. Más detalle en <a href="/vivienda">Vivienda</a>.</p>

{/if}

```sql pensiones_terr
SELECT
    CAST(p.anio AS INTEGER) AS anio, p.meses, p.pensiones,
    p.pension_media_jubilacion_real, p.pension_media_real,
    p.pensiones_por_1000_hab, p.pensiones_por_100_mayores, p.afiliados_por_pension,
    e.pension_media_jubilacion_real AS jub_espana, e.pensiones_por_1000_hab AS por_1000_espana,
    e.afiliados_por_pension AS ratio_espana, CAST(p.anio_euros AS INTEGER) AS anio_euros,
    (SELECT count(*) + 1 FROM mother.pensiones_territorio x
        WHERE x.nivel = p.nivel AND x.anio = p.anio AND x.pension_media_jubilacion_real > p.pension_media_jubilacion_real) AS puesto_pension,
    (SELECT count(*) FROM mother.pensiones_territorio x WHERE x.nivel = p.nivel AND x.anio = p.anio) AS n_territorios
FROM mother.pensiones_territorio p
JOIN mother.pensiones_territorio e ON e.nivel = 'pais' AND e.anio = p.anio
WHERE p.nivel = 'ccaa' AND p.cod = '${terr[0]?.cod}'
  AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
```

```sql pensiones_terr_serie
SELECT CAST(anio AS INTEGER) AS anio, pension_media_jubilacion_real, pensiones_por_1000_hab, afiliados_por_pension
FROM mother.pensiones_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND meses = 12
ORDER BY anio
```

{#if pensiones_terr.length > 0}

## Pensiones

<Grid cols=3>
    <KpiCard
        title="Pensión media de jubilación"
        value={pensiones_terr[0]?.pension_media_jubilacion_real}
        formattedValue="{formatNumber(pensiones_terr[0]?.pension_media_jubilacion_real, 0)} €/mes"
        period="{pensiones_terr[0]?.anio} (media de {pensiones_terr[0]?.meses} meses), euros de {pensiones_terr[0]?.anio_euros} · España: {formatNumber(pensiones_terr[0]?.jub_espana, 0)} € · puesto {pensiones_terr[0]?.puesto_pension} de {pensiones_terr[0]?.n_territorios}"
        source="Seguridad Social"
        sparklineData={pensiones_terr_serie.map(d => ({...d, y: d.pension_media_jubilacion_real}))}
    />
    <KpiCard
        title="Pensiones por 1.000 habitantes"
        value={pensiones_terr[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(pensiones_terr[0]?.pensiones_por_1000_hab, 0)}
        period="España: {formatNumber(pensiones_terr[0]?.por_1000_espana, 0)} · {formatNumber(pensiones_terr[0]?.pensiones_por_100_mayores, 0)} por cada 100 personas de 65+ · {formatNumber(pensiones_terr[0]?.pensiones, 0)} pensiones"
        source="Seguridad Social / INE"
        sparklineData={pensiones_terr_serie.map(d => ({...d, y: d.pensiones_por_1000_hab}))}
    />
    <KpiCard
        title="Afiliados por pensión"
        value={pensiones_terr[0]?.afiliados_por_pension}
        formattedValue={formatNumber(pensiones_terr[0]?.afiliados_por_pension, 2)}
        period="España: {formatNumber(pensiones_terr[0]?.ratio_espana, 2)} (datos por comunidad desde 2021)"
        source="Seguridad Social"
        sparklineData={pensiones_terr_serie.filter(d => d.afiliados_por_pension != null).map(d => ({...d, y: d.afiliados_por_pension}))}
    />
</Grid>

<p class="text-xs text-gray-500">Pensiones contributivas de la Seguridad Social. Importes brutos de cada una de las 14 pagas, descontada la inflación. Más en <a href="/cuentas-publicas/pensiones">Pensiones</a>.</p>

{/if}

```sql edu_ccaa
-- Indicadores educativos de la comunidad (último año disponible) frente a España y puesto entre las 19
WITH ult AS (
    SELECT indicador, cod, anio, valor
    FROM mother.educacion_indicadores
    WHERE nivel = 'ccaa' AND indicador IN ('abandono', 'superior_25_64', 'neet_15_29')
    QUALIFY row_number() OVER (PARTITION BY indicador, cod ORDER BY anio DESC) = 1
),
rk AS (
    SELECT *,
        rank() OVER (PARTITION BY indicador ORDER BY CASE WHEN indicador = 'superior_25_64' THEN -valor ELSE valor END) AS puesto,
        count(*) OVER (PARTITION BY indicador) AS n
    FROM ult
)
SELECT r.indicador, CAST(r.anio AS INTEGER) AS anio, r.valor, r.puesto, r.n, e.valor AS valor_espana
FROM rk r
LEFT JOIN mother.educacion_indicadores e ON e.nivel = 'pais' AND e.indicador = r.indicador AND e.anio = r.anio
WHERE r.cod = '${terr[0]?.cod}'
```

```sql edu_serie
SELECT c.anio, c.indicador, c.valor / 100 AS valor, e.valor / 100 AS valor_espana
FROM mother.educacion_indicadores c
JOIN mother.educacion_indicadores e ON e.nivel = 'pais' AND e.indicador = c.indicador AND e.anio = c.anio
WHERE c.nivel = 'ccaa' AND c.cod = '${terr[0]?.cod}' AND c.indicador IN ('abandono', 'superior_25_64', 'neet_15_29')
ORDER BY c.anio
```

{#if edu_ccaa.length > 0}

## Educación

<Grid cols=3>
    <KpiCard
        title="Abandono escolar temprano"
        value={edu_ccaa.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="de 18-24 años en {edu_ccaa.find(d => d.indicador === 'abandono')?.anio} · España: {formatNumber(edu_ccaa.find(d => d.indicador === 'abandono')?.valor_espana, 1)} % · puesto {edu_ccaa.find(d => d.indicador === 'abandono')?.puesto} de {edu_ccaa.find(d => d.indicador === 'abandono')?.n} (1 = menor)"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'abandono').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Adultos con estudios superiores"
        value={edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="de 25-64 años en {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.anio} · España: {formatNumber(edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor_espana, 1)} % · puesto {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.puesto} de {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.n}"
        direction="positive-up"
        source="Eurostat / EPA"
        href="/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'superior_25_64').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Jóvenes que ni estudian ni trabajan"
        value={edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="de 15-29 años en {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.anio} · España: {formatNumber(edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor_espana, 1)} % · puesto {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.puesto} de {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.n} (1 = menor)"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'neet_15_29').map(d => ({...d, y: d.valor}))}
    />
</Grid>

<LineChart
    data={edu_serie.filter(d => d.indicador === 'abandono')}
    x=anio
    y={['valor', 'valor_espana']}
    yFmt=pct0
    xFmt="####"
    seriesLabels={{valor: terr[0]?.nombre, valor_espana: 'España'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Abandono temprano de la educación y la formación (% de 18-24 años)"
/>

<p class="text-xs text-gray-500">EPA armonizada por Eurostat (regiones NUTS 2). Las cifras regionales salen de muestras pequeñas y oscilan de un año a otro, sobre todo en Ceuta y Melilla. Detalle y comparación con la UE en <a href="/sociedad/educacion">Educación</a>.</p>

{/if}

```sql tur_ccaa
SELECT
    c.anio, c.pernoct_1000hab, c.ocupacion_hotel, c.pct_extranjeros_hotel, c.pernoct_hotel, c.pernoct_apart,
    c.turistas, c.turistas_por_hab, c.gasto_real_por_hab, c.anio_base,
    e.pernoct_1000hab AS pernoct_1000hab_espana,
    e.ocupacion_hotel AS ocupacion_hotel_espana,
    e.turistas_por_hab AS turistas_por_hab_espana
FROM mother.turismo_ccaa c
JOIN mother.turismo_ccaa e ON e.cod_ccaa = '00' AND e.anio = c.anio
WHERE c.cod_ccaa = '${terr[0]?.cod}' AND c.meses_hotel = 12 AND c.anio >= 2000
ORDER BY c.anio
```

```sql tur_ccaa_estacional
SELECT
    m.mes_num,
    ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][CAST(m.mes_num AS INTEGER)] AS mes_nombre,
    m.pernoct_1000hab,
    e.pernoct_1000hab AS pernoct_1000hab_espana,
    CAST(m.anio AS INTEGER) AS anio
FROM mother.turismo_ccaa_mensual m
JOIN mother.turismo_ccaa_mensual e ON e.cod_ccaa = '00' AND e.mes = m.mes
WHERE m.cod_ccaa = '${terr[0]?.cod}'
  AND m.anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_hotel = 12)
ORDER BY m.mes_num
```

```sql tur_vut_ccaa
SELECT
    v.periodo, v.viviendas, v.pct_viviendas, v.viviendas_1000hab, v.var_interanual,
    e.pct_viviendas AS pct_viviendas_espana,
    e.viviendas_1000hab AS viviendas_1000hab_espana,
    ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(month(v.periodo) AS INTEGER)] || ' de ' || CAST(v.anio AS INTEGER) AS periodo_txt
FROM mother.turismo_viviendas v
JOIN mother.turismo_viviendas e ON e.nivel = 'pais' AND e.periodo = v.periodo
WHERE v.nivel = 'ccaa' AND v.cod = '${terr[0]?.cod}'
ORDER BY v.periodo
```

```sql tur_vut_mun_ccaa
SELECT v.municipio, v.poblacion, v.viviendas, v.pct_viviendas / 100 AS pct, v.viviendas_1000hab
FROM mother.turismo_viviendas_municipios v
WHERE v.cod_ccaa = '${terr[0]?.cod}'
  AND v.periodo = (SELECT max(periodo) FROM mother.turismo_viviendas_municipios)
  AND v.poblacion >= 1000
ORDER BY v.pct_viviendas DESC
LIMIT 10
```

{#if tur_ccaa.length > 0}

## Turismo

<Grid cols=3>
    <KpiCard
        title="Pernoctaciones turísticas"
        value={tur_ccaa.slice(-1)[0]?.pernoct_1000hab}
        formattedValue="{formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_1000hab, 0)} por 1.000 hab."
        period="en hoteles y apartamentos turísticos en {tur_ccaa.slice(-1)[0]?.anio} · España: {formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_1000hab_espana, 0)}"
        source="INE / EOH, EOAP"
        href="/economia/turismo"
        sparklineData={tur_ccaa.map(d => ({anio: d.anio, valor: d.pernoct_1000hab}))}
    />
    <KpiCard
        title="Ocupación hotelera"
        value={tur_ccaa.slice(-1)[0]?.ocupacion_hotel}
        formattedValue="{formatNumber(tur_ccaa.slice(-1)[0]?.ocupacion_hotel, 1)} %"
        period="de las plazas, media de {tur_ccaa.slice(-1)[0]?.anio} · España: {formatNumber(tur_ccaa.slice(-1)[0]?.ocupacion_hotel_espana, 1)} %"
        source="INE / EOH"
        sparklineData={tur_ccaa.filter(d => d.ocupacion_hotel != null).map(d => ({anio: d.anio, valor: d.ocupacion_hotel}))}
    />
    {#if tur_vut_ccaa.length > 0}
    <KpiCard
        title="Viviendas turísticas"
        value={tur_vut_ccaa.slice(-1)[0]?.pct_viviendas}
        formattedValue="{formatNumber(tur_vut_ccaa.slice(-1)[0]?.pct_viviendas, 2)} % de las viviendas"
        period="{formatNumber(tur_vut_ccaa.slice(-1)[0]?.viviendas_1000hab, 1)} por 1.000 hab. en {tur_vut_ccaa.slice(-1)[0]?.periodo_txt} · España: {formatNumber(tur_vut_ccaa.slice(-1)[0]?.pct_viviendas_espana, 2)} %"
        source="INE (experimental)"
        sparklineData={tur_vut_ccaa.map(d => ({x: d.periodo, y: d.pct_viviendas}))}
    />
    {/if}
</Grid>

<LineChart
    data={tur_ccaa}
    x=anio
    y={['pernoct_1000hab', 'pernoct_1000hab_espana']}
    yFmt=num0
    xFmt="####"
    seriesLabels={{pernoct_1000hab: terr[0]?.nombre, pernoct_1000hab_espana: 'España'}}
    colorPalette={['#0f766e', '#94a3b8']}
    legend=true
    yAxisTitle="por 1.000 habitantes"
    title="Pernoctaciones en hoteles y apartamentos turísticos por 1.000 habitantes"
/>

<BarChart
    data={tur_ccaa_estacional}
    x=mes_nombre
    y={['pernoct_1000hab', 'pernoct_1000hab_espana']}
    type=grouped
    sort=false
    yFmt=num0
    seriesLabels={{pernoct_1000hab: terr[0]?.nombre, pernoct_1000hab_espana: 'España'}}
    colorPalette={['#0f766e', '#94a3b8']}
    title="Estacionalidad: pernoctaciones por 1.000 habitantes en cada mes de {tur_ccaa_estacional[0]?.anio}"
/>

<p class="text-xs text-gray-500">{formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_hotel, 0)} noches de hotel en {tur_ccaa.slice(-1)[0]?.anio}, el {formatNumber(tur_ccaa.slice(-1)[0]?.pct_extranjeros_hotel, 1)} % de viajeros residentes en el extranjero (Coyuntura Turística Hotelera y Encuesta de Ocupación en Apartamentos Turísticos del INE; no incluyen viviendas turísticas).{#if tur_ccaa.slice(-1)[0]?.turistas_por_hab != null} Llegaron {formatNumber(tur_ccaa.slice(-1)[0]?.turistas_por_hab, 1)} turistas internacionales por habitante (España: {formatNumber(tur_ccaa.slice(-1)[0]?.turistas_por_hab_espana, 1)}), que gastaron {formatNumber(tur_ccaa.slice(-1)[0]?.gasto_real_por_hab, 0)} € por habitante en euros de {tur_ccaa.slice(-1)[0]?.anio_base} (FRONTUR y EGATUR).{/if} Más detalle en <a href="/economia/turismo">Turismo</a>.</p>

{#if tur_vut_mun_ccaa.length > 0}

<BarChart
    data={tur_vut_mun_ccaa}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#a21caf"
    title="Municipios con más viviendas turísticas (% del total de viviendas; municipios de 1.000 hab. o más)"
/>

{/if}

{/if}

```sql empresas_ccaa
SELECT
    e.empresas,
    e.empresas_1000hab,
    es.empresas_1000hab AS empresas_1000hab_espana,
    CAST(e.anio AS INTEGER) AS anio,
    (SELECT count(*) + 1 FROM mother.empresas_dirce_territorio o
      WHERE o.nivel = 'ccaa' AND o.anio = e.anio AND o.empresas_1000hab > e.empresas_1000hab) AS puesto
FROM mother.empresas_dirce_territorio e
JOIN mother.empresas_dirce_territorio es ON es.nivel = 'pais' AND es.anio = e.anio
WHERE e.nivel = 'ccaa' AND e.cod = '${terr[0]?.cod}'
  AND e.anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)
```

```sql empresas_ccaa_serie
SELECT CAST(e.anio AS INTEGER) AS anio, e.empresas_1000hab AS valor, es.empresas_1000hab AS valor_espana
FROM mother.empresas_dirce_territorio e
JOIN mother.empresas_dirce_territorio es ON es.nivel = 'pais' AND es.anio = e.anio
WHERE e.nivel = 'ccaa' AND e.cod = '${terr[0]?.cod}'
ORDER BY e.anio
```

```sql empresas_soc
SELECT
    s.constituidas_100k,
    s.disueltas_100k,
    es.constituidas_100k AS constituidas_100k_espana,
    s.constituidas,
    CAST(s.anio AS INTEGER) AS anio
FROM mother.empresas_sociedades_anual s
JOIN mother.empresas_sociedades_anual es ON es.cod = '00' AND es.anio = s.anio
WHERE s.cod = '${terr[0]?.cod}'
  AND s.anio = (SELECT max(anio) FROM mother.empresas_sociedades_anual)
```

```sql empresas_soc_serie
SELECT CAST(anio AS INTEGER) AS anio, constituidas_100k AS valor
FROM mother.empresas_sociedades_anual
WHERE cod = '${terr[0]?.cod}' AND constituidas_100k IS NOT NULL
ORDER BY anio
```

```sql empresas_aut
SELECT a.pct_cuenta_propia, es.pct_cuenta_propia AS pct_espana, CAST(a.anio AS INTEGER) AS anio
FROM mother.empresas_autonomos_anual a
JOIN mother.empresas_autonomos_anual es ON es.cod = '00' AND es.anio = a.anio
WHERE a.cod = '${terr[0]?.cod}'
ORDER BY a.anio
```

```sql empresas_id
SELECT i.pct_pib, i.eur_hab_real, i.investigadores_1000ocup, es.pct_pib AS pct_pib_espana,
    CAST(i.anio AS INTEGER) AS anio, CAST(i.anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_id_ccaa i
JOIN mother.empresas_id_ccaa es ON es.cod = '00' AND es.anio = i.anio AND es.sector = 'Total'
WHERE i.cod = '${terr[0]?.cod}' AND i.sector = 'Total' AND i.pct_pib IS NOT NULL
ORDER BY i.anio
```

{#if empresas_ccaa.length > 0}

## Empresas

<Grid cols=4>
    <KpiCard
        title="Empresas por 1.000 habitantes"
        value={empresas_ccaa[0]?.empresas_1000hab}
        formattedValue={formatNumber(empresas_ccaa[0]?.empresas_1000hab, 1)}
        period="España: {formatNumber(empresas_ccaa[0]?.empresas_1000hab_espana, 1)} · puesto {empresas_ccaa[0]?.puesto} de 19 · {formatNumber(empresas_ccaa[0]?.empresas, 0)} empresas a 1 de enero de {empresas_ccaa[0]?.anio}"
        source="INE / DIRCE"
        sparklineData={empresas_ccaa_serie.map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Sociedades creadas por 100.000 hab."
        value={empresas_soc[0]?.constituidas_100k}
        formattedValue={formatNumber(empresas_soc[0]?.constituidas_100k, 0)}
        period="en {empresas_soc[0]?.anio} · España: {formatNumber(empresas_soc[0]?.constituidas_100k_espana, 0)} · disueltas: {formatNumber(empresas_soc[0]?.disueltas_100k, 0)}"
        source="INE / Sociedades Mercantiles"
        sparklineData={empresas_soc_serie.map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Autónomos"
        value={empresas_aut.slice(-1)[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(empresas_aut.slice(-1)[0]?.pct_cuenta_propia, 1)} %"
        period="de los ocupados trabajan por cuenta propia ({empresas_aut.slice(-1)[0]?.anio}) · España: {formatNumber(empresas_aut.slice(-1)[0]?.pct_espana, 1)} %"
        source="INE / EPA"
        sparklineData={empresas_aut.map(d => ({...d, y: d.pct_cuenta_propia}))}
    />
    <KpiCard
        title="Gasto en I+D"
        value={empresas_id.slice(-1)[0]?.pct_pib}
        formattedValue="{formatNumber(empresas_id.slice(-1)[0]?.pct_pib, 2)} % del PIB"
        period="en {empresas_id.slice(-1)[0]?.anio} · España: {formatNumber(empresas_id.slice(-1)[0]?.pct_pib_espana, 2)} % · {formatNumber(empresas_id.slice(-1)[0]?.eur_hab_real, 0)} € por hab. (euros de {empresas_id.slice(-1)[0]?.anio_euros})"
        source="Eurostat / INE"
        sparklineData={empresas_id.map(d => ({...d, y: d.pct_pib}))}
    />
</Grid>

<LineChart
    data={empresas_ccaa_serie}
    x=anio
    y={['valor', 'valor_espana']}
    xFmt='0'
    yFmt='0.0'
    seriesLabels={{valor: terr[0]?.nombre, valor_espana: 'España'}}
    colorPalette={['#1d4ed8', '#94a3b8']}
    startingAtZero={false}
    yAxisTitle="por 1.000 habitantes"
    title="Empresas activas por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">Empresas activas a 1 de enero según el Directorio Central de Empresas, incluidos los autónomos, contadas en la comunidad de su sede. En 2023 el INE pasó a contar solo las empresas económicamente activas, lo que explica la caída de ese año. Más datos en <a href="/economia/empresas">Empresas, emprendimiento e I+D</a>.</p>

{/if}

```sql san_espera
SELECT l.fecha, l.tipo, l.tasa_1000, l.dias_medio, l.pct_espera_larga,
    CASE WHEN l.corte = 'junio' THEN '30 de junio de ' ELSE '31 de diciembre de ' END || CAST(l.anio AS INTEGER) AS fecha_txt,
    e.dias_medio AS dias_espana, e.tasa_1000 AS tasa_espana, e.pct_espera_larga AS pct_espana
FROM mother.sanidad_listas_espera l
LEFT JOIN mother.sanidad_listas_espera e ON e.nivel = 'pais' AND e.fecha = l.fecha AND e.tipo = l.tipo
WHERE l.nivel = 'ccaa' AND l.cod = '${terr[0]?.cod}'
ORDER BY l.fecha
```

```sql san_espera_dias
SELECT fecha, 'Operación · ' || '${terr[0]?.nombre}' AS serie, dias_medio FROM ${san_espera} WHERE tipo = 'quirurgica'
UNION ALL
SELECT fecha, 'Operación · España', dias_espana FROM ${san_espera} WHERE tipo = 'quirurgica'
UNION ALL
SELECT fecha, 'Especialista · ' || '${terr[0]?.nombre}', dias_medio FROM ${san_espera} WHERE tipo = 'consultas'
UNION ALL
SELECT fecha, 'Especialista · España', dias_espana FROM ${san_espera} WHERE tipo = 'consultas'
ORDER BY fecha
```

```sql san_espera_puesto
-- Puesto de la comunidad por espera media para operarse (1 = la que menos espera) en el último corte
WITH u AS (
    SELECT cod, dias_medio FROM mother.sanidad_listas_espera
    WHERE nivel = 'ccaa' AND tipo = 'quirurgica' AND fecha = (SELECT max(fecha) FROM mother.sanidad_listas_espera)
)
SELECT count(*) FILTER (WHERE dias_medio < (SELECT dias_medio FROM u WHERE cod = '${terr[0]?.cod}')) + 1 AS puesto, count(*) AS n
FROM u
```

```sql san_recursos
SELECT r.anio, r.recurso, r.por_1000, e.por_1000 AS por_1000_espana
FROM mother.sanidad_recursos_ccaa r
LEFT JOIN mother.sanidad_recursos_ccaa e ON e.nivel = 'pais' AND e.anio = r.anio AND e.recurso = r.recurso
WHERE r.nivel = 'ccaa' AND r.cod = '${terr[0]?.cod}'
ORDER BY r.anio
```

```sql san_gasto
SELECT g.anio, g.eur_hab_real, g.pct_pib, g.provisional, t.eur_hab_real AS eur_hab_real_ccaa
FROM mother.sanidad_gasto_ccaa g
LEFT JOIN mother.sanidad_gasto_ccaa t ON t.nivel = 'total_ccaa' AND t.anio = g.anio
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}'
ORDER BY g.anio
```

```sql san_gasto_serie
SELECT anio, '${terr[0]?.nombre}' AS serie, eur_hab_real FROM ${san_gasto}
UNION ALL
SELECT anio, 'Conjunto de las comunidades', eur_hab_real_ccaa FROM ${san_gasto}
ORDER BY anio
```

## Sanidad

{#if san_espera.length > 0}

<Grid cols=4>
    <KpiCard
        title="Espera media para operarse"
        value={san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_medio}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_medio, 0)} días"
        period="España: {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_espana, 0)} · puesto {san_espera_puesto[0]?.puesto} de {san_espera_puesto[0]?.n} (1 = menor espera) · {san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.fecha_txt}"
        direction="positive-down"
        source="Ministerio de Sanidad (SISLE)"
        href="/sociedad/salud#listas-de-espera"
        sparklineData={san_espera.filter(d => d.tipo === 'quirurgica').map(d => ({...d, valor: d.dias_medio}))}
    />
    <KpiCard
        title="Lista de espera quirúrgica"
        value={san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_1000}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_1000, 1)} por 1.000 hab."
        period="España: {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_espana, 1)} · {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.pct_espera_larga, 1)} % lleva más de 6 meses"
        direction="positive-down"
        source="Ministerio de Sanidad (SISLE)"
        sparklineData={san_espera.filter(d => d.tipo === 'quirurgica').map(d => ({...d, valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Espera media para el especialista"
        value={san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_medio}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_medio, 0)} días"
        period="España: {formatNumber(san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_espana, 0)} · primera consulta"
        direction="positive-down"
        source="Ministerio de Sanidad (SISLE)"
        sparklineData={san_espera.filter(d => d.tipo === 'consultas').map(d => ({...d, valor: d.dias_medio}))}
    />
    {#if san_gasto.length > 0}
    <KpiCard
        title="Gasto sanitario público"
        value={san_gasto.slice(-1)[0]?.eur_hab_real}
        formattedValue="{formatNumber(san_gasto.slice(-1)[0]?.eur_hab_real, 0)} € por hab."
        period="conjunto de las comunidades: {formatNumber(san_gasto.slice(-1)[0]?.eur_hab_real_ccaa, 0)} € · {san_gasto.slice(-1)[0]?.anio}{san_gasto.slice(-1)[0]?.provisional ? ' (provisional)' : ''} · euros de {base[0]?.anio_base}"
        source="Ministerio de Sanidad (EGSP)"
        sparklineData={san_gasto.map(d => ({...d, valor: d.eur_hab_real}))}
    />
    {:else if san_recursos.some(d => d.recurso === 'medicos' && d.por_1000 != null)}
    <KpiCard
        title="Médicos"
        value={san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000}
        formattedValue="{formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000, 1)} por 1.000 hab."
        period="España: {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000_espana, 1)} · {san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={san_recursos.filter(d => d.recurso === 'medicos').map(d => ({...d, valor: d.por_1000}))}
    />
    {/if}
</Grid>

<Grid cols=2>
    <LineChart
        data={san_espera_dias}
        x=fecha
        y=dias_medio
        series=serie
        yFmt=num0
        legend=true
        colorPalette={['#0f766e', '#99f6e4', '#7c3aed', '#ddd6fe']}
        yAxisTitle="días"
        title="Tiempo medio de espera en la sanidad pública"
    />
    {#if san_gasto.length > 0}
    <LineChart
        data={san_gasto_serie}
        x=anio
        y=eur_hab_real
        series=serie
        xFmt="####"
        yFmt='#,##0" €"'
        legend=true
        colorPalette={['#0f766e', '#94a3b8']}
        yAxisTitle="euros por habitante"
        title="Gasto sanitario público por habitante (euros de {base[0]?.anio_base})"
    />
    {/if}
</Grid>

{#if san_recursos.some(d => d.recurso === 'medicos' && d.por_1000 != null)}
<p class="text-sm">
{terr[0]?.nombre} tiene {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000, 1)} médicos y {formatNumber(san_recursos.filter(d => d.recurso === 'camas').slice(-1)[0]?.por_1000, 1)} camas de hospital por 1.000 habitantes (España: {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000_espana, 1)} y {formatNumber(san_recursos.filter(d => d.recurso === 'camas').slice(-1)[0]?.por_1000_espana, 1)}; Eurostat, {san_recursos.slice(-1)[0]?.anio}). <a href="/sociedad/salud#sistema-sanitario">Ver el sistema sanitario de España</a>.
</p>
{/if}

<p class="text-xs text-gray-500">Listas de espera del SNS (SISLE-SNS): cada comunidad aporta sus datos con sus propios criterios de cómputo, así que las comparaciones entre comunidades son orientativas. Gasto sanitario público: gasto del servicio de salud de la comunidad (Estadística de Gasto Sanitario Público), descontada la inflación.</p>

{/if}

```sql elec
SELECT p.proceso, p.fecha, strftime(p.fecha, '%-d/%-m/%Y') AS fecha_txt,
    p.participacion, p.participacion AS valor, p.ganador_siglas, p.ganador_pct,
    p.segundo_siglas, p.segundo_pct, p.nep_votos, p.escanos, e.participacion AS participacion_espana
FROM mother.elecciones_participacion p
JOIN mother.elecciones_participacion e ON e.proceso = p.proceso AND e.nivel = 'pais'
WHERE p.nivel = 'ccaa' AND p.cod = '${terr[0]?.cod}' AND p.tipo = '02'
ORDER BY p.fecha
```

```sql elec_part
SELECT fecha, '${terr[0]?.nombre}' AS ambito, participacion FROM ${elec}
UNION ALL
SELECT fecha, 'España' AS ambito, participacion_espana FROM ${elec}
ORDER BY fecha
```

```sql elec_familias
SELECT f.fecha, f.familia, f.color, f.orden_familia, f.pct, f.escanos
FROM mother.elecciones_familias f
WHERE f.nivel = 'ccaa' AND f.cod = '${terr[0]?.cod}' AND f.tipo = '02'
  AND f.familia IN (SELECT familia FROM mother.elecciones_familias
      WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND tipo = '02' AND bloque <> 'Otros'
      GROUP BY familia HAVING max(pct) >= 5)
ORDER BY f.fecha, f.orden_familia
```

```sql elec_colores
SELECT DISTINCT familia, color, orden_familia FROM ${elec_familias} ORDER BY orden_familia
```

{#if elec.length > 0}

## Elecciones

<Grid cols=3>
    <KpiCard title="Participación en las generales" value={elec.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec.slice(-1)[0]?.participacion, 1)} %"
        period="{elec.slice(-1)[0]?.fecha_txt} · España: {formatNumber(elec.slice(-1)[0]?.participacion_espana, 1)} %"
        source="Ministerio del Interior" href="/sociedad/elecciones" sparklineData={elec} />
    <KpiCard title="Candidatura más votada" value={elec.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec.slice(-1)[0]?.ganador_pct, 1)} %"
        period="segunda: {elec.slice(-1)[0]?.segundo_siglas} ({formatNumber(elec.slice(-1)[0]?.segundo_pct, 1)} %) · {formatNumber(elec.slice(-1)[0]?.escanos, 0)} escaños en juego"
        source="Ministerio del Interior" sparklineData={elec.map(d => ({...d, valor: d.ganador_pct}))} />
    <KpiCard title="Número efectivo de partidos" value={elec.slice(-1)[0]?.nep_votos}
        formattedValue={formatNumber(elec.slice(-1)[0]?.nep_votos, 1)} period="en votos, últimas generales"
        source="Cálculo propio" sparklineData={elec.map(d => ({...d, valor: d.nep_votos}))} />
</Grid>

<LineChart data={elec_familias} x=fecha y=pct series=familia yFmt='0.0"%"' markers=true
    seriesColors={Object.fromEntries(elec_colores.map(d => [d.familia, d.color]))}
    title="Voto en las generales por familia política, % de los votos válidos" />

<LineChart data={elec_part} x=fecha y=participacion series=ambito yFmt='0.0"%"' markers=true
    seriesColors={{'España': '#94a3b8'}} title="Participación en las generales, %" />

{/if}

## Fuentes oficiales

- **[Seguridad Social – Pensiones contributivas en vigor por CCAA y provincia](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24)**
- **INE**: [EPA](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76140), [Encuesta de Condiciones de Vida](https://www.ine.es/jaxiT3/Tabla.htm?t=9963), [Atlas de Distribución de Renta](https://www.ine.es/jaxiT3/Tabla.htm?t=30824), [Movimiento Natural de la Población](https://www.ine.es/jaxiT3/Tabla.htm?t=6524), [Coyuntura Turística Hotelera](https://www.ine.es/jaxiT3/Tabla.htm?t=2074); **SEPE**: paro registrado; **Ministerio de Vivienda**: valor tasado y SERPAVI; **Eurostat**: indicadores educativos por región (NUTS 2).
- **[INE – Cifras oficiales de población de los municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministerio de Hacienda – Liquidación de los presupuestos de las CCAA](https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx)**: datos consolidados; el gasto por políticas está depurado de la participación de las entidades locales en los tributos y de los fondos de la PAC, que solo transitan por las cuentas autonómicas.
- **[Banco de España – Boletín Estadístico, capítulo 13](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: deuda según el Protocolo de Déficit Excesivo y capacidad/necesidad de financiación de las comunidades autónomas.
- **[Registro Central de Personal – Boletín Estadístico del Personal al Servicio de las AAPP](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**: empleados públicos por administración y provincia del puesto; **[INE – Encuesta de Estructura Salarial 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: salarios públicos y privados.
- **[Instituto Geográfico Nacional (vía es-atlas)](https://github.com/martgnz/es-atlas)**: límites municipales (CC BY 4.0).

{:else}
<p role="status" class="my-8 text-sm text-gray-600 dark:text-gray-400">Actualizando los datos territoriales…</p>
{/if}

<LastRefreshed prefix="Datos actualizados" />
