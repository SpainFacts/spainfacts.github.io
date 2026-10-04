---
title: Transporte público
description: "Viajeros de metro, autobús, Cercanías, AVE, tren de media y larga distancia, avión y barco en España cada mes desde 2012, y el metro y el autobús urbano en Madrid, Barcelona, Valencia, Bilbao, Sevilla, Málaga y Palma."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql modos
SELECT * FROM mother.movilidad_transporte_modos WHERE clave IS NOT NULL
```

```sql ultimo
WITH u AS (SELECT max(mes) AS mes FROM ${modos})
SELECT
    strftime(u.mes, '%m/%Y') AS mes_texto,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
      ORDER BY anio DESC LIMIT 1) AS poblacion,
    sum(m.viajeros) FILTER (WHERE m.clave = 'total') AS total,
    sum(m.viajeros) FILTER (WHERE m.clave = 'metro') AS metro,
    sum(m.viajeros) FILTER (WHERE m.clave = 'alta_velocidad') AS ave,
    sum(m.viajeros) FILTER (WHERE m.clave = 'cercanias') AS cercanias
FROM ${modos} m, u
WHERE m.mes = u.mes
GROUP BY u.mes
```

```sql anual
-- Años completos
SELECT CAST(year(mes) AS INTEGER) AS anio, clave, modo, sum(viajeros) AS viajeros, count(*) AS meses
FROM ${modos}
GROUP BY ALL
HAVING count(*) = 12
```

```sql ultimo_anual
SELECT
    a.anio,
    sum(a.viajeros) FILTER (WHERE a.clave = 'total') AS total,
    sum(a.viajeros) FILTER (WHERE a.clave = 'alta_velocidad') AS ave,
    sum(p.viajeros) FILTER (WHERE p.clave = 'alta_velocidad') AS ave_2019,
    sum(p.viajeros) FILTER (WHERE p.clave = 'total') AS total_2019
FROM ${anual} a
LEFT JOIN ${anual} p ON p.clave = a.clave AND p.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM ${anual})
GROUP BY a.anio
```

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion
FROM mother.poblacion_territorios
WHERE nivel = 'pais' AND sexo = 'Total'
```

```sql serie_por_mil
-- Viajeros por cada 1.000 habitantes, últimos 36 meses
SELECT m.mes, m.clave, m.viajeros_por_1000_hab AS valor
FROM ${modos} AS m
WHERE m.clave IN ('total', 'metro')
  AND m.mes >= (SELECT max(mes) FROM ${modos}) - INTERVAL 35 MONTH
ORDER BY m.mes
```

```sql ave_por_mil
-- Viajeros de alta velocidad por cada 1.000 habitantes, años completos
SELECT a.anio, 1000 * a.viajeros / p.poblacion AS valor
FROM ${anual} AS a
JOIN ${poblacion} AS p ON p.anio = least(a.anio, (SELECT max(anio) FROM ${poblacion}))
WHERE a.clave = 'alta_velocidad'
ORDER BY a.anio
```

# 🚇 Transporte público

Cuántos viajeros mueven cada mes el metro, el autobús, el tren y el avión en España, según la Estadística de Transporte de Viajeros del INE.

<Grid cols=3>
    <KpiCard
        title="Viajes en transporte público"
        value={ultimo[0]?.total / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.total / ultimo[0]?.poblacion, 1)} por habitante"
        period="al mes · {formatCompact(ultimo[0]?.total, 1)} viajeros en total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'total')}
    />
    <KpiCard
        title="Viajes en metro"
        value={ultimo[0]?.metro / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.metro / ultimo[0]?.poblacion, 1)} por habitante"
        period="al mes (media de España) · {formatCompact(ultimo[0]?.metro, 1)} en total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'metro')}
    />
    <KpiCard
        title="Viajes en alta velocidad"
        value={ave_por_mil.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(ave_por_mil.slice(-1)[0]?.valor, 0)} por 1.000 hab."
        period={ultimo_anual[0]?.ave_2019
            ? `al año · ${formatCompact(ultimo_anual[0].ave, 1)} viajeros en ${ultimo_anual[0].anio} · ${ultimo_anual[0].ave > ultimo_anual[0].ave_2019 ? '+' : ''}${formatNumber(100 * (ultimo_anual[0].ave / ultimo_anual[0].ave_2019 - 1), 0)} % vs. 2019`
            : `al año · ${formatCompact(ultimo_anual[0]?.ave, 1)} viajeros en ${ultimo_anual[0]?.anio}`}
        source="INE"
        sparklineData={ave_por_mil}
    />
</Grid>

## Viajeros por modo de transporte

<ButtonGroup name=grupo_modo title="Modo">
    <ButtonGroupItem valueLabel="Urbano" value="urbano" default />
    <ButtonGroupItem valueLabel="Tren" value="tren" />
    <ButtonGroupItem valueLabel="Autobús interurbano, avión y barco" value="otros" />
</ButtonGroup>

```sql serie_modo
SELECT m.mes, m.modo, m.viajeros, m.viajeros_por_1000_hab AS por_1000
FROM ${modos} m
WHERE ('${inputs.grupo_modo}' = 'urbano' AND clave IN ('metro', 'autobus_urbano'))
   OR ('${inputs.grupo_modo}' = 'tren' AND clave IN ('cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional'))
   OR ('${inputs.grupo_modo}' = 'otros' AND clave IN ('autobus_interurbano', 'avion_interior', 'maritimo'))
ORDER BY m.mes
```

