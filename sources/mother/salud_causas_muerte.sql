-- Mart dbt salud_causas_muerte (transform/models/marts/salud_causas_muerte.sql).
-- Para aligerar el navegador: todos los capítulos y las causas concretas más
-- relevantes; provincias solo desde 2010.
SELECT *
FROM salud_causas_muerte
WHERE (tipo_causa IN ('total', 'capitulo') OR codigo_causa IN ('018', '059', '057', '058', '046', '090', '098', '099', '00A', '00B', '050', '021', '029', '013', '014'))
  AND (nivel <> 'provincia' OR anio >= 2010)
