-- Vehículos NUEVOS matriculados por mes, grupo, energía, marca y modelo en los
-- últimos 36 meses (DGT, MATRABA). El nombre del modelo es el de la ficha
-- técnica: un mismo coche puede aparecer con variantes ("SANDERO" / "SANDERO STEPWAY").
with ultimo as (
    select max(mes) as mes from {{ source('raw_movilidad', 'dgt_matriculaciones_modelos') }}
)
select
    m.mes,
    m.grupo,
    m.energia,
    trim(replace(m.marca, '¡', '')) as marca,
    coalesce(nullif(trim(replace(m.modelo, '¡', '')), ''), '(modelo sin especificar)') as modelo,
    sum(m.matriculaciones) as matriculaciones
from {{ source('raw_movilidad', 'dgt_matriculaciones_modelos') }} m, ultimo u
where m.nuevo_usado = 'N'
  and m.grupo in ('turismo', 'motocicleta', 'furgoneta')
  and trim(replace(m.marca, '¡', '')) <> ''
  and m.mes > u.mes - interval 36 month
group by all
