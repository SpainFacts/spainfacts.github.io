---
title: "La brecha entre vivienda y salarios: cuántos años de sueldo cuesta comprar o alquilar"
description: "Análisis de la evolución real de los precios de compra y alquiler frente a los salarios brutos en España y por comunidad autónoma, con datos del Ministerio de Vivienda y del INE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT
    anio,
    anios_salario,
    pct_alquiler,
    precio_90m2,
    salario_anual,
    alquiler_mes_mediana,
    precio_90m2_real,
    salario_anual_real,
    CAST(anio_base AS INTEGER) AS anio_base,
    100.0 * precio_90m2_real / first_value(precio_90m2_real) OVER (ORDER BY anio) AS idx_precio_real,
    100.0 * salario_anual_real / first_value(salario_anual_real) OVER (ORDER BY anio) AS idx_salario_real
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql indices
SELECT anio, 'Vivienda 90 m² (euros reales)' AS serie, idx_precio_real AS indice FROM ${espana}
UNION ALL
SELECT anio, 'Salario bruto medio (euros reales)' AS serie, idx_salario_real AS indice FROM ${espana}
ORDER BY anio, serie
```

```sql alquiler
SELECT anio, pct_alquiler, alquiler_mes_mediana, alquiler_mes_mediana_real
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND pct_alquiler IS NOT NULL
ORDER BY anio
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    min(anio) AS anio_ini,
    arg_max(anios_salario, anio) AS anios_ult,
    arg_max(precio_90m2, anio) AS precio_ult,
    arg_max(salario_anual, anio) AS salario_ult,
    max(anios_salario) AS anios_max,
    arg_max(anio, anios_salario) AS anio_max,
    min(anios_salario) AS anios_min,
    arg_min(anio, anios_salario) AS anio_min,
    100.0 * (arg_max(precio_90m2_real, anio) / arg_min(precio_90m2_real, anio) - 1) AS var_precio_real,
    100.0 * (arg_max(salario_anual_real, anio) / arg_min(salario_anual_real, anio) - 1) AS var_salario_real,
    max(anio_base) AS anio_base
FROM ${espana}
```

```sql ccaa
SELECT
    e.cod,
    e.nombre AS comunidad,
    t.ruta,
    e.anio,
    e.anios_salario,
    e.precio_90m2,
    e.salario_anual,
    a.anio AS anio_alquiler,
    a.pct_alquiler,
    a.alquiler_mes_mediana,
    e.anios_salario - (SELECT anios_ult FROM ${hitos}) AS dif_vs_espana
FROM mother.vivienda_esfuerzo e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
LEFT JOIN mother.vivienda_esfuerzo a
  ON a.nivel = 'ccaa' AND a.cod = e.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
WHERE e.nivel = 'ccaa'
  AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND anios_salario IS NOT NULL)
ORDER BY e.anios_salario DESC
```

```sql ccaa_extremos
SELECT anio, nombre, anios_salario
FROM mother.vivienda_esfuerzo
WHERE anios_salario IS NOT NULL
  AND (nivel = 'pais' OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario DESC LIMIT 3) OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario ASC LIMIT 2))
