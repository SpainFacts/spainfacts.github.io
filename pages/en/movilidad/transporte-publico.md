---
title: Public transport
description: "Passengers on metro, bus, Cercanías commuter rail, AVE high-speed rail, medium- and long-distance trains, air and sea in Spain every month since 2012, plus metro and city buses in Madrid, Barcelona, Valencia, Bilbao, Seville, Málaga and Palma."
i18n_origen: 2298a9087930
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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
SELECT m.mes, m.clave, 1000 * m.viajeros / p.poblacion AS valor
FROM ${modos} AS m
JOIN ${poblacion} AS p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM ${poblacion}))
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

# 🚇 Public transport

How many passengers the metro, buses, trains and planes carry in Spain every month, according to the INE's Passenger Transport Statistics.

<Grid cols=3>
    <KpiCard
        title="Public transport trips"
        value={ultimo[0]?.total / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.total / ultimo[0]?.poblacion, 1)} per person"
        period="per month · {formatCompact(ultimo[0]?.total, 1)} passengers in total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'total')}
    />
    <KpiCard
        title="Metro trips"
        value={ultimo[0]?.metro / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.metro / ultimo[0]?.poblacion, 1)} per person"
        period="per month (Spanish average) · {formatCompact(ultimo[0]?.metro, 1)} in total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'metro')}
    />
    <KpiCard
        title="High-speed rail trips"
        value={ave_por_mil.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(ave_por_mil.slice(-1)[0]?.valor, 0)} per 1,000 people"
        period={ultimo_anual[0]?.ave_2019
            ? `per year · ${formatCompact(ultimo_anual[0].ave, 1)} passengers in ${ultimo_anual[0].anio} · ${ultimo_anual[0].ave > ultimo_anual[0].ave_2019 ? '+' : ''}${formatNumber(100 * (ultimo_anual[0].ave / ultimo_anual[0].ave_2019 - 1), 0)}% vs. 2019`
            : `per year · ${formatCompact(ultimo_anual[0]?.ave, 1)} passengers in ${ultimo_anual[0]?.anio}`}
        source="INE"
        sparklineData={ave_por_mil}
    />
</Grid>

## Passengers by mode of transport

<ButtonGroup name=grupo_modo title="Mode">
    <ButtonGroupItem valueLabel="Urban" value="urbano" default />
    <ButtonGroupItem valueLabel="Rail" value="tren" />
    <ButtonGroupItem valueLabel="Intercity bus, air and sea" value="otros" />
</ButtonGroup>

```sql serie_modo
SELECT m.mes, m.modo, m.viajeros, 1000.0 * m.viajeros / p.poblacion AS por_1000
FROM ${modos} m
JOIN ${poblacion} p ON p.anio = greatest(least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM ${poblacion})), (SELECT min(anio) FROM ${poblacion}))
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
    yAxisTitle="trips per month per 1,000 people"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Trips per 1,000 people, so that population growth is not mistaken for greater use of transport. The collapse in 2020 is the COVID-19 pandemic. Air: domestic flights only; sea: coastal shipping (between Spanish ports).</p>

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

## Has public transport recovered since the pandemic?

Trips per 1,000 people in the latest full year ({ultimo_anual[0]?.anio}) compared with 2019, the last year before COVID-19.

<DataTable data={recuperacion} rows=all>
    <Column id=modo title="Mode" />
    <Column id=por_1000_2019 title="2019 (per 1,000 people)" fmt=num0 />
    <Column id=por_1000_ultimo title="Latest year (per 1,000 people)" fmt=num0 />
    <Column id=variacion title="Change per person" fmt=pct1 contentType=delta />
    <Column id=viajeros_ultimo_anio title="Total passengers" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">High-speed rail is growing thanks to liberalisation (Ouigo since 2021 and Iryo since 2022, alongside Renfe) and new lines.</p>

## Metro and city buses by city

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

<ButtonGroup name=modo_ciudad title="Mode">
    <ButtonGroupItem valueLabel="Metro" value="Metro" default />
    <ButtonGroupItem valueLabel="City bus" value="Autobús urbano" />
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
    yAxisTitle="trips per month per resident of the municipality"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Trips per month for each registered resident of the municipality. The metro systems in Madrid, Barcelona, Bilbao and Valencia also serve neighbouring municipalities, so the figure per city resident overstates use per person; it is better for tracking each city over time than for comparing cities with one another.</p>

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
    <Column id=ciudad title="City" />
    <Column id=modo title="Mode" />
    <Column id=por_habitante title="Trips per person (latest full year)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=vs_2019 title="Vs. 2019 (per person)" fmt=pct1 contentType=delta />
    <Column id=viajeros title="Total passengers" fmt=num0 />
</DataTable>

---

## Sources and notes

- **[INE – Passenger Transport Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176906&menu=ultiDatos&idp=1254735576820)**, tables [20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239) (Spain by mode) and [20193](https://www.ine.es/jaxiT3/Tabla.htm?t=20193) (cities with a metro). Monthly since 2012; the INE publishes it about 40 days after the end of each month.
- Urban transport: metro and regular city buses. Cercanías commuter rail counts as intercity.

<LastRefreshed prefix="Data updated" />
