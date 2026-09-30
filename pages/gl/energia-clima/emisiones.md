---
i18n_origen: 8873f7164972
title: Emisións e descarbonización
description: "Emisións oficiais de gases de efecto invernadoiro (GEI) de España desde 1990, por habitante, por euro de PIB real e por sector, fronte aos obxectivos de 2030 e á media europea."
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

# 🏭 Emisións de gases de efecto invernadoiro en España

Cantos gases de efecto invernadoiro emite España desde 1990, ano de referencia dos compromisos climáticos, medidos **por habitante** e **por euro de PIB real** para que o crecemento da poboación e da economía non distorsione a comparación. Son as cifras do inventario oficial que o MITECO comunica ás Nacións Unidas e á UE, sen contar os sumidoiros de usos do solo e bosques (LULUCF) agás onde se indica.{#if kpi[0]?.provisional} O dato de {kpi[0]?.anio} é o **avance provisional** do MITECO; a cifra definitiva chegará coa seguinte edición do inventario.{/if}

<Grid cols=4>
    <KpiCard
        title="Emisións por habitante"
        value={kpi[0]?.t_hab}
        formattedValue="{formatNumber(kpi[0]?.t_hab, 2)} t CO₂eq"
        period="{kpi[0]?.anio}{kpi[0]?.provisional ? ' (avance provisional)' : ''} · {formatNumber(kpi[0]?.total_mt, 1)} Mt en total"
        change={kpi[0]?.t_hab_var?.toFixed(1)}
        changePeriod="vs. ano anterior"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => d.t_hab)}
    />
    <KpiCard
        title="Fronte a 1990"
        value={kpi[0]?.var_1990_pct}
        formattedValue="{kpi[0]?.var_1990_pct >= 0 ? '+' : ''}{formatNumber(kpi[0]?.var_1990_pct, 1)} %"
        period="emisións totais en {kpi[0]?.anio} · {formatNumber(kpi[0]?.var_2005_pct, 1)} % fronte a 2005"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => d.var_1990_pct)}
    />
    <KpiCard
        title="Intensidade da economía"
        value={intensidad.slice(-1)[0]?.kg_por_euro}
        formattedValue="{formatNumber(intensidad.slice(-1)[0]?.kg_por_euro * 1000, 0)} g CO₂eq/€"
        period="por euro de PIB real (euros constantes) en {intensidad.slice(-1)[0]?.anio}"
        change={intensidad.slice(-1)[0]?.var_desde_inicio?.toFixed(0)}
        changePeriod="desde {intensidad[0]?.anio}"
        direction="positive-down"
        source="Eurostat"
        sparklineData={intensidad.map(d => d.kg_por_euro)}
    />
    <KpiCard
        title="España fronte á UE"
        value={ue_ratio.slice(-1)[0]?.pct_ue}
        formattedValue="{formatNumber(ue_ratio.slice(-1)[0]?.pct_ue, 0)} % da media"
        period="por habitante en {ue_ratio.slice(-1)[0]?.anio}: {formatNumber(ue_ratio.slice(-1)[0]?.t_hab, 1)} t fronte a {formatNumber(ue_ratio.slice(-1)[0]?.t_hab_ue, 1)} t na UE-27"
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


## Emisións por habitante desde 1990

Un español emitía {formatNumber(hitos[0]?.t_hab_1990, 1)} t de CO₂ equivalente en 1990; o máximo foi de {formatNumber(hitos[0]?.t_hab_max, 1)} t en {hitos[0]?.anio_t_hab_max} e en {kpi[0]?.anio} son {formatNumber(kpi[0]?.t_hab, 1)} t. A liña de emisións netas desconta o CO₂ que absorben bosques e solos (LULUCF). A media europea só chega ao último ano do inventario definitivo.

<LineChart
    data={hab_largo}
    x=anio
    y=t
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq por habitante"
    title="Emisións de GEI por habitante: España e UE-27"
    colorPalette={['#dc2626', '#16a34a', '#2563eb']}
