---
title: Municipios
description: "Busca calquera municipio de España: poboación, contas do concello e comparación con municipios do seu tamaño."
i18n_origen: 7ba463802b8c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorMunicipio from '../../../../../../../src/lib/components/BuscadorMunicipio.svelte';
    import MapaBarrios from '../../../../../../../src/lib/components/MapaBarrios.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import { etiquetaSuelo, etiquetasSuelo, puntosPorTextura, celdasMunicipio } from '../../../../../../../src/lib/suelos.js';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { idiomaDeRuta } from '../../../../../../../src/lib/i18n.js';
    import { page as paginaActual } from '$app/stores';
    $: idioma = idiomaDeRuta($paginaActual.url.pathname);
    $: suelo_toda = Array.from(suelo_mun ?? []).find((d) => d.cultivo === 'Toda la superficie agraria');
    $: suelo_prov = Array.from(suelo_ref ?? []).find((d) => d.nivel === 'provincia');
    $: suelo_esp = Array.from(suelo_ref ?? []).find((d) => d.nivel === 'pais');
    // Celdas de 250 m del municipio (fichero estático, ver tools/geo/suelos250.py)
    let celdas = [];
    $: cargarCeldas(suelo_toda?.cod_mun);
    function cargarCeldas(cod) {
        if (!cod) { celdas = []; return; }
        celdasMunicipio(cod).then((f) => { if (suelo_toda?.cod_mun === cod) celdas = f; });
    }
</script>

```sql lista_municipios
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion
FROM mother.poblacion_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
ORDER BY m.poblacion DESC
```

# 🏘️ O teu municipio en datos

Busca calquera dos máis de 8.100 municipios de España. A ligazón da páxina cambia coa túa elección, así que podes compartila tal cal.

<BuscadorMunicipio opciones={lista_municipios} name="municipio" defecto="28079" listo={mun[0]?.cod_mun} />

