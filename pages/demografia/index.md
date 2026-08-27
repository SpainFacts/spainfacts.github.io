---
title: Demografía y Población
---

<script>
    import SpainMap from "../../../../../src/lib/charts/maps/SpainMap.svelte";
    import WorldMap from "../../../../../src/lib/charts/maps/WorldMap.svelte";
    import PopulationPyramid from "../../../../../src/lib/components/PopulationPyramid.svelte";
    
    // Importar funciones de formato desde utils
    import { formatNumber, formatCurrency, formatCompact, formatMillions, formatThousands } from '../../../../../src/lib/utils.js';
    import CustomBarChart from '../../../../../src/lib/components/CustomBarChart.svelte';
    import CustomLineChart from '../../../../../src/lib/components/CustomLineChart.svelte';
    import CustomTable from '../../../../../src/lib/components/CustomTable.svelte';
    import CustomDonutChart from '../../../../../src/lib/components/CustomDonutChart.svelte';
</script>

# Demografía y Población de España

Los cambios en la población de España reflejan tendencias demográficas, económicas y sociales que han moldeado el país a lo largo del tiempo: desde el baby boom y la transición demográfica hasta el envejecimiento y los flujos migratorios recientes.

<div class="hero-card">
  <h2 class="text-2xl font-bold text-white mb-2">Evolución Demográfica Seleccionada</h2>
  <p class="text-white/90 mb-4">Selecciona el rango de años para comparar las cifras oficiales del censo y padrón del INE:</p>

  <div class="dropdown-container">
    <Dropdown 
      name=año_inicio
      data={items}
      value=Year
      defaultValue="1971"
      class="text-xl"
    />
    <Dropdown 
      name=año_fin
      data={items}
      value=Year
      defaultValue="2024"
    />
  </div>

| Población en {inputs.año_inicio.value} | Población en {inputs.año_fin.value} | Cambio de población |
| :---: | :---: | :---: |
| **{formatCompact(total_poblacion_year_inicio[0].Total, 2)}** | **{formatCompact(total_poblacion_year_fin[0].Total, 2)}** | **{formatNumber(((total_poblacion_year_fin[0].Total - total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total) * 100, 2) + '%'}** |

</div>

```sql total_poblacion_year_inicio
  SELECT Year, Total
  FROM mother.totalAno
  WHERE Year = '${inputs.año_inicio.value}'
```

```sql total_poblacion_year_fin
  SELECT Year, Total
  FROM mother.totalAno
  WHERE Year = '${inputs.año_fin.value}'
```

```sql items
  SELECT Year
  FROM mother.totalAno
  ORDER BY Year ASC
```

<LastRefreshed prefix="Datos actualizados" />

---

## 1. ¿Cómo ha cambiado la población en España?

```sql poblacion_variacion_anual  
WITH Poblacion_Anual AS (
    SELECT 
        CAST(Year AS INT) AS Year,
        Total AS Poblacion_Actual
    FROM mother.totalAno
    WHERE Year BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value}
)
SELECT 
    Year,
    Poblacion_Actual,
    LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC) AS Poblacion_Anterior,
    Poblacion_Actual - LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC) AS Variacion_Absoluta,
    (CAST(Poblacion_Actual AS DECIMAL) - LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC)) * 100.0 / LAG(Poblacion_Actual, 1, NULL) OVER (ORDER BY Year ASC) AS Variacion_Porcentual
FROM Poblacion_Anual
ORDER BY Year ASC;
```

<CustomBarChart
  data={poblacion_variacion_anual}
  title="Variación anual de la población en España"
  x="Year"
  y="Variacion_Porcentual"
  y2="Variacion_Absoluta"
  yAxisTitle="Variación Porcentual (%)"
  locale="es-ES"
/>

La población de España ha variado un **{formatNumber(((total_poblacion_year_fin[0].Total - total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total) * 100, 2)}%** entre {inputs.año_inicio.value} y {inputs.año_fin.value}, pasando de **{formatCompact(total_poblacion_year_inicio[0].Total, 2)}** a **{formatCompact(total_poblacion_year_fin[0].Total, 2)}** habitantes.

<CustomLineChart
  data={poblacion_variacion_anual}
  title="Evolución de la población total de España"
  x="Year"
  y="Poblacion_Actual"
  yAxisTitle="Población Total"
  locale="es-ES"
  startingAtZero={false}
/>

---

## 2. Población por Sexo

```sql poblacion_por_sexo
  SELECT Year, Sexo, Total
  FROM mother.totalAnoSexo
  WHERE Year BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value}
```

```sql donut_data_inicio
  SELECT Sexo AS name, Total AS value
  FROM ${poblacion_por_sexo}
  WHERE Year = ${inputs.año_inicio.value}
```

```sql donut_data_fin
  SELECT Sexo AS name, Total AS value
  FROM ${poblacion_por_sexo}
  WHERE Year = ${inputs.año_fin.value}
```

<Grid cols=2>
<Group>
<CustomDonutChart 
  data={donut_data_inicio} 
  title="Año {inputs.año_inicio.value}"
  name="name"
  value="value"
/>
</Group>
<Group>
<CustomDonutChart 
  data={donut_data_fin} 
  title="Año {inputs.año_fin.value}"
  name="name"
  value="value"
/>
</Group>
</Grid>

```sql poblacion_por_sexo3
WITH hombres AS (
  SELECT Year, Total
  FROM ${poblacion_por_sexo}
  WHERE Sexo = 'Hombres' 
),
mujeres AS (
  SELECT Year, Total
  FROM ${poblacion_por_sexo}
  WHERE Sexo = 'Mujeres'
)
SELECT 
  CAST(h.Year AS INTEGER) AS Year, 
  h.Total AS Hombres, 
  m.Total AS Mujeres, 
  CAST(m.Total AS DECIMAL) / CAST(h.Total AS DECIMAL) AS Ratio_Mujeres_Hombres
FROM hombres h
INNER JOIN mujeres m ON h.Year = m.Year
ORDER BY h.Year ASC;
```

<CustomLineChart
  data={poblacion_por_sexo3}
  title="Población por sexo a lo largo del tiempo"
  x="Year"
  y={["Hombres", "Mujeres"]}
  y2="Ratio_Mujeres_Hombres"
  xAxisTitle="Año"
  yAxisTitle="Población"
  locale="es-ES"
  startingAtZero={false}
/>

---

## 3. ¿Dónde viven las personas en España? Distribución Territorial

La distribución geográfica de la población en España varía significativamente entre provincias y comunidades autónomas, con una concentración progresiva en áreas metropolitanas y franjas costeras.

```sql orders_by_state_inicio
  SELECT statecode, Provincias, Población
  FROM mother.totalAnoProvincia 
  WHERE Year = ${inputs.año_inicio.value}
``` 

```sql orders_by_state_fin
  SELECT statecode, Provincias, Población
  FROM mother.totalAnoProvincia 
  WHERE Year = ${inputs.año_fin.value}
``` 

```sql orders_by_state_diff
SELECT
    i.statecode,
    i.Provincias AS Provincia,
    i.Población AS Poblacion_Inicio,
    f.Población AS Poblacion_Fin,
    (f.Población - i.Población) AS "Cambio en #",
    (CAST((f.Población - i.Población) AS FLOAT) / i.Población) * 100 AS "Cambio en %"
FROM
    ${orders_by_state_inicio} i
INNER JOIN
    ${orders_by_state_fin} f ON i.statecode = f.statecode;
```

<Accordion>
  <AccordionItem title="Población en {inputs.año_inicio.value}">
    <SpainMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_inicio}
      region="statecode"
      value="Población"
      colorScale="bluegreen"
      colorPalette={['#805973', '#557396', '#398cb6', '#133e6c']}
    />
  </AccordionItem>
  <AccordionItem title="Población en {inputs.año_fin.value}">  
    <SpainMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_fin}
      region="statecode"
      value="Población"
      colorScale="bluegreen"
      colorPalette={['#805973', '#557396', '#398cb6', '#133e6c']}
    />  
  </AccordionItem>
  <AccordionItem title="Cambio Absoluto (# habitantes)">
    <SpainMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_diff}
      region="statecode"
      value="Cambio en #"
      diverging={true}
      negativeColorPalette={['#5c0000', '#821516', '#a42a2d', '#c14444']}
      positiveColorPalette={['#805973', '#557396', '#398cb6', '#133e6c']}
      zeroColor="#a44456" 
    />
  </AccordionItem>
  <AccordionItem title="Cambio Relativo (%)">
    <SpainMap
      mapName="Spain"
      nameProperty="code"
      data={orders_by_state_diff}
      region="statecode"
      value="Cambio en %"
      diverging={true}
      negativeColorPalette={['#5c0000', '#821516', '#a42a2d', '#c14444']}
      positiveColorPalette={['#805973', '#557396', '#398cb6', '#133e6c']}
      zeroColor="#a44456" 
    />
  </AccordionItem>
