---
title: SpainFacts 
---
<script>
    // Due to the location that Evidence builds the site, we need to hop up many directories to get to root
    import FranceMap from "../../../../src/lib/charts/maps/FranceMap.svelte";
    import WorldMap from "../../../../src/lib/charts/maps/WorldMap.svelte";
</script>
# Nuestra Población Cambiante: España

SpainFacts es una iniciativa dedicada a proporcionar datos transparentes y objetivos sobre España. Inspirados en la visión de USAFacts, nuestro objetivo es ofrecer información precisa y accesible sobre la población, economía, salud y otros aspectos clave de la sociedad española, para fomentar una comprensión informada y basada en evidencia.

La población de España ha experimentado un crecimiento significativo en las últimas décadas, impulsado principalmente por la inmigración y un saldo vegetativo positivo en periodos recientes.

<div style="display:flex;justify-content:center;gap:1rem;align-items:center;">
  <Dropdown 
    name=año_inicio
    data={items}
    value=Year
    defaultValue="1971"
  />
  <Dropdown 
    name=año_fin
    data={items}
    value=Year
    defaultValue="2024"
  />
</div>

| Población en {inputs.año_inicio.value} | Población en {inputs.año_fin.value}   | Cambio de población |
| -------- | -------- | -------- |
| {(total_poblacion_year_inicio[0].Total / 1e6).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' M'} | {(total_poblacion_year_fin[0].Total / 1e6).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' M'} | {(((total_poblacion_year_fin[0].Total - total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total)).toLocaleString('es-ES', { style: 'percent', minimumFractionDigits: 2, maximumFractionDigits: 2 })} |




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


La población de España ha crecido {(((total_poblacion_year_fin[0].Total - total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total)).toLocaleString('es-ES', { style: 'percent', minimumFractionDigits: 2, maximumFractionDigits: 2 })} entre {inputs.año_inicio.value} y {inputs.año_fin.value}.

Desde {(total_poblacion_year_inicio[0].Total / 1e6).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} M hasta {(total_poblacion_year_fin[0].Total / 1e6).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} M.



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

<div style="text-align:center">Año {inputs.año_inicio.value}</div>
<ECharts config={{
  tooltip: {
    formatter: ({ name, value, percent }) => {
      const millones = value / 1e6;
      const texto = millones.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
      return `${name}: ${texto} M (${percent}%)`;
    }
  },
  legend: {
    top: '5%',
    left: 'center'
  },
  series: [
    {
      type: 'pie',
      radius: ['40%', '70%'],
      label: {
        show: true,
        position: 'inside',
        formatter: ({ value }) => {
          const millones = value / 1e6;
          return `${millones.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} M`;
        }
      },
      data: [...donut_data_inicio]
    }
  ]
}} />
</Group>
<Group>
<div style="text-align:center">Año {inputs.año_fin.value}</div>
<ECharts config={{
  tooltip: {
    formatter: ({ name, value, percent }) => {
      const millones = value / 1e6;
      const texto = millones.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
      return `${name}: ${texto} M (${percent}%)`;
    }
  },
  legend: {
    top: '5%',
    left: 'center'
  },
  series: [
    {
      type: 'pie',
      radius: ['40%', '70%'],
      label: {
        show: true,
        position: 'inside',
        formatter: ({ value }) => {
          const millones = value / 1e6;
          return `${millones.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} M`;
        }
      },
      data: [...donut_data_fin]
    }
  ]
}} />
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
  Cast(h.Year AS INTEGER) AS Year, 
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
<Accordion>
  <AccordionItem title="Poblacion en {inputs.año_inicio.value}">
    <FranceMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_inicio}
      region="statecode"
      value="Población"
      colorScale="bluegreen"
      colorPalette={["#f7fbff", "#b7e3ff", "#5dade2", "#2471a3", "#154360"]}
    />
  </AccordionItem>
  <AccordionItem title="Poblacion en {inputs.año_fin.value}">  
    <FranceMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_fin}
      region="statecode"
      value="Población"
      colorScale="bluegreen"
      colorPalette={["#f7fbff", "#b7e3ff", "#5dade2", "#2471a3", "#154360"]}
    />  
  </AccordionItem>
  <AccordionItem title="Cambio en #">
    <FranceMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_diff}
      region="statecode"
      value="Cambio en #"
      colorScale="bluegreen"
      colorPalette={['#bf6f2f', '#1c4738']}
    />
  </AccordionItem>
  <AccordionItem title="Cambio en %">
    <FranceMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_diff}
      region="statecode"
      value="Cambio en %"
      colorScale="bluegreen"
      colorPalette={['#bf6f2f', '#1c4738']}
    />
  </AccordionItem>
