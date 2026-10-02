---
title: Municipalities
description: "Look up any municipality in Spain: population, town council accounts and comparison with municipalities of a similar size."
i18n_origen: 9e50cb98a359
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorMunicipio from '../../../../../../../src/lib/components/BuscadorMunicipio.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql lista_municipios
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion
FROM mother.poblacion_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
ORDER BY m.poblacion DESC
```

# 🏘️ Your municipality in data

Search for any of Spain's more than 8,100 municipalities. The page link changes with your choice, so you can share it as it is.

<BuscadorMunicipio opciones={lista_municipios} name="municipio" defecto="28079" />

```sql mun
SELECT
    m.cod_mun, m.municipio, m.poblacion, m.anio,
    p.nombre AS provincia, '/en' || p.ruta AS provincia_ruta,
    c.nombre AS ccaa, '/en' || c.ruta AS ccaa_ruta
FROM mother.poblacion_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
LEFT JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = m.cod_ccaa
WHERE m.cod_mun = '${inputs.municipio}'
  AND m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
```

```sql base
-- Año de los euros constantes (último año completo de IPC)
SELECT max(anio_base) AS anio_base FROM mother.deflactor
```

```sql serie_poblacion
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, poblacion AS valor
FROM mother.poblacion_municipios
WHERE cod_mun = '${inputs.municipio}'
ORDER BY anio
```

```sql poblacion_contexto
WITH actual AS (
    SELECT poblacion FROM mother.poblacion_municipios
    WHERE cod_mun = '${inputs.municipio}' AND anio = (SELECT max(anio) FROM mother.poblacion_municipios)
),
antes AS (
    SELECT poblacion FROM mother.poblacion_municipios
    WHERE cod_mun = '${inputs.municipio}' AND anio = (SELECT max(anio) - 9 FROM mother.poblacion_municipios)
),
ranking AS (
    SELECT cod_mun, rank() OVER (ORDER BY poblacion DESC) AS puesto
    FROM mother.poblacion_municipios
    WHERE anio = (SELECT max(anio) FROM mother.poblacion_municipios)
)
SELECT
    100.0 * ((SELECT poblacion FROM actual) - (SELECT poblacion FROM antes)) / nullif((SELECT poblacion FROM antes), 0) AS crecimiento_10,
    (SELECT puesto FROM ranking WHERE cod_mun = '${inputs.municipio}') AS puesto
```

## {mun[0]?.municipio ?? '…'}

<p class="text-sm text-gray-500"><a href="/en/territorios">Regions</a> › <a href={mun[0]?.ccaa_ruta}>{mun[0]?.ccaa ?? '…'}</a> › <a href={mun[0]?.provincia_ruta}>{mun[0]?.provincia ?? '…'}</a> › {mun[0]?.municipio ?? '…'}</p>

<Grid cols=3>
    <KpiCard
        title="Population"
        value={mun[0]?.poblacion}
        formattedValue={formatNumber(mun[0]?.poblacion, 0)}
        unit="people"
        period="1 January {mun[0]?.anio ?? '…'}"
        source="INE – Municipal Register"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Change over 10 years"
        value={poblacion_contexto[0]?.crecimiento_10}
        formattedValue={formatNumber(poblacion_contexto[0]?.crecimiento_10, 1)}
        unit="%"
        direction="positive-up"
        sparklineData={serie_poblacion.slice(-10)}
    />
    <KpiCard
        title="Rank in Spain by population"
        value={poblacion_contexto[0]?.puesto}
        formattedValue="No. {formatNumber(poblacion_contexto[0]?.puesto, 0)}"
        period="out of {formatNumber(lista_municipios.length, 0)} municipalities"
    />
</Grid>

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Population on 1 January (Municipal Register)"
    lineColor="#1d4ed8"
/>

```sql cuentas_serie
-- Serie del municipio junto a la mediana de los municipios de su mismo tramo de
-- población ese año (mediana por habitante: no la distorsionan las ciudades grandes).
-- Las columnas _real están en euros constantes del último año completo (deflactor).
WITH mia AS (
    SELECT *,
        CASE
            WHEN poblacion < 1000 THEN '<1.000'
            WHEN poblacion < 5000 THEN '1.000-5.000'
            WHEN poblacion < 20000 THEN '5.000-20.000'
            WHEN poblacion < 50000 THEN '20.000-50.000'
            WHEN poblacion < 100000 THEN '50.000-100.000'
            WHEN poblacion < 500000 THEN '100.000-500.000'
            ELSE '>500.000'
        END AS tramo
    FROM mother.municipios_cuentas_serie
    WHERE cod_mun = '${inputs.municipio}'
)
SELECT
    make_date(CAST(m.anio AS INTEGER), 1, 1) AS fecha,
    m.anio, m.provisional, m.tiene_datos, m.tramo,
    m.gasto_hab, m.ingreso_hab, m.gastos_total, m.ingresos_total, m.saldo_no_financiero,
    t.gasto_hab_mediana AS gasto_hab_tramo,
    t.ingreso_hab_mediana AS ingreso_hab_tramo,
    t.n_municipios AS municipios_tramo,
    m.gasto_hab * f.factor AS gasto_hab_real,
    m.ingreso_hab * f.factor AS ingreso_hab_real,
    m.saldo_no_financiero / nullif(m.poblacion, 0) * f.factor AS saldo_hab_real,
    t.gasto_hab_mediana * f.factor AS gasto_hab_tramo_real,
    t.ingreso_hab_mediana * f.factor AS ingreso_hab_tramo_real,
    f.factor
