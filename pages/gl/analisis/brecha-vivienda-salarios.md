---
title: "A fenda entre vivenda e salarios: cantos anos de soldo custa mercar ou alugar"
description: "Análise da evolución real dos prezos de compra e alugueiro fronte aos salarios brutos en España e por comunidade autónoma, con datos do Ministerio de Vivenda e do INE."
i18n_origen: 3001d864626b
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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
    '/gl' || t.ruta AS ruta,
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
    <a href="/gl/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Análise en datos</a>
    <span>·</span>
    <span class="rounded-full bg-amber-100 dark:bg-amber-950/60 px-2.5 py-0.5 text-amber-800 dark:text-amber-300">Vivenda e Salarios</span>
    <span>·</span>
    <a href="/gl/vivienda/esfuerzo" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Ver panel permanente de esforzo →</a>
</div>

# 🏠 A fenda entre vivenda e salarios: cantos anos de soldo custa mercar ou alugar

O debate sobre o acceso á vivenda en España adoita mesturar cifras nominais que non descontan a inflación con medias nacionais que agochan diferenzas enormes entre comunidades autónomas. Ao cruzar o **valor taxado dun piso tipo de 90 m²** (Ministerio de Vivenda), o **alugueiro mediano declarado no IRPF** (SERPAVI) e o **salario bruto anual medio** de cada territorio (Enquisa Trimestral de Custo Laboral do INE), é posible medir exactamente canto esforzo salarial esixe hoxe ter casa fronte ás dúas últimas décadas.

