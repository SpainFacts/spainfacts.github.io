---
title: Indults
description: "Quants indults concedeix cada Govern d'Espanya des de 1977 segons el BOE, la seva evolució i com es compara cada president i cada partit segons el temps que ha governat."
i18n_origen: 774383d84eca
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

# ⚖️ Indults

L'**indult** és la gràcia per la qual el Govern perdona, totalment o parcialment, la pena imposada per una sentència ferma. El concedeix el Consell de Ministres mitjançant un reial decret, a proposta del Ministeri de Justícia i després d'un informe del tribunal que va dictar la sentència (Llei de 18 de juny de 1870, reformada el 1988 i el 2015). La Constitució prohibeix els indults generals (art. 62.i): tots són individuals i tots es publiquen al Butlletí Oficial de l'Estat. Aquesta pàgina els compta.

<Grid cols=4>
    <KpiCard
        title="Indults el {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.ultimo}
        formattedValue={formatNumber(resumen[0]?.ultimo, 0)}
        period="{formatNumber(resumen[0]?.en_curso, 0)} en el que va de {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => d.indultos)}
    />
    <KpiCard
        title="Mitjana dels últims deu anys"
        value={resumen[0]?.media_10}
        formattedValue={formatNumber(resumen[0]?.media_10, 0)}
        unit="l'any"
        period="davant {formatNumber(resumen[0]?.media_9605, 0)} l'any entre 1996 i 2005"
        source="BOE"
    />
    <KpiCard
        title="Ritme del Govern actual"
        value={actual[0]?.indultos_por_anio}
        formattedValue={formatNumber(actual[0]?.indultos_por_anio, 0)}
        unit="l'any"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.indultos, 0)} indults des de {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Any amb més indults"
        value={resumen[0]?.maximo}
        formattedValue={formatNumber(resumen[0]?.maximo, 0)}
        period="el {resumen[0]?.anio_maximo} · {formatNumber(resumen[0]?.total, 0)} en total des de 1978"
        source="BOE"
    />
</Grid>

## Quants se'n concedeixen cada any

Reials decrets d'indult per any d'aprovació al Consell de Ministres, acolorits segons el partit del president que més temps va governar aquell any. {resumen[0]?.anio_en_curso} només inclou el que va d'any.

<BarChart
    data={anual}
    x=anio
    y=indultos
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Indults"
    title="Indults concedits per any"
/>

La sèrie té pics puntuals d'indults aprovats en tandes: el més gran, el desembre de {pico[0]?.anio}, amb {formatNumber(pico[0]?.indultos, 0)} reials decrets d'indult aprovats en un sol mes. Des de {minimos[0]?.desde} no s'han superat els 100 indults en cap any, els nivells més baixos de tota la sèrie.

## Per Govern

Cada indult s'atribueix al president en exercici el dia que el Consell de Ministres va aprovar el reial decret. Per comparar mandats de durada diferent, la taula dona la **mitjana per any governat**.

<BarChart
    data={presidencias}
    x=presidente
    y=indultos_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0'
    title="Indults per any governat, per president"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="President"/>
    <Column id=partido title="Partit"/>
    <Column id=desde title="Des de" fmt='0'/>
    <Column id=hasta title="Fins a"/>
    <Column id=anios title="Anys" fmt='0.0'/>
    <Column id=indultos title="Indults" fmt='0'/>
    <Column id=indultos_por_anio title="Per any" fmt='0' contentType=bar barColor="#c4b5fd"/>
    <Column id=ratio title="Observats / esperats" fmt='0.00'/>
</DataTable>

## Per partit: observats davant esperats

Els **esperats** són els indults que correspondrien a cada partit si tots els governs des de 1977 haguessin indultat al mateix ritme, segons el temps que ha governat cadascun. Una ràtio d'1 és el que caldria esperar; 2, el doble; 0,5, la meitat.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partit del president"/>
    <Column id=anios title="Anys governats" fmt='0.0'/>
    <Column id=observados title="Observats" fmt='0'/>
    <Column id=esperados title="Esperats pel temps governat" fmt='0'/>
    <Column id=ratio title="Observats / esperats" fmt='0.00'/>
    <Column id=indultos_por_anio title="Per any" fmt='0'/>
</DataTable>

Amb aquest càlcul, el PSOE ha concedit {formatNumber(partidos_resumen[0]?.psoe, 2)} vegades els indults esperats pel temps governat, el PP {formatNumber(partidos_resumen[0]?.pp, 2)} vegades i la UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. Igual que amb qualsevol sèrie llarga, el ritme no ha estat constant: el nombre de condemnats, les lleis penals i el criteri dels tribunals a l'hora d'informar han canviat molt des de 1977. Per això convé mirar també la comparació dins d'una mateixa època: des de 1997, en els anys complets governats per un sol president.

<DataTable data={misma_epoca} rows=all>
    <Column id=partido title="Partit del president"/>
    <Column id=anios title="Anys complets (1997-)" fmt='0'/>
    <Column id=indultos_por_anio title="Indults per any (mitjana)" fmt='0'/>
    <Column id=mediana title="Mediana" fmt='0'/>
</DataTable>

## Metodologia i fonts

- **Font:** sumaris diaris del [Butlletí Oficial de l'Estat](https://www.boe.es/datosabiertos/), API de dades obertes, des de juliol de 1977: reials decrets de la secció III («Altres disposicions»), epígraf «Indults», el títol dels quals diu «por el que se indulta» o «por el que se conmuta». No es compten les correccions d'errors.
- **Què es compta:** reials decrets d'indult, no persones. Alguns decrets indulten diverses persones i alguna persona rep més d'un indult. No es distingeix entre indult total i parcial (el BOE ho diu en el text del decret, no en el títol). El nom de les persones indultades no es desa.
- **Data i Govern:** la data és la del reial decret (la del Consell de Ministres, que figura en el títol), no la de publicació, que pot arribar setmanes després; s'atribueix al president en exercici aquell dia, també si estava en funcions. En els pocs títols sense data (1977-1978) es fa servir la de publicació.
- **Esperats:** total d'indults des del 5 de juliol de 1977 multiplicat per la part d'aquest temps que va governar cada partit. Suposa un ritme constant, cosa que no passa (vegeu el text).
- **Comparació internacional:** no s'inclou; la figura de l'indult i la seva publicació canvien molt d'un país a l'altre i no hi ha una estadística oficial homogènia.