FROM mia m
LEFT JOIN mother.municipios_cuentas_medias t
  ON t.anio = m.anio AND t.tramo_poblacion = m.tramo
LEFT JOIN mother.deflactor f ON f.anio = CAST(m.anio AS INTEGER)
ORDER BY m.anio
```

```sql cuentas_ultimo
SELECT * FROM ${cuentas_serie}
WHERE tiene_datos
ORDER BY provisional ASC, anio DESC
LIMIT 1
```

```sql cuentas_grafico
SELECT fecha, 'Este municipio' AS serie, gasto_hab_real AS euros FROM ${cuentas_serie} WHERE tiene_datos
UNION ALL
SELECT fecha, 'Mediana de municipios de su tamaño', gasto_hab_tramo_real FROM ${cuentas_serie}
ORDER BY fecha
```

```sql areas
-- Gasto por áreas del último año definitivo con datos, por habitante, frente a la mediana del tramo
-- (en euros constantes del último año completo)
WITH anio AS (SELECT max(anio) AS anio FROM ${cuentas_serie} WHERE tiene_datos AND NOT provisional),
defl AS (SELECT coalesce(max(factor), 1) AS factor FROM mother.deflactor WHERE anio = (SELECT CAST(anio AS INTEGER) FROM anio)),
mia AS (
    SELECT * FROM mother.municipios_cuentas
    WHERE cod_mun = '${inputs.municipio}' AND anio = (SELECT anio FROM anio)
),
tramo AS (
    SELECT t.* FROM mother.municipios_cuentas_medias t
    WHERE t.anio = (SELECT anio FROM anio)
      AND t.tramo_poblacion = (SELECT tramo FROM ${cuentas_serie} WHERE anio = (SELECT anio FROM anio))
)
SELECT area, este * (SELECT factor FROM defl) AS este, mediana * (SELECT factor FROM defl) AS mediana FROM (
    SELECT 'Deuda pública' AS area, 1 AS orden, m.gasto_area_0 / m.poblacion AS este, t.gasto_area_0_hab_mediana AS mediana FROM mia m, tramo t
    UNION ALL SELECT 'Servicios públicos básicos', 2, m.gasto_area_1 / m.poblacion, t.gasto_area_1_hab_mediana FROM mia m, tramo t
    UNION ALL SELECT 'Protección y promoción social', 3, m.gasto_area_2 / m.poblacion, t.gasto_area_2_hab_mediana FROM mia m, tramo t
    UNION ALL SELECT 'Bienes públicos preferentes', 4, m.gasto_area_3 / m.poblacion, t.gasto_area_3_hab_mediana FROM mia m, tramo t
    UNION ALL SELECT 'Actuaciones económicas', 5, m.gasto_area_4 / m.poblacion, t.gasto_area_4_hab_mediana FROM mia m, tramo t
    UNION ALL SELECT 'Actuaciones de carácter general', 6, m.gasto_area_9 / m.poblacion, t.gasto_area_9_hab_mediana FROM mia m, tramo t
)
ORDER BY orden
```

```sql areas_grafico
SELECT area, 'Este municipio' AS serie, este AS euros FROM ${areas}
UNION ALL
SELECT area, 'Mediana de su tramo', mediana FROM ${areas}
```

```sql politicas_mun
-- Gasto por políticas (último año con clasificación por programas) frente a la
-- mediana de los municipios del mismo tramo de población que la informan.
-- Importes por habitante en euros constantes del último año completo.
WITH anio AS (SELECT max(anio) AS anio FROM mother.municipios_politicas),
defl AS (SELECT coalesce(max(factor), 1) AS factor FROM mother.deflactor WHERE anio = (SELECT CAST(anio AS INTEGER) FROM anio)),
pob AS (
    SELECT cod_mun, poblacion,
        CASE
            WHEN poblacion < 1000 THEN 1 WHEN poblacion < 5000 THEN 2 WHEN poblacion < 20000 THEN 3
            WHEN poblacion < 50000 THEN 4 WHEN poblacion < 100000 THEN 5 WHEN poblacion < 500000 THEN 6 ELSE 7
        END AS tramo
    FROM mother.municipios_cuentas_serie
    WHERE anio = (SELECT anio FROM anio)
),
todas AS (
    SELECT p.cod_mun, p.cod_politica, p.politica_nombre, p.importe, p.importe / nullif(b.poblacion, 0) AS hab, b.tramo
    FROM mother.municipios_politicas p
    JOIN pob b USING (cod_mun)
    WHERE p.anio = (SELECT anio FROM anio)
),
mediana AS (
    SELECT tramo, cod_politica, median(hab) AS mediana_hab
    FROM todas GROUP BY ALL
)
SELECT
    t.politica_nombre AS politica,
    t.importe,
    t.hab * (SELECT factor FROM defl) AS por_habitante,
    m.mediana_hab * (SELECT factor FROM defl) AS mediana_tramo,
    100.0 * (t.hab - m.mediana_hab) / nullif(m.mediana_hab, 0) AS dif_pct,
    t.importe / sum(t.importe) OVER () AS peso,
    (SELECT anio FROM anio) AS anio
