---
title: Konfiantza eta albisteen kontsumoa
description: "Zenbaterainoko konfiantza duten espainiarrek albisteetan eta komunikabide bakoitzean, nola informatzen diren (telebista, prentsa, internet, sare sozialak), zenbatek ordaintzen duten albiste digitalengatik eta zenbatek saihesten dituzten, 2013tik eta Europar Batasuneko gainerako herrialdeekin alderatuta."
i18n_origen: 420973bd0968
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
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

# <span aria-hidden="true">🗞️</span> Konfiantza eta albisteen kontsumoa

Zenbaterainoko konfiantza duten espainiarrek albisteetan eta komunikabide bakoitzean, nondik informatzen diren, zenbatek ordaintzen duten albiste digitalengatik eta zenbatek saihesten dituzten. Zifrak bi inkestatatik datoz: Reuters Instituteren (Oxfordeko Unibertsitatea) **Digital News Report**-etik, negu bakoitzean herrialde bakoitzeko 2.000 bat internauta galdekatzen dituena, eta Europako Batzordearen **Eurobarometrotik**, EBko estatu bakoitzeko biztanleria osoaren lagin batekin (ez internautena bakarrik) egindako elkarrizketekin. Dena **inkestatutako biztanleriaren ehunekotan** ematen da.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if es_ult.length && es_resumen.length}
    <KpiCard
        title="Albisteetan konfiantza dute"
        value={es_ult[0].confianza}
        formattedValue={formatNumber(es_ult[0].confianza, 0) + ' %'}
        unit="internautena"
        period={`${es_ult[0].anio} · ${es_ult[0].puesto_ue}. postua EBko ${es_ult[0].paises_ue} herrialdeen artean`}
        change={es_ult[0].confianza - es_resumen[0].primera}
        changeUnit=" pp"
        changePeriod={urtetik(es_resumen[0].primer_anio)}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es_conf.map(d => d.confianza)}
    />
    <KpiCard
        title="Online albisteengatik ordaintzen dute"
        value={es_resumen[0].paga_ult}
        formattedValue={formatNumber(es_resumen[0].paga_ult, 0) + ' %'}
        unit="azken urtean ordaindu zuten"
        period={`${es_resumen[0].paga_anio} · txostenaren EBko batez bestekoa: ${formatNumber(ue_extremos[0]?.paga_media, 0)} %`}
        change={es_resumen[0].paga_ult - es_resumen[0].paga_inicio}
        changeUnit=" pp"
        changePeriod={urtetik(es_resumen[0].paga_desde)}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.paga !== null).map(d => d.paga)}
    />
    <KpiCard
        title="Albisteak saihesten dituzte"
        value={es_resumen[0].evita_ult}
        formattedValue={formatNumber(es_resumen[0].evita_ult, 0) + ' %'}
        unit="maiz edo batzuetan"
        period={`${es_resumen[0].evita_anio} · ${urtean(es_resumen[0].evita_desde)}, ${formatNumber(es_resumen[0].evita_inicio, 0)} %`}
        change={es_resumen[0].evita_ult - es_resumen[0].evita_inicio}
        changeUnit=" pp"
        changePeriod={urtetik(es_resumen[0].evita_desde)}
        source="Reuters Institute, Digital News Report"
        direction="positive-down"
        sparklineData={es.filter(d => d.evita !== null).map(d => d.evita)}
    />
    <KpiCard
        title="Albisteekiko interes handia"
        value={es_resumen[0].interes_ult}
        formattedValue={formatNumber(es_resumen[0].interes_ult, 0) + ' %'}
        unit="oso edo izugarri interesatuta"
        period={`${es_resumen[0].interes_anio} · ${urtean(es_resumen[0].interes_desde)}, ${formatNumber(es_resumen[0].interes_inicio, 0)} %`}
        change={es_resumen[0].interes_ult - es_resumen[0].interes_inicio}
        changeUnit=" pp"
        changePeriod={urtetik(es_resumen[0].interes_desde)}
        source="Reuters Institute, Digital News Report"
        direction="positive-up"
        sparklineData={es.filter(d => d.interes !== null).map(d => d.interes)}
    />
    {/if}
</div>

## Konfiantza albisteetan

