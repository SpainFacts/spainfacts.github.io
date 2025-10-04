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
       RIGHT("Periodo",4) as Year, 
      SUM(CAST(REPLACE("Total", ',', '') AS BIGINT))/COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE 
      "Edad simple" = 'Todas las edades' 
      AND "Sexo" = 'Total' 
      AND "Provincias" = 'Total Nacional' 
      AND  RIGHT("Periodo",4)= '${inputs.año_inicio.value}'
      AND "Total" IS NOT NULL

  GROUP BY RIGHT("Periodo",4)

```
```sql total_poblacion_year_fin
   SELECT 
       RIGHT("Periodo",4) as Year, 
      SUM(CAST(REPLACE("Total", ',', '') AS BIGINT))/COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE 
      "Edad simple" = 'Todas las edades' 
      AND "Sexo" = 'Total' 
      AND "Provincias" = 'Total Nacional' 
      AND  RIGHT("Periodo",4)= '${inputs.año_fin.value}'
      AND "Total" IS NOT NULL

  GROUP BY RIGHT("Periodo",4)
```


<LastRefreshed />

## ¿Cómo ha cambiado la población en España?
```sql items
 SELECT 
       RIGHT("Periodo",4) as Year, 
  FROM mother.poblacion_provincias
  WHERE 
      "Edad simple" = 'Todas las edades' 
      AND "Sexo" = 'Total' 
      AND "Provincias" = 'Total Nacional' 
  GROUP BY RIGHT("Periodo",4)
``` 
```sql items
 SELECT 
       RIGHT("Periodo",4) as Year, 
  FROM mother.poblacion_provincias
  WHERE 
      "Edad simple" = 'Todas las edades' 
      AND "Sexo" = 'Total' 
      AND "Provincias" = 'Total Nacional' 
  GROUP BY RIGHT("Periodo",4)
