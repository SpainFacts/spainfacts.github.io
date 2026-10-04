---
title: Luzatutako aurrekontuak
description: "Zein urtetan izan dituen Espainiak Estatuko Aurrekontu Orokorrak garaiz onartuta, zein iritsi ziren berandu eta zein luzatu ziren, zenbat eguneko atzerapenarekin eta zer Gobernuk aurkeztu behar zituen, 1978tik."
i18n_origen: fd19bed34152
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresSituacion = { 'A tiempo': '#16a34a', 'Tarde': '#f59e0b', 'Prorrogado': '#dc2626', 'Prorrogado (en curso)': '#fca5a5' };
    // Datuetatik gaztelaniaz datorren egoera euskaratzen du
    const EGOERA = { 'A tiempo': 'Garaiz', 'Tarde': 'Berandu', 'Prorrogado': 'Luzatua', 'Prorrogado (en curso)': 'Luzatua (abian)' };
    const egoera = (s) => EGOERA[s] ?? s;
    // Urteei euskal atzizkiak eransten dizkie (2023ko, 2024tik...)
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
</script>

```sql ejercicios
SELECT
    CAST(anio AS INTEGER) AS ejercicio,
    situacion,
    coalesce(ley, '') AS ley,
    fecha_publicacion,
    CAST(dias_prorroga AS INTEGER) AS dias_prorroga,
    en_plazo,
    es_parcial AS en_curso,
    presidente_responsable,
    partido_responsable,
    presidente_1_enero,
    coalesce(url_html, '') AS url_html
FROM mother.gobierno_presupuestos
ORDER BY anio
```

```sql resumen
SELECT
    count(*) AS ejercicios,
    count(*) FILTER (WHERE en_plazo) AS a_tiempo,
    count(*) FILTER (WHERE situacion = 'Tarde') AS tarde,
    count(*) FILTER (WHERE situacion LIKE 'Prorrogado%') AS prorrogados,
    max(ejercicio) FILTER (WHERE en_plazo) AS ultimo_a_tiempo,
    max(ejercicio) AS actual,
    max(situacion) FILTER (WHERE en_curso) AS situacion_actual,
    max(dias_prorroga) FILTER (WHERE en_curso) AS dias_actual,
    count(*) FILTER (WHERE NOT en_plazo AND ejercicio >= (SELECT max(ejercicio) - 9 FROM ${ejercicios})) AS sin_ley_10,
    sum(dias_prorroga) FILTER (WHERE ejercicio >= 2016) AS dias_desde_2016
FROM ${ejercicios}
```

```sql racha
-- Ejercicios seguidos sin ley propia hasta el actual
WITH m AS (
    SELECT ejercicio, en_plazo OR situacion = 'Tarde' AS con_ley,
        sum(CASE WHEN en_plazo OR situacion = 'Tarde' THEN 1 ELSE 0 END) OVER (ORDER BY ejercicio DESC) AS con_ley_despues
    FROM ${ejercicios}
)
SELECT count(*) AS seguidos, min(ejercicio) AS desde FROM m WHERE NOT con_ley AND con_ley_despues = 0
```

```sql serie
SELECT ejercicio, situacion, dias_prorroga FROM ${ejercicios}
```

```sql presidentes
SELECT
    presidente_responsable AS presidente,
    any_value(partido_responsable) AS partido,
    min(ejercicio) AS primer_ejercicio,
    count(*) AS ejercicios,
    count(*) FILTER (WHERE en_plazo) AS a_tiempo,
    count(*) FILTER (WHERE situacion = 'Tarde') AS tarde,
    count(*) FILTER (WHERE situacion LIKE 'Prorrogado%') AS prorrogados,
    100.0 * count(*) FILTER (WHERE NOT en_plazo) / count(*) AS pct_sin_ley,
    avg(dias_prorroga) AS dias_medios
FROM ${ejercicios}
GROUP BY presidente_responsable
ORDER BY primer_ejercicio
```