FROM todas t
JOIN mediana m USING (tramo, cod_politica)
WHERE t.cod_mun = '${inputs.municipio}' AND t.importe > 0
ORDER BY t.importe DESC
```

```sql personal_ayto
-- Gasto de personal (capítulo 1) del último año definitivo con datos, frente a
-- la mediana por habitante de los municipios de su mismo tramo de población
-- (por habitante en euros constantes del último año completo)
WITH anio AS (SELECT max(anio) AS anio FROM ${cuentas_serie} WHERE tiene_datos AND NOT provisional),
defl AS (SELECT coalesce(max(factor), 1) AS factor FROM mother.deflactor WHERE anio = (SELECT CAST(anio AS INTEGER) FROM anio)),
todos AS (
    SELECT cod_mun, poblacion, gastos_c1, gastos_total,
        CASE
            WHEN poblacion < 1000 THEN 1 WHEN poblacion < 5000 THEN 2 WHEN poblacion < 20000 THEN 3
            WHEN poblacion < 50000 THEN 4 WHEN poblacion < 100000 THEN 5 WHEN poblacion < 500000 THEN 6 ELSE 7
        END AS tramo
    FROM mother.municipios_cuentas
    WHERE anio = (SELECT anio FROM anio) AND tiene_datos AND NOT provisional AND poblacion > 0
)
SELECT
    (SELECT anio FROM anio) AS anio,
    m.gastos_c1,
    m.gastos_c1 / m.poblacion * (SELECT factor FROM defl) AS por_habitante,
    m.gastos_c1 / nullif(m.gastos_total, 0) AS peso,
    (SELECT median(t.gastos_c1 / t.poblacion) FROM todos t WHERE t.tramo = m.tramo) * (SELECT factor FROM defl) AS mediana_tramo
FROM todos m
WHERE m.cod_mun = '${inputs.municipio}'
```

```sql deuda_ayto
-- Deuda por habitante en euros constantes. La población municipal cargada solo
-- cubre los últimos 10 años: fuera de ese rango se usa el año más cercano.
-- Sin IPC anual antes de 2002: la serie empieza ese año.
WITH pob AS (
    SELECT anio, poblacion FROM mother.poblacion_municipios
    WHERE cod_mun = '${inputs.municipio}'
),
rango AS (SELECT min(anio) AS ini, max(anio) AS fin FROM pob)
SELECT
    d.fecha,
    d.deuda_eur,
    d.deuda_eur / nullif(p.poblacion, 0) * f.factor AS deuda_hab_real
