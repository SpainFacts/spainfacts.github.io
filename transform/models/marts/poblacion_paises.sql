-- Población media anual de cada país y agregado (Eurostat demo_gind, AVG), para las cifras por
-- habitante de las tablas internacionales. Solo países del seed paises_iso.
select
    p.cod_pais,
    p.pais,
    cast(g.anio as integer) as anio,
    g.poblacion
from {{ source('raw', 'eurostat_poblacion_media_paises') }} g
join {{ ref('paises_iso') }} p on p.eurostat = g.geo
where g.poblacion is not null
