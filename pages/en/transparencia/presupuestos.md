---
title: Rolled-over budgets
description: "In which years Spain has had a General State Budget approved on time, which arrived late and which were rolled over, how many days late and which government was due to present them, since 1978."
i18n_origen: fd19bed34152
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresSituacion = { 'A tiempo': '#16a34a', 'Tarde': '#f59e0b', 'Prorrogado': '#dc2626', 'Prorrogado (en curso)': '#fca5a5' };
    // English labels for the status values that come from the data
    const situacionEn = { 'A tiempo': 'On time', 'Tarde': 'Late', 'Prorrogado': 'Rolled over', 'Prorrogado (en curso)': 'Rolled over (ongoing)' };
    const traducirSituacion = (s) => situacionEn[s] ?? s;
</script>

```sql ejercicios
SELECT
    CAST(anio AS INTEGER) AS ejercicio,
    situacion,
    coalesce(ley, '') AS ley,
    fecha_publicacion,
    CAST(dias_prorroga AS INTEGER) AS dias_prorroga,
    en_plazo,
    es_parcial AS en_curso,
    presidente_responsable,
    partido_responsable,
    presidente_1_enero,
    coalesce(url_html, '') AS url_html
FROM mother.gobierno_presupuestos
ORDER BY anio
```

```sql resumen
SELECT
    count(*) AS ejercicios,
    count(*) FILTER (WHERE en_plazo) AS a_tiempo,
    count(*) FILTER (WHERE situacion = 'Tarde') AS tarde,
    count(*) FILTER (WHERE situacion LIKE 'Prorrogado%') AS prorrogados,
    max(ejercicio) FILTER (WHERE en_plazo) AS ultimo_a_tiempo,
    max(ejercicio) AS actual,
    max(situacion) FILTER (WHERE en_curso) AS situacion_actual,
    max(dias_prorroga) FILTER (WHERE en_curso) AS dias_actual,
    count(*) FILTER (WHERE NOT en_plazo AND ejercicio >= (SELECT max(ejercicio) - 9 FROM ${ejercicios})) AS sin_ley_10,
    sum(dias_prorroga) FILTER (WHERE ejercicio >= 2016) AS dias_desde_2016
FROM ${ejercicios}
```

```sql racha
-- Ejercicios seguidos sin ley propia hasta el actual
WITH m AS (
    SELECT ejercicio, en_plazo OR situacion = 'Tarde' AS con_ley,
        sum(CASE WHEN en_plazo OR situacion = 'Tarde' THEN 1 ELSE 0 END) OVER (ORDER BY ejercicio DESC) AS con_ley_despues
    FROM ${ejercicios}
)
SELECT count(*) AS seguidos, min(ejercicio) AS desde FROM m WHERE NOT con_ley AND con_ley_despues = 0
```

```sql serie
SELECT ejercicio, situacion, dias_prorroga FROM ${ejercicios}
```

```sql presidentes
SELECT
    presidente_responsable AS presidente,
    any_value(partido_responsable) AS partido,
    min(ejercicio) AS primer_ejercicio,
    count(*) AS ejercicios,
    count(*) FILTER (WHERE en_plazo) AS a_tiempo,
    count(*) FILTER (WHERE situacion = 'Tarde') AS tarde,
    count(*) FILTER (WHERE situacion LIKE 'Prorrogado%') AS prorrogados,
    100.0 * count(*) FILTER (WHERE NOT en_plazo) / count(*) AS pct_sin_ley,
    avg(dias_prorroga) AS dias_medios
FROM ${ejercicios}
GROUP BY presidente_responsable
ORDER BY primer_ejercicio
```

