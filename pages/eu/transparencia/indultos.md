---
title: Indultuak
description: "Espainiako Gobernu bakoitzak 1977tik zenbat indultu ematen dituen BOEren arabera, haien bilakaera eta presidente eta alderdi bakoitza nola alderatzen den gobernatu duen denboraren arabera."
i18n_origen: a455aff1d882
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresPartido = { 'PSOE': '#e30613', 'PP': '#1d84ce', 'UCD': '#2f9c95' };
    // Urteei euskal atzizkiak eransten dizkie (2021ean, 2023ko, 2019tik...)
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
</script>

```sql anual
SELECT
    CAST(anio AS INTEGER) AS anio,
    CAST(indultos AS INTEGER) AS indultos,
    presidente,
    familia AS partido,
    anio_en_curso
FROM mother.gobierno_actos_anual
ORDER BY anio
```

```sql anual_completo
SELECT * FROM ${anual} WHERE NOT anio_en_curso
```

```sql resumen
WITH u AS (SELECT max(anio) AS anio FROM ${anual_completo})
SELECT
    u.anio AS ultimo_anio,
    max(a.indultos) FILTER (WHERE a.anio = u.anio) AS ultimo,
    avg(a.indultos) FILTER (WHERE a.anio BETWEEN u.anio - 9 AND u.anio) AS media_10,
    avg(a.indultos) FILTER (WHERE a.anio BETWEEN 1996 AND 2005) AS media_9605,
    sum(a.indultos) AS total,
    max(a.indultos) AS maximo,
    arg_max(a.anio, a.indultos) AS anio_maximo,
    (SELECT max(indultos) FROM ${anual} WHERE anio_en_curso) AS en_curso,
    (SELECT max(anio) FROM ${anual}) AS anio_en_curso
FROM ${anual_completo} a, u
GROUP BY u.anio
```

```sql pico
SELECT CAST(anio AS INTEGER) AS anio, CAST(indultos AS INTEGER) AS indultos
FROM mother.gobierno_indultos_mensual
ORDER BY indultos DESC
LIMIT 1
```

```sql minimos
SELECT CAST(max(anio) + 1 AS INTEGER) AS desde FROM ${anual} WHERE indultos > 100
```

```sql presidencias
SELECT
    grupo AS presidente,
    familia AS partido,
    CAST(year(desde) AS INTEGER) AS desde,
    CASE WHEN hasta IS NULL THEN 'hoy' ELSE CAST(year(hasta) AS VARCHAR) END AS hasta,
    anios,
    CAST(indultos AS INTEGER) AS indultos,
    indultos_por_anio,
    indultos_esperados AS esperados,
    indultos_ratio AS ratio,
    orden
FROM mother.gobierno_presidencias_resumen
WHERE nivel = 'Presidente'
ORDER BY orden
```

```sql actual
SELECT * FROM ${presidencias} WHERE hasta = 'hoy'
```

```sql partidos
SELECT
    grupo AS partido,
    anios,
    CAST(indultos AS INTEGER) AS observados,
    indultos_esperados AS esperados,
    indultos_ratio AS ratio,
    indultos_por_anio
FROM mother.gobierno_presidencias_resumen
WHERE nivel = 'Partido'
ORDER BY orden
```

```sql partidos_resumen
SELECT
    max(ratio) FILTER (WHERE partido = 'PSOE') AS psoe,
    max(ratio) FILTER (WHERE partido = 'PP') AS pp,
    max(ratio) FILTER (WHERE partido = 'UCD') AS ucd
FROM ${partidos}
```

```sql misma_epoca
-- Años completos gobernados por un solo presidente desde 1997
SELECT
    familia AS partido,
    count(*) AS anios,
    avg(indultos) AS indultos_por_anio,
    median(indultos) AS mediana
FROM mother.gobierno_actos_anual
WHERE anio >= 1997 AND NOT anio_en_curso AND NOT cambio_de_gobierno
GROUP BY familia
ORDER BY familia
```

# ⚖️ Indultuak

**Indultua** grazia bat da, zeinaren bidez Gobernuak epai irmo batek ezarritako zigorra osorik edo zati batean barkatzen duen. Ministroen Kontseiluak ematen du errege-dekretu bidez, Justizia Ministerioak proposatuta eta epaia eman zuen auzitegiaren txostenaren ondoren (1870eko ekainaren 18ko Legea, 1988an eta 2015ean aldatua). Konstituzioak indultu orokorrak debekatzen ditu (62.i art.): guztiak dira banakakoak eta guztiak argitaratzen dira Estatuko Aldizkari Ofizialean. Orri honek zenbatu egiten ditu.

<Grid cols=4>
    <KpiCard
        title="Indultuak: {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.ultimo}
        formattedValue={formatNumber(resumen[0]?.ultimo, 0)}
        period="{formatNumber(resumen[0]?.en_curso, 0)} {urtean(resumen[0]?.anio_en_curso)} orain arte"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.indultos}))}
    />
    <KpiCard
        title="Azken hamar urteetako batez bestekoa"
        value={resumen[0]?.media_10}
        formattedValue={formatNumber(resumen[0]?.media_10, 0)}
        unit="urtean"
        period="1996 eta 2005 artean, urteko {formatNumber(resumen[0]?.media_9605, 0)}"
        source="BOE"
    />
    <KpiCard
        title="Egungo Gobernuaren erritmoa"
        value={actual[0]?.indultos_por_anio}
        formattedValue={formatNumber(actual[0]?.indultos_por_anio, 0)}
        unit="urtean"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.indultos, 0)} indultu {urtetik(actual[0]?.desde)}"
        source="BOE"
    />
    <KpiCard
        title="Indultu gehien izan dituen urtea"
        value={resumen[0]?.maximo}
        formattedValue={formatNumber(resumen[0]?.maximo, 0)}
        period="{urtean(resumen[0]?.anio_maximo)} · guztira {formatNumber(resumen[0]?.total, 0)} 1978tik"
        source="BOE"
    />