FROM mother.local_deuda_municipio d
CROSS JOIN rango r
JOIN pob p ON p.anio = greatest(least(CAST(year(d.fecha) AS INTEGER), r.fin), r.ini)
JOIN mother.deflactor f ON f.anio = CAST(year(d.fecha) AS INTEGER)
WHERE d.cod_mun = '${inputs.municipio}'
ORDER BY d.fecha
```

## Town council accounts

{#if cuentas_ultimo.length > 0}

{#if cuentas_ultimo[0].anio < cuentas_serie.filter(r => !r.provisional).slice(-1)[0]?.anio}

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
The latest available data is from <b>{cuentas_ultimo[0].anio}</b>: since then this town council has not submitted its budget outturn to the Ministry of Finance, so the figures may be well out of date.
</div>

{/if}

Outturn of the town council budget (what was actually collected and spent, not what was budgeted). To make the comparison fair, it is set against the **median of municipalities in the same population band** ({cuentas_ultimo[0].tramo} inhabitants). Amounts are **per person** and **adjusted for inflation**, in {base[0]?.anio_base} euros.

<Grid cols=3>
    <KpiCard
        title="Spending per person"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="Median for its band: €{formatNumber(cuentas_ultimo[0]?.gasto_hab_tramo_real, 0)} · {cuentas_ultimo[0]?.anio}{cuentas_ultimo[0]?.provisional ? ' (provisional)' : ''}, in {base[0]?.anio_base} euros"
        source="Ministry of Finance"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.gasto_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.gasto_hab_real}))}
    />
    <KpiCard
        title="Revenue per person"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="Median for its band: €{formatNumber(cuentas_ultimo[0]?.ingreso_hab_tramo_real, 0)} · in {base[0]?.anio_base} euros"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.ingreso_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.ingreso_hab_real}))}
    />
    <KpiCard
        title="Non-financial balance per person"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Revenue − spending in chapters 1 to 7, in {base[0]?.anio_base} euros · total: €{formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 1)} in current euros"
        direction="positive-up"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.saldo_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.saldo_hab_real}))}
    />
</Grid>

{#if personal_ayto.length > 0 && personal_ayto[0]?.gastos_c1 != null}

<Grid cols=2>
    <KpiCard
        title="Staff costs per person"
        value={personal_ayto[0]?.por_habitante}
        formattedValue={formatNumber(personal_ayto[0]?.por_habitante, 0)}
        unit="€"
        period="Median for its band: €{formatNumber(personal_ayto[0]?.mediana_tramo, 0)} · {personal_ayto[0]?.anio}, in {base[0]?.anio_base} euros"
        source="Ministry of Finance (chapter 1)"
        href="/en/cuentas-publicas/empleo-publico"
    />
    <KpiCard
        title="Staff share of spending"
        value={personal_ayto[0]?.peso}
        formattedValue="{formatNumber(personal_ayto[0]?.peso / 0.01, 0)}%"
        period="€{formatCompact(personal_ayto[0]?.gastos_c1, 1)} in current euros on salaries, social security contributions and pay for elected officials"
    />
</Grid>

{/if}

<LineChart
    data={cuentas_grafico}
    x=fecha
    y=euros
    series=serie
    yFmt=num0
    yAxisTitle="€ per person"
    title="Spending per person ({base[0]?.anio_base} euros, adjusted for inflation)"
    colorPalette={['#0f766e', '#94a3b8']}
/>

{#if areas.length > 0}

<BarChart
    data={areas_grafico}
    x=area
    y=euros
    series=serie
    type=grouped
    swapXY=true
    yFmt=num0
    title="Spending per person by area, {cuentas_serie.filter(r => r.tiene_datos && !r.provisional).slice(-1)[0]?.anio} ({base[0]?.anio_base} euros)"
    colorPalette={['#0f766e', '#94a3b8']}
/>

{/if}

{#if politicas_mun.length > 0}

<Details title="Spending by policy ({politicas_mun[0].anio})">

<DataTable data={politicas_mun} rows=all>
    <Column id=politica title="Spending policy" />
    <Column id=por_habitante title="€ per person ({base[0]?.anio_base} euros)" fmt=num0 />
    <Column id=mediana_tramo title="Band median (€ per person)" fmt=num0 />
    <Column id=dif_pct title="Difference (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Share" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=importe title="Total spending (current €)" fmt=num0 />
</DataTable>

</Details>

{/if}

{#if deuda_ayto.length > 0}

<LineChart
    data={deuda_ayto}
    x=fecha
    y=deuda_hab_real
    yFmt=num0
    yAxisTitle="€ per person"
    title="Town council debt per person ({base[0]?.anio_base} euros, Banco de España)"
    lineColor="#b45309"
/>

<p class="text-xs text-gray-500">Debt at the end of each quarter: €{formatCompact(deuda_ayto[deuda_ayto.length - 1]?.deuda_eur, 0)} in current euros at the latest reading. Per person using each year's Municipal Register (the nearest year outside the last 10 years) and adjusted for inflation.</p>

{/if}

<p class="text-xs text-gray-500">Town council only (excludes the provincial council, associations of municipalities and municipal companies). Years in which the council did not submit its outturn to the Ministry of Finance are shown as missing, not as zero.</p>

{:else}

<p class="text-sm text-gray-500">This town council has not submitted its budget outturn to the Ministry of Finance for any of the available years.</p>

{/if}

```sql crimen_mun
WITH u AS (SELECT max(anio) AS anio FROM mother.crimen_balance WHERE nivel = 'municipio')
SELECT
    b.anio,
    max(b.infracciones) FILTER (WHERE b.categoria = 'Total infracciones penales') AS infracciones,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Total infracciones penales') AS tasa,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con violencia o intimidación') AS robos_violencia,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con fuerza en domicilios') AS robos_domicilios,
    (SELECT tasa_1000 FROM mother.crimen_balance e WHERE e.nivel = 'pais' AND e.categoria = 'Total infracciones penales' AND e.anio = b.anio) AS tasa_espana
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
WHERE b.nivel = 'municipio' AND b.cod = '${inputs.municipio}'
GROUP BY b.anio
```

```sql crimen_mun_serie
SELECT
    anio,
    max(tasa_1000) FILTER (WHERE categoria = 'Total infracciones penales') AS tasa,
    max(tasa_1000) FILTER (WHERE categoria = 'Robos con violencia o intimidación') AS robos_violencia,
    max(tasa_1000) FILTER (WHERE categoria = 'Robos con fuerza en domicilios') AS robos_domicilios
