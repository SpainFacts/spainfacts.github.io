-- Una fila por (semana, embalse). El MITECO publica los datos los martes.
select
    e.fecha,
    e.ambito as cuenca,
    d.cod_demarcacion,
    d.demarcacion,
    e.embalse,
    e.capacidad_hm3,
    e.volumen_hm3,
    e.uso_electrico,
    extract(isoyear from e.fecha) as anio,
    extract(week from e.fecha) as semana
from {{ source('raw', 'miteco_embalses') }} as e
left join {{ ref('cuencas_demarcaciones') }} as d
  on d.cuenca = e.ambito
where e.capacidad_hm3 > 0
  and e.volumen_hm3 is not null
