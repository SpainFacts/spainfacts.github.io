-- Superficie quemada por provincia y año (EFFIS). cod_prov casa con la
-- propiedad cod_prov de static/spain-provinces.geojson para los mapas.
select
    anio,
    cod_prov,
    provincia,
    count(*) as n_incendios,
    round(sum(area_ha), 0) as ha_quemadas,
    round(sum(area_ha * pct_natura2000 / 100), 0) as ha_natura2000,
    round(max(area_ha), 0) as ha_mayor_incendio
from {{ ref('stg_effis_areas_quemadas') }}
where cod_prov is not null
group by anio, cod_prov, provincia
order by anio, cod_prov
