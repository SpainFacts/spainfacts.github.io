select
    make_date(cast(periodo as integer), 1, 1) as periodo,
    cast(periodo as integer) as anio,
    cofog99 as cod_cofog,
    case cofog99
        when 'GF10' then 'Protección Social y Pensiones'
        when 'GF07' then 'Sanidad Pública'
        when 'GF09' then 'Educación'
        when 'GF01' then 'Servicios Públicos Generales'
        when 'GF04' then 'Asuntos Económicos y Transporte'
        when 'GF03' then 'Orden Público y Seguridad'
        when 'GF02' then 'Defensa'
        when 'GF05' then 'Protección del Medio Ambiente'
        when 'GF06' then 'Vivienda y Servicios Comunitarios'
        when 'GF08' then 'Ocio, Cultura y Religión'
        else cofog99
    end as funcion_cofog,
    unidad,
    valor as millones_euros
from {{ source('raw', 'eurostat_cuentas_gastos') }}
where valor is not null
  and cofog99 not in ('TOTAL')
