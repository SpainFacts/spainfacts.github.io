---
title: Camions i autobusos
description: "Camions i autobusos a Espanya: matriculacions per tipus de motor des del 2015, avenç de l'autobús elèctric, marques i grups més venuts i antiguitat dels que circulen."
i18n_origen: 4190a8292d58
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql anual
-- Camiones y autobuses nuevos por año y motor, por 100.000 habitantes
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.grupo,
    m.energia,
    m.energia_etiqueta AS motor,
    m.energia_orden,
    sum(m.matriculaciones) AS unidades,
    100000.0 * sum(m.matriculaciones) / any_value(p.poblacion) AS por_100000
FROM mother.movilidad_matriculaciones_mensual m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
WHERE m.grupo IN ('camion', 'autobus') AND m.nuevo_usado = 'N'
GROUP BY ALL
ORDER BY anio, m.energia_orden
```

```sql cero_emisiones
-- Cuota de cero emisiones (eléctricos puros e hidrógeno) en los últimos 12 meses y un año antes
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_mensual),
base AS (
    SELECT
        m.grupo,
        m.mes > u.mes - INTERVAL 12 MONTH AS actual,
        sum(m.matriculaciones) AS total,
        sum(m.matriculaciones) FILTER (WHERE m.energia IN ('bev', 'hidrogeno')) AS cero,
        sum(m.matriculaciones) FILTER (WHERE m.energia = 'diesel') AS diesel
    FROM mother.movilidad_matriculaciones_mensual m, ult u
    WHERE m.grupo IN ('camion', 'autobus') AND m.nuevo_usado = 'N'
      AND m.mes > u.mes - INTERVAL 24 MONTH
    GROUP BY ALL
)
SELECT
    a.grupo,
    a.total,
    a.cero / a.total AS cuota_cero,
    a.diesel / a.total AS cuota_diesel,
    b.cero / b.total AS cuota_cero_antes,
    (SELECT strftime(mes, '%m/%Y') FROM ult) AS mes_texto
FROM base a
JOIN base b ON b.grupo = a.grupo AND NOT b.actual
WHERE a.actual
```

```sql anual_cuota
SELECT anio, grupo,
    sum(unidades) FILTER (WHERE energia IN ('bev', 'hidrogeno')) / sum(unidades) AS cuota_cero,
    CASE grupo WHEN 'camion' THEN 'Camiones' ELSE 'Autobuses' END AS vehiculo
FROM ${anual}
GROUP BY ALL
ORDER BY anio
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${anual} ORDER BY energia_orden
```

# 🚚 Camions i autobusos

Els camions i autobusos són pocs al costat dels cotxes, però recorren molts més quilòmetres i cremen sobretot gasoil: el transport pesant és una part important de les emissions del transport per carretera. Aquí es veu quants se'n venen, amb quin motor i quants anys tenen els que circulen.

<Grid cols=2>
    <KpiCard
        title="Autobusos nous de zero emissions"
        value={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="elèctrics i hidrogen · 12 mesos fins al {cero_emisiones[0]?.mes_texto}"
        change={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. els 12 mesos anteriors"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Camions nous de zero emissions"
        value={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="elèctrics i hidrogen · {formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_diesel * 100, 0)} % dièsel · 12 mesos"
        change={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. els 12 mesos anteriors"
        direction="positive-up"
        source="DGT"
    />
</Grid>

## Quota de zero emissions en els vehicles nous

<LineChart
    data={anual_cuota}
    x=anio
    y=cuota_cero
    series=vehiculo
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#0f766e', '#f59e0b']}
    title="Elèctrics purs i hidrogen, % dels matriculats cada any"
/>

<p class="text-xs text-gray-500">Els autobusos urbans s'electrifiquen abans perquè fan recorreguts curts i tornen cada nit a les cotxeres, on es carreguen; els ajuts europeus i les zones de baixes emissions de les ciutats també hi empenyen. El camió de llarg recorregut continua gairebé tot en dièsel: les bateries pesen i la xarxa de recàrrega per a pesants tot just comença. L'últim any és incomplet.</p>

## Autobusos nous per tipus de motor

<BarChart
    data={anual.filter(d => d.grupo === 'autobus')}
    x=anio
    y=unidades
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

## Camions nous per tipus de motor

<BarChart
    data={anual.filter(d => d.grupo === 'camion')}
    x=anio
    y=por_100000
    series=motor
    type=stacked
    yFmt=num0
    yAxisTitle="per 100.000 habitants"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Camions nous matriculats per any, per 100.000 habitants"
/>

<p class="text-xs text-gray-500">Les vendes de camions segueixen el cicle econòmic: cauen en les crisis (2020) i es recuperen amb l'activitat. Inclou camions de tots els pesos i caps tractors; les furgonetes es compten a part.</p>

## Marques i grups més venuts

```sql marcas
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_marcas_mensual)
SELECT
    m.grupo,
    CASE m.grupo WHEN 'camion' THEN 'Camiones' ELSE 'Autobuses' END AS vehiculo,
    m.grupo_empresarial,
    m.marca,
    sum(m.matriculaciones) AS unidades
