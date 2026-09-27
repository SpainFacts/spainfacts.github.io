-- Población por provincia a 1 de enero; statecode = código INE de 2 dígitos
SELECT cod_prov AS statecode, provincia AS Provincias, poblacion AS "Población", anio::VARCHAR AS Year
FROM poblacion_anual
WHERE NOT es_total_nacional AND sexo = 'Total'