FROM mother.crimen_balance
WHERE nivel = 'municipio' AND cod = '${inputs.municipio}'
GROUP BY anio
ORDER BY anio
```

{#if crimen_mun.length > 0 && crimen_mun[0]?.infracciones != null}

```sql renta_mun
SELECT
    CAST(m.anio AS INTEGER) AS anio,
    m.renta_persona_real, m.renta_hogar_real, m.renta_uc_mediana_real, m.renta_persona,
    m.puesto_espana, m.municipios_con_dato,
    p.renta_persona_real AS renta_persona_provincia,
    e.renta_persona_real AS renta_persona_espana
FROM mother.renta_municipios m
LEFT JOIN mother.renta_territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov AND p.anio = m.anio
LEFT JOIN mother.renta_territorios e ON e.nivel = 'pais' AND e.anio = m.anio
WHERE m.cod_mun = '${inputs.municipio}' AND m.renta_persona_real IS NOT NULL
ORDER BY m.anio
```

```sql renta_mun_distritos
SELECT 'Distrito ' || distrito AS distrito, renta_persona_real, renta_hogar_real, CAST(anio AS INTEGER) AS anio
FROM mother.renta_distritos
WHERE cod_mun = '${inputs.municipio}' AND anio = (SELECT max(anio) FROM mother.renta_distritos)
ORDER BY cod_distrito
```

```sql paro_mun
SELECT
    municipio, paro_registrado, paro_registrado_hace_1_anio, por_100_hab, variacion_anual_pct, oculto,
    100.0 * paro_registrado_hace_1_anio / poblacion AS por_100_hab_hace_1_anio,
    strftime(mes, '%m/%Y') AS mes_txt
