---
title: Municipis
description: "Cerca qualsevol municipi d'Espanya: població, comptes de l'ajuntament i comparació amb municipis de la seva mida."
i18n_origen: fad225ccb8b9
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorMunicipio from '../../../../../../../src/lib/components/BuscadorMunicipio.svelte';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql lista_municipios
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion
FROM mother.poblacion_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
ORDER BY m.poblacion DESC
```

# 🏘️ El teu municipi en dades

Cerca qualsevol dels més de 8.100 municipis d'Espanya. L'enllaç de la pàgina canvia amb la teva tria, així que el pots compartir tal qual.

<BuscadorMunicipio opciones={lista_municipios} name="municipio" defecto="28079" />

```sql mun
SELECT
    m.cod_mun, m.municipio, m.poblacion, m.anio,
    p.nombre AS provincia, '/ca' || p.ruta AS provincia_ruta,
    c.nombre AS ccaa, '/ca' || c.ruta AS ccaa_ruta
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

<p class="text-sm text-gray-500"><a href="/ca/territorios">Territoris</a> › <a href={mun[0]?.ccaa_ruta}>{mun[0]?.ccaa ?? '…'}</a> › <a href={mun[0]?.provincia_ruta}>{mun[0]?.provincia ?? '…'}</a> › {mun[0]?.municipio ?? '…'}</p>

<Grid cols=3>
    <KpiCard
        title="Població"
        value={mun[0]?.poblacion}
        formattedValue={formatNumber(mun[0]?.poblacion, 0)}
        unit="hab."
        period="1 de gener de {mun[0]?.anio ?? '…'}"
        source="INE – Padró"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Evolució en 10 anys"
        value={poblacion_contexto[0]?.crecimiento_10}
        formattedValue={formatNumber(poblacion_contexto[0]?.crecimiento_10, 1)}
        unit="%"
        direction="positive-up"
        sparklineData={serie_poblacion.slice(-10)}
    />
    <KpiCard
        title="Posició a Espanya per població"
        value={poblacion_contexto[0]?.puesto}
        formattedValue="núm. {formatNumber(poblacion_contexto[0]?.puesto, 0)}"
        period="de {formatNumber(lista_municipios.length, 0)} municipis"
    />
</Grid>

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Població a 1 de gener (Padró)"
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

## Comptes de l'ajuntament

{#if cuentas_ultimo.length > 0}

{#if cuentas_ultimo[0].anio < cuentas_serie.filter(r => !r.provisional).slice(-1)[0]?.anio}

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
L'última dada disponible és del <b>{cuentas_ultimo[0].anio}</b>: des d'aleshores aquest ajuntament no ha tramès a Hisenda la liquidació dels seus pressupostos, de manera que les xifres poden estar molt desactualitzades.
</div>

{/if}

Liquidació del pressupost de l'ajuntament (el que realment s'ha ingressat i gastat, no el que s'havia pressupostat). Perquè la comparació sigui justa, es compara amb la **mediana dels municipis del mateix tram de població** ({cuentas_ultimo[0].tramo} habitants). Els imports són **per habitant** i **descomptada la inflació**, en euros de {base[0]?.anio_base}.

<Grid cols=3>
    <KpiCard
        title="Despesa per habitant"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="Mediana del seu tram: {formatNumber(cuentas_ultimo[0]?.gasto_hab_tramo_real, 0)} € · {cuentas_ultimo[0]?.anio}{cuentas_ultimo[0]?.provisional ? ' (avançament)' : ''}, en euros de {base[0]?.anio_base}"
        source="Ministeri d'Hisenda"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.gasto_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.gasto_hab_real}))}
    />
    <KpiCard
        title="Ingrés per habitant"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="Mediana del seu tram: {formatNumber(cuentas_ultimo[0]?.ingreso_hab_tramo_real, 0)} € · en euros de {base[0]?.anio_base}"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.ingreso_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.ingreso_hab_real}))}
    />
    <KpiCard
        title="Saldo no financer per habitant"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Ingressos − despeses dels capítols 1 a 7, en euros de {base[0]?.anio_base} · total: {formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 1)} € corrents"
        direction="positive-up"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.saldo_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.saldo_hab_real}))}
    />
</Grid>

