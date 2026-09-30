---
title: Indultos
description: "Cuántos indultos concede cada Gobierno de España desde 1977 según el BOE, su evolución y cómo se compara cada presidente y cada partido según el tiempo que ha gobernado."
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

El **indulto** es la gracia por la que el Gobierno perdona, total o parcialmente, la pena impuesta por una sentencia firme. Lo concede el Consejo de Ministros mediante un real decreto, a propuesta del Ministerio de Justicia y tras un informe del tribunal que dictó la sentencia (Ley de 18 de junio de 1870, reformada en 1988 y 2015). La Constitución prohíbe los indultos generales (art. 62.i): todos son individuales y todos se publican en el Boletín Oficial del Estado. Esta página los cuenta.

<Grid cols=4>
    <KpiCard
        title="Indultos en {resumen[0]?.ultimo_anio}"
        value={resumen[0]?.ultimo}
        formattedValue={formatNumber(resumen[0]?.ultimo, 0)}
        period="{formatNumber(resumen[0]?.en_curso, 0)} en lo que va de {resumen[0]?.anio_en_curso}"
        source="BOE"
        sparklineData={anual_completo.map(d => d.indultos)}
    />
    <KpiCard
        title="Media de los últimos diez años"
        value={resumen[0]?.media_10}
        formattedValue={formatNumber(resumen[0]?.media_10, 0)}
        unit="al año"
        period="frente a {formatNumber(resumen[0]?.media_9605, 0)} al año entre 1996 y 2005"
        source="BOE"
    />
    <KpiCard
        title="Ritmo del Gobierno actual"
        value={actual[0]?.indultos_por_anio}
        formattedValue={formatNumber(actual[0]?.indultos_por_anio, 0)}
        unit="al año"
        period="{actual[0]?.presidente} ({actual[0]?.partido}), {formatNumber(actual[0]?.indultos, 0)} indultos desde {actual[0]?.desde}"
        source="BOE"
    />
    <KpiCard
        title="Año con más indultos"
        value={resumen[0]?.maximo}
        formattedValue={formatNumber(resumen[0]?.maximo, 0)}
        period="en {resumen[0]?.anio_maximo} · {formatNumber(resumen[0]?.total, 0)} en total desde 1978"
        source="BOE"
    />
</Grid>

## Cuántos se conceden cada año

Reales decretos de indulto por año de su aprobación en el Consejo de Ministros, coloreados según el partido del presidente que más tiempo gobernó ese año. {resumen[0]?.anio_en_curso} solo incluye lo que va de año.

<BarChart
    data={anual}
    x=anio
    y=indultos
    series=partido
    xFmt='0'
    seriesColors={coloresPartido}
    yAxisTitle="Indultos"
    title="Indultos concedidos por año"
/>

La serie tiene picos puntuales de indultos aprobados en tandas: el mayor, en diciembre de {pico[0]?.anio}, con {formatNumber(pico[0]?.indultos, 0)} reales decretos de indulto aprobados en un solo mes. Desde {minimos[0]?.desde} no se han superado los 100 indultos en ningún año, los niveles más bajos de toda la serie.

## Por Gobierno

Cada indulto se atribuye al presidente en ejercicio el día en que el Consejo de Ministros aprobó el real decreto. Para comparar mandatos de distinta duración, la tabla da la **media por año gobernado**.

<BarChart
    data={presidencias}
    x=presidente
    y=indultos_por_anio
    series=partido
    sort=false
    swapXY=true
    seriesColors={coloresPartido}
    yFmt='0'
    title="Indultos por año gobernado, por presidente"
/>

<DataTable data={presidencias} rows=all>
    <Column id=presidente title="Presidente"/>
    <Column id=partido title="Partido"/>
    <Column id=desde title="Desde" fmt='0'/>
    <Column id=hasta title="Hasta"/>
    <Column id=anios title="Años" fmt='0.0'/>
    <Column id=indultos title="Indultos" fmt='0'/>
    <Column id=indultos_por_anio title="Por año" fmt='0' contentType=bar barColor="#c4b5fd"/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
</DataTable>

## Por partido: observados frente a esperados

Los **esperados** son los indultos que le corresponderían a cada partido si todos los Gobiernos desde 1977 hubieran indultado al mismo ritmo, según el tiempo que ha gobernado cada uno. Una ratio de 1 es lo esperable; 2, el doble; 0,5, la mitad.

<DataTable data={partidos} rows=all>
    <Column id=partido title="Partido del presidente"/>
    <Column id=anios title="Años gobernados" fmt='0.0'/>
    <Column id=observados title="Observados" fmt='0'/>
    <Column id=esperados title="Esperados por el tiempo gobernado" fmt='0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
    <Column id=indultos_por_anio title="Por año" fmt='0'/>
</DataTable>

Con este cálculo, el PSOE ha concedido {formatNumber(partidos_resumen[0]?.psoe, 2)} veces los indultos esperados por el tiempo gobernado, el PP {formatNumber(partidos_resumen[0]?.pp, 2)} veces y UCD {formatNumber(partidos_resumen[0]?.ucd, 2)}. Igual que con cualquier serie larga, el ritmo no ha sido constante: el número de condenados, las leyes penales y el criterio de los tribunales al informar han cambiado mucho desde 1977. Por eso conviene mirar también la comparación dentro de una misma época: desde 1997, en los años completos gobernados por un solo presidente.

<DataTable data={misma_epoca} rows=all>
    <Column id=partido title="Partido del presidente"/>
    <Column id=anios title="Años completos (1997-)" fmt='0'/>
    <Column id=indultos_por_anio title="Indultos por año (media)" fmt='0'/>
    <Column id=mediana title="Mediana" fmt='0'/>
</DataTable>

## Metodología y fuentes

- **Fuente:** sumarios diarios del [Boletín Oficial del Estado](https://www.boe.es/datosabiertos/), API de datos abiertos, desde julio de 1977: reales decretos de la sección III («Otras disposiciones»), epígrafe «Indultos», cuyo título dice «por el que se indulta» o «por el que se conmuta». No se cuentan las correcciones de errores.
- **Qué se cuenta:** reales decretos de indulto, no personas. Algunos decretos indultan a varias personas y alguna persona recibe más de un indulto. No se distingue entre indulto total y parcial (el BOE lo dice en el texto del decreto, no en el título). El nombre de las personas indultadas no se guarda.
- **Fecha y Gobierno:** la fecha es la del real decreto (la del Consejo de Ministros, que figura en el título), no la de publicación, que puede llegar semanas después; se atribuye al presidente en ejercicio ese día, también si estaba en funciones. En los pocos títulos sin fecha (1977-1978) se usa la de publicación.
- **Esperados:** total de indultos desde el 5 de julio de 1977 multiplicado por la parte de ese tiempo que gobernó cada partido. Supone un ritmo constante, cosa que no ocurre (ver el texto).
- **Comparación internacional:** no se incluye; la figura del indulto y su publicación cambian mucho de un país a otro y no hay una estadística oficial homogénea.