<LineChart
    data={serie_modo}
    x=mes
    y=por_1000
    series=modo
    yFmt=num0
    yAxisTitle="viajes al mes por 1.000 habitantes"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Viajes por cada 1.000 habitantes, para que el crecimiento de la población no se confunda con un mayor uso del transporte. El hundimiento de 2020 es la pandemia de COVID-19. Avión: solo vuelos interiores; barco: cabotaje (entre puertos españoles).</p>

```sql recuperacion
-- Viajes por 1.000 habitantes: la población creció entre 2019 y el último año
SELECT
    a.modo,
    1000.0 * a.viajeros / pa.poblacion AS por_1000_ultimo,
    1000.0 * p.viajeros / p19.poblacion AS por_1000_2019,
    (a.viajeros / pa.poblacion) / (p.viajeros / p19.poblacion) - 1 AS variacion,
    a.viajeros AS viajeros_ultimo_anio
FROM ${anual} a
JOIN ${anual} p ON p.clave = a.clave AND p.anio = 2019
JOIN ${poblacion} pa ON pa.anio = least(a.anio, (SELECT max(anio) FROM ${poblacion}))
JOIN ${poblacion} p19 ON p19.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM ${anual})
  AND a.clave NOT IN ('total', 'urbano', 'interurbano', 'ferrocarril', 'larga_distancia')
ORDER BY variacion DESC
```

## ¿Se ha recuperado el transporte público tras la pandemia?

Viajes por cada 1.000 habitantes en el último año completo ({ultimo_anual[0]?.anio}) frente a 2019, el último año antes de la COVID-19.

<DataTable data={recuperacion} rows=all>
    <Column id=modo title="Modo" />
    <Column id=por_1000_2019 title="2019 (por 1.000 hab.)" fmt=num0 />
    <Column id=por_1000_ultimo title="Último año (por 1.000 hab.)" fmt=num0 />
    <Column id=variacion title="Variación por habitante" fmt=pct1 contentType=delta />
    <Column id=viajeros_ultimo_anio title="Viajeros en total" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">La alta velocidad crece con la liberalización (Ouigo desde 2021 e Iryo desde 2022, además de Renfe) y las nuevas líneas.</p>

## Metro y autobús urbano por ciudad

```sql ciudades
-- Por habitante del municipio (padrón del año; el último para los más recientes)
WITH cod AS (
    SELECT * FROM (VALUES ('Madrid', '28079'), ('Barcelona', '08019'), ('València', '46250'), ('Bilbao', '48020'),
        ('Sevilla', '41091'), ('Málaga', '29067'), ('Palma', '07040')) AS t(ciudad, cod_mun)
),
pob AS (
    SELECT cod_mun, CAST(anio AS INTEGER) AS anio, poblacion FROM mother.poblacion_municipios
)
SELECT c.*, p.poblacion, c.viajeros / p.poblacion AS por_habitante
FROM mother.movilidad_transporte_ciudades c
JOIN cod ON cod.ciudad = c.ciudad
JOIN pob p ON p.cod_mun = cod.cod_mun
 AND p.anio = greatest(least(CAST(year(c.mes) AS INTEGER), (SELECT max(anio) FROM pob)), (SELECT min(anio) FROM pob))
ORDER BY c.mes
```

<ButtonGroup name=modo_ciudad title="Modo">
    <ButtonGroupItem valueLabel="Metro" value="Metro" default />
    <ButtonGroupItem valueLabel="Autobús urbano" value="Autobús urbano" />
</ButtonGroup>

```sql serie_ciudad
SELECT mes, ciudad, viajeros, por_habitante FROM ${ciudades} WHERE modo = '${inputs.modo_ciudad}'
```

<LineChart
    data={serie_ciudad}
    x=mes
    y=por_habitante
    series=ciudad
    yFmt=num1
    yAxisTitle="viajes al mes por habitante del municipio"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Viajes al mes por cada habitante empadronado en el municipio. El metro de Madrid, Barcelona, Bilbao o Valencia también da servicio a municipios vecinos, así que la cifra por vecino de la ciudad sobrestima el uso por persona; sirve para ver la evolución de cada ciudad más que para compararlas entre sí.</p>

```sql ciudades_anual
WITH anual AS (
    SELECT ciudad, modo, CAST(year(mes) AS INTEGER) AS anio, sum(viajeros) AS viajeros, sum(viajeros) / any_value(poblacion) AS por_habitante, count(*) AS meses
    FROM ${ciudades}
    GROUP BY ALL
    HAVING count(*) = 12
)
SELECT
    a.ciudad,
    a.modo,
    a.anio,
    a.viajeros,
    a.por_habitante,
    a.por_habitante / p.por_habitante - 1 AS vs_2019
FROM anual a
LEFT JOIN anual p ON p.ciudad = a.ciudad AND p.modo = a.modo AND p.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM anual)
ORDER BY a.modo DESC, a.por_habitante DESC
```

<DataTable data={ciudades_anual} rows=all>
    <Column id=ciudad title="Ciudad" />
    <Column id=modo title="Modo" />
    <Column id=por_habitante title="Viajes por habitante (último año completo)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=vs_2019 title="Vs. 2019 (por habitante)" fmt=pct1 contentType=delta />
    <Column id=viajeros title="Viajeros en total" fmt=num0 />
</DataTable>

---

## Fuentes y notas

- **[INE – Estadística de Transporte de Viajeros](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176906&menu=ultiDatos&idp=1254735576820)**, tablas [20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239) (España por modo) y [20193](https://www.ine.es/jaxiT3/Tabla.htm?t=20193) (ciudades con metro). Mensual desde 2012; el INE la publica unos 40 días después del final de cada mes.
- Transporte urbano: metro y autobús urbano regular. El tren de Cercanías cuenta como interurbano.

<LastRefreshed prefix="Datos actualizados" />
