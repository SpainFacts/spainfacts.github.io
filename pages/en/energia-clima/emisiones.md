---
title: Emissions and Decarbonisation
description: "Spain's official greenhouse gas (GHG) emissions since 1990, per person, per euro of real GDP and by sector, set against the 2030 targets and the EU average."
i18n_origen: 100c2894f1bf
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT *
FROM mother.clima_emisiones_anual
ORDER BY anio
```

```sql kpi
WITH a AS (
    SELECT *, lag(t_hab) OVER (ORDER BY anio) AS t_hab_prev, lag(total_mt) OVER (ORDER BY anio) AS total_prev
    FROM mother.clima_emisiones_anual
)
SELECT
    CAST(anio AS INTEGER) AS anio,
    provisional,
    fuente,
    t_hab,
    total_mt,
    netas_mt,
    var_1990_pct,
    var_2005_pct,
    100 * (t_hab / t_hab_prev - 1) AS t_hab_var,
    100 * (total_mt / total_prev - 1) AS total_var
FROM a
WHERE anio = (SELECT max(anio) FROM mother.clima_emisiones_anual)
```

```sql hitos
SELECT
    max(total_mt) FILTER (WHERE anio = 1990) AS mt_1990,
    max(t_hab) FILTER (WHERE anio = 1990) AS t_hab_1990,
    max(total_mt) AS mt_max,
    CAST(arg_max(anio, total_mt) AS INTEGER) AS anio_max,
    max(t_hab) AS t_hab_max,
    CAST(arg_max(anio, t_hab) AS INTEGER) AS anio_t_hab_max,
    0.68 * max(total_mt) FILTER (WHERE anio = 1990) AS objetivo_pniec_mt,
    100 * (0.68 * max(total_mt) FILTER (WHERE anio = 1990) / arg_max(total_mt, anio) - 1) AS falta_pniec_pct,
    CAST(max(anio) FILTER (WHERE NOT provisional) AS INTEGER) AS anio_def
FROM mother.clima_emisiones_anual
```

```sql intensidad
SELECT
    CAST(anio AS INTEGER) AS anio,
    kg_por_euro,
    pib_real_hab,
    provisional,
    100 * (kg_por_euro / first_value(kg_por_euro) OVER (ORDER BY anio) - 1) AS var_desde_inicio,
    CAST(first_value(anio) OVER (ORDER BY anio) AS INTEGER) AS anio_inicio
FROM mother.clima_emisiones_anual
WHERE kg_por_euro IS NOT NULL
ORDER BY anio
```

```sql ue_ratio
SELECT
    CAST(anio AS INTEGER) AS anio,
    t_hab,
    t_hab_ue,
    100 * t_hab / t_hab_ue AS pct_ue
FROM mother.clima_emisiones_anual
WHERE t_hab_ue IS NOT NULL
ORDER BY anio
```

```sql hab_largo
SELECT anio, 'España (sin LULUCF)' AS serie, t_hab AS t FROM mother.clima_emisiones_anual
UNION ALL
SELECT anio, 'Media UE-27 (sin LULUCF)' AS serie, t_hab_ue AS t FROM mother.clima_emisiones_anual WHERE t_hab_ue IS NOT NULL
UNION ALL
SELECT anio, 'España, emisiones netas (con sumideros LULUCF)' AS serie, t_hab_netas AS t FROM mother.clima_emisiones_anual
ORDER BY anio, serie
```

```sql indice_1990
SELECT anio, 100 * total_mt / (SELECT total_mt FROM mother.clima_emisiones_anual WHERE anio = 1990) AS indice
FROM mother.clima_emisiones_anual
ORDER BY anio
```

```sql desacople
WITH b AS (
    SELECT * FROM mother.clima_emisiones_anual WHERE kg_por_euro IS NOT NULL
), base AS (
    SELECT * FROM b WHERE anio = (SELECT min(anio) FROM b)
)
SELECT b.anio, 'PIB real por habitante' AS serie, 100 * b.pib_real_hab / base.pib_real_hab AS indice FROM b, base
UNION ALL
SELECT b.anio, 'Emisiones por habitante' AS serie, 100 * b.t_hab / base.t_hab AS indice FROM b, base
UNION ALL
SELECT b.anio, 'Emisiones por euro de PIB' AS serie, 100 * b.kg_por_euro / base.kg_por_euro AS indice FROM b, base
ORDER BY anio, serie
```

```sql sectores
SELECT anio, sector, kg_hab, mt_co2eq, pct_total, provisional
FROM mother.clima_emisiones_sectores
ORDER BY anio, sector
```

```sql sectores_tabla
SELECT
    s.sector,
    max(s.kg_hab) FILTER (WHERE s.anio = 1990) AS kg_1990,
    max(s.kg_hab) FILTER (WHERE s.anio = 2005) AS kg_2005,
    max(s.kg_hab) FILTER (WHERE s.anio = u.anio) AS kg_ult,
    max(s.mt_co2eq) FILTER (WHERE s.anio = u.anio) AS mt_ult,
    max(s.pct_total) FILTER (WHERE s.anio = u.anio) / 100.0 AS peso_ult,
    max(s.mt_co2eq) FILTER (WHERE s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.anio = 1990) - 1 AS var_1990
