

```sql orders_by_state_inicio
    SELECT statecode, Provincias, CAST(REPLACE(Población, ',', '') AS FLOAT) AS Población
    FROM mother.totalAnoProvincia 
    WHERE Year=1971
``` 
```sql orders_by_state_fin
    SELECT statecode, Provincias, CAST(REPLACE(Población, ',', '') AS FLOAT) AS Población
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
    mapName="Spain"
    nameProperty="code"
    data={orders_by_state_inicio}
    region="statecode"
    value="Población"
    colorScale="bluegreen"
    colorPalette={["#f7fbff", "#b7e3ff", "#5dade2", "#2471a3", "#154360"]}
/>
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
          ]} />
    </Tab>