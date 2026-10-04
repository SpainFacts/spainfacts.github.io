---
title: The media business
description: "How much the media are read, watched and listened to in Spain, what they live on (advertising spend by medium) and how many people work in them, per inhabitant and adjusted for inflation, compared with the EU and with the public money they receive."
i18n_origen: e0531df8ebcc
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql papel
SELECT CAST(anio AS INTEGER) AS anio, penetracion_pct, personas_miles, por_1000_hab
FROM mother.medios_sector_audiencia
WHERE medio = 'diarios_papel'
ORDER BY anio
```

```sql papel_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${papel} ORDER BY anio DESC LIMIT 1) AS anio,
    (SELECT por_1000_hab FROM ${papel} ORDER BY anio DESC LIMIT 1) AS por_1000,
    (SELECT personas_miles FROM ${papel} ORDER BY anio DESC LIMIT 1) AS miles,
    (SELECT penetracion_pct FROM ${papel} ORDER BY anio DESC LIMIT 1) AS pct,
    (SELECT CAST(anio AS INTEGER) FROM ${papel} WHERE por_1000_hab IS NOT NULL ORDER BY por_1000_hab DESC LIMIT 1) AS anio_max,
    (SELECT por_1000_hab FROM ${papel} WHERE por_1000_hab IS NOT NULL ORDER BY por_1000_hab DESC LIMIT 1) AS por_1000_max,
    (SELECT penetracion_pct FROM ${papel} ORDER BY penetracion_pct DESC LIMIT 1) AS pct_max,
    (SELECT CAST(anio AS INTEGER) FROM ${papel} ORDER BY penetracion_pct DESC LIMIT 1) AS anio_pct_max
```

```sql audiencia
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, penetracion_pct
FROM mother.medios_sector_audiencia
WHERE medio IN ('diarios_papel', 'diarios_internet', 'revistas_papel', 'radio', 'television')
  AND anio >= 2000
ORDER BY anio, medio
```

```sql audiencia_ult
SELECT
    max(penetracion_pct) FILTER (WHERE medio = 'diarios_internet') AS internet,
    max(penetracion_pct) FILTER (WHERE medio = 'diarios_papel') AS papel,
    max(penetracion_pct) FILTER (WHERE medio = 'diarios') AS diarios_total,
    max(penetracion_pct) FILTER (WHERE medio = 'radio') AS radio,
    max(penetracion_pct) FILTER (WHERE medio = 'television') AS tv,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.medios_sector_audiencia
WHERE anio = (SELECT max(anio) FROM mother.medios_sector_audiencia)
```

```sql minutos
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, minutos_dia
FROM mother.medios_sector_audiencia
WHERE medio IN ('radio', 'television') AND minutos_dia IS NOT NULL
ORDER BY anio, medio
```

```sql minutos_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${minutos} WHERE medio = 'Televisión' ORDER BY minutos_dia DESC LIMIT 1) AS anio_max_tv,
    (SELECT minutos_dia FROM ${minutos} WHERE medio = 'Televisión' ORDER BY minutos_dia DESC LIMIT 1) AS max_tv,
    (SELECT minutos_dia FROM ${minutos} WHERE medio = 'Televisión' ORDER BY anio DESC LIMIT 1) AS ult_tv,
    (SELECT minutos_dia FROM ${minutos} WHERE medio = 'Radio' ORDER BY anio DESC LIMIT 1) AS ult_radio
```

```sql cabeceras
SELECT u.puesto, u.cabecera, u.penetracion_pct, u.lectores_miles, u.por_1000_hab,
       i.lectores_miles AS lectores_miles_ini, u.variacion_desde_inicio_pct,
       CAST(u.anio AS INTEGER) AS anio