FROM mother.clima_emisiones_sectores s
CROSS JOIN (SELECT max(anio) AS anio FROM mother.clima_emisiones_sectores) u
GROUP BY s.sector
ORDER BY kg_ult DESC
```

```sql transporte
SELECT
    CAST(u.anio AS INTEGER) AS anio_ult,
    max(s.pct_total) FILTER (WHERE s.sector = 'Transporte' AND s.anio = u.anio) AS pct_transporte,
    100 * (max(s.mt_co2eq) FILTER (WHERE s.sector = 'Transporte' AND s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.sector = 'Transporte' AND s.anio = 1990) - 1) AS var_transporte,
    100 * (max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = 1990) - 1) AS var_electrica,
    100 * (max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = 2005) - 1) AS var_electrica_2005
FROM mother.clima_emisiones_sectores s
CROSS JOIN (SELECT max(anio) AS anio FROM mother.clima_emisiones_sectores) u
GROUP BY u.anio
```

```sql transporte_vs_electrica
SELECT anio, sector, kg_hab
FROM mother.clima_emisiones_sectores
WHERE sector IN ('Transporte', 'Generación Eléctrica')
ORDER BY anio, sector
```

```sql paises
SELECT anio, nombre, t_hab
FROM mother.clima_emisiones_paises
ORDER BY anio, nombre
```

```sql paises_ult
SELECT
    CAST(anio AS INTEGER) AS anio,
    nombre,
    t_hab,
    var_1990_pct / 100.0 AS var_1990,
    mt_co2eq,
    CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.clima_emisiones_paises
WHERE anio = (SELECT max(anio) FROM mother.clima_emisiones_paises)
ORDER BY t_hab DESC
```

```sql paises_rank
WITH u AS (
    SELECT * FROM mother.clima_emisiones_paises
    WHERE anio = (SELECT max(anio) FROM mother.clima_emisiones_paises)
), es AS (
    SELECT t_hab AS t_es, var_1990_pct AS var_es FROM u WHERE geo = 'ES'
)
SELECT
    CAST(max(u.anio) AS INTEGER) AS anio,
    count(*) FILTER (WHERE u.geo NOT IN ('ES', 'EU27_2020') AND u.t_hab < es.t_es) AS menos_que_es,
    max(u.var_1990_pct) FILTER (WHERE u.geo = 'EU27_2020') AS var_ue,
    max(es.var_es) AS var_es
