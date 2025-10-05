---
title: SpainFacts 
---

# Nuestra Población Cambiante: España

SpainFacts es una iniciativa dedicada a proporcionar datos transparentes y objetivos sobre España. Inspirados en la visión de USAFacts, nuestro objetivo es ofrecer información precisa y accesible sobre la población, economía, salud y otros aspectos clave de la sociedad española, para fomentar una comprensión informada y basada en evidencia.

La población de España ha experimentado un crecimiento significativo en las últimas décadas, impulsado principalmente por la inmigración y un saldo vegetativo positivo en periodos recientes.

| Población en {inputs.año_inicio.value} | Población en {inputs.año_fin.value}   | Cambio de población |
| -------- | -------- | -------- |
|<Value data={total_poblacion_year_inicio} column=Total fmt='#,##0.00,,"M"'/>  |  <Value data={total_poblacion_year_fin} column=Total fmt='#,##0.00,,"M"'/>   | {fmt((((total_poblacion_year_fin[0].Total-total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total) ), '#,##0.00%')}|

<Dropdown 
    name=año_inicio
    data={items}
    value=Year
/>
<Dropdown 
    name=año_fin
    data={items}
    value=Year
    defaultValue="2024"
/>


```sql total_poblacion_year_inicio
  SELECT 
      Year,Total
  FROM mother.totalAno
  WHERE 
    Year= '${inputs.año_inicio.value}'
```
```sql total_poblacion_year_fin
 SELECT 
      Year,Total
  FROM mother.totalAno
  WHERE 
    Year= '${inputs.año_fin.value}'
```


<LastRefreshed />

## ¿Cómo ha cambiado la población en España?
```sql items
 SELECT  Year
  FROM mother.totalAno
``` 


```sql poblacion_variacion_anual  
WITH Poblacion_Anual AS (
    -- Paso 1: Tu consulta base para obtener el total de población por año
    SELECT 
        CAST(Year AS INT) AS Year,
        Total AS Poblacion_Actual
    FROM mother.totalAno
    WHERE Year BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value}
)
SELECT 
    Year,
    Poblacion_Actual,
    -- Paso 2: Usar LAG() para obtener la población del año anterior
    LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC) AS Poblacion_Anterior,
    
    -- Paso 3: Calcular la Variación Absoluta (Población Actual - Población Anterior)
    Poblacion_Actual - LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC) AS Variacion_Absoluta,
    
    -- Paso 4: Calcular la Variación Porcentual Anual
    (CAST(Poblacion_Actual AS DECIMAL) - LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC)) * 100.0 / LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC) AS Variacion_Porcentual
FROM Poblacion_Anual
ORDER BY Year ASC;
```

<BarChart
  data={poblacion_variacion_anual}
  title="Variación anual de la población en España"
  x="Year"
  y="Variacion_Porcentual"
  y2="Variacion_Absoluta"
  yAxisTitle="Variación Porcentual (%)"
  curve="linear"
  yScale={true}
  echartsOptions={{
    yAxis: [
  {
    // Primary y-axis
    type: 'value'
  },
  {
    // Secondary y-axis (y2)
    type: 'value',
    position: 'right',
    axisLine: { show: false },
    axisLabel: { show: false },
    axisTick: { show: false },
    splitLine: { show: false }
  }
]   ,
    series: [
      {
        name: 'Variacion_Porcentual',
        type: 'bar',
        barWidth: '90%',
        encode: {
          x: 'Year',
          y: 'Variacion_Porcentual'
        }
      },
      {
        name: 'Variacion_Absoluta',
        type: 'bar',
        yAxisIndex: 1,
        encode: {
          x: 'Year',
          y: 'Variacion_Absoluta'
        },
        barWidth: '1%',
        itemStyle: {
          opacity: 0,
          width: 0
        },
        show: true
      }
    ]
  }}
/>


La poblacion de España ha crecido {fmt((((total_poblacion_year_fin[0].Total-total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total) ), '#,##0.00%')} entre {inputs.año_inicio.value} y {inputs.año_fin.value}.Desde <Value data={total_poblacion_year_inicio} column=Total fmt='#.###0,00,,"M"'/> hasta <Value data={total_poblacion_year_fin} column=Total fmt='#,##0.00,,"M"'/>.



<LineChart
  data={poblacion_variacion_anual}
  title="Evolución de la población total de España"
  x="Year"
  y="Poblacion_Actual"
  yAxisTitle="Población Total"
  curve="linear"
  yScale=true
/>

## Población por sexo


```sql poblacion_por_sexo
  SELECT Year,Sexo, Total
  FROM mother.totalAnoSexo
  WHERE Year between ${inputs.año_inicio.value} AND ${inputs.año_fin.value}
```
```sql donut_data_inicio
select Sexo as name, Total as value
from ${poblacion_por_sexo}
where Year = ${inputs.año_inicio.value}
```
```sql donut_data_fin
select Sexo as name, Total as value
from ${poblacion_por_sexo}
where Year = ${inputs.año_fin.value}
```
<Grid cols=2>
<Group>
Año {inputs.año_inicio.value}
<ECharts config={
    {
        tooltip: {
            formatter: '{b}: {c} ({d}%)'
        },
          legend: {
    top: '5%',
    left: 'center'
  },
      series: [
        {
          type: 'pie',
               label: {
        show: false,
        position: 'center'
      },
          radius: ['40%', '70%'],
          data: [...donut_data_inicio],
        }
      ]
      }
    }
/>
</Group>
<Group>
Año {inputs.año_fin.value}
<ECharts config={
    {
        tooltip: {
            formatter: '{b}: {c} ({d}%)'
        },
          legend: {
    top: '5%',
    left: 'center'
  },
      series: [
        {
          type: 'pie',
               label: {
        show: false,
        position: 'center'
      },
          radius: ['40%', '70%'],
          data: [...donut_data_fin],
        }
      ]
      }
    }
/>
</Group>
</Grid>

```sql poblacion_por_sexo3
 WITH hombres AS (
  SELECT 
    Year, 
    "Sexo", 
    Total
  FROM ${poblacion_por_sexo}
  WHERE Sexo = 'Hombres' 
),
mujeres AS (
  SELECT 
    Year, 
    "Sexo", 
    Total
  FROM ${poblacion_por_sexo}
  WHERE Sexo = 'Mujeres'
)
SELECT 
  h.Year, 
  h.Total AS Hombres, 
  m.Total AS Mujeres, 
  CAST(m.Total AS DECIMAL) / CAST(h.Total AS DECIMAL) AS Ratio_Mujeres_Hombres
FROM hombres h
INNER JOIN mujeres m ON h.Year = m.Year
ORDER BY h.Year DESC;


```



<LineChart
  data={poblacion_por_sexo3}
  title="Población por sexo a lo largo del tiempo"
  x="Year"
  y={["Hombres", "Mujeres"]}
  y2="Ratio_Mujeres_Hombres"
  xAxisTitle="Año"
  yAxisTitle="Población"
  yScale=true
  y2Scale=true
/>


```sql poblacion_por_sexo_edad
  SELECT *
  FROM mother.totalAnoSexoEdad
```


## ¿Dónde viven las personas en España? 
La distribución geográfica de la población en España varía significativamente entre comunidades autónomas. A continuación, se muestra un mapa que ilustra la población por comunidad autónoma.
<Tabs>
 
    <Tab label="Poblacion Total en {inputs.año_inicio.value}">
           <AreaMap 
    data={orders_by_state_inicio} 
    areaCol="statecode"
    geoJsonUrl="./spain-provinces.geojson"
    geoId="cod_prov"
    value="Población"
    tooltip={[
    {id: 'Provincias', fmt: 'id', showColumnName: false, valueClass: 'text-xl font-semibold'},
    {id: 'Población', fieldClass: 'text-[grey]', valueClass: 'text-[green]'}
    ]}  />
 
   <DataTable data={orders_by_state_inicio}/> 

    </Tab>


    <Tab label="Poblacion Total en {inputs.año_fin.value}">
           <AreaMap 
    data={orders_by_state_fin} 
    areaCol="statecode"
    geoJsonUrl="./spain-provinces.geojson"
    geoId="cod_prov"
    value="Población"
    colorPalette={[ '#0f1a5d','#e4d7f7',]}
    tooltip={[
    {id: 'Provincias', fmt: 'id', showColumnName: false, valueClass: 'text-xl font-semibold'},
    {id: 'Población', fieldClass: 'text-[grey]', valueClass: 'text-[green]'}
]}  />
    </Tab>
        <Tab label="Cambio en #">
           <AreaMap 
    data={orders_by_state_diff} 
    areaCol="statecode"
    geoJsonUrl="./spain-provinces.geojson"
    geoId="cod_prov"
    value="Cambio_Absoluto"
    colorPalette={['#bf6f2f', '#1c4738']}
    tooltip={[
    {id: 'Provincias', fmt: 'id', showColumnName: false, valueClass: 'text-xl font-semibold'},
    {id: 'Cambio_Absoluto', fieldClass: 'text-[grey]', valueClass: 'text-[green]'}
]}  />
    </Tab>
    
    
            <Tab label="Cambio en %">
           <AreaMap 
    data={orders_by_state_diff} 
    areaCol="statecode"
    geoJsonUrl="./spain-provinces.geojson"
    geoId="cod_prov"
    value="Porcentaje_Cambio"
    colorPalette={['#bf6f2f', '#1c4738']}
    tooltip={[
    {id: 'Provincias', fmt: 'id', showColumnName: false, valueClass: 'text-xl font-semibold'},
    {id: 'Porcentaje_Cambio', fieldClass: 'text-[grey]', valueClass: 'text-[green]'}
]}  />
    </Tab>
</Tabs>

```sql orders_by_state_inicio
  SELECT statecode, Provincias, Población
  FROM mother.totalAnoProvincia 
  WHERE Year=${inputs.año_inicio.value}
``` 
```sql orders_by_state_fin
    SELECT statecode, Provincias, Población
  FROM mother.totalAnoProvincia 
  WHERE Year=${inputs.año_fin.value}
``` 
```sql orders_by_state_diff

SELECT
i.statecode,
    i.Provincias,
    i.Población as Poblacion_Inicio,
    f.Población as Poblacion_Fin,
    -- Cálculo de la RESTA: Cambio absoluto
    (f.Población - i.Población) AS Cambio_Absoluto,
    -- Cálculo del PORCENTAJE DE CAMBIO
    -- Usamos CAST(AS FLOAT) para asegurar una división decimal precisa.
    (CAST((f.Población - i.Población) AS FLOAT) / i.Población) * 100 AS Porcentaje_Cambio
FROM
    ${orders_by_state_inicio} i
INNER JOIN
    ${orders_by_state_fin} f ON i.statecode = f.statecode;
``` 
## ¿Cómo es la distribución de edades en España?

España presenta una población envejecida, con un alto porcentaje de personas mayores de 65 años (alrededor del 20,91%). Para esta sección, considera cargar datos de edad desde INE (e.g., tabla con grupos quinquenales). Aquí un ejemplo asumiendo una tabla "poblacion_edad".


## Distribución por edad y sexo

Para una pirámide poblacional, Evidence soporta visualizaciones avanzadas. Ejemplo con datos de 2024 (0-4 años: 1.726.528 total, etc.). Integra datos reales en tu DB para interactividad.

## Próximos Pasos

- Explorar más datos sobre inmigración detallada por país de origen
- Integrar datos de edad y crear pirámides poblacionales interactivas
- Conectar nuevas fuentes como series temporales completas de INE
- Desarrollar secciones sobre diversidad étnica y migración

## Recursos
- [Instituto Nacional de Estadística (INE) - Población residente](https://www.ine.es/jaxiT3/Tabla.htm?t=56938)
- [INE - Cifras de población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951)
- [INE - Población por nacionalidad](https://www.ine.es/jaxiT3/Tabla.htm?t=59587)
---