/>

<DownloadCsvButton data={anual} filename="spainfacts_emisiones_gei_anual.csv" label="Descargar serie anual (CSV)" />

## Lonxe do obxectivo de 2030

As emisións totais tocaron teito en {hitos[0]?.anio_max} ({formatNumber(hitos[0]?.mt_max, 0)} Mt) e en {kpi[0]?.anio} están un {formatNumber(Math.abs(kpi[0]?.var_1990_pct), 1)} % {#if kpi[0]?.var_1990_pct < 0}por debaixo{:else}por riba{/if} de 1990. O Plan Nacional Integrado de Enerxía e Clima (PNIEC 2023-2030) fixa unha redución do 32 % respecto a 1990 para 2030, uns {formatNumber(hitos[0]?.objetivo_pniec_mt, 0)} Mt: desde o nivel de {kpi[0]?.anio} faltaría recortar un {formatNumber(Math.abs(hitos[0]?.falta_pniec_pct), 0)} % máis.

<LineChart
    data={indice_1990}
    x=anio
    y=indice
    xFmt='0'
    yFmt='0'
    yAxisTitle="1990 = 100"
    title="Emisións totais de GEI (índice 1990 = 100)"
    colorPalette={['#dc2626']}
>
    <ReferenceLine y=68 label="Obxectivo PNIEC 2030 (-32 %)" color="#16a34a" />
    <ReferenceLine y=100 label="Nivel de 1990" color="#6b7280" />
</LineChart>

## Medrar emitindo menos

Desde {intensidad[0]?.anio} o PIB real por habitante e as emisións por habitante seguiron camiños distintos: cada euro de PIB real prodúcese hoxe cun {formatNumber(Math.abs(intensidad.slice(-1)[0]?.var_desde_inicio), 0)} % {#if intensidad.slice(-1)[0]?.var_desde_inicio < 0}menos{:else}máis{/if} de emisións ca en {intensidad[0]?.anio}. O PIB mídese en euros constantes, descontada a inflación.

<LineChart
    data={desacople}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="{intensidad[0]?.anio} = 100"
    title="PIB real e emisións por habitante (índice {intensidad[0]?.anio} = 100)"
    colorPalette={['#16a34a', '#dc2626', '#2563eb']}
/>

## Quen emite? Emisións por sector

Quilos de CO₂ equivalente por habitante e ano segundo o sector que os emite.

<AreaChart
    data={sectores}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq por habitante"
    title="Emisións de GEI por sector e habitante"
/>

<DataTable data={sectores_tabla} search=false rows=10>
    <Column id=sector title="Sector" />
    <Column id=kg_1990 title="kg/hab 1990" fmt="#,##0" />
    <Column id=kg_2005 title="kg/hab 2005" fmt="#,##0" />
    <Column id=kg_ult title="kg/hab último ano" fmt="#,##0" />
    <Column id=peso_ult title="% do total" fmt="pct1" contentType=colorscale colorScale={['#fef3c7', '#dc2626']} />
    <Column id=var_1990 title="Total vs. 1990" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_ult title="Mt último ano" fmt="num1" />
</DataTable>

<DownloadCsvButton data={sectores} filename="spainfacts_emisiones_gei_sectorial.csv" label="Descargar emisións por sector (CSV)" />

## O transporte, o sector que non baixa

O transporte concentra o **{formatNumber(transporte[0]?.pct_transporte, 1)} %** das emisións en {transporte[0]?.anio_ult} e emite un {formatNumber(Math.abs(transporte[0]?.var_transporte), 0)} % {#if transporte[0]?.var_transporte >= 0}máis{:else}menos{/if} ca en 1990. A xeración eléctrica, en cambio, emite un {formatNumber(Math.abs(transporte[0]?.var_electrica), 0)} % {#if transporte[0]?.var_electrica < 0}menos{:else}máis{/if} ca en 1990 e un {formatNumber(Math.abs(transporte[0]?.var_electrica_2005), 0)} % {#if transporte[0]?.var_electrica_2005 < 0}menos{:else}máis{/if} ca en 2005. Máis detalle no [mix eléctrico](/gl/energia-clima/mix-electrico).

<LineChart
    data={transporte_vs_electrica}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq por habitante"
    title="Transporte fronte a xeración eléctrica (kg por habitante)"
    colorPalette={['#16a34a', '#f97316']}
/>

## España en Europa

Emisións por habitante sen LULUCF, cos inventarios definitivos de cada país. En {paises_rank[0]?.anio}, {paises_rank[0]?.menos_que_es} dos seis grandes países comparados emitían menos por habitante ca España. Desde 1990 as emisións totais de España variaron un {formatNumber(paises_rank[0]?.var_es, 1)} %, fronte ao {formatNumber(paises_rank[0]?.var_ue, 1)} % do conxunto da UE-27.

<BarChart
    data={paises_ult}
    x=nombre
    y=t_hab
    series=grupo
    swapXY=true
    yFmt='0.0'
    yAxisTitle="t CO₂eq por habitante"
    title="Emisións por habitante en {paises_ult[0]?.anio}"
    colorPalette={['#dc2626', '#94a3b8', '#2563eb']}
/>

<LineChart
    data={paises}
    x=anio
    y=t_hab
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq por habitante"
    title="Evolución das emisións por habitante"
/>

<DataTable data={paises_ult} search=false rows=10>
    <Column id=nombre title="País" />
    <Column id=t_hab title="t CO₂eq/hab" fmt="num1" />
    <Column id=var_1990 title="Emisións totais vs. 1990" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_co2eq title="Mt totais" fmt="num0" />
</DataTable>

## Obxectivos de redución

| Horizonte | Obxectivo | Referencia |
|:---|:---|:---|
| **2030 (España)** | -32 % de emisións respecto a 1990 | PNIEC 2023-2030 |
| **2030 (España, sectores difusos)** | -37,7 % respecto a 2005 en transporte, edificios, agricultura, residuos e gases fluorados (fóra do comercio de dereitos de emisión) | Regulamento de repartición de esforzos, (UE) 2023/857 |
| **2030 (UE)** | -55 % de emisións netas respecto a 1990 | Lei Europea do Clima, Regulamento (UE) 2021/1119 |
| **2050** | Neutralidade climática (emisións netas nulas) | Lei 7/2021 de cambio climático e Lei Europea do Clima |

---

## Fontes

- **Inventario Nacional de Emisións de GEI (MITECO)**, comunicado á Convención Marco das Nacións Unidas sobre o Cambio Climático, descargado de Eurostat [env_air_gge](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) por categoría CRF. Metodoloxía: directrices do IPCC de 2006. [MITECO – Inventario](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gases-efecto-invernadero.html).
- **Avance do inventario** do último ano (provisional): [MITECO, nota de avance de emisións de GEI de 2025](https://www.miteco.gob.es/content/dam/miteco/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/Nota-Avance-GEI-2025.pdf) (xullo de 2026). Substitúese pola cifra definitiva cando Eurostat a publica.
- **Poboación media anual**: Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table). **PIB real por habitante**: Eurostat [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), en euros constantes (ver [PIB por habitante](/gl/economia)).
- Agrupación en sectores: Xeración eléctrica = 1A1a; Transporte = 1A3 (nacional, sen búnkers internacionais); Industria e procesos = 1A1b-c + 1A2 + 1B + 2 (agás 2F e 2G); Residencial e comercial = 1A4a-b; Agricultura e gandaría = 3 + 1A4c; Residuos = 5; Gases fluorados e outros = 2F + 2G + 1A5 + 6.

<LastRefreshed prefix="Última sincronización de datos" />
