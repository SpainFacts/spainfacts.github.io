---
title: Businesses, entrepreneurship and R&D
description: "How many businesses there are in Spain per inhabitant and how large they are, how many companies are set up and dissolved, insolvency proceedings, the self-employed and R&D spending compared with Europe and by region."
i18n_origen: 990f0d94edd2
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql emp_pais
SELECT CAST(anio AS INTEGER) AS anio, empresas, empresas_1000hab, pct_personas_fisicas, crecimiento_pct
FROM mother.empresas_dirce_territorio
WHERE nivel = 'pais'
ORDER BY anio
```

```sql emp_hitos
SELECT
    max(empresas_1000hab) FILTER (WHERE anio = 2008) AS e2008,
    max(anio) AS anio_ult,
    max(empresas_1000hab) FILTER (WHERE anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)) AS e_ult,
    max(empresas_1000hab) FILTER (WHERE anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio) - 1) AS e_ant,
    max(empresas) FILTER (WHERE anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)) AS empresas_ult
FROM mother.empresas_dirce_territorio
WHERE nivel = 'pais'
```

```sql soc_12m
SELECT fecha, constituidas_12m_100k, disueltas_12m_100k, constituidas_12m, disueltas_12m,
    CAST(anio AS INTEGER) AS anio, CAST(mes AS INTEGER) AS mes
FROM mother.empresas_sociedades_mensual
WHERE cod = '00' AND constituidas_12m_100k IS NOT NULL
ORDER BY fecha
```

```sql soc_12m_ult
SELECT
    s.*,
    strftime(s.fecha, '%m/%Y') AS mes_texto,
    100 * (s.constituidas_12m / a.constituidas_12m - 1) AS cambio_anual
FROM ${soc_12m} s
LEFT JOIN ${soc_12m} a ON a.fecha = s.fecha - INTERVAL 1 YEAR
ORDER BY s.fecha DESC
LIMIT 1
```

```sql autonomos_pais
SELECT periodo, CAST(anio AS INTEGER) AS anio, trimestre, fecha, ocupados, cuenta_propia, empleadores, independientes,
    pct_cuenta_propia, pct_empleadores, pct_independientes
FROM mother.empresas_autonomos
WHERE cod = '00'
ORDER BY fecha
```

```sql autonomos_anual
SELECT CAST(anio AS INTEGER) AS anio, ocupados, cuenta_propia, empleadores, independientes,
    pct_cuenta_propia, pct_empleadores, pct_independientes
