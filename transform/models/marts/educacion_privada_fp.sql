-- Alumnado de formación profesional (ciclos formativos de grado básico, medio y superior) por
-- comunidad autónoma, curso, grado, modalidad (presencial / a distancia), familia profesional y
-- titularidad del centro. Fuente: Ministerio de Educación, FP y Deportes, Estadística de las
-- Enseñanzas no universitarias (EDUCAbase):
--   * familia = 'Total': tabla 1.1 de cada curso (gen-todas/todas_01.px), con las cinco
--     titularidades (Total, Pública, Privada, Privada concertada, Privada no concertada), desde
--     2011-12 (FP básica desde 2014-15);
--   * resto de familias: tablas «por comunidad autónoma/provincia, ciclo formativo y
--     titularidad» de gen-ciclos-fp (filas en mayúsculas = familia), que solo separan Pública /
--     Privada, desde 2016-17 (2016-17 y 2017-18 suman los planes LOGSE y LOE). Los nombres de
--     familia se unifican entre cursos (erratas, códigos delante y familias LOGSE equivalentes).
-- modalidad 'Todas' = presencial + a distancia. El alumnado a distancia de centros privados se
-- cuenta en la comunidad del centro aunque estudie desde otra.
-- cuota_pct: alumnos de la titularidad sobre el Total del mismo grupo (comunidad, curso, grado,
-- modalidad, familia). anio = año de fin del curso.
with totales as (
    select
        curso,
        cod_ccaa,
        case
            when lower(ensenanza) like '%b_sic%' then 'Básico'
            when lower(ensenanza) like '%grado medio%' then 'Medio'
            else 'Superior'
        end as grado,
        case when lower(ensenanza) like '%distancia%' then 'A distancia' else 'Presencial' end as modalidad,
        'Total' as familia,
        case titularidad
            when 'TODOS LOS CENTROS' then 'Total'
            when 'CENTROS PÚBLICOS' then 'Pública'
            when 'CENTROS PRIVADOS' then 'Privada'
            when 'Enseñanza privada concertada' then 'Privada concertada'
            when 'Enseñanza privada no concertada' then 'Privada no concertada'
        end as titularidad,
        alumnos
    from {{ source('raw_educacion_privada', 'educacion_privada_alumnado_curso') }}
    where (lower(ensenanza) like 'c%f%' and lower(ensenanza) not like 'cursos%')
),

familias as (
    select
        curso,
        cod_ccaa,
        grado,
        modalidad,
        {{ educacion_privada_familia_expr('familia') }} as familia,
        case titularidad
            when 'TODOS LOS CENTROS' then 'Total'
            when 'CENTROS PÚBLICOS' then 'Pública'
            when 'CENTROS PRIVADOS' then 'Privada'
        end as titularidad,
        alumnos
    from {{ source('raw_educacion_privada', 'educacion_privada_fp_ciclos') }}
    where es_familia
),

unido as (
    select curso, cod_ccaa, grado, modalidad, familia, titularidad, sum(alumnos) as alumnos
    from (
        select * from totales
        union all
        select * from familias where familia <> 'Total'
    )
    group by all
),

con_todas as (
    select * from unido
    union all
    select curso, cod_ccaa, grado, 'Todas', familia, titularidad, sum(alumnos)
    from unido
    group by all
),

con_total as (
    select
        *,
        sum(case when titularidad = 'Total' then alumnos end)
            over (partition by curso, cod_ccaa, grado, modalidad, familia) as alumnos_total
    from con_todas
)

select
    c.cod_ccaa,
    t.nombre as ccaa,
    c.curso,
    cast(right(c.curso, 4) as integer) as anio,
    c.grado,
    c.modalidad,
    c.familia,
    c.titularidad,
    cast(c.alumnos as bigint) as alumnos,
    100.0 * c.alumnos / nullif(c.alumnos_total, 0) as cuota_pct
from con_total c
join {{ ref('territorios') }} t
    on t.cod = c.cod_ccaa and t.nivel = case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end
where c.alumnos_total > 0