ORDER BY anio, nombre
```

<div class="not-prose mb-4 flex flex-wrap items-center gap-2 text-xs font-semibold text-gray-500 dark:text-gray-400">
    <a href="/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Análisis en datos</a>
    <span>·</span>
    <span class="rounded-full bg-amber-100 dark:bg-amber-950/60 px-2.5 py-0.5 text-amber-800 dark:text-amber-300">Vivienda y Salarios</span>
    <span>·</span>
    <a href="/vivienda/esfuerzo" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Ver panel permanente de esfuerzo →</a>
</div>

# 🏠 La brecha entre vivienda y salarios: cuántos años de sueldo cuesta comprar o alquilar

El debate sobre el acceso a la vivienda en España suele mezclarse con cifras nominales que no descuentan la inflación o con medias nacionales que ocultan diferencias enormes entre comunidades autónomas. Al cruzar el **valor tasado de un piso tipo de 90 m²** (Ministerio de Vivienda), el **alquiler mediano declarado en el IRPF** (SERPAVI) y el **salario bruto anual medio** de cada territorio (Encuesta Trimestral de Coste Laboral del INE), es posible medir exactamente cuánto esfuerzo salarial exige hoy tener casa frente a las dos últimas décadas.

<Grid cols=4>
    <KpiCard
        title="Años de sueldo para 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} años"
        period="sueldo bruto íntegro en {hitos[0]?.anio_ult} · pico: {formatNumber(hitos[0]?.anios_max, 1)} en {hitos[0]?.anio_max}"
        direction="positive-down"
        source="MIVAU / INE"
        href="/vivienda/esfuerzo"
        sparklineData={espana.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Sueldo destinado al alquiler"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="del salario bruto medio ({alquiler.slice(-1)[0]?.anio}) · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/mes"
        direction="positive-down"
        source="SERPAVI / INE"
        href="/vivienda/alquiler"
        sparklineData={alquiler.map(d => ({...d, y: d.pct_alquiler}))}
    />
    <KpiCard
        title="Comunidad con mayor esfuerzo"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} años"
        period="{ccaa[0]?.comunidad} ({ccaa[0]?.anio}) · frente a {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} en {ccaa.slice(-1)[0]?.comunidad}"
        direction="positive-down"
        source="MIVAU / INE"
        sparklineData={ccaa_extremos.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Salario bruto medio"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} €/año"
        period="España ({hitos[0]?.anio_ult}) · piso de 90 m²: {formatNumber(hitos[0]?.precio_ult, 0)} €"
        direction="positive-up"
        source="INE (ETCL)"
        href="/economia/salarios"
        sparklineData={espana.map(d => ({...d, y: d.salario_anual_real}))}
    />
</Grid>

## 1. Tres etapas en dos décadas: burbuja, ajuste y nuevo encarecimiento

Si descontamos la inflación (euros constantes de {hitos[0]?.anio_base}) y fijamos el año {hitos[0]?.anio_ini} como base 100, el mercado residencial español ha atravesado tres fases muy marcadas:

1. **El pico de la burbuja ({hitos[0]?.anio_max}):** comprar una vivienda de 90 m² llegó a requerir **{formatNumber(hitos[0]?.anios_max, 1)} años** de salario bruto íntegro.
2. **El ajuste tras la crisis financiera ({hitos[0]?.anio_min}):** la caída real de precios redujo el esfuerzo hasta un mínimo de **{formatNumber(hitos[0]?.anios_min, 1)} años** de sueldo.
3. **La última década ({hitos[0]?.anio_min}–{hitos[0]?.anio_ult}):** mientras el salario bruto real se ha mantenido prácticamente estancado (un {formatNumber(hitos[0]?.var_salario_real, 1)} % acumulado desde {hitos[0]?.anio_ini}), el precio real de la vivienda y del alquiler ha vuelto a subir en las grandes áreas urbanas y zonas turísticas, situando la media nacional en **{formatNumber(hitos[0]?.anios_ult, 1)} años** de sueldo bruto.

<LineChart
    data={indices}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Índice real (base 100 = primer año)"
    startingAtZero={false}
    title="Evolución real del precio de una vivienda de 90 m² frente al salario bruto medio (base 100)"
/>

<LineChart
    data={espana}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Años de salario bruto"
    startingAtZero={false}
    title="Años de salario bruto íntegro necesarios para comprar un piso de 90 m² en España"
/>

## 2. La brecha territorial se duplica entre costa/capitales e interior

La media nacional ({formatNumber(hitos[0]?.anios_ult, 1)} años) esconde una brecha de más del doble entre comunidades autónomas, incluso teniendo en cuenta que los salarios son más altos en regiones como Madrid, País Vasco o Cataluña:

- En **{ccaa[0]?.comunidad}** ({formatNumber(ccaa[0]?.anios_salario, 1)} años), **{ccaa[1]?.comunidad}** ({formatNumber(ccaa[1]?.anios_salario, 1)} años) y **{ccaa[2]?.comunidad}** ({formatNumber(ccaa[2]?.anios_salario, 1)} años), comprar un piso medio de 90 m² exige mucho más de una década de sueldo neto equivalente.
- En el extremo opuesto, en **{ccaa.slice(-1)[0]?.comunidad}** ({formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} años) y **{ccaa.slice(-2)[0]?.comunidad}** ({formatNumber(ccaa.slice(-2)[0]?.anios_salario, 1)} años), el esfuerzo necesario es menos de la mitad que en los mercados más tensionados.

<LineChart
    data={ccaa_extremos}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Años de salario bruto"
    startingAtZero={false}
    title="Evolución del esfuerzo de compra: las 3 comunidades más caras, las 2 más asequibles y España"
/>

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="Años de salario bruto"
    title="Años de salario bruto local para comprar una vivienda de 90 m² ({ccaa[0]?.anio})"
/>

## 3. El alquiler absorbe ya una cuarta parte del salario bruto mediano

Para quienes viven de alquiler, el indicador de referencia del Ministerio de Vivienda (contratos reales declarados en el IRPF) muestra que el alquiler mediano de una vivienda colectiva supone el **{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %** del salario bruto medio nacional ({formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/mes), superando el umbral del 30 % en las comunidades más tensionadas cuando se calcula sobre el salario neto.

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del salario bruto"
    startingAtZero={false}
    title="Porcentaje del salario bruto medio destinado al alquiler mediano en España"
/>

## 4. Tabla comparativa por comunidad autónoma

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=anios_salario title="Años de sueldo (90 m²)" fmt='0.0' />
    <Column id=dif_vs_espana title="Vs. media España (años)" fmt='+0.0;-0.0;0.0' contentType=delta />
    <Column id=precio_90m2 title="Piso 90 m² (€)" fmt='#,##0' />
    <Column id=salario_anual title="Salario bruto anual (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Alquiler / sueldo (%)" fmt='0.0"%"' />
    <Column id=alquiler_mes_mediana title="Alquiler mediano (€/mes)" fmt='#,##0' />
</DataTable>

---

**Metodología y fuentes:**
- **Precio de compra:** Valor tasado medio de la vivienda libre ([Ministerio de Vivienda y Agenda Urbana](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)), multiplicado por una superficie tipo de 90 m² (sin incluir impuestos de transmisión ni intereses hipotecarios).
- **Alquiler:** Renta mensual mediana de vivienda colectiva del Sistema Estatal de Referencia del Precio del Alquiler de Vivienda ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) a partir de datos fiscales de la AEAT.
- **Salarios:** Coste salarial bruto total por trabajador y año de la Encuesta Trimestral de Coste Laboral ([INE, tabla 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061)).
- **Para seguir explorando:** Consulta los paneles permanentes de [Vivienda](/vivienda), [Esfuerzo por provincia](/vivienda/esfuerzo), [Vivienda pública en alquiler](/vivienda/vivienda-publica) y [Salarios reales](/economia/salarios).
