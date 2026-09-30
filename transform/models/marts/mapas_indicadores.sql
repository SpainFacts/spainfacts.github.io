-- Catálogo largo de indicadores por territorio (comunidad o provincia) para el
-- explorador de mapas (/varios/mapas/). Cada bloque vive en mapas_<seccion>.sql.

select * from {{ ref('mapas_personas') }}
union all by name
select * from {{ ref('mapas_territorio') }}
