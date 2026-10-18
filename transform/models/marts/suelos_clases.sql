-- Reparto de la superficie agraria por clase de suelo (textura, grupo de textura, pH, materia
-- orgánica y grupo WRB) en España, comunidades, provincias y países europeos, por cultivo.
-- pct = % de la superficie agraria (con dato de esa dimensión) de ese territorio y cultivo.
with c as (
    select
        case when ambito = 'pais' and cod = 'ES' then 'pais' when ambito = 'pais' then 'europa' else ambito end as nivel,
        case when ambito = 'pais' and cod = 'ES' then '00' else cod end as cod,
        cultivo, dimension, clase, orden, superficie_km2
    from {{ source('raw_suelos', 'suelos_clases') }}
    -- las regiones NUTS 2 de Europa van en suelos_regiones
    where ambito <> 'nuts2'
)

select
    c.nivel,
    coalesce(p.cod_pais, c.cod) as cod,
    coalesce(t.nombre, p.pais) as nombre,
    c.cultivo,
    c.dimension,
    c.clase,
    c.orden,
    c.superficie_km2,
    100.0 * c.superficie_km2 / nullif(sum(c.superficie_km2) over (partition by c.nivel, c.cod, c.cultivo, c.dimension), 0) as pct
from c
left join {{ ref('territorios') }} t on t.nivel = c.nivel and t.cod = c.cod
left join {{ ref('paises_iso') }} p on c.nivel = 'europa' and p.eurostat = c.cod
where c.nivel <> 'europa' or p.cod_pais is not null
