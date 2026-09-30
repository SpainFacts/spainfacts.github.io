---
title: Emissions i Descarbonització
description: "Emissions oficials de gasos d'efecte d'hivernacle (GEH) d'Espanya des del 1990, per habitant, per euro de PIB real i per sector, davant dels objectius del 2030 i de la mitjana europea."
i18n_origen: 8873f7164972
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

# 🏭 Emissions de Gasos d'Efecte d'Hivernacle a Espanya

Quants gasos d'efecte d'hivernacle emet Espanya des del 1990, any de referència dels compromisos climàtics, mesurats **per habitant** i **per euro de PIB real** perquè el creixement de la població i de l'economia no distorsioni la comparació. Són les xifres de l'inventari oficial que el MITECO reporta a les Nacions Unides i a la UE, sense comptar els embornals d'usos del sòl i boscos (LULUCF) llevat d'on s'indica.{#if kpi[0]?.provisional} La dada del {kpi[0]?.anio} és l'**avançament provisional** del MITECO; la xifra definitiva arribarà amb la pròxima edició de l'inventari.{/if}

<Grid cols=4>
    <KpiCard
        title="Emissions per habitant"
        value={kpi[0]?.t_hab}
        formattedValue="{formatNumber(kpi[0]?.t_hab, 2)} t CO₂eq"
        period="{kpi[0]?.anio}{kpi[0]?.provisional ? ' (avançament provisional)' : ''} · {formatNumber(kpi[0]?.total_mt, 1)} Mt en total"
        change={kpi[0]?.t_hab_var?.toFixed(1)}
        changePeriod="vs. any anterior"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => d.t_hab)}
    />
    <KpiCard
        title="Respecte al 1990"
        value={kpi[0]?.var_1990_pct}
        formattedValue="{kpi[0]?.var_1990_pct >= 0 ? '+' : ''}{formatNumber(kpi[0]?.var_1990_pct, 1)} %"
        period="emissions totals el {kpi[0]?.anio} · {formatNumber(kpi[0]?.var_2005_pct, 1)} % respecte al 2005"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => d.var_1990_pct)}
    />
    <KpiCard
        title="Intensitat de l'economia"
        value={intensidad.slice(-1)[0]?.kg_por_euro}
        formattedValue="{formatNumber(intensidad.slice(-1)[0]?.kg_por_euro * 1000, 0)} g CO₂eq/€"
        period="per euro de PIB real (euros constants) el {intensidad.slice(-1)[0]?.anio}"
        change={intensidad.slice(-1)[0]?.var_desde_inicio?.toFixed(0)}
        changePeriod="des del {intensidad[0]?.anio}"
        direction="positive-down"
        source="Eurostat"
        sparklineData={intensidad.map(d => d.kg_por_euro)}
    />
    <KpiCard
        title="Espanya davant la UE"
        value={ue_ratio.slice(-1)[0]?.pct_ue}
        formattedValue="{formatNumber(ue_ratio.slice(-1)[0]?.pct_ue, 0)} % de la mitjana"
        period="per habitant el {ue_ratio.slice(-1)[0]?.anio}: {formatNumber(ue_ratio.slice(-1)[0]?.t_hab, 1)} t davant de {formatNumber(ue_ratio.slice(-1)[0]?.t_hab_ue, 1)} t a la UE-27"
        direction="positive-down"
        source="Eurostat"
        sparklineData={ue_ratio.map(d => d.pct_ue)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('gei_pc')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gei_pc')} />


## Emissions per habitant des del 1990

Un espanyol emetia {formatNumber(hitos[0]?.t_hab_1990, 1)} t de CO₂ equivalent el 1990; el màxim va ser de {formatNumber(hitos[0]?.t_hab_max, 1)} t el {hitos[0]?.anio_t_hab_max} i el {kpi[0]?.anio} són {formatNumber(kpi[0]?.t_hab, 1)} t. La línia d'emissions netes descompta el CO₂ que absorbeixen els boscos i els sòls (LULUCF). La mitjana europea només arriba a l'últim any de l'inventari definitiu.

<LineChart
    data={hab_largo}
    x=anio
    y=t
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq per habitant"
    title="Emissions de GEH per habitant: Espanya i UE-27"
    colorPalette={['#dc2626', '#16a34a', '#2563eb']}
/>

<DownloadCsvButton data={anual} filename="spainfacts_emisiones_gei_anual.csv" label="Descarregar la sèrie anual (CSV)" />

## Lluny de l'objectiu del 2030

Les emissions totals van tocar sostre el {hitos[0]?.anio_max} ({formatNumber(hitos[0]?.mt_max, 0)} Mt) i el {kpi[0]?.anio} estan un {formatNumber(Math.abs(kpi[0]?.var_1990_pct), 1)} % {#if kpi[0]?.var_1990_pct < 0}per sota{:else}per sobre{/if} del 1990. El Pla Nacional Integrat d'Energia i Clima (PNIEC 2023-2030) fixa una reducció del 32 % respecte al 1990 per al 2030, uns {formatNumber(hitos[0]?.objetivo_pniec_mt, 0)} Mt: des del nivell del {kpi[0]?.anio} caldria retallar un {formatNumber(Math.abs(hitos[0]?.falta_pniec_pct), 0)} % més.

<LineChart
    data={indice_1990}
    x=anio
    y=indice
    xFmt='0'
    yFmt='0'
    yAxisTitle="1990 = 100"
    title="Emissions totals de GEH (índex 1990 = 100)"
    colorPalette={['#dc2626']}
>
    <ReferenceLine y=68 label="Objectiu PNIEC 2030 (-32 %)" color="#16a34a" />
    <ReferenceLine y=100 label="Nivell del 1990" color="#6b7280" />
</LineChart>

## Créixer emetent menys

Des del {intensidad[0]?.anio} el PIB real per habitant i les emissions per habitant han seguit camins diferents: cada euro de PIB real es produeix avui amb un {formatNumber(Math.abs(intensidad.slice(-1)[0]?.var_desde_inicio), 0)} % {#if intensidad.slice(-1)[0]?.var_desde_inicio < 0}menys{:else}més{/if} d'emissions que el {intensidad[0]?.anio}. El PIB es mesura en euros constants, descomptada la inflació.

<LineChart
    data={desacople}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="{intensidad[0]?.anio} = 100"
    title="PIB real i emissions per habitant (índex {intensidad[0]?.anio} = 100)"
    colorPalette={['#16a34a', '#dc2626', '#2563eb']}
/>

## Qui emet? Emissions per sector

Quilos de CO₂ equivalent per habitant i any segons el sector que els emet.

<AreaChart
    data={sectores}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq per habitant"
    title="Emissions de GEH per sector i habitant"
/>

<DataTable data={sectores_tabla} search=false rows=10>
    <Column id=sector title="Sector" />
    <Column id=kg_1990 title="kg/hab. 1990" fmt="#,##0" />
    <Column id=kg_2005 title="kg/hab. 2005" fmt="#,##0" />
    <Column id=kg_ult title="kg/hab. últim any" fmt="#,##0" />
    <Column id=peso_ult title="% del total" fmt="pct1" contentType=colorscale colorScale={['#fef3c7', '#dc2626']} />
    <Column id=var_1990 title="Total vs. 1990" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_ult title="Mt últim any" fmt="num1" />
</DataTable>

<DownloadCsvButton data={sectores} filename="spainfacts_emisiones_gei_sectorial.csv" label="Descarregar les emissions per sector (CSV)" />

## El transport, el sector que no baixa

El transport concentra el **{formatNumber(transporte[0]?.pct_transporte, 1)} %** de les emissions el {transporte[0]?.anio_ult} i emet un {formatNumber(Math.abs(transporte[0]?.var_transporte), 0)} % {#if transporte[0]?.var_transporte >= 0}més{:else}menys{/if} que el 1990. La generació elèctrica, en canvi, emet un {formatNumber(Math.abs(transporte[0]?.var_electrica), 0)} % {#if transporte[0]?.var_electrica < 0}menys{:else}més{/if} que el 1990 i un {formatNumber(Math.abs(transporte[0]?.var_electrica_2005), 0)} % {#if transporte[0]?.var_electrica_2005 < 0}menys{:else}més{/if} que el 2005. Més detall al [mix elèctric](/ca/energia-clima/mix-electrico).

<LineChart
    data={transporte_vs_electrica}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq per habitant"
    title="Transport davant de generació elèctrica (kg per habitant)"
    colorPalette={['#16a34a', '#f97316']}
/>

## Espanya a Europa

Emissions per habitant sense LULUCF, amb els inventaris definitius de cada país. El {paises_rank[0]?.anio}, {paises_rank[0]?.menos_que_es} dels sis grans països comparats emetien menys per habitant que Espanya. Des del 1990 les emissions totals d'Espanya han variat un {formatNumber(paises_rank[0]?.var_es, 1)} %, davant del {formatNumber(paises_rank[0]?.var_ue, 1)} % del conjunt de la UE-27.

<BarChart
    data={paises_ult}
    x=nombre
    y=t_hab
    series=grupo
    swapXY=true
    yFmt='0.0'
    yAxisTitle="t CO₂eq per habitant"
    title="Emissions per habitant el {paises_ult[0]?.anio}"
    colorPalette={['#dc2626', '#94a3b8', '#2563eb']}
/>

<LineChart
    data={paises}
    x=anio
    y=t_hab
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq per habitant"
    title="Evolució de les emissions per habitant"
/>

<DataTable data={paises_ult} search=false rows=10>
    <Column id=nombre title="País" />
    <Column id=t_hab title="t CO₂eq/hab." fmt="num1" />
    <Column id=var_1990 title="Emissions totals vs. 1990" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_co2eq title="Mt totals" fmt="num0" />
</DataTable>

## Objectius de reducció

| Horitzó | Objectiu | Referència |
|:---|:---|:---|
| **2030 (Espanya)** | -32 % d'emissions respecte al 1990 | PNIEC 2023-2030 |
| **2030 (Espanya, sectors difusos)** | -37,7 % respecte al 2005 en transport, edificis, agricultura, residus i gasos fluorats (fora del comerç de drets d'emissió) | Reglament de repartiment d'esforços, (UE) 2023/857 |
| **2030 (UE)** | -55 % d'emissions netes respecte al 1990 | Llei Europea del Clima, Reglament (UE) 2021/1119 |
| **2050** | Neutralitat climàtica (emissions netes nul·les) | Llei 7/2021 de canvi climàtic i Llei Europea del Clima |

---

## Fonts

- **Inventari Nacional d'Emissions de GEH (MITECO)**, reportat a la Convenció Marc de les Nacions Unides sobre el Canvi Climàtic, descarregat d'Eurostat [env_air_gge](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) per categoria CRF. Metodologia: directrius de l'IPCC del 2006. [MITECO – Inventari](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gases-efecto-invernadero.html).
- **Avançament de l'inventari** de l'últim any (provisional): [MITECO, nota d'avançament d'emissions de GEH del 2025](https://www.miteco.gob.es/content/dam/miteco/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/Nota-Avance-GEI-2025.pdf) (juliol del 2026). Se substitueix per la xifra definitiva quan Eurostat la publica.
- **Població mitjana anual**: Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table). **PIB real per habitant**: Eurostat [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), en euros constants (vegeu [PIB per habitant](/ca/economia)).
- Agrupació en sectors: Generació Elèctrica = 1A1a; Transport = 1A3 (nacional, sense búnquers internacionals); Indústria i Processos = 1A1b-c + 1A2 + 1B + 2 (llevat de 2F i 2G); Residencial i Comercial = 1A4a-b; Agricultura i Ramaderia = 3 + 1A4c; Residus = 5; Gasos Fluorats i Altres = 2F + 2G + 1A5 + 6.

<LastRefreshed prefix="Última sincronització de dades" />
