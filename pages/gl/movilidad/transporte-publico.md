---
i18n_origen: 2298a9087930
title: Transporte público
description: "Viaxeiros de metro, autobús, Cercanías, AVE, tren de media e longa distancia, avión e barco en España cada mes desde 2012, e o metro e o autobús urbano en Madrid, Barcelona, Valencia, Bilbao, Sevilla, Málaga e Palma."
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

# 🚇 Transporte público

Cantos viaxeiros moven cada mes o metro, o autobús, o tren e o avión en España, segundo a Estadística de Transporte de Viajeros do INE.

<Grid cols=3>
    <KpiCard
        title="Viaxes en transporte público"
        value={ultimo[0]?.total / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.total / ultimo[0]?.poblacion, 1)} por habitante"
        period="ao mes · {formatCompact(ultimo[0]?.total, 1)} viaxeiros en total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'total')}
    />
    <KpiCard
        title="Viaxes en metro"
        value={ultimo[0]?.metro / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.metro / ultimo[0]?.poblacion, 1)} por habitante"
        period="ao mes (media de España) · {formatCompact(ultimo[0]?.metro, 1)} en total · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'metro')}
    />
    <KpiCard
        title="Viaxes en alta velocidade"
        value={ave_por_mil.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(ave_por_mil.slice(-1)[0]?.valor, 0)} por 1.000 hab."
        period={ultimo_anual[0]?.ave_2019
            ? `ao ano · ${formatCompact(ultimo_anual[0].ave, 1)} viaxeiros en ${ultimo_anual[0].anio} · ${ultimo_anual[0].ave > ultimo_anual[0].ave_2019 ? '+' : ''}${formatNumber(100 * (ultimo_anual[0].ave / ultimo_anual[0].ave_2019 - 1), 0)} % vs. 2019`
            : `ao ano · ${formatCompact(ultimo_anual[0]?.ave, 1)} viaxeiros en ${ultimo_anual[0]?.anio}`}
        source="INE"
        sparklineData={ave_por_mil}
    />
</Grid>

## Viaxeiros por modo de transporte

<ButtonGroup name=grupo_modo title="Modo">
    <ButtonGroupItem valueLabel="Urbano" value="urbano" default />
    <ButtonGroupItem valueLabel="Tren" value="tren" />
    <ButtonGroupItem valueLabel="Autobús interurbano, avión e barco" value="otros" />
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
    yAxisTitle="viaxes ao mes por 1.000 habitantes"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Viaxes por cada 1.000 habitantes, para que o crecemento da poboación non se confunda cun maior uso do transporte. O afundimento de 2020 é a pandemia de COVID-19. Avión: só voos interiores; barco: cabotaxe (entre portos españois).</p>

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

## Recuperouse o transporte público despois da pandemia?

Viaxes por cada 1.000 habitantes no último ano completo ({ultimo_anual[0]?.anio}) fronte a 2019, o último ano antes da COVID-19.

<DataTable data={recuperacion} rows=all>
    <Column id=modo title="Modo" />
    <Column id=por_1000_2019 title="2019 (por 1.000 hab.)" fmt=num0 />
    <Column id=por_1000_ultimo title="Último ano (por 1.000 hab.)" fmt=num0 />
    <Column id=variacion title="Variación por habitante" fmt=pct1 contentType=delta />
    <Column id=viajeros_ultimo_anio title="Viaxeiros en total" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">A alta velocidade medra coa liberalización (Ouigo desde 2021 e Iryo desde 2022, ademais de Renfe) e as novas liñas.</p>

## Metro e autobús urbano por cidade

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
    yAxisTitle="viaxes ao mes por habitante do concello"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Viaxes ao mes por cada habitante empadroado no concello. O metro de Madrid, Barcelona, Bilbao ou Valencia tamén dá servizo a concellos veciños, así que a cifra por veciño da cidade sobreestima o uso por persoa; serve para ver a evolución de cada cidade máis que para comparalas entre si.</p>

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
    <Column id=ciudad title="Cidade" />
    <Column id=modo title="Modo" />
    <Column id=por_habitante title="Viaxes por habitante (último ano completo)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=vs_2019 title="Vs. 2019 (por habitante)" fmt=pct1 contentType=delta />
    <Column id=viajeros title="Viaxeiros en total" fmt=num0 />
</DataTable>

---

## Fontes e notas

- **[INE – Estadística de Transporte de Viajeros](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176906&menu=ultiDatos&idp=1254735576820)**, táboas [20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239) (España por modo) e [20193](https://www.ine.es/jaxiT3/Tabla.htm?t=20193) (cidades con metro). Mensual desde 2012; o INE publícaa uns 40 días despois do final de cada mes.
- Transporte urbano: metro e autobús urbano regular. O tren de Cercanías conta como interurbano.

<LastRefreshed prefix="Datos actualizados" />