```sql partidos
-- Observados frente a esperados: los ejercicios sin ley el 1 de enero se reparten
-- según los ejercicios que le tocaba presentar a cada partido; z binomial (aprox. normal)
WITH p AS (
    SELECT
        partido_responsable AS partido,
        count(*) AS ejercicios,
        count(*) FILTER (WHERE NOT en_plazo) AS observados
    FROM ${ejercicios}
    GROUP BY partido_responsable
),
t AS (SELECT sum(ejercicios) AS n, sum(observados) AS total FROM p)
SELECT
    p.partido,
    p.ejercicios,
    p.observados,
    t.total * p.ejercicios / t.n AS esperados,
    p.observados / (t.total * p.ejercicios / t.n) AS ratio,
    (p.observados - t.total * p.ejercicios / t.n)
        / sqrt(t.total * (p.ejercicios / t.n) * (1 - p.ejercicios / t.n)) AS z
FROM p, t
ORDER BY p.ejercicios DESC
```

```sql partidos_resumen
SELECT
    max(ratio) FILTER (WHERE partido = 'PSOE') AS psoe,
    max(ratio) FILTER (WHERE partido = 'PP') AS pp,
    max(ratio) FILTER (WHERE partido = 'UCD') AS ucd,
    max(abs(z)) FILTER (WHERE partido IN ('PSOE', 'PP')) AS z_max
FROM ${partidos}
```

```sql listado
SELECT
    ejercicio,
    situacion,
    ley,
    fecha_publicacion,
    dias_prorroga,
    presidente_responsable,
    presidente_1_enero,
    url_html
FROM ${ejercicios}
ORDER BY ejercicio DESC
```

# 🧾 Estatuko Aurrekontu Orokorrak: garaiz, berandu edo luzatuta

Estatuko Aurrekontu Orokorrak Estatuak urtero zenbat eta zertan gasta dezakeen eta zenbat diru-sarrera aurreikusten dituen finkatzen duen legea dira. Konstituzioak Gobernuari agintzen dio proiektua Kongresuan aurkezteko urtea amaitu baino **hiru hilabete lehenago gutxienez** (134.3 art.), Gorteek urtarrilaren 1a baino lehen onar dezaten. Garaiz iristen ez bada, aurreko urteko aurrekontuak **automatikoki luzatzen dira** berriak onartu arte (134.4 art.). Orri honek, Estatuko Aldizkari Ofizialarekin, zenbat ekitaldi hasi diren aurrekontu propiorik gabe eta zer Gobernuk aurkeztu behar zuen kontatzen du.

<Grid cols=4>
    <KpiCard
        title="{urteko(resumen[0]?.actual)} aurrekontuak"
        value={resumen[0]?.dias_actual}
        formattedValue={egoera(resumen[0]?.situacion_actual)}
        period="{formatNumber(racha[0]?.seguidos, 0)} ekitaldi jarraian lege propiorik gabe, {urtetik(racha[0]?.desde)} · {formatNumber(resumen[0]?.dias_actual, 0)} luzapen-egun aurten"
        source="BOE"
        sparklineData={serie.map(d => d.dias_prorroga)}
    />
    <KpiCard
        title="Garaiz onartutako azken aurrekontua"
        value={resumen[0]?.ultimo_a_tiempo}
        formattedValue={resumen[0]?.ultimo_a_tiempo}
        period="urte horretako urtarrilaren 1a baino lehen BOEn argitaratua"
        source="BOE"
    />
    <KpiCard
        title="Urtarrilaren 1ean aurrekonturik gabeko ekitaldiak"
        value={resumen[0]?.ejercicios - resumen[0]?.a_tiempo}
        formattedValue="{formatNumber(resumen[0]?.ejercicios - resumen[0]?.a_tiempo, 0)} / {formatNumber(resumen[0]?.ejercicios, 0)}"
        period="1978tik: {formatNumber(resumen[0]?.tarde, 0)} berandu onartuak eta {formatNumber(resumen[0]?.prorrogados, 0)} luzatuak (egungoa barne)"
        source="BOE"
    />
    <KpiCard
        title="Azken hamar ekitaldiak"
        value={resumen[0]?.sin_ley_10}
        formattedValue="{formatNumber(resumen[0]?.sin_ley_10, 0)} / 10"
        period="aurrekontu propiorik gabe hasi ziren"
        source="BOE"
    />
