-- Resumen mensual del parque de turismos en España (DGT), un punto por cada
-- fichero mensual cargado (la DGT solo conserva unos 18 meses; la serie crece
-- con cada carga). Proporciones sobre el total de turismos y turismos por
-- 1.000 habitantes con el último padrón disponible para cada año.
with turismos as (
    select
        mes,
        sum(vehiculos) as turismos,
        sum(vehiculos) filter (where energia in ('bev', 'phev')) as enchufables,
        sum(vehiculos) filter (where energia = 'bev') as bev,
        sum(vehiculos) filter (where distintivo = 'SIN') as sin_distintivo,
        sum(vehiculos) filter (where antiguedad = '20+') as mas_de_20
    from {{ source('raw_movilidad', 'dgt_parque') }}
    where grupo = 'turismo'
    group by mes
),

todos as (
    select mes, sum(vehiculos) as vehiculos
    from {{ source('raw_movilidad', 'dgt_parque') }}
    group by mes
),

poblacion as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    t.mes,
    t.turismos,
    a.vehiculos,
    t.enchufables,
    t.bev,
    t.sin_distintivo,
    t.mas_de_20,
    p.poblacion,
    1000.0 * t.turismos / p.poblacion as turismos_1000,
    100.0 * t.enchufables / t.turismos as pct_enchufables,
    100.0 * t.bev / t.turismos as pct_bev,
    100.0 * t.sin_distintivo / t.turismos as pct_sin_distintivo,
    100.0 * t.mas_de_20 / t.turismos as pct_mas_de_20
from turismos t
join todos a using (mes)
left join poblacion p on p.anio = least(year(t.mes), (select max(anio) from poblacion))
