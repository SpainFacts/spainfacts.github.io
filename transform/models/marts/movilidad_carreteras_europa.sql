-- Autopistas por país y año (Eurostat road_if_motorwa): km, por 100.000 habitantes y por
-- 1.000 km² de superficie (demo_r_d3area, la última publicada de cada país).
with crudo as (
    select
        e.anio,
        p.cod_pais,
        p.pais,
        max(valor) filter (where indicador = 'km_autopistas') as km_autopistas
    from {{ source('raw_carreteras', 'carreteras_eurostat') }} e
    join {{ ref('paises_iso') }} p on p.eurostat = e.cod_fuente
    group by e.anio, p.cod_pais, p.pais
),

superficie as (
    select p.cod_pais, arg_max(valor, anio) as km2
    from {{ source('raw_carreteras', 'carreteras_eurostat') }} e
    join {{ ref('paises_iso') }} p on p.eurostat = e.cod_fuente
    where indicador = 'superficie_km2'
    group by p.cod_pais
)

select
    c.anio,
    c.cod_pais,
    c.pais,
    c.km_autopistas,
    100000.0 * c.km_autopistas / nullif(h.poblacion, 0) as km_por_100k_hab,
    1000.0 * c.km_autopistas / nullif(s.km2, 0) as km_por_1000_km2
from crudo c
left join {{ ref('poblacion_paises') }} h on h.cod_pais = c.cod_pais and h.anio = c.anio
left join superficie s on s.cod_pais = c.cod_pais
where c.km_autopistas is not null
