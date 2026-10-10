---
title: Pressupostos prorrogats
description: "Quins anys Espanya ha tingut Pressupostos Generals de l'Estat aprovats a temps, quins van arribar tard i quins es van prorrogar, amb quants dies de retard i quin Govern els havia de presentar, des de 1978."
i18n_origen: 1b5c090de484
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresSituacion = { 'A tiempo': '#16a34a', 'Tarde': '#f59e0b', 'Prorrogado': '#dc2626', 'Prorrogado (en curso)': '#fca5a5' };
    const situacionCa = { 'A tiempo': 'A temps', 'Tarde': 'Tard', 'Prorrogado': 'Prorrogat', 'Prorrogado (en curso)': 'Prorrogat (en curs)' };
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

# 🧾 Pressupostos Generals de l'Estat: a temps, tard o prorrogats

Els Pressupostos Generals de l'Estat són la llei que fixa cada any quant pot gastar l'Estat i en què, i quant preveu ingressar. La Constitució obliga el Govern a presentar el projecte al Congrés **almenys tres mesos abans** que acabi l'any (art. 134.3), perquè les Corts l'aprovin abans de l'1 de gener. Si no arriba a temps, els pressupostos de l'any anterior **es prorroguen automàticament** fins que s'aprovin els nous (art. 134.4). Aquesta pàgina compta, amb el Butlletí Oficial de l'Estat, quants exercicis han començat sense pressupost propi i quin Govern l'havia de presentar.

<Grid cols=4>
    <KpiCard
        title="Pressupostos de {resumen[0]?.actual}"
        value={resumen[0]?.dias_actual}
        formattedValue={situacionCa[resumen[0]?.situacion_actual] ?? resumen[0]?.situacion_actual}
        period="{formatNumber(racha[0]?.seguidos, 0)} exercicis seguits sense llei pròpia, des de {racha[0]?.desde} · {formatNumber(resumen[0]?.dias_actual, 0)} dies de pròrroga aquest any"
        source="BOE"
        sparklineData={serie.map(d => ({...d, y: d.dias_prorroga}))}
    />
    <KpiCard
        title="Últim pressupost aprovat a temps"
        value={resumen[0]?.ultimo_a_tiempo}
        formattedValue={resumen[0]?.ultimo_a_tiempo}
        period="publicat al BOE abans de l'1 de gener d'aquell any"
        source="BOE"
    />
    <KpiCard
        title="Exercicis sense pressupost l'1 de gener"
        value={resumen[0]?.ejercicios - resumen[0]?.a_tiempo}
        formattedValue="{formatNumber(resumen[0]?.ejercicios - resumen[0]?.a_tiempo, 0)} de {formatNumber(resumen[0]?.ejercicios, 0)}"
        period="des de 1978: {formatNumber(resumen[0]?.tarde, 0)} aprovats tard i {formatNumber(resumen[0]?.prorrogados, 0)} prorrogats (inclòs l'actual)"
        source="BOE"
    />
    <KpiCard
        title="Últims deu exercicis"
        value={resumen[0]?.sin_ley_10}
        formattedValue="{formatNumber(resumen[0]?.sin_ley_10, 0)} de 10"
        period="van començar sense pressupost propi"
        source="BOE"
    />
</Grid>

## Cada exercici, des de 1978

Dies de cada any en què l'Estat va funcionar amb els pressupostos de l'any anterior prorrogats: 0 si la llei es va publicar abans de l'1 de gener, l'any sencer si no es va arribar a aprovar. {resumen[0]?.actual} compta els dies transcorreguts fins avui.

<BarChart
    data={serie}
    x=ejercicio
    y=dias_prorroga
    series=situacion
    xFmt='0'
    seriesColors={coloresSituacion}
    yAxisTitle="Dies de pròrroga"
    title="Dies de cada exercici sense Llei de Pressupostos pròpia en vigor"
/>

Els retards de mig any es concentren en els exercicis amb eleccions generals o canvi de Govern a prop de la tardor anterior (1979, 1983, 1990, 2012 i 2017): el Govern sortint no presenta el projecte o les Corts es dissolen abans de votar-lo, i el nou Govern aprova el pressupost a mitjan any. El 2018 el retard es va deure a la manca de suports al Congrés. Els exercicis prorrogats sencers són aquells en què el Congrés va rebutjar el projecte o el Govern no el va arribar a presentar.

## Per Govern

Cada exercici s'atribueix al president que **havia de presentar el projecte**: el que estava en funcions el 30 de setembre de l'any anterior, quan venç el termini constitucional. L'última columna de la taula completa mostra a més qui governava l'1 de gener, que és qui gestiona la pròrroga.

