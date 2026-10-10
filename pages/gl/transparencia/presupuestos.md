---
i18n_origen: 1b5c090de484
title: Orzamentos prorrogados
description: "Que anos tivo España Orzamentos Xerais do Estado aprobados a tempo, cales chegaron tarde e cales se prorrogaron, con cantos días de atraso e que Goberno debía presentalos, desde 1978."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const coloresSituacion = { 'A tiempo': '#16a34a', 'Tarde': '#f59e0b', 'Prorrogado': '#dc2626', 'Prorrogado (en curso)': '#fca5a5' };
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

# 🧾 Orzamentos Xerais do Estado: a tempo, tarde ou prorrogados

Os Orzamentos Xerais do Estado son a lei que fixa cada ano canto pode gastar o Estado e en que, e canto prevé ingresar. A Constitución obriga o Goberno a presentar o proxecto no Congreso **polo menos tres meses antes** de que remate o ano (art. 134.3), para que as Cortes o aproben antes do 1 de xaneiro. Se non chega a tempo, os orzamentos do ano anterior **prorróganse automaticamente** ata que se aproben os novos (art. 134.4). Esta páxina conta, co Boletín Oficial do Estado, cantos exercicios comezaron sen orzamento propio e que Goberno debía presentalo.

<Grid cols=4>
    <KpiCard
        title="Orzamentos de {resumen[0]?.actual}"
        value={resumen[0]?.dias_actual}
        formattedValue={resumen[0]?.situacion_actual}
        period="{formatNumber(racha[0]?.seguidos, 0)} exercicios seguidos sen lei propia, desde {racha[0]?.desde} · {formatNumber(resumen[0]?.dias_actual, 0)} días de prórroga este ano"
        source="BOE"
        sparklineData={serie.map(d => ({...d, y: d.dias_prorroga}))}
    />
    <KpiCard
        title="Último orzamento aprobado a tempo"
        value={resumen[0]?.ultimo_a_tiempo}
        formattedValue={resumen[0]?.ultimo_a_tiempo}
        period="publicado no BOE antes do 1 de xaneiro dese ano"
        source="BOE"
    />
    <KpiCard
        title="Exercicios sen orzamento o 1 de xaneiro"
        value={resumen[0]?.ejercicios - resumen[0]?.a_tiempo}
        formattedValue="{formatNumber(resumen[0]?.ejercicios - resumen[0]?.a_tiempo, 0)} de {formatNumber(resumen[0]?.ejercicios, 0)}"
        period="desde 1978: {formatNumber(resumen[0]?.tarde, 0)} aprobados tarde e {formatNumber(resumen[0]?.prorrogados, 0)} prorrogados (incluído o actual)"
        source="BOE"
    />
    <KpiCard
        title="Últimos dez exercicios"
        value={resumen[0]?.sin_ley_10}
        formattedValue="{formatNumber(resumen[0]?.sin_ley_10, 0)} de 10"
        period="comezaron sen orzamento propio"
        source="BOE"
    />
</Grid>

## Cada exercicio, desde 1978

Días de cada ano en que o Estado funcionou cos orzamentos do ano anterior prorrogados: 0 se a lei se publicou antes do 1 de xaneiro, o ano enteiro se non chegou a aprobarse. {resumen[0]?.actual} conta os días transcorridos ata hoxe.

<BarChart
    data={serie}
    x=ejercicio
    y=dias_prorroga
    series=situacion
    xFmt='0'
    seriesColors={coloresSituacion}
    yAxisTitle="Días de prórroga"
    title="Días de cada exercicio sen Lei de Orzamentos propia en vigor"
/>

Os atrasos de medio ano concéntranse nos exercicios con eleccións xerais ou cambio de Goberno preto do outono anterior (1979, 1983, 1990, 2012 e 2017): o Goberno saínte non presenta o proxecto ou as Cortes disólvense antes de votalo, e o novo Goberno aproba o orzamento a metade de ano. En 2018 o atraso debeuse á falta de apoios no Congreso. Os exercicios prorrogados enteiros son aqueles en que o Congreso rexeitou o proxecto ou o Goberno non chegou a presentalo.

## Por Goberno

Cada exercicio atribúeselle ao presidente que **debía presentar o proxecto**: o que estaba en funcións o 30 de setembro do ano anterior, cando vence o prazo constitucional. A última columna da táboa completa mostra ademais quen gobernaba o 1 de xaneiro, que é quen xestiona a prórroga.

