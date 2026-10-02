-- Vehículos NUEVOS matriculados por mes, grupo, energía, canal, marca y modelo en los
-- últimos 36 meses (DGT, MATRABA). El nombre del modelo es el de la ficha
-- técnica: un mismo coche puede aparecer con variantes ("SANDERO" / "SANDERO STEPWAY").
with ultimo as (
    select max(mes) as mes from {{ ref('stg_dgt_matriculaciones_marcas') }}
)
select
    m.mes,
    m.grupo,
    m.energia,
    m.canal,
    m.marca,
    m.grupo_empresarial,
    coalesce(nullif(m.modelo, ''), '(modelo sin especificar)') as modelo,
    sum(m.matriculaciones) as matriculaciones
from {{ ref('stg_dgt_matriculaciones_marcas') }} m, ultimo u
where m.grupo in ('turismo', 'motocicleta', 'furgoneta', 'camion', 'autobus')
  and m.mes > u.mes - interval 36 month
group by all
