---
title: Subvencions
description: "Quants diners públics es concedeixen en subvencions a Espanya, quin percentatge s'adjudica per concessió directa o nominativa enfront de concurrència competitiva i quina administració ho gestiona (BDNS / IGAE)."
i18n_origen: 9dbf4f2110e5
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql subvenciones_anual
SELECT * FROM (
    VALUES
        (2018, 19.8, 12.9, 6.9, 34.8, 920),
        (2019, 21.4, 13.7, 7.7, 36.0, 985),
        (2020, 31.6, 15.2, 16.4, 51.9, 1480),
        (2021, 35.8, 18.4, 17.4, 48.6, 1620),
        (2022, 38.2, 21.8, 16.4, 42.9, 1540),
        (2023, 39.5, 23.3, 16.2, 41.0, 1590),
        (2024, 37.9, 22.9, 15.0, 39.6, 1510)
) AS t(anio, importe_total_mm, concurrencia_mm, directa_mm, pct_directa, concesiones_miles)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${subvenciones_anual} ORDER BY anio DESC LIMIT 1
```

```sql modalidad_serie
SELECT anio, 'Concurrencia competitiva' AS modalidad, concurrencia_mm AS importe_mm FROM ${subvenciones_anual}
UNION ALL
SELECT anio, 'Concesión directa y nominativa' AS modalidad, directa_mm AS importe_mm FROM ${subvenciones_anual}
ORDER BY anio, modalidad
```

```sql subvenciones_admin
SELECT * FROM (
    VALUES
        ('Administración General del Estado', 19.4, 51.2, 43.5),
        ('Comunidades Autónomas', 14.2, 37.5, 36.8),
        ('Entidades Locales', 4.3, 11.3, 31.2)
) AS t(administracion, importe_mm, pct_total, pct_directa)
ORDER BY importe_mm DESC
```

# <span aria-hidden="true">💶</span> Subvencions públiques

La Llei 38/2003 General de Subvencions estableix com a procediment ordinari la **concurrència competitiva** (convocatòria oberta en què les sol·licituds es comparen i baremen amb criteris objectius). La llei permet com a excepció les subvencions **nominatives** (amb beneficiari fixat als pressupostos) i les de **concessió directa** per raons d'interès públic, social o econòmic. Els registres de la **Base de Dades Nacional de Subvencions (BDNS / IGAE)** permeten mesurar quina part dels fons es reparteix per cada via.

<Grid cols=4>
    <KpiCard
        title="Import total concedit"
        value={ultimo[0]?.importe_total_mm}
        formattedValue="{formatNumber(ultimo[0]?.importe_total_mm, 1)} mil M€"
        period="registrat a la BDNS el {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.importe_total_mm}))}
    />
    <KpiCard
        title="Sense concurrència competitiva"
        value={ultimo[0]?.pct_directa}
        formattedValue="{formatNumber(ultimo[0]?.pct_directa, 1)} %"
        period="concessió directa o nominativa ({ultimo[0]?.anio}) · {formatNumber(ultimo[0]?.directa_mm, 1)} mil M€"
        direction="positive-down"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.pct_directa}))}
    />
    <KpiCard
        title="En concurrència competitiva"
        value={ultimo[0]?.concurrencia_mm}
        formattedValue="{formatNumber(ultimo[0]?.concurrencia_mm, 1)} mil M€"
        period="convocatòries obertes el {ultimo[0]?.anio} ({formatNumber(100 - ultimo[0]?.pct_directa, 1)} %)"
        direction="positive-up"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concurrencia_mm}))}
    />
    <KpiCard
        title="Concessions registrades"
        value={ultimo[0]?.concesiones_miles}
        formattedValue="{formatNumber(ultimo[0]?.concesiones_miles, 0)} mil"
        period="resolucions individuals el {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concesiones_miles}))}
    />
</Grid>

## 1. Concurrència competitiva enfront de concessió directa

Quatre de cada deu euros en subvencions (**{formatNumber(ultimo[0]?.pct_directa, 1)} %** el {ultimo[0]?.anio}) s'adjudiquen mitjançant procediments de concessió directa o nominativa. Durant la pandèmia (2020–2021), les ajudes extraordinàries d'emergència van elevar temporalment la via directa per sobre de la meitat de l'import total; des d'aleshores el pes de la concurrència competitiva s'ha recuperat, però el volum total de subvencions continua sent gairebé el doble que el 2018 pel desplegament dels fons europeus PRTR.

<BarChart
    data={modalidad_serie}
    x=anio
    y=importe_mm
    series=modalidad
    type=stacked
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Milers de milions d'€"
    title="Subvencions concedides segons procediment: concurrència competitiva vs. directa (milers de M€)"
/>

<LineChart
    data={subvenciones_anual}
    x=anio
    y=pct_directa
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de l'import total"
    startingAtZero={false}
    title="Percentatge de l'import de subvencions concedit sense concurrència competitiva (%)"
/>

## 2. Repartiment per nivell d'administració

L'Administració General de l'Estat concentra una mica més de la meitat de l'import registrat a la BDNS ({formatNumber(subvenciones_admin[0]?.pct_total, 1)} %) i presenta també la proporció més alta de concessions directes i nominatives ({formatNumber(subvenciones_admin[0]?.pct_directa, 1)} %), seguida per les comunitats autònomes ({formatNumber(subvenciones_admin[1]?.pct_total, 1)} % del total) i els ajuntaments i diputacions ({formatNumber(subvenciones_admin[2]?.pct_total, 1)} %).

<DataTable data={subvenciones_admin} search=false>
    <Column id=administracion title="Administració concedent" />
    <Column id=importe_mm title="Import (milers M€)" fmt='0.0' />
    <Column id=pct_total title="% del total nacional" fmt='0.0"%"' />
    <Column id=pct_directa title="% en concessió directa / nominativa" fmt='0.0"%"' />
</DataTable>

---

**Fonts i metodologia:**
- [Base de Dades Nacional de Subvencions (BDNS) — Intervenció General de l'Administració de l'Estat (IGAE)](https://www.infosubvenciones.es/bdnstrans/GE/es/index) i controls d'auditoria de subvencions de la IGAE / AIReF (*Spending Review* de subvencions públiques).
- Per consultar les subvencions i publicitat institucional destinades específicament a premsa, ràdio i televisió, visita la secció de [Mitjans i diners públics](/ca/medios/dinero-publico).
