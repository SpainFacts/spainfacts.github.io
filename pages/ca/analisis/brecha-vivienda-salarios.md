---
title: "La bretxa entre habitatge i salaris: quants anys de sou costa comprar o llogar"
description: "Anàlisi de l'evolució real dels preus de compra i lloguer enfront dels salaris bruts a Espanya i per comunitat autònoma, amb dades del Ministeri d'Habitatge i de l'INE."
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
    '/ca' || t.ruta AS ruta,
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
    <a href="/ca/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Anàlisi en dades</a>
    <span>·</span>
    <span class="rounded-full bg-amber-100 dark:bg-amber-950/60 px-2.5 py-0.5 text-amber-800 dark:text-amber-300">Habitatge i Salaris</span>
    <span>·</span>
    <a href="/ca/vivienda/esfuerzo" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Veure panell permanent d'esforç →</a>
</div>

# 🏠 La bretxa entre habitatge i salaris: quants anys de sou costa comprar o llogar

El debat sobre l'accés a l'habitatge a Espanya sol barrejar xifres nominals que no descompten la inflació amb mitjanes nacionals que amaguen diferències enormes entre comunitats autònomes. En creuar el **valor taxat d'un pis tipus de 90 m²** (Ministeri d'Habitatge), el **lloguer medià declarat a l'IRPF** (SERPAVI) i el **salari brut anual mitjà** de cada territori (Enquesta Trimestral de Cost Laboral de l'INE), es pot mesurar exactament quin esforç salarial exigeix avui tenir casa enfront de les dues últimes dècades.

