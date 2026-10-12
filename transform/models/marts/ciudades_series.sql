-- Ciudades de España y de Europa: series anuales (desde 2000) de los indicadores de Urban
-- Audit del seed ciudades_indicadores, en formato largo por indicador, ciudad y año, con el
-- nombre y el país de cada ciudad (mart ciudades). Nombre, unidad y sentido de cada
-- indicador en ciudades_resumen.
select
    s.indicador_id,
    s.cod_ciudad,
    c.ciudad,
    c.cod_pais,
    c.pais,
    c.es_espana,
    s.anio,
    cast(s.valor as double) as valor
from {{ ref('stg_ciudades_series') }} s
join {{ ref('ciudades') }} c using (cod_ciudad)
where s.anio >= 2000
  and isfinite(s.valor)
