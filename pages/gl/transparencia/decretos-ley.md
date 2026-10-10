---
i18n_origen: 2922ec7a33e0
title: Decretos lei
description: "Cantos reais decretos lei aproba cada Goberno de España desde 1977, que parte das normas con rango de lei se fan por decreto, cantos convalida ou derroga o Congreso e como se compara cada partido segundo o tempo que gobernou."
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

# 📜 Decretos lei: gobernar por decreto

O **real decreto lei** é unha norma con rango de lei que aproba o Goberno, non as Cortes. A Constitución (art. 86) só o permite en caso de **extraordinaria e urxente necesidade**, prohíbelle tocar certas materias (dereitos fundamentais, institucións do Estado, réxime electoral...) e obriga a que o Congreso o **convalide ou o derrogue** nos 30 días hábiles seguintes. Esta páxina conta, co Boletín Oficial do Estado, cantos aproba cada Goberno e que parte da lexislación se fai por esta vía.

<Grid cols=4>
    <KpiCard
        title="Decretos lei en {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.rdl_ultimo}
        formattedValue={formatNumber(resumen[0]?.rdl_ultimo, 0)}
        period="media desde 1979: {formatNumber(resumen[0]?.media_rdl, 1)} ao ano · {formatNumber(resumen[0]?.rdl_en_curso, 0)} no que vai de {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.decretos_ley}))}
    />
    <KpiCard
        title="Parte das normas con rango de lei"
        value={resumen[0]?.pct_ultimo}
        formattedValue="{formatNumber(resumen[0]?.pct_ultimo, 0)} %"
        period="decretos lei sobre decretos lei + leis en {resumen[0]?.ultimo_anio} · {formatNumber(resumen[0]?.pct_historico, 0)} % desde 1979"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.pct_rdl}))}
    />
    <KpiCard
        title="Ritmo do Goberno actual"
        value={actual[0]?.rdl_por_anio}
        formattedValue={formatNumber(actual[0]?.rdl_por_anio, 1)}
        unit="ao ano"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.decretos_ley, 0)} decretos lei desde {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Derrogados polo Congreso"
        value={estados_resumen[0]?.derogados}
        formattedValue={formatNumber(estados_resumen[0]?.derogados, 0)}
        period="de {formatNumber(estados_resumen[0]?.total, 0)} decretos lei desde 1979; o resto convalidouse ou está pendente"
        source="BOE (resolucións do Congreso)"
    />
</Grid>

## Cantos se aproban cada ano

Decretos lei aprobados cada ano, coloreados segundo o partido do presidente que máis tempo gobernou ese ano. {resumen[0]?.anio_en_curso} só inclúe o que vai de ano.

<BarChart
    data={anual}
    x=anio
    y=decretos_ley
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Decretos lei"
    title="Reais decretos lei aprobados por ano"
/>

O número de decretos lei non depende só de quen goberna: os anos con máis decretos coinciden a miúdo con crises (2012, en plena crise financeira; 2020, coa pandemia), e os anos electorais, coas Cortes disoltas parte do ano, teñen menos leis e, polo tanto, unha porcentaxe de decretos lei máis alta.

## Que parte da lexislación se fai por decreto

Para non depender de canta lexislación se aproba cada ano, a gráfica mostra a **porcentaxe de decretos lei sobre o total de normas con rango de lei** do Estado (decretos lei máis leis e leis orgánicas das Cortes). Un 50 % significa que por cada lei aprobada nas Cortes o Goberno aprobou un decreto lei.

<LineChart
    data={anual_completo}
    x=anio
    y=pct_rdl
    xFmt='0'
    yFmt='0'
    yAxisTitle="% decretos lei"
    title="Decretos lei sobre o total de normas con rango de lei (%)"
/>

## Por Goberno

Cada decreto lei atribúeselle ao presidente en exercicio o día en que o aprobou o Consello de Ministros (a data que figura no seu título). Para comparar mandatos de distinta duración, a táboa dá a **media por ano gobernado**.

<BarChart
    data={presidencias}
    x=presidente
    y=rdl_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0.0'
    title="Decretos lei por ano gobernado, por presidente"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=desde title="Desde" fmt='0'/>
    <Column id=hasta title="Ata"/>
    <Column id=anios title="Anos" fmt='0.0'/>
    <Column id=decretos_ley title="Decretos lei" fmt='0'/>
    <Column id=rdl_por_anio title="Por ano" fmt='0.0' contentType=bar barColor="#fca5a5"/>
    <Column id=leyes_por_anio title="Leis por ano" fmt='0.0'/>
    <Column id=pct_rdl title="% decretos lei" fmt='0'/>
    <Column id=derogados title="Derrogados" fmt='0'/>
</DataTable>

## Por partido: observados fronte a esperados

Contar sen máis favorece a quen menos gobernou. A táboa compara os decretos lei de cada partido cos **esperados** se todos os Gobernos desde 1977 aprobasen decretos lei ao mesmo ritmo, repartidos segundo o tempo que gobernou cada un. Unha ratio de 1 é o esperable; 2, o dobre; 0,5, a metade.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partido do presidente"/>
    <Column id=anios title="Anos gobernados" fmt='0.0'/>
    <Column id=observados title="Observados" fmt='0'/>
    <Column id=esperados title="Esperados polo tempo gobernado" fmt='0.0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
    <Column id=pct_rdl title="% decretos lei" fmt='0'/>
</DataTable>

O PSOE aprobou {formatNumber(partidos_resumen[0]?.psoe, 2)} veces os decretos lei que lle corresponderían polo tempo gobernado, o PP {formatNumber(partidos_resumen[0]?.pp, 2)} veces e UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. Esta comparación ten unha limitación importante: o uso do decreto lei **medrou cos anos**, así que os Gobernos máis recentes saen prexudicados fronte aos primeiros. Por iso convén mirar tamén a comparación dentro da mesma época: desde 1997, nos anos completos gobernados por un só presidente, PP e PSOE alternáronse no poder.

<DataTable data={decadas} rows=all>
    <Column id=partido title="Partido do presidente"/>
    <Column id=anios title="Anos completos (1997-)" fmt='0'/>
    <Column id=rdl_por_anio title="Decretos lei por ano" fmt='0.0'/>
    <Column id=pct_rdl title="% decretos lei" fmt='0'/>
</DataTable>

## Convalidados e derrogados

O Congreso debe votar cada decreto lei nos 30 días hábiles seguintes á súa publicación. Se o **convalida**, segue en vigor (e pode ademais tramitalo como proxecto de lei para emendalo); se o **derroga**, deixa de estar en vigor. Desde 1979, o Congreso derrogou {formatNumber(estados_resumen[0]?.derogados, 0)} decretos lei. En {formatNumber(estados_resumen[0]?.sin_resolucion, 0)} casos non se atopou no BOE a resolución do Congreso: {formatNumber(estados_resumen[0]?.recientes, 0)} son dos últimos 60 días (pendentes de votación) e o resto, sobre todo dos primeiros anos, cando a resolución non sempre se publicaba no BOE con ese título.

<DataTable data={derogados} rows=all link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decreto lei"/>
    <Column id=fecha_disposicion title="Data" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=titulo title="Título" wrap=true/>
</DataTable>

## Todos os decretos lei

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decreto lei"/>
    <Column id=fecha_disposicion title="Data" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=estado title="Congreso"/>
    <Column id=titulo title="Título" wrap=true/>
</DataTable>

## Metodoloxía e fontes

- **Fonte:** sumarios diarios do [Boletín Oficial do Estado](https://www.boe.es/datosabiertos/), API de datos abertos, desde xullo de 1977. Tómanse os reais decretos lei e as leis da sección I (Xefatura do Estado) e as resolucións do Congreso dos Deputados que ordenan publicar a convalidación ou derrogación de cada decreto lei. Cada norma cóntase unha vez aínda que o BOE a publique en varias partes.
- **Data e Goberno:** a data é a da disposición (a do Consello de Ministros, que figura no título), non a de publicación; o decreto atribúeselle ao presidente en exercicio ese día, tamén se estaba en funcións. Presidencias: Adolfo Suárez (UCD) ata o 26 de febreiro de 1981, Leopoldo Calvo-Sotelo (UCD), Felipe González (PSOE), José María Aznar (PP), José Luis Rodríguez Zapatero (PSOE), Mariano Rajoy (PP) e Pedro Sánchez (PSOE; en coalición con Unidas Podemos e despois Sumar desde xaneiro de 2020).
- **Rango de lei:** a porcentaxe compara decretos lei con leis e leis orgánicas das Cortes (incluída a de orzamentos). Non inclúe os decretos lexislativos (textos refundidos que o Goberno aproba por delegación das Cortes) nin as leis autonómicas.
- **Esperados:** total de decretos lei desde o 5 de xullo de 1977 multiplicado pola parte dese tempo que gobernou cada partido. Supón un ritmo constante, cousa que non ocorre (ver o texto).
- **Convalidación:** antes da Constitución (29 de decembro de 1978) os decretos lei non necesitaban convalidación do Congreso; por iso as contas de estado comezan en 1979.
- **Comparación internacional:** non se inclúe. Cada país ten figuras distintas (decreti-legge en Italia, ordonnances en Francia, medidas provisórias no Brasil...) e non hai unha estatística oficial homoxénea.