```sql mun
SELECT
    m.cod_mun, m.municipio, m.poblacion, m.anio,
    p.nombre AS provincia, '/gl' || p.ruta AS provincia_ruta,
    c.nombre AS ccaa, '/gl' || c.ruta AS ccaa_ruta
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
    WHERE cod_mun = '${inputs.municipio}' AND anio = (SELECT min(anio) FROM mother.poblacion_municipios WHERE anio >= (SELECT max(anio) - 10 FROM mother.poblacion_municipios))
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

<p class="text-sm text-gray-500"><a href="/gl/territorios">Territorios</a> › <a href={mun[0]?.ccaa_ruta}>{mun[0]?.ccaa ?? '…'}</a> › <a href={mun[0]?.provincia_ruta}>{mun[0]?.provincia ?? '…'}</a> › {mun[0]?.municipio ?? '…'}</p>

{#if inputs.municipio === '34120'}

<p><strong>Persoa destacada:</strong> Jonatan.</p>

{/if}

<Grid cols=3>
    <KpiCard
        title="Poboación"
        value={mun[0]?.poblacion}
        formattedValue={formatNumber(mun[0]?.poblacion, 0)}
        unit="hab."
        period="1 de xaneiro de {mun[0]?.anio ?? '…'}"
        source="INE – Padrón"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Evolución en 10 anos"
        value={poblacion_contexto[0]?.crecimiento_10}
        formattedValue={formatNumber(poblacion_contexto[0]?.crecimiento_10, 1)}
        unit="%"
        direction="positive-up"
        sparklineData={serie_poblacion.slice(-10)}
    />
    <KpiCard
        title="Posto en España por poboación"
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
    title="Poboación a 1 de xaneiro (Padrón)"
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

## Contas do concello

{#if cuentas_ultimo.length > 0}

{#if cuentas_ultimo[0].anio < cuentas_serie.filter(r => !r.provisional).slice(-1)[0]?.anio}

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-3 my-3 text-sm text-amber-900 dark:text-amber-200">
O último dato dispoñible é de <b>{cuentas_ultimo[0].anio}</b>: desde entón este concello non remitiu a Facenda a liquidación dos seus orzamentos, así que as cifras poden estar moi desactualizadas.
</div>

{/if}

Liquidación do orzamento do concello (o realmente ingresado e gastado, non o orzado). Para que a comparación sexa xusta, compárase coa **mediana dos municipios do seu mesmo tramo de poboación** ({cuentas_ultimo[0].tramo} habitantes). Os importes van **por habitante** e **descontada a inflación**, en euros de {base[0]?.anio_base}.

<Grid cols=3>
    <KpiCard
        title="Gasto por habitante"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="Mediana do seu tramo: {formatNumber(cuentas_ultimo[0]?.gasto_hab_tramo_real, 0)} € · {cuentas_ultimo[0]?.anio}{cuentas_ultimo[0]?.provisional ? ' (avance)' : ''}, en euros de {base[0]?.anio_base}"
        source="Ministerio de Facenda"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.gasto_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.gasto_hab_real}))}
    />
    <KpiCard
        title="Ingreso por habitante"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="Mediana do seu tramo: {formatNumber(cuentas_ultimo[0]?.ingreso_hab_tramo_real, 0)} € · en euros de {base[0]?.anio_base}"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.ingreso_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.ingreso_hab_real}))}
    />
    <KpiCard
        title="Saldo non financeiro por habitante"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Ingresos − gastos dos capítulos 1 a 7, en euros de {base[0]?.anio_base} · total: {formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 1)} € correntes"
        direction="positive-up"
        sparklineData={cuentas_serie.filter(r => r.tiene_datos && r.saldo_hab_real != null && r.anio <= cuentas_ultimo[0]?.anio).map(r => ({anio: r.anio, valor: r.saldo_hab_real}))}
    />
</Grid>

{#if personal_ayto.length > 0 && personal_ayto[0]?.gastos_c1 != null}

<Grid cols=2>
    <KpiCard
        title="Gasto de persoal por habitante"
        value={personal_ayto[0]?.por_habitante}
        formattedValue={formatNumber(personal_ayto[0]?.por_habitante, 0)}
        unit="€"
        period="Mediana do seu tramo: {formatNumber(personal_ayto[0]?.mediana_tramo, 0)} € · {personal_ayto[0]?.anio}, en euros de {base[0]?.anio_base}"
        source="Ministerio de Facenda (capítulo 1)"
        href="/gl/cuentas-publicas/empleo-publico"
    />
    <KpiCard
        title="Peso do persoal no gasto"
        value={personal_ayto[0]?.peso}
        formattedValue="{formatNumber(personal_ayto[0]?.peso / 0.01, 0)} %"
        period="{formatCompact(personal_ayto[0]?.gastos_c1, 1)} € correntes en soldos, cotizacións e retribucións de cargos electos"
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
    title="Gasto por habitante (euros de {base[0]?.anio_base}, descontada a inflación)"
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
    title="Gasto por habitante segundo a área, {cuentas_serie.filter(r => r.tiene_datos && !r.provisional).slice(-1)[0]?.anio} (euros de {base[0]?.anio_base})"
    colorPalette={['#0f766e', '#94a3b8']}
/>

{/if}

{#if politicas_mun.length > 0}

<Details title="Gasto por políticas ({politicas_mun[0].anio})">

<DataTable data={politicas_mun} rows=all>
    <Column id=politica title="Política de gasto" />
    <Column id=por_habitante title="€/habitante (euros de {base[0]?.anio_base})" fmt=num0 />
    <Column id=mediana_tramo title="Mediana do tramo (€/hab.)" fmt=num0 />
    <Column id=dif_pct title="Diferenza (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Peso" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=importe title="Gasto total (€ correntes)" fmt=num0 />
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
    title="Débeda do concello por habitante (euros de {base[0]?.anio_base}, Banco de España)"
    lineColor="#b45309"
/>

<p class="text-xs text-gray-500">Débeda ao final de cada trimestre: {formatCompact(deuda_ayto[deuda_ayto.length - 1]?.deuda_eur, 0)} € correntes no último dato. Por habitante co Padrón de cada ano e descontada a inflación.</p>

{/if}

<p class="text-xs text-gray-500">Só concello (non inclúe deputación, mancomunidades nin empresas municipais). Os anos en que o concello non remitiu a súa liquidación a Facenda aparecen sen dato, non como cero.</p>

{:else}

<p class="text-sm text-gray-500">Este concello non remitiu a Facenda a liquidación dos seus orzamentos nos anos dispoñibles.</p>

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

```sql tr_ent
SELECT * FROM mother.transparencia_cumplimiento_entidad
WHERE tipo_entidad = 'Ayuntamiento' AND cod_mun = '${inputs.municipio}'
```

```sql tr_obl
SELECT obligacion_nombre AS obligacion, periodo, strftime(fecha_plazo, '%d/%m/%Y') AS plazo, estado,
    CASE estado
        WHEN 'en_plazo' THEN '✅ En plazo'
        WHEN 'consta' THEN '✅ Consta'
        WHEN 'fuera_plazo' THEN '🟠 Fuera de plazo'
        WHEN 'no_consta' THEN '🔴 No consta'
        WHEN 'con_registros' THEN CASE WHEN n_fuera_plazo = 0 THEN '✅ Todo en plazo'
            ELSE '🟠 ' || n_fuera_plazo || ' de ' || n_total || ' fuera de plazo' END
        WHEN 'sin_registros' THEN '⚪ Sin registros'
        ELSE estado END AS situacion,
    dias_retraso, mediana_dias, gobernante_en_plazo, familia_en_plazo, url_fuente,
    100 * puntuacion AS nota
