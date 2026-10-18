-- Erosión del suelo por el agua estimada por el JRC (modelo RUSLE2015, Eurostat aei_pr_soiler) en
-- la superficie agraria con pastos naturales (CORINE: clases agrarias y 321), por año (2000, 2010,
-- 2016, 2023): t/ha y año de media y % de esa superficie con erosión moderada o grave (5 t/ha o
-- más) y grave (más de 10). Países, regiones NUTS 2 de Europa y, en España, comunidades y
-- provincias (las NUTS 3 insulares se suman en su provincia). Se recalcula con toneladas y
-- hectáreas para poder sumar regiones.
with base as (
    select
        geo, anio,
        sum(valor) filter (where grado = 'TOTAL' and unidad = 'T') as t,
        sum(valor) filter (where grado = 'TOTAL' and unidad = 'HA') as ha,
        sum(valor) filter (where grado = 'MOD_SEV' and unidad = 'HA') as ha_mod_sev,
        sum(valor) filter (where grado = 'SEV' and unidad = 'HA') as ha_sev
    from {{ source('raw_suelos', 'suelos_erosion') }}
    where cubierta = 'CLC2_321'
    group by geo, anio
),

todos as (
    -- Países
    select 'pais' as nivel, p.cod_pais as cod, p.pais as nombre, p.cod_pais as pais, b.anio, b.t, b.ha, b.ha_mod_sev, b.ha_sev
    from base b
    join {{ ref('paises_iso') }} p on p.eurostat = b.geo
    union all
    -- Regiones NUTS 2 de Europa
    select 'nuts2', b.geo, r.nombre, r.pais, b.anio, b.t, b.ha, b.ha_mod_sev, b.ha_sev
    from base b
    join {{ source('raw_suelos', 'suelos_regiones') }} r on r.cod = b.geo
    union all
    -- Comunidades y provincias de España
    select n.nivel, n.cod, t.nombre, 'ES', b.anio, sum(b.t), sum(b.ha), sum(b.ha_mod_sev), sum(b.ha_sev)
    from base b
    join {{ ref('nuts_espana') }} n on n.nuts = b.geo
    left join {{ ref('territorios') }} t on t.nivel = n.nivel and t.cod = n.cod
    group by n.nivel, n.cod, t.nombre, b.anio
)

select
    nivel,
    cod,
    nombre,
    pais,
    anio,
    t / nullif(ha, 0) as erosion_t_ha,
    100.0 * ha_mod_sev / nullif(ha, 0) as pct_moderada_grave,
    100.0 * ha_sev / nullif(ha, 0) as pct_grave,
    ha / 100.0 as superficie_km2,
    t as toneladas
from todos
where ha > 0
