-- Parque de vehículos del último mes por provincia, grupo, energía, distintivo
-- ambiental y antigüedad (DGT).
select
    p.mes,
    p.cod_prov,
    t.cod_ccaa,
    t.nombre as provincia,
    p.grupo,
    p.energia,
    p.distintivo,
    p.antiguedad,
    sum(p.vehiculos) as vehiculos
from {{ source('raw_movilidad', 'dgt_parque') }} p
join {{ ref('territorios_provincias') }} t on t.cod_prov = p.cod_prov
where p.mes = (select max(mes) from {{ source('raw_movilidad', 'dgt_parque') }})
group by all
