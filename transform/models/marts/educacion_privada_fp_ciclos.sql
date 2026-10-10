-- Alumnado de FP por ciclo formativo (título), con su familia profesional, por comunidad
-- autónoma, curso, grado, modalidad y titularidad (Total / Pública / Privada). Fuente:
-- Ministerio de Educación, FP y Deportes, Estadística de las Enseñanzas no universitarias
-- (EDUCAbase), tablas «por comunidad autónoma/provincia, ciclo formativo y titularidad» de
-- gen-ciclos-fp de cada curso, desde 2016-17 (2016-17 y 2017-18 suman planes LOGSE y LOE).
-- Es el detalle que esconde el total por familia: en ciclos concretos (p. ej. Higiene
-- bucodental, Desarrollo de aplicaciones multiplataforma) la privada puede ser mayoría.
-- La fuente no separa aquí la concertada de la no concertada (ver educacion_privada_fp).
-- Nombre del ciclo sin el código numérico que lleva en algunos cursos; el nombre exacto puede
-- variar ligeramente entre cursos. modalidad 'Todas' = presencial + a distancia.
-- cuota_pct: alumnos de la titularidad sobre el Total del mismo ciclo, comunidad, curso,
-- grado y modalidad. anio = año de fin del curso.
with ciclos as (
    select
        curso,
        cod_ccaa,
        grado,
        modalidad,
        {{ educacion_privada_familia_expr('familia') }} as familia,
        trim(regexp_replace(ciclo, '^\d+\s*', '')) as ciclo,
        case titularidad
            when 'TODOS LOS CENTROS' then 'Total'
            when 'CENTROS PÚBLICOS' then 'Pública'
            when 'CENTROS PRIVADOS' then 'Privada'
        end as titularidad,
        alumnos
    from {{ source('raw_educacion_privada', 'educacion_privada_fp_ciclos') }}
    where not es_familia
),

unido as (
    select curso, cod_ccaa, grado, modalidad, familia, ciclo, titularidad, sum(alumnos) as alumnos
    from ciclos
    group by all
),

con_todas as (
    select * from unido
    union all
    select curso, cod_ccaa, grado, 'Todas', familia, ciclo, titularidad, sum(alumnos)
    from unido
    group by all
),

con_total as (
    select
        *,
        sum(case when titularidad = 'Total' then alumnos end)
            over (partition by curso, cod_ccaa, grado, modalidad, familia, ciclo) as alumnos_total
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
    c.ciclo,
    c.titularidad,
    cast(c.alumnos as bigint) as alumnos,
    100.0 * c.alumnos / nullif(c.alumnos_total, 0) as cuota_pct
from con_total c
join {{ ref('territorios') }} t
    on t.cod = c.cod_ccaa and t.nivel = case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end
where c.alumnos_total > 0
