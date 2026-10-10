---
title: Trust and news consumption
description: "How much Spaniards trust the news and each outlet, how they get their news (television, print, online, social media), how many pay for online news and how many avoid it, since 2013 and compared with the rest of the European Union."
i18n_origen: 5bedbf85df21
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql es
SELECT CAST(anio AS INTEGER) AS anio, confianza, CAST(confianza_puesto_ue AS INTEGER) AS puesto_ue,
       CAST(paises_ue AS INTEGER) AS paises_ue, confianza_media_ue, paga, evita, interes, tv, prensa, online, redes
FROM mother.medios_confianza_espana_anual
ORDER BY anio
```

```sql es_conf
SELECT * FROM ${es} WHERE confianza IS NOT NULL ORDER BY anio
```

```sql es_ult
SELECT * FROM ${es_conf} ORDER BY anio DESC LIMIT 1
```

```sql es_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${es_conf} ORDER BY anio LIMIT 1) AS primer_anio,
    (SELECT confianza FROM ${es_conf} ORDER BY anio LIMIT 1) AS primera,
    (SELECT CAST(anio AS INTEGER) FROM ${es_conf} ORDER BY confianza DESC, anio LIMIT 1) AS anio_max,
    (SELECT confianza FROM ${es_conf} ORDER BY confianza DESC LIMIT 1) AS maxima,
    (SELECT CAST(anio AS INTEGER) FROM ${es_conf} ORDER BY confianza ASC, anio DESC LIMIT 1) AS anio_min,
    (SELECT confianza FROM ${es_conf} ORDER BY confianza ASC LIMIT 1) AS minima,
    (SELECT CAST(anio AS INTEGER) FROM ${es} WHERE paga IS NOT NULL ORDER BY anio LIMIT 1) AS paga_desde,
    (SELECT paga FROM ${es} WHERE paga IS NOT NULL ORDER BY anio LIMIT 1) AS paga_inicio,
    (SELECT paga FROM ${es} WHERE paga IS NOT NULL ORDER BY anio DESC LIMIT 1) AS paga_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${es} WHERE paga IS NOT NULL ORDER BY anio DESC LIMIT 1) AS paga_anio,
    (SELECT evita FROM ${es} WHERE evita IS NOT NULL ORDER BY anio DESC LIMIT 1) AS evita_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${es} WHERE evita IS NOT NULL ORDER BY anio DESC LIMIT 1) AS evita_anio,
    (SELECT evita FROM ${es} WHERE evita IS NOT NULL ORDER BY anio LIMIT 1) AS evita_inicio,
    (SELECT CAST(anio AS INTEGER) FROM ${es} WHERE evita IS NOT NULL ORDER BY anio LIMIT 1) AS evita_desde,
    (SELECT interes FROM ${es} WHERE interes IS NOT NULL ORDER BY anio DESC LIMIT 1) AS interes_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${es} WHERE interes IS NOT NULL ORDER BY anio DESC LIMIT 1) AS interes_anio,
    (SELECT interes FROM ${es} WHERE interes IS NOT NULL ORDER BY anio LIMIT 1) AS interes_inicio,
    (SELECT CAST(anio AS INTEGER) FROM ${es} WHERE interes IS NOT NULL ORDER BY anio LIMIT 1) AS interes_desde
```

```sql conf_series
SELECT anio, 'España' AS serie, confianza AS pct FROM ${es_conf}
UNION ALL
SELECT anio, 'Media de los países de la UE del informe' AS serie, confianza_media_ue AS pct FROM ${es_conf}
ORDER BY anio, serie
```

```sql paises
SELECT iso2, pais, ue, europa, CAST(anio AS INTEGER) AS anio, confianza, CAST(confianza_puesto_ue AS INTEGER) AS puesto_ue,
       CAST(paises_ue AS INTEGER) AS paises_ue, confianza_media_ue, CAST(anio_inicio AS INTEGER) AS anio_inicio,
       confianza_inicio, confianza_cambio_pp, paga, CAST(paga_anio AS INTEGER) AS paga_anio, evita,
       preocupa_falso, redes_noticias, CAST(paga_puesto_ue AS INTEGER) AS paga_puesto_ue,
       CAST(evita_puesto_ue AS INTEGER) AS evita_puesto_ue, CAST(preocupa_falso_puesto_ue AS INTEGER) AS preocupa_falso_puesto_ue,
       CASE WHEN iso2 = 'ES' THEN 'España' WHEN ue THEN 'Resto de la UE' ELSE 'Otros países europeos' END AS grupo
