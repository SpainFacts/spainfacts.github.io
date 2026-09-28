-- Modelos más comunes en el parque del último mes (DGT), con al menos 100 unidades.
select
    mes,
    grupo,
    energia,
    trim(replace(marca, '¡', '')) as marca,
    coalesce(nullif(trim(replace(modelo, '¡', '')), ''), '(modelo sin especificar)') as modelo,
    sum(vehiculos) as vehiculos
from {{ source('raw_movilidad', 'dgt_parque_modelos') }}
where mes = (select max(mes) from {{ source('raw_movilidad', 'dgt_parque_modelos') }})
  and grupo in ('turismo', 'motocicleta', 'furgoneta')
  and trim(replace(marca, '¡', '')) <> ''
group by all
having sum(vehiculos) >= 100
