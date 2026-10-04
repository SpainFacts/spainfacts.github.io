-- Parque de vehículos del último mes por provincia, grupo, energía, distintivo
-- ambiental y antigüedad (DGT). `poblacion` es la de la provincia (último padrón)
-- y se repite en cada fila: no se suma. `vehiculos_por_1000_hab` sí es aditiva
-- dentro de una provincia (la suma de sus filas es la tasa total de la provincia).
select
    p.mes,
    p.cod_prov,
    t.cod_ccaa,
    c.nombre as ccaa,
    t.nombre as provincia,
    p.grupo,
    p.energia,
    p.distintivo,
    p.antiguedad,
    sum(p.vehiculos) as vehiculos,
    any_value(tp.poblacion_ultima) as poblacion,
    1000.0 * sum(p.vehiculos) / nullif(any_value(tp.poblacion_ultima), 0) as vehiculos_por_1000_hab
from {{ source('raw_movilidad', 'dgt_parque') }} p
join {{ ref('territorios_provincias') }} t on t.cod_prov = p.cod_prov
join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = t.cod_ccaa
join {{ ref('territorios') }} tp on tp.nivel = 'provincia' and tp.cod = p.cod_prov
where p.mes = (select max(mes) from {{ source('raw_movilidad', 'dgt_parque') }})
group by all
