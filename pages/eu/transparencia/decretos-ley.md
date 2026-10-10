---
title: Lege-dekretuak
description: "Espainiako Gobernu bakoitzak 1977tik zenbat errege lege-dekretu onartzen dituen, lege-mailako arauen zer zati egiten den dekretuz, Kongresuak zenbat baliozkotzen edo indargabetzen dituen eta alderdi bakoitza nola alderatzen den gobernatu duen denboraren arabera."
i18n_origen: 2922ec7a33e0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresPartido = { 'PSOE': '#e30613', 'PP': '#1d84ce', 'UCD': '#2f9c95' };
    // Urteei euskal atzizkiak eransten dizkie (2021ean, 2023tik...)
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
</script>

```sql anual
SELECT
    CAST(anio AS INTEGER) AS anio,
    CAST(rdl AS INTEGER) AS decretos_ley,
    CAST(leyes AS INTEGER) AS leyes,
    pct_rdl,
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
    max(a.decretos_ley) FILTER (WHERE a.anio = u.anio) AS rdl_ultimo,
    max(a.pct_rdl) FILTER (WHERE a.anio = u.anio) AS pct_ultimo,
    avg(a.decretos_ley) FILTER (WHERE a.anio BETWEEN 1979 AND u.anio) AS media_rdl,
    100.0 * sum(a.decretos_ley) FILTER (WHERE a.anio BETWEEN 1979 AND u.anio)
        / sum(a.decretos_ley + a.leyes) FILTER (WHERE a.anio BETWEEN 1979 AND u.anio) AS pct_historico,
    (SELECT max(decretos_ley) FROM ${anual} WHERE anio_en_curso) AS rdl_en_curso,
    (SELECT max(anio) FROM ${anual}) AS anio_en_curso
FROM ${anual_completo} a, u
GROUP BY u.anio
```

```sql presidencias
SELECT
    grupo AS presidente,
    familia AS partido,
    CAST(year(desde) AS INTEGER) AS desde,
    CASE WHEN hasta IS NULL THEN 'hoy' ELSE CAST(year(hasta) AS VARCHAR) END AS hasta,
    anios,
    CAST(rdl AS INTEGER) AS decretos_ley,
    rdl_por_anio,
    leyes_por_anio,
    pct_rdl,
    CAST(rdl_derogados AS INTEGER) AS derogados,
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
    CAST(rdl AS INTEGER) AS observados,
    rdl_esperados AS esperados,
    rdl_ratio AS ratio,
    rdl_z AS z,
    rdl_por_anio,
    pct_rdl
FROM mother.gobierno_presidencias_resumen
WHERE nivel = 'Partido'
ORDER BY orden
```

```sql partidos_resumen
SELECT
    max(ratio) FILTER (WHERE partido = 'PSOE') AS psoe,
    max(ratio) FILTER (WHERE partido = 'PP') AS pp,
    max(ratio) FILTER (WHERE partido = 'UCD') AS ucd,
    max(rdl_por_anio) FILTER (WHERE partido = 'PSOE') AS psoe_anio,
    max(rdl_por_anio) FILTER (WHERE partido = 'PP') AS pp_anio,
    max(pct_rdl) FILTER (WHERE partido = 'PSOE') AS psoe_pct,
    max(pct_rdl) FILTER (WHERE partido = 'PP') AS pp_pct
FROM ${partidos}
```

```sql decadas
-- Mismo periodo, distinto partido: ritmo por año gobernado desde 1996, cuando PP y PSOE
-- se alternan en una época en que el decreto-ley ya es de uso habitual
SELECT
    familia AS partido,
    count(*) AS anios,
    avg(rdl) AS rdl_por_anio,
    100.0 * sum(rdl) / sum(rdl + leyes) AS pct_rdl
FROM mother.gobierno_actos_anual
WHERE anio >= 1997 AND NOT anio_en_curso AND NOT cambio_de_gobierno
GROUP BY familia
ORDER BY familia
```

```sql estados
SELECT
    estado,
    count(*) AS decretos_ley
FROM mother.gobierno_decretos_ley
WHERE fecha_disposicion >= DATE '1979-01-01'
GROUP BY estado
ORDER BY decretos_ley DESC
```

