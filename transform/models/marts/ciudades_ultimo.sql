-- Último dato de cada ciudad en cada indicador, para compararlas: Urban Audit no tiene todos
-- los años de todas las ciudades, así que se toma el último de cada una dentro de los cinco
-- años anteriores al año más reciente con dato de al menos 25 ciudades (año de referencia
-- del indicador) y se guarda su año. puesto: 1 = la mejor de Europa según el sentido del
-- indicador (en los neutros, el valor más alto); puesto_espana, entre las españolas.
with cobertura as (
    select indicador_id, max(anio) as anio_ref
    from (
        select indicador_id, anio, count(*) as n
        from {{ ref('ciudades_series') }}
        group by indicador_id, anio
    )
    where n >= 25
    group by indicador_id
),

ultimo as (
    select s.*
    from {{ ref('ciudades_series') }} s
    join cobertura c using (indicador_id)
    where s.anio between c.anio_ref - 4 and c.anio_ref
    qualify row_number() over (partition by s.indicador_id, s.cod_ciudad order by s.anio desc) = 1
),

ordenado as (
    select u.*, case when i.sentido = 'negativo' then u.valor else -u.valor end as orden_valor
    from ultimo u
    join {{ ref('ciudades_indicadores') }} i using (indicador_id)
)

select
    o.indicador_id,
    o.cod_ciudad,
    o.ciudad,
    o.cod_pais,
    o.pais,
    o.es_espana,
    c.cod_mun,
    c.lat,
    c.lon,
    c.poblacion,
    o.anio,
    o.valor,
    cast(rank() over (partition by o.indicador_id order by o.orden_valor) as integer) as puesto,
    cast(count(*) over (partition by o.indicador_id) as integer) as n_ciudades,
    case when o.es_espana then cast(rank() over (partition by o.indicador_id, o.es_espana order by o.orden_valor) as integer) end as puesto_espana,
    case when o.es_espana then cast(count(*) over (partition by o.indicador_id, o.es_espana) as integer) end as n_espana
from ordenado o
join {{ ref('ciudades') }} c using (cod_ciudad)