<Grid cols=4>
    <KpiCard
        title="Anos de soldo para 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} anos"
        period="soldo bruto íntegro en {hitos[0]?.anio_ult} · máximo: {formatNumber(hitos[0]?.anios_max, 1)} en {hitos[0]?.anio_max}"
        direction="positive-down"
        source="MIVAU / INE"
        href="/gl/vivienda/esfuerzo"
        sparklineData={espana.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Soldo destinado ao alugueiro"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="do salario bruto medio ({alquiler.slice(-1)[0]?.anio}) · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/mes"
        direction="positive-down"
        source="SERPAVI / INE"
        href="/gl/vivienda/alquiler"
        sparklineData={alquiler.map(d => ({...d, y: d.pct_alquiler}))}
    />
    <KpiCard
        title="Comunidade con maior esforzo"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} anos"
        period="{ccaa[0]?.comunidad} ({ccaa[0]?.anio}) · fronte a {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} en {ccaa.slice(-1)[0]?.comunidad}"
        direction="positive-down"
        source="MIVAU / INE"
        sparklineData={ccaa_extremos.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Salario bruto medio"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} €/ano"
        period="España ({hitos[0]?.anio_ult}) · piso de 90 m²: {formatNumber(hitos[0]?.precio_ult, 0)} €"
        direction="positive-up"
        source="INE (ETCL)"
        href="/gl/economia/salarios"
        sparklineData={espana.map(d => ({...d, y: d.salario_anual_real}))}
    />
</Grid>

## 1. Tres etapas en dúas décadas: burbulla, axuste e novo encarecemento

Se descontamos a inflación (euros constantes de {hitos[0]?.anio_base}) e fixamos o ano {hitos[0]?.anio_ini} como base 100, o mercado residencial español atravesou tres fases moi marcadas:

1. **O pico da burbulla ({hitos[0]?.anio_max}):** mercar unha vivenda de 90 m² chegou a requirir **{formatNumber(hitos[0]?.anios_max, 1)} anos** de salario bruto íntegro.
2. **O axuste tras a crise financeira ({hitos[0]?.anio_min}):** a caída real de prezos reduciu o esforzo ata un mínimo de **{formatNumber(hitos[0]?.anios_min, 1)} anos** de soldo.
3. **A última década ({hitos[0]?.anio_min}–{hitos[0]?.anio_ult}):** mentres o salario bruto real se mantivo practicamente estancado (un {formatNumber(hitos[0]?.var_salario_real, 1)} % acumulado desde {hitos[0]?.anio_ini}), o prezo real da vivenda e do alugueiro volveu subir nas grandes áreas urbanas e zonas turísticas, situando a media nacional en **{formatNumber(hitos[0]?.anios_ult, 1)} anos** de soldo bruto.

<LineChart
    data={indices}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Índice real (base 100 = primeiro ano)"
    startingAtZero={false}
    title="Evolución real do prezo dunha vivenda de 90 m² fronte ao salario bruto medio (base 100)"
/>

<LineChart
    data={espana}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Anos de salario bruto"
    startingAtZero={false}
    title="Anos de salario bruto íntegro necesarios para mercar un piso de 90 m² en España"
/>

## 2. A fenda territorial duplícase entre costa/capitais e interior

A media nacional ({formatNumber(hitos[0]?.anios_ult, 1)} anos) agocha unha fenda de máis do dobre entre comunidades autónomas, mesmo tendo en conta que os salarios son máis altos en rexións como Madrid, o País Vasco ou Cataluña:

- En **{ccaa[0]?.comunidad}** ({formatNumber(ccaa[0]?.anios_salario, 1)} anos), **{ccaa[1]?.comunidad}** ({formatNumber(ccaa[1]?.anios_salario, 1)} anos) e **{ccaa[2]?.comunidad}** ({formatNumber(ccaa[2]?.anios_salario, 1)} anos), mercar un piso medio de 90 m² esixe moito máis dunha década de soldo neto equivalente.
- No extremo oposto, en **{ccaa.slice(-1)[0]?.comunidad}** ({formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} anos) e **{ccaa.slice(-2)[0]?.comunidad}** ({formatNumber(ccaa.slice(-2)[0]?.anios_salario, 1)} anos), o esforzo necesario é menos da metade ca nos mercados máis tensionados.

<LineChart
    data={ccaa_extremos}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Anos de salario bruto"
    startingAtZero={false}
    title="Evolución do esforzo de compra: as 3 comunidades máis caras, as 2 máis accesibles e España"
/>

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="Anos de salario bruto"
    title="Anos de salario bruto local para mercar unha vivenda de 90 m² ({ccaa[0]?.anio})"
/>

## 3. O alugueiro absorbe xa unha cuarta parte do salario bruto mediano

Para quen vive de alugueiro, o indicador de referencia do Ministerio de Vivenda (contratos reais declarados no IRPF) mostra que o alugueiro mediano dunha vivenda colectiva supón o **{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %** do salario bruto medio nacional ({formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/mes), superando o limiar do 30 % nas comunidades máis tensionadas cando se calcula sobre o salario neto.

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% do salario bruto"
    startingAtZero={false}
    title="Porcentaxe do salario bruto medio destinado ao alugueiro mediano en España"
/>

## 4. Táboa comparativa por comunidade autónoma

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=anios_salario title="Anos de soldo (90 m²)" fmt='0.0' />
    <Column id=dif_vs_espana title="Vs. media España (anos)" fmt='+0.0;-0.0;0.0' contentType=delta />
    <Column id=precio_90m2 title="Piso 90 m² (€)" fmt='#,##0' />
    <Column id=salario_anual title="Salario bruto anual (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Alugueiro / soldo (%)" fmt='0.0"%"' />
    <Column id=alquiler_mes_mediana title="Alugueiro mediano (€/mes)" fmt='#,##0' />
</DataTable>

---

**Metodoloxía e fontes:**
- **Prezo de compra:** Valor taxado medio da vivenda libre ([Ministerio de Vivenda e Axenda Urbana](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)), multiplicado por unha superficie tipo de 90 m² (sen incluír impostos de transmisión nin xuros hipotecarios).
- **Alugueiro:** Renda mensual mediana de vivenda colectiva do Sistema Estatal de Referencia do Prezo do Alugueiro de Vivenda ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) a partir de datos fiscais da AEAT.
- **Salarios:** Custo salarial bruto total por traballador e ano da Enquisa Trimestral de Custo Laboral ([INE, táboa 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061)).
- **Para seguir explorando:** Consulta os paneis permanentes de [Vivenda](/gl/vivienda), [Esforzo por provincia](/gl/vivienda/esfuerzo), [Vivenda pública en alugueiro](/gl/vivienda/vivienda-publica) e [Salarios reais](/gl/economia/salarios).
