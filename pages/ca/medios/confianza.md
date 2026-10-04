---
title: Confiança i consum de notícies
description: "Quant confien els espanyols en les notícies i en cada mitjà, com s'informen (televisió, premsa, internet, xarxes), quants paguen per notícies digitals i quants les eviten, des del 2013 i en comparació amb la resta de la Unió Europea."
i18n_origen: 420973bd0968
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

# <span aria-hidden="true">🗞️</span> Confiança i consum de notícies

Quant es refien els espanyols de les notícies i de cada mitjà, per on s'informen, quants paguen per notícies digitals i quants les eviten. Les xifres surten de dues enquestes: el **Digital News Report** del Reuters Institute (Universitat d'Oxford), que pregunta cada hivern a uns 2.000 internautes per país, i l'**Eurobaròmetre** de la Comissió Europea, amb entrevistes a una mostra de tota la població (no només d'internautes) de cada estat de la UE. Tot es dona en **percentatge de la població enquestada**.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if es_ult.length && es_resumen.length}
    <KpiCard
        title="Confien en les notícies"
        value={es_ult[0].confianza}
        formattedValue={formatNumber(es_ult[0].confianza, 0) + ' %'}
        unit="dels internautes"
        period={`${es_ult[0].anio} · posició ${es_ult[0].puesto_ue} de ${es_ult[0].paises_ue} països de la UE`}
        change={es_ult[0].confianza - es_resumen[0].primera}
        changeUnit=" pp"
        changePeriod={`des del ${es_resumen[0].primer_anio}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es_conf.map(d => d.confianza)}
    />
    <KpiCard
        title="Paguen per notícies en línia"
        value={es_resumen[0].paga_ult}
        formattedValue={formatNumber(es_resumen[0].paga_ult, 0) + ' %'}
        unit="va pagar l'últim any"
        period={`${es_resumen[0].paga_anio} · mitjana de la UE de l'informe: ${formatNumber(ue_extremos[0]?.paga_media, 0)} %`}
        change={es_resumen[0].paga_ult - es_resumen[0].paga_inicio}
        changeUnit=" pp"
        changePeriod={`des del ${es_resumen[0].paga_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.paga !== null).map(d => d.paga)}
    />
    <KpiCard
        title="Eviten les notícies"
        value={es_resumen[0].evita_ult}
        formattedValue={formatNumber(es_resumen[0].evita_ult, 0) + ' %'}
        unit="sovint o de vegades"
        period={`${es_resumen[0].evita_anio} · el ${es_resumen[0].evita_desde}, ${formatNumber(es_resumen[0].evita_inicio, 0)} %`}
        change={es_resumen[0].evita_ult - es_resumen[0].evita_inicio}
        changeUnit=" pp"
        changePeriod={`des del ${es_resumen[0].evita_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-down"
        sparklineData={es.filter(d => d.evita !== null).map(d => d.evita)}
    />
    <KpiCard
        title="Molt interessats en les notícies"
        value={es_resumen[0].interes_ult}
        formattedValue={formatNumber(es_resumen[0].interes_ult, 0) + ' %'}
        unit="molt o extremadament"
        period={`${es_resumen[0].interes_anio} · el ${es_resumen[0].interes_desde}, ${formatNumber(es_resumen[0].interes_inicio, 0)} %`}
        change={es_resumen[0].interes_ult - es_resumen[0].interes_inicio}
        changeUnit=" pp"
        changePeriod={`des del ${es_resumen[0].interes_desde}`}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.interes !== null).map(d => d.interes)}
    />
    {/if}
</div>

## Confiança en les notícies

Percentatge que respon que es pot confiar en la majoria de les notícies la major part del temps. A Espanya va ser del {formatNumber(es_ult[0]?.confianza, 0)} % el {es_ult[0]?.anio}, enfront del {formatNumber(es_resumen[0]?.primera, 0)} % del {es_resumen[0]?.primer_anio}. El màxim de la sèrie va ser el {formatNumber(es_resumen[0]?.maxima, 0)} % del {es_resumen[0]?.anio_max} i el mínim, el {formatNumber(es_resumen[0]?.minima, 0)} % del {es_resumen[0]?.anio_min}.

<LineChart
    data={conf_series}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que confia en la majoria de les notícies"
    seriesColors={{'España': '#dc2626', 'Media de los países de la UE del informe': '#94a3b8'}}
    title="Confiança en les notícies, Espanya i mitjana de la UE"
/>

La mitjana és la simple dels estats de la UE que cobreix l'informe cada any, que han passat de {es_conf[0]?.paises_ue} el {es_conf[0]?.anio} a {es_ult[0]?.paises_ue} el {es_ult[0]?.anio}, de manera que la composició canvia.

### Comparació amb Europa

El {es_ult[0]?.anio} Espanya queda en la posició {es_ult[0]?.puesto_ue} de {es_ult[0]?.paises_ue} països de la UE, amb un {formatNumber(es_ult[0]?.confianza, 0)} % enfront d'una mitjana del {formatNumber(es_ult[0]?.confianza_media_ue, 1)} %. Va del {formatNumber(ue_extremos[0]?.mas_pct, 0)} % de {ue_extremos[0]?.mas} al {formatNumber(ue_extremos[0]?.menos_pct, 0)} % de {ue_extremos[0]?.menos}; en {ue_extremos[0]?.bajan} dels {ue_extremos[0]?.total} països la confiança és avui més baixa que en començar la sèrie.

<BarChart
    data={paises}
    x=pais
    y=confianza
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Confiança en les notícies per país, {es_ult[0]?.anio}"
/>

<DataTable data={paises} rows=25 search=true>
    <Column id=pais title="País" />
    <Column id=confianza title="Confia en les notícies %" fmt='0' />
    <Column id=puesto_ue title="Posició a la UE" fmt='0' />
    <Column id=confianza_inicio title="Primer any %" fmt='0' />
    <Column id=anio_inicio title="Primer any" fmt='0' />
    <Column id=confianza_cambio_pp title="Canvi (punts)" fmt='+0;-0;0' contentType=delta />
    <Column id=paga title="Paga per notícies en línia %" fmt='0' />
    <Column id=evita title="Evita les notícies %" fmt='0' />
    <Column id=preocupa_falso title="Li preocupa el que és fals a internet %" fmt='0' />
</DataTable>

## Confiança en cada mitjà

El Digital News Report demana a qui coneix cada marca que puntuï de 0 a 10 quant es refia de les seves notícies: confia qui dona de 6 a 10 i no confia qui dona de 0 a 4. Les marques són unes {marcas_ext[0]?.n} que tria el mateix informe, no tots els mitjans. El {marcas_ult[0]?.anio} la que inspira més confiança és {marcas_ext[0]?.mas} ({formatNumber(marcas_ext[0]?.mas_pct, 0)} %) i la que menys, {marcas_ext[0]?.menos} ({formatNumber(marcas_ext[0]?.menos_pct, 0)} %); la que té més gent que en desconfia és {marcas_ext[0]?.mas_desconfia} ({formatNumber(marcas_ext[0]?.mas_desconfia_pct, 0)} %).

<BarChart
    data={marcas_ult}
    x=marca
    y=confia
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor='#2563eb'
    title="Qui coneix cada marca i hi confia, {marcas_ult[0]?.anio}"
/>

<DataTable data={marcas_ult} rows=20>
    <Column id=puesto title="Posició" fmt='0' />
    <Column id=marca title="Marca" />
    <Column id=confia title="Confia %" fmt='0' />
    <Column id=ni_confia_ni_desconfia title="Ni confia ni desconfia %" fmt='0' />
    <Column id=no_confia title="No confia %" fmt='0' />
    <Column id=neto title="Net (punts)" fmt='+0;-0;0' contentType=delta />
    <Column id=confia_inicio title="Confia el {marcas_ult[0]?.anio_inicio} %" fmt='0' />
    <Column id=cambio title="Canvi (punts)" fmt='+0;-0;0' contentType=delta />
</DataTable>

<LineChart
    data={marcas_evol}
    x=anio
    y=confia
    series=marca
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que confia"
    title="Confiança en les marques preguntades tots els anys"
/>

### Premsa, ràdio, televisió, internet i xarxes

L'Eurobaròmetre pregunta per tipus de mitjà, no per marques: si es tendeix a confiar o no en la premsa escrita, la ràdio, la televisió, internet i les xarxes socials. A Espanya, com en el conjunt de la UE, la ràdio és el mitjà que inspira més confiança i les xarxes socials el que menys.

<LineChart
    data={eb_es}
    x=anio
    y=confia
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que tendeix a confiar"
    title="Espanya: confiança en cada tipus de mitjà (Eurobaròmetre)"
/>

<DataTable data={eb_ult}>
    <Column id=medio title="Mitjà" />
    <Column id=confia title="Espanya %" fmt='0' />
    <Column id=media_ue title="UE %" fmt='0' />
    <Column id=dif title="Diferència (punts)" fmt='+0;-0;0' contentType=delta />
    <Column id=puesto_ue title="Posició d'Espanya a la UE" fmt='0' />
    <Column id=paises_ue title="Països" fmt='0' />
</DataTable>

La televisió és on Espanya queda més lluny: el {eb_tv_es[0]?.anio} hi confiava el {formatNumber(eb_tv_es[0]?.confia, 0)} % dels espanyols, enfront del {formatNumber(eb_tv_es[0]?.media_ue, 0)} % de la UE, posició {eb_tv_es[0]?.puesto_ue} de {eb_tv_es[0]?.paises_ue}. Entre l'onada d'hivern del 2021-2022 i la de tardor del 2024 la confiança en tots els mitjans puja alhora en gairebé tots els països, de manera que aquest salt cal llegir-lo amb cautela.

<BarChart
    data={eb_tv}
    x=pais
    y=confia
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb'}}
    title="Confiança en la televisió per país, {eb_tv_es[0]?.anio} (Eurobaròmetre)"
/>

## Com s'informen els espanyols

Percentatge d'internautes que va fer servir cada font per informar-se l'última setmana. Entre el {fuentes_cambio[0]?.desde} i el {fuentes_cambio[0]?.hasta} la premsa impresa va passar del {formatNumber(fuentes_cambio[0]?.prensa_ini, 0)} % al {formatNumber(fuentes_cambio[0]?.prensa_fin, 0)} % i la televisió, del {formatNumber(fuentes_cambio[0]?.tv_ini, 0)} % al {formatNumber(fuentes_cambio[0]?.tv_fin, 0)} %. Avui el {formatNumber(fuentes_cambio[0]?.online_fin, 0)} % s'informa per internet (webs, aplicacions, xarxes, pòdcasts o xatbots) i el {formatNumber(fuentes_cambio[0]?.redes_fin, 0)} % per xarxes socials.

<LineChart
    data={fuentes}
    x=anio
    y=pct
    series=tipo
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% que la va fer servir l'última setmana"
    seriesColors={{'Televisión': '#2563eb', 'Prensa impresa': '#78350f', 'Internet (cualquier vía)': '#16a34a', 'Redes sociales': '#db2777'}}
    title="Fonts de notícies utilitzades l'última setmana"
/>

L'enquesta és en línia, així que no representa qui no fa servir internet.

## Pagar, evitar i desconfiar del que circula

El {es_resumen[0]?.paga_anio} va pagar per notícies en línia el {formatNumber(es_resumen[0]?.paga_ult, 0)} % dels internautes espanyols (subscripció, donació o pagament puntual), posició {es_pais[0]?.paga_puesto_ue} entre els països de la UE de l'informe, la mitjana dels quals és del {formatNumber(ue_extremos[0]?.paga_media, 0)} %; el que paga més és {ue_extremos[0]?.paga_mas}, amb el {formatNumber(ue_extremos[0]?.paga_mas_pct, 0)} %. El {formatNumber(es_resumen[0]?.evita_ult, 0)} % diu que evita les notícies sovint o de vegades (mitjana de la UE: {formatNumber(ue_extremos[0]?.evita_media, 0)} %).

Al {formatNumber(es_pais[0]?.preocupa_falso, 0)} % li preocupa no saber distingir el que és real del que és fals en les notícies d'internet, posició {es_pais[0]?.preocupa_falso_puesto_ue} entre els països de la UE de l'informe, la mitjana dels quals és del {formatNumber(ue_extremos[0]?.falso_media, 0)} %; el valor més alt és el de {ue_extremos[0]?.falso_mas} ({formatNumber(ue_extremos[0]?.falso_mas_pct, 0)} %).

<BarChart
    data={paises}
    x=pais
    y=preocupa_falso
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Preocupats per distingir el que és real del que és fals a internet, {paises[0]?.anio}"
/>

<BarChart
    data={paises}
    x=pais
    y=paga
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Van pagar per notícies en línia l'últim any, {es_resumen[0]?.paga_anio}"
/>

## Metodologia i fonts

- **Digital News Report** del [Reuters Institute for the Study of Journalism](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2026) (Universitat d'Oxford), amb la [Universitat de Navarra](https://www.digitalnewsreport.es/) a Espanya. Enquesta en línia de YouGov a finals de gener i principis de febrer de cada any, unes 2.000 persones per país amb quotes per edat, sexe i regió; representa els internautes, no tota la població. Les dades es prenen de les pàgines de cada país i del resum executiu (gràfics Datawrapper i xifres destacades), publicats amb llicència [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). La confiança per marca es mesura des del 2020 en una escala de 0 a 10; abans es donava una mitjana, no comparable. En els últims informes «internet per qualsevol via» inclou també els pòdcasts i els xatbots d'IA. Per a l'evitació de les notícies hi ha dada d'Espanya el 2017, el 2019, el 2022, el 2025 i el 2026; per a la preocupació pel que és fals, només la comparació del 2026.
- **Eurobaròmetre Standard** de la [Comissió Europea](https://europa.eu/eurobarometer/surveys/browse/all/series/4961): entrevistes a unes 1.000 persones de 15 anys o més per estat membre (unes 500 en els més petits). Pregunta sobre la confiança en la premsa escrita, la ràdio, la televisió, internet i les xarxes socials en línia («tendeix a confiar» o «tendeix a no confiar»), en les onades que la inclouen (de la tardor del 2013 a la tardor del 2025; no hi ha dades del 2020 ni del 2023); xifres preses dels annexos de dades en PDF de cada onada. La mitjana de la UE és la del mateix Eurobaròmetre, ponderada per població (amb el Regne Unit fins al 2019). Reutilització autoritzada citant la font (Decisió 2011/833/UE).
- SpainFacts no classifica els mitjans per la seva línia editorial: les marques i els seus noms són els que pregunta el Digital News Report.
