

```sql orders_by_state_inicio
  SELECT statecode, Provincias, Población
  FROM mother.totalAnoProvincia 
  WHERE Year=1971
``` 
```sql orders_by_state_fin
    SELECT statecode, Provincias, Población
  FROM mother.totalAnoProvincia 
  WHERE Year=2021
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
# Maps
<script>
    // Due to the location that Evidence builds the site, we need to hop up many directories to get to root
    import FranceMap from "../../../../../src/lib/charts/maps/FranceMap.svelte";
    import WorldMap from "../../../../../src/lib/charts/maps/WorldMap.svelte";
</script>

<FranceMap
    data={orders_by_state_inicio} 
    region=statecode
    value="Población"
/>
