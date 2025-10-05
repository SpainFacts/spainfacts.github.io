 SELECT 
       RIGHT("Periodo",4) as Year, 
      SUM(CAST(REPLACE("Total", ',', '') AS BIGINT))/COUNT(Total) AS Total,Sexo
  FROM main.poblacion_provincias
  WHERE 
      "Edad simple" = 'Todas las edades' 
      AND "Provincias" = 'Total Nacional' 
      AND "Total" IS NOT NULL
      AND "Sexo" != 'Total' 
  GROUP BY RIGHT("Periodo",4),Sexo