``` 

```sql poblacion_variacion_anual  
WITH Poblacion_Anual AS (
    -- Paso 1: Tu consulta base para obtener el total de población por año
    SELECT 
        CAST(RIGHT("Periodo",4) AS INT) AS Year, 
        SUM(CAST(REPLACE("Total", ',', '') AS BIGINT)) / COUNT("Total") AS Poblacion_Actual
    FROM mother.poblacion_provincias
    WHERE 
        "Edad simple" = 'Todas las edades' 
        AND "Sexo" = 'Total' 
        AND "Provincias" = 'Total Nacional' 
        AND "Total" IS NOT NULL
        AND CAST(RIGHT("Periodo",4) AS INT) BETWEEN 1971 AND 2024
    GROUP BY RIGHT("Periodo",4)
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


```sql total_poblacion
 SELECT 
       CAST(RIGHT("Periodo",4) AS INT) as Year, 
      SUM(CAST(REPLACE("Total", ',', '') AS BIGINT))/COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE 
      "Edad simple" = 'Todas las edades' 
      AND "Sexo" = 'Total' 
      AND "Provincias" = 'Total Nacional' 
      AND "Total" IS NOT NULL
      AND CAST(RIGHT("Periodo",4) AS INT) BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value}

  GROUP BY RIGHT("Periodo",4)
    order by Year ASC
```

<LineChart
  data={total_poblacion}
  title="Evolución de la población total de España"
  x="Year"
  y="Total"
  yAxisTitle="Población Total"
  curve="linear"
  yScale=true
/>

## Población por sexo

La distribución por sexo(número mujeres dividido entre número hombres) era  {fmt((((poblacion_por_sexo[0].Total) / poblacion_por_sexo[1].Total) ), '#,##0.00%')} y es {fmt((((poblacion_por_sexo[2].Total) / poblacion_por_sexo[3].Total) ), '#,##0.00%')} en {fmt(inputs.año_inicio.value,)} y {inputs.año_fin.value} respectivamente.

```sql poblacion_por_sexo
  SELECT RIGHT("Periodo",4) as Year, "Sexo", SUM(CAST(REPLACE(Total, ',', '') AS BIGINT))/COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE "Provincias" = 'Total Nacional' AND "Sexo" != 'Total' and "Edad simple" = 'Todas las edades' and (RIGHT("Periodo",4) =${inputs.año_inicio.value} OR RIGHT("Periodo",4) =${inputs.año_fin.value})
  GROUP BY  RIGHT("Periodo",4), "Sexo"
  ORDER BY Year DESC, Total DESC
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
    CAST(RIGHT("Periodo", 4) AS INT) AS Year, 
    "Sexo", 
    SUM(CAST(REPLACE(Total, ',', '') AS BIGINT)) / COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE "Provincias" = 'Total Nacional' 
    AND "Sexo" != 'Total' 
    AND "Edad simple" = 'Todas las edades' 
    AND CAST(RIGHT("Periodo", 4) AS INT) BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value} 
    AND Sexo = 'Hombres' 
  GROUP BY RIGHT("Periodo", 4), "Sexo"
  ORDER BY Year DESC, Total DESC
),
mujeres AS (
  SELECT 
    CAST(RIGHT("Periodo", 4) AS INT) AS Year, 
    "Sexo", 
    SUM(CAST(REPLACE(Total, ',', '') AS BIGINT)) / COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE "Provincias" = 'Total Nacional' 
    AND "Sexo" != 'Total' 
    AND "Edad simple" = 'Todas las edades' 
    AND CAST(RIGHT("Periodo", 4) AS INT) BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value} 
    AND Sexo = 'Mujeres'
  GROUP BY RIGHT("Periodo", 4), "Sexo"
  ORDER BY Year DESC, Total DESC
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



```sql poblacion_por_sexo2
  SELECT "Edad simple",RIGHT("Periodo",4) as Year, "Sexo", SUM(CAST(REPLACE(Total, ',', '') AS BIGINT))/COUNT(Total) AS Total
  FROM mother.poblacion_provincias
  WHERE "Provincias" = 'Total Nacional' AND "Sexo" != 'Total' and "Edad simple" != 'Todas las edades' and RIGHT("Periodo",4) =${inputs.año_inicio.value} and Total IS NOT NULL
  GROUP BY  RIGHT("Periodo",4), "Sexo","Edad simple"
  ORDER BY Year DESC, Total DESC
```

```sql poblacion_por_sexo_edad
WITH EdadesLimpias AS (
    -- Paso 1: Limpiar y convertir el campo "Edad simple" a un número entero (EdadNumerica)
    SELECT
        "Edad simple",
        RIGHT("Periodo", 4) AS Year,
        "Sexo",
        -- Expresión de Extracción de Edad Mejorada y Completa:
        CASE
            -- Manejar los casos especiales que causan errores de conversión
            WHEN "Edad simple" LIKE '%85 y más%' THEN 86
            WHEN "Edad simple" LIKE '+100 años' THEN 100 -- Caso +100 años añadido
            -- El resto de los casos son numéricos y se limpian antes de la conversión
            ELSE 
                CAST(
                    REPLACE(
                        REPLACE("Edad simple", ' años', ''),
                        ' año', ''
                    ) AS INT
                )
        END AS EdadNumerica,
        SUM(CAST(REPLACE(Total, ',', '') AS BIGINT)) / COUNT(Total) AS TotalPromedio
    FROM
        mother.poblacion_provincias
    WHERE
        "Provincias" = 'Total Nacional'
        AND "Sexo" != 'Total'
        AND "Edad simple" != 'Todas las edades'
        AND RIGHT("Periodo", 4) = '1971'
        AND Total IS NOT NULL
    GROUP BY
        "Edad simple",
        RIGHT("Periodo", 4),
        "Sexo"
)
SELECT
    -- Paso 2: Crear el rango de edad con intervalos de 5 años NO SOLAPADOS (0-5, 6-10, 11-15)
    -- Calcular el inicio del rango:
    CAST(
        (CASE
            WHEN EdadNumerica = 0 THEN 0
            ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
        END) AS VARCHAR
    ) || '-' ||
    -- Calcular el fin del rango:
    CAST(
        (CASE
            WHEN EdadNumerica = 0 THEN 5 -- 0 años es un caso especial
            ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 5
        END) AS VARCHAR
    ) || ' años' AS RangoEdad,
    Year,
    "Sexo",
    SUM(TotalPromedio) AS TotalAgrupado
FROM
    EdadesLimpias
GROUP BY
    RangoEdad,
    Year,
    "Sexo",
    -- Agrupamos por el inicio numérico del rango para una ordenación correcta
    (CASE
        WHEN EdadNumerica = 0 THEN 0
        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
    END)
ORDER BY
    Year DESC,
    (CASE
        WHEN EdadNumerica = 0 THEN 0
        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
    END) DESC;
 
```


## ¿Cómo ha cambiado la composición nacional en España?

La población extranjera ha crecido notablemente, representando alrededor del 13-15% de la población total en años recientes. Asumiendo que tu tabla incluye un campo "Nacionalidad" (o ajusta según "Lugar de nacimiento": 'España' vs 'Extranjero'), aquí una visualización comparativa.



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
  SELECT SUBSTRING("Provincias",1,2) as statecode,SUBSTRING("Provincias",3) as Provincias, SUM(CAST(REPLACE(Total, ',', '') AS BIGINT))/COUNT(Total) AS "Población"
  FROM mother.poblacion_provincias 
  WHERE "Edad simple" = 'Todas las edades' AND "Sexo" = 'Total' AND RIGHT("Periodo",4) =${inputs.año_inicio.value} and "Provincias" != 'Total Nacional' and Total is not null
  GROUP BY "Provincias"
``` 
```sql orders_by_state_fin
  SELECT SUBSTRING("Provincias",1,2) as statecode,SUBSTRING("Provincias",3) as Provincias, SUM(CAST(REPLACE(Total, ',', '') AS BIGINT))/COUNT(Total) AS "Población"
  FROM mother.poblacion_provincias 
  WHERE "Edad simple" = 'Todas las edades' AND "Sexo" = 'Total' AND RIGHT("Periodo",4) =${inputs.año_fin.value} and "Provincias" != 'Total Nacional' and Total is not null
  GROUP BY "Provincias"
``` 
```sql orders_by_state_diff
  WITH orders_by_state_inicio AS (
    SELECT
        SUBSTRING("Provincias", 1, 2) AS statecode,
        SUBSTRING("Provincias", 3) AS Provincias,
        SUM(CAST(REPLACE(Total, ',', '') AS BIGINT)) / COUNT(Total) AS Poblacion_Inicio
    FROM
        mother.poblacion_provincias
    WHERE
        "Edad simple" = 'Todas las edades'
        AND "Sexo" = 'Total'
        AND RIGHT("Periodo", 4) = ${inputs.año_inicio.value}
        AND "Provincias" != 'Total Nacional'
        AND Total IS NOT NULL
    GROUP BY
        "Provincias"
),
orders_by_state_fin AS (
    SELECT
        SUBSTRING("Provincias", 1, 2) AS statecode,
        SUBSTRING("Provincias", 3) AS Provincias,
        SUM(CAST(REPLACE(Total, ',', '') AS BIGINT)) / COUNT(Total) AS Poblacion_Fin
    FROM
        mother.poblacion_provincias
    WHERE
        "Edad simple" = 'Todas las edades'
        AND "Sexo" = 'Total'
        AND RIGHT("Periodo", 4) = ${inputs.año_fin.value}
        AND "Provincias" != 'Total Nacional'
        AND Total IS NOT NULL
    GROUP BY
        "Provincias"
)
SELECT
i.statecode,
    i.Provincias,
    i.Poblacion_Inicio,
    f.Poblacion_Fin,
    -- Cálculo de la RESTA: Cambio absoluto
    (f.Poblacion_Fin - i.Poblacion_Inicio) AS Cambio_Absoluto,
    -- Cálculo del PORCENTAJE DE CAMBIO
    -- Usamos CAST(AS FLOAT) para asegurar una división decimal precisa.
    (CAST((f.Poblacion_Fin - i.Poblacion_Inicio) AS FLOAT) / i.Poblacion_Inicio) * 100 AS Porcentaje_Cambio
FROM
    orders_by_state_inicio i
INNER JOIN
    orders_by_state_fin f ON i.statecode = f.statecode;
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