<DataTable data={presidentes} rows=all>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=ejercicios title="Exercicios que debía presentar" fmt='0'/>
    <Column id=a_tiempo title="A tempo" fmt='0'/>
    <Column id=tarde title="Tarde" fmt='0'/>
    <Column id=prorrogados title="Prorrogados" fmt='0'/>
    <Column id=pct_sin_ley title="% sen lei o 1 de xaneiro" fmt='0' contentType=bar barColor="#fca5a5"/>
    <Column id=dias_medios title="Días de prórroga por exercicio" fmt='0'/>
</DataTable>

## Por partido: observados fronte a esperados

Os **esperados** son os exercicios sen orzamento o 1 de xaneiro que lle corresponderían a cada partido se todos os Gobernos fallasen ao mesmo ritmo, segundo o número de exercicios que lle tocaba presentar a cada un. Unha ratio de 1 é o esperable; 2, o dobre; 0,5, a metade.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partido do presidente"/>
    <Column id=ejercicios title="Exercicios que debía presentar" fmt='0'/>
    <Column id=observados title="Sen lei o 1 de xaneiro" fmt='0'/>
    <Column id=esperados title="Esperados" fmt='0.0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
</DataTable>

O PSOE está en {formatNumber(partidos_resumen[0]?.psoe, 2)} veces o esperado, o PP en {formatNumber(partidos_resumen[0]?.pp, 2)} e UCD en {formatNumber(partidos_resumen[0]?.ucd, 2)}. {partidos_resumen[0]?.z_max >= 1.96 ? 'Entre PSOE e PP a diferenza é maior da que explicaría o azar, aínda que con poucos exercicios.' : 'Con tan poucos exercicios, a diferenza entre PSOE e PP non é maior da que podería explicar o azar.'} Que un orzamento saia adiante depende sobre todo de que o Goberno teña maioría no Congreso, e os Gobernos en minoría ou co Parlamento fragmentado foron máis frecuentes desde 2016.

## Todos os exercicios

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=ejercicio title="Exercicio" fmt='0'/>
    <Column id=situacion title="Situación"/>
    <Column id=ley title="Lei"/>
    <Column id=fecha_publicacion title="Publicada no BOE" fmt='dd/mm/yyyy'/>
    <Column id=dias_prorroga title="Días de prórroga" fmt='0'/>
    <Column id=presidente_responsable title="Debía presentalos"/>
    <Column id=presidente_1_enero title="Gobernaba o 1 de xaneiro"/>
</DataTable>

## Metodoloxía e fontes

- **Fonte:** sumarios diarios do [Boletín Oficial do Estado](https://www.boe.es/datosabiertos/), API de datos abertos: as leis cuxo título é «Ley N/AAAA, de ..., de Presupuestos Generales del Estado para el año ...». Se unha lei se publicou en varias partes, conta a data da primeira. Non se contan as leis que modifican ou amplían un orzamento xa aprobado.
- **Prórroga automática (art. 134.4 da Constitución):** se a Lei de Orzamentos non se aproba antes do primeiro día do exercicio, considéranse automaticamente prorrogados os do exercicio anterior ata que se aproben os novos. A prórroga mantén os créditos do ano anterior, pero non permite novas políticas de gasto que necesiten crédito propio, e as actualizacións (pensións, soldos públicos) fanse por real decreto lei.
- **Situación:** «A tempo» = lei publicada no BOE antes do 1 de xaneiro do exercicio; «Tarde» = publicada durante o exercicio; «Prorrogado» = o exercicio rematou sen lei propia. Días de prórroga: do 1 de xaneiro á publicación da lei (o ano enteiro se non a houbo; ata hoxe no exercicio en curso).
- **Atribución:** ao presidente en funcións o 30 de setembro do ano anterior, data en que vence o prazo do art. 134.3 para presentar o proxecto. É unha elección discutible cando o Goberno cambia no outono ou no inverno (exercicios 1983 e 2012): a táboa completa dá tamén o presidente do 1 de xaneiro.
- **Esperados:** total de exercicios sen lei o 1 de xaneiro desde 1978, repartido segundo os exercicios que debía presentar cada partido. Supón que todos os Gobernos tiñan a mesma probabilidade de fallar, cousa que non ocorre (a maioría parlamentaria importa moito).
- **Comparación internacional:** non se inclúe; as regras de prórroga ou de peche do Estado sen orzamento cambian dun país a outro e non hai unha estatística oficial homoxénea.