FROM mother.medios_confianza_paises
WHERE europa
ORDER BY confianza DESC
```

```sql paises_ue
SELECT * FROM ${paises} WHERE ue ORDER BY confianza DESC
```

```sql es_pais
SELECT * FROM ${paises} WHERE iso2 = 'ES'
```

```sql ue_extremos
SELECT
    (SELECT pais FROM ${paises_ue} ORDER BY confianza DESC LIMIT 1) AS mas,
    (SELECT confianza FROM ${paises_ue} ORDER BY confianza DESC LIMIT 1) AS mas_pct,
    (SELECT pais FROM ${paises_ue} ORDER BY confianza ASC LIMIT 1) AS menos,
    (SELECT confianza FROM ${paises_ue} ORDER BY confianza ASC LIMIT 1) AS menos_pct,
    (SELECT count(*) FROM ${paises_ue} WHERE confianza_cambio_pp < 0) AS bajan,
    (SELECT count(*) FROM ${paises_ue}) AS total,
    (SELECT pais FROM ${paises_ue} ORDER BY paga DESC LIMIT 1) AS paga_mas,
    (SELECT paga FROM ${paises_ue} ORDER BY paga DESC LIMIT 1) AS paga_mas_pct,
    (SELECT pais FROM ${paises_ue} ORDER BY preocupa_falso DESC LIMIT 1) AS falso_mas,
    (SELECT preocupa_falso FROM ${paises_ue} ORDER BY preocupa_falso DESC LIMIT 1) AS falso_mas_pct,
    (SELECT round(avg(preocupa_falso), 0) FROM ${paises_ue}) AS falso_media,
    (SELECT round(avg(paga), 0) FROM ${paises_ue}) AS paga_media,
    (SELECT round(avg(evita), 0) FROM ${paises_ue}) AS evita_media
```

```sql marcas
SELECT CAST(anio AS INTEGER) AS anio, marca, confia, ni_confia_ni_desconfia, no_confia, neto, CAST(puesto AS INTEGER) AS puesto
FROM mother.medios_confianza_marcas
ORDER BY anio, confia DESC
```

```sql marcas_ult
SELECT m.*, p.confia AS confia_inicio, m.confia - p.confia AS cambio,
       (SELECT CAST(min(anio) AS INTEGER) FROM ${marcas}) AS anio_inicio
FROM ${marcas} m
LEFT JOIN ${marcas} p ON p.marca = m.marca AND p.anio = (SELECT min(anio) FROM ${marcas})
WHERE m.anio = (SELECT max(anio) FROM ${marcas})
ORDER BY m.confia DESC
```

```sql marcas_ext
SELECT
    (SELECT marca FROM ${marcas_ult} ORDER BY confia DESC, neto DESC LIMIT 1) AS mas,
    (SELECT confia FROM ${marcas_ult} ORDER BY confia DESC LIMIT 1) AS mas_pct,
    (SELECT marca FROM ${marcas_ult} ORDER BY confia ASC, neto ASC LIMIT 1) AS menos,
    (SELECT confia FROM ${marcas_ult} ORDER BY confia ASC LIMIT 1) AS menos_pct,
    (SELECT marca FROM ${marcas_ult} ORDER BY no_confia DESC LIMIT 1) AS mas_desconfia,
    (SELECT no_confia FROM ${marcas_ult} ORDER BY no_confia DESC LIMIT 1) AS mas_desconfia_pct,
    (SELECT count(*) FROM ${marcas_ult}) AS n
