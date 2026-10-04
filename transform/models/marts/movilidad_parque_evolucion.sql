-- Parque de vehículos en España por mes, grupo y energía (DGT). Un punto por
-- cada fichero mensual de parque cargado.
-- vehiculos_por_1000_hab es aditiva (sumar grupos o energías da la tasa del conjunto):
-- vehículos / población de España (padrón del año de la fecha, el último para los
-- años sin padrón) por mil.
with parque as (
    select
        p.mes,
        p.grupo,
        g.etiqueta as grupo_etiqueta,
        p.energia,
        e.etiqueta as energia_etiqueta,
        e.orden as energia_orden,
        sum(p.vehiculos) as vehiculos
    from {{ source('raw_movilidad', 'dgt_parque') }} p
    left join {{ ref('movilidad_energias') }} e on e.energia = p.energia
    left join {{ ref('movilidad_grupos') }} g on g.grupo = p.grupo
    group by all
),

pob as (
    select anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

ultimo as (select max(anio) as anio from pob)

select
    a.mes,
    cast(year(a.mes) as integer) as anio,
    a.grupo,
    a.grupo_etiqueta,
    a.energia,
    a.energia_etiqueta,
    a.energia_orden,
    a.vehiculos,
    1000.0 * a.vehiculos / nullif(p.poblacion, 0) as vehiculos_por_1000_hab
from parque a
cross join ultimo u
left join pob p on p.anio = least(cast(year(a.mes) as integer), u.anio)
