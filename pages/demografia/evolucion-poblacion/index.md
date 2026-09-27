---
title: Evolución de la Población · SpainFacts
description: Análisis de los cambios anuales en la población española desde 1971.
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import CustomBarChart from '../../../../../../src/lib/components/CustomBarChart.svelte';
    import CustomLineChart from '../../../../../../src/lib/components/CustomLineChart.svelte';
</script>

# Evolución de la Población en España

Análisis detallado de cómo ha cambiado la población española a lo largo del tiempo, con datos oficiales del INE desde 1971.

```sql items
  SELECT Year
  FROM mother.totalAno
  ORDER BY Year ASC
```

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

| Población en {inputs.año_inicio.value} | Población en {inputs.año_fin.value} | Cambio de población |
| :---: | :---: | :---: |
| **{formatCompact(total_poblacion_year_inicio[0].Total, 2)}** | **{formatCompact(total_poblacion_year_fin[0].Total, 2)}** | **{formatNumber(((total_poblacion_year_fin[0].Total - total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total) * 100, 2) + '%'}** |

</div>

---

## Variación Anual de la Población

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

---

## Evolución Histórica

<CustomLineChart
  data={poblacion_variacion_anual}
  title="Evolución de la población total de España"
  x="Year"
  y="Poblacion_Actual"
  yAxisTitle="Población Total"
  locale="es-ES"
  startingAtZero={false}
/>

La población de España ha variado un **{formatNumber(((total_poblacion_year_fin[0].Total - total_poblacion_year_inicio[0].Total) / total_poblacion_year_inicio[0].Total) * 100, 2)}%** entre {inputs.año_inicio.value} y {inputs.año_fin.value}, pasando de **{formatCompact(total_poblacion_year_inicio[0].Total, 2)}** a **{formatCompact(total_poblacion_year_fin[0].Total, 2)}** habitantes.

---

## Fuentes Oficiales
- **[INE - Cifras oficiales de población (Padrón Continuo)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951)**

<LastRefreshed prefix="Datos actualizados" />
