-- Organismos del Estado con más personal en la última edición del Registro
-- Central de Personal. En las comunidades y entidades locales NOMBRE_ORGANISMO
-- es la provincia o el tipo de entidad, no un organismo: no se incluyen.
select
    fecha,
    case
        when tipo_administracion like '%ESTADO%' then 'Estado'
        when tipo_administracion like '%COMUNIDADES%' then 'Comunidades autónomas'
        else 'Entidades locales'
    end as administracion,
    coalesce(ministerio, '') as ministerio,
    organismo,
    sum(efectivos) as efectivos,
    sum(efectivos) filter (where sexo = 'M') as mujeres
from {{ source('raw_empleo', 'bepsap_efectivos') }}
where fecha = (select max(fecha) from {{ source('raw_empleo', 'bepsap_efectivos') }})
  and organismo is not null
  and tipo_administracion like '%ESTADO%'
group by all
having sum(efectivos) >= 100