</Grid>

## Ekitaldi bakoitza, 1978tik

Estatuak urte bakoitzean aurreko urteko aurrekontu luzatuekin funtzionatu zuen egunak: 0, legea urtarrilaren 1a baino lehen argitaratu bazen; urte osoa, onartu ez bazen. {resumen[0]?.actual}: gaur arte igarotako egunak zenbatzen dira.

<BarChart
    data={serie}
    x=ejercicio
    y=dias_prorroga
    series=situacion
    xFmt='0'
    seriesColors={coloresSituacion}
    yAxisTitle="Luzapen-egunak"
    title="Aurrekontu Lege propioa indarrean izan gabeko egunak ekitaldi bakoitzean"
/>

Urte erdiko atzerapenak aurreko udazkenetik gertu hauteskunde orokorrak edo Gobernu-aldaketa izan zuten ekitaldietan pilatzen dira (1979, 1983, 1990, 2012 eta 2017): Gobernu irtenak ez du proiektua aurkezten edo Gorteak bozkatu aurretik desegiten dira, eta Gobernu berriak urte erdian onartzen du aurrekontua. 2018an, atzerapena Kongresuan babesik ez izateagatik gertatu zen. Oso-osorik luzatutako ekitaldiak Kongresuak proiektua baztertu zuen edo Gobernuak aurkeztu ere egin ez zuen urteak dira.

## Gobernuka

Ekitaldi bakoitza **proiektua aurkeztu behar zuen** presidenteari egozten zaio: aurreko urteko irailaren 30ean kargu zegoenari, epe konstituzionala amaitzen den egunean. Taula osoaren azken zutabeak, gainera, urtarrilaren 1ean nork gobernatzen zuen erakusten du, hura baita luzapena kudeatzen duena.

<DataTable data={presidentes} rows=all>
    <Column id=presidente title="Presidentea"/>
    <Column id=partido title="Alderdia"/>
    <Column id=ejercicios title="Aurkeztu behar zituen ekitaldiak" fmt='0'/>
    <Column id=a_tiempo title="Garaiz" fmt='0'/>
    <Column id=tarde title="Berandu" fmt='0'/>
    <Column id=prorrogados title="Luzatuak" fmt='0'/>
    <Column id=pct_sin_ley title="% legerik gabe urtarrilaren 1ean" fmt='0' contentType=bar barColor="#fca5a5"/>
    <Column id=dias_medios title="Luzapen-egunak ekitaldiko" fmt='0'/>
</DataTable>

## Alderdika: behatuak eta esperotakoak

**Esperotakoak** urtarrilaren 1ean aurrekonturik gabeko ekitaldiak dira, alderdi bakoitzari legozkiokeenak Gobernu guztiek erritmo berean huts egin izan balute, bakoitzari aurkeztea zegokion ekitaldi kopuruaren arabera. 1eko ratioa da esperotakoa; 2, bikoitza; 0,5, erdia.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Presidentearen alderdia"/>
    <Column id=ejercicios title="Aurkeztu behar zituen ekitaldiak" fmt='0'/>
    <Column id=observados title="Legerik gabe urtarrilaren 1ean" fmt='0'/>
    <Column id=esperados title="Esperotakoak" fmt='0.0'/>
    <Column id=ratio title="Behatuak / esperotakoak" fmt='0.00'/>
</DataTable>