```sql partidos
-- Observados frente a esperados: los ejercicios sin ley el 1 de enero se reparten
-- según los ejercicios que le tocaba presentar a cada partido; z binomial (aprox. normal)
WITH p AS (
    SELECT
        partido_responsable AS partido,
        count(*) AS ejercicios,
        count(*) FILTER (WHERE NOT en_plazo) AS observados
    FROM ${ejercicios}
    GROUP BY partido_responsable
),
t AS (SELECT sum(ejercicios) AS n, sum(observados) AS total FROM p)
SELECT
    p.partido,
    p.ejercicios,
    p.observados,
    t.total * p.ejercicios / t.n AS esperados,
    p.observados / (t.total * p.ejercicios / t.n) AS ratio,
    (p.observados - t.total * p.ejercicios / t.n)
        / sqrt(t.total * (p.ejercicios / t.n) * (1 - p.ejercicios / t.n)) AS z
FROM p, t
ORDER BY p.ejercicios DESC
```

```sql partidos_resumen
SELECT
    max(ratio) FILTER (WHERE partido = 'PSOE') AS psoe,
    max(ratio) FILTER (WHERE partido = 'PP') AS pp,
    max(ratio) FILTER (WHERE partido = 'UCD') AS ucd,
    max(abs(z)) FILTER (WHERE partido IN ('PSOE', 'PP')) AS z_max
FROM ${partidos}
```

```sql listado
SELECT
    ejercicio,
    situacion,
    ley,
    fecha_publicacion,
    dias_prorroga,
    presidente_responsable,
    presidente_1_enero,
    url_html
FROM ${ejercicios}
ORDER BY ejercicio DESC
```

# 🧾 General State Budget: on time, late or rolled over

The General State Budget is the law that sets each year how much the State may spend and on what, and how much revenue it expects. The Constitution requires the Government to submit the bill to Congress **at least three months before** the end of the year (art. 134.3), so that Parliament can pass it before 1 January. If it is not ready in time, the previous year's budget is **automatically rolled over** until the new one is approved (art. 134.4). Using the Official State Gazette (BOE), this page counts how many financial years have started without their own budget and which government was due to present it.

<Grid cols=4>
    <KpiCard
        title="{resumen[0]?.actual} budget"
        value={resumen[0]?.dias_actual}
        formattedValue={traducirSituacion(resumen[0]?.situacion_actual)}
        period="{formatNumber(racha[0]?.seguidos, 0)} consecutive years without their own budget act, since {racha[0]?.desde} · {formatNumber(resumen[0]?.dias_actual, 0)} days of rollover this year"
        source="BOE"
        sparklineData={serie.map(d => d.dias_prorroga)}
    />
    <KpiCard
        title="Last budget approved on time"
        value={resumen[0]?.ultimo_a_tiempo}
        formattedValue={resumen[0]?.ultimo_a_tiempo}
        period="published in the BOE before 1 January of that year"
        source="BOE"
    />
    <KpiCard
        title="Years without a budget on 1 January"
        value={resumen[0]?.ejercicios - resumen[0]?.a_tiempo}
        formattedValue="{formatNumber(resumen[0]?.ejercicios - resumen[0]?.a_tiempo, 0)} of {formatNumber(resumen[0]?.ejercicios, 0)}"
        period="since 1978: {formatNumber(resumen[0]?.tarde, 0)} approved late and {formatNumber(resumen[0]?.prorrogados, 0)} rolled over (including the current one)"
        source="BOE"
    />
    <KpiCard
        title="Last ten financial years"
        value={resumen[0]?.sin_ley_10}
        formattedValue="{formatNumber(resumen[0]?.sin_ley_10, 0)} of 10"
        period="started without their own budget"
        source="BOE"
    />
</Grid>

## Every financial year since 1978

Days of each year on which the State operated with the previous year's budget rolled over: 0 if the act was published before 1 January, the whole year if it was never approved. {resumen[0]?.actual} counts the days elapsed up to today.

<BarChart
    data={serie}
    x=ejercicio
    y=dias_prorroga
    series=situacion
    xFmt='0'
    seriesColors={coloresSituacion}
    yAxisTitle="Days of rollover"
    title="Days of each financial year without its own Budget Act in force"
/>

Delays of half a year are concentrated in years with general elections or a change of government close to the previous autumn (1979, 1983, 1990, 2012 and 2017): the outgoing government does not submit the bill or Parliament is dissolved before voting on it, and the new government passes the budget mid-year. In 2018 the delay was due to a lack of support in Congress. Budgets rolled over for the whole year are those in which Congress rejected the bill or the Government never submitted it.

