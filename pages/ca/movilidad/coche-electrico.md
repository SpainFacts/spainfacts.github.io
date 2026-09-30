---
title: Cotxe elèctric
description: "Transició al cotxe elèctric a Espanya: matriculacions de turismes per tipus de motor cada mes des del 2015, quota d'elèctrics i híbrids endollables per província i emissions de CO2."
i18n_origen: 65c1259ad6d0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql mensual
SELECT
    mes,
    energia,
    energia_etiqueta AS motor,
    energia_orden,
    sum(matriculaciones) AS turismos
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY mes, energia_orden
```

```sql cuota_mensual
SELECT
    mes,
    sum(turismos) FILTER (WHERE energia = 'bev') / sum(turismos) AS cuota_bev,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev')) / sum(turismos) AS cuota_enchufables,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev', 'hev')) / sum(turismos) AS cuota_electrificados,
    sum(turismos) AS total
FROM ${mensual}
GROUP BY mes
ORDER BY mes
```

```sql ultimo
SELECT
    c.*,
    strftime(c.mes, '%m/%Y') AS mes_texto,
    a.cuota_enchufables AS cuota_enchufables_anio_antes,
    a.cuota_bev AS cuota_bev_anio_antes
FROM ${cuota_mensual} c
LEFT JOIN ${cuota_mensual} a ON a.mes = c.mes - INTERVAL 12 MONTH
ORDER BY c.mes DESC
LIMIT 1
```

```sql anual
-- Turismos nuevos por 1.000 habitantes (padrón del año; el último para los más recientes)
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.motor,
    m.energia_orden,
    sum(m.turismos) AS turismos,
    1000.0 * sum(m.turismos) / any_value(p.poblacion) AS por_1000
FROM ${mensual} m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
GROUP BY ALL
ORDER BY anio, m.energia_orden
```

```sql co2
SELECT
    mes,
    sum(co2_medio * matriculaciones) / sum(matriculaciones) AS co2_medio
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N' AND co2_medio IS NOT NULL
GROUP BY mes
ORDER BY mes
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${mensual} ORDER BY energia_orden
```

# ⚡ La transició al cotxe elèctric

Quants dels cotxes que es venen a Espanya ja són elèctrics? La resposta surt de les microdades de la Direcció General de Trànsit, que registren cada turisme matriculat amb el seu tipus de motor.

<Grid cols=3>
    <KpiCard
        title="Elèctrics purs"
        value={ultimo[0]?.cuota_bev * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_bev * 100, 1)}
        unit="%"
        period="dels turismes nous · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_bev_anio_antes != null ? ((ultimo[0].cuota_bev - ultimo[0].cuota_bev_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un any abans"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_bev * 100}))}
    />
    <KpiCard
        title="Endollables (elèctrics + híbrids endollables)"
        value={ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="dels turismes nous · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_enchufables_anio_antes != null ? ((ultimo[0].cuota_enchufables - ultimo[0].cuota_enchufables_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un any abans"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Electrificats (inclosos híbrids)"
        value={ultimo[0]?.cuota_electrificados * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_electrificados * 100, 1)}
        unit="%"
        period="dels turismes nous · {ultimo[0]?.mes_texto}"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_electrificados * 100}))}
    />
</Grid>

## Quota de mercat dels turismes nous cada mes

<LineChart
    data={cuota_mensual}
    x=mes
    y={['cuota_bev', 'cuota_enchufables', 'cuota_electrificados']}
    yFmt=pct0
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#14b8a6', '#a3e635']}
    legend=true
    seriesLabels={{cuota_bev: 'Elèctrics purs', cuota_enchufables: 'Elèctrics + endollables', cuota_electrificados: 'Tots els electrificats (amb híbrids)'}}
/>

## Turismes nous per tipus de motor

<BarChart
    data={mensual}
    x=mes
    y=turismos
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="mmm yyyy"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

<p class="text-xs text-gray-500">El dièsel va passar de ser més de la meitat de les vendes el 2015 a una fracció residual; el seu lloc el van ocupar primer la gasolina i després els híbrids. Híbrids no endollables (HEV) inclou els <em>mild hybrid</em> (etiqueta ECO); els d'autonomia estesa (REEV) es compten amb els endollables.</p>

<BarChart
    data={anual}
    x=anio
    y=por_1000
    series=motor
    type=stacked
    yFmt=num1
    yAxisTitle="per 1.000 habitants"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Turismes nous matriculats per any, per 1.000 habitants"
/>

<p class="text-xs text-gray-500">L'últim any és incomplet (fins a l'últim mes publicat).</p>

## Emissions de CO2 dels cotxes nous

<LineChart
    data={co2}
    x=mes
    y=co2_medio
    yFmt=num0
    xFmt="mmm yyyy"
    yAxisTitle="g CO2/km"
    colorPalette={['#78716c']}
/>

<p class="text-xs text-gray-500">Mitjana de les emissions homologades dels turismes nous (g/km, elèctrics inclosos amb 0). La pujada fins al 2021 té dues causes: el pas del dièsel (que emet menys CO2 per quilòmetre) a la gasolina i el canvi de cicle d'homologació de NEDC a WLTP, més exigent, que eleva les xifres oficials sense que els cotxes contaminin més. D'aleshores ençà baixen amb l'arribada d'híbrids i elèctrics.</p>

```sql provincias
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_provincia)
SELECT
    p.cod_prov,
    p.provincia,
    sum(p.matriculaciones) AS turismos,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'bev') / sum(p.matriculaciones) AS cuota_bev,
    sum(p.matriculaciones) FILTER (WHERE p.energia IN ('bev', 'phev')) / sum(p.matriculaciones) AS cuota_enchufables,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'diesel') / sum(p.matriculaciones) AS cuota_diesel
FROM mother.movilidad_matriculaciones_provincia p, ult
WHERE p.nuevo_usado = 'N'
  AND p.mes > ult.mes - INTERVAL 12 MONTH
GROUP BY ALL
ORDER BY cuota_enchufables DESC
```

## On es compren més cotxes endollables?

Quota d'elèctrics i híbrids endollables en els turismes nous dels últims 12 mesos, segons la província del domicili del titular.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_enchufables"
    valueFmt="pct1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_enchufables', title: 'Endollables', fmt: 'pct1'},
        {id: 'cuota_bev', title: 'Elèctrics purs', fmt: 'pct1'},
        {id: 'turismos', title: 'Turismes nous', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=turismos title="Turismes nous (12 mesos)" fmt=num0 />
    <Column id=cuota_bev title="Elèctrics purs" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_enchufables title="Endollables" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_diesel title="Dièsel" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Compte amb Madrid i altres províncies amb seus d'empreses de rènting i lloguer: s'hi matriculen flotes que després circulen per tot el país, cosa que n'infla el volum i la quota.</p>

---

## Fonts i notes

- **[DGT – Microdades de matriculacions de vehicles (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual des del gener del 2015. Només es compten les matriculacions ordinàries de turismes (inclosos tot terrenys) **nous**; els usats importats, que també es matriculen per primera vegada a Espanya, s'exclouen.
- El tipus de motor combina la categoria de vehicle elèctric (BEV, PHEV, REEV, HEV) i la propulsió de la fitxa tècnica. Gas inclou GLP i gas natural.
- Les xifres poden diferir lleugerament de les de les associacions del sector (ANFAC, que fa servir els seus propis criteris de data i classificació).

<LastRefreshed prefix="Dades actualitzades" />