FROM mother.mercado_paro_municipios
WHERE cod_municipio = '${inputs.municipio}'
```

{#if renta_mun.length > 0 || paro_mun.length > 0}

## Income and unemployment

<Grid cols=3>
{#if renta_mun.length > 0}
    <KpiCard
        title="Net income per person"
        value={renta_mun.slice(-1)[0]?.renta_persona_real}
        formattedValue="€{formatNumber(renta_mun.slice(-1)[0]?.renta_persona_real, 0)}"
        period="per year in {renta_mun.slice(-1)[0]?.anio}, 2025 euros · ranked {formatNumber(renta_mun.slice(-1)[0]?.puesto_espana, 0)} of {formatNumber(renta_mun.slice(-1)[0]?.municipios_con_dato, 0)} municipalities · province €{formatNumber(renta_mun.slice(-1)[0]?.renta_persona_provincia, 0)}"
        direction="positive-up"
        source="INE / Household Income Atlas"
        href="/en/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => d.renta_persona_real)}
    />
    <KpiCard
        title="Net income per household"
        value={renta_mun.slice(-1)[0]?.renta_hogar_real}
        formattedValue="€{formatNumber(renta_mun.slice(-1)[0]?.renta_hogar_real, 0)}"
        period="per year in {renta_mun.slice(-1)[0]?.anio}, 2025 euros"
        direction="positive-up"
        source="INE / Household Income Atlas"
        href="/en/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => d.renta_hogar_real)}
    />
{/if}
{#if paro_mun.length > 0 && !paro_mun[0]?.oculto}
    <KpiCard
        title="Registered unemployment"
        value={paro_mun[0]?.por_100_hab}
        formattedValue="{formatNumber(paro_mun[0]?.por_100_hab, 1)} per 100 inhabitants"
        period="{paro_mun[0]?.mes_txt} · {formatNumber(paro_mun[0]?.paro_registrado, 0)} people ({formatNumber(paro_mun[0]?.variacion_anual_pct, 1)}% year on year)"
        direction="positive-down"
        source="SEPE"
        href="/en/economia/paro"
        sparklineData={[paro_mun[0]?.por_100_hab_hace_1_anio, paro_mun[0]?.por_100_hab]}
    />
{/if}
</Grid>

{#if renta_mun.length > 1}
<LineChart
    data={renta_mun}
    x=anio
    y={['renta_persona_real', 'renta_persona_provincia']}
    seriesLabels={{renta_persona_real: mun[0]?.municipio, renta_persona_provincia: 'Province'}}
    colorPalette={['#b45309', '#94a3b8']}
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per person per year (real terms)"
    title="Average net income per person, 2025 euros"
/>
{/if}

{#if renta_mun_distritos.length > 1}
<BarChart
    data={renta_mun_distritos}
    x=distrito
    y=renta_persona_real
    yFmt='#,##0" €"'
    title="Income per person in each district ({renta_mun_distritos[0]?.anio}, 2025 euros)"
/>
{/if}

<p class="text-xs text-gray-500">Income: INE Household Income Distribution Atlas, based on tax data. Unemployment: jobseekers registered as unemployed with SEPE on the last day of the month, relative to the municipality's total population (there is no 16-to-64 population figure by municipality).</p>

{/if}

```sql tur_vut_mun
SELECT
    v.periodo, v.viviendas, v.plazas, v.pct_viviendas, v.viviendas_1000hab, v.puesto,
    e.pct_viviendas AS pct_viviendas_espana,
    e.viviendas_1000hab AS viviendas_1000hab_espana,
    (SELECT count(*) FROM mother.turismo_viviendas_municipios x WHERE x.periodo = v.periodo AND x.poblacion >= 1000) AS n_ranking,
    ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(month(v.periodo) AS INTEGER)] || ' de ' || CAST(v.anio AS INTEGER) AS periodo_txt
