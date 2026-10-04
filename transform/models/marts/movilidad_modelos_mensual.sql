-- Vehículos NUEVOS matriculados por mes, grupo, energía, canal, marca y modelo en los
-- últimos 36 meses (DGT, MATRABA). El nombre del modelo es el de la ficha
-- técnica: un mismo coche puede aparecer con variantes ("SANDERO" / "SANDERO STEPWAY").
-- Códigos con su etiqueta, como movilidad_matriculaciones_mensual.
with ultimo as (
    select max(mes) as mes from {{ ref('stg_dgt_matriculaciones_marcas') }}
)
select
    m.mes,
    cast(year(m.mes) as integer) as anio,
    m.grupo,
    g.etiqueta as grupo_etiqueta,
    m.energia,
    e.etiqueta as energia_etiqueta,
    m.canal,
    c.etiqueta as canal_etiqueta,
    m.marca,
    m.grupo_empresarial,
    coalesce(nullif(m.modelo, ''), '(modelo sin especificar)') as modelo,
    sum(m.matriculaciones) as matriculaciones
from {{ ref('stg_dgt_matriculaciones_marcas') }} m
cross join ultimo u
left join {{ ref('movilidad_grupos') }} g on g.grupo = m.grupo
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
left join {{ ref('movilidad_canales') }} c on c.canal = m.canal
where m.grupo in ('turismo', 'motocicleta', 'furgoneta', 'camion', 'autobus')
  and m.mes > u.mes - interval 36 month
group by all
