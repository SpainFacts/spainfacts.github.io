-- Vehículos NUEVOS matriculados por mes, grupo, energía, canal, marca y grupo
-- empresarial (DGT, MATRABA). Marca y grupo resueltos en stg_dgt_matriculaciones_marcas.
select
    mes,
    grupo,
    energia,
    canal,
    marca,
    grupo_empresarial,
    sum(matriculaciones) as matriculaciones
from {{ ref('stg_dgt_matriculaciones_marcas') }}
where grupo in ('turismo', 'motocicleta', 'furgoneta', 'camion', 'autobus')
group by all