<Grid cols=4>
    <KpiCard
        title="Anys de sou per a 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} anys"
        period="sou brut íntegre el {hitos[0]?.anio_ult} · màxim: {formatNumber(hitos[0]?.anios_max, 1)} el {hitos[0]?.anio_max}"
        direction="positive-down"
        source="MIVAU / INE"
        href="/ca/vivienda/esfuerzo"
        sparklineData={espana.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Sou destinat al lloguer"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="del salari brut mitjà ({alquiler.slice(-1)[0]?.anio}) · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/mes"
        direction="positive-down"
        source="SERPAVI / INE"
        href="/ca/vivienda/alquiler"
        sparklineData={alquiler.map(d => ({...d, y: d.pct_alquiler}))}
    />
    <KpiCard
        title="Comunitat amb més esforç"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} anys"
        period="{ccaa[0]?.comunidad} ({ccaa[0]?.anio}) · enfront de {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} a {ccaa.slice(-1)[0]?.comunidad}"
        direction="positive-down"
        source="MIVAU / INE"
        sparklineData={ccaa_extremos.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Salari brut mitjà"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} €/any"
        period="Espanya ({hitos[0]?.anio_ult}) · pis de 90 m²: {formatNumber(hitos[0]?.precio_ult, 0)} €"
        direction="positive-up"
        source="INE (ETCL)"
        href="/ca/economia/salarios"
        sparklineData={espana.map(d => ({...d, y: d.salario_anual_real}))}
    />
</Grid>

## 1. Tres etapes en dues dècades: bombolla, ajust i nou encariment

Si descomptem la inflació (euros constants del {hitos[0]?.anio_base}) i fixem l'any {hitos[0]?.anio_ini} com a base 100, el mercat residencial espanyol ha travessat tres fases molt marcades:

1. **El pic de la bombolla ({hitos[0]?.anio_max}):** comprar un habitatge de 90 m² va arribar a requerir **{formatNumber(hitos[0]?.anios_max, 1)} anys** de salari brut íntegre.
2. **L'ajust després de la crisi financera ({hitos[0]?.anio_min}):** la caiguda real de preus va reduir l'esforç fins a un mínim de **{formatNumber(hitos[0]?.anios_min, 1)} anys** de sou.
3. **L'última dècada ({hitos[0]?.anio_min}–{hitos[0]?.anio_ult}):** mentre que el salari brut real s'ha mantingut pràcticament estancat (un {formatNumber(hitos[0]?.var_salario_real, 1)} % acumulat des del {hitos[0]?.anio_ini}), el preu real de l'habitatge i del lloguer ha tornat a pujar a les grans àrees urbanes i zones turístiques, situant la mitjana nacional en **{formatNumber(hitos[0]?.anios_ult, 1)} anys** de sou brut.

<LineChart
    data={indices}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Índex real (base 100 = primer any)"
    startingAtZero={false}
    title="Evolució real del preu d'un habitatge de 90 m² enfront del salari brut mitjà (base 100)"
/>

<LineChart
    data={espana}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Anys de salari brut"
    startingAtZero={false}
    title="Anys de salari brut íntegre necessaris per comprar un pis de 90 m² a Espanya"
/>

## 2. La bretxa territorial es duplica entre costa/capitals i interior

La mitjana nacional ({formatNumber(hitos[0]?.anios_ult, 1)} anys) amaga una bretxa de més del doble entre comunitats autònomes, fins i tot tenint en compte que els salaris són més alts en regions com Madrid, el País Basc o Catalunya:

- A **{ccaa[0]?.comunidad}** ({formatNumber(ccaa[0]?.anios_salario, 1)} anys), **{ccaa[1]?.comunidad}** ({formatNumber(ccaa[1]?.anios_salario, 1)} anys) i **{ccaa[2]?.comunidad}** ({formatNumber(ccaa[2]?.anios_salario, 1)} anys), comprar un pis mitjà de 90 m² exigeix molt més d'una dècada de sou net equivalent.
- A l'extrem oposat, a **{ccaa.slice(-1)[0]?.comunidad}** ({formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} anys) i **{ccaa.slice(-2)[0]?.comunidad}** ({formatNumber(ccaa.slice(-2)[0]?.anios_salario, 1)} anys), l'esforç necessari és menys de la meitat que als mercats més tensionats.

<LineChart
    data={ccaa_extremos}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Anys de salari brut"
    startingAtZero={false}
    title="Evolució de l'esforç de compra: les 3 comunitats més cares, les 2 més assequibles i Espanya"
/>

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="Anys de salari brut"
    title="Anys de salari brut local per comprar un habitatge de 90 m² ({ccaa[0]?.anio})"
/>

## 3. El lloguer ja absorbeix una quarta part del salari brut medià

Per a qui viu de lloguer, l'indicador de referència del Ministeri d'Habitatge (contractes reals declarats a l'IRPF) mostra que el lloguer medià d'un habitatge col·lectiu suposa el **{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %** del salari brut mitjà nacional ({formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/mes), superant el llindar del 30 % a les comunitats més tensionades quan es calcula sobre el salari net.

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del salari brut"
    startingAtZero={false}
    title="Percentatge del salari brut mitjà destinat al lloguer medià a Espanya"
/>

## 4. Taula comparativa per comunitat autònoma

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=anios_salario title="Anys de sou (90 m²)" fmt='0.0' />
    <Column id=dif_vs_espana title="Vs. mitjana Espanya (anys)" fmt='+0.0;-0.0;0.0' contentType=delta />
    <Column id=precio_90m2 title="Pis 90 m² (€)" fmt='#,##0' />
    <Column id=salario_anual title="Salari brut anual (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Lloguer / sou (%)" fmt='0.0"%"' />
    <Column id=alquiler_mes_mediana title="Lloguer medià (€/mes)" fmt='#,##0' />
</DataTable>

---

**Metodologia i fonts:**
- **Preu de compra:** Valor taxat mitjà de l'habitatge lliure ([Ministeri d'Habitatge i Agenda Urbana](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)), multiplicat per una superfície tipus de 90 m² (sense incloure impostos de transmissió ni interessos hipotecaris).
- **Lloguer:** Renda mensual mediana d'habitatge col·lectiu del Sistema Estatal de Referència del Preu del Lloguer d'Habitatge ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) a partir de dades fiscals de l'AEAT.
- **Salaris:** Cost salarial brut total per treballador i any de l'Enquesta Trimestral de Cost Laboral ([INE, taula 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061)).
- **Per continuar explorant:** Consulta els panells permanents d'[Habitatge](/ca/vivienda), [Esforç per província](/ca/vivienda/esfuerzo), [Habitatge públic de lloguer](/ca/vivienda/vivienda-publica) i [Salaris reals](/ca/economia/salarios).