</Accordion>

<CustomTable 
  data={orders_by_state_diff}
  columns={[
    { title: "Provincia", accessor: "Provincia" },
    { title: `Población ${inputs.año_inicio.value}`, accessor: "Poblacion_Inicio", fmt: (val) => formatCompact(val, 1), align: 'right' },
    { title: `Población ${inputs.año_fin.value}`, accessor: "Poblacion_Fin", fmt: (val) => formatCompact(val, 1), align: 'right' },
    { title: "Cambio (#)", accessor: "Cambio en #", fmt: (val) => formatCompact(val, 1), align: 'right' },
    { title: "Cambio (%)", accessor: "Cambio en %", fmt: (val) => formatNumber(val, 2) + '%', align: 'right' }
  ]}
/>  

---

## 4. ¿Cómo es la distribución por edades? Pirámide de Población

```sql poblacion_por_sexo_edad_inicio
  SELECT *
  FROM mother.totalAnoSexoEdad
  WHERE Anio = ${inputs.año_inicio.value}
```

```sql poblacion_por_sexo_edad_fin
  SELECT *
  FROM mother.totalAnoSexoEdad
  WHERE Anio = ${inputs.año_fin.value}
```

<Grid cols=2>
  <Group>
    <PopulationPyramid 
      data={poblacion_por_sexo_edad_inicio} 
      year={inputs.año_inicio.value} 
    />
  </Group>
  <Group>
    <PopulationPyramid 
      data={poblacion_por_sexo_edad_fin} 
      year={inputs.año_fin.value} 
    />
  </Group>
</Grid>

---

## Fuentes Oficiales y Metodología
- **[INE - Cifras oficiales de población (Padrón Continuo)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951):** Series históricas anuales desagregadas por sexo, edad y provincia.
- **[INE - Censo de Población y Viviendas](https://www.ine.es/jaxiT3/Tabla.htm?t=56938)**
- **[INE - Población por nacionalidad](https://www.ine.es/jaxiT3/Tabla.htm?t=59587)**
