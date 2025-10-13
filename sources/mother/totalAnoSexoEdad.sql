-- Paso 1: Creamos una tabla temporal (CTE) con las edades exactas que queremos para 2023,
-- incluyendo solo la categoría "y más" más alta.
WITH EdadesFiltradas AS (
  -- Seleccionamos todas las edades normales (sin "más")
  SELECT "Edad simple", Periodo, Sexo
  FROM SpainFacts.main.poblacion_provincias
  WHERE "Edad simple" <> 'Todas las edades'
    AND Provincias = 'Total Nacional'
    AND Sexo <> 'Total'
    AND Total IS NOT NULL
    AND "Edad simple" NOT LIKE '%más%'
  UNION ALL
  -- Unimos el grupo de edad "y más" más alto
  SELECT "Edad simple", Periodo, Sexo
  FROM SpainFacts.main.poblacion_provincias
  WHERE "Edad simple" <> 'Todas las edades'
    AND Provincias = 'Total Nacional'
    AND Sexo <> 'Total'
    AND Total IS NOT NULL
    AND "Edad simple" LIKE '%más%'
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY Periodo, Sexo
    -- Ordenamos de forma descendente para coger la edad más alta (ej: "100 y más" antes que "85 y más")
    ORDER BY CAST(REPLACE(REPLACE(REPLACE("Edad simple", ' y más', ''), ' años', ''),' año','') AS INT) DESC
  ) = 1
)
-- Paso 2: Unimos la tabla original con nuestro filtro y aplicamos la agrupación de 5 en 5 años
SELECT
  Tab.Sexo,
  RIGHT(Tab.Periodo, 4) AS Anio,
  -- Creamos los grupos de edad de 5 en 5 años
  CASE
    WHEN Tab."Edad simple" LIKE '%más%' THEN REPLACE(REPLACE(Tab."Edad simple", 'y más años', '+'), ' año', '')  -- Etiqueta final para el grupo más alto
 ELSE CONCAT(
      -- AQUÍ ESTÁ EL CAMBIO: Quitamos "años" y "año" antes de convertir
      CAST(FLOOR(CAST(REPLACE(REPLACE(Tab."Edad simple", ' años', ''), ' año', '') AS INT) / 5) * 5 AS INT),
      '-',
      CAST(FLOOR(CAST(REPLACE(REPLACE(Tab."Edad simple", ' años', ''), ' año', '') AS INT) / 5) * 5 + 4 AS INT)
    )
  END AS RangoEdad,
  -- Creamos una columna para ordenar los grupos numéricamente
  CASE
    WHEN Tab."Edad simple" LIKE '%más%' THEN 999
    ELSE FLOOR(CAST(REPLACE(REPLACE(Tab."Edad simple", ' años', ''), ' año', '') AS INT) / 5) * 5
  END AS Orden_Grupo,
  SUM(CAST(REPLACE(Tab.Total, ',', '') AS INT)) AS Total
FROM
  SpainFacts.main.poblacion_provincias AS Tab
-- El INNER JOIN es la clave: solo procesamos las filas que existen en nuestra tabla filtrada
INNER JOIN
  EdadesFiltradas AS Filtro
  ON Tab.Periodo = Filtro.Periodo
  AND Tab."Edad simple" = Filtro."Edad simple"
  AND Tab.Sexo = Filtro.Sexo
GROUP BY
  Anio,
  Tab.Sexo,
  RangoEdad,
  Orden_Grupo
ORDER BY
  Anio,
  Tab.Sexo,
  Orden_Grupo;