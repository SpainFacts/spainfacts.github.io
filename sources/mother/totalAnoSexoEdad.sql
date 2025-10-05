WITH EdadesLimpias AS (
    -- Paso 1: Limpiar y convertir el campo "Edad simple" a un número entero (EdadNumerica)
    SELECT
        "Edad simple",
        RIGHT("Periodo", 4) AS Year,
        "Sexo",
        -- Expresión de Extracción de Edad Mejorada y Completa:
        CASE
            -- Manejar los casos especiales que causan errores de conversión
            WHEN "Edad simple" LIKE '%85 y más%' THEN 86
            WHEN "Edad simple" LIKE '%100 y más%' THEN 101 -- Caso +100 años añadido
            -- El resto de los casos son numéricos y se limpian antes de la conversión
            ELSE 
                CAST(
                    REPLACE(
                        REPLACE("Edad simple", ' años', ''),
                        ' año', ''
                    ) AS INT
                )
        END AS EdadNumerica,
        SUM(CAST(REPLACE(Total, ',', '') AS BIGINT)) / COUNT(Total) AS TotalPromedio
    FROM
        main.poblacion_provincias
    WHERE
        "Provincias" = 'Total Nacional'
        AND "Sexo" != 'Total'
        AND "Edad simple" != 'Todas las edades'
        AND Total IS NOT NULL
    GROUP BY
        "Edad simple",
        RIGHT("Periodo", 4),
        "Sexo"
)
SELECT
    -- Paso 2: Crear el rango de edad con intervalos de 5 años NO SOLAPADOS (0-5, 6-10, 11-15)
    -- Calcular el inicio del rango:
    CAST(
        (CASE
            WHEN EdadNumerica = 0 THEN 0
            ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
        END) AS VARCHAR
    ) || '-' ||
    -- Calcular el fin del rango:
    CAST(
        (CASE
            WHEN EdadNumerica = 0 THEN 5 -- 0 años es un caso especial
            ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 5
        END) AS VARCHAR
    ) || ' años' AS RangoEdad,
    Year,
    "Sexo",
    SUM(TotalPromedio) AS TotalAgrupado
FROM
    EdadesLimpias
GROUP BY
    RangoEdad,
    Year,
    "Sexo",
    -- Agrupamos por el inicio numérico del rango para una ordenación correcta
    (CASE
        WHEN EdadNumerica = 0 THEN 0
        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
    END)