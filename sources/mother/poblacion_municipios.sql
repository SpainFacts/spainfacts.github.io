-- Últimos 10 años, solo total (~81k filas) para no cargar de más el navegador
SELECT anio, cod_mun, municipio, cod_prov, cod_ccaa, poblacion
FROM poblacion_municipios
WHERE sexo = 'Total'
  AND anio >= (SELECT max(anio) - 9 FROM poblacion_municipios)