</Grid>

## Zenbat ematen diren urtero

Indultu-errege-dekretuak, Ministroen Kontseiluan onartu ziren urtearen arabera, urte horretan denbora gehien gobernatu zuen presidentearen alderdiaren arabera koloreztatuta. {resumen[0]?.anio_en_curso}: urtean orain artekoa baino ez dago.

<BarChart
    data={anual}
    x=anio
    y=indultos
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Indultuak"
    title="Urtero emandako indultuak"
/>

Serieak sortaka onartutako indultuen puntako batzuk ditu: handiena {urteko(pico[0]?.anio)} abenduan, hilabete bakarrean onartutako {formatNumber(pico[0]?.indultos, 0)} indultu-errege-dekreturekin. {urtetik(minimos[0]?.desde)} ez da urte batean ere 100 indultu gainditu, serie osoko mailarik baxuenak.

## Gobernuka

Indultu bakoitza Ministroen Kontseiluak errege-dekretua onartu zuen egunean kargu zegoen presidenteari egozten zaio. Iraupen desberdineko agintaldiak alderatzeko, taulak **gobernatutako urteko batez bestekoa** ematen du.

<BarChart
    data={presidencias}
    x=presidente
    y=indultos_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0'
    title="Indultuak gobernatutako urteko, presidenteka"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Presidentea"/>
    <Column id=partido title="Alderdia"/>
    <Column id=desde title="Noiztik" fmt='0'/>
    <Column id=hasta title="Noiz arte"/>
    <Column id=anios title="Urteak" fmt='0.0'/>
    <Column id=indultos title="Indultuak" fmt='0'/>
    <Column id=indultos_por_anio title="Urteko" fmt='0' contentType=bar barColor="#c4b5fd"/>
    <Column id=ratio title="Behatuak / esperotakoak" fmt='0.00'/>
</DataTable>

## Alderdika: behatuak eta esperotakoak

**Esperotakoak** alderdi bakoitzari legozkiokeen indultuak dira, 1977az geroztik Gobernu guztiek erritmo berean indultatu izan balute, bakoitzak gobernatu duen denboraren arabera. 1eko ratioa da esperotakoa; 2, bikoitza; 0,5, erdia.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Presidentearen alderdia"/>
    <Column id=anios title="Gobernatutako urteak" fmt='0.0'/>
    <Column id=observados title="Behatuak" fmt='0'/>
    <Column id=esperados title="Gobernatutako denboragatik esperotakoak" fmt='0'/>
    <Column id=ratio title="Behatuak / esperotakoak" fmt='0.00'/>
    <Column id=indultos_por_anio title="Urteko" fmt='0'/>
</DataTable>

Kalkulu horrekin, PSOEk gobernatutako denboragatik esperotako indultuen {formatNumber(partidos_resumen[0]?.psoe, 2)} aldiz eman ditu, PPk {formatNumber(partidos_resumen[0]?.pp, 2)} aldiz eta UCDk {formatNumber(partidos_resumen[0]?.ucd, 2)}. Edozein serie luzetan bezala, erritmoa ez da konstantea izan: kondenatuen kopurua, zigor-legeak eta auzitegiek txostenak egiteko duten irizpidea asko aldatu dira 1977tik. Horregatik, komeni da garai bereko alderaketari ere begiratzea: 1997tik, presidente bakar batek gobernatutako urte osoetan.

<DataTable data={misma_epoca} rows=all>
    <Column id=partido title="Presidentearen alderdia"/>
    <Column id=anios title="Urte osoak (1997-)" fmt='0'/>
    <Column id=indultos_por_anio title="Indultuak urteko (batez bestekoa)" fmt='0'/>
    <Column id=mediana title="Mediana" fmt='0'/>
</DataTable>

## Metodologia eta iturriak

- **Iturria:** [Estatuko Aldizkari Ofizialaren](https://www.boe.es/datosabiertos/) eguneroko sumarioak, datu irekien APIa, 1977ko uztailetik: III. ataleko («Beste xedapen batzuk») errege-dekretuak, «Indultos» epigrafekoak, zeinen tituluak «por el que se indulta» edo «por el que se conmuta» dioen. Akats-zuzenketak ez dira zenbatzen.
- **Zer zenbatzen den:** indultu-errege-dekretuak, ez pertsonak. Dekretu batzuek hainbat pertsona indultatzen dituzte, eta pertsona batzuek indultu bat baino gehiago jasotzen dute. Ez da bereizten indultu osoaren eta partzialaren artean (BOEk dekretuaren testuan dio, ez tituluan). Indultatutako pertsonen izena ez da gordetzen.
- **Data eta Gobernua:** data errege-dekretuarena da (Ministroen Kontseiluarena, tituluan agertzen dena), ez argitalpenarena, asteak geroago izan daitekeena; egun horretan kargu zegoen presidenteari egozten zaio, jardunean bazegoen ere. Datarik gabeko titulu gutxietan (1977-1978) argitalpen-data erabiltzen da.
- **Esperotakoak:** 1977ko uztailaren 5etik aurrerako indultuen guztizkoa, alderdi bakoitzak denbora horren zer zatitan gobernatu zuen biderkatuta. Erritmo konstantea suposatzen du, eta hori ez da gertatzen (ikus testua).
- **Nazioarteko alderaketa:** ez da sartzen; indultuaren figura eta haren argitalpena asko aldatzen dira herrialde batetik bestera, eta ez dago estatistika ofizial homogeneorik.