{#if personal_ayto.length > 0 && personal_ayto[0]?.gastos_c1 != null}

<Grid cols=2>
    <KpiCard
        title="Despesa de personal per habitant"
        value={personal_ayto[0]?.por_habitante}
        formattedValue={formatNumber(personal_ayto[0]?.por_habitante, 0)}
        unit="€"
        period="Mediana del seu tram: {formatNumber(personal_ayto[0]?.mediana_tramo, 0)} € · {personal_ayto[0]?.anio}, en euros de {base[0]?.anio_base}"
        source="Ministeri d'Hisenda (capítol 1)"
        href="/ca/cuentas-publicas/empleo-publico"
    />
    <KpiCard
        title="Pes del personal en la despesa"
        value={personal_ayto[0]?.peso}
        formattedValue="{formatNumber(personal_ayto[0]?.peso / 0.01, 0)} %"
        period="{formatCompact(personal_ayto[0]?.gastos_c1, 1)} € corrents en sous, cotitzacions i retribucions de càrrecs electes"
    />
</Grid>

{/if}

<LineChart
    data={cuentas_grafico}
    x=fecha
    y=euros
    series=serie
    yFmt=num0
    yAxisTitle="€ per habitant"
    title="Despesa per habitant (euros de {base[0]?.anio_base}, descomptada la inflació)"
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
    title="Despesa per habitant segons l'àrea, {cuentas_serie.filter(r => r.tiene_datos && !r.provisional).slice(-1)[0]?.anio} (euros de {base[0]?.anio_base})"
    colorPalette={['#0f766e', '#94a3b8']}
/>

{/if}

{#if politicas_mun.length > 0}

<Details title="Despesa per polítiques ({politicas_mun[0].anio})">

<DataTable data={politicas_mun} rows=all>
    <Column id=politica title="Política de despesa" />
    <Column id=por_habitante title="€/habitant (euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=mediana_tramo title="Mediana del tram (€/hab.)" fmt=num0 />
    <Column id=dif_pct title="Diferència (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Pes" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=importe title="Despesa total (€ corrents)" fmt=num0 />
</DataTable>

</Details>

{/if}

{#if deuda_ayto.length > 0}

<LineChart
    data={deuda_ayto}
    x=fecha
    y=deuda_eur_hab_real
    yFmt=num0
    yAxisTitle="€ per habitant"
    title="Deute de l'ajuntament per habitant (euros de {base[0]?.anio_base}, Banc d'Espanya)"
    lineColor="#b45309"
/>

<p class="text-xs text-gray-500">Deute al final de cada trimestre: {formatCompact(deuda_ayto[deuda_ayto.length - 1]?.deuda_eur, 0)} € corrents en l'última dada. Per habitant amb el Padró de cada any i descomptada la inflació.</p>

{/if}

<p class="text-xs text-gray-500">Només l'ajuntament (no inclou la diputació, les mancomunitats ni les empreses municipals). Els anys en què l'ajuntament no va trametre la liquidació a Hisenda apareixen sense dada, no com a zero.</p>

{:else}

<p class="text-sm text-gray-500">Aquest ajuntament no ha tramès a Hisenda la liquidació dels seus pressupostos en els anys disponibles.</p>

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

## Renda i atur

<Grid cols=3>
{#if renta_mun.length > 0}
    <KpiCard
        title="Renda neta per persona"
        value={renta_mun.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_mun.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="l'any {renta_mun.slice(-1)[0]?.anio}, euros de 2025 · posició {formatNumber(renta_mun.slice(-1)[0]?.puesto_espana, 0)} de {formatNumber(renta_mun.slice(-1)[0]?.municipios_con_dato, 0)} municipis · província {formatNumber(renta_mun.slice(-1)[0]?.renta_persona_provincia, 0)} €"
        direction="positive-up"
        source="INE / Atles de Renda"
        href="/ca/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => ({...d, y: d.renta_persona_real}))}
    />
    <KpiCard
        title="Renda neta per llar"
        value={renta_mun.slice(-1)[0]?.renta_hogar_real}
        formattedValue="{formatNumber(renta_mun.slice(-1)[0]?.renta_hogar_real, 0)} €"
        period="l'any {renta_mun.slice(-1)[0]?.anio}, euros de 2025"
        direction="positive-up"
        source="INE / Atles de Renda"
        href="/ca/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => ({...d, y: d.renta_hogar_real}))}
    />
{/if}
{#if paro_mun.length > 0 && !paro_mun[0]?.oculto}
    <KpiCard
        title="Atur registrat"
        value={paro_mun[0]?.por_100_hab}
        formattedValue="{formatNumber(paro_mun[0]?.por_100_hab, 1)} per 100 hab."
        period="{paro_mun[0]?.mes_txt} · {formatNumber(paro_mun[0]?.paro_registrado, 0)} persones ({formatNumber(paro_mun[0]?.variacion_anual_pct, 1)} % en un any)"
        direction="positive-down"
        source="SEPE"
        href="/ca/economia/paro"
        sparklineData={[{x: paro_mun[0]?.mes_iso_hace_1_anio, y: paro_mun[0]?.por_100_hab_hace_1_anio}, {x: paro_mun[0]?.mes_iso, y: paro_mun[0]?.por_100_hab}]}
    />
{/if}
</Grid>

{#if renta_mun.length > 1}
<LineChart
    data={renta_mun}
    x=anio
    y={['renta_persona_real', 'renta_persona_provincia']}
    seriesLabels={{renta_persona_real: mun[0]?.municipio, renta_persona_provincia: 'Província'}}
    colorPalette={['#b45309', '#94a3b8']}
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per persona i any (reals)"
    title="Renda neta mitjana per persona, euros de 2025"
/>
{/if}

{#if renta_mun_distritos.length > 1}
<BarChart
    data={renta_mun_distritos}
    x=distrito
    y=renta_persona_real
    yFmt='#,##0" €"'
    title="Renda per persona a cada districte ({renta_mun_distritos[0]?.anio}, euros de 2025)"
/>
{/if}

<p class="text-xs text-gray-500">Renda: Atles de Distribució de Renda de les Llars de l'INE, a partir de dades tributàries. Atur: demandants aturats registrats al SEPE l'últim dia del mes, sobre la població total del municipi (no hi ha població de 16 a 64 anys per municipi).</p>

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

## Barri a barri

Cada taca és una **secció censal**, la unitat més petita de l'estadística oficial: unes 1.000-2.500 persones que voten al mateix col·legi. Passa el ratolí per sobre per veure'n la xifra.

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
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'renta_persona_real', title: 'Renda per persona', prefixCol: 'renta_persona_marca', fmt: '#,##0" €"'}, {id: 'renta_hogar_real', title: 'Per llar', prefixCol: 'renta_hogar_marca', fmt: '#,##0" €"'}]}
    height=520
    title="Renda neta mitjana per persona el {barrios_renta[0]?.anio} (euros de {barrios_renta[0]?.anio_base})"
/>

{/if}

{#if barrios_elecciones.length > 0}

<ButtonGroup name=barrio_eleccion title="Elecció">
    {#if barrios_elecciones.some(e => e.tipo === '02')}<ButtonGroupItem valueLabel="Generals 2023" value="02" default />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '04')}<ButtonGroupItem valueLabel="Municipals 2023" value="04" default={!barrios_elecciones.some(e => e.tipo === '02')} />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '07')}<ButtonGroupItem valueLabel="Europees 2024" value="07" />{/if}
</ButtonGroup>

<ButtonGroup name=barrio_capa title="Què veure">
    <ButtonGroupItem valueLabel="Més votat" value="ganador" default />
    <ButtonGroupItem valueLabel="Esquerra" value="izquierda" />
    <ButtonGroupItem valueLabel="Dreta" value="derecha" />
    <ButtonGroupItem valueLabel="Centre" value="centro" />
    <ButtonGroupItem valueLabel="Nacionalistes" value="nacionalistas" />
    <ButtonGroupItem valueLabel="PSOE" value="psoe" />
    <ButtonGroupItem valueLabel="PP" value="pp" />
    <ButtonGroupItem valueLabel="Vox" value="vox" />
    <ButtonGroupItem valueLabel="IU, Podemos i Sumar" value="ips" />
    <ButtonGroupItem valueLabel="Participació" value="participacion" />
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
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'ganador_siglas', title: 'Més votada'}, {id: 'ganador_pct', title: '% dels vàlids', fmt: '0.0"%"'}, {id: 'participacion', title: 'Participació', fmt: '0.0"%"'}]}
    height=520
    title="Candidatura més votada a cada secció · {barrios_voto[0]?.eleccion}"
/>


<p class="text-xs text-gray-500">Com més intens és el color, més alt és el percentatge de la candidatura més votada.</p>

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
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'valor', title: '%', fmt: '0.0"%"'}, {id: 'ganador_siglas', title: 'Més votada'}]}
    height=520
    title="{inputs.barrio_capa === 'participacion' ? 'Participació' : ({izquierda: 'Esquerra', derecha: 'Dreta', centro: 'Centre', nacionalistas: 'Nacionalistes i regionalistes', psoe: 'PSOE', pp: 'PP', vox: 'Vox', ips: 'IU, Podemos i Sumar'})[inputs.barrio_capa] + ', % dels vàlids'} a cada secció · {barrios_voto[0]?.eleccion}"
/>

{/if}
{:else}

<p class="text-sm text-gray-500">No hi ha resultats per secció d'aquesta elecció al municipi (a les municipals només es publiquen els de més de 250 habitants amb llistes tancades).</p>

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
    title="Voten diferent els barris rics i els pobres? Vot per bloc segons la renda de la secció · {barrios_voto[0]?.eleccion}"
/>

<p class="text-xs text-gray-500">Les seccions del municipi s'ordenen per renda per persona i es parteixen en cinc grups amb el mateix nombre de seccions; el vot de cada grup és la mitjana de les seves seccions ponderada per votants.</p>

{/if}
{/if}

<p class="text-xs text-gray-500">Seccions censals: contorns de l'INE de l'any de cada dada. Renda: Atles de Distribució de Renda de les Llars de l'INE, que talla les seccions més riques i les més pobres a un mateix valor màxim i mínim (per això porten al davant «≥» o «≤»). Vots: resultats per mesa del Ministeri de l'Interior sumats per secció, sense el vot dels residents a l'estranger. Els percentatges de vot són sobre vots vàlids (candidatures i en blanc). Les seccions es parteixen o es renumeren quan canvia la seva població, així que alguna pot quedar en gris si no hi ha dada d'aquell any.</p>

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

## Habitatges turístics

<Grid cols=2>
    <KpiCard
        title="Habitatges turístics"
        value={tur_vut_mun.slice(-1)[0]?.pct_viviendas}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas, 2)} % dels habitatges"
        period="{new Date(tur_vut_mun.slice(-1)[0]?.periodo).toLocaleDateString('ca-ES', {month: 'long', year: 'numeric', timeZone: 'UTC'})} · Espanya: {formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas_espana, 2)} %"
        source="INE (experimental)"
        href="/ca/economia/turismo"
        sparklineData={tur_vut_mun.filter(d => d.pct_viviendas != null).map(d => ({x: d.periodo, y: d.pct_viviendas}))}
    />
    <KpiCard
        title="Per 1.000 habitants"
        value={tur_vut_mun.slice(-1)[0]?.viviendas_1000hab}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab, 1)}"
        period="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas, 0)} habitatges amb {formatNumber(tur_vut_mun.slice(-1)[0]?.plazas, 0)} places · Espanya: {formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab_espana, 1)}"
        source="INE (experimental)"
        sparklineData={tur_vut_mun.filter(d => d.viviendas_1000hab != null).map(d => ({x: d.periodo, y: d.viviendas_1000hab}))}
    />
