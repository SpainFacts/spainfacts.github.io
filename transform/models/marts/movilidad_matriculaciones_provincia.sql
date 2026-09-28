-- Turismos matriculados por mes, provincia del domicilio del vehículo, energía
-- y nuevo/usado (DGT, MATRABA).
select
    m.mes,
    m.cod_prov,
    p.cod_ccaa,
    p.nombre as provincia,
    m.energia,
    e.etiqueta_corta as energia_etiqueta,
    e.orden as energia_orden,
    m.nuevo_usado,
    sum(m.matriculaciones) as matriculaciones
from {{ source('raw_movilidad', 'dgt_matriculaciones') }} m
join {{ ref('territorios_provincias') }} p on p.cod_prov = m.cod_prov
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
where m.grupo = 'turismo'
group by all
