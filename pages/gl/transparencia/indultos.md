---
i18n_origen: a455aff1d882
title: Indultos
description: "Cantos indultos concede cada Goberno de España desde 1977 segundo o BOE, a súa evolución e como se compara cada presidente e cada partido segundo o tempo que gobernou."
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

# ⚖️ Indultos

O **indulto** é a graza pola que o Goberno perdoa, total ou parcialmente, a pena imposta por unha sentenza firme. Concédeo o Consello de Ministros mediante un real decreto, por proposta do Ministerio de Xustiza e tras un informe do tribunal que ditou a sentenza (Lei do 18 de xuño de 1870, reformada en 1988 e 2015). A Constitución prohibe os indultos xerais (art. 62.i): todos son individuais e todos se publican no Boletín Oficial do Estado. Esta páxina cóntaos.

<Grid cols=4>
    <KpiCard
        title="Indultos en {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.ultimo}
        formattedValue={formatNumber(resumen[0]?.ultimo, 0)}
        period="{formatNumber(resumen[0]?.en_curso, 0)} no que vai de {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.indultos}))}
    />
    <KpiCard
        title="Media dos últimos dez anos"
        value={resumen[0]?.media_10}
        formattedValue={formatNumber(resumen[0]?.media_10, 0)}
        unit="ao ano"
        period="fronte a {formatNumber(resumen[0]?.media_9605, 0)} ao ano entre 1996 e 2005"
        source="BOE"
    />
    <KpiCard
        title="Ritmo do Goberno actual"
        value={actual[0]?.indultos_por_anio}
        formattedValue={formatNumber(actual[0]?.indultos_por_anio, 0)}
        unit="ao ano"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.indultos, 0)} indultos desde {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Ano con máis indultos"
        value={resumen[0]?.maximo}
        formattedValue={formatNumber(resumen[0]?.maximo, 0)}
        period="en {resumen[0]?.anio_maximo} · {formatNumber(resumen[0]?.total, 0)} en total desde 1978"
        source="BOE"
    />
</Grid>

## Cantos se conceden cada ano

Reais decretos de indulto por ano da súa aprobación no Consello de Ministros, coloreados segundo o partido do presidente que máis tempo gobernou ese ano. {resumen[0]?.anio_en_curso} só inclúe o que vai de ano.

<BarChart
    data={anual}
    x=anio
    y=indultos
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Indultos"
    title="Indultos concedidos por ano"
/>

A serie ten picos puntuais de indultos aprobados en fornadas: o maior, en decembro de {pico[0]?.anio}, con {formatNumber(pico[0]?.indultos, 0)} reais decretos de indulto aprobados nun só mes. Desde {minimos[0]?.desde} non se superaron os 100 indultos en ningún ano, os niveis máis baixos de toda a serie.

## Por Goberno

Cada indulto atribúeselle ao presidente en exercicio o día en que o Consello de Ministros aprobou o real decreto. Para comparar mandatos de distinta duración, a táboa dá a **media por ano gobernado**.

<BarChart
    data={presidencias}
    x=presidente
    y=indultos_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0'
    title="Indultos por ano gobernado, por presidente"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=desde title="Desde" fmt='0'/>
    <Column id=hasta title="Ata"/>
    <Column id=anios title="Anos" fmt='0.0'/>
    <Column id=indultos title="Indultos" fmt='0'/>
    <Column id=indultos_por_anio title="Por ano" fmt='0' contentType=bar barColor="#c4b5fd"/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
</DataTable>

## Por partido: observados fronte a esperados

Os **esperados** son os indultos que lle corresponderían a cada partido se todos os Gobernos desde 1977 indultasen ao mesmo ritmo, segundo o tempo que gobernou cada un. Unha ratio de 1 é o esperable; 2, o dobre; 0,5, a metade.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partido do presidente"/>
    <Column id=anios title="Anos gobernados" fmt='0.0'/>
    <Column id=observados title="Observados" fmt='0'/>
    <Column id=esperados title="Esperados polo tempo gobernado" fmt='0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
    <Column id=indultos_por_anio title="Por ano" fmt='0'/>
</DataTable>

Con este cálculo, o PSOE concedeu {formatNumber(partidos_resumen[0]?.psoe, 2)} veces os indultos esperados polo tempo gobernado, o PP {formatNumber(partidos_resumen[0]?.pp, 2)} veces e UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. Igual que con calquera serie longa, o ritmo non foi constante: o número de condenados, as leis penais e o criterio dos tribunais ao informar cambiaron moito desde 1977. Por iso convén mirar tamén a comparación dentro dunha mesma época: desde 1997, nos anos completos gobernados por un só presidente.

<DataTable data={misma_epoca} rows=all>
    <Column id=partido title="Partido do presidente"/>
    <Column id=anios title="Anos completos (1997-)" fmt='0'/>
    <Column id=indultos_por_anio title="Indultos por ano (media)" fmt='0'/>
    <Column id=mediana title="Mediana" fmt='0'/>
</DataTable>

## Metodoloxía e fontes

- **Fonte:** sumarios diarios do [Boletín Oficial do Estado](https://www.boe.es/datosabiertos/), API de datos abertos, desde xullo de 1977: reais decretos da sección III («Otras disposiciones»), epígrafe «Indultos», cuxo título di «por el que se indulta» ou «por el que se conmuta». Non se contan as correccións de erros.
- **Que se conta:** reais decretos de indulto, non persoas. Algúns decretos indultan a varias persoas e algunha persoa recibe máis dun indulto. Non se distingue entre indulto total e parcial (o BOE dío no texto do decreto, non no título). O nome das persoas indultadas non se garda.
- **Data e Goberno:** a data é a do real decreto (a do Consello de Ministros, que figura no título), non a de publicación, que pode chegar semanas despois; atribúeselle ao presidente en exercicio ese día, tamén se estaba en funcións. Nos poucos títulos sen data (1977-1978) úsase a de publicación.
- **Esperados:** total de indultos desde o 5 de xullo de 1977 multiplicado pola parte dese tempo que gobernou cada partido. Supón un ritmo constante, cousa que non ocorre (ver o texto).
- **Comparación internacional:** non se inclúe; a figura do indulto e a súa publicación cambian moito dun país a outro e non hai unha estatística oficial homoxénea.