FROM mother.turismo_viviendas_municipios v
JOIN mother.turismo_viviendas e ON e.nivel = 'pais' AND e.periodo = v.periodo
WHERE v.cod_mun = '${inputs.municipio}'
ORDER BY v.periodo
```

{#if tur_vut_mun.length > 0 && tur_vut_mun.slice(-1)[0]?.viviendas != null}

## Tourist accommodation

<Grid cols=2>
    <KpiCard
        title="Tourist dwellings"
        value={tur_vut_mun.slice(-1)[0]?.pct_viviendas}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas, 2)}% of dwellings"
        period="{new Date(tur_vut_mun.slice(-1)[0]?.periodo).toLocaleDateString('en-GB', {month: 'long', year: 'numeric', timeZone: 'UTC'})} · Spain: {formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas_espana, 2)}%"
        source="INE (experimental)"
        href="/en/economia/turismo"
        sparklineData={tur_vut_mun.filter(d => d.pct_viviendas != null).map(d => ({x: d.periodo, y: d.pct_viviendas}))}
    />
    <KpiCard
        title="Per 1,000 inhabitants"
        value={tur_vut_mun.slice(-1)[0]?.viviendas_1000hab}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab, 1)}"
        period="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas, 0)} dwellings with {formatNumber(tur_vut_mun.slice(-1)[0]?.plazas, 0)} beds · Spain: {formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab_espana, 1)}"
        source="INE (experimental)"
        sparklineData={tur_vut_mun.filter(d => d.viviendas_1000hab != null).map(d => ({x: d.periodo, y: d.viviendas_1000hab}))}
    />
</Grid>

<p class="text-xs text-gray-500">Dwellings advertised as tourist accommodation on the major online platforms (experimental INE measurement, every six months). {#if tur_vut_mun.slice(-1)[0]?.puesto}It ranks {formatNumber(tur_vut_mun.slice(-1)[0]?.puesto, 0)} out of {formatNumber(tur_vut_mun.slice(-1)[0]?.n_ranking, 0)} municipalities with 1,000 or more inhabitants by share of tourist dwellings.{/if} More in <a href="/en/economia/turismo">Tourism</a>.</p>

{/if}

## Crime

<Grid cols=3>
    <KpiCard
        title="Recorded criminal offences"
        value={crimen_mun[0]?.tasa}
        formattedValue={formatNumber(crimen_mun[0]?.tasa, 1)}
        period="per 1,000 inhabitants in {crimen_mun[0]?.anio} · Spain: {formatNumber(crimen_mun[0]?.tasa_espana, 1)}"
        source="Ministry of the Interior"
        href="/en/sociedad/criminalidad"
        sparklineData={crimen_mun_serie.filter(d => d.tasa != null).map(d => ({anio: d.anio, valor: d.tasa}))}
    />
    <KpiCard
        title="Violent robberies"
        value={crimen_mun[0]?.robos_violencia}
        formattedValue={formatNumber(crimen_mun[0]?.robos_violencia, 2)}
        period="per 1,000 inhabitants"
        sparklineData={crimen_mun_serie.filter(d => d.robos_violencia != null).map(d => ({anio: d.anio, valor: d.robos_violencia}))}
    />
    <KpiCard
        title="Burglaries"
        value={crimen_mun[0]?.robos_domicilios}
        formattedValue={formatNumber(crimen_mun[0]?.robos_domicilios, 2)}
        period="per 1,000 inhabitants"
        sparklineData={crimen_mun_serie.filter(d => d.robos_domicilios != null).map(d => ({anio: d.anio, valor: d.robos_domicilios}))}
    />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(crimen_mun[0]?.infracciones, 0)} criminal offences known to the police within the municipality (Crime Report, municipalities with more than 20,000 inhabitants). In tourist municipalities or those with an airport the rate per registered resident comes out high because many victims are visitors.</p>

{/if}

```sql alcalde
SELECT
    lower(alcalde) AS alcalde,
    cargo,
    strftime(fecha_posesion, '%d/%m/%Y') AS desde,
    partido_original,
    familia,
    color,
    anios_en_cargo,
    anios_partido,
    primer_anio_familia,
    familia_anterior,
    cambio_ultimo_mandato
FROM mother.alcaldes_actuales
WHERE cod_mun = '${inputs.municipio}'
```

```sql historia_alcaldes
SELECT
    mandato,
    lower(alcalde) AS alcalde,
    strftime(fecha_posesion, '%d/%m/%Y') AS toma_posesion,
    partido_original AS lista,
    familia,
    color
FROM mother.alcaldes_historia
WHERE cod_mun = '${inputs.municipio}'
ORDER BY fecha_posesion DESC
```

```sql familias_mandato
SELECT mandato, familia, color, 1 AS mandatos
FROM mother.alcaldes_historia
WHERE cod_mun = '${inputs.municipio}'
QUALIFY row_number() OVER (PARTITION BY mandato ORDER BY fecha_posesion) = 1
ORDER BY mandato
```

{#if alcalde.length > 0}

```sql elec_mun
SELECT e.proceso, e.tipo, p.fecha, CAST(e.anio AS INTEGER) AS anio,
    CASE e.tipo WHEN '02' THEN 'Generales' ELSE 'Municipales' END AS eleccion,
    e.participacion, e.ganador_siglas, e.ganador_familia, b.color AS ganador_color, e.ganador_pct,
    e.pct_izquierda, e.pct_derecha, e.pct_centro, e.pct_nacionalistas, e.pct_psoe, e.pct_pp, e.pct_vox, e.pct_iu_podemos_sumar
FROM mother.elecciones_municipios e
JOIN mother.elecciones_participacion p ON p.proceso = e.proceso AND p.nivel = 'pais'
LEFT JOIN (SELECT DISTINCT familia, color FROM mother.elecciones_familias) b ON b.familia = e.ganador_familia
WHERE e.cod_mun = '${inputs.municipio}'
ORDER BY p.fecha
```

```sql elec_mun_gen
SELECT *, participacion AS valor FROM ${elec_mun} WHERE tipo = '02' ORDER BY fecha
```

```sql elec_mun_bloques
SELECT fecha, bloque, pct FROM (
    SELECT fecha, unnest(['Izquierda', 'Derecha', 'Centro', 'Nacionalistas y regionalistas']) AS bloque,
        unnest([pct_izquierda, pct_derecha, pct_centro, pct_nacionalistas]) AS pct
    FROM ${elec_mun_gen})
