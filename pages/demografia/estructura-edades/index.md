---
title: Estructura por Edades · SpainFacts
description: Pirámide poblacional y distribución por edad y sexo en España.
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import PopulationPyramid from '../../../../../../src/lib/components/PopulationPyramid.svelte';
</script>

# Estructura por Edades de la Población

Análisis de la pirámide poblacional española por edad y sexo, con datos históricos del INE.

```sql items
  SELECT Year
  FROM mother.totalAno
  ORDER BY Year ASC
```

<div class="hero-card">
  <h2 class="text-2xl font-bold text-white mb-2">Comparar Pirámides Poblacionales</h2>
  <p class="text-white/90 mb-4">Selecciona dos años para comparar la estructura por edades:</p>

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

---

## Pirámide de Población Comparada

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

## Análisis Demográfico

La pirámide poblacional muestra la estructura por edades de la población, lo que permite identificar:

- **Base ancha**: Alta natalidad (típico de poblaciones jóvenes)
- **Base estrecha**: Baja natalidad (población envejecida)
- **Cuerpo ancho**: Alta inmigración en edades laborales
- **Cúspide ancha**: Alta esperanza de vida

### Tendencias en España

```sql resumen_edades_inicio
SELECT 
  SUM(CASE WHEN Orden_Grupo < 15 THEN Total ELSE 0 END) AS Menores_15,
  SUM(CASE WHEN Orden_Grupo BETWEEN 15 AND 64 THEN Total ELSE 0 END) AS Edad_Laboral,
  SUM(CASE WHEN Orden_Grupo >= 65 THEN Total ELSE 0 END) AS Mayores_65,
  SUM(Total) AS Total
FROM mother.totalAnoSexoEdad
WHERE Anio = ${inputs.año_inicio.value}
```

```sql resumen_edades_fin
SELECT 
  SUM(CASE WHEN Orden_Grupo < 15 THEN Total ELSE 0 END) AS Menores_15,
  SUM(CASE WHEN Orden_Grupo BETWEEN 15 AND 64 THEN Total ELSE 0 END) AS Edad_Laboral,
  SUM(CASE WHEN Orden_Grupo >= 65 THEN Total ELSE 0 END) AS Mayores_65,
  SUM(Total) AS Total
FROM mother.totalAnoSexoEdad
WHERE Anio = ${inputs.año_fin.value}
```

```sql serie_edades
SELECT
  CAST(Anio AS INTEGER) AS anio,
  100.0 * SUM(CASE WHEN Orden_Grupo < 15 THEN Total ELSE 0 END) / SUM(Total) AS Pct_Menores_15,
  100.0 * SUM(CASE WHEN Orden_Grupo BETWEEN 15 AND 64 THEN Total ELSE 0 END) / SUM(Total) AS Pct_Edad_Laboral,
  100.0 * SUM(CASE WHEN Orden_Grupo >= 65 THEN Total ELSE 0 END) / SUM(Total) AS Pct_Mayores_65,
  100.0 * SUM(CASE WHEN Orden_Grupo >= 65 THEN Total ELSE 0 END) / NULLIF(SUM(CASE WHEN Orden_Grupo < 15 THEN Total ELSE 0 END), 0) AS Indice_Envejecimiento
FROM mother.totalAnoSexoEdad
WHERE CAST(Anio AS INTEGER) BETWEEN ${inputs.año_inicio.value} AND ${inputs.año_fin.value}
GROUP BY 1
ORDER BY 1
```

<Grid cols=3>
<Group>
<KpiCard
  title="Menores de 15 ({inputs.año_inicio.value})"
  value={resumen_edades_inicio[0]?.Menores_15}
  formattedValue={formatCompact(resumen_edades_inicio[0]?.Menores_15, 2)}
  sparklineData={serie_edades.map(d => d.Pct_Menores_15)}
/>
<KpiCard
  title="% Menores de 15"
  value={(resumen_edades_inicio[0]?.Menores_15 / resumen_edades_inicio[0]?.Total * 100).toFixed(1)}
  formattedValue={(resumen_edades_inicio[0]?.Menores_15 / resumen_edades_inicio[0]?.Total * 100).toFixed(1)}
  unit="%"
  sparklineData={serie_edades.map(d => d.Pct_Menores_15)}
/>
</Group>
<Group>
<KpiCard
  title="Edad Laboral ({inputs.año_inicio.value})"
  value={resumen_edades_inicio[0]?.Edad_Laboral}
  formattedValue={formatCompact(resumen_edades_inicio[0]?.Edad_Laboral, 2)}
  sparklineData={serie_edades.map(d => d.Pct_Edad_Laboral)}
/>
<KpiCard
  title="% Edad Laboral"
  value={(resumen_edades_inicio[0]?.Edad_Laboral / resumen_edades_inicio[0]?.Total * 100).toFixed(1)}
  formattedValue={(resumen_edades_inicio[0]?.Edad_Laboral / resumen_edades_inicio[0]?.Total * 100).toFixed(1)}
  unit="%"
  sparklineData={serie_edades.map(d => d.Pct_Edad_Laboral)}
