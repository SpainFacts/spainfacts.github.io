-- Turismos matriculados por mes, provincia del domicilio del vehículo, energía
-- nuevo/usado y canal (DGT, MATRABA). Las flotas (renting, alquiler) se matriculan
-- donde tienen sede, muchas en municipios con el impuesto de circulación más bajo.
select
    m.mes,
    m.cod_prov,
    p.cod_ccaa,
    p.nombre as provincia,
    m.energia,
    e.etiqueta_corta as energia_etiqueta,
    e.orden as energia_orden,
    m.nuevo_usado,
    m.canal,
    sum(m.matriculaciones) as matriculaciones
from {{ source('raw_movilidad', 'dgt_matriculaciones') }} m
join {{ ref('territorios_provincias') }} p on p.cod_prov = m.cod_prov
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
where m.grupo = 'turismo'
group by all