```sql estados_resumen
SELECT
    count(*) FILTER (WHERE estado = 'Derogado') AS derogados,
    count(*) FILTER (WHERE estado = 'Convalidado') AS convalidados,
    count(*) FILTER (WHERE estado = 'Sin resolución en el BOE') AS sin_resolucion,
    count(*) FILTER (WHERE estado = 'Sin resolución en el BOE' AND fecha_disposicion >= current_date - 60) AS recientes,
    count(*) AS total
FROM mother.gobierno_decretos_ley
WHERE fecha_disposicion >= DATE '1979-01-01'
```

```sql derogados
SELECT
    numero_oficial,
    fecha_disposicion,
    presidente,
    familia AS partido,
    titulo,
    url_html
FROM mother.gobierno_decretos_ley
WHERE estado = 'Derogado'
ORDER BY fecha_disposicion DESC
```

```sql listado
SELECT
    numero_oficial,
    fecha_disposicion,
    presidente,
    familia AS partido,
    estado,
    titulo,
    url_html
FROM mother.gobierno_decretos_ley
ORDER BY fecha_disposicion DESC, numero DESC
```

# 📜 Lege-dekretuak: dekretuz gobernatzea

**Errege lege-dekretua** Gobernuak, eta ez Gorteek, onartzen duen lege-mailako araua da. Konstituzioak (86. art.) **aparteko premia larriko** kasuetan baino ez du baimentzen, zenbait gai ukitzea debekatzen dio (oinarrizko eskubideak, Estatuko erakundeak, hauteskunde-araubidea...) eta Kongresuak hurrengo 30 egun baliodunetan **baliozkotu edo indargabetu** behar du. Orri honek, Estatuko Aldizkari Ofizialarekin, Gobernu bakoitzak zenbat onartzen dituen eta legegintzaren zer zati egiten den bide horretatik kontatzen du.

<Grid cols=4>
    <KpiCard
        title="Lege-dekretuak: {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.rdl_ultimo}
        formattedValue={formatNumber(resumen[0]?.rdl_ultimo, 0)}
        period="batez bestekoa 1979tik: urteko {formatNumber(resumen[0]?.media_rdl, 1)} · {formatNumber(resumen[0]?.rdl_en_curso, 0)} {urtean(resumen[0]?.anio_en_curso)} orain arte"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.decretos_ley}))}
    />
    <KpiCard
        title="Lege-mailako arauen zatia"
        value={resumen[0]?.pct_ultimo}
        formattedValue="{formatNumber(resumen[0]?.pct_ultimo, 0)} %"
        period="lege-dekretuak / (lege-dekretuak + legeak), {urtean(resumen[0]?.ultimo_anio)} · {formatNumber(resumen[0]?.pct_historico, 0)} % 1979tik"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.pct_rdl}))}
    />
    <KpiCard
        title="Egungo Gobernuaren erritmoa"
        value={actual[0]?.rdl_por_anio}
        formattedValue={formatNumber(actual[0]?.rdl_por_anio, 1)}
        unit="urtean"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.decretos_ley, 0)} lege-dekretu {urtetik(actual[0]?.desde)}"
        source="BOE"
    />
    <KpiCard
        title="Kongresuak indargabetuak"
        value={estados_resumen[0]?.derogados}
        formattedValue={formatNumber(estados_resumen[0]?.derogados, 0)}
        period="1979tik onartutako {formatNumber(estados_resumen[0]?.total, 0)} lege-dekretuen artean; gainerakoak baliozkotu egin ziren edo zain daude"
        source="BOE (Kongresuaren ebazpenak)"
    />
</Grid>

## Zenbat onartzen diren urtero

Urtero onartutako lege-dekretuak, urte horretan denbora gehien gobernatu zuen presidentearen alderdiaren arabera koloreztatuta. {resumen[0]?.anio_en_curso}: urtean orain artekoa baino ez dago.

<BarChart
    data={anual}
    x=anio
    y=decretos_ley
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Lege-dekretuak"
    title="Urtero onartutako errege lege-dekretuak"
/>

