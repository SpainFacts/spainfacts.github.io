---
title: Transporte público
description: "Viajeros de metro, autobús, Cercanías, AVE, tren de media y larga distancia, avión y barco en España cada mes desde 2012, y el metro y el autobús urbano en Madrid, Barcelona, Valencia, Bilbao, Sevilla, Málaga y Palma."
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

# 🚇 Transporte público

Cuántos viajeros mueven cada mes el metro, el autobús, el tren y el avión en España, según la Estadística de Transporte de Viajeros del INE.

<Grid cols=3>
    <KpiCard
        title="Viajeros de transporte público"
        value={ultimo[0]?.total}
        formattedValue={formatCompact(ultimo[0]?.total, 1)}
        period={ultimo[0]?.mes_texto}
        source="INE"
    />
    <KpiCard
        title="Viajeros de metro"
        value={ultimo[0]?.metro}
        formattedValue={formatCompact(ultimo[0]?.metro, 1)}
        period={ultimo[0]?.mes_texto}
        source="INE"
    />
    <KpiCard
        title="Viajeros de alta velocidad"
        value={ultimo_anual[0]?.ave}
        formattedValue={formatCompact(ultimo_anual[0]?.ave, 1)}
        period={ultimo_anual[0]?.ave_2019
            ? `en ${ultimo_anual[0].anio} · ${ultimo_anual[0].ave > ultimo_anual[0].ave_2019 ? '+' : ''}${formatNumber(100 * (ultimo_anual[0].ave / ultimo_anual[0].ave_2019 - 1), 0)} % vs. 2019`
            : `en ${ultimo_anual[0]?.anio}`}
        source="INE"
    />
</Grid>

## Viajeros por modo de transporte

<ButtonGroup name=grupo_modo title="Modo">
    <ButtonGroupItem valueLabel="Urbano" value="urbano" default />
    <ButtonGroupItem valueLabel="Tren" value="tren" />
    <ButtonGroupItem valueLabel="Autobús interurbano, avión y barco" value="otros" />
</ButtonGroup>

```sql serie_modo
SELECT mes, modo, viajeros
FROM ${modos}
WHERE ('${inputs.grupo_modo}' = 'urbano' AND clave IN ('metro', 'autobus_urbano'))
   OR ('${inputs.grupo_modo}' = 'tren' AND clave IN ('cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional'))
   OR ('${inputs.grupo_modo}' = 'otros' AND clave IN ('autobus_interurbano', 'avion_interior', 'maritimo'))
ORDER BY mes
```

<LineChart
    data={serie_modo}
    x=mes
    y=viajeros
    series=modo
    yFmt=num0
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">El hundimiento de 2020 es la pandemia de COVID-19. Avión: solo vuelos interiores; barco: cabotaje (entre puertos españoles).</p>

```sql recuperacion
SELECT
    a.modo,
    a.viajeros AS viajeros_ultimo_anio,
    p.viajeros AS viajeros_2019,
    a.viajeros / p.viajeros - 1 AS variacion
FROM ${anual} a
JOIN ${anual} p ON p.clave = a.clave AND p.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM ${anual})
  AND a.clave NOT IN ('total', 'urbano', 'interurbano', 'ferrocarril', 'larga_distancia')
ORDER BY variacion DESC
```

## ¿Se ha recuperado el transporte público tras la pandemia?

Viajeros del último año completo ({ultimo_anual[0]?.anio}) frente a 2019, el último año antes de la COVID-19.

<DataTable data={recuperacion} rows=all>
    <Column id=modo title="Modo" />
    <Column id=viajeros_2019 title="2019" fmt=num0 />
    <Column id=viajeros_ultimo_anio title="Último año" fmt=num0 />
    <Column id=variacion title="Variación" fmt=pct1 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">La alta velocidad crece con la liberalización (Ouigo desde 2021 e Iryo desde 2022, además de Renfe) y las nuevas líneas.</p>

## Metro y autobús urbano por ciudad

```sql ciudades
SELECT * FROM mother.movilidad_transporte_ciudades ORDER BY mes
```

<ButtonGroup name=modo_ciudad title="Modo">
    <ButtonGroupItem valueLabel="Metro" value="Metro" default />
    <ButtonGroupItem valueLabel="Autobús urbano" value="Autobús urbano" />
</ButtonGroup>

```sql serie_ciudad
SELECT mes, ciudad, viajeros FROM ${ciudades} WHERE modo = '${inputs.modo_ciudad}'
```

<LineChart
    data={serie_ciudad}
    x=mes
    y=viajeros
    series=ciudad
    yFmt=num0
    xFmt="mmm yyyy"
    legend=true
/>

```sql ciudades_anual
WITH anual AS (
    SELECT ciudad, modo, CAST(year(mes) AS INTEGER) AS anio, sum(viajeros) AS viajeros, count(*) AS meses
    FROM ${ciudades}
    GROUP BY ALL
    HAVING count(*) = 12
)
SELECT
    a.ciudad,
    a.modo,
    a.anio,
    a.viajeros,
    a.viajeros / p.viajeros - 1 AS vs_2019
FROM anual a
LEFT JOIN anual p ON p.ciudad = a.ciudad AND p.modo = a.modo AND p.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM anual)
ORDER BY a.modo DESC, a.viajeros DESC
```

<DataTable data={ciudades_anual} rows=all>
    <Column id=ciudad title="Ciudad" />
    <Column id=modo title="Modo" />
    <Column id=viajeros title="Viajeros (último año completo)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=vs_2019 title="Vs. 2019" fmt=pct1 contentType=delta />
</DataTable>

---

## Fuentes y notas

- **[INE – Estadística de Transporte de Viajeros](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176906&menu=ultiDatos&idp=1254735576820)**, tablas [20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239) (España por modo) y [20193](https://www.ine.es/jaxiT3/Tabla.htm?t=20193) (ciudades con metro). Mensual desde 2012; el INE la publica unos 40 días después del final de cada mes.
- Transporte urbano: metro y autobús urbano regular. El tren de Cercanías cuenta como interurbano.

<LastRefreshed prefix="Datos actualizados" />
