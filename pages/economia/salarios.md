---
title: Salarios
description: "Salario medio en España descontada la inflación, su crecimiento real y nominal, por sector y jornada, y la distribución por deciles."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT *
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql anual_largo
SELECT anio, 'Descontada la inflación' AS serie, salario_real AS salario FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total'
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, salario_nominal AS salario FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio, serie
```

```sql crecimientos
SELECT anio, 'Nominal' AS tipo, crecimiento_nominal AS crecimiento FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total' AND crecimiento_nominal IS NOT NULL
UNION ALL
SELECT anio, 'Real' AS tipo, crecimiento_real AS crecimiento FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total' AND crecimiento_real IS NOT NULL
ORDER BY anio, tipo
```

```sql trimestral
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, salario_total, salario_total_real, interanual_nominal, interanual_real, anio_euros
FROM mother.economia_salarios
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY trimestre
```

```sql interanual_largo
SELECT trimestre, 'Nominal' AS tipo, interanual_nominal AS variacion FROM mother.economia_salarios WHERE jornada = 'Todas' AND sector = 'Total' AND interanual_nominal IS NOT NULL
UNION ALL
SELECT trimestre, 'Real' AS tipo, interanual_real AS variacion FROM mother.economia_salarios WHERE jornada = 'Todas' AND sector = 'Total' AND interanual_real IS NOT NULL
ORDER BY trimestre, tipo
```

```sql por_sector
SELECT anio, sector, salario_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas'
ORDER BY anio, sector
```

```sql por_jornada
SELECT anio, jornada, salario_real
FROM mother.economia_salarios_anual
WHERE sector = 'Total'
ORDER BY anio, jornada
```

```sql hitos_salario
SELECT
    max(CASE WHEN anio = 2008 THEN salario_real END) AS r2008,
    max(salario_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) AS r_ult,
    max(salario_nominal) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) AS n_ult,
    max(CASE WHEN anio = 2008 THEN salario_nominal END) AS n2008,
    100 * (max(salario_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) / max(CASE WHEN anio = 2008 THEN salario_real END) - 1) AS real_vs2008,
    100 * (max(salario_nominal) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) / max(CASE WHEN anio = 2008 THEN salario_nominal END) - 1) AS nominal_vs2008,
    max(salario_real) AS r_max,
    arg_max(anio, salario_real) AS anio_max,
    max(anio) AS anio_ult
FROM ${anual}
```

```sql deciles
SELECT
    d.anio,
    d.decil,
    d.decil_nombre AS nombre_decil,
    d.salario_mensual,
    d.salario_mensual_real AS salario_real,
    d.anio_euros AS anio_base
FROM mother.empleo_salarios_deciles d
WHERE d.jornada = 'Total' AND d.sector = 'Total' AND d.decil IS NOT NULL
ORDER BY d.anio, d.decil
```

```sql deciles_ult
SELECT * FROM ${deciles} WHERE anio = (SELECT max(anio) FROM ${deciles}) ORDER BY decil
```

```sql deciles_evol
SELECT anio, CASE decil WHEN 1 THEN '10 % peor pagado (D1)' WHEN 5 THEN 'Mitad de la tabla (D5)' ELSE '10 % mejor pagado (D10)' END AS grupo, salario_real
FROM ${deciles}
WHERE decil IN (1, 5, 10)
ORDER BY anio, grupo
```

# 💶 Salarios

Cuánto se cobra en España y si el sueldo da para más o para menos que antes. Todos los importes son el **coste salarial bruto por trabajador y mes**, con las pagas extra prorrateadas, y se muestran **descontada la inflación**, en euros de {trimestral[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="Salario medio"
        value={anual.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.salario_real, 0)} €/mes"
        period="bruto en {anual.slice(-1)[0]?.anio} · {formatNumber(anual.slice(-1)[0]?.salario_anual_real, 0)} € al año"
        change={anual.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => ({...d, y: d.salario_real}))}
    />
    <KpiCard
        title="Subida real del último trimestre"
        value={trimestral.slice(-1)[0]?.interanual_real}
        formattedValue="{trimestral.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(trimestral.slice(-1)[0]?.interanual_real, 1)} %"
        period="{trimestral.slice(-1)[0]?.periodo} vs un año antes · {formatNumber(trimestral.slice(-1)[0]?.interanual_nominal, 1)} % sin descontar la inflación"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={trimestral.filter(d => d.interanual_real != null).slice(-20).map(d => ({...d, y: d.interanual_real}))}
    />
    <KpiCard
        title="Frente a 2008"
        value={hitos_salario[0]?.real_vs2008}
        formattedValue="{hitos_salario[0]?.real_vs2008 >= 0 ? '+' : ''}{formatNumber(hitos_salario[0]?.real_vs2008, 1)} %"
        period="poder de compra del salario medio en {hitos_salario[0]?.anio_ult} · +{formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % en euros de cada año"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => ({...d, y: d.salario_real}))}
    />
    <KpiCard
        title="Salario del decil central"
        value={deciles_ult.find(d => d.decil === 5)?.salario_real}
        formattedValue="{formatNumber(deciles_ult.find(d => d.decil === 5)?.salario_real, 0)} €/mes"
        period="lo que cobra el asalariado típico (decil 5 de la EPA) en {deciles_ult[0]?.anio}, euros de {deciles_ult[0]?.anio_base}"
        source="INE / EPA"
        sparklineData={deciles.filter(d => d.decil === 5).map(d => ({...d, y: d.salario_real}))}
    />
</Grid>

## El salario medio con y sin inflación

Sin descontar la inflación, el salario medio subió un {formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % entre 2008 y {hitos_salario[0]?.anio_ult}. Descontándola, el sueldo medio compra {#if hitos_salario[0]?.real_vs2008 < 0}un {formatNumber(-hitos_salario[0]?.real_vs2008, 1)} % menos{:else}un {formatNumber(hitos_salario[0]?.real_vs2008, 1)} % más{/if} que en 2008, y el máximo real de la serie es de {hitos_salario[0]?.anio_max}.

<LineChart
    data={anual_largo}
    x=anio
    y=salario
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ brutos al mes"
    startingAtZero={false}
    title="Salario medio mensual: euros de {trimestral[0]?.anio_euros} frente a euros de cada año"
/>

## Crecimiento de los salarios

Subida anual del salario medio, con y sin descontar la inflación. Cuando la barra real es negativa, el sueldo compra menos que el año anterior aunque haya subido en euros.

<BarChart
    data={crecimientos}
    x=anio
    y=crecimiento
    series=tipo
    type=grouped
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Crecimiento anual del salario medio: nominal y real"
/>

<LineChart
    data={interanual_largo}
    x=trimestre
    y=variacion
    series=tipo
    yFmt='0.0"%"'
    yAxisTitle="% interanual"
    title="Variación interanual del salario por trimestre"
/>

## Por sector y jornada

Salario medio mensual en euros de {trimestral[0]?.anio_euros}. Una parte de la diferencia entre sectores se debe a que algunos tienen mucho más empleo a tiempo parcial.

<LineChart
    data={por_sector}
    x=anio
    y=salario_real
    series=sector
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reales)"
    startingAtZero={false}
    title="Salario medio real por sector"
/>

<LineChart
    data={por_jornada}
    x=anio
    y=salario_real
    series=jornada
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reales)"
    title="Salario medio real por tipo de jornada"
/>

```sql por_ccaa
SELECT
    s.cod,
    t.nombre AS comunidad,
    t.ruta,
    s.salario_real,
    s.coste_laboral_real,
    s.crecimiento_real,
    s.indice_espana,
    100 * (s.salario_real / b.salario_real - 1) AS cambio_2008,
    CAST(s.anio AS INTEGER) AS anio,
    CAST(s.anio_euros AS INTEGER) AS anio_euros
