---
title: Población por Sexo · SpainFacts
description: Distribución y evolución comparada de mujeres y hombres en España.
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import CustomDonutChart from '../../../../../../src/lib/components/CustomDonutChart.svelte';
    import CustomLineChart from '../../../../../../src/lib/components/CustomLineChart.svelte';
</script>

# Población por Sexo en España

Análisis de la distribución por sexo de la población española, con datos históricos del INE.

```sql items
  SELECT Year
  FROM mother.totalAno
  ORDER BY Year ASC
```

<div class="hero-card">
  <h2 class="text-2xl font-bold text-white mb-2">Selecciona el Periodo</h2>
  <p class="text-white/90 mb-4">Comparar datos de población por sexo entre dos años:</p>

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

---

## Distribución por Sexo

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

---

## Evolución Temporal

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

## Datos Clave

```sql datos_ultimo_anio
SELECT 
  Year,
  SUM(CASE WHEN Sexo = 'Hombres' THEN Total ELSE 0 END) AS Hombres,
  SUM(CASE WHEN Sexo = 'Mujeres' THEN Total ELSE 0 END) AS Mujeres,
  SUM(Total) AS Total
FROM mother.totalAnoSexo
WHERE Year = ${inputs.año_fin.value}
GROUP BY Year
```

<Grid cols=3>
<KpiCard
  title="Hombres ({inputs.año_fin.value})"
  value={datos_ultimo_anio[0]?.Hombres}
  formattedValue={formatCompact(datos_ultimo_anio[0]?.Hombres, 2)}
/>
<KpiCard
  title="Mujeres ({inputs.año_fin.value})"
  value={datos_ultimo_anio[0]?.Mujeres}
  formattedValue={formatCompact(datos_ultimo_anio[0]?.Mujeres, 2)}
/>
<KpiCard
  title="Total ({inputs.año_fin.value})"
  value={datos_ultimo_anio[0]?.Total}
  formattedValue={formatCompact(datos_ultimo_anio[0]?.Total, 2)}
/>
</Grid>

---

## Fuentes Oficiales
- **[INE - Cifras oficiales de población por sexo](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951)**

<LastRefreshed prefix="Datos actualizados" />
