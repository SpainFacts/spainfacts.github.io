---
title: Confianza e consumo de noticias
description: "Canto confían os españois nas noticias e en cada medio, como se informan (televisión, prensa, internet, redes), cantos pagan por noticias dixitais e cantos as evitan, desde 2013 e comparado co resto da Unión Europea."
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

# <span aria-hidden="true">🗞️</span> Confianza e consumo de noticias

Canto se fían os españois das noticias e de cada medio, por onde se informan, cantos pagan por noticias dixitais e cantos as evitan. As cifras saen de dúas enquisas: o **Digital News Report** do Reuters Institute (Universidade de Oxford), que pregunta cada inverno a uns 2.000 internautas por país, e o **Eurobarómetro** da Comisión Europea, con entrevistas a unha mostra de toda a poboación (non só de internautas) de cada Estado da UE. Todo se dá en **porcentaxe da poboación enquisada**.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if es_ult.length && es_resumen.length}
    <KpiCard
        title="Confían nas noticias"
        value={es_ult[0].confianza}
        formattedValue={formatNumber(es_ult[0].confianza, 0) + ' %'}
        unit="dos internautas"
        period={`${es_ult[0].anio} · posto ${es_ult[0].puesto_ue} de ${es_ult[0].paises_ue} países da UE`}
        change={es_ult[0].confianza - es_resumen[0].primera}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].primer_anio}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es_conf.map(d => ({...d, y: d.confianza}))}
    />
    <KpiCard
        title="Pagan por noticias en liña"
        value={es_resumen[0].paga_ult}
        formattedValue={formatNumber(es_resumen[0].paga_ult, 0) + ' %'}
        unit="pagou o último ano"
        period={`${es_resumen[0].paga_anio} · media da UE do informe: ${formatNumber(ue_extremos[0]?.paga_media, 0)} %`}
        change={es_resumen[0].paga_ult - es_resumen[0].paga_inicio}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].paga_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.paga !== null).map(d => ({...d, y: d.paga}))}
    />
    <KpiCard
        title="Evitan as noticias"
        value={es_resumen[0].evita_ult}
        formattedValue={formatNumber(es_resumen[0].evita_ult, 0) + ' %'}
        unit="a miúdo ou ás veces"
        period={`${es_resumen[0].evita_anio} · en ${es_resumen[0].evita_desde}, ${formatNumber(es_resumen[0].evita_inicio, 0)} %`}
        change={es_resumen[0].evita_ult - es_resumen[0].evita_inicio}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].evita_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-down"
        sparklineData={es.filter(d => d.evita !== null).map(d => ({...d, y: d.evita}))}
    />
    <KpiCard
        title="Moi interesados nas noticias"
        value={es_resumen[0].interes_ult}
        formattedValue={formatNumber(es_resumen[0].interes_ult, 0) + ' %'}
        unit="moito ou extremadamente"
        period={`${es_resumen[0].interes_anio} · en ${es_resumen[0].interes_desde}, ${formatNumber(es_resumen[0].interes_inicio, 0)} %`}
        change={es_resumen[0].interes_ult - es_resumen[0].interes_inicio}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].interes_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.interes !== null).map(d => ({...d, y: d.interes}))}
    />
    {/if}
</div>

## Confianza nas noticias

Porcentaxe que responde que se pode confiar na maioría das noticias a maior parte do tempo. En España foi do {formatNumber(es_ult[0]?.confianza, 0)} % en {es_ult[0]?.anio}, fronte ao {formatNumber(es_resumen[0]?.primera, 0)} % de {es_resumen[0]?.primer_anio}. O máximo da serie foi o {formatNumber(es_resumen[0]?.maxima, 0)} % de {es_resumen[0]?.anio_max} e o mínimo, o {formatNumber(es_resumen[0]?.minima, 0)} % de {es_resumen[0]?.anio_min}.

<LineChart
    data={conf_series}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que confía na maioría das noticias"
    seriesColors={{'España': '#dc2626', 'Media de los países de la UE del informe': '#94a3b8'}}
    title="Confianza nas noticias, España e media da UE"
/>

A media é a simple dos Estados da UE que cobre o informe cada ano, que pasaron de {es_conf[0]?.paises_ue} en {es_conf[0]?.anio} a {es_ult[0]?.paises_ue} en {es_ult[0]?.anio}, así que a composición cambia.

### Comparación con Europa

En {es_ult[0]?.anio} España queda no posto {es_ult[0]?.puesto_ue} de {es_ult[0]?.paises_ue} países da UE, cun {formatNumber(es_ult[0]?.confianza, 0)} % fronte a unha media do {formatNumber(es_ult[0]?.confianza_media_ue, 1)} %. Vai do {formatNumber(ue_extremos[0]?.mas_pct, 0)} % en {ue_extremos[0]?.mas} ao {formatNumber(ue_extremos[0]?.menos_pct, 0)} % en {ue_extremos[0]?.menos}; en {ue_extremos[0]?.bajan} dos {ue_extremos[0]?.total} países a confianza é hoxe máis baixa que ao comezar a serie.

