---
title: Municipios
description: "Busca cualquier municipio de España: población, cuentas del ayuntamiento y comparación con municipios de su tamaño."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorMunicipio from '../../../../../../src/lib/components/BuscadorMunicipio.svelte';
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql lista_municipios
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion
FROM mother.poblacion_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
ORDER BY m.poblacion DESC
```

# 🏘️ Tu municipio en datos

Busca cualquiera de los más de 8.100 municipios de España. El enlace de la página cambia con tu elección, así que puedes compartirlo tal cual.

<BuscadorMunicipio opciones={lista_municipios} name="municipio" defecto="28079" />

```sql mun
SELECT
    m.cod_mun, m.municipio, m.poblacion, m.anio,
    p.nombre AS provincia, p.ruta AS provincia_ruta,
    c.nombre AS ccaa, c.ruta AS ccaa_ruta
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

<p class="text-sm text-gray-500"><a href="/territorios">Territorios</a> › <a href={mun[0]?.ccaa_ruta}>{mun[0]?.ccaa ?? '…'}</a> › <a href={mun[0]?.provincia_ruta}>{mun[0]?.provincia ?? '…'}</a> › {mun[0]?.municipio ?? '…'}</p>

<Grid cols=3>
    <KpiCard
        title="Población"
        value={mun[0]?.poblacion}
        formattedValue={formatNumber(mun[0]?.poblacion, 0)}
        unit="hab."
        period="1 de enero de {mun[0]?.anio ?? '…'}"
        source="INE – Padrón"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Evolución en 10 años"
        value={poblacion_contexto[0]?.crecimiento_10}
        formattedValue={formatNumber(poblacion_contexto[0]?.crecimiento_10, 1)}
        unit="%"
        direction="positive-up"
        sparklineData={serie_poblacion.slice(-10)}
    />
    <KpiCard
        title="Puesto en España por población"
        value={poblacion_contexto[0]?.puesto}
        formattedValue="{formatNumber(poblacion_contexto[0]?.puesto, 0)}.º"
        period="de {formatNumber(lista_municipios.length, 0)} municipios"
    />
</Grid>

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Población a 1 de enero (Padrón)"
    lineColor="#1d4ed8"
/>

```sql cuentas_serie
-- Serie del municipio junto a la mediana de los municipios de su mismo tramo de
-- población ese año (mediana por habitante: no la distorsionan las ciudades grandes).
-- Las columnas _real están en euros constantes del último año completo (deflactor).
WITH mia AS (
    SELECT *, tramo_poblacion AS tramo
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
    m.gasto_hab_real,
    m.ingreso_hab_real,
    m.saldo_hab_real,
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
pob AS (
    SELECT cod_mun, tramo_orden AS tramo
    FROM mother.municipios_cuentas_serie
    WHERE anio = (SELECT anio FROM anio)
),
todas AS (
    SELECT p.cod_mun, p.cod_politica, p.politica_nombre, p.importe, p.importe_hab_real AS hab, b.tramo
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
    t.hab AS por_habitante,
    m.mediana_hab AS mediana_tramo,
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
-- Deuda por habitante en euros constantes (el modelo ya trae población y deflactor)
SELECT
    fecha,
    deuda_eur,
    deuda_eur_hab_real
FROM mother.local_deuda_municipio
WHERE cod_mun = '${inputs.municipio}' AND deuda_eur_hab_real IS NOT NULL
ORDER BY fecha
```

## Cuentas del ayuntamiento