PSOE esperotakoaren {formatNumber(partidos_resumen[0]?.psoe, 2)} aldiz dago, PP {formatNumber(partidos_resumen[0]?.pp, 2)} aldiz eta UCD {formatNumber(partidos_resumen[0]?.ucd, 2)} aldiz. {partidos_resumen[0]?.z_max >= 1.96 ? 'PSOEren eta PPren arteko aldea zoriak azalduko lukeena baino handiagoa da, ekitaldi gutxirekin bada ere.' : 'Hain ekitaldi gutxirekin, PSOEren eta PPren arteko aldea ez da zoriak azal lezakeena baino handiagoa.'} Aurrekontu bat aurrera ateratzea, batez ere, Gobernuak Kongresuan gehiengoa izatearen araberakoa da, eta gutxiengoko Gobernuak edo Parlamentu zatikatua dutenak ohikoagoak izan dira 2016tik.

## Ekitaldi guztiak

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=ejercicio title="Ekitaldia" fmt='0'/>
    <Column id=situacion title="Egoera"/>
    <Column id=ley title="Legea"/>
    <Column id=fecha_publicacion title="BOEn argitaratua" fmt='dd/mm/yyyy'/>
    <Column id=dias_prorroga title="Luzapen-egunak" fmt='0'/>
    <Column id=presidente_responsable title="Aurkeztu behar zituena"/>
    <Column id=presidente_1_enero title="Urtarrilaren 1ean gobernatzen zuena"/>
</DataTable>

## Metodologia eta iturriak

- **Iturria:** [Estatuko Aldizkari Ofizialaren](https://www.boe.es/datosabiertos/) eguneroko sumarioak, datu irekien APIa: «Ley N/AAAA, de ..., de Presupuestos Generales del Estado para el año ...» titulua duten legeak. Lege bat hainbat zatitan argitaratu bazen, lehenengoaren data hartzen da. Ez dira zenbatzen jada onartutako aurrekontu bat aldatzen edo zabaltzen duten legeak.
- **Luzapen automatikoa (Konstituzioaren 134.4 art.):** Aurrekontu Legea ekitaldiaren lehen eguna baino lehen onartzen ez bada, aurreko ekitaldikoak automatikoki luzatutzat jotzen dira berriak onartu arte. Luzapenak aurreko urteko kredituak mantentzen ditu, baina ez du uzten kreditu propioa behar duten gastu-politika berririk egiten, eta eguneratzeak (pentsioak, soldata publikoak) errege lege-dekretu bidez egiten dira.
- **Egoera:** «Garaiz» = ekitaldiko urtarrilaren 1a baino lehen BOEn argitaratutako legea; «Berandu» = ekitaldian zehar argitaratua; «Luzatua» = ekitaldia lege propiorik gabe amaitu zen. Luzapen-egunak: urtarrilaren 1etik legea argitaratu arte (urte osoa, legerik izan ez bazen; gaur arte, abian dagoen ekitaldian).
- **Egozpena:** aurreko urteko irailaren 30ean kargu zegoen presidenteari, 134.3 artikuluak proiektua aurkezteko ezartzen duen epea amaitzen den egunean. Aukera eztabaidagarria da Gobernua udazkenean edo neguan aldatzen denean (1983ko eta 2012ko ekitaldiak): taula osoak urtarrilaren 1eko presidentea ere ematen du.
- **Esperotakoak:** 1978tik urtarrilaren 1ean legerik gabeko ekitaldien guztizkoa, alderdi bakoitzak aurkeztu behar zituen ekitaldien arabera banatuta. Gobernu guztiek huts egiteko probabilitate bera zutela suposatzen du, eta hori ez da gertatzen (gehiengo parlamentarioak asko axola du).
- **Nazioarteko alderaketa:** ez da sartzen; luzapen-arauak edo aurrekonturik gabeko Estatuaren itxierarenak herrialde batetik bestera aldatzen dira, eta ez dago estatistika ofizial homogeneorik.
