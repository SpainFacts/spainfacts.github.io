---
i18n_origen: a16ce5b323ef
title: Salarios
description: "Salario medio en España descontada a inflación, o seu crecemento real e nominal, por sector e xornada, e a distribución por decís."
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
    'D' || d.decil AS nombre_decil,
    d.salario_mensual,
    d.salario_mensual * f.factor AS salario_real,
    f.anio_base
FROM mother.empleo_salarios_deciles d
JOIN mother.deflactor f ON f.anio = d.anio
WHERE d.jornada = 'Total' AND d.sector = 'Total' AND d.decil > 0
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

Canto se cobra en España e se o soldo dá para máis ou para menos ca antes. Todos os importes son o **custo salarial bruto por traballador e mes**, coas pagas extra rateadas, e móstranse **descontada a inflación**, en euros de {trimestral[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="Salario medio"
        value={anual.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.salario_real, 0)} €/mes"
        period="bruto en {anual.slice(-1)[0]?.anio} · {formatNumber(anual.slice(-1)[0]?.salario_anual_real, 0)} € ao ano"
        change={anual.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real vs. ano anterior"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => d.salario_real)}
    />
    <KpiCard
        title="Suba real do último trimestre"
        value={trimestral.slice(-1)[0]?.interanual_real}
        formattedValue="{trimestral.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(trimestral.slice(-1)[0]?.interanual_real, 1)} %"
        period="{trimestral.slice(-1)[0]?.periodo} vs. un ano antes · {formatNumber(trimestral.slice(-1)[0]?.interanual_nominal, 1)} % sen descontar a inflación"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={trimestral.filter(d => d.interanual_real != null).slice(-20).map(d => d.interanual_real)}
    />
    <KpiCard
        title="Fronte a 2008"
        value={hitos_salario[0]?.real_vs2008}
        formattedValue="{hitos_salario[0]?.real_vs2008 >= 0 ? '+' : ''}{formatNumber(hitos_salario[0]?.real_vs2008, 1)} %"
        period="poder de compra do salario medio en {hitos_salario[0]?.anio_ult} · +{formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % en euros de cada ano"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => d.salario_real)}
    />
    <KpiCard
        title="Salario do decil central"
        value={deciles_ult.find(d => d.decil === 5)?.salario_real}
        formattedValue="{formatNumber(deciles_ult.find(d => d.decil === 5)?.salario_real, 0)} €/mes"
        period="o que cobra o asalariado típico (decil 5 da EPA) en {deciles_ult[0]?.anio}, euros de {deciles_ult[0]?.anio_base}"
        source="INE / EPA"
        sparklineData={deciles.filter(d => d.decil === 5).map(d => d.salario_real)}
    />
</Grid>

## O salario medio con e sen inflación

Sen descontar a inflación, o salario medio subiu un {formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % entre 2008 e {hitos_salario[0]?.anio_ult}. Descontándoa, o soldo medio compra {#if hitos_salario[0]?.real_vs2008 < 0}un {formatNumber(-hitos_salario[0]?.real_vs2008, 1)} % menos{:else}un {formatNumber(hitos_salario[0]?.real_vs2008, 1)} % máis{/if} ca en 2008, e o máximo real da serie é de {hitos_salario[0]?.anio_max}.

<LineChart
    data={anual_largo}
    x=anio
    y=salario
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ brutos ao mes"
    startingAtZero={false}
    title="Salario medio mensual: euros de {trimestral[0]?.anio_euros} fronte a euros de cada ano"
/>

## Crecemento dos salarios

Suba anual do salario medio, con e sen descontar a inflación. Cando a barra real é negativa, o soldo compra menos ca o ano anterior aínda que subise en euros.

<BarChart
    data={crecimientos}
    x=anio
    y=crecimiento
    series=tipo
    type=grouped
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% anual"
    title="Crecemento anual do salario medio: nominal e real"
/>

<LineChart
    data={interanual_largo}
    x=trimestre
    y=variacion
    series=tipo
    yFmt='0.0"%"'
    yAxisTitle="% interanual"
    title="Variación interanual do salario por trimestre"
/>

## Por sector e xornada

Salario medio mensual en euros de {trimestral[0]?.anio_euros}. Unha parte da diferenza entre sectores débese a que algúns teñen moito máis emprego a tempo parcial.

<LineChart
    data={por_sector}
    x=anio
    y=salario_real
    series=sector
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ ao mes (reais)"
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
    yAxisTitle="€ ao mes (reais)"
    title="Salario medio real por tipo de xornada"
/>

```sql por_ccaa
SELECT
    s.cod,
    t.nombre AS comunidad,
    '/gl' || t.ruta AS ruta,
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

## Por comunidade autónoma

Salario medio mensual bruto en {por_ccaa[0]?.anio}, en euros de {por_ccaa[0]?.anio_euros}. {por_ccaa[0]?.comunidad} encabeza a lista con {formatNumber(por_ccaa[0]?.salario_real, 0)} € e {por_ccaa.slice(-1)[0]?.comunidad} péchaa con {formatNumber(por_ccaa.slice(-1)[0]?.salario_real, 0)} €. Son euros sen corrixir polo custo da vida, que tamén varía entre comunidades. Ceuta e Melilla non se publican por separado.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'salario_real', title: 'Salario medio', fmt: '#,##0" €"'},
        {id: 'indice_espana', title: 'España = 100', fmt: '0.0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunidade"/>
    <Column id=salario_real title="Salario (€/mes)" fmt='#,##0'/>
    <Column id=indice_espana title="España = 100" fmt='0.0'/>
    <Column id=crecimiento_real title="Crecemento real último ano (%)" fmt='0.0' contentType=delta/>
    <Column id=cambio_2008 title="Real desde 2008 (%)" fmt='0.0' contentType=delta/>
    <Column id=coste_laboral_real title="Custo total para a empresa (€/mes)" fmt='#,##0'/>
</DataTable>

## Como se reparte: decís

A media ínchana os soldos máis altos. A EPA ordena todos os asalariados de menor a maior salario e divídeos en dez grupos iguais (decís); o decil 5 é o soldo típico. Datos de {deciles_ult[0]?.anio}, descontada a inflación.

<BarChart
    data={deciles_ult}
    x=nombre_decil
    y=salario_real
    yFmt='#,##0" €"'
    yAxisTitle="€ brutos ao mes"
    title="Salario medio de cada decil en {deciles_ult[0]?.anio} (euros de {deciles_ult[0]?.anio_base})"
/>

<LineChart
    data={deciles_evol}
    x=anio
    y=salario_real
    series=grupo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ ao mes (reais)"
    title="Evolución real dos soldos baixos, medios e altos"
/>

Os salarios públicos e o seu custo están en [Emprego público](/gl/cuentas-publicas/empleo-publico).

---

**Fontes:** [INE, Enquisa Trimestral de Custo Laboral, táboa 6038](https://www.ine.es/jaxiT3/Tabla.htm?t=6038) (custo salarial por traballador e mes en industria, construción e servizos; a media anual é a dos seus catro trimestres) e [INE, EPA, salarios por decís, táboa 66250](https://www.ine.es/jaxiT3/Tabla.htm?t=66250); por comunidade, [ETCL, táboa 6061](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactados co IPC xeral do INE (base 2025).
