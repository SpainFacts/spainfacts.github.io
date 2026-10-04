---
description: "Autonomous community profile: population, economy, public accounts, debt, public employment, crime and more, with official data compared with Spain as a whole."
i18n_origen: b9c51634f0cb
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'"
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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
    t.cod, t.nombre, '/en' || t.ruta AS ruta, t.poblacion_ultima AS poblacion,
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
    '/en/territorios/municipios?m=' || a.cod_mun AS enlace
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

# {terr[0]?.nombre}

<p class="text-sm text-gray-500"><a href="/en/territorios">Regions</a> › {terr[0]?.nombre}</p>

<Grid cols=3>
    <KpiCard
        title="Population"
        value={terr[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima, 0)}
        unit="people"
        period="1 January {terr[0]?.anio_poblacion}"
        source="INE – Municipal Register"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Share of Spain"
        value={100 * terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima / 0.01, 1)}
        unit="%"
        period="of Spain's population"
        sparklineData={peso_serie}
    />
    <KpiCard
        title="Municipalities"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} with fewer than 1,000 inhabitants · {formatNumber(resumen_municipios[0]?.pierden, 0)} lost population over 10 years"
    />
</Grid>

## Population

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Population on 1 January (Municipal Register)"
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

## Births and ageing

<Grid cols=4>
    <KpiCard
        title="Birth rate"
        value={demo_anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(demo_anual.slice(-1)[0]?.tasa_natalidad, 1)} per 1,000 inhabitants"
        period="{formatNumber(demo_anual.slice(-1)[0]?.nacimientos, 0)} births in {demo_anual.slice(-1)[0]?.anio} · Spain: {formatNumber(demo_espana[0]?.tasa_natalidad, 1)}"
        source="INE"
        href="/en/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Children per woman"
        value={demo_anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(demo_anual.slice(-1)[0]?.fecundidad, 2)}
        period="{demo_anual.slice(-1)[0]?.anio} · Spain: {formatNumber(demo_espana[0]?.fecundidad, 2)}"
        source="INE"
        href="/en/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Aged 65 and over"
        value={demo_edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.pct_65, 1)}%"
        period="of the population in {demo_edades.slice(-1)[0]?.anio} · Spain: {formatNumber(demo_espana[0]?.pct_65, 1)}%"
        source="INE"
        href="/en/demografia/estructura-edades"
        sparklineData={demo_edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Average age"
        value={demo_edades.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.edad_media, 1)} years"
        period="{demo_edades.slice(-1)[0]?.anio} · Spain: {formatNumber(demo_espana[0]?.edad_media, 1)} years"
        source="INE"
        href="/en/demografia/estructura-edades"
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
        title="Population pyramid, {demo_edades.slice(-1)[0]?.anio} (% of total)"
    />
    <LineChart
        data={demo_tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="per 1,000 inhabitants"
        title="Births and deaths per 1,000 inhabitants"
    />
</Grid>

<p class="text-xs text-gray-500">In {demo_anual.slice(-1)[0]?.anio} the population of {terr[0]?.nombre} changed by {formatNumber(demo_anual.slice(-1)[0]?.crecimiento_1000, 1)} per 1,000 inhabitants: {formatNumber(demo_anual.slice(-1)[0]?.vegetativo_1000, 1)} from births minus deaths and {formatNumber(demo_anual.slice(-1)[0]?.resto_1000, 1)} from migration (from abroad and from other communities) and adjustments. {formatNumber(demo_edades.slice(-1)[0]?.pct_nacidos_extranjero, 1)}% of its inhabitants were born abroad. Source: INE (Vital Statistics, Basic Demographic Indicators and Continuous Population Statistics).</p>

{#if provincias.length > 1}

## Provinces

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 not-prose">
{#each provincias as p}
    <a href={p.ruta} class="block rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-3 hover:border-blue-400 no-underline">
        <span class="font-semibold text-gray-900 dark:text-white">{p.nombre}</span>
        <span class="block text-xs text-gray-500">{formatNumber(p.poblacion, 0)} inhabitants · {p.municipios} municipalities</span>
    </a>
{/each}
</div>

{:else}

<p>{terr[0]?.nombre} is a single-province community. <a href={provincias[0]?.ruta}>See the provincial profile of {provincias[0]?.nombre}</a>.</p>

{/if}

## Municipalities

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Boundaries © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Population', fmt: 'num0'},
        {id: 'crecimiento', title: '10-year growth (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">The colour scale saturates at the most populous 10% of municipalities so that smaller ones can be told apart.</p>

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Population" fmt=num0 />
    <Column id=crecimiento title="10-year growth (%)" fmt=num1 contentType=delta />
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

## Community revenue and spending

Executed accounts (budget outturn) of the consolidated regional administration. **Non-financial** spending (chapters 1 to 7) is used, which leaves out asset purchases and debt repayment, to compare what each community really spends on services. All amounts are **per person** and **adjusted for inflation**, in {base[0]?.anio_base} euros: that way the trend does not rise just because there are more people or prices go up.

<Grid cols=3>
    <KpiCard
        title="Non-financial spending per person"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="Outturn {cuentas_ultimo[0]?.anio}, in {base[0]?.anio_base} euros · total: €{formatCompact(cuentas_ultimo[0]?.gastos_no_financieros, 0)} in current euros"
        source="Ministry of Finance"
        sparklineData={cuentas.filter(d => d.gasto_hab_real != null).map(d => ({anio: d.anio, valor: d.gasto_hab_real}))}
    />
    <KpiCard
        title="Non-financial revenue per person"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="In {base[0]?.anio_base} euros · total: €{formatCompact(cuentas_ultimo[0]?.ingresos_no_financieros, 0)} in current euros"
        sparklineData={cuentas.filter(d => d.ingreso_hab_real != null).map(d => ({anio: d.anio, valor: d.ingreso_hab_real}))}
    />
    <KpiCard
        title="Non-financial balance per person"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Non-financial revenue − spending, in {base[0]?.anio_base} euros · total: €{formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 0)} in current euros"
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
    title="Non-financial spending per person in {cuentas_ultimo[0]?.anio} ({base[0]?.anio_base} euros)"
    colorPalette={['#0f766e', '#cbd5e1']}
    sort=false
/>

### What does it spend on?

<BarChart
    data={politicas_grafico}
    x=politica
    y=euros
    series=serie
    type=grouped
    swapXY=true
    yFmt=num0
    title="Euros per person on each policy ({base[0]?.anio_base} euros; those accounting for at least 2%)"
    colorPalette={['#0f766e', '#94a3b8']}
/>

<DataTable data={politicas} rows=all>
    <Column id=politica title="Spending policy" />
    <Column id=por_habitante title="€ per person ({base[0]?.anio_base} euros)" fmt=num0 />
    <Column id=media_ccaa title="Communities' average (€ per person)" fmt=num0 />
    <Column id=dif_pct title="Difference (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Share" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=obligaciones title="Total spending (current €)" fmt=num0 />
</DataTable>

### Trend

<LineChart
    data={cuentas_evolucion}
    x=fecha
    y=importe
    series=concepto
    yFmt=num0
    yAxisTitle="€ per person"
    title="Non-financial revenue and spending per person ({base[0]?.anio_base} euros, adjusted for inflation)"
    colorPalette={['#0f766e', '#b45309']}
/>

<Details title="Breakdown by chapter for the latest year">

<DataTable data={capitulos} rows=all groupBy=tipo>
    <Column id=capitulo title="Ch." />
    <Column id=capitulo_nombre title="Chapter" />
    <Column id=ejecutado_hab title="Executed per person ({base[0]?.anio_base} euros)" fmt=num0 />
    <Column id=presupuesto_definitivo title="Final budget (€)" fmt=num0 />
    <Column id=ejecutado title="Executed (€)" fmt=num0 />
    <Column id=grado_ejecucion title="Execution rate" fmt=pct0 />
</DataTable>

</Details>

{:else}

<p class="text-sm text-gray-500">The Ministry of Finance only publishes the outturn for {terr[0]?.nombre} up to 2012, so the comparison with other communities is not shown.</p>

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

## Debt and deficit

<Grid cols=3>
    <KpiCard
        title="Public debt per person"
        value={deuda_ultima[0]?.deuda_hab_real}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_hab_real, 0)}
        unit="€"
        period="Q{deuda_ultima[0]?.trimestre} {deuda_ultima[0]?.anio}, in {base[0]?.anio_base} euros · total: €{formatCompact(deuda_ultima[0]?.deuda_eur, 0)} in current euros"
        source="Banco de España (EDP)"
        sparklineData={deuda_hab_serie}
    />
    <KpiCard
        title="Debt as % of regional GDP"
        value={deuda_ultima[0]?.deuda_pct_pib}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_pct_pib, 1)}
        unit="%"
        change={deuda_ultima[0]?.pct_pib_hace_un_anio != null ? (deuda_ultima[0].deuda_pct_pib - deuda_ultima[0].pct_pib_hace_un_anio).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. a year ago"
        direction="positive-down"
        sparklineData={deuda.filter(d => d.deuda_pct_pib != null).slice(-40).map(d => ({fecha: d.fecha, valor: d.deuda_pct_pib}))}
    />
    {#if saldo.length > 0}
    <KpiCard
        title="Deficit (−) or surplus (+)"
        value={saldo[saldo.length - 1]?.saldo_pct}
        formattedValue={formatNumber(saldo[saldo.length - 1]?.saldo_pct, 1)}
        unit="% of GDP"
        period="in {saldo[saldo.length - 1]?.anio}"
        direction="positive-up"
        sparklineData={saldo.map(d => ({anio: d.anio, valor: d.saldo_pct}))}
    />
    {/if}
</Grid>

<p class="text-xs text-gray-500">Debt per person uses each year's Municipal Register population (the latest available for years without Register data) and is adjusted for inflation: {base[0]?.anio_base} euros (the sparkline series starts in 1996, the first year with a price deflator).</p>

<BarChart
    data={deuda_ranking}
    x=comunidad
    y=deuda_pct_pib
    series=grupo
    swapXY=true
    yFmt=pct0
    title="Debt as % of regional GDP, all communities"
    colorPalette={['#1d4ed8', '#cbd5e1']}
    sort=false
/>

<LineChart
    data={deuda}
    x=fecha
    y=deuda_pct_pib
    yFmt=num0
    yAxisTitle="% of regional GDP"
    title="Debt over time (% of regional GDP)"
    lineColor="#1d4ed8"
/>

{#if saldo.length > 0}

<BarChart
    data={saldo}
    x=anio
    y=saldo_pct_pib
    yFmt=pct1
    title="Annual surplus (+) or deficit (−), % of regional GDP"
    fillColor="#64748b"
/>

<p class="text-xs text-gray-500">The annual balance is the sum of the twelve months published by the Banco de España (complete years only); the percentage is calculated using the regional GDP implied by its debt series.</p>

{/if}

{:else}

<p class="text-sm text-gray-500">The Banco de España does not publish separate debt figures for {terr[0]?.nombre}: under the Excessive Deficit Procedure, Ceuta and Melilla are counted as local government.</p>

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

## Crime

<LineChart
    data={crimen_ccaa}
    x=anio
    y={['tasa', 'tasa_espana']}
    yFmt=num1
    xFmt="####"
    seriesLabels={{tasa: terr[0]?.nombre, tasa_espana: 'Spain'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    yAxisTitle="per 1,000 inhabitants"
    title="Recorded criminal offences per 1,000 inhabitants"
/>

<p class="text-xs text-gray-500">{formatNumber(crimen_ccaa.slice(-1)[0]?.infracciones, 0)} recorded offences in {crimen_ccaa.slice(-1)[0]?.anio} (Ministry of the Interior; includes regional police forces). 2020 is the lockdown year. Breakdown by type of offence and municipality in <a href="/en/sociedad/criminalidad">Crime</a>.</p>

{/if}

{#if empleo.length > 0}

## Public employment

<Grid cols=3>
    <KpiCard
        title="Public employees per 1,000 inhabitants"
        value={empleo[0]?.por_1000}
        formattedValue={formatNumber(empleo[0]?.por_1000, 1)}
        period="Spain: {formatNumber(empleo[0]?.por_1000_espana, 1)} · ranked {empleo[0]?.puesto} of 19 · {formatNumber(empleo[0]?.efectivos, 0)} employees at {empleo[0]?.fecha_texto}"
        source="Central Personnel Register"
        sparklineData={empleo_total_serie.filter(d => d.por_1000_hab != null).map(d => ({fecha: d.fecha, valor: d.por_1000_hab}))}
    />
    <KpiCard
        title="Work for the community"
        value={empleo[0]?.pct_ccaa}
        formattedValue={formatNumber(empleo[0]?.pct_ccaa, 0)}
        unit="%"
        period="of public employment · central government: {formatNumber(empleo[0]?.pct_estado, 0)}% · local authorities: {formatNumber(empleo[0]?.pct_local, 0)}%"
        source="Central Personnel Register"
    />
    {#if empleo_gasto.length > 0}
    <KpiCard
        title="Community staff costs"
        value={empleo_gasto[0]?.gasto_personal_ccaa_hab}
        formattedValue="€{formatNumber(empleo_gasto[0]?.gasto_personal_ccaa_hab, 0)} per person"
        period="{empleo_gasto[0]?.anio}, in {base[0]?.anio_base} euros · communities' average: €{formatNumber(empleo_gasto[0]?.media_ccaa_hab, 0)} · total: €{formatNumber(empleo_gasto[0]?.gasto_personal_ccaa / 1e9, 1)} bn in current euros"
        source="Ministry of Finance (chapter 1)"
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
        title="By sector and administration (per 1,000 inhabitants)"
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
        title="Trend per 1,000 inhabitants (1 January and 1 July)"
    />
</Grid>

<p class="text-xs text-gray-500">Staff based in {terr[0]?.nombre} across the three tiers of government: central government (Guardia Civil, National Police, armed forces, Tax Agency...), the community (healthcare, education, universities...) and local authorities. {#if empleo_gasto.length > 0 && empleo_gasto[0]?.gasto_personal_ayuntamientos_hab}Town councils in the community spent €{formatNumber(empleo_gasto[0].gasto_personal_ayuntamientos_hab, 0)} per person on staff in {empleo_gasto[0].anio} (Spain average: €{formatNumber(empleo_gasto[0].aytos_espana_hab, 0)}; {base[0]?.anio_base} euros).{/if} {#if empleo_salario.length > 0 && empleo_salario[0]?.salario_publico}Average gross salary in 2022: €{formatNumber(empleo_salario[0].salario_publico, 0)} a year in the public sector and €{formatNumber(empleo_salario[0].salario_privado, 0)} in the private sector (INE).{/if} The jump in 2023 is partly due to a revision of the register. More in <a href="/en/cuentas-publicas/empleo-publico">Public employment</a>.</p>

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

## Unemployment and prices

<Grid cols=4>
    <KpiCard
        title="Unemployment rate"
        value={paro_terr.slice(-1)[0]?.tasa_paro}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro, 1)}%"
        period="LFS {paro_terr.slice(-1)[0]?.periodo} · average over the last year {formatNumber(paro_terr.slice(-1)[0]?.media_4t_tasa_paro, 1)}% · Spain {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_espana, 1)}%"
        direction="positive-down"
        source="INE / LFS (EPA)"
        href="/en/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => d.tasa_paro)}
    />
    <KpiCard
        title="Under-25 unemployment"
        value={paro_terr.slice(-1)[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25, 1)}%"
        period="{paro_terr.slice(-1)[0]?.periodo} · Spain {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25_espana, 1)}%"
        direction="positive-down"
        source="INE / LFS (EPA)"
        href="/en/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Registered unemployment"
        value={paro_reg_terr.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(paro_reg_terr.slice(-1)[0]?.por_100_16_64, 1)} per 100 inhabitants"
        period="aged 16 to 64, {paro_reg_terr.slice(-1)[0]?.mes_txt} · {formatNumber(paro_reg_terr.slice(-1)[0]?.paro_registrado, 0)} people ({formatNumber(paro_reg_terr.slice(-1)[0]?.variacion_anual_pct, 1)}% year on year)"
        direction="positive-down"
        source="SEPE"
        href="/en/economia/paro"
        sparklineData={paro_reg_terr.slice(-36).map(d => d.por_100_16_64)}
    />
    <KpiCard
        title="Inflation"
        value={ipc_terr.slice(-1)[0]?.var_anual}
        formattedValue="{formatNumber(ipc_terr.slice(-1)[0]?.var_anual, 1)}%"
        period="Annual CPI, {ipc_terr.slice(-1)[0]?.mes_txt} · prices +{formatNumber(ipc_terr.slice(-1)[0]?.subida_desde_2019, 1)}% since the end of 2019"
        direction="positive-down"
        source="INE / CPI"
        href="/en/economia/ipc"
        sparklineData={ipc_terr.slice(-36).map(d => d.var_anual)}
    />
</Grid>

<LineChart
    data={paro_terr}
    x=trimestre
    y={['tasa_paro', 'tasa_paro_espana']}
    seriesLabels={{tasa_paro: terr[0]?.nombre, tasa_paro_espana: 'Spain'}}
    colorPalette={['#2563eb', '#94a3b8']}
    yFmt='0.0"%"'
    yAxisTitle="% of the labour force"
    title="Unemployment rate (LFS)"
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
    '/en/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
WHERE m.cod_ccaa = '${terr[0]?.cod}' AND m.anio = (SELECT max(anio) FROM mother.renta_municipios)
  AND m.poblacion > 20000 AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

{#if renta_ccaa.length > 0}

## Income and poverty

<Grid cols=3>
    <KpiCard
        title="Average income per person"
        value={renta_ccaa.slice(-1)[0]?.renta_persona_real}
        formattedValue="€{formatNumber(renta_ccaa.slice(-1)[0]?.renta_persona_real, 0)}"
        period="per year, {renta_ccaa.slice(-1)[0]?.anio_renta} income adjusted for inflation · Spain €{formatNumber(renta_ccaa.slice(-1)[0]?.renta_persona_espana, 0)} · ranked {renta_ccaa_puesto[0]?.puesto_renta} of {renta_ccaa_puesto[0]?.n}"
        direction="positive-up"
        source="INE / SILC (ECV)"
        href="/en/sociedad/desigualdad"
        sparklineData={renta_ccaa.map(d => d.renta_persona_real)}
    />
    <KpiCard
        title="At risk of poverty"
        value={renta_ccaa.slice(-1)[0]?.tasa_pobreza}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.tasa_pobreza, 1)}%"
        period="of the population, {renta_ccaa.slice(-1)[0]?.anio} survey · Spain {formatNumber(renta_ccaa.slice(-1)[0]?.pobreza_espana, 1)}% · ranked {renta_ccaa_puesto[0]?.puesto_pobreza} of {renta_ccaa_puesto[0]?.n} (1 = highest poverty)"
        direction="positive-down"
        source="INE / SILC (ECV)"
        href="/en/sociedad/desigualdad"
        sparklineData={renta_ccaa.map(d => d.tasa_pobreza)}
    />
    <KpiCard
        title="Poverty or social exclusion (AROPE)"
        value={renta_ccaa.slice(-1)[0]?.arope}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.arope, 1)}%"
        period="{renta_ccaa.slice(-1)[0]?.anio} survey · Spain {formatNumber(renta_ccaa.slice(-1)[0]?.arope_espana, 1)}%"
        direction="positive-down"
        source="INE / SILC (ECV)"
        href="/en/sociedad/desigualdad"
        sparklineData={renta_ccaa.filter(d => d.arope != null).map(d => d.arope)}
    />
</Grid>

<LineChart
    data={renta_ccaa}
    x=anio
    y={['tasa_pobreza', 'pobreza_espana']}
    seriesLabels={{tasa_pobreza: terr[0]?.nombre, pobreza_espana: 'Spain'}}
    colorPalette={['#b45309', '#94a3b8']}
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of the population"
    title="At-risk-of-poverty rate (survey year)"
/>

{#if renta_ccaa_municipios.length > 0}

Average net income per person in municipalities with more than 20,000 inhabitants (Household Income Distribution Atlas, {renta_ccaa_municipios[0]?.anio}, 2025 euros).

<DataTable data={renta_ccaa_municipios} link=enlace rows=10 search=true>
    <Column id=municipio title="Municipality"/>
    <Column id=renta_persona_real title="Income per person (€)" fmt='#,##0'/>
    <Column id=renta_hogar_real title="Income per household (€)" fmt='#,##0'/>
    <Column id=poblacion title="Inhabitants" fmt='#,##0'/>
</DataTable>

{/if}

<p class="text-xs text-gray-500">INE Living Conditions Survey: income refers to the year before the survey. More in <a href="/en/sociedad/desigualdad">Income, poverty and inequality</a>.</p>

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
SELECT nombre AS provincia, '/en' || ruta AS ruta, euros_m2_real, precio_interanual_real, alquiler_mes_mediana_real, compraventas_12m_1000, terminadas_1000
FROM mother.vivienda_resumen_territorios
WHERE nivel = 'provincia' AND cod_ccaa = '${terr[0]?.cod}'
ORDER BY euros_m2_real DESC
```

{#if viv.length > 0 && viv[0]?.euros_m2_real != null}

## Housing

<Grid cols=4>
    <KpiCard
        title="House prices"
        value={viv[0]?.euros_m2_real}
        formattedValue="€{formatNumber(viv[0]?.euros_m2_real, 0)}/m²"
        period="appraised value, {viv[0]?.precio_periodo} · Spain: €{formatNumber(viv[0]?.euros_m2_real_espana, 0)}/m²"
        change={viv[0]?.precio_interanual_real?.toFixed(1)}
        changePeriod="real terms vs a year earlier"
        source="Ministry of Housing"
        href="/en/vivienda/precios"
        sparklineData={viv_precio_ccaa.map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Median flat rent"
        value={viv[0]?.alquiler_mes_mediana_real}
        formattedValue="€{formatNumber(viv[0]?.alquiler_mes_mediana_real, 0)}/month"
        period="{viv[0]?.alquiler_anio} · Spain: €{formatNumber(viv[0]?.alquiler_espana, 0)}/month"
        source="Ministry of Housing (SERPAVI)"
        href="/en/vivienda/alquiler"
        sparklineData={viv_alquiler.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Sales per 1,000 inhabitants"
        value={viv[0]?.compraventas_12m_1000}
        formattedValue={formatNumber(viv[0]?.compraventas_12m_1000, 1)}
        period="12 months to {viv[0]?.mercado_mes} · Spain: {formatNumber(viv[0]?.compraventas_espana, 1)}"
        source="INE / ETDP"
        href="/en/vivienda/compraventas"
        sparklineData={viv_mercado.map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Years of salary for 90 m²"
        value={viv[0]?.anios_salario}
        formattedValue="{formatNumber(viv[0]?.anios_salario, 1)} years"
        period="{viv[0]?.esfuerzo_anio} · Spain: {formatNumber(viv[0]?.anios_salario_espana, 1)}"
        direction="positive-down"
        source="Ministry of Housing / INE"
        href="/en/vivienda/esfuerzo"
        sparklineData={viv_esfuerzo.map(d => d.anios_salario)}
    />
</Grid>

<LineChart
    data={viv_precio}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² ({viv[0]?.anio_base} euros)"
    startingAtZero={false}
    title="Appraised housing value adjusted for inflation"
/>

{#if viv_provincias.length > 1}
<DataTable data={viv_provincias} link=ruta>
    <Column id=provincia title="Province" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Real annual change %" fmt='0.0' contentType=delta />
    <Column id=alquiler_mes_mediana_real title="Rent €/month" fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Sales per 1,000 inhabitants" fmt='0.0' />
    <Column id=terminadas_1000 title="Homes completed per 1,000 inhabitants" fmt='0.00' />
</DataTable>
{/if}

<p class="text-xs text-gray-500">Prices and rents in {viv[0]?.anio_base} euros. More detail in <a href="/en/vivienda">Housing</a>.</p>

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

## Pensions

<Grid cols=3>
    <KpiCard
        title="Average retirement pension"
        value={pensiones_terr[0]?.pension_media_jubilacion_real}
        formattedValue="€{formatNumber(pensiones_terr[0]?.pension_media_jubilacion_real, 0)}/month"
        period="{pensiones_terr[0]?.anio} (average of {pensiones_terr[0]?.meses} months), {pensiones_terr[0]?.anio_euros} euros · Spain: €{formatNumber(pensiones_terr[0]?.jub_espana, 0)} · ranked {pensiones_terr[0]?.puesto_pension} of {pensiones_terr[0]?.n_territorios}"
        source="Social Security"
        sparklineData={pensiones_terr_serie.map(d => d.pension_media_jubilacion_real)}
    />
    <KpiCard
        title="Pensions per 1,000 inhabitants"
        value={pensiones_terr[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(pensiones_terr[0]?.pensiones_por_1000_hab, 0)}
        period="Spain: {formatNumber(pensiones_terr[0]?.por_1000_espana, 0)} · {formatNumber(pensiones_terr[0]?.pensiones_por_100_mayores, 0)} for every 100 people aged 65+ · {formatNumber(pensiones_terr[0]?.pensiones, 0)} pensions"
        source="Social Security / INE"
        sparklineData={pensiones_terr_serie.map(d => d.pensiones_por_1000_hab)}
    />
    <KpiCard
        title="Contributors per pension"
        value={pensiones_terr[0]?.afiliados_por_pension}
        formattedValue={formatNumber(pensiones_terr[0]?.afiliados_por_pension, 2)}
        period="Spain: {formatNumber(pensiones_terr[0]?.ratio_espana, 2)} (data by community since 2021)"
        source="Social Security"
        sparklineData={pensiones_terr_serie.filter(d => d.afiliados_por_pension != null).map(d => d.afiliados_por_pension)}
    />
</Grid>

<p class="text-xs text-gray-500">Social Security contributory pensions. Gross amounts for each of the 14 annual payments, adjusted for inflation. More in <a href="/en/cuentas-publicas/pensiones">Pensions</a>.</p>

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

## Education

<Grid cols=3>
    <KpiCard
        title="Early school leaving"
        value={edu_ccaa.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'abandono')?.valor, 1)}%"
        period="of 18-24-year-olds in {edu_ccaa.find(d => d.indicador === 'abandono')?.anio} · Spain: {formatNumber(edu_ccaa.find(d => d.indicador === 'abandono')?.valor_espana, 1)}% · ranked {edu_ccaa.find(d => d.indicador === 'abandono')?.puesto} of {edu_ccaa.find(d => d.indicador === 'abandono')?.n} (1 = lowest)"
        direction="positive-down"
        source="Eurostat / LFS"
        href="/en/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'abandono').map(d => d.valor)}
    />
    <KpiCard
        title="Adults with tertiary education"
        value={edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor, 1)}%"
        period="of 25-64-year-olds in {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.anio} · Spain: {formatNumber(edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor_espana, 1)}% · ranked {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.puesto} of {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.n}"
        direction="positive-up"
        source="Eurostat / LFS"
        href="/en/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'superior_25_64').map(d => d.valor)}
    />
    <KpiCard
        title="Young people not in education or employment (NEET)"
        value={edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor, 1)}%"
        period="of 15-29-year-olds in {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.anio} · Spain: {formatNumber(edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor_espana, 1)}% · ranked {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.puesto} of {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.n} (1 = lowest)"
        direction="positive-down"
        source="Eurostat / LFS"
        href="/en/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'neet_15_29').map(d => d.valor)}
    />
</Grid>

<LineChart
    data={edu_serie.filter(d => d.indicador === 'abandono')}
    x=anio
    y={['valor', 'valor_espana']}
    yFmt=pct0
    xFmt="####"
    seriesLabels={{valor: terr[0]?.nombre, valor_espana: 'Spain'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Early leavers from education and training (% of 18-24-year-olds)"
/>

<p class="text-xs text-gray-500">Labour Force Survey harmonised by Eurostat (NUTS 2 regions). Regional figures come from small samples and fluctuate from year to year, especially in Ceuta and Melilla. Details and EU comparison in <a href="/en/sociedad/educacion">Education</a>.</p>

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

## Tourism

<Grid cols=3>
    <KpiCard
        title="Tourist overnight stays"
        value={tur_ccaa.slice(-1)[0]?.pernoct_1000hab}
        formattedValue="{formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_1000hab, 0)} per 1,000 inhabitants"
        period="in hotels and tourist apartments in {tur_ccaa.slice(-1)[0]?.anio} · Spain: {formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_1000hab_espana, 0)}"
        source="INE / EOH, EOAP"
        href="/en/economia/turismo"
        sparklineData={tur_ccaa.map(d => ({anio: d.anio, valor: d.pernoct_1000hab}))}
    />
    <KpiCard
        title="Hotel occupancy"
        value={tur_ccaa.slice(-1)[0]?.ocupacion_hotel}
        formattedValue="{formatNumber(tur_ccaa.slice(-1)[0]?.ocupacion_hotel, 1)}%"
        period="of beds, {tur_ccaa.slice(-1)[0]?.anio} average · Spain: {formatNumber(tur_ccaa.slice(-1)[0]?.ocupacion_hotel_espana, 1)}%"
        source="INE / EOH"
        sparklineData={tur_ccaa.filter(d => d.ocupacion_hotel != null).map(d => ({anio: d.anio, valor: d.ocupacion_hotel}))}
    />
    {#if tur_vut_ccaa.length > 0}
    <KpiCard
        title="Tourist dwellings"
        value={tur_vut_ccaa.slice(-1)[0]?.pct_viviendas}
        formattedValue="{formatNumber(tur_vut_ccaa.slice(-1)[0]?.pct_viviendas, 2)}% of dwellings"
        period="{formatNumber(tur_vut_ccaa.slice(-1)[0]?.viviendas_1000hab, 1)} per 1,000 inhabitants in {new Date(tur_vut_ccaa.slice(-1)[0]?.periodo).toLocaleDateString('en-GB', {month: 'long', year: 'numeric', timeZone: 'UTC'})} · Spain: {formatNumber(tur_vut_ccaa.slice(-1)[0]?.pct_viviendas_espana, 2)}%"
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
    seriesLabels={{pernoct_1000hab: terr[0]?.nombre, pernoct_1000hab_espana: 'Spain'}}
    colorPalette={['#0f766e', '#94a3b8']}
    legend=true
    yAxisTitle="per 1,000 inhabitants"
    title="Overnight stays in hotels and tourist apartments per 1,000 inhabitants"
/>

<BarChart
    data={tur_ccaa_estacional}
    x=mes_nombre
    y={['pernoct_1000hab', 'pernoct_1000hab_espana']}
    type=grouped
    sort=false
    yFmt=num0
    seriesLabels={{pernoct_1000hab: terr[0]?.nombre, pernoct_1000hab_espana: 'Spain'}}
    colorPalette={['#0f766e', '#94a3b8']}
    title="Seasonality: overnight stays per 1,000 inhabitants in each month of {tur_ccaa_estacional[0]?.anio}"
/>

<p class="text-xs text-gray-500">{formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_hotel, 0)} hotel nights in {tur_ccaa.slice(-1)[0]?.anio}, {formatNumber(tur_ccaa.slice(-1)[0]?.pct_extranjeros_hotel, 1)}% of them by travellers resident abroad (INE Hotel Occupancy Survey and Tourist Apartment Occupancy Survey; tourist dwellings are not included).{#if tur_ccaa.slice(-1)[0]?.turistas_por_hab != null} {formatNumber(tur_ccaa.slice(-1)[0]?.turistas_por_hab, 1)} international tourists per inhabitant arrived (Spain: {formatNumber(tur_ccaa.slice(-1)[0]?.turistas_por_hab_espana, 1)}), spending €{formatNumber(tur_ccaa.slice(-1)[0]?.gasto_real_por_hab, 0)} per inhabitant in {tur_ccaa.slice(-1)[0]?.anio_base} euros (FRONTUR and EGATUR).{/if} More detail in <a href="/en/economia/turismo">Tourism</a>.</p>

{#if tur_vut_mun_ccaa.length > 0}

<BarChart
    data={tur_vut_mun_ccaa}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#a21caf"
    title="Municipalities with the most tourist dwellings (% of all dwellings; municipalities with 1,000 or more inhabitants)"
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

## Businesses

<Grid cols=4>
    <KpiCard
        title="Businesses per 1,000 inhabitants"
        value={empresas_ccaa[0]?.empresas_1000hab}
        formattedValue={formatNumber(empresas_ccaa[0]?.empresas_1000hab, 1)}
        period="Spain: {formatNumber(empresas_ccaa[0]?.empresas_1000hab_espana, 1)} · ranked {empresas_ccaa[0]?.puesto} of 19 · {formatNumber(empresas_ccaa[0]?.empresas, 0)} businesses on 1 January {empresas_ccaa[0]?.anio}"
        source="INE / DIRCE"
        sparklineData={empresas_ccaa_serie.map(d => d.valor)}
    />
    <KpiCard
        title="Companies created per 100,000 inhabitants"
        value={empresas_soc[0]?.constituidas_100k}
        formattedValue={formatNumber(empresas_soc[0]?.constituidas_100k, 0)}
        period="in {empresas_soc[0]?.anio} · Spain: {formatNumber(empresas_soc[0]?.constituidas_100k_espana, 0)} · dissolved: {formatNumber(empresas_soc[0]?.disueltas_100k, 0)}"
        source="INE / Commercial Companies"
        sparklineData={empresas_soc_serie.map(d => d.valor)}
    />
    <KpiCard
        title="Self-employed"
        value={empresas_aut.slice(-1)[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(empresas_aut.slice(-1)[0]?.pct_cuenta_propia, 1)}%"
        period="of people in work are self-employed ({empresas_aut.slice(-1)[0]?.anio}) · Spain: {formatNumber(empresas_aut.slice(-1)[0]?.pct_espana, 1)}%"
        source="INE / LFS (EPA)"
        sparklineData={empresas_aut.map(d => d.pct_cuenta_propia)}
    />
    <KpiCard
        title="R&D spending"
        value={empresas_id.slice(-1)[0]?.pct_pib}
        formattedValue="{formatNumber(empresas_id.slice(-1)[0]?.pct_pib, 2)}% of GDP"
        period="in {empresas_id.slice(-1)[0]?.anio} · Spain: {formatNumber(empresas_id.slice(-1)[0]?.pct_pib_espana, 2)}% · €{formatNumber(empresas_id.slice(-1)[0]?.eur_hab_real, 0)} per inhabitant ({empresas_id.slice(-1)[0]?.anio_euros} euros)"
        source="Eurostat / INE"
        sparklineData={empresas_id.map(d => d.pct_pib)}
    />
</Grid>

<LineChart
    data={empresas_ccaa_serie}
    x=anio
    y={['valor', 'valor_espana']}
    xFmt='0'
    yFmt='0.0'
    seriesLabels={{valor: terr[0]?.nombre, valor_espana: 'Spain'}}
    colorPalette={['#1d4ed8', '#94a3b8']}
    startingAtZero={false}
    yAxisTitle="per 1,000 inhabitants"
    title="Active businesses per 1,000 inhabitants"
/>

<p class="text-xs text-gray-500">Active businesses on 1 January according to the Central Business Register, including the self-employed, counted in the community where they are headquartered. In 2023 the INE began counting only economically active businesses, which explains that year's drop. More data in <a href="/en/economia/empresas">Businesses, entrepreneurship and R&D</a>.</p>

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

## Healthcare

{#if san_espera.length > 0}

<Grid cols=4>
    <KpiCard
        title="Average wait for surgery"
        value={san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_medio}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_medio, 0)} days"
        period="Spain: {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_espana, 0)} · ranked {san_espera_puesto[0]?.puesto} of {san_espera_puesto[0]?.n} (1 = shortest wait) · {new Date(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.fecha).toLocaleDateString('en-GB', {day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC'})}"
        direction="positive-down"
        source="Ministry of Health (SISLE)"
        href="/en/sociedad/salud#waiting-lists"
        sparklineData={san_espera.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Surgical waiting list"
        value={san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_1000}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_1000, 1)} per 1,000 inhabitants"
        period="Spain: {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_espana, 1)} · {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.pct_espera_larga, 1)}% have waited more than 6 months"
        direction="positive-down"
        source="Ministry of Health (SISLE)"
        sparklineData={san_espera.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Average wait for a specialist"
        value={san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_medio}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_medio, 0)} days"
        period="Spain: {formatNumber(san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_espana, 0)} · first appointment"
        direction="positive-down"
        source="Ministry of Health (SISLE)"
        sparklineData={san_espera.filter(d => d.tipo === 'consultas').map(d => ({valor: d.dias_medio}))}
    />
    {#if san_gasto.length > 0}
    <KpiCard
        title="Public health spending"
        value={san_gasto.slice(-1)[0]?.eur_hab_real}
        formattedValue="€{formatNumber(san_gasto.slice(-1)[0]?.eur_hab_real, 0)} per inhabitant"
        period="all communities: €{formatNumber(san_gasto.slice(-1)[0]?.eur_hab_real_ccaa, 0)} · {san_gasto.slice(-1)[0]?.anio}{san_gasto.slice(-1)[0]?.provisional ? ' (provisional)' : ''} · {base[0]?.anio_base} euros"
        source="Ministry of Health (EGSP)"
        sparklineData={san_gasto.map(d => ({valor: d.eur_hab_real}))}
    />
    {:else if san_recursos.some(d => d.recurso === 'medicos' && d.por_1000 != null)}
    <KpiCard
        title="Doctors"
        value={san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000}
        formattedValue="{formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000, 1)} per 1,000 inhabitants"
        period="Spain: {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000_espana, 1)} · {san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={san_recursos.filter(d => d.recurso === 'medicos').map(d => ({valor: d.por_1000}))}
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
        yAxisTitle="days"
        title="Average waiting time in the public health system"
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
        yAxisTitle="euros per inhabitant"
        title="Public health spending per inhabitant ({base[0]?.anio_base} euros)"
    />
    {/if}
</Grid>

{#if san_recursos.some(d => d.recurso === 'medicos' && d.por_1000 != null)}
<p class="text-sm">
{terr[0]?.nombre} has {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000, 1)} doctors and {formatNumber(san_recursos.filter(d => d.recurso === 'camas').slice(-1)[0]?.por_1000, 1)} hospital beds per 1,000 inhabitants (Spain: {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000_espana, 1)} and {formatNumber(san_recursos.filter(d => d.recurso === 'camas').slice(-1)[0]?.por_1000_espana, 1)}; Eurostat, {san_recursos.slice(-1)[0]?.anio}). <a href="/en/sociedad/salud#health-system">See Spain's health system</a>.
</p>
{/if}

<p class="text-xs text-gray-500">National Health System waiting lists (SISLE-SNS): each community reports its data using its own counting criteria, so comparisons between communities are only indicative. Public health spending: spending by the community's health service (Public Health Expenditure Statistics), adjusted for inflation.</p>

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

## Elections

<Grid cols=3>
    <KpiCard title="Turnout in general elections" value={elec.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec.slice(-1)[0]?.participacion, 1)}%"
        period="{elec.slice(-1)[0]?.fecha_txt} · Spain: {formatNumber(elec.slice(-1)[0]?.participacion_espana, 1)}%"
        source="Ministry of the Interior" href="/en/sociedad/elecciones" sparklineData={elec} />
    <KpiCard title="Most voted list" value={elec.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec.slice(-1)[0]?.ganador_pct, 1)}%"
        period="second: {elec.slice(-1)[0]?.segundo_siglas} ({formatNumber(elec.slice(-1)[0]?.segundo_pct, 1)}%) · {formatNumber(elec.slice(-1)[0]?.escanos, 0)} seats at stake"
        source="Ministry of the Interior" sparklineData={elec.map(d => ({valor: d.ganador_pct}))} />
    <KpiCard title="Effective number of parties" value={elec.slice(-1)[0]?.nep_votos}
        formattedValue={formatNumber(elec.slice(-1)[0]?.nep_votos, 1)} period="by votes, latest general election"
        source="Own calculation" sparklineData={elec.map(d => ({valor: d.nep_votos}))} />
</Grid>

<LineChart data={elec_familias} x=fecha y=pct series=familia yFmt='0.0"%"' markers=true
    seriesColors={Object.fromEntries(elec_colores.map(d => [d.familia, d.color]))}
    title="General election vote by political family, % of valid votes" />

<LineChart data={elec_part} x=fecha y=participacion series=ambito yFmt='0.0"%"' markers=true
    seriesColors={{'España': '#94a3b8'}} title="Turnout in general elections, %" />

{/if}

## Official sources

- **[Social Security – Contributory pensions in force by autonomous community and province](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24)**
- **INE**: [Labour Force Survey (EPA)](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [CPI](https://www.ine.es/jaxiT3/Tabla.htm?t=76140), [Living Conditions Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=9963), [Household Income Distribution Atlas](https://www.ine.es/jaxiT3/Tabla.htm?t=30824), [Vital Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=6524), [Hotel Occupancy Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=2074); **SEPE**: registered unemployment; **Ministry of Housing**: appraised value and SERPAVI; **Eurostat**: education indicators by region (NUTS 2).
- **[INE – Official population figures for municipalities (Municipal Register)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministry of Finance – Budget outturns of the autonomous communities](https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx)**: consolidated data; spending by policy excludes local authorities' share of tax revenue and CAP funds, which only pass through the regional accounts.
- **[Banco de España – Statistical Bulletin, chapter 13](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: debt under the Excessive Deficit Procedure and net lending/borrowing of the autonomous communities.
- **[Central Personnel Register – Statistical Bulletin of Public Administration Staff](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**: public employees by administration and province of the post; **[INE – Wage Structure Survey 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: public and private sector salaries.
- **[Instituto Geográfico Nacional (via es-atlas)](https://github.com/martgnz/es-atlas)**: municipal boundaries (CC BY 4.0).

<LastRefreshed prefix="Data updated" />