</Accordion>

<DataTable data={orders_by_state_diff}>
  <Column title="Provincia" id="Provincia" />
  <Column title="Población {inputs.año_inicio.value}" id="Poblacion_Inicio" />
  <Column title="Población {inputs.año_fin.value}" id="Poblacion_Fin" />
  <Column title="Cambio en #" id="Cambio en #" />
  <Column title="Cambio en %" id="Cambio en %" />
</DataTable>  


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
    i.Provincias as Provincia,
    i.Población as Poblacion_Inicio,
    f.Población as Poblacion_Fin,
    -- Cálculo de la RESTA: Cambio absoluto
    (f.Población - i.Población) AS "Cambio en #",
    -- Cálculo del PORCENTAJE DE CAMBIO
    -- Usamos CAST(AS FLOAT) para asegurar una división decimal precisa.
    (CAST((f.Población - i.Población) AS FLOAT) / i.Población) * 100 AS "Cambio en %"
FROM
    ${orders_by_state_inicio} i
INNER JOIN
    ${orders_by_state_fin} f ON i.statecode = f.statecode;
``` 
## ¿Cómo es la distribución de edades en España?

```sql poblacion_por_sexo_edad_inicio
  SELECT *
  FROM mother.totalAnoSexoEdad
  where Year = ${inputs.año_inicio.value}
```
```sql poblacion_por_sexo_edad_fin
  SELECT *
  FROM mother.totalAnoSexoEdad
  where Year = ${inputs.año_fin.value}