<DataTable data={presidentes} rows=all>
    <Column id=presidente title="President"/>
    <Column id=partido title="Partit"/>
    <Column id=ejercicios title="Exercicis que havia de presentar" fmt='0'/>
    <Column id=a_tiempo title="A temps" fmt='0'/>
    <Column id=tarde title="Tard" fmt='0'/>
    <Column id=prorrogados title="Prorrogats" fmt='0'/>
    <Column id=pct_sin_ley title="% sense llei l'1 de gener" fmt='0' contentType=bar barColor="#fca5a5"/>
    <Column id=dias_medios title="Dies de pròrroga per exercici" fmt='0'/>
</DataTable>

## Per partit: observats davant esperats

Els **esperats** són els exercicis sense pressupost l'1 de gener que correspondrien a cada partit si tots els governs haguessin fallat al mateix ritme, segons el nombre d'exercicis que tocava presentar a cadascun. Una ràtio d'1 és el que caldria esperar; 2, el doble; 0,5, la meitat.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partit del president"/>
    <Column id=ejercicios title="Exercicis que havia de presentar" fmt='0'/>
    <Column id=observados title="Sense llei l'1 de gener" fmt='0'/>
    <Column id=esperados title="Esperats" fmt='0.0'/>
    <Column id=ratio title="Observats / esperats" fmt='0.00'/>
</DataTable>

El PSOE és a {formatNumber(partidos_resumen[0]?.psoe, 2)} vegades el que caldria esperar, el PP a {formatNumber(partidos_resumen[0]?.pp, 2)} i la UCD a {formatNumber(partidos_resumen[0]?.ucd, 2)}. {partidos_resumen[0]?.z_max >= 1.96 ? "Entre PSOE i PP la diferència és més gran de la que explicaria l'atzar, encara que amb pocs exercicis." : "Amb tan pocs exercicis, la diferència entre PSOE i PP no és més gran de la que podria explicar l'atzar."} Que un pressupost tiri endavant depèn sobretot que el Govern tingui majoria al Congrés, i els governs en minoria o amb el Parlament fragmentat han estat més freqüents des de 2016.

## Tots els exercicis

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=ejercicio title="Exercici" fmt='0'/>
    <Column id=situacion title="Situació"/>
    <Column id=ley title="Llei"/>
    <Column id=fecha_publicacion title="Publicada al BOE" fmt='dd/mm/yyyy'/>
    <Column id=dias_prorroga title="Dies de pròrroga" fmt='0'/>
    <Column id=presidente_responsable title="Els havia de presentar"/>
    <Column id=presidente_1_enero title="Governava l'1 de gener"/>
</DataTable>

## Metodologia i fonts

- **Font:** sumaris diaris del [Butlletí Oficial de l'Estat](https://www.boe.es/datosabiertos/), API de dades obertes: les lleis el títol de les quals és «Ley N/AAAA, de ..., de Presupuestos Generales del Estado para el año ...». Si una llei es va publicar en diverses parts, compta la data de la primera. No es compten les lleis que modifiquen o amplien un pressupost ja aprovat.
- **Pròrroga automàtica (art. 134.4 de la Constitució):** si la Llei de Pressupostos no s'aprova abans del primer dia de l'exercici, es consideren automàticament prorrogats els de l'exercici anterior fins que s'aprovin els nous. La pròrroga manté els crèdits de l'any anterior, però no permet noves polítiques de despesa que necessitin crèdit propi, i les actualitzacions (pensions, sous públics) es fan per reial decret llei.
- **Situació:** «A temps» = llei publicada al BOE abans de l'1 de gener de l'exercici; «Tard» = publicada durant l'exercici; «Prorrogat» = l'exercici va acabar sense llei pròpia. Dies de pròrroga: de l'1 de gener a la publicació de la llei (l'any sencer si no n'hi va haver; fins avui en l'exercici en curs).
- **Atribució:** al president en funcions el 30 de setembre de l'any anterior, data en què venç el termini de l'art. 134.3 per presentar el projecte. És una elecció discutible quan el Govern canvia a la tardor o a l'hivern (exercicis 1983 i 2012): la taula completa dona també el president de l'1 de gener.
- **Esperats:** total d'exercicis sense llei l'1 de gener des de 1978, repartit segons els exercicis que havia de presentar cada partit. Suposa que tots els governs tenien la mateixa probabilitat de fallar, cosa que no passa (la majoria parlamentària importa molt).
- **Comparació internacional:** no s'inclou; les regles de pròrroga o de tancament de l'Estat sense pressupost canvien d'un país a l'altre i no hi ha una estadística oficial homogènia.