Lege-dekretuen kopurua ez dago gobernatzen duenaren mende soilik: dekretu gehien dituzten urteak krisiekin bat etortzen dira askotan (2012, finantza-krisiaren erdian; 2020, pandemiarekin), eta hauteskunde-urteek, Gorteak urtearen zati batean desegita daudela, lege gutxiago dituzte eta, beraz, lege-dekretuen ehuneko handiagoa.

## Legegintzaren zer zati egiten den dekretuz

Urtero zenbat legegintza onartzen denaren mende ez egoteko, grafikoak Estatuko **lege-mailako arau guztien gainean lege-dekretuek duten ehunekoa** erakusten du (lege-dekretuak gehi Gorteen legeak eta lege organikoak). % 50ek esan nahi du Gorteetan onartutako lege bakoitzeko Gobernuak lege-dekretu bat onartu zuela.

<LineChart
    data={anual_completo}
    x=anio
    y=pct_rdl
    xFmt='0'
    yFmt='0'
    yAxisTitle="lege-dekretuen %"
    title="Lege-dekretuak lege-mailako arau guztien gainean (%)"
/>

## Gobernuka

Lege-dekretu bakoitza Ministroen Kontseiluak onartu zuen egunean (tituluan agertzen den data) kargu zegoen presidenteari egozten zaio. Iraupen desberdineko agintaldiak alderatzeko, taulak **gobernatutako urteko batez bestekoa** ematen du.

<BarChart
    data={presidencias}
    x=presidente
    y=rdl_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0.0'
    title="Lege-dekretuak gobernatutako urteko, presidenteka"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Presidentea"/>
    <Column id=partido title="Alderdia"/>
    <Column id=desde title="Noiztik" fmt='0'/>
    <Column id=hasta title="Noiz arte"/>
    <Column id=anios title="Urteak" fmt='0.0'/>
    <Column id=decretos_ley title="Lege-dekretuak" fmt='0'/>
    <Column id=rdl_por_anio title="Urteko" fmt='0.0' contentType=bar barColor="#fca5a5"/>
    <Column id=leyes_por_anio title="Legeak urteko" fmt='0.0'/>
    <Column id=pct_rdl title="Lege-dekretuen %" fmt='0'/>
    <Column id=derogados title="Indargabetuak" fmt='0'/>
</DataTable>

## Alderdika: behatuak eta esperotakoak

Besterik gabe zenbatzeak gutxien gobernatu duenari egiten dio mesede. Taulak alderdi bakoitzaren lege-dekretuak alderatzen ditu 1977az geroztik Gobernu guztiek erritmo berean onartu izan balituzte **esperoko liratekeenekin**, bakoitzak gobernatu duen denboraren arabera banatuta. 1eko ratioa da esperotakoa; 2, bikoitza; 0,5, erdia.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Presidentearen alderdia"/>
    <Column id=anios title="Gobernatutako urteak" fmt='0.0'/>
    <Column id=observados title="Behatuak" fmt='0'/>
    <Column id=esperados title="Gobernatutako denboragatik esperotakoak" fmt='0.0'/>
    <Column id=ratio title="Behatuak / esperotakoak" fmt='0.00'/>
    <Column id=pct_rdl title="Lege-dekretuen %" fmt='0'/>
</DataTable>

PSOEk gobernatutako denboragatik legokiokeen lege-dekretuen {formatNumber(partidos_resumen[0]?.psoe, 2)} aldiz onartu ditu, PPk {formatNumber(partidos_resumen[0]?.pp, 2)} aldiz eta UCDk {formatNumber(partidos_resumen[0]?.ucd, 2)}. Alderaketa horrek muga garrantzitsu bat du: lege-dekretuaren erabilera **urteekin hazi da**, eta, beraz, Gobernu berrienak kaltetuta ateratzen dira lehenengoen aldean. Horregatik, komeni da garai bereko alderaketari ere begiratzea: 1997tik, presidente bakar batek gobernatutako urte osoetan, PP eta PSOE txandakatu egin dira boterean.