</Grid>

<p class="text-xs text-gray-500">Habitatges anunciats com a allotjament turístic a les grans plataformes digitals (mesura experimental de l'INE, semestral). {#if tur_vut_mun.slice(-1)[0]?.puesto}És el municipi número {formatNumber(tur_vut_mun.slice(-1)[0]?.puesto, 0)} de {formatNumber(tur_vut_mun.slice(-1)[0]?.n_ranking, 0)} amb 1.000 habitants o més per percentatge d'habitatges turístics.{/if} Més a <a href="/ca/economia/turismo">Turisme</a>.</p>

{/if}

## Seguretat

<Grid cols=3>
    <KpiCard
        title="Infraccions penals conegudes"
        value={crimen_mun[0]?.tasa}
        formattedValue={formatNumber(crimen_mun[0]?.tasa, 1)}
        period="per 1.000 habitants el {crimen_mun[0]?.anio} · Espanya: {formatNumber(crimen_mun[0]?.tasa_espana, 1)}"
        source="Ministeri de l'Interior"
        href="/ca/sociedad/criminalidad"
        sparklineData={crimen_mun_serie.filter(d => d.tasa != null).map(d => ({anio: d.anio, valor: d.tasa}))}
    />
    <KpiCard
        title="Robatoris amb violència"
        value={crimen_mun[0]?.robos_violencia}
        formattedValue={formatNumber(crimen_mun[0]?.robos_violencia, 2)}
        period="per 1.000 habitants"
        sparklineData={crimen_mun_serie.filter(d => d.robos_violencia != null).map(d => ({anio: d.anio, valor: d.robos_violencia}))}
    />
    <KpiCard
        title="Robatoris en domicilis"
        value={crimen_mun[0]?.robos_domicilios}
        formattedValue={formatNumber(crimen_mun[0]?.robos_domicilios, 2)}
        period="per 1.000 habitants"
        sparklineData={crimen_mun_serie.filter(d => d.robos_domicilios != null).map(d => ({anio: d.anio, valor: d.robos_domicilios}))}
    />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(crimen_mun[0]?.infracciones, 0)} infraccions penals conegudes per les forces de seguretat al terme municipal (Balanç de Criminalitat, municipis de més de 20.000 habitants). En municipis turístics o amb aeroport la taxa per veí empadronat surt alta perquè moltes víctimes són visitants.</p>

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

