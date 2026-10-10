-- Estudiantes matriculados en universidades públicas y privadas por comunidad autónoma, curso,
-- nivel y modalidad. Fuente: Ministerio de Ciencia, Innovación y Universidades, Sistema
-- Integrado de Información Universitaria (SIIU), Estadística de Estudiantes Universitarios,
-- series históricas por comunidad (HIST_GRADO y HIST_MASTER, *_matric_sexo_rama_ca.px),
-- ambos sexos y todas las ramas.
--   nivel: 'Grado' (incluye las antiguas licenciaturas, diplomaturas e ingenierías: datos desde
--   1985-86), 'Máster' (oficial, desde 2006-07) y 'Grado y máster' (suma; solo cursos con máster).
--   modalidad: 'Todas', 'Presencial' o 'No presencial' (UNIR, UOC, VIU, UDIMA... cuentan en la
--   comunidad de su sede aunque sus alumnos vivan en toda España).
--   tipo_universidad: 'Total', 'Pública', 'Privada'; cuota_pct sobre el Total de la misma
--   comunidad, curso, nivel y modalidad.
-- La comunidad es la de la universidad. España ('00') incluye las universidades de ámbito
-- estatal (UNED, UIMP), que no se asignan a ninguna comunidad. El último curso es provisional
-- (es_provisional). anio = año de fin del curso.
with base as (
    select
        nivel,
        case when cod_siiu = 'CAXX' then '00' else right(cod_siiu, 2) end as cod_ccaa,
        curso,
        case modalidad when 'Total' then 'Todas' when 'Presencial' then 'Presencial'
            when 'No Presencial' then 'No presencial' end as modalidad,
        tipo_universidad,
        estudiantes
    from {{ source('raw_educacion_privada', 'educacion_privada_univ_matriculados') }}
    where nivel_academico = 'Total'
      and cod_siiu not in ('CA00', 'CAYY')
      and modalidad in ('Total', 'Presencial', 'No Presencial')
      and tipo_universidad in ('Total', 'Pública', 'Privada')
),

con_suma as (
    select * from base
    union all
    select 'Grado y máster', cod_ccaa, curso, modalidad, tipo_universidad, sum(estudiantes)
    from base
    where curso in (select curso from base where nivel = 'Máster')
    group by all
),

con_total as (
    select
        *,
        sum(case when tipo_universidad = 'Total' then estudiantes end)
            over (partition by nivel, cod_ccaa, curso, modalidad) as estudiantes_total
    from con_suma
)

select
    c.cod_ccaa,
    t.nombre as ccaa,
    c.curso,
    cast(right(c.curso, 4) as integer) as anio,
    c.nivel,
    c.modalidad,
    c.tipo_universidad,
    cast(c.estudiantes as bigint) as estudiantes,
    100.0 * c.estudiantes / nullif(c.estudiantes_total, 0) as cuota_pct,
    c.curso = (select max(curso) from base) as es_provisional
from con_total c
join {{ ref('territorios') }} t
    on t.cod = c.cod_ccaa and t.nivel = case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end
where c.estudiantes_total > 0
