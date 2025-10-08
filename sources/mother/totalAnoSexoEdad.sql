WITH EdadesLimpias AS (
    -- Paso 1: Limpiar y convertir el campo "Edad simple" a un número entero (EdadNumerica)
    SELECT
        "Edad simple",
        RIGHT("Periodo", 4) AS Year,
        "Sexo",
        CASE
            WHEN "Edad simple" LIKE '%85 y más%' THEN 186
            WHEN "Edad simple" LIKE '%100 y más%' THEN 1101
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
),
RangosPorAño AS (
    -- Paso 2: Generar rangos de edad dinámicos, incluyendo +85 y +100 solo si existen
    SELECT DISTINCT
        CASE
            WHEN EdadNumerica = 186 THEN '+85'
            WHEN EdadNumerica = 1101 THEN '+100'
            ELSE
                CAST(
                    (CASE
                        WHEN EdadNumerica = 0 THEN 0
                        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
                    END) AS VARCHAR
                ) || '-' ||
                CAST(
                    (CASE
                        WHEN EdadNumerica = 0 THEN 5
                        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 5
                    END) AS VARCHAR
                )
        END AS RangoEdad,
        Year,
        CASE
            WHEN EdadNumerica = 186 THEN 186
            WHEN EdadNumerica = 1101 THEN 1101
            WHEN EdadNumerica = 0 THEN 0
            ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
        END AS Orden
    FROM EdadesLimpias
),
DatosAgrupados AS (
    -- Paso 3: Agrupar datos por rango de edad, año y sexo
    SELECT
        CASE
            WHEN EdadNumerica = 186 THEN '+85'
            WHEN EdadNumerica = 1101 THEN '+100'
            ELSE
                CAST(
                    (CASE
                        WHEN EdadNumerica = 0 THEN 0
                        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
                    END) AS VARCHAR
                ) || '-' ||
                CAST(
                    (CASE
                        WHEN EdadNumerica = 0 THEN 5
                        ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 5
                    END) AS VARCHAR
                )
        END AS RangoEdad,
        Year,
        "Sexo",
        SUM(TotalPromedio) AS TotalAgrupado
    FROM EdadesLimpias
    GROUP BY
        RangoEdad,
        Year,
        "Sexo",
        CASE
            WHEN EdadNumerica = 186 THEN 186
            WHEN EdadNumerica = 1101 THEN 1101
            WHEN EdadNumerica = 0 THEN 0
            ELSE (CAST(FLOOR((EdadNumerica - 1) / 5) AS INT) * 5) + 1
        END
)
SELECT
    r.RangoEdad,
    r.Year,
    d.Sexo,
    COALESCE(d.TotalAgrupado, 0) AS TotalAgrupado,
    r.Orden
FROM RangosPorAño r
CROSS JOIN (
    SELECT DISTINCT Sexo FROM EdadesLimpias
) s
LEFT JOIN DatosAgrupados d
    ON r.RangoEdad = d.RangoEdad
    AND r.Year = d.Year
    AND s.Sexo = d.Sexo
ORDER BY r.Year, r.Orden, s.Sexo