## Eleccions

<Grid cols=2>
    <KpiCard title="Participació a les generals" value={elec_mun_gen.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec_mun_gen.slice(-1)[0]?.participacion, 1)} %"
        period="{elec_mun_gen.slice(-1)[0]?.anio} · sense el vot dels residents a l'estranger"
        source="Ministeri de l'Interior" href="/ca/sociedad/elecciones" sparklineData={elec_mun_gen} />
    <KpiCard title="Més votada a les generals" value={elec_mun_gen.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec_mun_gen.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec_mun_gen.slice(-1)[0]?.ganador_pct, 1)} %"
        period="{elec_mun_gen.slice(-1)[0]?.anio}" source="Ministeri de l'Interior"
        sparklineData={elec_mun_gen.map(d => ({...d, valor: d.ganador_pct}))} />
</Grid>

<LineChart data={elec_mun_bloques} x=fecha y=pct series=bloque yFmt='0"%"' markers=true
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04'}}
    title="Vot per bloc a les generals, % dels vots vàlids" />

<DataTable data={elec_mun} rows=10>
    <Column id=anio title="Any" fmt='0' />
    <Column id=eleccion title="Elecció" />
    <Column id=ganador_siglas title="Més votada" />
    <Column id=ganador_pct title="% vot" fmt='0.0"%"' />
    <Column id=participacion title="Participació" fmt='0.0"%"' />