FROM mother.transparencia_cumplimiento
WHERE tipo_entidad = 'Ayuntamiento' AND cod_mun = '${inputs.municipio}' AND es_ultimo
ORDER BY puntuacion, fecha_plazo DESC
```

```sql tr_serie
-- Nota media por año del ayuntamiento frente a la de los de su tramo de población
WITH t AS (
    SELECT cod_mun, anio, tramo_poblacion, puntuacion
    FROM mother.transparencia_cumplimiento
    WHERE tipo_entidad = 'Ayuntamiento' AND puntuacion IS NOT NULL AND vencido IS DISTINCT FROM false
),
propio AS (
    SELECT anio, avg(puntuacion) AS nota, any_value(tramo_poblacion) AS tramo FROM t WHERE cod_mun = '${inputs.municipio}' GROUP BY anio
)
SELECT CAST(CAST(p.anio AS INTEGER) AS VARCHAR) AS anio, 'Este ayuntamiento' AS serie, 100 * p.nota AS nota FROM propio p
UNION ALL
SELECT CAST(CAST(t.anio AS INTEGER) AS VARCHAR), 'Media de su tamaño', 100 * avg(t.puntuacion)
FROM t JOIN propio p ON p.anio = t.anio AND p.tramo = t.tramo_poblacion
GROUP BY t.anio
ORDER BY 1, 2
```

```sql tr_eval
SELECT evaluador, indice, periodo, puntuacion, escala_original, puntuacion_original, estado, url_pagina
FROM mother.transparencia_publicidad_activa
WHERE cod_mun = '${inputs.municipio}' AND tipo_administracion = 'Ayuntamiento'
QUALIFY row_number() OVER (PARTITION BY evaluador ORDER BY orden_periodo DESC) = 1
```

{#if tr_obl.length > 0}

## Transparencia

{#if tr_ent[0]?.n_incumplimientos_destacados > 0}
<div role="alert" class="not-prose my-4 rounded-xl border-2 border-red-600 bg-red-50 p-4 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Non consta no rexistro oficial</p>
    <p class="mt-1 text-lg font-extrabold leading-snug text-red-700 dark:text-red-300">{tr_ent[0].incumplimientos}</p>
    <p class="mt-1 text-sm text-red-900 dark:text-red-100">O prazo legal venceu hai máis de tres meses e non figura na fonte oficial á data da última descarga. Pode terse remitido por outra canle: cada fila da táboa enlaza á súa fonte.</p>
</div>
{/if}

Remite este concello a tempo o que lle obriga a lei? É unha **medición propia** de SpainFacts con rexistros oficiais que levan data. Facenda, o Tribunal de Contas, a Base de Datos Nacional de Subvencións e a Plataforma de Contratación din se cada obriga consta e cando chegou fronte ao seu prazo ([criterios e código](/gl/fuentes#datos-de-elaboración-propia)). Compárase cos concellos do seu tamaño ({tr_ent[0]?.tramo_poblacion} habitantes).

<Grid cols=3>
    <KpiCard
        title="Índice de cumprimento"
        value={tr_ent[0]?.indice}
        formattedValue={tr_ent[0]?.indice == null ? 'Sen índice' : formatNumber(tr_ent[0]?.indice, 1) + ' de 100'}
        period="Media do seu tamaño en España: {formatNumber(tr_ent[0]?.media_tramo_espana, 1)} · na súa provincia: {formatNumber(tr_ent[0]?.media_tramo_provincia, 1)}"
        source="SpainFacts (elaboración propia)"
        sparklineData={tr_serie.filter(d => d.serie === 'Este ayuntamiento').map(d => ({...d, y: d.nota}))}
    />
    <KpiCard
        title="Obrigas vencidas que non constan"
        value={tr_ent[0]?.n_incumplimientos_destacados}
        formattedValue={formatNumber(tr_ent[0]?.n_incumplimientos_destacados ?? 0, 0)}
        period="de {formatNumber(tr_ent[0]?.obligaciones_medidas, 0)} medidas, máis de 3 meses despois do prazo"
        source="SpainFacts (elaboración propia)"
    />
    <KpiCard
        title="Posto entre os concellos"
        value={tr_ent[0]?.puesto}
        formattedValue={tr_ent[0]?.puesto == null ? '—' : formatNumber(tr_ent[0]?.puesto, 0) + '.º'}
        period="de {formatNumber(tr_ent[0]?.total_tipo, 0)} con índice (1.º = o que mellor cumpre; empatan moitos)"
        source="SpainFacts (elaboración propia)"
    />
</Grid>

<DataTable data={tr_obl} rows=all link=url_fuente showLinkCol=false>
    <Column id=obligacion title="Obriga" />
    <Column id=periodo title="Período" />
    <Column id=plazo title="Prazo" />
    <Column id=situacion title="Situación" />
    <Column id=dias_retraso title="Días de atraso" fmt=num0 />
    <Column id=mediana_dias title="Días que tarda (mediana)" fmt=num0 />
    <Column id=gobernante_en_plazo title="Alcalde o día do prazo" />
    <Column id=familia_en_plazo title="Partido" />
</DataTable>

<p class="text-xs text-gray-500">Móstrase o último período con prazo vencido de cada obriga. «Sen rexistros» non é un incumprimento: pode que non conceda subvencións ou que contrate por el a deputación. Fai clic nunha fila para ir á fonte oficial.</p>

{#if tr_serie.length > 2}
<LineChart
    data={tr_serie}
    x=anio
    y=nota
    series=serie
    yFmt=num0
    yMin=0
    yMax=100
    markers=true
    sort=false
    title="Cumprimento por ano (0-100)"
/>
{/if}

{#if tr_eval.length > 0}

Ademais, este concello ten unha **avaliación oficial** do seu portal de transparencia (con outro método, non comparable coa medición propia):

<DataTable data={tr_eval} rows=all link=url_pagina showLinkCol=false>
    <Column id=evaluador title="Avaliador" />
    <Column id=indice title="Índice" />
    <Column id=periodo title="Avaliación" />
    <Column id=puntuacion title="Nota (sobre 100)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>
{/if}

Todos os concellos, o método e a comparación por partido están en [Publicidade activa](/gl/transparencia/publicidad-activa#medición-propia-todas-as-administracións).

{/if}

{#if renta_mun.length > 0 || paro_mun.length > 0}

## Renda e paro

<Grid cols=3>
{#if renta_mun.length > 0}
    <KpiCard
        title="Renda neta por persoa"
        value={renta_mun.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_mun.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="ao ano en {renta_mun.slice(-1)[0]?.anio}, euros de 2025 · posto {formatNumber(renta_mun.slice(-1)[0]?.puesto_espana, 0)} de {formatNumber(renta_mun.slice(-1)[0]?.municipios_con_dato, 0)} municipios · provincia {formatNumber(renta_mun.slice(-1)[0]?.renta_persona_provincia, 0)} €"
        direction="positive-up"
        source="INE / Atlas de Renda"
        href="/gl/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => ({...d, y: d.renta_persona_real}))}
    />
    <KpiCard
        title="Renda neta por fogar"
        value={renta_mun.slice(-1)[0]?.renta_hogar_real}
        formattedValue="{formatNumber(renta_mun.slice(-1)[0]?.renta_hogar_real, 0)} €"
        period="ao ano en {renta_mun.slice(-1)[0]?.anio}, euros de 2025"
        direction="positive-up"
        source="INE / Atlas de Renda"
        href="/gl/sociedad/desigualdad"
        sparklineData={renta_mun.map(d => ({...d, y: d.renta_hogar_real}))}
    />
{/if}
{#if paro_mun.length > 0 && !paro_mun[0]?.oculto}
    <KpiCard
        title="Paro rexistrado"
        value={paro_mun[0]?.por_100_hab}
        formattedValue="{formatNumber(paro_mun[0]?.por_100_hab, 1)} por 100 hab."
        period="{paro_mun[0]?.mes_txt} · {formatNumber(paro_mun[0]?.paro_registrado, 0)} persoas ({formatNumber(paro_mun[0]?.variacion_anual_pct, 1)} % nun ano)"
        direction="positive-down"
        source="SEPE"
        href="/gl/economia/paro"
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
    yAxisTitle="€ por persoa e ano (reais)"
    title="Renda neta media por persoa, euros de 2025"
/>
{/if}

{#if renta_mun_distritos.length > 1}
<BarChart
    data={renta_mun_distritos}
    x=distrito
    y=renta_persona_real
    yFmt='#,##0" €"'
    title="Renda por persoa en cada distrito ({renta_mun_distritos[0]?.anio}, euros de 2025)"
/>
{/if}

<p class="text-xs text-gray-500">Renda: Atlas de Distribución de Renda dos Fogares do INE, a partir de datos tributarios. Paro: demandantes parados rexistrados no SEPE o último día do mes, sobre a poboación total do municipio (non hai poboación de 16 a 64 anos por municipio).</p>

{/if}

```sql barrios_renta
SELECT cod_mun, cod_seccion, seccion, renta_persona_real, renta_hogar_real,
    CASE WHEN renta_persona_tope THEN '≥ ' WHEN renta_persona_suelo THEN '≤ ' ELSE '' END AS renta_persona_marca,
    CASE WHEN renta_hogar_tope THEN '≥ ' WHEN renta_hogar_suelo THEN '≤ ' ELSE '' END AS renta_hogar_marca,
    CAST(anio AS INTEGER) AS anio, CAST(anio_base AS INTEGER) AS anio_base, CAST(geo_anio AS INTEGER) AS geo_anio
