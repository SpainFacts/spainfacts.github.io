-- Mart dbt elecciones_municipios (transform/models/marts/elecciones_municipios.sql)
-- ~270k filas (municipio x elección): a Evidence solo llegan Congreso y Municipales,
-- las columnas que usa la ficha de municipio y los % con un decimal (~2,3 MB).
SELECT
    proceso,
    tipo,
    CAST(anio AS INTEGER) AS anio,
    cod_mun,
    CAST(round(participacion, 1) AS DECIMAL(4, 1)) AS participacion,
    ganador_siglas,
    ganador_familia,
    CAST(round(ganador_pct, 1) AS DECIMAL(4, 1)) AS ganador_pct,
    CAST(round(pct_izquierda, 1) AS DECIMAL(4, 1)) AS pct_izquierda,
    CAST(round(pct_derecha, 1) AS DECIMAL(4, 1)) AS pct_derecha,
    CAST(round(pct_centro, 1) AS DECIMAL(4, 1)) AS pct_centro,
    CAST(round(pct_nacionalistas, 1) AS DECIMAL(4, 1)) AS pct_nacionalistas,
    CAST(round(pct_psoe, 1) AS DECIMAL(4, 1)) AS pct_psoe,
    CAST(round(pct_pp, 1) AS DECIMAL(4, 1)) AS pct_pp,
    CAST(round(pct_vox, 1) AS DECIMAL(4, 1)) AS pct_vox,
    CAST(round(pct_iu_podemos_sumar, 1) AS DECIMAL(4, 1)) AS pct_iu_podemos_sumar
FROM elecciones_municipios
WHERE tipo IN ('02', '04')
ORDER BY cod_mun, proceso
