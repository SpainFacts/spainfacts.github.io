---
title: Subvencións
description: "Canto diñeiro público se concede en subvencións en España, que porcentaxe se adxudica por concesión directa ou nominativa fronte a concorrencia competitiva e que administración o xestiona (BDNS / IGAE)."
i18n_origen: 3373354f3424
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

# <span aria-hidden="true">💶</span> Subvencións públicas

A Lei 38/2003 Xeral de Subvencións establece como procedemento ordinario a **concorrencia competitiva** (convocatoria aberta na que as solicitudes se comparan e bareman con criterios obxectivos). A lei permite como excepción as subvencións **nominativas** (con beneficiario fixado nos orzamentos) e as de **concesión directa** por razóns de interese público, social ou económico. Os rexistros da **Base de Datos Nacional de Subvencións (BDNS / IGAE)** permiten medir que parte dos fondos se reparte por cada vía.

<Grid cols=4>
    <KpiCard
        title="Importe total concedido"
        value={ultimo[0]?.importe_total_mm}
        formattedValue="{formatNumber(ultimo[0]?.importe_total_mm, 1)} mil M€"
        period="rexistrado na BDNS en {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.importe_total_mm}))}
    />
    <KpiCard
        title="Sen concorrencia competitiva"
        value={ultimo[0]?.pct_directa}
        formattedValue="{formatNumber(ultimo[0]?.pct_directa, 1)} %"
        period="concesión directa ou nominativa ({ultimo[0]?.anio}) · {formatNumber(ultimo[0]?.directa_mm, 1)} mil M€"
        direction="positive-down"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.pct_directa}))}
    />
    <KpiCard
        title="En concorrencia competitiva"
        value={ultimo[0]?.concurrencia_mm}
        formattedValue="{formatNumber(ultimo[0]?.concurrencia_mm, 1)} mil M€"
        period="convocatorias abertas en {ultimo[0]?.anio} ({formatNumber(100 - ultimo[0]?.pct_directa, 1)} %)"
        direction="positive-up"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concurrencia_mm}))}
    />
    <KpiCard
        title="Concesións rexistradas"
        value={ultimo[0]?.concesiones_miles}
        formattedValue="{formatNumber(ultimo[0]?.concesiones_miles, 0)} mil"
        period="resolucións individuais en {ultimo[0]?.anio}"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concesiones_miles}))}
    />
</Grid>

## 1. Concorrencia competitiva fronte a concesión directa

Catro de cada dez euros en subvencións (**{formatNumber(ultimo[0]?.pct_directa, 1)} %** en {ultimo[0]?.anio}) adxudícanse mediante procedementos de concesión directa ou nominativa. Durante a pandemia (2020–2021), as axudas extraordinarias de emerxencia elevaron temporalmente a vía directa por riba da metade do importe total; desde entón o peso da concorrencia competitiva recuperouse, pero o volume total de subvencións segue sendo case o dobre ca en 2018 polo despregamento dos fondos europeos PRTR.

<BarChart
    data={modalidad_serie}
    x=anio
    y=importe_mm
    series=modalidad
    type=stacked
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Miles de millóns de €"
    title="Subvencións concedidas segundo procedemento: concorrencia competitiva vs. directa (miles de M€)"
/>

<LineChart
    data={subvenciones_anual}
    x=anio
    y=pct_directa
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% do importe total"
    startingAtZero={false}
    title="Porcentaxe do importe de subvencións concedido sen concorrencia competitiva (%)"
/>

## 2. Repartición por nivel de administración

A Administración Xeral do Estado concentra algo máis da metade do importe rexistrado na BDNS ({formatNumber(subvenciones_admin[0]?.pct_total, 1)} %) e presenta tamén a maior proporción de concesións directas e nominativas ({formatNumber(subvenciones_admin[0]?.pct_directa, 1)} %), seguida polas comunidades autónomas ({formatNumber(subvenciones_admin[1]?.pct_total, 1)} % do total) e os concellos e deputacións ({formatNumber(subvenciones_admin[2]?.pct_total, 1)} %).

<DataTable data={subvenciones_admin} search=false>
    <Column id=administracion title="Administración concedente" />
    <Column id=importe_mm title="Importe (miles M€)" fmt='0.0' />
    <Column id=pct_total title="% do total nacional" fmt='0.0"%"' />
    <Column id=pct_directa title="% en concesión directa / nominativa" fmt='0.0"%"' />
</DataTable>

---

**Fontes e metodoloxía:**
- [Base de Datos Nacional de Subvencións (BDNS) — Intervención Xeral da Administración do Estado (IGAE)](https://www.infosubvenciones.es/bdnstrans/GE/es/index) e controis de auditoría de subvencións da IGAE / AIReF (*Spending Review* de subvencións públicas).
- Para consultar as subvencións e publicidade institucional destinadas especificamente a prensa, radio e televisión, visita a sección de [Medios de comunicación](/gl/medios/subvenciones).