<BarChart
    data={paises}
    x=pais
    y=confianza
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Confianza nas noticias por país, {es_ult[0]?.anio}"
/>

<DataTable data={paises} rows=25 search=true>
    <Column id=pais title="País" />
    <Column id=confianza title="Confía nas noticias %" fmt='0' />
    <Column id=puesto_ue title="Posto na UE" fmt='0' />
    <Column id=confianza_inicio title="Primeiro ano %" fmt='0' />
    <Column id=anio_inicio title="Primeiro ano" fmt='0' />
    <Column id=confianza_cambio_pp title="Cambio (puntos)" fmt='+0;-0;0' contentType=delta />
    <Column id=paga title="Paga por noticias en liña %" fmt='0' />
    <Column id=evita title="Evita as noticias %" fmt='0' />
    <Column id=preocupa_falso title="Preocúpalle o falso en internet %" fmt='0' />
</DataTable>

## Confianza en cada medio

O Digital News Report pídelle a quen coñece cada marca que puntúe de 0 a 10 canto se fía das súas noticias: confía quen dá de 6 a 10 e non confía quen dá de 0 a 4. As marcas son unhas {marcas_ext[0]?.n} que elixe o propio informe, non todos os medios. En {marcas_ult[0]?.anio} a que máis confianza inspira é {marcas_ext[0]?.mas} ({formatNumber(marcas_ext[0]?.mas_pct, 0)} %) e a que menos, {marcas_ext[0]?.menos} ({formatNumber(marcas_ext[0]?.menos_pct, 0)} %); a que ten máis xente que desconfía é {marcas_ext[0]?.mas_desconfia} ({formatNumber(marcas_ext[0]?.mas_desconfia_pct, 0)} %).

<BarChart
    data={marcas_ult}
    x=marca
    y=confia
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor='#2563eb'
    title="Quen coñece cada marca e confía nela, {marcas_ult[0]?.anio}"
/>

<DataTable data={marcas_ult} rows=20>
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=marca title="Marca" />
    <Column id=confia title="Confía %" fmt='0' />
    <Column id=ni_confia_ni_desconfia title="Nin confía nin desconfía %" fmt='0' />
    <Column id=no_confia title="Non confía %" fmt='0' />
    <Column id=neto title="Neto (puntos)" fmt='+0;-0;0' contentType=delta />
    <Column id=confia_inicio title="Confía en {marcas_ult[0]?.anio_inicio} %" fmt='0' />
    <Column id=cambio title="Cambio (puntos)" fmt='+0;-0;0' contentType=delta />
</DataTable>

<LineChart
    data={marcas_evol}
    x=anio
    y=confia
    series=marca
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que confía"
    title="Confianza nas marcas preguntadas todos os anos"
/>

### Prensa, radio, televisión, internet e redes

O Eurobarómetro pregunta por tipos de medio, non por marcas: se se tende a confiar ou non na prensa escrita, a radio, a televisión, internet e as redes sociais. En España, como no conxunto da UE, a radio é o medio que máis confianza dá e as redes sociais o que menos.

<LineChart
    data={eb_es}
    x=anio
    y=confia
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que tende a confiar"
    title="España: confianza en cada tipo de medio (Eurobarómetro)"
/>

<DataTable data={eb_ult}>
    <Column id=medio title="Medio" />
    <Column id=confia title="España %" fmt='0' />
    <Column id=media_ue title="UE %" fmt='0' />
    <Column id=dif title="Diferenza (puntos)" fmt='+0;-0;0' contentType=delta />
    <Column id=puesto_ue title="Posto de España na UE" fmt='0' />
    <Column id=paises_ue title="Países" fmt='0' />
</DataTable>

A televisión é onde España queda máis lonxe: en {eb_tv_es[0]?.anio} confiaba nela o {formatNumber(eb_tv_es[0]?.confia, 0)} % dos españois, fronte ao {formatNumber(eb_tv_es[0]?.media_ue, 0)} % da UE, posto {eb_tv_es[0]?.puesto_ue} de {eb_tv_es[0]?.paises_ue}. Entre a vaga de inverno de 2021-2022 e a de outono de 2024 a confianza en todos os medios sobe á vez en case todos os países, así que ese salto hai que lelo con cautela.

<BarChart
    data={eb_tv}
    x=pais
    y=confia
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb'}}
    title="Confianza na televisión por país, {eb_tv_es[0]?.anio} (Eurobarómetro)"