<DataTable data={decadas} rows=all>
    <Column id=partido title="Presidentearen alderdia"/>
    <Column id=anios title="Urte osoak (1997-)" fmt='0'/>
    <Column id=rdl_por_anio title="Lege-dekretuak urteko" fmt='0.0'/>
    <Column id=pct_rdl title="Lege-dekretuen %" fmt='0'/>
</DataTable>

## Baliozkotuak eta indargabetuak

Kongresuak lege-dekretu bakoitza bozkatu behar du argitaratu eta hurrengo 30 egun baliodunetan. **Baliozkotzen** badu, indarrean jarraitzen du (eta, gainera, lege-proiektu gisa izapidetu dezake zuzenketak egiteko); **indargabetzen** badu, indarrean egoteari uzten dio. 1979tik, Kongresuak {formatNumber(estados_resumen[0]?.derogados, 0)} lege-dekretu indargabetu ditu. {formatNumber(estados_resumen[0]?.sin_resolucion, 0)} kasutan ez da Kongresuaren ebazpena aurkitu BOEn: {formatNumber(estados_resumen[0]?.recientes, 0)} azken 60 egunetakoak dira (bozkatzeko zain), eta gainerakoak, batez ere lehen urteetakoak, ebazpena ez baitzen beti titulu horrekin argitaratzen BOEn.

<DataTable data={derogados} rows=all link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Lege-dekretua"/>
    <Column id=fecha_disposicion title="Data" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Presidentea"/>
    <Column id=partido title="Alderdia"/>
    <Column id=titulo title="Titulua" wrap=true/>
</DataTable>

## Lege-dekretu guztiak

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Lege-dekretua"/>
    <Column id=fecha_disposicion title="Data" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Presidentea"/>
    <Column id=partido title="Alderdia"/>
    <Column id=estado title="Kongresua"/>
    <Column id=titulo title="Titulua" wrap=true/>
</DataTable>

## Metodologia eta iturriak

- **Iturria:** [Estatuko Aldizkari Ofizialaren](https://www.boe.es/datosabiertos/) eguneroko sumarioak, datu irekien APIa, 1977ko uztailetik. I. ataleko (Estatuburutza) errege lege-dekretuak eta legeak hartzen dira, bai eta lege-dekretu bakoitzaren baliozkotzea edo indargabetzea argitaratzeko agintzen duten Diputatuen Kongresuaren ebazpenak ere. Arau bakoitza behin zenbatzen da, BOEk hainbat zatitan argitaratzen badu ere.
- **Data eta Gobernua:** data xedapenarena da (Ministroen Kontseiluarena, tituluan agertzen dena), ez argitalpenarena; dekretua egun horretan kargu zegoen presidenteari egozten zaio, jardunean bazegoen ere. Presidentetzak: Adolfo Suárez (UCD) 1981eko otsailaren 26ra arte, Leopoldo Calvo-Sotelo (UCD), Felipe González (PSOE), José María Aznar (PP), José Luis Rodríguez Zapatero (PSOE), Mariano Rajoy (PP) eta Pedro Sánchez (PSOE; Unidas Podemosekin koalizioan eta gero Sumarrekin, 2020ko urtarriletik).
- **Lege-maila:** ehunekoak lege-dekretuak Gorteen legeekin eta lege organikoekin alderatzen ditu (aurrekontuetakoa barne). Ez ditu barne hartzen legegintzako dekretuak (Gobernuak Gorteen eskuordetzaz onartzen dituen testu bateginak), ezta autonomia-erkidegoetako legeak ere.
- **Esperotakoak:** 1977ko uztailaren 5etik aurrerako lege-dekretuen guztizkoa, alderdi bakoitzak denbora horren zer zatitan gobernatu zuen biderkatuta. Erritmo konstantea suposatzen du, eta hori ez da gertatzen (ikus testua).
- **Baliozkotzea:** Konstituzioa baino lehen (1978ko abenduaren 29a) lege-dekretuek ez zuten Kongresuaren baliozkotzerik behar; horregatik, egoeren zenbaketak 1979an hasten dira.
- **Nazioarteko alderaketa:** ez da sartzen. Herrialde bakoitzak figura desberdinak ditu (decreti-legge Italian, ordonnances Frantzian, medidas provisórias Brasilen...) eta ez dago estatistika ofizial homogeneorik.