{#if cuentas_ultimo.length > 0}

{#if cuentas_ultimo[0].anio < cuentas_serie.filter(r => !r.provisional).slice(-1)[0]?.anio}

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
El último dato disponible es de <b>{cuentas_ultimo[0].anio}</b>: desde entonces este ayuntamiento no ha remitido a Hacienda la liquidación de sus presupuestos, así que las cifras pueden estar muy desactualizadas.
</div>

{/if}

Liquidación del presupuesto del ayuntamiento (lo realmente ingresado y gastado, no lo presupuestado). Para que la comparación sea justa, se compara con la **mediana de los municipios de su mismo tramo de población** ({cuentas_ultimo[0].tramo} habitantes). Los importes van **por habitante** y **descontada la inflación**, en euros de {base[0]?.anio_base}.

<Grid cols=3>
    <KpiCard
        title="Gasto por habitante"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="Mediana de su tramo: {formatNumber(cuentas_ultimo[0]?.gasto_hab_tramo_real, 0)} € · {cuentas_ultimo[0]?.anio}{cuentas_ultimo[0]?.provisional ? ' (avance)' : ''}, en euros de {base[0]?.anio_base}"
        source="Ministerio de Hacienda"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.gasto_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.gasto_hab_real}))}
    />
    <KpiCard
        title="Ingreso por habitante"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="Mediana de su tramo: {formatNumber(cuentas_ultimo[0]?.ingreso_hab_tramo_real, 0)} € · en euros de {base[0]?.anio_base}"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.ingreso_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.ingreso_hab_real}))}
    />
    <KpiCard
        title="Saldo no financiero por habitante"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Ingresos − gastos de los capítulos 1 a 7, en euros de {base[0]?.anio_base} · total: {formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 1)} € corrientes"
        direction="positive-up"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.saldo_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.saldo_hab_real}))}
    />
</Grid>