FROM mother.empresas_autonomos_anual
WHERE cod = '00'
ORDER BY anio
```

```sql autonomos_ult
SELECT * FROM ${autonomos_pais} ORDER BY fecha DESC LIMIT 1
```

```sql id_es
SELECT CAST(anio AS INTEGER) AS anio, pct_pib, eur_hab_real, investigadores_1000ocup, CAST(anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_id_paises
WHERE geo = 'ES' AND sector = 'Total' AND pct_pib IS NOT NULL
ORDER BY anio
```

```sql id_ue_ult
SELECT
    e.anio,
    e.pct_pib AS es,
    u.pct_pib AS ue,
    e.eur_hab_real AS es_hab,
    u.eur_hab_real AS ue_hab,
    e.investigadores_1000ocup AS es_inv,
    u.investigadores_1000ocup AS ue_inv
FROM mother.empresas_id_paises e
JOIN mother.empresas_id_paises u ON u.geo = 'EU27_2020' AND u.anio = e.anio AND u.sector = 'Total'
WHERE e.geo = 'ES' AND e.sector = 'Total' AND e.pct_pib IS NOT NULL AND u.pct_pib IS NOT NULL
ORDER BY e.anio DESC
LIMIT 1
```

# 🏭 Businesses, entrepreneurship and R&D

How many businesses there are in Spain and how large they are, how many companies are set up and how many close, how many workers are self-employed and how much is invested in research and development (R&D) compared with Europe. Figures are given per inhabitant, as a percentage or, where they are in euros, adjusted for inflation.

<Grid cols=4>
    <KpiCard
        title="Businesses per 1,000 inhabitants"
        value={emp_hitos[0]?.e_ult}
        formattedValue={formatNumber(emp_hitos[0]?.e_ult, 1)}
        period="active on 1 January {emp_hitos[0]?.anio_ult} · {formatCompact(emp_hitos[0]?.empresas_ult, 2)} businesses, including the self-employed"
        change={(emp_hitos[0]?.e_ult - emp_hitos[0]?.e_ant)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs previous year"
        direction="positive-up"
        source="INE / DIRCE"
        sparklineData={emp_pais.map(d => ({...d, y: d.empresas_1000hab}))}
    />
    <KpiCard
        title="Companies set up"
        value={soc_12m_ult[0]?.constituidas_12m_100k}
        formattedValue="{formatNumber(soc_12m_ult[0]?.constituidas_12m_100k, 0)} per 100,000 inhab."
        period="in the 12 months to {soc_12m_ult[0]?.mes_texto} · {formatNumber(soc_12m_ult[0]?.constituidas_12m, 0)} trading companies"
        change={soc_12m_ult[0]?.cambio_anual?.toFixed(1)}
        changePeriod="vs 12 months earlier"
        direction="positive-up"
        source="INE / Trading Companies Statistics"
        sparklineData={soc_12m.slice(-120).map(d => ({...d, y: d.constituidas_12m_100k}))}
    />
    <KpiCard
        title="Self-employed"
        value={autonomos_ult[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(autonomos_ult[0]?.pct_cuenta_propia, 1)}% of the employed"
        period="work for themselves ({autonomos_ult[0]?.periodo}) · {formatNumber(autonomos_ult[0]?.cuenta_propia / 1000, 2)} million people"
        direction="neutral"
        source="INE / EPA"
        sparklineData={autonomos_anual.map(d => ({...d, y: d.pct_cuenta_propia}))}
    />
    <KpiCard
        title="R&D spending"
        value={id_ue_ult[0]?.es}
        formattedValue="{formatNumber(id_ue_ult[0]?.es, 2)}% of GDP"
        period="in {id_ue_ult[0]?.anio} · EU-27: {formatNumber(id_ue_ult[0]?.ue, 2)}% · €{formatNumber(id_ue_ult[0]?.es_hab, 0)} per inhabitant ({id_es.slice(-1)[0]?.anio_euros} euros)"
        direction="positive-up"
        source="Eurostat / INE"
        sparklineData={id_es.map(d => ({...d, y: d.pct_pib}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('id_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'id_pib')} />


## How many businesses there are

```sql emp_ccaa
SELECT
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    e.cod,
    e.empresas,
    e.empresas_1000hab,
    e.pct_personas_fisicas,
    100 * e.empresas_1000hab / es.empresas_1000hab AS indice_espana,
    CAST(e.anio AS INTEGER) AS anio
FROM mother.empresas_dirce_territorio e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.empresas_dirce_territorio es ON es.nivel = 'pais' AND es.anio = e.anio
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)
ORDER BY e.empresas_1000hab DESC
```

The INE's Central Business Register (DIRCE) counts every active business on 1 January, including the self-employed, except those in farming and fishing, public administration and domestic service. In {emp_hitos[0]?.anio_ult} there were {formatNumber(emp_hitos[0]?.e_ult, 1)} per 1,000 inhabitants, compared with {formatNumber(emp_hitos[0]?.e2008, 1)} in 2008. In 2023 the INE switched to counting only economically active businesses: the drop that year reflects the change of criterion (on a like-for-like basis the number of businesses grew by 0.5%, according to the INE).

<LineChart
    data={emp_pais}
    x=anio
    y=empresas_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="businesses per 1,000 inhab."
    startingAtZero={false}
    title="Active businesses per 1,000 inhabitants"
/>

<BarChart
    data={emp_pais}
    x=anio
    y=pct_personas_fisicas
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of businesses"
    title="Businesses that are natural persons (self-employed people running a business), % of total"
/>

By region, {emp_ccaa[0]?.comunidad} has the highest business density, with {formatNumber(emp_ccaa[0]?.empresas_1000hab, 1)} businesses per 1,000 inhabitants, and {emp_ccaa.slice(-1)[0]?.comunidad} the lowest, with {formatNumber(emp_ccaa.slice(-1)[0]?.empresas_1000hab, 1)}. Businesses are counted in the region where they have their head office, not where their premises are.

<MapaEspana
    data={emp_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="empresas_1000hab"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'empresas_1000hab', title: 'Businesses per 1,000 inhab.', fmt: '0.0'},
        {id: 'empresas', title: 'Businesses', fmt: '#,##0'}
    ]}
/>

## Size: almost all are very small

```sql tamano_es
SELECT tamano, orden, empresas, pct, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_tamano
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_tamano)
ORDER BY orden
```

```sql tamano_resumen
SELECT
    max(pct) FILTER (WHERE tamano = 'Sin asalariados') AS sin_asal,
    sum(pct) FILTER (WHERE orden <= 2) AS hasta_9,
    sum(pct) FILTER (WHERE orden >= 4) AS medianas_grandes,
    max(empresas) FILTER (WHERE tamano = 'Grandes (250 o más)') AS grandes,
    max(anio) AS anio