/>
</Group>
<Group>
<KpiCard
  title="Mayores de 65 ({inputs.año_inicio.value})"
  value={resumen_edades_inicio[0]?.Mayores_65}
  formattedValue={formatCompact(resumen_edades_inicio[0]?.Mayores_65, 2)}
  sparklineData={serie_edades.map(d => d.Pct_Mayores_65)}
/>
<KpiCard
  title="% Mayores de 65"
  value={(resumen_edades_inicio[0]?.Mayores_65 / resumen_edades_inicio[0]?.Total * 100).toFixed(1)}
  formattedValue={(resumen_edades_inicio[0]?.Mayores_65 / resumen_edades_inicio[0]?.Total * 100).toFixed(1)}
  unit="%"
  sparklineData={serie_edades.map(d => d.Pct_Mayores_65)}
/>
</Group>
</Grid>

<Grid cols=3>
<Group>
<KpiCard
  title="Menores de 15 ({inputs.año_fin.value})"
  value={resumen_edades_fin[0]?.Menores_15}
  formattedValue={formatCompact(resumen_edades_fin[0]?.Menores_15, 2)}
  sparklineData={serie_edades.map(d => d.Pct_Menores_15)}
/>
<KpiCard
  title="% Menores de 15"
  value={(resumen_edades_fin[0]?.Menores_15 / resumen_edades_fin[0]?.Total * 100).toFixed(1)}
  formattedValue={(resumen_edades_fin[0]?.Menores_15 / resumen_edades_fin[0]?.Total * 100).toFixed(1)}
  unit="%"
  sparklineData={serie_edades.map(d => d.Pct_Menores_15)}
/>
</Group>
<Group>
<KpiCard
  title="Edad Laboral ({inputs.año_fin.value})"
  value={resumen_edades_fin[0]?.Edad_Laboral}
  formattedValue={formatCompact(resumen_edades_fin[0]?.Edad_Laboral, 2)}
  sparklineData={serie_edades.map(d => d.Pct_Edad_Laboral)}
/>
<KpiCard
  title="% Edad Laboral"
  value={(resumen_edades_fin[0]?.Edad_Laboral / resumen_edades_fin[0]?.Total * 100).toFixed(1)}
  formattedValue={(resumen_edades_fin[0]?.Edad_Laboral / resumen_edades_fin[0]?.Total * 100).toFixed(1)}
  unit="%"
  sparklineData={serie_edades.map(d => d.Pct_Edad_Laboral)}
/>
</Group>
<Group>
<KpiCard
  title="Mayores de 65 ({inputs.año_fin.value})"
  value={resumen_edades_fin[0]?.Mayores_65}
  formattedValue={formatCompact(resumen_edades_fin[0]?.Mayores_65, 2)}
  sparklineData={serie_edades.map(d => d.Pct_Mayores_65)}
/>
<KpiCard
  title="% Mayores de 65"
  value={(resumen_edades_fin[0]?.Mayores_65 / resumen_edades_fin[0]?.Total * 100).toFixed(1)}
  formattedValue={(resumen_edades_fin[0]?.Mayores_65 / resumen_edades_fin[0]?.Total * 100).toFixed(1)}
  unit="%"
  sparklineData={serie_edades.map(d => d.Pct_Mayores_65)}
/>
</Group>
</Grid>

---

## Tendencias de Envejecimiento

El índice de envejecimiento (relación entre población mayor de 65 años y menores de 15 años) es un indicador clave del proceso de transición demográfica.

```sql indice_envejecimiento
SELECT 
  ${inputs.año_inicio.value} AS Año_Inicio,
  ${inputs.año_fin.value} AS Año_Fin,
  (f.Mayores_65 / NULLIF(f.Menores_15, 0) * 100) AS Indice_Envejecimiento_Fin,
  (i.Mayores_65 / NULLIF(i.Menores_15, 0) * 100) AS Indice_Envejecimiento_Inicio,
  (f.Mayores_65 / NULLIF(f.Menores_15, 0) * 100) -
  (i.Mayores_65 / NULLIF(i.Menores_15, 0) * 100) AS Cambio_Indice
FROM ${resumen_edades_inicio} AS i, ${resumen_edades_fin} AS f
```

<KpiCard
  title="Índice de Envejecimiento ({inputs.año_fin.value})"
  value={indice_envejecimiento[0]?.Indice_Envejecimiento_Fin}
  formattedValue={formatNumber(indice_envejecimiento[0]?.Indice_Envejecimiento_Fin, 1)}
  unit="%"
  change={indice_envejecimiento[0]?.Cambio_Indice?.toFixed(1)}
  changeUnit=" pp"
  changePeriod="vs {inputs.año_inicio.value}"
  sparklineData={serie_edades.map(d => d.Indice_Envejecimiento)}
/>

---

## Fuentes Oficiales
- **[INE - Pirámide poblacional](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176951)**

<LastRefreshed prefix="Datos actualizados" />
