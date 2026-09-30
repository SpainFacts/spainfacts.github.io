---
title: Esforzo para comprar ou alugar
description: "Cantos anos de salario bruto custa unha vivenda de 90 m² en España e en cada comunidade, e que parte do soldo se vai no aluguer, con datos do Ministerio de Vivenda e do INE."
i18n_origen: 5b404f87105a
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, anios_salario, pct_alquiler, precio_90m2, salario_anual, alquiler_mes_mediana
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
    100 * (arg_max(precio_90m2, anio) / arg_min(precio_90m2, anio) - 1) AS var_precio,
    100 * (arg_max(salario_anual, anio) / arg_min(salario_anual, anio) - 1) AS var_salario,
    min(anio) AS anio_ini
FROM ${compra}
```

```sql ccaa
SELECT e.cod, e.nombre AS comunidad, '/gl' || t.ruta AS ruta, e.anio, e.anios_salario, e.precio_90m2, e.salario_anual,
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

# ⚖️ Esforzo para comprar ou alugar

Canto pesa a vivenda no soldo. Para comprar: **cantos anos de salario bruto íntegro** fan falta para pagar un piso de 90 m² ao valor taxado medio, sen contar impostos, gastos nin xuros. Para alugar: **que parte do salario bruto** vai no aluguer mediano dun piso. Como se comparan euros do mesmo ano, a inflación non altera o resultado.

<Grid cols=4>
    <KpiCard
        title="Anos de salario para 90 m²"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} anos"
        period="España, {hitos[0]?.anio_ult} · máximo: {formatNumber(hitos[0]?.anios_max, 1)} en {hitos[0]?.anio_max}"
        direction="positive-down"
        source="Ministerio de Vivenda / INE"
        sparklineData={compra.map(d => d.anios_salario)}
    />
    <KpiCard
        title="Aluguer sobre o salario"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="do salario bruto medio, {alquiler.slice(-1)[0]?.anio} · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} € ao mes"
        direction="positive-down"
        source="Ministerio de Vivenda / INE"
        sparklineData={alquiler.map(d => d.pct_alquiler)}
    />
    <KpiCard
        title="Onde máis custa comprar"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} anos"
        period="{ccaa[0]?.comunidad}, {ccaa[0]?.anio} · onde menos: {ccaa.slice(-1)[0]?.comunidad}, {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)}"
        direction="positive-down"
        source="Ministerio de Vivenda / INE"
        sparklineData={ccaa_serie.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => d.anios_salario)}
    />
    <KpiCard
        title="Salario bruto medio"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} € ao ano"
        period="España, {hitos[0]?.anio_ult} · un piso de 90 m² táxase en {formatNumber(hitos[0]?.precio_ult, 0)} €"
        source="INE / ETCL"
        sparklineData={compra.map(d => d.salario_anual)}
    />
</Grid>

## Comprar: anos de salario

Entre {hitos[0]?.anio_ini} e {hitos[0]?.anio_ult} o valor taxado dun piso de 90 m² cambiou un {formatNumber(hitos[0]?.var_precio, 1)} % e o salario bruto medio, un {formatNumber(hitos[0]?.var_salario, 1)} %, ambos en euros de cada ano. O mínimo da serie foi en {hitos[0]?.anio_min}, con {formatNumber(hitos[0]?.anios_min, 1)} anos de salario.

<LineChart
    data={compra}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="anos de salario bruto"
    startingAtZero={false}
    title="Anos de salario bruto medio para pagar unha vivenda de 90 m² en España"
/>

<LineChart
    data={ccaa_serie}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="anos de salario bruto"
    title="As tres comunidades con máis esforzo, a de menos e España"
/>

## Alugar: parte do salario

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% do salario bruto"
    startingAtZero={false}
    title="Aluguer mediano dun piso sobre o salario bruto medio en España"
/>

## Por comunidade

Compra: datos de {ccaa[0]?.anio}; aluguer: de {ccaa[0]?.anio_alquiler}, último ano publicado. O salario é o de cada comunidade, así que a comparación ten en conta que nunhas se cobra máis ca noutras.

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="anos de salario bruto"
    title="Anos de salario para pagar 90 m² por comunidade, {ccaa[0]?.anio}"
/>

<BarChart
    data={ccaa_alquiler}
    x=comunidad
    y=pct_alquiler
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% do salario bruto"
    title="Aluguer mediano sobre o salario por comunidade, {ccaa_alquiler[0]?.anio}"
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=anios_salario title="Anos de salario (90 m²)" fmt='0.0' />
    <Column id=precio_90m2 title="Piso de 90 m² (€)" fmt='#,##0' />
    <Column id=salario_anual title="Salario bruto anual (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Aluguer / salario %" fmt='0.0' />
    <Column id=alquiler_mes_mediana title="Aluguer mediano (€/mes)" fmt='#,##0' />
</DataTable>

Ceuta e Melilla non aparecen porque a Enquisa de Custo Laboral non dá o seu salario.

---

**Cálculo:** anos de salario = valor taxado medio da vivenda libre do ano (media dos seus catro trimestres, [Ministerio de Vivenda](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)) × 90 m² ÷ (custo salarial total por traballador e mes × 12, [INE, Enquisa Trimestral de Custo Laboral, táboa 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061), industria, construción e servizos). Aluguer sobre salario = aluguer mensual mediano dun piso ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) × 12 ÷ ese mesmo salario anual. Son salarios brutos medios por traballador, non ingresos por fogar.