FROM mother.renta_secciones
WHERE cod_mun = '${inputs.municipio}' AND renta_persona_real IS NOT NULL
```

```sql barrios_renta_espana
-- Escala de toda España para el mapa de renta por barrio: percentiles 5, 50 y 95 de todas las secciones
SELECT quantile_cont(renta_persona_real, 0.05) AS p05, quantile_cont(renta_persona_real, 0.5) AS p50,
    quantile_cont(renta_persona_real, 0.95) AS p95
FROM mother.renta_secciones
WHERE renta_persona_real IS NOT NULL
```

```sql barrios_elecciones
SELECT tipo, max(anio) AS anio FROM mother.elecciones_secciones WHERE cod_mun = '${inputs.municipio}' GROUP BY tipo
```

```sql barrios_voto
SELECT cod_mun, cod_seccion, seccion, eleccion, proceso, cobertura, CAST(geo_anio AS INTEGER) AS geo_anio,
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
  -- autonómicas: la última de la comunidad (Cáceres tiene dos)
  AND proceso = (SELECT max(proceso) FROM mother.elecciones_secciones
                 WHERE cod_mun = '${inputs.municipio}' AND tipo = '${inputs.barrio_eleccion}')
```

```sql barrios_voto_espana
-- Escala de referencia de los mapas de voto por barrio: percentiles 5, 50 y 95 de todas las secciones
-- de cada elección (de España; en las autonómicas, de la comunidad) y capa
SELECT proceso, capa, quantile_cont(v, 0.05) AS p05, quantile_cont(v, 0.5) AS p50, quantile_cont(v, 0.95) AS p95
FROM (
    SELECT proceso,
        unnest(['izquierda', 'derecha', 'centro', 'nacionalistas', 'psoe', 'pp', 'vox', 'ips', 'participacion']) AS capa,
        unnest([pct_izquierda, pct_derecha, pct_centro, pct_nacionalistas, pct_psoe, pct_pp, pct_vox, pct_iu_podemos_sumar, participacion]) AS v
    FROM mother.elecciones_secciones
)
WHERE v IS NOT NULL
GROUP BY ALL
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

Cada mancha é unha **sección censual**, a unidade máis pequena da estatística oficial: unhas 1.000-2.500 persoas que votan no mesmo colexio. Pasa o rato por riba para ver a cifra de cada unha.

