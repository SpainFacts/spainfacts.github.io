---
title: Contratación pública
description: "Volumen de contratación pública en España, licitaciones con un solo ofertante, procedimientos sin publicidad, adjudicación a pymes y reparto por administración según la OIReScon."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql licitacion_anual
SELECT * FROM (
    VALUES
        (2019, 134.2, 58.4, 31.0, 4.8, 63.2, 742.0),
        (2020, 118.5, 51.2, 33.0, 8.2, 62.1, 615.0),
        (2021, 152.8, 72.6, 32.0, 3.6, 64.5, 698.0),
        (2022, 169.4, 83.9, 34.0, 2.9, 64.8, 754.0),
        (2023, 181.6, 91.5, 35.0, 2.6, 65.1, 790.0),
        (2024, 186.3, 95.8, 34.5, 2.4, 65.4, 812.0)
) AS t(anio, contratos_miles, importe_mm_eur, pct_un_licitador, pct_sin_publicidad, pymes_pct, contratos_menores_miles)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${licitacion_anual} ORDER BY anio DESC LIMIT 1
```

```sql competencia_serie
SELECT anio, 'Un solo licitador (%)' AS indicador, pct_un_licitador AS pct FROM ${licitacion_anual}
UNION ALL
SELECT anio, 'Negociado sin publicidad (%)' AS indicador, pct_sin_publicidad AS pct FROM ${licitacion_anual}
ORDER BY anio, indicador
```

```sql por_administracion
SELECT * FROM (
    VALUES
        ('Comunidades Autónomas', 40.8, 36.5, 39.1, 108),
        ('Entidades Locales (Ayuntamientos y Diputaciones)', 34.5, 48.2, 33.1, 96),
        ('Administración General del Estado', 24.7, 15.3, 23.6, 114)
) AS t(administracion, pct_importe, pct_contratos, importe_mm_eur, plazo_medio_dias)
ORDER BY pct_importe DESC
```

# <span aria-hidden="true">📑</span> Contratación pública

La contratación pública absorbe cerca de uno de cada diez euros del PIB español. La **Oficina Independiente de Regulación y Supervisión de la Contratación (OIReScon)** y el marcador del Mercado Único de la **Comisión Europea** evalúan cada año la concurrencia real de las licitaciones: cuánto dinero se adjudica, en cuántos contratos se presenta **una única empresa** (alerta de baja competencia), cuántos se tramitan **sin publicidad previa** y qué peso tienen los **contratos menores**.

<Grid cols=4>
    <KpiCard
        title="Importe adjudicado"
        value={ultimo[0]?.importe_mm_eur}
        formattedValue="{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mil M€"
        period="sin IVA en {ultimo[0]?.anio} · {formatNumber(ultimo[0]?.contratos_miles, 1)} mil contratos ordinarios"
        direction="neutral"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.importe_mm_eur}))}
    />
    <KpiCard
        title="Con un solo licitador"
        value={ultimo[0]?.pct_un_licitador}
        formattedValue="{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %"
        period="de las licitaciones en {ultimo[0]?.anio}"
        direction="positive-down"
        source="OIReScon / Comisión Europea"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_un_licitador}))}
    />
    <KpiCard
        title="Sin publicidad previa"
        value={ultimo[0]?.pct_sin_publicidad}
        formattedValue="{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %"
        period="procedimiento negociado sin publicidad ({ultimo[0]?.anio})"
        direction="positive-down"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_sin_publicidad}))}
    />
    <KpiCard
        title="Adjudicado a pymes"
        value={ultimo[0]?.pymes_pct}
        formattedValue="{formatNumber(ultimo[0]?.pymes_pct, 1)} %"
        period="de los contratos adjudicados en {ultimo[0]?.anio}"
        direction="positive-up"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pymes_pct}))}
    />
</Grid>

## 1. Volumen anual de contratación pública

Tras el parón de 2020 y la posterior ejecución de los fondos europeos del Plan de Recuperación, el importe anual adjudicado por el conjunto de las administraciones públicas (sin impuestos) ha crecido hasta los **{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mil millones de euros** en {ultimo[0]?.anio}, repartidos en {formatNumber(ultimo[0]?.contratos_miles, 1)} mil contratos ordinarios y más de {formatNumber(ultimo[0]?.contratos_menores_miles, 0)} mil contratos menores registrados.

<BarChart
    data={licitacion_anual}
    x=anio
    y=importe_mm_eur
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Miles de millones de € (sin IVA)"
    title="Importe anual adjudicado en contratación pública ordinaria (miles de M€)"
/>

## 2. Competencia efectiva: un tercio de los contratos recibe una sola oferta

La Ley 9/2017 de Contratos del Sector Público redujo drásticamente el uso del **procedimiento negociado sin publicidad** (que cayó al **{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %** en {ultimo[0]?.anio}, tras el repunte excepcional de los contratos de emergencia sanitaria en 2020). Sin embargo, el principal indicador de alerta de la Comisión Europea —la proporción de licitaciones abiertas en las que **solo se presenta un único ofertante**— se mantiene en torno al **{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %**.

<LineChart
    data={competencia_serie}
    x=anio
    y=pct
    series=indicador
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de los contratos"
    title="Licitaciones con un único ofertante y procedimientos sin publicidad (%)"
/>

## 3. Quién contrata: comunidades y ayuntamientos concentran tres cuartas partes

Las comunidades autónomas ({formatNumber(por_administracion[0]?.pct_importe, 1)} % del importe) y las entidades locales ({formatNumber(por_administracion[1]?.pct_importe, 1)} %) gestionan tres de cada cuatro euros licitados en España, mientras que la Administración General del Estado representa el {formatNumber(por_administracion[2]?.pct_importe, 1)} %.

<BarChart
    data={por_administracion}
    x=administracion
    y=pct_importe
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% del importe adjudicado"
    title="Reparto del importe adjudicado por nivel de administración (%)"
/>

<DataTable data={por_administracion} search=false>
    <Column id=administracion title="Administración" />
    <Column id=importe_mm_eur title="Importe (miles M€)" fmt='0.0' />
    <Column id=pct_importe title="% del importe" fmt='0.0"%"' />
    <Column id=pct_contratos title="% de los contratos" fmt='0.0"%"' />
    <Column id=plazo_medio_dias title="Plazo medio de adjudicación (días)" fmt='0' />
</DataTable>

---

**Fuentes y metodología:**
- [Oficina Independiente de Regulación y Supervisión de la Contratación (OIReScon)](https://www.hacienda.gob.es/es-ES/Oirescon/Paginas/ias.aspx) — *Informe Anual de Supervisión de la Contratación Pública en España* (agregado nacional de la Plataforma de Contratación del Sector Público y plataformas autonómicas).
- [Comisión Europea — Single Market Scoreboard (Public Procurement)](https://single-market-scoreboard.ec.europa.eu/policy_areas/public-procurement_en).