</DataTable>

{/if}

## Qui governa?

<div class="not-prose rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 my-4" style="border-left: 6px solid {alcalde[0].color}">
    <p class="text-xs uppercase tracking-wide text-gray-500 mb-1">{alcalde[0].cargo} des del {alcalde[0].desde}</p>
    <p class="text-2xl font-bold text-gray-900 dark:text-white capitalize mb-1">{alcalde[0].alcalde}</p>
    <p class="text-sm text-gray-700 dark:text-gray-300 mb-0">Llista: <b>{alcalde[0].partido_original}</b> · Família política: <b>{alcalde[0].familia}</b></p>
</div>

<Grid cols=2>
    <KpiCard
        title="Anys en el càrrec"
        value={alcalde[0]?.anios_en_cargo}
        formattedValue={formatNumber(alcalde[0]?.anios_en_cargo, 1)}
        unit="anys"
        period="de manera continuada, inclosos mandats anteriors"
    />
    <KpiCard
        title="Anys de {alcalde[0]?.familia} a l'alcaldia"
        value={alcalde[0]?.anios_partido}
        formattedValue={formatNumber(alcalde[0]?.anios_partido, 1)}
        unit="anys"
        period="governa sense interrupció des del {alcalde[0]?.primer_anio_familia}"
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
    title="Família política de l'alcaldia en començar cada mandat"
    seriesColors={Object.fromEntries(familias_mandato.map(f => [f.familia, f.color]))}
/>

{/if}

<Details title="Tots els alcaldes des del 1979">

<DataTable data={historia_alcaldes} rows=15>
    <Column id=mandato title="Mandat" />
    <Column id=alcalde title="Alcalde/essa" />
    <Column id=toma_posesion title="Presa de possessió" />
    <Column id=lista title="Llista" />
    <Column id=familia title="Família" />
</DataTable>

</Details>

<p class="text-xs text-gray-500">Les llistes s'agrupen en famílies polítiques (per exemple, PSC, PSOE-A o PSdeG-PSOE a «PSOE»). Els anys es calculen per continuïtat del nom i de la família entre mandats; entre el 2007 i el 2023 la font fa servir de vegades etiquetes genèriques de coalició («C. ELECTORAL», «OTROS»), que apareixen com a «Sin detalle en la fuente» quan no es poden resoldre.</p>

{/if}

---

## Fonts oficials

- **[INE – Xifres oficials de població dels municipis (Padró)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministeri d'Hisenda – Liquidacions de les entitats locals (CONPREL)](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: ingressos i despeses per capítols, àrees i polítiques de cada ajuntament des del 2010.
- **[Banc d'Espanya – Butlletí Estadístic, capítol 14](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: deute dels ajuntaments de més de 300.000 habitants.
- **[Ministeri de Política Territorial – Alcaldes i regidors](https://concejales.redsara.es/consulta/)**: alcalde actual (mandat 2023-2027) i llistats històrics d'alcaldes des del 1979 del Sistema d'Informació Local.

<LastRefreshed prefix="Dades actualitzades" />
