-- Condenados adultos en España por sexo, tramo de edad, nacionalidad (española /
-- extranjera) y procedencia (INE, Estadística de Condenados, tabla 25645) y su tasa
-- por 1.000 residentes del mismo sexo, tramo de edad y procedencia (INE 56942).
--
-- nacionalidad / procedencia:
--   'Española'   / 'España'
--   'Extranjera' / 'Total' (todos los extranjeros)
--   'Extranjera' / 'Unión Europea', 'Resto de Europa', 'África', 'América', 'Asia y Oceanía'
-- (para no contar dos veces, filtrar procedencia IN ('España', 'Total') o excluir 'Total').
-- El INE no separa más: América junta a Hispanoamérica con EE. UU. y Canadá, y África
-- al norte de África con el resto del continente.
--
-- Es la base de los ajustes por edad y sexo de crimen_condenados_ajuste y
-- crimen_condenados_procedencia.
--   - Extranjeros = Total - Española (Total = Española + grupos, sin «no consta»).
--   - Población a mitad de año: media del 1 de enero del año y del siguiente
--     (los condenados se cuentan a lo largo de todo el año). Para el último año,
--     sin el 1 de enero siguiente, se extrapola medio año con el crecimiento del
--     año anterior.
--   - Unión Europea y Resto de Europa (con el Reino Unido fuera de la UE) solo existen
--     desde 2020 en los condenados y desde el 1-1-2021 en la población: para 2020 se
--     usa la población del 1-1-2021, y antes no hay datos de esas procedencias.
--   - La población viene en grupos de cinco años (15-19, 20-24...) y los tramos de
--     los condenados no coinciden (18-20, 21-25...): se reparte cada grupo de
--     forma uniforme entre sus cinco edades (p. ej. 18-20 = 2/5 de 15-19 + 1/5 de 20-24).

with condenados_ine as (
    select
        anyo as anio,
        split_part(serie, '. ', 1) as sexo,
        split_part(serie, '. ', 2) as nacionalidad_ine,
        trim(split_part(serie, '. ', 3)) as tramo_edad,
        valor as condenados
    from {{ source('raw_criminalidad', 'ine_condenados_edad_nacionalidad') }}
    where serie like '%. Dato base. %'
      and valor is not null
      and split_part(serie, '. ', 1) in ('Hombres', 'Mujeres')
      and trim(split_part(serie, '. ', 3)) <> 'Total'
),

condenados_grupo as (
    select anio, sexo, tramo_edad, {{ procedencia_ine('nacionalidad_ine') }} as procedencia, sum(condenados) as condenados
    from condenados_ine
    where nacionalidad_ine not like '%UE28%'
    group by all
),

-- los extranjeros en total = Total - Española
condenados_largo as (
    select anio, sexo, tramo_edad, procedencia, condenados
    from condenados_grupo
    where procedencia not in ('Total')
    union all
    select t.anio, t.sexo, t.tramo_edad, 'Total', t.condenados - e.condenados
    from condenados_grupo t
    join condenados_grupo e
      on e.anio = t.anio and e.sexo = t.sexo and e.tramo_edad = t.tramo_edad and e.procedencia = 'España'
    where t.procedencia = 'Total'
),

tramos as (
    select distinct
        tramo_edad,
        cast(regexp_extract(tramo_edad, '([0-9]+)', 1) as integer) as edad_desde,
        coalesce(try_cast(regexp_extract(tramo_edad, ' a ([0-9]+)', 1) as integer), 200) as edad_hasta
    from condenados_ine
),

-- grupos quinquenales de población a 1 de enero; «90 y más» es abierto
poblacion_grupos as (
    select
        anio,
        sexo,
        {{ procedencia_ine('nacionalidad') }} as procedencia,
        cast(regexp_extract(edad, '([0-9]+)', 1) as integer) as grupo_desde,
        edad like '%y más%' as abierto,
        sum(poblacion) as poblacion
    from {{ source('raw_criminalidad', 'ine_poblacion_nacionalidad') }}
    where cod_ccaa = '00'
      and sexo in ('Hombres', 'Mujeres')
      and edad <> 'Todas las edades'
      and nacionalidad not in ('Total', 'Apátridas')
    group by all
),

poblacion_enero as (
    select
        p.anio,
        p.sexo,
        p.procedencia,
        t.tramo_edad,
        sum(p.poblacion * case
            when p.abierto then case when t.edad_hasta >= 200 and t.edad_desde <= p.grupo_desde then 1 else 0 end
            else greatest(0, least(t.edad_hasta, p.grupo_desde + 4) - greatest(t.edad_desde, p.grupo_desde) + 1) / 5.0
        end) as poblacion
    from poblacion_grupos p
    cross join tramos t
    where p.procedencia is not null
    group by all
),

poblacion_media as (
    select
        anio,
        sexo,
        procedencia,
        tramo_edad,
        coalesce(
            (poblacion + lead(poblacion) over w) / 2,
            poblacion * sqrt(poblacion / nullif(lag(poblacion) over w, 0)),
            lead(poblacion) over w  -- UE sin Reino Unido: el INE la da desde el 1-1-2021
        ) as poblacion
    from poblacion_enero
    window w as (partition by sexo, procedencia, tramo_edad order by anio)
)

select
    c.anio,
    c.sexo,
    c.tramo_edad,
    t.edad_desde,
    case when c.procedencia = 'España' then 'Española' else 'Extranjera' end as nacionalidad,
    c.procedencia,
    c.condenados,
    round(p.poblacion) as poblacion,
    1000.0 * c.condenados / nullif(p.poblacion, 0) as condenados_por_1000_hab
from condenados_largo c
join tramos t using (tramo_edad)
join poblacion_media p
  on p.anio = c.anio and p.sexo = c.sexo and p.procedencia = c.procedencia and p.tramo_edad = c.tramo_edad