{#if personal_ayto.length > 0 && personal_ayto[0]?.gastos_c1 != null}

<Grid cols=2>
    <KpiCard
        title="Gasto de personal por habitante"
        value={personal_ayto[0]?.por_habitante}
        formattedValue={formatNumber(personal_ayto[0]?.por_habitante, 0)}
        unit="€"
        period="Mediana de su tramo: {formatNumber(personal_ayto[0]?.mediana_tramo, 0)} € · {personal_ayto[0]?.anio}, en euros de {base[0]?.anio_base}"
        source="Ministerio de Hacienda (capítulo 1)"
        href="/cuentas-publicas/empleo-publico"
    />
    <KpiCard
        title="Peso del personal en el gasto"
        value={personal_ayto[0]?.peso}
        formattedValue="{formatNumber(personal_ayto[0]?.peso / 0.01, 0)} %"
        period="{formatCompact(personal_ayto[0]?.gastos_c1, 1)} € corrientes en sueldos, cotizaciones y retribuciones de cargos electos"
    />
</Grid>

{/if}

<LineChart
    data={cuentas_grafico}
    x=fecha
    y=euros
    series=serie
    yFmt=num0
    yAxisTitle="€ por habitante"
    title="Gasto por habitante (euros de {base[0]?.anio_base}, descontada la inflación)"
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
    title="Gasto por habitante según el área, {cuentas_serie.filter(r => r.tiene_datos && !r.provisional).slice(-1)[0]?.anio} (euros de {base[0]?.anio_base})"
    colorPalette={['#0f766e', '#94a3b8']}
/>

{/if}

{#if politicas_mun.length > 0}

<Details title="Gasto por políticas ({politicas_mun[0].anio})">

<DataTable data={politicas_mun} rows=all>
    <Column id=politica title="Política de gasto" />
    <Column id=por_habitante title="€/habitante (euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=mediana_tramo title="Mediana del tramo (€/hab.)" fmt=num0 />
    <Column id=dif_pct title="Diferencia (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Peso" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=importe title="Gasto total (€ corrientes)" fmt=num0 />
</DataTable>

</Details>

{/if}

{#if deuda_ayto.length > 0}

<LineChart
    data={deuda_ayto}
    x=fecha
    y=deuda_eur_hab_real
    yFmt=num0
    yAxisTitle="€ por habitante"
    title="Deuda del ayuntamiento por habitante (euros de {base[0]?.anio_base}, Banco de España)"
    lineColor="#b45309"
/>

<p class="text-xs text-gray-500">Deuda al final de cada trimestre: {formatCompact(deuda_ayto[deuda_ayto.length - 1]?.deuda_eur, 0)} € corrientes en el último dato. Por habitante con el Padrón de cada año y descontada la inflación.</p>

{/if}

<p class="text-xs text-gray-500">Solo ayuntamiento (no incluye diputación, mancomunidades ni empresas municipales). Los años en que el ayuntamiento no remitió su liquidación a Hacienda aparecen sin dato, no como cero.</p>

{:else}

<p class="text-sm text-gray-500">Este ayuntamiento no ha remitido a Hacienda la liquidación de sus presupuestos en los años disponibles.</p>

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
SELECT distrito, renta_persona_real, renta_hogar_real, CAST(anio AS INTEGER) AS anio
FROM mother.renta_distritos
WHERE cod_mun = '${inputs.municipio}' AND anio = (SELECT max(anio) FROM mother.renta_distritos)
ORDER BY cod_distrito
```

```sql paro_mun
SELECT
    municipio, paro_registrado, paro_registrado_hace_1_anio, por_100_hab, variacion_anual_pct, oculto,
    100.0 * paro_registrado_hace_1_anio / poblacion AS por_100_hab_hace_1_anio,
    strftime(mes, '%m/%Y') AS mes_txt,
    strftime(mes, '%Y-%m') AS mes_iso,
    strftime(mes - INTERVAL 1 YEAR, '%Y-%m') AS mes_iso_hace_1_anio
FROM mother.mercado_paro_municipios
WHERE cod_municipio = '${inputs.municipio}'
```

{#if renta_mun.length > 0 || paro_mun.length > 0}

## Renta y paro

<Grid cols=3>
{#if renta_mun.length > 0}
    <KpiCard
        title="Renta neta por persona"
        value={renta_mun.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_mun.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="al año en {renta_mun.slice(-1)[0]?.anio}, euros de 2025 · puesto {formatNumber(renta_mun.slice(-1)[0]?.puesto_espana, 0)} de {formatNumber(renta_mun.slice(-1)[0]?.municipios_con_dato, 0)} municipios · provincia {formatNumber(renta_mun.slice(-1)[0]?.renta_persona_provincia, 0)} €"
        direction="positive-up"
        source="INE / Atlas de Renta"
        href="/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => ({...d, y: d.renta_persona_real}))}
    />
    <KpiCard
        title="Renta neta por hogar"
        value={renta_mun.slice(-1)[0]?.renta_hogar_real}
        formattedValue="{formatNumber(renta_mun.slice(-1)[0]?.renta_hogar_real, 0)} €"
        period="al año en {renta_mun.slice(-1)[0]?.anio}, euros de 2025"
        direction="positive-up"
        source="INE / Atlas de Renta"
        href="/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => ({...d, y: d.renta_hogar_real}))}
    />
{/if}
{#if paro_mun.length > 0 && !paro_mun[0]?.oculto}
    <KpiCard
        title="Paro registrado"
        value={paro_mun[0]?.por_100_hab}
        formattedValue="{formatNumber(paro_mun[0]?.por_100_hab, 1)} por 100 hab."
        period="{paro_mun[0]?.mes_txt} · {formatNumber(paro_mun[0]?.paro_registrado, 0)} personas ({formatNumber(paro_mun[0]?.variacion_anual_pct, 1)} % en un año)"
        direction="positive-down"
        source="SEPE"
        href="/economia/paro"
        sparklineData={[{x: paro_mun[0]?.mes_iso_hace_1_anio, y: paro_mun[0]?.por_100_hab_hace_1_anio}, {x: paro_mun[0]?.mes_iso, y: paro_mun[0]?.por_100_hab}]}
    />
{/if}
</Grid>

{#if renta_mun.length > 1}
<LineChart
    data={renta_mun}
    x=anio
    y={['renta_persona_real', 'renta_persona_provincia']}
    seriesLabels={{renta_persona_real: mun[0]?.municipio, renta_persona_provincia: 'Provincia'}}
    colorPalette={['#b45309', '#94a3b8']}
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por persona y año (reales)"
    title="Renta neta media por persona, euros de 2025"
/>
{/if}

{#if renta_mun_distritos.length > 1}
<BarChart
    data={renta_mun_distritos}
    x=distrito
    y=renta_persona_real
    yFmt='#,##0" €"'
    title="Renta por persona en cada distrito ({renta_mun_distritos[0]?.anio}, euros de 2025)"
/>
{/if}

<p class="text-xs text-gray-500">Renta: Atlas de Distribución de Renta de los Hogares del INE, a partir de datos tributarios. Paro: demandantes parados registrados en el SEPE el último día del mes, sobre la población total del municipio (no hay población de 16 a 64 años por municipio).</p>

{/if}

```sql barrios_renta
SELECT cod_mun, cod_seccion, seccion, renta_persona_real, renta_hogar_real,
    CASE WHEN renta_persona_tope THEN '≥ ' WHEN renta_persona_suelo THEN '≤ ' ELSE '' END AS renta_persona_marca,
    CASE WHEN renta_hogar_tope THEN '≥ ' WHEN renta_hogar_suelo THEN '≤ ' ELSE '' END AS renta_hogar_marca,
    CAST(anio AS INTEGER) AS anio, CAST(anio_base AS INTEGER) AS anio_base, CAST(geo_anio AS INTEGER) AS geo_anio
FROM mother.renta_secciones
WHERE cod_mun = '${inputs.municipio}' AND renta_persona_real IS NOT NULL
```

```sql barrios_elecciones
SELECT DISTINCT tipo FROM mother.elecciones_secciones WHERE cod_mun = '${inputs.municipio}'
```

```sql barrios_voto
SELECT cod_mun, cod_seccion, seccion, eleccion, CAST(geo_anio AS INTEGER) AS geo_anio,
    participacion, ganador_siglas, ganador_familia, ganador_color, ganador_pct, votantes,
    pct_izquierda, pct_derecha, pct_centro, pct_nacionalistas, pct_psoe, pct_pp, pct_vox, pct_iu_podemos_sumar,
    CASE '${inputs.barrio_capa}'
        WHEN 'izquierda' THEN pct_izquierda WHEN 'derecha' THEN pct_derecha
        WHEN 'centro' THEN pct_centro WHEN 'nacionalistas' THEN pct_nacionalistas
        WHEN 'psoe' THEN pct_psoe WHEN 'pp' THEN pct_pp WHEN 'vox' THEN pct_vox
        WHEN 'ips' THEN pct_iu_podemos_sumar WHEN 'participacion' THEN participacion
    END AS valor
FROM mother.elecciones_secciones
WHERE cod_mun = '${inputs.municipio}' AND tipo = '${inputs.barrio_eleccion}'
```

```sql barrios_quintiles
WITH s AS (
    SELECT v.*, ntile(5) OVER (ORDER BY r.renta_persona_real) AS quintil
    FROM ${barrios_voto} v
    JOIN ${barrios_renta} r USING (cod_seccion)
)
SELECT quintil,
    CASE quintil WHEN 1 THEN '20 % más pobre' WHEN 2 THEN '2.º' WHEN 3 THEN '3.º' WHEN 4 THEN '4.º' ELSE '20 % más rico' END AS grupo,
    bloque, sum(p * votantes) / sum(votantes) AS pct
FROM (
    SELECT quintil, votantes, unnest(['Izquierda', 'Derecha', 'Centro', 'Nacionalistas y regionalistas']) AS bloque,
        unnest([pct_izquierda, pct_derecha, pct_centro, pct_nacionalistas]) AS p
    FROM s
)
GROUP BY quintil, grupo, bloque
HAVING (SELECT count(*) FROM s) >= 10
QUALIFY max(sum(p * votantes) / sum(votantes)) OVER (PARTITION BY bloque) >= 1
ORDER BY quintil
```

{#if barrios_renta.length > 1 || barrios_elecciones.length > 0}

## Barrio a barrio

Cada mancha es una **sección censal**, la unidad más pequeña de la estadística oficial: unas 1.000-2.500 personas que votan en el mismo colegio. Pasa el ratón por encima para ver la cifra de cada una.

{#if barrios_renta.length > 1}

<MapaEspana
    data={barrios_renta}
    geoJsonUrl="/geo/secciones/{barrios_renta[0]?.geo_anio}/{barrios_renta[0]?.cod_mun}.geojson"
    geoId=id
    areaCol=cod_seccion
    encuadre=denso
    value=renta_persona_real
    valueFmt='#,##0" €"'
    colorPalette={['#fef3c7', '#f59e0b', '#78350f']}
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'renta_persona_real', title: 'Renta por persona', prefixCol: 'renta_persona_marca', fmt: '#,##0" €"'}, {id: 'renta_hogar_real', title: 'Por hogar', prefixCol: 'renta_hogar_marca', fmt: '#,##0" €"'}]}
    height=520
    title="Renta neta media por persona en {barrios_renta[0]?.anio} (euros de {barrios_renta[0]?.anio_base})"
/>

{/if}

{#if barrios_elecciones.length > 0}

<ButtonGroup name=barrio_eleccion title="Elección">
    {#if barrios_elecciones.some(e => e.tipo === '02')}<ButtonGroupItem valueLabel="Generales 2023" value="02" default />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '04')}<ButtonGroupItem valueLabel="Municipales 2023" value="04" default={!barrios_elecciones.some(e => e.tipo === '02')} />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '07')}<ButtonGroupItem valueLabel="Europeas 2024" value="07" />{/if}
</ButtonGroup>

<ButtonGroup name=barrio_capa title="Qué ver">
    <ButtonGroupItem valueLabel="Más votado" value="ganador" default />
    <ButtonGroupItem valueLabel="Izquierda" value="izquierda" />
    <ButtonGroupItem valueLabel="Derecha" value="derecha" />
    <ButtonGroupItem valueLabel="Centro" value="centro" />
    <ButtonGroupItem valueLabel="Nacionalistas" value="nacionalistas" />
    <ButtonGroupItem valueLabel="PSOE" value="psoe" />
    <ButtonGroupItem valueLabel="PP" value="pp" />
    <ButtonGroupItem valueLabel="Vox" value="vox" />
    <ButtonGroupItem valueLabel="IU, Podemos y Sumar" value="ips" />
    <ButtonGroupItem valueLabel="Participación" value="participacion" />
</ButtonGroup>

{#if barrios_voto.length > 0}
{#if inputs.barrio_capa === 'ganador'}

<MapaEspana
    data={barrios_voto}
    geoJsonUrl="/geo/secciones/{barrios_voto[0]?.geo_anio}/{barrios_voto[0]?.cod_mun}.geojson"
    geoId=id
    areaCol=cod_seccion
    encuadre=denso
    value=ganador_familia
    colorCol=ganador_color
    intensidad=ganador_pct
    legendType=categorical
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'ganador_siglas', title: 'Más votada'}, {id: 'ganador_pct', title: '% de los válidos', fmt: '0.0"%"'}, {id: 'participacion', title: 'Participación', fmt: '0.0"%"'}]}
    height=520
    title="Candidatura más votada en cada sección · {barrios_voto[0]?.eleccion}"
/>


<p class="text-xs text-gray-500">Cuanto más intenso el color, mayor el porcentaje de la candidatura más votada.</p>

{:else}

<MapaEspana
    data={barrios_voto}
    geoJsonUrl="/geo/secciones/{barrios_voto[0]?.geo_anio}/{barrios_voto[0]?.cod_mun}.geojson"
    geoId=id
    areaCol=cod_seccion
    encuadre=denso
    value=valor
    valueFmt='0.0"%"'
    colorPalette={({izquierda: ['#fef2f2', '#dc2626', '#7f1d1d'], derecha: ['#eff6ff', '#2563eb', '#1e3a8a'], centro: ['#fff7ed', '#f97316', '#7c2d12'], nacionalistas: ['#fefce8', '#ca8a04', '#713f12'], psoe: ['#fef2f2', '#e30613', '#7f1d1d'], pp: ['#eff6ff', '#1d84ce', '#1e3a8a'], vox: ['#f0fdf4', '#5ac035', '#14532d'], ips: ['#faf5ff', '#7b2d8e', '#3b0764'], participacion: ['#f0fdfa', '#0d9488', '#134e4a']})[inputs.barrio_capa] ?? ['#eff6ff', '#3b82f6', '#1e3a8a']}
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'valor', title: '%', fmt: '0.0"%"'}, {id: 'ganador_siglas', title: 'Más votada'}]}
    height=520
    title="{inputs.barrio_capa === 'participacion' ? 'Participación' : ({izquierda: 'Izquierda', derecha: 'Derecha', centro: 'Centro', nacionalistas: 'Nacionalistas y regionalistas', psoe: 'PSOE', pp: 'PP', vox: 'Vox', ips: 'IU, Podemos y Sumar'})[inputs.barrio_capa] + ', % de los válidos'} en cada sección · {barrios_voto[0]?.eleccion}"
/>

{/if}
{:else}

<p class="text-sm text-gray-500">No hay resultados por sección de esta elección en el municipio (en las municipales solo se publican los de más de 250 habitantes con listas cerradas).</p>

{/if}

{#if barrios_quintiles.length > 0}

<BarChart
    data={barrios_quintiles}
    x=grupo
    y=pct
    series=bloque
    type=grouped
    sort=false
    yFmt='0"%"'
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04'}}
    title="¿Votan distinto los barrios ricos y los pobres? Voto por bloque según la renta de la sección · {barrios_voto[0]?.eleccion}"
/>

<p class="text-xs text-gray-500">Las secciones del municipio se ordenan por renta por persona y se parten en cinco grupos con el mismo número de secciones; el voto de cada grupo es la media de sus secciones ponderada por votantes.</p>

{/if}
{/if}

<p class="text-xs text-gray-500">Secciones censales: contornos del INE del año de cada dato. Renta: Atlas de Distribución de Renta de los Hogares del INE, que corta las secciones más ricas y las más pobres a un mismo valor máximo y mínimo (por eso llevan delante «≥» o «≤»). Votos: resultados por mesa del Ministerio del Interior sumados por sección, sin el voto de los residentes en el extranjero. Los porcentajes de voto son sobre votos válidos (candidaturas y en blanco). Las secciones se parten o se renumeran cuando cambia su población, así que alguna puede quedar en gris si no hay dato de ese año.</p>

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

## Viviendas turísticas

<Grid cols=2>
    <KpiCard
        title="Viviendas turísticas"
        value={tur_vut_mun.slice(-1)[0]?.pct_viviendas}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas, 2)} % de las viviendas"
        period="{tur_vut_mun.slice(-1)[0]?.periodo_txt} · España: {formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas_espana, 2)} %"
        source="INE (experimental)"
        href="/economia/turismo"
        sparklineData={tur_vut_mun.filter(d => d.pct_viviendas != null).map(d => ({x: d.periodo, y: d.pct_viviendas}))}
    />
    <KpiCard
        title="Por 1.000 habitantes"
        value={tur_vut_mun.slice(-1)[0]?.viviendas_1000hab}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab, 1)}"
        period="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas, 0)} viviendas con {formatNumber(tur_vut_mun.slice(-1)[0]?.plazas, 0)} plazas · España: {formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab_espana, 1)}"
        source="INE (experimental)"
        sparklineData={tur_vut_mun.filter(d => d.viviendas_1000hab != null).map(d => ({x: d.periodo, y: d.viviendas_1000hab}))}
    />
</Grid>

<p class="text-xs text-gray-500">Viviendas anunciadas como alojamiento turístico en las grandes plataformas digitales (medición experimental del INE, semestral). {#if tur_vut_mun.slice(-1)[0]?.puesto}Es el municipio número {formatNumber(tur_vut_mun.slice(-1)[0]?.puesto, 0)} de {formatNumber(tur_vut_mun.slice(-1)[0]?.n_ranking, 0)} con 1.000 habitantes o más por porcentaje de viviendas turísticas.{/if} Más en <a href="/economia/turismo">Turismo</a>.</p>

{/if}

## Seguridad

<Grid cols=3>
    <KpiCard
        title="Infracciones penales conocidas"
        value={crimen_mun[0]?.tasa}
        formattedValue={formatNumber(crimen_mun[0]?.tasa, 1)}
        period="por 1.000 habitantes en {crimen_mun[0]?.anio} · España: {formatNumber(crimen_mun[0]?.tasa_espana, 1)}"
        source="Ministerio del Interior"
        href="/sociedad/criminalidad"
        sparklineData={crimen_mun_serie.filter(d => d.tasa != null).map(d => ({anio: d.anio, valor: d.tasa}))}
    />
    <KpiCard
        title="Robos con violencia"
        value={crimen_mun[0]?.robos_violencia}
        formattedValue={formatNumber(crimen_mun[0]?.robos_violencia, 2)}
        period="por 1.000 habitantes"
        sparklineData={crimen_mun_serie.filter(d => d.robos_violencia != null).map(d => ({anio: d.anio, valor: d.robos_violencia}))}
    />
    <KpiCard
        title="Robos en domicilios"
        value={crimen_mun[0]?.robos_domicilios}
        formattedValue={formatNumber(crimen_mun[0]?.robos_domicilios, 2)}
        period="por 1.000 habitantes"
        sparklineData={crimen_mun_serie.filter(d => d.robos_domicilios != null).map(d => ({anio: d.anio, valor: d.robos_domicilios}))}
    />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(crimen_mun[0]?.infracciones, 0)} infracciones penales conocidas por las fuerzas de seguridad en el término municipal (Balance de Criminalidad, municipios de más de 20.000 habitantes). En municipios turísticos o con aeropuerto la tasa por vecino empadronado sale alta porque muchas víctimas son visitantes.</p>

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
SELECT e.proceso, e.tipo, e.fecha, CAST(e.anio AS INTEGER) AS anio,
    CASE e.tipo WHEN '02' THEN 'Generales' ELSE 'Municipales' END AS eleccion,
    e.participacion, e.ganador_siglas, e.ganador_familia, b.color AS ganador_color, e.ganador_pct,
    e.pct_izquierda, e.pct_derecha, e.pct_centro, e.pct_nacionalistas, e.pct_psoe, e.pct_pp, e.pct_vox, e.pct_iu_podemos_sumar
FROM mother.elecciones_municipios e
LEFT JOIN (SELECT DISTINCT familia, color FROM mother.elecciones_familias) b ON b.familia = e.ganador_familia
WHERE e.cod_mun = '${inputs.municipio}'
ORDER BY e.fecha
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

## Elecciones

<Grid cols=2>
    <KpiCard title="Participación en las generales" value={elec_mun_gen.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec_mun_gen.slice(-1)[0]?.participacion, 1)} %"
        period="{elec_mun_gen.slice(-1)[0]?.anio} · sin voto de residentes en el extranjero"
        source="Ministerio del Interior" href="/sociedad/elecciones" sparklineData={elec_mun_gen} />
    <KpiCard title="Más votada en las generales" value={elec_mun_gen.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec_mun_gen.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec_mun_gen.slice(-1)[0]?.ganador_pct, 1)} %"
        period="{elec_mun_gen.slice(-1)[0]?.anio}" source="Ministerio del Interior"
        sparklineData={elec_mun_gen.map(d => ({...d, valor: d.ganador_pct}))} />
</Grid>

<LineChart data={elec_mun_bloques} x=fecha y=pct series=bloque yFmt='0"%"' markers=true
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04'}}
    title="Voto por bloque en las generales, % de los votos válidos" />

<DataTable data={elec_mun} rows=10>
    <Column id=anio title="Año" fmt='0' />
    <Column id=eleccion title="Elección" />
    <Column id=ganador_siglas title="Más votada" />
    <Column id=ganador_pct title="% voto" fmt='0.0"%"' />
    <Column id=participacion title="Participación" fmt='0.0"%"' />
</DataTable>

{/if}

## ¿Quién gobierna?

<div class="not-prose rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 my-4" style="border-left: 6px solid {alcalde[0].color}">
    <p class="text-xs uppercase tracking-wide text-gray-500 mb-1">{alcalde[0].cargo} desde el {alcalde[0].desde}</p>
    <p class="text-2xl font-bold text-gray-900 dark:text-white capitalize mb-1">{alcalde[0].alcalde}</p>
    <p class="text-sm text-gray-700 dark:text-gray-300 mb-0">Lista: <b>{alcalde[0].partido_original}</b> · Familia política: <b>{alcalde[0].familia}</b></p>
</div>

<Grid cols=2>
    <KpiCard
        title="Años en el cargo"
        value={alcalde[0]?.anios_en_cargo}
        formattedValue={formatNumber(alcalde[0]?.anios_en_cargo, 1)}
        unit="años"
        period="de forma continuada, incluidos mandatos anteriores"
    />
    <KpiCard
        title="Años de {alcalde[0]?.familia} en la alcaldía"
        value={alcalde[0]?.anios_partido}
        formattedValue={formatNumber(alcalde[0]?.anios_partido, 1)}
        unit="años"
        period="gobierna sin interrupción desde {alcalde[0]?.primer_anio_familia}"
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
    title="Familia política de la alcaldía al empezar cada mandato"
    seriesColors={Object.fromEntries(familias_mandato.map(f => [f.familia, f.color]))}
/>

{/if}

<Details title="Todos los alcaldes desde 1979">

<DataTable data={historia_alcaldes} rows=15>
    <Column id=mandato title="Mandato" />
    <Column id=alcalde title="Alcalde/sa" />
    <Column id=toma_posesion title="Toma de posesión" />
    <Column id=lista title="Lista" />
    <Column id=familia title="Familia" />
</DataTable>

</Details>

<p class="text-xs text-gray-500">Las listas se agrupan en familias políticas (por ejemplo, PSC, PSOE-A o PSdeG-PSOE en «PSOE»). Los años se calculan por continuidad del nombre y de la familia entre mandatos; en 2007-2023 la fuente usa a veces etiquetas genéricas de coalición («C. ELECTORAL», «OTROS»), que aparecen como «Sin detalle en la fuente» cuando no se pueden resolver.</p>

{/if}

---

## Fuentes oficiales

- **[INE – Cifras oficiales de población de los municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministerio de Hacienda – Liquidaciones de las entidades locales (CONPREL)](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: ingresos y gastos por capítulos, áreas y políticas de cada ayuntamiento desde 2010.
- **[Banco de España – Boletín Estadístico, capítulo 14](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: deuda de los ayuntamientos de más de 300.000 habitantes.
- **[Ministerio de Política Territorial – Alcaldes y concejales](https://concejales.redsara.es/consulta/)**: alcalde actual (mandato 2023-2027) y listados históricos de alcaldes desde 1979 del Sistema de Información Local.

<LastRefreshed prefix="Datos actualizados" />
