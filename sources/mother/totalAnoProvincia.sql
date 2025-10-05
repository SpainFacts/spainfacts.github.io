  SELECT SUBSTRING("Provincias",1,2) as statecode,
  SUBSTRING("Provincias",3) as Provincias,
  SUM(CAST(REPLACE(Total, ',', '') AS BIGINT))/COUNT(Total) AS "Población",
  RIGHT("Periodo",4) as Year
  FROM main.poblacion_provincias 
  WHERE "Edad simple" = 'Todas las edades' 
  AND "Sexo" = 'Total' 
  AND "Provincias" != 'Total Nacional' 
  AND Total is not null
  GROUP BY "Provincias", RIGHT("Periodo",4)