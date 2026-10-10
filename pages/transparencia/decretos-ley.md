---
title: Decretos-ley
description: "Cuántos reales decretos-ley aprueba cada Gobierno de España desde 1977, qué parte de las normas con rango de ley se hacen por decreto, cuántos convalida o deroga el Congreso y cómo se compara cada partido según el tiempo que ha gobernado."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 📜 Decretos-ley: gobernar por decreto

El **real decreto-ley** es una norma con rango de ley que aprueba el Gobierno, no las Cortes. La Constitución (art. 86) solo lo permite en caso de **extraordinaria y urgente necesidad**, le prohíbe tocar ciertas materias (derechos fundamentales, instituciones del Estado, régimen electoral...) y obliga a que el Congreso lo **convalide o lo derogue** en los 30 días hábiles siguientes. Esta página cuenta, con el Boletín Oficial del Estado, cuántos aprueba cada Gobierno y qué parte de la legislación se hace por esta vía.

<Grid cols=4>
    <KpiCard
        title="Decretos-ley en {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.rdl_ultimo}
        formattedValue={formatNumber(resumen[0]?.rdl_ultimo, 0)}
        period="media desde 1979: {formatNumber(resumen[0]?.media_rdl, 1)} al año · {formatNumber(resumen[0]?.rdl_en_curso, 0)} en lo que va de {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.decretos_ley}))}
    />
    <KpiCard
        title="Parte de las normas con rango de ley"
        value={resumen[0]?.pct_ultimo}
        formattedValue="{formatNumber(resumen[0]?.pct_ultimo, 0)} %"
        period="decretos-ley sobre decretos-ley + leyes en {resumen[0]?.ultimo_anio} · {formatNumber(resumen[0]?.pct_historico, 0)} % desde 1979"
        source="BOE"
        sparklineData={anual_completo.map(d => ({...d, y: d.pct_rdl}))}
    />
    <KpiCard
        title="Ritmo del Gobierno actual"
        value={actual[0]?.rdl_por_anio}
        formattedValue={formatNumber(actual[0]?.rdl_por_anio, 1)}
        unit="al año"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.decretos_ley, 0)} decretos-ley desde {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Derogados por el Congreso"
        value={estados_resumen[0]?.derogados}
        formattedValue={formatNumber(estados_resumen[0]?.derogados, 0)}
        period="de {formatNumber(estados_resumen[0]?.total, 0)} decretos-ley desde 1979; el resto se convalidó o está pendiente"
        source="BOE (resoluciones del Congreso)"
    />
</Grid>

## Cuántos se aprueban cada año

Decretos-ley aprobados cada año, coloreados según el partido del presidente que más tiempo gobernó ese año. {resumen[0]?.anio_en_curso} solo incluye lo que va de año.

<BarChart
    data={anual}
    x=anio
    y=decretos_ley
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Decretos-ley"
    title="Reales decretos-ley aprobados por año"
/>

El número de decretos-ley no depende solo de quién gobierna: los años con más decretos coinciden a menudo con crisis (2012, en plena crisis financiera; 2020, con la pandemia), y los años electorales, con las Cortes disueltas parte del año, tienen menos leyes y por tanto un porcentaje de decretos-ley más alto.

## Qué parte de la legislación se hace por decreto

Para no depender de cuánta legislación se aprueba cada año, la gráfica muestra el **porcentaje de decretos-ley sobre el total de normas con rango de ley** del Estado (decretos-ley más leyes y leyes orgánicas de las Cortes). Un 50 % significa que por cada ley aprobada en las Cortes el Gobierno aprobó un decreto-ley.

<LineChart
    data={anual_completo}
    x=anio
    y=pct_rdl
    xFmt='0'
    yFmt='0'
    yAxisTitle="% decretos-ley"
    title="Decretos-ley sobre el total de normas con rango de ley (%)"
/>

## Por Gobierno

Cada decreto-ley se atribuye al presidente en ejercicio el día en que lo aprobó el Consejo de Ministros (la fecha que figura en su título). Para comparar mandatos de distinta duración, la tabla da la **media por año gobernado**.

<BarChart
    data={presidencias}
    x=presidente
    y=rdl_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0.0'
    title="Decretos-ley por año gobernado, por presidente"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=desde title="Desde" fmt='0'/>
    <Column id=hasta title="Hasta"/>
    <Column id=anios title="Años" fmt='0.0'/>
    <Column id=decretos_ley title="Decretos-ley" fmt='0'/>
    <Column id=rdl_por_anio title="Por año" fmt='0.0' contentType=bar barColor="#fca5a5"/>
    <Column id=leyes_por_anio title="Leyes por año" fmt='0.0'/>
    <Column id=pct_rdl title="% decretos-ley" fmt='0'/>
    <Column id=derogados title="Derogados" fmt='0'/>
</DataTable>

## Por partido: observados frente a esperados

Contar sin más favorece a quien menos ha gobernado. La tabla compara los decretos-ley de cada partido con los **esperados** si todos los Gobiernos desde 1977 hubieran aprobado decretos-ley al mismo ritmo, repartidos según el tiempo que ha gobernado cada uno. Una ratio de 1 es lo esperable; 2, el doble; 0,5, la mitad.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partido del presidente"/>
    <Column id=anios title="Años gobernados" fmt='0.0'/>
    <Column id=observados title="Observados" fmt='0'/>
    <Column id=esperados title="Esperados por el tiempo gobernado" fmt='0.0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
    <Column id=pct_rdl title="% decretos-ley" fmt='0'/>
</DataTable>

El PSOE ha aprobado {formatNumber(partidos_resumen[0]?.psoe, 2)} veces los decretos-ley que le corresponderían por el tiempo gobernado, el PP {formatNumber(partidos_resumen[0]?.pp, 2)} veces y UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. Esta comparación tiene una limitación importante: el uso del decreto-ley **ha crecido con los años**, así que los Gobiernos más recientes salen perjudicados frente a los primeros. Por eso conviene mirar también la comparación dentro de la misma época: desde 1997, en los años completos gobernados por un solo presidente, PP y PSOE se han alternado en el poder.

<DataTable data={decadas} rows=all>
    <Column id=partido title="Partido del presidente"/>
    <Column id=anios title="Años completos (1997-)" fmt='0'/>
    <Column id=rdl_por_anio title="Decretos-ley por año" fmt='0.0'/>
    <Column id=pct_rdl title="% decretos-ley" fmt='0'/>
</DataTable>

## Convalidados y derogados

El Congreso debe votar cada decreto-ley en los 30 días hábiles siguientes a su publicación. Si lo **convalida**, sigue en vigor (y puede además tramitarlo como proyecto de ley para enmendarlo); si lo **deroga**, deja de estar en vigor. Desde 1979, el Congreso ha derogado {formatNumber(estados_resumen[0]?.derogados, 0)} decretos-ley. En {formatNumber(estados_resumen[0]?.sin_resolucion, 0)} casos no se ha encontrado en el BOE la resolución del Congreso: {formatNumber(estados_resumen[0]?.recientes, 0)} son de los últimos 60 días (pendientes de votación) y el resto, sobre todo de los primeros años, cuando la resolución no siempre se publicaba en el BOE con ese título.

<DataTable data={derogados} rows=all link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decreto-ley"/>
    <Column id=fecha_disposicion title="Fecha" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=titulo title="Título" wrap=true/>
</DataTable>

## Todos los decretos-ley

<DataTable data={listado} rows=15 search=true link=url_html showLinkCol=false>
    <Column id=numero_oficial title="Decreto-ley"/>
    <Column id=fecha_disposicion title="Fecha" fmt='dd/mm/yyyy'/>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=estado title="Congreso"/>
    <Column id=titulo title="Título" wrap=true/>
</DataTable>

## Metodología y fuentes

- **Fuente:** sumarios diarios del [Boletín Oficial del Estado](https://www.boe.es/datosabiertos/), API de datos abiertos, desde julio de 1977. Se toman los reales decretos-ley y las leyes de la sección I (Jefatura del Estado) y las resoluciones del Congreso de los Diputados que ordenan publicar la convalidación o derogación de cada decreto-ley. Cada norma se cuenta una vez aunque el BOE la publique en varias partes.
- **Fecha y Gobierno:** la fecha es la de la disposición (la del Consejo de Ministros, que figura en el título), no la de publicación; el decreto se atribuye al presidente en ejercicio ese día, también si estaba en funciones. Presidencias: Adolfo Suárez (UCD) hasta el 26 de febrero de 1981, Leopoldo Calvo-Sotelo (UCD), Felipe González (PSOE), José María Aznar (PP), José Luis Rodríguez Zapatero (PSOE), Mariano Rajoy (PP) y Pedro Sánchez (PSOE; en coalición con Unidas Podemos y después Sumar desde enero de 2020).
- **Rango de ley:** el porcentaje compara decretos-ley con leyes y leyes orgánicas de las Cortes (incluida la de presupuestos). No incluye los decretos legislativos (textos refundidos que el Gobierno aprueba por delegación de las Cortes) ni las leyes autonómicas.
- **Esperados:** total de decretos-ley desde el 5 de julio de 1977 multiplicado por la parte de ese tiempo que gobernó cada partido. Supone un ritmo constante, cosa que no ocurre (ver el texto).
- **Convalidación:** antes de la Constitución (29 de diciembre de 1978) los decretos-ley no necesitaban convalidación del Congreso; por eso los recuentos de estado empiezan en 1979.
- **Comparación internacional:** no se incluye. Cada país tiene figuras distintas (decreti-legge en Italia, ordonnances en Francia, medidas provisórias en Brasil...) y no hay una estadística oficial homogénea.
