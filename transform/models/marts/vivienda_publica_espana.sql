-- Vivienda pública en alquiler en España, una fila por año (2004-...):
-- - ECV (INE): % de hogares en alquiler inferior al precio de mercado (incluye
--   el alquiler social público y también rentas reducidas entre particulares o
--   de empresa), a precio de mercado y en cesión.
-- - Calificaciones provisionales de vivienda protegida en régimen de alquiler
--   (MIVAU, 2005-2023): viviendas protegidas de alquiler que empiezan su
--   tramitación cada año, total y por 100.000 habitantes.
-- - Parque autonómico en alquiler (encuestas de vivienda social 2019 y 2023,
--   suma de comunidades y ciudades autónomas) y estimación nacional del MIVAU
--   para 2023 (autonómico + municipal escalado por población), por 1.000 hab.
--   y en % de los hogares.
-- - OCDE PH4.2: viviendas sociales de alquiler de España en % del parque total.
with anios as (
    select anio from {{ ref('stg_vivienda_publica_ecv') }} where cod_ccaa = '00'
    union
    select cast(anio as integer) from {{ source('raw_vivienda_publica', 'vp_calificaciones') }}
),

pob as (
    select anio, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
),

hogares as (
    select anio, hogares from {{ ref('demografia_hogares') }} where nivel = 'pais'
),

calif as (
    select cast(anio as integer) as anio,
        max(viviendas) filter (where regimen = 'alquiler') as calif_alquiler,
        max(viviendas) filter (where regimen = 'total') as calif_total
    from {{ source('raw_vivienda_publica', 'vp_calificaciones') }}
    where cod_ccaa = '00'
    group by 1
),

autonomico as (
    select cast(anio as integer) as anio, sum(arrendamiento) as parque_autonomico_alquiler
    from {{ source('raw_vivienda_publica', 'vp_ccaa_parque') }}
    group by 1
),

nacional as (
    select cast(anio as integer) as anio,
        max(valor) filter (where concepto = 'parque_alquiler_publico') as parque_publico_alquiler,
        max(valor) filter (where concepto = 'parque_municipal') as parque_municipal_estimado,
        max(valor) filter (where concepto = 'pct_hogares') as pct_hogares_mivau
    from {{ source('raw_vivienda_publica', 'vp_nacional') }}
    group by 1
),

ocde as (
    select cast(anio as integer) as anio, viviendas_sociales as ocde_viviendas_sociales, pct_parque as ocde_pct_parque
    from {{ source('raw_vivienda_publica', 'vp_ocde') }}
    where cod_pais = 'ESP' and not es_media
)

select
    a.anio,
    e.pct_alquiler_inferior as ecv_pct_alquiler_inferior,
    e.pct_alquiler_mercado as ecv_pct_alquiler_mercado,
    e.pct_cesion as ecv_pct_cesion,
    e.pct_propiedad as ecv_pct_propiedad,
    cast(c.calif_alquiler as integer) as calif_alquiler,
    cast(c.calif_total as integer) as calif_total,
    100.0 * c.calif_alquiler / nullif(c.calif_total, 0) as pct_calif_alquiler,
    100000.0 * c.calif_alquiler / p.poblacion as calif_alquiler_100k,
    cast(au.parque_autonomico_alquiler as integer) as parque_autonomico_alquiler,
    1000.0 * au.parque_autonomico_alquiler / p.poblacion as parque_autonomico_1000hab,
    cast(n.parque_publico_alquiler as integer) as parque_publico_alquiler,
    cast(n.parque_municipal_estimado as integer) as parque_municipal_estimado,
    1000.0 * n.parque_publico_alquiler / p.poblacion as parque_publico_1000hab,
    n.pct_hogares_mivau,
    100.0 * n.parque_publico_alquiler / h.hogares as parque_publico_pct_hogares,
    cast(o.ocde_viviendas_sociales as integer) as ocde_viviendas_sociales,
    o.ocde_pct_parque,
    cast(p.poblacion as bigint) as poblacion,
    cast(h.hogares as bigint) as hogares
from anios a
left join {{ ref('stg_vivienda_publica_ecv') }} e on e.cod_ccaa = '00' and e.anio = a.anio
left join calif c on c.anio = a.anio
left join autonomico au on au.anio = a.anio
left join nacional n on n.anio = a.anio
left join ocde o on o.anio = a.anio
left join pob p on p.anio = a.anio
left join hogares h on h.anio = a.anio
order by a.anio
