---
title: Esforç per comprar o llogar
description: "Quants anys de salari brut costa un habitatge de 90 m² a Espanya i a cada comunitat, i quina part del sou se'n va en el lloguer, amb dades del Ministeri d'Habitatge i de l'INE."
i18n_origen: 720363cb6517
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, anios_salario, pct_alquiler, precio_90m2, salario_anual, alquiler_mes_mediana,
       precio_90m2_real, salario_anual_real, anio_base
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais'
ORDER BY anio
```

```sql compra
SELECT * FROM ${espana} WHERE anios_salario IS NOT NULL ORDER BY anio
```

```sql alquiler
SELECT * FROM ${espana} WHERE pct_alquiler IS NOT NULL ORDER BY anio
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(anios_salario, anio) AS anios_ult,
    arg_max(precio_90m2, anio) AS precio_ult,
    arg_max(salario_anual, anio) AS salario_ult,
    max(anios_salario) AS anios_max,
    arg_max(anio, anios_salario) AS anio_max,
    min(anios_salario) AS anios_min,
    arg_min(anio, anios_salario) AS anio_min,
    100 * (arg_max(precio_90m2_real, anio) / arg_min(precio_90m2_real, anio) - 1) AS var_precio,
    100 * (arg_max(salario_anual_real, anio) / arg_min(salario_anual_real, anio) - 1) AS var_salario,
    CAST(max(anio_base) AS INTEGER) AS anio_base,
    min(anio) AS anio_ini
FROM ${compra}
```

```sql ccaa
SELECT e.cod, e.nombre AS comunidad, '/ca' || t.ruta AS ruta, e.anio, e.anios_salario, e.precio_90m2, e.salario_anual,
       a.anio AS anio_alquiler, a.pct_alquiler, a.alquiler_mes_mediana
FROM mother.vivienda_esfuerzo e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
LEFT JOIN mother.vivienda_esfuerzo a
  ON a.nivel = 'ccaa' AND a.cod = e.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND anios_salario IS NOT NULL)
ORDER BY e.anios_salario DESC
```

```sql ccaa_alquiler
SELECT e.cod, e.nombre AS comunidad, e.anio, e.pct_alquiler
FROM mother.vivienda_esfuerzo e
WHERE e.nivel = 'ccaa' AND e.pct_alquiler IS NOT NULL
  AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
ORDER BY e.pct_alquiler DESC
```

```sql ccaa_serie
SELECT anio, nombre, anios_salario
FROM mother.vivienda_esfuerzo
WHERE anios_salario IS NOT NULL
  AND (nivel = 'pais' OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario DESC LIMIT 3) OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario LIMIT 1))
ORDER BY anio, nombre
```

# ⚖️ Esforç per comprar o llogar

Quant pesa l'habitatge en el sou. Per comprar: **quants anys de salari brut íntegre** calen per pagar un pis de 90 m² al valor taxat mitjà, sense comptar impostos, despeses ni interessos. Per llogar: **quina part del salari brut** se'n va en el lloguer medià d'un pis. Com que es comparen euros del mateix any, la inflació no altera el resultat.

<Grid cols=4>
    <KpiCard
        title="Anys de salari per a 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} anys"
        period="Espanya, {hitos[0]?.anio_ult} · màxim: {formatNumber(hitos[0]?.anios_max, 1)} el {hitos[0]?.anio_max}"
        direction="positive-down"
        source="Ministeri d'Habitatge / INE"
        sparklineData={compra.map(d => d.anios_salario)}
    />
    <KpiCard
        title="Lloguer sobre el salari"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="del salari brut mitjà, {alquiler.slice(-1)[0]?.anio} · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} € al mes"
        direction="positive-down"
        source="Ministeri d'Habitatge / INE"
        sparklineData={alquiler.map(d => d.pct_alquiler)}
    />
    <KpiCard
        title="On costa més comprar"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} anys"
        period="{ccaa[0]?.comunidad}, {ccaa[0]?.anio} · on menys: {ccaa.slice(-1)[0]?.comunidad}, {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)}"
        direction="positive-down"
        source="Ministeri d'Habitatge / INE"
        sparklineData={ccaa_serie.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => d.anios_salario)}
    />
    <KpiCard
        title="Salari brut mitjà"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} € l'any"
        period="Espanya, {hitos[0]?.anio_ult} · un pis de 90 m² es taxa en {formatNumber(hitos[0]?.precio_ult, 0)} €"
        source="INE / ETCL"
        sparklineData={compra.map(d => d.salario_anual_real)}
    />
</Grid>

## Comprar: anys de salari

Entre el {hitos[0]?.anio_ini} i el {hitos[0]?.anio_ult} el valor taxat d'un pis de 90 m² va canviar un {formatNumber(hitos[0]?.var_precio, 1)} % i el salari brut mitjà, un {formatNumber(hitos[0]?.var_salario, 1)} %, tots dos en euros constants de {hitos[0]?.anio_base}, descomptada la inflació. El mínim de la sèrie va ser el {hitos[0]?.anio_min}, amb {formatNumber(hitos[0]?.anios_min, 1)} anys de salari.

<LineChart
    data={compra}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="anys de salari brut"
    startingAtZero={false}
    title="Anys de salari brut mitjà per pagar un habitatge de 90 m² a Espanya"
/>

<LineChart
    data={ccaa_serie}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="anys de salari brut"
    title="Les tres comunitats amb més esforç, la de menys i Espanya"
/>

## Llogar: part del salari

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del salari brut"
    startingAtZero={false}
    title="Lloguer medià d'un pis sobre el salari brut mitjà a Espanya"
/>

## Per comunitat

Compra: dades del {ccaa[0]?.anio}; lloguer: del {ccaa[0]?.anio_alquiler}, últim any publicat. El salari és el de cada comunitat, de manera que la comparació té en compte que en unes es cobra més que en altres.

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="anys de salari brut"
    title="Anys de salari per pagar 90 m² per comunitat, {ccaa[0]?.anio}"
/>

<BarChart
    data={ccaa_alquiler}
    x=comunidad
    y=pct_alquiler
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% del salari brut"
    title="Lloguer medià sobre el salari per comunitat, {ccaa_alquiler[0]?.anio}"
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=anios_salario title="Anys de salari (90 m²)" fmt='0.0' />
    <Column id=precio_90m2 title="Pis de 90 m² (€)" fmt='#,##0' />
    <Column id=salario_anual title="Salari brut anual (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Lloguer / salari %" fmt='0.0' />
    <Column id=alquiler_mes_mediana title="Lloguer medià (€/mes)" fmt='#,##0' />
</DataTable>

Ceuta i Melilla no hi apareixen perquè l'Enquesta de Cost Laboral no en dona el salari.

---

**Càlcul:** anys de salari = valor taxat mitjà de l'habitatge lliure de l'any (mitjana dels seus quatre trimestres, [Ministeri d'Habitatge](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)) × 90 m² ÷ (cost salarial total per treballador i mes × 12, [INE, Enquesta Trimestral de Cost Laboral, taula 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061), indústria, construcció i serveis). Lloguer sobre salari = lloguer mensual medià d'un pis ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) × 12 ÷ aquest mateix salari anual. Són salaris bruts mitjans per treballador, no ingressos per llar.
