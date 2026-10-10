---
title: Salaris
description: "Salari mitjà a Espanya descomptada la inflació, el seu creixement real i nominal, per sector i jornada, i la distribució per decils."
i18n_origen: c141d7649501
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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

# 💶 Salaris

Quant es cobra a Espanya i si el sou dona per a més o per a menys que abans. Tots els imports són el **cost salarial brut per treballador i mes**, amb les pagues extres prorratejades, i es mostren **descomptada la inflació**, en euros del {trimestral[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="Salari mitjà"
        value={anual.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.salario_real, 0)} €/mes"
        period="brut el {anual.slice(-1)[0]?.anio} · {formatNumber(anual.slice(-1)[0]?.salario_anual_real, 0)} € l'any"
        change={anual.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real respecte a l'any anterior"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => ({...d, y: d.salario_real}))}
    />
    <KpiCard
        title="Pujada real de l'últim trimestre"
        value={trimestral.slice(-1)[0]?.interanual_real}
        formattedValue="{trimestral.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(trimestral.slice(-1)[0]?.interanual_real, 1)} %"
        period="{trimestral.slice(-1)[0]?.periodo} respecte a un any abans · {formatNumber(trimestral.slice(-1)[0]?.interanual_nominal, 1)} % sense descomptar la inflació"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={trimestral.filter(d => d.interanual_real != null).slice(-20).map(d => ({...d, y: d.interanual_real}))}
    />
    <KpiCard
        title="Respecte al 2008"
        value={hitos_salario[0]?.real_vs2008}
        formattedValue="{hitos_salario[0]?.real_vs2008 >= 0 ? '+' : ''}{formatNumber(hitos_salario[0]?.real_vs2008, 1)} %"
        period="poder adquisitiu del salari mitjà el {hitos_salario[0]?.anio_ult} · +{formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % en euros de cada any"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => ({...d, y: d.salario_real}))}
    />
    <KpiCard
        title="Salari del decil central"
        value={deciles_ult.find(d => d.decil === 5)?.salario_real}
        formattedValue="{formatNumber(deciles_ult.find(d => d.decil === 5)?.salario_real, 0)} €/mes"
        period="el que cobra l'assalariat típic (decil 5 de l'EPA) el {deciles_ult[0]?.anio}, euros del {deciles_ult[0]?.anio_base}"
        source="INE / EPA"
        sparklineData={deciles.filter(d => d.decil === 5).map(d => ({...d, y: d.salario_real}))}
    />
</Grid>

## El salari mitjà amb inflació i sense

Sense descomptar la inflació, el salari mitjà va pujar un {formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % entre el 2008 i el {hitos_salario[0]?.anio_ult}. Descomptant-la, el sou mitjà compra {#if hitos_salario[0]?.real_vs2008 < 0}un {formatNumber(-hitos_salario[0]?.real_vs2008, 1)} % menys{:else}un {formatNumber(hitos_salario[0]?.real_vs2008, 1)} % més{/if} que el 2008, i el màxim real de la sèrie és del {hitos_salario[0]?.anio_max}.

<LineChart
    data={anual_largo}
    x=anio
    y=salario
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ bruts al mes"
    startingAtZero={false}
    title="Salari mitjà mensual: euros del {trimestral[0]?.anio_euros} davant d'euros de cada any"
/>

## Creixement dels salaris

Pujada anual del salari mitjà, descomptant la inflació i sense descomptar-la. Quan la barra real és negativa, el sou compra menys que l'any anterior encara que hagi pujat en euros.

<BarChart
    data={crecimientos}
    x=anio
    y=crecimiento
    series=tipo
    type=grouped
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Creixement anual del salari mitjà: nominal i real"
/>

<LineChart
    data={interanual_largo}
    x=trimestre
    y=variacion
    series=tipo
    yFmt='0.0"%"'
    yAxisTitle="% interanual"
    title="Variació interanual del salari per trimestre"
/>

## Per sector i jornada

Salari mitjà mensual en euros del {trimestral[0]?.anio_euros}. Una part de la diferència entre sectors es deu al fet que alguns tenen molta més ocupació a temps parcial.

<LineChart
    data={por_sector}
    x=anio
    y=salario_real
    series=sector
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reals)"
    startingAtZero={false}
    title="Salari mitjà real per sector"
/>

<LineChart
    data={por_jornada}
    x=anio
    y=salario_real
    series=jornada
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reals)"
    title="Salari mitjà real per tipus de jornada"
/>

```sql por_ccaa
SELECT
    s.cod,
    t.nombre AS comunidad,
    '/ca' || t.ruta AS ruta,
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

## Per comunitat autònoma

Salari mitjà mensual brut el {por_ccaa[0]?.anio}, en euros del {por_ccaa[0]?.anio_euros}. {por_ccaa[0]?.comunidad} encapçala la llista amb {formatNumber(por_ccaa[0]?.salario_real, 0)} € i {por_ccaa.slice(-1)[0]?.comunidad} la tanca amb {formatNumber(por_ccaa.slice(-1)[0]?.salario_real, 0)} €. Són euros sense corregir pel cost de la vida, que també varia entre comunitats. Ceuta i Melilla no es publiquen per separat.

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'salario_real', title: 'Salari mitjà', fmt: '#,##0" €"'},
        {id: 'indice_espana', title: 'Espanya = 100', fmt: '0.0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunitat"/>
    <Column id=salario_real title="Salari (€/mes)" fmt='#,##0'/>
    <Column id=indice_espana title="Espanya = 100" fmt='0.0'/>
    <Column id=crecimiento_real title="Creixement real darrer any (%)" fmt='0.0' contentType=delta/>
    <Column id=cambio_2008 title="Real des del 2008 (%)" fmt='0.0' contentType=delta/>
    <Column id=coste_laboral_real title="Cost total per a l'empresa (€/mes)" fmt='#,##0'/>
</DataTable>

## Com es reparteix: decils

La mitjana l'inflen els sous més alts. L'EPA ordena tots els assalariats de menor a major salari i els divideix en deu grups iguals (decils); el decil 5 és el sou típic. Dades del {deciles_ult[0]?.anio}, descomptada la inflació.

<BarChart
    data={deciles_ult}
    x=nombre_decil
    y=salario_real
    yFmt='#,##0" €"'
    yAxisTitle="€ bruts al mes"
    title="Salari mitjà de cada decil el {deciles_ult[0]?.anio} (euros del {deciles_ult[0]?.anio_base})"
/>

<LineChart
    data={deciles_evol}
    x=anio
    y=salario_real
    series=grupo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reals)"
    title="Evolució real dels sous baixos, mitjans i alts"
/>

Els salaris públics i el seu cost són a [Ocupació pública](/ca/cuentas-publicas/empleo-publico).

---

**Fonts:** [INE, Enquesta trimestral de cost laboral, taula 6038](https://www.ine.es/jaxiT3/Tabla.htm?t=6038) (cost salarial per treballador i mes a la indústria, la construcció i els serveis; la mitjana anual és la dels seus quatre trimestres) i [INE, EPA, salaris per decils, taula 66250](https://www.ine.es/jaxiT3/Tabla.htm?t=66250); per comunitat, [ETCL, taula 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactats amb l'IPC general de l'INE (base 2025).