FROM ${tamano_es}
```

In {tamano_resumen[0]?.anio}, {formatNumber(tamano_resumen[0]?.sin_asal, 1)}% of businesses had no employees at all and {formatNumber(tamano_resumen[0]?.hasta_9, 1)}% had fewer than 10. Only {formatNumber(tamano_resumen[0]?.medianas_grandes, 2)}% had 50 or more employees; large businesses, with 250 or more, numbered {formatNumber(tamano_resumen[0]?.grandes, 0)}.

<BarChart
    data={tamano_es}
    x=tamano
    y=pct
    sort=false
    swapXY=true
    yFmt='0.00"%"'
    title="Businesses by number of employees, % of total ({tamano_es[0]?.anio})"
/>

```sql tamano_ue
SELECT cod_pais, pais, tamano, orden, pct_empresas, pct_empleo, pct_vab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_tamano_ue
WHERE anio = (SELECT max(anio) FROM mother.empresas_tamano_ue WHERE cod_pais = 'EU27_2020' AND pct_vab IS NOT NULL)
  AND cod_pais IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT')
ORDER BY orden, pais
```

```sql tamano_ue_resumen
SELECT
    max(pct_empleo) FILTER (WHERE cod_pais = 'ES' AND orden = 1) AS es_micro,
    max(pct_empleo) FILTER (WHERE cod_pais = 'EU27_2020' AND orden = 1) AS ue_micro,
    max(pct_empleo) FILTER (WHERE cod_pais = 'ES' AND orden = 4) AS es_grandes,
    max(pct_empleo) FILTER (WHERE cod_pais = 'EU27_2020' AND orden = 4) AS ue_grandes,
    max(pct_empleo) FILTER (WHERE cod_pais = 'DE' AND orden = 4) AS de_grandes,
    max(anio) AS anio
