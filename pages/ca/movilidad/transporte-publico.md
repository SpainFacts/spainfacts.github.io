---
title: Transport públic
description: "Viatgers de metro, autobús, Rodalies, AVE, tren de mitjana i llarga distància, avió i vaixell a Espanya cada mes des del 2012, i el metro i l'autobús urbà a Madrid, Barcelona, València, Bilbao, Sevilla, Màlaga i Palma."
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

# 🚇 Transport públic

Quants viatgers mouen cada mes el metro, l'autobús, el tren i l'avió a Espanya, segons l'Estadística de Transport de Viatgers de l'INE.

<Grid cols=3>
    <KpiCard
        title="Viatges en transport públic"
        value={ultimo[0]?.total / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.total / ultimo[0]?.poblacion, 1)} per habitant"
        period="al mes · {formatCompact(ultimo[0]?.total, 1)} viatgers en total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'total')}
    />
    <KpiCard
        title="Viatges en metro"
        value={ultimo[0]?.metro / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.metro / ultimo[0]?.poblacion, 1)} per habitant"
        period="al mes (mitjana d'Espanya) · {formatCompact(ultimo[0]?.metro, 1)} en total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'metro')}
    />
    <KpiCard
        title="Viatges en alta velocitat"
        value={ave_por_mil.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(ave_por_mil.slice(-1)[0]?.valor, 0)} per 1.000 hab."
        period={ultimo_anual[0]?.ave_2019
            ? `a l'any · ${formatCompact(ultimo_anual[0].ave, 1)} viatgers el ${ultimo_anual[0].anio} · ${ultimo_anual[0].ave > ultimo_anual[0].ave_2019 ? '+' : ''}${formatNumber(100 * (ultimo_anual[0].ave / ultimo_anual[0].ave_2019 - 1), 0)} % vs. 2019`
            : `a l'any · ${formatCompact(ultimo_anual[0]?.ave, 1)} viatgers el ${ultimo_anual[0]?.anio}`}
        source="INE"
        sparklineData={ave_por_mil}
    />
</Grid>

## Viatgers per mitjà de transport

<ButtonGroup name=grupo_modo title="Mitjà">
    <ButtonGroupItem valueLabel="Urbà" value="urbano" default />
    <ButtonGroupItem valueLabel="Tren" value="tren" />
    <ButtonGroupItem valueLabel="Autobús interurbà, avió i vaixell" value="otros" />
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
    yAxisTitle="viatges al mes per 1.000 habitants"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Viatges per cada 1.000 habitants, perquè el creixement de la població no es confongui amb un ús més gran del transport. L'enfonsament del 2020 és la pandèmia de COVID-19. Avió: només vols interiors; vaixell: cabotatge (entre ports espanyols).</p>

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

## S'ha recuperat el transport públic després de la pandèmia?

Viatges per cada 1.000 habitants l'últim any complet ({ultimo_anual[0]?.anio}) davant del 2019, l'últim any abans de la COVID-19.

<DataTable data={recuperacion} rows=all>
    <Column id=modo title="Mitjà" />
    <Column id=por_1000_2019 title="2019 (per 1.000 hab.)" fmt=num0 />
    <Column id=por_1000_ultimo title="Últim any (per 1.000 hab.)" fmt=num0 />
    <Column id=variacion title="Variació per habitant" fmt=pct1 contentType=delta />
    <Column id=viajeros_ultimo_anio title="Viatgers en total" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">L'alta velocitat creix amb la liberalització (Ouigo des del 2021 i Iryo des del 2022, a més de Renfe) i les noves línies.</p>

## Metro i autobús urbà per ciutat

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

<ButtonGroup name=modo_ciudad title="Mitjà">
    <ButtonGroupItem valueLabel="Metro" value="Metro" default />
    <ButtonGroupItem valueLabel="Autobús urbà" value="Autobús urbano" />
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
    yAxisTitle="viatges al mes per habitant del municipi"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Viatges al mes per cada habitant empadronat al municipi. El metro de Madrid, Barcelona, Bilbao o València també dona servei a municipis veïns, de manera que la xifra per veí de la ciutat sobreestima l'ús per persona; serveix per veure l'evolució de cada ciutat més que per comparar-les entre si.</p>

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
    <Column id=ciudad title="Ciutat" />
    <Column id=modo title="Mitjà" />
    <Column id=por_habitante title="Viatges per habitant (últim any complet)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=vs_2019 title="Vs. 2019 (per habitant)" fmt=pct1 contentType=delta />
    <Column id=viajeros title="Viatgers en total" fmt=num0 />
</DataTable>

---

## Fonts i notes

- **[INE – Estadística de Transport de Viatgers](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176906&menu=ultiDatos&idp=1254735576820)**, taules [20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239) (Espanya per mitjà) i [20193](https://www.ine.es/jaxiT3/Tabla.htm?t=20193) (ciutats amb metro). Mensual des del 2012; l'INE la publica uns 40 dies després del final de cada mes.
- Transport urbà: metro i autobús urbà regular. El tren de Rodalies compta com a interurbà.

<LastRefreshed prefix="Dades actualitzades" />
