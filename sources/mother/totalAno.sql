  SELECT RIGHT("Periodo",4) as Year, 
  SUM(CAST(REPLACE(Total, ',', '') AS BIGINT))/COUNT(Total) AS Total
  FROM main.poblacion_provincias
  WHERE "Provincias" = 'Total Nacional' 
  AND "Sexo" = 'Total' 
  AND "Edad simple" = 'Todas las edades' 
  GROUP BY  RIGHT("Periodo",4)
  ORDER BY Year DESC, Total DESC