FROM mother.movilidad_marcas_mensual m, ult u
WHERE m.grupo IN ('camion', 'autobus')
  AND m.mes > u.mes - INTERVAL 12 MONTH
GROUP BY ALL
```

```sql grupos
WITH g AS (
    SELECT
        vehiculo,
        grupo_empresarial AS grupo,
        string_agg(marca, ', ' ORDER BY unidades DESC) AS marcas,
        sum(unidades) AS unidades
    FROM ${marcas}
    GROUP BY vehiculo, grupo_empresarial
)
SELECT *
FROM (
    SELECT *,
        unidades / sum(unidades) OVER (PARTITION BY vehiculo) AS cuota,
        row_number() OVER (PARTITION BY vehiculo ORDER BY unidades DESC) AS puesto
    FROM g
)
WHERE puesto <= 10
ORDER BY vehiculo DESC, unidades DESC
```

Els deu grups amb més matriculacions dels últims 12 mesos. En els vehicles que acaba un carrosser (la majoria dels autobusos i molts camions) es compta la marca del xassís: un autobús amb carrosseria d'Irizar o Castrosua sobre un xassís Scania compta com a Scania.

<DataTable data={grupos} rows=20 groupBy=vehiculo groupsOpen=true>
    <Column id=grupo title="Grup" />
    <Column id=marcas title="Marques" wrap=true />
    <Column id=unidades title="Unitats" fmt=num0 />
    <Column id=cuota title="Quota" fmt=pct1 contentType=bar barColor="#ddd6fe" />
</DataTable>

<p class="text-xs text-gray-500">Grup segons el propietari majoritari: Scania i MAN són del grup Volkswagen (Traton); Volvo i Renault Trucks, d'AB Volvo (diferent de Volvo Cars, que és de Geely); Mercedes-Benz, Setra i Fuso, de Daimler Truck. El rànquing complet, per mes i per tipus de motor, és a <a href="/ca/movilidad/marcas-y-modelos">Marques i models</a>.</p>

## Antiguitat dels que circulen

```sql antiguedad
SELECT
    CASE grupo WHEN 'camion' THEN 'Camiones' WHEN 'autobus' THEN 'Autobuses' ELSE 'Turismos' END AS vehiculo,
    antiguedad,
    CASE antiguedad WHEN '0-4' THEN 1 WHEN '5-9' THEN 2 WHEN '10-14' THEN 3 WHEN '15-19' THEN 4 WHEN '20+' THEN 5 ELSE 6 END AS orden,
    CASE antiguedad WHEN '0-4' THEN 'Menos de 5 años' WHEN '5-9' THEN '5 a 9 años' WHEN '10-14' THEN '10 a 14 años'
        WHEN '15-19' THEN '15 a 19 años' WHEN '20+' THEN '20 años o más' ELSE 'Sin dato' END AS tramo,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo IN ('camion', 'autobus', 'turismo')
  AND mes = (SELECT max(mes) FROM mother.movilidad_parque_provincia)
GROUP BY ALL
ORDER BY orden
```

```sql tramos
SELECT DISTINCT tramo, orden FROM ${antiguedad} ORDER BY orden
```

<BarChart
    data={antiguedad}
    x=vehiculo
    y=vehiculos
    series=tramo
    type=stacked100
    swapXY=true
    yFmt=pct0
    seriesOrder={tramos.map(d => d.tramo)}
    colorPalette={['#0f766e', '#5eead4', '#fde68a', '#f59e0b', '#b91c1c', '#d1d5db']}
    title="Vehicles en circulació per antiguitat (els turismes, com a referència)"
/>

<p class="text-xs text-gray-500">Parc de vehicles d'alta de la DGT, últim mes publicat. Més detall, per província i municipi, a <a href="/ca/movilidad/parque">Parc de vehicles</a>.</p>

---

## Fonts i notes

- **[DGT – Microdades de matriculacions de vehicles (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual des del gener del 2015. Només matriculacions ordinàries de vehicles nous.
- **[DGT – Parc de vehicles](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**, últim mes publicat.
- Camions: els tipus de camió i cap tractor de la DGT, de qualsevol pes. Autobusos: autobusos i autocars, inclosos els articulats i els de dos pisos. Zero emissions: elèctrics purs (BEV) i de pila d'hidrogen.

<LastRefreshed prefix="Dades actualitzades" />
