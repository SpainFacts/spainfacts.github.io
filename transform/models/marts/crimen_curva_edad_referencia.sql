-- Curva de referencia de condenados por sexo y grupo quinquenal de edad (15-19 ... 85+):
-- condenados por habitante en España (todos los adultos, españoles y extranjeros, último
-- año de la Estadística de Condenados del INE). Se usa para corregir por edad y sexo
-- donde no se conoce la edad de los condenados o detenidos (comparación europea y
-- detenciones por país): con ella se calcula cuántos casos cabría esperar en un grupo
-- solo por su pirámide de sexo y edad.
-- Los tramos del INE (18-20, 21-25...) se pasan a grupos de cinco años repartiendo cada
-- edad por igual; a los de 15 a 17 se les supone la mitad de la tasa de 18 a 20.
with curva_tramos as (
    select e.sexo, e.edad_desde, any_value(e.tramo_edad) as tramo_edad,
           sum(e.condenados) / sum(e.poblacion) as tasa
    from {{ ref('crimen_condenados_edad') }} e
    where e.procedencia in ('España', 'Total')
      and e.anio = (select max(anio) from {{ ref('crimen_condenados_edad') }})
    group by e.sexo, e.edad_desde
),

tramos as (
    select
        sexo, tasa, edad_desde,
        coalesce(try_cast(regexp_extract(tramo_edad, ' a ([0-9]+)', 1) as integer), 200) as edad_hasta
    from curva_tramos
    union all
    select sexo, tasa / 2, 15, 17 from curva_tramos where edad_desde = 18
),

grupos as (
    select unnest(range(15, 85, 5)) as grupo_desde
)

select
    t.sexo,
    g.grupo_desde,
    sum(t.tasa * greatest(0, least(t.edad_hasta, g.grupo_desde + 4) - greatest(t.edad_desde, g.grupo_desde) + 1)) / 5.0 as tasa
from tramos t
cross join grupos g
group by t.sexo, g.grupo_desde
union all
select sexo, 85, tasa from tramos where edad_desde = 71
