-- Modelos más comunes en el parque del último mes (DGT), con al menos 100 unidades.
-- es_modelo_real es falso en las filas "(modelo sin especificar)", que no son un modelo.
with m as (
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
)

select
    m.mes,
    m.grupo,
    g.etiqueta as grupo_etiqueta,
    m.energia,
    e.etiqueta as energia_etiqueta,
    m.marca,
    m.modelo,
    m.modelo <> '(modelo sin especificar)' as es_modelo_real,
    m.vehiculos
from m
left join {{ ref('movilidad_grupos') }} g on g.grupo = m.grupo
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