Albiste gehienez gehienetan fida daitekeela erantzuten dutenen ehunekoa. Espainian {formatNumber(es_ult[0]?.confianza, 0)} % izan zen {urtean(es_ult[0]?.anio)}, {urteko(es_resumen[0]?.primer_anio)} {formatNumber(es_resumen[0]?.primera, 0)} %-aren aldean. Serieko maximoa {urteko(es_resumen[0]?.anio_max)} {formatNumber(es_resumen[0]?.maxima, 0)} % izan zen, eta minimoa, {urteko(es_resumen[0]?.anio_min)} {formatNumber(es_resumen[0]?.minima, 0)} %.

<LineChart
    data={conf_series}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="Albiste gehienetan konfiantza duenaren %"
    seriesColors={{'España': '#dc2626', 'Media de los países de la UE del informe': '#94a3b8'}}
    title="Konfiantza albisteetan, Espainia eta EBko batez bestekoa"
/>

Batez bestekoa txostenak urte bakoitzean hartzen dituen EBko estatuen batez besteko soila da; estatu horiek {urteko(es_conf[0]?.anio)} {es_conf[0]?.paises_ue} izatetik {urteko(es_ult[0]?.anio)} {es_ult[0]?.paises_ue} izatera igaro dira, beraz, osaera aldatu egiten da.

### Europarekin alderatuta

{urtean(es_ult[0]?.anio)} Espainia EBko {es_ult[0]?.paises_ue} herrialdeen artean {es_ult[0]?.puesto_ue}. postuan dago, {formatNumber(es_ult[0]?.confianza, 0)} %-rekin, {formatNumber(es_ult[0]?.confianza_media_ue, 1)} %-ko batez bestekoaren aldean. Tartea {ue_extremos[0]?.mas} herrialdeko {formatNumber(ue_extremos[0]?.mas_pct, 0)} %-tik {ue_extremos[0]?.menos} herrialdeko {formatNumber(ue_extremos[0]?.menos_pct, 0)} %-ra doa; {ue_extremos[0]?.total} herrialdeetatik {ue_extremos[0]?.bajan}etan konfiantza gaur baxuagoa da seriearen hasieran baino.

<BarChart
    data={paises}
    x=pais
    y=confianza
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Konfiantza albisteetan herrialdeka, {es_ult[0]?.anio}"
/>

<DataTable data={paises} rows=25 search=true>
    <Column id=pais title="Herrialdea" />
    <Column id=confianza title="Albisteetan konfiantza %" fmt='0' />
    <Column id=puesto_ue title="Postua EBn" fmt='0' />
    <Column id=confianza_inicio title="Lehen urtea %" fmt='0' />
    <Column id=anio_inicio title="Lehen urtea" fmt='0' />
    <Column id=confianza_cambio_pp title="Aldaketa (puntuak)" fmt='+0;-0;0' contentType=delta />
    <Column id=paga title="Online albisteengatik ordaintzen du %" fmt='0' />
    <Column id=evita title="Albisteak saihesten ditu %" fmt='0' />
    <Column id=preocupa_falso title="Interneteko faltsuak kezkatzen du %" fmt='0' />
</DataTable>

## Konfiantza komunikabide bakoitzean

Digital News Report-ek marka bakoitza ezagutzen duenari eskatzen dio 0tik 10era puntuatzeko zenbat fidatzen den haren albisteez: 6tik 10era ematen duenak konfiantza du, eta 0tik 4ra ematen duenak ez. Markak txostenak berak aukeratutako {marcas_ext[0]?.n} bat dira, ez komunikabide guztiak. {urtean(marcas_ult[0]?.anio)} konfiantza handiena ematen duena {marcas_ext[0]?.mas} da ({formatNumber(marcas_ext[0]?.mas_pct, 0)} %), eta txikiena, {marcas_ext[0]?.menos} ({formatNumber(marcas_ext[0]?.menos_pct, 0)} %); mesfidati gehien dituena {marcas_ext[0]?.mas_desconfia} da ({formatNumber(marcas_ext[0]?.mas_desconfia_pct, 0)} %).

<BarChart
    data={marcas_ult}
    x=marca
    y=confia
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor='#2563eb'
    title="Marka bakoitza ezagutu eta harengan konfiantza dutenak, {marcas_ult[0]?.anio}"
/>