FROM mother.medios_sector_cabeceras u
JOIN mother.medios_sector_cabeceras i ON i.cabecera = u.cabecera AND i.anio = (SELECT min(anio) FROM mother.medios_sector_cabeceras)
WHERE u.anio = (SELECT max(anio) FROM mother.medios_sector_cabeceras)
ORDER BY u.penetracion_pct DESC, u.cabecera
```

```sql cabeceras_serie
SELECT CAST(anio AS INTEGER) AS anio, cabecera, por_1000_hab
FROM mother.medios_sector_cabeceras
WHERE cabecera IN ('Marca', 'El País', 'El Mundo', 'As', 'La Vanguardia', 'ABC', 'La Voz de Galicia')
ORDER BY anio, cabecera
```

```sql pub_mercado
SELECT anio, metodologia, inversion_meur_nominal, eur_hab_real, anio_base
FROM mother.medios_sector_publicidad
WHERE medio = 'subtotal_controlados'
QUALIFY row_number() OVER (PARTITION BY anio ORDER BY CASE WHEN metodologia = 'controlados' THEN 1 ELSE 2 END) = 1
ORDER BY anio
```

```sql pub_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS anio,
    (SELECT eur_hab_real FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS eur_hab,
    (SELECT inversion_meur_nominal FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS meur,
    (SELECT CAST(anio AS INTEGER) FROM ${pub_mercado} ORDER BY eur_hab_real DESC LIMIT 1) AS anio_max,
    (SELECT eur_hab_real FROM ${pub_mercado} ORDER BY eur_hab_real DESC LIMIT 1) AS eur_hab_max,
    (SELECT anio_base FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS anio_base
```

```sql pub_larga
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, eur_hab_real
FROM mother.medios_sector_publicidad
WHERE metodologia = 'convencionales' AND es_desglose
ORDER BY anio, medio
```

```sql pub_prensa
SELECT
    max(eur_hab_real) FILTER (WHERE medio = 'diarios' AND anio = 2007) AS diarios_2007,
    max(eur_hab_real) FILTER (WHERE medio = 'diarios' AND anio = 2023) AS diarios_2023,
    max(pct_controlados) FILTER (WHERE medio = 'diarios' AND anio = 2007) AS pct_2007,
    max(pct_controlados) FILTER (WHERE medio = 'diarios' AND anio = 2023) AS pct_2023,
    max(eur_hab_real) FILTER (WHERE medio = 'television' AND anio = 2007) AS tv_2007,
    max(eur_hab_real) FILTER (WHERE medio = 'television' AND anio = 2023) AS tv_2023,
    max(eur_hab_real) FILTER (WHERE medio = 'internet' AND anio = 2023) AS internet_2023
FROM mother.medios_sector_publicidad
WHERE metodologia = 'convencionales'
```

```sql pub_nueva
SELECT medio_nombre AS medio, eur_hab_real, inversion_meur_nominal, pct_controlados, CAST(anio AS INTEGER) AS anio
FROM mother.medios_sector_publicidad
WHERE metodologia = 'controlados' AND es_desglose
  AND anio = (SELECT max(anio) FROM mother.medios_sector_publicidad WHERE metodologia = 'controlados')
ORDER BY eur_hab_real DESC
```

```sql pub_papel_web
SELECT
    max(inversion_meur_nominal) FILTER (WHERE medio = 'diarios_dominicales_papel') AS papel,
    max(inversion_meur_nominal) FILTER (WHERE medio = 'diarios_dominicales_digital') AS web,
    max(pct_controlados) FILTER (WHERE medio IN ('redes_sociales')) AS pct_redes,
    max(pct_controlados) FILTER (WHERE medio IN ('search')) AS pct_search,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.medios_sector_publicidad
WHERE metodologia = 'controlados' AND anio = (SELECT max(anio) FROM mother.medios_sector_publicidad WHERE metodologia = 'controlados')
```

```sql empleo
SELECT CAST(anio AS INTEGER) AS anio, rama_nombre AS rama, ocupados_100k_hab, ocupados, serie
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama IN ('J5813', 'J5814', 'J601', 'J602', 'J6391') AND ocupados IS NOT NULL
ORDER BY anio, rama
```

```sql empleo_largo
SELECT CAST(anio AS INTEGER) AS anio, rama_nombre AS rama, ocupados_100k_hab, cifra_negocios_eur_hab_real
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama IN ('J60', 'J58') AND ocupados IS NOT NULL
ORDER BY anio, rama
```

```sql empleo_ult
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    max(ocupados) FILTER (WHERE rama = 'J5813') AS periodicos,
    max(ocupados_100k_hab) FILTER (WHERE rama = 'J5813') AS periodicos_100k,
    max(empresas) FILTER (WHERE rama = 'J5813') AS periodicos_empresas,
    max(cifra_negocios_eur_hab_real) FILTER (WHERE rama = 'J5813') AS periodicos_eur_hab,
    max(ocupados) FILTER (WHERE rama = 'J601') AS radio,
    max(ocupados) FILTER (WHERE rama = 'J602') AS tv,
    max(ocupados) FILTER (WHERE rama = 'J6391') AS agencias,
    max(cifra_negocios_eur_hab_real) FILTER (WHERE rama = 'J602') AS tv_eur_hab
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND anio = (SELECT max(anio) FROM mother.medios_sector_empresas WHERE pais = 'ES' AND rama = 'J5813' AND ocupados IS NOT NULL)
```

```sql empleo_spark
SELECT CAST(anio AS INTEGER) AS anio, ocupados_100k_hab
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama = 'J5813' AND ocupados IS NOT NULL
ORDER BY anio
```

```sql j60_extremos
SELECT
    max(ocupados_100k_hab) FILTER (WHERE anio = 2008) AS tv_radio_2008,
    max(ocupados_100k_hab) FILTER (WHERE anio = (SELECT max(anio) FROM mother.medios_sector_empresas WHERE pais = 'ES' AND rama = 'J60' AND ocupados IS NOT NULL)) AS tv_radio_ult
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama = 'J60'
```

```sql ue
SELECT CASE pais WHEN 'EU27_2020' THEN 'UE-27' WHEN 'ES' THEN 'España' WHEN 'DE' THEN 'Alemania' WHEN 'FR' THEN 'Francia'
            WHEN 'IT' THEN 'Italia' WHEN 'NL' THEN 'Países Bajos' WHEN 'PT' THEN 'Portugal' WHEN 'PL' THEN 'Polonia'
            WHEN 'SE' THEN 'Suecia' WHEN 'BE' THEN 'Bélgica' WHEN 'AT' THEN 'Austria' WHEN 'DK' THEN 'Dinamarca'
            WHEN 'FI' THEN 'Finlandia' WHEN 'IE' THEN 'Irlanda' WHEN 'EL' THEN 'Grecia' WHEN 'CZ' THEN 'Chequia'
            WHEN 'RO' THEN 'Rumanía' WHEN 'HU' THEN 'Hungría' ELSE pais END AS pais_nombre,
       pais, CAST(anio AS INTEGER) AS anio,
       max(ocupados_100k_hab) FILTER (WHERE rama = 'J5813') AS periodicos_100k,
       max(ocupados_100k_hab) FILTER (WHERE rama = 'J60') AS radio_tv_100k,
       max(cifra_negocios_eur_hab) FILTER (WHERE rama = 'J5813') AS periodicos_eur_hab,
       max(cifra_negocios_eur_hab) FILTER (WHERE rama = 'J60') AS radio_tv_eur_hab,
       CASE WHEN pais = 'ES' THEN 'España' WHEN pais = 'EU27_2020' THEN 'UE-27' ELSE 'Otros países' END AS grupo
FROM mother.medios_sector_empresas
WHERE serie = 'desde_2021' AND pais NOT IN ('EU28', 'LU', 'MT', 'CY')
  AND anio = (SELECT max(anio) FROM mother.medios_sector_empresas WHERE pais = 'ES' AND rama = 'J5813' AND ocupados IS NOT NULL)
GROUP BY ALL
HAVING max(ocupados_100k_hab) FILTER (WHERE rama = 'J5813') IS NOT NULL
ORDER BY periodicos_100k DESC
```

```sql ue_es
SELECT
    (SELECT periodicos_100k FROM ${ue} WHERE pais = 'ES') AS es,
    (SELECT periodicos_100k FROM ${ue} WHERE pais = 'EU27_2020') AS ue,
    (SELECT count(*) FROM ${ue} WHERE pais NOT IN ('EU27_2020')) AS n,
    (SELECT count(*) FROM ${ue} WHERE pais NOT IN ('EU27_2020') AND periodicos_100k > (SELECT periodicos_100k FROM ${ue} WHERE pais = 'ES')) + 1 AS puesto,
    (SELECT radio_tv_100k FROM ${ue} WHERE pais = 'ES') AS es_tv,
    (SELECT radio_tv_100k FROM ${ue} WHERE pais = 'EU27_2020') AS ue_tv
```

```sql grupos
SELECT CAST(anio AS INTEGER) AS anio, grupo, ingresos_meur_real, resultado_neto_meur_real, ingresos_eur_hab_real,
       ingresos_meur_nominal, resultado_neto_meur_nominal, margen_neto_pct
FROM mother.medios_sector_grupos
ORDER BY anio
```

```sql grupos_resumen
SELECT
    (SELECT ingresos_meur_real FROM ${grupos} WHERE anio = 2007) AS ing_2007,
    (SELECT ingresos_meur_real FROM ${grupos} ORDER BY anio DESC LIMIT 1) AS ing_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${grupos} ORDER BY anio DESC LIMIT 1) AS anio_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${grupos} ORDER BY ingresos_meur_real ASC LIMIT 1) AS anio_min,
    (SELECT ingresos_meur_real FROM ${grupos} ORDER BY ingresos_meur_real ASC LIMIT 1) AS ing_min
```

```sql grupos_series
SELECT anio, 'Ingresos' AS concepto, ingresos_meur_real AS meur_real FROM ${grupos}
UNION ALL
SELECT anio, 'Beneficio neto' AS concepto, resultado_neto_meur_real AS meur_real FROM ${grupos}
ORDER BY anio, concepto
```

```sql publico
SELECT CAST(anio AS INTEGER) AS anio, controlados_eur_hab_real, publicidad_estado_eur_hab_real, tv_publica_eur_hab_real,
       subvenciones_eur_hab_real, contratos_eur_hab_real, publicidad_estado_pct_mercado, tv_publica_pct_mercado,
       tv_publica_pct_publicidad_tv, controlados_meur, publicidad_estado_meur, tv_publica_meur
FROM mother.medios_sector_dinero_publico
WHERE publicidad_estado_meur IS NOT NULL
ORDER BY anio
```

```sql publico_series
SELECT anio, 'Publicidad del Estado y sus empresas' AS concepto, publicidad_estado_pct_mercado AS pct FROM ${publico}
UNION ALL
SELECT anio, 'RTVE y radiotelevisiones autonómicas' AS concepto, tv_publica_pct_mercado AS pct FROM ${publico} WHERE tv_publica_pct_mercado IS NOT NULL
ORDER BY anio, concepto
```

```sql publico_ult
SELECT * FROM ${publico} WHERE tv_publica_eur_hab_real IS NOT NULL ORDER BY anio DESC LIMIT 1
```

```sql publico_ult_age
SELECT * FROM ${publico} ORDER BY anio DESC LIMIT 1
```

# <span aria-hidden="true">📈</span> The media business

How much the media are read, watched and listened to in Spain, what they live on and how many people work in them. Audiences come from the Estudio General de Medios, advertising from the InfoAdex study, and employment and turnover from the business statistics of INE and Eurostat. All figures are **per inhabitant and adjusted for inflation**, in {pub_resumen[0]?.anio_base} euros. What public administrations pay the media is covered in [Public money in the media](/en/medios/dinero-publico).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if papel_resumen.length && pub_resumen.length && empleo_ult.length && publico_ult_age.length}
    <KpiCard
        title="Print newspaper readers"
        value={papel_resumen[0].por_1000}
        formattedValue={formatNumber(papel_resumen[0].por_1000, 0)}
        unit="per 1,000 inhabitants"
        period={`${papel_resumen[0].anio} · ${formatNumber(papel_resumen[0].miles / 1000, 1)} million readers a day`}
        source="AIMC (EGM)"
        direction="positive-up"
        sparklineData={papel.filter(d => d.por_1000_hab !== null).map(d => d.por_1000_hab)}
    />
    <KpiCard
        title="Advertising spend in the media"
        value={pub_resumen[0].eur_hab}
        formattedValue={formatNumber(pub_resumen[0].eur_hab, 0) + ' €'}
        unit="per inhabitant"
        period={`${pub_resumen[0].anio} · ${formatCompact(pub_resumen[0].meur * 1e6, 2)} € on television, press, radio, digital, outdoor and cinema`}
        source="InfoAdex"
        direction="positive-up"
        sparklineData={pub_mercado.map(d => d.eur_hab_real)}
    />
    <KpiCard
        title="Employment in newspaper publishing"
        value={empleo_ult[0].periodicos_100k}
        formattedValue={formatNumber(empleo_ult[0].periodicos_100k, 1)}
        unit="persons employed per 100,000 inhabitants"
        period={`${empleo_ult[0].anio} · ${formatNumber(empleo_ult[0].periodicos, 0)} people in ${formatNumber(empleo_ult[0].periodicos_empresas, 0)} companies`}
        source="INE and Eurostat (SBS)"
        direction="positive-up"
        sparklineData={empleo_spark.map(d => d.ocupados_100k_hab)}
    />
    <KpiCard
        title="Central government advertising vs the market"
        value={publico_ult_age[0].publicidad_estado_pct_mercado}
        formattedValue={formatNumber(publico_ult_age[0].publicidad_estado_pct_mercado, 1) + ' %'}
        unit="of media advertising spend"
        period={`${publico_ult_age[0].anio} · ${formatCompact(publico_ult_age[0].publicidad_estado_meur * 1e6, 2)} € on campaigns by the State and its companies`}
        source="Moncloa and InfoAdex"
        direction="positive-down"
        sparklineData={publico.map(d => d.publicidad_estado_pct_mercado)}
    />
    {/if}
</div>

## How much is read, watched and listened to

In {papel_resumen[0]?.anio}, {formatNumber(papel_resumen[0]?.por_1000, 0)} in every 1,000 inhabitants read a print newspaper each day, {formatNumber(papel_resumen[0]?.pct, 1)} % of those aged over 14. The series peaked in {papel_resumen[0]?.anio_pct_max}, at {formatNumber(papel_resumen[0]?.pct_max, 1)} %. Until 2017 the EGM counts print only; from 2018 it adds those who read the newspaper's digital replica (PDF or viewer).

<LineChart
    data={papel}
    x=anio
    y=por_1000_hab
    xFmt='0'
    yFmt='0'
    yAxisTitle="Readers per 1,000 inhabitants"
    title="Daily readers of print newspapers, per 1,000 inhabitants"
/>

Reading has not disappeared: it has moved online. In {audiencia_ult[0]?.anio}, {formatNumber(audiencia_ult[0]?.internet, 1)} % of those aged over 14 visited a newspaper's website every day, compared with {formatNumber(audiencia_ult[0]?.papel, 1)} % who read one in print; adding both, {formatNumber(audiencia_ult[0]?.diarios_total, 1)} %. Television reaches {formatNumber(audiencia_ult[0]?.tv, 1)} % of the population every day and radio {formatNumber(audiencia_ult[0]?.radio, 1)} %.

<LineChart
    data={audiencia}
    x=anio
    y=penetracion_pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% of the population aged 14 or over"
    seriesColors={{'Diarios en papel': '#2563eb', 'Diarios en internet': '#93c5fd', 'Revistas en papel': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Daily audience of each medium (magazines: over their publication period), % of the population aged 14 or over"
/>

Each person aged 14 or over watches an average of {minutos_resumen[0]?.ult_tv} minutes of television a day and listens to {minutos_resumen[0]?.ult_radio} minutes of radio. Television peaked in {minutos_resumen[0]?.anio_max_tv}, at {minutos_resumen[0]?.max_tv} minutes.

<LineChart
    data={minutos}
    x=anio
    y=minutos_dia
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="Minutes per person per day"
    seriesColors={{'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Daily minutes of radio and television per person"
/>

### The most-read print newspapers

Daily readers of each newspaper in print and digital replica in {cabeceras[0]?.anio}, compared with 2009. It does not include those who read the newspaper on its website.

<LineChart
    data={cabeceras_serie}
    x=anio
    y=por_1000_hab
    series=cabecera
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Readers per 1,000 inhabitants"
    title="Daily readers of the main print newspapers, per 1,000 inhabitants"
/>

<DataTable data={cabeceras} rows=15 search=true>
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=cabecera title="Newspaper" />
    <Column id=por_1000_hab title="Readers per 1,000 inhab." fmt='0.0' />
    <Column id=lectores_miles title="Readers (thousands)" fmt='#,##0' />
    <Column id=lectores_miles_ini title="Readers in 2009 (thousands)" fmt='#,##0' />
    <Column id=variacion_desde_inicio_pct title="Change since 2009 %" fmt='0' contentType=delta />
</DataTable>

## What they live on: advertising

In {pub_resumen[0]?.anio} advertisers spent {formatNumber(pub_resumen[0]?.eur_hab, 0)} € per inhabitant in conventional media (television, press, magazines, radio, internet, outdoor and cinema), adjusted for inflation. The peak was in {pub_resumen[0]?.anio_max}, at {formatNumber(pub_resumen[0]?.eur_hab_max, 0)} €. Print daily newspapers have gone from {formatNumber(pub_prensa[0]?.diarios_2007, 1)} € per inhabitant in 2007 ({formatNumber(pub_prensa[0]?.pct_2007, 0)} % of spend) to {formatNumber(pub_prensa[0]?.diarios_2023, 1)} € in 2023 ({formatNumber(pub_prensa[0]?.pct_2023, 0)} %), and television from {formatNumber(pub_prensa[0]?.tv_2007, 0)} € to {formatNumber(pub_prensa[0]?.tv_2023, 0)} €, while internet reached {formatNumber(pub_prensa[0]?.internet_2023, 0)} €.

<BarChart
    data={pub_larga}
    x=anio
    y=eur_hab_real
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ per inhabitant (adjusted for inflation)"
    seriesColors={{'Televisión': '#ef4444', 'Diarios (papel)': '#2563eb', 'Internet': '#22c55e', 'Radio': '#f59e0b', 'Revistas': '#a855f7', 'Exterior': '#64748b', 'Dominicales': '#93c5fd', 'Cine': '#0f172a'}}
    title="Advertising spend in conventional media by medium, € per inhabitant adjusted for inflation (long series, 2004-2023)"
/>

In this long series "Newspapers" is print only, and all digital advertising, including that on newspapers' websites, goes under "Internet", which includes Google, Meta and the other platforms. Since the 2025 study, InfoAdex adds each medium's digital share to it and separates search engines, social media and other websites. On that basis, in {pub_papel_web[0]?.anio} daily newspapers and Sunday supplements earned {formatNumber(pub_papel_web[0]?.web, 0)} million euros from advertising on their websites and {formatNumber(pub_papel_web[0]?.papel, 0)} million in print, and social media and search engines took {formatNumber(pub_papel_web[0]?.pct_redes + pub_papel_web[0]?.pct_search, 0)} % of all spend.

<BarChart
    data={pub_nueva}
    x=medio
    y=eur_hab_real
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="€ per inhabitant"
    title="Advertising spend by medium in {pub_nueva[0]?.anio}, each medium including its digital share (€ per inhabitant)"
/>

## How many people work in the media

Persons employed (employees and self-employed) in the companies of each branch according to the structural business statistics. In {empleo_ult[0]?.anio} newspaper publishing employed {formatNumber(empleo_ult[0]?.periodicos, 0)} people, radio stations {formatNumber(empleo_ult[0]?.radio, 0)}, television broadcasters {formatNumber(empleo_ult[0]?.tv, 0)} and news agencies {formatNumber(empleo_ult[0]?.agencias, 0)}. Eurostat only gives these branches separately from 2016 (with a methodological break in 2021).

<LineChart
    data={empleo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Persons employed per 100,000 inhabitants"
    seriesColors={{'Periódicos': '#2563eb', 'Revistas': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444', 'Agencias de noticias': '#64748b'}}
    title="Persons employed in media companies, per 100,000 inhabitants"
/>

To go back to 2005, broader branches have to be used: radio and television together, and all publishing (which includes books and software). Radio and television have gone from {formatNumber(j60_extremos[0]?.tv_radio_2008, 0)} persons employed per 100,000 inhabitants in 2008 to {formatNumber(j60_extremos[0]?.tv_radio_ult, 0)}.

<LineChart
    data={empleo_largo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="Persons employed per 100,000 inhabitants"
    title="Persons employed in publishing and in radio and television, per 100,000 inhabitants (2005-latest)"
/>

<LineChart
    data={empleo_largo}
    x=anio
    y=cifra_negocios_eur_hab_real
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ per inhabitant (adjusted for inflation)"
    title="Turnover of publishing and of radio and television, € per inhabitant adjusted for inflation"
/>

### Compared with Europe

In {ue[0]?.anio} Spain had {formatNumber(ue_es[0]?.es, 1)} persons employed in newspaper publishing per 100,000 inhabitants, against an EU average of {formatNumber(ue_es[0]?.ue, 1)} (rank {ue_es[0]?.puesto} of {ue_es[0]?.n} countries with data). In radio and television, {formatNumber(ue_es[0]?.es_tv, 1)} against {formatNumber(ue_es[0]?.ue_tv, 1)}.

<BarChart
    data={ue}
    x=pais_nombre
    y=periodicos_100k
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Persons employed per 100,000 inhabitants"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Persons employed in newspaper publishing per 100,000 inhabitants, {ue[0]?.anio}"
/>

<DataTable data={ue} rows=27>
    <Column id=pais_nombre title="Country" />
    <Column id=periodicos_100k title="Newspapers: employed per 100,000 inhab." fmt='0.0' />
    <Column id=periodicos_eur_hab title="Newspapers: turnover € per inhab." fmt='0.0' />
    <Column id=radio_tv_100k title="Radio and TV: employed per 100,000 inhab." fmt='0.0' />
    <Column id=radio_tv_eur_hab title="Radio and TV: turnover € per inhab." fmt='0.0' />
</DataTable>

## A large listed group: Atresmedia

Revenue and net profit of Atresmedia (Antena 3, laSexta, Onda Cero), in millions of euros adjusted for inflation. In {grupos_resumen[0]?.anio_ult} its revenue was {formatNumber(grupos_resumen[0]?.ing_ult, 0)} million, compared with {formatNumber(grupos_resumen[0]?.ing_2007, 0)} million in 2007; the low point was in {grupos_resumen[0]?.anio_min}, at {formatNumber(grupos_resumen[0]?.ing_min, 0)} million.

<BarChart
    data={grupos_series}
    x=anio
    y=meur_real
    series=concepto
    type=grouped
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Millions of euros (adjusted for inflation)"
    seriesColors={{'Ingresos': '#2563eb', 'Beneficio neto': '#16a34a'}}
    title="Atresmedia: revenue and net profit, millions of euros adjusted for inflation"
/>

## Public money compared with the advertising market

To put public money in the context of the size of the business, the chart divides what the State and its companies spend on advertising campaigns, and what RTVE and the regional broadcasters receive, by total media advertising spend in that year. In {publico_ult_age[0]?.anio} central government advertising was equivalent to {formatNumber(publico_ult_age[0]?.publicidad_estado_pct_mercado, 1)} % of media advertising spend. In {publico_ult[0]?.anio} public funding of the broadcasters was equivalent to {formatNumber(publico_ult[0]?.tv_publica_pct_mercado, 0)} % of all that spend and {formatNumber(publico_ult[0]?.tv_publica_pct_publicidad_tv, 0)} % of television advertising.

<LineChart
    data={publico_series}
    x=anio
    y=pct
    series=concepto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of media advertising spend"
    seriesColors={{'Publicidad del Estado y sus empresas': '#2563eb', 'RTVE y radiotelevisiones autonómicas': '#f59e0b'}}
    title="Public money as a % of media advertising spend"
/>

<DataTable data={publico} rows=20>
    <Column id=anio title="Year" fmt='0' />
    <Column id=controlados_eur_hab_real title="Media advertising spend, €/inhab." fmt='0.0' />
    <Column id=publicidad_estado_eur_hab_real title="Central government advertising, €/inhab." fmt='0.00' />
    <Column id=tv_publica_eur_hab_real title="RTVE and regional broadcasters, €/inhab." fmt='0.0' />
    <Column id=subvenciones_eur_hab_real title="Subsidies to private media, €/inhab." fmt='0.00' />
    <Column id=contratos_eur_hab_real title="Contracts with private media, €/inhab." fmt='0.00' />
</DataTable>

These magnitudes do not measure exactly the same thing: InfoAdex estimates what the media receive for advertising space, net of discounts, whereas the cost of central government campaigns includes creative work, production and, it seems, VAT. The funding of public broadcasters is not advertising, but it is money entering the same audiovisual market. Funding of the regional broadcasters is only available from 2017, and advertising by regional and local governments is missing, as only some of them publish it.

## Methodology and sources

- **Audiences**: [AIMC, Marco General de los Medios en España 2026](https://www.aimc.es/a1mc-c0nt3nt/uploads/2026/02/Marco_General_Medios_2026.pdf) (free publication with data from the Estudio General de Medios): evolution of the general audience 1980-2025, minutes of radio and television 1991-2025 and readers per newspaper 2009-2025. Reach over the population aged 14 or over; to convert to readers per 1,000 inhabitants it is multiplied by the EGM universe and divided by the whole population of the INE municipal register. Until 2017 newspaper reading is print only; from 2018 it includes the digital replica.
- **Advertising spend**: public summaries of the [InfoAdex study of advertising spend in Spain](https://www.infoadex.es/) (2010-2026 editions; the full study is paid). For each year the latest published revision is used. The 2004-2023 series follows the old criterion (newspapers = print; digital, under internet) and the 2022-2025 series the new one (each medium with its website); they are not mixed. Internet was revised upwards from 2014 and outdoor from 2018.
- **Companies and employment**: Eurostat, structural business statistics ([sbs_na_1a_se_r2](https://ec.europa.eu/eurostat/databrowser/view/sbs_na_1a_se_r2/default/table) up to 2020 and [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) from 2021), compiled for Spain by INE with the Structural Business Statistics for the services sector. NACE branches 58.13 (newspapers), 58.14 (magazines), 60.1 (radio), 60.2 (television) and 63.91 (news agencies). The method changed in 2021 (FRIBS regulation).
- **Atresmedia**: [Key figures](https://www.atresmediacorporacion.com/accionistas-inversores/informacion-economico-financiera/principales-magnitudes/) from its shareholders' website (consolidated accounts).
- **Public money**: marts of the [Public money in the media](/en/medios/dinero-publico) section (Institutional Advertising and Communication Commission, CNMC, RTVE accounts, BDNS and the Public Procurement Platform).
- **Constant euros** using the INE CPI, and **population** from the municipal register.