/>

## Como se informan os españois

Porcentaxe de internautas que usou cada fonte para informarse na última semana. Entre {fuentes_cambio[0]?.desde} e {fuentes_cambio[0]?.hasta} a prensa impresa pasou do {formatNumber(fuentes_cambio[0]?.prensa_ini, 0)} % ao {formatNumber(fuentes_cambio[0]?.prensa_fin, 0)} % e a televisión, do {formatNumber(fuentes_cambio[0]?.tv_ini, 0)} % ao {formatNumber(fuentes_cambio[0]?.tv_fin, 0)} %. Hoxe o {formatNumber(fuentes_cambio[0]?.online_fin, 0)} % infórmase por internet (webs, aplicacións, redes, podcasts ou chatbots) e o {formatNumber(fuentes_cambio[0]?.redes_fin, 0)} % por redes sociais.

<LineChart
    data={fuentes}
    x=anio
    y=pct
    series=tipo
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que a usou a última semana"
    seriesColors={{'Televisión': '#2563eb', 'Prensa impresa': '#78350f', 'Internet (cualquier vía)': '#16a34a', 'Redes sociales': '#db2777'}}
    title="Fontes de noticias usadas a última semana"
/>

A enquisa é en liña, así que non representa a quen non usa internet.

## Pagar, evitar e desconfiar do que circula

En {es_resumen[0]?.paga_anio} pagou por noticias en liña o {formatNumber(es_resumen[0]?.paga_ult, 0)} % dos internautas españois (subscrición, doazón ou pagamento puntual), posto {es_pais[0]?.paga_puesto_ue} entre os países da UE do informe, cuxa media é do {formatNumber(ue_extremos[0]?.paga_media, 0)} %; o que máis paga é {ue_extremos[0]?.paga_mas}, co {formatNumber(ue_extremos[0]?.paga_mas_pct, 0)} %. O {formatNumber(es_resumen[0]?.evita_ult, 0)} % di evitar as noticias a miúdo ou ás veces (media da UE: {formatNumber(ue_extremos[0]?.evita_media, 0)} %).

Ao {formatNumber(es_pais[0]?.preocupa_falso, 0)} % preocúpalle non saber distinguir o real do falso nas noticias de internet, posto {es_pais[0]?.preocupa_falso_puesto_ue} entre os países da UE do informe, cuxa media é do {formatNumber(ue_extremos[0]?.falso_media, 0)} %; o valor máis alto é o de {ue_extremos[0]?.falso_mas} ({formatNumber(ue_extremos[0]?.falso_mas_pct, 0)} %).

<BarChart
    data={paises}
    x=pais
    y=preocupa_falso
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Preocupados por distinguir o real do falso en internet, {paises[0]?.anio}"
/>

<BarChart
    data={paises}
    x=pais
    y=paga
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Pagaron por noticias en liña o último ano, {es_resumen[0]?.paga_anio}"
/>

## Metodoloxía e fontes

- **Digital News Report** do [Reuters Institute for the Study of Journalism](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2026) (Universidade de Oxford), coa [Universidade de Navarra](https://www.digitalnewsreport.es/) en España. Enquisa en liña de YouGov a finais de xaneiro e principios de febreiro de cada ano, unhas 2.000 persoas por país con cotas por idade, sexo e rexión; representa os internautas, non toda a poboación. Os datos tómanse das páxinas de cada país e do resumo executivo (gráficos Datawrapper e cifras destacadas), publicados con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). A confianza por marca mídese desde 2020 nunha escala de 0 a 10; antes dábase unha media, non comparable. Nos últimos informes «internet por calquera vía» inclúe tamén os podcasts e os chatbots de IA. Para evitar as noticias hai dato de España en 2017, 2019, 2022, 2025 e 2026; para a preocupación polo falso, só a comparación de 2026.
- **Eurobarómetro Standard** da [Comisión Europea](https://europa.eu/eurobarometer/surveys/browse/all/series/4961): entrevistas a unhas 1.000 persoas de 15 anos ou máis por Estado membro (unhas 500 nos máis pequenos). Pregunta sobre a confianza na prensa escrita, a radio, a televisión, internet e as redes sociais en liña («tende a confiar» ou «tende a non confiar»), nas vagas que a inclúen (do outono de 2013 ao outono de 2025; non hai datos de 2020 nin de 2023); cifras tomadas dos anexos de datos en PDF de cada vaga. A media da UE é a do propio Eurobarómetro, ponderada por poboación (co Reino Unido ata 2019). Reutilización autorizada citando a fonte (Decisión 2011/833/UE).
- SpainFacts non clasifica os medios pola súa liña editorial: as marcas e os seus nomes son os que pregunta o Digital News Report.
