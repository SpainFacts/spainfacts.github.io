-- Vehículos NUEVOS matriculados por mes, grupo, energía y marca (DGT, MATRABA).
select
    mes,
    grupo,
    energia,
    trim(replace(marca, '¡', '')) as marca,
    sum(matriculaciones) as matriculaciones
from {{ source('raw_movilidad', 'dgt_matriculaciones_modelos') }}
where nuevo_usado = 'N'
  and grupo in ('turismo', 'motocicleta', 'furgoneta')
  and trim(replace(marca, '¡', '')) <> ''
group by all
