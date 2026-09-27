-- Últimos 10 años de incendios, sin columnas de detalle que la página no usa
SELECT
    id, fecha, anio, provincia, cod_prov, municipio, area_ha,
    latitud, longitud, ha_natura2000, pct_natura2000, pct_arbolado, pct_matorral, cubierta_principal
FROM incendios_areas_quemadas
WHERE anio >= (SELECT max(anio) - 9 FROM incendios_areas_quemadas)
