

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
