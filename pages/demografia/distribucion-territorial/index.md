---
title: Distribución Territorial · SpainFacts
description: Población por provincia y comunidades autónomas en España.
---

<script>
    import { formatNumber, formatCompact } from '../../../../src/lib/utils.js';
    import SpainMap from '../../../../src/lib/charts/maps/SpainMap.svelte';
    import CustomTable from '../../../../src/lib/components/CustomTable.svelte';
</script>

# Distribución Territorial de la Población

La distribución geográfica de la población en España varía significativamente entre provincias y comunidades autónomas, con una concentración progresiva en áreas metropolitanas y franjas costeras.

```sql items
  SELECT Year
  FROM mother.totalAno
  ORDER BY Year ASC
```

<div class="hero-card">
  <h2 class="text-2xl font-bold text-white mb-2">Selecciona el Periodo</h2>
  <p class="text-white/90 mb-4">Comparar distribución territorial entre dos años:</p>

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
</div>

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

---

## Mapas de Distribución

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

---

## Datos por Provincia

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

## Resumen Nacional

```sql resumen_inicio
SELECT 
  SUM(Población) AS Total,
  COUNT(*) AS Provincias
FROM ${orders_by_state_inicio}
```

```sql resumen_fin
SELECT 
  SUM(Población) AS Total,
  COUNT(*) AS Provincias
FROM ${orders_by_state_fin}
```

<Grid cols=2>
<Value
  value={resumen_inicio[0]?.Total}
  title="Población total ({inputs.año_inicio.value})"
  fmt="compact"
/>
<Value
  value={resumen_fin[0]?.Total}
  title="Población total ({inputs.año_fin.value})"
  fmt="compact"
/>
</Grid>

---

## Fuentes Oficiales
- **[INE - Población por provincia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951)**

<LastRefreshed prefix="Datos actualizados" />