```
<Grid cols=2>
  <Group>
  <div style="text-align:center">Año {inputs.año_inicio.value}</div>
 <ECharts
  config={{
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: function (params) {
        return params.map(param => `${param.seriesName}: ${Math.abs(param.value)}`).join('<br>');
      }
    },
    legend: {
      top: '5%',
      left: 'center',
      data: ['Mujeres', 'Hombres']
    },
    grid: [
      { // Left pyramid (Mujeres)
        left: '5%',
        width: '40%',
        bottom: '3%',
        containLabel: false
      },
      { // Right pyramid (Hombres)
        left: '60 %', // Larger gap for labels
        width: '40%',
        bottom: '3%',
        containLabel: false
      }
    ],
    xAxis: [
      {
        type: 'value',
        gridIndex: 0,
        inverse: true,
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        axisLabel: { formatter: value => Math.abs(value) }
      },
      {
        type: 'value',
        gridIndex: 1,
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        axisLabel: { formatter: value => Math.abs(value) }
      }
    ],
        yAxis: [
      { // Left pyramid yAxis (shows labels in middle)
        type: 'category',
        gridIndex: 0,
        position: 'right',
        inverse: false, // Cambia a true si quieres el mayor al inicio
        axisLabel: { show: true, inside: false, interval: 0 },
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])];
          return union.sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
        })()
      },
      { // Right pyramid yAxis (hidden labels)
        type: 'category',
        gridIndex: 1,
        position: 'left',
        inverse: false, // Coincide con el yAxis izquierdo
        axisLabel: { show: false },
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])];
          return union.sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
        })()
      }
    ],
    series: [
      {
        name: 'Mujeres',
        type: 'bar',
        xAxisIndex: 0,
        yAxisIndex: 0,
        itemStyle: { color: '#6a1b9a' }, // Purple
        label: { show: false },
        emphasis: { focus: 'series' },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])].sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
          return union.map(rango => {
            const row = poblacion_por_sexo_edad_inicio.find(row => row.Sexo === 'Mujeres' && row.RangoEdad === rango);
            return row ? row.TotalAgrupado : 0;
          });
        })()
      },
      {
        name: 'Hombres',
        type: 'bar',
        xAxisIndex: 1,
        yAxisIndex: 1,
        itemStyle: { color: '#388e3c' }, // Green
        label: { show: false },
        emphasis: { focus: 'series' },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])].sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
          return union.map(rango => {
            const row = poblacion_por_sexo_edad_inicio.find(row => row.Sexo === 'Hombres' && row.RangoEdad === rango);
            return row ? row.TotalAgrupado : 0;
          });
        })()
      }
    ]
  }}
/>
</Group>
  <Group>
  <div style="text-align:center">Año {inputs.año_fin.value}</div>
 <ECharts
  config={{
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: function (params) {
        return params.map(param => `${param.seriesName}: ${Math.abs(param.value)}`).join('<br>');
      }
    },
    legend: {
      top: '5%',
      left: 'center',
      data: ['Mujeres', 'Hombres']
    },
    grid: [
      { // Left pyramid (Mujeres)
        left: '5%',
        width: '40%',
        bottom: '3%',
        containLabel: false
      },
      { // Right pyramid (Hombres)
        left: '60%', // Larger gap for labels
        width: '40%',
        bottom: '3%',
        containLabel: false
      }
    ],
    xAxis: [
      {
        type: 'value',
        gridIndex: 0,
        inverse: true,
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        axisLabel: { formatter: value => Math.abs(value) }
      },
      {
        type: 'value',
        gridIndex: 1,
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        axisLabel: { formatter: value => Math.abs(value) }
      }
    ],
   yAxis: [
      { // Left pyramid yAxis (shows labels in middle)
        type: 'category',
        gridIndex: 0,
        position: 'right',
        inverse: false, // Cambia a true si quieres el mayor al inicio
        axisLabel: { show: true, inside: false ,interval:0},
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])];
          return union.sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
        })()
      },
      { // Right pyramid yAxis (hidden labels)
        type: 'category',
        gridIndex: 1,
        position: 'left',
        inverse: false, // Coincide con el yAxis izquierdo
        axisLabel: { show: false },
        axisTick: { show: false },
        axisLine: { show: false },
        splitLine: { show: false },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])];
          return union.sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
        })()
      }
    ],
    series: [
      {
        name: 'Mujeres',
        type: 'bar',
        xAxisIndex: 0,
        yAxisIndex: 0,
        itemStyle: { color: '#6a1b9a' }, // Purple
        label: { show: false },
        emphasis: { focus: 'series' },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])].sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
          return union.map(rango => {
            const row = poblacion_por_sexo_edad_fin.find(row => row.Sexo === 'Mujeres' && row.RangoEdad === rango);
            return row ? row.TotalAgrupado : 0;
          });
        })()
      },
      {
        name: 'Hombres',
        type: 'bar',
        xAxisIndex: 1,
        yAxisIndex: 1,
        itemStyle: { color: '#388e3c' }, // Green
        label: { show: false },
        emphasis: { focus: 'series' },
        data: (() => {
          const union = [...new Set([
            ...poblacion_por_sexo_edad_inicio.map(r => r.RangoEdad),
            ...poblacion_por_sexo_edad_fin.map(r => r.RangoEdad)
          ])].sort((a, b) => parseInt(a.split('-')[0]) - parseInt(b.split('-')[0]));
          return union.map(rango => {
            const row = poblacion_por_sexo_edad_fin.find(row => row.Sexo === 'Hombres' && row.RangoEdad === rango);
            return row ? row.TotalAgrupado : 0;
          });
        })()
      }
    ]
  }}
/>
</Group>
</Grid>


## Recursos
- [Instituto Nacional de Estadística (INE) - Población residente](https://www.ine.es/jaxiT3/Tabla.htm?t=56938)
- [INE - Cifras de población](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951)
- [INE - Población por nacionalidad](https://www.ine.es/jaxiT3/Tabla.htm?t=59587)
---