<DataTable data={marcas_ult} rows=20>
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=marca title="Marka" />
    <Column id=confia title="Konfiantza du %" fmt='0' />
    <Column id=ni_confia_ni_desconfia title="Ez konfiantza ez mesfidantza %" fmt='0' />
    <Column id=no_confia title="Ez du konfiantzarik %" fmt='0' />
    <Column id=neto title="Garbia (puntuak)" fmt='+0;-0;0' contentType=delta />
    <Column id=confia_inicio title="Konfiantza {urtean(marcas_ult[0]?.anio_inicio)} %" fmt='0' />
    <Column id=cambio title="Aldaketa (puntuak)" fmt='+0;-0;0' contentType=delta />
</DataTable>

<LineChart
    data={marcas_evol}
    x=anio
    y=confia
    series=marca
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="Konfiantza duenaren %"
    title="Konfiantza urtero galdetutako marketan"
/>

### Prentsa, irratia, telebista, internet eta sare sozialak

Eurobarometroak komunikabide motei buruz galdetzen du, ez markei buruz: idatzizko prentsan, irratian, telebistan, interneten eta sare sozialetan konfiantza izateko joera dagoen ala ez. Espainian, EB osoan bezala, irratia da konfiantza gehien ematen duen komunikabidea, eta sare sozialak gutxien ematen dutenak.

<LineChart
    data={eb_es}
    x=anio
    y=confia
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="Konfiantza izateko joera duenaren %"
    title="Espainia: konfiantza komunikabide mota bakoitzean (Eurobarometroa)"
/>

<DataTable data={eb_ult}>
    <Column id=medio title="Komunikabidea" />
    <Column id=confia title="Espainia %" fmt='0' />
    <Column id=media_ue title="EB %" fmt='0' />
    <Column id=dif title="Aldea (puntuak)" fmt='+0;-0;0' contentType=delta />
    <Column id=puesto_ue title="Espainiaren postua EBn" fmt='0' />
    <Column id=paises_ue title="Herrialdeak" fmt='0' />
</DataTable>

Telebistan dago Espainia urrunen: {urtean(eb_tv_es[0]?.anio)} espainiarren {formatNumber(eb_tv_es[0]?.confia, 0)} %-k zuen konfiantza harengan, EBko {formatNumber(eb_tv_es[0]?.media_ue, 0)} %-aren aldean, {eb_tv_es[0]?.paises_ue} herrialdeetatik {eb_tv_es[0]?.puesto_ue}. postuan. 2021-2022ko neguko oleadaren eta 2024ko udazkenekoaren artean komunikabide guztiekiko konfiantza aldi berean igotzen da ia herrialde guztietan, beraz, jauzi hori kontuz irakurri behar da.

<BarChart
    data={eb_tv}
    x=pais
    y=confia
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb'}}
    title="Konfiantza telebistan herrialdeka, {eb_tv_es[0]?.anio} (Eurobarometroa)"
/>

## Nola informatzen diren espainiarrak

Azken astean informatzeko iturri bakoitza erabili zuten internauten ehunekoa. {urtetik(fuentes_cambio[0]?.desde)} {urtera(fuentes_cambio[0]?.hasta)}, inprimatutako prentsa {formatNumber(fuentes_cambio[0]?.prensa_ini, 0)} %-tik {formatNumber(fuentes_cambio[0]?.prensa_fin, 0)} %-ra igaro zen, eta telebista, {formatNumber(fuentes_cambio[0]?.tv_ini, 0)} %-tik {formatNumber(fuentes_cambio[0]?.tv_fin, 0)} %-ra. Gaur {formatNumber(fuentes_cambio[0]?.online_fin, 0)} % internet bidez informatzen da (webguneak, aplikazioak, sare sozialak, podcastak edo txatbotak), eta {formatNumber(fuentes_cambio[0]?.redes_fin, 0)} % sare sozialen bidez.

<LineChart
    data={fuentes}
    x=anio
    y=pct
    series=tipo
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="Azken astean erabili zuenaren %"
    seriesColors={{'Televisión': '#2563eb', 'Prensa impresa': '#78350f', 'Internet (cualquier vía)': '#16a34a', 'Redes sociales': '#db2777'}}
    title="Azken astean erabilitako albiste-iturriak"
/>

Inkesta online egiten da; beraz, ez ditu ordezkatzen internet erabiltzen ez dutenak.

## Ordaindu, saihestu eta zabaltzen denaz mesfidatu

