---
title: Confianza y consumo de noticias
description: "Cuánto confían los españoles en las noticias y en cada medio, cómo se informan (televisión, prensa, internet, redes), cuántos pagan por noticias digitales y cuántos las evitan, desde 2013 y comparado con el resto de la Unión Europea."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# <span aria-hidden="true">🗞️</span> Confianza y consumo de noticias

Cuánto se fían los españoles de las noticias y de cada medio, por dónde se informan, cuántos pagan por noticias digitales y cuántos las evitan. Las cifras salen de dos encuestas: el **Digital News Report** del Reuters Institute (Universidad de Oxford), que pregunta cada invierno a unos 2.000 internautas por país, y el **Eurobarómetro** de la Comisión Europea, con entrevistas a una muestra de toda la población (no solo de internautas) de cada Estado de la UE. Todo se da en **porcentaje de la población encuestada**.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if es_ult.length && es_resumen.length}
    <KpiCard
        title="Confían en las noticias"
        value={es_ult[0].confianza}
        formattedValue={formatNumber(es_ult[0].confianza, 0) + ' %'}
        unit="de los internautas"
        period={`${es_ult[0].anio} · puesto ${es_ult[0].puesto_ue} de ${es_ult[0].paises_ue} países de la UE`}
        change={es_ult[0].confianza - es_resumen[0].primera}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].primer_anio}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es_conf.map(d => d.confianza)}
    />
    <KpiCard
        title="Pagan por noticias online"
        value={es_resumen[0].paga_ult}
        formattedValue={formatNumber(es_resumen[0].paga_ult, 0) + ' %'}
        unit="pagó el último año"
        period={`${es_resumen[0].paga_anio} · media de la UE del informe: ${formatNumber(ue_extremos[0]?.paga_media, 0)} %`}
        change={es_resumen[0].paga_ult - es_resumen[0].paga_inicio}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].paga_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.paga !== null).map(d => d.paga)}
    />
    <KpiCard
        title="Evitan las noticias"
        value={es_resumen[0].evita_ult}
        formattedValue={formatNumber(es_resumen[0].evita_ult, 0) + ' %'}
        unit="a menudo o a veces"
        period={`${es_resumen[0].evita_anio} · en ${es_resumen[0].evita_desde}, ${formatNumber(es_resumen[0].evita_inicio, 0)} %`}
        change={es_resumen[0].evita_ult - es_resumen[0].evita_inicio}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].evita_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-down"
        sparklineData={es.filter(d => d.evita !== null).map(d => d.evita)}
    />
    <KpiCard
        title="Muy interesados en las noticias"
        value={es_resumen[0].interes_ult}
        formattedValue={formatNumber(es_resumen[0].interes_ult, 0) + ' %'}
        unit="muy o extremadamente"
        period={`${es_resumen[0].interes_anio} · en ${es_resumen[0].interes_desde}, ${formatNumber(es_resumen[0].interes_inicio, 0)} %`}
        change={es_resumen[0].interes_ult - es_resumen[0].interes_inicio}
        changeUnit=" pp"
        changePeriod={`desde ${es_resumen[0].interes_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.interes !== null).map(d => d.interes)}
    />
    {/if}
</div>

## Confianza en las noticias

Porcentaje que responde que se puede confiar en la mayoría de las noticias la mayor parte del tiempo. En España fue del {formatNumber(es_ult[0]?.confianza, 0)} % en {es_ult[0]?.anio}, frente al {formatNumber(es_resumen[0]?.primera, 0)} % de {es_resumen[0]?.primer_anio}. El máximo de la serie fue el {formatNumber(es_resumen[0]?.maxima, 0)} % de {es_resumen[0]?.anio_max} y el mínimo, el {formatNumber(es_resumen[0]?.minima, 0)} % de {es_resumen[0]?.anio_min}.

<LineChart
    data={conf_series}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que confía en la mayoría de las noticias"
    seriesColors={{'España': '#dc2626', 'Media de los países de la UE del informe': '#94a3b8'}}
    title="Confianza en las noticias, España y media de la UE"
/>

La media es la simple de los Estados de la UE que cubre el informe cada año, que han pasado de {es_conf[0]?.paises_ue} en {es_conf[0]?.anio} a {es_ult[0]?.paises_ue} en {es_ult[0]?.anio}, así que la composición cambia.

### Comparación con Europa

En {es_ult[0]?.anio} España queda en el puesto {es_ult[0]?.puesto_ue} de {es_ult[0]?.paises_ue} países de la UE, con {formatNumber(es_ult[0]?.confianza, 0)} % frente a una media de {formatNumber(es_ult[0]?.confianza_media_ue, 1)} %. Va de {formatNumber(ue_extremos[0]?.mas_pct, 0)} % en {ue_extremos[0]?.mas} a {formatNumber(ue_extremos[0]?.menos_pct, 0)} % en {ue_extremos[0]?.menos}; en {ue_extremos[0]?.bajan} de los {ue_extremos[0]?.total} países la confianza es hoy más baja que al empezar la serie.

<BarChart
    data={paises}
    x=pais
    y=confianza
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Confianza en las noticias por país, {es_ult[0]?.anio}"
/>

<DataTable data={paises} rows=25 search=true>
    <Column id=pais title="País" />
    <Column id=confianza title="Confía en las noticias %" fmt='0' />
    <Column id=puesto_ue title="Puesto en la UE" fmt='0' />
    <Column id=confianza_inicio title="Primer año %" fmt='0' />
    <Column id=anio_inicio title="Primer año" fmt='0' />
    <Column id=confianza_cambio_pp title="Cambio (puntos)" fmt='+0;-0;0' contentType=delta />
    <Column id=paga title="Paga por noticias online %" fmt='0' />
    <Column id=evita title="Evita las noticias %" fmt='0' />
    <Column id=preocupa_falso title="Le preocupa lo falso en internet %" fmt='0' />
</DataTable>

## Confianza en cada medio

El Digital News Report pide a quien conoce cada marca que puntúe de 0 a 10 cuánto se fía de sus noticias: confía quien da de 6 a 10 y no confía quien da de 0 a 4. Las marcas son unas {marcas_ext[0]?.n} que elige el propio informe, no todos los medios. En {marcas_ult[0]?.anio} la que más confianza inspira es {marcas_ext[0]?.mas} ({formatNumber(marcas_ext[0]?.mas_pct, 0)} %) y la que menos, {marcas_ext[0]?.menos} ({formatNumber(marcas_ext[0]?.menos_pct, 0)} %); la que tiene más gente que desconfía es {marcas_ext[0]?.mas_desconfia} ({formatNumber(marcas_ext[0]?.mas_desconfia_pct, 0)} %).

<BarChart
    data={marcas_ult}
    x=marca
    y=confia
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor='#2563eb'
    title="Quien conoce cada marca y confía en ella, {marcas_ult[0]?.anio}"
/>

<DataTable data={marcas_ult} rows=20>
    <Column id=puesto title="Puesto" fmt='0' />
    <Column id=marca title="Marca" />
    <Column id=confia title="Confía %" fmt='0' />
    <Column id=ni_confia_ni_desconfia title="Ni confía ni desconfía %" fmt='0' />
    <Column id=no_confia title="No confía %" fmt='0' />
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
    title="Confianza en las marcas preguntadas todos los años"
/>

### Prensa, radio, televisión, internet y redes

El Eurobarómetro pregunta por tipos de medio, no por marcas: si se tiende a confiar o no en la prensa escrita, la radio, la televisión, internet y las redes sociales. En España, como en el conjunto de la UE, la radio es el medio que más confianza da y las redes sociales el que menos.

<LineChart
    data={eb_es}
    x=anio
    y=confia
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que tiende a confiar"
    title="España: confianza en cada tipo de medio (Eurobarómetro)"
/>

<DataTable data={eb_ult}>
    <Column id=medio title="Medio" />
    <Column id=confia title="España %" fmt='0' />
    <Column id=media_ue title="UE %" fmt='0' />
    <Column id=dif title="Diferencia (puntos)" fmt='+0;-0;0' contentType=delta />
    <Column id=puesto_ue title="Puesto de España en la UE" fmt='0' />
    <Column id=paises_ue title="Países" fmt='0' />
</DataTable>

La televisión es donde España se queda más lejos: en {eb_tv_es[0]?.anio} confiaba en ella el {formatNumber(eb_tv_es[0]?.confia, 0)} % de los españoles, frente al {formatNumber(eb_tv_es[0]?.media_ue, 0)} % de la UE, puesto {eb_tv_es[0]?.puesto_ue} de {eb_tv_es[0]?.paises_ue}. Entre la oleada de invierno de 2021-2022 y la de otoño de 2024 la confianza en todos los medios sube a la vez en casi todos los países, así que ese salto hay que leerlo con cautela.

<BarChart
    data={eb_tv}
    x=pais
    y=confia
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb'}}
    title="Confianza en la televisión por país, {eb_tv_es[0]?.anio} (Eurobarómetro)"
/>

## Cómo se informan los españoles

Porcentaje de internautas que usó cada fuente para informarse en la última semana. Entre {fuentes_cambio[0]?.desde} y {fuentes_cambio[0]?.hasta} la prensa impresa pasó del {formatNumber(fuentes_cambio[0]?.prensa_ini, 0)} % al {formatNumber(fuentes_cambio[0]?.prensa_fin, 0)} % y la televisión, del {formatNumber(fuentes_cambio[0]?.tv_ini, 0)} % al {formatNumber(fuentes_cambio[0]?.tv_fin, 0)} %. Hoy el {formatNumber(fuentes_cambio[0]?.online_fin, 0)} % se informa por internet (webs, aplicaciones, redes, podcasts o chatbots) y el {formatNumber(fuentes_cambio[0]?.redes_fin, 0)} % por redes sociales.

<LineChart
    data={fuentes}
    x=anio
    y=pct
    series=tipo
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que la usó la última semana"
    seriesColors={{'Televisión': '#2563eb', 'Prensa impresa': '#78350f', 'Internet (cualquier vía)': '#16a34a', 'Redes sociales': '#db2777'}}
    title="Fuentes de noticias usadas la última semana"
/>

La encuesta es online, así que no representa a quien no usa internet.

## Pagar, evitar y desconfiar de lo que circula

En {es_resumen[0]?.paga_anio} pagó por noticias online el {formatNumber(es_resumen[0]?.paga_ult, 0)} % de los internautas españoles (suscripción, donación o pago puntual), puesto {es_pais[0]?.paga_puesto_ue} entre los países de la UE del informe, cuya media es del {formatNumber(ue_extremos[0]?.paga_media, 0)} %; el que más paga es {ue_extremos[0]?.paga_mas}, con el {formatNumber(ue_extremos[0]?.paga_mas_pct, 0)} %. El {formatNumber(es_resumen[0]?.evita_ult, 0)} % dice evitar las noticias a menudo o a veces (media de la UE: {formatNumber(ue_extremos[0]?.evita_media, 0)} %).

Al {formatNumber(es_pais[0]?.preocupa_falso, 0)} % le preocupa no saber distinguir lo real de lo falso en las noticias de internet, puesto {es_pais[0]?.preocupa_falso_puesto_ue} entre los países de la UE del informe, cuya media es del {formatNumber(ue_extremos[0]?.falso_media, 0)} %; el valor más alto es el de {ue_extremos[0]?.falso_mas} ({formatNumber(ue_extremos[0]?.falso_mas_pct, 0)} %).

<BarChart
    data={paises}
    x=pais
    y=preocupa_falso
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Preocupados por distinguir lo real de lo falso en internet, {paises[0]?.anio}"
/>

<BarChart
    data={paises}
    x=pais
    y=paga
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Pagaron por noticias online el último año, {es_resumen[0]?.paga_anio}"
/>

## Metodología y fuentes

- **Digital News Report** del [Reuters Institute for the Study of Journalism](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2026) (Universidad de Oxford), con la [Universidad de Navarra](https://www.digitalnewsreport.es/) en España. Encuesta online de YouGov a finales de enero y principios de febrero de cada año, unas 2.000 personas por país con cuotas por edad, sexo y región; representa a los internautas, no a toda la población. Los datos se toman de las páginas de cada país y del resumen ejecutivo (gráficos Datawrapper y cifras destacadas), publicados con licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). La confianza por marca se mide desde 2020 en una escala de 0 a 10; antes se daba una media, no comparable. En los últimos informes «internet por cualquier vía» incluye también los podcasts y los chatbots de IA. Para evitar las noticias hay dato de España en 2017, 2019, 2022, 2025 y 2026; para la preocupación por lo falso, solo la comparación de 2026.
- **Eurobarómetro Standard** de la [Comisión Europea](https://europa.eu/eurobarometer/surveys/browse/all/series/4961): entrevistas a unas 1.000 personas de 15 años o más por Estado miembro (unas 500 en los más pequeños). Pregunta sobre la confianza en la prensa escrita, la radio, la televisión, internet y las redes sociales online («tiende a confiar» o «tiende a no confiar»), en las oleadas que la incluyen (de otoño de 2013 a otoño de 2025; no hay datos de 2020 ni de 2023); cifras tomadas de los anexos de datos en PDF de cada oleada. La media de la UE es la del propio Eurobarómetro, ponderada por población (con el Reino Unido hasta 2019). Reutilización autorizada citando la fuente (Decisión 2011/833/UE).
- SpainFacts no clasifica los medios por su línea editorial: las marcas y sus nombres son los que pregunta el Digital News Report.
