-- Serie desde 2000: suficiente para las comparativas y ligera para el navegador
SELECT fecha, anio, semana, nivel, cod, nombre, capacidad_hm3, volumen_hm3, pct_llenado
FROM embalses_semanal
WHERE fecha >= DATE '2000-01-01' AND nivel IN ('pais', 'cuenca')