FROM ${tamano_ue}
```

To compare with Europe, Eurostat measures size by persons employed (including owners) and leaves out finance. In {tamano_ue_resumen[0]?.anio}, micro-enterprises (fewer than 10 persons employed) accounted for {formatNumber(tamano_ue_resumen[0]?.es_micro, 1)}% of business employment in Spain, compared with {formatNumber(tamano_ue_resumen[0]?.ue_micro, 1)}% in the EU-27; large enterprises for {formatNumber(tamano_ue_resumen[0]?.es_grandes, 1)}% compared with {formatNumber(tamano_ue_resumen[0]?.ue_grandes, 1)}% (in Germany, {formatNumber(tamano_ue_resumen[0]?.de_grandes, 1)}%).

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_empleo
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Share of business employment by enterprise size ({tamano_ue[0]?.anio})"
/>

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_vab
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Share of value added by enterprise size ({tamano_ue[0]?.anio})"
/>

## What they do

```sql sector_es
SELECT sector, empresas, pct, por_1000_hab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_sector
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_sector)
ORDER BY pct DESC
```

Active businesses by broad sector in {sector_es[0]?.anio}. {sector_es[0]?.sector} is the sector with the most businesses: {formatNumber(sector_es[0]?.pct, 1)}% of the total, {formatNumber(sector_es[0]?.por_1000hab, 1)} per 1,000 inhabitants.

<BarChart
    data={sector_es}
    x=sector
    y=por_1000_hab
    swapXY=true
    yFmt='0.0'
    title="Businesses per 1,000 inhabitants by activity ({sector_es[0]?.anio})"
/>

## Companies set up and dissolved

```sql soc_largo
SELECT fecha, 'Creadas' AS tipo, constituidas_12m_100k AS valor FROM ${soc_12m}
UNION ALL
SELECT fecha, 'Disueltas' AS tipo, disueltas_12m_100k AS valor FROM ${soc_12m}
ORDER BY fecha, tipo
```

```sql soc_anual
SELECT CAST(anio AS INTEGER) AS anio, constituidas, disueltas, constituidas_100k, disueltas_100k, saldo_100k,
    ratio_disueltas, capital_real, capital_medio_real, capital_real_hab, CAST(anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_sociedades_anual
WHERE cod = '00'
ORDER BY anio
```

```sql soc_hitos
SELECT
    max(constituidas_100k) FILTER (WHERE anio = 2006) AS c2006,
    max(constituidas_100k) FILTER (WHERE anio = 2009) AS c2009,
    max(constituidas_100k) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS c_ult,
    max(disueltas_100k) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS d_ult,
    max(ratio_disueltas) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS ratio_ult,
    max(capital_medio_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS cap_medio_ult,
    max(capital_medio_real) FILTER (WHERE anio = 2006) AS cap_medio_2006,
    max(anio) AS anio_ult
FROM ${soc_anual}
```

Trading companies (mostly private and public limited companies) registered and dissolved at the Companies Register, adding up the previous 12 months and per 100,000 inhabitants. In {soc_hitos[0]?.anio_ult}, {formatNumber(soc_hitos[0]?.c_ult, 0)} were set up per 100,000 inhabitants, compared with {formatNumber(soc_hitos[0]?.c2006, 0)} in 2006 and {formatNumber(soc_hitos[0]?.c2009, 0)} in 2009; {formatNumber(soc_hitos[0]?.d_ult, 0)} per 100,000 were dissolved, that is, {formatNumber(soc_hitos[0]?.ratio_ult, 0)} for every 100 set up. The self-employed are not included here.

<LineChart
    data={soc_largo}
    x=fecha
    y=valor
    series=tipo
    yFmt='0'
    yAxisTitle="per 100,000 inhab. (12 months)"
    colorPalette={['#2563eb', '#dc2626']}
    title="Trading companies set up and dissolved in the last 12 months, per 100,000 inhabitants"
/>

The capital that new companies start with, adjusted for inflation, has fallen: average subscribed capital was €{formatNumber(soc_hitos[0]?.cap_medio_ult, 0)} in {soc_hitos[0]?.anio_ult}, compared with €{formatNumber(soc_hitos[0]?.cap_medio_2006, 0)} in 2006 ({soc_anual.slice(-1)[0]?.anio_euros} euros). It is an average: a few companies with a great deal of capital weigh heavily on it.

<LineChart
    data={soc_anual.filter(d => d.capital_real_hab != null)}
    x=anio
    y=capital_real_hab
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per inhabitant"
    title="Capital subscribed by new companies, {soc_anual.slice(-1)[0]?.anio_euros} euros per inhabitant"
/>

```sql soc_ccaa
SELECT
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    s.cod,
    s.constituidas_100k,
    s.disueltas_100k,
    s.saldo_100k,
    s.capital_real_hab,
    CAST(s.anio AS INTEGER) AS anio
FROM mother.empresas_sociedades_anual s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
WHERE s.anio = (SELECT max(anio) FROM mother.empresas_sociedades_anual)
ORDER BY s.constituidas_100k DESC
```

By region, in {soc_ccaa[0]?.anio}. Each company is counted in the region of its registered office.

<DataTable data={soc_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Region"/>
    <Column id=constituidas_100k title="Set up per 100,000 inhab." fmt='0'/>
    <Column id=disueltas_100k title="Dissolved per 100,000 inhab." fmt='0'/>
    <Column id=saldo_100k title="Net balance per 100,000 inhab." fmt='0' contentType=delta/>
    <Column id=capital_real_hab title="Subscribed capital (€ per inhab.)" fmt='#,##0'/>
</DataTable>

## Insolvency proceedings

```sql concursos
SELECT CAST(anio AS INTEGER) AS anio, concursos, concursos_100k, concursos_1000emp
FROM mother.empresas_concursos
WHERE cod = '00' AND anio >= 2005
ORDER BY anio
```

```sql concursos_hitos
SELECT
    max(concursos_1000emp) FILTER (WHERE anio = 2007) AS r2007,
    max(concursos_1000emp) AS r_max,
    arg_max(anio, concursos_1000emp) AS anio_max,
    max(concursos_1000emp) FILTER (WHERE anio = 2020) AS r2020,
    max(concursos_100k) FILTER (WHERE anio = 2020) AS h2020
FROM ${concursos}
```

Businesses and individuals entering insolvency proceedings (the former bankruptcy or suspension of payments), per 1,000 active businesses. The figure rose from {formatNumber(concursos_hitos[0]?.r2007, 2)} in 2007 to {formatNumber(concursos_hitos[0]?.r_max, 2)} in {concursos_hitos[0]?.anio_max}. In 2020 it stood at {formatNumber(concursos_hitos[0]?.r2020, 2)} per 1,000 businesses ({formatNumber(concursos_hitos[0]?.h2020, 1)} per 100,000 inhabitants). The INE has not published these statistics since 2020.

<BarChart
    data={concursos}
    x=anio
    y=concursos_1000emp
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="per 1,000 businesses"
    title="Debtors in insolvency proceedings per 1,000 active businesses (2005-2020)"
/>

```sql quiebras
SELECT fecha, periodo, pais, indice
FROM mother.empresas_altas_quiebras
WHERE indicador = 'Quiebras' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT')
ORDER BY fecha, pais
```

```sql quiebras_ult
SELECT
    max(periodo) AS periodo,
    max(indice) FILTER (WHERE geo = 'ES' AND fecha = (SELECT max(fecha) FROM mother.empresas_altas_quiebras)) AS es,
    max(indice) FILTER (WHERE geo = 'EU27_2020' AND fecha = (SELECT max(fecha) FROM mother.empresas_altas_quiebras)) AS ue
FROM mother.empresas_altas_quiebras
WHERE indicador = 'Quiebras'
```

For the recent trend, Eurostat's index of bankruptcy declarations is useful: it compares each country with itself (2021 = 100) and does not allow levels to be compared across countries. In {quiebras_ult[0]?.periodo}, Spain's index stood at {formatNumber(quiebras_ult[0]?.es, 0)} and the EU-27's at {formatNumber(quiebras_ult[0]?.ue, 0)}.

<LineChart
    data={quiebras}
    x=fecha
    y=indice
    series=pais
    yFmt='0'
    yAxisTitle="index 2021 = 100"
    title="Bankruptcy declarations (index 2021 = 100, seasonally adjusted)"
/>

## The self-employed

```sql autonomos_tipo
SELECT anio, 'Empleadores (con asalariados)' AS tipo, pct_empleadores AS pct FROM ${autonomos_anual}
UNION ALL
SELECT anio, 'Sin asalariados' AS tipo, pct_independientes AS pct FROM ${autonomos_anual}
UNION ALL
SELECT anio, 'Otros (cooperativistas, ayuda familiar)' AS tipo, pct_cuenta_propia - pct_empleadores - pct_independientes AS pct FROM ${autonomos_anual}
ORDER BY anio, tipo
```

```sql autonomos_hitos
SELECT
    max(pct_cuenta_propia) FILTER (WHERE anio = 2002) AS p2002,
    max(pct_cuenta_propia) FILTER (WHERE anio = (SELECT max(anio) FROM ${autonomos_anual})) AS p_ult,
    max(cuenta_propia) FILTER (WHERE anio = 2002) AS n2002,
    max(cuenta_propia) FILTER (WHERE anio = (SELECT max(anio) FROM ${autonomos_anual})) AS n_ult,
    max(anio) AS anio_ult
FROM ${autonomos_anual}
```

The Labour Force Survey (EPA) asks every employed person whether they work for themselves or for someone else. The number of self-employed workers has changed little ({formatNumber(autonomos_hitos[0]?.n2002 / 1000, 2)} million in 2002 and {formatNumber(autonomos_hitos[0]?.n_ult / 1000, 2)} million in {autonomos_hitos[0]?.anio_ult}), but because salaried employment has grown faster, their share has fallen from {formatNumber(autonomos_hitos[0]?.p2002, 1)}% to {formatNumber(autonomos_hitos[0]?.p_ult, 1)}% of the employed. These are people, not Social Security registrations: the number of people registered under the self-employed scheme is different.

<BarChart
    data={autonomos_tipo}
    x=anio
    y=pct
    series=tipo
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of the employed"
    colorPalette={['#1d4ed8', '#94a3b8', '#60a5fa']}
    title="Self-employed workers as % of the employed (annual average)"
/>

```sql autonomos_ccaa
SELECT
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    a.cod,
    a.pct_cuenta_propia,
    a.pct_empleadores,
    a.cuenta_propia,
    CAST(a.anio AS INTEGER) AS anio
FROM mother.empresas_autonomos_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.anio = (SELECT max(anio) FROM mother.empresas_autonomos_anual)
ORDER BY a.pct_cuenta_propia DESC
```

In {autonomos_ccaa[0]?.anio}, {autonomos_ccaa[0]?.comunidad} had the highest proportion of self-employed workers ({formatNumber(autonomos_ccaa[0]?.pct_cuenta_propia, 1)}% of the employed) and {autonomos_ccaa.slice(-1)[0]?.comunidad} the lowest ({formatNumber(autonomos_ccaa.slice(-1)[0]?.pct_cuenta_propia, 1)}%).

<BarChart
    data={autonomos_ccaa}
    x=comunidad
    y=pct_cuenta_propia
    swapXY=true
    yFmt='0.0"%"'
    title="Self-employed workers, % of the employed ({autonomos_ccaa[0]?.anio})"
/>

## Research and development (R&D)

```sql id_paises
SELECT pais, es_ue, pct_pib, investigadores_1000ocup, CAST(anio AS INTEGER) AS anio,
    CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND pais IS NOT NULL AND pct_pib IS NOT NULL
  AND (es_ue OR geo IN ('EU27_2020', 'NO', 'CH', 'US', 'JP', 'KR', 'CN_X_HK', 'UK'))
  AND anio = (SELECT max(anio) FROM mother.empresas_id_paises WHERE geo = 'ES' AND pct_pib IS NOT NULL)
ORDER BY pct_pib DESC
```

```sql id_rank
SELECT
    count(*) FILTER (WHERE pct_pib > (SELECT pct_pib FROM ${id_paises} WHERE pais = 'España')) + 1 AS puesto,
    count(*) AS paises
FROM ${id_paises}
WHERE es_ue
```

```sql id_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, pct_pib
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND pct_pib IS NOT NULL AND anio >= 2000
ORDER BY anio, pais
```

```sql id_hitos
SELECT
    max(pct_pib) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS p_max,
    arg_max(anio, pct_pib) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS anio_pmax,
    min(pct_pib) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS p_min,
    arg_min(anio, pct_pib) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS anio_min,
    max(eur_hab_real) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS h_max,
    arg_max(anio, eur_hab_real) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS anio_hmax,
    min(eur_hab_real) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS h_min,
    arg_min(anio, eur_hab_real) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS anio_hmin,
    max(eur_hab_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${id_es})) AS h_ult,
    max(investigadores_1000ocup) FILTER (WHERE anio = (SELECT max(anio) FROM ${id_es})) AS inv_ult,
    max(anio) AS anio_ult
FROM ${id_es}
```

R&D spending includes research carried out by businesses, government, universities and non-profit institutions, and is measured as a percentage of GDP. In {id_ue_ult[0]?.anio}, Spain spent {formatNumber(id_ue_ult[0]?.es, 2)}% of GDP, compared with {formatNumber(id_ue_ult[0]?.ue, 2)}% in the EU-27, ranking {id_rank[0]?.puesto} out of the {id_rank[0]?.paises} countries of the Union.

<BarChart
    data={id_paises}
    x=pais
    y=pct_pib
    series=grupo
    swapXY=true
    yFmt='0.00"%"'
    colorPalette={['#dc2626', '#94a3b8', '#1d4ed8']}
    title="R&D spending as % of GDP ({id_paises[0]?.anio})"
/>

Spending fell back during the crisis: from {formatNumber(id_hitos[0]?.p_max, 2)}% of GDP in {id_hitos[0]?.anio_pmax} to {formatNumber(id_hitos[0]?.p_min, 2)}% in {id_hitos[0]?.anio_min}. Adjusted for inflation, it fell from €{formatNumber(id_hitos[0]?.h_max, 0)} per inhabitant in {id_hitos[0]?.anio_hmax} to €{formatNumber(id_hitos[0]?.h_min, 0)} in {id_hitos[0]?.anio_hmin}, and in {id_hitos[0]?.anio_ult} it was €{formatNumber(id_hitos[0]?.h_ult, 0)} ({id_es.slice(-1)[0]?.anio_euros} euros).

<LineChart
    data={id_evol}
    x=anio
    y=pct_pib
    series=pais
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% of GDP"
    title="R&D spending as % of GDP: Spain and other countries"
/>

<LineChart
    data={id_es}
    x=anio
    y=eur_hab_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per inhabitant"
    title="R&D spending per inhabitant in Spain, {id_es.slice(-1)[0]?.anio_euros} euros"
/>

```sql id_sector
SELECT CAST(anio AS INTEGER) AS anio, sector, pct_pib
FROM mother.empresas_id_paises
WHERE geo = 'ES' AND sector <> 'Total' AND pct_pib IS NOT NULL
ORDER BY anio, sector
```

```sql id_sector_ue
SELECT
    max(pct_pib) FILTER (WHERE geo = 'ES' AND sector = 'Empresas') AS es_emp,
    max(pct_pib) FILTER (WHERE geo = 'EU27_2020' AND sector = 'Empresas') AS ue_emp,
    max(pct_pib) FILTER (WHERE geo = 'ES' AND sector IN ('Administraciones públicas')) AS es_aapp,
    max(pct_pib) FILTER (WHERE geo = 'EU27_2020' AND sector IN ('Administraciones públicas')) AS ue_aapp,
    max(pct_pib) FILTER (WHERE geo = 'ES' AND sector IN ('Universidades')) AS es_uni,
    max(pct_pib) FILTER (WHERE geo = 'EU27_2020' AND sector IN ('Universidades')) AS ue_uni,
    max(anio) AS anio
FROM mother.empresas_id_paises
WHERE anio = (SELECT max(anio) FROM ${id_es})
```

Who carries out the spending. In {id_sector_ue[0]?.anio}, businesses spent {formatNumber(id_sector_ue[0]?.es_emp, 2)}% of GDP on R&D in Spain and {formatNumber(id_sector_ue[0]?.ue_emp, 2)}% in the EU-27; government, {formatNumber(id_sector_ue[0]?.es_aapp, 2)}% compared with {formatNumber(id_sector_ue[0]?.ue_aapp, 2)}%; and universities, {formatNumber(id_sector_ue[0]?.es_uni, 2)}% compared with {formatNumber(id_sector_ue[0]?.ue_uni, 2)}%. The gap with Europe lies mainly in businesses.

<BarChart
    data={id_sector}
    x=anio
    y=pct_pib
    series=sector
    type=stacked
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% of GDP"
    colorPalette={['#0f766e', '#1d4ed8', '#cbd5e1', '#f59e0b']}
    title="R&D spending in Spain by performing sector, % of GDP"
/>

```sql inv_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, investigadores_1000ocup
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND investigadores_1000ocup IS NOT NULL AND anio >= 2005
ORDER BY anio, pais
```

Full-time equivalent researchers per 1,000 employed: {formatNumber(id_ue_ult[0]?.es_inv, 1)} in Spain and {formatNumber(id_ue_ult[0]?.ue_inv, 1)} in the EU-27 in {id_ue_ult[0]?.anio}.

<LineChart
    data={inv_evol}
    x=anio
    y=investigadores_1000ocup
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1,000 employed"
    title="Researchers (full-time equivalent) per 1,000 employed"
/>

```sql id_ccaa
SELECT
    t.nombre AS comunidad,
    '/en' || t.ruta AS ruta,
    i.cod,
    i.pct_pib,
    i.eur_hab_real,
    i.investigadores_1000ocup,
    e.pct_pib AS pct_pib_empresas,
    CAST(i.anio AS INTEGER) AS anio,
    CAST(i.anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_id_ccaa i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
LEFT JOIN mother.empresas_id_ccaa e ON e.cod = i.cod AND e.anio = i.anio AND e.sector = 'Empresas'
WHERE i.sector = 'Total'
  AND i.anio = (SELECT max(anio) FROM mother.empresas_id_ccaa WHERE cod <> '00' AND sector = 'Total' AND pct_pib IS NOT NULL)
ORDER BY i.pct_pib DESC
```

By region, in {id_ccaa[0]?.anio} (latest year with regional data). {id_ccaa[0]?.comunidad} devoted {formatNumber(id_ccaa[0]?.pct_pib, 2)}% of its GDP to R&D and {id_ccaa.slice(-1)[0]?.comunidad} {formatNumber(id_ccaa.slice(-1)[0]?.pct_pib, 2)}%.

<MapaEspana
    data={id_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pct_pib"
    valueFmt='0.00"%"'
    link="ruta"
    colorPalette={['#f0fdf4', '#4ade80', '#14532d']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Eurostat / INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_pib', title: 'R&D, % of GDP', fmt: '0.00"%"'},
        {id: 'eur_hab_real', title: '€ per inhabitant', fmt: '#,##0'}
    ]}
/>

<DataTable data={id_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Region"/>
    <Column id=pct_pib title="R&D (% of GDP)" fmt='0.00'/>
    <Column id=pct_pib_empresas title="Of which, businesses (% of GDP)" fmt='0.00'/>
    <Column id=eur_hab_real title="€ per inhabitant (real)" fmt='#,##0'/>
    <Column id=investigadores_1000ocup title="Researchers per 1,000 employed" fmt='0.0'/>
</DataTable>

Business output by sector is in [Sectors](/en/economia/sectores) and wages in [Wages](/en/economia/salarios).

---

**Sources:** INE, [Central Business Register (DIRCE)](https://www.ine.es/dyngs/INEbase/operacion.htm?c=Estadistica_C&cid=1254736160707&idp=1254735576550), tables [302](https://www.ine.es/jaxiT3/Tabla.htm?t=302) (businesses by province since 1999) and [39372](https://www.ine.es/jaxiT3/Tabla.htm?t=39372) (by region, activity and number of employees); [Trading Companies Statistics, table 13912](https://www.ine.es/jaxiT3/Tabla.htm?t=13912); [Insolvency Proceedings Statistics, table 2992](https://www.ine.es/jaxiT3/Tabla.htm?t=2992); [EPA (Labour Force Survey), employed persons by professional status, table 65316](https://www.ine.es/jaxiT3/Tabla.htm?t=65316). Eurostat: R&D expenditure [rd_e_gerdtot](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table) and [rd_e_gerdreg](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table), researchers [rd_p_perslf](https://ec.europa.eu/eurostat/databrowser/view/rd_p_perslf/default/table) and [rd_p_persreg](https://ec.europa.eu/eurostat/databrowser/view/rd_p_persreg/default/table) (compiled from the INE's Statistics on R&D Activities), enterprises by size [sbs_sc_ovw](https://ec.europa.eu/eurostat/databrowser/view/sbs_sc_ovw/default/table) and registrations and bankruptcies [sts_rb_q](https://ec.europa.eu/eurostat/databrowser/view/sts_rb_q/default/table). Population: INE municipal register (padrón). Constant euros using the INE's general CPI (base 2025).