FROM u CROSS JOIN es
```

# 🏭 Greenhouse Gas Emissions in Spain

How much greenhouse gas Spain has emitted since 1990, the reference year for climate commitments, measured **per person** and **per euro of real GDP** so that population and economic growth do not distort the comparison. These are the figures from the official inventory that MITECO (the Ministry for the Ecological Transition) reports to the United Nations and the EU, excluding land use and forestry sinks (LULUCF) except where stated.{#if kpi[0]?.provisional} The {kpi[0]?.anio} figure is MITECO's **provisional estimate**; the final figure will arrive with the next edition of the inventory.{/if}

<Grid cols=4>
    <KpiCard
        title="Emissions per person"
        value={kpi[0]?.t_hab}
        formattedValue="{formatNumber(kpi[0]?.t_hab, 2)} t CO₂eq"
        period="{kpi[0]?.anio}{kpi[0]?.provisional ? ' (provisional estimate)' : ''} · {formatNumber(kpi[0]?.total_mt, 1)} Mt in total"
        change={kpi[0]?.t_hab_var?.toFixed(1)}
        changePeriod="vs previous year"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => ({...d, y: d.t_hab}))}
    />
    <KpiCard
        title="Compared with 1990"
        value={kpi[0]?.var_1990_pct}
        formattedValue="{kpi[0]?.var_1990_pct >= 0 ? '+' : ''}{formatNumber(kpi[0]?.var_1990_pct, 1)} %"
        period="total emissions in {kpi[0]?.anio} · {formatNumber(kpi[0]?.var_2005_pct, 1)} % compared with 2005"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => ({...d, y: d.var_1990_pct}))}
    />
    <KpiCard
        title="Carbon intensity of the economy"
        value={intensidad.slice(-1)[0]?.kg_por_euro}
        formattedValue="{formatNumber(intensidad.slice(-1)[0]?.kg_por_euro * 1000, 0)} g CO₂eq/€"
        period="per euro of real GDP (constant euros) in {intensidad.slice(-1)[0]?.anio}"
        change={intensidad.slice(-1)[0]?.var_desde_inicio?.toFixed(0)}
        changePeriod="since {intensidad[0]?.anio}"
        direction="positive-down"
        source="Eurostat"
        sparklineData={intensidad.map(d => ({...d, y: d.kg_por_euro}))}
    />
    <KpiCard
        title="Spain compared with the EU"
        value={ue_ratio.slice(-1)[0]?.pct_ue}
        formattedValue="{formatNumber(ue_ratio.slice(-1)[0]?.pct_ue, 0)} % of the average"
        period="per person in {ue_ratio.slice(-1)[0]?.anio}: {formatNumber(ue_ratio.slice(-1)[0]?.t_hab, 1)} t vs {formatNumber(ue_ratio.slice(-1)[0]?.t_hab_ue, 1)} t in the EU-27"
        direction="positive-down"
        source="Eurostat"
        sparklineData={ue_ratio.map(d => ({...d, y: d.pct_ue}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('gei_pc')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gei_pc')} />


## Emissions per person since 1990

A Spanish resident emitted {formatNumber(hitos[0]?.t_hab_1990, 1)} t of CO₂ equivalent in 1990; the peak was {formatNumber(hitos[0]?.t_hab_max, 1)} t in {hitos[0]?.anio_t_hab_max} and in {kpi[0]?.anio} the figure is {formatNumber(kpi[0]?.t_hab, 1)} t. The net emissions line subtracts the CO₂ absorbed by forests and soils (LULUCF). The EU average only runs to the last year of the final inventory.

<LineChart
    data={hab_largo}
    x=anio
    y=t
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq per person"
    title="GHG emissions per person: Spain and EU-27"
    colorPalette={['#dc2626', '#16a34a', '#2563eb']}
/>

<DownloadCsvButton data={anual} filename="spainfacts_emisiones_gei_anual.csv" label="Download annual series (CSV)" />

## Far from the 2030 target

Total emissions peaked in {hitos[0]?.anio_max} ({formatNumber(hitos[0]?.mt_max, 0)} Mt) and in {kpi[0]?.anio} they stand {formatNumber(Math.abs(kpi[0]?.var_1990_pct), 1)} % {#if kpi[0]?.var_1990_pct < 0}below{:else}above{/if} 1990. The National Integrated Energy and Climate Plan (PNIEC 2023-2030) sets a 32 % reduction on 1990 levels by 2030, some {formatNumber(hitos[0]?.objetivo_pniec_mt, 0)} Mt: from the {kpi[0]?.anio} level, a further {formatNumber(Math.abs(hitos[0]?.falta_pniec_pct), 0)} % cut would be needed.

<LineChart
    data={indice_1990}
    x=anio
    y=indice
    xFmt='0'
    yFmt='0'
    yAxisTitle="1990 = 100"
    title="Total GHG emissions (index 1990 = 100)"
    colorPalette={['#dc2626']}
>
    <ReferenceLine y=68 label="PNIEC 2030 target (-32 %)" color="#16a34a" />
    <ReferenceLine y=100 label="1990 level" color="#6b7280" />
</LineChart>

## Growing while emitting less

Since {intensidad[0]?.anio}, real GDP per person and emissions per person have followed different paths: each euro of real GDP is now produced with {formatNumber(Math.abs(intensidad.slice(-1)[0]?.var_desde_inicio), 0)} % {#if intensidad.slice(-1)[0]?.var_desde_inicio < 0}fewer{:else}more{/if} emissions than in {intensidad[0]?.anio}. GDP is measured in constant euros, adjusted for inflation.

<LineChart
    data={desacople}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="{intensidad[0]?.anio} = 100"
    title="Real GDP and emissions per person (index {intensidad[0]?.anio} = 100)"
    colorPalette={['#16a34a', '#dc2626', '#2563eb']}
/>

## Who emits? Emissions by sector

Kilograms of CO₂ equivalent per person per year, by emitting sector.

<AreaChart
    data={sectores}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq per person"
    title="GHG emissions by sector, per person"
/>

<DataTable data={sectores_tabla} search=false rows=10>
    <Column id=sector title="Sector" />
    <Column id=kg_1990 title="kg/person 1990" fmt="#,##0" />
    <Column id=kg_2005 title="kg/person 2005" fmt="#,##0" />
    <Column id=kg_ult title="kg/person latest year" fmt="#,##0" />
    <Column id=peso_ult title="% of total" fmt="pct1" contentType=colorscale colorScale={['#fef3c7', '#dc2626']} />
    <Column id=var_1990 title="Total vs 1990" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_ult title="Mt latest year" fmt="num1" />
</DataTable>

<DownloadCsvButton data={sectores} filename="spainfacts_emisiones_gei_sectorial.csv" label="Download emissions by sector (CSV)" />

## Transport, the sector that won't come down

Transport accounts for **{formatNumber(transporte[0]?.pct_transporte, 1)} %** of emissions in {transporte[0]?.anio_ult} and emits {formatNumber(Math.abs(transporte[0]?.var_transporte), 0)} % {#if transporte[0]?.var_transporte >= 0}more{:else}less{/if} than in 1990. Electricity generation, by contrast, emits {formatNumber(Math.abs(transporte[0]?.var_electrica), 0)} % {#if transporte[0]?.var_electrica < 0}less{:else}more{/if} than in 1990 and {formatNumber(Math.abs(transporte[0]?.var_electrica_2005), 0)} % {#if transporte[0]?.var_electrica_2005 < 0}less{:else}more{/if} than in 2005. More detail on the [electricity mix](/en/energia-clima/mix-electrico) page.

<LineChart
    data={transporte_vs_electrica}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq per person"
    title="Transport vs electricity generation (kg per person)"
    colorPalette={['#16a34a', '#f97316']}
/>

## Spain in Europe

Emissions per person excluding LULUCF, using each country's final inventory. In {paises_rank[0]?.anio}, {paises_rank[0]?.menos_que_es} of the six large countries compared emitted less per person than Spain. Since 1990 Spain's total emissions have changed by {formatNumber(paises_rank[0]?.var_es, 1)} %, compared with {formatNumber(paises_rank[0]?.var_ue, 1)} % for the EU-27 as a whole.

<BarChart
    data={paises_ult}
    x=nombre
    y=t_hab
    series=grupo
    swapXY=true
    yFmt='0.0'
    yAxisTitle="t CO₂eq per person"
    title="Emissions per person in {paises_ult[0]?.anio}"
    colorPalette={['#dc2626', '#94a3b8', '#2563eb']}
/>

<LineChart
    data={paises}
    x=anio
    y=t_hab
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq per person"
    title="Emissions per person over time"
/>

<DataTable data={paises_ult} search=false rows=10>
    <Column id=nombre title="Country" />
    <Column id=t_hab title="t CO₂eq/person" fmt="num1" />
    <Column id=var_1990 title="Total emissions vs 1990" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_co2eq title="Total Mt" fmt="num0" />
</DataTable>

## Reduction targets

| Horizon | Target | Reference |
|:---|:---|:---|
| **2030 (Spain)** | -32 % emissions compared with 1990 | PNIEC 2023-2030 |
| **2030 (Spain, non-ETS sectors)** | -37.7 % compared with 2005 in transport, buildings, agriculture, waste and fluorinated gases (outside the emissions trading system) | Effort Sharing Regulation, (EU) 2023/857 |
| **2030 (EU)** | -55 % net emissions compared with 1990 | European Climate Law, Regulation (EU) 2021/1119 |
| **2050** | Climate neutrality (net zero emissions) | Law 7/2021 on climate change and European Climate Law |

---

## Sources

- **National GHG Emissions Inventory (MITECO)**, reported to the United Nations Framework Convention on Climate Change, downloaded from Eurostat [env_air_gge](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) by CRF category. Methodology: 2006 IPCC guidelines. [MITECO – Inventory](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gases-efecto-invernadero.html).
- **Provisional inventory estimate** for the latest year: [MITECO, advance note on 2025 GHG emissions](https://www.miteco.gob.es/content/dam/miteco/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/Nota-Avance-GEI-2025.pdf) (July 2026). It is replaced by the final figure once Eurostat publishes it.
- **Average annual population**: Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table). **Real GDP per person**: Eurostat [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), in constant euros (see [GDP per person](/en/economia)).
- Sector grouping: Electricity Generation = 1A1a; Transport = 1A3 (domestic, excluding international bunkers); Industry and Processes = 1A1b-c + 1A2 + 1B + 2 (except 2F and 2G); Residential and Commercial = 1A4a-b; Agriculture and Livestock = 3 + 1A4c; Waste = 5; Fluorinated Gases and Other = 2F + 2G + 1A5 + 6.

<LastRefreshed prefix="Last data sync" />