```

```sql marcas_evol
SELECT anio, marca, confia FROM ${marcas}
WHERE marca IN (SELECT marca FROM ${marcas} GROUP BY marca HAVING count(*) = (SELECT count(DISTINCT anio) FROM ${marcas}))
ORDER BY anio, marca
```

```sql fuentes
SELECT CAST(anio AS INTEGER) AS anio, tipo, pct
FROM mother.medios_confianza_fuentes
ORDER BY anio, tipo
```

```sql fuentes_cambio
SELECT
    (SELECT CAST(min(anio) AS INTEGER) FROM ${fuentes}) AS desde,
    (SELECT CAST(max(anio) AS INTEGER) FROM ${fuentes}) AS hasta,
    max(pct) FILTER (WHERE tipo = 'Prensa impresa' AND anio = (SELECT min(anio) FROM ${fuentes})) AS prensa_ini,
    max(pct) FILTER (WHERE tipo = 'Prensa impresa' AND anio = (SELECT max(anio) FROM ${fuentes})) AS prensa_fin,
    max(pct) FILTER (WHERE tipo = 'Televisión' AND anio = (SELECT min(anio) FROM ${fuentes})) AS tv_ini,
    max(pct) FILTER (WHERE tipo = 'Televisión' AND anio = (SELECT max(anio) FROM ${fuentes})) AS tv_fin,
    max(pct) FILTER (WHERE tipo = 'Redes sociales' AND anio = (SELECT max(anio) FROM ${fuentes})) AS redes_fin,
    max(pct) FILTER (WHERE tipo = 'Internet (cualquier vía)' AND anio = (SELECT max(anio) FROM ${fuentes})) AS online_fin
FROM ${fuentes}
```

```sql eb
SELECT CAST(oleada AS INTEGER) AS oleada, CAST(anio AS INTEGER) AS anio, medio, iso2, pais, ue, confia, media_ue,
       CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(paises_ue AS INTEGER) AS paises_ue
