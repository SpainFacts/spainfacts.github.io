-- Turismos en circulación por municipio en el último mes (DGT). La DGT no da
-- el municipio en los de menos de 10.000 habitantes: esos no aparecen aquí.
-- Nombre y población: último padrón (poblacion_municipios).
with p as (
    select
        p.mes,
        p.cod_mun,
        sum(p.vehiculos) as turismos,
        sum(p.vehiculos) filter (where p.energia = 'bev') as bev,
        sum(p.vehiculos) filter (where p.energia = 'phev') as phev,
        sum(p.vehiculos) filter (where p.energia = 'hev') as hev,
        sum(p.vehiculos) filter (where p.distintivo = 'CERO') as distintivo_cero,
        sum(p.vehiculos) filter (where p.distintivo = 'ECO') as distintivo_eco,
        sum(p.vehiculos) filter (where p.distintivo = 'C') as distintivo_c,
        sum(p.vehiculos) filter (where p.distintivo = 'B') as distintivo_b,
        sum(p.vehiculos) filter (where p.distintivo = 'SIN') as sin_distintivo,
        sum(p.vehiculos) filter (where p.antiguedad in ('15-19', '20+')) as mas_de_15_anios
    from {{ source('raw_movilidad', 'dgt_parque') }} p
    where p.mes = (select max(mes) from {{ source('raw_movilidad', 'dgt_parque') }})
      and p.grupo = 'turismo'
      and p.cod_mun is not null
    group by all
)
select
    p.mes,
    p.cod_mun,
    m.municipio,
    m.cod_prov,
    m.poblacion,
    p.turismos,
    1000.0 * p.turismos / nullif(m.poblacion, 0) as turismos_por_1000_hab,
    100.0 * (p.bev + coalesce(p.phev, 0)) / p.turismos as enchufables_pct,
    100.0 * p.sin_distintivo / p.turismos as sin_distintivo_pct,
    100.0 * p.mas_de_15_anios / p.turismos as mas_de_15_anios_pct,
    p.bev,
    p.phev,
    p.hev,
    p.distintivo_cero,
    p.distintivo_eco,
    p.distintivo_c,
    p.distintivo_b,
    p.sin_distintivo,
    p.mas_de_15_anios
from p
left join (
    select cod_mun, municipio, cod_prov, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify anio = max(anio) over ()
) m using (cod_mun)
