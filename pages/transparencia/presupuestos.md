---
title: Presupuestos prorrogados
description: "Qué años ha tenido España Presupuestos Generales del Estado aprobados a tiempo, cuáles llegaron tarde y cuáles se prorrogaron, con cuántos días de retraso y qué Gobierno debía presentarlos, desde 1978."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    const coloresSituacion = { 'A tiempo': '#16a34a', 'Tarde': '#f59e0b', 'Prorrogado': '#dc2626', 'Prorrogado (en curso)': '#fca5a5' };
</script>

```sql ejercicios
SELECT
    CAST(ejercicio AS INTEGER) AS ejercicio,
    situacion,
    coalesce(ley, '') AS ley,
    fecha_publicacion,
    CAST(dias_prorroga AS INTEGER) AS dias_prorroga,
    en_plazo,
    en_curso,
    presidente_responsable,
    partido_responsable,
    presidente_1_enero,
    coalesce(url_html, '') AS url_html
FROM mother.gobierno_presupuestos
ORDER BY ejercicio
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

# 🧾 Presupuestos Generales del Estado: a tiempo, tarde o prorrogados

Los Presupuestos Generales del Estado son la ley que fija cada año cuánto puede gastar el Estado y en qué, y cuánto prevé ingresar. La Constitución obliga al Gobierno a presentar el proyecto en el Congreso **al menos tres meses antes** de que acabe el año (art. 134.3), para que las Cortes lo aprueben antes del 1 de enero. Si no llega a tiempo, los presupuestos del año anterior **se prorrogan automáticamente** hasta que se aprueben los nuevos (art. 134.4). Esta página cuenta, con el Boletín Oficial del Estado, cuántos ejercicios han empezado sin presupuesto propio y qué Gobierno debía presentarlo.

<Grid cols=4>
    <KpiCard
        title="Presupuestos de {resumen[0]?.actual}"
        value={resumen[0]?.dias_actual}
        formattedValue={resumen[0]?.situacion_actual}
        period="{formatNumber(racha[0]?.seguidos, 0)} ejercicios seguidos sin ley propia, desde {racha[0]?.desde} · {formatNumber(resumen[0]?.dias_actual, 0)} días de prórroga este año"
        source="BOE"
        sparklineData={serie.map(d => d.dias_prorroga)}
    />
    <KpiCard
        title="Último presupuesto aprobado a tiempo"
        value={resumen[0]?.ultimo_a_tiempo}
        formattedValue={resumen[0]?.ultimo_a_tiempo}
        period="publicado en el BOE antes del 1 de enero de ese año"
        source="BOE"
    />
    <KpiCard
        title="Ejercicios sin presupuesto el 1 de enero"
        value={resumen[0]?.ejercicios - resumen[0]?.a_tiempo}
        formattedValue="{formatNumber(resumen[0]?.ejercicios - resumen[0]?.a_tiempo, 0)} de {formatNumber(resumen[0]?.ejercicios, 0)}"
        period="desde 1978: {formatNumber(resumen[0]?.tarde, 0)} aprobados tarde y {formatNumber(resumen[0]?.prorrogados, 0)} prorrogados (incluido el actual)"
        source="BOE"
    />
    <KpiCard
        title="Últimos diez ejercicios"
        value={resumen[0]?.sin_ley_10}
        formattedValue="{formatNumber(resumen[0]?.sin_ley_10, 0)} de 10"
        period="empezaron sin presupuesto propio"
        source="BOE"
    />
</Grid>

## Cada ejercicio, desde 1978

Días de cada año en que el Estado funcionó con los presupuestos del año anterior prorrogados: 0 si la ley se publicó antes del 1 de enero, el año entero si no llegó a aprobarse. {resumen[0]?.actual} cuenta los días transcurridos hasta hoy.

<BarChart
    data={serie}
    x=ejercicio
    y=dias_prorroga
    series=situacion
    xFmt='0'
    seriesColors={coloresSituacion}
    yAxisTitle="Días de prórroga"
    title="Días de cada ejercicio sin Ley de Presupuestos propia en vigor"
/>

Los retrasos de medio año se concentran en los ejercicios con elecciones generales o cambio de Gobierno cerca del otoño anterior (1979, 1983, 1990, 2012 y 2017): el Gobierno saliente no presenta el proyecto o las Cortes se disuelven antes de votarlo, y el nuevo Gobierno aprueba el presupuesto a mitad de año. En 2018 el retraso se debió a la falta de apoyos en el Congreso. Los ejercicios prorrogados enteros son aquellos en que el Congreso rechazó el proyecto o el Gobierno no llegó a presentarlo.

## Por Gobierno

Cada ejercicio se atribuye al presidente que **debía presentar el proyecto**: el que estaba en funciones el 30 de septiembre del año anterior, cuando vence el plazo constitucional. La última columna de la tabla completa muestra además quién gobernaba el 1 de enero, que es quien gestiona la prórroga.

<DataTable data={presidentes} rows=all>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=ejercicios title="Ejercicios que debía presentar" fmt='0'/>
    <Column id=a_tiempo title="A tiempo" fmt='0'/>
    <Column id=tarde title="Tarde" fmt='0'/>
    <Column id=prorrogados title="Prorrogados" fmt='0'/>
    <Column id=pct_sin_ley title="% sin ley el 1 de enero" fmt='0' contentType=bar barColor="#fca5a5"/>
    <Column id=dias_medios title="Días de prórroga por ejercicio" fmt='0'/>
</DataTable>

## Por partido: observados frente a esperados

Los **esperados** son los ejercicios sin presupuesto el 1 de enero que le corresponderían a cada partido si todos los Gobiernos hubieran fallado al mismo ritmo, según el número de ejercicios que le tocaba presentar a cada uno. Una ratio de 1 es lo esperable; 2, el doble; 0,5, la mitad.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partido del presidente"/>
    <Column id=ejercicios title="Ejercicios que debía presentar" fmt='0'/>
    <Column id=observados title="Sin ley el 1 de enero" fmt='0'/>
    <Column id=esperados title="Esperados" fmt='0.0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
</DataTable>

El PSOE está en {formatNumber(partidos_resumen[0]?.psoe, 2)} veces lo esperado, el PP en {formatNumber(partidos_resumen[0]?.pp, 2)} y UCD en {formatNumber(partidos_resumen[0]?.ucd, 2)}. {partidos_resumen[0]?.z_max >= 1.96 ? 'Entre PSOE y PP la diferencia es mayor de la que explicaría el azar, aunque con pocos ejercicios.' : 'Con tan pocos ejercicios, la diferencia entre PSOE y PP no es mayor de la que podría explicar el azar.'} Que un presupuesto salga adelante depende sobre todo de que el Gobierno tenga mayoría en el Congreso, y los Gobiernos en minoría o con el Parlamento fragmentado han sido más frecuentes desde 2016.

## Todos los ejercicios

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=ejercicio title="Ejercicio" fmt='0'/>
    <Column id=situacion title="Situación"/>
    <Column id=ley title="Ley"/>
    <Column id=fecha_publicacion title="Publicada en el BOE" fmt='dd/mm/yyyy'/>
    <Column id=dias_prorroga title="Días de prórroga" fmt='0'/>
    <Column id=presidente_responsable title="Debía presentarlos"/>
    <Column id=presidente_1_enero title="Gobernaba el 1 de enero"/>
</DataTable>

## Metodología y fuentes

- **Fuente:** sumarios diarios del [Boletín Oficial del Estado](https://www.boe.es/datosabiertos/), API de datos abiertos: las leyes cuyo título es «Ley N/AAAA, de ..., de Presupuestos Generales del Estado para el año ...». Si una ley se publicó en varias partes, cuenta la fecha de la primera. No se cuentan las leyes que modifican o amplían un presupuesto ya aprobado.
- **Prórroga automática (art. 134.4 de la Constitución):** si la Ley de Presupuestos no se aprueba antes del primer día del ejercicio, se consideran automáticamente prorrogados los del ejercicio anterior hasta que se aprueben los nuevos. La prórroga mantiene los créditos del año anterior, pero no permite nuevas políticas de gasto que necesiten crédito propio, y las actualizaciones (pensiones, sueldos públicos) se hacen por real decreto-ley.
- **Situación:** «A tiempo» = ley publicada en el BOE antes del 1 de enero del ejercicio; «Tarde» = publicada durante el ejercicio; «Prorrogado» = el ejercicio terminó sin ley propia. Días de prórroga: del 1 de enero a la publicación de la ley (el año entero si no la hubo; hasta hoy en el ejercicio en curso).
- **Atribución:** al presidente en funciones el 30 de septiembre del año anterior, fecha en que vence el plazo del art. 134.3 para presentar el proyecto. Es una elección discutible cuando el Gobierno cambia en otoño o invierno (ejercicios 1983 y 2012): la tabla completa da también el presidente del 1 de enero.
- **Esperados:** total de ejercicios sin ley el 1 de enero desde 1978, repartido según los ejercicios que debía presentar cada partido. Supone que todos los Gobiernos tenían la misma probabilidad de fallar, cosa que no ocurre (la mayoría parlamentaria importa mucho).
- **Comparación internacional:** no se incluye; las reglas de prórroga o de cierre del Estado sin presupuesto cambian de un país a otro y no hay una estadística oficial homogénea.