{urtean(es_resumen[0]?.paga_anio)} internauta espainiarren {formatNumber(es_resumen[0]?.paga_ult, 0)} %-k ordaindu zuen online albisteengatik (harpidetza, dohaintza edo ordainketa puntuala), txostenaren EBko herrialdeen artean {es_pais[0]?.paga_puesto_ue}. postuan; horien batez bestekoa {formatNumber(ue_extremos[0]?.paga_media, 0)} % da, eta gehien ordaintzen duena {ue_extremos[0]?.paga_mas} da, {formatNumber(ue_extremos[0]?.paga_mas_pct, 0)} %-rekin. {formatNumber(es_resumen[0]?.evita_ult, 0)} %-k dio albisteak maiz edo batzuetan saihesten dituela (EBko batez bestekoa: {formatNumber(ue_extremos[0]?.evita_media, 0)} %).

{formatNumber(es_pais[0]?.preocupa_falso, 0)} %-ri kezka ematen dio interneteko albisteetan egiazkoa faltsutik bereizten ez jakiteak; txostenaren EBko herrialdeen artean {es_pais[0]?.preocupa_falso_puesto_ue}. postua da, eta horien batez bestekoa {formatNumber(ue_extremos[0]?.falso_media, 0)} % da; baliorik altuena {ue_extremos[0]?.falso_mas} herrialdekoa da ({formatNumber(ue_extremos[0]?.falso_mas_pct, 0)} %).

<BarChart
    data={paises}
    x=pais
    y=preocupa_falso
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Interneten egiazkoa faltsutik bereizteaz kezkatuta, {paises[0]?.anio}"
/>

<BarChart
    data={paises}
    x=pais
    y=paga
    series=grupo
    swapXY=true
    yFmt='0"%"'
    seriesColors={{'España': '#dc2626', 'Resto de la UE': '#2563eb', 'Otros países europeos': '#94a3b8'}}
    title="Azken urtean online albisteengatik ordaindu zuten, {es_resumen[0]?.paga_anio}"
/>

## Metodologia eta iturriak

- [Reuters Institute for the Study of Journalism](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2026)-en **Digital News Report** (Oxfordeko Unibertsitatea), Espainian [Nafarroako Unibertsitatearekin](https://www.digitalnewsreport.es/). YouGov-ek urte bakoitzeko urtarrilaren amaieran eta otsailaren hasieran egindako online inkesta, herrialde bakoitzeko 2.000 bat pertsonarekin, adin, sexu eta eskualdeko kuotekin; internautak ordezkatzen ditu, ez biztanleria osoa. Datuak herrialde bakoitzaren orrietatik eta laburpen exekutibotik hartzen dira (Datawrapper grafikoak eta zifra nabarmenak), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) lizentziarekin argitaratuak. Markakako konfiantza 2020tik neurtzen da 0tik 10erako eskalan; lehenago batez besteko bat ematen zen, ez konparagarria. Azken txostenetan «internet edozein bidetatik» kategoriak podcastak eta AAko txatbotak ere barne hartzen ditu. Albisteak saihesteari buruz Espainiako datua dago 2017an, 2019an, 2022an, 2025ean eta 2026an; faltsuaren inguruko kezkari buruz, 2026ko alderaketa soilik.
- [Europako Batzordearen](https://europa.eu/eurobarometer/surveys/browse/all/series/4961) **Eurobarometro Estandarra**: estatu kide bakoitzeko 15 urte edo gehiagoko 1.000 bat pertsonari egindako elkarrizketak (txikienetan 500 bat). Idatzizko prentsan, irratian, telebistan, interneten eta online sare sozialetan duten konfiantzari buruzko galdera («konfiantza izateko joera du» edo «konfiantzarik ez izateko joera du»), galdera hori jasotzen duten oleadetan (2013ko udazkenetik 2025eko udazkenera; ez dago 2020ko ez 2023ko daturik); oleada bakoitzaren PDF formatuko datu-eranskinetatik hartutako zifrak. EBko batez bestekoa Eurobarometroarena bera da, biztanleriaren arabera haztatua (Erresuma Batuarekin 2019ra arte). Berrerabilera baimenduta dago iturria aipatuz gero (2011/833/EB Erabakia).
- SpainFacts-ek ez ditu komunikabideak beren ildo editorialaren arabera sailkatzen: markak eta haien izenak Digital News Report-ek galdetzen dituenak dira.