{#if barrios_renta.length > 1}

<MapaBarrios
    data={barrios_renta}
    geoJsonUrl="/geo/secciones/{barrios_renta[0]?.geo_anio}/{barrios_renta[0]?.cod_mun}.geojson"
    geoId=id
    areaCol=cod_seccion
    value=renta_persona_real
    referencia={barrios_renta_espana[0]}
    valueFmt='#,##0" €"'
    colorPalette={['#fef3c7', '#f59e0b', '#78350f']}
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'renta_persona_real', title: 'Renda por persoa', prefixCol: 'renta_persona_marca', fmt: '#,##0" €"'}, {id: 'renta_hogar_real', title: 'Por fogar', prefixCol: 'renta_hogar_marca', fmt: '#,##0" €"'}]}
    height=520
    title="Renda neta media por persoa en {barrios_renta[0]?.anio} (euros de {barrios_renta[0]?.anio_base})"
/>

{/if}

{#if barrios_elecciones.length > 0}

<ButtonGroup name=barrio_eleccion title="Elección">
    {#if barrios_elecciones.some(e => e.tipo === '02')}<ButtonGroupItem valueLabel="Xerais 2023" value="02" default />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '04')}<ButtonGroupItem valueLabel="Municipais 2023" value="04" default={!barrios_elecciones.some(e => e.tipo === '02')} />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '07')}<ButtonGroupItem valueLabel="Europeas 2024" value="07" />{/if}
    {#if barrios_elecciones.some(e => e.tipo === '05')}<ButtonGroupItem valueLabel="Autonómicas {barrios_elecciones.find(e => e.tipo === '05')?.anio}" value="05" />{/if}
</ButtonGroup>

<ButtonGroup name=barrio_capa title="Que ver">
    <ButtonGroupItem valueLabel="Máis votado" value="ganador" default />
    <ButtonGroupItem valueLabel="Esquerda" value="izquierda" />
    <ButtonGroupItem valueLabel="Dereita" value="derecha" />
    <ButtonGroupItem valueLabel="Centro" value="centro" />
    <ButtonGroupItem valueLabel="Nacionalistas" value="nacionalistas" />
    <ButtonGroupItem valueLabel="PSOE" value="psoe" />
    <ButtonGroupItem valueLabel="PP" value="pp" />
    <ButtonGroupItem valueLabel="Vox" value="vox" />
    <ButtonGroupItem valueLabel="IU, Podemos e Sumar" value="ips" />
    <ButtonGroupItem valueLabel="Participación" value="participacion" />
</ButtonGroup>

{#if barrios_voto[0]?.cobertura}

<p class="text-sm text-amber-700 dark:text-amber-400">Aviso da fonte: {barrios_voto[0].cobertura}.</p>

{/if}

{#if barrios_voto.length > 0}
{#if inputs.barrio_capa === 'ganador'}

<MapaBarrios
    data={barrios_voto}
    geoJsonUrl="/geo/secciones/{barrios_voto[0]?.geo_anio}/{barrios_voto[0]?.cod_mun}.geojson"
    geoId=id
    areaCol=cod_seccion
    value=ganador_familia
    colorCol=ganador_color
    intensidad=ganador_pct
    legendType=categorical
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'ganador_siglas', title: 'Máis votada'}, {id: 'ganador_pct', title: '% dos válidos', fmt: '0.0"%"'}, {id: 'participacion', title: 'Participación', fmt: '0.0"%"'}]}
    height=520
    title="Candidatura máis votada en cada sección · {barrios_voto[0]?.eleccion}"
/>


<p class="text-xs text-gray-500">Canto máis intensa a cor, maior a porcentaxe da candidatura máis votada.</p>

{:else}

<MapaBarrios
    data={barrios_voto}
    geoJsonUrl="/geo/secciones/{barrios_voto[0]?.geo_anio}/{barrios_voto[0]?.cod_mun}.geojson"
    geoId=id
    areaCol=cod_seccion
    value=valor
    referencia={barrios_voto_espana.find(e => e.proceso === barrios_voto[0]?.proceso && e.capa === inputs.barrio_capa)}
    referenciaNombre={inputs.barrio_eleccion === '05' ? 'comunidad' : 'espana'}
    valueFmt='0.0"%"'
    colorPalette={({izquierda: ['#fef2f2', '#dc2626', '#7f1d1d'], derecha: ['#eff6ff', '#2563eb', '#1e3a8a'], centro: ['#fff7ed', '#f97316', '#7c2d12'], nacionalistas: ['#fefce8', '#ca8a04', '#713f12'], psoe: ['#fef2f2', '#e30613', '#7f1d1d'], pp: ['#eff6ff', '#1d84ce', '#1e3a8a'], vox: ['#f0fdf4', '#5ac035', '#14532d'], ips: ['#faf5ff', '#7b2d8e', '#3b0764'], participacion: ['#f0fdfa', '#0d9488', '#134e4a']})[inputs.barrio_capa] ?? ['#eff6ff', '#3b82f6', '#1e3a8a']}
    tooltip={[{id: 'seccion', showColumnName: false, valueClass: 'font-semibold'}, {id: 'valor', title: '%', fmt: '0.0"%"'}, {id: 'ganador_siglas', title: 'Máis votada'}]}
    height=520
    title="{inputs.barrio_capa === 'participacion' ? 'Participación' : ({izquierda: 'Esquerda', derecha: 'Dereita', centro: 'Centro', nacionalistas: 'Nacionalistas e rexionalistas', psoe: 'PSOE', pp: 'PP', vox: 'Vox', ips: 'IU, Podemos e Sumar'})[inputs.barrio_capa] + ', % dos válidos'} en cada sección · {barrios_voto[0]?.eleccion}"
/>

{/if}
{:else}

<p class="text-sm text-gray-500">Non hai resultados por sección desta elección no concello (nas municipais só se publican os de máis de 250 habitantes con listas pechadas).</p>

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
    title="Votan distinto os barrios ricos e os pobres? Voto por bloque segundo a renda da sección · {barrios_voto[0]?.eleccion}"
/>

<p class="text-xs text-gray-500">As seccións do concello ordénanse por renda por persoa e pártense en cinco grupos co mesmo número de seccións; o voto de cada grupo é a media das súas seccións ponderada por votantes.</p>

{/if}
{/if}

<p class="text-xs text-gray-500">Seccións censuais: contornos do INE do ano de cada dato, sobre o rueiro do IGN. Renda: Atlas de Distribución de Renda dos Fogares do INE, que corta as seccións máis ricas e as máis pobres nun mesmo valor máximo e mínimo (por iso levan diante «≥» ou «≤»). Votos: resultados por mesa do Ministerio do Interior sumados por sección, sen o voto dos residentes no estranxeiro. As porcentaxes de voto son sobre votos válidos (candidaturas e en branco). As seccións pártense ou renuméranse cando cambia a súa poboación, así que algunha pode quedar en gris se non hai dato dese ano. Autonómicas: datos por mesa de cada comunidade (Interior non as publica), sumados por sección. Asturias só publica os de Xixón e Estremadura os de Cáceres.</p>

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

## Vivendas turísticas

<Grid cols=2>
    <KpiCard
        title="Vivendas turísticas"
        value={tur_vut_mun.slice(-1)[0]?.pct_viviendas}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas, 2)} % das vivendas"
        period="{new Date(tur_vut_mun.slice(-1)[0]?.periodo).toLocaleDateString('gl-ES', {month: 'long', year: 'numeric', timeZone: 'UTC'})} · España: {formatNumber(tur_vut_mun.slice(-1)[0]?.pct_viviendas_espana, 2)} %"
        source="INE (experimental)"
        href="/gl/economia/turismo"
        sparklineData={tur_vut_mun.filter(d => d.pct_viviendas != null).map(d => ({x: d.periodo, y: d.pct_viviendas}))}
    />
    <KpiCard
        title="Por 1.000 habitantes"
        value={tur_vut_mun.slice(-1)[0]?.viviendas_1000hab}
        formattedValue="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab, 1)}"
        period="{formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas, 0)} vivendas con {formatNumber(tur_vut_mun.slice(-1)[0]?.plazas, 0)} prazas · España: {formatNumber(tur_vut_mun.slice(-1)[0]?.viviendas_1000hab_espana, 1)}"
        source="INE (experimental)"
        sparklineData={tur_vut_mun.filter(d => d.viviendas_1000hab != null).map(d => ({x: d.periodo, y: d.viviendas_1000hab}))}
    />
</Grid>

<p class="text-xs text-gray-500">Vivendas anunciadas como aloxamento turístico nas grandes plataformas dixitais (medición experimental do INE, semestral). {#if tur_vut_mun.slice(-1)[0]?.puesto}É o municipio número {formatNumber(tur_vut_mun.slice(-1)[0]?.puesto, 0)} de {formatNumber(tur_vut_mun.slice(-1)[0]?.n_ranking, 0)} con 1.000 habitantes ou máis por porcentaxe de vivendas turísticas.{/if} Máis en <a href="/gl/economia/turismo">Turismo</a>.</p>

{/if}

```sql suelo_mun
SELECT * FROM mother.suelos_municipio
WHERE cod_mun = '${inputs.municipio}'
ORDER BY superficie_agraria_km2 DESC
```

```sql suelo_ref
SELECT nivel, nombre, pct_agraria, pct_fuertes, ph, materia_organica_pct
FROM mother.suelos_territorio
WHERE cultivo = 'Toda la superficie agraria'
    AND ((nivel = 'provincia' AND cod = left('${inputs.municipio}', 2)) OR nivel = 'pais')
```

{#if suelo_toda}

## Solo agrario

{#if suelo_toda.superficie_agraria_km2 > 0}

O {formatNumber(suelo_toda.pct_agraria, 0)} % do termo municipal é superficie agraria ({formatNumber(suelo_toda.superficie_agraria_km2, 1)} km²; na provincia, o {formatNumber(suelo_prov?.pct_agraria, 0)} %). Nesa terra domina a textura **{etiquetaSuelo('TEXTURA', suelo_toda.textura_dominante, idioma).toLowerCase()}** e o tipo de solo máis estendido son os **{etiquetaSuelo('WRB', suelo_toda.wrb_dominante, idioma).toLowerCase()}**.

<Grid cols=3>
    <KpiCard
        title="Terras fortes (franco-arxilosas e arxilosas)"
        value={suelo_toda.pct_fuertes}
        formattedValue="{formatNumber(suelo_toda.pct_fuertes, 0)} %"
        period="da superficie agraria · provincia: {formatNumber(suelo_prov?.pct_fuertes, 0)} % · España: {formatNumber(suelo_esp?.pct_fuertes, 0)} %"
        direction="neutral"
        source="SoilGrids · CORINE 2018"
    />
    <KpiCard
        title="pH medio do solo agrario"
        value={suelo_toda.ph}
        formattedValue={formatNumber(suelo_toda.ph, 1)}
        period="{formatNumber(suelo_toda.pct_basico, 0)} % básico ou calcario · provincia: {formatNumber(suelo_prov?.ph, 1)} · España: {formatNumber(suelo_esp?.ph, 1)}"
        direction="neutral"
        source="SoilGrids"
    />
    <KpiCard
        title="Materia orgánica media"
        value={suelo_toda.materia_organica_pct}
        formattedValue="{formatNumber(suelo_toda.materia_organica_pct, 1)} %"
        period="provincia: {formatNumber(suelo_prov?.materia_organica_pct, 1)} % · España: {formatNumber(suelo_esp?.materia_organica_pct, 1)} %"
        direction="neutral"
        source="SoilGrids"
    />
</Grid>

{#if celdas.length > 0}

<MapaBarrios
    data={puntosPorTextura(celdas, idioma)}
    lat=lat
    long=lon
    value=categoria
    colorCol=color
    legendType=categorical
    geoJsonUrl="/geo/municipios/{suelo_toda.cod_ccaa}.geojson"
    filtroGeo={{cod_mun: suelo_toda.cod_mun}}
    celdaKm={0.25}
    height={420}
    tooltip={[
        {id: 'textura_txt', showColumnName: false, valueClass: 'font-semibold'},
        {id: 'arcilla_pct', title: 'Arxila (%)', fmt: 'num0'},
        {id: 'ph', title: 'pH', fmt: 'num1'},
        {id: 'materia_organica_pct', title: 'Materia orgánica (%)', fmt: 'num1'},
        {id: 'wrb_txt', title: 'Tipo de solo'},
        {id: 'cultivo_txt', title: 'Cultivo principal'}
    ]}
/>

<p class="text-xs text-gray-500">Cada punto é unha cela de 250 × 250 m con superficie agraria, coloreada pola súa textura. Por pH, materia orgánica, tipo de solo ou cultivo, en <a href="/gl/territorios/suelos?m={suelo_toda.cod_mun}">o mapa de solos agrarios</a>.</p>

{/if}

{#if suelo_mun.length > 1}

<DataTable data={etiquetasSuelo(suelo_mun.filter((d) => d.cultivo !== 'Toda la superficie agraria'), idioma)} rows=10>
    <Column id=cultivo_txt title="Cultivo" />
    <Column id=superficie_agraria_km2 title="Km²" fmt=num1 contentType=bar barColor="#e7d3b5" />
    <Column id=pct_de_la_agraria title="% da superficie agraria" fmt=num1 />
    <Column id=textura_txt title="Textura máis frecuente" />
    <Column id=ph title="pH" fmt=num1 />
    <Column id=materia_organica_pct title="Materia orgánica (%)" fmt=num1 />
    <Column id=wrb_txt title="Tipo de solo" />
</DataTable>

{/if}

{:else}

<p>O mapa de usos do solo CORINE 2018 non marca superficie agraria neste termo municipal: é monte, cidade ou ten parcelas de cultivo de menos de 25 ha, que CORINE funde co que as rodea.</p>

{/if}

<p class="text-xs text-gray-500">Capa arable (0-30 cm) do modelo SoilGrids (ISRIC), con celas de 250 m, sobre a superficie agraria do mapa CORINE Land Cover 2018. Nos municipios pequenos a cifra sae de moi poucas celas: serve para facerse unha idea, non substitúe unha análise de solo da parcela. Comparación co resto de España e Europa en <a href="/gl/territorios/suelos">solos agrarios</a>.</p>

{/if}

## Seguridade

<Grid cols=3>
    <KpiCard
        title="Infraccións penais coñecidas"
        value={crimen_mun[0]?.tasa}
        formattedValue={formatNumber(crimen_mun[0]?.tasa, 1)}
        period="por 1.000 habitantes en {crimen_mun[0]?.anio} · España: {formatNumber(crimen_mun[0]?.tasa_espana, 1)}"
        source="Ministerio do Interior"
        href="/gl/sociedad/criminalidad"
        sparklineData={crimen_mun_serie.filter(d => d.tasa != null).map(d => ({anio: d.anio, valor: d.tasa}))}
    />
    <KpiCard
        title="Roubos con violencia"
        value={crimen_mun[0]?.robos_violencia}
        formattedValue={formatNumber(crimen_mun[0]?.robos_violencia, 2)}
        period="por 1.000 habitantes"
        sparklineData={crimen_mun_serie.filter(d => d.robos_violencia != null).map(d => ({anio: d.anio, valor: d.robos_violencia}))}
    />
    <KpiCard
        title="Roubos en domicilios"
        value={crimen_mun[0]?.robos_domicilios}
        formattedValue={formatNumber(crimen_mun[0]?.robos_domicilios, 2)}
        period="por 1.000 habitantes"
        sparklineData={crimen_mun_serie.filter(d => d.robos_domicilios != null).map(d => ({anio: d.anio, valor: d.robos_domicilios}))}
    />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(crimen_mun[0]?.infracciones, 0)} infraccións penais coñecidas polas forzas de seguridade no termo municipal (Balance de Criminalidade, municipios de máis de 20.000 habitantes). En municipios turísticos ou con aeroporto a taxa por veciño empadroado sae alta porque moitas vítimas son visitantes.</p>

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

## Eleccións

<Grid cols=2>
    <KpiCard title="Participación nas xerais" value={elec_mun_gen.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec_mun_gen.slice(-1)[0]?.participacion, 1)} %"
        period="{elec_mun_gen.slice(-1)[0]?.anio} · sen voto de residentes no estranxeiro"
        source="Ministerio do Interior" href="/gl/sociedad/elecciones" sparklineData={elec_mun_gen} />
    <KpiCard title="Máis votada nas xerais" value={elec_mun_gen.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec_mun_gen.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec_mun_gen.slice(-1)[0]?.ganador_pct, 1)} %"
        period="{elec_mun_gen.slice(-1)[0]?.anio}" source="Ministerio do Interior"
        sparklineData={elec_mun_gen.map(d => ({...d, valor: d.ganador_pct}))} />
</Grid>

<LineChart data={elec_mun_bloques} x=fecha y=pct series=bloque yFmt='0"%"' markers=true
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04'}}
    title="Voto por bloque nas xerais, % dos votos válidos" />

<DataTable data={elec_mun} rows=10>
    <Column id=anio title="Ano" fmt='0' />
    <Column id=eleccion title="Elección" />
    <Column id=ganador_siglas title="Máis votada" />
    <Column id=ganador_pct title="% voto" fmt='0.0"%"' />
    <Column id=participacion title="Participación" fmt='0.0"%"' />
</DataTable>

{/if}

## Quen goberna?

<div class="not-prose rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 my-4" style="border-left: 6px solid {alcalde[0].color}">
    <p class="text-xs uppercase tracking-wide text-gray-500 mb-1">{alcalde[0].cargo} desde o {alcalde[0].desde}</p>
    <p class="text-2xl font-bold text-gray-900 dark:text-white capitalize mb-1">{alcalde[0].alcalde}</p>
    <p class="text-sm text-gray-700 dark:text-gray-300 mb-0">Lista: <b>{alcalde[0].partido_original}</b> · Familia política: <b>{alcalde[0].familia}</b></p>
</div>

<Grid cols=2>
    <KpiCard
        title="Anos no cargo"
        value={alcalde[0]?.anios_en_cargo}
        formattedValue={formatNumber(alcalde[0]?.anios_en_cargo, 1)}
        unit="anos"
        period="de forma continuada, incluídos mandatos anteriores"
    />
    <KpiCard
        title="Anos de {alcalde[0]?.familia} na alcaldía"
        value={alcalde[0]?.anios_partido}
        formattedValue={formatNumber(alcalde[0]?.anios_partido, 1)}
        unit="anos"
        period="goberna sen interrupción desde {alcalde[0]?.primer_anio_familia}"
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
    title="Familia política da alcaldía ao comezar cada mandato"
    seriesColors={Object.fromEntries(familias_mandato.map(f => [f.familia, f.color]))}
/>

{/if}

<Details title="Todos os alcaldes desde 1979">

<DataTable data={historia_alcaldes} rows=15>
    <Column id=mandato title="Mandato" />
    <Column id=alcalde title="Alcalde/sa" />
    <Column id=toma_posesion title="Toma de posesión" />
    <Column id=lista title="Lista" />
    <Column id=familia title="Familia" />
</DataTable>

</Details>

<p class="text-xs text-gray-500">As listas agrúpanse en familias políticas (por exemplo, PSC, PSOE-A ou PSdeG-PSOE en «PSOE»). Os anos calcúlanse pola continuidade do nome e da familia entre mandatos; en 2007-2023 a fonte usa ás veces etiquetas xenéricas de coalición («C. ELECTORAL», «OTROS»), que aparecen como «Sin detalle en la fuente» cando non se poden resolver.</p>

{/if}

---

## Fontes oficiais

- **[INE – Cifras oficiais de poboación dos municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministerio de Facenda – Liquidacións das entidades locais (CONPREL)](https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL)**: ingresos e gastos por capítulos, áreas e políticas de cada concello desde 2010.
- **[Banco de España – Boletín Estatístico, capítulo 14](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: débeda dos concellos de máis de 300.000 habitantes.
- **[Ministerio de Política Territorial – Alcaldes e concelleiros](https://concejales.redsara.es/consulta/)**: alcalde actual (mandato 2023-2027) e listaxes históricas de alcaldes desde 1979 do Sistema de Información Local.
- **[INE – Atlas de Distribución de Renda dos Fogares](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177088&menu=ultiDatos&idp=1254735976608)**: renda por concello, distrito e sección censual a partir de datos tributarios.
- **[INE – Cartografía de seccións censuais](https://www.ine.es/ss/Satellite?L=es_ES&c=Page&cid=1259952026632&p=1259952026632&pagename=ProductosYServicios%2FPYSLayout)**: contornos das seccións de cada ano (mapas de barrio).
- **[Ministerio do Interior – Resultados electorais por mesa](https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/)**: xerais, municipais e europeas, sumados por sección censual.
- **[Instituto Xeográfico Nacional – Rueiro (IGN Base)](https://www.ign.es/web/ign/portal/ide-area-nodo-ide-ign)**: fondo de rúas dos mapas de barrio.

<LastRefreshed prefix="Datos actualizados" />