FROM mother.medios_confianza_eurobarometro
```

```sql eb_es
SELECT anio, medio, confia FROM ${eb} WHERE iso2 = 'ES' ORDER BY anio, medio
```

```sql eb_ult
SELECT e.medio, e.confia, e.media_ue, e.confia - e.media_ue AS dif, e.puesto_ue, e.paises_ue, e.anio
FROM ${eb} e
WHERE e.iso2 = 'ES' AND e.oleada = (SELECT max(oleada) FROM ${eb})
ORDER BY e.confia DESC
```

```sql eb_tv
SELECT pais, confia, CASE WHEN iso2 = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM ${eb}
WHERE ue AND medio = 'Televisión' AND oleada = (SELECT max(oleada) FROM ${eb})
ORDER BY confia DESC
```

```sql eb_tv_es
SELECT * FROM ${eb_ult} WHERE medio = 'Televisión'
```

# <span aria-hidden="true">🗞️</span> Trust and news consumption

How much Spaniards trust the news and each outlet, where they get their news, how many pay for online news and how many avoid it. The figures come from two surveys: the Reuters Institute's **Digital News Report** (University of Oxford), which every winter asks around 2,000 internet users per country, and the European Commission's **Eurobarometer**, with interviews of a sample of the whole population (not just internet users) of each EU member state. Everything is given as a **percentage of the population surveyed**.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if es_ult.length && es_resumen.length}
    <KpiCard
        title="Trust the news"
        value={es_ult[0].confianza}
        formattedValue={formatNumber(es_ult[0].confianza, 0) + ' %'}
        unit="of internet users"
        period={`${es_ult[0].anio} · rank ${es_ult[0].puesto_ue} of ${es_ult[0].paises_ue} EU countries`}
        change={es_ult[0].confianza - es_resumen[0].primera}
        changeUnit=" pp"
        changePeriod={`since ${es_resumen[0].primer_anio}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es_conf.map(d => ({...d, y: d.confianza}))}
    />
    <KpiCard
        title="Pay for online news"
        value={es_resumen[0].paga_ult}
        formattedValue={formatNumber(es_resumen[0].paga_ult, 0) + ' %'}
        unit="paid in the last year"
        period={`${es_resumen[0].paga_anio} · average of the report's EU countries: ${formatNumber(ue_extremos[0]?.paga_media, 0)} %`}
        change={es_resumen[0].paga_ult - es_resumen[0].paga_inicio}
        changeUnit=" pp"
        changePeriod={`since ${es_resumen[0].paga_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.paga !== null).map(d => ({...d, y: d.paga}))}
    />
    <KpiCard
        title="Avoid the news"
        value={es_resumen[0].evita_ult}
        formattedValue={formatNumber(es_resumen[0].evita_ult, 0) + ' %'}
        unit="often or sometimes"
        period={`${es_resumen[0].evita_anio} · in ${es_resumen[0].evita_desde}, ${formatNumber(es_resumen[0].evita_inicio, 0)} %`}
        change={es_resumen[0].evita_ult - es_resumen[0].evita_inicio}
        changeUnit=" pp"
        changePeriod={`since ${es_resumen[0].evita_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-down"
        sparklineData={es.filter(d => d.evita !== null).map(d => ({...d, y: d.evita}))}
    />
    <KpiCard
        title="Very interested in the news"
        value={es_resumen[0].interes_ult}
        formattedValue={formatNumber(es_resumen[0].interes_ult, 0) + ' %'}
        unit="very or extremely"
        period={`${es_resumen[0].interes_anio} · in ${es_resumen[0].interes_desde}, ${formatNumber(es_resumen[0].interes_inicio, 0)} %`}
        change={es_resumen[0].interes_ult - es_resumen[0].interes_inicio}
        changeUnit=" pp"
        changePeriod={`since ${es_resumen[0].interes_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.interes !== null).map(d => ({...d, y: d.interes}))}
    />
    {/if}
</div>

## Trust in the news

Share answering that you can trust most news most of the time. In Spain it was {formatNumber(es_ult[0]?.confianza, 0)} % in {es_ult[0]?.anio}, compared with {formatNumber(es_resumen[0]?.primera, 0)} % in {es_resumen[0]?.primer_anio}. The series peaked at {formatNumber(es_resumen[0]?.maxima, 0)} % in {es_resumen[0]?.anio_max} and hit its low of {formatNumber(es_resumen[0]?.minima, 0)} % in {es_resumen[0]?.anio_min}.

<LineChart
    data={conf_series}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% who trust most news"
    seriesColors={{'España': '#dc2626', 'Media de los países de la UE del informe': '#94a3b8'}}
    title="Trust in the news, Spain and EU average"
/>

The average is the simple average of the EU member states covered by the report each year, which have gone from {es_conf[0]?.paises_ue} in {es_conf[0]?.anio} to {es_ult[0]?.paises_ue} in {es_ult[0]?.anio}, so the composition changes.

### Comparison with Europe

In {es_ult[0]?.anio} Spain ranks {es_ult[0]?.puesto_ue} of {es_ult[0]?.paises_ue} EU countries, with {formatNumber(es_ult[0]?.confianza, 0)} % against an average of {formatNumber(es_ult[0]?.confianza_media_ue, 1)} %. The range runs from {formatNumber(ue_extremos[0]?.mas_pct, 0)} % in {ue_extremos[0]?.mas} to {formatNumber(ue_extremos[0]?.menos_pct, 0)} % in {ue_extremos[0]?.menos}; in {ue_extremos[0]?.bajan} of the {ue_extremos[0]?.total} countries trust is lower today than when the series began.

<BarChart
    data={paises}
    x=pais
    y=confianza
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Trust in the news by country, {es_ult[0]?.anio}"
/>

<DataTable data={paises} rows=25 search=true>
    <Column id=pais title="Country" />
    <Column id=confianza title="Trust the news %" fmt='0' />
    <Column id=puesto_ue title="EU rank" fmt='0' />
    <Column id=confianza_inicio title="First year %" fmt='0' />
    <Column id=anio_inicio title="First year" fmt='0' />
    <Column id=confianza_cambio_pp title="Change (points)" fmt='+0;-0;0' contentType=delta />
    <Column id=paga title="Pay for online news %" fmt='0' />
    <Column id=evita title="Avoid the news %" fmt='0' />
    <Column id=preocupa_falso title="Concerned about what is fake online %" fmt='0' />
</DataTable>

## Trust in each outlet

The Digital News Report asks those who know each brand to rate from 0 to 10 how much they trust its news: those who give 6 to 10 trust it and those who give 0 to 4 do not. The brands are some {marcas_ext[0]?.n} chosen by the report itself, not all outlets. In {marcas_ult[0]?.anio} the most trusted is {marcas_ext[0]?.mas} ({formatNumber(marcas_ext[0]?.mas_pct, 0)} %) and the least trusted, {marcas_ext[0]?.menos} ({formatNumber(marcas_ext[0]?.menos_pct, 0)} %); the one with the most people who distrust it is {marcas_ext[0]?.mas_desconfia} ({formatNumber(marcas_ext[0]?.mas_desconfia_pct, 0)} %).

<BarChart
    data={marcas_ult}
    x=marca
    y=confia
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor='#2563eb'
    title="Those who know each brand and trust it, {marcas_ult[0]?.anio}"
/>

<DataTable data={marcas_ult} rows=20>
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=marca title="Brand" />
    <Column id=confia title="Trust %" fmt='0' />
    <Column id=ni_confia_ni_desconfia title="Neither trust nor distrust %" fmt='0' />
    <Column id=no_confia title="Do not trust %" fmt='0' />
    <Column id=neto title="Net (points)" fmt='+0;-0;0' contentType=delta />
    <Column id=confia_inicio title="Trust in {marcas_ult[0]?.anio_inicio} %" fmt='0' />
    <Column id=cambio title="Change (points)" fmt='+0;-0;0' contentType=delta />
</DataTable>

<LineChart
    data={marcas_evol}
    x=anio
    y=confia
    series=marca
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% who trust"
    title="Trust in the brands asked about every year"
/>

### Print, radio, television, internet and social media

The Eurobarometer asks about types of media, not brands: whether people tend to trust the written press, radio, television, the internet and social networks or not. In Spain, as in the EU as a whole, radio is the most trusted medium and social networks the least.

<LineChart
    data={eb_es}
    x=anio
    y=confia
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% who tend to trust"
    title="Spain: trust in each type of media (Eurobarometer)"
/>

<DataTable data={eb_ult}>
    <Column id=medio title="Medium" />
    <Column id=confia title="Spain %" fmt='0' />
    <Column id=media_ue title="EU %" fmt='0' />
    <Column id=dif title="Difference (points)" fmt='+0;-0;0' contentType=delta />
    <Column id=puesto_ue title="Spain's EU rank" fmt='0' />
    <Column id=paises_ue title="Countries" fmt='0' />
</DataTable>

Television is where Spain lags furthest behind: in {eb_tv_es[0]?.anio} {formatNumber(eb_tv_es[0]?.confia, 0)} % of Spaniards trusted it, against {formatNumber(eb_tv_es[0]?.media_ue, 0)} % in the EU, rank {eb_tv_es[0]?.puesto_ue} of {eb_tv_es[0]?.paises_ue}. Between the winter 2021-2022 wave and the autumn 2024 wave, trust in all media rises at the same time in almost every country, so that jump should be read with caution.

<BarChart
    data={eb_tv}
    x=pais
    y=confia
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb'}}
    title="Trust in television by country, {eb_tv_es[0]?.anio} (Eurobarometer)"
/>

## How Spaniards get their news

Share of internet users who used each source for news in the last week. Between {fuentes_cambio[0]?.desde} and {fuentes_cambio[0]?.hasta} print went from {formatNumber(fuentes_cambio[0]?.prensa_ini, 0)} % to {formatNumber(fuentes_cambio[0]?.prensa_fin, 0)} % and television from {formatNumber(fuentes_cambio[0]?.tv_ini, 0)} % to {formatNumber(fuentes_cambio[0]?.tv_fin, 0)} %. Today {formatNumber(fuentes_cambio[0]?.online_fin, 0)} % get their news online (websites, apps, social media, podcasts or chatbots) and {formatNumber(fuentes_cambio[0]?.redes_fin, 0)} % through social media.

<LineChart
    data={fuentes}
    x=anio
    y=pct
    series=tipo
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% who used it in the last week"
    seriesColors={{'Televisión': '#2563eb', 'Prensa impresa': '#78350f', 'Internet (cualquier vía)': '#16a34a', 'Redes sociales': '#db2777'}}
    title="News sources used in the last week"
/>

The survey is online, so it does not represent people who do not use the internet.

## Paying, avoiding and distrusting what circulates

In {es_resumen[0]?.paga_anio} {formatNumber(es_resumen[0]?.paga_ult, 0)} % of Spanish internet users paid for online news (subscription, donation or one-off payment), rank {es_pais[0]?.paga_puesto_ue} among the report's EU countries, whose average is {formatNumber(ue_extremos[0]?.paga_media, 0)} %; the country that pays most is {ue_extremos[0]?.paga_mas}, with {formatNumber(ue_extremos[0]?.paga_mas_pct, 0)} %. {formatNumber(es_resumen[0]?.evita_ult, 0)} % say they avoid the news often or sometimes (EU average: {formatNumber(ue_extremos[0]?.evita_media, 0)} %).

{formatNumber(es_pais[0]?.preocupa_falso, 0)} % are concerned about not being able to tell what is real from what is fake in online news, rank {es_pais[0]?.preocupa_falso_puesto_ue} among the report's EU countries, whose average is {formatNumber(ue_extremos[0]?.falso_media, 0)} %; the highest value is in {ue_extremos[0]?.falso_mas} ({formatNumber(ue_extremos[0]?.falso_mas_pct, 0)} %).

<BarChart
    data={paises}
    x=pais
    y=preocupa_falso
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Concerned about telling real from fake online, {paises[0]?.anio}"
/>

<BarChart
    data={paises}
    x=pais
    y=paga
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Paid for online news in the last year, {es_resumen[0]?.paga_anio}"
/>

## Methodology and sources

- **Digital News Report** by the [Reuters Institute for the Study of Journalism](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2026) (University of Oxford), with the [University of Navarra](https://www.digitalnewsreport.es/) in Spain. Online YouGov survey in late January and early February each year, around 2,000 people per country with quotas by age, sex and region; it represents internet users, not the whole population. The data are taken from each country's pages and from the executive summary (Datawrapper charts and headline figures), published under a [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) licence. Trust by brand has been measured since 2020 on a 0 to 10 scale; before that an average was given, which is not comparable. In the latest reports "online by any route" also includes podcasts and AI chatbots. For news avoidance there are data for Spain in 2017, 2019, 2022, 2025 and 2026; for concern about what is fake, only the 2026 comparison.
- **Standard Eurobarometer** of the [European Commission](https://europa.eu/eurobarometer/surveys/browse/all/series/4961): interviews with around 1,000 people aged 15 or over per member state (around 500 in the smallest). Question on trust in the written press, radio, television, the internet and online social networks ("tend to trust" or "tend not to trust"), in the waves that include it (from autumn 2013 to autumn 2025; there are no data for 2020 or 2023); figures taken from the PDF data annexes of each wave. The EU average is the Eurobarometer's own, weighted by population (including the United Kingdom until 2019). Reuse authorised provided the source is acknowledged (Decision 2011/833/EU).
- SpainFacts does not classify media by editorial line: the brands and their names are those asked about by the Digital News Report.