## By government

Each financial year is attributed to the prime minister who **was due to submit the bill**: the one in office on 30 September of the previous year, when the constitutional deadline expires. The last column of the full table also shows who was in government on 1 January, which is who manages the rollover.

<DataTable data={presidentes} rows=all>
    <Column id=presidente title="Prime minister"/>
    <Column id=partido title="Party"/>
    <Column id=ejercicios title="Years due to present" fmt='0'/>
    <Column id=a_tiempo title="On time" fmt='0'/>
    <Column id=tarde title="Late" fmt='0'/>
    <Column id=prorrogados title="Rolled over" fmt='0'/>
    <Column id=pct_sin_ley title="% without an act on 1 January" fmt='0' contentType=bar barColor="#fca5a5"/>
    <Column id=dias_medios title="Days of rollover per year" fmt='0'/>
</DataTable>

## By party: observed versus expected

The **expected** figures are the years without a budget on 1 January that each party would have had if every government had failed at the same rate, according to the number of years each one was due to present. A ratio of 1 is what would be expected; 2, twice as many; 0.5, half.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Prime minister's party"/>
    <Column id=ejercicios title="Years due to present" fmt='0'/>
    <Column id=observados title="Without an act on 1 January" fmt='0'/>
    <Column id=esperados title="Expected" fmt='0.0'/>
    <Column id=ratio title="Observed / expected" fmt='0.00'/>
</DataTable>

The PSOE stands at {formatNumber(partidos_resumen[0]?.psoe, 2)} times what would be expected, the PP at {formatNumber(partidos_resumen[0]?.pp, 2)} and the UCD at {formatNumber(partidos_resumen[0]?.ucd, 2)}. {partidos_resumen[0]?.z_max >= 1.96 ? 'The difference between the PSOE and the PP is greater than chance would explain, although with few financial years.' : 'With so few financial years, the difference between the PSOE and the PP is no greater than chance could explain.'} Whether a budget goes through depends above all on the Government having a majority in Congress, and minority governments or a fragmented Parliament have been more common since 2016.

## All financial years

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=ejercicio title="Financial year" fmt='0'/>
    <Column id=situacion title="Status"/>
    <Column id=ley title="Act"/>
    <Column id=fecha_publicacion title="Published in the BOE" fmt='dd/mm/yyyy'/>
    <Column id=dias_prorroga title="Days of rollover" fmt='0'/>
    <Column id=presidente_responsable title="Due to present it"/>
    <Column id=presidente_1_enero title="In government on 1 January"/>
</DataTable>

## Methodology and sources

- **Source:** daily summaries of the [Official State Gazette (BOE)](https://www.boe.es/datosabiertos/), open data API: acts whose title is «Ley N/AAAA, de ..., de Presupuestos Generales del Estado para el año ...» (General State Budget Act for the year ...). If an act was published in several parts, the date of the first counts. Acts that amend or extend a budget already approved are not counted.
- **Automatic rollover (art. 134.4 of the Constitution):** if the Budget Act is not approved before the first day of the financial year, the previous year's budget is automatically deemed rolled over until the new one is approved. The rollover keeps the previous year's appropriations, but does not allow new spending policies that need their own appropriation, and updates (pensions, public sector pay) are made by royal decree-law.
- **Status:** «On time» = act published in the BOE before 1 January of the financial year; «Late» = published during the financial year; «Rolled over» = the financial year ended without its own act. Days of rollover: from 1 January to publication of the act (the whole year if there was none; up to today in the current financial year).
- **Attribution:** to the prime minister in office on 30 September of the previous year, when the art. 134.3 deadline for submitting the bill expires. This is a debatable choice when the government changes in autumn or winter (financial years 1983 and 2012): the full table also gives the prime minister on 1 January.
- **Expected:** total years without an act on 1 January since 1978, shared out according to the financial years each party was due to present. It assumes that every government had the same probability of failing, which is not the case (a parliamentary majority matters a great deal).
- **International comparison:** not included; the rules on rollover or government shutdown without a budget vary from one country to another and there is no consistent official statistic.
