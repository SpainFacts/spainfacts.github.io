---
title: Contratación pública
description: "Volume de contratación pública en España, licitacións cun só ofertante, procedementos sen publicidade, adxudicación a pemes e repartición por administración segundo a OIReScon."
i18n_origen: 11662929b821
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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

A contratación pública absorbe preto dun de cada dez euros do PIB español. A **Oficina Independente de Regulación e Supervisión da Contratación (OIReScon)** e o marcador do Mercado Único da **Comisión Europea** avalían cada ano a concorrencia real das licitacións: canto diñeiro se adxudica, en cantos contratos se presenta **unha única empresa** (alerta de baixa competencia), cantos se tramitan **sen publicidade previa** e que peso teñen os **contratos menores**.

<Grid cols=4>
    <KpiCard
        title="Importe adxudicado"
        value={ultimo[0]?.importe_mm_eur}
        formattedValue="{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mil M€"
        period="sen IVE en {ultimo[0]?.anio} · {formatNumber(ultimo[0]?.contratos_miles, 1)} mil contratos ordinarios"
        direction="neutral"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.importe_mm_eur}))}
    />
    <KpiCard
        title="Cun só licitador"
        value={ultimo[0]?.pct_un_licitador}
        formattedValue="{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %"
        period="das licitacións en {ultimo[0]?.anio}"
        direction="positive-down"
        source="OIReScon / Comisión Europea"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_un_licitador}))}
    />
    <KpiCard
        title="Sen publicidade previa"
        value={ultimo[0]?.pct_sin_publicidad}
        formattedValue="{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %"
        period="procedemento negociado sen publicidade ({ultimo[0]?.anio})"
        direction="positive-down"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_sin_publicidad}))}
    />
    <KpiCard
        title="Adxudicado a pemes"
        value={ultimo[0]?.pymes_pct}
        formattedValue="{formatNumber(ultimo[0]?.pymes_pct, 1)} %"
        period="dos contratos adxudicados en {ultimo[0]?.anio}"
        direction="positive-up"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pymes_pct}))}
    />
</Grid>

## 1. Volume anual de contratación pública

Tras o parón de 2020 e a posterior execución dos fondos europeos do Plan de Recuperación, o importe anual adxudicado polo conxunto das administracións públicas (sen impostos) medrou ata os **{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mil millóns de euros** en {ultimo[0]?.anio}, repartidos en {formatNumber(ultimo[0]?.contratos_miles, 1)} mil contratos ordinarios e máis de {formatNumber(ultimo[0]?.contratos_menores_miles, 0)} mil contratos menores rexistrados.

<BarChart
    data={licitacion_anual}
    x=anio
    y=importe_mm_eur
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Miles de millóns de € (sen IVE)"
    title="Importe anual adxudicado en contratación pública ordinaria (miles de M€)"
/>

## 2. Competencia efectiva: un terzo dos contratos recibe unha soa oferta

A Lei 9/2017 de Contratos do Sector Público reduciu drasticamente o uso do **procedemento negociado sen publicidade** (que caeu ao **{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %** en {ultimo[0]?.anio}, tras o repunte excepcional dos contratos de emerxencia sanitaria en 2020). Porén, o principal indicador de alerta da Comisión Europea —a proporción de licitacións abertas nas que **só se presenta un único ofertante**— mantense arredor do **{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %**.

<LineChart
    data={competencia_serie}
    x=anio
    y=pct
    series=indicador
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dos contratos"
    title="Licitacións cun único ofertante e procedementos sen publicidade (%)"
/>

## 3. Quen contrata: comunidades e concellos concentran tres cuartas partes

As comunidades autónomas ({formatNumber(por_administracion[0]?.pct_importe, 1)} % do importe) e as entidades locais ({formatNumber(por_administracion[1]?.pct_importe, 1)} %) xestionan tres de cada catro euros licitados en España, mentres que a Administración Xeral do Estado representa o {formatNumber(por_administracion[2]?.pct_importe, 1)} %.

<BarChart
    data={por_administracion}
    x=administracion
    y=pct_importe
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% do importe adxudicado"
    title="Repartición do importe adxudicado por nivel de administración (%)"
/>

<DataTable data={por_administracion} search=false>
    <Column id=administracion title="Administración" />
    <Column id=importe_mm_eur title="Importe (miles M€)" fmt='0.0' />
    <Column id=pct_importe title="% do importe" fmt='0.0"%"' />
    <Column id=pct_contratos title="% dos contratos" fmt='0.0"%"' />
    <Column id=plazo_medio_dias title="Prazo medio de adxudicación (días)" fmt='0' />
</DataTable>

---

**Fontes e metodoloxía:**
- [Oficina Independente de Regulación e Supervisión da Contratación (OIReScon)](https://www.hacienda.gob.es/es-ES/Oirescon/Paginas/ias.aspx) — *Informe Anual de Supervisión da Contratación Pública en España* (agregado nacional da Plataforma de Contratación do Sector Público e plataformas autonómicas).
- [Comisión Europea — Single Market Scoreboard (Public Procurement)](https://single-market-scoreboard.ec.europa.eu/policy_areas/public-procurement_en).
