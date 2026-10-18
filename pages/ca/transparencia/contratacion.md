---
title: Contractació pública
description: "Volum de contractació pública a Espanya, licitacions amb un sol ofertant, procediments sense publicitat, adjudicació a pimes i repartiment per administració segons l'OIReScon."
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

# <span aria-hidden="true">📑</span> Contractació pública

La contractació pública absorbeix prop d'un de cada deu euros del PIB espanyol. L'**Oficina Independent de Regulació i Supervisió de la Contractació (OIReScon)** i el marcador del Mercat Únic de la **Comissió Europea** avaluen cada any la concurrència real de les licitacions: quants diners s'adjudiquen, en quants contractes es presenta **una única empresa** (alerta de baixa competència), quants es tramiten **sense publicitat prèvia** i quin pes tenen els **contractes menors**.

<Grid cols=4>
    <KpiCard
        title="Import adjudicat"
        value={ultimo[0]?.importe_mm_eur}
        formattedValue="{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mil M€"
        period="sense IVA el {ultimo[0]?.anio} · {formatNumber(ultimo[0]?.contratos_miles, 1)} mil contractes ordinaris"
        direction="neutral"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.importe_mm_eur}))}
    />
    <KpiCard
        title="Amb un sol licitador"
        value={ultimo[0]?.pct_un_licitador}
        formattedValue="{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %"
        period="de les licitacions el {ultimo[0]?.anio}"
        direction="positive-down"
        source="OIReScon / Comissió Europea"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_un_licitador}))}
    />
    <KpiCard
        title="Sense publicitat prèvia"
        value={ultimo[0]?.pct_sin_publicidad}
        formattedValue="{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %"
        period="procediment negociat sense publicitat ({ultimo[0]?.anio})"
        direction="positive-down"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_sin_publicidad}))}
    />
    <KpiCard
        title="Adjudicat a pimes"
        value={ultimo[0]?.pymes_pct}
        formattedValue="{formatNumber(ultimo[0]?.pymes_pct, 1)} %"
        period="dels contractes adjudicats el {ultimo[0]?.anio}"
        direction="positive-up"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pymes_pct}))}
    />
</Grid>

## 1. Volum anual de contractació pública

Després de l'aturada del 2020 i la posterior execució dels fons europeus del Pla de Recuperació, l'import anual adjudicat pel conjunt de les administracions públiques (sense impostos) ha crescut fins als **{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mil milions d'euros** el {ultimo[0]?.anio}, repartits en {formatNumber(ultimo[0]?.contratos_miles, 1)} mil contractes ordinaris i més de {formatNumber(ultimo[0]?.contratos_menores_miles, 0)} mil contractes menors registrats.

<BarChart
    data={licitacion_anual}
    x=anio
    y=importe_mm_eur
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Milers de milions d'€ (sense IVA)"
    title="Import anual adjudicat en contractació pública ordinària (milers de M€)"
/>

## 2. Competència efectiva: un terç dels contractes rep una sola oferta

La Llei 9/2017 de Contractes del Sector Públic va reduir dràsticament l'ús del **procediment negociat sense publicitat** (que va caure al **{formatNumber(ultimo[0]?.pct_sin_publicidad, 1)} %** el {ultimo[0]?.anio}, després del repunt excepcional dels contractes d'emergència sanitària el 2020). Tanmateix, el principal indicador d'alerta de la Comissió Europea —la proporció de licitacions obertes en què **només es presenta un únic ofertant**— es manté al voltant del **{formatNumber(ultimo[0]?.pct_un_licitador, 1)} %**.

<LineChart
    data={competencia_serie}
    x=anio
    y=pct
    series=indicador
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dels contractes"
    title="Licitacions amb un únic ofertant i procediments sense publicitat (%)"
/>

## 3. Qui contracta: comunitats i ajuntaments concentren tres quartes parts

Les comunitats autònomes ({formatNumber(por_administracion[0]?.pct_importe, 1)} % de l'import) i les entitats locals ({formatNumber(por_administracion[1]?.pct_importe, 1)} %) gestionen tres de cada quatre euros licitats a Espanya, mentre que l'Administració General de l'Estat representa el {formatNumber(por_administracion[2]?.pct_importe, 1)} %.

<BarChart
    data={por_administracion}
    x=administracion
    y=pct_importe
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="% de l'import adjudicat"
    title="Repartiment de l'import adjudicat per nivell d'administració (%)"
/>

<DataTable data={por_administracion} search=false>
    <Column id=administracion title="Administració" />
    <Column id=importe_mm_eur title="Import (milers M€)" fmt='0.0' />
    <Column id=pct_importe title="% de l'import" fmt='0.0"%"' />
    <Column id=pct_contratos title="% dels contractes" fmt='0.0"%"' />
    <Column id=plazo_medio_dias title="Termini mitjà d'adjudicació (dies)" fmt='0' />
</DataTable>

---

**Fonts i metodologia:**
- [Oficina Independent de Regulació i Supervisió de la Contractació (OIReScon)](https://www.hacienda.gob.es/es-ES/Oirescon/Paginas/ias.aspx) — *Informe Anual de Supervisió de la Contractació Pública a Espanya* (agregat nacional de la Plataforma de Contractació del Sector Públic i plataformes autonòmiques).
- [Comissió Europea — Single Market Scoreboard (Public Procurement)](https://single-market-scoreboard.ec.europa.eu/policy_areas/public-procurement_en).
