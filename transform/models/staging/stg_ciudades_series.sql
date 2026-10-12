-- Indicadores de ciudades de Urban Audit (Eurostat) en formato largo: indicador_id del seed
-- ciudades_indicadores, cod_ciudad, anio y valor. Cada indicador es la suma de sus códigos
-- indic_ur (en la encuesta de percepción, «muy» + «bastante» de acuerdo) por su factor; solo
-- se calcula si están todos los códigos de esa ciudad y año. Se descartan los valores fuera
-- del rango plausible del seed (valor_min, valor_max): Urban Audit trae algunos imposibles
-- (Gera con un 206 % de nacidos en otro país, Trento con 4.995 coches por 1.000 habitantes).
with catalogo as (
    select indicador_id, tabla, factor, valor_min, valor_max, len(string_split(codigos, '+')) as n_codigos,
           unnest(string_split(codigos, '+')) as indic_ur
    from {{ ref('ciudades_indicadores') }}
)

select
    c.indicador_id,
    u.cod_ciudad,
    cast(u.anio as integer) as anio,
    sum(u.valor) * any_value(c.factor) as valor
from {{ source('raw_ciudades', 'ciudades_urban_audit') }} u
join catalogo c on c.tabla = u.tabla and c.indic_ur = u.indic_ur
where u.valor is not null
group by c.indicador_id, u.cod_ciudad, u.anio
having count(*) = any_value(c.n_codigos)
   and sum(u.valor) * any_value(c.factor) >= coalesce(any_value(c.valor_min), -1e18)
   and sum(u.valor) * any_value(c.factor) <= coalesce(any_value(c.valor_max), 1e18)
