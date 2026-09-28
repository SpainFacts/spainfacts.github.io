-- Condenados adultos por comunidad, sexo y nacionalidad (INE, Estadística de
-- Condenados, tabla 25704) y su tasa por 1.000 residentes de 18 o más años de
-- la misma comunidad, sexo y nacionalidad (INE 56942 a 1 de enero del año).
--
-- Cautelas (se explican en la web):
--   - la comunidad es la del juzgado que condena, no la de residencia;
--   - entre los condenados extranjeros hay personas que no residen en España
--     (turistas, personas en tránsito o en situación irregular) y que no están
--     en el denominador: eso eleva la tasa de extranjeros;
--   - la población extranjera es más joven y con más hombres, los grupos que más
--     delinquen en cualquier país; por eso se dan tasas por sexo, pero no se puede
--     ajustar por edad porque el INE no cruza edad y nacionalidad de los condenados.
-- Población de 18 o más años aproximada con los grupos quinquenales: 20 y más
-- años + 2/5 del grupo de 15 a 19.
with condenados as (
    select
        anyo as anio,
        split_part(serie, '. ', 1) as sexo,
        split_part(serie, '. ', 2) as territorio,
        split_part(serie, '. ', 4) as nacionalidad,
        valor as condenados
    from {{ source('raw_criminalidad', 'ine_condenados_ccaa') }}
    where serie like '%. Dato base. %' and valor is not null
),

poblacion as (
    select
        anio,
        cod_ccaa,
        sexo,
        nacionalidad,
        sum(case
            when try_cast(regexp_extract(edad, '([0-9]+)', 1) as integer) >= 20 then poblacion
            when try_cast(regexp_extract(edad, '([0-9]+)', 1) as integer) = 15 then poblacion * 0.4
            else 0
        end) as poblacion_18
    from {{ source('raw_criminalidad', 'ine_poblacion_nacionalidad') }}
    where edad <> 'Todas las edades' and nacionalidad in ('Total', 'Española', 'Extranjera')
    group by all
)

select
    c.anio,
    n.cod_ccaa,
    c.sexo,
    c.nacionalidad,
    c.condenados,
    p.poblacion_18,
    1000.0 * c.condenados / nullif(p.poblacion_18, 0) as tasa_1000
from condenados c
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = c.territorio
left join poblacion p
  on p.anio = c.anio and p.cod_ccaa = n.cod_ccaa and p.sexo = c.sexo and p.nacionalidad = c.nacionalidad