FROM mother.economia_salarios_ccaa s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
LEFT JOIN mother.economia_salarios_ccaa b ON b.cod = s.cod AND b.anio = 2008
WHERE s.cod <> '00' AND s.anio = (SELECT max(anio) FROM mother.economia_salarios_ccaa)
ORDER BY s.salario_real DESC
```

## Por comunidad autónoma

Salario medio mensual bruto en {por_ccaa[0]?.anio}, en euros de {por_ccaa[0]?.anio_euros}. {por_ccaa[0]?.comunidad} encabeza la lista con {formatNumber(por_ccaa[0]?.salario_real, 0)} € y {por_ccaa.slice(-1)[0]?.comunidad} la cierra con {formatNumber(por_ccaa.slice(-1)[0]?.salario_real, 0)} €. Son euros sin corregir por el coste de la vida, que también varía entre comunidades. Ceuta y Melilla no se publican por separado.

<MapaEspana
    data={por_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="salario_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'salario_real', title: 'Salario medio', fmt: '#,##0" €"'},
        {id: 'indice_espana', title: 'España = 100', fmt: '0.0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunidad"/>
    <Column id=salario_real title="Salario (€/mes)" fmt='#,##0'/>
    <Column id=indice_espana title="España = 100" fmt='0.0'/>
    <Column id=crecimiento_real title="Crecimiento real último año (%)" fmt='0.0' contentType=delta/>
    <Column id=cambio_2008 title="Real desde 2008 (%)" fmt='0.0' contentType=delta/>
    <Column id=coste_laboral_real title="Coste total para la empresa (€/mes)" fmt='#,##0'/>
</DataTable>

## Cómo se reparte: deciles

La media la inflan los sueldos más altos. La EPA ordena a todos los asalariados de menor a mayor salario y los divide en diez grupos iguales (deciles); el decil 5 es el sueldo típico. Datos de {deciles_ult[0]?.anio}, descontada la inflación.

<BarChart
    data={deciles_ult}
    x=nombre_decil
    y=salario_real
    yFmt='#,##0" €"'
    yAxisTitle="€ brutos al mes"
    title="Salario medio de cada decil en {deciles_ult[0]?.anio} (euros de {deciles_ult[0]?.anio_base})"
/>

<LineChart
    data={deciles_evol}
    x=anio
    y=salario_real
    series=grupo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reales)"
    title="Evolución real de los sueldos bajos, medios y altos"
/>

Los salarios públicos y su coste están en [Empleo público](/cuentas-publicas/empleo-publico).

---

**Fuentes:** [INE, Encuesta Trimestral de Coste Laboral, tabla 6038](https://www.ine.es/jaxiT3/Tabla.htm?t=6038) (coste salarial por trabajador y mes en industria, construcción y servicios; la media anual es la de sus cuatro trimestres) y [INE, EPA, salarios por deciles, tabla 66250](https://www.ine.es/jaxiT3/Tabla.htm?t=66250); por comunidad, [ETCL, tabla 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactados con el IPC general del INE (base 2025).
