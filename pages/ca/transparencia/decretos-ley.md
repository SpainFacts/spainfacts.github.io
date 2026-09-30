---
title: Decrets llei
description: "Quants reials decrets llei aprova cada Govern d'Espanya des de 1977, quina part de les normes amb rang de llei es fan per decret, quants en convalida o en deroga el Congrés i com es compara cada partit segons el temps que ha governat."
i18n_origen: 4d28d421b631
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresPartido = { 'PSOE': '#e30613', 'PP': '#1d84ce', 'UCD': '#2f9c95' };
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

# 📜 Decrets llei: governar per decret

El **reial decret llei** és una norma amb rang de llei que aprova el Govern, no les Corts. La Constitució (art. 86) només ho permet en cas d'**extraordinària i urgent necessitat**, li prohibeix tocar certes matèries (drets fonamentals, institucions de l'Estat, règim electoral...) i obliga que el Congrés el **convalidi o el derogui** en els 30 dies hàbils següents. Aquesta pàgina compta, amb el Butlletí Oficial de l'Estat, quants n'aprova cada Govern i quina part de la legislació es fa per aquesta via.

<Grid cols=4>
    <KpiCard
        title="Decrets llei el {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.rdl_ultimo}
        formattedValue={formatNumber(resumen[0]?.rdl_ultimo, 0)}
        period="mitjana des de 1979: {formatNumber(resumen[0]?.media_rdl, 1)} l'any · {formatNumber(resumen[0]?.rdl_en_curso, 0)} en el que va de {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => d.decretos_ley)}
    />
    <KpiCard
        title="Part de les normes amb rang de llei"
        value={resumen[0]?.pct_ultimo}
        formattedValue="{formatNumber(resumen[0]?.pct_ultimo, 0)} %"
        period="decrets llei sobre decrets llei + lleis el {resumen[0]?.ultimo_anio} · {formatNumber(resumen[0]?.pct_historico, 0)} % des de 1979"
        source="BOE"
        sparklineData={anual_completo.map(d => d.pct_rdl)}
    />
    <KpiCard
        title="Ritme del Govern actual"
        value={actual[0]?.rdl_por_anio}
        formattedValue={formatNumber(actual[0]?.rdl_por_anio, 1)}
        unit="l'any"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.decretos_ley, 0)} decrets llei des de {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Derogats pel Congrés"
        value={estados_resumen[0]?.derogados}
        formattedValue={formatNumber(estados_resumen[0]?.derogados, 0)}
        period="de {formatNumber(estados_resumen[0]?.total, 0)} decrets llei des de 1979; la resta es van convalidar o estan pendents"
        source="BOE (resolucions del Congrés)"
    />
</Grid>

## Quants se n'aproven cada any

Decrets llei aprovats cada any, acolorits segons el partit del president que més temps va governar aquell any. {resumen[0]?.anio_en_curso} només inclou el que va d'any.

<BarChart
    data={anual}
    x=anio
    y=decretos_ley
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Decrets llei"
    title="Reials decrets llei aprovats per any"
/>

El nombre de decrets llei no depèn només de qui governa: els anys amb més decrets coincideixen sovint amb crisis (2012, en plena crisi financera; 2020, amb la pandèmia), i els anys electorals, amb les Corts dissoltes part de l'any, tenen menys lleis i, per tant, un percentatge de decrets llei més alt.

## Quina part de la legislació es fa per decret

Per no dependre de quanta legislació s'aprova cada any, el gràfic mostra el **percentatge de decrets llei sobre el total de normes amb rang de llei** de l'Estat (decrets llei més lleis i lleis orgàniques de les Corts). Un 50 % vol dir que per cada llei aprovada a les Corts el Govern va aprovar un decret llei.

<LineChart
    data={anual_completo}
    x=anio
    y=pct_rdl
    xFmt='0'
    yFmt='0'
    yAxisTitle="% decrets llei"
    title="Decrets llei sobre el total de normes amb rang de llei (%)"
/>

## Per Govern

Cada decret llei s'atribueix al president en exercici el dia que el va aprovar el Consell de Ministres (la data que figura en el títol). Per comparar mandats de durada diferent, la taula dona la **mitjana per any governat**.

<BarChart
    data={presidencias}
    x=presidente
    y=rdl_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0.0'
    title="Decrets llei per any governat, per president"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="President"/>
    <Column id=partido title="Partit"/>
    <Column id=desde title="Des de" fmt='0'/>
    <Column id=hasta title="Fins a"/>
    <Column id=anios title="Anys" fmt='0.0'/>
    <Column id=decretos_ley title="Decrets llei" fmt='0'/>
    <Column id=rdl_por_anio title="Per any" fmt='0.0' contentType=bar barColor="#fca5a5"/>
    <Column id=leyes_por_anio title="Lleis per any" fmt='0.0'/>
    <Column id=pct_rdl title="% decrets llei" fmt='0'/>
    <Column id=derogados title="Derogats" fmt='0'/>
</DataTable>

## Per partit: observats davant esperats

Comptar sense més afavoreix qui menys ha governat. La taula compara els decrets llei de cada partit amb els **esperats** si tots els governs des de 1977 haguessin aprovat decrets llei al mateix ritme, repartits segons el temps que ha governat cadascun. Una ràtio d'1 és el que caldria esperar; 2, el doble; 0,5, la meitat.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partit del president"/>
    <Column id=anios title="Anys governats" fmt='0.0'/>
    <Column id=observados title="Observats" fmt='0'/>
    <Column id=esperados title="Esperats pel temps governat" fmt='0.0'/>
    <Column id=ratio title="Observats / esperats" fmt='0.00'/>
    <Column id=pct_rdl title="% decrets llei" fmt='0'/>
</DataTable>

El PSOE ha aprovat {formatNumber(partidos_resumen[0]?.psoe, 2)} vegades els decrets llei que li correspondrien pel temps governat, el PP {formatNumber(partidos_resumen[0]?.pp, 2)} vegades i la UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. Aquesta comparació té una limitació important: l'ús del decret llei **ha crescut amb els anys**, de manera que els governs més recents en surten perjudicats davant dels primers. Per això convé mirar també la comparació dins de la mateixa època: des de 1997, en els anys complets governats per un sol president, PP i PSOE s'han alternat al poder.

<DataTable data={decadas} rows=all>
    <Column id=partido title="Partit del president"/>
    <Column id=anios title="Anys complets (1997-)" fmt='0'/>
    <Column id=rdl_por_anio title="Decrets llei per any" fmt='0.0'/>
    <Column id=pct_rdl title="% decrets llei" fmt='0'/>
</DataTable>

## Convalidats i derogats

El Congrés ha de votar cada decret llei en els 30 dies hàbils següents a la seva publicació. Si el **convalida**, continua en vigor (i a més el pot tramitar com a projecte de llei per esmenar-lo); si el **deroga**, deixa d'estar en vigor. Des de 1979, el Congrés ha derogat {formatNumber(estados_resumen[0]?.derogados, 0)} decrets llei. En {formatNumber(estados_resumen[0]?.sin_resolucion, 0)} casos no s'ha trobat al BOE la resolució del Congrés: {formatNumber(estados_resumen[0]?.recientes, 0)} són dels últims 60 dies (pendents de votació) i la resta, sobretot dels primers anys, quan la resolució no sempre es publicava al BOE amb aquest títol.

<DataTable data={derogados} rows=all link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decret llei"/>
    <Column id=fecha_disposicion title="Data" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="President"/>
    <Column id=partido title="Partit"/>
    <Column id=titulo title="Títol" wrap=true/>
</DataTable>

## Tots els decrets llei

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decret llei"/>
    <Column id=fecha_disposicion title="Data" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="President"/>
    <Column id=partido title="Partit"/>
    <Column id=estado title="Congrés"/>
    <Column id=titulo title="Títol" wrap=true/>
</DataTable>

## Metodologia i fonts

- **Font:** sumaris diaris del [Butlletí Oficial de l'Estat](https://www.boe.es/datosabiertos/), API de dades obertes, des de juliol de 1977. Es prenen els reials decrets llei i les lleis de la secció I (Prefectura de l'Estat) i les resolucions del Congrés dels Diputats que ordenen publicar la convalidació o derogació de cada decret llei. Cada norma es compta una vegada encara que el BOE la publiqui en diverses parts.
- **Data i Govern:** la data és la de la disposició (la del Consell de Ministres, que figura en el títol), no la de publicació; el decret s'atribueix al president en exercici aquell dia, també si estava en funcions. Presidències: Adolfo Suárez (UCD) fins al 26 de febrer de 1981, Leopoldo Calvo-Sotelo (UCD), Felipe González (PSOE), José María Aznar (PP), José Luis Rodríguez Zapatero (PSOE), Mariano Rajoy (PP) i Pedro Sánchez (PSOE; en coalició amb Unidas Podemos i després Sumar des de gener de 2020).
- **Rang de llei:** el percentatge compara decrets llei amb lleis i lleis orgàniques de les Corts (inclosa la de pressupostos). No inclou els decrets legislatius (textos refosos que el Govern aprova per delegació de les Corts) ni les lleis autonòmiques.
- **Esperats:** total de decrets llei des del 5 de juliol de 1977 multiplicat per la part d'aquest temps que va governar cada partit. Suposa un ritme constant, cosa que no passa (vegeu el text).
- **Convalidació:** abans de la Constitució (29 de desembre de 1978) els decrets llei no necessitaven convalidació del Congrés; per això els recomptes d'estat comencen el 1979.
- **Comparació internacional:** no s'inclou. Cada país té figures diferents (decreti-legge a Itàlia, ordonnances a França, medidas provisórias al Brasil...) i no hi ha una estadística oficial homogènia.