ORDER BY fecha
```

{#if elec_mun_gen.length > 0}

## Elections

<Grid cols=2>
    <KpiCard title="Turnout in general elections" value={elec_mun_gen.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec_mun_gen.slice(-1)[0]?.participacion, 1)}%"
        period="{elec_mun_gen.slice(-1)[0]?.anio} · excluding votes from residents abroad"
        source="Ministry of the Interior" href="/en/sociedad/elecciones" sparklineData={elec_mun_gen} />
    <KpiCard title="Most voted in general elections" value={elec_mun_gen.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec_mun_gen.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec_mun_gen.slice(-1)[0]?.ganador_pct, 1)}%"
        period="{elec_mun_gen.slice(-1)[0]?.anio}" source="Ministry of the Interior"
        sparklineData={elec_mun_gen.map(d => ({valor: d.ganador_pct}))} />
</Grid>

<LineChart data={elec_mun_bloques} x=fecha y=pct series=bloque yFmt='0"%"' markers=true
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04'}}
    title="Vote by bloc in general elections, % of valid votes" />

<DataTable data={elec_mun} rows=10>
    <Column id=anio title="Year" fmt='0' />
    <Column id=eleccion title="Election" />
    <Column id=ganador_siglas title="Most voted" />
    <Column id=ganador_pct title="% of vote" fmt='0.0"%"' />
    <Column id=participacion title="Turnout" fmt='0.0"%"' />
</DataTable>

{/if}

## Who governs?

<div class="not-prose rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 my-4" style="border-left: 6px solid {alcalde[0].color}">
    <p class="text-xs uppercase tracking-wide text-gray-500 mb-1">{alcalde[0].cargo} since {alcalde[0].desde}</p>
    <p class="text-2xl font-bold text-gray-900 dark:text-white capitalize mb-1">{alcalde[0].alcalde}</p>
    <p class="text-sm text-gray-700 dark:text-gray-300 mb-0">List: <b>{alcalde[0].partido_original}</b> · Political family: <b>{alcalde[0].familia}</b></p>
</div>

<Grid cols=2>
    <KpiCard
        title="Years in office"
        value={alcalde[0]?.anios_en_cargo}
        formattedValue={formatNumber(alcalde[0]?.anios_en_cargo, 1)}
        unit="years"
        period="continuously, including previous terms"
    />
    <KpiCard
        title="Years of {alcalde[0]?.familia} holding the mayoralty"
        value={alcalde[0]?.anios_partido}
        formattedValue={formatNumber(alcalde[0]?.anios_partido, 1)}
        unit="years"
        period="governing without interruption since {alcalde[0]?.primer_anio_familia}"
    />
</Grid>

{#if familias_mandato.length > 1}

<BarChart
    data={familias_mandato}
    x=mandato
    y=mandatos
    series=familia
    type=stacked
    yMax=1
    yAxisLabels=false
    yGridlines=false
    title="Political family holding the mayoralty at the start of each term"
    seriesColors={Object.fromEntries(familias_mandato.map(f => [f.familia, f.color]))}
/>

{/if}

<Details title="All mayors since 1979">

<DataTable data={historia_alcaldes} rows=15>
    <Column id=mandato title="Term" />
    <Column id=alcalde title="Mayor" />
    <Column id=toma_posesion title="Took office" />
    <Column id=lista title="List" />
    <Column id=familia title="Family" />
</DataTable>

</Details>

<p class="text-xs text-gray-500">Lists are grouped into political families (for example, PSC, PSOE-A or PSdeG-PSOE under «PSOE»). Years are calculated from the continuity of the name and the family across terms; in 2007-2023 the source sometimes uses generic coalition labels («C. ELECTORAL», «OTROS»), which appear as «Sin detalle en la fuente» (no detail in the source) when they cannot be resolved.</p>

{/if}

---

## Official sources

- **[INE – Official population figures for municipalities (Municipal Register)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministry of Finance – Local authority budget outturns (CONPREL)](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: revenue and spending by chapter, area and policy for every town council since 2010.
- **[Banco de España – Statistical Bulletin, chapter 14](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: debt of town councils with more than 300,000 inhabitants.
- **[Ministry of Territorial Policy – Mayors and councillors](https://concejales.redsara.es/consulta/)**: current mayor (2023-2027 term) and historical lists of mayors since 1979 from the Local Information System.

<LastRefreshed prefix="Data updated" />
